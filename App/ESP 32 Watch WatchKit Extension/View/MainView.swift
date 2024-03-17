//
//  ContentView.swift
//  ESP 32 Watch WatchKit Extension
//
//  Created by Miquel Sitges Nicolau on 25/6/22.
//

import SwiftUI


struct MainView: View {
    @ObservedObject  var esp32Manager: ESP32Manager
    @State private var selection = 0
    
    @AppStorage("dirrecionIp") var dirrecionIp: String = ""
    
    var body: some View {
        
       
           Group(){
               
           
           if(esp32Manager.configuracionRealizada)
           {
               TabView(selection: $selection) {
            JoystickView(esp32Manager: esp32Manager)
            
               
            Distancia(esp32Manager: esp32Manager)
               
               Acelerometro(esp32Manager: esp32Manager)
               }
               .tabViewStyle(.page)
                
           }
           else
           {
               ConfigurationView(esp32Manager: esp32Manager)
           }
        }

       .onAppear(){
           esp32Manager.realIP = dirrecionIp
           Task{
               await esp32Manager.debug()
           }
       }
       
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(esp32Manager: ESP32Manager())
    }
}
