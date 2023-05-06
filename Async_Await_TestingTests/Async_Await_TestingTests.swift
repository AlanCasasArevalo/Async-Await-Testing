import Foundation
import XCTest
@testable import Async_Await_Testing

typealias NetworkError = NetworkService.NetworkError

class NetworkServiceTests: XCTestCase {
    
    func test_performRequest_doesNotStartsNetworkRequest() {
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

    func test_performRequest_deliversDataOn200HttpResponse() async throws {
        let validData = Data("some data".utf8)
        let validResponse = httpResponse(statusCode: 200)
        let (sut, _) = makeSUT(result: .success((validData, validResponse)))

        let receivedData = try await sut.performRequest(anyRequest())
        XCTAssertEqual(receivedData, validData)
    }
}

extension NetworkServiceTests {
    private func makeSUT(result: Result<(Data, URLResponse), Error> = .success(anyValidResult())) -> (sut: NetworkService, session: URLSessionSpy) {
        let session = URLSessionSpy(result: result)
        let sut = NetworkService(session: session)
        return (sut, session)
    }
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


