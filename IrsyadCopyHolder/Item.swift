//
//  Item.swift
//  IrsyadCopyHolder
//
//  Created by Muh Irsyad Ashari on 7/15/25.
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
