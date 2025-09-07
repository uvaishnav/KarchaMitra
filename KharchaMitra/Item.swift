//
//  Item.swift
//  KharchaMitra
//
//  Created by Vaishnav Uppalapati on 04/09/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
