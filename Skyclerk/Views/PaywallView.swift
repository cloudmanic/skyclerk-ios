//
// PaywallView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The premium subscription/upgrade screen presented to users on a trial or free plan.
/// Displays a dark-themed card with the list of premium features (unlimited transactions,
/// contacts, storage, and Snap!Clerks), followed by monthly and yearly pricing buttons.
/// The screen also includes footer links to the Privacy Policy and Terms of Service.
///
/// NOTE: In-app purchases (StoreKit integration) are not yet implemented. The pricing
/// buttons currently show a placeholder alert. This view will be connected to StoreKit
/// once the subscription products are configured in App Store Connect.
struct PaywallView: View {
    /// Environment action for opening external URLs (privacy policy, terms of service).
    @Environment(\.openURL) private var openURL

    /// Whether the placeholder alert is currently displayed when a pricing button is tapped.
    @State private var showPlaceholderAlert: Bool = false

    /// Custom color constants matching the paywall design specification.
    /// These colors are specific to the paywall card and do not appear elsewhere in the app.
    private let cardHeaderColor = Color(hex: "1b2125")
    private let cardBodyColor = Color(hex: "3f3f3f")
    private let paywallBgColor = Color(hex: "313131")
    private let linkColor = Color(hex: "29abe2")

    /// The main view body. Displays the paywall screen with a dark background,
    /// a feature list card, pricing buttons, motivational text, and footer links.
    var body: some View {
        ZStack {
            // Full-screen dark background that extends to all edges.
            Color.appDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 30)

                    // Upgrade card with header, features list, and pricing buttons.
                    upgradeCard

                    Spacer()
                        .frame(height: 30)

                    // Motivational message encouraging the user to choose a plan.
                    motivationalSection

                    Spacer()
                        .frame(height: 24)

                    // Footer links to Privacy Policy and Terms of Service.
                    footerLinks

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Upgrade")
        .navigationBarTitleDisplayMode(.inline)
        // Placeholder alert shown when pricing buttons are tapped.
        .alert("Coming Soon", isPresented: $showPlaceholderAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("In-app purchases are coming soon. Stay tuned for Skyclerk premium subscriptions!")
        }
    }

    // MARK: - Upgrade Card

    /// The main upgrade card containing the header title, feature checklist,
    /// and pricing action buttons. Styled with a dark card appearance matching
    /// the paywall design specification.
    private var upgradeCard: some View {
        VStack(spacing: 0) {
            // Card header with the upgrade title.
            cardHeader

            // Card body with features list and pricing buttons.
            cardBody
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBgDarkGray.opacity(0.5), lineWidth: 1)
        )
    }

    /// The header section of the upgrade card. Displays "Skyclerk Upgrade" in
    /// bold white text on a dark blue-gray background.
    private var cardHeader: some View {
        Text("Skyclerk Upgrade")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 18)
            .background(cardHeaderColor)
    }

    /// The body section of the upgrade card. Contains the features checklist
    /// and pricing buttons on a slightly lighter dark background.
    private var cardBody: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 4)

            // Feature checklist with green checkmarks.
            featuresSection

            // Divider between features and pricing buttons.
            Divider()
                .background(Color.appBgDarkGray)
                .padding(.horizontal, 8)

            // Monthly and yearly pricing buttons.
            pricingButtons

            Spacer()
                .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(cardBodyColor)
    }

    // MARK: - Features Section

    /// The features checklist section inside the upgrade card. Lists all premium
    /// features with green checkmark icons to indicate they are included in the plan.
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Unlimited Transactions feature row.
            featureRow("Unlimited Transactions")

            // Unlimited Contacts feature row.
            featureRow("Unlimited Contacts")

            // Unlimited Storage feature row.
            featureRow("Unlimited Storage")

            // 100 Snap!Clerks per month feature row.
            featureRow("100 Snap!Clerks / Month")
        }
    }

    /// Creates a single feature row with a green checkmark icon and the feature name.
    /// Used to build the feature checklist inside the upgrade card.
    ///
    /// - Parameter title: The feature name to display (e.g., "Unlimited Transactions").
    /// - Returns: A styled HStack with a checkmark and feature text.
    private func featureRow(_ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(Color.appSuccess)

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }

    // MARK: - Pricing Buttons

    /// The pricing buttons section with monthly and yearly subscription options.
    /// Both buttons are styled as full-width green buttons. Tapping either button
    /// shows a placeholder alert since StoreKit integration is not yet implemented.
    private var pricingButtons: some View {
        VStack(spacing: 12) {
            // Monthly subscription button at $5.99/month.
            Button {
                showPlaceholderAlert = true
            } label: {
                Text("Choose Monthly - $5.99")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appSuccess)
                    .cornerRadius(10)
            }

            // Yearly subscription button at $59.99/year.
            Button {
                showPlaceholderAlert = true
            } label: {
                Text("Choose Yearly - $59.99")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appSuccess)
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Motivational Section

    /// The motivational text section below the upgrade card. Displays an encouraging
    /// message asking the user to choose a plan and thanking them for using Skyclerk.
    private var motivationalSection: some View {
        VStack(spacing: 8) {
            Text("It's Time To Choose a Plan")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("We hope you've enjoyed Skyclerk!")
                .font(.system(size: 14))
                .foregroundColor(Color.appTextGray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer Links

    /// The footer section with links to the Privacy Policy and Terms of Service.
    /// Both links are styled in the paywall's link color and open external URLs.
    private var footerLinks: some View {
        HStack(spacing: 20) {
            // Privacy Policy link opening the Skyclerk privacy policy page.
            Button {
                if let url = URL(string: "https://skyclerk.com/privacy-policy") {
                    openURL(url)
                }
            } label: {
                Text("Privacy Policy")
                    .font(.system(size: 13))
                    .foregroundColor(linkColor)
            }

            // Visual separator between the two links.
            Text("|")
                .font(.system(size: 13))
                .foregroundColor(Color.appTextGray)

            // Terms of Service link opening the Skyclerk terms page.
            Button {
                if let url = URL(string: "https://skyclerk.com/terms-of-service") {
                    openURL(url)
                }
            } label: {
                Text("Terms of Service")
                    .font(.system(size: 13))
                    .foregroundColor(linkColor)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView()
    }
}
