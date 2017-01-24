import Foundation
import SchemaParser
import CodeGenerator

var standardError = FileHandle.standardError

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}

func printUsage() {
    print("usage: lark-generate-client WSDL", to: &standardError)
}

if CommandLine.arguments.contains("-h") || CommandLine.arguments.contains("--help") {
    print("Generate code for types and client from WSDL", to: &standardError)
    printUsage()
    exit(1)
}

if CommandLine.arguments.count != 2 {
    print("error: need the location of the WSDL as a single argument", to: &standardError)
    printUsage()
    exit(1)
}

let wsdl: WSDL
do {
    let wsdlURL = CommandLine.arguments[1].hasPrefix("http") ? URL(string: CommandLine.arguments[1])! : URL(fileURLWithPath: CommandLine.arguments[1])
    wsdl = try parseWSDL(contentsOf: wsdlURL)
} catch {
    print("error when parsing WSDL: \(error)", to: &standardError)
    exit(1)
}

guard let service = wsdl.services.first else {
    print("error: could not find service in WSDL", to: &standardError)
    exit(1)
}

do {
    try print(generate(wsdl: wsdl, service: service))
} catch {
    print("error when generating code: \(error)", to: &standardError)
    exit(1)
}
