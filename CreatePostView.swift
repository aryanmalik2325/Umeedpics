// CreatePostView.swift
// Create a new help request post

import SwiftUI
import PhotosUI
import CoreLocation
import FirebaseFirestore

struct CreatePostView: View {
    @EnvironmentObject var authManager: FirebaseManager
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.tabSelection) var tabSelection
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedTags: Set<NeedTag> = []
    @State private var selectedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var isPosting = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var useCurrentLocation = true
    @State private var customLocationName = ""
    
    var isFormValid: Bool {
        !title.isEmpty && !selectedTags.isEmpty && selectedImage != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Photo Section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Photo", subtitle: "Add a clear photo of the person who needs help")
                        
                        if let image = selectedImage {
                            // Show selected image
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .cornerRadius(14)
                                    .clipped()
                                
                                Button {
                                    withAnimation { selectedImage = nil }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .shadow(radius: 4)
                                }
                                .padding(10)
                            }
                        } else {
                            // Photo picker
                            HStack(spacing: 12) {
                                PhotoPickerButton(
                                    icon: "camera.fill",
                                    label: "Camera"
                                ) {
                                    showCamera = true
                                }
                                
                                PhotosPickerView(
                                    selectedItem: $photosPickerItem,
                                    selectedImage: $selectedImage
                                )
                            }
                        }
                    }
                    
                    // MARK: - Title & Description
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Details", subtitle: "Describe what help is needed")
                        
                        TextField("Brief title (e.g. 'Child needs food near bus stand')", text: $title)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $description)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            if description.isEmpty {
                                Text("Add more details about the person and what they need...")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                    // MARK: - Need Tags
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            title: "What do they need?",
                            subtitle: "Select all that apply"
                        )
                        
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 10) {
                            ForEach(NeedTag.allCases) { tag in
                                NeedTagButton(
                                    tag: tag,
                                    isSelected: selectedTags.contains(tag)
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if selectedTags.isEmpty {
                            Text("⚠️ Please select at least one need")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // MARK: - Location
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Location", subtitle: "Where are they located?")
                        
                        Toggle(isOn: $useCurrentLocation) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(Color(hex: "#FF4757"))
                                Text("Use my current location")
                                    .font(.subheadline)
                            }
                        }
                        .tint(Color(hex: "#FF4757"))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        if useCurrentLocation {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(Color(hex: "#FF4757"))
                                Text(locationManager.locationName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#FF4757").opacity(0.07))
                            .cornerRadius(12)
                        } else {
                            TextField("Enter location manually (e.g. Sonipat Bus Stand)", text: $customLocationName)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // MARK: - Error
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .background(.red.opacity(0.08))
                            .cornerRadius(10)
                    }
                    
                    // MARK: - Post Button
                    Button {
                        Task { await submitPost() }
                    } label: {
                        HStack {
                            if isPosting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "heart.fill")
                                Text("Post Help Request")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid
                                    ? Color(hex: "#FF4757")
                                    : Color(.systemGray3))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(!isFormValid || isPosting)
                    
                    // Help note
                    Text("By posting, you confirm this person has consented or is in urgent need.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .navigationTitle("Post Help Request")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
        }
        .alert("Posted Successfully! 🎉", isPresented: $showSuccess) {
            Button("OK") { resetForm() }
        } message: {
            Text("Your help request has been posted. People nearby will be notified.")
        }
    }
    
    // MARK: - Submit
    private func submitPost() async {
        guard let user = authManager.currentUser else {
            errorMessage = "Please login first."
            return
        }
        
        guard let location = locationManager.currentLocation else {
            errorMessage = "Could not get location. Please enable location access in Settings."
            return
        }
        
        isPosting = true
        errorMessage = ""
        
        let locationName = useCurrentLocation ? locationManager.locationName : customLocationName
        
        let post = NeedPost(
            authorId: user.id ?? "",
            authorName: user.name,
            title: title,
            description: description,
            tags: Array(selectedTags),
            location: GeoPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            locationName: locationName,
            status: .open,
            createdAt: Date(),
            updatedAt: Date(),
            viewCount: 0,
            helpOfferCount: 0
        )
        
        do {
            try await authManager.createPost(post, image: selectedImage)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isPosting = false
    }
    
    private func resetForm() {
        title = ""
        description = ""
        selectedTags = []
        selectedImage = nil
        errorMessage = ""
    }
}

// MARK: - Need Tag Button
struct NeedTagButton: View {
    let tag: NeedTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Emoji
                Text(String(tag.rawValue.prefix(2)))
                    .font(.title2)
                
                // Label (remove emoji)
                Text(tag.rawValue.dropFirst(2).trimmingCharacters(in: .whitespaces))
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected
                ? Color(hex: tag.color)
                : Color(hex: tag.color).opacity(0.1)
            )
            .foregroundColor(isSelected ? .white : Color(hex: tag.color))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : Color(hex: tag.color).opacity(0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
    }
}

// MARK: - Photos Picker Wrapper
struct PhotosPickerView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            PhotoPickerButton(icon: "photo.fill", label: "Gallery") {}
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }
}

// MARK: - Photo Picker Button
struct PhotoPickerButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color(hex: "#FF4757").opacity(0.08))
            .foregroundColor(Color(hex: "#FF4757"))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#FF4757").opacity(0.3), lineWidth: 1.5)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Camera View (UIKit wrapper)
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Tab Selection Environment Key (for tab switching)
private struct TabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var tabSelection: Binding<Int> {
        get { self[TabSelectionKey.self] }
        set { self[TabSelectionKey.self] = newValue }
    }
}
