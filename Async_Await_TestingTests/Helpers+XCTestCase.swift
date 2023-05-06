import Foundation

func anyRequest(urlString: String = "https://a-url.com") -> URLRequest {
    URLRequest(url: URL(string: urlString)!)
}

func httpResponse(url: URL = URL(string: "https://a-url.com")!, statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

func anyValidResult(statusCode: Int = 200) -> (Data, HTTPURLResponse) {
    (Data(), httpResponse(statusCode: statusCode))
}

struct AnyError: Error {}

func anyError() -> Error {
    AnyError()
}
