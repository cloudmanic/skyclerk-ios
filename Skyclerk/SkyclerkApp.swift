//
// SkyclerkApp.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The main entry point for the Skyclerk iOS application.
/// Uses AuthService as the shared environment object to determine whether
/// the user is authenticated. Shows IntroView for unauthenticated users
/// and HomeView for authenticated users. AuthService is injected as an
/// environment object so all child views can access authentication state.
@main
struct SkyclerkApp: App {
    @StateObject private var authService = AuthService.shared

    /// The root scene of the application.
    /// Conditionally renders either the HomeView (for authenticated sessions)
    /// or the IntroView (for unauthenticated sessions), passing the shared
    /// AuthService instance as an environment object to the entire view hierarchy.
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                HomeView()
                    .environmentObject(authService)
            } else {
                IntroView()
                    .environmentObject(authService)
            }
        }
    }
}
