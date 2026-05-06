# An ordered grid where crystals grow from noise and puzzles snap shut with the satisfaction of a prediction confirmed

The Introduction laid the full equation on the table — QFE = F - λE(S) + φΔE(S,t) — and let the learner grab each term as a weighted sphere, feeling structure as mass and entropy as drift. The formula existed as architecture: walkable, touchable, spatially distributed across a laboratory. But the terms were peers there. Equal in presentation. The Introduction did not take sides.

This map takes sides. It isolates F — the free energy term, the prediction error, the drive toward order — and gives it the entire space. The lambda slider locks at zero. Entropy contributes nothing. The formula collapses to QFE = F + φΔE(S,t), and without the entropic counterweight, structure becomes absolute. Crystals grow.

Puzzles resolve. Patterns emerge from chaos with the inevitability of a proof reaching its conclusion. The map feels good. It should. F-minimization is the pleasure of understanding. The danger is that it feels too good, and the dark room at the end of the corridor exists to demonstrate what happens when a system pursues prediction error reduction as its only goal.

## Prediction Error: The Gap Between Model and World

F measures how far the system's internal model sits from the world it models. High F means surprise — the model expected one state and encountered another. Low F means accuracy — predictions match observations, the model fits, nothing unexpected arrives.

Every formal system the curriculum has built was an exercise in minimizing F. Placing vertices on a cube — reducing the gap between intended geometry and actual mesh. Translating an object to a coordinate — eliminating positional error. Scaling uniformly — maintaining proportion against deformation. The learner performed F-minimization dozens of times before the term had a name.

```gdscript
# F as prediction error — the distance between expected and actual
func compute_F(predicted: Dictionary, actual: Dictionary) -> float:
    var error := 0.0
    for key in predicted:
        if actual.has(key):
            var diff: float = predicted[key] - actual[key]
            error += diff * diff
    return sqrt(error)
```

The function squares each component difference and sums them. This is Euclidean distance in state space — the same magnitude calculation from VectorBasics applied not to physical position but to the abstract space of model-versus-reality. High F: the model vector and the world vector point in different directions. Low F: they converge. Zero F: perfect prediction. The system knows everything that will happen next.

The squared differences matter. Squaring penalizes large errors disproportionately — a model catastrophically wrong in one dimension accumulates more F than one slightly wrong everywhere. The system prioritizes its worst failures.

## Crystallization: Order From Noise

The `crystal_cluster` artifact demonstrates F-minimization as a physical process. Five hexagonal prisms emerge from procedural generation, each constructed vertex by vertex using `SurfaceTool`:

```gdscript
func create_single_crystal(size: float) -> MeshInstance3D:
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    var vertices = []
    var height = size * 1.5

    # Bottom hex
    for i in range(6):
        var angle = i * PI / 3.0
        vertices.append(Vector3(cos(angle) * size, -height/2, sin(angle) * size))

    # Top hex
    for i in range(6):
        var angle = i * PI / 3.0
        vertices.append(Vector3(cos(angle) * size * 0.7, height/2, sin(angle) * size * 0.7))
```

The bottom hexagon uses full size. The top hexagon tapers to 0.7 — a truncated prism, a crystal that narrows toward its apex. The geometry is deterministic. Given the same size parameter, the same crystal emerges. This is zero-entropy construction: one input maps to exactly one output, no randomness, no branching, no alternative configurations.

The cluster positions each crystal using deterministic seeding:

```gdscript
var rng = RandomNumberGenerator.new()
rng.seed = i * 42  # Deterministic seeding

crystal_node.position = Vector3(
    rng.randf_range(-0.2, 0.2),
    rng.randf_range(-0.1, 0.1),
    rng.randf_range(-0.2, 0.2)
)
```

The seed `i * 42` ensures that crystal 0 always occupies the same position, crystal 1 always the same. The `RandomNumberGenerator` produces values that look scattered but are fully determined by the index. Pseudorandom structure — the appearance of disorder governed by an underlying rule. Every time the cluster spawns, the same five crystals appear in the same configuration. The crystal remembers its shape. F is zero: the model (the seed) perfectly predicts the outcome (the positions).

The shader material reinforces the ordered aesthetic:

```gdscript
material.set_shader_parameter("base_color", color)
material.set_shader_parameter("edge_color", Color.WHITE)
material.set_shader_parameter("edge_width", 1.5)
material.set_shader_parameter("emission_strength", 1.0)
```

White wireframe edges over blue base color. The edges are the lattice — the visible skeleton of the crystal's internal geometry. Emission at 1.0 makes the crystal glow, asserting its presence. The aesthetic is cold precision. No noise, no drift, no organic variation. Pure F.

## Pattern Completion: The Snap Puzzles

The map places two puzzles flanking the central crystal: `snap_cube_puzzle` and `snap_tetra_puzzle`. Both extend `SnapPointPuzzleBase`, which defines a state machine governing the learner's interaction:

```gdscript
enum PuzzleState {
    BUILDING,     # Player is connecting points
    VALIDATING,   # Checking if shape is complete
    LOCKED,       # Shape validated, points frozen
    COMPLETED     # Puzzle solved, rewards given
}
```

Four states. A strict progression. The learner cannot skip from BUILDING to COMPLETED — validation must intervene. The state machine enforces that pattern-completion is verified before reward. F-minimization requires confirmation that the prediction (the intended shape) matches the actual construction (the connected points).

The `SnapConnectionManager` operates as the graph topology engine. It maintains an adjacency list of all connected snap points and detects geometric shapes automatically:

```gdscript
var _adjacency: Dictionary = {}  # Node3D -> Array[Node3D]

func create_connection(point_a: Node3D, point_b: Node3D) -> Node3D:
    # Add to adjacency list (undirected edge)
    if point_b not in _adjacency[point_a]:
        _adjacency[point_a].append(point_b)
    if point_a not in _adjacency[point_b]:
        _adjacency[point_b].append(point_a)

    # Check for new shapes
    _detect_and_create_shapes()
    return line
```

Every time the learner connects two points, the manager rebuilds its shape detection — triangles (3-cycles), tetrahedra (complete K4 subgraphs), and higher structures. The detection is exhaustive. The learner snaps two points together and the system immediately checks whether a recognizable pattern has formed.

The tetrahedron puzzle listens for the specific signal:

```gdscript
func _connect_signals() -> void:
    if connection_manager:
        connection_manager.tetrahedron_formed.connect(_on_tetrahedron_formed)

func _on_tetrahedron_formed(points: Array) -> void:
    var our_points_count = 0
    for point in points:
        if point in snap_points:
            our_points_count += 1

    if our_points_count == 4:
        _complete_puzzle()
```

The check is ownership-based. Only when all four vertices belong to this puzzle does completion trigger. Borrowing structure from an adjacent puzzle does not count. F-minimization is local — each system reduces its own prediction error.

When the puzzle completes, the base class orchestrates a cascade:

```gdscript
func _complete_puzzle() -> void:
    current_state = PuzzleState.VALIDATING
    _lock_points()
    current_state = PuzzleState.LOCKED
    _play_completion_sound()

    if trigger_tag != "":
        TagSystem.trigger_tag_action(trigger_tag, action)
```

Points freeze. Sound plays. Tagged objects respond. The satisfaction of completion is not accidental — it is engineered. The puzzle transitions from loose points (high structural entropy, many possible configurations) to a locked solid (zero structural entropy, one configuration, the correct one). F drops to zero at the moment of completion. The prediction — "these four points form a tetrahedron" — is confirmed by the adjacency graph.

## The Lambda Slider at Zero

The `lambda_slider` in this map initializes with a `locked:0` parameter. Lambda fixed at zero. The slider handle sits at the leftmost position — blue, the order color.

```gdscript
const COLOR_ORDER = Color(0.2, 0.4, 0.9, 1.0)   # Blue at λ=0
const COLOR_EDGE = Color(0.2, 0.9, 0.4, 1.0)    # Green at λ≈0.4
const COLOR_CHAOS = Color(0.9, 0.2, 0.2, 1.0)   # Red at λ=1
```

The gradient encodes the QFEP spectrum. Blue: crystal regime. Green: edge of chaos, where cellular automata produce gliders. Red: dissolution. In this map, the learner sees only blue. The gradient exists on the rail as a visual promise of territory not yet explored, but the handle cannot move. Lambda is locked. The formula reads QFE = F.

The slider's particle system responds to its lambda value:

```gdscript
_particles.amount = int(lerp(10.0, 100.0, lambda))
particle_mat.initial_velocity_max = lerp(0.05, 0.3, lambda)
particle_mat.spread = lerp(10.0, 60.0, lambda)
```

At lambda zero, ten particles drift upward at minimum velocity with tight spread. The slider whispers. It does not scatter. The visual reinforces the content: in the pure-F regime, even the control interface is calm. The instrument reflects the system it measures.

The asymmetry of the color gradient reveals a design decision:

```gdscript
func _get_lambda_color(value: float) -> Color:
    if value < 0.4:
        var t = value / 0.4
        return COLOR_ORDER.lerp(COLOR_EDGE, t)
    else:
        var t = (value - 0.4) / 0.6
        return COLOR_EDGE.lerp(COLOR_CHAOS, t)
```

Order-to-edge spans 40% of the rail. Edge-to-chaos spans 60%. The edge of chaos sits closer to order than to entropy. This mirrors the empirical finding from cellular automata: complex behavior occupies a narrow band near low entropy. Most parameter space above 0.5 is dissolution in various textures. The green zone is small. The learner locked at zero sits just below it.

## The Dark Sphere: Where Order Ends

At the far end of the map, past the crystal cluster and the puzzles and the locked slider, the `dark_sphere` sits. A semi-transparent orb with pulsing emission and slow rotation. It is the ambient constant — present in many maps as decorative atmosphere. Here it carries the map's warning.

```gdscript
func _process(delta: float) -> void:
    _time_elapsed += delta

    if _sphere_mesh:
        _sphere_mesh.rotation.y += rotation_speed * delta
        _sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05

    if _sphere_material:
        var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
        _sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

The rotation is minimal — 0.15 radians per second around Y, a faint wobble of 0.05 radians on X. The emission pulses between 0.05 and 0.35 energy multiplier. This is a system at near-stasis. Low F made manifest. The sphere predicts its own next state almost perfectly: rotation will continue at the same speed, emission will pulse at the same frequency, the wobble will trace the same sinusoidal arc. Nothing surprises the dark sphere. Its prediction error approaches zero.

The albedo brightness oscillation adds a second layer:

```gdscript
var brightness := lerpf(0.6, 1.0, pulse_t)
_sphere_material.albedo_color = Color(
    albedo_color.r * brightness,
    albedo_color.g * brightness,
    albedo_color.b * brightness,
    albedo_color.a
)
```

The sphere darkens and brightens in sync with its emission pulse. The range is narrow — 60% to 100% of the base color. From a distance, the sphere appears to breathe. From close, the repetition becomes apparent. The same cycle, every time, forever. No variation. No surprise. No entropy.

This is the dark room problem. A system that only minimizes F — only reduces prediction error — converges on the simplest possible environment. Close the eyes and prediction becomes trivial: expect nothing, perceive nothing, error equals zero. The dark sphere does not close its eyes, but it does the equivalent: it occupies the most predictable state available. Rotation at constant speed. Pulsing at constant frequency. The sphere has solved its own dynamics and has no reason to change.

The halo ring beneath the sphere pulses at 70% of the main frequency:

```gdscript
var halo_t := (sin(_time_elapsed * pulse_speed * 0.7) + 1.0) * 0.5
halo_mat.albedo_color.a = lerpf(0.08, 0.2, halo_t)
```

The offset creates a phase relationship — the halo sometimes brightens when the sphere dims, sometimes synchronizes. Two sinusoids at a fixed frequency ratio. Even the apparent complexity is fully determined. The dark room does not generate new information. It recycles the same waveform at different speeds.

## The Map as Argument

The spatial layout of `QFEP_F_Term` traces a corridor from satisfaction to stasis. The learner enters at the north, passing the subtitle board and spawn point. Immediately ahead: the snap puzzles, one cube and one tetrahedron, flanking the central path. The puzzles are satisfying. Grab points, connect edges, hear the system validate the shape. F drops. Pattern emerges from scattered components. The reward circuitry fires.

Beyond the puzzles, the crystal cluster occupies the raised central platform — elevation 2 in the structure layer, a 4x4 block of heightened geometry. The crystals are beautiful. Blue wireframe on dark substrate. Deterministic arrangement.

Each prism tapers to its apex with mathematical precision. The learner cannot interact with the cluster the way they interact with the puzzles, but the visual statement is clear: this is what pure F-minimization produces. Frozen geometry. Perfect prediction. Zero surprise.

The elevator at position `(4, 4)` lifts the learner to height 3 — the highest point in the map. From above, the ordered grid reads as a checkerboard of regular blocks. The puzzles below are symmetric. The crystal cluster sits centered. The composition is clean. This is the F-term vista: structure visible at every scale, no element out of place.

The south corridor descends. Heights drop from 2 back to 1, then to 0 — the floor falls away. The dark sphere waits at the terminal position. No puzzles here.

No crystals. Just the sphere, pulsing in its constrained loop, the halo breathing beneath it. The teleporter beside it reads "Escape the Dark Room" — an explicit statement that this endpoint is not the destination. Pure order is a trap. Continue to entropy.

## Determinism and the Seed

The crystal cluster uses `rng.seed = i * 42` — a deterministic seed derived from the crystal index. This is not random placement. It is pseudorandom placement, which in the context of F-minimization means the same thing as no randomness at all. The seed is the model. The positions are the predictions. F is zero because the model (the deterministic RNG) perfectly predicts the outcome (the crystal positions).

Pseudorandomness is compressed determinism. A short seed generates a long sequence. The sequence looks disordered to an observer who does not know the seed, but to the system that holds it, every value is predicted. The crystal cluster appears natural — but the appearance of variation is an illusion. The same cluster spawns identically every time.

This is the computational analogy of the dark room. A system that has memorized its environment has minimized F to zero but lost the ability to respond to novelty. A new crystal size, an unexpected position, a rotation outside the seeded range — none can occur. The system is optimal for the world it encoded and fragile to any world it has not.

## The Reset Timer: F Over Time

The puzzle base class includes a reset mechanism that adds temporal pressure to the F-minimization process:

```gdscript
func _process(delta: float) -> void:
    _elapsed_time += delta
    var progress = _elapsed_time / reset_time_seconds
    _update_progress_bar(1.0 - progress)

    if _elapsed_time >= reset_time_seconds:
        _reset_puzzle()
```

The bar depletes over 60 seconds. If the learner does not complete the puzzle in time, snap points return to initial positions, connections break, the timer resets. Maximum structural entropy restored — scattered points, no edges, no shapes detected.

The color feedback encodes urgency:

```gdscript
if progress > 0.5:
    color = Color(0.3, 0.8, 0.3, 0.6)  # Green
elif progress > 0.25:
    color = Color(0.8, 0.8, 0.3, 0.6)  # Yellow
else:
    color = Color(0.8, 0.3, 0.3, 0.6)  # Red
```

Green to yellow to red. The progression mirrors the lambda gradient in reverse — as time runs out, the visual shifts from stability toward crisis. The reset is an entropic event imposed on the F-minimization process. The system will not wait forever for order to emerge. If the learner cannot reduce structural error fast enough, entropy reasserts itself. The scattered points represent a prediction failure: the intended shape did not materialize within the available time.

This temporal pressure introduces the φΔE(S,t) term implicitly. The rate of entropy change matters — not just whether the puzzle is solved but how quickly. A fast completion means ΔE(S,t) is negative and steep: entropy dropping rapidly as connections form. A slow completion means ΔE(S,t) is shallow — the system drifts toward order without urgency. A reset means ΔE(S,t) spikes positive: entropy jumps as structure dissolves.

## From Crystal to Chaos

The teleporter at the map's southern edge carries the learner out of the F-term regime. The destination is QFEP_E_Term, where lambda pins to 1.0 instead of 0.0, where particles scatter omnidirectionally, where cubes drift and bounce without settling. The transition is a phase change: from the crystal to the gas, from the blue end of the gradient to the red.

The F-term map makes this transition meaningful by establishing what pure order feels like in the body. The puzzles snap shut. The crystals glow with cold precision. The dark sphere pulses in its loop. The learner leaves with the sensation of completion — and the unease of the dark room. The satisfaction is real. The trap is real. Both truths hold simultaneously, and the formula's minus sign is the hinge between them.

## Possible Artifacts

**prediction_error_field** — A spatial grid where each cell displays a color representing the local prediction error between the learner's last position and their current position. Cells the learner has visited recently glow low-F blue (the model predicts correctly because the trajectory is recent). Cells the learner has never visited glow high-F red (the model has no data, prediction error is maximum). The field makes F spatial and personal — the learner sees their own exploration history as a prediction accuracy map, and watches F drop in real time as they walk through unexplored territory.

**crystal_growth_timelapse** — An artifact that replays the crystal cluster's construction in slow motion, showing vertices placed one at a time, faces triangulated, normals computed. The growth begins from a single seed point and expands outward as each hexagonal ring completes. The timelapse makes the SurfaceTool operations visible — each `add_vertex` call becomes a flash, each `commit` a structural consolidation. The learner sees F-minimization as an incremental process: each vertex reduces the gap between the intended crystal and the actual mesh.

**dark_room_simulator** — A sealed chamber where sensory input progressively decreases. Lighting dims. Audio fades. Geometry simplifies. The walls flatten.

The ceiling lowers. F drops toward zero as the environment approaches perfect predictability. The learner experiences the logical endpoint of pure F-minimization: a room with no features, no variation, no surprise. A readout displays F approaching zero while a second readout displays "information gained: 0 bits per second." The simulator makes the dark room problem visceral rather than conceptual.
