# Each boid sees only neighbors, applies three forces, and a flock emerges across the open arena

Physarum agents coordinated through the environment. They deposited trail, sensed trail, and the grid carried every message. No agent ever perceived another agent. The medium was the channel — stigmergy, indirect communication, the world as shared memory.

Boids break that indirection. A boid perceives its neighbors directly. It reads their positions and velocities without any intermediary substance. The coordination channel shifts from environment to peer — from trail on a grid to vectors between agents. The three rules Craig Reynolds published in 1987 formalize this: separation, alignment, cohesion.

Each computes a steering force from the local neighborhood. The weighted sum of those forces drives the boid's velocity. No leader assigns headings. No global planner routes the flock. Each individual runs the same three calculations, and the collective motion — wheeling, splitting, reforming — is a side effect.

The shift matters. Physarum's trail persisted — agents communicated across time. Boids communicate across space but not across time. A boid has no memory of where its neighbors were last frame. It reacts to the present configuration every frame, from scratch.

The flock's coherence is maintained not by accumulated history but by continuous, instantaneous mutual adjustment. Remove the trail map. Replace it with neighbor queries. The computation changes. The principle — local rules producing global order — stays.

## The Boid

A boid is a position, a velocity, and perception radii. Nothing else.

```gdscript
var positions: PackedVector3Array
var velocities: PackedVector3Array
var accelerations: PackedVector3Array

var num_boids: int = 200
var max_speed: float = 8.0
var max_force: float = 4.0

func _ready() -> void:
    positions.resize(num_boids)
    velocities.resize(num_boids)
    accelerations.resize(num_boids)

    for i in num_boids:
        positions[i] = Vector3(
            randf_range(-20.0, 20.0),
            randf_range(2.0, 10.0),
            randf_range(-20.0, 20.0))
        velocities[i] = Vector3(
            randf_range(-1.0, 1.0),
            randf_range(-0.5, 0.5),
            randf_range(-1.0, 1.0)).normalized() * max_speed * 0.5
        accelerations[i] = Vector3.ZERO
```

Three parallel arrays — structure-of-arrays, same layout as the Physarum colony. Positions scatter across the arena volume. Velocities start at half max speed in random directions. Accelerations reset to zero each frame before forces accumulate. The boid carries no heading angle — velocity is the heading. Direction and speed are one vector, not two separate quantities.

The `boids_aquarium` artifact in this map spawns these arrays and renders each boid as a small oriented mesh. The mesh's forward axis aligns with the velocity vector using `look_at` or a basis rotation — the visual pointing matches the physical heading without any separate facing variable. Velocity is truth. The mesh follows.

## Neighbor Queries: Who Is Nearby

Before computing any steering force, each boid must identify its neighbors. A neighbor is any other boid within a specified perception radius. The naive approach compares every pair.

```gdscript
var perception_radius: float = 10.0

func get_neighbors(i: int, radius: float) -> PackedInt32Array:
    var neighbors: PackedInt32Array = PackedInt32Array()
    var radius_sq: float = radius * radius

    for j in num_boids:
        if j == i:
            continue
        var offset: Vector3 = positions[j] - positions[i]
        if offset.length_squared() < radius_sq:
            neighbors.append(j)

    return neighbors
```

O(n^2) per frame. For 200 boids, that is 39,800 distance checks — fast enough. For 2,000 boids, it becomes 3,998,000 — too slow. The `boid_manager` artifact addresses this with spatial partitioning. A uniform grid divides the arena into cells. Each boid registers in the cell containing its position. Neighbor queries check only the current cell and its 26 adjacent cells in 3D (or 8 in 2D). The cost drops from O(n^2) to approximately O(n * k) where k is the average number of boids per cell neighborhood.

```gdscript
var cell_size: float = 10.0
var grid: Dictionary = {}

func update_grid() -> void:
    grid.clear()
    for i in num_boids:
        var key: Vector3i = Vector3i(
            int(floor(positions[i].x / cell_size)),
            int(floor(positions[i].y / cell_size)),
            int(floor(positions[i].z / cell_size)))
        if not grid.has(key):
            grid[key] = PackedInt32Array()
        grid[key].append(i)

func get_neighbors_grid(i: int, radius: float) -> PackedInt32Array:
    var neighbors: PackedInt32Array = PackedInt32Array()
    var radius_sq: float = radius * radius
    var center: Vector3i = Vector3i(
        int(floor(positions[i].x / cell_size)),
        int(floor(positions[i].y / cell_size)),
        int(floor(positions[i].z / cell_size)))

    for dx in range(-1, 2):
        for dy in range(-1, 2):
            for dz in range(-1, 2):
                var key: Vector3i = center + Vector3i(dx, dy, dz)
                if grid.has(key):
                    for j in grid[key]:
                        if j == i:
                            continue
                        if (positions[j] - positions[i]).length_squared() < radius_sq:
                            neighbors.append(j)

    return neighbors
```

The cell size should match or exceed the largest perception radius. Smaller cells waste time checking empty neighbors. Larger cells include too many distant boids. The grid rebuilds every frame — boids move fast enough that caching across frames introduces stale data. Rebuild is cheap. Stale neighbors are not.

## Separation: Avoid Crowding

Separation prevents collision. Each boid computes a vector pointing away from neighbors that are too close — within a short separation radius, tighter than the general perception radius.

```gdscript
var separation_radius: float = 4.0
var separation_weight: float = 2.5

func compute_separation(i: int, neighbors: PackedInt32Array) -> Vector3:
    var steer: Vector3 = Vector3.ZERO
    var count: int = 0

    for j in neighbors:
        var offset: Vector3 = positions[i] - positions[j]
        var dist: float = offset.length()
        if dist < separation_radius and dist > 0.001:
            steer += offset.normalized() / dist
            count += 1

    if count > 0:
        steer /= float(count)
        steer = steer.normalized() * max_speed
        steer -= velocities[i]
        steer = steer.limit_length(max_force)

    return steer
```

The repulsion vector divides by distance — closer neighbors push harder. A boid 0.5 units away contributes four times the repulsion of one 2 units away. The inverse weighting creates a steep gradient near the boid's body — soft at range, sharp at contact. This is the same inverse-distance falloff seen in gravitational and electrostatic forces, applied here as a social force.

The `steer.normalized() * max_speed` step is Reynolds' steering formula. The desired velocity points away from crowding at full speed. Subtract the current velocity to get the force needed to redirect the boid. Clamp to `max_force` — the boid cannot turn instantaneously. It leans into the correction over multiple frames. The force limit produces smooth curves rather than jerky snapping.

Separation is the flock's collision avoidance. Without it, boids pile into clumps and overlap. With it, they maintain personal space — a minimum distance that gives the flock its visible structure of distinct, spaced individuals moving in concert.

## Alignment: Match the Flock's Heading

Alignment steers each boid toward the average velocity of its neighbors. Not toward their position — toward their heading and speed.

```gdscript
var alignment_radius: float = 8.0
var alignment_weight: float = 1.0

func compute_alignment(i: int, neighbors: PackedInt32Array) -> Vector3:
    var avg_velocity: Vector3 = Vector3.ZERO
    var count: int = 0

    for j in neighbors:
        var dist: float = (positions[j] - positions[i]).length()
        if dist < alignment_radius:
            avg_velocity += velocities[j]
            count += 1

    if count == 0:
        return Vector3.ZERO

    avg_velocity /= float(count)
    avg_velocity = avg_velocity.normalized() * max_speed
    var steer: Vector3 = avg_velocity - velocities[i]
    return steer.limit_length(max_force)
```

The average velocity is a consensus direction. Alignment pushes each boid toward that consensus — not rigidly, not instantly, but with the same steering-force mechanism. The boid wants to go where its neighbors are going, at the speed they are going. The subtraction `avg_velocity - velocities[i]` is the discrepancy between the local consensus and the individual's current state. The force acts to close that gap.

Alignment produces the flock's most visible feature: parallel motion. A group of boids all running alignment converges on a uniform heading within a few seconds. They stream together like a river. Without alignment, separation and cohesion alone produce a jittery cloud that stays together but never flows. Alignment is what makes a flock look like a flock.

The alignment radius is typically larger than the separation radius but smaller than or equal to the cohesion radius. A boid aligns with neighbors it can see but does not need to avoid. The layered radii create concentric zones of influence — a tight repulsive core, a mid-range alignment band, and a wide cohesive shell.

## Cohesion: Stay With the Group

Cohesion steers each boid toward the average position of its neighbors — the centroid of its local group.

```gdscript
var cohesion_radius: float = 10.0
var cohesion_weight: float = 1.0

func compute_cohesion(i: int, neighbors: PackedInt32Array) -> Vector3:
    var center_of_mass: Vector3 = Vector3.ZERO
    var count: int = 0

    for j in neighbors:
        var dist: float = (positions[j] - positions[i]).length()
        if dist < cohesion_radius:
            center_of_mass += positions[j]
            count += 1

    if count == 0:
        return Vector3.ZERO

    center_of_mass /= float(count)
    var desired: Vector3 = (center_of_mass - positions[i]).normalized() * max_speed
    var steer: Vector3 = desired - velocities[i]
    return steer.limit_length(max_force)
```

The target is the centroid — the geometric center of all neighbors within range. The desired velocity points from the boid's position toward that centroid at max speed. Steering subtracts current velocity. The force pulls the boid inward, toward the group's center of mass.

Cohesion is what prevents dissolution. Without it, separation pushes boids apart and alignment makes them parallel, but nothing holds the group together. They drift apart into parallel lines that never reconverge. Cohesion is the counter-force — the social gravity that binds the flock into a persistent cluster.

The interplay between separation and cohesion creates an equilibrium distance. Separation pushes out. Cohesion pulls in. The boid settles where the forces balance — not at any fixed distance but at a dynamic equilibrium that shifts as the neighborhood changes. The flock breathes. It compresses when cohesion dominates a turn, expands when separation fires during crowding. The breathing is not programmed. It is the residual oscillation of opposing forces.

## The Weighted Sum: Three Forces, One Acceleration

Each frame, the three steering forces combine into a single acceleration.

```gdscript
func _process(delta: float) -> void:
    update_grid()

    for i in num_boids:
        var neighbors: PackedInt32Array = get_neighbors_grid(i, cohesion_radius)

        var sep: Vector3 = compute_separation(i, neighbors) * separation_weight
        var ali: Vector3 = compute_alignment(i, neighbors) * alignment_weight
        var coh: Vector3 = compute_cohesion(i, neighbors) * cohesion_weight

        accelerations[i] = sep + ali + coh

    for i in num_boids:
        velocities[i] += accelerations[i] * delta
        velocities[i] = velocities[i].limit_length(max_speed)
        positions[i] += velocities[i] * delta
        accelerations[i] = Vector3.ZERO
```

The weights are the system's personality. High separation weight with low cohesion produces a loose, skittish flock that fragments under pressure. High cohesion with low alignment produces a tight ball that rolls more than flows. Equal weights produce the classic Reynolds flock — smooth, organic, birdlike. The `boid_flocking` artifact exposes these weights as sliders, letting the learner sculpt flock behavior in real time.

Three weights and three radii form a six-dimensional parameter space. Qualitatively different behaviors cluster in distinct regions. Some combinations produce tight schooling — fish. Others produce wide wheeling — starlings. Others produce parallel streams — migrating geese. The boids algorithm does not model any particular species. It models the abstract structure of flocking itself, and the parameters tune it toward particular expressions.

The two-pass loop matters. First pass: compute all forces using current positions and velocities. Second pass: integrate. If forces and positions updated in the same pass, early boids would move before late boids computed their forces, introducing order-dependent artifacts. The separation into force-computation and integration passes ensures all boids see the same snapshot of the world — the same double-buffer principle that governs cellular automaton updates.

## The Arena and Observation

The map places four artifact stations across a flat 11x11 arena with observation platforms at varying heights. The `boids_aquarium` sits at grid position (3, 3) — a bounded volume where boids demonstrate flocking within visible walls. The `boid_flocking` station at (7, 3) exposes the weight and radius sliders. The `boid_manager` at (3, 7) visualizes the spatial grid — cells lighting up as boids enter and leave. The `boids_2d_in_3d` at (7, 7) projects the same three rules onto a flat plane, collapsing the y-axis to show 2D flocking rendered in the 3D arena.

From the elevated platforms, the flock reveals patterns invisible at ground level. A stream of boids viewed from above shows lane formation — parallel tracks that self-organize without any lane-assignment logic. Viewed from the side, the same stream shows vertical stratification — boids at different altitudes aligning with altitude-mates more than with boids directly above or below. The three-dimensional flock has structure along every axis. The observation platforms exist to make that structure legible.

## Prediction Error and the Flock

Each boid expects its neighbors to be there. Cohesion encodes this — the force toward the centroid is a correction applied when the boid's position deviates from the expected center of the group. Alignment encodes a velocity prediction — the boid expects its neighbors to move in a certain direction and steers to match. Separation encodes a proximity boundary — the boid predicts a minimum safe distance and corrects when that boundary is violated.

The three forces are three prediction errors, measured against three different expectations. Cohesion minimizes positional surprise. Alignment minimizes directional surprise. Separation minimizes proximity surprise. The weighted sum is a composite error signal that the boid corrects by adjusting its own velocity. Over many frames, the flock converges toward a state where all three prediction errors are minimized simultaneously — a dynamic equilibrium where each boid's expectations about its neighbors are approximately satisfied.

This maps directly onto the free energy principle's formulation of active inference. The boid does not passively observe and react. It steers — it acts on the world to bring sensory input into alignment with its generative model. The generative model is implicit: "neighbors should be at moderate distance, moving in similar directions, not too close." The steering forces are the actions that minimize the divergence between this model and reality. The flock is the collective fixed point where every agent's model is simultaneously satisfied.

No boid represents the flock. No boid stores a model of the flock's shape or trajectory. The flock is a higher-order structure that exists only in the aggregate — an attractor in the joint state space of all boids. Reynolds demonstrated that this attractor requires only three local forces and a handful of parameters.

The gap between the simplicity of the rules and the complexity of the emergent motion is the central lesson. Physarum computed with trail. Boids compute with proximity. The substrate differs. The principle — local error minimization producing global coordination — persists.

## From Flocking to General Agent Models

The boids algorithm fixes the three forces. Separation, alignment, cohesion — always these three, always weighted and summed. But many collective behaviors require different forces. Predator evasion adds a fourth: flee from threats. Obstacle avoidance adds a fifth: steer around geometry. Goal seeking adds a sixth: move toward a target. Each new force slots into the same weighted-sum architecture, but the system is no longer "boids" — it is agent-based modeling.

The next map in the sequence, Agent-Based Modeling, generalizes this pattern. Agents carry arbitrary state. Forces are replaced by rules that can reference any combination of agent properties, environmental conditions, and stochastic processes. The three-force structure of boids becomes a special case within a broader framework. But boids remain the clearest demonstration of the core mechanism: per-agent local computation, no global coordination, emergent collective behavior. Every agent-based model inherits this DNA.

## Possible Artifacts

**predator_evader** — Introduces a single predator agent into the flock. The predator moves toward the nearest boid at higher-than-flock speed. Boids within a fear radius add a fourth steering force: flee, weighted heavily. The flock splits around the predator, reforms behind it, and exhibits the characteristic wave-like compression seen in real starling murmurations under falcon attack. Sliders control predator speed, fear radius, and flee weight. Demonstrates that flocking is not merely aesthetic — it is a survival geometry where interior boids gain protection from the collective body.

**weight_sculptor** — Three large sliders mapped to separation, alignment, and cohesion weights, plus three sliders for radii. A phase-space indicator plots the current configuration against known behavioral regimes: schooling, streaming, swarming, dispersal. Preset buttons load parameter sets labeled "starlings," "fish school," "migrating geese," "mosquito swarm." Each preset produces visibly distinct flock character from the same three rules — the parameter space explored as a design tool.

**neighbor_visualizer** — Selects a single boid and renders its three perception radii as concentric transparent spheres. Lines connect it to neighbors within each radius, color-coded by which force they contribute to — red for separation, green for alignment, blue for cohesion. The force vectors themselves render as arrows on the selected boid, showing the real-time steering computation. Toggling forces on and off reveals each rule's contribution to the composite behavior — alignment alone produces parallel streams, cohesion alone produces collapse, separation alone produces explosion.
