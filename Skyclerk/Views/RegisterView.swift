//
// RegisterView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The registration form screen where new users can create a free Skyclerk account.
/// Matches the Ionic app's register page pixel-for-pixel: dark #232323 content
/// background, #141414 form card with rounded corners and box shadow, title with
/// "FREE" highlighted in the link color (#b2d6ec) and the rest in green (#b8cda3)
/// at 35px bold, white input fields with 5px radius, a gradient green "Create Account"
/// button with d-arrow icon, and a dark footer toolbar with cancel link and small logo.
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

    /// The main view body. Renders the full registration screen with a dark background,
    /// a form card container, input fields, submit button, and a dark footer toolbar
    /// matching the Ionic app's register page layout exactly.
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
                    // Title: "Create your FREE SkyClerk Account" matching Ionic's h3 styling
                    // inside [income] .form-content: color #b8cda3, font-size 35px,
                    // font-weight 700, with span colored #b2d6ec for "FREE".
                    titleSection

                    // Spacer between title and form fields.
                    Spacer()
                        .frame(height: 16)

                    // Name, email, password, and confirm password input fields matching
                    // Ionic's login-form-list styling with stacked labels and white inputs.
                    formFieldsSection

                    // Green "Create Account" submit button matching Ionic's button-success
                    // button-custom styling with gradient background and d-arrow icon.
                    submitButtonSection
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
        .alert("Oops! Register Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    /// The screen title section displayed at the top of the form card.
    /// Matches Ionic's [income] .form-content h3: color #b8cda3, font-size 35px,
    /// padding 10px 0 5px, font-weight 700, margin 0, text-center.
    /// The <span> "FREE" uses color $link_color (#b2d6ec).
    /// Line break after "FREE" to match <br> in the HTML.
    private var titleSection: some View {
        VStack(spacing: 0) {
            (Text("Create your ")
                .foregroundColor(Color(hex: "b8cda3")) +
            Text("FREE")
                .foregroundColor(Color(hex: "b2d6ec")))
                .font(.system(size: 35, weight: .bold))
                .multilineTextAlignment(.center)

            Text("SkyClerk Account")
                .font(.system(size: 35, weight: .bold))
                .foregroundColor(Color(hex: "b8cda3"))
        }
        .padding(.top, 10)
        .padding(.bottom, 5)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    /// The form fields section containing inputs for name, email, password, and
    /// password confirmation. Matches Ionic's [login-form-list] styling: transparent
    /// background, margin-bottom 16px. Each item has stacked label (16px, font-weight
    /// 600, color #bcbcbc) and white input field (height 42px, border-radius 5px,
    /// margin-top 10px, padding 8px).
    private var formFieldsSection: some View {
        VStack(spacing: 0) {
            // Name input field matching Ionic's stacked label + input pattern.
            VStack(alignment: .leading, spacing: 0) {
                Text("Name *")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "bcbcbc"))

                TextField("", text: $name)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 8)
                    .frame(height: 42)
                    .background(Color.white)
                    .cornerRadius(5)
                    .foregroundColor(.black)
                    .padding(.top, 10)
            }

            Spacer()
                .frame(height: 16)

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
                    .textContentType(.newPassword)
                    .padding(.horizontal, 8)
                    .frame(height: 42)
                    .background(Color.white)
                    .cornerRadius(5)
                    .foregroundColor(.black)
                    .padding(.top, 10)
            }

            Spacer()
                .frame(height: 16)

            // Confirm password input field matching Ionic's stacked label + input pattern.
            VStack(alignment: .leading, spacing: 0) {
                Text("Confirm Password *")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "bcbcbc"))

                SecureField("", text: $confirmPassword)
                    .textContentType(.newPassword)
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

    /// The submit button matching Ionic's button-success button-custom text-large styling:
    /// --background: linear-gradient(0deg, #5c882c 0%, #75a04a 100%),
    /// --border-radius: 6px, height 50px (min-height 60px for size="large"),
    /// --border-width: 2px, --border-style: solid, --border-color: #141414,
    /// box-shadow with inset white highlight and outer glow,
    /// font-size 26px (text-large), white text color,
    /// d-arrow.svg icon to the right with 10px margin-left.
    private var submitButtonSection: some View {
        Button {
            performRegistration()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Account")
                        .font(.system(size: 26, weight: .regular))

                    // Right arrow icon matching Ionic's <img src="assets/imgs/d-arrow.svg" img-right>
                    // with margin-left: 10px (handled by HStack spacing).
                    Image("d-arrow")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "75a04a"),
                        Color(hex: "5c882c")
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

    /// Validates all form fields and initiates the registration request.
    /// Checks that all fields are non-empty and that the two password fields match,
    /// mirroring the Ionic app's doRegister() validation logic exactly.
    /// Splits the name into first and last name components at the first space character.
    /// If the name has no space, the entire value is used as the first name and the
    /// last name defaults to an empty string. Shows an error alert on validation
    /// failure or API error using the same "Oops! Register Error" header as the Ionic app.
    private func performRegistration() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate name - matches Ionic's: if (!this.name.length)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please provide a name."
            showError = true
            return
        }

        // Validate email - matches Ionic's: if (!this.email.length)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please provide an email."
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

        // Validate passwords match - matches Ionic's: if (this.password != this.confirm)
        guard password == confirmPassword else {
            errorMessage = "Your passwords do not match."
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
