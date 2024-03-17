//
//  File.swift
//  ESP 32 Watch WatchKit Extension
//
//  Created by Miquel Sitges Nicolau on 25/6/22.
//


import SwiftUIJoystick
import SwiftUI

struct Joystick: View {
    
    /// The monitor object to observe the user input on the Joystick in XY or Polar coordinates
    @ObservedObject public var joystickMonitor: JoystickMonitor
    /// The width or diameter in which the Joystick will report values
    ///  For example: 100 will provide 0-100, with (50,50) being the origin
    private let dragDiameter: CGFloat
    /// Can be `.rect` or `.circle`
    /// Rect will allow the user to access the four corners
    /// Circle will limit Joystick it's radius determined by `dragDiameter / 2`
    private let shape: JoystickShape
    
    public init(monitor: JoystickMonitor, width: CGFloat, shape: JoystickShape = .rect) {
        self.joystickMonitor = monitor
        self.dragDiameter = width
        self.shape = shape
    }
    
    public var body: some View {
        VStack{
            JoystickBuilder(
                monitor: self.joystickMonitor,
                width: self.dragDiameter,
                shape: .circle,
                background: {
                    // Example Background
                    Circle().fill(Color.yellow.opacity(0.7))
                     
                    
                    
                },
                foreground: {
                    // Example Thumb
                    Circle().fill(Color.red)
                },
                locksInPlace: false)
        }
    }
}

public extension CGFloat {
    var formattedString: String {
        String(format: "%.2f", self)
    }
}


struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        Joystick(monitor: JoystickMonitor.init(), width: 100)
    }
}
