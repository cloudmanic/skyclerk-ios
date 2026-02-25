//
// LabelsView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI


/// Label selection and management screen used when creating or editing a ledger entry.
/// Displays all available labels with checkboxes, allows the user to select/deselect
/// labels, and provides a text field to create new labels on the fly. Uses a callback
/// closure pattern to pass the selected labels back to the calling view (LedgerModifyView).
struct LabelsView: View {
    /// The labels that are already selected when this view opens.
    /// Used to pre-check labels that were previously attached to the ledger entry.
    let selectedLabels: [LedgerLabel]

    /// Callback closure invoked when the user taps "Save Labels".
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

    // MARK: - Body

    /// The main view body. Displays a dark-themed screen with a title,
    /// a text field for creating new labels, a scrollable list of all labels
    /// with checkboxes, and a save button at the bottom.
    var body: some View {
        ZStack {
            // Full-screen dark background extending to all edges.
            Color.appDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title header.
                headerSection

                // New label creation row.
                addLabelSection

                // Scrollable list of all labels with checkboxes.
                labelsList

                // Full-width save button pinned to the bottom.
                saveButton
            }
        }
        .navigationTitle("Add Labels")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .darkToolbar()
        .toolbar {
            // Cancel button in the bottom toolbar to dismiss without saving.
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
            loadLabels()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header Section

    /// Displays the screen title "Add Labels" in a prominent style
    /// at the top of the view, above the label list.
    private var headerSection: some View {
        HStack {
            Text("Add Labels")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Add Label Section

    /// A text field with a "+" button for creating new labels.
    /// When the user types a name and taps the button, a new label is created
    /// via LabelService, added to the list, and automatically selected.
    private var addLabelSection: some View {
        HStack(spacing: 10) {
            TextField("Add New Label", text: $newLabelName)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.appDarkGray)
                .cornerRadius(8)

            // Create button that sends the new label to the API.
            Button {
                createNewLabel()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.appSuccess)
            }
            .disabled(newLabelName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Labels List

    /// A scrollable list of all available labels, each with a checkbox toggle.
    /// Selected labels show a filled checkmark circle, unselected labels show
    /// an empty circle. Tapping a row toggles its selection state.
    private var labelsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(labels) { item in
                    // Each label row is tappable to toggle its selection.
                    Button {
                        toggleLabel(item)
                    } label: {
                        HStack(spacing: 12) {
                            // Checkbox indicator: filled when selected, empty when not.
                            Image(systemName: selectedLabelIds.contains(item.Id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(selectedLabelIds.contains(item.Id) ? Color.appSuccess : Color.appTextGray)

                            Text(item.Name)
                                .font(.system(size: 15))
                                .foregroundColor(.white)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }

                    // Subtle divider between rows.
                    Divider()
                        .background(Color.appDarkGray)
                        .padding(.leading, 54)
                }
            }
        }
    }

    // MARK: - Save Button

    /// A full-width green save button that collects all selected labels
    /// and passes them back to the parent view via the onSave callback.
    private var saveButton: some View {
        Button {
            saveSelectedLabels()
        } label: {
            Text("Save Labels")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appSuccess)
                .cornerRadius(10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
