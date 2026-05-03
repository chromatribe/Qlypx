//
//  SnippetCSVService.swift
//  Qlypx
//

import Foundation

final class SnippetCSVService {
    
    static let shared = SnippetCSVService()
    
    /// CSV形式にエクスポート
    func export(folders: [QLYFolder]) -> String {
        var csvString = ""
        
        for folder in folders {
            for snippet in folder.snippets {
                let row = [folder.title, snippet.title, snippet.content]
                    .map { escapeCSVField($0) }
                    .joined(separator: ",")
                csvString += row + "\n"
            }
        }
        
        return csvString
    }
    
    /// CSVからインポート
    func parse(csvString: String) -> [(folder: String, title: String, content: String)] {
        var results: [(folder: String, title: String, content: String)] = []
        
        let lines = csvString.components(separatedBy: .newlines)
        for line in lines where !line.isEmpty {
            let fields = parseCSVLine(line)
            if fields.count >= 3 {
                results.append((folder: fields[0], title: fields[1], content: fields[2]))
            }
        }
        
        return results
    }
    
    // MARK: - Private Helpers
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var skipNext = false
        
        let characters = Array(line)
        for i in 0..<characters.count {
            if skipNext {
                skipNext = false
                continue
            }
            
            let char = characters[i]
            if char == "\"" {
                if inQuotes && i + 1 < characters.count && characters[i + 1] == "\"" {
                    // Double quote means escaped quote
                    currentField.append("\"")
                    skipNext = true
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        fields.append(currentField)
        
        return fields
    }
}
