//
// LabelsView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// Label selection and management screen used when creating or editing a ledger entry.
/// Pixel-perfect match of the Ionic Skyclerk labels page.
/// Displays a dark card (#141414) on a #404040 background with centered "Add Labels" title,
/// a text input for creating new labels with a gray gradient dropdown/add button,
/// a scrollable list of all labels with dark checkbox rows (#2a2a2a unchecked, #474747 checked),
/// and a light-gray gradient "Save Label" button with a tags icon.
struct LabelsView: View {
    /// The labels that are already selected when this view opens.
    /// Used to pre-check labels that were previously attached to the ledger entry.
    let selectedLabels: [LedgerLabel]

    /// Callback closure invoked when the user taps "Save Label".
    /// Passes the final array of selected LedgerLabel objects back to the parent view.
    let onSave: ([LedgerLabel]) -> Void

    /// Dismiss action to close this view when cancelling.
    @Environment(\.dismiss) private var dismiss

    /// All labels loaded from the API via LabelService.
    @State private var labels: [LedgerLabel] = []

    /// The set of label IDs that are currently selected (checked).
    /// Initialized from the selectedLabels parameter on appear.
    @State private var selectedLabelIds: Set<Int> = []

    /// The text entered in the "Add New Label" field.
    @State private var newLabelName: String = ""

    /// Whether a data loading or creation operation is in progress.
    @State private var isLoading: Bool = false

    /// Whether an error alert should be displayed.
    @State private var showError: Bool = false

    /// The error message to display in the error alert.
    @State private var errorMessage: String = ""

    // MARK: - Colors matching Ionic SCSS

    /// Background color for the content area behind the form card (#404040).
    private let bgColor = Color(hex: "404040")

    /// Background color for the form card (#141414).
    private let formBgColor = Color(hex: "141414")

    /// Label text color (#bcbcbc).
    private let labelColor = Color(hex: "bcbcbc")

    /// Unchecked checkbox row background (#2a2a2a).
    private let uncheckedRowBg = Color(hex: "2a2a2a")

    /// Checked checkbox row background (#474747).
    private let checkedRowBg = Color(hex: "474747")

    /// Link color for the back button (#b2d6ec).
    private let linkColor = Color(hex: "b2d6ec")

    // MARK: - Body

    /// The main view body. Renders the full Ionic labels page layout:
    /// a #404040 background with a #141414 form card containing centered "Add Labels" title,
    /// a new label input row, checkbox label rows, and a "Save Label" button.
    /// The bottom toolbar has a "Cancel and go Back" link and logo.
    var body: some View {
        ZStack {
            // Full-screen background matching Ionic's havePopup content background.
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // The dark form card container.
                formCard
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
            loadLabels()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Form Card

    /// The main dark form card (#141414) with rounded corners and shadow,
    /// matching the Ionic .form-content container. Contains the title,
    /// new label input, checkbox list, and save button.
    private var formCard: some View {
        VStack(spacing: 0) {
            // Centered "Add Labels" title (matching Ionic h3 text-center).
            titleSection

            // New label input with dropdown/add button (matching Ionic .dropdown layout).
            addLabelSection

            // Scrollable checkbox list of all labels.
            labelsList

            // Save button (matching Ionic button-container with lightgray gradient).
            saveButton
                .padding(.top, 16)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .background(formBgColor)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.75), radius: 16, x: 0, y: 0)
    }

    // MARK: - Title Section

    /// Centered "Add Labels" title matching Ionic's h3 text-center style.
    /// The title uses 35px bold text in the income green-tinted color (#b8cda3).
    private var titleSection: some View {
        Text("Add Labels")
            .font(.system(size: 35, weight: .bold))
            .foregroundColor(Color(hex: "b8cda3"))
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .padding(.bottom, 10)
    }

    // MARK: - Add Label Section

    /// A text field with a gray gradient dropdown/add button for creating new labels.
    /// Matches the Ionic .dropdown layout with a stacked "Add New Label" label,
    /// a white background text input, and a 50px wide gray gradient button on the right.
    /// When the user types a name and taps the button, a new label is created
    /// via LabelService, added to the list, and automatically selected.
    private var addLabelSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add New Label")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(labelColor)
                .padding(.bottom, 10)

            HStack(spacing: 8) {
                // Text input with white background matching Ionic's ion-input style.
                TextField("", text: $newLabelName)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .frame(height: 42)
                    .background(Color.white)
                    .cornerRadius(5)
                    .autocorrectionDisabled()
                    .onSubmit {
                        createNewLabel()
                    }

                // Gray gradient add button matching Ionic's graygradiantbtn.
                Button {
                    createNewLabel()
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
                        colors: [Color(hex: "5b5b5b"), Color(hex: "8f8f8f")],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(5)
                .disabled(newLabelName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Labels List

    /// A scrollable list of all available labels with custom checkbox rows.
    /// Each row matches the Ionic ion-item[checkbox] style:
    /// - Unchecked: #2a2a2a background with dark check icon
    /// - Checked: #474747 background with light check icon
    /// Rows have 5px border radius, 16px horizontal padding, and 5px top margin between items.
    /// The checkbox image (24px) is on the right side, label name on the left.
    private var labelsList: some View {
        ScrollView {
            LazyVStack(spacing: 5) {
                ForEach(labels) { item in
                    // Each label row is tappable to toggle its selection.
                    Button {
                        toggleLabel(item)
                    } label: {
                        labelRow(item: item)
                    }
                }
            }
        }
    }

    /// Builds a single label row matching the Ionic checkbox item style.
    /// Shows the label name on the left and a custom check icon on the right.
    /// Background color changes based on whether the label is selected.
    ///
    /// - Parameter item: The LedgerLabel to display in this row.
    /// - Returns: A styled row view for the label.
    private func labelRow(item: LedgerLabel) -> some View {
        let isSelected = selectedLabelIds.contains(item.Id)

        return HStack {
            Text(item.Name)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()

            // Custom check icon matching Ionic's check-dark.svg / check-light.svg.
            Image(isSelected ? "check-light" : "check-dark")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? checkedRowBg : uncheckedRowBg)
        .cornerRadius(5)
    }

    // MARK: - Save Button

    /// A full-width "Save Label" button with a light-gray gradient background,
    /// matching the Ionic lightgray button-custom style.
    /// Gradient: rgb(150,154,157) -> rgb(226,228,230).
    /// Includes a tags icon on the left matching Ionic's btn-tags.svg.
    /// Height: 50px, font: 16px, uppercase text, 2px dark border, 6px radius.
    private var saveButton: some View {
        Button {
            saveSelectedLabels()
        } label: {
            HStack(spacing: 10) {
                Image("btn-tags")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)

                Text("Save Label")
                    .font(.system(size: 16, weight: .regular))
                    .textCase(.uppercase)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [Color(red: 150/255, green: 154/255, blue: 157/255), Color(red: 226/255, green: 228/255, blue: 230/255)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(hex: "141414"), lineWidth: 2)
            )
            .cornerRadius(6)
        }
    }

    // MARK: - Data Loading

    /// Loads all labels from LabelService and initializes the selected IDs
    /// from the labels that were passed in as already selected.
    private func loadLabels() {
        // Initialize the selected IDs from the pre-selected labels.
        selectedLabelIds = Set(selectedLabels.map { $0.Id })

        Task {
            do {
                let loadedLabels = try await LabelService.shared.getLabels()
                await MainActor.run {
                    labels = loadedLabels
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load labels: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    // MARK: - Toggle Label Selection

    /// Toggles the selection state of a label. If the label is currently selected,
    /// it is removed from the selection set. If not selected, it is added.
    ///
    /// - Parameter label: The label to toggle.
    private func toggleLabel(_ label: LedgerLabel) {
        if selectedLabelIds.contains(label.Id) {
            selectedLabelIds.remove(label.Id)
        } else {
            selectedLabelIds.insert(label.Id)
        }
    }

    // MARK: - Create New Label

    /// Creates a new label via LabelService with the name entered in the text field.
    /// On success, appends the new label to the list, auto-selects it, and clears
    /// the text field. On failure, displays an error alert.
    private func createNewLabel() {
        let name = newLabelName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        isLoading = true

        Task {
            do {
                let newLabel = try await LabelService.shared.createLabel(name: name)
                await MainActor.run {
                    labels.append(newLabel)
                    selectedLabelIds.insert(newLabel.Id)
                    newLabelName = ""
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create label: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    // MARK: - Save Selected Labels

    /// Collects the full Label objects for all selected IDs and passes them
    /// to the onSave callback. This sends the selected labels back to the
    /// parent LedgerModifyView.
    private func saveSelectedLabels() {
        let selected = labels.filter { selectedLabelIds.contains($0.Id) }
        onSave(selected)
    }
}

#Preview {
    NavigationStack {
        LabelsView(selectedLabels: []) { labels in
            print("Selected: \(labels)")
        }
    }
}
