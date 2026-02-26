//
// NoteEditorView.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI

/// A modal editor for adding or editing a ledger note. Presented as a `.sheet`
/// from LedgerModifyView, this view provides a multi-line text editor with save,
/// clear, and cancel actions. It works on a local draft copy of the note text so
/// that changes are only written back to the parent binding when the user taps
/// "Save Note". Cancelling discards any edits.
///
/// The styling matches the app's dark modal pattern used by ContactPickerView
/// and CategoryPickerView: #232323 background, #2a2a2a button backgrounds,
/// #bcbcbc label text, and white input fields with 5px corner radius.
struct NoteEditorView: View {
    /// Binding to the parent view's note string. Only updated when the user
    /// taps "Save Note" or "Clear Note". Cancel leaves this value unchanged.
    @Binding var note: String

    /// Dismiss action to close this sheet modal.
    @Environment(\.dismiss) private var dismiss

    /// A local draft copy of the note text. Initialized from the `note` binding
    /// on appear so that edits are isolated until the user explicitly saves.
    @State private var draftNote: String = ""

    // MARK: - Colors

    /// Modal background color (#232323), matching the app's dark sheet pattern.
    private let bgColor = Color(hex: "232323")

    /// Button and row background color (#2a2a2a), used for cancel and clear buttons.
    private let rowBgColor = Color(hex: "2a2a2a")

    /// Label and secondary text color (#bcbcbc), used for the title and button text.
    private let labelColor = Color(hex: "bcbcbc")

    // MARK: - Body

    /// The main view body. Renders a dark modal with a centered title, a multi-line
    /// text editor, a green save button, an optional clear button (shown only when
    /// the note has existing content), and a cancel button at the bottom.
    var body: some View {
        VStack(spacing: 0) {
            // Centered title
            titleSection

            // Multi-line text editor for the note content
            noteEditor
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // Save button with green gradient
            saveButton
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            // Clear note button, only visible when there is existing note text
            if !note.isEmpty {
                clearButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            Spacer()

            // Cancel button at the bottom
            cancelButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(bgColor.ignoresSafeArea())
        .onAppear {
            initializeDraft()
        }
    }

    // MARK: - Title Section

    /// Centered "Ledger Note" title matching the app's modal title style.
    /// Uses 16px semibold text in the label gray color (#bcbcbc).
    private var titleSection: some View {
        Text("Ledger Note")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(labelColor)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 4)
    }

    // MARK: - Note Editor

    /// A multi-line TextEditor for composing the note content. Uses a white background
    /// with black text, 16px font, 5px corner radius, and a minimum height of 150px.
    /// An overlay displays placeholder text ("Enter a note...") when the editor is empty.
    /// The `.scrollContentBackground(.hidden)` modifier removes the default gray
    /// background that iOS applies to TextEditor.
    private var noteEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $draftNote)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 150)
                .background(Color.white)
                .cornerRadius(5)

            // Placeholder text overlay, shown only when the editor is empty.
            // Positioned with matching padding so it aligns with the typed text.
            if draftNote.isEmpty {
                Text("Enter a note...")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "999999"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Save Button

    /// A full-width save button with the green gradient matching the income submit
    /// button style. Gradient runs from #5c882c (bottom) to #75a04a (top).
    /// Tapping writes the draft text back to the parent's note binding and dismisses.
    private var saveButton: some View {
        Button {
            saveNote()
        } label: {
            Text("Save Note")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "5c882c"), Color(hex: "75a04a")],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(5)
        }
    }

    // MARK: - Clear Button

    /// A full-width button that clears the note text entirely and dismisses the modal.
    /// Only shown when the parent's note binding already has content.
    /// Styled as a subtle dark button (#2a2a2a background, #bcbcbc text).
    private var clearButton: some View {
        Button {
            clearNote()
        } label: {
            Text("Clear Note")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(labelColor)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(rowBgColor)
                .cornerRadius(5)
        }
    }

    // MARK: - Cancel Button

    /// A full-width cancel button at the bottom of the modal. Dismisses the sheet
    /// without saving any changes to the note. The draft is simply discarded.
    /// Styled as a subtle dark button (#2a2a2a background, #bcbcbc text).
    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(labelColor)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(rowBgColor)
                .cornerRadius(5)
        }
    }

    // MARK: - Actions

    /// Initializes the local draft note from the parent's note binding.
    /// Called on `.onAppear` so the user sees their existing note text
    /// pre-populated in the editor, ready for editing.
    private func initializeDraft() {
        draftNote = note
    }

    /// Writes the draft note text back to the parent's note binding and dismisses.
    /// This is the only path that persists changes made in the editor.
    private func saveNote() {
        note = draftNote
        dismiss()
    }

    /// Clears the note by setting the parent's binding to an empty string
    /// and dismisses the modal. Used when the user wants to remove an
    /// existing note entirely.
    private func clearNote() {
        note = ""
        dismiss()
    }
}

#Preview {
    NoteEditorView(note: .constant("Sample note text for preview"))
}
