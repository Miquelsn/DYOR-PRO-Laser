//
//  Aceleromote datos.swift
//  ESP 32 Watch WatchKit Extension
//
//  Created by Miquel Sitges Nicolau on 25/6/22.
//



import CoreMotion
import  Foundation

import WatchKit
import WatchConnectivity


class MotionDetector:ObservableObject{
    
    private let motionManager = CMMotionManager()
  
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    
    func start(){
        if motionManager.isDeviceMotionAvailable{
            motionManager.startDeviceMotionUpdates()
        }else{
            print("No disponible")
            return
        }
    }
        func updateMotionData() {
            if let data = motionManager.deviceMotion {
                roll=data.attitude.roll
                pitch=data.attitude.pitch
                
               
            }
        }
        func stop() {
            motionManager.stopDeviceMotionUpdates()
        }
}
   
    
    


extension MotionDetector {
    func started() -> MotionDetector {
        start()
        return self
    }
}
