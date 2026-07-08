// Models.swift
// All data models for HelpConnect

import Foundation
import FirebaseFirestore
import CoreLocation

// MARK: - User Model
struct HelpUser: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String?
    var phoneNumber: String?
    var profileImageURL: String?
    var location: GeoPoint?
    var joinedAt: Date
    var helpCount: Int       // times they helped others
    var postCount: Int       // times they posted a need
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phoneNumber, profileImageURL, location, joinedAt, helpCount, postCount
    }
    
    static var empty: HelpUser {
        HelpUser(name: "", joinedAt: Date(), helpCount: 0, postCount: 0)
    }
}

// MARK: - Need Tags
enum NeedTag: String, CaseIterable, Codable, Identifiable {
    case food        = "🍲 Food"
    case clothing    = "👕 Clothing"
    case medicine    = "💊 Medicine"
    case shelter     = "🏠 Shelter"
    case water       = "💧 Water"
    case stationery  = "✏️ Stationery"
    case toys        = "🧸 Toys"
    case blankets    = "🛏 Blankets"
    case shoes       = "👟 Shoes"
    case hygiene     = "🧴 Hygiene"
    case books       = "📚 Books"
    case other       = "📦 Other"
    
    var id: String { rawValue }
    
    var color: String {
        switch self {
        case .food:       return "#FF6B35"
        case .clothing:   return "#4ECDC4"
        case .medicine:   return "#FF4757"
        case .shelter:    return "#5352ED"
        case .water:      return "#1E90FF"
        case .stationery: return "#FFA502"
        case .toys:       return "#FF6B81"
        case .blankets:   return "#A29BFE"
        case .shoes:      return "#00B894"
        case .hygiene:    return "#FDCB6E"
        case .books:      return "#6C5CE7"
        case .other:      return "#636E72"
        }
    }
}

// MARK: - Post Status
enum PostStatus: String, Codable {
    case open       = "open"
    case inProgress = "in_progress"
    case fulfilled  = "fulfilled"
    
    var displayText: String {
        switch self {
        case .open:       return "Needs Help"
        case .inProgress: return "Help On The Way"
        case .fulfilled:  return "Helped ✓"
        }
    }
    
    var color: String {
        switch self {
        case .open:       return "#FF4757"
        case .inProgress: return "#FFA502"
        case .fulfilled:  return "#2ED573"
        }
    }
}

// MARK: - Need Post Model
struct NeedPost: Identifiable, Codable {
    @DocumentID var id: String?
    var authorId: String
    var authorName: String
    var title: String
    var description: String
    var imageURL: String?
    var tags: [NeedTag]
    var location: GeoPoint
    var locationName: String       // human readable address
    var status: PostStatus
    var createdAt: Date
    var updatedAt: Date
    var viewCount: Int
    var helpOfferCount: Int
    
    // Computed: not stored in Firestore
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    enum CodingKeys: String, CodingKey {
        case id, authorId, authorName, title, description, imageURL,
             tags, location, locationName, status, createdAt, updatedAt,
             viewCount, helpOfferCount
    }
    
    static var preview: NeedPost {
        NeedPost(
            authorId: "preview",
            authorName: "Rahul",
            title: "Child needs food and clothing",
            description: "Found a young child near the bus stand. Needs warm food and clothing immediately.",
            tags: [.food, .clothing],
            location: GeoPoint(latitude: 28.9845, longitude: 77.0000),
            locationName: "Sonipat Bus Stand, Haryana",
            status: .open,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date(),
            viewCount: 12,
            helpOfferCount: 3
        )
    }
}

// MARK: - Help Offer Model
struct HelpOffer: Identifiable, Codable {
    @DocumentID var id: String?
    var postId: String
    var helperId: String
    var helperName: String
    var helperPhone: String?
    var message: String
    var offeredTags: [NeedTag]     // which needs they can fulfill
    var createdAt: Date
    var isAccepted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, postId, helperId, helperName, helperPhone, message,
             offeredTags, createdAt, isAccepted
    }
}

// MARK: - Notification Model
struct HelpNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var type: NotificationType
    var title: String
    var body: String
    var postId: String?
    var isRead: Bool
    var createdAt: Date
    
    enum NotificationType: String, Codable {
        case helpOffered    = "help_offered"
        case helpAccepted   = "help_accepted"
        case postFulfilled  = "post_fulfilled"
        case nearbyPost     = "nearby_post"
    }
}
