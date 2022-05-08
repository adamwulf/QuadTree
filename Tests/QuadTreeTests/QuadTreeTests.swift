//
//  QuadTreeTests.swift
//
//
//  Created by Adam Wulf on 5/8/22.
//

import XCTest
@testable import QuadTree
import SwiftToolbox

extension CGRect: Locatable { }

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

    func testInsertMax() throws {
        var quadtree: QuadTree<CGRect> = QuadTree(size: CGSize(100, 100))

        for _ in 0..<20 {
            quadtree.insert(CGRect(x: 10, y: 10, width: 10, height: 10))
        }

        XCTAssertEqual(quadtree.count, 20)
        XCTAssertGreaterThan(quadtree.depth, 1)
    }
}
