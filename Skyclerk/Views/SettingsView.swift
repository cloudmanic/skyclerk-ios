//
// SettingsView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The settings panel view embedded in the Home view's Settings tab.
/// This is a pixel-perfect match of the Ionic Skyclerk settings component.
/// It uses a light gray grouped-list background (#f2f2f2) with white ion-card-style
/// rows containing disclosure chevrons. Sections are organized into Account, Support,
/// Documents, and App Info with uppercase section headers.
///
/// Each row either opens an inline alert for editing (profile, account name, password)
/// or navigates to an external URL (help center, privacy policy, etc.).
/// The view loads user, account, and billing data on appear, and provides actions
/// for updating profile info, managing subscriptions, closing the account, and logging out.
struct SettingsView: View {
    /// The shared authentication service used to log out the user.
    @EnvironmentObject var authService: AuthService

    /// Environment action for opening external URLs in the default browser.
    @Environment(\.openURL) private var openURL

    /// The currently authenticated user's profile, loaded on appear.
    @State private var user: User = User()

    /// The current account details, loaded on appear.
    @State private var account: Account = Account()

    /// The account's billing/subscription information, loaded on appear.
    @State private var billing: Billing = Billing()

    // MARK: - Color Constants (matching Ionic global.scss)

    /// The light gray background color matching the Ionic settings page.
    /// From global.scss: `background: var(--ion-color-step-50, #f2f2f2)`.
    private let settingsBgColor = Color(hex: "f2f2f2")

    /// The white background for card items matching ion-card default styling.
    private let cardBgColor = Color.white

    /// The danger button gradient bottom color from global.scss `button-danger`.
    /// Linear gradient from #7b2624 (bottom) to #96312d (top).
    private let dangerGradientBottom = Color(hex: "7b2624")

    /// The danger button gradient top color from global.scss `button-danger`.
    private let dangerGradientTop = Color(hex: "96312d")

    /// The divider/border color matching Ionic's default ion-item lines.
    private let dividerColor = Color(hex: "c8c7cc")

    /// The section header text color matching Ionic's uppercase labels.
    private let sectionHeaderColor = Color(hex: "8e8e93")

    /// The chevron/disclosure indicator color matching Ionic's detail arrows.
    private let chevronColor = Color(hex: "c7c7cc")

    /// The note/secondary text color for the version number.
    private let noteColor = Color(hex: "8e8e93")

    // MARK: - User Profile Alert State

    /// Whether the user profile editing alert is currently displayed.
    @State private var showProfileAlert: Bool = false

    /// The first name value in the profile editing alert.
    @State private var editFirstName: String = ""

    /// The last name value in the profile editing alert.
    @State private var editLastName: String = ""

    /// The email value in the profile editing alert.
    @State private var editEmail: String = ""

    // MARK: - Account Name Alert State

    /// Whether the account name editing alert is currently displayed.
    @State private var showAccountAlert: Bool = false

    /// The account name value in the account name editing alert.
    @State private var editAccountName: String = ""

    // MARK: - Change Password Alert State

    /// Whether the change password alert is currently displayed.
    @State private var showPasswordAlert: Bool = false

    /// The current password field value in the change password alert.
    @State private var currentPassword: String = ""

    /// The new password field value in the change password alert.
    @State private var newPassword: String = ""

    /// The confirm password field value in the change password alert.
    @State private var confirmPassword: String = ""

    // MARK: - Close Account Alert State

    /// Whether the close account confirmation alert is currently displayed.
    @State private var showCloseAccountAlert: Bool = false

    // MARK: - Stripe Subscription Alert State

    /// Whether the Stripe subscription management alert is currently displayed.
    @State private var showStripeAlert: Bool = false

    // MARK: - General Alert State

    /// Whether a general-purpose error/success alert is currently displayed.
    @State private var showAlert: Bool = false

    /// The title for the general-purpose alert.
    @State private var alertTitle: String = ""

    /// The message for the general-purpose alert.
    @State private var alertMessage: String = ""

    /// Whether the PaywallView sheet is presented.
    @State private var showPaywall: Bool = false

    /// The main view body. Displays grouped settings sections matching the Ionic app's
    /// light-themed settings page. Uses a #f2f2f2 background with white card rows,
    /// standard iOS-style dividers, and uppercase section headers. Sections include
    /// Account, Support, Documents, App Info, and a red logout button at the bottom.
    var body: some View {
        ZStack {
            // Full-screen light gray background matching Ionic's settings background.
            settingsBgColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 30)

                    // Account settings section: profile, account name, password, subscription.
                    accountSection

                    // Support section: help center, contact, close account.
                    supportSection

                    // Documents section: privacy policy, terms of service.
                    documentsSection

                    // App info section: version number.
                    appInfoSection

                    // Full-width red logout button matching Ionic's danger button gradient.
                    logoutButton

                    Spacer()
                        .frame(height: 30)
                }
            }
        }
        .onAppear {
            loadSettingsData()
        }
        // User profile editing alert with text fields for first name, last name, and email.
        .alert("User Profile", isPresented: $showProfileAlert) {
            TextField("First Name", text: $editFirstName)
                .textInputAutocapitalization(.words)
            TextField("Last Name", text: $editLastName)
                .textInputAutocapitalization(.words)
            TextField("Email", text: $editEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)

            Button("Update") {
                saveProfile()
            }

            Button("Cancel", role: .cancel) {}
        }
        // Account name editing alert with a single text field.
        .alert("Account Name", isPresented: $showAccountAlert) {
            TextField("Account Name", text: $editAccountName)
                .textInputAutocapitalization(.words)

            Button("Update") {
                saveAccountName()
            }

            Button("Cancel", role: .cancel) {}
        }
        // Change password alert with three secure fields: current, new, and confirm.
        .alert("Change Password", isPresented: $showPasswordAlert) {
            SecureField("Current Password", text: $currentPassword)
            SecureField("Password", text: $newPassword)
            SecureField("Password Confirm", text: $confirmPassword)

            Button("Update") {
                savePassword()
            }

            Button("Cancel", role: .cancel) {}
        }
        // Close account confirmation alert matching the Ionic wording exactly.
        .alert("Close Down Account", isPresented: $showCloseAccountAlert) {
            Button("Yes, I am sure.", role: .destructive) {
                closeAccount()
            }

            Button("No, just joking.", role: .cancel) {}
        } message: {
            Text("Are you sure you want to close down your account? ALL YOUR DATA WILL BE LOST FOREVER.")
        }
        // Stripe subscription management alert matching the Ionic alert.
        .alert("Subscription Via Website", isPresented: $showStripeAlert) {
            Button("Cancel", role: .cancel) {}

            Button("Go to app.skyclerk.com") {
                if let url = URL(string: "https://app.skyclerk.com/settings/billing") {
                    openURL(url)
                }
            }
        } message: {
            Text("It seems you have upgraded your account via our website. Please visit https://app.skyclerk.com to manage your subscription.")
        }
        // General-purpose alert for success/error messages.
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        // Sheet presentation for the PaywallView when user has no payment processor.
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") {
                                showPaywall = false
                            }
                            .foregroundColor(Color.appLink)
                        }
                    }
                    .toolbarBackground(Color(hex: "1b2125"), for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
    }

    // MARK: - Account Section

    /// The Account settings section matching the Ionic layout. Contains rows for
    /// User Profile, Account Name, Change Password, and a subscription row whose
    /// label varies based on the billing PaymentProcessor value:
    /// - "Apple In-App": "Manage Subscription" (opens App Store subscriptions)
    /// - "Stripe": "Manage Subscription" (shows website alert)
    /// - "None": "Setup Your Subscription" (opens PaywallView)
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Uppercase section header with left margin matching Ionic's ion-label.
            sectionHeader("ACCOUNT")

            VStack(spacing: 0) {
                // User Profile row - opens an alert with editable profile fields.
                settingsRow(title: "User Profile", showDivider: true) {
                    editFirstName = user.FirstName
                    editLastName = user.LastName
                    editEmail = user.Email
                    showProfileAlert = true
                }

                // Account Name row - opens an alert with the account name field.
                settingsRow(title: "Account Name", showDivider: true) {
                    editAccountName = account.Name
                    showAccountAlert = true
                }

                // Change Password row - opens an alert with password fields.
                settingsRow(title: "Change Password", showDivider: true) {
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    showPasswordAlert = true
                }

                // Subscription row - label and action depend on the payment processor.
                subscriptionRow
            }
            .background(cardBgColor)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Subscription Row

    /// The subscription management row whose label and behavior changes based on
    /// the billing PaymentProcessor field, exactly matching the Ionic template:
    /// - "Apple In-App" => "Manage Subscription" (opens App Store)
    /// - "Stripe" => "Manage Subscription" (shows website alert)
    /// - "None" => "Setup Your Subscription" (opens PaywallView)
    private var subscriptionRow: some View {
        Group {
            if billing.PaymentProcessor == "Apple In-App" {
                // Apple subscription - link to App Store subscription management.
                settingsRow(title: "Manage Subscription", showDivider: false) {
                    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                        openURL(url)
                    }
                }
            } else if billing.PaymentProcessor == "Stripe" {
                // Stripe subscription - show alert directing user to the website.
                settingsRow(title: "Manage Subscription", showDivider: false) {
                    showStripeAlert = true
                }
            } else {
                // No payment processor - navigate to the PaywallView.
                settingsRow(title: "Setup Your Subscription", showDivider: false) {
                    showPaywall = true
                }
            }
        }
    }

    // MARK: - Support Section

    /// The Support settings section matching the Ionic layout. Contains rows for
    /// Help Center, Contact Support, and Close My Account. Help and contact rows
    /// open external URLs. Close account shows a destructive confirmation alert.
    /// Note: In the Ionic app, "Close My Account" is standard text color (not red).
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Uppercase section header with left margin.
            sectionHeader("SUPPORT")

            VStack(spacing: 0) {
                // Help Center row - opens the Skyclerk support page in the browser.
                settingsRow(title: "Help Center", showDivider: true) {
                    if let url = URL(string: "https://skyclerk.com/support") {
                        openURL(url)
                    }
                }

                // Contact Support row - opens the Skyclerk contact page in the browser.
                settingsRow(title: "Contact Support", showDivider: true) {
                    if let url = URL(string: "https://skyclerk.com/contact-us") {
                        openURL(url)
                    }
                }

                // Close My Account row - shows a destructive confirmation alert.
                settingsRow(title: "Close My Account", showDivider: false) {
                    showCloseAccountAlert = true
                }
            }
            .background(cardBgColor)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Documents Section

    /// The Documents settings section matching the Ionic layout. Contains rows for
    /// Privacy Policy and Terms of Service, both opening external URLs in the browser.
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Uppercase section header with left margin.
            sectionHeader("DOCUMENTS")

            VStack(spacing: 0) {
                // Privacy Policy row - opens the Skyclerk privacy policy page.
                settingsRow(title: "Privacy Policy", showDivider: true) {
                    if let url = URL(string: "https://skyclerk.com/privacy-policy") {
                        openURL(url)
                    }
                }

                // Terms of Service row - opens the Skyclerk terms page.
                settingsRow(title: "Terms of Service", showDivider: false) {
                    if let url = URL(string: "https://skyclerk.com/terms-of-service") {
                        openURL(url)
                    }
                }
            }
            .background(cardBgColor)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - App Info Section

    /// The App Info settings section matching the Ionic layout. Displays the current
    /// app version number in a non-interactive row with a right-aligned note.
    /// The Ionic version uses `ion-note slot="end"` for the version text.
    /// This section has `lines="none"` in Ionic, meaning no bottom border.
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Uppercase section header with left margin.
            sectionHeader("APP INFO")

            HStack {
                Text("Version")
                    .font(.system(size: 17))
                    .foregroundColor(.black)

                Spacer()

                Text(AppEnvironment.version)
                    .font(.system(size: 17))
                    .foregroundColor(noteColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(cardBgColor)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Logout Button

    /// The full-width red logout button at the bottom of the settings panel.
    /// Matches the Ionic `ion-button expand="block" class="danger"` styling,
    /// which uses a red gradient background from #7b2624 to #96312d, white text,
    /// 2px solid #141414 border, 6px border radius, and 50px height.
    private var logoutButton: some View {
        Button {
            AuthService.shared.logout()
        } label: {
            Text("Logout")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [dangerGradientBottom, dangerGradientTop]),
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
        .padding(.horizontal, 16)
    }

    // MARK: - Reusable Components

    /// Creates a section header label styled in uppercase with gray text and left margin,
    /// matching the Ionic `ion-label text-uppercase` with `margin-left: 20px`.
    ///
    /// - Parameter title: The section title to display (e.g., "ACCOUNT", "SUPPORT").
    /// - Returns: A styled Text view for the section header.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(sectionHeaderColor)
            .textCase(.uppercase)
            .padding(.leading, 4)
            .padding(.bottom, 6)
            .padding(.top, 4)
    }

    /// Creates a single settings row matching the Ionic `ion-item detail="true"` style.
    /// Each row has a title label on the left and an iOS-style chevron disclosure indicator
    /// on the right. Rows use the standard 44pt touch target height and have a divider
    /// that starts with 16px left inset (matching Ionic's `lines="full"`).
    ///
    /// - Parameters:
    ///   - title: The display text for the row.
    ///   - showDivider: Whether to show a bottom divider line below the row.
    ///   - action: The closure to execute when the row is tapped.
    /// - Returns: A styled Button view representing a settings row.
    private func settingsRow(title: String, showDivider: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button {
                action()
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 17))
                        .foregroundColor(.black)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(chevronColor)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showDivider {
                Rectangle()
                    .fill(dividerColor)
                    .frame(height: 0.5)
                    .padding(.leading, 16)
            }
        }
    }

    // MARK: - Actions

    /// Loads user profile, account details, and billing information from the API.
    /// Called on view appear. Silently logs errors to the console since the view
    /// can still display with partial data.
    private func loadSettingsData() {
        Task {
            do {
                let fetchedUser = try await MeService.shared.getMe()
                let fetchedAccount = try await AccountService.shared.getAccount()
                let fetchedBilling = try await AccountService.shared.getBilling()

                await MainActor.run {
                    user = fetchedUser
                    account = fetchedAccount
                    billing = fetchedBilling
                }
            } catch {
                print("Failed to load settings data: \(error.localizedDescription)")
            }
        }
    }

    /// Saves the updated user profile (first name, last name, email) to the API.
    /// Validates all three fields are non-empty before submitting, matching the
    /// Ionic validation: "First name field is required", "Last name field is required",
    /// "Email field is required". Shows a success alert on completion or error on failure.
    private func saveProfile() {
        let firstName = editFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = editLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = editEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate that required fields are not empty, matching Ionic field-by-field checks.
        if firstName.isEmpty {
            alertTitle = "Oops!"
            alertMessage = "First name field is required."
            showAlert = true
            return
        }

        if lastName.isEmpty {
            alertTitle = "Oops!"
            alertMessage = "Last name field is required."
            showAlert = true
            return
        }

        if email.isEmpty {
            alertTitle = "Oops!"
            alertMessage = "Email field is required."
            showAlert = true
            return
        }

        Task {
            do {
                try await MeService.shared.updateProfile(
                    firstName: firstName,
                    lastName: lastName,
                    email: email
                )

                await MainActor.run {
                    user.FirstName = firstName
                    user.LastName = lastName
                    user.Email = email
                    alertTitle = "Success!"
                    alertMessage = "Your profile has been updated."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Oops!"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    /// Saves the updated account name to the API. Validates the field is non-empty
    /// matching the Ionic message "Please fill out all fields.".
    /// Updates the local account state on success.
    private func saveAccountName() {
        let name = editAccountName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate that the account name is not empty.
        guard !name.isEmpty else {
            alertTitle = "Oops!"
            alertMessage = "Please fill out all fields."
            showAlert = true
            return
        }

        Task {
            do {
                var updatedAccount = account
                updatedAccount.Name = name
                let result = try await AccountService.shared.updateAccount(account: updatedAccount)

                await MainActor.run {
                    account = result
                    alertTitle = "Success!"
                    alertMessage = "Your account name has been updated."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Oops!"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    /// Validates the password fields and calls the API to change the user's password.
    /// Matches the Ionic validation: checks all fields filled ("Please fill out all fields.")
    /// then checks passwords match ("Passwords did not match.").
    /// Shows success or error alert matching the Ionic wording.
    private func savePassword() {
        // Validate that all password fields are filled in.
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            alertTitle = "Oops!"
            alertMessage = "Please fill out all fields."
            showAlert = true
            return
        }

        // Validate that the new password and confirmation match.
        guard newPassword == confirmPassword else {
            alertTitle = "Oops!"
            alertMessage = "Passwords did not match."
            showAlert = true
            return
        }

        Task {
            do {
                try await MeService.shared.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                    confirmPassword: confirmPassword
                )

                await MainActor.run {
                    alertTitle = "Success!"
                    alertMessage = "Your password was successfully updated."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Oops!"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    /// Deletes the user's account permanently and logs them out.
    /// Calls AccountService.deleteAccount() followed by AuthService.logout().
    /// On success shows "Your account was successfully deleted." then logs out.
    /// On failure shows the API error message, matching the Ionic behavior.
    private func closeAccount() {
        Task {
            do {
                try await AccountService.shared.deleteAccount()
                await MainActor.run {
                    alertTitle = "Success!"
                    alertMessage = "Your account was successfully deleted."
                    showAlert = true
                    AuthService.shared.logout()
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Oops!"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthService.shared)
    }
}
