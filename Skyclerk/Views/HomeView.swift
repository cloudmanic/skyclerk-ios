//
// HomeView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The main dashboard view of the Skyclerk app, displayed after successful authentication.
/// Features a custom 4-segment tab control at the top (Ledger, Snap!Clerk, Search, Settings)
/// instead of a system TabView. Each tab presents different content: the ledger list with
/// income/expense filtering, Snap!Clerk receipt submissions, a search interface, and settings.
/// Manages all primary data loading (user profile, ledgers, snap!clerks, P&L reports) and
/// supports account switching for users with multiple accounts.
struct HomeView: View {
    /// The shared authentication service injected from the parent view hierarchy.
    /// Used to log the user out and react to authentication state changes.
    @EnvironmentObject var authService: AuthService

    /// The currently selected tab index. 0 = Ledger, 1 = Snap!Clerk, 2 = Search, 3 = Settings.
    @State private var selectedTab: Int = 0

    /// The list of ledger entries currently loaded for the active account and filter.
    @State private var ledgers: [Ledger] = []

    /// The list of Snap!Clerk receipt submissions loaded for the active account.
    @State private var snapclerks: [SnapClerk] = []

    /// The current page number for paginated ledger loading (1-indexed).
    @State private var currentPage: Int = 1

    /// Whether the most recently fetched page was the last page of ledger results.
    /// When true, the "Load More" button is hidden since there are no more entries.
    @State private var isLastPage: Bool = false

    /// The current page number for paginated Snap!Clerk loading (1-indexed).
    @State private var snapClerkPage: Int = 1

    /// Whether the most recently fetched page was the last page of Snap!Clerk results.
    @State private var isSnapClerkLastPage: Bool = false

    /// The active filter type for ledger entries. nil shows all entries,
    /// "Income" shows only income, "Expense" shows only expenses.
    @State private var filterType: String? = nil

    /// The search query text entered by the user in the Search tab.
    @State private var searchText: String = ""

    /// The search results returned from the API when searching ledger entries.
    @State private var searchResults: [Ledger] = []

    /// Whether a search has been performed (used to show "no results" vs initial state).
    @State private var hasSearched: Bool = false

    /// The current year's profit and loss summary for display in the ledger toolbar.
    @State private var pnl: PnlCurrentYear = PnlCurrentYear()

    /// The currently authenticated user's profile, including their list of accounts.
    @State private var user: User = User()

    /// The currently active account that the user is viewing data for.
    @State private var currentAccount: Account = Account()

    /// Whether a data loading operation is in progress. Used to show loading indicators.
    @State private var isLoading: Bool = false

    /// Whether the account picker confirmation dialog is currently presented.
    @State private var showAccountPicker: Bool = false

    /// Any error message to display to the user via an alert dialog.
    @State private var errorMessage: String? = nil

    /// Whether the error alert dialog is currently visible.
    @State private var showError: Bool = false

    /// The tab segment labels displayed in the custom segmented control at the top.
    private let tabTitles = ["Ledger", "Snap!Clerk", "Search", "Settings"]

    /// The main view body. Wraps the entire dashboard in a NavigationStack with a
    /// dark background theme. The layout consists of the custom segmented control
    /// at the top, followed by the content for the currently selected tab.
    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen dark background extending to all edges.
                Color.appDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Custom segmented tab control at the top of the screen.
                    segmentedControl

                    // Content area that switches based on the selected tab.
                    tabContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .darkToolbar()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Skyclerk")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadInitialData()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .confirmationDialog("Switch Account", isPresented: $showAccountPicker, titleVisibility: .visible) {
            // Show each account as a selectable option in the action sheet.
            accountPickerButtons
        }
    }

    // MARK: - Segmented Control

    /// The custom segmented control displayed at the top of the dashboard.
    /// Renders 4 horizontally equal buttons (Ledger, Snap!Clerk, Search, Settings)
    /// with dark background styling. The active segment has a lighter background
    /// and brighter text color, while inactive segments use muted gray text.
    private var segmentedControl: some View {
        HStack(spacing: 2) {
            ForEach(0..<tabTitles.count, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    Text(tabTitles[index])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedTab == index ? Color.appSegmentActive : Color.appSegmentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedTab == index ? Color.appSegmentActiveBg : Color.clear)
                        .cornerRadius(6)
                }
            }
        }
        .padding(3)
        .background(Color.appSegmentBg)
        .cornerRadius(8)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Tab Content

    /// Routes to the correct tab content view based on the currently selected tab index.
    /// Uses a switch statement with @ViewBuilder to conditionally render the appropriate
    /// content without wrapping each case in AnyView.
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            ledgerTab
        case 1:
            snapClerkTab
        case 2:
            searchTab
        case 3:
            settingsTab
        default:
            EmptyView()
        }
    }

    // MARK: - Tab 0: Ledger

    /// The Ledger tab content. Displays action buttons for adding income/expenses at the top,
    /// an optional account header for multi-account users, column headers for the data table,
    /// a scrollable list of ledger entries with pull-to-refresh, a "Load More" button for
    /// pagination, and a bottom toolbar with type filters and the P&L summary.
    private var ledgerTab: some View {
        VStack(spacing: 0) {
            // Scrollable content area with pull-to-refresh support.
            ScrollView {
                VStack(spacing: 0) {
                    // Income and Expense action buttons side by side.
                    ledgerActionButtons

                    // Account name header (only shown for multi-account users).
                    accountHeader

                    // Column header row: Date | Vendor | Amount.
                    ledgerColumnHeader

                    // The list of ledger entries, or an empty state message.
                    if ledgers.isEmpty && !isLoading {
                        ledgerEmptyState
                    } else {
                        ledgerList
                    }

                    // Loading indicator shown while fetching data.
                    if isLoading {
                        ProgressView()
                            .tint(Color.appTextGray)
                            .padding(.vertical, 20)
                    }

                    // "Load More" button shown when there are more pages to fetch.
                    if !isLastPage && !ledgers.isEmpty {
                        loadMoreButton
                    }
                }
            }
            .refreshable {
                await refreshLedgerData()
            }

            // Bottom toolbar with filter buttons and P&L display.
            ledgerToolbar
        }
    }

    /// Two action buttons displayed side by side at the top of the Ledger tab.
    /// The "Add Income" button has a green background and navigates to the ledger
    /// modify view in income mode. The "Add Expense" button has a red background
    /// and navigates to the ledger modify view in expense mode.
    private var ledgerActionButtons: some View {
        HStack(spacing: 10) {
            // Add Income button with green background.
            NavigationLink(destination: LedgerModifyView(type: "income")) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Income")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appSuccess)
                .cornerRadius(8)
            }

            // Add Expense button with red background.
            NavigationLink(destination: LedgerModifyView(type: "expense")) {
                HStack(spacing: 6) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Expense")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appDanger)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// The account header row displayed when the user has more than one account.
    /// Shows the current account name and a chevron indicator to signal it is tappable.
    /// Tapping opens a confirmation dialog (action sheet) to switch accounts.
    @ViewBuilder
    private var accountHeader: some View {
        if user.Accounts.count > 1 {
            Button {
                showAccountPicker = true
            } label: {
                HStack {
                    Image(systemName: "building.2")
                        .font(.system(size: 13))
                        .foregroundColor(Color.appTextGray)

                    Text(currentAccount.Name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appTextGray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.appDarkGray)
            }
        }
    }

    /// The column header row for the ledger data table.
    /// Displays "Date", "Vendor", and "Amount" labels matching the proportions
    /// of the LedgerRowView columns. Uses a darker background to visually
    /// separate the header from the data rows.
    private var ledgerColumnHeader: some View {
        HStack(spacing: 8) {
            Text("Date")
                .frame(width: 65, alignment: .center)
            Text("Vendor")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Amount")
                .frame(width: 90, alignment: .trailing)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color.appMedium)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.appDarkGray)
    }

    /// The scrollable list of ledger entries. Each entry is rendered using LedgerRowView
    /// with a subtle divider between rows. Odd rows have a slightly different background
    /// for visual alternation (zebra striping adapted for dark mode).
    private var ledgerList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(ledgers.enumerated()), id: \.element.id) { index, ledger in
                VStack(spacing: 0) {
                    LedgerRowView(ledger: ledger)
                        .background(index % 2 == 0 ? Color.appDark : Color.appDarkGray.opacity(0.5))

                    // Thin divider between rows for visual separation.
                    Divider()
                        .background(Color.appBgDarkGray.opacity(0.5))
                }
            }
        }
    }

    /// The empty state view shown when no ledger entries exist for the current
    /// account and filter. Displays an encouraging message and a book icon
    /// to prompt the user to add their first transaction.
    private var ledgerEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(Color.appTextGray)

            Text("Let's get started by adding your first ledger entry")
                .font(.system(size: 16))
                .foregroundColor(Color.appTextGray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 30)
    }

    /// The "Load More" button displayed at the bottom of the ledger list when
    /// additional pages of results are available. Triggers loading the next page
    /// and appending results to the existing list.
    private var loadMoreButton: some View {
        Button {
            Task {
                await loadMoreLedgers()
            }
        } label: {
            Text("Load More")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appLink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appDarkGray)
                .cornerRadius(8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// The bottom toolbar for the Ledger tab. Contains three filter buttons (ALL, INCOME, EXPENSES)
    /// and a P&L (Profit & Loss) summary for the current year. The active filter button is
    /// highlighted with its corresponding color. The P&L section is only shown when the year
    /// value is greater than 0, indicating data is available.
    private var ledgerToolbar: some View {
        VStack(spacing: 0) {
            // Top border line separating toolbar from content.
            Divider()
                .background(Color.appBgDarkGray)

            HStack(spacing: 0) {
                // Filter buttons: ALL, INCOME, EXPENSES.
                filterButton(label: "ALL", type: nil, color: Color.appTextGray)
                filterButton(label: "INCOME", type: "Income", color: Color.appSuccess)
                filterButton(label: "EXPENSES", type: "Expense", color: Color.appDanger)

                Spacer()

                // P&L summary displayed on the right side of the toolbar.
                if pnl.Year > 0 {
                    Text("\(String(pnl.Year)) P&L | \(pnl.Value.toCurrency())")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(pnl.Value >= 0 ? Color.appSuccess : Color.appDanger)
                        .padding(.trailing, 12)
                }
            }
            .padding(.vertical, 8)
            .background(Color.appDarkGray)
        }
    }

    /// Creates a single filter button for the ledger toolbar. The button toggles the
    /// filterType state and reloads ledger data. The active filter is rendered with its
    /// accent color, while inactive filters use a muted appearance.
    ///
    /// - Parameters:
    ///   - label: The display text for the button (e.g., "ALL", "INCOME", "EXPENSES").
    ///   - type: The API filter value to use when this button is active. nil means no filter.
    ///   - color: The accent color to use when this filter is active.
    /// - Returns: A styled Button view for the filter option.
    private func filterButton(label: String, type: String?, color: Color) -> some View {
        Button {
            if filterType == type {
                return
            }
            filterType = type
            Task {
                await reloadLedgers()
            }
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(filterType == type ? color : Color.appSegmentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
    }

    // MARK: - Tab 1: Snap!Clerk

    /// The Snap!Clerk tab content. Displays an upload button at the top for adding new
    /// receipt photos, the account header for multi-account users, a list of existing
    /// Snap!Clerk submissions with their processing status, and pagination support.
    /// Shows an onboarding empty state when no submissions exist yet.
    private var snapClerkTab: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Full-width upload button for submitting new receipts.
                    snapClerkUploadButton

                    // Account name header (only shown for multi-account users).
                    accountHeader

                    // The list of snap!clerk entries, or an empty state message.
                    if snapclerks.isEmpty && !isLoading {
                        snapClerkEmptyState
                    } else {
                        snapClerkList
                    }

                    // Loading indicator shown while fetching data.
                    if isLoading {
                        ProgressView()
                            .tint(Color.appTextGray)
                            .padding(.vertical, 20)
                    }

                    // "Load More" button for pagination.
                    if !isSnapClerkLastPage && !snapclerks.isEmpty {
                        snapClerkLoadMoreButton
                    }
                }
            }
            .refreshable {
                await refreshSnapClerkData()
            }
        }
    }

    /// The upload button at the top of the Snap!Clerk tab. Full-width design with
    /// a camera icon and descriptive text. Navigates to the UploadReceiptView where
    /// the user can photograph or select a receipt image for processing.
    private var snapClerkUploadButton: some View {
        NavigationLink(destination: UploadReceiptView()) {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16))
                Text("Upload New Receipt")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appPrimary)
            .cornerRadius(8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// The scrollable list of Snap!Clerk receipt submissions. Each submission is
    /// rendered using SnapClerkRowView with dividers between rows for separation.
    private var snapClerkList: some View {
        LazyVStack(spacing: 0) {
            ForEach(snapclerks) { snapclerk in
                VStack(spacing: 0) {
                    SnapClerkRowView(snapclerk: snapclerk)

                    Divider()
                        .background(Color.appBgDarkGray.opacity(0.5))
                }
            }
        }
    }

    /// The empty state view for the Snap!Clerk tab. Displayed when no receipt
    /// submissions exist yet. Shows onboarding text explaining the feature and
    /// a prominent "GET STARTED now!" button that navigates to the upload screen.
    private var snapClerkEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(Color.appTextGray)

            Text("Snap!Clerk lets you photograph receipts and automatically extract the transaction details.")
                .font(.system(size: 15))
                .foregroundColor(Color.appTextGray)
                .multilineTextAlignment(.center)

            Text("Take a photo of your receipt and we'll do the rest.")
                .font(.system(size: 14))
                .foregroundColor(Color.appTextLightGray)
                .multilineTextAlignment(.center)

            NavigationLink(destination: UploadReceiptView()) {
                Text("GET STARTED now!")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.appSuccess)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 30)
    }

    /// The "Load More" button for the Snap!Clerk list, identical in styling to the
    /// ledger's load more button. Fetches the next page of Snap!Clerk submissions.
    private var snapClerkLoadMoreButton: some View {
        Button {
            Task {
                await loadMoreSnapClerks()
            }
        } label: {
            Text("Load More")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appLink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appDarkGray)
                .cornerRadius(8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Tab 2: Search

    /// The Search tab content. Features a search text field at the top where the user
    /// can type a query to search across all ledger entries. Results are displayed in
    /// the same LedgerRowView format used in the Ledger tab. Shows appropriate messages
    /// for the initial state (before any search) and for empty results.
    private var searchTab: some View {
        VStack(spacing: 0) {
            // Search bar with text field and search button.
            searchBar

            ScrollView {
                VStack(spacing: 0) {
                    // Search results header showing the current query.
                    if hasSearched {
                        searchResultsHeader
                    }

                    // Search results list or empty state.
                    if !searchResults.isEmpty {
                        searchResultsList
                    } else if hasSearched {
                        searchEmptyState
                    } else {
                        searchInitialState
                    }
                }
            }
        }
    }

    /// The search bar containing a text field for entering search queries and a
    /// search button to trigger the search. The text field uses a dark appearance
    /// matching the app theme. Pressing Return on the keyboard also triggers the search.
    private var searchBar: some View {
        HStack(spacing: 10) {
            // Search text field with magnifying glass icon.
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.appTextGray)

                TextField("Search ledger entries...", text: $searchText)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        Task {
                            await performSearch()
                        }
                    }

                // Clear button shown when there is text in the field.
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                        hasSearched = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.appTextGray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.appDarkGray)
            .cornerRadius(8)

            // Search action button.
            Button {
                Task {
                    await performSearch()
                }
            } label: {
                Text("Search")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// The header displayed above search results showing the current search query.
    /// Helps the user understand what results are being displayed.
    private var searchResultsHeader: some View {
        HStack {
            Text("Your Search Results for '\(searchText)'")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appTextGray)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// The list of search results displayed using LedgerRowView, matching the
    /// same visual format as the main Ledger tab list.
    private var searchResultsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, ledger in
                VStack(spacing: 0) {
                    LedgerRowView(ledger: ledger)
                        .background(index % 2 == 0 ? Color.appDark : Color.appDarkGray.opacity(0.5))

                    Divider()
                        .background(Color.appBgDarkGray.opacity(0.5))
                }
            }
        }
    }

    /// The empty state shown when a search returns no results. Displays a
    /// message indicating no matching entries were found.
    private var searchEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(Color.appTextGray)

            Text("No results found for '\(searchText)'")
                .font(.system(size: 15))
                .foregroundColor(Color.appTextGray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 30)
    }

    /// The initial state shown before the user has performed any search.
    /// Provides a hint about what can be searched.
    private var searchInitialState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(Color.appTextGray)

            Text("Search your ledger entries by vendor name, category, or notes")
                .font(.system(size: 15))
                .foregroundColor(Color.appTextGray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 30)
    }

    // MARK: - Tab 3: Settings

    /// The Settings tab content. Embeds the SettingsView component which provides
    /// access to profile management, account settings, billing, and logout functionality.
    private var settingsTab: some View {
        SettingsView()
    }

    // MARK: - Account Picker

    /// Generates the account picker confirmation dialog buttons. Creates one button
    /// per account from the user's account list. Tapping an account switches the
    /// active account, stores the new account ID in UserDefaults, and reloads all data.
    @ViewBuilder
    private var accountPickerButtons: some View {
        ForEach(user.Accounts) { account in
            Button {
                switchAccount(to: account)
            } label: {
                if account.Id == currentAccount.Id {
                    // Show a checkmark next to the currently active account.
                    Label(account.Name, systemImage: "checkmark")
                } else {
                    Text(account.Name)
                }
            }
        }

        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Data Loading

    /// Loads all initial data when the view first appears. Fetches the user profile
    /// to determine which accounts are available, sets the active account from
    /// UserDefaults (or defaults to the first account), then loads ledgers and the
    /// P&L report for the active account. Called from .onAppear.
    private func loadInitialData() {
        Task {
            await loadUserAndData()
        }
    }

    /// Fetches the user profile and then loads all data for the active account.
    /// First calls MeService.getMe() to get the user's accounts list, then determines
    /// which account to use based on the stored account_id in UserDefaults. If no
    /// stored account ID exists, falls back to the first account in the user's list.
    /// After setting the active account, loads ledgers and the P&L report.
    private func loadUserAndData() async {
        isLoading = true

        do {
            // Fetch the authenticated user's profile to get their accounts list.
            let fetchedUser = try await MeService.shared.getMe()
            await MainActor.run {
                user = fetchedUser
            }

            // Determine the active account from UserDefaults or fall back to the first account.
            let storedAccountId = UserDefaults.standard.integer(forKey: "account_id")
            let activeAccount = fetchedUser.Accounts.first(where: { $0.Id == storedAccountId }) ?? fetchedUser.Accounts.first ?? Account()

            await MainActor.run {
                currentAccount = activeAccount
                // Ensure the account_id is stored for API calls.
                if activeAccount.Id > 0 {
                    UserDefaults.standard.set(activeAccount.Id, forKey: "account_id")
                }
            }

            // Load ledger data and P&L report concurrently.
            async let ledgerResult = LedgerService.shared.getLedgers(page: 1, type: nil, search: nil)
            async let pnlResult = ReportService.shared.getPnlCurrentYear()

            let (fetchedLedgers, fetchedPnl) = try await (ledgerResult, pnlResult)

            await MainActor.run {
                ledgers = fetchedLedgers.ledgers
                isLastPage = fetchedLedgers.lastPage
                currentPage = 1
                pnl = fetchedPnl
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Refreshes ledger data by resetting to page 1 and reloading with the current filter.
    /// Called by pull-to-refresh on the ledger list. Also refreshes the P&L report.
    private func refreshLedgerData() async {
        do {
            async let ledgerResult = LedgerService.shared.getLedgers(page: 1, type: filterType, search: nil)
            async let pnlResult = ReportService.shared.getPnlCurrentYear()

            let (fetchedLedgers, fetchedPnl) = try await (ledgerResult, pnlResult)

            await MainActor.run {
                ledgers = fetchedLedgers.ledgers
                isLastPage = fetchedLedgers.lastPage
                currentPage = 1
                pnl = fetchedPnl
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Reloads ledgers from page 1 with the current filter type.
    /// Called when the user changes the filter between ALL, INCOME, and EXPENSES.
    /// Replaces the entire ledger list with the new filtered results.
    private func reloadLedgers() async {
        isLoading = true

        do {
            let result = try await LedgerService.shared.getLedgers(page: 1, type: filterType, search: nil)

            await MainActor.run {
                ledgers = result.ledgers
                isLastPage = result.lastPage
                currentPage = 1
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Loads the next page of ledger entries and appends them to the existing list.
    /// Called when the user taps the "Load More" button. Increments the page counter
    /// and updates the isLastPage flag to hide the button when no more pages remain.
    private func loadMoreLedgers() async {
        let nextPage = currentPage + 1

        do {
            let result = try await LedgerService.shared.getLedgers(page: nextPage, type: filterType, search: nil)

            await MainActor.run {
                ledgers.append(contentsOf: result.ledgers)
                isLastPage = result.lastPage
                currentPage = nextPage
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Refreshes Snap!Clerk data by resetting to page 1 and reloading.
    /// Called by pull-to-refresh on the Snap!Clerk list.
    private func refreshSnapClerkData() async {
        do {
            let result = try await SnapClerkService.shared.getSnapClerks(page: 1)

            await MainActor.run {
                snapclerks = result.snapclerks
                isSnapClerkLastPage = result.lastPage
                snapClerkPage = 1
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Loads the next page of Snap!Clerk submissions and appends them to the existing list.
    /// Called when the user taps the "Load More" button on the Snap!Clerk tab.
    private func loadMoreSnapClerks() async {
        let nextPage = snapClerkPage + 1

        do {
            let result = try await SnapClerkService.shared.getSnapClerks(page: nextPage)

            await MainActor.run {
                snapclerks.append(contentsOf: result.snapclerks)
                isSnapClerkLastPage = result.lastPage
                snapClerkPage = nextPage
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Performs a search query against the ledger API using the text entered in the
    /// search bar. Fetches the first page of results with the search parameter and
    /// replaces the searchResults array. Sets hasSearched to true so the empty state
    /// can distinguish between "no search yet" and "no results found."
    private func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isLoading = true

        do {
            let result = try await LedgerService.shared.getLedgers(page: 1, type: nil, search: query)

            await MainActor.run {
                searchResults = result.ledgers
                hasSearched = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Switches the active account to the given account. Stores the new account ID
    /// in UserDefaults so all API calls use the correct account endpoint, then
    /// reloads all data (ledgers, P&L, snap!clerks) for the newly selected account.
    ///
    /// - Parameter account: The Account to switch to.
    private func switchAccount(to account: Account) {
        guard account.Id != currentAccount.Id else { return }

        currentAccount = account
        UserDefaults.standard.set(account.Id, forKey: "account_id")

        // Reset all data and reload for the new account.
        ledgers = []
        snapclerks = []
        currentPage = 1
        snapClerkPage = 1
        isLastPage = false
        isSnapClerkLastPage = false
        pnl = PnlCurrentYear()

        Task {
            await loadUserAndData()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService.shared)
}
