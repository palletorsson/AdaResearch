> Current encounter and verification (24 September 2026): [encounter notes](encounter-notes.md). The earlier account below is retained; the current note governs changed placement, controls and validation.

# Random_Cubes - Technical Tutorial

## Randomizing Geometry

The `random_edge_profile` element applies randomness to mesh geometry, not just transforms.

### Edge Profile Randomization

```gdscript
extends MeshInstance3D

@export var edge_variance: float = 0.3
@export var seed_offset: int = 0

func _ready():
    randomize_edges()

func randomize_edges():
    var rng = RandomNumberGenerator.new()
    rng.seed = hash(global_position) + seed_offset  # Deterministic per-position

    # Get mesh data
    var mesh_data = ArrayMesh.new()
    var vertices = get_base_cube_vertices()

    # Randomize each vertex along edges
    for i in range(vertices.size()):
        var v = vertices[i]
        # Only perturb edge vertices (not faces)
        if is_edge_vertex(v):
            v += Vector3(
                rng.randf_range(-edge_variance, edge_variance),
                rng.randf_range(-edge_variance, edge_variance),
                rng.randf_range(-edge_variance, edge_variance)
            )
        vertices[i] = v

    # Rebuild mesh with randomized vertices
    rebuild_mesh(mesh_data, vertices)
    mesh = mesh_data
```

### Position-Based Seeding

The key technique: **seed from position** for deterministic yet varied results.

```gdscript
# Each cube gets unique but reproducible randomness
rng.seed = hash(global_position)

# Benefits:
# - Same position = same shape (reproducible)
# - Different positions = different shapes (varied)
# - No need to store random values (stateless)
# - Regenerates identically on reload
```

### Random Object Spawner

The `random_object_spawner` creates dynamic randomness:

```gdscript
extends Node3D

@export var spawn_interval: float = 2.0
@export var spawn_radius: float = 3.0
@export var object_scenes: Array[PackedScene] = []

var rng = RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    spawn_timer()

func spawn_timer():
    while true:
        await get_tree().create_timer(spawn_interval).timeout
        spawn_random_object()

func spawn_random_object():
    if object_scenes.is_empty():
        return

    # Random scene selection
    var scene = object_scenes[rng.randi() % object_scenes.size()]
    var instance = scene.instantiate()

    # Random position within radius
    var angle = rng.randf() * TAU
    var distance = rng.randf() * spawn_radius
    instance.position = Vector3(
        cos(angle) * distance,
        0,
        sin(angle) * distance
    )

    # Random rotation
    instance.rotation.y = rng.randf() * TAU

    add_child(instance)
```

## Grid Layout Analysis

The map uses a specific pattern for `random_edge_profile` placement:

```gdscript
# Rows 1-2: North wall (rotation 0°)
# 6 cubes per row × 2 rows = 12 cubes

# Rows 4-8: East/West columns (rotation 90°)
# 2 cubes per side × 5 rows × 2 sides = 20 cubes

# Rows 10-11: South wall (rotation 0°)
# 6 cubes per row × 2 rows = 12 cubes

# Total: ~44 random_edge_profile instances
```

The rotation parameter (0° or 90°) affects which axis the edge randomization applies to.

## Geometric Randomization Strategies

```gdscript
# Strategy 1: Vertex displacement
func displace_vertices(vertices: Array, amount: float) -> Array:
    for i in range(vertices.size()):
        vertices[i] += random_vector3() * amount
    return vertices

# Strategy 2: Edge extrusion
func extrude_random_edges(mesh: ArrayMesh, count: int):
    var edges = get_edges(mesh)
    for i in range(count):
        var edge = edges[randi() % edges.size()]
        extrude_edge(mesh, edge, randf_range(0.1, 0.5))

# Strategy 3: Face subdivision
func subdivide_random_faces(mesh: ArrayMesh, probability: float):
    for face in get_faces(mesh):
        if randf() < probability:
            subdivide_face(mesh, face)
```

## Implementation Notes

### Arena Structure
- Perimeter raised (height 2) creates walls
- Interior flat (height 1) is the observation floor
- Central raised platform (heights 2) at (5,6)-(6,6) hosts the spawners
- Void at (9,12) allows teleporter access

### Visual Coherence
Despite random edges, the cubes maintain recognizable cube-ness:
- Randomization is bounded (edge_variance parameter)
- Core structure preserved
- Variation is local, not global

## Key Takeaway

Randomness can operate at any level of geometric abstraction:
- **Position**: Where objects are (covered in earlier maps)
- **Rotation**: How objects orient (next map: Random_Rotate_Random_XYZ)
- **Scale**: How large objects are
- **Topology**: The fundamental shape of objects (this map)

The `random_edge_profile` demonstrates that even the "identity" of an object—its shape—can be a random variable. The cube is still recognizably a cube, but no two are identical.

## Axiom References
- Related concepts in `commons/context/clipboard/tutorial_text/cube_axioms.md`
- Mesh manipulation concepts

## Within the Sequence

Random_Cubes extends randomness from position to form. The sequence has established randomness as a sampling primitive; this map shows that any property, including geometric shape, can be a random variable.

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.


## Paired dice column — 24 September 2026

`paired_dice_column:180` at grid (5,4) adds two XRTools dice derived from `dice_throw`. The original die scene/script are unchanged. The local variant keeps its pips, release hooks and mature settle test, using 11 cm dice in 90 cm-high trays and no reward rain. Desktop input remains a release without a tracked throw.

Only a released die settling in its own tray supplies a value. Both fresh values are required; grabbing a pending die invalidates that value, and the next pair cannot reuse the previous pair's other face. A full-size column uses 18 cm per pip, blue A below pink B, on a 20 cm base. Its collision height follows the total. Twelve miniature columns retain the recent ordered pairs; the total count can exceed twelve. Two MultiMeshes bound the shelf's coloured-unit rendering.

RETURN DICE preserves the last column and history. CLEAR RECORD also cancels pending results and removes the record. A loose die below 18 cm or over 3 m from its tray returns after 0.7 seconds; a held die is never reclaimed. Recovery does not produce a throw. The ideal independent fair-dice model has a triangular sum distribution; physical throws do not automatically validate that model.

Review and native evidence: `doc/book/iterations/2026-09-24-paired-dice/`.


## The continuing die — 24 September 2026

`continuing_die` at (2,5), yaw 180, uses the unmodified `paired_die.gd` tray and its settled-orientation reader. The die is a production XRToolsPickable with desktop grab/drop hooks. No RNG picks a face, and no automatic reroll is performed. One fresh release arms one valid result; recovery alone never arms it.

Each accepted face appends to a chain and adds to total. A face other than six closes the chain. A six permits another accepted throw unless five throws have already been retained. Five sixes produce total 30, a 2.7m column on a 0.14m base, and an explicit UNFINISHED state. A non-six on the fifth throw completes normally. Further results cannot change a closed or capped column until NEW CHAIN. The cap is a display budget, not a natural end or a claim about an unbounded stochastic process.

One 9cm unit represents each pip; seams and labels retain individual throws. A separate fixed 6+6+3 column is marked WORKED EXAMPLE / NOT LIVE THROWS. It is not sampled, not a remembered player outcome and not mixed into live state. Column support collision follows the live sum. RETURN DIE preserves the chain. NEW CHAIN cancels pending results and clears the live column, retaining ownership if a hand holds the die. Fallen unattended dice return through the existing tray recovery.

Evidence: `doc/book/iterations/2026-09-24-continuing-die/`. Controlled face-up physics drops exercise the production reader; event-only transaction cases are separately identified. These establish behavior, not uniformity, independence or a measured outcome distribution. Tracked-hand throwing and comfort remain pending.
