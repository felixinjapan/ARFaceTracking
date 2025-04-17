//
//  UDPClient.swift
//  ARDemo
//
//  Created by チョン ソンユル（Seoungyul Chon） on 2025/04/17.
//

import Foundation
import Network

class UDPClient: ObservableObject {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "udp.client.queue")
    
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    
    func connect(to host: String, port: String) {
        guard let portNumber = UInt16(port) else {
            connectionStatus = "Invalid port number"
            return
        }
        
        let host = NWEndpoint.Host(host)
        let port = NWEndpoint.Port(rawValue: portNumber)!
        
        connection = NWConnection(host: host, port: port, using: .udp)
        print("Connecting to \(host) on port \(port.rawValue)")
        
        connection?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.isConnected = true
                    self?.connectionStatus = "Connected"
                    print("UDP connection established")
                case .failed(let error):
                    self?.isConnected = false
                    self?.connectionStatus = "Failed: \(error.localizedDescription)"
                    print("UDP connection failed: \(error)")
                case .cancelled:
                    self?.isConnected = false
                    self?.connectionStatus = "Disconnected"
                    print("UDP connection cancelled")
                case .waiting(let error):
                    self?.isConnected = false
                    self?.connectionStatus = "Waiting: \(error.localizedDescription)"
                    print("UDP connection waiting: \(error)")
                default:
                    break
                }
            }
        }
        
        connection?.start(queue: queue)
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
        connectionStatus = "Disconnected"
    }
    
    func sendData(_ data: Data) {
        guard isConnected, let connection = connection else {
            print("Cannot send data: not connected")
            return
        }
        
        connection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed { error in
            if let error = error {
                print("Send error: \(error)")
                Task { @MainActor in
                    self.connectionStatus = "Send failed: \(error.localizedDescription)"
                }
            }
        })
    }
    
    func sendFaceTrackingData(_ data: FaceTrackingData) {
        let openTrackData = createOpenTrackPacket(from: data)
        sendData(openTrackData)
    }
    
    private func createOpenTrackPacket(from data: FaceTrackingData) -> Data {
        var packet = Data()
        
        // Convert position (X, Y, Z) and rotation (yaw, pitch, roll) from Float to Double
        let values: [Double] = [
            Double(data.position.x),
            Double(data.position.y),
            Double(data.position.z),
            Double(data.yaw),
            Double(data.pitch),
            Double(data.roll)
        ]
        
        // Pack each double value (8 bytes each) in little-endian format
        for value in values {
            withUnsafeBytes(of: value.bitPattern) { packet.append(contentsOf: $0) }
        }
        
        return packet
    }
}

extension UDPClient {
    func sendSensorDataFormat(_ data: FaceTrackingData) {
        let timestamp = Date().timeIntervalSince1970
        let message = String(format: "%.3f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f",
                            timestamp,
                            data.position.x,
                            data.position.y,
                            data.position.z,
                            data.roll,
                            data.pitch,
                            data.yaw)
        
        if let messageData = message.data(using: .utf8) {
            sendData(messageData)
            print("Sending Sensor Data format: \(message)")
        }
    }
}

struct FaceTrackingMessage: Codable {
    let x: Float
    let y: Float
    let z: Float
    let yaw: Float
    let pitch: Float
    let roll: Float
    let timestamp: TimeInterval
}
