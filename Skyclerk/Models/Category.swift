//
// Category.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Category represents a financial category used to classify ledger entries.
/// Categories belong to an account and are either income or expense types.
/// The API may return the Type field as either a numeric string ("1" for income,
/// "2" for expense) or a descriptive string ("income", "expense"). This model
/// normalizes both formats via computed properties.
struct Category: Codable, Identifiable, Hashable {
    /// The unique identifier for the category, assigned by the API.
    var Id: Int = 0

    /// The ID of the account this category belongs to.
    var AccountId: Int = 0

    /// The display name of the category (e.g., "Rent", "Sales Revenue", "Office Supplies").
    var Name: String = ""

    /// The type of category as returned by the API. This can be either a numeric
    /// string ("1" for income, "2" for expense) or a descriptive string ("income", "expense").
    /// Use the typeLabel, isIncome, and isExpense computed properties for normalized access.
    /// Named categoryType in Swift to avoid conflict with the reserved .Type expression,
    /// but maps to "Type" in JSON via CodingKeys.
    var categoryType: String = ""

    /// CodingKeys maps Swift property names to JSON field names from the API.
    /// The "Type" JSON field is mapped to categoryType to avoid Swift naming conflicts.
    enum CodingKeys: String, CodingKey {
        case Id = "id"
        case AccountId = "account_id"
        case Name = "name"
        case categoryType = "type"
    }

    /// Computed property to satisfy the Identifiable protocol using the API's Id field.
    var id: Int { Id }

    /// Returns a normalized string label for the category type.
    /// Maps both numeric ("1", "2") and string ("income", "expense") API values
    /// to a consistent lowercase label. Returns the raw categoryType value as a fallback
    /// for any unexpected values.
    var typeLabel: String {
        switch categoryType {
        case "1", "income": return "income"
        case "2", "expense": return "expense"
        default: return categoryType
        }
    }

    /// Returns true if this category represents an income type.
    var isIncome: Bool { typeLabel == "income" }

    /// Returns true if this category represents an expense type.
    var isExpense: Bool { typeLabel == "expense" }
}
