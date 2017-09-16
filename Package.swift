// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Lark",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.5.0")
    ],
    targets: [
        .target(name: "Lark", dependencies: ["Alamofire"]),
        .target(name: "CodeGenerator", dependencies: ["Lark", "SchemaParser"]),
        .target(name: "SchemaParser", dependencies: ["Lark"]),
        .target(name: "lark-generate-client", dependencies: ["SchemaParser", "CodeGenerator"]),
        .testTarget(name: "CodeGeneratorTests", dependencies: ["CodeGenerator"]),
        .testTarget(name: "LarkTests", dependencies: ["Lark"]),
        .testTarget(name: "SchemaParserTests", dependencies: ["SchemaParser"]),
    ],
    swiftLanguageVersions: [4]
)
