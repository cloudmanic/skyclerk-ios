//
// Extensions.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

extension Double {
    /// Format as currency string (e.g., "$1,234.56").
    /// Uses NumberFormatter with the specified locale and currency code
    /// to produce a properly formatted currency string.
    ///
    /// - Parameters:
    ///   - locale: The locale identifier for formatting (default: "en-US").
    ///   - currency: The ISO 4217 currency code (default: "USD").
    /// - Returns: A formatted currency string, or "$0.00" if formatting fails.
    func toCurrency(locale: String = "en-US", currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: locale)
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}

extension Date {
    /// Format date as "MMM dd\nyyyy" for ledger list display.
    /// This produces a two-line date string suitable for compact ledger row layouts,
    /// with the month and day on the first line and the year on the second.
    ///
    /// - Returns: A formatted date string with a newline between day and year.
    func toLedgerDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd\nyyyy"
        return formatter.string(from: self)
    }

    /// Format date as a short date string using the system's short date style.
    /// The exact format depends on the user's locale settings (e.g., "2/25/26" in en-US).
    ///
    /// - Returns: A short formatted date string.
    func toShortDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }

    /// Format as an ISO 8601 string suitable for API requests.
    /// Uses UTC timezone and the format "yyyy-MM-dd'T'HH:mm:ss'Z'".
    ///
    /// - Returns: An ISO 8601 formatted date string in UTC.
    func toAPIString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: self)
    }

    /// Format as MM/DD/YYYY for display in form fields.
    /// This provides a consistent, human-readable date format for input forms.
    ///
    /// - Returns: A date string in MM/dd/yyyy format.
    func toFormDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: self)
    }
}

// App color palette matching the Ionic app
extension Color {
    static let appPrimary = Color(hex: "065182")
    static let appLightBlue = Color(hex: "1181c3")
    static let appDark = Color(hex: "141414")
    static let appDarkGray = Color(hex: "242424")
    static let appBgDarkGray = Color(hex: "404040")
    static let appTextGray = Color(hex: "bcbcbc")
    static let appTextLightGray = Color(hex: "b7b7b7")
    static let appFocus = Color(hex: "d8e9f0")
    static let appLink = Color(hex: "b2d6ec")
    static let appBorder = Color(hex: "cbcbcb")
    static let appItemBg = Color(hex: "f5f5f5")
    static let appAltItemBg = Color(hex: "eaeaea")
    static let appSegmentBg = Color(hex: "272727")
    static let appSegmentBorder = Color(hex: "343434")
    static let appSegmentColor = Color(hex: "808080")
    static let appSegmentActive = Color(hex: "cccccc")
    static let appSegmentActiveBg = Color(hex: "4a4a4a")
    static let appTableHead = Color(hex: "cdcdcd")
    static let appTableOdd = Color(hex: "f7f7f7")
    static let appSuccess = Color(hex: "10dc60")
    static let appDanger = Color(hex: "f04141")
    static let appWarning = Color(hex: "ffce00")
    static let appMedium = Color(hex: "494949")

    /// Initialize a Color from a hex string.
    /// Supports 3-character, 6-character, and 8-character (with alpha) hex strings.
    /// Any non-alphanumeric characters (such as "#") are automatically stripped.
    ///
    /// - Parameter hex: A hex color string (e.g., "065182", "#FF0000", "F00").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    /// Apply the standard app dark background color to the view.
    /// Uses Color.appDark as the background fill.
    ///
    /// - Returns: A view with the app's dark background applied.
    func appBackground() -> some View {
        self.background(Color.appDark)
    }

    /// Apply the standard dark toolbar style to a navigation bar.
    /// Sets the navigation bar background to the app's dark color
    /// and applies a dark color scheme for proper contrast.
    ///
    /// - Returns: A view with dark-styled navigation toolbar.
    func darkToolbar() -> some View {
        self.toolbarBackground(Color.appDark, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
