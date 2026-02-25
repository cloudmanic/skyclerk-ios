//
// LedgerViewPage.swift
//
// Created on 2026-02-25.
// Copyright 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import MapKit
import SwiftUI

/// Detail view for displaying a single ledger entry's full information.
/// Pixel-perfect match of the Ionic Skyclerk ledger-view page. Uses a light-themed
/// card (#f2f2f2) on a dark background (#232323) displaying the contact header,
/// a detail list (date, amount, category, labels, note), a thumbnail grid of
/// attached files, a map if coordinates exist, and a danger-styled delete button.
/// A dark footer toolbar provides a "Go Back to Ledger" navigation link.
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

    // MARK: - Computed Properties

    /// Determines whether the map section should be displayed.
    /// Returns true only when both latitude and longitude are non-zero,
    /// indicating that a real GPS location was recorded.
    private var hasLocation: Bool {
        ledger.Lat != 0 && ledger.Lon != 0
    }

    /// Determines the thumbnail size based on the number of attached files.
    /// Matches the Ionic app: 100pt for 1 file, 75pt for 2 files, 50pt for 3+.
    private var thumbnailSize: CGFloat {
        switch ledger.Files.count {
        case 1: return 100
        case 2: return 75
        default: return 50
        }
    }

    /// The coordinate region for the map view, centered on the ledger's GPS location.
    /// Uses a span matching the Ionic app's zoom level 14 (~0.01 degrees).
    private var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: ledger.Lat, longitude: ledger.Lon),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    /// Builds the contact subtitle text. If Contact.Name exists, it is the subtitle
    /// and FirstName LastName is the title. Otherwise FirstName LastName is the subtitle.
    /// Matches the Ionic template's conditional header rendering.
    private var contactSubtitle: String {
        if !ledger.LedgerContact.Name.isEmpty {
            return ledger.LedgerContact.Name
        }
        let parts = [ledger.LedgerContact.FirstName, ledger.LedgerContact.LastName].filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    /// Builds the contact title text (FirstName LastName), shown only when Contact.Name exists.
    /// This matches the Ionic ion-card-title that only appears when Contact.Name is present.
    private var contactTitle: String? {
        guard !ledger.LedgerContact.Name.isEmpty else { return nil }
        let parts = [ledger.LedgerContact.FirstName, ledger.LedgerContact.LastName].filter { !$0.isEmpty }
        let joined = parts.joined(separator: " ")
        return joined.isEmpty ? nil : joined
    }

    /// The color for the amount text. Expenses (#b7433f red) vs income (default #606060 dark gray).
    /// Matches the Ionic ledger list's .danger amount color for expenses.
    private var amountColor: Color {
        if ledger.LedgerCategory.isExpense {
            return Color(hex: "b7433f")
        }
        return Color(hex: "606060")
    }

    // MARK: - Body

    /// The main view body. Renders a scrollable page with dark background (#232323),
    /// a light card with contact header and detail rows, optional file thumbnails card,
    /// optional map card, and a danger-gradient delete button. A dark footer toolbar
    /// provides a back-navigation link matching the Ionic footer.
    var body: some View {
        ZStack {
            // Full-screen background matching Ionic ion-content --background: #232323.
            Color(hex: "232323")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Top spacing matching Ionic card margin-top: 60px.
                    Spacer().frame(height: 60)

                    // Main detail card with contact header and data rows.
                    detailCard

                    // File attachments card (only shown if files exist).
                    if !ledger.Files.isEmpty {
                        attachmentsCard
                    }

                    // Map card (only shown if coordinates exist).
                    if hasLocation {
                        mapCard
                    }

                    // Full-width danger-styled delete button.
                    deleteButton
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Entry Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .darkToolbar()
        .toolbar {
            // Dark footer toolbar with back button matching Ionic ion-footer.
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("\u{00AB} Go Back to Ledger")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
            }
        }
        .toolbarBackground(Color(hex: "2c2c2c"), for: .bottomBar)
        .toolbarColorScheme(.dark, for: .bottomBar)
        .alert("Delete Ledger Entry", isPresented: $showDeleteConfirmation) {
            Button("No, just joking.", role: .cancel) {}
            Button("Yes, I am sure.", role: .destructive) {
                performDelete()
            }
        } message: {
            Text("Are you sure you want to delete this ledger entry?")
        }
        .alert("Oops!", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showFullImage) {
            fullImageSheet
        }
    }

    // MARK: - Detail Card

    /// The main information card matching the Ionic ion-card with background #f2f2f2.
    /// Contains the contact header (subtitle/title) and a list of detail rows
    /// (Date, Amount, Category, Labels, Note) styled as Ionic ion-items with
    /// left-aligned labels and right-aligned note values separated by dividers.
    private var detailCard: some View {
        VStack(spacing: 0) {
            // Contact header section matching Ionic ion-card-header.
            cardHeader

            // Detail rows matching Ionic ion-list > ion-item layout.
            detailsList
        }
        .background(Color(hex: "f2f2f2"))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    /// The card header section displaying the contact name(s).
    /// Matches the Ionic ion-card-header with subtitle (smaller gray text)
    /// and optional title (larger bold text). The subtitle is Contact.Name
    /// when it exists, with FirstName LastName as the title. When no Contact.Name
    /// exists, FirstName LastName serves as the subtitle with no title.
    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Subtitle: Contact.Name if available, otherwise FirstName LastName.
            // Matches Ionic ion-card-subtitle styling.
            Text(contactSubtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "999999"))
                .textCase(.uppercase)

            // Title: FirstName LastName, only shown when Contact.Name exists.
            // Matches Ionic ion-card-title styling.
            if let title = contactTitle {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "1a1a1a"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    /// The list of detail rows inside the card, matching Ionic ion-list > ion-item.
    /// Each row has a left-aligned label and a right-aligned value with a separator
    /// between rows. Uses standard Ionic item styling: dark labels on the left,
    /// muted gray (#8c8c8c) note values on the right.
    private var detailsList: some View {
        VStack(spacing: 0) {
            // Date row showing the formatted short date.
            detailRow(label: "Date", value: ledger.formattedDate?.toShortDate() ?? ledger.LedgerDate)

            rowDivider

            // Amount row showing the currency value with type-based coloring.
            amountRow

            rowDivider

            // Category row showing the assigned category name.
            detailRow(label: "Category", value: ledger.LedgerCategory.Name)

            rowDivider

            // Labels row showing comma-separated label names.
            labelsRow

            rowDivider

            // Note row showing the transaction memo/note.
            noteRow
        }
    }

    /// Builds a single detail row matching an Ionic ion-item with ion-label on the
    /// left and ion-note slot="end" on the right. The label is dark text on the left,
    /// the value is muted gray (#8c8c8c) text right-aligned on the right.
    ///
    /// - Parameters:
    ///   - label: The field name displayed on the left (e.g., "Date", "Category").
    ///   - value: The field value displayed on the right.
    /// - Returns: A styled horizontal row view matching Ionic ion-item layout.
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "1a1a1a"))

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8c8c8c"))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// The amount detail row with type-based color. Expenses display in red (#b7433f),
    /// income in dark gray (#606060). Matches the Ionic ledger-view amount display
    /// with the raw numeric value (no sign prefix).
    private var amountRow: some View {
        HStack {
            Text("Amount")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "1a1a1a"))

            Spacer()

            Text(abs(ledger.Amount).toCurrency())
                .font(.system(size: 14))
                .foregroundColor(amountColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// The labels detail row showing comma-separated label names.
    /// Matches the Ionic template's label rendering with comma separators
    /// between label names, excluding the trailing comma on the last item.
    private var labelsRow: some View {
        HStack {
            Text("Labels")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "1a1a1a"))

            Spacer()

            Text(ledger.Labels.map { $0.Name }.joined(separator: ", "))
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8c8c8c"))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// The note detail row showing the transaction memo.
    /// Matches the Ionic ion-item for Note with right-aligned gray text.
    private var noteRow: some View {
        HStack(alignment: .top) {
            Text("Note")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "1a1a1a"))

            Spacer()

            Text(ledger.Note)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8c8c8c"))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// A thin hairline divider between detail rows, matching the Ionic ion-item
    /// border separator. Inset from the left to match Ionic's item divider style.
    private var rowDivider: some View {
        Divider()
            .background(Color(hex: "c8c7cc"))
            .padding(.leading, 16)
    }

    // MARK: - Attachments Card

    /// A card displaying attached file thumbnails in a wrapping horizontal grid.
    /// Matches the Ionic ion-card for files with background #f2f2f2, float-left
    /// thumbnail divs with 5px padding. Thumbnail sizes scale based on file count:
    /// 100px for 1 file, 75px for 2, 50px for 3+. Tapping a thumbnail opens
    /// the full-size image in a modal sheet.
    private var attachmentsCard: some View {
        VStack(spacing: 0) {
            // Wrapping horizontal layout matching Ionic float:left divs with 5px padding.
            FlowLayout(spacing: 5) {
                ForEach(ledger.Files) { file in
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
                            case .failure:
                                thumbnailPlaceholder
                            case .empty:
                                ProgressView()
                                    .frame(width: thumbnailSize, height: thumbnailSize)
                            @unknown default:
                                thumbnailPlaceholder
                            }
                        }
                    }
                    .padding(5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(5)
        }
        .background(Color(hex: "f2f2f2"))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    /// A placeholder view shown when an attachment thumbnail fails to load.
    /// Displays a document icon in a gray rectangle matching the card background.
    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color(hex: "d8d8d8"))
            .frame(width: thumbnailSize, height: thumbnailSize)
            .overlay(
                Image(systemName: "doc")
                    .foregroundColor(Color(hex: "8c8c8c"))
            )
    }

    // MARK: - Full Image Sheet

    /// A sheet that displays the full-size image when a thumbnail is tapped.
    /// Matches the Ionic view-attachment page with a full-screen image container
    /// on a white background, with the file name overlaid at the bottom
    /// and a close button to dismiss.
    private var fullImageSheet: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with close button.
                HStack {
                    Spacer()
                    Button {
                        showFullImage = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "8c8c8c"))
                    }
                    .padding()
                }

                Spacer()

                // Full-size image loaded from the file URL.
                if let urlString = selectedFileURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .padding()
                        case .failure:
                            Text("Failed to load image")
                                .foregroundColor(Color(hex: "8c8c8c"))
                        case .empty:
                            ProgressView()
                                .tint(Color(hex: "8c8c8c"))
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Map Card

    /// Displays a map card matching the Ionic ion-card with agm-map inside.
    /// Shows a 200pt tall map centered on the ledger's GPS coordinates at
    /// zoom level 14, with a marker pin at the location. Background #f2f2f2.
    private var mapCard: some View {
        VStack(spacing: 0) {
            Map(initialPosition: .region(mapRegion)) {
                Marker(ledger.contactDisplayName, coordinate: CLLocationCoordinate2D(
                    latitude: ledger.Lat,
                    longitude: ledger.Lon
                ))
            }
            .frame(height: 200)
            .allowsHitTesting(false)
        }
        .background(Color(hex: "f2f2f2"))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Delete Button

    /// A full-width delete button matching the Ionic danger-class button.
    /// Uses a gradient from #a73632 (bottom) to #bd4743 (top) with white text,
    /// rounded corners, and a slight shadow. Triggers a confirmation alert
    /// before performing the delete. Shows a spinner while deleting.
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
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.45), radius: 0, x: 0, y: 1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "a73632"), Color(hex: "bd4743")]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(4)
        }
        .disabled(isDeleting)
    }

    // MARK: - Delete Action

    /// Performs the delete operation by calling LedgerService.deleteLedger().
    /// On success, dismisses the view to return to the ledger list.
    /// On failure, displays an error alert with the server error description.
    /// Matches the Ionic deleteLedger() method's behavior and error handling.
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
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - FlowLayout

/// A horizontal wrapping layout that arranges child views left-to-right,
/// wrapping to the next line when the available width is exceeded. This matches
/// the Ionic float:left behavior used for file thumbnail containers in the
/// ledger-view attachments card.
struct FlowLayout: Layout {
    /// The spacing between items in the flow layout.
    var spacing: CGFloat = 0

    /// Calculates the total size needed to lay out all subviews in a
    /// wrapping horizontal arrangement within the proposed width.
    ///
    /// - Parameters:
    ///   - subviews: The child views to be laid out.
    ///   - proposal: The proposed size from the parent container.
    /// - Returns: The computed size needed for all subviews.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(subviews: subviews, proposal: proposal)
        return result.size
    }

    /// Places each subview at its computed position within the wrapping
    /// horizontal layout, flowing left-to-right and top-to-bottom.
    ///
    /// - Parameters:
    ///   - bounds: The available rectangle to place subviews within.
    ///   - proposal: The proposed size from the parent container.
    ///   - subviews: The child views to place.
    ///   - cache: Unused layout cache.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(subviews: subviews, proposal: proposal)
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, proposal: .unspecified)
        }
    }

    /// Computes the positions and total size for all subviews arranged in a
    /// wrapping horizontal flow. Iterates through subviews, placing each one
    /// after the previous with spacing. When a subview would exceed the
    /// available width, it wraps to a new line.
    ///
    /// - Parameters:
    ///   - subviews: The child views to compute layout for.
    ///   - proposal: The proposed size constraint from the parent.
    /// - Returns: A tuple containing the array of computed positions and the total size.
    private func computeLayout(subviews: Subviews, proposal: ProposedViewSize) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}

#Preview {
    NavigationStack {
        LedgerViewPage(ledger: Ledger())
    }
}
