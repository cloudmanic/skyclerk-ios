//
// Ledger.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Ledger represents a single financial transaction entry (income or expense).
/// Each ledger entry belongs to an account and contains details about the transaction
/// including the amount, date, associated contact, category, labels, and attached files.
/// This is the core data model for tracking finances in Skyclerk.
struct Ledger: Codable, Identifiable {
    /// The unique identifier for the ledger entry, assigned by the API.
    var Id: Int = 0

    /// The ID of the account this ledger entry belongs to.
    var AccountId: Int = 0

    /// The date of the transaction as an ISO date string from the API.
    /// This will be parsed into a native Date object via the formattedDate computed property.
    /// Named LedgerDate in Swift to avoid conflict with Foundation.Date,
    /// but maps to "Date" in JSON via CodingKeys.
    var LedgerDate: String = ""

    /// The monetary amount of the transaction. Positive values represent income,
    /// negative values represent expenses (depending on the category type).
    var Amount: Double = 0.0

    /// An optional note or memo attached to this transaction for additional context.
    var Note: String = ""

    /// The latitude coordinate of the location where the transaction occurred.
    /// A value of 0.0 indicates no location was recorded.
    var Lat: Double = 0.0

    /// The longitude coordinate of the location where the transaction occurred.
    /// A value of 0.0 indicates no location was recorded.
    var Lon: Double = 0.0

    /// The contact (payee or payer) associated with this transaction.
    /// Named LedgerContact in Swift to avoid shadowing the Contact type,
    /// but maps to "Contact" in JSON via CodingKeys.
    var LedgerContact: Contact = .init()

    /// The category assigned to this transaction (e.g., "Rent", "Sales Revenue").
    /// Named LedgerCategory in Swift to avoid shadowing the Category type,
    /// but maps to "Category" in JSON via CodingKeys.
    var LedgerCategory: Category = .init()

    /// A list of labels (tags) applied to this transaction for additional organization.
    var Labels: [LedgerLabel] = []

    /// A list of files (receipts, invoices, etc.) attached to this transaction.
    var Files: [FileModel] = []

    /// CodingKeys maps Swift property names to JSON field names from the API.
    /// Several properties are renamed in Swift to avoid shadowing their type names,
    /// but they still decode from and encode to the original API field names.
    enum CodingKeys: String, CodingKey {
        case Id = "id"
        case AccountId = "account_id"
        case LedgerDate = "date"
        case Amount = "amount"
        case Note = "note"
        case Lat = "lat"
        case Lon = "lon"
        case LedgerContact = "contact"
        case LedgerCategory = "category"
        case Labels = "labels"
        case Files = "files"
    }

    /// Computed property to satisfy the Identifiable protocol using the API's Id field.
    var id: Int { Id }

    /// Parses the LedgerDate string from the API into a native Swift Date object.
    /// Supports multiple date formats returned by the API:
    /// - ISO 8601 with fractional seconds: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    /// - ISO 8601 without fractional seconds: "yyyy-MM-dd'T'HH:mm:ss'Z'"
    /// - Simple date format: "yyyy-MM-dd"
    /// Returns nil if the date string cannot be parsed by any known format.
    var formattedDate: Foundation.Date? {
        let formatters: [DateFormatter] = {
            let f1 = DateFormatter()
            f1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            f1.timeZone = TimeZone(abbreviation: "UTC")
            let f2 = DateFormatter()
            f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            f2.timeZone = TimeZone(abbreviation: "UTC")
            let f3 = DateFormatter()
            f3.dateFormat = "yyyy-MM-dd"
            return [f1, f2, f3]
        }()
        for formatter in formatters {
            if let date = formatter.date(from: self.LedgerDate) {
                return date
            }
        }
        return nil
    }

    /// Returns a human-readable display name for the associated contact.
    /// Prefers the contact's Name field. If that is empty, falls back to
    /// combining FirstName and LastName, filtering out any empty parts.
    var contactDisplayName: String {
        if !LedgerContact.Name.isEmpty {
            return LedgerContact.Name
        }
        let parts = [LedgerContact.FirstName, LedgerContact.LastName].filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }
}
