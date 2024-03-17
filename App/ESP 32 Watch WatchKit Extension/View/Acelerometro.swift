//
//  Aceleremotro.swift
//  ESP 32 Watch WatchKit Extension
//
//  Created by Miquel Sitges Nicolau on 25/6/22.
//

import SwiftUI

struct Acelerometro: View {
    @State var activado = false
    @State var timer = Timer.publish(every: 0.1,on: .main, in: .common).autoconnect()
    @ObservedObject  var esp32Manager: ESP32Manager
    @StateObject var motionManager=MotionDetector()
    var body: some View {
        Button(activado ? "Apaga" : "Activa" )
        {
            print("Pulsado")
            if(!activado)
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
            activado.toggle()
        }.tint(activado ? .red :  .green)
            .onAppear(){
                timer.upstream.connect().cancel()
                activado=false
            }
            .onReceive(timer)
        {time in
            if(activado)
            {
            motionManager.updateMotionData()
            
            Task{
                var x = Int(motionManager.roll*100)
                var y = Int(-motionManager.pitch*100)
                var dist=Int(Double((x*x+y*y)).squareRoot())
                await esp32Manager.MandarMovimiento(x:String(x), y:String(y), dist:String(dist) )
            }
            }
            else{
                timer.upstream.connect().cancel()
            }
        }
    }
}

struct Aceleremotro_Previews: PreviewProvider {
    static var previews: some View {
        Acelerometro(esp32Manager: ESP32Manager())
    }
}
