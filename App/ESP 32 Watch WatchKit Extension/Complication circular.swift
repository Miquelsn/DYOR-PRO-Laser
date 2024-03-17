//
//  Complication circular.swift
//  ESP 32 Watch WatchKit Extension
//
//  Created by Miquel Sitges Nicolau on 25/6/22.
//

import SwiftUI
import ClockKit

struct ComplicationViewCircular: View {
    var body: some View {
        ZStack{
           
//            Image("robot")
//                .renderingMode(.template)
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .foregroundColor(.yellow)
//                .complicationForeground()
            Text("Hola")
      }
     
    }
}
struct ComplicationViewCornerCircular: View {
  // 2


  var body: some View {
    // 3
    ZStack {
      Circle()
        .fill(Color.red)
    
        .foregroundColor(Color.black)
     Text("abc")
  
    }
  }
}

struct Complication_circular_Previews: PreviewProvider {
    static var previews: some View {
        Group {
                    
            CLKComplicationTemplateGraphicCornerCircularView(ComplicationViewCircular()).previewContext()
            
            CLKComplicationTemplateGraphicCornerCircularView(
              ComplicationViewCornerCircular()).previewContext(faceColor: .red)
                }
    }
}
