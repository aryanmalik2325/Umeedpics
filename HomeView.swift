// HomeView.swift
// Main feed showing nearby needy people

import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var authManager: FirebaseManager
    @StateObject private var locationManager = LocationManager.shared
    
    @State private var posts: [NeedPost] = []
    @State private var isLoading = false
    @State private var selectedFilter: NeedTag? = nil
    @State private var searchText = ""
    @State private var radiusKm: Double = 10
    @State private var showFilters = false
    @State private var selectedPost: NeedPost?
    
    var filteredPosts: [NeedPost] {
        var result = posts
        if let filter = selectedFilter {
            result = result.filter { $0.tags.contains(filter) }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.locationName.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search by name, location, or need...", text: $searchText)
                            .autocapitalization(.none)
                        
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Filter Tags horizontal scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // All filter
                            FilterChip(
                                label: "All",
                                isSelected: selectedFilter == nil,
                                color: "#636E72"
                            ) {
                                withAnimation { selectedFilter = nil }
                            }
                            
                            ForEach(NeedTag.allCases) { tag in
                                FilterChip(
                                    label: tag.rawValue,
                                    isSelected: selectedFilter == tag,
                                    color: tag.color
                                ) {
                                    withAnimation {
                                        selectedFilter = selectedFilter == tag ? nil : tag
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    
                    // Radius / location info bar
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#FF4757"))
                        
                        Text(locationManager.currentLocation != nil
                             ? "Within \(Int(radiusKm))km of you"
                             : "Showing all posts (enable location for nearby)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(filteredPosts.count) posts")
                            .font(.caption.bold())
                            .foregroundColor(Color(hex: "#FF4757"))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    
                    // Posts List
                    if isLoading {
                        Spacer()
                        ProgressView("Looking for nearby help requests...")
                            .tint(Color(hex: "#FF4757"))
                        Spacer()
                    } else if filteredPosts.isEmpty {
                        EmptyFeedView(hasFilter: selectedFilter != nil)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredPosts) { post in
                                    PostCardView(post: post)
                                        .onTapGesture {
                                            selectedPost = post
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        .refreshable {
                            await loadPosts()
                        }
                    }
                }
            }
            .navigationTitle("Help Nearby")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Search Radius") {
                            ForEach([5.0, 10.0, 20.0, 50.0], id: \.self) { km in
                                Button("\(Int(km))km") {
                                    radiusKm = km
                                    Task { await loadPosts() }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .task {
                await loadPosts()
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
        }
    }
    
    private func loadPosts() async {
        isLoading = true
        do {
            if let location = locationManager.currentLocation {
                posts = try await authManager.fetchNearbyPosts(near: location, radiusKm: radiusKm)
            } else {
                posts = try await authManager.fetchAllPosts()
            }
        } catch {
            print("Error loading posts: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Post Card View
struct PostCardView: View {
    let post: NeedPost
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Section
            ZStack(alignment: .topTrailing) {
                if let imageURL = post.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure(_):
                            PostPlaceholderImage()
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray5))
                        @unknown default:
                            PostPlaceholderImage()
                        }
                    }
                } else {
                    PostPlaceholderImage()
                }
                
                // Status Badge
                Text(post.status.displayText)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: post.status.color))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(10)
            }
            
            // Content Section
            VStack(alignment: .leading, spacing: 10) {
                Text(post.title)
                    .font(.headline)
                    .lineLimit(2)
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(post.tags) { tag in
                            Text(tag.rawValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: tag.color).opacity(0.15))
                                .foregroundColor(Color(hex: tag.color))
                                .cornerRadius(6)
                        }
                    }
                }
                
                // Location & Time
                HStack {
                    Label(post.locationName, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(post.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Stats Row
                HStack(spacing: 16) {
                    Label("\(post.helpOfferCount) helpers", systemImage: "hands.sparkles")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#FF4757"))
                    
                    Label("\(post.viewCount) views", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Distance
                    if let location = locationManager.currentLocation {
                        let postLocation = CLLocation(
                            latitude: post.location.latitude,
                            longitude: post.location.longitude
                        )
                        Text(locationManager.distance(from: postLocation))
                            .font(.caption.bold())
                            .foregroundColor(Color(hex: "#FF6B35"))
                    }
                }
            }
            .padding(14)
        }
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let color: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color(hex: color) : Color(hex: color).opacity(0.1))
                .foregroundColor(isSelected ? .white : Color(hex: color))
                .cornerRadius(20)
        }
    }
}

// MARK: - Empty Feed View
struct EmptyFeedView: View {
    let hasFilter: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: hasFilter ? "line.3.horizontal.decrease.circle" : "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(hasFilter ? .secondary : Color(hex: "#2ED573"))
            
            Text(hasFilter ? "No posts match this filter" : "No help requests nearby 🎉")
                .font(.headline)
            
            Text(hasFilter
                 ? "Try removing filters or increasing your search radius."
                 : "Your community is doing well! Check back later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Placeholder Image
struct PostPlaceholderImage: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#FF6B35").opacity(0.2), Color(hex: "#FF4757").opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 200)
            .overlay(
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "#FF4757").opacity(0.5))
            )
    }
}

import CoreLocation
