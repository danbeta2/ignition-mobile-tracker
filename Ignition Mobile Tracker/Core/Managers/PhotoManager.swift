//
//  PhotoManager.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI
import PhotosUI
import UIKit
import Combine

@MainActor
class PhotoManager: ObservableObject {
    static let shared = PhotoManager()
    
    @Published var selectedImages: [UIImage] = []
    @Published var isShowingPhotoPicker = false
    @Published var isShowingCamera = false
    @Published var isProcessing = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Photo Selection
    
    func selectPhotos() {
        isShowingPhotoPicker = true
    }
    
    func takePhoto() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            error = "Camera not available"
            return
        }
        isShowingCamera = true
    }
    
    // MARK: - Image Processing
    
    func processSelectedPhotos(_ items: [PhotosPickerItem]) async {
        isProcessing = true
        error = nil
        
        var newImages: [UIImage] = []
        
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    let processedImage = await processImage(image)
                    newImages.append(processedImage)
                }
            } catch {
                self.error = "Failed to load image: \(error.localizedDescription)"
            }
        }
        
        selectedImages.append(contentsOf: newImages)
        isProcessing = false
    }
    
    func processCameraPhoto(_ image: UIImage) async {
        isProcessing = true
        let processedImage = await processImage(image)
        selectedImages.append(processedImage)
        isProcessing = false
    }
    
    // MARK: - Image Processing
    
    private func processImage(_ image: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Resize image to max 1024x1024 while maintaining aspect ratio
                let maxSize: CGFloat = 1024
                let size = image.size
                
                var newSize: CGSize
                if size.width > size.height {
                    newSize = CGSize(width: maxSize, height: size.height * maxSize / size.width)
                } else {
                    newSize = CGSize(width: size.width * maxSize / size.height, height: maxSize)
                }
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
                
                continuation.resume(returning: resizedImage)
            }
        }
    }
    
    // MARK: - Data Conversion
    
    func imageToData(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: compressionQuality)
    }
    
    func dataToImage(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    // MARK: - Cleanup
    
    func clearSelectedImages() {
        selectedImages = []
        error = nil
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
}

// MARK: - UIImagePickerController Coordinator
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}
