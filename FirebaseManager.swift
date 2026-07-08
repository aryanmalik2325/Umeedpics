// FirebaseManager.swift
// All Firebase operations: Auth, Firestore, Storage

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine
import CoreLocation

@MainActor
class FirebaseManager: NSObject, ObservableObject {
    
    static let shared = FirebaseManager()
    
    // MARK: - Published State
    @Published var currentUser: HelpUser?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Firebase refs
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    // Phone auth verification ID
    var phoneVerificationID: String?
    
    override init() {
        super.init()
        listenToAuthState()
    }
    
    // MARK: - Auth State Listener
    private func listenToAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.isLoggedIn = true
                    await self?.fetchCurrentUser(uid: user.uid)
                } else {
                    self?.isLoggedIn = false
                    self?.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - EMAIL AUTH
    
    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = HelpUser(
            id: result.user.uid,
            name: name,
            email: email,
            joinedAt: Date(),
            helpCount: 0,
            postCount: 0
        )
        try await saveUser(user)
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    // MARK: - PHONE AUTH
    
    func sendOTP(phoneNumber: String) async throws {
        // Format: +91XXXXXXXXXX for India
        let formatted = phoneNumber.hasPrefix("+") ? phoneNumber : "+91\(phoneNumber)"
        isLoading = true
        defer { isLoading = false }
        
        let verificationID = try await PhoneAuthProvider.provider()
            .verifyPhoneNumber(formatted, uiDelegate: nil)
        self.phoneVerificationID = verificationID
    }
    
    func verifyOTP(otp: String, name: String) async throws {
        guard let verificationID = phoneVerificationID else {
            throw AppError.missingVerificationID
        }
        isLoading = true
        defer { isLoading = false }
        
        let credential = PhoneAuthProvider.provider()
            .credential(withVerificationID: verificationID, verificationCode: otp)
        
        let result = try await Auth.auth().signIn(with: credential)
        
        // Check if user exists, if not create profile
        let docSnapshot = try await db.collection("users").document(result.user.uid).getDocument()
        if !docSnapshot.exists {
            let user = HelpUser(
                id: result.user.uid,
                name: name,
                phoneNumber: result.user.phoneNumber,
                joinedAt: Date(),
                helpCount: 0,
                postCount: 0
            )
            try await saveUser(user)
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
    }
    
    // MARK: - USER OPERATIONS
    
    func saveUser(_ user: HelpUser) async throws {
        guard let uid = user.id ?? Auth.auth().currentUser?.uid else { return }
        try db.collection("users").document(uid).setData(from: user)
    }
    
    func fetchCurrentUser(uid: String) async {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            self.currentUser = try doc.data(as: HelpUser.self)
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    func updateUserLocation(_ location: CLLocation) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let geoPoint = GeoPoint(latitude: location.coordinate.latitude,
                                 longitude: location.coordinate.longitude)
        try await db.collection("users").document(uid).updateData(["location": geoPoint])
    }
    
    // MARK: - POST OPERATIONS
    
    func createPost(_ post: NeedPost, image: UIImage?) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw AppError.notAuthenticated }
        isLoading = true
        defer { isLoading = false }
        
        var newPost = post
        newPost.authorId = uid
        
        // Upload image if provided
        if let image = image {
            let imageURL = try await uploadImage(image, path: "posts/\(UUID().uuidString).jpg")
            newPost = NeedPost(
                authorId: newPost.authorId,
                authorName: newPost.authorName,
                title: newPost.title,
                description: newPost.description,
                imageURL: imageURL,
                tags: newPost.tags,
                location: newPost.location,
                locationName: newPost.locationName,
                status: newPost.status,
                createdAt: newPost.createdAt,
                updatedAt: newPost.updatedAt,
                viewCount: newPost.viewCount,
                helpOfferCount: newPost.helpOfferCount
            )
        }
        
        // Save to Firestore
        let _ = try db.collection("posts").addDocument(from: newPost)
        
        // Increment user's post count
        try await db.collection("users").document(uid).updateData([
            "postCount": FieldValue.increment(Int64(1))
        ])
    }
    
    /// Fetch posts near a given location within `radiusKm` kilometers
    func fetchNearbyPosts(
        near location: CLLocation,
        radiusKm: Double = 10.0
    ) async throws -> [NeedPost] {
        // Firestore doesn't support native geo queries; we use a bounding box approach
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        let latDelta = radiusKm / 111.0
        let lngDelta = radiusKm / (111.0 * cos(lat * .pi / 180))
        
        let snapshot = try await db.collection("posts")
            .whereField("location", isGreaterThanOrEqualTo:
                GeoPoint(latitude: lat - latDelta, longitude: lng - lngDelta))
            .whereField("location", isLessThanOrEqualTo:
                GeoPoint(latitude: lat + latDelta, longitude: lng + lngDelta))
            .whereField("status", isEqualTo: PostStatus.open.rawValue)
            .order(by: "location")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: NeedPost.self) }
    }
    
    /// Fetch all open posts (fallback if location unavailable)
    func fetchAllPosts() async throws -> [NeedPost] {
        let snapshot = try await db.collection("posts")
            .whereField("status", isEqualTo: PostStatus.open.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: 30)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: NeedPost.self) }
    }
    
    func fetchMyPosts() async throws -> [NeedPost] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        let snapshot = try await db.collection("posts")
            .whereField("authorId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: NeedPost.self) }
    }
    
    func updatePostStatus(_ postId: String, status: PostStatus) async throws {
        try await db.collection("posts").document(postId).updateData([
            "status": status.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    func incrementViewCount(_ postId: String) {
        db.collection("posts").document(postId).updateData([
            "viewCount": FieldValue.increment(Int64(1))
        ])
    }
    
    // MARK: - HELP OFFER OPERATIONS
    
    func offerHelp(_ offer: HelpOffer) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw AppError.notAuthenticated }
        var newOffer = offer
        // set helperId
        _ = uid
        let _ = try db.collection("helpOffers").addDocument(from: newOffer)
        
        // Increment offer count on post
        try await db.collection("posts").document(offer.postId).updateData([
            "helpOfferCount": FieldValue.increment(Int64(1)),
            "status": PostStatus.inProgress.rawValue
        ])
        
        // Increment helper's count
        try await db.collection("users").document(uid).updateData([
            "helpCount": FieldValue.increment(Int64(1))
        ])
        
        // Notify post author
        await sendNotificationToPostAuthor(postId: offer.postId, helperName: offer.helperName)
    }
    
    func fetchHelpOffers(for postId: String) async throws -> [HelpOffer] {
        let snapshot = try await db.collection("helpOffers")
            .whereField("postId", isEqualTo: postId)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: HelpOffer.self) }
    }
    
    // MARK: - IMAGE UPLOAD
    
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw AppError.imageConversionFailed
        }
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
    
    // MARK: - NOTIFICATIONS (In-app)
    
    private func sendNotificationToPostAuthor(postId: String, helperName: String) async {
        do {
            // Get the post to find author
            let postDoc = try await db.collection("posts").document(postId).getDocument()
            guard let post = try? postDoc.data(as: NeedPost.self) else { return }
            
            let notification = HelpNotification(
                userId: post.authorId,
                type: .helpOffered,
                title: "Someone wants to help!",
                body: "\(helperName) has offered to help with your post.",
                postId: postId,
                isRead: false,
                createdAt: Date()
            )
            try db.collection("notifications").addDocument(from: notification)
        } catch {
            print("Notification error: \(error)")
        }
    }
}

// MARK: - App Errors
enum AppError: LocalizedError {
    case notAuthenticated
    case missingVerificationID
    case imageConversionFailed
    case postNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:      return "Please login to continue."
        case .missingVerificationID: return "OTP session expired. Please try again."
        case .imageConversionFailed: return "Could not process image. Please try another."
        case .postNotFound:          return "This post no longer exists."
        }
    }
}
