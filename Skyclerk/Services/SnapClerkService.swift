//
// SnapClerkService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Service responsible for managing SnapClerk receipt scanning operations.
/// SnapClerk allows users to photograph receipts which are then processed by the
/// server to extract transaction details (amount, date, vendor, etc.).
/// Communicates with the /api/v3/{accountId}/snapclerk endpoints.
class SnapClerkService {
    /// Shared singleton instance used throughout the app.
    nonisolated(unsafe) static let shared = SnapClerkService()

    /// Private initializer to enforce singleton usage via SnapClerkService.shared.
    private init() {}

    /// Fetches a paginated list of SnapClerk receipt submissions for the current account.
    /// Results are ordered by creation date descending (newest first).
    /// The API returns pagination info via the X-Last-Page response header.
    ///
    /// - Parameter page: The page number to fetch (1-indexed).
    /// - Returns: A tuple containing the array of SnapClerk objects and a boolean indicating if this is the last page.
    /// - Throws: APIError if the request fails or the response cannot be decoded.
    func getSnapClerks(page: Int) async throws -> (snapclerks: [SnapClerk], lastPage: Bool) {
        let url = APIService.shared.accountURL("snapclerk")

        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "sort", value: "created_at")
        ]

        let response: PaginatedResponse<[SnapClerk]> = try await APIService.shared.getPaginated(url: url, queryItems: queryItems)
        return (snapclerks: response.data, lastPage: response.isLastPage)
    }

    /// Uploads a receipt image to SnapClerk for processing.
    /// The image is sent as a multipart/form-data POST with the photo in the "photo" field
    /// along with optional metadata (note, category, labels, and GPS coordinates).
    /// The server will asynchronously process the receipt and extract transaction details.
    ///
    /// - Parameters:
    ///   - imageData: The raw binary data of the receipt image (typically JPEG).
    ///   - note: An optional note to attach to the receipt for additional context.
    ///   - categoryId: The optional category ID to pre-assign to the receipt. Pass nil to leave unassigned.
    ///   - labelIds: An array of label IDs to tag the receipt with. Pass an empty array for no labels.
    ///   - lat: The latitude coordinate where the receipt was captured. Pass 0.0 if no location is available.
    ///   - lon: The longitude coordinate where the receipt was captured. Pass 0.0 if no location is available.
    /// - Throws: APIError if the upload fails (e.g., file too large, server error).
    func uploadReceipt(imageData: Data, note: String, categoryId: Int?, labelIds: [Int], lat: Double, lon: Double) async throws {
        let url = APIService.shared.accountURL("snapclerk")

        // Generate a unique filename using the current Unix timestamp.
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "sc-mobile-\(timestamp).jpg"

        // Build the additional form fields to send alongside the photo.
        var fields: [String: String] = [
            "note": note,
            "lat": String(lat),
            "lon": String(lon)
        ]

        // Convert label IDs to a comma-separated string (e.g., "1,5,12").
        if !labelIds.isEmpty {
            fields["labels"] = labelIds.map { String($0) }.joined(separator: ",")
        }

        // Include category ID if one was selected.
        if let categoryId = categoryId, categoryId > 0 {
            fields["category"] = String(categoryId)
        }

        try await APIService.shared.uploadMultipart(
            url: url,
            fileData: imageData,
            fileName: fileName,
            mimeType: "image/jpeg",
            additionalFields: fields
        )
    }
}
