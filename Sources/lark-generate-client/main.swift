import Foundation
import SchemaParser
import CodeGenerator

let wsdlURL = CommandLine.arguments[1].hasPrefix("http") ? URL(string: CommandLine.arguments[1])! : URL(fileURLWithPath: CommandLine.arguments[1])
let wsdlXml = try XMLDocument(contentsOf: wsdlURL, options: 0)

let wsdl = try parse(WSDL: wsdlXml.rootElement()!)

guard let service = wsdl.services.first else {
    print("Error: could not find service in WSDL")
    exit(1)
}

try print(generate(wsdl: wsdl, service: service))
