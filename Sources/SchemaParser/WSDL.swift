struct Message {
    let name: String
}

struct PortType {
    struct Operation {
        let name: String
        let input: String
        let output: String
    }

    let name: String
    let operations: [Operation]
}

struct Binding {
    struct Operation {
        let name: String
    }

    let name: String
    let operations: [Operation]
}

struct Service {
    enum Port {
        case soap(address: String)
        case soap12(address: String)
    }

    let ports: [Port]
}

struct WSDL {
    let schema: XSD
    let messages: [Message]
    let portType: PortType
    let bindings: [Binding]
    let service: Service
}
