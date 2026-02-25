//
// MeService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Intermediate model for decoding the /oauth/me response which returns snake_case JSON keys.
/// The account-scoped endpoints return PascalCase keys, but /oauth/me is an OAuth endpoint
/// that uses a different serialization format. This struct maps the snake_case keys and is
/// then converted to the standard User and Account models used throughout the app.
private struct MeResponse: Decodable {
    let id: Int
    let first_name: String
    let last_name: String
    let email: String
    let accounts: [MeAccountResponse]
}

/// Intermediate model for decoding account objects within the /oauth/me response.
/// Maps snake_case JSON keys from the OAuth endpoint to local properties, which are
/// then converted to the standard Account model used throughout the app.
private struct MeAccountResponse: Decodable {
    let id: Int
    let owner_id: Int
    let name: String
    let locale: String
    let currency: String
}

/// Request body for updating the user's profile information.
/// Sent as JSON to the PUT /me endpoint.
private struct UpdateProfileRequest: Encodable {
    let FirstName: String
    let LastName: String
    let Email: String
}

/// Request body for changing the user's password.
/// Sent as JSON to the POST /me/change-password endpoint.
private struct ChangePasswordRequest: Encodable {
    let CurrentPassword: String
    let Password: String
    let ConfirmPassword: String
}

/// Service responsible for fetching and updating the current user's profile information.
/// Communicates with the /oauth/me and /api/v3/{accountId}/me endpoints.
class MeService {
    /// Shared singleton instance used throughout the app.
    nonisolated(unsafe) static let shared = MeService()

    /// Private initializer to enforce singleton usage via MeService.shared.
    private init() {}

    /// Fetches the currently authenticated user's profile from the API.
    /// Calls GET /oauth/me which returns the user's profile with their accounts list.
    /// The /oauth/me endpoint returns snake_case JSON keys (unlike the account-scoped
    /// endpoints which use PascalCase), so this method decodes into an intermediate
    /// MeResponse struct and then maps it to the standard User and Account models.
    /// This is typically called after login to determine which accounts the user has access to.
    ///
    /// - Returns: A User object containing the user's profile and their list of accounts.
    /// - Throws: APIError if the request fails or the response cannot be decoded.
    func getMe() async throws -> User {
        let url = "\(AppEnvironment.appServer)/oauth/me"
        let response: MeResponse = try await APIService.shared.get(url: url)

        // Map the snake_case MeResponse to the PascalCase User and Account models
        // used throughout the rest of the app.
        var user = User()
        user.Id = response.id
        user.Email = response.email
        user.FirstName = response.first_name
        user.LastName = response.last_name
        user.Accounts = response.accounts.map { acct in
            var account = Account()
            account.Id = acct.id
            account.OwnerId = acct.owner_id
            account.Name = acct.name
            account.Locale = acct.locale
            account.Currency = acct.currency
            return account
        }

        return user
    }

    /// Updates the current user's profile information (first name, last name, email).
    /// Sends a PUT request to /api/v3/{accountId}/me with the updated fields.
    ///
    /// - Parameters:
    ///   - firstName: The updated first name.
    ///   - lastName: The updated last name.
    ///   - email: The updated email address.
    /// - Throws: APIError if the request fails (e.g., email already in use, validation error).
    func updateProfile(firstName: String, lastName: String, email: String) async throws {
        let url = APIService.shared.accountURL("me")
        let body = UpdateProfileRequest(FirstName: firstName, LastName: lastName, Email: email)
        let _: User = try await APIService.shared.put(url: url, body: body)
    }

    /// Changes the current user's password.
    /// Sends a POST request to /api/v3/{accountId}/me/change-password with the current
    /// password for verification and the new password with confirmation.
    ///
    /// - Parameters:
    ///   - currentPassword: The user's current password for verification.
    ///   - newPassword: The new password to set.
    ///   - confirmPassword: Confirmation of the new password (must match newPassword).
    /// - Throws: APIError if the request fails (e.g., current password is wrong, passwords don't match).
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) async throws {
        let url = APIService.shared.accountURL("me/change-password")
        let body = ChangePasswordRequest(
            CurrentPassword: currentPassword,
            Password: newPassword,
            ConfirmPassword: confirmPassword
        )
        try await APIService.shared.post(url: url, body: body) as Void
    }
}
