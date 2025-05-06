import SwiftUI
import FirebaseAuth

struct DoctorAuthView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        LoginScreen(userType: "doctor")
    }
} 
