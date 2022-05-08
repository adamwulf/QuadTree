//
//  QuadTree.swift
//  
//
//  Created by Adam Wulf on 5/8/22.
//

import Foundation
import CloudKit
import SwiftToolbox

public protocol Locatable: Hashable {
    func intersects(_ rect: CGRect) -> Bool
}

public struct QuadTree<Element: Locatable> {
    indirect enum QuadType {
        case leaf(_ items: [Element])
        case branch(_ tl: QuadTree, _ tr: QuadTree, _ bl: QuadTree, _ br: QuadTree)
    }

    private var data: QuadType
    let frame: CGRect
    var origin: CGPoint {
        return frame.origin
    }
    var size: CGSize {
        return frame.size
    }
    let MaxDepth: Int = 10
    let maxPerLeaf: Int
    private let level: Int
    var depth: Int {
        switch self.data {
        case .leaf:
            return level
        case .branch(let tl, let tr, let bl, let br):
            return max(tl.depth, tr.depth, bl.depth, br.depth)
        }
    }
    var items: Set<Element> {
        switch self.data {
        case .leaf(let items):
            return Set(items)
        case .branch(let tl, let tr, let bl, let br):
            return tl.items.union(tr.items).union(bl.items).union(br.items)
        }
    }

    var count: Int {
        return items.count
    }

    public init(origin: CGPoint = .zero, size: CGSize, maxPerLeaf: Int = 10) {
        self.maxPerLeaf = maxPerLeaf
        frame = CGRect(origin: origin, size: size)
        data = .leaf([])
        level = 1
    }

    init(frame: CGRect, data: QuadType, maxPerLeaf: Int, level: Int) {
        self.frame = frame
        self.data = data
        self.maxPerLeaf = maxPerLeaf
        self.level = level
    }

    // MARK: - Public

    public func inserting(_ element: Element) -> QuadTree {
        guard element.intersects(frame) else { return self }
        switch self.data {
        case .leaf(let items):
            guard
                items.count >= maxPerLeaf,
                level < MaxDepth
            else {
                let updated = items.contains(element) ? items : items + [element]
                return QuadTree(frame: frame, data: .leaf(updated), maxPerLeaf: maxPerLeaf, level: level)
            }
            let tlFr = CGRect(origin: origin, size: size / 2)
            let trFr = CGRect(origin: origin + CGVector(dx: size.width, dy: 0), size: size / 2)
            let blFr = CGRect(origin: origin + CGVector(dx: 0, dy: size.height), size: size / 2)
            let brFr = CGRect(origin: origin + size / 2, size: size / 2)
            let tl = QuadTree(frame: tlFr, data: .leaf([]), maxPerLeaf: maxPerLeaf, level: level + 1)
            let tr = QuadTree(frame: trFr, data: .leaf([]), maxPerLeaf: maxPerLeaf, level: level + 1)
            let bl = QuadTree(frame: blFr, data: .leaf([]), maxPerLeaf: maxPerLeaf, level: level + 1)
            let br = QuadTree(frame: brFr, data: .leaf([]), maxPerLeaf: maxPerLeaf, level: level + 1)
            var tree =  QuadTree(frame: frame,
                                 data: .branch(tl, tr, bl, br),
                                 maxPerLeaf: maxPerLeaf,
                                 level: level)
            for item in items + [element] {
                tree.insert(item)
            }
            return tree
        case .branch(let tl, let tr, let bl, let br):
            return QuadTree(frame: frame,
                            data: .branch(tl.inserting(element),
                                          tr.inserting(element),
                                          bl.inserting(element),
                                          br.inserting(element)),
                            maxPerLeaf: maxPerLeaf,
                            level: level)
        }
    }

    mutating public func insert(_ element: Element) {
        guard element.intersects(frame) else { return }
        self = inserting(element)
    }
}
