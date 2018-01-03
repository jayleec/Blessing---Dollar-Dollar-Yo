//
//  Face.swift
//  Blessing - Dollar Dollar Yo
//
//  Created by Jay on 24/12/2017.
//  Copyright © 2017 Jay. All rights reserved.
//

import Foundation
import ARKit

class Face {
    let index: Int
    let node: SCNNode
    var hidden: Bool {
        get{
            return node.opacity != 1
        }
    }
    
    private(set) var updated = Date()
    
    init(index: Int, node: SCNNode) {
        self.index = index
        self.node = node
    }
}
