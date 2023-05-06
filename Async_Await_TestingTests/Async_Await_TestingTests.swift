import Foundation
import XCTest

public protocol URLSessionProtocol {
    func fetchRequest(request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {
    public func fetchRequest(request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: delegate)
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

public final class NetworkService {
    private let session: URLSessionProtocol
    
    public init(session: URLSessionProtocol) {
        self.session = session
    }
        
    public func performRequest(_ request: URLRequest) async throws -> Data {
        guard let (data, response) = try? await session.fetchRequest(request: request, delegate: nil) else {
            throw NetworkError.connectivity
        }

        guard let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode <= 299 else {
            throw NetworkError.invalidData
        }
        return data
    }
    
    enum NetworkError: Error {
        case invalidData
        case connectivity
    }

}

typealias NetworkError = NetworkService.NetworkError

class NetworkServiceTests: XCTestCase {
    
    func test_performRequest_doesNotStartsNetworkRequest() async throws {
        let (_, session) = makeSUT()
        XCTAssertEqual(session.requests, [] , "Precondition: should not perform request")
    }

    func test_performRequest_startsNetworkRequest() async throws {
        let (sut, session) = makeSUT()
        let request = anyRequest()

        _ = try await sut.performRequest(request)

        XCTAssertEqual(session.requests, [request])
    }

    func test_performRequest_deliversConnectivityErrorOnNetworkError() async {
        let (sut, _) = makeSUT(result: .failure(anyError()))

        do {
            _ = try await sut.performRequest(anyRequest())
            XCTFail("Expected  error: \(NetworkError.connectivity)")
        } catch {
            XCTAssertEqual(error as? NetworkError , NetworkError.connectivity)
        }
    }

    func test_performRequest_deliversBadResponseCodeErrorOnNon200HttpResponse() async throws {
        let non200Response = (Data(), httpResponse(statusCode: 400))
        let (sut, _) = makeSUT(result: .success(non200Response))

        do {
            _ = try await sut.performRequest(anyRequest())
            XCTFail("Expected  error: \(NetworkError.invalidData)")
        } catch {
            XCTAssertEqual(error as? NetworkError, NetworkError.invalidData)
        }
    }
//
//    func test_performRequest_deliversDataOn200HttpResponse() async throws {
//        let (sut, session) = makeSUT()
//
//        let validData = Data("some data".utf8)
//        let validResponse = httpResponse(statusCode: 200)
//        session.completeWith((validData, validResponse))
//
//        let receivedData = try await sut.performRequest(anyRequest())
//        XCTAssertEqual(receivedData, validData)
//    }
}

extension NetworkServiceTests {
    private func makeSUT(result: Result<(Data, URLResponse), Error> = .success(anyValidResult())) -> (sut: NetworkService, session: URLSessionSpy) {
        let session = URLSessionSpy(result: result)
        let sut = NetworkService(session: session)
        return (sut, session)
    }
}
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

private final class URLSessionSpy: URLSessionProtocol {
    private(set) var requests: [URLRequest?] = []
    let result: Result<(Data, URLResponse), Error>

    init(result: Result<(Data, URLResponse), Error>) {
        self.result = result
    }
    
    func fetchRequest(request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        self.requests.append(request)
        return try result.get()
    }
}


