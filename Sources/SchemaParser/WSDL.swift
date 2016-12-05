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
        public let name: QualifiedName

        init(deserialize element: XMLElement) throws {
            self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
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
            case soap(String)
            case soap12(String)
        }

        public let name: QualifiedName
        public let binding: QualifiedName
        public let address: Address

        init(deserialize element: XMLElement) throws {
            self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
            self.binding = try QualifiedName(type: element.attribute(forName: "binding")!.stringValue!, inTree: element)
            if let address = element.elements(forLocalName: "address", uri: NS_SOAP).first {
                self.address = .soap(address.attribute(forName: "location")!.stringValue!)
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
    public let schema: [XSD.Node]
    public let messages: [Message]
    public let portTypes: [PortType]
    public let bindings: [Binding]
    public let services: [Service]

    init(deserialize element: XMLElement) throws {
        var schema: [XSD.Node] = []
        if let typesNode = element.elements(forLocalName: "types", uri: NS_WSDL).first {
            var remainingSchemaNodes = typesNode.elements(forLocalName: "schema", uri: NS_XSD)
            var seenSchemaURLs = Set<URL>()
            while let schemaNode = remainingSchemaNodes.popLast() {
                for node in try XSD(deserialize: schemaNode).nodes {
                    switch node {
                    case let .import(`import`):
                        let url = URL(string: `import`.schemaLocation)!
                        if seenSchemaURLs.insert(url).inserted {
                            remainingSchemaNodes.append(try XMLDocument(contentsOf: url, options: 0).rootElement()!)
                        }
                    default:
                        schema.append(node)
                    }
                }
            }
        }
        self.schema = schema
        messages = try element.elements(forLocalName: "message", uri: NS_WSDL).map(Message.init(deserialize:))
        portTypes = try element.elements(forLocalName: "portType", uri: NS_WSDL).map(PortType.init(deserialize:))
        bindings = try element.elements(forLocalName: "binding", uri: NS_WSDL).map(Binding.init(deserialize:))
        services = try element.elements(forLocalName: "service", uri: NS_WSDL).map(Service.init(deserialize:))
    }
}
