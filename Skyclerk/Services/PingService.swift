//
// PingService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Response model for the ping endpoint.
/// The Status field indicates the account's subscription state.
private struct PingResponse: Decodable {
    /// The subscription status returned by the server.
    /// Possible values: "active", "delinquent", "expired", "logout".
    let Status: String
}

/// Service responsible for periodically pinging the Skyclerk server to check
/// the account's subscription status. Runs a background timer every 10 seconds
/// while the user is authenticated. If the subscription has lapsed or the server
/// requests a logout, this service updates published properties that the UI
/// observes to show a paywall or force a logout.
@MainActor
class PingService: ObservableObject {
    /// Shared singleton instance used throughout the app.
    static let shared = PingService()

    /// When true, the UI should present a paywall screen because the account's
    /// subscription is delinquent or expired.
    @Published var shouldShowPaywall = false

    /// When true, the UI should force a logout because the server returned a "logout" status.
    /// This typically happens when the user's session has been invalidated server-side.
    @Published var shouldLogout = false

    /// The repeating timer that fires every 10 seconds to ping the server.
    /// Nil when pinging is stopped (e.g., user is logged out).
    private var timer: Timer?

    /// Private initializer to enforce singleton usage via PingService.shared.
    private init() {}

    /// Starts the periodic ping timer. Should be called when the user becomes authenticated.
    /// If a timer is already running, it is invalidated and replaced with a new one.
    /// The timer fires every 10 seconds on the main run loop and triggers an async ping request.
    func startPinging() {
        // Stop any existing timer before starting a new one to prevent duplicates.
        stopPinging()

        // Schedule the timer on the main thread since it publishes to @Published properties.
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.ping()
            }
        }
    }

    /// Stops the periodic ping timer. Should be called when the user logs out
    /// or the app moves to the background to conserve resources.
    func stopPinging() {
        timer?.invalidate()
        timer = nil
    }

    /// Performs a single ping request to the server and processes the response.
    /// Checks the returned status and updates the published properties accordingly:
    /// - "delinquent" or "expired": Sets shouldShowPaywall to true.
    /// - "logout": Sets shouldLogout to true and triggers a full logout via AuthService.
    /// - Any other status (e.g., "active"): Clears the paywall flag.
    /// Errors are silently ignored since the ping is a background health check
    /// and will be retried automatically on the next timer tick.
    private func ping() async {
        do {
            let url = APIService.shared.accountURL("ping")
            let response: PingResponse = try await APIService.shared.get(url: url)

            switch response.Status.lowercased() {
            case "delinquent", "expired":
                // The account's subscription has lapsed. Show the paywall.
                self.shouldShowPaywall = true
                self.shouldLogout = false

            case "logout":
                // The server is requesting the user be logged out (session invalidated).
                self.shouldShowPaywall = false
                self.shouldLogout = true
                self.stopPinging()
                AuthService.shared.logout()

            default:
                // Subscription is active. Clear any previous paywall state.
                self.shouldShowPaywall = false
                self.shouldLogout = false
            }
        } catch {
            // Silently ignore ping errors. The timer will retry on the next tick.
            // This prevents transient network issues from disrupting the user experience.
        }
    }
}
