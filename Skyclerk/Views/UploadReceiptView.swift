//
// UploadReceiptView.swift
//
// Created on 2026-02-25.
// Copyright 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// The upload receipt screen for the Snap!Clerk feature, pixel-perfect match to the Ionic app.
/// Uses a gray textured background pattern with a centered header showing a receipt icon
/// and "Upload Receipt" title. Below is a two-column layout (5:7 ratio) with the camera/photo
/// preview on the left and instructional text on the right. Form fields follow for category,
/// note, and labels. A green gradient "Submit Receipt" button triggers the upload. A dark
/// footer bar provides a cancel action and displays the Skyclerk logo.
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

    // MARK: - Color Constants (matching Ionic CSS exactly)

    /// Header text color matching Ionic's #a2a9ae used for the "Upload Receipt" title and note text.
    private let headerGrayColor = Color(hex: "a2a9ae")

    /// Add receipt button text color matching Ionic's #43494e.
    private let addReceiptTextColor = Color(hex: "43494e")

    /// Lightgray gradient start color from Ionic's rgb(150,154,157).
    private let lightGrayGradientStart = Color(red: 150/255, green: 154/255, blue: 157/255)

    /// Lightgray gradient end color from Ionic's rgb(226,228,230).
    private let lightGrayGradientEnd = Color(red: 226/255, green: 228/255, blue: 230/255)

    /// Success button gradient start color from Ionic's #5c882c.
    private let successGradientStart = Color(hex: "5c882c")

    /// Success button gradient end color from Ionic's #75a04a.
    private let successGradientEnd = Color(hex: "75a04a")

    /// Dark button gradient start color from Ionic's rgb(57,57,57).
    private let darkBtnGradientStart = Color(red: 57/255, green: 57/255, blue: 57/255)

    /// Dark button gradient end color from Ionic's rgb(84,84,84).
    private let darkBtnGradientEnd = Color(red: 84/255, green: 84/255, blue: 84/255)

    /// Gray gradient dropdown button start color from Ionic's #5b5b5b.
    private let grayGradientStart = Color(hex: "5b5b5b")

    /// Gray gradient dropdown button end color from Ionic's #8f8f8f.
    private let grayGradientEnd = Color(hex: "8f8f8f")

    /// Form label text color matching Ionic's #bcbcbc (login-form-list label color).
    private let formLabelColor = Color(hex: "bcbcbc")

    /// Add labels helper text color matching Ionic's #a2a9ae at 12px.
    private let addLabelsTextColor = Color(hex: "a2a9ae")

    /// Dark footer toolbar background matching Ionic's dark toolbar color.
    private let footerBgColor = Color(hex: "2c2c2c")

    /// Preview image inset shadow background matching Ionic's rgb(234,234,234).
    private let previewBgColor = Color(hex: "eaeaea")

    /// Button border color matching Ionic's #141414.
    private let buttonBorderColor = Color(hex: "141414")

    /// Background tint for the gray pattern area matching Ionic's #51585d.
    private let patternBgTint = Color(hex: "51585d")

    /// The main view body. Displays a textured gray background with the receipt upload form.
    /// The layout matches the Ionic app's upload-receipt page exactly: header with receipt icon,
    /// two-column camera/instructions section, category dropdown, note textarea, labels row,
    /// green submit button, and dark footer toolbar.
    var body: some View {
        ZStack {
            // Gray textured pattern background matching Ionic's bggraypettern.
            // Uses the gray-pettern asset tiled over a #51585d base color.
            patternBgTint
                .ignoresSafeArea()

            // Tile the gray pattern image over the background.
            GeometryReader { geo in
                Image("gray-pettern")
                    .resizable(resizingMode: .tile)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .opacity(0.6)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Main scrollable content area with the form.
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with receipt icon and "Upload Receipt" title.
                        headerSection

                        // Form list area with top margin matching Ionic's margin-top: 24px.
                        VStack(spacing: 0) {
                            // Two-column layout: image preview (5/12) and instructions (7/12).
                            topTwoColumnSection
                                .padding(.horizontal, 10)

                            // Category dropdown field.
                            categoryDropdownField
                                .padding(.horizontal, 10)
                                .padding(.top, 10)

                            // Note textarea field.
                            noteTextareaField
                                .padding(.horizontal, 10)
                                .padding(.top, 10)

                            // Labels row with tag button and selected labels display.
                            labelsRow
                                .padding(.horizontal, 10)
                                .padding(.top, 10)
                        }
                        .padding(.top, 24)

                        // Submit button section centered below the form.
                        submitButtonSection
                            .padding(.top, 20)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 6)
                }

                // Dark footer toolbar with cancel button and logo.
                footerToolbar
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $receiptImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showLabelsSheet) {
            labelsSelectionSheet
        }
        .confirmationDialog("Categories", isPresented: $showCategoryPicker, titleVisibility: .visible) {
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

    // MARK: - Header Section

    /// The header section matching Ionic's h3 element with receipt-gray.png icon and
    /// "Upload Receipt" title text. Centered horizontally with color #a2a9ae, font-weight 700,
    /// font-size 30px. The header has a top margin of 40px matching [snapclerk-upload] [header].
    private var headerSection: some View {
        HStack(spacing: 10) {
            // Receipt gray icon matching Ionic's receipt-gray.png at 34px height.
            Image("receipt-gray")
                .resizable()
                .scaledToFit()
                .frame(height: 34)

            // "Upload Receipt" title matching Ionic's h3 style.
            Text("Upload Receipt")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(headerGrayColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Two-Column Section

    /// The two-column layout matching Ionic's ion-row[llrm] with 5:7 column ratio.
    /// Left column (5/12): photo preview or "Add receipt" camera button.
    /// Right column (7/12): instructional note paragraph.
    /// Uses -10px margin (llrm) with 10px padding on each column.
    private var topTwoColumnSection: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left column: 5/12 width ratio - image preview or camera button.
            imagePreviewColumn
                .frame(width: UIScreen.main.bounds.width * 5.0 / 12.0 - 16)
                .padding(10)

            // Right column: 7/12 width ratio - instructional text.
            instructionColumn
                .frame(maxWidth: .infinity)
                .padding(10)
        }
    }

    /// The left column of the top section. Shows either the captured receipt image with
    /// the Ionic preview styling (border-radius 5px, eaeaea background, inset shadow)
    /// or the "Add receipt" button with lightgray gradient, camera-graphic.svg icon,
    /// 130px height, and #43494e text color matching the Ionic design exactly.
    private var imagePreviewColumn: some View {
        Group {
            if let image = receiptImage {
                // Display the captured receipt image matching Ionic's [preview] styling:
                // border-radius 5px, background eaeaea, inset box-shadow.
                Button {
                    showCamera = true
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(previewBgColor)
                        )
                }
            } else {
                // "Add receipt" button matching Ionic's lightgray gradient button:
                // height 130px, border-radius 6px, border 2px solid #141414,
                // gradient from rgb(150,154,157) to rgb(226,228,230),
                // camera-graphic.svg icon 70x60, text #43494e font-weight 600.
                Button {
                    showCamera = true
                } label: {
                    VStack(spacing: 4) {
                        // Camera graphic icon matching Ionic's 70x60 size.
                        Image("camera-graphic")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 60)

                        // "Add receipt" text matching Ionic's styling.
                        Text("Add receipt")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(addReceiptTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [lightGrayGradientEnd, lightGrayGradientStart]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(buttonBorderColor, lineWidth: 2)
                    )
                    // Inner highlight matching Ionic's inset box-shadow.
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                            .padding(2)
                    )
                }
            }
        }
    }

    /// The right column instructional text matching Ionic's p.note styling:
    /// color #a2a9ae, font-size 18px, font-weight 700. Contains two paragraphs
    /// separated by line breaks as in the original HTML template.
    private var instructionColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Just snap a photo of your receipt and we'll pull out the details.")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(headerGrayColor)

            Spacer()
                .frame(height: 18)

            Text("The receipt will be added to your ledger.")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(headerGrayColor)
        }
    }

    // MARK: - Category Dropdown Field

    /// The category dropdown field matching Ionic's .dropdown structure:
    /// A stacked label "Category (optional)" at 16px semibold #bcbcbc,
    /// a readonly input field with white background and 5px border-radius,
    /// and a gray gradient dropdown button (50px wide) positioned on the right.
    /// The dropdown area has right padding of 60px and bottom margin of 20px.
    private var categoryDropdownField: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Stacked label matching Ionic's ion-label position="stacked".
            Text("Category (optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(formLabelColor)

            // Input row with readonly text field and dropdown button.
            HStack(spacing: 0) {
                // Category text input area matching Ionic's ion-input with white bg.
                HStack {
                    Text(selectedCategoryName)
                        .font(.system(size: 16))
                        .foregroundColor(selectedCategoryId != nil ? Color(hex: "333333") : Color(hex: "999999"))
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 8)
                .frame(height: 42)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.trailing, 10)

                // Gray gradient dropdown button matching Ionic's [graygradiantbtn]:
                // gradient from #5b5b5b to #8f8f8f, 50px wide, 42px tall,
                // border-radius 5px, with down-arrow-gray.svg icon.
                Button {
                    showCategoryPicker = true
                } label: {
                    Image("down-arrow-gray")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                        .padding(.top, 3)
                }
                .frame(width: 50, height: 42)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [grayGradientEnd, grayGradientStart]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 5))
                // Inner highlight matching Ionic's inset box-shadow.
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                )
            }
            .padding(.top, 10)
        }
    }

    // MARK: - Note Textarea Field

    /// The note textarea field matching Ionic's ion-textarea styling:
    /// stacked label "Note (optional)" at 16px semibold #bcbcbc,
    /// white background textarea with border-radius 5px, min-height 80px,
    /// padding-start and padding-end of 8px, margin-top 6px.
    private var noteTextareaField: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Stacked label matching Ionic's ion-label position="stacked".
            Text("Note (optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(formLabelColor)

            // Textarea matching Ionic's ion-textarea with white bg, border-radius 5px,
            // min-height 80px, padding 8px.
            TextEditor(text: $note)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "333333"))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.top, 6)
        }
    }

    // MARK: - Labels Row

    /// The labels row matching Ionic's 3:9 column layout (only shown when labels exist):
    /// Left column (3/12): dark gradient button with tags.svg icon, "Add Labels (optional)"
    /// text below at 12px centered color #a2a9ae.
    /// Right column (9/12): readonly textarea showing comma-separated selected label names.
    private var labelsRow: some View {
        Group {
            if !allLabels.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    // Left column: tag button and helper text (3/12 width).
                    VStack(spacing: 4) {
                        // Dark gradient button matching Ionic's [button-dark] [button-custom]:
                        // gradient from rgb(57,57,57) to rgb(84,84,84), border-radius 6px,
                        // border 2px solid #141414, height 50px, with tags.svg icon.
                        Button {
                            showLabelsSheet = true
                        } label: {
                            Image("tags")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 24)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [darkBtnGradientEnd, darkBtnGradientStart]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(buttonBorderColor, lineWidth: 2)
                        )
                        // Inner highlight matching Ionic's inset box-shadow.
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                                .padding(2)
                        )

                        // "Add Labels (optional)" helper text matching Ionic's p.add-labels:
                        // font-size 12px, text-align center, color #a2a9ae.
                        Text("Add Labels (optional)")
                            .font(.system(size: 12))
                            .foregroundColor(addLabelsTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: UIScreen.main.bounds.width * 3.0 / 12.0 - 10)
                    .padding(10)

                    // Right column: readonly textarea showing selected labels (9/12 width).
                    VStack(alignment: .leading, spacing: 0) {
                        // Textarea matching Ionic's readonly ion-textarea for labels display.
                        Text(selectedLabelsText.isEmpty ? " " : selectedLabelsText)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "333333"))
                            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                }
            }
        }
    }

    // MARK: - Submit Button Section

    /// The submit button section matching Ionic's button-container with centered layout.
    /// The button uses a green gradient (button-success): from #5c882c to #75a04a,
    /// border-radius 6px, border 2px solid #141414, with upload.svg icon (24px height,
    /// 10px right margin) and "Submit Receipt" text in uppercase white.
    private var submitButtonSection: some View {
        Button {
            submitReceipt()
        } label: {
            HStack(spacing: 10) {
                if isSubmitting {
                    // Loading spinner during upload.
                    ProgressView()
                        .tint(.white)
                } else {
                    // Upload icon matching Ionic's upload.svg at 24px height with 10px right margin.
                    Image("upload")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)

                    // "SUBMIT RECEIPT" text in uppercase matching Ionic's text-uppercase attribute.
                    Text("SUBMIT RECEIPT")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Group {
                    if receiptImage != nil && !isSubmitting {
                        // Active green gradient matching Ionic's button-success.
                        LinearGradient(
                            gradient: Gradient(colors: [successGradientEnd, successGradientStart]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        // Dimmed green gradient when disabled.
                        LinearGradient(
                            gradient: Gradient(colors: [successGradientEnd.opacity(0.4), successGradientStart.opacity(0.4)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(buttonBorderColor, lineWidth: 2)
            )
            // Inner highlight matching Ionic's inset box-shadow.
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                    .padding(2)
            )
        }
        .disabled(receiptImage == nil || isSubmitting)
    }

    // MARK: - Footer Toolbar

    /// The dark footer toolbar matching Ionic's ion-footer with dark toolbar.
    /// Left side: "Cancel and go Back" button with light color text.
    /// Right side: logo-small.svg image at 20px height.
    /// Background is the dark toolbar color from the Ionic theme.
    private var footerToolbar: some View {
        HStack {
            // Cancel button matching Ionic's footer button: clear fill, light color, uppercase.
            Button {
                dismiss()
            } label: {
                Text("\u{00AB} Cancel and go Back")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .textCase(.uppercase)
            }

            Spacer()

            // Logo matching Ionic's logo-small.svg at 20px height.
            Image("logo-small")
                .resizable()
                .scaledToFit()
                .frame(height: 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(footerBgColor)
    }

    // MARK: - Labels Selection Sheet

    /// A sheet view for selecting labels to tag the receipt with. Displays a list
    /// of all available labels with checkmarks next to selected ones. The user can
    /// toggle labels on/off by tapping them. Matches the Ionic alert-style checkbox
    /// selection but presented as a native iOS sheet.
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
                                        .foregroundColor(Color(hex: "75a04a"))
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

    // MARK: - Computed Properties

    /// Returns the display name of the currently selected category, or an empty string
    /// if no category has been selected by the user. Matches the Ionic behavior where
    /// the input is blank when no category is selected.
    private var selectedCategoryName: String {
        if let id = selectedCategoryId, let cat = categories.first(where: { $0.Id == id }) {
            return cat.Name
        }
        return ""
    }

    /// Returns a comma-separated string of the names of all selected labels.
    /// Used to display the selected labels inline in the labels textarea field,
    /// matching the Ionic behavior of joining with ", ".
    private var selectedLabelsText: String {
        allLabels
            .filter { selectedLabelIds.contains($0.Id) }
            .map { $0.Name }
            .joined(separator: ", ")
    }

    // MARK: - Actions

    /// Loads categories and labels from the API on view appear. Also requests
    /// location permission so GPS coordinates are available at submission time.
    /// Filters categories to only show expense types in the picker, matching
    /// the Ionic behavior where only expense categories are listed.
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
    /// Matches the Ionic doSumbit() behavior of emitting the upload data.
    private func submitReceipt() {
        // Validate that a receipt image has been captured.
        guard let image = receiptImage else {
            errorMessage = "Please take a photo of your receipt first."
            showError = true
            return
        }

        // Convert the UIImage to JPEG data with moderate compression (quality 80 matching Ionic).
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
