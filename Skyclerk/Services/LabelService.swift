//
// LabelService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Request body for creating a new label.
/// Sent as JSON to the POST /labels endpoint.
private struct CreateLabelRequest: Encodable {
    let Name: String
}

/// Service responsible for managing labels (tags) in the Skyclerk API.
/// Labels are used to tag ledger entries for additional organization beyond categories.
/// For example, a user might label entries as "Tax Deductible" or "Q1 2026".
class LabelService {
    /// Shared singleton instance used throughout the app.
    nonisolated(unsafe) static let shared = LabelService()

    /// Private initializer to enforce singleton usage via LabelService.shared.
    private init() {}

    /// Fetches all labels for the current account.
    /// Labels are used in ledger entry forms and filters. The full list is
    /// fetched at once since accounts typically have a manageable number of labels.
    ///
    /// - Returns: An array of LedgerLabel objects for the current account.
    /// - Throws: APIError if the request fails or the response cannot be decoded.
    func getLabels() async throws -> [LedgerLabel] {
        let url = APIService.shared.accountURL("labels")
        let labels: [LedgerLabel] = try await APIService.shared.get(url: url)
        return labels
    }

    /// Creates a new label with the given name in the current account.
    /// Used when the user wants to add a new tag that doesn't exist yet,
    /// typically from within a ledger entry form.
    ///
    /// - Parameter name: The display name for the new label.
    /// - Returns: The newly created LedgerLabel object with its server-assigned ID.
    /// - Throws: APIError if the request fails (e.g., duplicate name, validation error) or the response cannot be decoded.
    func createLabel(name: String) async throws -> LedgerLabel {
        let url = APIService.shared.accountURL("labels")
        let body = CreateLabelRequest(Name: name)
        let label: LedgerLabel = try await APIService.shared.post(url: url, body: body)
        return label
    }
}
