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
    let frame: CGRect
    var origin: CGPoint {
        return frame.origin
    }
    var size: CGSize {
        return frame.size
    }
    let MaxDepth: Int = 10
    let maxPerLeaf: Int

    private var branches: [QuadTree<Element>]

    private let _depth: Int
    var depth: Int {
        if !branches.isEmpty {
            return branches.reduce(0, { max($0, $1.depth) })
        } else {
            return _depth
        }
    }

    private var _items: Set<Element>
    var items: Set<Element> {
        if !branches.isEmpty {
            return branches.reduce(Set(), { $0.union($1.items) })
        } else {
            return _items
        }
    }

    var count: Int {
        return items.count
    }

    public init(origin: CGPoint = .zero, size: CGSize, maxPerLeaf: Int = 10) {
        self.maxPerLeaf = maxPerLeaf
        frame = CGRect(origin: origin, size: size)
        _depth = 1
        _items = Set()
        branches = []
    }

    init(frame: CGRect,
         items: Set<Element> = Set(),
         branches: [QuadTree<Element>] = [],
         maxPerLeaf: Int,
         level: Int) {
        self.frame = frame
        self._items = items
        self.branches = branches
        self.maxPerLeaf = maxPerLeaf
        self._depth = level
    }

    // MARK: - Public

    public func inserting(_ element: Element) -> QuadTree {
        guard element.intersects(frame) else { return self }
        if !branches.isEmpty {
            return QuadTree(frame: frame,
                            branches: branches.map({ $0.inserting(element) }),
                            maxPerLeaf: maxPerLeaf,
                            level: _depth)
        } else if items.count >= maxPerLeaf, _depth < MaxDepth {
            let tlFr = CGRect(origin: origin, size: size / 2)
            let trFr = CGRect(origin: origin + CGVector(dx: size.width, dy: 0), size: size / 2)
            let blFr = CGRect(origin: origin + CGVector(dx: 0, dy: size.height), size: size / 2)
            let brFr = CGRect(origin: origin + size / 2, size: size / 2)
            let tl = QuadTree(frame: tlFr, maxPerLeaf: maxPerLeaf, level: _depth + 1)
            let tr = QuadTree(frame: trFr, maxPerLeaf: maxPerLeaf, level: _depth + 1)
            let bl = QuadTree(frame: blFr, maxPerLeaf: maxPerLeaf, level: _depth + 1)
            let br = QuadTree(frame: brFr, maxPerLeaf: maxPerLeaf, level: _depth + 1)
            var tree =  QuadTree(frame: frame,
                                 branches: [tl, tr, bl, br],
                                 maxPerLeaf: maxPerLeaf,
                                 level: _depth)
            for item in items + [element] {
                tree.insert(item)
            }
            return tree
        } else {
            let updated = _items.union([element])
            return QuadTree(frame: frame, items: updated, maxPerLeaf: maxPerLeaf, level: _depth)
        }
    }

    mutating public func insert(_ element: Element) {
        guard element.intersects(frame) else { return }
        self = inserting(element)
    }
}
