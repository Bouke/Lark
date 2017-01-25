import Alamofire
import Foundation

/// SOAP Namespace URI
public let NS_SOAP = "http://schemas.xmlsoap.org/soap/envelope/"

/// XML Schema-Instance Namespace URI
public let NS_XSI = "http://www.w3.org/2001/XMLSchema-instance"

/// SOAP messages are encoded as XML documents called Envelope. An Envelope
/// consists of an optional SOAP header and a mandatory SOAP body.
public struct Envelope {
    let document: XMLDocument

    init() {
        let root = XMLElement.element(withName: "soap:Envelope", uri: NS_SOAP) as! XMLElement
        root.addNamespace(XMLElement.namespace(withName: "soap", stringValue: NS_SOAP) as! XMLNode)
        root.addNamespace(XMLElement.namespace(withName: "xsi", stringValue: NS_XSI) as! XMLNode)
        let body = XMLElement.element(withName: "soap:Body", uri: NS_SOAP) as! XMLElement
        root.addChild(body)
        document = XMLDocument(rootElement: root)
        document.version = "1.0"
        document.characterEncoding = "utf-8"
        document.isStandalone = true
    }

    init(document: XMLDocument) {
        self.document = document
    }

    var root: XMLElement {
        return document.rootElement()!
    }

    public var header: XMLElement {
        if let header = root.elements(forLocalName: "Header", uri: NS_SOAP).first {
            return header
        }
        let header = XMLElement.element(withName: "soap:Header", uri: NS_SOAP) as! XMLElement
        root.insertChild(header, at: 0)
        return header
    }

    public var body: XMLElement {
        return root.elements(forLocalName: "Body", uri: NS_SOAP).first!
    }
}


struct EnvelopeDeserializer: DataResponseSerializerProtocol {
    typealias SerializedObject = Envelope
    let serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Alamofire.Result<Envelope> = {
        if let error = $3 {
            return .failure(error)
        }
        do {
            if let data = $2 {
                let document = try XMLDocument(data: data, options: 0)
                return .success(Envelope(document: document))
            }
        } catch {
            return .failure(error)
        }
        abort()
    }
}


/// Adopt this protocol to create a custom SOAP header.
/// 
/// See also `Header` which provides a basic SOAP header.
public protocol HeaderSerializable {

    /// Serialize the header into an XMLElement. This method will be called
    /// when an `Envelope` is created. If the serialization fails, it will
    /// cancel the service call.
    ///
    /// - Returns: XML serialization of the header
    /// - Throws: can throw any error
    func serialize() throws -> XMLElement
}


/// Generic SOAP Header. SOAP provides a flexible mechanism for extending a 
/// message in a decentralized and modular way without prior knowledge between
/// the communicating parties. Typical examples of extensions that can be 
/// implemented as header entries are authentication, transaction management,
/// payment etc.
public struct Header<Value: XMLSerializable>: HeaderSerializable {
    public let name: QualifiedName
    public let value: Value

    /// Instantiate a `Header` instance.
    ///
    /// - Parameters:
    ///   - name: qualified name of the header
    ///   - value: the value of the header; must be XMLSerializable
    public init(name: QualifiedName, value: Value) {
        self.name = name
        self.value = value
    }

    public func serialize() throws -> XMLElement {
        let node = XMLElement(name: name.localName, uri: name.uri)
        node.setAttributesWith(["xmlns": name.uri])
        try value.serialize(node)
        return node
    }
}
