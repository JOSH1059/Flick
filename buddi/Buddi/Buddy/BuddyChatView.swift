import SwiftUI

/// Chat interface for talking to your buddy pet.
/// Designed to match the Claude ChatView's visual quality.
struct BuddyChatView: View {
    @ObservedObject private var chatService = BuddyChatService.shared
    @ObservedObject private var manager = BuddyManager.shared
    @State private var inputText = ""
    @State private var isHeaderHovered = false
    @FocusState private var isInputFocused: Bool
    let onClose: () -> Void

    private var identity: BuddyIdentity { manager.effectiveIdentity }
    private var buddyName: String {
        identity.name ?? identity.species.rawValue.capitalized
    }
    private var rarityColor: Color { Color(nsColor: identity.rarity.nsColor) }
    private let fadeColor = Color(red: 0.07, green: 0.07, blue: 0.09)

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            chatHeader

            // Messages
            if chatService.messages.isEmpty {
                emptyState
            } else {
                messageList
            }

            // Input bar
            inputBar
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        Button {
            onClose()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(isHeaderHovered ? 1.0 : 0.6))
                    .frame(width: 24, height: 24)

                Text(buddyName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isHeaderHovered ? rarityColor : .white.opacity(0.85))
                    .lineLimit(1)

                Spacer()

                if !chatService.messages.isEmpty {
                    Button {
                        chatService.clearHistory()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .help("Clear chat")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHeaderHovered ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHeaderHovered = $0 }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.2))
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [fadeColor.opacity(0.7), fadeColor.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .offset(y: 24)
            .allowsHitTesting(false)
        }
        .zIndex(1)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(chatService.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }
                    if chatService.isLoading {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .onChange(of: chatService.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    if chatService.isLoading {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else if let last = chatService.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text(SpriteData.face(species: identity.species, eye: identity.eye))
                .font(.system(size: 20, design: .monospaced))
                .foregroundColor(rarityColor)
            if chatService.isConfigured {
                Text("*\(buddyName) looks at you expectantly*")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text("Add an API key in Settings to chat")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: BuddyChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            Text(message.content)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(message.role == .user
                              ? Color.white.opacity(0.12)
                              : rarityColor.opacity(0.15))
                )
                .textSelection(.enabled)

            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(rarityColor.opacity(0.5))
                    .frame(width: 5, height: 5)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(rarityColor.opacity(0.08))
        )
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message \(buddyName)...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .focused($isInputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .onSubmit {
                    sendMessage()
                }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(inputText.isEmpty || chatService.isLoading
                                     ? .white.opacity(0.2)
                                     : rarityColor.opacity(0.9))
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty || chatService.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [fadeColor.opacity(0), fadeColor.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .offset(y: -24)
            .allowsHitTesting(false)
        }
        .zIndex(1)
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { await chatService.send(text) }
    }
}
