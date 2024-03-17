//
//  ConfigurationView.swift
//  ESP 32 Watch WatchKit Extension
//
//  Created by Miquel Sitges Nicolau on 25/6/22.
//

import SwiftUI

struct ConfigurationView: View {
    @ObservedObject  var esp32Manager: ESP32Manager
   
    var body: some View {
        VStack{
            if(esp32Manager.conectado){
        Button("Buscar Ip"){
            esp32Manager.read()
            print("conectar")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                Task
                {
                    await esp32Manager.debug()
                }
            }

        }
            }else
            {
                ZStack{
                    Rectangle()
                        .ignoresSafeArea()
                        .foregroundColor(.mint.opacity(0.5))
                    VStack {
                        Text("Conectando...")
                            .font(.title2)
                        .foregroundColor(.green)
                    .padding(-10)
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .padding()
                    }
                }
                .edgesIgnoringSafeArea(.all)
              
                
            }
       
    }
        .onAppear()
        {
            esp32Manager.startScan()
        }
    }
}

struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView(esp32Manager: ESP32Manager())
    }
}
