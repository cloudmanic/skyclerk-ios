//
// LedgerModifyView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// Typealias to reference the LedgerLabel model type more concisely throughout this file.
/// The model is named LedgerLabel to avoid conflict with SwiftUI.Label.
typealias LabelModel = LedgerLabel

/// Form view for creating a new ledger entry (income or expense).
/// Adapts its appearance and behavior based on the `type` parameter:
/// income entries use green accents and filter to income categories,
/// while expense entries use red accents and filter to expense categories.
/// Includes fields for contact, category, date, amount, and action buttons
/// for adding notes, labels, and file attachments. On submit, builds a
/// Ledger object and sends it to the API via LedgerService.
struct LedgerModifyView: View {
    /// The transaction type, either "income" or "expense".
    /// Determines the accent color, available categories, and how the amount is signed.
    let type: String

    /// Dismiss action to navigate back after successful creation or cancellation.
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    /// The text entered in the contact name field. Can be a new name or match an existing contact.
    @State private var contactName: String = ""

    /// The currently selected contact from the dropdown picker. Nil if typing a new contact name.
    @State private var selectedContact: Contact? = nil

    /// The currently selected category for this ledger entry.
    @State private var selectedCategory: Category? = nil

    /// The transaction date, defaulting to today.
    @State private var date: Date = Date()

    /// The amount string entered by the user, parsed to Double on submit.
    @State private var amount: String = ""

    /// An optional note/memo attached to the transaction.
    @State private var note: String = ""

    /// The set of labels (tags) selected for this transaction via LabelsView.
    @State private var labels: [LabelModel] = []

    /// The list of uploaded file attachments for this transaction.
    @State private var files: [FileModel] = []

    /// The image captured from the camera or photo library, awaiting upload.
    @State private var capturedImage: UIImage? = nil

    // MARK: - Data State

    /// All contacts loaded from the API for the contact picker dropdown.
    @State private var contacts: [Contact] = []

    /// All categories loaded from the API, filtered by type for the category picker.
    @State private var categories: [Category] = []

    // MARK: - UI State

    /// Whether an async operation (loading data or submitting) is in progress.
    @State private var isLoading: Bool = false

    /// Whether an error alert should be displayed.
    @State private var showError: Bool = false

    /// The error message to display in the error alert.
    @State private var errorMessage: String = ""

    /// Controls display of the contact picker confirmation dialog.
    @State private var showContactPicker: Bool = false

    /// Controls display of the category picker confirmation dialog.
    @State private var showCategoryPicker: Bool = false

    /// Controls display of the note input alert.
    @State private var showNoteAlert: Bool = false

    /// Controls display of the image source picker (camera vs photo library).
    @State private var showImageSourcePicker: Bool = false

    /// Controls display of the camera image picker.
    @State private var showCamera: Bool = false

    /// Controls display of the photo library image picker.
    @State private var showPhotoLibrary: Bool = false

    /// Controls navigation to the LabelsView for label selection.
    @State private var showLabelsView: Bool = false

    /// Location manager for tagging the transaction with GPS coordinates.
    @StateObject private var locationManager = LocationManager()

    // MARK: - Computed Properties

    /// Returns the accent color based on the transaction type.
    /// Green for income, red for expense.
    private var accentColor: Color {
        type == "income" ? Color.appSuccess : Color.appDanger
    }

    /// Returns the navigation title based on the transaction type.
    private var titleText: String {
        type == "income" ? "Add Income" : "Add Expense"
    }

    /// Returns the submit button label based on the transaction type.
    private var submitButtonText: String {
        type == "income" ? "Add Income" : "Add Expense"
    }

    /// Filters the loaded categories to only those matching the current transaction type.
    private var filteredCategories: [Category] {
        categories.filter { type == "income" ? $0.isIncome : $0.isExpense }
    }

    // MARK: - Body

    /// The main view body. Wraps the form in a dark-themed scrollable layout
    /// with a colored header bar, form fields, action buttons, and a submit button.
    var body: some View {
        ZStack {
            // Full-screen dark background extending to all edges.
            Color.appDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Accent color bar at the top of the form.
                accentColor
                    .frame(height: 4)

                ScrollView {
                    VStack(spacing: 20) {
                        // Contact name input with dropdown picker.
                        contactField

                        // Category selector with dropdown picker.
                        categoryField

                        // Date picker in compact style.
                        dateField

                        // Amount text input with decimal keyboard.
                        amountField

                        // Row of action buttons: Note, Labels, Picture.
                        actionButtonsRow

                        // Full-width submit button.
                        submitButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(titleText)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .darkToolbar()
        .toolbar {
            // Cancel button in the bottom toolbar to dismiss the view.
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Cancel and go Back")
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
        .onAppear {
            loadData()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Add Note", isPresented: $showNoteAlert) {
            TextField("Enter note...", text: $note)
            Button("Save", role: .cancel) {}
        } message: {
            Text("Add a note to this entry.")
        }
        .confirmationDialog("Select Contact", isPresented: $showContactPicker, titleVisibility: .visible) {
            contactPickerButtons
        }
        .confirmationDialog("Select Category", isPresented: $showCategoryPicker, titleVisibility: .visible) {
            categoryPickerButtons
        }
        .confirmationDialog("Attach Photo", isPresented: $showImageSourcePicker, titleVisibility: .visible) {
            imageSourceButtons
        }
        .sheet(isPresented: $showCamera, onDismiss: {
            // Upload the captured image after the camera sheet is dismissed.
            if let image = capturedImage {
                uploadCapturedImage(image)
            }
        }) {
            ImagePicker(image: $capturedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showPhotoLibrary, onDismiss: {
            // Upload the selected image after the photo library sheet is dismissed.
            if let image = capturedImage {
                uploadCapturedImage(image)
            }
        }) {
            ImagePicker(image: $capturedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showLabelsView) {
            labelsSheet
        }
    }

    // MARK: - Contact Field

    /// The contact name text field with a dropdown button for selecting existing contacts.
    /// The user can type a new contact name directly or tap the dropdown to pick from
    /// previously used contacts loaded from the API.
    private var contactField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Contact Name")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.appTextGray)

            HStack(spacing: 8) {
                TextField("Enter contact name", text: $contactName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()

                // Dropdown button to show the contact picker dialog.
                Button {
                    showContactPicker = true
                } label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.appTextGray)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.appDarkGray)
            .cornerRadius(10)
        }
    }

    /// Builds the list of buttons for the contact picker confirmation dialog.
    /// Each button sets the contact name field and stores the selected Contact object.
    @ViewBuilder
    private var contactPickerButtons: some View {
        ForEach(contacts) { contact in
            Button(contact.displayName) {
                contactName = contact.displayName
                selectedContact = contact
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Category Field

    /// The category selector displaying the currently selected category name
    /// with a dropdown button to open the category picker dialog.
    /// Categories are filtered by the transaction type (income or expense).
    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Category")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.appTextGray)

            HStack(spacing: 8) {
                Text(selectedCategory?.Name ?? "Select a category")
                    .font(.system(size: 16))
                    .foregroundColor(selectedCategory != nil ? .white : Color.appTextGray.opacity(0.6))

                Spacer()

                // Dropdown button to show the category picker dialog.
                Button {
                    showCategoryPicker = true
                } label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.appTextGray)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.appDarkGray)
            .cornerRadius(10)
        }
    }

    /// Builds the list of buttons for the category picker confirmation dialog.
    /// Only shows categories that match the current transaction type.
    @ViewBuilder
    private var categoryPickerButtons: some View {
        ForEach(filteredCategories) { category in
            Button(category.Name) {
                selectedCategory = category
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Date Field

    /// A compact-style date picker for selecting the transaction date.
    /// Defaults to today and uses the app's dark theme styling.
    private var dateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Date")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.appTextGray)

            HStack {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.appDarkGray)
            .cornerRadius(10)
        }
    }

    // MARK: - Amount Field

    /// A text field for entering the monetary amount with a decimal keyboard.
    /// Displays a dollar sign prefix inside the field for context.
    private var amountField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Amount")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.appTextGray)

            HStack(spacing: 4) {
                Text("$")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.appTextGray)

                TextField("0.00", text: $amount)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.appDarkGray)
            .cornerRadius(10)
        }
    }

    // MARK: - Action Buttons Row

    /// A row of three equally-spaced action buttons for Note, Labels, and Picture.
    /// Each button shows an SF Symbol icon, a label, and a badge count when items
    /// have been added. Tapping each button triggers its respective interaction.
    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            // Note button: shows an alert with a text field to add/edit a note.
            actionButton(
                icon: "note.text",
                label: "Note",
                badgeCount: note.isEmpty ? 0 : 1,
                action: { showNoteAlert = true }
            )

            // Labels button: navigates to LabelsView for label selection.
            actionButton(
                icon: "tag",
                label: "Labels",
                badgeCount: labels.count,
                action: { showLabelsView = true }
            )

            // Picture button: shows a dialog to choose camera or photo library.
            actionButton(
                icon: "paperclip",
                label: "Picture",
                badgeCount: files.count,
                action: { showImageSourcePicker = true }
            )
        }
    }

    /// Builds a single action button with an icon, label, and optional badge count.
    /// The button is styled as a dark card with the accent color used for the icon
    /// and badge indicator.
    ///
    /// - Parameters:
    ///   - icon: The SF Symbol name for the button's icon.
    ///   - label: The text label displayed below the icon.
    ///   - badgeCount: The number to display in the badge. Hidden when zero.
    ///   - action: The closure to execute when the button is tapped.
    /// - Returns: A styled action button view.
    private func actionButton(icon: String, label: String, badgeCount: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(accentColor)
                        .frame(width: 40, height: 40)

                    // Badge indicator showing the count of attached items.
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(accentColor)
                            .clipShape(Circle())
                            .offset(x: 6, y: -4)
                    }
                }

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.appTextGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appDarkGray)
            .cornerRadius(10)
        }
    }

    /// Builds the buttons for the image source confirmation dialog.
    /// Offers Camera and Photo Library options, with Camera only available on physical devices.
    @ViewBuilder
    private var imageSourceButtons: some View {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            Button("Camera") {
                showCamera = true
            }
        }
        Button("Photo Library") {
            showPhotoLibrary = true
        }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Labels Sheet

    /// Presents the LabelsView as a sheet for selecting and managing labels.
    /// Uses a callback closure to receive the selected labels when the user saves.
    private var labelsSheet: some View {
        NavigationStack {
            LabelsView(selectedLabels: labels) { updatedLabels in
                labels = updatedLabels
                showLabelsView = false
            }
        }
    }

    // MARK: - Submit Button

    /// The full-width submit button styled with the accent color.
    /// Shows a loading spinner while the create request is in progress.
    /// Validates required fields before attempting to submit.
    private var submitButton: some View {
        Button {
            submitLedger()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(submitButtonText)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(accentColor)
            .cornerRadius(10)
        }
        .disabled(isLoading)
        .padding(.top, 8)
    }

    // MARK: - Data Loading

    /// Loads contacts and categories from their respective services on view appear.
    /// Also requests the user's location for geo-tagging the transaction.
    /// Runs all loads concurrently using a TaskGroup pattern.
    private func loadData() {
        locationManager.requestLocation()

        Task {
            do {
                async let contactsResult = ContactService.shared.getContacts()
                async let categoriesResult = CategoryService.shared.getCategories()

                let loadedContacts = try await contactsResult
                let loadedCategories = try await categoriesResult

                await MainActor.run {
                    contacts = loadedContacts
                    categories = loadedCategories
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load data: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    // MARK: - Image Upload

    /// Uploads a captured UIImage to the API via FileService.
    /// Converts the image to JPEG data, uploads it, and appends the returned
    /// FileModel to the files array. Clears the captured image after upload.
    ///
    /// - Parameter image: The UIImage captured from the camera or photo library.
    private func uploadCapturedImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        Task {
            do {
                let fileModel = try await FileService.shared.uploadFile(imageData: imageData, fileExtension: "jpg")
                await MainActor.run {
                    files.append(fileModel)
                    capturedImage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    showError = true
                    capturedImage = nil
                }
            }
        }
    }

    // MARK: - Submit

    /// Validates the form fields and submits the new ledger entry to the API.
    /// Builds a Ledger object from the form state, negates the amount for expenses,
    /// attaches GPS coordinates from the location manager, and calls
    /// LedgerService.createLedger(). On success, dismisses the view.
    private func submitLedger() {
        // Validate required fields.
        guard !contactName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a contact name."
            showError = true
            return
        }

        guard selectedCategory != nil else {
            errorMessage = "Please select a category."
            showError = true
            return
        }

        guard let parsedAmount = Double(amount), parsedAmount > 0 else {
            errorMessage = "Please enter a valid amount."
            showError = true
            return
        }

        isLoading = true

        Task {
            do {
                // Build the contact object. Use the selected contact if available,
                // otherwise create a new contact with just the typed name.
                var contact = selectedContact ?? Contact()
                if selectedContact == nil {
                    contact.Name = contactName.trimmingCharacters(in: .whitespaces)
                }

                // Determine the signed amount. Expenses are stored as negative values.
                var finalAmount = parsedAmount
                if type == "expense" {
                    finalAmount = parsedAmount * -1
                }

                // Build the Ledger object with all form fields.
                var ledger = Ledger()
                ledger.LedgerDate = date.toAPIString()
                ledger.Amount = finalAmount
                ledger.Note = note
                ledger.Lat = locationManager.latitude
                ledger.Lon = locationManager.longitude
                ledger.LedgerContact = contact
                ledger.LedgerCategory = selectedCategory!
                ledger.Labels = labels
                ledger.Files = files

                _ = try await LedgerService.shared.createLedger(ledger: ledger)

                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create entry: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LedgerModifyView(type: "expense")
    }
}
