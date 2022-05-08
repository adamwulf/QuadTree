//
//  File.swift
//  
//
//  Created by Adam Wulf on 5/8/22.
//

import Foundation
import QuadTree

fileprivate var nextName = 1

struct Item: Locatable {
    let name: Int
    let frame: CGRect

    init(frame: CGRect) {
        self.name = nextName
        self.frame = frame
        nextName += 1
    }
}
