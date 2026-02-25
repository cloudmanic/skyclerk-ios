//
// SnapClerkRowView.swift
//
// Created on 2026-02-25.
// Copyright 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// A single row in the Snap!Clerk list that displays a receipt submission entry.
/// Matches the Ionic app-snapclerk-list row styling exactly with 4 columns:
/// - Thumbnail (col size="2"): Receipt image from Thumb600By600Url in an ion-thumbnail
/// - Date (col size="2"): Creation date formatted as "MMM dd" on top, "yyyy" below
/// - Details (col, flexible): Contact name and category text
/// - Status (col size="3"): Color-coded status badge button (warning/danger/success)
///
/// The row has white/light gray alternating background with #cbcbcb borders,
/// matching the Ionic tableViewGrid row styling. Text colors are dark (not white)
/// since rows sit on light backgrounds. Padding uses the Ionic custom padding pattern
/// with specific padding per column position.
struct SnapClerkRowView: View {
    /// The SnapClerk submission to display in this row. Contains the file reference
    /// for the thumbnail, status, contact, category, and creation timestamp.
    let snapclerk: SnapClerk

    /// The main view body. Lays out the thumbnail, date, contact/category info, and status badge
    /// in a horizontal stack matching the Ionic 2/2/flex/3 column layout with justify-content-between.
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Column 1 (size="2"): Thumbnail image.
            thumbnailColumn
                .padding(.leading, 12)

            // Column 2 (size="2"): Creation date.
            dateColumn
                .padding(.leading, 5)

            // Column 3 (flexible): Contact and category details.
            detailsColumn

            Spacer()

            // Column 4 (size="3"): Status badge.
            statusBadge
                .padding(.trailing, 12)
        }
        .padding(.vertical, 12)
    }

    /// The thumbnail column displayed on the far left of the row.
    /// Uses AsyncImage to load the receipt thumbnail from the Thumb600By600Url,
    /// matching the Ionic ion-thumbnail component. Shows a placeholder document icon
    /// while loading or if no image is available.
    private var thumbnailColumn: some View {
        AsyncImage(url: URL(string: snapclerk.File.Thumb600By600Url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Image(systemName: "doc.text")
                    .foregroundColor(Color(hex: "808080"))
            case .empty:
                ProgressView()
                    .tint(Color(hex: "808080"))
            @unknown default:
                Image(systemName: "doc.text")
                    .foregroundColor(Color(hex: "808080"))
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "eaeaea"))
        )
    }

    /// The date column showing when the SnapClerk entry was created.
    /// Formats as two lines: "MMM dd" in small text on top, "yyyy" below.
    /// Matches the Ionic .date class styling (font-weight 500, font-size 15px).
    private var dateColumn: some View {
        VStack(spacing: 0) {
            if let date = snapclerk.createdDate {
                Text(formatMonthDay(date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black)
                Text(formatYear(date))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
            } else {
                Text(snapclerk.CreatedAt)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black)
            }
        }
        .frame(width: 50, alignment: .center)
    }

    /// The details column showing contact and category information.
    /// Displays the vendor/contact name on the first line in dark text,
    /// with the category name below in link blue (#1181c3).
    /// Matches the Ionic .vendor class styling.
    private var detailsColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Contact/vendor name extracted from the receipt.
            Text(snapclerk.Contact.isEmpty ? "-" : snapclerk.Contact)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "606060"))
                .lineLimit(1)

            // Category name in link blue matching Ionic <a> styling.
            Text(snapclerk.Category.isEmpty ? "-" : snapclerk.Category)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "1181c3"))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 8)
    }

    /// The status badge displayed on the right side of the row.
    /// Shows the current processing status as a small rounded button matching
    /// the Ionic ion-button size="small" with color-coded backgrounds:
    /// - "warning" (Ionic orange/yellow) for Pending items
    /// - "danger" (red) for Rejected or Error items
    /// - "success" (green) for Complete/Success items
    /// Matches the Ionic getColor() method for status-to-color mapping.
    private var statusBadge: some View {
        Text(snapclerk.Status.capitalized)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(statusBackgroundColor)
            .cornerRadius(4)
    }

    /// Returns the appropriate background color for the status badge based on
    /// the SnapClerk entry's status. Maps to Ionic's ion-color values:
    /// - "Pending" -> "warning" -> #ffce00 (Ionic warning)
    /// - "Rejected" -> "danger" -> #f04141 (Ionic danger)
    /// - Default -> "success" -> #10dc60 (Ionic success)
    private var statusBackgroundColor: Color {
        switch snapclerk.statusColor {
        case .warning:
            return Color(hex: "ffce00")
        case .danger:
            return Color(hex: "f04141")
        case .success:
            return Color(hex: "10dc60")
        }
    }

    /// Formats a Date as "MMM dd" for the top line of the date column.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A string like "Feb 25".
    private func formatMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }

    /// Formats a Date as "yyyy" for the bottom line of the date column.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A string like "2026".
    private func formatYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 0) {
        SnapClerkRowView(snapclerk: SnapClerk(
            Id: 1,
            Status: "pending",
            File: FileModel(Thumb600By600Url: ""),
            Contact: "Starbucks",
            Category: "Meals",
            CreatedAt: "2026-02-25T10:00:00Z"
        ))
        .background(Color.white)

        SnapClerkRowView(snapclerk: SnapClerk(
            Id: 2,
            Status: "complete",
            File: FileModel(Thumb600By600Url: ""),
            Contact: "Amazon",
            Category: "Office Supplies",
            CreatedAt: "2026-02-24T14:30:00Z"
        ))
        .background(Color(hex: "f7f7f7"))

        SnapClerkRowView(snapclerk: SnapClerk(
            Id: 3,
            Status: "rejected",
            File: FileModel(Thumb600By600Url: ""),
            Contact: "",
            Category: "",
            CreatedAt: "2026-02-23T09:15:00Z"
        ))
        .background(Color.white)
    }
}
