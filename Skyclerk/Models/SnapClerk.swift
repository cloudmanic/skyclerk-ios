//
// SnapClerk.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// SnapClerk represents a receipt or document that has been submitted for
/// automated processing. When a user photographs a receipt, a SnapClerk entry
/// is created and processed asynchronously. Once processing is complete, the
/// extracted data (amount, contact, category, etc.) is used to create a ledger entry.
/// The status field tracks the processing lifecycle from pending through completion.
struct SnapClerk: Codable, Identifiable {
    /// The unique identifier for the SnapClerk submission, assigned by the API.
    var Id: Int = 0

    /// The ID of the account this SnapClerk submission belongs to.
    var AccountId: Int = 0

    /// The current processing status of the submission.
    /// Common values: "pending", "success", "complete", "rejected", "error".
    var Status: String = ""

    /// The uploaded file (image or document) associated with this submission.
    var File: FileModel = FileModel()

    /// The ID of the ledger entry created from this submission after successful processing.
    /// A value of 0 indicates no ledger entry has been created yet.
    var LedgerId: Int = 0

    /// The extracted or manually entered monetary amount from the receipt.
    var Amount: Double = 0.0

    /// The extracted or manually entered contact/vendor name from the receipt.
    var Contact: String = ""

    /// The extracted or manually entered category name for the transaction.
    var Category: String = ""

    /// A comma-separated string of label names to apply to the resulting ledger entry.
    var Labels: String = ""

    /// An optional note or memo to attach to the resulting ledger entry.
    var Note: String = ""

    /// The latitude coordinate as a string, representing where the receipt was captured.
    var Lat: String = ""

    /// The longitude coordinate as a string, representing where the receipt was captured.
    var Lon: String = ""

    /// The ISO 8601 timestamp of when this submission was created.
    var CreatedAt: String = ""

    /// The ISO 8601 timestamp of when this submission was processed.
    /// Empty if processing has not yet completed.
    var ProcessedAt: String = ""

    enum CodingKeys: String, CodingKey {
        case Id = "id"
        case AccountId = "account_id"
        case Status = "status"
        case File = "file"
        case LedgerId = "ledger_id"
        case Amount = "amount"
        case Contact = "contact"
        case Category = "category"
        case Labels = "labels"
        case Note = "note"
        case Lat = "lat"
        case Lon = "lon"
        case CreatedAt = "created_at"
        case ProcessedAt = "processed_at"
    }

    /// Computed property to satisfy the Identifiable protocol using the API's Id field.
    var id: Int { Id }

    /// Parses the CreatedAt string into a native Swift Date object.
    /// Expects the ISO 8601 format "yyyy-MM-dd'T'HH:mm:ss'Z'" with UTC timezone.
    /// Returns nil if the date string cannot be parsed.
    var createdDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: CreatedAt)
    }

    /// Returns a StatusColor enum value based on the current processing status.
    /// Used to visually indicate the state of the submission in the UI:
    /// - .warning (yellow/orange) for pending items
    /// - .danger (red) for rejected or errored items
    /// - .success (green) for successfully processed items
    var statusColor: StatusColor {
        switch Status.lowercased() {
        case "pending": return .warning
        case "rejected", "error": return .danger
        case "success", "complete": return .success
        default: return .warning
        }
    }

    /// Represents the visual color state for a SnapClerk submission's status indicator.
    enum StatusColor {
        /// Yellow/orange color indicating the submission is still being processed.
        case warning

        /// Red color indicating the submission was rejected or encountered an error.
        case danger

        /// Green color indicating the submission was successfully processed.
        case success
    }
}
