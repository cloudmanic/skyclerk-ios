//
// APIService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation
import os

/// Custom error types for API operations.
/// These errors provide meaningful context about what went wrong during an API call.
enum APIError: LocalizedError {
    /// The request URL could not be constructed from the provided string.
    case invalidURL

    /// The server responded with an HTTP status code outside the 200-299 success range.
    case httpError(statusCode: Int, message: String)

    /// The response could not be decoded into the expected model type.
    case decodingError(Error)

    /// The response could not be encoded into JSON for the request body.
    case encodingError(Error)

    /// No valid authentication token was found in UserDefaults.
    case unauthorized

    /// A human-readable description of the error for display in the UI.
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .unauthorized:
            return "Not authenticated. Please log in."
        }
    }
}

/// A response wrapper that includes both the decoded data and pagination metadata.
/// Used by GET requests that return paginated lists from the API.
struct PaginatedResponse<T> {
    /// The decoded array of items returned by the API.
    let data: T

    /// Whether this is the last page of results. Parsed from the X-Last-Page response header.
    let isLastPage: Bool
}

/// Singleton HTTP client responsible for all communication with the Skyclerk REST API.
/// Handles authentication headers, JSON encoding/decoding, multipart file uploads,
/// form-urlencoded requests (for OAuth), and pagination header parsing.
/// All methods use Swift concurrency (async/await) for non-blocking network calls.
class APIService {
    /// Shared singleton instance used throughout the app.
    nonisolated(unsafe) static let shared = APIService()

    /// The base URL for all API requests, sourced from the app's environment configuration.
    private var baseURL: String { AppEnvironment.appServer }

    /// The OAuth bearer token stored after successful authentication.
    /// Returns nil if the user has not logged in or the token has been cleared.
    private var authToken: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    /// The currently active account ID, stored after login or account selection.
    /// Returns 0 if no account has been selected (default integer value).
    private var accountId: Int {
        UserDefaults.standard.integer(forKey: "account_id")
    }

    /// A shared JSONDecoder configured for decoding API responses.
    /// Uses the default decoding strategy since the API returns PascalCase keys
    /// that match the model property names directly.
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    /// A shared JSONEncoder configured for encoding request bodies.
    /// Uses the default encoding strategy since the API expects PascalCase keys
    /// that match the model property names directly.
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()

    /// Private initializer to enforce singleton usage via APIService.shared.
    private init() {}

    // MARK: - Logging

    /// Logger for API network requests using the unified logging system.
    private let logger = Logger(subsystem: "com.cloudmanic.skyclerk", category: "API")

    /// Logs an outgoing API request to the console with its method, URL, and auth token.
    private func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        let token = request.value(forHTTPHeaderField: "Authorization") ?? "none"
        logger.notice("→ \(method, privacy: .public) \(url, privacy: .public) [Auth: \(token, privacy: .public)]")
    }

    /// Logs the API response with status code and a truncated body preview.
    private func logResponse(_ response: URLResponse, data: Data) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let body = String(data: data.prefix(500), encoding: .utf8) ?? "<binary \(data.count) bytes>"
        logger.notice("← \(statusCode, privacy: .public) (\(data.count, privacy: .public) bytes) \(body, privacy: .public)")
    }

    // MARK: - URL Helpers

    /// Builds a full URL string for account-specific API endpoints.
    /// The account ID is automatically inserted into the path from UserDefaults.
    ///
    /// - Parameter path: The endpoint path after the account ID segment (e.g., "ledger", "contacts").
    /// - Returns: A full URL string like "https://app.skyclerk.com/api/v3/42/ledger".
    func accountURL(_ path: String) -> String {
        return "\(baseURL)/api/v3/\(accountId)/\(path)"
    }

    // MARK: - GET

    /// Performs an authenticated GET request and decodes the JSON response into the specified type.
    /// Automatically attaches the OAuth bearer token from UserDefaults.
    ///
    /// - Parameters:
    ///   - url: The full URL string for the request.
    ///   - queryItems: Optional array of URL query parameters to append to the URL.
    /// - Returns: The decoded response of type T.
    /// - Throws: APIError.invalidURL, APIError.unauthorized, APIError.httpError, or APIError.decodingError.
    func get<T: Decodable>(url: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        guard var urlComponents = URLComponents(string: url) else {
            throw APIError.invalidURL
        }

        if let queryItems = queryItems, !queryItems.isEmpty {
            urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems
        }

        guard let requestURL = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        try addAuthHeader(to: &request)
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Performs an authenticated GET request and returns a PaginatedResponse containing
    /// the decoded data along with the X-Last-Page pagination flag from the response header.
    ///
    /// - Parameters:
    ///   - url: The full URL string for the request.
    ///   - queryItems: Optional array of URL query parameters to append to the URL.
    /// - Returns: A PaginatedResponse wrapping the decoded data and pagination metadata.
    /// - Throws: APIError.invalidURL, APIError.unauthorized, APIError.httpError, or APIError.decodingError.
    func getPaginated<T: Decodable>(url: String, queryItems: [URLQueryItem]? = nil) async throws -> PaginatedResponse<T> {
        guard var urlComponents = URLComponents(string: url) else {
            throw APIError.invalidURL
        }

        if let queryItems = queryItems, !queryItems.isEmpty {
            urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems
        }

        guard let requestURL = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        try addAuthHeader(to: &request)
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)

        let httpResponse = response as? HTTPURLResponse
        let lastPageHeader = httpResponse?.value(forHTTPHeaderField: "X-Last-Page") ?? "false"
        let isLastPage = lastPageHeader.lowercased() == "true"

        do {
            let decoded = try decoder.decode(T.self, from: data)
            return PaginatedResponse(data: decoded, isLastPage: isLastPage)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - POST

    /// Performs an authenticated POST request with a JSON-encoded body and decodes the response.
    ///
    /// - Parameters:
    ///   - url: The full URL string for the request.
    ///   - body: An Encodable object to serialize as the JSON request body.
    /// - Returns: The decoded response of type T.
    /// - Throws: APIError.invalidURL, APIError.unauthorized, APIError.encodingError, APIError.httpError, or APIError.decodingError.
    func post<T: Decodable, B: Encodable>(url: String, body: B) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try addAuthHeader(to: &request)

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Performs an authenticated POST request with a JSON-encoded body that expects no response body.
    /// Used for endpoints that return 200/204 with an empty or irrelevant response.
    ///
    /// - Parameters:
    ///   - url: The full URL string for the request.
    ///   - body: An Encodable object to serialize as the JSON request body.
    /// - Throws: APIError.invalidURL, APIError.unauthorized, APIError.encodingError, or APIError.httpError.
    func post<B: Encodable>(url: String, body: B) async throws {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try addAuthHeader(to: &request)

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)
    }

    /// Performs an authenticated POST request with no request body and no expected response body.
    /// Used for action endpoints like delete-account that only need the URL and auth.
    ///
    /// - Parameter url: The full URL string for the request.
    /// - Throws: APIError.invalidURL, APIError.unauthorized, or APIError.httpError.
    func postEmpty(url: String) async throws {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        try addAuthHeader(to: &request)
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)
    }

    /// Performs a POST request with a JSON-encoded body without an Authorization header.
    /// Used for unauthenticated endpoints like /register where the user does not yet have a token.
    ///
    /// - Parameters:
    ///   - url: The full URL string for the request.
    ///   - body: An Encodable object to serialize as the JSON request body.
    /// - Returns: The decoded response of type T.
    /// - Throws: APIError.invalidURL, APIError.encodingError, APIError.httpError, or APIError.decodingError.
    func postJSON<T: Decodable, B: Encodable>(url: String, body: B) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - PUT

    /// Performs an authenticated PUT request with a JSON-encoded body and decodes the response.
    ///
    /// - Parameters:
    ///   - url: The full URL string for the request.
    ///   - body: An Encodable object to serialize as the JSON request body.
    /// - Returns: The decoded response of type T.
    /// - Throws: APIError.invalidURL, APIError.unauthorized, APIError.encodingError, APIError.httpError, or APIError.decodingError.
    func put<T: Decodable, B: Encodable>(url: String, body: B) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try addAuthHeader(to: &request)

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - DELETE

    /// Performs an authenticated DELETE request. Expects no response body.
    ///
    /// - Parameter url: The full URL string for the resource to delete.
    /// - Throws: APIError.invalidURL, APIError.unauthorized, or APIError.httpError.
    func delete(url: String) async throws {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        try addAuthHeader(to: &request)
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)
    }

    // MARK: - Form URL-Encoded POST (OAuth)

    /// Performs a POST request with application/x-www-form-urlencoded body encoding.
    /// Used specifically for OAuth token requests where the server expects form parameters
    /// rather than JSON. This method does NOT attach an Authorization header since it is
    /// used before the user has a token (during login/registration).
    ///
    /// - Parameters:
    ///   - url: The full URL string for the request.
    ///   - params: A dictionary of key-value pairs to encode as form data.
    /// - Returns: The decoded response of type T.
    /// - Throws: APIError.invalidURL, APIError.httpError, or APIError.decodingError.
    func postForm<T: Decodable>(url: String, params: [String: String]) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = params.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Multipart File Upload

    /// Performs an authenticated multipart/form-data file upload.
    /// Constructs a multipart request body containing the file data and any additional text fields.
    /// Used for uploading receipts, images, and other files to the API.
    ///
    /// - Parameters:
    ///   - url: The full URL string for the upload endpoint.
    ///   - fileData: The raw binary data of the file to upload.
    ///   - fileName: The filename to include in the Content-Disposition header (e.g., "receipt.jpg").
    ///   - mimeType: The MIME type of the file (e.g., "image/jpeg", "image/png").
    ///   - fieldName: The form field name for the file data (e.g., "file", "photo"). Defaults to "file".
    ///   - additionalFields: Optional dictionary of additional text fields to include in the multipart form.
    /// - Returns: The decoded FileModel from the API response.
    /// - Throws: APIError.invalidURL, APIError.unauthorized, APIError.httpError, or APIError.decodingError.
    func uploadFile(url: String, fileData: Data, fileName: String, mimeType: String, fieldName: String = "file", additionalFields: [String: String]? = nil) async throws -> FileModel {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        try addAuthHeader(to: &request)

        var body = Data()

        // Add additional text fields if provided.
        if let fields = additionalFields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        // Add the file data.
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // Close the multipart boundary.
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(FileModel.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Performs an authenticated multipart/form-data upload for SnapClerk receipts.
    /// Unlike the generic uploadFile method, this does not return a FileModel because
    /// the SnapClerk endpoint returns a different response structure (or no body).
    ///
    /// - Parameters:
    ///   - url: The full URL string for the SnapClerk upload endpoint.
    ///   - fileData: The raw binary data of the receipt image to upload.
    ///   - fileName: The filename to include in the Content-Disposition header.
    ///   - mimeType: The MIME type of the file (e.g., "image/jpeg").
    ///   - additionalFields: Optional dictionary of additional text fields (note, labels, category, lat, lon).
    /// - Throws: APIError.invalidURL, APIError.unauthorized, or APIError.httpError.
    func uploadMultipart(url: String, fileData: Data, fileName: String, mimeType: String, additionalFields: [String: String]? = nil) async throws {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        try addAuthHeader(to: &request)

        var body = Data()

        // Add additional text fields if provided.
        if let fields = additionalFields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        // Add the photo file data.
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // Close the multipart boundary.
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        logRequest(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        logResponse(response, data: data)
        try validateResponse(response, data: data)
    }

    // MARK: - Private Helpers

    /// Adds the OAuth bearer token Authorization header to the given request.
    /// Reads the token from UserDefaults. If no token is found, throws an unauthorized error.
    ///
    /// - Parameter request: The URLRequest to modify (passed by reference).
    /// - Throws: APIError.unauthorized if no access_token is stored in UserDefaults.
    private func addAuthHeader(to request: inout URLRequest) throws {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    /// Validates the HTTP response status code. If the status code is outside the
    /// 200-299 success range, attempts to extract an error message from the response
    /// body and throws an httpError.
    ///
    /// - Parameters:
    ///   - response: The URLResponse to validate.
    ///   - data: The response body data, used to extract error messages on failure.
    /// - Throws: APIError.httpError if the status code indicates failure.
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}
