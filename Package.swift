import PackageDescription

let package = Package(
    name: "Lark",
    targets: [
        Target(name: "CodeGenerator", dependencies: ["SchemaParser"]),
        Target(name: "lark-generate-client", dependencies: ["SchemaParser", "CodeGenerator"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/Bouke/Evergreen.git", majorVersion: 0),
    ]
)
