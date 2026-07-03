import Foundation

enum ShareError: LocalizedError {
    case notConfigured
    case badURL
    case emptyDocument
    case server(status: Int, message: String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "No API key set. Open Settings (⌘,) and paste your MD_SHARE_API_KEY."
        case .badURL:
            return "The share base URL in Settings is not valid."
        case .emptyDocument:
            return "There's nothing to share — the document is empty."
        case .server(let status, let message):
            return "Server error (\(status)): \(message)"
        case .network(let detail):
            return "Couldn't reach the server: \(detail)"
        }
    }
}

/// Posts the current Markdown to the website's share endpoint and returns the
/// public URL. Mirrors `POST /api/md-to-pdf/share/external`.
enum ShareService {
    static func share(markdown: String) async throws -> URL {
        guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShareError.emptyDocument
        }

        let settings = ShareSettings.shared
        let key = settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw ShareError.notConfigured }

        guard let url = URL(string: "\(settings.normalizedBase)/api/md-to-pdf/share/external") else {
            throw ShareError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["markdown": markdown])
        request.timeoutInterval = 20

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ShareError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ShareError.network("Unexpected response")
        }

        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

        guard http.statusCode == 200 else {
            let message = (json?["error"] as? String) ?? "HTTP \(http.statusCode)"
            throw ShareError.server(status: http.statusCode, message: message)
        }

        guard let urlString = json?["url"] as? String, let shareURL = URL(string: urlString) else {
            throw ShareError.server(status: http.statusCode, message: "Response had no url")
        }

        return shareURL
    }
}
