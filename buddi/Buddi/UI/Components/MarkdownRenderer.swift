import SwiftUI

struct BuddiMarkdownText: View {
    let text: String
    let baseColor: Color
    let fontSize: CGFloat

    init(_ text: String, color: Color = .white.opacity(0.9), fontSize: CGFloat = 13) {
        self.text = text
        self.baseColor = color
        self.fontSize = fontSize
    }

    var body: some View {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            SwiftUI.Text(attributed)
                .font(.system(size: fontSize))
                .foregroundStyle(baseColor)
                .tint(Color.accentColor)
        } else {
            SwiftUI.Text(text)
                .font(.system(size: fontSize))
                .foregroundStyle(baseColor)
        }
    }
}
