//
// LedgerRowView.swift
//
// Created on 2026-02-25.
// Copyright 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// A single row in the ledger list that displays a financial transaction entry.
/// Matches the Ionic app-ledger-list row styling exactly:
/// - 3-column layout: date (col-2), vendor/category (col-6), amount (remaining)
/// - Date column: month/day in <small> text on the first line, year below, font-weight 500, size 15px
/// - Vendor column: contact name in #606060 14px, category name in <small><a> #1181c3 ~13px
/// - Amount column: inset shadow box (#eaeaea background, rounded 4px, semibold 16px text),
///   with a small colored circle indicator (green #698451 for income, red #b7433f for expense)
/// - Row text color is dark (not white) since rows have white/light gray backgrounds
/// The entire row is wrapped in a NavigationLink for tap navigation to the detail view.
struct LedgerRowView: View {
    /// The ledger entry to display in this row. Contains the date, amount,
    /// contact, category, and all other transaction details.
    let ledger: Ledger

    /// The main view body. Lays out the date, contact/category, and amount
    /// in a horizontal stack matching the Ionic 2/6/4 column proportions.
    /// Wraps everything in a NavigationLink targeting the LedgerViewPage detail screen.
    var body: some View {
        NavigationLink(destination: LedgerViewPage(ledger: ledger)) {
            HStack(alignment: .center, spacing: 0) {
                // Left column (size="2"): Transaction date formatted as "MMM dd\nyyyy".
                dateColumn
                    .frame(width: 55)
                    .padding(.leading, 12)

                // Middle column (size="6", class="size-sm"): Contact name and category.
                contactColumn
                    .padding(.leading, 8)
                    .padding(.trailing, 4)

                Spacer()

                // Right column (text-right): Currency amount in inset shadow box.
                amountColumn
                    .padding(.trailing, 12)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    /// The date column displayed on the left side of the row.
    /// Parses the ledger's date string and formats it as a two-line display
    /// matching the Ionic format: "MMM dd" in <small> text on top, "yyyy" below.
    /// The <small> tag in HTML renders at ~80% of parent size, so month/day is ~11px
    /// while the year uses the full .date class size of 15px weight 500.
    private var dateColumn: some View {
        VStack(spacing: 1) {
            if let date = ledger.formattedDate {
                Text(formatMonthDay(date))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "333333"))
                Text(formatYear(date))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
            } else {
                Text(ledger.LedgerDate)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black)
            }
        }
    }

    /// The contact and category column displayed in the center of the row.
    /// Shows the contact display name (vendor) in #606060 color at 14px,
    /// with the category name below in #1181c3 (link blue) at ~13px.
    /// The Ionic wraps the category in <small><a>, which renders slightly smaller
    /// than the base 14px row font. Matches the Ionic .vendor class styling.
    private var contactColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Contact display name (vendor or payee) in gray.
            Text(ledger.contactDisplayName)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "606060"))
                .lineLimit(1)

            // Category name in link blue (#1181c3) matching the Ionic <small><a> styling.
            if !ledger.LedgerCategory.Name.isEmpty {
                Text(ledger.LedgerCategory.Name)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "1181c3"))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The amount column displayed on the right side of the row.
    /// Renders the currency amount inside an inset shadow-style box (#eaeaea background)
    /// with a small colored circle indicator on the right edge. Green circle (#698451) for
    /// income (positive amounts), red circle and red text (#b7433f) for expenses (negative).
    /// The box has rounded corners (4px), font-weight 600, font-size 16px, and text-align right.
    /// Includes white text-shadow matching Ionic $t_shadow_white.
    /// Matches the Ionic .amount class with its :before pseudo-element for the indicator dot.
    private var amountColumn: some View {
        ZStack(alignment: .trailing) {
            // Amount text inside the inset shadow box matching Ionic styling:
            // background #eaeaea, inset box-shadow rgba(0,0,0,0.33), border-radius 4px,
            // text-shadow 0px 1px 0px rgba(255,255,255,0.4).
            Text(ledger.Amount.toCurrency())
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ledger.Amount < 0 ? Color(hex: "b7433f") : Color(hex: "606060"))
                .shadow(color: Color.white.opacity(0.4), radius: 0, x: 0, y: 1)
                .padding(.vertical, 7)
                .padding(.leading, 5)
                .padding(.trailing, 15)
                .frame(minWidth: 80, alignment: .trailing)
                .background(Color(hex: "eaeaea"))
                .cornerRadius(4)
                .overlay(
                    // Simulate inset shadow: dark gradient at the top fading down,
                    // matching Ionic inset 0px 2px 3px 0px rgba(0,0,0,0.33).
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.black.opacity(0.2), Color.clear],
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: 0.4)
                            )
                        )
                        .allowsHitTesting(false)
                )

            // Colored circle indicator on the right edge of the box.
            // Matches Ionic :before pseudo-element: right: -8px, 16x16, border-radius 50%.
            Circle()
                .fill(ledger.Amount < 0 ? Color(hex: "b7433f") : Color(hex: "698451"))
                .frame(width: 16, height: 16)
                .offset(x: 8)
        }
    }

    /// Formats a Date as "MMM dd" for the top line of the date column.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A string like "Feb 25".
    private func formatMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }

    /// Formats a Date as "yyyy" for the bottom line of the date column.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A string like "2026".
    private func formatYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
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
            .background(Color.white)

            LedgerRowView(ledger: Ledger(
                Id: 2,
                LedgerDate: "2026-02-24",
                Amount: -45.99,
                LedgerContact: Contact(Name: "Office Depot"),
                LedgerCategory: Category(Name: "Office Supplies")
            ))
            .background(Color(hex: "f7f7f7"))

            LedgerRowView(ledger: Ledger(
                Id: 3,
                LedgerDate: "2026-01-15",
                Amount: 1250.00,
                LedgerContact: Contact(FirstName: "John", LastName: "Smith"),
                LedgerCategory: Category(Name: "Consulting Income")
            ))
            .background(Color.white)
        }
    }
}
