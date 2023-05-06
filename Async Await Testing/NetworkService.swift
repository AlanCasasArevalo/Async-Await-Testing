import Foundation

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

