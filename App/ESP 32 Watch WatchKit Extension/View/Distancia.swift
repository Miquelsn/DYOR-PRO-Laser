//
//  Distancia.swift
//  ESP 32 Watch WatchKit Extension
//
//  Created by Miquel Sitges Nicolau on 25/6/22.
//

import SwiftUI

struct Distancia: View {
    @ObservedObject  var esp32Manager: ESP32Manager
    var body: some View {
        VStack{
            Button("Lectura distancia")
            {
                Task{
                    await esp32Manager.medir()
                }
            }
            .padding(.all, 20.0)
            .buttonStyle(.borderedProminent)
            .lineLimit(1)
            Text(esp32Manager.medida)
        }
    }
}

struct Distancia_Previews: PreviewProvider {
    static var previews: some View {
        Distancia(esp32Manager: ESP32Manager())
    }
}
