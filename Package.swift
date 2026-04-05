// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Papelim",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/raspu/Highlightr", from: "2.1.2"),
    ],
    targets: [
        .target(
            name: "PapelimCore",
            dependencies: [],
            path: "PapelimCore/Sources"
        ),
        .executableTarget(
            name: "Papelim",
            dependencies: [
                "PapelimCore",
                "Highlightr",
            ],
            path: "Papelim/Sources",
            resources: [
                .process("../Resources"),
            ]
        ),
        .testTarget(
            name: "PapelimTests",
            dependencies: ["PapelimCore"],
            path: "PapelimTests"
        ),
    ]
)
