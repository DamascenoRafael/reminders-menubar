import Foundation

class GithubService {
    static let urlSession = URLSession(configuration: .ephemeral)
    
    static func getLatestRelease(completion: @escaping (Result<Release, Error>) -> Void) {
        guard let latestReleaseUrl = URL(string: ApiGithubConstants.latestRelease) else {
            return
        }
        
        let request = URLRequest(url: latestReleaseUrl, cachePolicy: .reloadIgnoringLocalCacheData)
        
        urlSession.dataTask(with: request) { data, _, error in
            guard let data else {
                if let error {
                    completion(.failure(error))
                }
                return
            }
            
            do {
                let release = try JSONDecoder().decode(Release.self, from: data)
                completion(.success(release))
            } catch let error {
                completion(.failure(error))
            }
        }
        .resume()
    }
}
