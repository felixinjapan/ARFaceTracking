//
//  NetworkConfiguration.swift
//  ARDemo
//
//  Created by チョン ソンユル（Seoungyul Chon） on 2025/04/17.
//

import Foundation

enum UDPProtocolType: String, CaseIterable {
    case openTrack = "OpenTrack"
    // TODO: remove later or replace with usb connection
    case sensorData = "Sensor Data"
}

struct NetworkConfiguration {
    var ipAddress: String
    var port: String
    var protocolType: UDPProtocolType = .openTrack
    
    static let `default` = NetworkConfiguration(
        ipAddress: "192.168.1.100",
        port: "8080",
        protocolType: .openTrack
    )
    
    var fullAddress: String {
        "\(ipAddress):\(port) (\(protocolType.rawValue))"
    }
}

@MainActor
class NetworkConfigurationStore: ObservableObject {
    @Published var configuration: NetworkConfiguration
    @Published var isConnected: Bool = false
    @Published var showConfigurationModal: Bool = false
    
    @Published var udpClient = UDPClient()
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let ipAddress = "network_ip_address"
        static let port = "network_port"
        static let protocolType = "network_protocol_type"
    }
    
    init() {
        let ipAddress = userDefaults.string(forKey: Keys.ipAddress) ?? NetworkConfiguration.default.ipAddress
        let port = userDefaults.string(forKey: Keys.port) ?? NetworkConfiguration.default.port
        let protocolTypeRaw = userDefaults.string(forKey: Keys.protocolType) ?? UDPProtocolType.openTrack.rawValue
        let protocolType = UDPProtocolType(rawValue: protocolTypeRaw) ?? .openTrack
        
        self.configuration = NetworkConfiguration(ipAddress: ipAddress, port: port, protocolType: protocolType)
    }
    
    func showConfiguration() {
        showConfigurationModal = true
    }
    
    func updateConfiguration(_ newConfiguration: NetworkConfiguration) {
        // If connected, disconnect first
        if isConnected {
            toggleConnection()
        }
        
        configuration = newConfiguration
        userDefaults.set(newConfiguration.ipAddress, forKey: Keys.ipAddress)
        userDefaults.set(newConfiguration.port, forKey: Keys.port)
        userDefaults.set(newConfiguration.protocolType.rawValue, forKey: Keys.protocolType)
        showConfigurationModal = false
    }
    
    func toggleConnection() {
        if isConnected {
            udpClient.disconnect()
            isConnected = false
        } else {
            udpClient.connect(to: configuration.ipAddress, port: configuration.port)
            isConnected = true
        }
    }
    
    func sendFaceTrackingData(_ data: FaceTrackingData) {
        guard isConnected else { return }
        
        switch configuration.protocolType {
        case .openTrack:
            udpClient.sendFaceTrackingData(data)
        case .sensorData:
            udpClient.sendSensorDataFormat(data)
        }
    }
}
