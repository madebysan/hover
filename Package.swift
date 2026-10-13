// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Hover",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.10.0")
    ],
    targets: [
        .executableTarget(
            name: "Hover",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Hover",
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Info.plist",
                    // Sparkle.framework is embedded in Contents/Frameworks by scripts/build-dmg.sh.
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks"
                ])
            ]
        )
    ]
)
