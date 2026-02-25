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
/// Pixel-perfect match of the Ionic Skyclerk ledger-modify page.
/// The form is wrapped in a dark card (#141414) on a #404040 background,
/// with a centered title, stacked form fields with white inputs, three
/// 70x70 action buttons for Note/Labels/Picture, and a gradient submit button.
/// Income uses green accents, expense uses red accents.
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

    /// The text entered in the category field. Can be a new name or match an existing category.
    @State private var categoryText: String = ""

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

    /// Controls display of the date picker popover.
    @State private var showDatePicker: Bool = false

    /// Location manager for tagging the transaction with GPS coordinates.
    @StateObject private var locationManager = LocationManager()

    // MARK: - Colors matching Ionic SCSS

    /// Background color for the content area behind the form card (#404040).
    private let bgColor = Color(hex: "404040")

    /// Background color for the form card (#141414).
    private let formBgColor = Color(hex: "141414")

    /// Label text color (#bcbcbc).
    private let labelColor = Color(hex: "bcbcbc")

    /// Title color for income entries (#b8cda3).
    private let incomeTitleColor = Color(hex: "b8cda3")

    /// Title color for expense entries (#bcbcbc).
    private let expenseTitleColor = Color(hex: "bcbcbc")

    /// Action button background color (#3b3b3b).
    private let actionBtnBg = Color(hex: "3b3b3b")

    /// Action button label text color (#b4b4b4).
    private let actionBtnLabelColor = Color(hex: "b4b4b4")

    /// Dark footer/toolbar background color (#141414).
    private let footerBg = Color(hex: "141414")

    /// Link color for the back button (#b2d6ec).
    private let linkColor = Color(hex: "b2d6ec")

    // MARK: - Computed Properties

    /// Returns the title color based on the transaction type.
    /// Green-tinted for income, gray for expense.
    private var titleColor: Color {
        type == "income" ? incomeTitleColor : expenseTitleColor
    }

    /// Returns the title text based on the transaction type.
    private var titleText: String {
        type == "income" ? "Add Income" : "Add Expense"
    }

    /// Returns the asset catalog icon name for the title based on the transaction type.
    private var titleIconName: String {
        type == "income" ? "add-income-icon" : "add-expense-icon"
    }

    /// Returns the submit button text based on the transaction type.
    private var submitButtonText: String {
        type == "income" ? "Add Income" : "Add Expense"
    }

    /// Returns the gradient colors for the submit button.
    /// Income: green gradient (#5c882c -> #75a04a).
    /// Expense: red gradient (#7b2624 -> #96312d).
    private var submitGradient: LinearGradient {
        if type == "income" {
            return LinearGradient(
                colors: [Color(hex: "5c882c"), Color(hex: "75a04a")],
                startPoint: .bottom,
                endPoint: .top
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "7b2624"), Color(hex: "96312d")],
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }

    /// Filters the loaded categories to only those matching the current transaction type.
    private var filteredCategories: [Category] {
        categories.filter { type == "income" ? $0.isIncome : $0.isExpense }
    }

    // MARK: - Body

    /// The main view body. Renders the full Ionic ledger-modify page layout:
    /// a #404040 background with a #141414 form card containing centered title,
    /// stacked form fields, action buttons row, and a gradient submit button.
    /// The bottom toolbar has a "Cancel and go Back" link and logo.
    var body: some View {
        ZStack {
            // Full-screen background matching Ionic's havePopup content background.
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // The dark form card container.
                    formCard
                }
                .padding(.horizontal, 0)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Empty principal to prevent default title.
            ToolbarItem(placement: .principal) {
                EmptyView()
            }
        }
        .toolbarBackground(bgColor, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            // Bottom toolbar with cancel link and logo, matching Ionic dark footer.
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("\u{00AB} Cancel and go Back")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(linkColor)
                            .textCase(.uppercase)
                    }
                    Spacer()
                    Image("logo-small")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                }
            }
        }
        .toolbarBackground(Color(hex: "2c2c2c"), for: .bottomBar)
        .toolbarColorScheme(.dark, for: .bottomBar)
        .onAppear {
            loadData()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Ledger Note", isPresented: $showNoteAlert) {
            TextField("Enter a ledger note...", text: $note)
            Button("Cancel", role: .cancel) {}
            Button("Add Note") {}
        } message: {
            Text("")
        }
        .confirmationDialog("Contacts", isPresented: $showContactPicker, titleVisibility: .visible) {
            contactPickerButtons
        }
        .confirmationDialog("Categories", isPresented: $showCategoryPicker, titleVisibility: .visible) {
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

    // MARK: - Form Card

    /// The main dark form card (#141414) with rounded corners and shadow,
    /// matching the Ionic .form-content container. Contains the title,
    /// form fields, action buttons, and submit button.
    private var formCard: some View {
        VStack(spacing: 0) {
            // Centered title with icon (matching Ionic h3 text-center).
            titleSection

            // Form fields list (matching Ionic ion-list with login-form-list).
            formFieldsSection

            // Action buttons row: Note, Labels, Picture (matching Ionic ion-row[buttons]).
            actionButtonsRow
                .padding(.top, 10)
                .padding(.bottom, 20)

            // Submit button (matching Ionic button-container).
            submitButton
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 0)
        .background(formBgColor)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.75), radius: 16, x: 0, y: 0)
    }

    // MARK: - Title Section

    /// Centered title with the type icon, matching Ionic's h3 text-center.
    /// Shows "Add Income" with green-tinted text or "Add Expense" with gray text.
    /// The icon is 32px tall, positioned slightly below baseline, with bold 35px text.
    private var titleSection: some View {
        HStack(spacing: 6) {
            Image(titleIconName)
                .resizable()
                .scaledToFit()
                .frame(height: 32)
                .offset(y: 3)

            Text(titleText)
                .font(.system(size: 35, weight: .bold))
                .foregroundColor(titleColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Form Fields Section

    /// The stacked form fields matching the Ionic ion-list layout.
    /// Contact and Category each have a text input with a dropdown button.
    /// Date and Amount sit side-by-side in a 50/50 split row.
    /// Labels: 16px semibold #bcbcbc, inputs: white bg, 42px height, 5px radius.
    private var formFieldsSection: some View {
        VStack(spacing: 0) {
            // Contact name field with dropdown.
            contactField
                .padding(.bottom, 20)

            // Category field with dropdown.
            categoryField
                .padding(.bottom, 20)

            // Date and Amount side by side (matching Ionic 6-col + 6-col layout).
            HStack(alignment: .top, spacing: 10) {
                dateField
                amountField
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Contact Field

    /// Contact name text field with a gray gradient dropdown button on the right.
    /// Matches the Ionic .dropdown layout: input fills available space with
    /// padding-right: 60px for the absolutely-positioned 50px wide dropdown button.
    /// The stacked label reads "Contact Name" in 16px semibold #bcbcbc.
    private var contactField: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Contact Name")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(labelColor)
                .padding(.bottom, 10)

            HStack(spacing: 8) {
                // Text input with white background matching Ionic's ion-input style.
                TextField("", text: $contactName)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .frame(height: 42)
                    .background(Color.white)
                    .cornerRadius(5)
                    .autocorrectionDisabled()

                // Gray gradient dropdown button matching Ionic's graygradiantbtn.
                dropdownButton {
                    showContactPicker = true
                }
            }
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

    /// Category text field with a gray gradient dropdown button on the right.
    /// Same layout as the contact field. The stacked label reads "Category".
    /// User can type a new category name or pick from the dropdown.
    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(labelColor)
                .padding(.bottom, 10)

            HStack(spacing: 8) {
                // Text input with white background.
                TextField("", text: $categoryText)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .frame(height: 42)
                    .background(Color.white)
                    .cornerRadius(5)
                    .autocorrectionDisabled()

                // Gray gradient dropdown button.
                dropdownButton {
                    showCategoryPicker = true
                }
            }
        }
    }

    /// Builds the list of buttons for the category picker confirmation dialog.
    /// Only shows categories that match the current transaction type.
    @ViewBuilder
    private var categoryPickerButtons: some View {
        ForEach(filteredCategories) { category in
            Button(category.Name) {
                selectedCategory = category
                categoryText = category.Name
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Date Field

    /// A date input field matching the Ionic ion-datetime display.
    /// Shows a stacked "Date" label and a white-background field with the
    /// date formatted as MM/DD/YYYY. Taps open a native date picker.
    private var dateField: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Date")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(labelColor)
                .padding(.bottom, 10)

            // White background container matching the Ionic input field style.
            ZStack {
                // DatePicker styled to blend with the white input field.
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.black)
                    .colorScheme(.light)
            }
            .frame(height: 42)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(5)
        }
    }

    // MARK: - Amount Field

    /// An amount text field with decimal keyboard, matching the Ionic layout.
    /// Shows a stacked "Amount" label and a white-background input field
    /// with placeholder "0.00". Takes half the width beside the date field.
    private var amountField: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Amount")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(labelColor)
                .padding(.bottom, 10)

            // Text input with white background.
            TextField("0.00", text: $amount)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 8)
                .frame(height: 42)
                .background(Color.white)
                .cornerRadius(5)
        }
    }

    // MARK: - Dropdown Button

    /// A reusable gray gradient dropdown button matching the Ionic graygradiantbtn style.
    /// Shows a down-arrow-gray icon inside a gradient background (#5b5b5b -> #8f8f8f).
    /// The button is 50px wide and 42px tall with 5px border radius.
    ///
    /// - Parameter action: The closure to execute when the button is tapped.
    /// - Returns: A styled dropdown button view.
    private func dropdownButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image("down-arrow-gray")
                .resizable()
                .scaledToFit()
                .frame(height: 24)
                .padding(.top, 3)
        }
        .frame(width: 50, height: 42)
        .background(
            LinearGradient(
                colors: [Color(hex: "5b5b5b"), Color(hex: "8f8f8f")],
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .cornerRadius(5)
    }

    // MARK: - Action Buttons Row

    /// A row of three action buttons matching the Ionic ion-row[buttons] layout.
    /// Each button is a 70x70 dark square (#3b3b3b) with a shadow effect,
    /// containing a 36px icon. Below each button is a 14px semibold label in #b4b4b4.
    /// Badge counts appear as small blue circles positioned at the top-left of each button.
    private var actionButtonsRow: some View {
        HStack(spacing: 0) {
            // Note button - left aligned.
            VStack(spacing: 0) {
                actionButtonWithBadge(
                    imageName: "note",
                    badgeCount: note.isEmpty ? 0 : 1,
                    badgeOffsetX: -25,
                    action: { showNoteAlert = true }
                )
                Text("Note")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(actionBtnLabelColor)
                    .frame(width: 70)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Labels button - center aligned.
            VStack(spacing: 0) {
                actionButtonWithBadge(
                    imageName: "tags",
                    badgeCount: labels.count,
                    badgeOffsetX: -25,
                    action: { showLabelsView = true }
                )
                Text("Labels")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(actionBtnLabelColor)
                    .frame(width: 70)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Picture button - right aligned.
            VStack(spacing: 0) {
                actionButtonWithBadge(
                    imageName: "attach",
                    badgeCount: files.count,
                    badgeOffsetX: -15,
                    action: { showImageSourcePicker = true }
                )
                Text("Picture")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(actionBtnLabelColor)
                    .frame(width: 70)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    /// Builds a single 70x70 action button with the Ionic graybtn style and an optional badge.
    /// The button has a dark background (#3b3b3b) with a highlight shadow on top
    /// and a dark inset shadow on bottom, matching the Ionic box-shadow.
    ///
    /// - Parameters:
    ///   - imageName: The asset catalog image name for the icon.
    ///   - badgeCount: The number to display in the badge. Hidden when zero.
    ///   - badgeOffsetX: Horizontal offset for the badge position.
    ///   - action: The closure to execute when the button is tapped.
    /// - Returns: A styled action button view with optional badge overlay.
    private func actionButtonWithBadge(imageName: String, badgeCount: Int, badgeOffsetX: CGFloat, action: @escaping () -> Void) -> some View {
        ZStack(alignment: .topLeading) {
            Button(action: action) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
            }
            .frame(width: 70, height: 70)
            .background(actionBtnBg)
            .overlay(
                // Top highlight matching Ionic box-shadow: 0px -2px 0px rgba(255,255,255,0.22).
                VStack {
                    Color.white.opacity(0.22).frame(height: 2)
                    Spacer()
                    Color.black.opacity(0.67).frame(height: 2)
                }
            )
            .cornerRadius(6)

            // Badge count circle matching Ionic ledger-modify-bubble-count.
            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Color(hex: "3880ff"))
                    .clipShape(Circle())
                    .offset(x: -2, y: -2)
            }
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

    /// The full-width submit button with gradient background matching the Ionic button-custom style.
    /// Income: green gradient (#5c882c -> #75a04a) with icon.
    /// Expense: red gradient (#7b2624 -> #96312d) with icon.
    /// Height: 54px minimum, font: 16px, uppercase text, 2px dark border.
    private var submitButton: some View {
        Button {
            submitLedger()
        } label: {
            HStack(spacing: 5) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(titleIconName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                }
                Text(submitButtonText)
                    .font(.system(size: 16, weight: .regular))
                    .textCase(.uppercase)
            }
            .foregroundColor(.white)
            .frame(minWidth: UIScreen.main.bounds.width * 0.60)
            .frame(height: 54)
            .background(submitGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(hex: "141414"), lineWidth: 2)
            )
            .cornerRadius(6)
        }
        .disabled(isLoading)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Data Loading

    /// Loads contacts and categories from their respective services on view appear.
    /// Also requests the user's location for geo-tagging the transaction.
    /// Runs all loads concurrently using async let.
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
    /// Handles both contact text input and dropdown selection for contact resolution.
    /// Handles both category text input and dropdown selection for category resolution.
    private func submitLedger() {
        // Validate required fields.
        guard !contactName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a contact name."
            showError = true
            return
        }

        // Use the selected category from the dropdown, or build a new one from the text.
        let resolvedCategory: Category
        if let selected = selectedCategory {
            resolvedCategory = selected
        } else if !categoryText.trimmingCharacters(in: .whitespaces).isEmpty {
            var cat = Category()
            cat.categoryType = type
            cat.Name = categoryText.trimmingCharacters(in: .whitespaces)
            resolvedCategory = cat
        } else {
            errorMessage = "Please select or enter a category."
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
                ledger.LedgerCategory = resolvedCategory
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
