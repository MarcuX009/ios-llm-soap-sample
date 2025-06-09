//
//  ContentViewModel.swift
//  Qwen3_tester
//
//  Created by Marcus Lee on 5/14/25.
//

import Foundation

enum TestCase: String, CaseIterable, Identifiable {
    case case1 = "Case 1"
    case case2 = "Case 2"
    case case3 = "Case 3"
    
    var id: String { self.rawValue }
}

@MainActor
class ContentViewModel: ObservableObject {
    @Published var llm = LLMEvaluator()
    @Published var finalSOAPNote = ""
    
    func generate() {
        llm.generate()
    }
    
    func cancel() {
        llm.cancelGeneration()
    }
    
    func generateSOAP(label: String, forCase testCase: TestCase) {
        self.finalSOAPNote = ""
        
        let input = patientInput(forCase: testCase)
        llm.prompt = llm.makePrompt(label: label, inputs: input)
        generate()
    }
    
    func generateFullSOAP(forCase testCase: TestCase) async {
        self.finalSOAPNote = ""
        
        let input = patientInput(forCase: testCase)
        var sections: [String: String] = [:]
        var allOutput = ""
        
        llm.output = "Generating Full SOAP Note for \(testCase.rawValue)...\n\n"
        
        for label in ["S", "O", "A", "P"] {
            let prompt = llm.makePrompt(label: label, inputs: input, previousSections: sections)
            
            let currentStepOutput = "--- Generating \(label) ---\n"
            allOutput += currentStepOutput
            llm.output = allOutput
            
            await llm.generate(prompt: prompt)
            
            let components = llm.output.components(separatedBy: "</think>")
            let sectionResult = (components.last ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            sections[label] = sectionResult
            
            allOutput = allOutput.replacingOccurrences(of: currentStepOutput, with: "\(sectionResult)\n\n")
            llm.output = allOutput
        }
        
        let note = """
                \(sections["S"] ?? "S: Data not generated.")
                
                \(sections["O"] ?? "O: Data not generated.")
                
                \(sections["A"] ?? "A: Data not generated.")
                
                \(sections["P"] ?? "P: Data not generated.")
                """
        
        self.finalSOAPNote = note
    }
    private func patientInput(forCase testCase: TestCase) -> PatientInput {
        switch testCase {
        case .case1:
            return case1_InitialVisit_WorriedWell()
        case .case2:
            return case2_InitialVisit_MetabolicRisk()
        case .case3:
            return case3_InitialVisit_StressAndSleep()
        }
    }
    
    private func case1_InitialVisit_WorriedWell() -> PatientInput {
        return PatientInput(
            Metadata: [
                "Age": "32",
                "Sex": "Male"
            ],
            Subjective: [
                "Chief Complaint": "Heart palpitations and persistent fatigue for the last 2 weeks.",
                "Symptoms": "Feels his heart 'fluttering' especially in the evening. Finds it hard to concentrate at work. General feeling of being 'wired but tired'.",
                "Lifestyle": "Works long hours, typically 10-12 hours a day. Reports high stress levels from a recent project deadline.",
                "Diet": "Admits to drinking 4-5 cups of coffee per day to stay focused. Often skips lunch or orders takeout.",
                "Sleep": "Reports difficulty falling asleep and wakes up 2-3 times during the night. Feels unrefreshed in the morning.",
                "Family History": "No significant family history of heart disease."
            ],
            Objective: [
                // Data from HealthKit from the past 2 weeks
                "Resting Heart Rate (Avg)": "75 bpm",
                "Walking Heart Rate (Avg)": "110 bpm",
                "High Heart Rate Events": "4 notifications in the last 14 days (>120 bpm at rest)",
                "Heart Rate Variability (SDNN Avg)": "35 ms (Lower than his usual 55 ms)",
                "Time Asleep (Avg)": "5 hr 30 min",
                "Sleep Efficiency (Avg)": "75%",
                "Caffeine Intake (Avg Daily)": "450 mg",
                "Mindful Minutes": "0 min logged",
                "State of Mind (Logged)": "Frequently logged 'Stressed' and 'Anxious' moods."
            ]
        )
    }
    private func case2_InitialVisit_MetabolicRisk() -> PatientInput {
        return PatientInput(
            Metadata: [
                "Age": "48",
                "Sex": "Male"
            ],
            Subjective: [
                "Chief Complaint": "General annual check-up.",
                "Symptoms": "Reports feeling 'more tired than usual' over the past year. Notes increased thirst and needing to urinate more often, especially at night. Experiences some numbness in his feet occasionally.",
                "Lifestyle": "Sedentary job. Drives to work. Watches TV in the evening.",
                "Diet": "Enjoys fast food and sugary drinks. Doesn't actively track nutrition.",
                "Exercise": "Reports 'no time for exercise'.",
                "Family History": "Father had Type 2 Diabetes, Mother has Hypertension."
            ],
            Objective: [
                // Data from HealthKit from the past 30 days
                "Weight": "95 kg",
                "Height": "178 cm",
                "Body Mass Index (BMI)": "29.9 kg/m²",
                "Waist Circumference": "105 cm",
                "Steps (Avg Daily)": "3,500 steps",
                "Flights Climbed (Avg Daily)": "2 flights",
                "Blood Pressure (from home cuff)": "Several readings logged, avg 138/88 mmHg",
                "Apple Walking Steadiness": "OK (82%)",
                "Number of Times Fallen": "0"
            ]
        )
    }
    private func case3_InitialVisit_StressAndSleep() -> PatientInput {
        return PatientInput(
            Metadata: [
                "Age": "22",
                "Sex": "Female"
            ],
            Subjective: [
                "Chief Complaint": "Trouble sleeping and feeling down for the past month.",
                "Symptoms": "Cannot quiet her mind at night, leading to taking 2-3 hours to fall asleep. Feels irritable and has low motivation for her studies. Cries easily over small things.",
                "Social History": "Lives in a dorm. Feels isolated due to heavy study load.",
                "Diet": "Reports loss of appetite and sometimes forgetting to eat.",
                "Medications": "Not taking any prescription medications."
            ],
            Objective: [
                // Data from HealthKit from the past 30 days
                "Time in Bed (Avg)": "9 hr",
                "Time Asleep (Avg)": "5 hr 15 min",
                "Sleep Stages (Avg)": "Deep: 30 min, REM: 1 hr",
                "Wrist Temperature (during sleep)": "Avg +0.4°C deviation from baseline",
                "Mental Health Assessment (PHQ-9)": "Logged a score of 14 (Moderately Severe Depression)",
                "State of Mind (Logged)": "Predominantly 'Unpleasant' moods logged, with emotions like 'Sad', 'Overwhelmed'.",
                "Active Energy Burned (Avg Daily)": "150 kcal (significantly lower than her baseline)",
                "Menstrual Cycles": "Logged as 'Irregular' for the past 2 cycles."
            ]
        )
    }
    // MARK: previous unfinished study, saving it for later
    //    func defaultPatientInput() -> PatientInput {
    //        return PatientInput(
    //            Metadata: [
    //                "Age": "Unknown",
    //                "Sex": "Unknown"
    //            ],
    //            Subjective: [
    //                "Chief Complaint": "First-time seizure at home.",
    //                "Recent Illness": "Felt sick for 2-3 days; upper respiratory infection symptoms (cough, nasal congestion).",
    //                "Event Description": "Patient does not remember the event clearly. Mother reports hearing a 'thud', finding patient shaking on the floor, incontinent of urine and stool. Shaking lasted 1-2 minutes.",
    //                "Diet/Hydration": "Decreased appetite; picky eater; has only eaten french fries. Encouraged to drink Gatorade and Pedialyte.",
    //                "Past Medical History": "No significant PMH, surgeries, or hospitalizations.",
    //                "Allergies": "Amoxicillin (causes hives).",
    //                "Medications": "No daily medications.",
    //                "Vaccinations": "Up to date.",
    //                "Family History": "Hypertension; no family history of seizures.",
    //                "Social History": "Lives in a house with mom; feels safe at home; no one else at home sick recently."
    //            ],
    //            Objective: [
    //                "Temperature": "38°C",
    //                "Heart Rate": "108 bpm",
    //                "Blood Pressure": "111/70 mmHg",
    //                "Respiratory Rate": "26 breaths/min",
    //                "Oxygen Saturation": "97% on room air",
    //                "Initial Mental Status": "Somnolent, arousable, confused (postictal state)"
    //            ]
    //        )
    //    }
}
