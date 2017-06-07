import Alamofire
import Foundation

extension DataRequest {
    /// Deserializes `Fault` on error responses.
    ///
    /// If the response is a 500 response, but not a SOAP `Fault`, it will
    /// wrap an `Error` instead.
    ///
    /// - Returns: self, to chain other response handlers
    func deserializeFault() -> Self {
        return validate { _, response, data in
            switch response.statusCode {
            case 200: return .success
            case 500:
                do {
                    let document = try XMLDocument(data: data!, options: [])
                    let envelope = try Envelope(document: document)
                    guard let faultElement = envelope.body.elements(forLocalName: "Fault", uri: NS_SOAP_ENVELOPE).first else {
                        return .failure(ServerError.cannotDeserializeFault(data!))
                    }
                    let fault = try Fault(deserialize: faultElement)
                    return .failure(fault)
                } catch {
                    return .failure(error)
                }
            default:
                fatalError("Unexpected status code \(response.statusCode). Verify that validate(statusCode:) is called before this validation.")
            }
        }
    }
}

/// Typed error message returned by the server.
///
/// If the message was received by the server, but could somehow not be 
/// processed, it should return a `Fault`. The issue could for example that the
/// provided data is invalid, some object could not be deserialized, the
/// server performed an illegal operation.
///
/// For more information on SOAP Faults see the [SOAP reference, section 4.4][0].
///
/// [0]: https://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383507
public struct Fault: Error, CustomStringConvertible {

    /// Provides an algorithmic mechanism for identifying the fault.
    public let faultcode: QualifiedName

    /// Provides a human readable explanation of the fault and is not intended for algorithmic processing.
    public let faultstring: String

    /// Provides information about who caused the fault to happen within the message path.
    public let faultactor: URL?

    /// Carries application specific error information related to the `Body` element.
    public let detail: [XMLNode]

    /// A textual representation of this `Fault` instance.
    public var description: String {
        let actor = faultactor?.absoluteString ?? "nil"
        let detail = self.detail.map({ $0.xmlString }).joined(separator: ", ")
        return "Server returned a fault: Fault(code=\(faultcode), actor=\(actor), string=\(faultstring), detail=\(detail))"
    }

    // MARK: - Internal API

    /// Deserializes a `<soap:fault/>` into a `Fault` instance.
    ///
    /// - Parameter element: the `<soap:fault/>` node
    /// - Throws: errors when a typed property cannot be deserialized
    init(deserialize element: XMLElement) throws {
        guard let faultcode = element.elements(forName: "faultcode").first?.stringValue else {
            fatalError("Missing faultcode")
        }
        self.faultcode = try QualifiedName(type: faultcode, inTree: element)
        faultstring = element.elements(forName: "faultstring").first!.stringValue!

        if let actor = element.elements(forName: "faultactor").first, actor.stringValue != "" {
            faultactor = try URL(deserialize: actor)
        } else {
            faultactor = nil
        }
        detail = element.elements(forName: "detail").first?.children ?? []
    }

    init(faultcode: QualifiedName, faultstring: String, faultactor: URL?, detail: [XMLNode]) {
        self.faultcode = faultcode
        self.faultstring = faultstring
        self.faultactor = faultactor
        self.detail = detail
    }

    /// Serializes a `Fault` instance into a `XMLElement`.
    ///
    /// Useful for testing `Fault` deserialization.
    ///
    /// - Parameter element: the `XMLElement` node to serialize into.
    func serialize(_ element: XMLElement) {
        let faultcodePrefix = element.resolveOrAddPrefix(forNamespaceURI: faultcode.uri)
        element.addChild(XMLElement(name: "faultcode", stringValue: "\(faultcodePrefix):\(faultcode.localName)"))

        element.addChild(XMLElement(name: "faultstring", stringValue: faultstring))
        element.addChild(XMLElement(name: "faultactor", stringValue: faultactor?.absoluteString))

        let detailNode = XMLElement(name: "detail")
        for child in detail {
            detailNode.addChild(child)
        }
    }
}

/// Unspecified / untyped error message returned by the server.
///
/// If server produces an uncaught internal server error, it might not return
/// a `Fault`. In such cases, the processing of the server response might fail
/// as the response is unspecified. It's up to the caller to make sense of the
/// `Data` returned by the server.
public enum ServerError: Error, CustomStringConvertible {
    /// The response could not be deserialized into a `Fault`.
    case cannotDeserializeFault(Data)

    /// A textual representation of this `Fault` instance.
    public var description: String {
        switch self {
        case .cannotDeserializeFault: return "Server responded with a HTTP 500 status code, but the expected Fault could not be deserialized. The error's data might contain additional information."
        }
    }
}
