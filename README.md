Lark: Swift SOAP Client
=======================

Usage
-----

First, install the package by including the following in `Package.swift`:

    .Package(url: "https://github.com/Bouke/Lark.git", majorVersion: 0)

Then, build your package. This will result in an executable named `lark-generate-client` which can generate the client code:

    swift build
    .build/debug/lark-generate-client "http://localhost:8000/?wsdl" > Sources/Client.swift

Then from your code, you can use the generated client. Inspect the generated code on how to use it. Or have a look at the included demo code.

Limitations
-----------

The current implementation has a lot of limitations. If the library doesn't work for you, rather submit pull requests than issues. The short term wish list is:

* [x] Support simple `complexTypes`: `sequence`
* [ ] Support for `XSD` schema imports
* [ ] Support all `XSD` base types: `decimal`, `dateTime` etc
* [ ] Support other content types: `simpleTypes`, `choice` etc
* [x] Support `Array` and `Optional` types
* [ ] Support multiple ports / bindings
* [ ] Stricter SOAP 1.0 / 1.1 support
* [ ] Collapse messages into client methods (instead of passing request objects, pass request's parameters into client method)
* [ ] Handle `sequence` correctly (elements are strictly ordered)
* [ ] Default value `nil` for `Optional`s

Why is it called Lark?
----------------------

SOAP is sometimes referred to as a fat messaging protocol. Swift is an elegant bird. A Lark sometimes looks like a fat bird.
