import XCTest

@testable import Lark

class XMLElementTests: XCTestCase {
    let namespaces = [
        "http://tempuri.org/0",
        "http://tempuri.org/1",
        "http://tempuri.org/2"
    ]

    func testInit() {
        let element = XMLElement(prefix: "ns0", localName: "test", uri: namespaces[0])
        XCTAssertEqual(element.xmlString, "<ns0:test></ns0:test>")
    }

    func testCreateElement() throws {
        do {
            let root = XMLElement(name: "test")
            _ = root.createChildElement(localName: "foo", uri: namespaces[0])
            XCTAssertEqual(root.xmlString, "<test xmlns:ns1=\"http://tempuri.org/0\"><ns1:foo></ns1:foo></test>")
        }
        do {
            let root = XMLElement(name: "test")
            let foo = root.createChildElement(localName: "foo", uri: namespaces[0])
            _ = foo.createChildElement(localName: "bar", uri: namespaces[1])
            XCTAssertEqual(root.xmlString, "<test xmlns:ns1=\"http://tempuri.org/0\"><ns1:foo xmlns:ns1=\"http://tempuri.org/1\"><ns1:bar></ns1:bar></ns1:foo></test>")
        }
    }

    func testTargetNamespace() {
        let root = XMLElement(name: "test")
        XCTAssertNil(root.targetNamespace)

        root.addAttribute(XMLNode.attribute(withName: "targetNamespace", stringValue: namespaces[0]) as! XMLNode)
        XCTAssertEqual(root.targetNamespace, namespaces[0])

        // inheritance
        let child = XMLElement(name: "foo")
        root.addChild(child)
        XCTAssertEqual(child.targetNamespace, namespaces[0])

        // override
        child.addAttribute(XMLNode.attribute(withName: "targetNamespace", stringValue: namespaces[1]) as! XMLNode)
        XCTAssertEqual(child.targetNamespace, namespaces[1])
        XCTAssertEqual(root.targetNamespace, namespaces[0])
    }
}
