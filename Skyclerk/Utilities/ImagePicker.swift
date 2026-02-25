//
// ImagePicker.swift
//
// Created on 2026-02-25.
// Copyright © 2026 Cloudmanic Labs, LLC. All rights reserved.
//

import SwiftUI
import UIKit
import PhotosUI

/// UIKit wrapper for camera and photo library access.
/// This UIViewControllerRepresentable bridges UIImagePickerController into SwiftUI,
/// allowing the app to present the camera or photo library and capture a selected image.
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    var sourceType: UIImagePickerController.SourceType = .camera

    /// Create and configure a UIImagePickerController with the specified source type.
    /// Sets up the picker's delegate through the coordinator to handle image selection
    /// and cancellation callbacks.
    ///
    /// - Parameter context: The representable context provided by SwiftUI.
    /// - Returns: A configured UIImagePickerController instance.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    /// Required by UIViewControllerRepresentable but not needed for this implementation
    /// since the picker configuration does not change after creation.
    ///
    /// - Parameters:
    ///   - uiViewController: The existing UIImagePickerController instance.
    ///   - context: The representable context provided by SwiftUI.
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    /// Create the coordinator that acts as the delegate for UIImagePickerController.
    /// The coordinator handles image selection and cancellation events.
    ///
    /// - Returns: A new Coordinator instance linked to this ImagePicker.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Coordinator class that serves as the delegate for UIImagePickerController.
    /// Handles the image selection and cancellation callbacks, updating the
    /// parent ImagePicker's bound image and dismissing the picker.
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        /// Initialize the coordinator with a reference to the parent ImagePicker.
        ///
        /// - Parameter parent: The ImagePicker instance that owns this coordinator.
        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        /// Called when the user selects an image from the picker.
        /// Extracts the original image from the info dictionary, assigns it to the
        /// parent's bound image property, and dismisses the picker.
        ///
        /// - Parameters:
        ///   - picker: The UIImagePickerController that captured the image.
        ///   - info: A dictionary containing the selected image and metadata.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        /// Called when the user cancels the image picker without selecting an image.
        /// Dismisses the picker without modifying the bound image property.
        ///
        /// - Parameter picker: The UIImagePickerController that was cancelled.
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
