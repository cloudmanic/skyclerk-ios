//
// Contact.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Contact represents a payee or payer associated with ledger entries.
/// Contacts belong to an account and can be referenced by multiple ledger entries.
/// They support both a single Name field and split FirstName/LastName fields
/// to accommodate different naming conventions.
struct Contact: Codable, Identifiable, Hashable {
    /// The unique identifier for the contact, assigned by the API.
    var Id: Int = 0

    /// The ID of the account this contact belongs to.
    var AccountId: Int = 0

    /// The full name or business name of the contact (e.g., "Acme Corp", "John Doe").
    /// This is the primary name field and is preferred over FirstName/LastName when available.
    var Name: String = ""

    /// The first name of the contact, used when names are split into parts.
    var FirstName: String = ""

    /// The last name of the contact, used when names are split into parts.
    var LastName: String = ""

    /// The email address of the contact.
    var Email: String = ""

    enum CodingKeys: String, CodingKey {
        case Id = "id"
        case AccountId = "account_id"
        case Name = "name"
        case FirstName = "first_name"
        case LastName = "last_name"
        case Email = "email"
    }

    /// Computed property to satisfy the Identifiable protocol using the API's Id field.
    var id: Int { Id }

    /// Returns the best available display name for this contact.
    /// Prefers the Name field if it is not empty. Otherwise, combines
    /// FirstName and LastName, filtering out any empty parts and joining with a space.
    var displayName: String {
        if !Name.isEmpty { return Name }
        let parts = [FirstName, LastName].filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }
}
