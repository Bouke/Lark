import Foundation
import XCTest

@testable import LarkRuntime

class _Channel: Channel {
    struct _Transport: Transport {
        func send(action: URL, message: Data, completionHandler: (Result<Data>) -> Void) {
            fatalError("Not implemented")
        }
    }
    var request: (action: URL?, request: Envelope)? = nil
    let response: Result<Envelope>
    public init(response: Result<Envelope>) {
        self.response = response
        super.init(transport: _Transport())
    }
    override func send(action: URL, request: Envelope, completionHandler: @escaping (Result<Envelope>) -> Void) {
        self.request = (action, request)
        completionHandler(response)
    }
}

class ClientTests: XCTestCase {
    /// Verify that request is serialized correctly and correct response is returned.
    func test() throws {
        let expected = Envelope()
        expected.body.addChild(XMLElement(name: "hello", stringValue: "world"))
        let channel = _Channel(response: .success(expected))
        let client = Client(channel: channel)
        try expect { future in
            try client.send(action: URL(string: "action")!, parameters: [XMLElement(name: "foo", stringValue: "bar")]) {
                do {
                    let actual = try $0.resolve()
                    XCTAssertEqual(channel.request!.request.body.xmlString,
                                   "<soap:Body><foo>bar</foo></soap:Body>")
                    XCTAssertEqual(actual.xmlString, expected.body.xmlString)
                } catch {
                    XCTFail("Failed with error: \(error)")
                }
                future.fulfill()
            }
        }
    }

    /// Not setting a header should not result in a `<soap:Header/>` node
    func testNoHeaders() throws {
        let channel = _Channel(response: .success(Envelope()))
        let client = Client(channel: channel)
        try expect { future in
            try client.send(action: URL(string: "action")!, parameters: []) {
                _ = try! $0.resolve()
                XCTAssertEqual(channel.request!.request.root.xmlString,
                               "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body></soap:Body></soap:Envelope>")
                future.fulfill()
            }
        }
    }

    /// Verify that headers are added to the envelope.
    func testSetHeaders() throws {
        let channel = _Channel(response: .success(Envelope()))
        let client = Client(channel: channel)
        client.headers.append((QualifiedName(uri: "System", localName: "String"), "ABC"))
        try expect { future in
            try client.send(action: URL(string: "action")!, parameters: []) {
                _ = try! $0.resolve()
                XCTAssertEqual(channel.request!.request.header.xmlString,
                               "<soap:Header><String xmlns=\"System\">ABC</String></soap:Header>")
                future.fulfill()
            }
        }
    }
}
