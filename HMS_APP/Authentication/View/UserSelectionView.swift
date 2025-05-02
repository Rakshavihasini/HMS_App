import SwiftUI

struct UserSelectionView: View {
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [Color.medicareBlue.opacity(0.1), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Text("Welcome to")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("MediCare Manager")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.medicareBlue)
                    
                    Text("Choose your role to continue")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)
                
                Spacer()
                    .frame(height: 40)
                
                // Role Selection Cards
                VStack(spacing: 20) {
                    RoleCard(
                        title: "Hospital Admin",
                        description: "Manage hospital operations and staff",
                        icon: "h.circle",
                        color: .medicareBlue,
                        userType: "hospital"
                    )
                    
                    RoleCard(
                        title: "Doctor",
                        description: "Access patient records and appointments",
                        icon: "stethoscope",
                        color: .medicareGreen,
                        userType: "doctor"
                    )
                    
                    RoleCard(
                        title: "Patient",
                        description: "Book appointments and view medical history",
                        icon: "person.text.rectangle",
                        color: .medicareRed,
                        userType: "patient"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Footer
                Text("Need help? Contact support")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
}

struct RoleCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let userType: String
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: LoginScreen(userType: userType)) {
            HStack(spacing: 20) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 10,
                x: 0,
                y: 5
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: { })
    }
}

#Preview {
    NavigationView {
        UserSelectionView()
    }
}
