import Foundation
import SchemaParser
import CodeGenerator

let wsdlURL = CommandLine.arguments[1].hasPrefix("http") ? URL(string: CommandLine.arguments[1])! : URL(fileURLWithPath: CommandLine.arguments[1])
let wsdl = try parseWSDL(contentsOf: wsdlURL)

guard let service = wsdl.services.first else {
    print("Error: could not find service in WSDL")
    exit(1)
}

try print(generate(wsdl: wsdl, service: service))
