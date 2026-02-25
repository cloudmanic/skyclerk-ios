//
// LedgerRowView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// A single row in the ledger list that displays a financial transaction entry.
/// Shows the transaction date on the left, the contact name and category in the
/// middle, and the formatted currency amount on the right. The entire row is
/// wrapped in a NavigationLink so tapping it navigates to the ledger detail view.
/// Expense amounts are displayed in red, while income amounts use default white text.
struct LedgerRowView: View {
    /// The ledger entry to display in this row. Contains the date, amount,
    /// contact, category, and all other transaction details.
    let ledger: Ledger

    /// The main view body. Lays out the date, contact/category, and amount
    /// in a horizontal stack with proportional widths. Wraps everything in
    /// a NavigationLink targeting the LedgerViewPage detail screen.
    var body: some View {
        NavigationLink(destination: LedgerViewPage(ledger: ledger)) {
            HStack(alignment: .center, spacing: 8) {
                // Left column: Transaction date formatted as "MMM dd\nyyyy".
                dateColumn

                // Middle column: Contact display name on top, category name below.
                contactColumn

                // Right column: Currency amount, colored red for expenses.
                amountColumn
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }

    /// The date column displayed on the left side of the row (~25% width).
    /// Parses the ledger's date string and formats it as a two-line display
    /// with month/day on the first line and year on the second line.
    /// Falls back to showing the raw date string if parsing fails.
    private var dateColumn: some View {
        Text(ledger.formattedDate?.toLedgerDisplay() ?? ledger.LedgerDate)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(Color.appTextGray)
            .multilineTextAlignment(.center)
            .frame(width: 65, alignment: .center)
    }

    /// The contact and category column displayed in the center of the row (~50% width).
    /// Shows the contact display name (vendor/payee) prominently on top, with the
    /// category name in smaller, lighter text below it. Both are left-aligned.
    private var contactColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Contact display name (vendor or payee).
            Text(ledger.contactDisplayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            // Category name in smaller gray text.
            if !ledger.LedgerCategory.Name.isEmpty {
                Text(ledger.LedgerCategory.Name)
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextLightGray)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The amount column displayed on the right side of the row (~25% width).
    /// Formats the ledger amount as a currency string using the Double.toCurrency()
    /// extension. Negative amounts (expenses) are displayed in the app's danger (red)
    /// color, while positive amounts (income) use the app's success (green) color.
    private var amountColumn: some View {
        Text(ledger.Amount.toCurrency())
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(ledger.Amount < 0 ? Color.appDanger : Color.appSuccess)
            .frame(width: 90, alignment: .trailing)
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: 0) {
            LedgerRowView(ledger: Ledger(
                Id: 1,
                LedgerDate: "2026-02-25",
                Amount: 150.00,
                LedgerContact: Contact(Name: "Acme Corp"),
                LedgerCategory: Category(Name: "Sales Revenue")
            ))

            Divider().background(Color.appBgDarkGray)

            LedgerRowView(ledger: Ledger(
                Id: 2,
                LedgerDate: "2026-02-24",
                Amount: -45.99,
                LedgerContact: Contact(Name: "Office Depot"),
                LedgerCategory: Category(Name: "Office Supplies")
            ))
        }
        .background(Color.appDark)
    }
}
