import SwiftUI

struct ProfileView: View {
    @State private var selectedTab: ProfileTab = .videos
    @State private var showMenu = false
    @Namespace private var underlineAnimation
    
    // Example user properties
    let displayName: String = "Jane Doe"
    let userName: String = "@janedoe"
    let profileImage: Image = Image(systemName: "person.crop.circle.fill")
    let followingCount = 123
    let followersCount = 9876
    let likesCount = 45678
    let bio: String = "Adventurer & creator 🌎 | Check out my blog:"
    let website: String? = "https://example.com"
    let isOwner = true  // Set to false if viewing someone else's profile

    // Mocked example for grid thumbnails
    let videos = (1...18).map { "video_\($0)" }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // MARK: Profile Header
                    VStack(spacing: 8) {
                        profileImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        
                        Text(displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(userName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // MARK: Stats
                    HStack(spacing: 32) {
                        statView(count: followingCount, label: "Following")
                        statView(count: followersCount, label: "Followers")
                        statView(count: likesCount, label: "Likes")
                    }
                    
                    // MARK: Bio
                    VStack(spacing: 4) {
                        Text(bio)
                            .font(.body)
                            .multilineTextAlignment(.center)
                        
                        if let link = website, let url = URL(string: link) {
                            Link(link, destination: url)
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // MARK: Profile Actions
                    HStack(spacing: 16) {
                        Button("Edit Profile") {
                            // handle edit profile
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button(action: {
                            // handle share profile
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .padding()
                        }
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    
                    // MARK: Tabs with Pinned Header
                    LazyVStack(pinnedViews: .sectionHeaders) {
                        Section(header: tabBar) {
                            // Content area (grid) for each tab
                            let gridColumns = Array(repeating: GridItem(.flexible()), count: 3)
                            LazyVGrid(columns: gridColumns, spacing: 2) {
                                ForEach(filteredVideos, id: \.self) { vid in
                                    VideoThumbnailView(videoID: vid)
                                }
                            }
                            .padding(.horizontal, 2)
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: hamburgerMenu)
            // Default to dark, but can be toggled
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: Computed property to hide 'Private' tab if not owner
    private var availableTabs: [ProfileTab] {
        isOwner ? ProfileTab.allCases : ProfileTab.allCases.filter { $0 != .privateTab }
    }
    
    // MARK: Filter content based on tab selection
    private var filteredVideos: [String] {
        switch selectedTab {
        case .videos:      return videos
        case .liked:       return videos.shuffled()
        case .bookmarks:   return videos.shuffled()
        case .privateTab:  return videos.shuffled()
        }
    }
    
    // MARK: Tab Bar
    private var tabBar: some View {
        HStack(spacing: 20) {
            ForEach(availableTabs, id: \.self) { tab in
                VStack {
                    Text(tab.title)
                        .font(.subheadline)
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                    
                    if selectedTab == tab {
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "underline", in: underlineAnimation)
                    } else {
                        Color.clear.frame(height: 2)
                    }
                }
                .onTapGesture { withAnimation { selectedTab = tab } }
            }
        }
        .padding(.top, 8)
        .padding(.vertical, 5)
        .background(Color.black) // pinned tab background
    }
    
    // MARK: Hamburger Menu
    private var hamburgerMenu: some View {
        Menu {
            Button("Settings", action: { /* handle settings */ })
            Button("Log Out", action: { /* handle log out */ })
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title2)
        }
    }
    
    // MARK: Stat View
    private func statView(count: Int, label: String) -> some View {
        VStack {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: Tabs
enum ProfileTab: CaseIterable {
    case videos, liked, bookmarks, privateTab
    
    var title: String {
        switch self {
        case .videos:      return "Videos"
        case .liked:       return "Liked"
        case .bookmarks:   return "Bookmarks"
        case .privateTab:  return "Private"
        }
    }
}

// MARK: VideoThumbnailView (example placeholder)
struct VideoThumbnailView: View {
    let videoID: String
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(Color.gray)
                .aspectRatio(9/16, contentMode: .fit)
                .overlay(
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                )
            
            HStack(spacing: 4) {
                Image(systemName: "eye.fill")
                    .font(.footnote)
                Text("\(Int.random(in: 1_000...100_000))")
                    .font(.footnote)
            }
            .padding(4)
            .background(Color.black.opacity(0.5))
            .foregroundColor(.white)
        }
    }
}
