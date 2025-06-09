//
//  LLMEvaluator.swift
//  Qwen3_tester
//
//  Created by Marcus Lee on 5/14/25.
//

import AsyncAlgorithms
import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom
import MarkdownUI
import Metal
import SwiftUI
import Tokenizers
import Foundation

@Observable
@MainActor
class LLMEvaluator {
    
    var running = false
    var enableThinking = true
    
    var prompt = ""
    var output = ""
    var stat = ""
    
    let modelConfiguration = LLMRegistry.qwen3_1_7b
    
    /// parameters controlling the output
    let generateParameters = GenerateParameters(maxTokens: 1000, temperature: 0.6)
    let updateInterval = Duration.seconds(0.25)
    
    /// A task responsible for handling the generation process.
    var generationTask: Task<Void, Error>?
    
    enum LoadState {
        case idle
        case loaded(ModelContainer)
    }
    
    var loadState = LoadState.idle
    
    private func formatDictionary(_ data: [String: String]) -> String {
        return data.map { key, value in "\(key): \(value)" }.joined(separator: "\n")
    }
    
    func makePrompt(label: String, inputs: PatientInput, previousSections: [String: String] = [:]) -> String {
        let sectionName: String = [
            "S": "Subjective",
            "O": "Objective",
            "A": "Assessment",
            "P": "Plan"
        ][label] ?? ""
        
        let metadataSection = formatDictionary(inputs.Metadata)
        let subjectiveSection = formatDictionary(inputs.Subjective)
        let objectiveSection = formatDictionary(inputs.Objective)
        
        let systemRole = """
            ### Your Role and Goal
            You are an AI assistant for primary care physicians. Your task is to process pre-visit information from a patient's questionnaire and their HealthKit data to generate a concise DRAFT SOAP note for an INITIAL CONSULTATION.
            """
        
        let patientData = """
            ### Patient Metadata
            \(metadataSection)
            
            ### Patient's Subjective Report
            \(subjectiveSection)
            
            ### Patient's Objective HealthKit Data
            \(objectiveSection)
            """
        
        var contextSection = ""
        if !previousSections.isEmpty {
            contextSection = "\n### Previously Generated Sections (for context):\n\(formatDictionary(previousSections))"
        }
        
        var instructions = ""
        switch label {
            
        case "S":
            instructions = """
                ### Your Current Task: Generate the '\(sectionName)' Section (S)
                - Summarize the patient's self-reported reasons for this initial consultation into a coherent narrative paragraph.
                - You MUST ONLY use information from the 'Patient's Subjective Report'.
                - Your output MUST start with exactly "S:".
                
                Now, generate ONLY the 'S' section.
                """
            // For 'S', return a lean prompt with NO context of A or P.
            return "\(systemRole)\n\n\(patientData)\n\n\(instructions)"
            
        case "O":
            instructions = """
                ### Your Current Task: Generate the '\(sectionName)' Section (O)
                - From the 'Patient's Objective HealthKit Data', select and list ONLY the most clinically relevant measurements for the patient's complaint.
                - If a specific vital sign is NOT provided, you MUST omit it. DO NOT invent data.
                - Your output MUST start with exactly "O:".
                
                Now, generate ONLY the 'O' section.
                """
            // For 'O', also return a lean prompt.
            return "\(systemRole)\n\n\(patientData)\n\n\(instructions)"
            
        case "A":
            instructions = """
                ### Your Current Task: Generate the '\(sectionName)' Section (A)
                - Act as a reviewing clinician. Based on ALL the information provided above (S and O), formulate a preliminary 'Problem List'.
                - These are potential issues for the doctor to investigate, NOT a final diagnosis.
                - Frame it as a numbered list of concise clinical observations.
                - Your output MUST start with exactly "A:".
                
                Now, based on all the information above, generate the 'A' section as a 'Problem List'.
                """
            
        case "P":
            instructions = """
                ### Your Current Task: Generate the '\(sectionName)' Section (P)
                - Based on the Assessment (A) and all other data, suggest an 'Initial Plan & Discussion Points' for the physician to CONSIDER.
                - Focus on potential diagnostic steps (e.g., lab tests), lifestyle topics to discuss, and referrals.
                - This MUST be a numbered list.
                - Your output MUST start with exactly "P:".
                
                Now, based on the 'Problem List' in the Assessment, generate the 'P' section.
                """
            
        default:
            break
        }
        
        // For 'A' and 'P', assemble the prompt with the full context.
        return "\(systemRole)\n\n\(patientData)\(contextSection)\n\n\(instructions)"
    }
    
    
    func load() async throws -> ModelContainer {
        switch loadState {
        case .idle:
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
            
            let modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: modelConfiguration
            )
            let _ = await modelContainer.perform { context in
                context.model.numParameters()
            }
            
            loadState = .loaded(modelContainer)
            return modelContainer
            
        case .loaded(let modelContainer):
            return modelContainer
        }
    }
    
    func generate(prompt: String) async {
        print("🟡 [LLMEvaluator] Start generating...")
        self.output = ""
        let chat: [Chat.Message] = [
            .system("You are a helpful clinician assistant"),
            .user(prompt),
        ]
        let userInput = UserInput(
            chat: chat, additionalContext: ["enable_thinking": enableThinking])
        print("🟡 [LLMEvaluator] User input ready.")
        
        do {
            let modelContainer = try await load()
            print("🟢 [LLMEvaluator] Model loaded")
            
            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))
            
            try await modelContainer.perform { (context: ModelContext) -> Void in
                let lmInput = try await context.processor.prepare(input: userInput)
                print("🟢 [LLMEvaluator] Input prepared")
                
                let stream = try MLXLMCommon.generate(
                    input: lmInput, parameters: generateParameters, context: context)
                print("🟢 [LLMEvaluator] Stream ready")
                
                for await batch in stream._throttle(
                    for: updateInterval, reducing: Generation.collect)
                {
                    print("🔁 [LLMEvaluator] Batch received")
                    
                    let output = batch.compactMap { $0.chunk }.joined(separator: "")
                    print("🧩 [LLMEvaluator] Output chunk: \"\(output)\"")
                    
                    if !output.isEmpty {
                        Task { @MainActor [output] in
                            self.output += output
                        }
                    }
                    
                    if let completion = batch.compactMap({ $0.info }).first {
                        print("⚡️ [LLMEvaluator] tokens/s: \(completion.tokensPerSecond)")
                        Task { @MainActor in
                            self.stat = "\(completion.tokensPerSecond) tokens/s"
                        }
                    }
                }
            }
            
        } catch {
            output = "Failed: \(error)"
        }
    }
    
    
    func generate() {
        guard !running else { return }
        let currentPrompt = prompt
        prompt = ""
        generationTask = Task {
            running = true
            await generate(prompt: currentPrompt)
            running = false
        }
    }
    
    func cancelGeneration() {
        generationTask?.cancel()
        running = false
    }
}
