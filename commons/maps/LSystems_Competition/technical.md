# One tree is a grammar — two trees is a negotiation, and a forest is a war fought in slow motion

Grammar Lab demonstrated a single grammar producing a single tree. Growth demonstrated a single grammar shaped by its environment. Architecture demonstrated a single grammar producing different spatial artifacts through different interpreters. Every map so far treated the grammar as solitary — one axiom, one rule set, one output. The forest begins at two.

This map places multiple L-systems in a shared spatial substrate. Each tree has its own axiom, its own production rules, its own growth strategy. But they share light, soil, and space. The resources are finite. The canopy only has so much room. When branches collide, health drops. When one tree shades another, growth redirects. Ecology emerges not from a master plan but from local grammars pressing against each other's limits.

## The ForestCompetition Simulation

The `ForestCompetition` artifact manages multiple L-system instances growing simultaneously in a shared environment.

```gdscript
var trees: Array[Dictionary] = []
var light_map: PackedFloat32Array
var soil_map: PackedFloat32Array
var grid_width: int = 64
var grid_height: int = 64

func _ready() -> void:
    light_map.resize(grid_width * grid_height)
    soil_map.resize(grid_width * grid_height)
    light_map.fill(1.0)   # full sunlight everywhere initially
    soil_map.fill(1.0)     # full nutrients everywhere initially

    # Spawn 5-8 trees with different grammars
    for i in range(tree_count):
        trees.append({
            "axiom": _random_axiom(),
            "rules": _random_rules(),
            "position": _random_spawn_point(),
            "current_string": "",
            "generation": 0,
            "health": 1.0,
            "segments": []
        })
```

Each tree is an independent L-system with its own rule set. The light and soil maps are shared 2D grids — the same flat-array structure used by the Physarum trail map in the swarm intelligence sequence. Light starts at 1.0 everywhere. As trees grow upward, their canopy segments shadow the cells below. Soil starts at 1.0 everywhere. As trees consume nutrients for growth, the soil beneath and around them depletes.

## Resource Competition

Light competition operates through vertical projection. Each branch segment at height h casts a shadow onto the light map below it.

```gdscript
func update_light_map() -> void:
    light_map.fill(1.0)
    for tree in trees:
        for seg in tree["segments"]:
            var shadow_x: int = int(seg["position"].x / cell_size)
            var shadow_z: int = int(seg["position"].z / cell_size)
            if shadow_x >= 0 and shadow_x < grid_width and shadow_z >= 0 and shadow_z < grid_height:
                var idx: int = shadow_z * grid_width + shadow_x
                # Higher segments cast stronger shadows
                var shadow_strength: float = seg["position"].y / max_height
                light_map[idx] = minf(light_map[idx], 1.0 - shadow_strength * 0.8)
```

The tallest branches cast the deepest shade. A tree that grows tall first dominates the light field — its canopy reduces the light available to shorter neighbors. This creates a feedback loop: vertical growth earns more light, which funds more vertical growth. The first-mover advantage in height is the competitive dynamic that shapes real forest canopy structure.

Soil competition operates through proximity. Each tree draws nutrients from a radius around its base.

```gdscript
func update_soil_map(delta: float) -> void:
    for tree in trees:
        var base_x: int = int(tree["position"].x / cell_size)
        var base_z: int = int(tree["position"].z / cell_size)
        var uptake_radius: int = 3 + tree["generation"]

        for dx in range(-uptake_radius, uptake_radius + 1):
            for dz in range(-uptake_radius, uptake_radius + 1):
                var nx: int = base_x + dx
                var nz: int = base_z + dz
                if nx >= 0 and nx < grid_width and nz >= 0 and nz < grid_height:
                    var idx: int = nz * grid_width + nx
                    var dist: float = sqrt(float(dx * dx + dz * dz))
                    var uptake: float = nutrient_rate / (1.0 + dist) * delta
                    soil_map[idx] = maxf(0.0, soil_map[idx] - uptake)
```

Larger trees (higher generation count) have wider root systems — the uptake radius grows with the tree. Nutrient depletion falls off with distance from the base. Two trees planted close together deplete each other's soil faster than two trees planted far apart. The spacing between trees is not a design decision — it is an emergent consequence of nutrient competition.

## Growth Modulation

Each generation of growth, a tree consults the light and soil maps to determine whether it can expand.

```gdscript
func attempt_growth(tree: Dictionary) -> bool:
    var base_x: int = int(tree["position"].x / cell_size)
    var base_z: int = int(tree["position"].z / cell_size)

    if base_x < 0 or base_x >= grid_width or base_z < 0 or base_z >= grid_height:
        return false

    var idx: int = base_z * grid_width + base_x
    var available_light: float = light_map[idx]
    var available_soil: float = soil_map[idx]

    tree["health"] = (available_light + available_soil) / 2.0

    if tree["health"] < growth_threshold:
        return false

    # Grow one generation
    tree["current_string"] = derive(tree["current_string"], tree["rules"], 1)
    tree["generation"] += 1

    # Interpret with tropism — bend toward light
    var light_direction := _compute_light_gradient(base_x, base_z)
    tree["segments"] = interpret_with_tropism(
        tree["current_string"], tree["rules"],
        tree["position"], light_direction)
    return true
```

Health is the average of available light and available soil. Below a threshold, growth stalls — the tree stops rewriting its string. The grammar is still there, but the environment has denied it resources. This is the corridor constraint from Growth applied ecologically. The tree's genome (its rule set) does not change. Its phenotype (its realized form) depends on what the environment permits.

Tropism — the tendency to grow toward light — adjusts the turtle's heading during interpretation. The `light_direction` vector points toward the brightest cells in the light map. Branch segments curve toward available light, bending away from the canopy of taller neighbors. The grammar says "branch left." The tropism says "actually, light is to the right." The compromise between grammar and environment produces the characteristic asymmetric crowns of forest-edge trees.

## Collision and Pruning

When two trees' branch segments occupy the same grid cell, collision occurs.

```gdscript
func check_collisions() -> void:
    var occupied: Dictionary = {}
    for tree_idx in range(trees.size()):
        for seg in trees[tree_idx]["segments"]:
            var cell: Vector2i = Vector2i(
                int(seg["position"].x / cell_size),
                int(seg["position"].z / cell_size))
            if occupied.has(cell):
                var other_idx: int = occupied[cell]
                # Both trees take damage at collision point
                trees[tree_idx]["health"] -= collision_penalty
                trees[other_idx]["health"] -= collision_penalty
            else:
                occupied[cell] = tree_idx
```

Collision is mutual damage. Both trees lose health at the contact point. Over time, trees in crowded conditions lose enough health to stop growing, while trees with open space maintain high health and continue expanding. Niche partitioning emerges: trees space themselves to avoid collision, not through any avoidance rule in the grammar, but through the health penalty that makes crowding unsustainable.

## The Branching Coral

The `branching_coral` artifact demonstrates that the same competitive dynamics apply in a different kingdom. Marine branching organisms — corals, sponges, gorgonians — compete for current flow rather than sunlight. The grammar is adapted: wider branching angles, denser growth, stochastic variation tuned to underwater aesthetics. But the mechanism is identical. Multiple shoots grow from a shared base, each following its own L-system rules (`F -> FF[+F][-F][>F][<F]`), and the colony's morphology emerges from the interaction of independent growing tips competing for space and flow.

```gdscript
# From branching_coral.gd @identity:
# essence: F → FF[+F][-F][>F][<F] from multiple shoot origins
# with 3D pitch/roll branching
# critical_parameter: num_shoots — the number of independent growth starts
```

The coral proves that competition-as-growth-modifier is not specific to trees. It is a general principle: when multiple generative systems share a finite substrate, the substrate mediates between them, and form becomes relational rather than intrinsic. A coral growing alone looks nothing like the same coral growing in a dense colony. The grammar did not change. The social environment did.

## The Dark Sphere as Catalyst Station

At the south of the map, the `dark_sphere` marks a transition. In earlier maps it served as a visual anchor. Here it previews the branching catalyst — the tool that will let the learner seed their own trees into the world in LSystems_Living. The grammar stops being something the learner observes and becomes something they author. The competitive ecology they have witnessed will accept their contribution.

## From Observation to Authorship

The map's open field layout — height 1 throughout, with void clearings as ecological niches — gives the forest room to demonstrate its dynamics. The learner watches trees grow, compete, shade each other, specialize into vertical or horizontal strategies, and partition the available space. The ForestCompetition artifact runs the simulation continuously. Trees that find open niches thrive. Trees hemmed by neighbors stunt.

The sequence arc becomes visible in retrospect. Grammar Lab: one grammar, one tree. Growth: one grammar, shaped by walls. Architecture: one grammar, multiple interpretations. Competition: multiple grammars, one world. Each map added a dimension of complexity without replacing the fundamental mechanism. The production rules still fire. The turtle still walks. The string still rewrites. What changed is the social context — from solo performance to ensemble, from monologue to parliament.
