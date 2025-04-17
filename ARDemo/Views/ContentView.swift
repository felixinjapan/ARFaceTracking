//
//  ContentView.swift
//  ARDemo
//
//  Created by チョン ソンユル（Seoungyul Chon） on 2025/04/17.
//

import SwiftUI
import ARKit
import RealityKit
import Foundation
import simd

struct FaceTrackingData: Equatable {
    var position: SIMD3<Float>
    var yaw: Float
    var pitch: Float
    var roll: Float
}

enum ArrowOrientation: Comparable {
    enum Top: Comparable {
        case center
        case left
        case right
        case topLeft
        case topRight
    }

    enum Bottom: Comparable {
        case center
        case left
        case right
        case bottomLeft
        case bottomRight
    }

    case top(Top)
    case bottom(Bottom)
    case left
    case right
}

let oritentation = ArrowOrientation.top(.center)

struct ContentView: View {

    @State var trackingData: FaceTrackingData?
    @StateObject private var networkStore = NetworkConfigurationStore()

    var body: some View {
        VStack(spacing: 0) {
            FaceTrackingView(trackingData: $trackingData)
                .frame(height: 300)
                .cornerRadius(16)
                .shadow(radius: 5)
            
            if let data = trackingData {
                VStack(alignment: .leading) {
                    Text(String(format: "Face Position - x: %.3f, y: %.3f, z: %.3f", data.position.x, data.position.y, data.position.z))
                        .foregroundStyle(.white)
                    Text(String(format: "Yaw: %.3f, Pitch: %.3f, Roll: %.3f", data.yaw, data.pitch, data.roll))
                        .foregroundStyle(.white)
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .padding()
            } else {
                Text("Detecting face...")
                    .foregroundColor(.gray)
            }
            
            NetworkConfigurationView(store: networkStore)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea(.all)
        .onChange(of: trackingData) {
            if let data = trackingData, networkStore.isConnected {
                networkStore.sendFaceTrackingData(data)
            }
        }
    }
}

struct FaceTrackingView: UIViewRepresentable {

    @Binding var trackingData: FaceTrackingData?
    
    func makeCoordinator() -> FaceTrackingCoordinator {
        FaceTrackingCoordinator(trackingData: $trackingData)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator
        let configuration = ARFaceTrackingConfiguration()
        arView.session.run(configuration, options: [])
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    let stubPosition = SIMD3<Float>(0.12, -0.34, 1.56)
    let data = FaceTrackingData(position: stubPosition, yaw: 0.0, pitch: 0.0, roll: 0.0)
    
    ContentView(trackingData: data)
}
