//
//  TitleAndIconLabelStyle.swift
//  DealsViewer
//
//  Created by Aynur Nasybullin on 27.03.2024.
//

import SwiftUI

struct TitleAndIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
                .padding(0)
            configuration.icon
                .padding(0)
        }
    }
}
