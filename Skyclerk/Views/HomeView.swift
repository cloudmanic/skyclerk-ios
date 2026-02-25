//
// HomeView.swift
//
// Created on 2026-02-25.
// Copyright 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The main dashboard view of the Skyclerk app, displayed after successful authentication.
/// Features a header area with a background pattern image and action buttons (Add Income/Expense
/// or Upload Receipt), a 4-segment tab control (Ledger, Snap!Clerk, Search, Settings) with
/// dark background styling, scrollable content for each tab, and a bottom footer bar with
/// filter buttons (ALL/INCOME/EXPENSES) and a small logo. This view matches the visual layout
/// and behavior of the Ionic Skyclerk mobile app's home.page exactly.
struct HomeView: View {
    /// The shared authentication service injected from the parent view hierarchy.
    /// Used to log the user out and react to authentication state changes.
    @EnvironmentObject var authService: AuthService

    /// The currently selected tab name. Matches Ionic tab identifiers:
    /// "ledger", "snapclerk", "search", "settings".
    @State private var selectedTab: String = "ledger"

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

    /// The active filter type for ledger entries. Empty string shows all entries,
    /// "income" shows only income, "expense" shows only expenses. Matches Ionic behavior.
    @State private var ledgersType: String = ""

    /// The search term text actively being typed by the user in the Search tab input field.
    @State private var ledgersSearchTerm: String = ""

    /// The search query that was last submitted (set when user hits the search button).
    /// Separated from ledgersSearchTerm to match the Ionic pattern.
    @State private var ledgersSearch: String = ""

    /// The current year's profit and loss summary for display in the P&L footer row.
    @State private var pnl: PnlCurrentYear = PnlCurrentYear()

    /// The currently authenticated user's profile, including their list of accounts.
    @State private var user: User = User()

    /// The currently active account that the user is viewing data for.
    @State private var currentAccount: Account = Account()

    /// Whether a data loading operation is in progress. Used to show loading indicators.
    @State private var isLoading: Bool = false

    /// Whether the account picker confirmation dialog is currently presented.
    @State private var showAccountPicker: Bool = false

    /// Which table header mode is active for the ledger: "account" shows account name,
    /// "cols" shows Date/Vendor/Amount column headers. Mirrors Ionic activeTableHeader.
    @State private var activeTableHeader: String = ""

    /// Any error message to display to the user via an alert dialog.
    @State private var errorMessage: String? = nil

    /// Whether the error alert dialog is currently visible.
    @State private var showError: Bool = false

    /// The segment tab labels displayed in the custom segmented control.
    private let tabKeys = ["ledger", "snapclerk", "search", "settings"]

    /// The display labels for each segment tab, matching the Ionic segment-button text.
    private let tabLabels = ["Ledger", "Snap!Clerk", "Search", "Settings"]

    /// The main view body. Wraps the entire dashboard in a NavigationStack with the
    /// Ionic layout: dark navigation bar with "Skyclerk" title, pattern background header
    /// with action buttons, segment control, scrollable content area, and bottom footer bar.
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pattern background header with action buttons (context-sensitive per tab).
                headerActionButtons

                // Segment control bar on dark background with border-top styling.
                segmentedControl

                // Main content area with dark background (#232323).
                ZStack {
                    Color(hex: "232323")
                        .ignoresSafeArea(edges: .bottom)

                    // Tab content that switches based on selected tab.
                    tabContent
                }

                // Bottom footer bar with filter buttons and logo (always visible).
                footerBar
            }
            .background(Color.appDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        .confirmationDialog("Your Accounts", isPresented: $showAccountPicker, titleVisibility: .visible) {
            // Show each account as a selectable option in the action sheet.
            accountPickerButtons
        }
    }

    // MARK: - Header Action Buttons

    /// The header section with a pattern background image and context-sensitive action buttons.
    /// On the Ledger and Settings tabs: shows side-by-side "Add Income" (green) and "Add Expense" (red) buttons.
    /// On the Snap!Clerk tab: shows a single full-width "Upload New Receipt" (green) button.
    /// On the Search tab: shows a search input field with a gray gradient search button.
    /// The pattern background uses the bg-pettern asset from the Ionic app.
    private var headerActionButtons: some View {
        ZStack {
            // Pattern background image tiled behind the buttons.
            Image("bg-pettern")
                .resizable(resizingMode: .tile)
                .frame(height: 70)
                .clipped()

            switch selectedTab {
            case "ledger", "settings":
                // Side-by-side Add Income / Add Expense buttons matching Ionic styling.
                ledgerHeaderButtons
            case "snapclerk":
                // Full-width Upload New Receipt button.
                snapClerkHeaderButton
            case "search":
                // Search input field with search button.
                searchHeaderBar
            default:
                EmptyView()
            }
        }
        .frame(height: 70)
    }

    /// Two side-by-side buttons for adding income (green gradient) and expense (red gradient).
    /// Each button uses the matching SVG icon from the asset catalog and navigates to LedgerModifyView.
    /// Matches the Ionic button-success and button-danger custom button styles with gradient backgrounds,
    /// border radius of 6px, height of 50px, and 2px solid #141414 border.
    private var ledgerHeaderButtons: some View {
        HStack(spacing: 0) {
            // Add Income button with green gradient background.
            NavigationLink(destination: LedgerModifyView(type: "income")) {
                HStack(spacing: 8) {
                    Image("add-income-icon")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                    Text("Add Income")
                        .font(.system(size: 16, weight: .regular))
                        .textCase(.uppercase)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "5c882c"), Color(hex: "75a04a")],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "141414"), lineWidth: 2)
                )
                .overlay(
                    // Inset highlight: subtle white line at top matching Ionic inset shadow.
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white.opacity(0.32), lineWidth: 1)
                        .padding(2)
                )
                .shadow(color: Color.white.opacity(0.28), radius: 8, x: 0, y: 0)
            }
            .padding(.leading, 12)
            .padding(.trailing, 6)

            // Add Expense button with red gradient background.
            NavigationLink(destination: LedgerModifyView(type: "expense")) {
                HStack(spacing: 8) {
                    Image("add-expense-icon")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                    Text("Add Expense")
                        .font(.system(size: 16, weight: .regular))
                        .textCase(.uppercase)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "7b2624"), Color(hex: "96312d")],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "141414"), lineWidth: 2)
                )
                .overlay(
                    // Inset highlight: subtle white line at top matching Ionic inset shadow.
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white.opacity(0.32), lineWidth: 1)
                        .padding(2)
                )
                .shadow(color: Color.white.opacity(0.28), radius: 8, x: 0, y: 0)
            }
            .padding(.leading, 6)
            .padding(.trailing, 12)
        }
    }

    /// Full-width upload button for the Snap!Clerk tab header. Uses a green gradient background
    /// with the upload SVG icon. Navigates to UploadReceiptView. Matches Ionic button-success
    /// button-custom styling.
    private var snapClerkHeaderButton: some View {
        NavigationLink(destination: UploadReceiptView()) {
            HStack(spacing: 8) {
                Image("upload")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                Text("Upload New Receipt")
                    .font(.system(size: 16, weight: .regular))
                    .textCase(.uppercase)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [Color(hex: "5c882c"), Color(hex: "75a04a")],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(hex: "141414"), lineWidth: 2)
            )
        }
        .padding(.horizontal, 12)
    }

    /// The search input field and search button displayed in the header on the Search tab.
    /// Matches the Ionic custom-input-search styling: a light gray rounded input field (#eaeaea)
    /// with inset shadow, alongside a gray gradient search button with the search SVG icon.
    private var searchHeaderBar: some View {
        HStack(spacing: 6) {
            // Text input field with light background and inset shadow appearance.
            TextField("Search...", text: $ledgersSearchTerm)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(Color(hex: "eaeaea"))
                .cornerRadius(5)
                .onSubmit {
                    doLedgerSearch()
                }

            // Gray gradient search button with search icon.
            Button {
                doLedgerSearch()
            } label: {
                Image("search")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .frame(width: 46, height: 40)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "5b5b5b"), Color(hex: "8f8f8f")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(5)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Segmented Control

    /// The custom segmented control displayed below the header action buttons.
    /// Renders 4 horizontally distributed buttons (Ledger, Snap!Clerk, Search, Settings)
    /// on a dark background (#2c2c2c toolbar color from Ionic) with a top border (#373737).
    /// The active segment has a lighter background and brighter text; inactive segments
    /// use #808080 text. Font size 16px, weight 600, height 32px per button. Matches the
    /// Ionic segment-toolbar styling exactly.
    private var segmentedControl: some View {
        VStack(spacing: 0) {
            // Top border line matching Ionic's border-top: 1px solid #373737.
            Rectangle()
                .fill(Color(hex: "373737"))
                .frame(height: 1)

            HStack(spacing: 5) {
                ForEach(0..<tabKeys.count, id: \.self) { index in
                    Button {
                        let newTab = tabKeys[index]
                        selectedTab = newTab
                        // Mimic Ionic's doLedgerTabClick: reset ledger state when tapping Ledger tab.
                        if newTab == "ledger" {
                            doLedgerTabClick()
                        }
                    } label: {
                        Text(tabLabels[index])
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedTab == tabKeys[index] ? Color(hex: "cccccc") : Color(hex: "808080"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(
                                selectedTab == tabKeys[index]
                                    ? AnyShapeStyle(Color(hex: "4a4a4a"))
                                    : AnyShapeStyle(Color.clear)
                            )
                            .cornerRadius(5)
                    }
                }
            }
            .padding(5)
            .background(Color(hex: "2c2c2c"))
        }
    }

    // MARK: - Tab Content

    /// Routes to the correct tab content view based on the currently selected tab string.
    /// Uses a switch statement with @ViewBuilder to conditionally render the appropriate
    /// content without wrapping each case in AnyView.
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case "ledger":
            ledgerTab
        case "snapclerk":
            snapClerkTab
        case "search":
            searchTab
        case "settings":
            settingsTab
        default:
            EmptyView()
        }
    }

    // MARK: - Tab: Ledger

    /// The Ledger tab content area. Contains the account header or column headers (togglable),
    /// a scrollable list of ledger entries with white/light gray alternating row backgrounds,
    /// a "Load More" button for pagination, and a P&L footer row at the bottom with a dark
    /// gradient background. Matches the Ionic .ledgers container layout.
    private var ledgerTab: some View {
        VStack(spacing: 0) {
            // Toggleable header: either account name or column headers.
            ledgerTableHeader

            // Scrollable content area with pull-to-refresh support.
            ScrollView {
                VStack(spacing: 0) {
                    // Ledger entry rows or empty state.
                    if ledgers.isEmpty && !isLoading {
                        ledgerEmptyState
                    } else {
                        ledgerList
                    }

                    // Loading indicator shown while fetching data.
                    if isLoading {
                        ProgressView()
                            .tint(Color(hex: "808080"))
                            .padding(.vertical, 20)
                    }

                    // "Load More" button when additional pages are available.
                    if !isLastPage && !ledgers.isEmpty {
                        loadMoreButton
                    }
                }
            }
            .refreshable {
                await refreshLedgerData()
            }

            // P&L footer bar at the bottom of the ledger tab.
            if pnl.Year > 0 {
                pnlFooterRow
            }
        }
    }

    /// The toggleable table header at the top of the ledger list.
    /// When activeTableHeader is "account", shows the current account name centered.
    /// When "cols", shows Date/Vendor/Amount column headers.
    /// Tapping the header toggles between the two modes (matching Ionic behavior).
    @ViewBuilder
    private var ledgerTableHeader: some View {
        if activeTableHeader == "account" {
            // Account name header row: gray background (#cdcdcd), centered text, tappable.
            Button {
                activeTableHeader = "cols"
            } label: {
                Text(currentAccount.Name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(hex: "cdcdcd"))
            }
            .frame(height: 30)
        } else if activeTableHeader == "cols" {
            // Column header row: gray background, Date/Vendor/Amount labels with text-shadow appearance.
            Button {
                // Toggle back to account header if user has multiple accounts.
                if user.Accounts.count > 1 {
                    activeTableHeader = "account"
                }
            } label: {
                HStack(spacing: 0) {
                    Text("Date")
                        .frame(width: 70, alignment: .leading)
                    Text("Vendor")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Amount")
                        .frame(width: 110, alignment: .trailing)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .shadow(color: Color.white.opacity(0.4), radius: 0, x: 0, y: 1)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(hex: "cdcdcd"))
            }
        }
    }

    /// The scrollable list of ledger entries. Each entry is rendered using LedgerRowView.
    /// Alternating row backgrounds: white (#ffffff) for odd rows, light gray (#f7f7f7) for even rows.
    /// Each row has a top and bottom border (#cbcbcb). Matches the Ionic tableViewGrid styling.
    private var ledgerList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(ledgers.enumerated()), id: \.element.id) { index, ledger in
                LedgerRowView(ledger: ledger)
                    .background(index % 2 == 0 ? Color.white : Color(hex: "f7f7f7"))
                    .overlay(
                        VStack(spacing: 0) {
                            Rectangle().fill(Color(hex: "cbcbcb")).frame(height: 1)
                            Spacer()
                            Rectangle().fill(Color(hex: "cbcbcb")).frame(height: 1)
                        }
                    )
            }
        }
    }

    /// The empty state view shown when no ledger entries exist for the current
    /// account and filter. Displays the encouraging message matching Ionic's first-run styling.
    private var ledgerEmptyState: some View {
        VStack(spacing: 0) {
            Text("Let's get started by adding\nyour first ledger entry")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(hex: "808080"))
                .multilineTextAlignment(.center)
                .padding(.top, 60)
                .padding(.horizontal, 60)
        }
        .frame(maxWidth: .infinity)
    }

    /// The "Load More" button displayed at the bottom of the ledger list when
    /// additional pages of results are available. Styled as a small outlined button
    /// matching Ionic's ion-button expand="block" fill="outline" color="medium" size="small".
    private var loadMoreButton: some View {
        Button {
            Task {
                await loadMoreLedgers()
            }
        } label: {
            Text("Load More...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "6b6b6b"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: "6b6b6b"), lineWidth: 1)
                )
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    /// The P&L (Profit & Loss) footer row at the bottom of the ledger content.
    /// Dark gradient background (black to #262626), displays the year and P&L label on the left
    /// in gray text, and the total amount on the right in white text with + prefix for positive.
    /// Matches the Ionic .footer row styling exactly.
    private var pnlFooterRow: some View {
        HStack {
            Text("\(String(pnl.Year)) Profit & Loss")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "8c8c8c"))
                .textCase(.uppercase)
                .shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: 1)

            Spacer()

            Text("\(pnl.Value > 0 ? "+" : "")\(pnl.Value.toCurrencyWholeNumber())")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: 1)
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(
            LinearGradient(
                colors: [Color.black, Color(hex: "262626")],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    // MARK: - Tab: Snap!Clerk

    /// The Snap!Clerk tab content. Displays the account header, then a list of receipt
    /// submissions or the onboarding empty state. Supports pull-to-refresh and pagination.
    private var snapClerkTab: some View {
        VStack(spacing: 0) {
            // Account header for multi-account users.
            snapClerkAccountHeader

            ScrollView {
                VStack(spacing: 0) {
                    // The list of snap!clerk entries, or an empty state.
                    if snapclerks.isEmpty && !isLoading {
                        snapClerkEmptyState
                    } else {
                        snapClerkList
                    }

                    // Loading indicator shown while fetching data.
                    if isLoading {
                        ProgressView()
                            .tint(Color(hex: "808080"))
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

    /// The account header shown at the top of the Snap!Clerk tab when user has multiple accounts.
    /// Centered account name on a gray (#cdcdcd) background. Tapping opens the account picker.
    @ViewBuilder
    private var snapClerkAccountHeader: some View {
        if user.Accounts.count > 1 {
            Button {
                showAccountPicker = true
            } label: {
                Text(currentAccount.Name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(hex: "cdcdcd"))
            }
        }
    }

    /// The scrollable list of Snap!Clerk receipt submissions. Each submission is rendered
    /// using SnapClerkRowView with white/alternating backgrounds and borders matching
    /// the Ionic tableViewGrid ion-row styling.
    private var snapClerkList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(snapclerks.enumerated()), id: \.element.id) { index, snapclerk in
                SnapClerkRowView(snapclerk: snapclerk)
                    .background(index % 2 == 0 ? Color.white : Color(hex: "f7f7f7"))
                    .overlay(
                        VStack(spacing: 0) {
                            Rectangle().fill(Color(hex: "cbcbcb")).frame(height: 1)
                            Spacer()
                            Rectangle().fill(Color(hex: "cbcbcb")).frame(height: 1)
                        }
                    )
            }
        }
    }

    /// The empty state view for the Snap!Clerk tab. Displayed when no receipt submissions exist.
    /// Shows the onboarding image from the asset catalog and a prominent "GET STARTED now!" button
    /// matching the Ionic yellow gradient button styling.
    private var snapClerkEmptyState: some View {
        VStack(spacing: 0) {
            // Onboarding image from the asset catalog.
            Image("onboarding")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 20)

            // GET STARTED now! button with yellow gradient matching Ionic styling.
            NavigationLink(destination: UploadReceiptView()) {
                Text("GET STARTED now!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "1e1e1e"))
                    .tracking(1)
                    .textCase(.uppercase)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "ffd92a"), Color(hex: "fdf9be")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "1e1e1e"), lineWidth: 2)
                    )
            }
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity)
    }

    /// The "Load More" button for the Snap!Clerk list. Styled identically to the ledger
    /// load more button with an outlined appearance.
    private var snapClerkLoadMoreButton: some View {
        Button {
            Task {
                await loadMoreSnapClerks()
            }
        } label: {
            Text("Load More...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "6b6b6b"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: "6b6b6b"), lineWidth: 1)
                )
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Tab: Search

    /// The Search tab content. Displays a search results header when results are available,
    /// the account header for multi-account users, column headers, and a ledger list showing
    /// search results. Matches the Ionic search tab layout with the search-result banner.
    private var searchTab: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Search results banner: "Your Search Results for" with the query below.
                    if !ledgersSearch.isEmpty {
                        searchResultsBanner
                    }

                    // Account header (same toggle pattern as ledger tab).
                    searchAccountHeader

                    // Reuse column headers matching the ledger tab.
                    if activeTableHeader == "cols" && !ledgersSearch.isEmpty {
                        searchColumnHeader
                    }

                    // Search results as ledger rows.
                    if !ledgers.isEmpty && !ledgersSearch.isEmpty {
                        searchResultsList
                    } else if ledgersSearch.isEmpty {
                        searchInitialState
                    }

                    // Loading indicator.
                    if isLoading {
                        ProgressView()
                            .tint(Color(hex: "808080"))
                            .padding(.vertical, 20)
                    }
                }
            }
        }
    }

    /// The search results banner displayed at the top of the search results.
    /// Dark background (#232323) with inset shadow appearance. Shows "Your Search Results for"
    /// in gray text and the actual search query in white below it.
    /// Matches Ionic .search-result styling exactly.
    private var searchResultsBanner: some View {
        VStack(spacing: 2) {
            Text("Your Search Results for")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "959595"))
            Text("\"\(ledgersSearch)\"")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color(hex: "232323"))
    }

    /// The account header shown in the search tab for multi-account users.
    @ViewBuilder
    private var searchAccountHeader: some View {
        if activeTableHeader == "account" && user.Accounts.count > 1 {
            Button {
                activeTableHeader = "cols"
            } label: {
                Text(currentAccount.Name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(hex: "cdcdcd"))
            }
        }
    }

    /// Column headers for search results, matching the ledger column header.
    private var searchColumnHeader: some View {
        HStack(spacing: 0) {
            Text("Date")
                .frame(width: 70, alignment: .leading)
            Text("Vendor")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Amount")
                .frame(width: 110, alignment: .trailing)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color(hex: "cdcdcd"))
    }

    /// The list of search results displayed using LedgerRowView format with white
    /// backgrounds and borders, matching the main ledger tab appearance.
    private var searchResultsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(ledgers.enumerated()), id: \.element.id) { index, ledger in
                LedgerRowView(ledger: ledger)
                    .background(index % 2 == 0 ? Color.white : Color(hex: "f7f7f7"))
                    .overlay(
                        VStack(spacing: 0) {
                            Rectangle().fill(Color(hex: "cbcbcb")).frame(height: 1)
                            Spacer()
                            Rectangle().fill(Color(hex: "cbcbcb")).frame(height: 1)
                        }
                    )
            }
        }
    }

    /// The initial state shown before the user has performed any search.
    /// Shows a hint about what can be searched in gray text on the dark background.
    private var searchInitialState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "808080"))

            Text("Search your ledger entries by vendor name, category, or notes")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "808080"))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 30)
    }

    // MARK: - Tab: Settings

    /// The Settings tab content. Embeds the SettingsView component which provides
    /// access to profile management, account settings, billing, and logout functionality.
    private var settingsTab: some View {
        SettingsView()
    }

    // MARK: - Footer Bar

    /// The bottom footer bar displayed on all tabs. Contains three filter buttons
    /// (ALL, INCOME, EXPENSES) on the left side with gradient backgrounds matching the Ionic
    /// footer overview styling, and a small Skyclerk logo on the right side that triggers
    /// the account picker on tap. The footer has a dark toolbar background.
    /// Matches ion-footer[overview] with ion-toolbar color="dark".
    private var footerBar: some View {
        HStack(spacing: 0) {
            // ALL filter button with gray gradient.
            footerFilterButton(label: "ALL", type: "", gradientColors: [Color(hex: "4b4b4b"), Color(hex: "606468")])

            // INCOME filter button with green gradient.
            footerFilterButton(label: "INCOME", type: "income", gradientColors: [Color(hex: "678250"), Color(hex: "77965c")])

            // EXPENSES filter button with red gradient.
            footerFilterButton(label: "EXPENSES", type: "expense", gradientColors: [Color(hex: "a73632"), Color(hex: "bd4743")])

            Spacer()

            // Small Skyclerk logo on the right. Tapping opens account picker if multi-account.
            Button {
                doFooterLogoClick()
            } label: {
                Image("logo-small")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
            }
            .padding(.trailing, 12)
        }
        .padding(.vertical, 6)
        .background(Color(hex: "2c2c2c"))
    }

    /// Creates a single footer filter button with a gradient background.
    /// Matches the Ionic footer overview button styling: white text, 14px font, text-shadow,
    /// horizontal padding 14px, border-radius 4px, gradient background specific to each type.
    ///
    /// - Parameters:
    ///   - label: The display text for the button (e.g., "ALL", "INCOME", "EXPENSES").
    ///   - type: The filter value to apply. Empty string means no filter (all ledgers).
    ///   - gradientColors: The two colors for the linear gradient background.
    /// - Returns: A styled Button view for the filter option.
    private func footerFilterButton(label: String, type: String, gradientColors: [Color]) -> some View {
        Button {
            doLedgerType(type)
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: 1)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
        }
        .padding(.leading, 4)
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

    // MARK: - Actions (Matching Ionic Methods)

    /// Handles tapping the footer logo. If the user has multiple accounts, opens the account
    /// picker dialog. Matches the Ionic doFooterLogoClick() method.
    private func doFooterLogoClick() {
        if user.Accounts.count > 1 {
            showAccountPicker = true
        }
    }

    /// Handles tapping a ledger type filter button (ALL/INCOME/EXPENSES).
    /// Resets to page 1, sets the filter type, switches to the ledger tab, and reloads data.
    /// Matches the Ionic doLedgerType() method.
    ///
    /// - Parameter type: The filter type string ("", "income", or "expense").
    private func doLedgerType(_ type: String) {
        currentPage = 1
        ledgersType = type
        selectedTab = "ledger"
        Task {
            await loadPageData()
        }
    }

    /// Handles tapping the Ledger segment tab. Resets search, filter, and page state
    /// then reloads data. Matches the Ionic doLedgerTabClick() method.
    private func doLedgerTabClick() {
        ledgersSearch = ""
        ledgersSearchTerm = ""
        currentPage = 1
        ledgersType = ""
        Task {
            await loadPageData()
        }
    }

    /// Performs a search query on the ledger. Copies the search term to the active search,
    /// resets page and type, then reloads data. Matches the Ionic doLedgerSearch() method.
    private func doLedgerSearch() {
        ledgersSearch = ledgersSearchTerm
        currentPage = 1
        ledgersType = ""
        Task {
            await loadPageData()
        }
    }

    // MARK: - Data Loading

    /// Loads all initial data when the view first appears. Fetches the user profile
    /// to determine which accounts are available, sets the active account from
    /// UserDefaults (or defaults to the first account), then loads all page data.
    private func loadInitialData() {
        Task {
            await loadUserAndData()
        }
    }

    /// Fetches the user profile and then loads all data for the active account.
    /// First calls MeService.getMe() to get the user's accounts list, then determines
    /// which account to use based on the stored account_id in UserDefaults. If no
    /// stored account ID exists, falls back to the first account in the user's list.
    /// Also sets the activeTableHeader based on account count (matching Ionic loadMe logic).
    private func loadUserAndData() async {
        isLoading = true

        do {
            // Fetch the authenticated user's profile to get their accounts list.
            let fetchedUser = try await MeService.shared.getMe()
            await MainActor.run {
                user = fetchedUser

                // Set header mode based on number of accounts (matching Ionic logic).
                if fetchedUser.Accounts.count > 1 {
                    activeTableHeader = "account"
                } else {
                    activeTableHeader = "cols"
                }
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

            // Load all page data (ledgers, snapclerks, P&L).
            await loadPageData()

            await MainActor.run {
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

    /// Loads all page data: P&L, ledger entries, and Snap!Clerk entries concurrently.
    /// Matches the Ionic loadPageData() method which calls getPnL, loadLedgerData,
    /// and loadSnapClerkData together. Each data source loads independently so a
    /// failure in one (e.g. SnapClerk 404) doesn't block the others.
    private func loadPageData() async {
        let searchParam: String? = ledgersSearch.isEmpty ? nil : ledgersSearch
        let typeParam: String? = ledgersType.isEmpty ? nil : ledgersType

        // Load ledger and P&L together — these are critical.
        do {
            async let ledgerResult = LedgerService.shared.getLedgers(page: currentPage, type: typeParam, search: searchParam)
            async let pnlResult = ReportService.shared.getPnlCurrentYear()

            let (fetchedLedgers, fetchedPnl) = try await (ledgerResult, pnlResult)

            await MainActor.run {
                if currentPage <= 1 {
                    ledgers = fetchedLedgers.ledgers
                } else {
                    ledgers.append(contentsOf: fetchedLedgers.ledgers)
                }
                isLastPage = fetchedLedgers.lastPage
                pnl = fetchedPnl
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }

        // Load SnapClerk independently — a failure here just leaves the list empty.
        do {
            let fetchedSnapClerks = try await SnapClerkService.shared.getSnapClerks(page: 1)
            await MainActor.run {
                snapclerks = fetchedSnapClerks.snapclerks
                isSnapClerkLastPage = fetchedSnapClerks.lastPage
                snapClerkPage = 1
            }
        } catch {
            // SnapClerk may not be available for all accounts — silently ignore.
        }
    }

    /// Refreshes ledger data by resetting to page 1 and reloading with the current filter.
    /// Called by pull-to-refresh on the ledger list. Also refreshes the P&L report and snapclerks.
    private func refreshLedgerData() async {
        currentPage = 1
        await loadPageData()
    }

    /// Loads the next page of ledger entries and appends them to the existing list.
    /// Called when the user taps the "Load More" button. Increments the page counter
    /// and updates the isLastPage flag.
    private func loadMoreLedgers() async {
        let nextPage = currentPage + 1

        do {
            let searchParam: String? = ledgersSearch.isEmpty ? nil : ledgersSearch
            let typeParam: String? = ledgersType.isEmpty ? nil : ledgersType
            let result = try await LedgerService.shared.getLedgers(page: nextPage, type: typeParam, search: searchParam)

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

    /// Switches the active account to the given account. Stores the new account ID
    /// in UserDefaults so all API calls use the correct account endpoint, then
    /// reloads all data for the newly selected account. Matches Ionic doAccountChange().
    ///
    /// - Parameter account: The Account to switch to.
    private func switchAccount(to account: Account) {
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
            await loadPageData()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService.shared)
}
