import SwiftUI

/// Small chat popover for talking to your buddy pet.
struct BuddyChatView: View {
    @ObservedObject private var chatService = BuddyChatService.shared
    @ObservedObject private var manager = BuddyManager.shared
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    let onClose: () -> Void

    private var identity: BuddyIdentity { manager.effectiveIdentity }
    private var buddyName: String {
        identity.name ?? identity.species.rawValue.capitalized
    }
    private var rarityColor: Color { Color(nsColor: identity.rarity.nsColor) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Chat with \(buddyName)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                if !chatService.messages.isEmpty {
                    Button {
                        chatService.clearHistory()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear chat")
                }
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider().background(Color.white.opacity(0.1))

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        if chatService.messages.isEmpty {
                            emptyState
                        }
                        ForEach(chatService.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                        if chatService.isLoading {
                            typingIndicator
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .onChange(of: chatService.messages.count) { _, _ in
                    if let last = chatService.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)

            Divider().background(Color.white.opacity(0.1))

            // Input
            HStack(spacing: 6) {
                TextField("Say something...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.body)
                        .foregroundColor(inputText.isEmpty ? .secondary : rarityColor)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty || chatService.isLoading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Components

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text(SpriteData.face(species: identity.species, eye: identity.eye))
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(rarityColor)
            if chatService.isConfigured {
                Text("*\(buddyName) looks at you expectantly*")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text("Set up an API key in Settings > Claude Code > Buddy Chat to talk to \(buddyName)!")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func messageBubble(_ message: BuddyChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 30) }

            Text(message.content)
                .font(.system(size: 11))
                .foregroundColor(message.role == .user ? .white : .white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(message.role == .user
                              ? Color.blue.opacity(0.3)
                              : Color.white.opacity(0.08))
                )
                .textSelection(.enabled)

            if message.role == .assistant { Spacer(minLength: 30) }
        }
    }

    private var typingIndicator: some View {
        HStack {
            Text("*\(buddyName) is thinking...*")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .italic()
            Spacer()
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""

        Task {
            await chatService.send(text)
        }
    }
}
