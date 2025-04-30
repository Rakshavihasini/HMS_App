import SwiftUI

struct UserSelectionView: View {
    @State private var selectedUserType: String? = nil
    
    var body: some View {
        ZStack {
            Color(.systemBackground) // Background color
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("Select Your User Type")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 40)
                
                // Cards
                CardView(title: "Hospital", color: Color.blue)
                CardView(title: "Doctor", color: Color.green)
                CardView(title: "Patient", color: Color.red)
                
                Spacer() // Pushes content to the top
            }
            .navigationTitle("") // Optional: Clears default navigation title if used in a navigation stack
        }
    }
}

// Reusable Card View
struct CardView: View {
    let title: String
    let color: Color
    
    var body: some View {
        NavigationLink(destination: LoginScreen(),){
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(color)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.horizontal)
        }
    }
    
}


// Preview
#Preview {
    NavigationView {
        UserSelectionView()
    }
}
