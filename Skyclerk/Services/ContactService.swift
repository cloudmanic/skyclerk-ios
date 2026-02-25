//
// ContactService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Service responsible for managing contacts (payees and payers).
/// Handles fetching and creating contacts via the /api/v3/{accountId}/contacts endpoints.
class ContactService {
    /// Shared singleton instance used throughout the app.
    nonisolated(unsafe) static let shared = ContactService()

    /// Private initializer to enforce singleton usage via ContactService.shared.
    private init() {}

    /// Fetches the list of contacts for the current account.
    /// Requests up to 500 contacts by default and supports optional text search filtering.
    /// The large limit is used because contacts are typically shown in a picker/autocomplete
    /// and the total number per account is usually manageable.
    ///
    /// - Parameter search: Optional search query to filter contacts by name or email. Pass nil for all contacts.
    /// - Returns: An array of Contact objects for the current account.
    /// - Throws: APIError if the request fails or the response cannot be decoded.
    func getContacts(search: String? = nil) async throws -> [Contact] {
        let url = APIService.shared.accountURL("contacts")

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "500")
        ]

        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        let contacts: [Contact] = try await APIService.shared.get(url: url, queryItems: queryItems)
        return contacts
    }

    /// Creates a new contact in the current account.
    /// Sends the Contact object as JSON to the API which returns the created contact
    /// with its server-assigned ID.
    ///
    /// - Parameter contact: The Contact object to create. The Id field is ignored by the server.
    /// - Returns: The newly created Contact object with its server-assigned ID.
    /// - Throws: APIError if the request fails (e.g., validation error) or the response cannot be decoded.
    func createContact(contact: Contact) async throws -> Contact {
        let url = APIService.shared.accountURL("contacts")
        let created: Contact = try await APIService.shared.post(url: url, body: contact)
        return created
    }
}
