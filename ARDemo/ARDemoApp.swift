//
//  ARDemoApp.swift
//  ARDemo
//
//  Created by チョン ソンユル（Seoungyul Chon） on 2025/04/17.
//

import SwiftUI


// TODO:
// 1. Configurable positionScale adn rotationScale adjustment
// 2. Temperature monitoring (Automatically lower camera resolution or frame rate if thermal limits or frame drops are detected.)
// 3. Configurable camera quality
// 4. Display real-time tracking points or head model.
// 5. Auto Calibration / Calibration Wizard in the begging
// 6. Profile Presets
// 7. Environment Lighting Detection
// 8. Background Mode (doable?)
// 9. USB Connection (if possible)


@main
struct ARDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
