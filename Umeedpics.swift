// Umeedpics.swift
// Main entry point for HelpConnect

import SwiftUI
import Firebase

@main
struct HelpConnectApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = FirebaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// MARK: - Root View (Auth Gate)
struct RootView: View {
    @EnvironmentObject var authManager: FirebaseManager
    
    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authManager.isLoggedIn)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            MapPostsView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            
            CreatePostView()
                .tabItem {
                    Label("Post Help", systemImage: "plus.circle.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(.orange)
        .onAppear {
            locationManager.requestPermission()
        }
    }
}
