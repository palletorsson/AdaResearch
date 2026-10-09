# PG Space Colonization — Technical

The space colonisation algorithm grows a branching structure by letting branch tips reach toward scattered attractor points. Each tip consumes attractors within a kill radius, and new tips sprout from the growing branches.

```gdscript
class_name SpaceColonizer extends Node3D

@export var attractor_count: int = 200
@export var attraction_radius: float = 3.0
@export var kill_radius: float = 0.5
@export var step_length: float = 0.2

var attractors: Array = []
var nodes: Array = []  # list of {position, parent_index}

func _ready() -> void:
    for i in range(attractor_count):
        attractors.append(random_point_in_bounds())
    nodes.append({"position": Vector3.ZERO, "parent_index": -1})

func grow_step() -> bool:
    var tip_influences: Dictionary = {}
    var nodes_to_kill_attractors: Array = []
    for i in range(attractors.size() - 1, -1, -1):
        var a: Vector3 = attractors[i]
        var best_tip: int = -1
        var best_dist: float = attraction_radius
        for j in range(nodes.size()):
            var d := a.distance_to(nodes[j].position)
            if d < best_dist:
                best_dist = d; best_tip = j
            if d < kill_radius:
                attractors.remove_at(i); break
        if best_tip != -1:
            tip_influences.get_or_add(best_tip, Vector3.ZERO)
            tip_influences[best_tip] += (a - nodes[best_tip].position).normalized()
    if tip_influences.is_empty():
        return false  # terminated
    for tip_index in tip_influences:
        var direction = tip_influences[tip_index].normalized()
        var new_pos: Vector3 = nodes[tip_index].position + direction * step_length
        nodes.append({"position": new_pos, "parent_index": tip_index})
    return true
```

## Complexity

Each step is O(A·N) where A is the attractor count and N is the branch node count. A grows shorter as attractors are consumed; N grows longer as branches extend. The product tends toward a peak in the middle of the growth and decreases as the algorithm terminates.

Spatial indexing accelerates the inner loop. A KD-tree reduces the nearest-tip query from O(N) to O(log N), which matters when N reaches hundreds of nodes. The map's tree scales use 200 attractors and produce a few hundred nodes; naive O(A·N) runs at interactive rates.

## Termination

The algorithm terminates when no attractor is within attraction_radius of any tip. Bounded attractor regions produce bounded trees; unbounded regions produce trees that keep growing. The map uses a bounded region so the tree finishes in a predictable number of steps.

## Mesh Generation

Converting the branch skeleton to a mesh is a separate step. Generalised cylinders — a tube whose radius varies along the branch — are the standard approach. Radius can be a function of child-branch count (thicker at the trunk, thinner at the leaves) or a function of accumulated flow from the root.

Within the sequence, Space_Colonization grows a tree without an L-system grammar. The environment's geometry — where the attractors happen to be — determines the tree's shape. PG_Percolation_Network will next turn to connectivity as a different generative phenomenon.

## Initial Node Choice

The root node's position determines where the tree begins. A single root at the origin produces a single trunk. Multiple roots produce a forest. A root high above the attractor cloud produces a tree that grows downward; below it, one that grows upward. The map's default places the root at the bottom of the attractor cloud and lets the tree grow toward the sky.

## Attractor Distribution

Uniform random attractors produce uniform trees. Clustered attractors produce trees that reach into the clusters selectively. Structured attractors — for instance, attractors placed on the surface of a target shape — produce trees that grow into the shape.

```gdscript
func attractors_on_surface(mesh: ArrayMesh, count: int) -> Array:
    var attractors: Array = []
    for _i in range(count):
        attractors.append(random_point_on_surface(mesh))
    return attractors
```

This technique generates trees that grow to fit a specific envelope — useful for populating a volume with convincing vegetation.

## Runciman's Original

Runciman and colleagues introduced the algorithm in 2007 for tree modeling. The original publication parameterised attraction by kd (the kill distance) and di (the radius of influence), which the map's kill_radius and attraction_radius preserve. Setting di equal to kd makes the algorithm produce linear branches; setting di much larger than kd produces dense bushy branching.

## Variants

Weighted attractors produce trees that prefer specific directions. Dynamic attractors that move or disappear produce trees that adapt to changing environments. Multi-resource attractors that represent different growth factors (light, water, nutrients) produce trees whose branching reflects ecological priorities.

## Final Mesh

Converting the branch skeleton to a mesh is a separate step after growth terminates. Simple cylinders capture the basic look; generalised cylinders with tapered radius look more organic; mesh refinement with normal smoothing produces production-quality output at higher rendering cost.
