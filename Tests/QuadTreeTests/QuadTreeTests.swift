//
//  QuadTreeTests.swift
//
//
//  Created by Adam Wulf on 5/8/22.
//

import XCTest
@testable import QuadTree
import SwiftToolbox

extension CGRect: Locatable {
    public var frame: CGRect {
        return self
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin.x)
        hasher.combine(origin.y)
        hasher.combine(size.width)
        hasher.combine(size.height)
    }
}

final class QuadTreeTests: XCTestCase {
    func testInsert() throws {
        var quadtree: QuadTree<CGRect> = QuadTree(size: CGSize(100, 100))

        quadtree.insert(CGRect(x: 10, y: 10, width: 10, height: 10))

        XCTAssertEqual(quadtree.count, 1)
        XCTAssertEqual(quadtree.frame, CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    func testFailedInsert() throws {
        var quadtree: QuadTree<CGRect> = QuadTree(size: CGSize(100, 100))

        quadtree.insert(CGRect(x: 110, y: 10, width: 10, height: 10))

        XCTAssertEqual(quadtree.count, 0)
        XCTAssertEqual(quadtree.frame, CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    func testPreventDuplicates() throws {
        var quadtree: QuadTree<CGRect> = QuadTree(size: CGSize(100, 100))

        for _ in 0..<20 {
            quadtree.insert(CGRect(x: 10, y: 10, width: 10, height: 10))
        }

        XCTAssertEqual(quadtree.count, 1)
        XCTAssertEqual(quadtree.depth, 1)
    }

    func testMultipleLevels() throws {
        var quadtree: QuadTree<CGRect> = QuadTree(size: CGSize(1000, 1000))

        for _ in 0..<200 {
            quadtree.insert(CGRect(x: CGFloat.random(in: -90..<990),
                                   y: CGFloat.random(in: -90..<990),
                                   width: CGFloat.random(in: 0..<100),
                                   height: CGFloat.random(in: 0..<100)))
        }

        XCTAssertGreaterThan(quadtree.count, 50)
        XCTAssertGreaterThan(quadtree.depth, 1)
    }

    func testFullyContains() throws {
        var quadtree: QuadTree<CGRect> = QuadTree(size: CGSize(100, 100))

        for _ in 0..<20 {
            quadtree.insert(CGRect(x: -100 + CGFloat.random(in: -10..<10),
                                   y: -100 + CGFloat.random(in: -10..<10),
                                   width: 300 + CGFloat.random(in: -10..<10),
                                   height: 300 + CGFloat.random(in: -10..<10)))
        }

        XCTAssertEqual(quadtree.count, 20)
        XCTAssertEqual(quadtree.depth, 2)

        quadtree.walk { node in
            guard !node.elements.isEmpty else { return true }
            XCTAssertGreaterThan(node.elements.count, node.maxPerLeaf)
            return true
        }
    }

    func testMaxDepth() throws {
        var quadtree: QuadTree<Item> = QuadTree(size: CGSize(100, 100))

        for _ in 0..<200 {
            let item = Item(frame: CGRect(x: CGFloat.random(in: 0..<10),
                                          y: CGFloat.random(in: 0..<10),
                                          width: CGFloat.random(in: 0..<10),
                                          height: CGFloat.random(in: 0..<10)))
            quadtree.insert(item)
        }

        XCTAssertEqual(quadtree.count, 200)
        XCTAssertEqual(quadtree.depth, 5)
    }

    func testWalk() throws {
        var quadtree: QuadTree<Item> = QuadTree(size: CGSize(100, 100))

        for _ in 0..<200 {
            let item = Item(frame: CGRect(x: CGFloat.random(in: 0..<10),
                                          y: CGFloat.random(in: 0..<10),
                                          width: CGFloat.random(in: 0..<10),
                                          height: CGFloat.random(in: 0..<10)))
            quadtree.insert(item)
        }

        var didReturnFalse = false
        quadtree.walk { tree in
            guard !didReturnFalse else { XCTFail(); return true }
            let ret = tree.level != 4
            if !ret {
                didReturnFalse = true
            }
            return ret
        }
    }

    func testFindInRect() throws {
        var quadtree: QuadTree<CGRect> = QuadTree(size: CGSize(1000, 1000))

        for _ in 0..<2000 {
            quadtree.insert(CGRect(x: CGFloat.random(in: -90..<990),
                                   y: CGFloat.random(in: -90..<990),
                                   width: CGFloat.random(in: 0..<100),
                                   height: CGFloat.random(in: 0..<100)))
        }

        let elements = quadtree.elements(in: CGRect(x: 300, y: 300, width: 50, height: 50))
        XCTAssertFalse(elements.isEmpty)
    }

    func testExpandTree() throws {
        var quadtree: QuadTree<CGRect> = QuadTree(size: CGSize(1000, 1000), allowsExpansion: true)
        quadtree.insert(CGRect(x: 1750, y: 1750, width: 100, height: 100))

        XCTAssertEqual(quadtree.depth, 2)
        XCTAssertEqual(quadtree.count, 1)
        XCTAssertEqual(quadtree.frame, CGRect(origin: .zero, size: CGSize(2000, 2000)))

        let found = quadtree.elements(in: CGRect(x: 1000, y: 1000, width: 1000, height: 1000))
        XCTAssertEqual(found.count, 1)
    }

    func testExpandTreeTwice() throws {
        var quadtree: QuadTree<CGRect> = QuadTree(size: CGSize(1000, 1000), allowsExpansion: true)
        quadtree.insert(CGRect(x: 2750, y: 2750, width: 100, height: 100))

        XCTAssertEqual(quadtree.depth, 3)
        XCTAssertEqual(quadtree.count, 1)
        XCTAssertEqual(quadtree.frame, CGRect(origin: .zero, size: CGSize(4000, 4000)))

        let found = quadtree.elements(in: CGRect(x: 2000, y: 2000, width: 1000, height: 1000))
        XCTAssertEqual(found.count, 1)
    }

    func testExpandToLeft() throws {
        var quadtree: QuadTree<CGRect> = QuadTree(size: CGSize(1000, 1000), allowsExpansion: true)
        quadtree.insert(CGRect(x: -1750, y: -1750, width: 100, height: 100))

        XCTAssertEqual(quadtree.depth, 3)
        XCTAssertEqual(quadtree.count, 1)
        XCTAssertEqual(quadtree.frame, CGRect(origin: CGPoint(-3000, -3000), size: CGSize(4000, 4000)))

        let found = quadtree.elements(in: CGRect(x: -2000, y: -2000, width: 1000, height: 1000))
        XCTAssertEqual(found.count, 1)
    }
}
