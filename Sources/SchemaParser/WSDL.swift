import Foundation

public struct Message {
    public struct Part {
        public let name: QualifiedName
        public let element: QualifiedName

        init(deserialize element: XMLElement) throws {
            self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
            self.element = try QualifiedName(type: element.attribute(forName: "element")!.stringValue!, inTree: element)
        }
    }

    public let name: QualifiedName
    public let parts: [Part]

    init(deserialize element: XMLElement) throws {
        self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
        self.parts = try element.elements(forLocalName: "part", uri: NS_WSDL).map(Part.init(deserialize:))
    }
}

public struct PortType {
    public struct Operation {
        public let name: QualifiedName
        public let documentation: String?
        public let inputMessage: QualifiedName
        public let outputMessage: QualifiedName

        init(deserialize element: XMLElement) throws {
            self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
            self.documentation = element.elements(forLocalName: "documentation", uri: NS_WSDL).first?.stringValue
            self.inputMessage = try QualifiedName(type: element.elements(forLocalName: "input", uri: NS_WSDL).first!.attribute(forName: "message")!.stringValue!, inTree: element)
            self.outputMessage = try QualifiedName(type: element.elements(forLocalName: "output", uri: NS_WSDL).first!.attribute(forName: "message")!.stringValue!, inTree: element)
        }
    }

    public let name: QualifiedName
    public let operations: [Operation]

    init(deserialize element: XMLElement) throws {
        self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
        self.operations = try element.elements(forLocalName: "operation", uri: NS_WSDL).map(Operation.init(deserialize:))
    }
}

public struct Binding {
    public struct Operation {
        public enum Style: String {
            case document
            case rpc
        }

        public enum Use: String {
            case literal
            case encoded
        }

        public let name: QualifiedName

        // soap specific info, might not always be present
        public let action: URL?
        public let style: Style

        // soap specific info, might not always be present
        public let input: Use
        public let output: Use

        init(deserialize element: XMLElement) throws {
            name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
            if let operation = element.elements(forLocalName: "operation", uri: NS_SOAP).first {
                action = URL(string: operation.attribute(forName: "soapAction")!.stringValue!)
                style = Style(rawValue: operation.attribute(forName: "style")!.stringValue!)!
            } else if let operation = element.elements(forLocalName: "operation", uri: NS_SOAP12).first {
                action = URL(string: operation.attribute(forName: "soapAction")!.stringValue!)
                style = Style(rawValue: operation.attribute(forName: "style")!.stringValue!)!
            } else {
                throw ParseError.unsupportedOperation
            }

            guard let input = element.elements(forLocalName: "input", uri: NS_WSDL).first else {
                throw ParseError.bindingOperationIncomplete
            }
            if let body = input.elements(forLocalName: "body", uri: NS_SOAP).first {
                self.input = Use(rawValue: body.attribute(forName: "use")!.stringValue!)!
            } else if let body = input.elements(forLocalName: "body", uri: NS_SOAP12).first {
                self.input = Use(rawValue: body.attribute(forName: "use")!.stringValue!)!
            } else {
                throw ParseError.bindingOperationIncomplete
            }

            guard let output = element.elements(forLocalName: "output", uri: NS_WSDL).first else {
                throw ParseError.bindingOperationIncomplete
            }
            if let body = output.elements(forLocalName: "body", uri: NS_SOAP).first {
                self.output = Use(rawValue: body.attribute(forName: "use")!.stringValue!)!
            } else if let body = output.elements(forLocalName: "body", uri: NS_SOAP12).first {
                self.output = Use(rawValue: body.attribute(forName: "use")!.stringValue!)!
            } else {
                throw ParseError.bindingOperationIncomplete
            }
        }
    }

    public let name: QualifiedName
    public let type: QualifiedName
    public let operations: [Operation]

    init(deserialize element: XMLElement) throws {
        self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
        self.type = try QualifiedName(type: element.attribute(forName: "type")!.stringValue!, inTree: element)
        self.operations = try element.elements(forLocalName: "operation", uri: NS_WSDL).map(Operation.init(deserialize:))
    }
}

public struct Service {
    public struct Port {
        public enum Address {
            case soap11(String)
            case soap12(String)
        }

        public let name: QualifiedName
        public let binding: QualifiedName
        public let address: Address

        init(deserialize element: XMLElement) throws {
            self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
            self.binding = try QualifiedName(type: element.attribute(forName: "binding")!.stringValue!, inTree: element)
            if let address = element.elements(forLocalName: "address", uri: NS_SOAP).first {
                self.address = .soap11(address.attribute(forName: "location")!.stringValue!)
            } else if let address = element.elements(forLocalName: "address", uri: NS_SOAP12).first {
                self.address = .soap12(address.attribute(forName: "location")!.stringValue!)
            } else {
                throw ParseError.unsupportedPortAddress
            }
        }
    }

    public let name: QualifiedName
    public let documentation: String?
    public let ports: [Port]

    init(deserialize element: XMLElement) throws {
        self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
        self.documentation = element.elements(forLocalName: "documentation", uri: NS_WSDL).first?.stringValue
        self.ports = try element.elements(forLocalName: "port", uri: NS_WSDL).map(Port.init(deserialize:))
    }
}

public struct WSDL {
    public let schema: XSD
    public let messages: [Message]
    public let portTypes: [PortType]
    public let bindings: [Binding]
    public let services: [Service]

    /// Deserialize a WSDL from an XMLElement
    ///
    /// - parameter deserialize: XML node to deserialize
    /// - parameter relativeTo: Used to resolve relative xsd schema imports
    ///
    /// - throws: `ParserError` and any upstream Cocoa error
    init(deserialize element: XMLElement, relativeTo url: URL?) throws {
        guard element.localName == "definitions" && element.uri == NS_WSDL else {
            throw ParseError.incorrectRootElement
        }

        var nodes: [XSD.Node] = []
        if let typesNode = element.elements(forLocalName: "types", uri: NS_WSDL).first, let schemaNode = typesNode.elements(forLocalName: "schema", uri: NS_XSD).first {
            var remainingImports: Set<URL> = []
            var seenSchemaURLs: Set<URL> = []
            for node in try XSD(deserialize: schemaNode) {
                switch node {
                case let .import(`import`):
                    let url = URL(string: `import`.schemaLocation, relativeTo: url)!
                    print(url)
                    if seenSchemaURLs.insert(url).inserted {
                        remainingImports.insert(url)
                    }
                default:
                    nodes.append(node)
                }
            }
            while let importUrl = remainingImports.popFirst() {
                let `import` = try parseXSD(contentsOf: importUrl)
                for node in `import` {
                    switch node {
                    case let .import(`import`):
                        let url = URL(string: `import`.schemaLocation, relativeTo: importUrl)!
                        print(url)
                        if seenSchemaURLs.insert(url).inserted {
                            remainingImports.insert(url)
                        }
                    default:
                        nodes.append(node)
                    }
                }
            }
        }
        self.schema = XSD(nodes: nodes)
        messages = try element.elements(forLocalName: "message", uri: NS_WSDL).map(Message.init(deserialize:))
        portTypes = try element.elements(forLocalName: "portType", uri: NS_WSDL).map(PortType.init(deserialize:))
        bindings = try element.elements(forLocalName: "binding", uri: NS_WSDL).map(Binding.init(deserialize:))
        services = try element.elements(forLocalName: "service", uri: NS_WSDL).map(Service.init(deserialize:))
    }
}
