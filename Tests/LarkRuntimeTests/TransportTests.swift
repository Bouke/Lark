import Foundation
import XCTest

@testable import LarkRuntime

class _HTTPTransport: HTTPTransport {
    var request: URLRequest? = nil
    let response: Result<(HTTPURLResponse, Data)>

    public init(endpoint: URL, response: Result<(HTTPURLResponse, Data)>) {
        self.response = response
        super.init(endpoint: endpoint)
    }

    override func send(_ request: URLRequest) throws -> (HTTPURLResponse, Data) {
        self.request = request
        return try response.resolve()
    }
}

class HTTPTransportTests: XCTestCase {
    func testOk() {
        let response = HTTPURLResponse(
            url: URL(string: "http://tempuri.org")!,
            statusCode: 200,
            httpVersion: "1.1",
            headerFields: [
                "Content-Type": "text/xml"
            ])!
        let data = "<hello>world</hello>".data(using: .utf8)!
        let transport = _HTTPTransport(endpoint: URL(string: "http://tempuri.org")!, response: .success((response, data)))
        do {
            let result = try transport.send(action: URL(string: "GetCountries")!, message: Data())
            XCTAssertEqual(result, data)
            XCTAssertNotNil(transport.request)
            XCTAssertEqual(transport.request!.allHTTPHeaderFields ?? [:],
                           ["Content-Type": "text/xml; charset=utf-8",
                            "SOAPAction": "GetCountries",
                            "Content-Length": "0"])
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testServerError() {
        let response = HTTPURLResponse(
            url: URL(string: "http://tempuri.org")!,
            statusCode: 500,
            httpVersion: "1.1",
            headerFields: [
                "Content-Type": "text/xml"
            ])!
        let data = "<hello>world</hello>".data(using: .utf8)!
        let transport = _HTTPTransport(endpoint: URL(string: "http://tempuri.org")!, response: .success((response, data)))
        do {
            _ = try transport.send(action: URL(string: "GetCountries")!, message: Data())
            XCTFail("Should throw on status code 500")
        } catch HTTPTransportError.notOk(let (statusCode, result)) where statusCode == 500 {
            XCTAssertEqual(result, data)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testInvalidMimeType() {
        let response = HTTPURLResponse(
            url: URL(string: "http://tempuri.org")!,
            statusCode: 200,
            httpVersion: "1.1",
            headerFields: [
                "Content-Type": "text/html"
            ])!
        let transport = _HTTPTransport(endpoint: URL(string: "http://tempuri.org")!, response: .success((response, Data())))
        do {
            _ = try transport.send(action: URL(string: "GetCountries")!, message: Data())
            XCTFail("Should throw on invalid mime type")
        } catch HTTPTransportError.invalidMimeType(let type) where type == "text/html" {
            // ok
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testHTTPHeaders() {
        let response = HTTPURLResponse(
            url: URL(string: "http://tempuri.org")!,
            statusCode: 200,
            httpVersion: "1.1",
            headerFields: [
                "Content-Type": "text/xml"
            ])!
        let transport = _HTTPTransport(endpoint: URL(string: "http://tempuri.org")!, response: .success((response, Data())))
        let headers = ["Authentication": "Basic 0xdeadbeef"]
        transport.headers = headers
        do {
            _ = try transport.send(action: URL(string: "GetCountries")!, message: Data())
            XCTAssertEqual(transport.request?.allHTTPHeaderFields?["Authentication"],
                           headers["Authentication"])
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
}
