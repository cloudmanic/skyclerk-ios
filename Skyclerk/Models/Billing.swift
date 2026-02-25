//
// Billing.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Billing represents the subscription and payment information for a Skyclerk account.
/// This model contains details about the current subscription plan, payment method,
/// billing cycle, and trial status. It is used to display billing information
/// in the account settings and manage subscription state.
struct Billing: Codable {
    /// The unique identifier for the billing record, assigned by the API.
    var Id: Int = 0

    /// The name or tier of the subscription plan (e.g., "monthly", "yearly", "free").
    var Subscription: String = ""

    /// The current status of the subscription (e.g., "active", "trialing", "canceled", "past_due").
    var Status: String = ""

    /// The payment processor handling the subscription (e.g., "stripe", "apple").
    var PaymentProcessor: String = ""

    /// The ISO 8601 date string indicating when the trial period expires.
    /// Empty if the account is not in a trial period.
    var TrialExpire: String = ""

    /// The brand of the payment card on file (e.g., "Visa", "Mastercard", "Amex").
    var CardBrand: String = ""

    /// The last four digits of the payment card on file, used for display purposes.
    var CardLast4: String = ""

    /// The expiration month of the payment card on file (1-12).
    var CardExpMonth: Int = 0

    /// The expiration year of the payment card on file (e.g., 2027).
    var CardExpYear: Int = 0

    /// The ISO 8601 date string for the start of the current billing period.
    var CurrentPeriodStart: String = ""

    /// The ISO 8601 date string for the end of the current billing period.
    var CurrentPeriodEnd: String = ""

    enum CodingKeys: String, CodingKey {
        case Id = "id"
        case Subscription = "subscription"
        case Status = "status"
        case PaymentProcessor = "payment_processor"
        case TrialExpire = "trial_expire"
        case CardBrand = "card_brand"
        case CardLast4 = "card_last_4"
        case CardExpMonth = "card_exp_month"
        case CardExpYear = "card_exp_year"
        case CurrentPeriodStart = "current_period_start"
        case CurrentPeriodEnd = "current_period_end"
    }
}
