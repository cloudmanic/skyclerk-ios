//
// Account.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Account represents a Skyclerk account (workspace) that a user belongs to.
/// Each account has its own set of ledger entries, contacts, categories, labels, and files.
/// A user may belong to multiple accounts and can switch between them.
struct Account: Codable, Identifiable, Hashable {
    /// The unique identifier for the account, assigned by the API.
    var Id: Int = 0

    /// The display name of the account (e.g., "My Business", "Personal Finances").
    var Name: String = ""

    /// The user ID of the account owner. The owner has full administrative privileges.
    var OwnerId: Int = 0

    /// The locale setting for the account, used for number and date formatting (e.g., "en-US").
    var Locale: String = "en-US"

    /// The ISO 4217 currency code used by this account (e.g., "USD", "EUR", "GBP").
    var Currency: String = "USD"

    enum CodingKeys: String, CodingKey {
        case Id = "id"
        case Name = "name"
        case OwnerId = "owner_id"
        case Locale = "locale"
        case Currency = "currency"
    }

    /// Computed property to satisfy the Identifiable protocol using the API's Id field.
    var id: Int { Id }
}
