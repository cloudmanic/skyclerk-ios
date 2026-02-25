//
// RegisterView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The registration form screen where new users can create a free Skyclerk account.
/// Displays a title with "FREE" highlighted in green, form fields for name, email,
/// and password (with confirmation), and a green "Create Account" submit button.
/// On submit, validates all fields, splits the name into first/last components,
/// and calls authService.register() to create the account and auto-login.
struct RegisterView: View {
    /// The shared authentication service injected from the parent view hierarchy.
    /// Used to call the register method and update the authentication state.
    @EnvironmentObject var authService: AuthService

    /// Binding to the parent NavigationStack path, allowing this view to
    /// navigate back to the intro screen via the cancel button.
    @Binding var navigationPath: NavigationPath

    /// The user's full name entered in the text field. Will be split into
    /// first and last name at the first space character before submission.
    @State private var name: String = ""

    /// The user's email address entered in the text field.
    @State private var email: String = ""

    /// The user's chosen password entered in the secure field.
    @State private var password: String = ""

    /// The password confirmation entered in the second secure field.
    /// Must match the password field for the form to be valid.
    @State private var confirmPassword: String = ""

    /// Whether a registration request is currently in progress. Used to disable
    /// the submit button and show a loading indicator during the API call.
    @State private var isLoading: Bool = false

    /// Whether the error alert is currently displayed.
    @State private var showError: Bool = false

    /// The error message to display in the alert when validation or registration fails.
    @State private var errorMessage: String = ""

    /// The main view body. Displays the registration form inside a ScrollView with
    /// a dark background. Includes the title with highlighted text, form fields,
    /// and a green submit button. A bottom toolbar provides cancel and logo options.
    var body: some View {
        ZStack {
            // Full-screen dark background that extends to all edges.
            Color.appDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    // Screen title with "FREE" highlighted in green.
                    titleSection

                    // Name, email, password, and confirm password input fields.
                    formFieldsSection

                    // Green "Create Account" submit button.
                    actionButtonSection

                    Spacer()
                }
                .padding(.horizontal, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Bottom toolbar with cancel button on the left and logo on the right.
            ToolbarItemGroup(placement: .bottomBar) {
                bottomToolbarContent
            }
        }
        .toolbarBackground(Color.appDarkGray, for: .bottomBar)
        .toolbarBackground(.visible, for: .bottomBar)
        .toolbarColorScheme(.dark, for: .bottomBar)
        .darkToolbar()
        .alert("Registration Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    /// The screen title section displayed at the top of the form.
    /// Uses an attributed text approach to show "Create your" and "Skyclerk Account"
    /// in white, with "FREE" prominently displayed in the app's green success color.
    private var titleSection: some View {
        HStack(spacing: 0) {
            (Text("Create your ")
                .foregroundColor(.white) +
            Text("FREE")
                .foregroundColor(Color.appSuccess)
                .fontWeight(.heavy) +
            Text(" Skyclerk Account")
                .foregroundColor(.white))
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    /// The form fields section containing inputs for name, email, password, and
    /// password confirmation. Each field has a label above it with an asterisk
    /// indicating it is required. The email field uses the email keyboard type.
    /// Password fields use SecureField for masked input.
    private var formFieldsSection: some View {
        VStack(spacing: 18) {
            // Full name input field.
            VStack(alignment: .leading, spacing: 6) {
                Text("Name *")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appTextGray)

                TextField("", text: $name)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.appDarkGray)
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }

            // Email address input field.
            VStack(alignment: .leading, spacing: 6) {
                Text("Email Address *")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appTextGray)

                TextField("", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.appDarkGray)
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }

            // Password input field.
            VStack(alignment: .leading, spacing: 6) {
                Text("Password *")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appTextGray)

                SecureField("", text: $password)
                    .textContentType(.newPassword)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.appDarkGray)
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }

            // Confirm password input field.
            VStack(alignment: .leading, spacing: 6) {
                Text("Confirm Password *")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appTextGray)

                SecureField("", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.appDarkGray)
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
        }
    }

    /// The submit button section with a green "Create Account" button styled
    /// using the app's success color. Shows a loading spinner when a request
    /// is in progress and is disabled during loading to prevent double submissions.
    private var actionButtonSection: some View {
        Button {
            performRegistration()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Account")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appSuccess)
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }

    /// The bottom toolbar content with a cancel button on the left that
    /// navigates back to the intro screen, and a small logo placeholder
    /// on the right side.
    private var bottomToolbarContent: some View {
        HStack {
            Button {
                navigationPath = NavigationPath()
            } label: {
                Text("Cancel and go Back")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appTextGray)
            }

            Spacer()

            // Small logo placeholder in the toolbar.
            Image(systemName: "dollarsign.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(Color.appLink)
        }
    }

    /// Validates all form fields and initiates the registration request.
    /// Checks that all fields are non-empty and that the two password fields match.
    /// Splits the name into first and last name components at the first space character.
    /// If the name has no space, the entire value is used as the first name and the
    /// last name defaults to an empty string. Shows an error alert on validation
    /// failure or API error.
    private func performRegistration() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate that all required fields are filled in.
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter your name."
            showError = true
            return
        }

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            showError = true
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter a password."
            showError = true
            return
        }

        guard !confirmPassword.isEmpty else {
            errorMessage = "Please confirm your password."
            showError = true
            return
        }

        // Validate that the passwords match.
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match. Please try again."
            showError = true
            return
        }

        // Split the name into first and last name at the first space.
        // If there is no space, use the full name as the first name.
        let firstName: String
        let lastName: String

        if let spaceIndex = trimmedName.firstIndex(of: " ") {
            firstName = String(trimmedName[trimmedName.startIndex..<spaceIndex])
            lastName = String(trimmedName[trimmedName.index(after: spaceIndex)...])
        } else {
            firstName = trimmedName
            lastName = ""
        }

        isLoading = true

        Task {
            do {
                try await authService.register(
                    email: trimmedEmail,
                    password: password,
                    firstName: firstName,
                    lastName: lastName
                )
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView(navigationPath: .constant(NavigationPath()))
            .environmentObject(AuthService.shared)
    }
}
