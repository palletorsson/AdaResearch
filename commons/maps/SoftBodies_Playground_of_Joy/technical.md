# Open field where soft bodies, branching growth, and grid agents converge into unstructured play

Five maps of structured lessons. Now the scaffolding comes down. The playground scatters soft bodies, procedural growth systems, and autonomous agents across an open arena with no objectives, no progression, no prescribed interaction order. The technical content is the convergence itself — three independent systems (soft body physics, branching growth, agent-based grid interaction) operating in the same space, their outputs available for cross-system interference.

## The Rounded Soft Body: Curvature and Strain Visualization

The rounded_softbody_test artifact extends the jelly cube concept to curved geometry. Instead of eight vertices at cube corners, the mesh is a subdivided rounded cube — a sphere-swept box with smooth normals and continuous curvature.

```gdscript
# From rounded_softbody @identity:
# SoftBody3D rounded cube with per-vertex strain energy
# E = 0.5 * k * displacement^2
# displayed as blue-green-red heatmap overlay

@export var _stiffness: float = 10.0

func _compute_strain_energy() -> void:
    for i in range(soft_body.get_point_count()):
        var current_pos := soft_body.get_point_position(i)
        var rest_pos := _rest_positions[i]
        var displacement := current_pos.distance_to(rest_pos)
        var energy := 0.5 * _stiffness * displacement * displacement
        _set_vertex_color(i, _strain_to_color(energy))
```

The strain heatmap makes internal forces visible. Blue vertices are at rest — no displacement, no stored energy. Green vertices are moderately displaced. Red vertices are under significant strain. When the learner squeezes the soft body with VR hands, the contact region blooms red while distant regions remain blue. The strain field propagates through the spring network, making the force distribution legible in real time.

Three visualization modes correspond to three aspects of continuum mechanics:

**Strain mode** displays the elastic potential energy per vertex — how much each point has moved from its rest position. This is the spring memory made visible.

**Collision mode** highlights vertices currently in contact with external geometry, distinguishing between resting contact (green) and active penetration resolution (red).

**Volume mode** tracks the body's total volume and adjusts the pressure_coefficient to maintain conservation. Squeezing one side causes the opposite side to bulge, revealing volume preservation as an emergent constraint of the pressure system.

```gdscript
# Volume preservation through pressure adjustment:
# V_current = compute_mesh_volume()
# V_target = V_rest
# pressure_coefficient = base_pressure * (V_target / V_current)
# When compressed: V_current < V_target → pressure increases → body expands elsewhere
```

## Branching Growth Algorithm: L-System Meets Soft Bodies

The branching_growth_algorithm artifact generates organic tree-like structures through recursive branching. Each branch extends, splits at configurable angles, and continues to a specified depth. In the playground, these structures grow *among* soft bodies, creating obstacle geometry that is procedural rather than hand-placed.

```gdscript
# From branching_growth_algorithm:
# Recursive branching with configurable parameters
@export var branch_angle: float = 25.0  # degrees
@export var branch_ratio: float = 0.7   # child length / parent length
@export var max_depth: int = 5

func _grow_branch(origin: Vector3, direction: Vector3, length: float,
                   depth: int) -> void:
    if depth > max_depth:
        return
    var end := origin + direction * length
    _draw_segment(origin, end, _radius_at_depth(depth))

    # Split into two child branches
    var angle_rad := deg_to_rad(branch_angle)
    var left_dir := direction.rotated(Vector3.UP, angle_rad)
    var right_dir := direction.rotated(Vector3.UP, -angle_rad)
    _grow_branch(end, left_dir, length * branch_ratio, depth + 1)
    _grow_branch(end, right_dir, length * branch_ratio, depth + 1)
```

The branch_ratio controls self-similarity — each generation is a scaled copy of the parent. The branch_angle determines the spread. Together, they define a fractal structure whose parameters (angle, ratio, depth) map directly to L-system production rules: F -> F[+F][-F] with angle and scale parameters.

In the playground context, the branching structures serve as organic obstacles. Soft bodies dropped or thrown among the branches must navigate the fractal geometry, deforming around narrow passages between limbs. The procedural generation means each playground session produces a different obstacle field — the learner cannot memorize the layout, only develop general intuition about soft body-obstacle interaction.

## Grid Agents: Autonomous Perturbation

The gridagent artifact introduces autonomous actors into the soft body playground. Grid agents operate on the tile grid, executing simple programs — copy, translate, rotate, scale — that modify the grid environment around them.

```gdscript
# Grid agent behaviors:
# copy:      duplicate the artifact at the current position to an adjacent cell
# translate: move an artifact from one cell to another
# rotate:    rotate an artifact in place
# random:    apply random perturbation to nearby artifacts
```

In the playground, grid agents wander among the soft bodies and branching structures, copying artifacts, rearranging the layout, and introducing perturbations that the learner did not initiate. The playground's population changes over time without player intervention — grid agents multiply soft bodies, relocate obstacles, and create configurations that no single designer intended.

This is the playground's most radical technical feature: autonomous modification of the play environment during play. The learner encounters not a static sandbox but a dynamic ecology where agents, soft bodies, and growth algorithms co-evolve the space.

## Cross-System Interference

The playground's technical interest lies in what happens when these three systems overlap:

**Branching growth through soft bodies:** A branch growing through a space occupied by a soft body pushes the body aside as the geometry expands. The soft body deforms around the growing structure, the contact forces updating each frame as new branch segments appear.

**Soft bodies on branching structures:** A jelly cube or rounded soft body dropped onto a branching structure drapes across the branches, each vertex independently colliding with the nearest branch segment. The body assumes a shape determined by the fractal geometry beneath it — an organic drape that no hand-placed obstacle could produce.

**Grid agents modifying soft body contexts:** An agent that copies a soft body creates a new physics object with its own spring network, mass, and velocity. Two identical soft bodies dropped from the same height onto different branching configurations produce different deformation patterns — the same material, different contexts, different outcomes.

## VR Interaction: Haptic Play

The playground's lack of objectives makes VR interaction the primary content. The learner picks up soft bodies, squeezes them (rounded_softbody_test shows strain), throws them at branching structures, stacks them, drops them from heights, and observes the results. The strain visualization provides real-time feedback: red zones mark where the learner's grip is strongest, and the propagation of strain through the spring network makes internal physics visible.

```gdscript
# VR hand squeeze interaction:
func _on_grip_pressed(hand: XRController3D) -> void:
    var hand_pos := hand.global_position
    for i in range(soft_body.get_point_count()):
        var point_pos := soft_body.get_point_position(i)
        var dist := hand_pos.distance_to(point_pos)
        if dist < squeeze_radius:
            var push := (point_pos - hand_pos).normalized()
            push *= (squeeze_radius - dist) * squeeze_force
            soft_body.set_point_position(i, point_pos + push)
```

The squeeze pushes vertices outward from the hand center, creating a concavity that the spring network propagates through the body. Release the grip and the springs pull the vertices back toward their rest positions. The recovery speed depends on stiffness — stiff bodies snap back, soft bodies ooze back slowly. The learner develops an embodied understanding of stiffness by feeling the difference through repeated interaction.

## Playground as Integration Test

The playground is technically an integration test. It verifies that soft body physics, procedural generation, and agent-based systems can coexist in the same scene without conflicts — that collision systems handle the increased geometric complexity, that performance remains interactive with multiple soft bodies and growing structures, and that the grid agent's modifications don't destabilize the physics simulation.

```gdscript
# Performance budget for the playground:
# - 3-5 soft bodies active simultaneously (each ~256 vertices, ~700 springs)
# - 1 branching structure (depth 5 ≈ 63 segments)
# - 1-2 grid agents (low-frequency updates, ~1 action per second)
# Target: 72 fps on Quest 2, 90 fps on Quest 3
# Bottleneck: soft body self-collision at O(n^2) per body
```

The lack of objectives is not laziness. It is the technical proof that the systems work — that the spring-mass framework established in five structured maps is robust enough to support free-form interaction without failing, exploding, or producing nonsensical behavior.
