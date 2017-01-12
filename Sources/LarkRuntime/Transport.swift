import Foundation
import Evergreen
import Alamofire

public protocol Transport {
    func send(action: URL, message: Data, completionHandler: @escaping (Result<Data>) -> Void)
}

public enum HTTPTransportError: Error {
    case notOk(Int, Data)
    case invalidMimeType(String?)
}

open class HTTPTransport: Transport {
    open let endpoint: URL
    open let logger = Evergreen.getLogger("Lark.HTTPTransport")
    open var headers: [String: String] = [:]

    public init(endpoint: URL) {
        self.endpoint = endpoint
    }

    open func send(action: URL, message: Data, completionHandler: @escaping (Result<Data>) -> Void) {
        var request = URLRequest(url: endpoint)
        request.httpBody = message
        request.httpMethod = "POST"
        request.addValue(action.absoluteString, forHTTPHeaderField: "SOAPAction")
        request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("\(message.count)", forHTTPHeaderField: "Content-Length")
        for item in headers {
            request.addValue(item.value, forHTTPHeaderField: item.key)
        }
        logger.debug("Request: " + request.debugDescription + "\n" + (request.allHTTPHeaderFields?.map({"\($0): \($1)"}).joined(separator: "\n") ?? ""))

        do {
            var response: URLResponse? = nil
            // TODO: configuration of connection timeouts
            let data = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("Expected HTTPURLResponse")
            }

            logger.debug("Response: " + httpResponse.debugDescription)
            logger.debug("Response body: " + (String(data: data, encoding: .utf8) ?? "Failed to decode the body as UTF-8 for logging"))
            guard httpResponse.statusCode == 200 else {
                throw HTTPTransportError.notOk(httpResponse.statusCode, data)
            }
            guard httpResponse.mimeType == "text/xml" else {
                throw HTTPTransportError.invalidMimeType(httpResponse.mimeType)
            }
            completionHandler(.success(data))
        } catch {
            completionHandler(.failure(error))
        }
    }
}

