// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "QlypxDependencies",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "QlypxDependencies",
            targets: ["QlypxDependencies"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.6.0"),
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.52.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.0"),
        .package(url: "https://github.com/Clipy/Sauce.git", from: "2.4.0"),
        .package(url: "https://github.com/Clipy/Magnet.git", from: "3.5.0"),
        .package(url: "https://github.com/thii/SwiftHEXColors.git", from: "1.4.0"),
        .package(url: "https://github.com/pinterest/PINCache.git", from: "3.0.3"),
        .package(url: "https://github.com/Clipy/KeyHolder.git", from: "4.1.0"),
        .package(url: "https://github.com/tadija/AEXML.git", from: "4.6.1"),
        .package(url: "https://github.com/Clipy/Screeen.git", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "QlypxDependencies",
            dependencies: [
                "RxSwift",
                "RxCocoa",
                "RxRelay",
                "RealmSwift",
                "Sparkle",
                "Sauce",
                "Magnet",
                "SwiftHEXColors",
                "PINCache",
                "KeyHolder",
                "AEXML",
                "Screeen",
                "RxScreeen"
            ],
            path: "",
            exclude: ["Sources/QlypxDependencies/Placeholder.swift"]
        )
    ]
)
