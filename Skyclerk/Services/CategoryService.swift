//
// CategoryService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Service responsible for fetching categories from the Skyclerk API.
/// Categories are used to classify ledger entries (e.g., "Rent", "Sales Revenue", "Office Supplies").
/// Categories are read-only from the mobile app; they are managed via the web interface.
class CategoryService {
    /// Shared singleton instance used throughout the app.
    nonisolated(unsafe) static let shared = CategoryService()

    /// Private initializer to enforce singleton usage via CategoryService.shared.
    private init() {}

    /// Fetches all categories for the current account.
    /// Categories are used in ledger entry forms and filters. The full list is
    /// fetched at once since accounts typically have a manageable number of categories.
    ///
    /// - Returns: An array of Category objects for the current account.
    /// - Throws: APIError if the request fails or the response cannot be decoded.
    func getCategories() async throws -> [Category] {
        let url = APIService.shared.accountURL("categories")
        let categories: [Category] = try await APIService.shared.get(url: url)
        return categories
    }
}
