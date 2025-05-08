//
//  CheckoutViewController.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 07/05/25.
//

import SwiftUI
import UIKit
import Razorpay
import FirebaseFirestore

class CheckoutViewController: UIViewController, RazorpayPaymentCompletionProtocol {
    var razorpay: RazorpayCheckout!
    var consultationFee: Int = 100
    var coordinator: PaymentGatewayHelper.Coordinator?
    private var paymentWindow: UIWindow?
    private var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActivityIndicator()
        razorpay = RazorpayCheckout.initWithKey("rzp_test_ZqBfMQUf8mFXbt", andDelegate: self)
        
        // Start the activity indicator
        activityIndicator.startAnimating()
        
        // Add a delay before showing the payment form
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showPaymentForm()
        }
    }
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .systemBlue
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Add a loading label below the activity indicator
        let loadingLabel = UILabel()
        loadingLabel.text = "Preparing Payment Gateway..."
        loadingLabel.textAlignment = .center
        loadingLabel.textColor = .systemGray
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16)
        ])
    }
    
    func showPaymentForm() {
        // Convert fee to paise (smallest currency unit)
        let amountInPaise = String(consultationFee * 100)
        
        let options: [String:Any] = [
            "amount": amountInPaise, // Amount in smallest currency unit (100 = ₹1)
            "currency": "INR",
            "description": "Medical Consultation",
            "image": "https://your-company-logo-url.png",
            "name": "HMS Hospital",
            "prefill": [
                "contact": "9876543210",
                "email": "user@example.com"
            ],
            "theme": [
                "color": "#007AFF"
            ]
        ]
        
        // Create a temporary window for Razorpay
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let tempWindow = UIWindow(windowScene: windowScene)
            let tempController = UIViewController()
            tempWindow.rootViewController = tempController
            tempWindow.makeKeyAndVisible()
            self.paymentWindow = tempWindow
            
            // Initialize Razorpay on the temp controller
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                // Stop the activity indicator when opening Razorpay
                self.activityIndicator.stopAnimating()
                self.razorpay.open(options)
            }
        } else {
            // Fallback to normal presentation
            activityIndicator.stopAnimating()
            razorpay.open(options)
        }
    }
    
    func onPaymentSuccess(_ payment_id: String) {
        print("Payment Success: \(payment_id)")
        // Handle successful payment
        
        // Update appointment status in Firestore
        if let appointmentId = UserDefaults.standard.string(forKey: "currentAppointmentId") {
            let db = Firestore.firestore()
            let appointmentRef = db.collection("hms4_appointments").document(appointmentId)
            
            appointmentRef.updateData([
                "status": "SCHEDULED",
                "paymentStatus": "completed",
                "paymentId": payment_id
            ]) { error in
                if let error = error {
                    print("Error updating appointment status: \(error.localizedDescription)")
                } else {
                    print("Appointment status updated successfully")
                }
                
                // Clean up the UserDefaults
                UserDefaults.standard.removeObject(forKey: "currentAppointmentId")
                
                // Continue with UI cleanup and navigation
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Clean up the temporary window
                    self.paymentWindow = nil
                    
                    // Get the window scene
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        
                        // Create a new PatientHomeView as the root
                        let patientHomeView = UIHostingController(rootView: PatientHomeView()
                            .environmentObject(AuthManager())
                            .environmentObject(AppointmentManager()))
                        
                        // Set as the root view controller to clear navigation stack
                        window.rootViewController = patientHomeView
                        
                        // Show the alert on the new root view
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let alertController = UIAlertController(
                                title: "Appointment Scheduled",
                                message: "Your appointment has been scheduled successfully!",
                                preferredStyle: .alert
                            )
                            
                            alertController.addAction(UIAlertAction(title: "OK", style: .default))
                            
                            patientHomeView.present(alertController, animated: true)
                        }
                    }
                }
            }
        } else {
            // If no appointment ID found, just continue with UI cleanup
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Clean up the temporary window
                self.paymentWindow = nil
                
                // Get the window scene
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    
                    // Create a new PatientHomeView as the root
                    let patientHomeView = UIHostingController(rootView: PatientHomeView()
                        .environmentObject(AuthManager())
                        .environmentObject(AppointmentManager()))
                    
                    // Set as the root view controller to clear navigation stack
                    window.rootViewController = patientHomeView
                    
                    // Show the alert on the new root view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let alertController = UIAlertController(
                            title: "Appointment Scheduled",
                            message: "Your appointment has been scheduled successfully!",
                            preferredStyle: .alert
                        )
                        
                        alertController.addAction(UIAlertAction(title: "OK", style: .default))
                        
                        patientHomeView.present(alertController, animated: true)
                    }
                }
            }
        }
    }
    
    func onPaymentError(_ code: Int32, description: String) {
        print("Payment Error: \(code) - \(description)")
        // Handle payment error
        DispatchQueue.main.async { [weak self] in
            // Clean up the temporary window
            self?.paymentWindow = nil
            // Navigate back
            self?.coordinator?.parent.router.navigateBack()
        }
    }
}
