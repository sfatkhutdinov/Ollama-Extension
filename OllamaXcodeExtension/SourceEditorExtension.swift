import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    func extensionDidFinishLaunching() {
        // Setup any extension initialization here
    }
}

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        guard let buffer = invocation.buffer else {
            completionHandler(NSError(domain: "OllamaXcode", code: -1, userInfo: nil))
            return
        }
        
        // Get selected text or entire file content
        let selectedRanges = buffer.selections.map { $0 as! XCSourceTextRange }
        let selectedText = getSelectedText(from: buffer, ranges: selectedRanges)
        
        // Process with Ollama
        OllamaService.shared.processCode(selectedText) { result in
            switch result {
            case .success(let response):
                // Update the code with AI suggestions
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
        // Replace the selected text with the AI response
        for range in ranges.reversed() {
            let startLine = range.start.line
            let startColumn = range.start.column
            let endLine = range.end.line
            let endColumn = range.end.column
            
            // Remove the selected text
            if startLine == endLine {
                var line = buffer.lines[startLine] as! String
                line.replaceSubrange(
                    line.index(line.startIndex, offsetBy: startColumn)..<line.index(line.startIndex, offsetBy: endColumn),
                    with: text
                )
                buffer.lines[startLine] = line
            } else {
                // Handle multi-line replacement
                buffer.lines.removeObjects(in: NSRange(location: startLine, length: endLine - startLine + 1))
                buffer.lines.insert(text, at: startLine)
            }
        }
    }
} 