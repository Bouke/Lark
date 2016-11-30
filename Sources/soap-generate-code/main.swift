import Foundation
import SchemaParser

let wsdlURL = CommandLine.arguments[1].hasPrefix("http") ? URL(string: CommandLine.arguments[1])! : URL(fileURLWithPath: CommandLine.arguments[1])
let wsdl = try XMLDocument(contentsOf: wsdlURL, options: 0)

print(try parse(WSDL: wsdl.rootElement()!))
