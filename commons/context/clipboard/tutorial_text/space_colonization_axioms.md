**Space Colonization Algorithm**
Organic Growth, Venation, Tree Structures

**Space colonization grows branching structures toward attractors.**

**Algorithm:**
1. Place **attraction points** in space
2. Grow **nodes** toward nearest attractors
3. When node reaches attractor, **kill attractor**
4. Repeat until all attractors consumed

---

## Code

**Implementation:**

```
var nodes = [Node.new(Vector3.ZERO)]  # Start at root
var attractors = []  # Target points

func grow_step():
    # Find closest node for each attractor
    var influences = {}
    for attr in attractors:
        var closest_node = find_closest_node(attr)
        if closest_node.position.distance_to(attr) < influence_distance:
            if closest_node not in influences:
                influences = []
            influences.append(attr)

    # Grow nodes toward attractors
    for node in influences:
        var direction = Vector3.ZERO
        for attr in influences:
            direction += (attr - node.position).normalized()
        direction = direction.normalized()

        var new_node = Node.new(node.position + direction * segment_length)
        new_node.parent = node
        nodes.append(new_node)

    # Kill reached attractors
    for attr in attractors:
        if closest_node.position.distance_to(attr) < kill_distance:
            attractors.erase(attr)
```

**Result:** Organic tree-like structures, venation patterns.

---

## Applications

- **Tree generation** (procedural plants)
- **Vein/root networks** (biological venation)
- **Lightning bolts** (electrical discharge)
- **River deltas** (erosion patterns)

---

## Queer Space Colonization

**