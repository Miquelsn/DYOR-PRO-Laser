//
//  Matriz.swift
//  ESP 32
//
//  Created by Miquel Sitges Nicolau on 31/5/22.
//

import SwiftUI

struct MatrizView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var datos:datosMatrix
    @ObservedObject var esp32Manager:ESP32Manager
    let efecto = ["Aparecer","Parpadeo","Scroll hacia arriba","Scroll hacia abajo","Scroll hacia derecha","Scroll hacia izquierda","Columnas horizontales","Columnas inversas verticales","Encendido y apagado con brillo","Puntos diagonales","Encendido columnas horizontales","Aleatorio punto a punto","Muestreo horizontal","Muestreo horizontal con cursor","Columna a columna horizontal","Columna a columna horizontal apagada","Columna a columna vertical","Columna a columna vertical apagada","Columna a columna desde el centro","Apertura","Cierre","Scroll hacia arriba izquierda","Scroll hacia arriba derecha","Scroll hacia abajo izquierda","Scroll hacia abajo derecha","Crece de arriba a abajo","Crece de abajo a arriba"]
    @State var efectoSelecionado = 0
    @State var velocidad = 225.0
    var body: some View {
        NavigationView{
            HStack{
                HStack {
                    ForEach(0..<8){ i in
                        columna(numColumna: i, datos: datos)
                    }
                    
                }
                .padding()
                .frame(width: 350, height: 350)
                Form{
                    
                    Section("Efecto")
                    {
                        Picker("Efecto Selecionado", selection: $efectoSelecionado, content: {
                            ForEach(0..<efecto.count, content: { index in // <2>
                                Text(efecto[index]) // <3>
                            })
                        })
                    }
                    Section("Velocidad")
                    {
                        Slider(
                            value: $velocidad,
                            in: 20...700,
                            step: 20
                        ) {
                            Text("")
                        } minimumValueLabel: {
                            Text("Minima")
                        } maximumValueLabel: {
                            Text("Maxima")
                        }
                    }
                    
                    
                    Button("Manda los valores")
                    {
                        
                        datos.calculaValores()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            Task{
                                await esp32Manager.creacionSimbolo(matriz:datos.valorColumnas,efecto: efectoSelecionado,velocidad: Int(720-velocidad))
                            }
                        }
                        
                       dismiss()
                        
                    }
                    
                    
                    
                }
                
                
            }
        }
        
    }
}
struct columna: View {
    @State var sumaColumna=0
    @State var numColumna = 0
    @ObservedObject var datos:datosMatrix
    var body: some View {
        VStack {
            ForEach(0..<8){ i in
                Circulo(color: Color.black,valor: i,numColumna: numColumna, datos: datos)
                
                
            }
        }
        
        
    }
}

struct Circulo: View {
    @State var color = Color.black
    @State var valor = 0
    @State var activo = false
    @State var numColumna = 0
    @ObservedObject var datos:datosMatrix
    var body: some View {
        Circle()
            .fill(activo ? .red : .black)
        
            .onTapGesture {
                if(!activo){
                    
                    datos.valorPuntos[numColumna][valor]=Int(pow(Double(2), Double(valor)))
                }else{
                    datos.valorPuntos[numColumna][valor]=0
                }
                
                activo.toggle()
            }
    }
}
class datosMatrix :ObservableObject
{
    @Published var valorPuntos=Array(repeating: Array(repeating: 0, count: 8), count: 8)
    @Published var valorColumnas=Array(repeating: 0, count: 8)
    
    func calculaValores()
    {
        for i in 0...7
        {
            valorColumnas[i]=0
            valorColumnas[i]=valorColumnas[i] + valorPuntos[i].reduce(0,+)
            
            
        }
        
    }
}

struct MatrizView_Previews: PreviewProvider {
    
    static var previews: some View {
        MatrizView(datos: datosMatrix(), esp32Manager: ESP32Manager())
            .previewDevice("iPhone 13 Pro")
            .previewInterfaceOrientation(.landscapeRight)
        
    }
}
