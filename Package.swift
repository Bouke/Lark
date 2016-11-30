import PackageDescription

let package = Package(
    name: "SOAP",
    targets: [
        Target(name: "soap-generate-code", dependencies: ["SchemaParser"]),
    ]
)
