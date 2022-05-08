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
}
