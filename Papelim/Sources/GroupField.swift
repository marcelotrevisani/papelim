import SwiftUI
import PapelimCore

/// TextField with a popover-backed autocomplete list. Shows existing group
/// names that match the typed prefix/substring; clicking a suggestion fills
/// the binding.
struct GroupField: View {
    @Binding var value: String?
    var candidates: [String]

    @State private var draft: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        let matches = suggestions(for: draft)
        TextField("Group (optional)", text: $draft)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 200)
            .focused($focused)
            .onAppear { draft = value ?? "" }
            .onChange(of: value) { new in
                if !focused { draft = new ?? "" }
            }
            .onChange(of: draft) { new in
                value = new.isEmpty ? nil : new
            }
            .popover(isPresented: Binding(
                get: { focused && !matches.isEmpty },
                set: { if !$0 { focused = false } }
            ), arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(matches, id: \.self) { match in
                        Button {
                            draft = match
                            focused = false
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundStyle(.secondary)
                                Text(match)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(minWidth: 180)
                .padding(.vertical, 4)
            }
    }

    private func suggestions(for text: String) -> [String] {
        GroupAutocomplete.suggestions(for: text, candidates: candidates)
    }
}
