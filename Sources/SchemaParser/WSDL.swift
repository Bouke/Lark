import Foundation
import Lark

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
                throw WSDLParseError.unsupportedOperation(name)
            }

            guard let input = element.elements(forLocalName: "input", uri: NS_WSDL).first else {
                throw WSDLParseError.bindingOperationMissingInput(name)
            }
            if let body = input.elements(forLocalName: "body", uri: NS_SOAP).first {
                self.input = Use(rawValue: body.attribute(forName: "use")!.stringValue!)!
            } else if let body = input.elements(forLocalName: "body", uri: NS_SOAP12).first {
                self.input = Use(rawValue: body.attribute(forName: "use")!.stringValue!)!
            } else {
                throw WSDLParseError.unsupportedBindingOperationEncoding(name)
            }

            guard let output = element.elements(forLocalName: "output", uri: NS_WSDL).first else {
                throw WSDLParseError.bindingOperationMissingOutput(name)
            }
            if let body = output.elements(forLocalName: "body", uri: NS_SOAP).first {
                self.output = Use(rawValue: body.attribute(forName: "use")!.stringValue!)!
            } else if let body = output.elements(forLocalName: "body", uri: NS_SOAP12).first {
                self.output = Use(rawValue: body.attribute(forName: "use")!.stringValue!)!
            } else {
                throw WSDLParseError.unsupportedBindingOperationEncoding(name)
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
                throw WSDLParseError.unsupportedPortAddress(name)
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
            throw WSDLParseError.incorrectRootElement
        }

        var nodes: [XSD.Node] = []
        if let typesNode = element.elements(forLocalName: "types", uri: NS_WSDL).first, let schemaNode = typesNode.elements(forLocalName: "schema", uri: NS_XSD).first {
            var remainingImports: Set<URL> = []
            var seenSchemaURLs: Set<URL> = []

            func append(xsd: XSD, relativeTo url: URL?) {
                for node in xsd {
                    switch node {
                    case let .import(`import`):
                        let url = URL(string: `import`.schemaLocation, relativeTo: url)!
                        if seenSchemaURLs.insert(url).inserted {
                            remainingImports.insert(url)
                        }
                    default:
                        nodes.append(node)
                    }
                }
            }
            append(xsd: try XSD(deserialize: schemaNode), relativeTo: url)
            while let importUrl = remainingImports.popFirst() {
                append(xsd: try parseXSD(contentsOf: importUrl), relativeTo: importUrl)
            }
        }
        self.schema = XSD(nodes: nodes)
        messages = try element.elements(forLocalName: "message", uri: NS_WSDL).map(Message.init(deserialize:))
        portTypes = try element.elements(forLocalName: "portType", uri: NS_WSDL).map(PortType.init(deserialize:))
        bindings = try element.elements(forLocalName: "binding", uri: NS_WSDL).map(Binding.init(deserialize:))
        services = try element.elements(forLocalName: "service", uri: NS_WSDL).map(Service.init(deserialize:))
    }
}

fileprivate func targetNamespace(ofNode node: XMLElement) throws -> String {
    guard let tns = node.targetNamespace else {
        throw WSDLParseError.nodeWithoutTargetNamespace
    }
    return tns
}

public enum WSDLParseError: Error {
    case incorrectRootElement
    case unsupportedPortAddress(QualifiedName)
    case unsupportedOperation(QualifiedName)
    case bindingOperationMissingInput(QualifiedName)
    case bindingOperationMissingOutput(QualifiedName)
    case unsupportedBindingOperationEncoding(QualifiedName)
    case nodeWithoutTargetNamespace
}

extension WSDLParseError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .incorrectRootElement:
            return "incorrect root element. The root element of the WSDL should be (\(NS_WSDL))definitions."
        case let .unsupportedPortAddress(port):
            return "port address of port '\(port)' is unsupported. The port address must be either (\(NS_SOAP))address or (\(NS_SOAP12))address."
        case let .unsupportedOperation(operation):
            return "binding operation '\(operation)' is invalid. The operation must be either (\(NS_SOAP))operation or (\(NS_SOAP12))operation."
        case let .bindingOperationMissingInput(operation):
            return "binding operation '\(operation)' contains an operation without an input."
        case let .bindingOperationMissingOutput(operation):
            return "binding operation '\(operation)' contains an operation without an output."
        case let .unsupportedBindingOperationEncoding(operation):
            return "binding operation '\(operation)' contains a message with unsupported encoding."
        case .nodeWithoutTargetNamespace:
            return "XSD node must have a target namespace."
        }
    }
}

