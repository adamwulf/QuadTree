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
    var frame: CGRect { get }
}

public struct QuadTree<Element: Locatable> {
    // MARK: - Constants

    let minDim: CGFloat
    public let maxPerLeaf: Int

    // MARK: - Size

    public let frame: CGRect
    public var origin: CGPoint {
        return frame.origin
    }
    public var size: CGSize {
        return frame.size
    }

    // MARK: - Private Properties

    private var isTopLevel: Bool
    private var frameCache: [Element: CGRect]
    private var branches: [QuadTree<Element>]
    private var _elements: Set<Element>

    // MARK: - Computed Properties

    public let level: Int
    public var depth: Int {
        if !branches.isEmpty {
            let branchDepth = branches.reduce(0, { max($0, $1.depth) })
            if level <= 0 {
                return branchDepth + 1
            } else {
                return branchDepth
            }
        } else {
            return level
        }
    }

    public var elements: Set<Element> {
        if !branches.isEmpty {
            return branches.reduce(Set(), { $0.union($1.elements) }).union(_elements)
        } else {
            return _elements
        }
    }

    public var count: Int {
        return elements.count
    }

    public init(origin: CGPoint = .zero, size: CGSize, maxPerLeaf: Int = 10, minDim: CGFloat = 10) {
        self.maxPerLeaf = maxPerLeaf
        self.minDim = minDim
        frame = CGRect(origin: origin, size: size)
        level = 1
        _elements = Set()
        branches = []
        frameCache = [:]
        isTopLevel = true
    }

    init(frame: CGRect,
         branches: [QuadTree<Element>] = [],
         maxPerLeaf: Int,
         minDim: CGFloat = 10,
         level: Int) {
        self.frame = frame
        self._elements = []
        self.branches = branches
        self.maxPerLeaf = maxPerLeaf
        self.minDim = minDim
        self.level = level
        self.frameCache = [:]
        self.isTopLevel = false
    }

    // MARK: - Public

    /// Breadth first walk of the quad tree, until `block` returns false
    public func walk(_ block: (QuadTree) -> Bool) {
        var nodes: [QuadTree] = [self]
        while !nodes.isEmpty {
            let node = nodes.removeFirst()
            if !block(node) {
                break
            }
            nodes.append(contentsOf: node.branches)
        }
    }

    mutating public func insert(_ element: Element) {
        let eleFrame = element.frame
        insert(element, frame: eleFrame)
    }

    public func elements(in rect: CGRect) -> Set<Element> {
        guard frame.intersects(rect) else { return Set() }
        let myElements = _elements.filter({
            guard let frame = frameCache[$0] else { return false }
            return frame.intersects(rect)
        })
        let kidElements = branches.map({ $0.elements(in:rect) })
        return kidElements.reduce(myElements, { $0.union($1) })
    }

    // MARK: - Helper

    mutating internal func insert(_ element: Element, frame eleFrame: CGRect) {
        guard eleFrame.intersects(frame) else {
            guard frame != .null, frame != .infinite else { return }
            if isTopLevel {
                // we should grow our quad tree to encompass this element
                let tl = self
                let tr = QuadTree(frame: tl.frame + CGVector(tl.size.width, 0),
                                  branches: [],
                                  maxPerLeaf: maxPerLeaf,
                                  minDim: minDim,
                                  level: level)
                let bl = QuadTree(frame: tl.frame + CGVector(0, tl.size.height),
                                  branches: [],
                                  maxPerLeaf: maxPerLeaf,
                                  minDim: minDim,
                                  level: level)
                let br = QuadTree(frame: tl.frame + CGVector(tl.size.width, tl.size.height),
                                  branches: [],
                                  maxPerLeaf: maxPerLeaf,
                                  minDim: minDim,
                                  level: level)
                var newSelf = QuadTree(frame: frame + size, branches: [tl, tr, bl, br], maxPerLeaf: maxPerLeaf, minDim: minDim, level: level - 1)
                newSelf.isTopLevel = true
                isTopLevel = false
                self = newSelf
                self.insert(element)
            }
            return
        }
        if !branches.isEmpty {
            if eleFrame.contains(frame) {
                _elements.formUnion([element])
                frameCache[element] = eleFrame
            } else {
                for i in 0..<branches.count {
                    guard branches[i].frame.intersects(eleFrame) else { continue }
                    branches[i].insert(element, frame: eleFrame)
                }
            }
        } else if elements.count >= maxPerLeaf, size.min > minDim {
            let tlFr = CGRect(origin: origin, size: size / 2)
            let trFr = CGRect(origin: origin + CGVector(dx: size.width / 2, dy: 0), size: size / 2)
            let blFr = CGRect(origin: origin + CGVector(dx: 0, dy: size.height / 2), size: size / 2)
            let brFr = CGRect(origin: origin + size / 2, size: size / 2)
            let tl = QuadTree(frame: tlFr, maxPerLeaf: maxPerLeaf, level: level + 1)
            let tr = QuadTree(frame: trFr, maxPerLeaf: maxPerLeaf, level: level + 1)
            let bl = QuadTree(frame: blFr, maxPerLeaf: maxPerLeaf, level: level + 1)
            let br = QuadTree(frame: brFr, maxPerLeaf: maxPerLeaf, level: level + 1)
            var tree =  QuadTree(frame: frame,
                                 branches: [tl, tr, bl, br],
                                 maxPerLeaf: maxPerLeaf,
                                 level: level)
            for item in elements + [element] {
                let itemFrame = frameCache[item] ?? item.frame
                tree.insert(item, frame: itemFrame)
            }
            self = tree
        } else {
            _elements.formUnion([element])
            frameCache[element] = eleFrame
        }
    }
}
