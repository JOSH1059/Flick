//
//  WelcomeView.swift
//  buddi
//
//

import SwiftUI
import SwiftUIIntrospect

struct WelcomeView: View {
    var onGetStarted: (() -> Void)? = nil

    private let accentTeal = Color(red: 0.45, green: 0.72, blue: 0.70)
    private let bgDark = Color(red: 0.08, green: 0.10, blue: 0.14)

    var body: some View {
        ZStack {
            // Background gradient matching the logo's dark theme
            LinearGradient(
                colors: [
                    bgDark,
                    Color(red: 0.10, green: 0.14, blue: 0.20),
                    bgDark
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle glow behind the logo
            Circle()
                .fill(accentTeal.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(y: -40)

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)

                // Logo
                Image("AppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .shadow(color: accentTeal.opacity(0.3), radius: 20, y: 4)
                    .padding(.bottom, 16)

                // Title
                Text("Flick")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                // Subtitle
                Text("Your Notch Companion")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(accentTeal.opacity(0.8))
                    .padding(.bottom, 32)

                // Get started button
                Button {
                    onGetStarted?()
                } label: {
                    Text("Get Started")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(bgDark)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(accentTeal)
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                // Credit
                HStack(spacing: 6) {
                    Image("CreatorLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 16)
                    Text("Flick by Josh")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WelcomeView()
}
