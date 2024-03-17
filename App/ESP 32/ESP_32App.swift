//
//  ESP_32App.swift
//  ESP 32
//
//  Created by Miquel Sitges Nicolau on 7/5/22.
//

import SwiftUI

@main
struct ESP_32App: App {
	@StateObject var esp32Manager = ESP32Manager()

    
    var body: some Scene {
        WindowGroup {
            MainView(esp32Manager: esp32Manager)
        }
        
    }
}
