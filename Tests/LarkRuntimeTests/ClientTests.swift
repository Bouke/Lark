import Foundation
import XCTest

@testable import LarkRuntime

class _Channel: Channel {
    struct _Transport: Transport {
        func send(action: URL, message: Data) throws -> Data {
            fatalError("Not implemented")
        }
    }
    var request: (action: URL?, request: Envelope)? = nil
    let response: Result<Envelope>
    public init(response: Result<Envelope>) {
        self.response = response
        super.init(transport: _Transport())
    }
    override func send(action: URL?, request: Envelope) throws -> Envelope {
        self.request = (action, request)
        return try response.resolve()
    }
}

class ClientTests: XCTestCase {
    /// Verify that request is serialized correctly and correct response is returned.
    func test() {
        let expected = Envelope()
        expected.body.addChild(XMLElement(name: "hello", stringValue: "world"))
        let channel = _Channel(response: .success(expected))
        let client = Client(channel: channel)
        do {
            let actual = try client.send(action: URL(string: "action")!, parameters: [XMLElement(name: "foo", stringValue: "bar")])
            XCTAssertEqual(channel.request!.request.body.xmlString,
                           "<soap:Body><foo>bar</foo></soap:Body>")
            XCTAssertEqual(actual.xmlString, expected.body.xmlString)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    /// Not setting a header should not result in a `<soap:Header/>` node
    func testNoHeaders() throws {
        let channel = _Channel(response: .success(Envelope()))
        let client = Client(channel: channel)
        _ = try client.send(action: URL(string: "action")!, parameters: [])
        XCTAssertEqual(channel.request!.request.root.xmlString,
                       "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body></soap:Body></soap:Envelope>")
    }

    /// Verify that headers are added to the envelope.
    func testSetHeaders() throws {
        let channel = _Channel(response: .success(Envelope()))
        let client = Client(channel: channel)
        client.headers.append((QualifiedName(uri: "System", localName: "String"), "ABC"))
        _ = try client.send(action: URL(string: "action")!, parameters: [])
        XCTAssertEqual(channel.request!.request.header.xmlString,
                       "<soap:Header><String xmlns=\"System\">ABC</String></soap:Header>")
    }
}
