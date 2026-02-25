//
// SnapClerkRowView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// A single row in the Snap!Clerk list that displays a receipt submission entry.
/// Shows a thumbnail image of the uploaded receipt on the left, the creation date,
/// contact/category information in the middle, and a color-coded status badge on the right.
/// The status badge color reflects the processing state: yellow for pending,
/// red for rejected/error, and green for success/complete.
struct SnapClerkRowView: View {
    /// The SnapClerk submission to display in this row. Contains the file reference
    /// for the thumbnail, status, contact, category, and creation timestamp.
    let snapclerk: SnapClerk

    /// The main view body. Lays out the thumbnail, date/contact info, and status badge
    /// in a horizontal stack with appropriate spacing and alignment.
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Left column: Thumbnail image loaded asynchronously from the file's 600x600 URL.
            thumbnailColumn

            // Middle-left column: Creation date formatted as a short date string.
            dateColumn

            // Middle column: Contact name on top, category name below.
            detailsColumn

            Spacer()

            // Right column: Status badge with color-coded background.
            statusBadge
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }

    /// The thumbnail column displayed on the far left of the row (~20% width).
    /// Uses AsyncImage to load the receipt thumbnail from the Thumb600By600Url.
    /// Shows a placeholder document icon while loading or if no image is available.
    /// The thumbnail is clipped to a small rounded rectangle for a clean appearance.
    private var thumbnailColumn: some View {
        AsyncImage(url: URL(string: snapclerk.File.Thumb600By600Url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Image(systemName: "doc.text")
                    .foregroundColor(Color.appTextGray)
            case .empty:
                ProgressView()
                    .tint(Color.appTextGray)
            @unknown default:
                Image(systemName: "doc.text")
                    .foregroundColor(Color.appTextGray)
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.appDarkGray)
        )
    }

    /// The date column showing when the SnapClerk entry was created (~20% width).
    /// Parses the CreatedAt timestamp and formats it as a short date. Falls back
    /// to the raw CreatedAt string if the date cannot be parsed.
    private var dateColumn: some View {
        Text(snapclerk.createdDate?.toShortDate() ?? snapclerk.CreatedAt)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.appTextGray)
            .frame(width: 60, alignment: .center)
    }

    /// The details column showing contact and category information in the center.
    /// Displays the vendor/contact name prominently on the first line, with the
    /// category name in smaller gray text below. If either field is empty,
    /// it shows a placeholder dash instead.
    private var detailsColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Contact/vendor name extracted from the receipt.
            Text(snapclerk.Contact.isEmpty ? "-" : snapclerk.Contact)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            // Category name assigned to the receipt.
            Text(snapclerk.Category.isEmpty ? "-" : snapclerk.Category)
                .font(.system(size: 12))
                .foregroundColor(Color.appTextLightGray)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The status badge displayed on the right side of the row (~30% width).
    /// Shows the current processing status as a small rounded pill with a
    /// color-coded background that matches the status:
    /// - Warning (yellow) for "Pending" items still being processed.
    /// - Danger (red) for "Rejected" or "Error" items that failed.
    /// - Success (green) for "Success" or "Complete" items that finished.
    private var statusBadge: some View {
        Text(snapclerk.Status.capitalized)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusBackgroundColor)
            .clipShape(Capsule())
    }

    /// Returns the appropriate background color for the status badge based on
    /// the SnapClerk entry's statusColor enum value. Maps the StatusColor cases
    /// to the corresponding app color constants.
    private var statusBackgroundColor: Color {
        switch snapclerk.statusColor {
        case .warning:
            return Color.appWarning
        case .danger:
            return Color.appDanger
        case .success:
            return Color.appSuccess
        }
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

        Divider().background(Color.appBgDarkGray)

        SnapClerkRowView(snapclerk: SnapClerk(
            Id: 2,
            Status: "complete",
            File: FileModel(Thumb600By600Url: ""),
            Contact: "Amazon",
            Category: "Office Supplies",
            CreatedAt: "2026-02-24T14:30:00Z"
        ))

        Divider().background(Color.appBgDarkGray)

        SnapClerkRowView(snapclerk: SnapClerk(
            Id: 3,
            Status: "error",
            File: FileModel(Thumb600By600Url: ""),
            Contact: "",
            Category: "",
            CreatedAt: "2026-02-23T09:15:00Z"
        ))
    }
    .background(Color.appDark)
}
