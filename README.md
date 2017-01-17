Lark: Swift SOAP Client
=======================

Lark is a SOAP library written in Swift.

[![Build Status](https://travis-ci.org/Bouke/Lark.svg?branch=master)](https://travis-ci.org/Bouke/Lark)

## Features

* [x] Swift 3
* [x] Swift Package Manager 
* [x] API Client code generation
* [x] Strictly typed
* [x] SOAP 1.1
* [x] SOAP document/literal (wrapped) encoding
* [x] Both synchronous and asynchronous

## Communication

- If you **need help**, open an issue.
- If you'd like to **ask a general question**, open an issue.
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

    let client = HelloWorldServiceClient()

To call a remote method, inspect the generated functions on the Client. For example the `sayHello` method that takes a `SayHello` parameter and returns a `SayHelloResponse`:

    let result = try client.sayHello(SayHello(name: "World", times: 2))
    print(result.sayHelloResult)

Or if you're building a GUI that requires non-blocking networking, use the async version:

    client.sayHelloAsync(SayHello(name: "World", times: 2)) { result in
        print(result?.value.sayHelloResult)
    }

## Example

See the [Lark-Example](https://github.com/Bouke/Lark-Example) repository for an
example of how to use Lark.

## Development

Pull requests welcome!

Known issues:

* [x] Support mixed namespaces in generated code
* [ ] Support all `XSD` base types: `decimal`, `dateTime` etc
* [ ] Support other content types: `simpleTypes`, `choice` etc
* [ ] Handle `sequence` correctly (elements are strictly ordered)

Backlog:

* [x] Move Demo code to separate repository
* [x] Unit tests
* [x] Authentication (by setting HTTP / SOAP headers)
* [x] Implement `simpleType`s: list and list (wrapped)
* [x] Asynchronous
* [x] Client endpoint as static variable
* [x] Default value `nil` for `Optional`s
* [x] Revise API for both sync/async calls
* [ ] Parse `nillable=true` in XSD
* [ ] Provide helper methods for inspecting requests / replies

Ideas for the future:

* [x] Provide asynchronous `HTTPTransport`s out-of-the-box
* [ ] Collapse messages into client methods (instead of passing request objects, pass request's parameters into client method)
* [ ] Generate Envelope/SoapFault types from XSD (become self-hosted)
* [ ] Stricter SOAP 1.0 / 1.1 / 1.2 support
* [ ] Support multiple ports / bindings
* [ ] Cocoapods / Carthage support
* [ ] Wrap all errors, or bubble cocoa errors -- what's common for Swift libraries?

Out of (my) scope:

* RPC encoding support

## FAQ

### Why is it called Lark?

SOAP is sometimes referred to as a fat messaging protocol. Swift is an elegant bird. A Lark sometimes looks like a fat bird.

## Credits

This library was written by [Bouke Haarsma](https://twitter.com/BoukeHaarsma).
