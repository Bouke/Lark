// swift-tools-version:3.1
import PackageDescription

let package = Package(
    name: "Lark",
    targets: [
        Target(name: "CodeGenerator", dependencies: ["Lark", "SchemaParser"]),
        Target(name: "SchemaParser", dependencies: ["Lark"]),
        Target(name: "lark-generate-client", dependencies: ["SchemaParser", "CodeGenerator"])
    ],
    dependencies: [
        .Package(url: "https://github.com/Alamofire/Alamofire.git", majorVersion: 4)
    ],
    swiftLanguageVersions: [3, 4]
)
