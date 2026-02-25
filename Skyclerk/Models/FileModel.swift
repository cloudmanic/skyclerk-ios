//
// FileModel.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// FileModel represents a file (receipt, invoice, document, or image) that has been
/// uploaded to Skyclerk and attached to a ledger entry or SnapClerk submission.
/// Files are stored remotely and accessed via URLs. The model is named FileModel
/// to avoid conflicts with Swift's built-in File types.
struct FileModel: Codable, Identifiable {
    /// The unique identifier for the file, assigned by the API.
    var Id: Int = 0

    /// The ID of the account this file belongs to.
    var AccountId: Int = 0

    /// The original file name as uploaded (e.g., "receipt_2026.pdf", "invoice.jpg").
    var Name: String = ""

    /// The MIME type or file extension type (e.g., "image/jpeg", "application/pdf").
    /// Named fileType in Swift to avoid conflict with the reserved .Type expression,
    /// but maps to "Type" in JSON via CodingKeys.
    var fileType: String = ""

    /// The file size in bytes.
    var Size: Int = 0

    /// The full URL to download or view the original file.
    var Url: String = ""

    /// The URL for a 600x600 pixel thumbnail of the file, typically used for
    /// image previews in the UI. Empty if no thumbnail is available (e.g., for PDFs).
    var Thumb600By600Url: String = ""

    /// CodingKeys maps Swift property names to JSON field names from the API.
    /// The "Type" JSON field is mapped to fileType to avoid Swift naming conflicts.
    enum CodingKeys: String, CodingKey {
        case Id = "id"
        case AccountId = "account_id"
        case Name = "name"
        case fileType = "type"
        case Size = "size"
        case Url = "url"
        case Thumb600By600Url = "thumb_600_by_600_url"
    }

    /// Computed property to satisfy the Identifiable protocol using the API's Id field.
    var id: Int { Id }
}
