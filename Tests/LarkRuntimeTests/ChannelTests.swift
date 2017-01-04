import Foundation
import XCTest

@testable import LarkRuntime

class _Transport: Transport {
    var request: (action: URL?, message: Data)? = nil
    let response: Result<Data>
    public init(response: Result<Data>) {
        self.response = response
    }
    func send(action: URL?, message: Data) throws -> Data {
        request = (action, message)
        return try response.resolve()
    }
}

class ChannelTests: XCTestCase {
    func testFault() {
        let fault = Fault(faultcode: "SOAP-ENV:Server", faultstring: "NullReferenceException occurred.", faultactor: nil, detail: [])
        let envelope = Envelope()
        let faultNode = try! envelope.body.createElement(localName: "Fault", uri: NS_SOAP)
        envelope.body.addChild(faultNode)
        try! fault.serialize(faultNode)
        let transport = _Transport(response: .failure(HTTPTransportError.notOk(500, envelope.document.xmlData)))
        let channel = Channel(transport: transport)
        do {
            _ = try channel.send(action: nil, request: Envelope())
        } catch let error as Fault {
            print(error)
            XCTAssertEqual(error.faultcode, fault.faultcode)
            XCTAssertEqual(error.faultstring, fault.faultstring)
            XCTAssertEqual(error.faultactor, fault.faultactor)
            XCTAssertEqual(error.detail, fault.detail)
        } catch {
            XCTFail("Should have thrown Fault, but failed with error: \(error)")
        }
    }

    func testSerialize() {
        let action = URL(string: "my_action")!
        let request = Envelope()
        request.body.addChild(XMLElement(name: "hello", stringValue: "world"))
        let response = Envelope()
        response.body.addChild(XMLElement(name: "foo", stringValue: "bar"))
        let transport = _Transport(response: .success(response.document.xmlData))
        let channel = Channel(transport: transport)
        do {
            let result = try channel.send(action: action, request: request)
            XCTAssertEqual(transport.request!.action, action)
            XCTAssertEqual(transport.request!.message, request.document.xmlData)
            XCTAssertEqual(result.document.xmlString, response.document.xmlString)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
}
