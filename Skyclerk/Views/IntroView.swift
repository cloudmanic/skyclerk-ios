//
// IntroView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The intro/welcome screen displayed when the user is not authenticated.
/// Replicates the Ionic app's intro page pixel-for-pixel: a dark (#141414)
/// upper section taking 70% of the viewport height with the logo centered
/// and a gradient "Add Your Skyclerk Account" button, and a dark-gray (#242424)
/// lower section taking 30% with a diamond arrow decoration, "Don't have an
/// account?" text, and a "Register for SkyClerk now!" link.
struct IntroView: View {
    /// The shared authentication service injected from the parent view hierarchy.
    /// Used to check and update the user's authentication state.
    @EnvironmentObject var authService: AuthService

    /// Controls navigation within the authentication flow using NavigationStack.
    /// Destinations are pushed onto this path for LoginView and RegisterView.
    @State private var navigationPath = NavigationPath()

    /// The main view body. Splits the screen into two sections matching the
    /// Ionic layout: a 70vh logo section on dark background and a 30vh
    /// create-account section on dark gray background with a decorative
    /// diamond arrow at the divider.
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    // Full-screen dark background that extends to all edges.
                    Color.appDark
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        // Upper section: logo + login button (70% of screen height).
                        logoSection(height: geometry.size.height * 0.70)

                        // Lower section: registration prompt (30% of screen height).
                        createAccountSection(height: geometry.size.height * 0.30)
                    }
                }
            }
            .ignoresSafeArea()
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

    /// The upper 70% section containing the centered logo and the primary login button.
    /// Matches the Ionic `.logo-content` div: flexbox centered, max-width 86%,
    /// with logo padded 40px top/bottom 20px left/right, and the button styled
    /// as `button-light button-custom size="large"`.
    ///
    /// - Parameter height: The calculated height for this section (70% of viewport).
    /// - Returns: A view matching the Ionic logo-content section.
    private func logoSection(height: CGFloat) -> some View {
        ZStack {
            // Background: dark (#141414) matching ion-content[bgdark].
            Color.appDark

            VStack(spacing: 0) {
                // Logo with padding matching Ionic: padding 40px 20px.
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)

                // Primary login button matching Ionic button-light button-custom size="large":
                // - Gradient: linear-gradient(0deg, #939393 0%, #c3c3c3 100%)
                // - White text color
                // - Border: 2px solid #141414
                // - Border-radius: 6px
                // - Min-height: 60px
                // - Box-shadow: inset highlight + outer glow
                // - Font-weight: 400
                Button {
                    navigationPath.append("login")
                } label: {
                    HStack(spacing: 10) {
                        // Plus icon matching Ionic: <img img-left src="plus.svg"> height 24px, margin-right 10px.
                        Image("plus")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 24)

                        Text("Add Your Skyclerk Account")
                            .font(.system(size: 18, weight: .regular))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 60)
                    .background(
                        // Gradient from bottom #939393 to top #c3c3c3.
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "939393"),
                                Color(hex: "c3c3c3")
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .overlay(
                        // 2px solid #141414 border matching --border-width/--border-color.
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.appDark, lineWidth: 2)
                    )
                    .cornerRadius(6)
                    .shadow(color: Color.white.opacity(0.28), radius: 8, x: 0, y: 0)
                }
            }
            // Max-width 86% matching Ionic .content { max-width: 86% }.
            .frame(maxWidth: UIScreen.main.bounds.width * 0.86)
        }
        .frame(height: height)
    }

    /// The lower 30% section with the "Don't have an account?" prompt and register link.
    /// Matches the Ionic `.create-account` div: dark gray (#242424) background,
    /// 1px solid #393939 border-top, centered content, with a decorative diamond
    /// arrow (30x30 rotated square) at the top-center of the divider.
    ///
    /// - Parameter height: The calculated height for this section (30% of viewport).
    /// - Returns: A view matching the Ionic create-account section.
    private func createAccountSection(height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Background: dark gray (#242424) matching $darkgray.
            Color.appDarkGray

            // 1px border-top matching: border-top: 1px solid $darkgray_border (#393939).
            VStack {
                Color(hex: "393939")
                    .frame(height: 1)
                Spacer()
            }

            // Decorative diamond arrow at the top center.
            // Matches the ::before pseudo-element: 30x30 square rotated 45deg,
            // background: $darkgray (#242424), border-top/left: 1px solid #393939,
            // positioned at top: -15px (half of 30px), centered horizontally.
            diamondArrow
                .offset(y: -15)

            // Centered text content matching Ionic flexbox centering.
            VStack(spacing: 0) {
                // "Don't have an account?" text:
                // color: white, font-size: 16px, text-shadow: 0px 1px 0px rgba(0,0,0,0.45).
                Text("Don't have an account?")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: 1)

                // "Register for SkyClerk now!" link button:
                // color: #b2d6ec (appLink), font-size: 16px, margin-top: 10px.
                Button {
                    navigationPath.append("register")
                } label: {
                    Text("Register for SkyClerk now!")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.appLink)
                }
                .padding(.top, 10)
            }
        }
        .frame(height: height)
    }

    /// The decorative diamond arrow at the divider between the logo section and
    /// the create-account section. Matches the Ionic ::before pseudo-element:
    /// a 30x30 square rotated 45 degrees with dark gray (#242424) background
    /// and border-top + border-left of 1px solid #393939. Creates the visual
    /// effect of a downward-pointing arrow at the section boundary.
    private var diamondArrow: some View {
        ZStack {
            // Background fill matching $darkgray (#242424).
            Rectangle()
                .fill(Color.appDarkGray)
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(45))

            // Border: only top and left edges visible after rotation,
            // matching border-top-color and border-left-color: #393939.
            Rectangle()
                .stroke(Color(hex: "393939"), lineWidth: 1)
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(45))
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
