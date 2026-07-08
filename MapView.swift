// MapView.swift
// Map view showing nearby needy people as pins

import SwiftUI
import MapKit

struct MapPostsView: View {
    @EnvironmentObject var authManager: FirebaseManager
    @StateObject private var locationManager = LocationManager.shared
    
    @State private var posts: [NeedPost] = []
    @State private var selectedPost: NeedPost?
    @State private var showDetail = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.9845, longitude: 77.0000), // Default: Sonipat
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Map
                Map(coordinateRegion: $mapRegion,
                    showsUserLocation: true,
                    userTrackingMode: .constant(.none),
                    annotationItems: posts) { post in
                    
                    MapAnnotation(coordinate: post.coordinate) {
                        PostMapPin(post: post, isSelected: selectedPost?.id == post.id)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedPost = post
                                }
                            }
                    }
                }
                .ignoresSafeArea()
                
                // Center on user button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            centerOnUser()
                        } label: {
                            Image(systemName: "location.fill")
                                .padding(14)
                                .background(.white)
                                .foregroundColor(Color(hex: "#FF4757"))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                    
                    // Selected post card
                    if let post = selectedPost {
                        SelectedPostCard(post: post) {
                            showDetail = true
                        } onDismiss: {
                            withAnimation { selectedPost = nil }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Nearby Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(posts.count) nearby")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#FF4757").opacity(0.15))
                        .foregroundColor(Color(hex: "#FF4757"))
                        .cornerRadius(10)
                }
            }
        }
        .task {
            await loadPosts()
            centerOnUser()
        }
        .sheet(isPresented: $showDetail) {
            if let post = selectedPost {
                PostDetailView(post: post)
            }
        }
    }
    
    private func loadPosts() async {
        if let location = locationManager.currentLocation {
            posts = (try? await authManager.fetchNearbyPosts(near: location, radiusKm: 20)) ?? []
        } else {
            posts = (try? await authManager.fetchAllPosts()) ?? []
        }
    }
    
    private func centerOnUser() {
        guard let location = locationManager.currentLocation else { return }
        withAnimation {
            mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}

// MARK: - Map Pin for a Post
struct PostMapPin: View {
    let post: NeedPost
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color(hex: post.status.color))
                    .frame(width: isSelected ? 50 : 38, height: isSelected ? 50 : 38)
                    .shadow(color: Color(hex: post.status.color).opacity(0.4),
                            radius: isSelected ? 8 : 4)
                
                // Show first tag emoji
                if let firstTag = post.tags.first {
                    Text(String(firstTag.rawValue.prefix(2)))
                        .font(isSelected ? .title3 : .body)
                }
            }
            
            // Pin tip
            Triangle()
                .fill(Color(hex: post.status.color))
                .frame(width: 12, height: 8)
            
            if isSelected {
                Text(post.title)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white)
                    .cornerRadius(6)
                    .shadow(radius: 3)
                    .lineLimit(1)
                    .frame(maxWidth: 130)
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Triangle shape for pin
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

// MARK: - Selected Post Preview Card
struct SelectedPostCard: View {
    let post: NeedPost
    let onViewDetail: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageURL = post.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                             .frame(width: 70, height: 70)
                             .cornerRadius(10)
                             .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#FF4757").opacity(0.15))
                            .frame(width: 70, height: 70)
                            .overlay(Image(systemName: "person.2.fill")
                                        .foregroundColor(Color(hex: "#FF4757").opacity(0.5)))
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#FF4757").opacity(0.15))
                    .frame(width: 70, height: 70)
                    .overlay(Image(systemName: "person.2.fill")
                                .foregroundColor(Color(hex: "#FF4757").opacity(0.5)))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(post.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                
                Text(post.locationName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    ForEach(post.tags.prefix(3)) { tag in
                        Text(String(tag.rawValue.prefix(2)))
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                
                Button(action: onViewDetail) {
                    Text("View")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#FF4757"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}
