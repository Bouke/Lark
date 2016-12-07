import Foundation
import SchemaParser
import CodeGenerator

let wsdlURL = CommandLine.arguments[1].hasPrefix("http") ? URL(string: CommandLine.arguments[1])! : URL(fileURLWithPath: CommandLine.arguments[1])
let wsdlXml = try XMLDocument(contentsOf: wsdlURL, options: 0)

let wsdl = try parse(WSDL: wsdlXml.rootElement()!)
//print(wsdl)

try print(generate(wsdl: wsdl, service: wsdl.services.first!, binding: wsdl.bindings.first!))
