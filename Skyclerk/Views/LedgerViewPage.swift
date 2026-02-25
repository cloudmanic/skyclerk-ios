//
// LedgerViewPage.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import MapKit
import SwiftUI

/// Detail view for displaying a single ledger entry's full information.
/// Shows the contact name as a title, followed by a card-style details list
/// (date, amount, category, labels, note), a thumbnail grid of attached files,
/// a map showing the transaction location (if available), and a delete button.
/// The ledger entry can be deleted after confirmation, which navigates back.
struct LedgerViewPage: View {
    /// The ledger entry to display. Passed in from the parent list view.
    let ledger: Ledger

    /// Dismiss action to navigate back after deletion or when tapping back.
    @Environment(\.dismiss) private var dismiss

    /// Controls display of the delete confirmation alert.
    @State private var showDeleteConfirmation: Bool = false

    /// Whether a delete operation is currently in progress.
    @State private var isDeleting: Bool = false

    /// Whether an error alert should be displayed.
    @State private var showError: Bool = false

    /// The error message to display in the error alert.
    @State private var errorMessage: String = ""

    /// Controls the sheet for viewing a full-size image attachment.
    @State private var selectedFileURL: String? = nil

    /// Whether the full-size image sheet is presented.
    @State private var showFullImage: Bool = false

    /// Determines whether the map section should be displayed.
    /// Returns true only when both latitude and longitude are non-zero,
    /// indicating that a real GPS location was recorded.
    private var hasLocation: Bool {
        ledger.Lat != 0 && ledger.Lon != 0
    }

    /// Determines the thumbnail size based on the number of attached files.
    /// Returns 100pt for 1 file, 75pt for 2 files, and 50pt for 3 or more.
    private var thumbnailSize: CGFloat {
        switch ledger.Files.count {
        case 1: return 100
        case 2: return 75
        default: return 50
        }
    }

    /// The coordinate region for the map view, centered on the ledger's GPS location.
    /// Uses a span of 0.01 degrees (~1km) for a neighborhood-level view.
    private var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: ledger.Lat, longitude: ledger.Lon),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    // MARK: - Body

    /// The main view body. Displays the ledger details in a scrollable dark-themed layout
    /// with a card-style information section, optional attachments grid, optional map,
    /// and a delete button at the bottom.
    var body: some View {
        ZStack {
            // Full-screen dark background extending to all edges.
            Color.appDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Contact display name as the page title.
                    headerSection

                    // Card showing date, amount, category, labels, and note.
                    detailsCard

                    // Grid of file thumbnails (only shown if files exist).
                    if !ledger.Files.isEmpty {
                        attachmentsSection
                    }

                    // Map showing the transaction location (only shown if coordinates exist).
                    if hasLocation {
                        mapSection
                    }

                    // Full-width red delete button with confirmation.
                    deleteButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Entry Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .darkToolbar()
        .toolbar {
            // Back button in the bottom toolbar to return to the ledger list.
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Go Back to Ledger")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color.appLink)
                    }
                    Spacer()
                }
            }
        }
        .toolbarBackground(Color.appDarkGray, for: .bottomBar)
        .toolbarColorScheme(.dark, for: .bottomBar)
        .alert("Delete Entry", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                performDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showFullImage) {
            fullImageSheet
        }
    }

    // MARK: - Header Section

    /// Displays the contact's display name as a large, prominent title
    /// at the top of the detail view.
    private var headerSection: some View {
        HStack {
            Text(ledger.contactDisplayName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
    }

    // MARK: - Details Card

    /// A card-style section displaying the ledger entry's key details
    /// in a labeled list format. Each row shows a label on the left
    /// and the corresponding value on the right.
    private var detailsCard: some View {
        VStack(spacing: 0) {
            // Date row
            detailRow(label: "Date", value: ledger.formattedDate?.toShortDate() ?? ledger.LedgerDate)

            Divider().background(Color.appDarkGray.opacity(0.3))

            // Amount row with currency formatting.
            detailRow(label: "Amount", value: abs(ledger.Amount).toCurrency())

            Divider().background(Color.appDarkGray.opacity(0.3))

            // Category name row.
            detailRow(label: "Category", value: ledger.LedgerCategory.Name)

            // Labels row (only shown if labels exist).
            if !ledger.Labels.isEmpty {
                Divider().background(Color.appDarkGray.opacity(0.3))
                detailRow(label: "Labels", value: ledger.Labels.map { $0.Name }.joined(separator: ", "))
            }

            // Note row (only shown if a note exists).
            if !ledger.Note.isEmpty {
                Divider().background(Color.appDarkGray.opacity(0.3))
                detailRow(label: "Note", value: ledger.Note)
            }
        }
        .background(Color.appDarkGray)
        .cornerRadius(12)
    }

    /// Builds a single detail row with a left-aligned label and a right-aligned value.
    /// Used within the details card for each piece of ledger information.
    ///
    /// - Parameters:
    ///   - label: The field name displayed on the left (e.g., "Date", "Amount").
    ///   - value: The field value displayed on the right.
    /// - Returns: A styled horizontal row view.
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appTextGray)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Attachments Section

    /// A grid of thumbnail images for attached files. Each thumbnail loads
    /// asynchronously from the Thumb600By600Url. Tapping a thumbnail opens
    /// the full-size image in a sheet.
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Attachments")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            // Flexible grid that wraps thumbnails based on available space.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: thumbnailSize), spacing: 10)], spacing: 10) {
                ForEach(ledger.Files) { file in
                    // Each thumbnail is tappable to view the full-size image.
                    Button {
                        selectedFileURL = file.Url
                        showFullImage = true
                    } label: {
                        AsyncImage(url: URL(string: file.Thumb600By600Url)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: thumbnailSize, height: thumbnailSize)
                                    .clipped()
                                    .cornerRadius(8)
                            case .failure:
                                // Fallback icon for failed image loads.
                                thumbnailPlaceholder
                            case .empty:
                                // Loading placeholder while the image downloads.
                                ProgressView()
                                    .frame(width: thumbnailSize, height: thumbnailSize)
                            @unknown default:
                                thumbnailPlaceholder
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appDarkGray)
        .cornerRadius(12)
    }

    /// A placeholder view shown when an attachment thumbnail fails to load.
    /// Displays a document icon in a gray rectangle.
    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.appBgDarkGray)
            .frame(width: thumbnailSize, height: thumbnailSize)
            .overlay(
                Image(systemName: "doc")
                    .foregroundColor(Color.appTextGray)
            )
    }

    // MARK: - Full Image Sheet

    /// A sheet that displays the full-size image when a thumbnail is tapped.
    /// Uses AsyncImage to load the full URL and provides a close button.
    private var fullImageSheet: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    // Close button to dismiss the full image sheet.
                    Button {
                        showFullImage = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }

                Spacer()

                if let urlString = selectedFileURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .padding()
                        case .failure:
                            Text("Failed to load image")
                                .foregroundColor(Color.appTextGray)
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Map Section

    /// Displays a map centered on the ledger entry's GPS coordinates.
    /// Shows a single annotation pin at the recorded location.
    /// Only rendered when hasLocation is true (both Lat and Lon are non-zero).
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Location")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            Map(initialPosition: .region(mapRegion)) {
                Marker(ledger.contactDisplayName, coordinate: CLLocationCoordinate2D(
                    latitude: ledger.Lat,
                    longitude: ledger.Lon
                ))
            }
            .frame(height: 200)
            .cornerRadius(12)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Delete Button

    /// A full-width red button that triggers a confirmation alert before deleting
    /// the ledger entry. Shows a loading spinner while the delete request is in progress.
    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: 8) {
                if isDeleting {
                    ProgressView()
                        .tint(.white)
                }
                Text("Delete Entry")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appDanger)
            .cornerRadius(10)
        }
        .disabled(isDeleting)
        .padding(.top, 8)
    }

    // MARK: - Delete Action

    /// Performs the delete operation by calling LedgerService.deleteLedger().
    /// On success, dismisses the view to return to the ledger list.
    /// On failure, displays an error alert with the error description.
    private func performDelete() {
        isDeleting = true

        Task {
            do {
                try await LedgerService.shared.deleteLedger(id: ledger.Id)
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = "Failed to delete entry: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LedgerViewPage(ledger: Ledger())
    }
}
