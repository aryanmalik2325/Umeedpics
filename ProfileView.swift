// ProfileView.swift
// User profile with stats, my posts, and settings

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: FirebaseManager
    @State private var myPosts: [NeedPost] = []
    @State private var isLoading = false
    @State private var showLogoutAlert = false
    
    var user: HelpUser? { authManager.currentUser }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    
                    // MARK: - Profile Header
                    ZStack(alignment: .bottom) {
                        LinearGradient(
                            colors: [Color(hex: "#FF6B35"), Color(hex: "#FF4757")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 160)
                        
                        VStack(spacing: 10) {
                            // Avatar
                            Circle()
                                .fill(.white)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(String(user?.name.prefix(1) ?? "?").uppercased())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color(hex: "#FF4757"))
                                )
                                .shadow(radius: 6)
                                .offset(y: 40)
                        }
                    }
                    
                    VStack(spacing: 6) {
                        Text(user?.name ?? "User")
                            .font(.title2.bold())
                        
                        if let email = user?.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if let phone = user?.phoneNumber {
                            Text(phone)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 16)
                    
                    // MARK: - Stats
                    HStack(spacing: 0) {
                        ProfileStat(
                            value: "\(user?.postCount ?? 0)",
                            label: "Requests\nPosted",
                            icon: "megaphone.fill",
                            color: "#FF4757"
                        )
                        Divider().frame(height: 50)
                        ProfileStat(
                            value: "\(user?.helpCount ?? 0)",
                            label: "People\nHelped",
                            icon: "hands.sparkles.fill",
                            color: "#2ED573"
                        )
                        Divider().frame(height: 50)
                        ProfileStat(
                            value: myPosts.filter { $0.status == .fulfilled }.count.description,
                            label: "Posts\nFulfilled",
                            icon: "checkmark.circle.fill",
                            color: "#FFA502"
                        )
                    }
                    .padding(.vertical, 16)
                    .background(.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 6)
                    .padding(.horizontal, 20)
                    
                    // MARK: - My Posts
                    VStack(alignment: .leading, spacing: 14) {
                        Text("My Help Requests")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        if isLoading {
                            ProgressView().padding()
                        } else if myPosts.isEmpty {
                            Text("You haven't posted any help requests yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        } else {
                            ForEach(myPosts) { post in
                                MyPostRow(post: post)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 24)
                    
                    // MARK: - Settings
                    VStack(spacing: 0) {
                        Text("Settings")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        
                        VStack(spacing: 0) {
                            SettingsRow(icon: "bell.fill", label: "Notifications", color: "#FF6B35") {}
                            Divider().padding(.leading, 52)
                            SettingsRow(icon: "location.fill", label: "Location Settings", color: "#1E90FF") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            Divider().padding(.leading, 52)
                            SettingsRow(icon: "shield.fill", label: "Privacy Policy", color: "#6C5CE7") {}
                            Divider().padding(.leading, 52)
                            SettingsRow(icon: "questionmark.circle.fill", label: "Help & Support", color: "#00B894") {}
                        }
                        .background(.white)
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Sign Out
                        Button {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.08))
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            isLoading = true
            myPosts = (try? await authManager.fetchMyPosts()) ?? []
            isLoading = false
        }
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Sign Out", role: .destructive) { authManager.signOut() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct ProfileStat: View {
    let value: String
    let label: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: color))
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MyPostRow: View {
    let post: NeedPost
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: post.status.color).opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: post.status == .fulfilled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(Color(hex: post.status.color))
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(post.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(post.locationName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text(post.status.displayText)
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: post.status.color))
                Text("\(post.helpOfferCount) offers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

struct SettingsRow: View {
    let icon: String
    let label: String
    let color: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color(hex: color))
                    .cornerRadius(6)
                
                Text(label)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
