# Fold Runtime Spec v1

> No philosophy except this: folding is locomotion, defense, communication, and care
> expressed through one variable — `fold_amount` — across a stack of algorithms.

This spec defines the classes, contracts, update order, and authoring workflow
for the folding creature system in Godot 4.6.

---

## Core Classes

### Class Hierarchy

```
Resource
├── FoldRig
├── FoldSolver (abstract)
│   ├── BoneFoldSolver
│   ├── ChainFoldSolver
│   └── ShellFoldSolver
├── FoldPoseResource
├── FoldSegmentData
├── FoldConstraintData
└── FoldMaterialProfile

CharacterBody3D
└── FoldCritter (extends HazardCreatureBase)
```

---

## 1. FoldSegmentData

```gdscript
class_name FoldSegmentData
extends Resource

@export var segment_name: StringName = &""
@export var fold_axis: Vector3 = Vector3.RIGHT       # Local axis of rotation
@export var angle_closed: float = 0.0                # Degrees when fold_amount = 0
@export var angle_open: float = 90.0                 # Degrees when fold_amount = 1
@export var parent_segment: StringName = &""          # Empty = root segment
@export var parent_min_fold: float = 0.0             # Parent must be this open before child opens
@export var material_type: StringName = &"bone"       # bone, membrane, flesh
@export var spring_stiffness: float = -1.0           # -1 = use FoldRig default
@export var spring_damping: float = -1.0             # -1 = use FoldRig default
@export var mass: float = 1.0                        # Affects inertia and tension contribution
```

**Who creates it**: Graph grammar (from BodyGraph) or designer (hand-authored).
**Who reads it**: FoldSolver subclasses during `compute_fold()`.
**Signals**: None — pure data.

---

## 2. FoldConstraintData

```gdscript
class_name FoldConstraintData
extends Resource

@export var segment_name: StringName = &""
@export var min_angle: float = 0.0
@export var max_angle: float = 90.0
@export var latch_angle: float = -1.0                # -1 = no latch; else snap to this angle
@export var latch_threshold: float = 5.0             # Degrees — snap if within this range
@export var break_force: float = -1.0                # -1 = unbreakable; positive = misfold if exceeded
```

**Who creates it**: Designer or derived from BodyGraph socket types.
**Who reads it**: FoldSolver during constraint enforcement (step 5 of pipeline).

---

## 3. FoldPoseResource

```gdscript
class_name FoldPoseResource
extends Resource

@export var pose_name: StringName = &""
@export var segment_transforms: Dictionary = {}       # StringName -> Transform3D
@export var compatible_states: PackedInt32Array = []   # FoldState enum values
@export var blend_curve: Curve = null                 # null = linear lerp
@export var has_latch: bool = false
@export var latch_threshold: float = 0.95
```

**Who creates it**: Designer (authored) or generation pipeline (derived from topology).
**Who reads it**: FoldSolver during pose interpolation.

---

## 4. FoldMaterialProfile

```gdscript
class_name FoldMaterialProfile
extends Resource

@export_range(0.0, 1.0) var shell_ratio: float = 0.0
@export_range(0.0, 1.0) var membrane_ratio: float = 0.0
@export_range(0.0, 1.0) var flesh_ratio: float = 0.0
@export_range(0.0, 1.0) var crease_visibility: float = 0.5
@export_range(0.0, 1.0) var wrinkle_response: float = 0.3
```

**Who creates it**: Derived from CritterDNA fold material tendencies.
**Who reads it**: CritterTraitMapper for shader parameter binding.

---

## 5. FoldSolver

Abstract base. Each subclass implements one deformation strategy.

```gdscript
class_name FoldSolver
extends Resource

## Compute deformed transforms for all segments at given fold state.
## Returns Dictionary[StringName, Transform3D] — segment_name -> local transform.
func compute_fold(
    fold_amount: float,
    fold_tension: float,
    segments: Array[FoldSegmentData],
    constraints: Array[FoldConstraintData],
    current_pose: FoldPoseResource,
    target_pose: FoldPoseResource,
) -> Dictionary:
    return {}

## Optional: compute secondary motion (breathing, idle sway).
func compute_secondary(delta: float, activity: StringName) -> Dictionary:
    return {}
```

### 5a. BoneFoldSolver

For shells, wings, limbs — hierarchical bone rotations.

```gdscript
class_name BoneFoldSolver
extends FoldSolver

func compute_fold(
    fold_amount: float,
    fold_tension: float,
    segments: Array[FoldSegmentData],
    constraints: Array[FoldConstraintData],
    current_pose: FoldPoseResource,
    target_pose: FoldPoseResource,
) -> Dictionary:
    var result: Dictionary = {}

    for seg in segments:
        # Interpolate angle between closed and open
        var angle: float = lerp(seg.angle_closed, seg.angle_open, fold_amount)

        # Parent gating: child can't open past parent's progress
        if seg.parent_segment != &"" and result.has(seg.parent_segment):
            var parent_progress: float = _get_parent_fold_progress(seg.parent_segment, segments, fold_amount)
            if parent_progress < seg.parent_min_fold:
                var gate_factor: float = parent_progress / max(seg.parent_min_fold, 0.001)
                angle = lerp(seg.angle_closed, angle, clamp(gate_factor, 0.0, 1.0))

        # Apply constraints
        for c in constraints:
            if c.segment_name == seg.segment_name:
                angle = clamp(angle, c.min_angle, c.max_angle)
                # Latch
                if c.latch_angle >= 0.0 and abs(angle - c.latch_angle) < c.latch_threshold:
                    angle = c.latch_angle

        # Tension adds micro-tremor
        var tremor: float = 0.0
        if fold_tension > 0.3:
            tremor = sin(Time.get_ticks_msec() * 0.01 * seg.mass) * fold_tension * 2.0

        var t := Transform3D.IDENTITY
        t = t.rotated(seg.fold_axis, deg_to_rad(angle + tremor))
        result[seg.segment_name] = t

    return result

func _get_parent_fold_progress(parent_name: StringName, segments: Array[FoldSegmentData], fold_amount: float) -> float:
    for seg in segments:
        if seg.segment_name == parent_name:
            var range_span: float = seg.angle_open - seg.angle_closed
            if abs(range_span) < 0.001:
                return 1.0
            var current_angle: float = lerp(seg.angle_closed, seg.angle_open, fold_amount)
            return (current_angle - seg.angle_closed) / range_span
    return 1.0
```

### 5b. ChainFoldSolver

For accordion bodies, tails, necks — segments along a compressible curve.

```gdscript
class_name ChainFoldSolver
extends FoldSolver

@export var curve_length_folded: float = 0.5
@export var curve_length_open: float = 3.0
@export var curvature_folded: float = 0.8    # How curved when compressed
@export var curvature_open: float = 0.1      # How straight when extended

func compute_fold(
    fold_amount: float,
    fold_tension: float,
    segments: Array[FoldSegmentData],
    constraints: Array[FoldConstraintData],
    current_pose: FoldPoseResource,
    target_pose: FoldPoseResource,
) -> Dictionary:
    var result: Dictionary = {}
    var seg_count: int = segments.size()
    if seg_count == 0:
        return result

    var length: float = lerp(curve_length_folded, curve_length_open, fold_amount)
    var curvature: float = lerp(curvature_folded, curvature_open, fold_amount)

    for i in seg_count:
        var t: float = float(i) / max(seg_count - 1.0, 1.0)
        var seg: FoldSegmentData = segments[i]

        # Position along curve
        var z: float = t * length
        var y: float = curvature * sin(PI * t) * length * 0.15

        # Tension adds zigzag offset
        var x: float = 0.0
        if fold_tension > 0.2:
            x = sin(t * PI * 4.0 + Time.get_ticks_msec() * 0.005) * fold_tension * 0.05

        var transform := Transform3D.IDENTITY
        transform.origin = Vector3(x, y, z)
        result[seg.segment_name] = transform

    return result
```

### 5c. ShellFoldSolver

For nested layers, chambered creatures — concentric shells opening/closing.

```gdscript
class_name ShellFoldSolver
extends FoldSolver

@export var layer_spacing_closed: float = 0.02
@export var layer_spacing_open: float = 0.15
@export var rotation_per_layer: float = 15.0   # Degrees — spiral effect

func compute_fold(
    fold_amount: float,
    fold_tension: float,
    segments: Array[FoldSegmentData],
    constraints: Array[FoldConstraintData],
    current_pose: FoldPoseResource,
    target_pose: FoldPoseResource,
) -> Dictionary:
    var result: Dictionary = {}
    var layer_count: int = segments.size()

    for i in layer_count:
        var seg: FoldSegmentData = segments[i]
        var layer_t: float = float(i) / max(layer_count - 1.0, 1.0)

        # Layers open from outside in: outer layers open first
        var layer_fold: float = clamp(fold_amount * (1.0 + layer_t * 0.5) - layer_t * 0.3, 0.0, 1.0)

        var spacing: float = lerp(layer_spacing_closed, layer_spacing_open, layer_fold)
        var rot_angle: float = layer_fold * rotation_per_layer * layer_t

        var transform := Transform3D.IDENTITY
        transform.origin = Vector3.UP * spacing * float(i)
        transform = transform.rotated(Vector3.UP, deg_to_rad(rot_angle))

        # Tension makes shells rattle
        if fold_tension > 0.4:
            var rattle: float = sin(Time.get_ticks_msec() * 0.02 * (i + 1)) * fold_tension * 0.01
            transform.origin += Vector3(rattle, 0, rattle)

        result[seg.segment_name] = transform

    return result
```

---

## 6. FoldRig

```gdscript
class_name FoldRig
extends Resource

@export var solver: FoldSolver = null
@export var segments: Array[FoldSegmentData] = []
@export var constraints: Array[FoldConstraintData] = []
@export var poses: Dictionary = {}                  # StringName -> FoldPoseResource
@export var material_profile: FoldMaterialProfile = null

@export var base_stiffness: float = 10.0
@export var base_damping: float = 0.82
@export var base_fold_speed: float = 0.5
@export var max_fold_energy: float = 1.0

@export var allowed_fold_states: PackedInt32Array = []
@export var min_fold_amount: float = 0.0
@export var max_fold_amount: float = 1.0

@export var supports_misfold: bool = true
@export var supports_latch: bool = false
@export var supports_nesting: bool = false
@export var supports_inversion: bool = false
@export var is_hatchable: bool = false

## Get the pose resource for a given state, or null.
func get_pose_for_state(state: int) -> FoldPoseResource:
    for key in poses:
        var pose: FoldPoseResource = poses[key]
        if state in pose.compatible_states:
            return pose
    return null

## Check if a fold state is allowed for this creature.
func is_state_allowed(state: int) -> bool:
    return allowed_fold_states.is_empty() or state in allowed_fold_states
```

---

## 7. FoldCritter

The runtime creature class. Extends `HazardCreatureBase` to inherit personality,
patrol AI, damage interface, and player detection.

```gdscript
class_name FoldCritter
extends HazardCreatureBase

# ── Three Independent Axes ────────────────────────────────────
# Affect is inherited from HazardCreatureBase as _personality

enum FoldState {
    EGG, HATCHING, FOLDED, UNFOLDING, DEPLOYED,
    DEFENSIVE, REFOLDING, MISFOLDED, DORMANT
}

var fold_state: FoldState = FoldState.FOLDED
var activity: StringName = &"idle"  # idle, fleeing, feeding, attacking, hatching, signaling

# ── Fold Runtime Variables ────────────────────────────────────

var fold_amount: float = 0.0
var target_fold: float = 0.0
var fold_velocity: float = 0.0
var fold_tension: float = 0.0
var fold_energy: float = 1.0
var fold_energy_max: float = 1.0
var misfold_amount: float = 0.0
var misfold_seed: int = 0

# ── Hit Reaction ──────────────────────────────────────────────

var hit_impulse: float = 0.0
var hit_direction: Vector3 = Vector3.ZERO

# ── Resources ─────────────────────────────────────────────────

@export var fold_rig: FoldRig = null
@export var dna: CritterDNA = null

# ── Segment Nodes ─────────────────────────────────────────────
# Populated by _build_mesh() or scene setup.
# Maps segment_name -> Node3D in the scene tree.
var _segment_nodes: Dictionary = {}


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _on_ready() -> void:
    if fold_rig:
        fold_energy_max = fold_rig.max_fold_energy
        fold_energy = fold_energy_max
    misfold_seed = get_instance_id()


# ═══════════════════════════════════════════════════════════════
# MAIN UPDATE — called from HazardCreatureBase._physics_process
# ═══════════════════════════════════════════════════════════════

func _process_visual(delta: float) -> void:
    if not fold_rig or not fold_rig.solver:
        return

    # Step 1-2: Affect and activity updated by HazardCreatureBase state machine
    # Step 3: Fold FSM transitions
    _update_fold_fsm()

    # Step 4: Compute target fold
    _compute_target_fold()

    # Step 5: Energy metabolism
    _update_fold_energy(delta)

    # Step 6: Spring update
    _update_fold_spring(delta)

    # Step 7: Misfold threshold check
    _check_misfold_threshold(delta)

    # Step 8-12: Pose pipeline
    _apply_pose_pipeline(delta)

    # Step 14: Shader/VFX update
    _update_fold_visuals()


# ═══════════════════════════════════════════════════════════════
# STEP 3: FOLD FSM
# ═══════════════════════════════════════════════════════════════

func _update_fold_fsm() -> void:
    var new_state: FoldState = fold_state

    match fold_state:
        FoldState.EGG:
            if fold_energy > 0.5:  # Enough energy to hatch
                new_state = FoldState.HATCHING
        FoldState.HATCHING:
            if fold_amount > 0.3:
                new_state = FoldState.FOLDED
        FoldState.FOLDED:
            if _should_deploy():
                new_state = FoldState.UNFOLDING
            elif fold_energy < 0.1:
                new_state = FoldState.DORMANT
        FoldState.UNFOLDING:
            if fold_amount > 0.9:
                new_state = FoldState.DEPLOYED
        FoldState.DEPLOYED:
            if _is_threatened():
                new_state = FoldState.DEFENSIVE
            elif _should_rest():
                new_state = FoldState.REFOLDING
        FoldState.DEFENSIVE:
            if not _is_threatened():
                new_state = FoldState.REFOLDING
        FoldState.REFOLDING:
            if fold_amount < 0.15:
                new_state = FoldState.FOLDED
        FoldState.MISFOLDED:
            if misfold_amount < 0.1:
                new_state = FoldState.REFOLDING
        FoldState.DORMANT:
            if fold_energy > 0.3:
                new_state = FoldState.UNFOLDING

    if new_state != fold_state:
        if fold_rig.is_state_allowed(new_state):
            _set_fold_state(new_state)


func _set_fold_state(new_state: FoldState) -> void:
    fold_state = new_state


# ═══════════════════════════════════════════════════════════════
# STEP 4: TARGET FOLD
# ═══════════════════════════════════════════════════════════════

func _compute_target_fold() -> void:
    match fold_state:
        FoldState.EGG:
            target_fold = 0.0
        FoldState.HATCHING:
            target_fold = 0.4
        FoldState.FOLDED:
            target_fold = fold_rig.min_fold_amount + 0.05
        FoldState.UNFOLDING:
            target_fold = 1.0
        FoldState.DEPLOYED:
            target_fold = fold_rig.max_fold_amount
        FoldState.DEFENSIVE:
            target_fold = 0.1
        FoldState.REFOLDING:
            target_fold = fold_rig.min_fold_amount
        FoldState.MISFOLDED:
            # Stuck at whatever fold_amount it was when misfolded
            pass
        FoldState.DORMANT:
            target_fold = 0.0


# ═══════════════════════════════════════════════════════════════
# STEP 5: ENERGY
# ═══════════════════════════════════════════════════════════════

func _update_fold_energy(delta: float) -> void:
    if not dna:
        return

    # Resting recovers energy
    if fold_state in [FoldState.FOLDED, FoldState.DORMANT]:
        fold_energy += delta * 0.05
    # Deployed drains energy (proportional to DNA fold_energy gene)
    elif fold_state == FoldState.DEPLOYED:
        fold_energy -= delta * dna.fold_energy * 0.02

    fold_energy = clamp(fold_energy, 0.0, fold_energy_max)


# ═══════════════════════════════════════════════════════════════
# STEP 6: SPRING
# ═══════════════════════════════════════════════════════════════

func _update_fold_spring(delta: float) -> void:
    # Energy gate
    if fold_energy <= 0.0 and target_fold > fold_amount:
        target_fold = fold_amount

    # Clamp to rig limits
    target_fold = clamp(target_fold, fold_rig.min_fold_amount, fold_rig.max_fold_amount)

    # Spring
    var force: float = (target_fold - fold_amount) * fold_rig.base_stiffness
    fold_velocity += force * delta
    fold_velocity *= fold_rig.base_damping
    fold_amount += fold_velocity * delta
    fold_amount = clamp(fold_amount, 0.0, 1.0)

    # Tension
    fold_tension += abs(fold_velocity) * delta * 0.1
    fold_tension *= 0.995
    fold_tension = clamp(fold_tension, 0.0, 1.0)

    # Motion energy cost
    if dna:
        fold_energy -= abs(fold_velocity) * delta * dna.fold_energy * 0.01
        fold_energy = clamp(fold_energy, 0.0, fold_energy_max)


# ═══════════════════════════════════════════════════════════════
# STEP 7: MISFOLD CHECK
# ═══════════════════════════════════════════════════════════════

func _check_misfold_threshold(delta: float) -> void:
    if not fold_rig.supports_misfold:
        return
    if not dna:
        return

    if fold_tension > 0.8 and dna.fold_risk > 0.3:
        misfold_amount += (fold_tension - 0.8) * dna.fold_risk * delta
        if misfold_amount > 0.5 and fold_state != FoldState.MISFOLDED:
            _set_fold_state(FoldState.MISFOLDED)

    # Natural healing when not under stress
    if fold_tension < 0.3 and misfold_amount > 0.0:
        misfold_amount -= delta * 0.01 * dna.fold_memory
        misfold_amount = max(0.0, misfold_amount)


# ═══════════════════════════════════════════════════════════════
# STEPS 8-13: POSE PIPELINE
# ═══════════════════════════════════════════════════════════════

func _apply_pose_pipeline(delta: float) -> void:
    var solver: FoldSolver = fold_rig.solver
    var current_pose: FoldPoseResource = fold_rig.get_pose_for_state(fold_state)
    var target_pose: FoldPoseResource = current_pose  # Same for now

    # Step 8: Compute solver pose
    var solved: Dictionary = solver.compute_fold(
        fold_amount, fold_tension,
        fold_rig.segments, fold_rig.constraints,
        current_pose, target_pose
    )

    # Step 10: Misfold offset
    if misfold_amount > 0.01:
        _apply_misfold_offset(solved)

    # Step 11: Hit reaction
    if hit_impulse > 0.01:
        _apply_hit_reaction(solved)
        hit_impulse *= 0.85

    # Step 12: Secondary motion
    var secondary: Dictionary = solver.compute_secondary(delta, activity)
    for seg_name in secondary:
        if solved.has(seg_name):
            var t: Transform3D = solved[seg_name]
            var s: Transform3D = secondary[seg_name]
            solved[seg_name] = Transform3D(t.basis * s.basis, t.origin + s.origin)

    # Step 13: Commit to scene tree
    for seg_name in solved:
        if _segment_nodes.has(seg_name):
            var node: Node3D = _segment_nodes[seg_name]
            node.transform = solved[seg_name]


func _apply_misfold_offset(solved: Dictionary) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = misfold_seed
    for seg_name in solved:
        var noise_angle: float = rng.randf_range(-1.0, 1.0) * misfold_amount * 15.0
        var noise_axis := Vector3(
            rng.randf_range(-1, 1),
            rng.randf_range(-1, 1),
            rng.randf_range(-1, 1)
        ).normalized()
        var t: Transform3D = solved[seg_name]
        solved[seg_name] = t.rotated(noise_axis, deg_to_rad(noise_angle))


func _apply_hit_reaction(solved: Dictionary) -> void:
    for seg_name in solved:
        var t: Transform3D = solved[seg_name]
        t.origin += hit_direction * hit_impulse * 0.1
        solved[seg_name] = t


# ═══════════════════════════════════════════════════════════════
# STEP 14: VISUALS
# ═══════════════════════════════════════════════════════════════

func _update_fold_visuals() -> void:
    # Update shader parameters if trait mapper available
    # fold_amount -> crease depth
    # fold_tension -> surface tremor
    # misfold_amount -> corruption overlay
    # fold_energy -> glow/vitality
    pass


# ═══════════════════════════════════════════════════════════════
# QUERIES (used by FSM)
# ═══════════════════════════════════════════════════════════════

func _should_deploy() -> bool:
    # Deploy when curious/friend personality and player nearby
    if _personality in ["curious", "friend"]:
        return _get_player_distance() < detection_radius
    return false

func _is_threatened() -> bool:
    if _personality == "foe":
        return false  # Foe doesn't feel threatened, it IS the threat
    return _get_player_distance() < detection_radius * 0.5

func _should_rest() -> bool:
    return fold_energy < 0.2 or _get_player_distance() > disengage_radius


# ═══════════════════════════════════════════════════════════════
# DAMAGE OVERRIDE (adds fold system response)
# ═══════════════════════════════════════════════════════════════

func _on_damaged(amount: float) -> void:
    super._on_damaged(amount)
    hit_impulse = amount / max_health
    hit_direction = -_get_player_direction()
    fold_tension += amount / max_health * 0.3


# ═══════════════════════════════════════════════════════════════
# VR VERB API (called by interaction system)
# ═══════════════════════════════════════════════════════════════

## Player squeezes creature — store energy, risk misfold
func vr_compress(strength: float) -> void:
    target_fold = max(target_fold - strength * 0.3, fold_rig.min_fold_amount)
    fold_tension += strength * 0.15

## Player pulls creature open
func vr_fan_open(strength: float) -> void:
    if fold_energy > 0.1:
        target_fold = min(target_fold + strength * 0.3, fold_rig.max_fold_amount)
        fold_energy -= strength * 0.05

## Player pushes parts inward
func vr_tuck(strength: float) -> void:
    target_fold = max(target_fold - strength * 0.2, fold_rig.min_fold_amount)
    fold_tension -= strength * 0.05  # Tucking reduces tension

## Player strokes surface — heal misfold
func vr_smooth(strength: float) -> void:
    misfold_amount -= strength * 0.02
    misfold_amount = max(0.0, misfold_amount)
    fold_tension -= strength * 0.03
    fold_tension = max(0.0, fold_tension)

## Player offers warmth/food
func vr_feed(amount: float) -> void:
    fold_energy = min(fold_energy + amount * 0.2, fold_energy_max)
```

---

## Signals

```gdscript
# FoldCritter emits:
signal fold_state_changed(old_state: FoldState, new_state: FoldState)
signal fold_latched(segment_name: StringName, latch_angle: float)
signal misfold_triggered(misfold_amount: float)
signal hatch_complete()
signal fold_energy_depleted()
```

---

## Authoring Workflow

### How to make one folding creature

1. **Create CritterDNA** — set fold topology tendencies and dynamics
2. **Build scene** — Node3D segments as children of FoldCritter
3. **Create FoldSegmentData** — one per segment (name, axis, angles, parent)
4. **Create FoldConstraintData** — joint limits, latches
5. **Create FoldPoseResource** — at least "folded" and "deployed"
6. **Choose solver** — BoneFoldSolver for most creatures
7. **Assemble FoldRig** — segments + constraints + poses + solver
8. **Assign to FoldCritter** — `fold_rig` export
9. **Map segment names** — populate `_segment_nodes` in `_build_mesh()`

### How to add one pose

1. Position creature segments manually in editor
2. Record transforms per segment into FoldPoseResource
3. Set `compatible_states` (which FoldStates use this pose)
4. Add to FoldRig.poses dictionary

### How to hook VR verbs

1. In your VR interaction system, detect grip/pull/stroke gestures
2. Call `vr_compress()`, `vr_fan_open()`, `vr_tuck()`, `vr_smooth()` on FoldCritter
3. Haptic feedback: pulse on latch events (listen to `fold_latched` signal)

### How to test in zoo map

1. Place FoldCritter in zoo pen
2. Add debug overlay (fold_amount / tension / energy / misfold readout)
3. Add global sliders to override target_fold across all creatures
4. Add push buttons for test scenarios (force DEPLOYED, inject tension, etc.)

---

## File Locations

```
commons/fold_system/
├── fold_critter.gd
├── fold_rig.gd
├── fold_solver.gd
├── fold_segment_data.gd
├── fold_constraint_data.gd
├── fold_pose_resource.gd
├── fold_material_profile.gd
├── solvers/
│   ├── bone_fold_solver.gd
│   ├── chain_fold_solver.gd
│   └── shell_fold_solver.gd
└── zoo/
    ├── folding_zoo.tscn
    ├── folding_zoo.gd
    └── fold_debug_overlay.gd
```

---

*This spec defines contracts, not concepts. Hand it to implementation.*

*Last updated: 2026-04-03*
