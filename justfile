# Build in debug mode
debug:
    swift build

# Build in release mode
release:
    swift build -c release

# Run the app bundle (GUI apps need a real .app bundle to receive key events)
run:
    ./scripts/build-app.sh debug
    open build/Papelim.app

# Run all tests
test:
    swift test

# Format Swift source files
format:
    swiftformat .

# Build Papelim.app bundle (default: release)
app config="release":
    ./scripts/build-app.sh {{ config }}

# Build DMG installer (default version: dev)
dmg version="dev":
    ./scripts/build-dmg.sh {{ version }}

# Clean build artifacts
clean:
    rm -rf .build build
