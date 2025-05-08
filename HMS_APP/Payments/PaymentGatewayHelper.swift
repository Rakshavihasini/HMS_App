//
//  PaymentGatewayHelper.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 07/05/25.
//


import UIKit
import SwiftUI
import Razorpay

struct PaymentGatewayHelper: UIViewControllerRepresentable {
    @EnvironmentObject var router: Router<ViewPath>
    var consultationFee: Int = 100
    
    func makeUIViewController(context: Context) -> CheckoutViewController {
        let controller = CheckoutViewController()
        controller.consultationFee = consultationFee
        controller.coordinator = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CheckoutViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: PaymentGatewayHelper
        
        init(_ parent: PaymentGatewayHelper) {
            self.parent = parent
            super.init()
        }
    }
}
