import AppKit
import PapelimCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: SnippetStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Storage Locations").font(.title2).bold()
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            Text("Snippets are saved to every enabled location. Reads merge all locations (newest wins per snippet).")
                .font(.callout)
                .foregroundStyle(.secondary)

            List {
                ForEach(store.locations) { loc in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { loc.enabled },
                            set: { _ in store.toggleLocation(loc) }
                        )).labelsHidden()
                        VStack(alignment: .leading) {
                            Text(loc.name).font(.body)
                            Text(loc.rawPath).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                        }
                        Spacer()
                        Button(role: .destructive) { store.removeLocation(loc) } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(minHeight: 180)

            HStack {
                Button {
                    pickFolder()
                } label: {
                    Label("Add Folder…", systemImage: "folder.badge.plus")
                }
                Spacer()
                Button("Reload") {
                    Task { await store.loadAll() }
                }
            }
        }
        .padding(20)
        .frame(width: 560)
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Pick a folder (e.g. inside iCloud Drive or Google Drive)"
        if panel.runModal() == .OK, let url = panel.url {
            let name = guessName(for: url)
            store.addLocation(StorageLocation(name: name, rawPath: url.path))
        }
    }

    private func guessName(for url: URL) -> String {
        let p = url.path
        if p.contains("com~apple~CloudDocs") {
            return "iCloud Drive"
        }
        if p.contains("GoogleDrive") || p.contains("Google Drive") {
            return "Google Drive"
        }
        if p.contains("Dropbox") {
            return "Dropbox"
        }
        if p.contains("OneDrive") {
            return "OneDrive"
        }
        return url.lastPathComponent
    }
}
