//
//  ContentView.swift
//  ESP 32
//
//  Created by Miquel Sitges Nicolau on 7/5/22.
//

import SwiftUI

struct ConfigurationView: View {
    @ObservedObject var esp32Manager: ESP32Manager
    
    @State var ssid:String=""
    @State var password:String=""
    @State private var velSiguelineas=30.0
    @State private var ganancia=0.01
    @State private var gananciaD=0.003
    @State private var velEsquiva=30.0
    @State private var distanciaObjetos=400
    
    @State private var siguelineasEnviado=false
    @State private var esquivaObstaculosEnviado=false
    @State var mostrarAlerta = false
    
    
    var body: some View {
        NavigationView {
            Form{
                if !esp32Manager.configuracionRealizada
                {
                    NavigationLink("Volver sin configurar",destination: MainView(esp32Manager: esp32Manager)
                    )
                    .foregroundColor(.red)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(true)
                    DisclosureGroup("WiFi")
                    {
                    TextField("Introduce el nombre de la red", text: $ssid)
                    TextField("Introduce la contraseña de la red", text: $password)
                    
                    
                    Button("Enviar")
                    {
                        esp32Manager.write(value: Data((ssid).utf8))
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            
                            esp32Manager.write(value: Data((password).utf8))
                        }
                        
                    }
                    .disabled(!esp32Manager.conectado)
                    }
                    
                    
                    Button("Recibir la IP")
                    {
                        esp32Manager.read()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            Task
                            {
                                await esp32Manager.debug()
                            }
                        }
                    }
                    .disabled(!esp32Manager.conectado)
                }
                
                if esp32Manager.configuracionRealizada
                {
                    DisclosureGroup("Parametros del siguelineas") {
                        
                        Slider(
                            value: $velSiguelineas,
                            in: 0...100,
                            step: 1
                        ) {
                            Text("\(velSiguelineas)")
                        } minimumValueLabel: {
                            Text("Velocidad \(Int(velSiguelineas))")
                        } maximumValueLabel: {
                            Text("")
                        }
                        
                        Stepper("Ganancia del error:  \(ganancia, specifier: "%.3f")", value: $ganancia, in: 0.001...0.02,step: 0.001)
                        Stepper("Ganancia del error derivativo:  \(gananciaD, specifier: "%.4f")", value: $gananciaD, in: 0.001...0.03,step: 0.0002)
                        
                        
                        Button("Envia los datos")
                        {
                            if(!siguelineasEnviado)
                            {
                                mostrarAlerta=true
                                siguelineasEnviado=true
                            }else{
                                Task {
                                    await esp32Manager.parametrosSiguelinea(vel:String(velSiguelineas),k:String(ganancia),k_der:String(gananciaD))
                                }
                            }
                            
                            
                        }
                        .tint(siguelineasEnviado ? .green : .blue)
                        
                        Button("Valores predeterminados")
                        {
                            velSiguelineas=40
                            ganancia=0.001
                            gananciaD=0.001
                            Task {
                                await esp32Manager.parametrosSiguelinea(vel:String(velSiguelineas),k:String(ganancia),k_der:String(gananciaD))
                            }
                            siguelineasEnviado=false
                        }
                        .tint(siguelineasEnviado ? .blue : .yellow)
                    }
                    
                    
                    DisclosureGroup("Parametros del esquiva obstaculos") {
                        
                        Slider(
                            value: $velEsquiva,
                            in: 0...100,
                            step: 1
                        ) {
                            Text("\(velEsquiva)")
                        } minimumValueLabel: {
                            Text("Velocidad \(Int(velEsquiva))")
                        } maximumValueLabel: {
                            Text("")
                        }
                        
                        Stepper("Distancia al objeto  \(distanciaObjetos)", value: $distanciaObjetos, in: 90...520,step: 30)
                        
                        Button("Envia los datos")
                        {
                            if(!esquivaObstaculosEnviado){
                                mostrarAlerta=true
                                esquivaObstaculosEnviado=true
                            }else{
                                
                                Task{
                                    await esp32Manager.parametrosObstaculos(vel: String(velEsquiva), dist: String(distanciaObjetos))
                                }
                            }
                        }
                        .tint(esquivaObstaculosEnviado ? .green : .blue)
                        
                        Button("Valores predeterminados")
                        {
                            velEsquiva=40
                            distanciaObjetos=400
                            
                            Task {
                                await esp32Manager.parametrosObstaculos(vel: String(velEsquiva), dist: String(distanciaObjetos))
                            }
                            siguelineasEnviado=false
                        }
                        .tint(siguelineasEnviado ? .blue : .yellow)
                    
                        
                        
                    }
                    .alert(isPresented: $mostrarAlerta) {
                        Alert(title: Text("Estas modificando los valores predeterminados"), message: Text("Podria tener efectos extraños en  el comportamiento"), primaryButton: .default(Text("Modificar"))
                              {
                            Task {
                                if(!esquivaObstaculosEnviado)
                                {
                                    await esp32Manager.parametrosSiguelinea(vel:String(velSiguelineas),k:String(ganancia),k_der:String(gananciaD))
                                    
                                }else if(!siguelineasEnviado)
                                {
                                    await esp32Manager.parametrosObstaculos(vel: String(velEsquiva), dist: String(distanciaObjetos))
                                }
                            }
                        }, secondaryButton: .destructive(Text("No modificar"))
                              {
                            siguelineasEnviado=false
                            esquivaObstaculosEnviado=false
                        })
                    }
                    Text(esp32Manager.Ip)
                    NavigationLink("Configuracion Realizada",destination: MainView(esp32Manager: esp32Manager)
                    )
                    
                    .navigationBarHidden(true)
                    .navigationBarBackButtonHidden(true)
                    
                    .foregroundColor(.green)
                 
                
                    
                }
                
            }
            
        }
        
        
        .onAppear()
        {
            esquivaObstaculosEnviado=false
            siguelineasEnviado=false
            Task{
                
            
            await esp32Manager.debug()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .navigationViewStyle(.stack)
        
        
    }
    
}





struct ConfigurationView_Previews: PreviewProvider {
    static var esp32Manager = ESP32Manager()
    static var previews: some View {
        ConfigurationView(esp32Manager: esp32Manager)
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
