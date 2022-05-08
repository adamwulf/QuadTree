//
//  QuadTree.swift
//  
//
//  Created by Adam Wulf on 5/8/22.
//

import Foundation
import CloudKit
import SwiftToolbox

public protocol Locatable: Equatable {
    func intersects(_ rect: CGRect) -> Bool
}

public struct QuadTree<Element: Locatable> {
    indirect enum QuadType {
        case leaf(_ items: [Element])
        case branch(_ tl: QuadTree, _ tr: QuadTree, _ bl: QuadTree, _ br: QuadTree)
    }

    private var data: QuadType
    let frame: CGRect
    let maxPerLeaf: Int
    var depth: Int {
        switch self.data {
        case .leaf:
            return 1
        case .branch(let tl, let tr, let bl, let br):
            return 1 + max(tl.depth, tr.depth, bl.depth, br.depth)
        }
    }

    var count: Int {
        switch self.data {
        case .leaf(let items):
            return items.count
        case .branch(let tl, let tr, let bl, let br):
            return tl.count + tr.count + bl.count + br.count
        }
    }

    public init(origin: CGPoint = .zero, size: CGSize, maxPerLeaf: Int = 10) {
        self.maxPerLeaf = maxPerLeaf
        frame = CGRect(origin: origin, size: size)
        data = .leaf([])
    }

    init(frame: CGRect, data: QuadType, maxPerLeaf: Int) {
        self.frame = frame
        self.data = data
        self.maxPerLeaf = maxPerLeaf
    }

    public func inserting(_ element: Element) -> QuadTree {
        guard element.intersects(frame) else { return self }
        switch self.data {
        case .leaf(let items):
            return QuadTree(frame: frame, data: .leaf(items + [element]), maxPerLeaf: maxPerLeaf)
        case .branch(let tl, let tr, let bl, let br):
            return QuadTree(frame: frame,
                            data: .branch(tl.inserting(element),
                                          tr.inserting(element),
                                          bl.inserting(element),
                                          br.inserting(element)),
                            maxPerLeaf: maxPerLeaf)
        }
    }

    mutating public func insert(_ element: Element) {
        guard element.intersects(frame) else { return }
        switch self.data {
        case .leaf(let items):
            data = .leaf(items + [element])
        case .branch(let tl, let tr, let bl, let br):
            data = .branch(tl.inserting(element),
                           tr.inserting(element),
                           bl.inserting(element),
                           br.inserting(element))
        }
    }
}
