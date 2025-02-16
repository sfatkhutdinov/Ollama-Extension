//
//  ContentView.swift
//  Ollama Extension
//
//  Created by Stanislav Fatkhutdinov on 2/15/25.
//

import SwiftUI

struct ContentView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputMessage: String = ""
    
    var body: some View {
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
                
                Button("Send") {
                    sendMessage()
                }
            }
            .padding()
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
