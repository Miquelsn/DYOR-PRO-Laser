//
//  BarChart.swift
//  ESP 32
//
//  Created by Miquel Sitges Nicolau on 24/5/22.
//

import SwiftUI

struct CeldaHistograma: View {
    var height:Double
    var width:Double
    var barColor: Color
    
    var body: some View {
        Rectangle()
            .fill(barColor)
            .frame(width: width, height: height,alignment: .bottom)
        
    }
}


struct Histograma: View{
    @ObservedObject  var esp32Manager: ESP32Manager
    var barColor: Color
    var body: some View {
        GeometryReader{geometry in
            VStack(alignment:.leading){
                HStack(alignment:.bottom,spacing: 0){
                    CeldaHistograma(height: geometry.size.height , width: 1, barColor: .blue.opacity(0))
                    ForEach(0..<esp32Manager.barridoMedidas.count, id: \.self){ i in
                        
                        CeldaHistograma(height: geometry.size.height/1200 * Double(esp32Manager.barridoMedidas[i]),width: geometry.size.width/Double(esp32Manager.barridoMedidas.count), barColor: barColor)
                    }
                }
                .scaleEffect(CGSize(width: -1.0, height: 1.0))

            }
        }
    }
}

struct BarChart_Previews: PreviewProvider {
    static var previews: some View {
        Histograma(esp32Manager: ESP32Manager(), barColor: .red)
            .previewInterfaceOrientation(.landscapeRight)
        
    }
    
}
