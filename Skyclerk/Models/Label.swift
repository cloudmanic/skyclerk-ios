//
// Label.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Label represents a tag that can be applied to ledger entries for additional
/// organization and filtering. Labels belong to an account and a single ledger
/// entry can have multiple labels attached to it. They provide a flexible way
/// to categorize transactions beyond the primary category system.
struct LedgerLabel: Codable, Identifiable, Hashable {
    /// The unique identifier for the label, assigned by the API.
    var Id: Int = 0

    /// The ID of the account this label belongs to.
    var AccountId: Int = 0

    /// The display name of the label (e.g., "Tax Deductible", "Q1 2026", "Client Project").
    var Name: String = ""

    enum CodingKeys: String, CodingKey {
        case Id = "id"
        case AccountId = "account_id"
        case Name = "name"
    }

    /// Computed property to satisfy the Identifiable protocol using the API's Id field.
    var id: Int { Id }
}
