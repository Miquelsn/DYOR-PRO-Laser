//
//  2Vista.swift
//  ESP 32 Watch WatchKit Extension
//
//  Created by Miquel Sitges Nicolau on 25/6/22.
//

import SwiftUI
import SwiftUIJoystick

struct JoystickView: View {
    @State var timer = Timer.publish(every: 0.1,on: .main, in: .common).autoconnect()
    @ObservedObject  var esp32Manager: ESP32Manager
    @StateObject private var movimiento=JoystickMonitor()
    
    @State var timerEncendido=false
    
    var body: some View {
        GeometryReader {geometry in
            Joystick(monitor: movimiento, width: geometry.size.width-20, shape: .circle)
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
                    .padding([.top, .leading], 10)
                    .onReceive(timer){
                        time in
                        
                        
                            var x = Int(movimiento.xyPoint.x/(geometry.size.width-20)*100)
                            var y = Int(-movimiento.xyPoint.y/(geometry.size.width-20)*100)
                            var dist=Int(Double((x*x+y*y)).squareRoot())
                          
                            Task{
                                await esp32Manager.MandarMovimiento(x:String(x), y:String(y), dist:String(dist) )
                            }
                        print(x)
                        print(y)
                        
                            
        }
                    .onAppear(){
                        timerEncendido=false
                        timer.upstream.connect().cancel()
                        
                    }
                    
        }
        .background(Color.green)
    }
}

struct _Vista_Previews: PreviewProvider {
    static var previews: some View {
        JoystickView(esp32Manager: ESP32Manager())
    }
}
