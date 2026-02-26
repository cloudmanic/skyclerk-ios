//
// CategoryPickerView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// A searchable category picker modal presented as a sheet from LedgerModifyView.
/// Displays a dark-themed list of categories that can be filtered by typing in the
/// search bar. Tapping a category row selects it and dismisses the sheet.
/// The styling matches the app's dark card aesthetic with #232323 background,
/// #2a2a2a row backgrounds, white text, and white search input field.
struct CategoryPickerView: View {
    /// The list of categories to display and search through.
    /// Should already be filtered by type (income/expense) before being passed in.
    let categories: [Category]

    /// Callback closure invoked when the user selects a category.
    /// Passes the selected Category object back to the parent view.
    let onSelect: (Category) -> Void

    /// Dismiss action to close this sheet when the user cancels.
    @Environment(\.dismiss) private var dismiss

    /// The search text entered by the user to filter the categories list.
    /// Filtering is case-insensitive on the category's Name.
    @State private var searchText: String = ""

    // MARK: - Colors

    /// Modal background color (#232323).
    private let bgColor = Color(hex: "232323")

    /// Row background color (#2a2a2a).
    private let rowBgColor = Color(hex: "2a2a2a")

    /// Label text color (#bcbcbc) for the title and helper text.
    private let labelColor = Color(hex: "bcbcbc")

    // MARK: - Computed Properties

    /// Returns the categories filtered by the search text.
    /// When the search text is empty, all categories are returned.
    /// Otherwise, categories are filtered by a case-insensitive match on Name.
    private var filteredCategories: [Category] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return categories
        }
        return categories.filter {
            $0.Name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Body

    /// The main view body. Renders a dark modal with a centered title,
    /// a white search input field, a scrollable list of category rows,
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

            // Scrollable category list
            categoryList
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

    /// Centered "Select Category" title matching the app's form title style.
    /// Uses 16px semibold text in the label gray color (#bcbcbc).
    private var titleSection: some View {
        Text("Select Category")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(labelColor)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 4)
    }

    // MARK: - Search Field

    /// A white-background text field for filtering categories by name.
    /// Matches the app's standard input field style: white background,
    /// 42px height, 5px corner radius, 8px horizontal padding, black text.
    private var searchField: some View {
        TextField("Search categories...", text: $searchText)
            .font(.system(size: 16))
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .frame(height: 42)
            .background(Color.white)
            .cornerRadius(5)
            .autocorrectionDisabled()
    }

    // MARK: - Category List

    /// A scrollable list of category rows filtered by the search text.
    /// Each row has a #2a2a2a background, white 16px text, 5px corner radius,
    /// and 5px spacing between rows. Tapping a row selects the category,
    /// fires the onSelect callback, and dismisses the sheet.
    private var categoryList: some View {
        ScrollView {
            LazyVStack(spacing: 5) {
                ForEach(filteredCategories) { category in
                    Button {
                        onSelect(category)
                        dismiss()
                    } label: {
                        categoryRow(category: category)
                    }
                }
            }
        }
    }

    /// Builds a single category row matching the app's dark list row style.
    /// Shows the category's name in white 16px text on a #2a2a2a background
    /// with 16px horizontal padding, 12px vertical padding, and 5px corner radius.
    ///
    /// - Parameter category: The Category to display in this row.
    /// - Returns: A styled row view for the category.
    private func categoryRow(category: Category) -> some View {
        HStack {
            Text(category.Name)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(rowBgColor)
        .cornerRadius(5)
    }

    // MARK: - Cancel Button

    /// A full-width cancel button at the bottom of the modal.
    /// Styled as a subtle dark button matching the app's aesthetic.
    /// Dismisses the sheet without selecting any category.
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
    CategoryPickerView(
        categories: [
            Category(Id: 1, Name: "Sales Revenue", categoryType: "1"),
            Category(Id: 2, Name: "Consulting Income", categoryType: "1"),
            Category(Id: 3, Name: "Office Supplies", categoryType: "2"),
        ]
    ) { category in
        print("Selected: \(category.Name)")
    }
}
