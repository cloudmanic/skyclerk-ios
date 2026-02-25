//
// Environment.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Environment configuration for the Skyclerk app.
/// Contains all static configuration values such as server URLs, API keys,
/// and version information. These values are used throughout the app to
/// connect to backend services and configure third-party integrations.
///
/// Sensitive values (clientId, googleMapsApiKey) are loaded from Secrets.swift,
/// which is not committed to the repository. See README.md for setup instructions.
struct AppEnvironment {
    /// API server base URL used for all REST API requests.
    static let appServer = "https://app.skyclerk.com"

    /// OAuth client ID identifying this mobile app to the Skyclerk OAuth server.
    /// This is sent during login and registration to authenticate the app itself.
    static let clientId = AppSecrets.clientId

    /// The current version string of the app, displayed in settings and sent to the API.
    static let version = "1.0.0"

    /// Google Maps API key used for displaying maps and geocoding in the app.
    static let googleMapsApiKey = AppSecrets.googleMapsApiKey
}
