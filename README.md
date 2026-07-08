# Umeedpics – Community Help App
UmeedPics is a community-driven social welfare platform designed to connect people who need assistance with individuals who are willing to help. The platform enables users to share real-time information about people in need by posting images, videos, descriptions,and location details, making it easier for nearby community members to provide support

## 🚀 Setup Instructions

### 1. Create Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project called **Umeedpics**
3. Add an **iOS app** with your bundle ID (e.g. `com.yourname.Umeedpics`)
4. Download `GoogleService-Info.plist` and drag it into your Xcode project root

### 2. Enable Firebase Services
In Firebase Console:
- **Authentication** → Sign-in methods → Enable **Email/Password** and **Phone**
- **Firestore Database** → Create database (start in test mode)
- **Storage** → Get started (start in test mode)

### 3. Add Firebase via Swift Package Manager
In Xcode: File → Add Package Dependencies  
URL: `https://github.com/firebase/firebase-ios-sdk`  
Add these packages:
- `FirebaseAuth`
- `FirebaseFirestore`
- `FirebaseStorage`
- `FirebaseMessaging` (optional, for notifications)

### 4. Info.plist Permissions
Add these keys to your `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby help requests.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to notify you of nearby help requests.</string>
<key>NSCameraUsageDescription</key>
<string>Take photos of people who need help.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Select photos from your library to post.</string>
```

### 5. Firestore Security Rules
In Firebase Console → Firestore → Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.authorId;
    }
    match /helpOffers/{offerId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

### 6. File Structure
```
HelpConnect/
├── App/
│   └── Umeedpics.swift
├── Models/
│   └── Models.swift
├── Services/
│   ├── FirebaseManager.swift
│   └── LocationManager.swift
├── Views/
│   ├── Auth/
│   │   ├── AuthView.swift
│   │   ├── EmailAuthView.swift
│   │   └── PhoneAuthView.swift
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── PostCardView.swift
│   ├── Post/
│   │   ├── CreatePostView.swift
│   │   └── PostDetailView.swift
│   └── Map/
│       └── MapView.swift
└── GoogleService-Info.plist
```

👨‍💻 Author
Aryan Malik

⭐ If you like this project, consider giving it a star!
