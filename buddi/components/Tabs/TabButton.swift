//
//  TabButton.swift
//  buddi
//
//

import os
import SwiftUI

private let tabButtonLogger = os.Logger(subsystem: "com.josh.flick", category: "TabButton")

struct TabButton: View {
    let label: String
    let icon: String
    let selected: Bool
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            Image(systemName: icon)
                .padding(.horizontal, 15)
                .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TabButton(label: "Home", icon: "tray.fill", selected: true) {
        tabButtonLogger.debug("Tapped")
    }
}
