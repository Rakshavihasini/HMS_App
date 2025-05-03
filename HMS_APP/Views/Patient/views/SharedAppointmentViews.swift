import SwiftUI

// Helper view to display appointment details in sheet
struct AppointmentSheetContents: View {
    let appointment: AppointmentData
    @Binding var showRescheduleModal: Bool
    @ObservedObject var appointmentManager: AppointmentManager
    let onDismiss: () -> Void
    
    var body: some View {
        AppointmentDetailView(
            appointment: appointment,
            showRescheduleModal: $showRescheduleModal,
            onCancel: {
                appointmentManager.cancelAppointment(appointmentId: appointment.id)
                onDismiss()
            }
        )
        .onAppear {
            print("DEBUG: Opening sheet with appointment - ID: " + appointment.id)
        }
    }
} 
