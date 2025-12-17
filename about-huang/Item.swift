//
//  Item.swift
//  about-huang
//
//  Created by 皮卡 on 2025/12/17.
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
