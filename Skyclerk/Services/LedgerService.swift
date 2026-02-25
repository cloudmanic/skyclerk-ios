//
// LedgerService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Service responsible for managing ledger entries (financial transactions).
/// Handles CRUD operations against the /api/v3/{accountId}/ledger endpoints.
/// Publishes the current list of ledgers and pagination state for SwiftUI views.
@MainActor
class LedgerService: ObservableObject {
    /// Shared singleton instance used throughout the app.
    static let shared = LedgerService()

    /// The currently loaded list of ledger entries. Published so views can
    /// reactively display the list as it changes.
    @Published var ledgers: [Ledger] = []

    /// Whether the most recently fetched page was the last page of results.
    /// Used by views to determine if more data should be loaded on scroll.
    @Published var isLastPage = false

    /// Private initializer to enforce singleton usage via LedgerService.shared.
    private init() {}

    /// Fetches a paginated list of ledger entries from the API.
    /// Supports filtering by transaction type (income/expense) and text search.
    /// The API returns pagination info via the X-Last-Page response header.
    ///
    /// - Parameters:
    ///   - page: The page number to fetch (1-indexed).
    ///   - type: Optional transaction type filter (e.g., "Expense", "Income"). Pass nil for all types.
    ///   - search: Optional search query to filter ledger entries by contact name, note, or category.
    /// - Returns: A tuple containing the array of Ledger objects and a boolean indicating if this is the last page.
    /// - Throws: APIError if the request fails or the response cannot be decoded.
    func getLedgers(page: Int, type: String?, search: String?) async throws -> (ledgers: [Ledger], lastPage: Bool) {
        let url = APIService.shared.accountURL("ledger")

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page))
        ]

        if let type = type, !type.isEmpty {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }

        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        let response: PaginatedResponse<[Ledger]> = try await APIService.shared.getPaginated(url: url, queryItems: queryItems)

        self.isLastPage = response.isLastPage

        return (ledgers: response.data, lastPage: response.isLastPage)
    }

    /// Fetches a single ledger entry by its ID.
    /// Used when navigating to a ledger detail view or refreshing a specific entry.
    ///
    /// - Parameter id: The unique identifier of the ledger entry to fetch.
    /// - Returns: The Ledger object matching the given ID.
    /// - Throws: APIError if the request fails, the entry is not found, or the response cannot be decoded.
    func getLedger(id: Int) async throws -> Ledger {
        let url = APIService.shared.accountURL("ledger/\(id)")
        let ledger: Ledger = try await APIService.shared.get(url: url)
        return ledger
    }

    /// Creates a new ledger entry in the current account.
    /// Sends the full Ledger object as JSON to the API which returns the created entry
    /// with its server-assigned ID and any server-computed fields.
    ///
    /// - Parameter ledger: The Ledger object to create. The Id field is ignored by the server.
    /// - Returns: The newly created Ledger object with its server-assigned ID.
    /// - Throws: APIError if the request fails (e.g., validation error) or the response cannot be decoded.
    func createLedger(ledger: Ledger) async throws -> Ledger {
        let url = APIService.shared.accountURL("ledger")
        let created: Ledger = try await APIService.shared.post(url: url, body: ledger)
        return created
    }

    /// Deletes a ledger entry by its ID from the current account.
    /// This is a permanent deletion and cannot be undone.
    ///
    /// - Parameter id: The unique identifier of the ledger entry to delete.
    /// - Throws: APIError if the request fails (e.g., entry not found, permission denied).
    func deleteLedger(id: Int) async throws {
        let url = APIService.shared.accountURL("ledger/\(id)")
        try await APIService.shared.delete(url: url)
    }
}
