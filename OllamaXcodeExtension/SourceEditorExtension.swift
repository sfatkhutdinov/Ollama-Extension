//
//  SourceEditorExtension.swift
//  OllamaXcodeExtension
//
//  Created by Stanislav Fatkhutdinov on 2/15/25.
//

import Foundation
import XcodeKit

@objc(SourceEditorExtension)
class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    
    func extensionDidFinishLaunching() {
        // Setup any extension initialization here
    }
    
    /*
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
        return []
    }
    */
    
}

@objc(SourceEditorCommand)
class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        // Since buffer is not optional, we can use it directly
        let buffer = invocation.buffer
        
        // Get selected text or entire file content
        let selectedRanges = buffer.selections.map { $0 as! XCSourceTextRange }
        let selectedText = getSelectedText(from: buffer, ranges: selectedRanges)
        
        // Process with Ollama
        OllamaService.shared.processCode(selectedText) { result in
            switch result {
            case .success(let response):
                self.updateBuffer(buffer, with: response, ranges: selectedRanges)
                completionHandler(nil)
            case .failure(let error):
                completionHandler(error)
            }
        }
    }
    
    private func getSelectedText(from buffer: XCSourceTextBuffer, ranges: [XCSourceTextRange]) -> String {
        var selectedText = ""
        for range in ranges {
            let startLine = range.start.line
            let startColumn = range.start.column
            let endLine = range.end.line
            let endColumn = range.end.column
            
            if startLine == endLine {
                let line = buffer.lines[startLine] as! String
                selectedText += line[line.index(line.startIndex, offsetBy: startColumn)..<line.index(line.startIndex, offsetBy: endColumn)]
            } else {
                for lineIndex in startLine...endLine {
                    let line = buffer.lines[lineIndex] as! String
                    if lineIndex == startLine {
                        selectedText += line[line.index(line.startIndex, offsetBy: startColumn)...]
                    } else if lineIndex == endLine {
                        selectedText += line[..<line.index(line.startIndex, offsetBy: endColumn)]
                    } else {
                        selectedText += line
                    }
                    selectedText += "\n"
                }
            }
        }
        return selectedText
    }
    
    private func updateBuffer(_ buffer: XCSourceTextBuffer, with text: String, ranges: [XCSourceTextRange]) {
        for range in ranges.reversed() {
            let startLine = range.start.line
            let startColumn = range.start.column
            let endLine = range.end.line
            let endColumn = range.end.column
            
            if startLine == endLine {
                var line = buffer.lines[startLine] as! String
                line.replaceSubrange(
                    line.index(line.startIndex, offsetBy: startColumn)..<line.index(line.startIndex, offsetBy: endColumn),
                    with: text
                )
                buffer.lines[startLine] = line
            } else {
                buffer.lines.removeObjects(in: NSRange(location: startLine, length: endLine - startLine + 1))
                buffer.lines.insert(text, at: startLine)
            }
        }
    }
}
