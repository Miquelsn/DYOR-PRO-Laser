//
//  Acelerometro.swift
//  ESP 32
//
//  Created by Miquel Sitges Nicolau on 31/5/22.
//

import CoreMotion
import  UIKit
import SwiftUI


class MotionDetector:ObservableObject{
    
    private let motionManager = CMMotionManager()
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    
   
    private var currentOrientation: UIDeviceOrientation = .landscapeLeft
    private var orientationObserver: NSObjectProtocol? = nil
    let notification = UIDevice.orientationDidChangeNotification
    
    func start(){
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver=NotificationCenter.default.addObserver(forName: notification, object: nil, queue: .main){ [weak self] _ in
            switch UIDevice.current.orientation {
            case .faceUp, .faceDown, .unknown:
                break
            default:
                self?.currentOrientation = UIDevice.current.orientation
            }
        }
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates()
        } else {
            
        }
    }
    func updateMotionData() {
        if let data = motionManager.deviceMotion {
            (roll, pitch) = currentOrientation.adjustedRollAndPitch(data.attitude)
        }
    }
    func stop() {
        motionManager.stopDeviceMotionUpdates()
        
        if let orientationObserver = orientationObserver {
            NotificationCenter.default.removeObserver(orientationObserver, name: notification, object: nil)
        }
        orientationObserver = nil
    }
    
    deinit {
        stop()
    }
    
}


extension MotionDetector {
    func started() -> MotionDetector {
        start()
        return self
    }
}

extension UIDeviceOrientation {
    func adjustedRollAndPitch(_ attitude: CMAttitude) -> (roll: Double, pitch: Double) {
        switch self {
        case .unknown, .faceUp, .faceDown:
            return (attitude.roll, -attitude.pitch)
        case .landscapeLeft:
            return (attitude.pitch, -attitude.roll)
        case .portrait:
            return (attitude.roll, attitude.pitch)
        case .portraitUpsideDown:
            return (-attitude.roll, -attitude.pitch)
        case .landscapeRight:
            return (-attitude.pitch, attitude.roll)
        @unknown default:
            return (attitude.roll, attitude.pitch)
        }
    }
}
