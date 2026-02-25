//
// LoginView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The login form screen where users enter their email and password to
/// authenticate with their existing Skyclerk account. Displays a centered
/// title, email and password fields, a submit button, and a link to the
/// registration screen. Uses an async task to call AuthService.login()
/// and displays an alert on authentication failure.
struct LoginView: View {
    /// The shared authentication service injected from the parent view hierarchy.
    /// Used to call the login method and update the authentication state.
    @EnvironmentObject var authService: AuthService

    /// Binding to the parent NavigationStack path, allowing this view to
    /// navigate to the register screen or pop back to the intro screen.
    @Binding var navigationPath: NavigationPath

    /// The user's email address entered in the text field.
    @State private var email: String = ""

    /// The user's password entered in the secure field.
    @State private var password: String = ""

    /// Whether a login request is currently in progress. Used to disable
    /// the submit button and show a loading indicator during authentication.
    @State private var isLoading: Bool = false

    /// Whether the error alert is currently displayed.
    @State private var showError: Bool = false

    /// The error message to display in the alert when login fails.
    @State private var errorMessage: String = ""

    /// The main view body. Displays the login form inside a ScrollView with
    /// a dark background. Includes the title, form fields, submit button,
    /// and registration link. A bottom toolbar provides cancel and logo options.
    var body: some View {
        ZStack {
            // Full-screen dark background that extends to all edges.
            Color.appDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)

                    // Screen title centered at the top.
                    titleSection

                    // Email and password input fields.
                    formFieldsSection

                    // Submit button and registration link.
                    actionButtonsSection

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
        .alert("Login Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    /// The screen title displayed prominently at the top of the form.
    /// Shows "Add Your Account" in white bold text, centered horizontally.
    private var titleSection: some View {
        Text("Add Your Account")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    /// The form fields section containing the email and password inputs.
    /// Each field has a label above it with an asterisk indicating it is required.
    /// The email field uses the email keyboard type and disables autocorrection.
    /// The password field uses a SecureField for masked input.
    private var formFieldsSection: some View {
        VStack(spacing: 18) {
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
                    .textContentType(.password)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.appDarkGray)
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
        }
    }

    /// The action buttons section containing the primary submit button and
    /// a secondary link to the registration screen. The submit button is
    /// styled with a white/light appearance, shows a loading spinner when
    /// a request is in progress, and is disabled during loading.
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary submit button that triggers the login action.
            Button {
                performLogin()
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(Color.appDark)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Text("Add Your Skyclerk Account")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color.appDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(10)
            }
            .disabled(isLoading)

            // Secondary registration prompt and link.
            VStack(spacing: 6) {
                Text("Don't have an account?")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appTextGray)

                Button {
                    navigationPath.append("register")
                } label: {
                    Text("Register for a Skyclerk account now!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.appLink)
                }
            }
        }
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

    /// Validates the form fields and initiates the login request.
    /// Checks that both email and password are non-empty before calling
    /// authService.login(). Sets isLoading to true during the request
    /// and displays an error alert if the request fails.
    private func performLogin() {
        // Validate that required fields are not empty.
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter your email address."
            showError = true
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter your password."
            showError = true
            return
        }

        isLoading = true

        Task {
            do {
                try await authService.login(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
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
        LoginView(navigationPath: .constant(NavigationPath()))
            .environmentObject(AuthService.shared)
    }
}
