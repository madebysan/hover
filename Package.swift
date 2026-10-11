// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Hover",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Hover",
            path: "Sources/Hover",
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Info.plist"
                ])
            ]
        )
    ]
)
