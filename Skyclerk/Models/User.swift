//
// User.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// User represents the currently authenticated user (the "Me" model).
/// This model is returned from the /me API endpoint and contains the user's
/// profile information along with a list of accounts they have access to.
struct User: Codable {
    /// The unique identifier for the user, assigned by the API.
    var Id: Int = 0

    /// The user's email address, used for authentication and notifications.
    var Email: String = ""

    /// The user's first name.
    var FirstName: String = ""

    /// The user's last name.
    var LastName: String = ""

    /// The list of accounts this user has access to. A user may belong to
    /// multiple accounts and can switch between them within the app.
    var Accounts: [Account] = []
}
