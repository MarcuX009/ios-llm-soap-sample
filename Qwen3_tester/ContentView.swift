//
//  ContentView.swift
//  Qwen3_tester
//
//  Created by Marcus Lee on 5/12/25.
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

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                HStack {
                    Spacer()
                    Text(viewModel.llm.stat)
                }
                
                HStack {
                    Toggle(isOn: $viewModel.llm.enableThinking) {
                        Text("Thinking Mode")
                            .help("Switches between thinking and non-thinking modes. Support: Qwen3")
                    }
                    
                    Spacer()
                    
                    if viewModel.llm.running {
                        ProgressView()
                            .frame(maxHeight: 20)
                        Spacer()
                    }
                }
            }
            
            ScrollView(.vertical) {
                ScrollViewReader { sp in
                    Markdown(viewModel.llm.output)
                        .textSelection(.enabled)
                        .onChange(of: viewModel.llm.output) { _, _ in
                            sp.scrollTo("bottom")
                        }
                    
                    Spacer()
                        .frame(width: 1, height: 1)
                        .id("bottom")
                }
            }
            
            HStack {
                TextField("prompt", text: Bindable(viewModel.llm).prompt)
                    .onSubmit(viewModel.generate)
                    .disabled(viewModel.llm.running)
                Button(viewModel.llm.running ? "Stop" : "Generate",
                       action: viewModel.llm.running ? viewModel.cancel : viewModel.generate)
            }
            
            if !viewModel.finalSOAPNote.isEmpty {
                Divider().padding(.vertical, 8)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Final Editable SOAP Note")
                            .font(.headline)
                        Spacer()
                        Button {
                            copyToClipboard(viewModel.finalSOAPNote)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                    TextEditor(text: $viewModel.finalSOAPNote)
                        .frame(height: 200)
                        .border(Color.gray.opacity(0.5), width: 1)
                        .font(.body.monospaced())
                }
                .padding(.top)
            }
            
            Divider().padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Generate individual SOAP sections:")
                    .font(.subheadline)
                
                ForEach(["S", "O", "A", "P"], id: \.self) { label in
                    HStack {
                        Text("\(label):")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .frame(width: 25, alignment: .leading)
                        
                        ForEach(TestCase.allCases) { testCase in
                            Button(testCase.rawValue.split(separator: ":")[0]) {
                                viewModel.generateSOAP(label: label, forCase: testCase)
                            }
                            .help("Generate \(label) for \(testCase.rawValue)")
                        }
                    }
                }
                Divider().padding(.vertical, 4)
                
                Text("Generate Full SOAP Note:")
                    .font(.headline)
                
                HStack {
                    ForEach(TestCase.allCases) { testCase in
                        Button(testCase.rawValue) {
                            Task {
                                await viewModel.generateFullSOAP(forCase: testCase)
                            }
                        }
                    }
                }
            }
            .disabled(viewModel.llm.running)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        copyToClipboard(viewModel.llm.output)
                    }
                } label: {
                    Label("Copy Output", systemImage: "doc.on.doc.fill")
                }
                .disabled(viewModel.llm.output == "")
                .labelStyle(.titleAndIcon)
            }
        }
        .task {
            _ = try? await viewModel.llm.load()
        }
    }
    
    private func copyToClipboard(_ string: String) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
#else
        UIPasteboard.general.string = string
#endif
    }
}

#Preview {
    ContentView()
}
