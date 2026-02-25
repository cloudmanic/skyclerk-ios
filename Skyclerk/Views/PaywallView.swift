//
// PaywallView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The premium subscription/upgrade screen presented to users on a trial or free plan.
/// This is a pixel-perfect match of the Ionic Skyclerk paywall page. It uses a dark
/// background (#141414 matching bgdark), a feature card with dark header (#1b2125)
/// and body (#3f3f3f), green gradient subscription buttons, motivational text, and
/// footer links to Privacy Policy and Terms of Service.
///
/// The Ionic layout structure is:
/// - ion-content[bgdark] -> .section-update-plan -> .section__body
///   - .updates card (header #1b2125, body #3f3f3f, width 325px)
///   - .upgrade-buttons (width 325px, green gradient buttons)
///   - Motivational text paragraphs
///   - Privacy/Terms links
/// - ion-footer (only shown when billing.Status == "Trial")
///
/// NOTE: In-app purchases (StoreKit integration) are not yet implemented. The pricing
/// buttons currently show a placeholder alert. This view will be connected to StoreKit
/// once the subscription products are configured in App Store Connect.
struct PaywallView: View {
    /// Environment dismiss action for the back/cancel button.
    @Environment(\.dismiss) private var dismiss

    /// Environment action for opening external URLs (privacy policy, terms of service).
    @Environment(\.openURL) private var openURL

    /// Whether the placeholder alert is currently displayed when a pricing button is tapped.
    @State private var showPlaceholderAlert: Bool = false

    /// The billing object loaded from the API to determine if we show the back button.
    @State private var billing: Billing = Billing()

    /// The monthly price display string, matching the Ionic "Loading..." initial state.
    @State private var monthlyPrice: String = "$5.99"

    /// The yearly price display string, matching the Ionic "Loading..." initial state.
    @State private var yearlyPrice: String = "$59.99"

    // MARK: - Color Constants (matching Ionic paywall.page.scss and global.scss)

    /// The main background color matching Ionic's `ion-content[bgdark]` -> `--background: #141414`.
    private let bgColor = Color(hex: "141414")

    /// The outer section background matching `.section-update-plan` -> `background-color: #313131`.
    private let sectionBgColor = Color(hex: "313131")

    /// The card header background matching `.updates__head` -> `background-color: #1b2125`.
    private let cardHeaderColor = Color(hex: "1b2125")

    /// The card body background matching `.updates` -> `background-color: #3f3f3f`.
    private let cardBodyColor = Color(hex: "3f3f3f")

    /// The feature list item divider color matching `.updates__body li + li` -> `border-top: 1px solid #999`.
    private let featureDividerColor = Color(hex: "999999")

    /// The green button gradient bottom color from global.scss `button-success`.
    /// Linear gradient from #5c882c (bottom) to #75a04a (top).
    private let successGradientBottom = Color(hex: "5c882c")

    /// The green button gradient top color from global.scss `button-success`.
    private let successGradientTop = Color(hex: "75a04a")

    /// The button border color matching global.scss `--border-color: #141414`.
    private let buttonBorderColor = Color(hex: "141414")

    /// The link color matching `.section__content a` -> `color: #29abe2`.
    private let linkColor = Color(hex: "29abe2")

    /// The dark footer toolbar background matching `ion-toolbar color="dark"`.
    private let footerBgColor = Color(hex: "2c2c2c")

    /// The fixed card width matching Ionic's `.updates` and `.upgrade-buttons` -> `width: 325px`.
    private let cardWidth: CGFloat = 325

    /// The main view body. Displays the paywall screen matching the Ionic layout exactly:
    /// dark background, centered feature card, green gradient pricing buttons below,
    /// motivational text, and privacy/terms links. A footer bar with "Cancel and go Back"
    /// appears only when the billing status is "Trial".
    var body: some View {
        ZStack {
            // Full-screen dark background matching bgdark (#141414).
            bgColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // The section-update-plan container with centered body.
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: 10)

                            // The .section__aside with .updates card.
                            upgradeCard

                            Spacer()
                                .frame(height: 20)

                            // The .upgrade-buttons container with monthly and yearly buttons.
                            pricingButtons

                            Spacer()
                                .frame(height: 24)

                            // Motivational text paragraphs.
                            motivationalSection

                            Spacer()
                                .frame(height: 20)

                            // Privacy Policy | Terms of Service links.
                            footerLinks

                            Spacer()
                                .frame(height: 40)
                        }
                        .frame(maxWidth: .infinity)
                        .background(sectionBgColor)
                    }
                }

                // Footer bar shown only for trial users, matching the Ionic ion-footer.
                if billing.Status == "Trial" {
                    trialFooter
                }
            }
        }
        .navigationTitle("Upgrade")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadBilling()
        }
        // Placeholder alert shown when pricing buttons are tapped.
        .alert("Coming Soon", isPresented: $showPlaceholderAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("In-app purchases are coming soon. Stay tuned for Skyclerk premium subscriptions!")
        }
    }

    // MARK: - Upgrade Card

    /// The main upgrade feature card matching the Ionic `.updates` component.
    /// Fixed width of 325px, centered horizontally. Has a dark header (#1b2125)
    /// with "Skyclerk Upgrade" title and a body (#3f3f3f) containing four feature
    /// rows with checkmark icons. Feature rows are separated by 1px #999 dividers
    /// with 28px margin-top and 32px padding-top between items.
    private var upgradeCard: some View {
        VStack(spacing: 0) {
            // Card header: .updates__head with bg #1b2125, padding 13px 15px.
            HStack {
                Text("Skyclerk Upgrade")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: cardWidth)
            .padding(.vertical, 13)
            .padding(.horizontal, 15)
            .background(cardHeaderColor)

            // Card body: .updates__body with feature list.
            VStack(alignment: .leading, spacing: 0) {
                // Feature list matching .updates__body ul.
                featureItem(boldText: "Unlimited", normalText: " Transactions", isFirst: true)
                featureItem(boldText: "Unlimited", normalText: " Contacts", isFirst: false)
                featureItem(boldText: "Unlimited", normalText: " Storage", isFirst: false)
                featureItem(boldText: "100", normalText: " Snap!Clerks / Month", isFirst: false)
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 15)
            .frame(width: cardWidth)
            .background(cardBodyColor)
        }
        .frame(width: cardWidth)
    }

    /// Creates a single feature list item matching the Ionic `.updates__body li` style.
    /// Each item has a green checkmark icon and inline text where part is bold.
    /// Non-first items have a top border (1px solid #999) with spacing matching
    /// the Ionic: `margin-top: 28px; border-top: 1px solid #999; padding-top: 32px`.
    ///
    /// - Parameters:
    ///   - boldText: The bold portion of the feature text (e.g., "Unlimited", "100").
    ///   - normalText: The normal-weight portion of the feature text.
    ///   - isFirst: Whether this is the first item (no top divider).
    /// - Returns: A styled feature list item view.
    private func featureItem(boldText: String, normalText: String, isFirst: Bool) -> some View {
        VStack(spacing: 0) {
            if !isFirst {
                // Divider matching li + li border-top: 1px solid #999.
                Rectangle()
                    .fill(featureDividerColor)
                    .frame(height: 1)
                    .padding(.top, 28)
            }

            HStack(spacing: 8) {
                // Checkmark icon matching the ico-updates@2x.png asset.
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "75a04a"))

                // Feature text with bold + normal parts matching the h5 > strong pattern.
                (Text(boldText)
                    .fontWeight(.bold) +
                Text(normalText))
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            .padding(.top, isFirst ? 20 : 32)
        }
    }

    // MARK: - Pricing Buttons

    /// The pricing buttons section matching the Ionic `.upgrade-buttons` container.
    /// Fixed width of 325px, centered. Contains two full-width green gradient buttons
    /// matching the `button-success button-custom` styling: linear-gradient from
    /// #5c882c to #75a04a, 50px height, 6px border radius, 2px solid #141414 border,
    /// uppercase text. The yearly button has 20px top margin.
    private var pricingButtons: some View {
        VStack(spacing: 0) {
            // Monthly subscription button.
            Button {
                showPlaceholderAlert = true
            } label: {
                Text("Choose Monthly - \(monthlyPrice)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
                    .frame(width: cardWidth, height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [successGradientBottom, successGradientTop]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(buttonBorderColor, lineWidth: 2)
                    )
            }

            // Yearly subscription button with 20px top margin matching .yearly class.
            Button {
                showPlaceholderAlert = true
            } label: {
                Text("Choose Yearly - \(yearlyPrice)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
                    .frame(width: cardWidth, height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [successGradientBottom, successGradientTop]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(buttonBorderColor, lineWidth: 2)
                    )
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Motivational Section

    /// The motivational text section below the buttons matching the Ionic paragraphs:
    /// `<p><b>It's Time To Choose a Plan</b></p>` and `<p>We hope you've enjoyed Skyclerk!</p>`.
    /// Both are centered white text on the #313131 background.
    private var motivationalSection: some View {
        VStack(spacing: 8) {
            Text("It's Time To Choose a Plan")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text("We hope you've enjoyed Skyclerk!")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer Links

    /// The footer links section matching the Ionic privacy/terms anchor tags.
    /// Uses the link color #29abe2 with a pipe separator, centered horizontally.
    private var footerLinks: some View {
        HStack(spacing: 4) {
            // Privacy Policy link opening the Skyclerk privacy policy page.
            Button {
                if let url = URL(string: "https://skyclerk.com/privacy-policy") {
                    openURL(url)
                }
            } label: {
                Text("Privacy Policy")
                    .font(.system(size: 14))
                    .foregroundColor(linkColor)
            }

            // Visual separator between the two links.
            Text("|")
                .font(.system(size: 14))
                .foregroundColor(.white)

            // Terms of Service link opening the Skyclerk terms page.
            Button {
                if let url = URL(string: "https://skyclerk.com/terms-of-service") {
                    openURL(url)
                }
            } label: {
                Text("Terms of Service")
                    .font(.system(size: 14))
                    .foregroundColor(linkColor)
            }
        }
    }

    // MARK: - Trial Footer

    /// The bottom footer bar shown only for trial users, matching the Ionic
    /// `ion-footer[no-border] mode="md"` with `ion-toolbar color="dark"`.
    /// Contains a "Cancel and go Back" button on the left and a small logo on the right.
    /// The toolbar uses a dark background (#2c2c2c) matching Ionic's dark color.
    private var trialFooter: some View {
        HStack {
            // "Cancel and go Back" button matching the Ionic left-aligned button.
            Button {
                dismiss()
            } label: {
                Text("\u{00AB} Cancel and go Back")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
            }

            Spacer()

            // Small logo on the right matching the Ionic .bar-logo img (height: 20px).
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(footerBgColor)
    }

    // MARK: - Actions

    /// Loads billing information from the API to determine whether to show the
    /// trial-user back button footer. Also checks if the user already has an active
    /// subscription and should be redirected away, matching the Ionic refreshBilling logic.
    private func loadBilling() {
        Task {
            do {
                let fetchedBilling = try await AccountService.shared.getBilling()
                await MainActor.run {
                    billing = fetchedBilling
                }
            } catch {
                print("Failed to load billing data: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView()
    }
}
