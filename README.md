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

```swift
.Package(url: "https://github.com/Bouke/Lark.git", majorVersion: 0)
```

Then, build your package. This will result in an executable named `lark-generate-client` which can generate the client code:

```sh
swift build
.build/debug/lark-generate-client "http://localhost:8000/?wsdl" > Sources/Client.swift
```

In your code you can now use the generated `Client` like this:

```swift
let client = HelloWorldServiceClient()
```

To call a remote method, inspect the generated functions on the Client. For example the `sayHello` method that takes a `SayHello` parameter and returns a `SayHelloResponse`:

```swift
let result = try client.sayHello(SayHello(name: "World", times: 2))
print(result.sayHelloResult)
```

Or if you're building a GUI that requires non-blocking networking, use the async version:

```swift
client.sayHelloAsync(SayHello(name: "World", times: 2)) { result in
    print(result?.value.sayHelloResult)
}
```

## Example

See the [Lark-Example](https://github.com/Bouke/Lark-Example) repository for an
example of how to use Lark.

## FAQ

### Why is it called Lark?

SOAP is sometimes referred to as a fat messaging protocol. Swift is an elegant bird. A Lark sometimes looks like a fat bird.

## Credits

This library was written by [Bouke Haarsma](https://twitter.com/BoukeHaarsma).
