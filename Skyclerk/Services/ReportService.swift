//
// ReportService.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import Foundation

/// Service responsible for fetching financial reports from the Skyclerk API.
/// Reports provide aggregated financial data such as profit & loss summaries.
/// Communicates with the /api/v3/{accountId}/reports endpoints.
class ReportService {
    /// Shared singleton instance used throughout the app.
    nonisolated(unsafe) static let shared = ReportService()

    /// Private initializer to enforce singleton usage via ReportService.shared.
    private init() {}

    /// Fetches the current year's profit and loss (P&L) report for the active account.
    /// This report summarizes total income, total expenses, and net profit/loss
    /// for the current calendar year, along with monthly breakdowns.
    ///
    /// - Returns: A PnlCurrentYear object containing the current year's financial summary.
    /// - Throws: APIError if the request fails or the response cannot be decoded.
    func getPnlCurrentYear() async throws -> PnlCurrentYear {
        let url = APIService.shared.accountURL("reports/pnl-current-year")
        let report: PnlCurrentYear = try await APIService.shared.get(url: url)
        return report
    }
}
