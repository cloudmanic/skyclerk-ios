//
// Secrets.example.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//
// Copy this file to Secrets.swift and fill in your own values.
// Secrets.swift is excluded from version control via .gitignore.
//

import Foundation

/// Contains sensitive configuration values that should not be committed to version control.
/// Copy this file to Secrets.swift and replace the placeholder values with your own keys.
struct AppSecrets {
    /// OAuth client ID for the Skyclerk API.
    static let clientId = "YOUR_CLIENT_ID_HERE"

    /// Google Maps API key for location services.
    static let googleMapsApiKey = "YOUR_GOOGLE_MAPS_API_KEY_HERE"
}
