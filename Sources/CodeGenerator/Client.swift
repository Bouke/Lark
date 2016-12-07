import SchemaParser

extension Service {
    func toSwift(wsdl: WSDL) -> SwiftClass {
        // SOAP 1.1 port
        let port = ports.first { if case .soap = $0.address { return true } else { return false } }!
        let binding = wsdl.bindings.first { $0.name == port.binding }!
        let portType = wsdl.portTypes.first { $0.name == binding.type }!

        let name = "\(self.name.localName.toSwiftTypeName())Client"

        for operation in portType.operations {
        }
        let members = portType.operations.map { operation -> ServiceMethod in
            let input = wsdl.messages.first { $0.name == operation.inputMessage }!
            let output = wsdl.messages.first { $0.name == operation.outputMessage }!
            return ServiceMethod(operation: operation, input: input, output: output)
        }

        return SwiftClass(name: name, members: members)
    }
}

struct ServiceMethod {
    let name: String
    let input: Message
    let output: Message

    init(operation: PortType.Operation, input: Message, output: Message) {
        name = operation.name.localName.toSwiftPropertyName()
        self.input = input
        self.output = output
    }
}

extension ServiceMethod: LinesOfCodeConvertible {
    func toLinesOfCode(at indentation: Indentation) -> [LineOfCode] {
        return indentation.apply(
            toFirstLine: "func \(name)(\(parameterList)) throws {",
            nestedLines:     linesOfCodeForBody(at:),
            andLastLine: "}")
    }

    private func linesOfCodeForBody(at indentation: Indentation) -> [LineOfCode] {
        return [indentation.apply(toLineOfCode: "let parameters = [XMLElement]()")]
            + linesOfCodeForParameters(at: indentation)
            + linesOfCodeForSend(at: indentation)
    }

    private func linesOfCodeForParameters(at indentation: Indentation) -> [LineOfCode] {
        return input.parts.flatMap(linesOfCodeForParameter(part:)).map(indentation.apply(toLineOfCode:))
    }

    private func linesOfCodeForParameter(part: Message.Part) -> [LineOfCode] {
        let property = part.name.localName.toSwiftPropertyName()
        return [
            "let \(property)Node = XMLElement(prefix: \"ns0\", localName: \"\(part.name.localName)\", uri: \"\(part.name.uri)\")",
            "\(property)Node.addNamespace(XMLNode.namespace(withName: \"ns0\", stringValue: \"\(part.name.uri)\") as! XMLNode)",
            "try \(property).serialize(\(property)Node)",
            "parameters.append(\(property)Node)"
        ]
    }

    func linesOfCodeForSend(at indentation: Indentation) -> [LineOfCode] {
        return [
            "try send(parameters: parameters, output: { body in",
            "    let outputNode = body.elements(forLocalName: \"\(output.name.localName)\", uri: \"\(output.name.uri)\").first!",
            "    output(try \(output.name.localName.toSwiftTypeName())(deserialize: outputNode))",
            "})"
        ].map(indentation.apply(toLineOfCode:))
    }

    private var parameterList: String {
        return parameters.map { $0.toSwiftCode() }.joined(separator: ", ")
    }

    var parameters: [SwiftParameter] {
        return input.parts.map {
                SwiftParameter(name: $0.name.localName.toSwiftPropertyName(), type: .identifier($0.element.localName.toSwiftTypeName()))
            }
            + [SwiftParameter(name: "output", type: .identifier("() -> ()"))]
    }
}


//        print("    func \(operation.name.localName)(input: \(inputType.signature), output: (\(outputType.signature)) -> ()) throws {")
//        print("        let parameter = XMLElement(prefix: \"ns0\", localName: \"\(input.name.localName)\", uri: \"\(input.name.uri)\")")
//        print("        parameter.addNamespace(XMLNode.namespace(withName: \"ns0\", stringValue: \"\(input.name.uri)\") as! XMLNode)")
//        print("        try input.serialize(parameter)")
//        print("        try send(parameters: [parameter], output: { body in")
//        print("            let element = body.elements(forLocalName: \"\(output.name.localName)\", uri: \"\(output.name.uri)\").first!")
//        print("            output(try \(outputType.signature)(deserialize: element))")
//        print("        })")
