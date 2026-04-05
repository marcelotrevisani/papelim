# Papelim

A native macOS code snippet manager with syntax highlighting and multi-location
cloud sync (iCloud Drive, Google Drive, Dropbox, local folders — any combination
you want).

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Multi-block snippets** — each snippet can hold multiple code blocks, each
  with its own language. Great for workflows like "bash command + YAML it
  produces" or "Rust source + cargo invocation" in one place.
- **Groups** — organize snippets into free-form groups (work, personal, ansible…).
- **Multi-location sync** — configure several storage folders; writes fan out to
  all of them, reads merge (newest-wins per snippet id). Your cloud provider of
  choice (or several at once) handles the actual sync.
- **Syntax highlighting** via Highlightr (highlight.js) — 180+ languages.
- **Fast search** across titles, tags, groups, and block contents.

## Supported languages

Plain text, Bash, Nushell, Justfile, Python, Rust, C, C++, JavaScript,
TypeScript, Groovy, YAML, GitHub Actions, JSON, TOML, Markdown, SQL, Go, Swift,
Ruby, Dockerfile.

## How storage works

You add any number of folders in **Settings → Storage Locations**. Suggested
locations are auto-detected on first run:

- `~/Library/Mobile Documents/com~apple~CloudDocs/Papelim` (iCloud Drive)
- `~/Library/CloudStorage/GoogleDrive-*/My Drive/Papelim` (Google Drive Desktop)
- `~/Documents/Papelim` (local)

Each snippet is stored as a single `.json` file named by its UUID. Cloud
providers sync these folders; Papelim just reads and writes the files.

## Development

```bash
# Build
swift build

# Run
swift run Papelim

# Test
swift test

# Build .app bundle
./scripts/build-app.sh release

# Build DMG
./scripts/build-dmg.sh v0.1.0
```

## Releasing

1. Push a git tag like `v0.1.0`.
2. Create a GitHub release with that tag.
3. The `release.yml` workflow builds, tests, uploads the DMG, and updates the
   `marcelotrevisani/homebrew-tap` cask formula automatically.

Install via Homebrew:

```bash
brew install --cask marcelotrevisani/tap/papelim
```

## License

MIT
