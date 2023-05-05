import Foundation
import XCTest

public protocol URLsessionProtocol {
    func fetchRequest(request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
}

extension URLSession: URLsessionProtocol {
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
    private let session: URLsessionProtocol
    
    public init(session: URLsessionProtocol) {
        self.session = session
    }
        
    public func performRequest(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.fetchRequest(request: request, delegate: nil)
            guard let response = response as? HTTPURLResponse, response.statusCode >= 200 else {
                throw NetworkError.invalidData
            }
            
            return data
        } catch {
            throw NetworkError.connectivity
        }
    }
    
    enum NetworkError: Error {
        case invalidData
        case connectivity
    }

}

typealias NetworkError = NetworkService.NetworkError

class NetworkServiceTests: XCTestCase {
    
    func test_performRequest_startsNetworkRequest() async {
        let (sut, session) = makeSUT()
        
        XCTAssertFalse(session.didStartRequest)
        
        _ = try? await sut.performRequest(anyRequest())
        
        XCTAssertTrue(session.didStartRequest)
        XCTAssertEqual(session.request, anyRequest())
    }
    
    func test_performRequest_deliversConnectivityErrorOnNetworkError() async {
        let (sut, session) = makeSUT()
        
        session.completeWith(.connectivity)
        
        do {
            _ = try await sut.performRequest(anyRequest())
        } catch {
            XCTAssertEqual(error as? NetworkError , NetworkError.connectivity)
        }
    }
    
    func test_performRequest_deliversBadResponseCodeErrorOnNon200HttpResponse() async {
        let (sut, session) = makeSUT()
        
        let someResult = (Data(), httpResponse(statusCode: 400))
        session.completeWith(someResult)
        
        do {
            _ = try await sut.performRequest(anyRequest())
        } catch {
            XCTAssertEqual(error as? NetworkError , NetworkError.invalidData)
        }
    }
    
    func test_performRequest_deliversDataOn200HttpResponse() async throws {
        let (sut, session) = makeSUT()
        
        let validData = Data("some data".utf8)
        let validResponse = httpResponse(statusCode: 200)
        session.completeWith((validData, validResponse))
        
        let receivedData = try await sut.performRequest(anyRequest())
        XCTAssertEqual(receivedData, validData)
    }
}

extension NetworkServiceTests {
    
    private func makeSUT() -> (sut: NetworkService, session: URLSessionSpy) {
        let session = URLSessionSpy()
        let sut = NetworkService(session: session)
        return (sut, session)
    }
    
    private func anyRequest(urlString: String = "https://a-url.com") -> URLRequest {
        URLRequest(url: URL(string: urlString)!)
    }
    
    private func httpResponse(url: URL = URL(string: "https://a-url.com")!, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

private final class URLSessionSpy: URLsessionProtocol {
    var didStartRequest: Bool = false
    var request: URLRequest?
    var error: Error?
    var result: (Data, URLResponse)?
    
    func fetchRequest(request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        didStartRequest = true
        self.request = request
        if let error = error {
            throw error
        }
        
        if let result = result {
            return result
        } else {
            throw URLError(.cannotLoadFromNetwork)
        }
    }
    
    func completeWith(_ error: NetworkError) {
        self.error = error
    }
    
    func completeWith(_ result: (Data, URLResponse)) {
        self.result = result
    }
}


