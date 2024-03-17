//
//  File.swift
//  ESP 32 Watch WatchKit Extension
//
//  Created by Miquel Sitges Nicolau on 26/6/22.
//

import Foundation
import ClockKit
import SwiftUI

final class ShortcutComplicationProvider {
  func getShortcutComplication() -> CLKComplicationTemplate {
    return CLKComplicationTemplateGraphicCornerCircularView(ComplicationViewCircular())
  }
}
