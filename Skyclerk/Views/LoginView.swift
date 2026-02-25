//
// LoginView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The login form screen where users enter their email and password to
/// authenticate with their existing Skyclerk account. Matches the Ionic
/// app's login page pixel-for-pixel: dark #232323 content background,
/// #141414 form card with rounded corners and box shadow, white input
/// fields with 5px radius, a gradient light-gray "Add Your Skyclerk Account"
/// button with plus icon, a "Don't have an account?" section, and a dark
/// footer toolbar with cancel link and small logo.
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

    /// The main view body. Renders the full login screen with a dark background,
    /// a form card container, input fields, submit button, register link, and
    /// a dark footer toolbar matching the Ionic app's layout exactly.
    var body: some View {
        ZStack {
            // Full-screen content background matching Ionic's ion-content --background: #232323.
            Color(hex: "232323")
                .ignoresSafeArea()

            ScrollView {
                // Form card container matching Ionic's .form-content styling:
                // background: $dark (#141414), padding: 16px, border-radius: 10px,
                // box-shadow for depth effect.
                VStack(spacing: 0) {
                    // Title: "Add Your Account" matching Ionic's h3 styling inside
                    // app-login [income] .form-content: color white, font-size 30px,
                    // margin 0, centered.
                    titleSection

                    // Spacer between title and form fields.
                    Spacer()
                        .frame(height: 16)

                    // Email and password input fields matching Ionic's login-form-list
                    // styling with stacked labels and white input backgrounds.
                    formFieldsSection

                    // Primary submit button matching Ionic's button-light button-custom
                    // styling with gradient background and plus icon.
                    submitButtonSection

                    // "Don't have an account?" section matching Ionic's .create-account
                    // styling with centered text and link button.
                    createAccountSection
                }
                .padding(16)
                .background(Color.appDark)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.75), radius: 16, x: 0, y: 0)
                .padding(.horizontal, 12)
            }
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            // Bottom toolbar matching Ionic's ion-footer with dark toolbar,
            // cancel button on the left and small logo on the right.
            HStack {
                Button {
                    navigationPath = NavigationPath()
                } label: {
                    Text("\u{00AB} Cancel and go Back")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "f4f5f8"))
                        .textCase(.uppercase)
                }
                Spacer()
                Image("logo-small")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(height: 20)
                    .foregroundColor(Color(hex: "808080"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "2c2c2c"))
        }
        .alert("Oops! Login Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    /// The screen title displayed at the top of the form card.
    /// Matches Ionic's app-login h3: color white (#fff), font-size 30px,
    /// font-weight 700 (bold), padding 10px 0 5px, margin 0, text-center.
    private var titleSection: some View {
        Text("Add Your Account")
            .font(.system(size: 30, weight: .bold))
            .foregroundColor(.white)
            .padding(.top, 10)
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    /// The form fields section containing the email and password inputs.
    /// Matches Ionic's [login-form-list] styling: transparent background,
    /// margin-bottom 16px. Each ion-item has transparent background, stacked
    /// label (16px, font-weight 600, color #bcbcbc), and white input field
    /// (height 42px, border-radius 5px, margin-top 10px, padding 8px).
    private var formFieldsSection: some View {
        VStack(spacing: 0) {
            // Email address input field matching Ionic's stacked label + input pattern.
            VStack(alignment: .leading, spacing: 0) {
                Text("Email Address *")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "bcbcbc"))

                TextField("", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 8)
                    .frame(height: 42)
                    .background(Color.white)
                    .cornerRadius(5)
                    .foregroundColor(.black)
                    .padding(.top, 10)
            }

            Spacer()
                .frame(height: 16)

            // Password input field matching Ionic's stacked label + input pattern.
            VStack(alignment: .leading, spacing: 0) {
                Text("Password *")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "bcbcbc"))

                SecureField("", text: $password)
                    .textContentType(.password)
                    .padding(.horizontal, 8)
                    .frame(height: 42)
                    .background(Color.white)
                    .cornerRadius(5)
                    .foregroundColor(.black)
                    .padding(.top, 10)
            }
        }
        .padding(.bottom, 16)
    }

    /// The primary submit button matching Ionic's button-light button-custom styling:
    /// --background: linear-gradient(0deg, #939393 0%, #c3c3c3 100%),
    /// --border-radius: 6px, height 50px (min-height 60px for size="large"),
    /// --border-width: 2px, --border-style: solid, --border-color: #141414,
    /// box-shadow with inset white highlight and outer glow,
    /// plus.svg icon (24px height) with 10px margin-right, white text color.
    private var submitButtonSection: some View {
        Button {
            performLogin()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    // Plus icon matching Ionic's <img img-left src="assets/imgs/plus.svg">
                    // with height: 24px and margin-right: 10px.
                    Image("plus")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)

                    Text("Add Your Skyclerk Account")
                        .font(.system(size: 16, weight: .regular))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "c3c3c3"),
                        Color(hex: "939393")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(hex: "141414"), lineWidth: 2)
            )
            .overlay(
                // Inset highlight matching Ionic box-shadow: inset 0px 2px 0px rgba(255,255,255,0.32).
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(0.32), lineWidth: 1)
                    .padding(2)
            )
            .shadow(color: Color.white.opacity(0.28), radius: 8, x: 0, y: 0)
        }
        .disabled(isLoading)
    }

    /// The "Don't have an account?" section matching Ionic's .create-account styling
    /// inside app-login: height 30vh (approximated), margin-top 1rem, centered
    /// vertically and horizontally. Paragraph text is white, 16px.
    /// Link button uses color="link" which maps to #b2d6ec.
    private var createAccountSection: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 24)

            VStack(spacing: 8) {
                Text("Don't have an account?")
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                Button {
                    navigationPath.append("register")
                } label: {
                    Text("Register for a Skyclerk account now!")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "b2d6ec"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    /// Validates the form fields and initiates the login request.
    /// Checks that both email and password are non-empty before calling
    /// authService.login(). Sets isLoading to true during the request
    /// and displays an alert on authentication failure. Error alert matches
    /// Ionic's doErrorAlert with header "Oops! Login Error".
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
