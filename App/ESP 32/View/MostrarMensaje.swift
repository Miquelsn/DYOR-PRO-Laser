//
//  vistaMensaje.swift
//  ESP 32
//
//  Created by Miquel Sitges Nicolau on 25/5/22.
//
import SwiftUI

struct MostrarMensaje: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var esp32Manager:ESP32Manager
    
    @State var mensaje:String=""
    let scroll = ["Izquierda","Derecha"]
    @State var scrollSelecionado = "Izquierda"
    @State var velocidad:Double=225
    
    var body: some View {
        Form {
            Section("Mensaje")
            {
                TextField("Introduzca el mensaje", text: $mensaje)
            }
            Section("Tipo de Scroll"){
                Picker("¿Que tipo de Scroll prefieres?",selection: $scrollSelecionado)
                {
                    ForEach(scroll,id: \.self)
                    {
                        Text($0)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Velocidad")
            {
                Slider(
                    value: $velocidad,
                    in: 50...400,
                    step: 10
                ) {
                    Text("")
                } minimumValueLabel: {
                    Text("Minima")
                } maximumValueLabel: {
                    Text("Maxima")
                }
            }
            
            Section()
            {
                Button("Envia el mensaje") {
                    dismiss()
                    Task {
                        await esp32Manager.MandarMensaje(mensaje:mensaje,scroll:scrollSelecionado,velocidad:Int(450-velocidad))
                    }
                }
            }
            
            
            
            
        }
        
    }
}

struct MostrarMensajes_Previews: PreviewProvider {
    
    static var previews: some View {
        MostrarMensaje(esp32Manager: ESP32Manager())
            .previewDevice("iPhone 13 Pro")
            .previewInterfaceOrientation(.landscapeRight)
        
    }
}
