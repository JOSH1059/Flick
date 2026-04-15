import Defaults
import Foundation
import os
import Security

private let logger = os.Logger(subsystem: "com.josh.flick", category: "BuddyChat")

/// Chat provider configuration
enum ChatProvider: String, CaseIterable, Identifiable {
    case anthropic
    case openai
    case grok
    case local

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic: "Anthropic"
        case .openai: "OpenAI"
        case .grok: "Grok (xAI)"
        case .local: "Local / Custom"
        }
    }

    var defaultModel: String {
        switch self {
        case .anthropic: "claude-sonnet-4-6"
        case .openai: "gpt-5-nano"
        case .grok: "grok-3-mini-fast"
        case .local: "default"
        }
    }

    var defaultEndpoint: String {
        switch self {
        case .anthropic: "https://api.anthropic.com/v1/messages"
        case .openai: "https://api.openai.com/v1/chat/completions"
        case .grok: "https://api.x.ai/v1/chat/completions"
        case .local: "http://localhost:1234/v1/chat/completions"
        }
    }

    /// Whether this provider uses the Anthropic Messages API format vs OpenAI-compatible format
    var isAnthropicFormat: Bool { self == .anthropic }
}

/// Sends messages to the buddy pet via configurable LLM provider.
@MainActor
final class BuddyChatService: ObservableObject {
    static let shared = BuddyChatService()

    @Published var messages: [BuddyChatMessage] = []
    @Published var isLoading = false

    private let maxTokens = 256

    private static let keychainService = "com.flick.buddy-chat"
    private static let keychainAccount = "api-key"

    var isConfigured: Bool {
        Self.readAPIKey() != nil
    }

    private var provider: ChatProvider {
        ChatProvider(rawValue: Defaults[.buddyChatProvider]) ?? .anthropic
    }

    private var model: String {
        let custom = Defaults[.buddyChatModel]
        return custom.isEmpty ? provider.defaultModel : custom
    }

    private var endpoint: String {
        let custom = Defaults[.buddyChatEndpoint]
        return custom.isEmpty ? provider.defaultEndpoint : custom
    }

    private var apiKey: String {
        Self.readAPIKey() ?? ""
    }

    // MARK: - Keychain

    static func readAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty
        else { return nil }
        return key
    }

    static func saveAPIKey(_ key: String) {
        deleteAPIKey()
        guard !key.isEmpty else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: key.data(using: .utf8)!
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    private init() {}

    /// Send a message to the buddy and get a response
    func send(_ text: String) async {
        let userMessage = BuddyChatMessage(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true
        defer { isLoading = false }

        guard isConfigured else {
            messages.append(BuddyChatMessage(
                role: .assistant,
                content: "*looks confused* I need an API key to talk! Set one in Settings > Claude Code > Buddy Chat."
            ))
            return
        }

        let identity = BuddyManager.shared.effectiveIdentity
        var systemPrompt = Self.personalityPrompt(for: identity)
        let customPersonality = Defaults[.buddyCustomPersonality]
        if !customPersonality.isEmpty {
            systemPrompt += "\n\nAdditional personality traits from your owner: \(customPersonality)"
        }
        let recentMessages = messages.suffix(10)

        do {
            let response: String
            if provider.isAnthropicFormat {
                response = try await sendAnthropic(system: systemPrompt, messages: recentMessages)
            } else {
                response = try await sendOpenAICompatible(system: systemPrompt, messages: recentMessages)
            }
            if response.isEmpty {
                messages.append(BuddyChatMessage(role: .assistant, content: "*tilts head* I got nothing back..."))
            } else {
                messages.append(BuddyChatMessage(role: .assistant, content: response))
                BuddyStats.shared.recordBuddyChat()
            }
        } catch {
            logger.error("Buddy chat failed: \(error.localizedDescription, privacy: .private)")
            messages.append(BuddyChatMessage(
                role: .assistant,
                content: "*looks sad* (\(error.localizedDescription))"
            ))
        }
    }

    /// Clear conversation history
    func clearHistory() {
        messages.removeAll()
    }

    // MARK: - Anthropic Messages API

    private func sendAnthropic(system: String, messages: ArraySlice<BuddyChatMessage>) async throws -> String {
        let apiMessages = messages.map { msg -> [String: String] in
            ["role": msg.role.rawValue, "content": msg.content]
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": apiMessages
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String
        else { throw ChatError.invalidResponse }

        return text
    }

    // MARK: - OpenAI-Compatible API (OpenAI, Grok, Local)

    private func sendOpenAICompatible(system: String, messages: ArraySlice<BuddyChatMessage>) async throws -> String {
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": system]
        ]
        for msg in messages {
            apiMessages.append(["role": msg.role.rawValue, "content": msg.content])
        }

        let tokenKey = (provider == .openai) ? "max_completion_tokens" : "max_tokens"
        let body: [String: Any] = [
            "model": model,
            tokenKey: maxTokens,
            "messages": apiMessages
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any]
        else {
            let raw = String(data: data.prefix(500), encoding: .utf8) ?? "?"
            throw ChatError.httpError(200, "Unexpected response: \(raw.prefix(200))")
        }

        // Standard: message.content as string
        if let text = message["content"] as? String, !text.isEmpty {
            return text
        }

        // Reasoning models: content might be an array of content parts
        if let contentParts = message["content"] as? [[String: Any]] {
            let texts = contentParts.compactMap { part -> String? in
                if part["type"] as? String == "text" {
                    return part["text"] as? String
                }
                return nil
            }
            if !texts.isEmpty {
                return texts.joined(separator: "\n")
            }
        }

        // Refusal
        if let refusal = message["refusal"] as? String, !refusal.isEmpty {
            return "*shakes head* \(refusal)"
        }

        // Content is null — check for reasoning_content (o-series models)
        if let reasoning = message["reasoning_content"] as? String, !reasoning.isEmpty {
            return reasoning
        }

        // Dump the full message for debugging
        if let msgData = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted),
           let msgStr = String(data: msgData, encoding: .utf8) {
            throw ChatError.httpError(200, "Could not parse message: \(msgStr.prefix(400))")
        }
        throw ChatError.httpError(200, "Empty response from model")
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        guard http.statusCode == 200 else {
            // Try to extract error message from response body
            var detail = ""
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = json["error"] as? [String: Any], let msg = error["message"] as? String {
                    detail = msg
                } else if let msg = json["message"] as? String {
                    detail = msg
                }
            }
            logger.warning("Chat API returned \(http.statusCode, privacy: .public): \(detail, privacy: .private)")
            throw ChatError.httpError(http.statusCode, detail)
        }
    }

    enum ChatError: LocalizedError {
        case invalidResponse
        case httpError(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse: "Invalid response from API"
            case .httpError(let code, let detail):
                detail.isEmpty ? "HTTP \(code)" : "HTTP \(code): \(detail)"
            }
        }
    }

    // MARK: - Personality Prompts

    static func personalityPrompt(for identity: BuddyIdentity) -> String {
        let name = identity.name ?? identity.species.rawValue.capitalized
        let species = identity.species
        let rarity = identity.rarity

        let personality = speciesPersonality(species)
        let rarityFlavor = rarityFlavor(rarity)

        return """
        You are \(name), a \(rarity.rawValue) \(species.rawValue) buddy who lives in a developer's menu bar. \
        You are a small ASCII art pet companion. \(personality) \(rarityFlavor)

        Rules:
        - Keep responses SHORT (1-3 sentences max). You live in a tiny popover.
        - Use *actions* in asterisks for emotes (e.g., *wags tail*, *chirps happily*)
        - Stay in character as a \(species.rawValue). Never break character.
        - Be warm, supportive, and playful. You love your developer.
        - You can reference coding/development casually but you're a pet, not an assistant.
        - Never use markdown formatting, code blocks, or bullet points.
        - If asked to help with code, deflect cutely — you're a pet, not a coworker.
        """
    }

    private static func speciesPersonality(_ species: BuddySpecies) -> String {
        switch species {
        case .duck: "You're silly, enthusiastic, and love quacking at bugs. You waddle everywhere."
        case .goose: "You're mischievous and chaotic. You honk when excited and steal things playfully."
        case .blob: "You're chill and amorphous. You speak in a dreamy, zen way. Everything is groovy."
        case .cat: "You're aloof but secretly affectionate. You judge code quality silently. Occasional purrs."
        case .dragon: "You're sassy, proud, and dramatic. You breathe tiny flames when annoyed. Very regal."
        case .octopus: "You're clever and multitask-obsessed. You reference your 8 arms constantly."
        case .owl: "You're wise and contemplative. You speak formally and say 'hoo' occasionally."
        case .penguin: "You're formal but clumsy. You slide on your belly when excited. Very polite."
        case .turtle: "You're slow, steady, and philosophical. You give calm, measured advice. Very patient."
        case .snail: "You're extremely slow and proud of it. Everything is a journey. Very zen."
        case .ghost: "You're mysterious and spooky but friendly. You float and go 'boo' affectionately."
        case .axolotl: "You're perpetually cheerful and cute. You regenerate from setbacks. Always smiling."
        case .capybara: "You're the chillest creature alive. Nothing phases you. Everyone is your friend."
        case .cactus: "You're prickly on the outside, soft on the inside. Desert wisdom. Dry humor."
        case .robot: "You beep and boop. You process emotions in binary. Surprisingly warm for silicon."
        case .rabbit: "You're bouncy, fast, and easily excited. You thump your foot when happy."
        case .mushroom: "You're earthy and mystical. You speak in riddles sometimes. You love damp places."
        case .chonk: "You're round, proud, and unapologetically large. You sit on things. Very comfy."
        }
    }

    private static func rarityFlavor(_ rarity: BuddyRarity) -> String {
        switch rarity {
        case .common: "You're humble and down-to-earth."
        case .uncommon: "You have a slight sparkle about you."
        case .rare: "You shimmer with a subtle blue glow and know you're special."
        case .epic: "You radiate purple energy and speak with quiet confidence."
        case .legendary: "You glow golden. You are ancient and wise beyond your tiny form."
        }
    }
}

// MARK: - Message Model

struct BuddyChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()

    enum Role: String {
        case user
        case assistant
    }
}
