//
// AccountPickerView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// A searchable account picker modal presented as a sheet from HomeView.
/// Displays a dark-themed list of accounts that can be filtered by typing in the
/// search bar. The currently active account is indicated with a checkmark.
/// Tapping an account row selects it and dismisses the sheet.
/// The styling matches the app's dark card aesthetic with #232323 background,
/// #2a2a2a row backgrounds, white text, and white search input field.
struct AccountPickerView: View {
    /// The full list of accounts to display and search through.
    let accounts: [Account]

    /// The currently active account ID, used to show a checkmark indicator.
    let currentAccountId: Int

    /// Callback closure invoked when the user selects an account.
    /// Passes the selected Account object back to the parent view.
    let onSelect: (Account) -> Void

    /// Dismiss action to close this sheet when the user cancels.
    @Environment(\.dismiss) private var dismiss

    /// The search text entered by the user to filter the accounts list.
    /// Filtering is case-insensitive on the account's Name.
    @State private var searchText: String = ""

    // MARK: - Colors

    /// Modal background color (#232323).
    private let bgColor = Color(hex: "232323")

    /// Row background color (#2a2a2a).
    private let rowBgColor = Color(hex: "2a2a2a")

    /// Active/selected row background color (#474747).
    private let activeRowBgColor = Color(hex: "474747")

    /// Label text color (#bcbcbc) for the title and helper text.
    private let labelColor = Color(hex: "bcbcbc")

    // MARK: - Computed Properties

    /// Returns the accounts filtered by the search text.
    /// When the search text is empty, all accounts are returned.
    /// Otherwise, accounts are filtered by a case-insensitive match on Name.
    private var filteredAccounts: [Account] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return accounts
        }
        return accounts.filter {
            $0.Name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Body

    /// The main view body. Renders a dark modal with a centered title,
    /// a white search input field, a scrollable list of account rows,
    /// and a cancel button at the bottom.
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            titleSection

            // Search input field
            searchField
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

            // Scrollable account list
            accountList
                .padding(.horizontal, 16)

            Spacer()

            // Cancel button at the bottom
            cancelButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(bgColor.ignoresSafeArea())
    }

    // MARK: - Title Section

    /// Centered "Your Accounts" title matching the app's form title style.
    /// Uses 16px semibold text in the label gray color (#bcbcbc).
    private var titleSection: some View {
        Text("Your Accounts")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(labelColor)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 4)
    }

    // MARK: - Search Field

    /// A white-background text field for filtering accounts by name.
    /// Matches the app's standard input field style: white background,
    /// 42px height, 5px corner radius, 8px horizontal padding, black text.
    private var searchField: some View {
        TextField("Search accounts...", text: $searchText)
            .font(.system(size: 16))
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .frame(height: 42)
            .background(Color.white)
            .cornerRadius(5)
            .autocorrectionDisabled()
    }

    // MARK: - Account List

    /// A scrollable list of account rows filtered by the search text.
    /// Each row has a #2a2a2a background (or #474747 if active), white 16px text,
    /// 5px corner radius, and 5px spacing between rows. The active account shows
    /// a checkmark on the right. Tapping a row selects the account,
    /// fires the onSelect callback, and dismisses the sheet.
    private var accountList: some View {
        ScrollView {
            LazyVStack(spacing: 5) {
                ForEach(filteredAccounts) { account in
                    Button {
                        onSelect(account)
                        dismiss()
                    } label: {
                        accountRow(account: account)
                    }
                }
            }
        }
    }

    /// Builds a single account row matching the app's dark list row style.
    /// Shows the account's name in white 16px text with a checkmark for the
    /// currently active account. Active rows use a lighter background (#474747).
    ///
    /// - Parameter account: The Account to display in this row.
    /// - Returns: A styled row view for the account.
    private func accountRow(account: Account) -> some View {
        let isActive = account.Id == currentAccountId
        return HStack {
            Text(account.Name)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()

            if isActive {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isActive ? activeRowBgColor : rowBgColor)
        .cornerRadius(5)
    }

    // MARK: - Cancel Button

    /// A full-width cancel button at the bottom of the modal.
    /// Styled as a subtle dark button matching the app's aesthetic.
    /// Dismisses the sheet without selecting any account.
    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(labelColor)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(rowBgColor)
                .cornerRadius(5)
        }
    }
}

#Preview {
    AccountPickerView(
        accounts: [
            Account(Id: 1, Name: "Cloudmanic Labs, LLC"),
            Account(Id: 2, Name: "Personal Finances"),
            Account(Id: 3, Name: "Side Project"),
        ],
        currentAccountId: 1
    ) { account in
        print("Selected: \(account.Name)")
    }
}
