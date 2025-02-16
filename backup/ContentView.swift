//
//  ContentView.swift
//  Ollama Extension
//
//  Created by Stanislav Fatkhutdinov on 2/15/25.
//

import SwiftUI

// Add the model import
struct XcodeContext {
    let currentFile: String
    let fileStructure: [String: Any]
    let imports: [String]
    let selectedCode: String
    let surroundingContext: String
    
    static let empty = XcodeContext(
        currentFile: "",
        fileStructure: [:],
        imports: [],
        selectedCode: "",
        surroundingContext: ""
    )
}

struct ContentView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputMessage: String = ""
    @State private var currentContext: XcodeContext = .empty
    
    var body: some View {
        HSplitView {
            // Chat interface
            VStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                HStack {
                    TextField("Type your message...", text: $inputMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            if !inputMessage.isEmpty {
                                sendMessage()
                            }
                        }
                        .submitLabel(.send)
                    
                    Button("Send") {
                        if !inputMessage.isEmpty {
                            sendMessage()
                        }
                    }
                }
                .padding()
            }
            .frame(minWidth: 300)
            
            // Context viewer
            VStack {
                Text("Current Context")
                    .font(.headline)
                    .padding()
                
                List {
                    Text("Current File: \(currentContext.currentFile)")
                    
                    Section("Imports") {
                        ForEach(currentContext.imports, id: \.self) { import_ in
                            Text(import_)
                        }
                    }
                    
                    Section("Selected Code") {
                        Text(currentContext.selectedCode)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .frame(minWidth: 200)
        }
    }
    
    private func sendMessage() {
        let userMessage = ChatMessage(content: inputMessage, isUser: true)
        messages.append(userMessage)
        
        OllamaService.shared.processCode(inputMessage) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let aiMessage = ChatMessage(content: response, isUser: false)
                    messages.append(aiMessage)
                case .failure(let error):
                    let errorMessage = ChatMessage(content: "Error: \(error.localizedDescription)", isUser: false)
                    messages.append(errorMessage)
                }
            }
        }
        
        inputMessage = ""
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.content)
                .padding()
                .background(message.isUser ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            
            if !message.isUser { Spacer() }
        }
    }
}

#Preview {
    ContentView()
}
