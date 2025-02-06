import SwiftUI

struct BottomNavBarView: View {
    var body: some View {
        HStack {
            navButton(icon: "house", title: "Home")
            Spacer()
            navButton(icon: "person.2", title: "Friends")
            Spacer()
            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            Spacer()
            navButton(icon: "tray", title: "Inbox")
            Spacer()
            navButton(icon: "person.crop.circle", title: "Profile")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black)
    }
    
    private func navButton(icon: String, title: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}

struct BottomNavBarView_Previews: PreviewProvider {
    static var previews: some View {
        BottomNavBarView()
            .previewLayout(.sizeThatFits)
    }
}
