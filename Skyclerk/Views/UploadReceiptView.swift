//
// UploadReceiptView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The upload receipt screen for the Snap!Clerk feature.
/// Allows users to photograph a receipt using the device camera and submit it to the
/// SnapClerk service for automatic data extraction. The view is split into a two-column
/// layout at the top (image preview on the left, instructions on the right), followed by
/// optional form fields for category, note, and labels. On submission, the receipt image
/// is uploaded along with GPS coordinates and any user-provided metadata.
struct UploadReceiptView: View {
    /// Dismiss action to pop this view from the navigation stack after successful upload.
    @Environment(\.dismiss) private var dismiss

    /// The captured receipt image from the camera. Nil until the user takes a photo.
    @State private var receiptImage: UIImage? = nil

    /// Whether the camera picker sheet is currently presented.
    @State private var showCamera: Bool = false

    /// The list of expense categories fetched from the API for the category picker.
    @State private var categories: [Category] = []

    /// The currently selected category ID. Nil means no category selected.
    @State private var selectedCategoryId: Int? = nil

    /// The optional note text the user can attach to the receipt.
    @State private var note: String = ""

    /// The list of all available labels fetched from the API.
    @State private var allLabels: [LedgerLabel] = []

    /// The set of label IDs the user has selected to tag this receipt.
    @State private var selectedLabelIds: Set<Int> = []

    /// Whether the labels selection sheet is currently presented.
    @State private var showLabelsSheet: Bool = false

    /// Whether the category confirmation dialog is currently presented.
    @State private var showCategoryPicker: Bool = false

    /// Whether a submission is currently in progress. Disables the submit button
    /// and shows a loading indicator to prevent double submissions.
    @State private var isSubmitting: Bool = false

    /// Whether the success alert is currently displayed after a successful upload.
    @State private var showSuccess: Bool = false

    /// Whether the error alert is currently displayed.
    @State private var showError: Bool = false

    /// The error message to display when submission fails.
    @State private var errorMessage: String = ""

    /// Location manager used to capture the user's GPS coordinates when submitting.
    @StateObject private var locationManager = LocationManager()

    /// The main view body. Displays a dark-themed scrollable layout with the image preview,
    /// instructions, form fields, and submit button. A bottom toolbar provides a cancel option.
    var body: some View {
        ZStack {
            // Full-screen dark background that extends to all edges.
            Color.appDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 10)

                    // Two-column layout: image preview on left, instructions on right.
                    topSection

                    // Divider between the top section and the form fields.
                    Divider()
                        .background(Color.appBgDarkGray)
                        .padding(.horizontal, 16)

                    // Category picker, note field, and labels selector.
                    formSection

                    // Green submit button spanning full width.
                    submitButton

                    Spacer()
                        .frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Snap!Clerk")
        .navigationBarTitleDisplayMode(.inline)
        .darkToolbar()
        .toolbar {
            // Bottom toolbar with cancel/back button.
            ToolbarItemGroup(placement: .bottomBar) {
                bottomToolbarContent
            }
        }
        .toolbarBackground(Color.appDarkGray, for: .bottomBar)
        .toolbarBackground(.visible, for: .bottomBar)
        .toolbarColorScheme(.dark, for: .bottomBar)
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $receiptImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showLabelsSheet) {
            labelsSelectionSheet
        }
        .confirmationDialog("Select Category", isPresented: $showCategoryPicker, titleVisibility: .visible) {
            // "None" option to clear the selected category.
            Button("None") {
                selectedCategoryId = nil
            }

            // List each expense category as a selectable option.
            ForEach(categories) { category in
                Button(category.Name) {
                    selectedCategoryId = category.Id
                }
            }

            Button("Cancel", role: .cancel) {}
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your receipt has been submitted and will be processed shortly.")
        }
        .alert("Upload Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadData()
        }
    }

    // MARK: - Top Section

    /// The two-column layout at the top of the view. The left column (~40%) shows the
    /// receipt image preview or a camera button placeholder. The right column (~60%)
    /// displays instructional text explaining the Snap!Clerk feature.
    private var topSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column: Image preview or camera button.
            imagePreviewColumn
                .frame(maxWidth: .infinity)

            // Right column: Instructional text.
            instructionColumn
                .frame(maxWidth: .infinity)
        }
    }

    /// The left column of the top section. Shows either the captured receipt image
    /// or a large camera button that opens the device camera. Tapping the image
    /// also re-opens the camera to retake the photo.
    private var imagePreviewColumn: some View {
        Group {
            if let image = receiptImage {
                // Display the captured receipt image with rounded corners.
                // Tapping the image opens the camera to retake the photo.
                Button {
                    showCamera = true
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.appBgDarkGray, lineWidth: 1)
                        )
                }
            } else {
                // Camera button placeholder when no image has been captured yet.
                Button {
                    showCamera = true
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color.appTextGray)

                        Text("Add receipt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.appTextGray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .background(Color.appDarkGray)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.appBgDarkGray, lineWidth: 1)
                    )
                }
            }
        }
    }

    /// The right column of the top section. Displays instructional text explaining
    /// how the Snap!Clerk feature works: snap a photo and it gets added to the ledger.
    private var instructionColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Just snap a photo of your receipt and we'll pull out the details.\n\nThe receipt will be added to your ledger.")
                .font(.system(size: 14))
                .foregroundColor(Color.appTextGray)
                .lineSpacing(4)
        }
        .padding(.top, 8)
    }

    // MARK: - Form Section

    /// The form section below the top two-column layout. Contains the optional
    /// category picker, multiline note field, and labels selector.
    private var formSection: some View {
        VStack(spacing: 18) {
            // Category picker row.
            categoryField

            // Multiline note input field.
            noteField

            // Labels selector with tag icon.
            labelsField
        }
    }

    /// The category picker field. Displays the currently selected category name
    /// or "No Category" if none is selected. Tapping opens a confirmation dialog
    /// with all available expense categories.
    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Category (optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appTextGray)

            Button {
                showCategoryPicker = true
            } label: {
                HStack {
                    Text(selectedCategoryName)
                        .font(.system(size: 15))
                        .foregroundColor(selectedCategoryId != nil ? .white : Color.appTextLightGray)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appTextGray)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.appDarkGray)
                .cornerRadius(8)
            }
        }
    }

    /// The multiline note text input field. Allows the user to type an optional
    /// note to attach to the receipt for additional context.
    private var noteField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Note (optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appTextGray)

            TextEditor(text: $note)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.appDarkGray)
                .cornerRadius(8)
        }
    }

    /// The labels selector field. Shows a button with a tag icon and the number of
    /// selected labels. Tapping opens a sheet where the user can toggle labels on/off.
    private var labelsField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Labels (optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appTextGray)

            Button {
                showLabelsSheet = true
            } label: {
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.appTextGray)

                    if selectedLabelIds.isEmpty {
                        Text("Add Labels")
                            .font(.system(size: 15))
                            .foregroundColor(Color.appTextLightGray)
                    } else {
                        Text(selectedLabelsText)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appTextGray)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.appDarkGray)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Labels Selection Sheet

    /// A sheet view for selecting labels to tag the receipt with. Displays a list
    /// of all available labels with checkmarks next to selected ones. The user can
    /// toggle labels on/off by tapping them.
    private var labelsSelectionSheet: some View {
        NavigationStack {
            ZStack {
                Color.appDark
                    .ignoresSafeArea()

                List {
                    ForEach(allLabels) { label in
                        Button {
                            toggleLabel(label.Id)
                        } label: {
                            HStack {
                                Text(label.Name)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))

                                Spacer()

                                if selectedLabelIds.contains(label.Id) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.appSuccess)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.appDarkGray)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showLabelsSheet = false
                    }
                    .foregroundColor(Color.appLink)
                }
            }
            .toolbarBackground(Color.appDarkGray, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Submit Button

    /// The full-width green submit button. Triggers the receipt upload process.
    /// Shows a loading spinner while the upload is in progress and is disabled
    /// if no image has been captured or a submission is already underway.
    private var submitButton: some View {
        Button {
            submitReceipt()
        } label: {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Submit Receipt")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(receiptImage != nil && !isSubmitting ? Color.appSuccess : Color.appSuccess.opacity(0.4))
            .cornerRadius(10)
        }
        .disabled(receiptImage == nil || isSubmitting)
    }

    // MARK: - Bottom Toolbar

    /// The bottom toolbar content with a cancel button that dismisses the view
    /// and a small logo placeholder on the right side.
    private var bottomToolbarContent: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Cancel and go Back")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appTextGray)
            }

            Spacer()

            // Small logo placeholder in the toolbar.
            Image(systemName: "dollarsign.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(Color.appLink)
        }
    }

    // MARK: - Computed Properties

    /// Returns the display name of the currently selected category, or "No Category"
    /// if no category has been selected by the user.
    private var selectedCategoryName: String {
        if let id = selectedCategoryId, let cat = categories.first(where: { $0.Id == id }) {
            return cat.Name
        }
        return "No Category"
    }

    /// Returns a comma-separated string of the names of all selected labels.
    /// Used to display the selected labels inline in the labels field.
    private var selectedLabelsText: String {
        allLabels
            .filter { selectedLabelIds.contains($0.Id) }
            .map { $0.Name }
            .joined(separator: ", ")
    }

    // MARK: - Actions

    /// Loads categories and labels from the API on view appear. Also requests
    /// location permission so GPS coordinates are available at submission time.
    /// Filters categories to only show expense types in the picker.
    private func loadData() {
        locationManager.requestLocation()

        Task {
            do {
                let allCategories = try await CategoryService.shared.getCategories()
                let labels = try await LabelService.shared.getLabels()

                await MainActor.run {
                    // Filter to only show expense categories in the picker.
                    categories = allCategories.filter { $0.isExpense }
                    allLabels = labels
                }
            } catch {
                print("Failed to load categories/labels: \(error.localizedDescription)")
            }
        }
    }

    /// Toggles a label's selection state. If the label is already selected, it is
    /// removed from the set. If not selected, it is added to the set.
    ///
    /// - Parameter labelId: The ID of the label to toggle.
    private func toggleLabel(_ labelId: Int) {
        if selectedLabelIds.contains(labelId) {
            selectedLabelIds.remove(labelId)
        } else {
            selectedLabelIds.insert(labelId)
        }
    }

    /// Validates the form, converts the receipt image to JPEG data, and uploads
    /// it to the SnapClerk service along with GPS coordinates, the selected category,
    /// note, and labels. Shows a success alert on completion or an error alert on failure.
    private func submitReceipt() {
        // Validate that a receipt image has been captured.
        guard let image = receiptImage else {
            errorMessage = "Please take a photo of your receipt first."
            showError = true
            return
        }

        // Convert the UIImage to JPEG data with moderate compression.
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process the receipt image. Please try again."
            showError = true
            return
        }

        isSubmitting = true

        Task {
            do {
                try await SnapClerkService.shared.uploadReceipt(
                    imageData: imageData,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                    categoryId: selectedCategoryId,
                    labelIds: Array(selectedLabelIds),
                    lat: locationManager.latitude,
                    lon: locationManager.longitude
                )

                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UploadReceiptView()
    }
}
