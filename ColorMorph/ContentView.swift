//
//  ContentView.swift
//  ColorMorph
//
//  Created by Stephano Portella on 22/07/25.
//

import SwiftUI

struct ContentView: View {
    @State private var parameters = ColorFieldParameters.default

    var body: some View {
        ZStack(alignment: .bottom) {
            MetalBackgroundView(parameters: parameters)
                .ignoresSafeArea()
            ControlsView(parameters: $parameters)
        }
    }
}

#Preview {
    ContentView()
}
