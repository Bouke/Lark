import XCTest

@testable import Lark

class FaultTests: XCTestCase {
    func testDeserialization() throws {
        let element = try XMLElement(xmlString: "<fault xmlns:soap=\"\(NS_SOAP_ENVELOPE)\"><faultcode>soap:Server</faultcode><faultstring>NullReferenceException</faultstring><faultactor>http://tempuri.org/my-server</faultactor><detail><foo>bar</foo></detail></fault>")
        let fault = try Fault(deserialize: element)
        XCTAssertEqual(fault.faultcode, QualifiedName(uri: NS_SOAP_ENVELOPE, localName: "Server"))
        XCTAssertEqual(fault.faultstring, "NullReferenceException")
        XCTAssertEqual(fault.faultactor?.absoluteString, "http://tempuri.org/my-server")
        XCTAssertEqual(fault.detail.count, 1)
        XCTAssertEqual(fault.detail[0].xmlString, "<foo>bar</foo>")
    }

    func testDescription() {
        let fault = Fault(faultcode: QualifiedName(uri: NS_SOAP_ENVELOPE, localName: "VersionMismatch"), faultstring: "version>=4", faultactor: nil, detail: [])
        XCTAssertEqual(fault.description, "Fault(code=(http://schemas.xmlsoap.org/soap/envelope/)VersionMismatch, actor=nil, string=version>=4, detail=)")
    }
}
