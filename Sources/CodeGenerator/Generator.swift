import SchemaParser

typealias Writer = (String) -> ()

public func generateClientForBinding(_ print: Writer, wsdl: WSDL, service: Service, binding: Binding) {
    let port = wsdl.portTypes.first(where: { $0.name == binding.type })!

    print("class \(service.name.localName)Client {")

    for operation in binding.operations {
        let operation2 = port.operations.first(where: { $0.name == operation.name })!
        let input = wsdl.messages.first(where: { $0.name == operation2.inputMessage })!
        let output = wsdl.messages.first(where: { $0.name == operation2.outputMessage })!

        let inputType = wsdl.schemas.flatMap { $0.first { $0.name == input.part.element } }.first!
        let outputType = wsdl.schemas.flatMap { $0.first { $0.name == output.part.element } }.first!

        print("    func \(operation.name.localName)(input: \(inputType.name.localName)) -> \(outputType.name.localName) {")
        print("    }")
    }

    print("}")
}

