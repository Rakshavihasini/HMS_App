//
//  CheckoutViewController.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 07/05/25.
//


import UIKit
import Razorpay

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
                "color": "#F37254"
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
        DispatchQueue.main.async { [weak self] in
            // Clean up the temporary window
            self?.paymentWindow = nil
            // Navigate back to the root view
            self?.coordinator?.parent.router.navigateToRoot()
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
