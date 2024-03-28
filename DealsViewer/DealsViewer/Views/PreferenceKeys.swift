//
//  PreferenceKeys.swift
//  DealsViewer
//
//  Created by Aynur Nasybullin on 28.03.2024.
//

import SwiftUI

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
