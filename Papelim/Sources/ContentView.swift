import PapelimCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: SnippetStore

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            SnippetListView()
        } detail: {
            if let id = store.selectedId, let binding = store.binding(for: id) {
                SnippetEditorView(snippet: binding)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No snippet selected").font(.title3)
                    Text("Select a snippet or press ⌘N to create one.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $store.showingSettings) {
            SettingsView().environmentObject(store)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { store.createNew() }) {
                    Label("New", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { store.showingSettings = true }) {
                    Label("Locations", systemImage: "externaldrive.badge.icloud")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { Task { await store.loadAll() } }) {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}

// MARK: - Sidebar: All / Groups / Languages

struct SidebarView: View {
    @EnvironmentObject var store: SnippetStore

    var body: some View {
        List(selection: $store.sidebarSelection) {
            Section("Library") {
                Label("All Snippets", systemImage: "tray.full")
                    .tag(SidebarSelection.all)
            }
            let groups = SnippetFiltering.groups(in: store.snippets)
            if !groups.isEmpty {
                Section("Groups") {
                    ForEach(groups, id: \.self) { g in
                        Label(g, systemImage: "folder")
                            .tag(SidebarSelection.group(g))
                    }
                }
            }
            Section("Languages") {
                ForEach(Language.all) { lang in
                    Label(lang.display, systemImage: iconFor(lang.id))
                        .tag(SidebarSelection.language(lang.id))
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Papelim")
        .safeAreaInset(edge: .bottom) {
            if !store.lastSyncMessage.isEmpty {
                Text(store.lastSyncMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func iconFor(_ id: String) -> String {
        switch id {
        case "yaml", "github-actions", "json", "toml": return "doc.text"
        case "bash", "nushell", "justfile": return "terminal"
        case "markdown": return "text.alignleft"
        case "sql": return "cylinder"
        case "dockerfile": return "shippingbox"
        default: return "chevron.left.forwardslash.chevron.right"
        }
    }
}

// MARK: - Middle list

struct SnippetListView: View {
    @EnvironmentObject var store: SnippetStore

    var body: some View {
        List(selection: $store.selectedId) {
            ForEach(store.filtered) { snip in
                VStack(alignment: .leading, spacing: 2) {
                    Text(snip.title).font(.body).lineLimit(1)
                    HStack(spacing: 6) {
                        if let g = snip.group, !g.isEmpty {
                            Label(g, systemImage: "folder")
                                .font(.caption2)
                                .labelStyle(.titleAndIcon)
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        Text(Language.forId(snip.primaryLanguage).display)
                            .font(.caption2)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                        if snip.blocks.count > 1 {
                            Text("\(snip.blocks.count) blocks")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tag(Optional(snip.id))
                .contextMenu {
                    Button("Delete", role: .destructive) { store.delete(snip) }
                }
            }
        }
        .searchable(text: $store.searchText, placement: .sidebar, prompt: "Search snippets")
        .navigationTitle(store.listTitle)
    }
}

// MARK: - Editor: title, group, tags, multiple blocks

struct SnippetEditorView: View {
    @Binding var snippet: Snippet
    @EnvironmentObject var store: SnippetStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                TextField("Title", text: $snippet.title)
                    .textFieldStyle(.plain)
                    .font(.title2)
                HStack(spacing: 8) {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    GroupField(
                        value: $snippet.group,
                        candidates: SnippetFiltering.groups(in: store.snippets)
                    )

                    Image(systemName: "tag")
                        .foregroundStyle(.secondary)
                    TextField("tags, comma, separated",
                              text: Binding(
                                  get: { snippet.tags.joined(separator: ", ") },
                                  set: { snippet.tags = $0
                                      .split(separator: ",")
                                      .map { $0.trimmingCharacters(in: .whitespaces) }
                                      .filter { !$0.isEmpty }
                                  }
                              ))
                              .textFieldStyle(.roundedBorder)
                }
                .font(.caption)
            }
            .padding(12)
            Divider()

            // Blocks
            ScrollView {
                VStack(spacing: 12) {
                    ForEach($snippet.blocks) { $block in
                        BlockView(block: $block,
                                  canDelete: snippet.blocks.count > 1,
                                  onDelete: {
                                      snippet.blocks.removeAll { $0.id == block.id }
                                  })
                    }
                    Button {
                        snippet.blocks.append(SnippetBlock())
                    } label: {
                        Label("Add Block", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderless)
                    .padding(.vertical, 8)
                }
                .padding(12)
            }
        }
    }
}

struct BlockView: View {
    @Binding var block: SnippetBlock
    var canDelete: Bool
    var onDelete: () -> Void

    var body: some View {
        // In rendered markdown mode the whole block UI is replaced by a clean
        // preview. Double-click anywhere on it to return to edit mode.
        if block.wantsMarkdownPreview {
            renderedView
        } else {
            editView
        }
    }

    private var renderedView: some View {
        ScrollView {
            MarkdownRenderer(source: block.content, baseFontSize: block.effectiveFontSize)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
        }
        .frame(minHeight: 180)
        .background(Color(nsColor: .textBackgroundColor))
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Label("Rendered — double-click to edit", systemImage: "eye")
                .labelStyle(.titleAndIcon)
                .font(.caption2)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(6)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { block.renderMarkdown = false }
    }

    private var editView: some View {
        VStack(spacing: 0) {
            // Header: title, language, render-toggle (md only), delete
            HStack {
                TextField("Block title (optional)", text: $block.title)
                    .textFieldStyle(.plain)
                Spacer()
                if block.language == "markdown" {
                    Toggle(isOn: $block.renderMarkdown) {
                        Label("Render", systemImage: "eye")
                    }
                    .toggleStyle(.button)
                    .controlSize(.small)
                }
                Picker("", selection: $block.language) {
                    ForEach(Language.all) { lang in
                        Text(lang.display).tag(lang.id)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
                if canDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(8)

            // Formatting row (plaintext / markdown only)
            if block.wantsPlainTextEditor {
                Divider()
                HStack(spacing: 10) {
                    Image(systemName: "textformat.size")
                        .foregroundStyle(.secondary)
                    Stepper(
                        value: Binding(
                            get: { block.effectiveFontSize },
                            set: { block.fontSize = $0 }
                        ),
                        in: 10 ... 28,
                        step: 1
                    ) {
                        Text("\(Int(block.effectiveFontSize))pt").monospacedDigit()
                    }
                    .fixedSize()
                    FontPicker(family: $block.fontFamily)
                    Spacer()
                }
                .font(.caption)
                .padding(.horizontal, 8).padding(.vertical, 4)
            }

            Divider()
            bodyEditor
                .frame(minHeight: 180)
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var bodyEditor: some View {
        if block.wantsPlainTextEditor {
            PlainTextEditor(
                text: $block.content,
                fontSize: block.effectiveFontSize,
                fontFamily: block.fontFamily
            )
        } else {
            CodeEditor(text: $block.content, languageId: block.language)
        }
    }
}
