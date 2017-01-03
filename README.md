Lark: Swift SOAP Client
=======================

Lark is a SOAP library written in Swift.

## Features

* [x] Swift 3
* [x] Swift Package Manager 
* [x] API Client code generation
* [x] Strictly typed
* [x] SOAP 1.1
* [x] SOAP document/literal (wrapped) encoding

## Communication

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/search?q=%5Bswift%5D+lark). (Mention 'lark')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/search?q=%5Bswift%5D+lark).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Usage

First, install the package by including the following in `Package.swift`:

    .Package(url: "https://github.com/Bouke/Lark.git", majorVersion: 0)

Then, build your package. This will result in an executable named `lark-generate-client` which can generate the client code:

    swift build
    .build/debug/lark-generate-client "http://localhost:8000/?wsdl" > Sources/Client.swift

In your code you can now use the generated `Client` like this:

    let client = Client()
    try {
        let result = try client.sayHello(SayHello(name: "World", times: 2))
        print(result.sayHelloResult.string)
    } catch let fault as LarkRuntime.Fault {
        print("Server generated a Fault: \(fault)")
    }

## Development

Pull requests welcome!

Known issues:

* [ ] RPC encoding not supported
* [ ] Support all `XSD` base types: `decimal`, `dateTime` etc
* [ ] Support other content types: `simpleTypes`, `choice` etc
* [ ] Handle `sequence` correctly (elements are strictly ordered)
* [ ] Support mixed namespaces in generated code (currently uses "ns0" everywhere)

Backlog:

* [ ] Unit tests
* [ ] Asynchronous
* [ ] Authentication
* [ ] Better error messages
* [ ] Move Demo code to separate repository

Ideas for the future:

* [ ] Collapse messages into client methods (instead of passing request objects, pass request's parameters into client method)
* [ ] Default value `nil` for `Optional`s
* [ ] Generate Envelope/SoapFault types from XSD (become self-hosted)
* [ ] Stricter SOAP 1.0 / 1.1 / 1.2 support
* [ ] Support multiple ports / bindings
* [ ] Cocoapods / Carthage support

## FAQ

### Why is it called Lark?

SOAP is sometimes referred to as a fat messaging protocol. Swift is an elegant bird. A Lark sometimes looks like a fat bird.

## Credits

This library was written by [Bouke Haarsma](https://twitter.com/BoukeHaarsma).
