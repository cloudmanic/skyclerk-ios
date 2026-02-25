//
// FileService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Service responsible for uploading files (receipts, invoices, images) to the Skyclerk API.
/// Files are uploaded as multipart form data and associated with ledger entries or SnapClerk receipts.
class FileService {
    /// Shared singleton instance used throughout the app.
    nonisolated(unsafe) static let shared = FileService()

    /// Private initializer to enforce singleton usage via FileService.shared.
    private init() {}

    /// Uploads an image file to the current account's file storage.
    /// Generates a unique filename using the format "sc-mobile-{timestamp}.{extension}"
    /// to avoid naming collisions and identify files uploaded from the mobile app.
    /// The file is sent as a multipart/form-data POST request.
    ///
    /// - Parameters:
    ///   - imageData: The raw binary data of the image to upload.
    ///   - fileExtension: The file extension without a dot (e.g., "jpg", "png", "pdf").
    /// - Returns: The FileModel object returned by the API, containing the file's ID and URL.
    /// - Throws: APIError if the upload fails (e.g., file too large, server error).
    func uploadFile(imageData: Data, fileExtension: String) async throws -> FileModel {
        let url = APIService.shared.accountURL("files")

        // Generate a unique filename using the current Unix timestamp.
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "sc-mobile-\(timestamp).\(fileExtension)"

        // Determine the MIME type based on the file extension.
        let mimeType = mimeTypeForExtension(fileExtension)

        let fileModel = try await APIService.shared.uploadFile(
            url: url,
            fileData: imageData,
            fileName: fileName,
            mimeType: mimeType
        )

        return fileModel
    }

    /// Maps a file extension to its corresponding MIME type string.
    /// Supports common image formats used for receipt and document uploads.
    /// Defaults to "application/octet-stream" for unrecognized extensions.
    ///
    /// - Parameter ext: The file extension without a dot (e.g., "jpg", "png", "pdf").
    /// - Returns: The MIME type string (e.g., "image/jpeg", "image/png").
    private func mimeTypeForExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        case "heic":
            return "image/heic"
        default:
            return "application/octet-stream"
        }
    }
}
