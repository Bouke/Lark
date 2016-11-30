import PackageDescription

let package = Package(
    name: "SOAP",
    targets: [
        Target(name: "CodeGenerator", dependencies: ["SchemaParser"]),
        Target(name: "soap-generate-code", dependencies: ["SchemaParser", "CodeGenerator"]),
    ]
)
