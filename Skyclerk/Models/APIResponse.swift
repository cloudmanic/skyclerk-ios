//
// APIResponse.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// LoginResponse represents the API response after a successful authentication.
/// Contains the authenticated user's ID and an access token for subsequent API requests.
struct LoginResponse: Codable {
    /// The unique identifier of the authenticated user.
    var user_id: Int

    /// The bearer token used to authenticate subsequent API requests.
    /// This token should be stored securely and included in the Authorization header.
    var access_token: String
}

/// RegisterResponse represents the API response after a successful account registration.
/// Contains the new user's ID, an access token, and the ID of the newly created account.
struct RegisterResponse: Codable {
    /// The unique identifier of the newly created user.
    var user_id: Int

    /// The bearer token used to authenticate subsequent API requests.
    /// This token should be stored securely and included in the Authorization header.
    var access_token: String

    /// The unique identifier of the newly created account associated with this user.
    var account_id: Int
}

/// PnlCurrentYear represents the profit and loss summary value for a specific year.
/// Used on the dashboard to display the current year's financial performance at a glance.
struct PnlCurrentYear: Codable {
    /// The year this P&L value represents (e.g., 2026).
    var Year: Int = 0

    /// The net profit or loss value for the year. Positive values indicate profit,
    /// negative values indicate loss.
    var Value: Double = 0.0

    enum CodingKeys: String, CodingKey {
        case Year = "year"
        case Value = "value"
    }
}
