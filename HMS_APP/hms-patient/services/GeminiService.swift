import Foundation
import FirebaseVertexAI

public class GeminiService {
    public static let shared = GeminiService()
    private let generativeModel: GenerativeModel
    
    private init() {
        // Initialize the Vertex AI service
        let vertex = VertexAI.vertexAI()
        // Create a GenerativeModel instance with the appropriate model
        self.generativeModel = vertex.generativeModel(modelName: "gemini-2.0-flash")
    }
    
    public func generateText(prompt: String) async throws -> String {
        do {
            let response = try await generativeModel.generateContent(prompt)
            guard let text = response.text else {
                throw NSError(domain: "SymptomChecker", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response text received"])
            }
            return text
        } catch {
            throw error
        }
    }
} 