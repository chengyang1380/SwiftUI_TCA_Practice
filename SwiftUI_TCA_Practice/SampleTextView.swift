//
//  SampleTextView.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 3/31/25.
//

import ComposableArchitecture
import SwiftUI

struct SampleTextView: View {

    @Bindable var store: StoreOf<SampleTextFeature>

    var body: some View {
        ZStack {
            VStack {
                Button("Load") { store.send(.load) }
                Text(store.text)
            }
            if store.loading {
                ProgressView().progressViewStyle(.circular)
            }
        }
    }
}

#Preview {
    SampleTextView(
        store: Store(
            initialState: SampleTextFeature.State()
        ) {
            SampleTextFeature()
        } withDependencies: {
            $0.sampleTextFeatureEnvironment = .testValue
        }
    )
}
