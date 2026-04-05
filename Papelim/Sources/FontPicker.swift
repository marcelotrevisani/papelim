import SwiftUI
import AppKit

/// Picker over all system font families. Empty string represents "default
/// monospace". The list is cached at first access (AppKit call is not cheap).
enum SystemFonts {
    static let families: [String] = NSFontManager.shared.availableFontFamilies.sorted()
    static let defaultLabel = "Monospace (default)"
}

struct FontPicker: View {
    @Binding var family: String?

    var body: some View {
        Menu {
            Button(SystemFonts.defaultLabel) { family = nil }
            Divider()
            ForEach(SystemFonts.families, id: \.self) { fam in
                Button(fam) { family = fam }
            }
        } label: {
            Label(family ?? SystemFonts.defaultLabel, systemImage: "textformat")
                .lineLimit(1)
        }
        .menuStyle(.borderlessButton)
        .frame(minWidth: 160, maxWidth: 220, alignment: .leading)
        .fixedSize()
    }
}
