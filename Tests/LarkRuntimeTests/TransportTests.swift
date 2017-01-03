import Foundation
import XCTest

@testable import LarkRuntime

class _HTTPTransport: HTTPTransport {
    var request: URLRequest? = nil

    let response: HTTPURLResponse?
    let data: Data?
    let error: Error?

    public init(endpoint: URL, response: HTTPURLResponse?, data: Data?, error: Error?) {
        self.response = response
        self.data = data
        self.error = error
        super.init(endpoint: endpoint)
    }

    override func doSend(_ request: URLRequest) throws -> (HTTPURLResponse, Data) {
        self.request = request
        if let error = error {
            throw error
        } else {
            return (response!, data!)
        }
    }
}

class HTTPTransportTests: XCTestCase {
    func testOk() throws {
        let response = HTTPURLResponse(
            url: URL(string: "http://tempuri.org")!,
            statusCode: 200,
            httpVersion: "1.1",
            headerFields: [
                "Content-Type": "text/xml"
            ])!
        let data = "<hello>world</hello>".data(using: .utf8)
        let transport = _HTTPTransport(endpoint: URL(string: "http://tempuri.org")!, response: response, data: data, error: nil)

        let result = try transport.send(action: URL(string: "GetCountries"), message: Data())
        XCTAssertEqual(result, data)
        XCTAssertNotNil(transport.request)
        XCTAssertEqual(transport.request!.allHTTPHeaderFields ?? [:],
                       ["Content-Type": "text/xml; charset=utf-8",
                        "SOAPAction": "GetCountries",
                        "Content-Length": "0"])
    }

    func testServerError() throws {
        let response = HTTPURLResponse(
            url: URL(string: "http://tempuri.org")!,
            statusCode: 500,
            httpVersion: "1.1",
            headerFields: [
                "Content-Type": "text/xml"
            ])!
        let data = "<hello>world</hello>".data(using: .utf8)
        let transport = _HTTPTransport(endpoint: URL(string: "http://tempuri.org")!, response: response, data: data, error: nil)

        do {
            _ = try transport.send(action: URL(string: "GetCountries"), message: Data())
            XCTFail("Should throw on status code 500")
        } catch HTTPTransportError.notOk(let (statusCode, result)) where statusCode == 500 {
            XCTAssertEqual(result, data)
        }
    }
}
