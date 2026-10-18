//  AndoWidgetBundle.swift — Widget extension entry point

import WidgetKit
import SwiftUI

@main
struct AndoWidgetBundle: WidgetBundle {
    var body: some Widget {
        AndoBalanceWidget()
        AndoAccessoryWidget()
        AndoRoomWidget()
    }
}
