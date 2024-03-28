//
//  ContentView.swift
//  DealsViewer
//
//  Created by Aynur Nasybullin on 26.03.2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var dealsProvider: DealsViewModel = .shared
    
    var body: some View {
        
        DealsView()
            .onAppear {
                loadDealsFromNetwork()
            }
    }
    
    private func loadDealsFromNetwork() {
        Task {
            await dealsProvider.deleteAll()
            await dealsProvider.loadDealsFromNetwork()
        }
    }
}

#Preview {
    ContentView()
}
