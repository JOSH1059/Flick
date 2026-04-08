import Combine
import SwiftUI

enum NotchContentType: Equatable {
    case instances
    case menu
    case chat(SessionState)

    var id: String {
        switch self {
        case .instances: return "instances"
        case .menu: return "menu"
        case .chat(let session): return "chat-\(session.sessionId)"
        }
    }
}

@MainActor
class BuddyPanelViewModel: ObservableObject {
    @Published var contentType: NotchContentType = .instances

    private var currentChatSession: SessionState?

    func showChat(for session: SessionState) {
        if case .chat(let current) = contentType, current.sessionId == session.sessionId {
            return
        }
        contentType = .chat(session)
    }

    func exitChat() {
        currentChatSession = nil
        contentType = .instances
    }

    func restoreChatIfNeeded() {
        if let chatSession = currentChatSession {
            if case .chat(let current) = contentType, current.sessionId == chatSession.sessionId {
                return
            }
            contentType = .chat(chatSession)
        }
    }

    func saveChatState() {
        if case .chat(let session) = contentType {
            currentChatSession = session
        }
    }
}
