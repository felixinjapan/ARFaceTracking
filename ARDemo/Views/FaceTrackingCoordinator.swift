//
//  FaceTrackingCoordinator.swift
//  ARDemo
//
//  Created by チョン ソンユル（Seoungyul Chon） on 2025/04/17.
//

import ARKit
import SwiftUI

final class FaceTrackingCoordinator: NSObject, ARSessionDelegate {

    @Binding var trackingData: FaceTrackingData?
    
    /// Calibration storage (neutral/center) as a full transform
    private var referenceMatrix: simd_float4x4?
    /// Deadzone threshold for noise reduction (degrees for angles, cm for translation)
    private let deadzoneThreshold: Float = 0.15
        
    private enum Conversion {
        static let metersTocentimeters: Float = 100.0
        static let radiansToDegrees: Float = 180.0 / .pi
    }
    
    init(trackingData: Binding<FaceTrackingData?>) {
        self._trackingData = trackingData
        super.init()
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        
        let currentTransform = faceAnchor.transform
        
        // Initialize reference matrix on first detection
        initializeReferenceIfNeeded(with: currentTransform)
        
        // Calculate relative transform
        let relativeTransform = calculateRelativeTransform(from: currentTransform)
        
        // Extract and convert translation
        let translation = extractAndConvertTranslation(from: relativeTransform)
        
        // Extract and convert rotation
        let rotation = extractAndConvertRotation(from: relativeTransform)
        
        // Apply deadzone filtering
        let filteredTranslation = applyDeadzone(to: translation)
        let filteredRotation = applyDeadzone(to: rotation)
        
        // Update tracking data on main thread
        Task { @MainActor in
            self.trackingData = .init(
                position: filteredTranslation,
                yaw: filteredRotation.x,
                pitch: filteredRotation.y,
                roll: filteredRotation.z
            )
        }
    }

    private func initializeReferenceIfNeeded(with transform: simd_float4x4) {
        if referenceMatrix == nil {
            referenceMatrix = transform
        }
    }
    
    private func calculateRelativeTransform(from currentTransform: simd_float4x4) -> simd_float4x4 {
        guard let reference = referenceMatrix else {
            return matrix_identity_float4x4
        }
        
        let inverseReference = simd_inverse(reference)
        return simd_mul(inverseReference, currentTransform)
    }
    
    private func extractAndConvertTranslation(from transform: simd_float4x4) -> SIMD3<Float> {
        // Extract translation from transform matrix (meters -> centimeters)
        let translation = transform.columns.3
        let xCentimeters = translation.x * Conversion.metersTocentimeters  // ARKit: +X right
        let yCentimeters = translation.y * Conversion.metersTocentimeters  // ARKit: +Y up
        let zCentimeters = translation.z * Conversion.metersTocentimeters  // ARKit: face in front => negative Z
        
        // Map to tracker/game convention (OpenTrack-like): +X = left, +Y = up, +Z = forward
        let mappedX = -xCentimeters
        let mappedY = yCentimeters
        let mappedZ = -zCentimeters
        
        return SIMD3<Float>(mappedX, mappedY, mappedZ)
    }
    
    private func extractAndConvertRotation(from transform: simd_float4x4) -> SIMD3<Float> {
        // Extract Euler angles (degrees) from the relative rotation (Y-X-Z)
        let (yawDegrees, pitchDegrees, rollDegrees) = Self.eulerYXZDegrees(from: transform)
        
        // Apply sign tweaks to match preview expectations
        let mappedYaw = -yawDegrees
        let mappedPitch = pitchDegrees
        let mappedRoll = -rollDegrees
        
        return SIMD3<Float>(mappedYaw, mappedPitch, mappedRoll)
    }
    
    private func applyDeadzone(to vector: SIMD3<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(
            applyDeadzoneToValue(vector.x),
            applyDeadzoneToValue(vector.y),
            applyDeadzoneToValue(vector.z)
        )
    }
    
    private func applyDeadzoneToValue(_ value: Float) -> Float {
        return abs(value) < deadzoneThreshold ? 0.0 : value
    }

    private static func eulerYXZDegrees(from transform: simd_float4x4) -> (Float, Float, Float) {
        // Extract rotation matrix components
        let r01 = transform.columns.1.x
        let r11 = transform.columns.1.y
        let r21 = transform.columns.1.z
        let r20 = transform.columns.0.z
        let r22 = transform.columns.2.z
        
        // Calculate Euler angles in radians
        let pitchRadians = asinf(-r21)
        let yawRadians = atan2f(r20, r22)
        let rollRadians = atan2f(r01, r11)
        
        // Convert to degrees
        return (
            yawRadians * Conversion.radiansToDegrees,
            pitchRadians * Conversion.radiansToDegrees,
            rollRadians * Conversion.radiansToDegrees
        )
    }
}
