//
// SettingsView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The settings panel view embedded in the Home view's Settings tab.
/// Organizes settings into grouped sections: Account, Support, Documents, and App Info.
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

    // MARK: - General Alert State

    /// Whether a general-purpose error/success alert is currently displayed.
    @State private var showAlert: Bool = false

    /// The title for the general-purpose alert.
    @State private var alertTitle: String = ""

    /// The message for the general-purpose alert.
    @State private var alertMessage: String = ""

    /// The main view body. Displays grouped settings sections inside a ScrollView
    /// with a dark background. Sections include Account, Support, Documents, App Info,
    /// and a logout button at the bottom.
    var body: some View {
        ZStack {
            // Full-screen dark background that extends to all edges.
            Color.appDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 10)

                    // Account settings section: profile, account name, password, subscription.
                    accountSection

                    // Support section: help center, contact, close account.
                    supportSection

                    // Documents section: privacy policy, terms of service.
                    documentsSection

                    // App info section: version number.
                    appInfoSection

                    // Full-width red logout button at the bottom.
                    logoutButton

                    Spacer()
                        .frame(height: 20)
                }
                .padding(.horizontal, 20)
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

            Button("Save") {
                saveProfile()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Update your profile information.")
        }
        // Account name editing alert with a single text field.
        .alert("Account Name", isPresented: $showAccountAlert) {
            TextField("Account Name", text: $editAccountName)
                .textInputAutocapitalization(.words)

            Button("Save") {
                saveAccountName()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Update your account name.")
        }
        // Change password alert with three secure fields: current, new, and confirm.
        .alert("Change Password", isPresented: $showPasswordAlert) {
            SecureField("Current Password", text: $currentPassword)
            SecureField("New Password", text: $newPassword)
            SecureField("Confirm Password", text: $confirmPassword)

            Button("Change") {
                savePassword()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your current password and choose a new one.")
        }
        // Close account confirmation alert with destructive warning.
        .alert("Close Account", isPresented: $showCloseAccountAlert) {
            Button("Close My Account", role: .destructive) {
                closeAccount()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to close down your account? ALL YOUR DATA WILL BE LOST FOREVER.")
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

    /// The Account settings section. Contains rows for User Profile, Account Name,
    /// Change Password, and Manage Subscription. Each row is styled as a card with
    /// a chevron indicator on the right side.
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header label.
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

                // Manage Subscription row - behavior depends on the payment processor.
                settingsRow(title: "Manage Subscription", showDivider: false) {
                    handleManageSubscription()
                }
            }
            .background(Color.appDarkGray)
            .cornerRadius(10)
        }
    }

    // MARK: - Support Section

    /// The Support settings section. Contains rows for Help Center, Contact Support,
    /// and Close My Account. Help and contact rows open external URLs. Close account
    /// shows a destructive confirmation alert.
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header label.
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
                settingsRow(title: "Close My Account", titleColor: Color.appDanger, showDivider: false) {
                    showCloseAccountAlert = true
                }
            }
            .background(Color.appDarkGray)
            .cornerRadius(10)
        }
    }

    // MARK: - Documents Section

    /// The Documents settings section. Contains rows for Privacy Policy and Terms of Service.
    /// Both rows open external URLs in the default browser.
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header label.
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
            .background(Color.appDarkGray)
            .cornerRadius(10)
        }
    }

    // MARK: - App Info Section

    /// The App Info settings section. Displays the current app version number
    /// from AppEnvironment.version in a non-interactive row.
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header label.
            sectionHeader("APP INFO")

            HStack {
                Text("Version")
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                Spacer()

                Text(AppEnvironment.version)
                    .font(.system(size: 16))
                    .foregroundColor(Color.appTextGray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.appDarkGray)
            .cornerRadius(10)
        }
    }

    // MARK: - Logout Button

    /// The full-width red logout button at the bottom of the settings panel.
    /// Calls AuthService.logout() to clear credentials and return to the login screen.
    private var logoutButton: some View {
        Button {
            AuthService.shared.logout()
        } label: {
            Text("Logout")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appDanger)
                .cornerRadius(10)
        }
    }

    // MARK: - Reusable Components

    /// Creates a section header label styled in uppercase with gray text and bottom spacing.
    ///
    /// - Parameter title: The section title to display (e.g., "ACCOUNT", "SUPPORT").
    /// - Returns: A styled Text view for the section header.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color.appTextGray)
            .padding(.bottom, 8)
    }

    /// Creates a single settings row with a title, chevron indicator, optional divider,
    /// and a tap action. Used for all interactive rows in the settings sections.
    ///
    /// - Parameters:
    ///   - title: The display text for the row.
    ///   - titleColor: The color of the title text. Defaults to white.
    ///   - showDivider: Whether to show a bottom divider line below the row.
    ///   - action: The closure to execute when the row is tapped.
    /// - Returns: A styled Button view representing a settings row.
    private func settingsRow(title: String, titleColor: Color = .white, showDivider: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button {
                action()
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(titleColor)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.appTextGray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showDivider {
                Divider()
                    .background(Color.appBgDarkGray)
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
    /// Shows a success alert on completion or an error alert on failure.
    /// Updates the local user state with the new values on success.
    private func saveProfile() {
        let firstName = editFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = editLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = editEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate that required fields are not empty.
        guard !firstName.isEmpty, !email.isEmpty else {
            alertTitle = "Error"
            alertMessage = "First name and email are required."
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
                    alertTitle = "Success"
                    alertMessage = "Your profile has been updated."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    /// Saves the updated account name to the API. Shows a success alert on completion
    /// or an error alert on failure. Updates the local account state on success.
    private func saveAccountName() {
        let name = editAccountName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate that the account name is not empty.
        guard !name.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Account name is required."
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
                    alertTitle = "Success"
                    alertMessage = "Your account name has been updated."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    /// Validates the password fields and calls the API to change the user's password.
    /// Checks that the new password and confirmation match before submitting.
    /// Shows a success alert on completion or an error alert on failure.
    private func savePassword() {
        // Validate that all password fields are filled in.
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            alertTitle = "Error"
            alertMessage = "All password fields are required."
            showAlert = true
            return
        }

        // Validate that the new password and confirmation match.
        guard newPassword == confirmPassword else {
            alertTitle = "Error"
            alertMessage = "New password and confirmation do not match."
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
                    alertTitle = "Success"
                    alertMessage = "Your password has been changed."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    /// Handles the "Manage Subscription" row tap based on the account's payment processor.
    /// For Apple subscriptions, opens the App Store subscription management page.
    /// For Stripe subscriptions, opens the Skyclerk web billing settings.
    /// For accounts without a payment processor (e.g., trial), navigates to the PaywallView.
    private func handleManageSubscription() {
        if billing.PaymentProcessor == "apple" {
            // Open the App Store subscriptions management page.
            if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                openURL(url)
            }
        } else if billing.PaymentProcessor == "stripe" {
            // Open the Skyclerk web billing settings page.
            if let url = URL(string: "https://app.skyclerk.com/settings/billing") {
                openURL(url)
            }
        } else {
            // No payment processor: show the in-app paywall.
            showPaywall = true
        }
    }

    /// Whether the PaywallView navigation is active. Set to true when a trial user
    /// taps "Manage Subscription" and no payment processor is configured.
    @State private var showPaywall: Bool = false

    /// Deletes the user's account permanently and logs them out.
    /// Calls AccountService.deleteAccount() followed by AuthService.logout().
    /// Shows an error alert if the deletion fails.
    private func closeAccount() {
        Task {
            do {
                try await AccountService.shared.deleteAccount()
                await MainActor.run {
                    AuthService.shared.logout()
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Error"
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
