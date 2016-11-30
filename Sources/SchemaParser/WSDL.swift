import Foundation

struct Message {
    let name: String
    let part: Part

    init(deserialize element: XMLElement) {
        self.name = element.attribute(forName: "name")!.stringValue!
        self.part = Part(deserialize: element.elements(forLocalName: "part", uri: NS_WSDL).first!)
    }

    struct Part {
        let name: String
        let element: String

        init(deserialize element: XMLElement) {
            self.name = element.attribute(forName: "name")!.stringValue!
            self.element = element.attribute(forName: "element")!.stringValue!
        }
    }
}

struct PortType {
    struct Operation {
        let name: String
        let inputMessage: String
        let outputMessage: String

        init(deserialize element: XMLElement) {
            self.name = element.attribute(forName: "name")!.stringValue!
            self.inputMessage = element.elements(forLocalName: "input", uri: NS_WSDL).first!.attribute(forName: "message")!.stringValue!
            self.outputMessage = element.elements(forLocalName: "output", uri: NS_WSDL).first!.attribute(forName: "message")!.stringValue!
        }
    }

    let name: String
    let operations: [Operation]

    init(deserialize element: XMLElement) {
        self.name = element.attribute(forName: "name")!.stringValue!
        self.operations = element.elements(forLocalName: "operation", uri: NS_WSDL).map(Operation.init(deserialize:))
    }
}

struct Binding {
    struct Operation {
        let name: String

        init(deserialize element: XMLElement) {
            self.name = element.attribute(forName: "name")!.stringValue!
        }
    }

    let name: String
    let operations: [Operation]

    init(deserialize element: XMLElement) {
        self.name = element.attribute(forName: "name")!.stringValue!
        self.operations = element.elements(forLocalName: "operation", uri: NS_WSDL).map(Operation.init(deserialize:))
    }
}

struct Service {
    struct Port {
        enum Address {
            case soap(String)
            case soap12(String)
        }

        let name: String
        let binding: String
        let address: Address

        init(deserialize element: XMLElement) throws {
            self.name = element.attribute(forName: "name")!.stringValue!
            self.binding = element.attribute(forName: "binding")!.stringValue!
            if let address = element.elements(forLocalName: "address", uri: NS_SOAP).first {
                self.address = .soap(address.attribute(forName: "location")!.stringValue!)
            } else if let address = element.elements(forLocalName: "address", uri: NS_SOAP12).first {
                self.address = .soap12(address.attribute(forName: "location")!.stringValue!)
            } else {
                throw ParseError.unsupportedPortAddress
            }
        }
    }

    let name: String
    let ports: [Port]

    init(deserialize element: XMLElement) throws {
        self.name = element.attribute(forName: "name")!.stringValue!
        self.ports = try element.elements(forLocalName: "port", uri: NS_WSDL).map(Port.init(deserialize:))
    }
}

public struct WSDL {
    let schemas: [XSD]
    let messages: [Message]
    let portTypes: [PortType]
    let bindings: [Binding]
    let services: [Service]

    init(deserialize element: XMLElement) throws {
        guard let schema = element
            .elements(forLocalName: "types", uri: NS_WSDL)
            .first?
            .elements(forLocalName: "schema", uri: NS_XSD)
            .first else {
                throw ParseError.schemaNotFound
        }
        schemas = [try parse(XSD: schema)]
        messages = element.elements(forLocalName: "message", uri: NS_WSDL).map(Message.init(deserialize:))
        portTypes = element.elements(forLocalName: "portType", uri: NS_WSDL).map(PortType.init(deserialize:))
        bindings = element.elements(forLocalName: "binding", uri: NS_WSDL).map(Binding.init(deserialize:))
        services = try element.elements(forLocalName: "service", uri: NS_WSDL).map(Service.init(deserialize:))
    }
}
