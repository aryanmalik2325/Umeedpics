// PostDetailView.swift
// View a help request and offer help

import SwiftUI
import MapKit

struct PostDetailView: View {
    let post: NeedPost
    
    @EnvironmentObject var authManager: FirebaseManager
    @Environment(\.dismiss) var dismiss
    
    @State private var helpOffers: [HelpOffer] = []
    @State private var showOfferSheet = false
    @State private var isLoading = true
    @State private var mapRegion: MKCoordinateRegion
    @State private var showMarkFulfilled = false
    
    init(post: NeedPost) {
        self.post = post
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: post.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var isMyPost: Bool {
        post.authorId == authManager.currentUser?.id
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // MARK: - Image
                    if let imageURL = post.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 280)
                                    .clipped()
                            default:
                                PostPlaceholderImage()
                            }
                        }
                    } else {
                        PostPlaceholderImage()
                            .frame(height: 180)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Status + Title
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                StatusBadge(status: post.status)
                                Spacer()
                                Text(post.timeAgo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(post.title)
                                .font(.title2.bold())
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Tags
                            FlowLayout(spacing: 8) {
                                ForEach(post.tags) { tag in
                                    Text(tag.rawValue)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(hex: tag.color).opacity(0.15))
                                        .foregroundColor(Color(hex: tag.color))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // MARK: - Description
                        if !post.description.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("About this request")
                                    .font(.headline)
                                Text(post.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        // MARK: - Stats
                        HStack(spacing: 20) {
                            StatBadge(
                                icon: "hands.sparkles.fill",
                                value: "\(post.helpOfferCount)",
                                label: "Helpers",
                                color: "#FF4757"
                            )
                            StatBadge(
                                icon: "eye.fill",
                                value: "\(post.viewCount)",
                                label: "Views",
                                color: "#636E72"
                            )
                            Spacer()
                        }
                        
                        Divider()
                        
                        // MARK: - Location
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Location", systemImage: "mappin.circle.fill")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#FF4757"))
                            
                            Text(post.locationName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Map snippet
                            Map(coordinateRegion: $mapRegion, annotationItems: [post]) { p in
                                MapMarker(coordinate: p.coordinate, tint: .red)
                            }
                            .frame(height: 160)
                            .cornerRadius(12)
                            .disabled(true)
                            
                            // Open in Apple Maps
                            Button {
                                openInMaps()
                            } label: {
                                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                                    .font(.subheadline.bold())
                                    .foregroundColor(Color(hex: "#FF4757"))
                            }
                        }
                        
                        Divider()
                        
                        // MARK: - Posted By
                        HStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#FF6B35"), Color(hex: "#FF4757")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(post.authorName.prefix(1)).uppercased())
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Posted by")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(post.authorName)
                                    .font(.subheadline.bold())
                            }
                        }
                        
                        Divider()
                        
                        // MARK: - Help Offers Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("People offering help (\(helpOffers.count))")
                                .font(.headline)
                            
                            if isLoading {
                                ProgressView()
                            } else if helpOffers.isEmpty {
                                Text("No one has offered help yet. Be the first! 💪")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            } else {
                                ForEach(helpOffers) { offer in
                                    HelpOfferCard(offer: offer)
                                }
                            }
                        }
                        
                        // MARK: - Action Buttons
                        VStack(spacing: 12) {
                            if !isMyPost && post.status == .open {
                                Button {
                                    showOfferSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "hands.sparkles.fill")
                                        Text("Offer to Help")
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#FF4757"))
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                }
                            }
                            
                            if isMyPost && post.status != .fulfilled {
                                Button {
                                    showMarkFulfilled = true
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Mark as Helped ✓")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                }
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white, Color.black.opacity(0.3))
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(
                        item: "Someone needs help at \(post.locationName)!\n\nNeeds: \(post.tags.map(\.rawValue).joined(separator: ", "))\n\nHelp via HelpConnect app."
                    ) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .foregroundStyle(.white, Color.black.opacity(0.3))
                            .font(.title3)
                    }
                }
            }
        }
        .task {
            await loadOffers()
            authManager.incrementViewCount(post.id ?? "")
        }
        .sheet(isPresented: $showOfferSheet) {
            OfferHelpSheet(post: post) {
                Task { await loadOffers() }
            }
        }
        .confirmationDialog(
            "Mark this request as fulfilled?",
            isPresented: $showMarkFulfilled,
            titleVisibility: .visible
        ) {
            Button("Yes, they got help!") {
                Task {
                    try? await authManager.updatePostStatus(post.id ?? "", status: .fulfilled)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func loadOffers() async {
        isLoading = true
        helpOffers = (try? await authManager.fetchHelpOffers(for: post.id ?? "")) ?? []
        isLoading = false
    }
    
    private func openInMaps() {
        let coordinate = post.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = post.locationName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Offer Help Sheet
struct OfferHelpSheet: View {
    let post: NeedPost
    let onSuccess: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: FirebaseManager
    
    @State private var message = ""
    @State private var offeredTags: Set<NeedTag> = []
    @State private var sharePhone = false
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Offer Help 💛")
                            .font(.title2.bold())
                        Text("Tell them what you can provide")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // What can you provide?
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What can you provide?")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
                            ForEach(post.tags) { tag in
                                Button {
                                    withAnimation {
                                        if offeredTags.contains(tag) {
                                            offeredTags.remove(tag)
                                        } else {
                                            offeredTags.insert(tag)
                                        }
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(String(tag.rawValue.prefix(2)))
                                            .font(.title3)
                                        Text(tag.rawValue.dropFirst(2).trimmingCharacters(in: .whitespaces))
                                            .font(.caption.bold())
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(offeredTags.contains(tag)
                                                ? Color(hex: tag.color)
                                                : Color(hex: tag.color).opacity(0.1))
                                    .foregroundColor(offeredTags.contains(tag) ? .white : Color(hex: tag.color))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message (optional)")
                            .font(.headline)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $message)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            if message.isEmpty {
                                Text("E.g. I have extra food I can bring within 30 minutes...")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(16)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    
                    // Share phone toggle
                    Toggle(isOn: $sharePhone) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share my phone number")
                                .font(.subheadline.bold())
                            Text("Allows the poster to contact you directly")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(Color(hex: "#FF4757"))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Submit
                    Button {
                        Task { await submitOffer() }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Send Help Offer")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(offeredTags.isEmpty ? Color(.systemGray3) : Color(hex: "#FF4757"))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(offeredTags.isEmpty || isSubmitting)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func submitOffer() async {
        guard let user = authManager.currentUser else { return }
        isSubmitting = true
        
        let offer = HelpOffer(
            postId: post.id ?? "",
            helperId: user.id ?? "",
            helperName: user.name,
            helperPhone: sharePhone ? user.phoneNumber : nil,
            message: message,
            offeredTags: Array(offeredTags),
            createdAt: Date(),
            isAccepted: false
        )
        
        do {
            try await authManager.offerHelp(offer)
            dismiss()
            onSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - Help Offer Card
struct HelpOfferCard: View {
    let offer: HelpOffer
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hex: "#FF6B35"), Color(hex: "#FF4757")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(offer.helperName.prefix(1)).uppercased())
                        .font(.caption.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(offer.helperName)
                        .font(.subheadline.bold())
                    
                    if offer.isAccepted {
                        Text("Accepted ✓")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    Text(offer.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Offered items
                HStack(spacing: 4) {
                    ForEach(offer.offeredTags) { tag in
                        Text(String(tag.rawValue.prefix(2)))
                            .font(.caption)
                    }
                }
                
                if !offer.message.isEmpty {
                    Text(offer.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let phone = offer.helperPhone {
                    Link(destination: URL(string: "tel:\(phone)")!) {
                        Label(phone, systemImage: "phone.fill")
                            .font(.caption.bold())
                            .foregroundColor(Color(hex: "#FF4757"))
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: PostStatus
    
    var body: some View {
        Text(status.displayText)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(hex: status.color).opacity(0.15))
            .foregroundColor(Color(hex: status.color))
            .cornerRadius(20)
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: color))
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.headline.bold())
                Text(label).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Flow Layout (for tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? 0,
            height: rows.last.map { $0.maxY } ?? 0
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        for row in rows {
            for item in row.items {
                item.view.place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + item.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }
    
    private struct RowItem {
        let view: LayoutSubview
        let x: CGFloat
        let y: CGFloat
        let size: CGSize
    }
    
    private struct Row {
        var items: [RowItem] = []
        var maxY: CGFloat = 0
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = [Row()]
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
                rows.append(Row())
            }
            rows[rows.count - 1].items.append(RowItem(view: view, x: x, y: y, size: size))
            rows[rows.count - 1].maxY = y + size.height
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return rows
    }
}
