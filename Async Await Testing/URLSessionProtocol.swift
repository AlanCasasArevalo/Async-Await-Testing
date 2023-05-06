import Foundation

public protocol URLSessionProtocol {
    func fetchRequest(request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {
    public func fetchRequest(request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: delegate)
    }
}
