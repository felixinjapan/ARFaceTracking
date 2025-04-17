//
//  NetworkConfigurationView.swift
//  ARDemo
//
//  Created by チョン ソンユル（Seoungyul Chon） on 2025/04/17.
//

import SwiftUI

struct NetworkConfigurationView: View {
    @ObservedObject var store: NetworkConfigurationStore
    
    var body: some View {
        HStack(spacing: 16) {
            // IP Address Display
            Button(action: {
                store.showConfiguration()
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network Address")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(store.configuration.fullAddress)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Start/Stop Button
            Button(action: {
                store.toggleConnection()
            }) {
                Text(store.isConnected ? "Stop" : "Start")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 30)
                    .background(store.isConnected ? Color.red : Color.green)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $store.showConfigurationModal) {
            NetworkConfigurationModalView(store: store)
        }
    }
}

struct NetworkConfigurationModalView: View {
    @ObservedObject var store: NetworkConfigurationStore
    @State private var ipAddress: String = ""
    @State private var port: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Network Configuration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("IP Address")
                            .font(.headline)
                        TextField("192.168.1.100", text: $ipAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numbersAndPunctuation)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Port")
                            .font(.headline)
                        TextField("8080", text: $port)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                Section {
                    Button("Save Configuration") {
                        let newConfiguration = NetworkConfiguration(
                            ipAddress: ipAddress,
                            port: port
                        )
                        store.updateConfiguration(newConfiguration)
                    }
                    .disabled(ipAddress.isEmpty || port.isEmpty)
                }
            }
            .navigationTitle("Network Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        store.showConfigurationModal = false
                    }
                }
            }
        }
        .onAppear {
            ipAddress = store.configuration.ipAddress
            port = store.configuration.port
        }
    }
}
