# QuadTree

A very simple implementation of a QuadTree datastructure.

Using a sample `Item` type:

```
struct Item: Locatable {
    let name: String
    let frame: CGRect

    init(name: String frame: CGRect) {
        self.name = name
        self.frame = frame
    }
}
```

These items can be inserted and queried in the tree:

```
var quadtree: QuadTree<Item> = QuadTree(size: CGSize(1000, 1000))
quadtree.insert(Item(name: "Fumble", frame: CGRect(x: 100, y: 100, width: 20, height: 40))

// return all elements that intersect the input rect
let elements = quadtree.elements(in: CGRect(x: 80, y: 80, width: 30, height: 30))

elements.count // 1
elements.first?.name // "Fumble"
```
