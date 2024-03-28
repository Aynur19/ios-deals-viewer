//
//  DealsViewerApp.swift
//  DealsViewer
//
//  Created by Aynur Nasybullin on 26.03.2024.
//

import SwiftUI

@main
struct DealsViewerApp: App {
    var dealsProvider: DealsViewModel = .shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dealsProvider.container.viewContext)
        }
    }
}
