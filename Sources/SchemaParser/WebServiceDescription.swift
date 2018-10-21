// swiftlint:disable nesting

import Foundation
import Lark

public struct Message {
    public struct Part {
        public let name: QualifiedName
        public let element: QualifiedName?
        public let type: QualifiedName?

        init(deserialize element: XMLElement) throws {
            self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
            self.element = try element.attribute(forName: "element")?.stringValue.flatMap({ try QualifiedName(type: $0, inTree: element) })
            self.type = try element.attribute(forName: "type")?.stringValue.flatMap({ try QualifiedName(type: $0, inTree: element) })
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
    public enum ParseError: Error, CustomStringConvertible {
        case unsupportedTransport(String)
        case noTransport
        case unsupportedOperation(QualifiedName)
        case bindingOperationMissingInput(QualifiedName)
        case bindingOperationMissingOutput(QualifiedName)
        case unsupportedBindingOperationEncoding(QualifiedName)
        case invalidOperationStyleForBindingOperation(QualifiedName)

        public var description: String {
            switch self {
            case let .unsupportedTransport(transport):
                return "Unsupported transport type '\(transport)', must be '\(SOAP_HTTP)'"
            case .noTransport:
                return "No transport type, must be: '\(SOAP_HTTP)'"
            case let .unsupportedOperation(operation):
                return "binding operation '\(operation)' is invalid. The operation must be either (\(NS_SOAP))operation or (\(NS_SOAP12))operation."
            case let .bindingOperationMissingInput(operation):
                return "binding operation '\(operation)' contains an operation without an input."
            case let .bindingOperationMissingOutput(operation):
                return "binding operation '\(operation)' contains an operation without an output."
            case let .unsupportedBindingOperationEncoding(operation):
                return "binding operation '\(operation)' contains a message with unsupported encoding."
            case let .invalidOperationStyleForBindingOperation(operation):
                return "binding operation '\(operation)' has an invalid operation style."
            }
        }
    }

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
                guard let style = operation.attribute(forName: "style")?.stringValue.flatMap({ Style(rawValue: $0) }) else {
                    throw ParseError.invalidOperationStyleForBindingOperation(name)
                }
                self.style = style
            } else if let operation = element.elements(forLocalName: "operation", uri: NS_SOAP12).first {
                action = URL(string: operation.attribute(forName: "soapAction")!.stringValue!)
                guard let style = operation.attribute(forName: "style")?.stringValue.flatMap({ Style(rawValue: $0) }) else {
                    throw ParseError.invalidOperationStyleForBindingOperation(name)
                }
                self.style = style
            } else {
                throw ParseError.unsupportedOperation(name)
            }

            let use = { (element: XMLElement) -> Use? in
                if let body = element.elements(forLocalName: "body", uri: NS_SOAP).first {
                    guard let use = body.attribute(forName: "use")?.stringValue.flatMap({ Use(rawValue: $0) }) else {
                        return nil
                    }
                    return use
                } else if let body = element.elements(forLocalName: "body", uri: NS_SOAP12).first {
                    guard let use = body.attribute(forName: "use")?.stringValue.flatMap({ Use(rawValue: $0) }) else {
                        return nil
                    }
                    return use
                } else {
                    return nil
                }
            }

            guard let input = element.elements(forLocalName: "input", uri: NS_WSDL).first else {
                throw ParseError.bindingOperationMissingInput(name)
            }
            guard let inputUse = use(input) else {
                throw ParseError.unsupportedBindingOperationEncoding(name)
            }
            self.input = inputUse

            guard let output = element.elements(forLocalName: "output", uri: NS_WSDL).first else {
                throw ParseError.bindingOperationMissingOutput(name)
            }
            guard let outputUse = use(output) else {
                throw ParseError.unsupportedBindingOperationEncoding(name)
            }
            self.output = outputUse
        }
    }

    public let name: QualifiedName
    public let type: QualifiedName
    public let operations: [Operation]

    init(deserialize element: XMLElement) throws {
        if let transport = element.elements(forLocalName: "binding", uri: NS_SOAP).first?.attribute(forName: "transport")?.stringValue {
            guard transport == SOAP_HTTP else {
                throw ParseError.unsupportedTransport(transport)
            }
        } else if let transport = element.elements(forLocalName: "binding", uri: NS_SOAP12).first?.attribute(forName: "transport")?.stringValue {
            guard transport == SOAP_HTTP else {
                throw ParseError.unsupportedTransport(transport)
            }
        } else {
            throw ParseError.noTransport
        }

        self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
        self.type = try QualifiedName(type: element.attribute(forName: "type")!.stringValue!, inTree: element)
        self.operations = try element.elements(forLocalName: "operation", uri: NS_WSDL).compactMap {
            do {
                return try Operation.init(deserialize: $0)
            } catch ParseError.unsupportedOperation {
                return nil
            }
        }
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
                throw WebServiceDescriptionParseError.unsupportedPortAddress(name)
            }
        }
    }

    public let name: QualifiedName
    public let documentation: String?
    public let ports: [Port]

    init(deserialize element: XMLElement) throws {
        self.name = QualifiedName(uri: try targetNamespace(ofNode: element), localName: element.attribute(forName: "name")!.stringValue!)
        self.documentation = element.elements(forLocalName: "documentation", uri: NS_WSDL).first?.stringValue
        self.ports = try element.elements(forLocalName: "port", uri: NS_WSDL).compactMap {
            do {
                return try Port.init(deserialize: $0)
            } catch WebServiceDescriptionParseError.unsupportedPortAddress {
                return nil
            }
        }
    }
}

public struct WebServiceDescription {
    internal let imports: [(namespace: URL, location: URL)]
    public let schema: Schema
    public let messages: [Message]
    public let portTypes: [PortType]
    public let bindings: [Binding]
    public let services: [Service]

    internal init(schema: Schema, messages: [Message], portTypes: [PortType], bindings: [Binding], services: [Service]) {
        self.imports = []
        self.schema = schema
        self.messages = messages
        self.portTypes = portTypes
        self.bindings = bindings
        self.services = services
    }

    /// Deserialize a WebServiceDescription from an XMLElement
    ///
    /// - parameter deserialize: XML node to deserialize
    /// - parameter relativeTo: Used to resolve relative xsd schema imports
    ///
    /// - throws: `ParserError` and any upstream Cocoa error
    init(deserialize element: XMLElement, relativeTo url: URL?) throws {
        guard element.localName == "definitions" && element.uri == NS_WSDL else {
            throw WebServiceDescriptionParseError.incorrectRootElement
        }

        imports = try element.elements(forLocalName: "import", uri: NS_WSDL).map {
            guard let namespace = $0.attribute(forName: "namespace")?.stringValue.flatMap({ URL(string: $0) }) else {
                throw WebServiceDescriptionParseError.unsupportedImport
            }
            guard let location = $0.attribute(forName: "location")?.stringValue.flatMap({ URL(string: $0, relativeTo: url) }) else {
                throw WebServiceDescriptionParseError.unsupportedImport
            }
            return (namespace, location)
        }

        var nodes: [Schema.Node] = []
        if let typesNode = element.elements(forLocalName: "types", uri: NS_WSDL).first {
            var remainingImports: Set<URL> = []
            var seenSchemaURLs: Set<URL> = []
            var requiredNamespaces: Set<String> = []
            var importedNamespaces: Set<String> = []

            func append(xsd: Schema, relativeTo url: URL?) {
                for node in xsd {
                    switch node {
                    case let .import(`import`):
                        requiredNamespaces.insert(`import`.namespace)

                        if let schemaLocation = `import`.schemaLocation {
                            let url = URL(string: schemaLocation, relativeTo: url)!
                            if seenSchemaURLs.insert(url).inserted {
                                remainingImports.insert(url)
                            }
                        }
                    default:
                        nodes.append(node)
                    }
                }
            }

            // Parse all schemas inside the WSDL.
            for schemaNode in typesNode.elements(forLocalName: "schema", uri: NS_XS) {
                let schema = try Schema(deserialize: schemaNode)
                guard let tns = schema.targetNamespace else {
                    throw WebServiceDescriptionParseError.schemaWithoutTargetNamespace
                }
                importedNamespaces.insert(tns)
                append(xsd: schema, relativeTo: url)
            }

            // Download and parse all imported schemas.
            while let importUrl = remainingImports.popFirst() {
                let schema = try parseSchema(contentsOf: importUrl)
                guard let tns = schema.targetNamespace else {
                    throw WebServiceDescriptionParseError.schemaWithoutTargetNamespace
                }
                importedNamespaces.insert(tns)
                append(xsd: schema, relativeTo: importUrl)
            }

            // Verify that we've got all imported schemas.
            if !requiredNamespaces.isSubset(of: importedNamespaces) {
                throw WebServiceDescriptionParseError.missingImportedNamespaces(requiredNamespaces.subtracting(importedNamespaces))
            }
        }
        self.schema = Schema(nodes: nodes)
        messages = try element.elements(forLocalName: "message", uri: NS_WSDL).map(Message.init(deserialize:))
        portTypes = try element.elements(forLocalName: "portType", uri: NS_WSDL).map(PortType.init(deserialize:))
        bindings = try element.elements(forLocalName: "binding", uri: NS_WSDL).compactMap {
            do {
                return try Binding.init(deserialize: $0)
            } catch Binding.ParseError.noTransport {
                return nil
            } catch let error as Binding.ParseError {
                throw WebServiceDescriptionParseError.bindingParseError(error)
            }
        }
        services = try element.elements(forLocalName: "service", uri: NS_WSDL).map(Service.init(deserialize:))
    }
}

fileprivate func targetNamespace(ofNode node: XMLElement) throws -> String {
    guard let tns = node.targetNamespace else {
        throw WebServiceDescriptionParseError.nodeWithoutTargetNamespace
    }
    return tns
}

public enum WebServiceDescriptionParseError: Error {
    case unsupportedImport
    case incorrectRootElement
    case unsupportedPortAddress(QualifiedName)
    case nodeWithoutTargetNamespace
    case schemaWithoutTargetNamespace
    case missingImportedNamespaces(Set<String>)
    case bindingParseError(Binding.ParseError)
}

extension WebServiceDescriptionParseError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unsupportedImport:
            return "incorrect definition import. It should contain both namespace and location attributes."
        case .incorrectRootElement:
            return "incorrect root element. The root element of the WSDL should be (\(NS_WSDL))definitions."
        case let .unsupportedPortAddress(port):
            return "port address of port '\(port)' is unsupported. The port address must be either (\(NS_SOAP))address or (\(NS_SOAP12))address."
        case .nodeWithoutTargetNamespace:
            return "schema node must have a target namespace."
        case .schemaWithoutTargetNamespace:
            return "schema must have a target namespace."
        case let .missingImportedNamespaces(namespaces):
            return "some namespaces were required, but have not been imported: \(namespaces)."
        case let .bindingParseError(error):
            return "a binding could not be parsed, the underlying error: \(error)"
        }
    }
}
