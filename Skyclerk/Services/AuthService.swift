//
// AuthService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Service responsible for user authentication, registration, and session management.
/// Uses OAuth password grant flow for login and stores credentials in UserDefaults.
/// Publishes authentication state changes so SwiftUI views can react to login/logout events.
@MainActor
class AuthService: ObservableObject {
    /// Shared singleton instance used throughout the app.
    static let shared = AuthService()

    /// Whether the user is currently authenticated. Published so views can
    /// observe changes and switch between authenticated and unauthenticated UI.
    @Published var isAuthenticated = false

    /// Private initializer to enforce singleton usage. Checks for existing
    /// stored credentials on initialization to restore session state.
    private init() {
        checkAuth()
    }

    /// Checks if the user has a stored access token in UserDefaults.
    /// If an access token is present and non-empty, sets isAuthenticated to true so the
    /// app can skip the login screen. The account_id is resolved separately after login
    /// by calling /oauth/me (the /oauth/token endpoint does not return account_id).
    /// Called on initialization and can be called again to re-verify auth state.
    func checkAuth() {
        let token = UserDefaults.standard.string(forKey: "access_token")
        isAuthenticated = (token != nil && !token!.isEmpty)
    }

    /// Authenticates the user with email and password using the OAuth password grant flow.
    /// Sends a POST request to /oauth/token with grant_type=password, the user's credentials,
    /// and the app's client_id. On success, stores the access token, user ID, and email
    /// in UserDefaults. Then calls /oauth/me to fetch the user's accounts list and stores
    /// the first account's ID in UserDefaults (since /oauth/token does not return account_id).
    /// This mirrors the Ionic app's login flow which also calls /oauth/me after authentication.
    /// Finally sets isAuthenticated to true so the app transitions to the home screen.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Throws: APIError if the request fails or credentials are invalid.
    func login(email: String, password: String) async throws {
        let url = "\(AppEnvironment.appServer)/oauth/token"

        let params: [String: String] = [
            "grant_type": "password",
            "username": email,
            "password": password,
            "client_id": AppEnvironment.clientId
        ]

        let response: LoginResponse = try await APIService.shared.postForm(url: url, params: params)

        // Store credentials in UserDefaults for persistent session.
        UserDefaults.standard.set(response.access_token, forKey: "access_token")
        UserDefaults.standard.set(response.user_id, forKey: "user_id")
        UserDefaults.standard.set(email, forKey: "user_email")

        // Fetch the user's profile to get their accounts list and store the first account ID.
        // The /oauth/token endpoint does not return account_id, so we must call /oauth/me
        // to resolve it before transitioning to the home screen.
        let user = try await MeService.shared.getMe()
        if let firstAccount = user.Accounts.first {
            UserDefaults.standard.set(firstAccount.Id, forKey: "account_id")
        }

        isAuthenticated = true
    }

    /// Registers a new user account with the Skyclerk API.
    /// Sends a POST request to /register with the user's details and the app's client_id.
    /// On success, stores the access token, user ID, account ID, and email in UserDefaults
    /// and sets isAuthenticated to true so the user is immediately logged in.
    ///
    /// - Parameters:
    ///   - email: The new user's email address.
    ///   - password: The new user's chosen password.
    ///   - firstName: The new user's first name.
    ///   - lastName: The new user's last name.
    /// - Throws: APIError if the request fails (e.g., email already taken, validation error).
    func register(email: String, password: String, firstName: String, lastName: String) async throws {
        let url = "\(AppEnvironment.appServer)/register"

        let params: [String: String] = [
            "email": email,
            "password": password,
            "first": firstName,
            "last": lastName,
            "client_id": AppEnvironment.clientId,
            "token": ""
        ]

        let response: RegisterResponse = try await APIService.shared.postForm(url: url, params: params)

        // Store credentials in UserDefaults for persistent session.
        UserDefaults.standard.set(response.access_token, forKey: "access_token")
        UserDefaults.standard.set(response.user_id, forKey: "user_id")
        UserDefaults.standard.set(response.account_id, forKey: "account_id")
        UserDefaults.standard.set(email, forKey: "user_email")
        isAuthenticated = true
    }

    /// Logs the user out by clearing all stored credentials and session data from UserDefaults.
    /// Sets isAuthenticated to false so the app navigates back to the login screen.
    /// Also stops the ping service timer to prevent background network requests.
    func logout() {
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "account_id")
        UserDefaults.standard.removeObject(forKey: "user_email")
        isAuthenticated = false

        // Stop the ping service when logging out.
        PingService.shared.stopPinging()
    }
}
