extends Node

var text = '''[center][font_size=28][b]Space Colonization Algorithm[/b][/font_size][/center]
[center][i]Organic Growth, Venation, Tree Structures[/i][/center]

**Space colonization grows branching structures toward attractors.**

**Algorithm:**
1. Place **attraction points** in space
2. Grow **nodes** toward nearest attractors
3. When node reaches attractor, **kill attractor**
4. Repeat until all attractors consumed

[hr]

[b]Code[/b]

[color=yellow][b]Implementation:[/b][/color]
[code]
var nodes = [Node.new(Vector3.ZERO)]  # Start at root
var attractors = []  # Target points

func grow_step():
    # Find closest node for each attractor
    var influences = {}
    for attr in attractors:
        var closest_node = find_closest_node(attr)
        if closest_node.position.distance_to(attr) < influence_distance:
            if closest_node not in influences:
                influences[closest_node] = []
            influences[closest_node].append(attr)

    # Grow nodes toward attractors
    for node in influences:
        var direction = Vector3.ZERO
        for attr in influences[node]:
            direction += (attr - node.position).normalized()
        direction = direction.normalized()

        var new_node = Node.new(node.position + direction * segment_length)
        new_node.parent = node
        nodes.append(new_node)

    # Kill reached attractors
    for attr in attractors:
        if closest_node.position.distance_to(attr) < kill_distance:
            attractors.erase(attr)
[/code]

**Result:** Organic tree-like structures, venation patterns.

[hr]

[b]Applications[/b]

- **Tree generation** (procedural plants)
- **Vein/root networks** (biological venation)
- **Lightning bolts** (electrical discharge)
- **River deltas** (erosion patterns)

[hr]

[b]Queer Space Colonization[/b]

**"Colonization" is loaded term** - imperial expansion, indigenous erasure.

**The algorithm colonizes empty space** - fills void with growth.

**Queer reading:** Attractors as desires, growth toward what pulls us, killing desire once reached (consumption).

**But also:** Organic non-hierarchical branching, decentralized growth, responding to environmental signals not internal blueprint.

**Tension:** Colonial language vs emergent non-authoritarian structure.

[hr]

[color=cyan][b]Summary:[/b][/color]
Space colonization: grow branches toward attractors, kill when reached. Organic venation, tree structures. Applications: plants, veins, lightning. Queer tension: colonial terminology vs decentralized emergent growth. Attractors as desires, growth toward what calls us.

'''
