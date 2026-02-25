//
// AccountService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Service responsible for managing account-level operations in the Skyclerk API.
/// Handles fetching, updating, and deleting the current account, as well as
/// retrieving billing/subscription information.
/// Communicates with the /api/v3/{accountId}/account endpoints.
class AccountService {
    /// Shared singleton instance used throughout the app.
    nonisolated(unsafe) static let shared = AccountService()

    /// Private initializer to enforce singleton usage via AccountService.shared.
    private init() {}

    /// Fetches the current account's details from the API.
    /// Returns the Account model with name, currency, locale, and owner information.
    ///
    /// - Returns: The Account object for the currently active account.
    /// - Throws: APIError if the request fails or the response cannot be decoded.
    func getAccount() async throws -> Account {
        let url = APIService.shared.accountURL("account")
        let account: Account = try await APIService.shared.get(url: url)
        return account
    }

    /// Updates the current account's settings (name, currency, locale, etc.).
    /// Sends the full Account object as JSON to the API which returns the updated account.
    ///
    /// - Parameter account: The Account object with updated fields to save.
    /// - Returns: The updated Account object as returned by the server.
    /// - Throws: APIError if the request fails (e.g., validation error) or the response cannot be decoded.
    func updateAccount(account: Account) async throws -> Account {
        let url = APIService.shared.accountURL("account")
        let updated: Account = try await APIService.shared.put(url: url, body: account)
        return updated
    }

    /// Permanently deletes the current account and all associated data.
    /// This action is irreversible. The user will be logged out after deletion.
    /// Sends a POST request to the account/delete endpoint.
    ///
    /// - Throws: APIError if the request fails (e.g., permission denied, server error).
    func deleteAccount() async throws {
        let url = APIService.shared.accountURL("account/delete")
        try await APIService.shared.postEmpty(url: url)
    }

    /// Fetches the billing and subscription information for the current account.
    /// Returns details about the current plan, payment status, and subscription dates.
    ///
    /// - Returns: A Billing object with the account's subscription and payment details.
    /// - Throws: APIError if the request fails or the response cannot be decoded.
    func getBilling() async throws -> Billing {
        let url = APIService.shared.accountURL("account/billing")
        let billing: Billing = try await APIService.shared.get(url: url)
        return billing
    }
}
