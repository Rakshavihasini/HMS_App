//
//  Router.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 07/05/25.
//


import Foundation
import SwiftUI

class Router<T: Hashable>: ObservableObject {
    @Published var path: [T] = []
    
    func navigate(to destination: T) {
        path.append(destination)
    }
    
    func navigateBack() {
        _ = path.popLast()
    }
    
    func navigateToRoot() {
        path.removeAll()
    }
}
