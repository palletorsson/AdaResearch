import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

adds = {
'PG_Genetic_Evolution': """

## Encoding Strategies

Genome encoding shapes which solutions the evolution can explore. Real-valued encodings work well for continuous parameters such as joint angles; integer encodings suit discrete choices such as limb count; tree encodings (genetic programming proper) support whole program structures as genomes.

```gdscript
class_name Genome

var real_values: Array = []     # for real-valued params
var integer_values: Array = []  # for discrete choices
var behavior_tree: Dictionary = {}  # tree structure for strategy

func decode() -> CreatureSpec:
    return CreatureSpec.new(real_values, integer_values, behavior_tree)

func random_encoding() -> void:
    for i in range(16):
        real_values.append(randf_range(-1.0, 1.0))
        integer_values.append(randi() % 4)
    behavior_tree = random_tree(3)
```

The map uses a flat real-valued encoding for simplicity; production applications often mix encodings within a single genome.

## Novelty Search

Fitness-based selection rewards whatever currently works best. Novelty search rewards whatever is most different from past individuals. It avoids premature convergence by directly optimising for exploration. Kenneth Stanley's NEAT algorithm combines novelty search with structural mutation for neural architecture search.

## Parallel Fitness Evaluation

Evolutionary algorithms are embarrassingly parallel at the population level. Each individual's fitness evaluation is independent, so a population of P individuals evaluates in O(trial_time) wall clock with P cores and O(P · trial_time) with one core. The map runs serial on the game's main thread for pedagogical legibility; a real application would evaluate a population in parallel across CPU cores or GPU workers.
""",
'PG_Space_Colonization': """

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
""",
'PG_Percolation_Network': """

## Universality

The critical exponents of percolation are universal: they depend only on the lattice dimension, not on the specific lattice geometry. This is a surprising and powerful result that connects percolation to critical phenomena in physics more broadly. The same universal exponents describe phase transitions in ferromagnets, the liquid-gas transition in fluids, and the connectivity of large networks.

## Fractal Dimension of the Incipient Cluster

At exactly the critical threshold, the largest cluster is a fractal. Its mass M scales with the linear size L as M ~ L^(df), where df is the fractal dimension of the incipient cluster. For 2D site percolation, df = 91/48 ≈ 1.896. For 3D, df ≈ 2.52. These values are computed from the lattice's critical exponents.

```gdscript
func estimate_fractal_dimension(cluster: Array, sample_radii: Array) -> float:
    var points: Array = []
    for r in sample_radii:
        var count := 0
        for cell in cluster:
            if cell.distance_to(Vector2.ZERO) < r:
                count += 1
        points.append([log(r), log(count)])
    return linear_fit_slope(points)
```

The map's analysis panel estimates the fractal dimension at the current probability; near p_c the estimate converges to the theoretical value.

## Applications

Percolation theory underlies several practical problems. Fluid flow through porous rock is modeled as bond percolation where bonds are pore-connecting throats. Epidemic spread in a population is site percolation where sites are susceptible individuals. Electrical conductivity through a random mixture of conducting and insulating grains follows bond percolation with a conductivity-weighted critical exponent.

## Algorithm Variants

Invasion percolation grows a connected cluster by always adding the cell with the smallest random value. It produces self-organised critical clusters without tuning p. Explosive percolation uses an Achlioptas process to delay percolation by preferring to add bonds that keep clusters small, producing a sharper transition.
""",
'PG_Branching_Growth': """

## Parameter Space

The rule-based branch is controlled by three parameters: branching angle, length scale factor, and maximum depth. Each parameter has a visible effect. Small angles produce narrow elongated trees; large angles produce flat wide ones. Length scales near 1.0 produce trees where all branches have similar length; scales near 0.5 produce trees where distal branches are much shorter.

The noise-driven growth is controlled by the noise scale (how far apart the features are), the step size (how far each growth step moves), and the noise type (Perlin, Simplex, worley, etc.). Different noise types produce different grain structures.

```gdscript
func switch_noise_type(noise: FastNoiseLite, new_type: int) -> void:
    noise.noise_type = new_type
    # Clear any cached samples
    path_cache.clear()
```

## L-System Comparison

L-systems — another rule-based growth strategy — are more controlled than the map's rule-based branch. An L-system has an alphabet and rewrite rules; each generation rewrites every symbol. Turtle interpretation then renders the resulting string as geometry. L-systems produce more variety (stochastic rules, context-sensitive rules, parametric symbols) at the cost of complexity.

The map's rule-based branch is effectively a deterministic bracketed L-system with a single rule: F → F[+F][-F]. The mapping is exact, and the map's side panel names the correspondence.

## Renderable Limits

Both strategies hit practical limits at deep iteration. The rule-based branch produces 2^D segments, exceeding Godot's per-frame draw budget at D=14 or so. Noise-driven growth produces one segment per step, so step count is the limit — a few thousand segments per path at interactive rates.

Mesh simplification helps: once a structure is grown, the geometry can be converted to a reduced mesh with vertex welding and edge collapse, dropping the effective primitive count by 10× or more.

## Self-Avoidance

Adding self-avoidance to either strategy requires a spatial data structure. A uniform grid with bucket indices supports O(1) queries for "any branch within radius R" given the grid's cell size is O(R). The map's implementations skip self-avoidance for simplicity; visible overlaps are part of the output's organic character.
""",
'PG_Caves_Mazes': """

## CA Rule Exploration

The cellular automaton cave generator is parameterised by two numbers: the birth threshold (how many neighbours cause an empty cell to become wall) and the survival threshold (how many neighbours keep a wall cell as wall). Different thresholds produce different cave characters.

```gdscript
class_name CAParameters extends Resource

@export var birth_threshold: int = 5
@export var survival_threshold: int = 4
@export var initial_fill: float = 0.45
@export var iterations: int = 5

func rule_name() -> String:
    return "B%d/S%d" % [birth_threshold, survival_threshold]
```

The rule "B5/S4" (born at 5+, survives at 4+) is the map's default. "B678/S345678" produces more spherical caves; "B5678/S45678" is another common choice.

## Maze Algorithm Variants

Beyond recursive backtracking and Kruskal's, several other maze algorithms produce distinct textures.

```gdscript
# Prim's-based maze: grows from a single seed
func prims_maze(start: Vector2i) -> void:
    var frontier: Array = [start]
    visited[start] = true
    while not frontier.is_empty():
        var cell = frontier[randi() % frontier.size()]
        frontier.erase(cell)
        var unvisited_neighbours = get_unvisited_neighbours(cell)
        if unvisited_neighbours.is_empty():
            continue
        var next = unvisited_neighbours[randi() % unvisited_neighbours.size()]
        carve_wall_between(cell, next)
        visited[next] = true
        frontier.append(next)
```

Prim's produces mazes with many short passages. Wilson's algorithm produces uniformly random spanning trees — mazes that look more random than recursive backtracking's characteristic zigzag. Eller's algorithm generates mazes row by row in O(W) space, useful for very large mazes where the full grid cannot fit in memory.

## Postprocessing

Raw CA caves often have small disconnected regions. A post-processing pass finds the largest connected region and fills in the others, guaranteeing a navigable space. Mazes often benefit from "braiding" — removing some dead ends to create loops, making the maze feel less punitive to navigate.

```gdscript
func braid(maze: Array, loop_probability: float = 0.3) -> Array:
    var dead_ends := find_dead_ends(maze)
    for cell in dead_ends:
        if randf() < loop_probability:
            var wall_to_remove := random_wall_around(cell)
            if wall_to_remove:
                maze[wall_to_remove.y][wall_to_remove.x] = false
    return maze
```

## Hybrid Approaches

Combining strategies produces interesting hybrid spaces. A CA cave with a maze embedded in one region combines organic and engineered aesthetics. The map's two sides share a central wall to stage the contrast cleanly, but production applications often blend them spatially.
""",
'PG_Sculpted_Forms': """

## Stability and Settling

The mound grows by dropping cubes that settle under gravity. The settling time depends on the height fallen and the friction of the cubes. At fast drop rates, cubes pile on each other before the lower ones have fully settled, producing unstable piles that sometimes collapse spectacularly.

```gdscript
@export var drop_rate: float = 5.0  # cubes per second
@export var settling_time: float = 0.5  # grace period before next drop

var time_since_last_settled: float = 0.0

func _process(delta: float) -> void:
    time_since_last_settled += delta
    if all_recent_cubes_settled() and time_since_last_settled > settling_time:
        drop_cube()
        time_since_last_settled = 0.0
```

The map uses a slower drop rate to ensure the mound is stable for observation. Faster rates produce more dynamic piles at the cost of occasional collapses.

## Dome Tessellation

The dome's tessellation affects both rendering cost and visual quality. A geodesic dome subdivides an icosahedron recursively, producing a nearly-uniform distribution of triangles. A latitudinal tessellation (like the map's implementation) produces more triangles near the equator and fewer near the poles, which is simpler to generate but less efficient at equivalent visual quality.

```gdscript
func geodesic_subdivide(mesh: ArrayMesh, depth: int) -> ArrayMesh:
    var result := mesh.duplicate()
    for _i in range(depth):
        var vertices = result.surface_get_arrays(0)[0]
        var indices = result.surface_get_arrays(0)[-1]
        var new_vertices: PackedVector3Array = []
        var new_indices: PackedInt32Array = []
        # Subdivide each triangle into four by midpoint insertion
        for t in range(0, indices.size(), 3):
            var a = vertices[indices[t]]
            var b = vertices[indices[t + 1]]
            var c = vertices[indices[t + 2]]
            # Compute midpoints, project to sphere surface
            var ab = ((a + b) * 0.5).normalized()
            var bc = ((b + c) * 0.5).normalized()
            var ca = ((c + a) * 0.5).normalized()
            # Add four new triangles
        result = rebuild_mesh(new_vertices, new_indices)
    return result
```

## Lamination Techniques

Membrane lamination produces thick surfaces from thin layers. The layers can be offset rigidly (every layer displaced by the same vector) or parametrically (each layer displaced by a function of its layer index). Parametric displacement produces curved, flowing volumes; rigid displacement produces stacked plates.

Booleans are another accumulation operation. Union combines two meshes; difference subtracts one from another; intersection keeps the shared region. Constructive solid geometry (CSG) composes complex shapes from simple primitives through repeated booleans, and the mound, dome, and membrane stations all admit CSG variants.

## Memory and Performance

Accumulated geometry grows without bound unless pruned. The map periodically checks the total primitive count and collapses older geometry into a baked mesh when the count exceeds a threshold. The bake operation is O(N) in primitive count but is performed rarely enough that amortised cost is negligible.
""",
'PG_Mirrored_Patterns': """

## Anti-Aliasing

Symmetric patterns often show aliasing artifacts at the symmetry axes — the pixels right at the mirror line look different from their neighbours because they are directly reflected rather than being interpolated. A half-pixel offset on the mirror operation corrects this: the mirror point is placed between two pixels rather than on a single pixel.

```gdscript
func mirror_h_offset(cells: Array) -> Array:
    var size = cells.size()
    var half = size / 2
    var out: Array = []
    for y in range(size):
        out.append([])
        for x in range(size):
            if x < half:
                out[y].append(cells[y][x])
            else:
                # Mirror across x = half - 0.5
                out[y].append(cells[y][2 * half - 1 - x])
    return out
```

## Frieze Groups

The 17 wallpaper groups classify 2D periodic patterns. There are also seven frieze groups, which classify patterns that repeat along one axis (borders and stripes). The map implements a subset of wallpaper groups (p1, p2, p4m, p6m) but a full implementation would include all seventeen.

## Rhizomatic Maze Algorithm Details

The rhizomatic maze grows from multiple seeds rather than from a single root. Each seed is effectively a separate recursive-backtracker search, and when two searches' passages touch, they merge into a shared region. The merging is the non-hierarchical feature: a cell in the resulting maze can be reached from multiple seeds via different paths.

```gdscript
var cell_seed: Dictionary = {}  # cell -> seed index

func grow_rhizome() -> void:
    var active_seeds: Array = seeds.duplicate()
    while not active_seeds.is_empty():
        for i in range(active_seeds.size() - 1, -1, -1):
            var seed_cell = active_seeds[i]
            var growth = random_unclaimed_neighbour(seed_cell)
            if growth == null:
                active_seeds.remove_at(i)
            else:
                cell_seed[growth] = cell_seed[seed_cell]
                connect(seed_cell, growth)
                active_seeds[i] = growth
```

## Performance

Symmetric CA is faster than a full CA because only half the cells need to be computed; the rest are copied by mirror. The map exploits this to run larger grids at the same frame rate. For a 256×256 mirrored grid, only the 128×256 left half is updated per step.

The rhizomatic maze completes in O(N) steps for N cells, same as recursive backtracking, but with a larger constant factor because of the merging bookkeeping. At 64×64, generation is imperceptible; at 256×256 it takes a few frames to complete.
""",
'Chamber_ProcGen': """

## Morphology Bias

Over many strike-reassemble cycles, the golem's morphology drifts. The drift reflects what the learner struck most often. A golem whose legs are struck repeatedly will rebuild with reinforced legs — more legs, sturdier attachment, faster regeneration of leg fragments. A golem whose torso is targeted develops a more robust torso at the expense of extremities.

```gdscript
class_name MorphologyTracker extends Resource

var strike_history: Array = []
var priority_weights: Dictionary = {"leg": 1.0, "arm": 1.0, "torso": 1.0, "head": 1.0}
@export var drift_rate: float = 0.02

func register_strike(part_type: String) -> void:
    strike_history.append(part_type)
    if strike_history.size() > 100:
        strike_history.pop_front()
    recompute_weights()

func recompute_weights() -> void:
    var counts: Dictionary = {}
    for s in strike_history:
        counts[s] = counts.get(s, 0) + 1
    for t in priority_weights:
        var count = counts.get(t, 0)
        var target_weight: float = 1.0 + count * drift_rate
        priority_weights[t] = lerp(priority_weights[t], target_weight, 0.1)
```

## Assembly Rules

The bricoleur's assembly rule is a simple grammar. Given a set of available fragments and a current body state, the rule selects the next fragment to attach and a candidate attachment point.

```gdscript
func assembly_rule() -> Array:  # [fragment, point]
    var eligible := detached.filter(func(f): return f.distance_to(global_position) < pickup_radius)
    if eligible.is_empty():
        return []
    # Prefer fragments whose type has high priority
    eligible.sort_custom(func(a, b): return priority(a.type) > priority(b.type))
    var fragment = eligible[0]
    var point := choose_attachment_point_for(fragment)
    return [fragment, point]
```

Different assembly rules produce different creature aesthetics. A symmetric rule tries to keep the body bilaterally symmetric. An extension rule favours attaching fragments far from the centre. A compaction rule favours attaching fragments close to existing parts.

## Termination

The bricoleur never stops assembling unless no fragments remain. The chamber ensures a continuous supply of debris by spawning fresh fragments when the floor becomes bare. The infinite-assembly condition is part of the chamber's argument: procedural generation has no natural endpoint.

## Emergent Morphology

The drifting priority weights produce emergent morphology that was not designed by the chamber's author. A learner who consistently targets one part type will evolve a golem that looks different from what any other learner's golem looks like. The chamber's output is a joint product of the learner's behaviour and the chamber's rules, and neither can be credited with authorship alone.

## Persistence

The map does not persist the golem's morphology across sessions. Each entry to the chamber produces a fresh golem. A persistent variant would be a natural extension — the chamber becomes a long-term companion whose morphology records the learner's history with it.
""",
}

for m, add in adds.items():
    p = Path(f'commons/maps/{m}/technical.md')
    t = p.read_text(encoding='utf-8')
    p.write_text(t.rstrip() + add, encoding='utf-8')

print('done', len(adds))
