//
// IntroView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The intro/welcome screen displayed when the user is not authenticated.
/// Shows the app logo and name prominently at the top, with action buttons
/// at the bottom for logging in or registering a new account. On appear,
/// checks UserDefaults for existing credentials and automatically marks the
/// user as authenticated if valid tokens are found, skipping this screen.
struct IntroView: View {
    /// The shared authentication service injected from the parent view hierarchy.
    /// Used to check and update the user's authentication state.
    @EnvironmentObject var authService: AuthService

    /// Controls navigation within the authentication flow using NavigationStack.
    /// Destinations are pushed onto this path for LoginView and RegisterView.
    @State private var navigationPath = NavigationPath()

    /// The main view body. Wraps everything in a NavigationStack with a dark
    /// background. Displays the logo, app name, login button, and register link
    /// in a vertically centered layout.
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Full-screen dark background that extends to all edges.
                Color.appDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

                    // App logo placeholder using an SF Symbol. Replace with the
                    // actual logo asset once it is added to the asset catalog.
                    logoSection

                    Spacer()

                    // Action buttons section with the login button and register link.
                    actionButtonsSection

                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, 30)
            }
            .navigationDestination(for: String.self) { destination in
                // Route to the appropriate view based on the navigation destination string.
                destinationView(for: destination)
            }
        }
        .onAppear {
            // Check for stored credentials on appear. If valid access_token and
            // user_id exist in UserDefaults, skip the intro and mark as authenticated.
            checkForExistingCredentials()
        }
    }

    /// The logo and app name section displayed at the top of the screen.
    /// Shows a large dollar sign circle SF Symbol as a placeholder for the
    /// actual app logo, with the app name "Skyclerk" in bold white text below.
    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(Color.appLink)

            Text("Skyclerk")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
        }
    }

    /// The action buttons section at the bottom of the screen.
    /// Contains the primary "Add Your Skyclerk Account" login button styled
    /// with a white/light appearance and full width, followed by a secondary
    /// prompt and link to the registration screen.
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary login button that navigates to the LoginView.
            Button {
                navigationPath.append("login")
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Add Your Skyclerk Account")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color.appDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(10)
            }

            // Secondary registration prompt and link.
            VStack(spacing: 6) {
                Text("Don't have an account?")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appTextGray)

                Button {
                    navigationPath.append("register")
                } label: {
                    Text("Register for Skyclerk now!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.appLink)
                }
            }
        }
    }

    /// Returns the appropriate destination view for a given navigation string.
    /// Maps "login" to LoginView and "register" to RegisterView, passing the
    /// shared navigation path so child views can manipulate the navigation stack.
    ///
    /// - Parameter destination: The navigation destination string identifier.
    /// - Returns: The corresponding SwiftUI view for the destination.
    @ViewBuilder
    private func destinationView(for destination: String) -> some View {
        switch destination {
        case "login":
            LoginView(navigationPath: $navigationPath)
        case "register":
            RegisterView(navigationPath: $navigationPath)
        default:
            EmptyView()
        }
    }

    /// Checks UserDefaults for existing access_token and user_id values.
    /// If both are present and non-empty, sets authService.isAuthenticated to true
    /// so the app bypasses the intro screen and navigates directly to the home screen.
    private func checkForExistingCredentials() {
        let token = UserDefaults.standard.string(forKey: "access_token")
        let userId = UserDefaults.standard.integer(forKey: "user_id")

        if let token = token, !token.isEmpty, userId > 0 {
            authService.isAuthenticated = true
        }
    }
}

#Preview {
    IntroView()
        .environmentObject(AuthService.shared)
}
