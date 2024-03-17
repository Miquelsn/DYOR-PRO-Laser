//
//  MainView.swift
//  ESP 32
//
//  Created by Miquel Sitges Nicolau on 7/5/22.
//
import SwiftUI
import SwiftUIJoystick


struct MainView: View {
    
    @StateObject private var movimiento=JoystickMonitor()
    @StateObject var motionManager=MotionDetector()
    
    var ancho:CGFloat=125
    
    @State var cambioMovimiento = true
    @State var servo:Double=90
    @State private var editandoServo = false
    @ObservedObject  var esp32Manager: ESP32Manager
    
    
    let backgroundGradient = LinearGradient(
        colors: [Color.blue.opacity(0.2), Color.green.opacity(0.3)],
        startPoint: .top, endPoint: .bottom)
    
    @State var timer = Timer.publish(every: 0.1,on: .main, in: .common).autoconnect()
    @State var timerEncendido=false
    @State var sinJoystick:Bool=false
    @State private var mostrarMensaje = false
    @State private var crearSimbolo = false
    
    @AppStorage("dirrecionIp") var dirrecionIp: String = ""
    
    
    
    var body: some View {
        GeometryReader{geometry in
            
            NavigationView{
                Group{
                    
                    VStack{
                        HStack{
                            Button("Siguelineas")
                            {
                                Task{
                                    await esp32Manager.SeguirLineas()
                                }
                            }
                            .lineLimit(1)
                            .padding([.top, .leading, .trailing], 20.0)
                            .buttonStyle(.borderedProminent)
                            .tint(esp32Manager.configuracionRealizada ? .blue : .red)
                            .disabled(esp32Manager.esquivaObstaculos || sinJoystick)
                            Button("Esquiva Obstaculos")
                            {
                                Task{
                                    await esp32Manager.EsquivaObstaculos()
                                }
                            }
                            .padding([.top, .leading, .trailing], 20.0)
                            .buttonStyle(.borderedProminent)
                            .lineLimit(2)
                            .tint(esp32Manager.configuracionRealizada ? .blue : .red)
                            .disabled(esp32Manager.sigueLineas || sinJoystick)
                            
                            Button("Control por giroscopio")
                            {
                                if(!sinJoystick)
                                {
                                    motionManager.start()
                                    timer=Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()
                                }else{
                                    motionManager.stop()
                                    timer.upstream.connect().cancel()
                                    Task{
                                        await esp32Manager.MandarMovimiento(x:String(0), y:String(0), dist: String(0))
                                    }
                                }
                                sinJoystick.toggle()
                                
                            }
                            .padding([.top, .leading, .trailing], 20.0)
                            .buttonStyle(.borderedProminent)
                            .lineLimit(3)
                            .tint(esp32Manager.configuracionRealizada  && sinJoystick == true ? .blue : .red)
                            .disabled(esp32Manager.sigueLineas || esp32Manager.esquivaObstaculos)
                            Spacer()
                            
                            NavigationLink( destination: ConfigurationView(esp32Manager: esp32Manager))
                            {
                                HStack{
                                    Image(systemName: "gear.circle")
                                    Text("Config")
                                }
                            }
                            
                            .navigationBarHidden(true)
                            .tint(esp32Manager.configuracionRealizada == true ? .blue : .red)
                            .border(Color.gray, width: 1)
                            .padding()
                            .onTapGesture {
                                esp32Manager.startScan()
                              
                                
                                
                            }
                            
                            
                        }
                        
                        
                        Spacer()
                        
                        
                        HStack{
                            colorOjos(esp32Manager: esp32Manager)
                                .padding(.leading, 50)
                            
                            HStack(spacing:0){
                                VStack
                                {
                                    Spacer()
                                    Text("Izquierda")
                                }
                                .frame(maxHeight:geometry.size.height/2)
                                Histograma(esp32Manager: esp32Manager, barColor: .yellow.opacity(0.7))
                                
                                    .border(.black)
                                    .frame(maxHeight:geometry.size.height/2)
                                    .padding()
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        Task{
                                            await esp32Manager.barrido()
                                        }
                                    }
                                
                                
                                VStack()
                                {
                                    Text("1.2 m")
                                    Spacer()
                                    Text("Derecha")
                                }.frame(maxHeight:geometry.size.height/2)
                            }
                            
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
                            .tint(esp32Manager.configuracionRealizada == true ? .green : .red)
                            
                        }
                        Spacer()
                        HStack{
                            Joystick(monitor: movimiento, width: ancho, shape: .circle)
                                .padding(.horizontal, 30)
                                .opacity(sinJoystick || esp32Manager.sigueLineas || esp32Manager.esquivaObstaculos  ? 0.2 : 1)
#if !os(iOS)
                            
                                .padding(50)
#endif
                                .onChange(of: movimiento.xyPoint.y){ value in
                                    if(value == 0 && timerEncendido && movimiento.xyPoint.x == 0){
                                   
                                        timerEncendido=false
                                        timer.upstream.connect().cancel()
                                        Task{
                                            await esp32Manager.MandarMovimiento(x:String(0), y:String(0), dist: String(0))
                                        }
                                    }
                                    else if(!timerEncendido)
                                    {
                                       
                                        timerEncendido=true
                                        timer=Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()
                                    }
                                }
                            //
                                .onReceive(timer){
                                    time in
                                    
                                    if(!sinJoystick){
                                        var x = Int(movimiento.xyPoint.x/ancho*100)
                                        var y = Int(-movimiento.xyPoint.y/ancho*100)
                                        var dist=Int(Double((x*x+y*y)).squareRoot())
                                        
                                        Task{
                                            await esp32Manager.MandarMovimiento(x:String(x), y:String(y), dist:String(dist) )
                                        }
                                    }else{
                                        motionManager.updateMotionData()
                                        
                                        var x = Int(motionManager.roll*100)
                                        var y = Int(-motionManager.pitch*100)
                                        var dist=Int(Double((x*x+y*y)).squareRoot())
                                     
                                        Task{
                                            await esp32Manager.MandarMovimiento(x:String(x), y:String(y), dist:String(dist) )
                                        }
                                        
                                    }
                                }
                                .disabled(sinJoystick ||  esp32Manager.sigueLineas || esp32Manager.esquivaObstaculos)
                            
                            Spacer()
                            HStack{
                                VStack{
                                    Button("Mensaje")
                                    {
                                        mostrarMensaje.toggle()
                                    }
                                    .lineLimit(1)
                                    .padding(.bottom)
                                    
                                    Button("Simbolo")
                                    {
                                        Task{
                                            crearSimbolo.toggle()
                                        }
                                    }
                                    
                                    
                                }
                                .tint(esp32Manager.configuracionRealizada == true ? .blue : .red)
                                .padding(2)
                                VStack{
                                    Button()
                                    {
                                        Task{
                                            await esp32Manager.MandarSimbolo(simbolo: "Rayo")
                                        }
                                    }
                                label:{
                                    Image(systemName: "bolt")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                }
                                    
                                    Button()
                                    {
                                        Task{
                                            await esp32Manager.MandarSimbolo(simbolo: "Flecha_d")
                                        }
                                    }
                                    
                                label:{
                                    Image(systemName: "arrow.right")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                    
                                }
                                }
                                
                                .tint(esp32Manager.configuracionRealizada == true ? .blue : .red)
                                .padding()
                            }
                            .contentShape(Rectangle())
                            .sheet(isPresented: $crearSimbolo) {
                                MatrizView( datos: datosMatrix(), esp32Manager: esp32Manager)
                            }
                            .sheet(isPresented: $mostrarMensaje) {
                                MostrarMensaje( esp32Manager: esp32Manager)
                            }
                            Spacer()
                            
                            Slider(
                                value: $servo,
                                in: 0...180,
                                step: 1
                            ) {
                                Text("")
                            } minimumValueLabel: {
                                Text("Izquierda")
                            } maximumValueLabel: {
                                Text("Derecha")
                            } onEditingChanged: { editing in
                               
                                if(editing==false)
                                {
                                    Task {
                                        await esp32Manager.servo(angulo: Int(servo))
                                    }
                                }
                                
                            }
                            .frame(width: geometry.size.width/2)
                            .padding()
                            .tint(esp32Manager.configuracionRealizada == true ? .green : .red)
                            .disabled( esp32Manager.sigueLineas && esp32Manager.esquivaObstaculos)
                            
                            
                        }
                        .padding(.bottom)
                    }
                    .onAppear
                    {
                        print("Aqui")
                        esp32Manager.realIP=dirrecionIp
                        print(esp32Manager.realIP)
                        print(dirrecionIp)
                        Task {
                            await esp32Manager.debug()
                        }
                        print(esp32Manager.realIP)
                        print(dirrecionIp)
                        timer.upstream.connect().cancel()
                    }
                }
                .background(backgroundGradient)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .navigationViewStyle(.stack)
        }
    }
}

struct colorOjos: View {
    @State private var  colorD = Color.red
    @State private var colorI = Color.red
    @ObservedObject var esp32Manager : ESP32Manager
    var body: some View {
        VStack{
            HStack{
                ColorPicker("I", selection: $colorI,supportsOpacity: false)
                    .labelsHidden()
                ColorPicker("D", selection: $colorD, supportsOpacity: false)
                    .labelsHidden()
            }
            Button("Manda Color")
            {
                Task{
                    await esp32Manager.Rgb(color: colorI, derecho: false)
                    await esp32Manager.Rgb(color: colorD, derecho: true)
                }
            }
            .tint(esp32Manager.configuracionRealizada == true ? .green : .red)
        }
    }
}


struct MainView_Previews: PreviewProvider {
    
    static var previews: some View {
        MainView(esp32Manager: ESP32Manager())
            .previewDevice("iPhone 13 Pro")
            .previewInterfaceOrientation(.landscapeRight)
    }
}
