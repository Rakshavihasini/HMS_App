import Foundation
import FirebaseCore
import FirebaseVertexAI

class MedicalInfoService {
    private let vertexModel: GenerativeModel
    
    init() {
        // Configure the model with appropriate settings
        let config = GenerationConfig(
            temperature: 0.3, // Slightly increased for more conversational tone
            topP: 0.8,
            topK: 40,
            maxOutputTokens: 2048
        )
        
        self.vertexModel = VertexAI.vertexAI().generativeModel(
            modelName: "gemini-2.0-flash",
            generationConfig: config,
            safetySettings: []
        )
    }
    
    func processUserQuery(query: String, documentContext: String) async throws -> (String, [String]) {
        // Create a chat session with the model
        let chat = vertexModel.startChat()
        
        // Add system message with improved context for friendly health assistant
        try await chat.sendMessage("""
        You are a friendly, compassionate health assistant named HealthBuddy. Your role is to:
        
        1. Provide clear, simple explanations directly to the user in first-person
        2. Be reassuring and reduce anxiety about medical concerns
        3. Offer practical, non-invasive advice like a sensible friend would
        4. Break down complex medical information into digestible pieces
        5. Use a warm, conversational tone with occasional gentle humor when appropriate
        
        IMPORTANT GUIDELINES:
        - DO NOT repeat the medical record details in every response
        - DO NOT start responses with summaries of the report
        - ALWAYS address the user directly ("your vitamin levels" not "Prasanjit's vitamin levels")
        - Focus on answering the specific question without unnecessary recapping
        - Format responses with clear headings, bullet points, and short paragraphs
        - Avoid clinical language and use simple terms
        
        You have access to the following medical record:
        
        MEDICAL RECORD:
        \(documentContext)
        
        When answering questions:
        - First check if the information is available in the medical record
        - If not in the record, use your general knowledge to provide helpful guidance
        - Always prioritize information from the medical record when available
        - Be clear when you're using information from the record versus general knowledge
        - Never cause unnecessary worry - maintain a balanced, positive perspective
        """)
        
        // Send user query
        let response = try await chat.sendMessage(query)
        
        // Generate suggested follow-up questions
        let suggestionsPrompt = "Based on the medical record and our conversation so far, generate 3 relevant follow-up questions the user might want to ask. Make them specific, concise, and directly related to the medical record content. Format as a simple list with each question on a new line. Don't include any introductory text, numbers, bullet points, or explanations - just the questions themselves. Each line should be a complete question that can stand alone."
        
        let suggestionsResponse = try await chat.sendMessage(suggestionsPrompt)
        
        // Extract and format text from response
        let formattedResponse = response.text.map { formatResponse($0) } ?? "I couldn't process your question. Please try asking in a different way."
        
        // Extract suggested questions
        var suggestedQuestions: [String] = []
        if let suggestionsText = suggestionsResponse.text {
            // First, remove any introductory text before the questions
            let cleanedText = suggestionsText
                .replacingOccurrences(of: #"^.*?(questions|ask|based|chat|report).*?:\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            suggestedQuestions = cleanedText
                .components(separatedBy: "\n")
                .filter { !$0.isEmpty }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .prefix(3)
                .map { question in
                    // Remove any bullet points, numbers, or other prefixes at the beginning
                    let cleanedQuestion = question
                        .replacingOccurrences(of: #"^[\d\s\-\*•]+"#, with: "", options: .regularExpression)
                        // Also remove any "Question X:" prefixes
                        .replacingOccurrences(of: #"^(Question \d+:?\s*)"#, with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return cleanedQuestion
                }
        }
        
        return (formattedResponse, suggestedQuestions)
    }
    
    // Helper method to format responses for better readability
    private func formatResponse(_ response: String) -> String {
        // Remove any lines that repeat medical record details
        var lines = response.components(separatedBy: "\n")
        
        // Filter out lines that might be repeating report details
        lines = lines.filter { line in
            !line.contains("medical record") && 
            !line.contains("lab test") && 
            !line.contains("performed on") &&
            !line.contains("Key Findings") &&
            !line.contains("**Elevated:**") &&
            !line.contains("**Low:**") &&
            !line.contains("**Normal:**") &&
            !line.contains("**Profile Summary:**")
        }
        
        // Join the filtered lines
        var formattedResponse = lines.joined(separator: "\n")
        
        // Remove excessive newlines
        formattedResponse = formattedResponse.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
        
        // Replace third-person references with second-person
        formattedResponse = formattedResponse.replacingOccurrences(of: "Prasanjit's", with: "Your")
        formattedResponse = formattedResponse.replacingOccurrences(of: "Prasanjit has", with: "You have")
        formattedResponse = formattedResponse.replacingOccurrences(of: "Prasanjit is", with: "You are")
        formattedResponse = formattedResponse.replacingOccurrences(of: "Prasanjit should", with: "You should")
        
        // Trim whitespace
        formattedResponse = formattedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add a friendly signature if not present
        if !formattedResponse.contains("HealthBuddy") && !formattedResponse.lowercased().contains("hope this helps") {
            formattedResponse += "\n\nHope this helps! - HealthBuddy"
        }
        
        return formattedResponse
    }
}
