import Foundation

public class OllamaService {
    public static let shared = OllamaService()
    private let baseURL = "http://localhost:11434/api"
    
    public func processCode(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/generate"
        let parameters: [String: Any] = [
            "model": "qwen2.5-coder:32b",
            "prompt": code,
            "stream": false
        ]
        
        guard let url = URL(string: endpoint),
              let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            completion(.failure(NSError(domain: "OllamaXcode", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let response = try? JSONDecoder().decode(OllamaResponse.self, from: data) else {
                completion(.failure(NSError(domain: "OllamaXcode", code: -2, userInfo: nil)))
                return
            }
            
            completion(.success(response.response))
        }.resume()
    }
}

public struct OllamaResponse: Codable {
    public let response: String
} 