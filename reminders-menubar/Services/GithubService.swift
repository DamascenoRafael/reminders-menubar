import Foundation

// swiftlint:disable:next convenience_type
class GithubService {
    static let urlSession = URLSession(configuration: .ephemeral)
    
    static func getLatestRelease() async throws -> Release {
        guard let latestReleaseUrl = URL(string: ApiGithubConstants.latestRelease) else {
            throw URLError(.badURL)
        }
        
        let request = URLRequest(url: latestReleaseUrl, cachePolicy: .reloadIgnoringLocalCacheData)
        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode(Release.self, from: data)
    }
}
