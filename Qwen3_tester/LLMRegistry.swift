//
//  LLMRegistry.swift
//  Qwen3_tester
//
//  Created by Marcus Lee on 5/14/25.
//

import Foundation
import MLXLMCommon

enum LLMRegistry {
    static let qwen3_1_7b: ModelConfiguration = {
        guard let tokenizerURL = Bundle.main.url(
            forResource: "tokenizer", withExtension: "json")
        else {
            fatalError("❌ tokenizer.json not in Bundle")
        }

        let modelDir = tokenizerURL.deletingLastPathComponent()
        print("✅ nice nice nice, found model dir is:", modelDir.path)

        return ModelConfiguration(
            directory: modelDir,
            overrideTokenizer: "tokenizer.json",
            defaultPrompt: "Who is Wenjin Li from USC😜?"
        )
    }()
}

