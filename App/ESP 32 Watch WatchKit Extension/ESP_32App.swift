//
//  ESP_32App.swift
//  ESP 32 Watch WatchKit Extension
//
//  Created by Miquel Sitges Nicolau on 25/6/22.
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
