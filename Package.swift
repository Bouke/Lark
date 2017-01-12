import PackageDescription

let package = Package(
    name: "Lark",
    targets: [
        Target(name: "CodeGenerator", dependencies: ["LarkRuntime", "SchemaParser"]),
        Target(name: "SchemaParser", dependencies: ["LarkRuntime"]),
        Target(name: "lark-generate-client", dependencies: ["SchemaParser", "CodeGenerator"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Bouke/Evergreen.git", majorVersion: 0),
        .Package(url: "https://github.com/Alamofire/Alamofire.git", majorVersion: 4),
    ]
)
