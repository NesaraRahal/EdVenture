//
//  EdVentureWidgetExtensionBundle.swift
//  EdVentureWidgetExtension
//
//  Created by COBSCCOMP24.2P-053 on 2026-05-07.
//

import WidgetKit
import SwiftUI

@main
struct EdVentureWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        EdVentureHomeWidget()
        EdVentureWidgetExtensionLiveActivity()
    }
}
