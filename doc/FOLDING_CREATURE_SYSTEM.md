# Folding Creature System — Design Document v2.1

> Life in this world survives by intelligent compaction and expressive unfolding.

Folding is a **universal transformation principle** that already runs through Ada Research.
This document specifies the algorithm stack, runtime architecture, and authoring model
needed to build it in Godot — sharpened from design vision to implementation blueprint.

---

## Table of Contents

1. [Core Philosophy](#core-philosophy)
2. [Folding Already Present in Ada Research](#folding-already-present)
3. [Three Independent Axes](#three-axes)
4. [Fold DNA — Multi-Vector Topology](#fold-dna)
5. [Fold State Machine](#fold-state-machine)
6. [The FoldRig Abstraction](#fold-rig)
7. [Authoring Model vs Runtime Model](#authoring-runtime)
8. [Algorithm Stack](#algorithm-stack)
9. [Layered Pose Pipeline](#pose-pipeline)
10. [Shape Families vs Behavior Families](#shape-behavior)
11. [Creature Archetypes](#creature-archetypes)
12. [VR Interaction Verbs](#vr-interaction-verbs)
13. [Folding Zoo — All-Stage Showcase Map](#folding-zoo)
14. [Implementation Phases](#implementation-phases)
15. [Integration Map](#integration-map)

---

## Core Philosophy <a name="core-philosophy"></a>

Folding operates on four levels simultaneously:

| Level | Question | Examples |
|-------|----------|----------|
| **Morphological** | How does the body change shape? | Egg cracks, wings tuck, shell spirals, petals unfold |
| **Functional** | Why does it fold? | Defense, travel, stealth, incubation, tool mode |
| **Structural** | How does its geometry work? | Hinges, membranes, telescoping, spiral rolling, lattice collapse |
| **Symbolic** | What does it mean? | Folded=dormant memory, overfolded=trauma, refolding=healing |

A critter is not just an animal. It is a body that switches between:
**compact**, **latent**, **deployed**, **defensive**, **tool-like**, **damaged/misfolded**.

---

## Folding Already Present in Ada Research <a name="folding-already-present"></a>

### Creatures (16 across 20 stages)

The personality arc **FOE -> WARY -> NEUTRAL -> CURIOUS -> FRIEND** influences fold tendency.

**MiuraCrawler already implements this**: States (DORMANT/ALERT/CRAWL/ATTACK/FLATTEN),
`_fold_amount` from 0.0 to 1.0 driving MiuraGeometry solver, inchworm locomotion from
sinusoidal fold cycling. This IS the prototype.

### Catalyst (10 modes, absorbs into hand)

The crystal pickup IS a fold — compact crystal -> deployed hand-tool in 0.35 seconds.

### Capacity Ladder (L1-L6)

| Level | Fold Interaction |
|-------|-----------------|
| L1 Observe | See folds |
| L2 Touch | Feel folds |
| L3 Manipulate | Change folds |
| L4 Construct | Create folds |
| L5 Control | Tune fold params |
| L6 Embody | BE the fold |

### Fractal Database

*"Same tree, different folds. The compression IS the index."*
875 entities through 5 fold lenses at variable depths.

---

## Three Independent Axes <a name="three-axes"></a>

**Critical design correction**: Personality, fold state, and activity are three
**related but distinct** axes. A creature can be emotionally curious while physically
folded. Shy curiosity, wounded friendliness, deceptive openness, sleeping trust.

```gdscript
# Three independent state axes
var affect: String = "neutral"      # foe, wary, neutral, curious, friend
var fold_state: FoldState = FoldState.FOLDED  # physical body configuration
var activity: String = "idle"       # idle, fleeing, feeding, attacking, hatching, signaling
```

### How They Interact

Affect **influences** fold choice but does not determine it:

| Affect | Typical Fold | But Also... |
|--------|-------------|-------------|
| foe | defensive | deployed-aggressive (display attack), folded-ambush |
| wary | folded, ready to flee | unfolding cautiously to peek |
| neutral | resting fold | deployed-idle (sunbathing) |
| curious | unfolding | still folded but leaning, stretching one limb |
| friend | deployed/open | folded-sleeping-near-player (trust without display) |

Activity modifies both:

| Activity | Effect on Fold | Effect on Affect Expression |
|----------|---------------|---------------------------|
| fleeing | rapid refolding | wary overrides all |
| feeding | partial deploy (mouth) | relaxed regardless of base affect |
| attacking | full deploy or snap-strike | aggressive regardless of base affect |
| hatching | uncontrolled unfolding | no affect yet — pure body logic |
| signaling | rhythmic fold display | curious/friend = beautiful, foe = threatening |

This makes creatures feel alive instead of mechanical state machines.

---

## Fold DNA — Multi-Vector Topology <a name="fold-dna"></a>

### Fold Topology as Tendency Vector

`fold_axis` as a single float is semantically muddy. Linear, radial, spiral, bilateral,
nested, chaotic are not points on one line. Use a **tendency vector** — closer to biology
where a creature can have mostly bilateral organization with spiral tail and nested shell.

```gdscript
# ── FOLD TOPOLOGY (tendency vector — normalizes to 1.0) ──────
@export_range(0.0, 1.0) var fold_linear: float = 0.0     ## Accordion, telescoping
@export_range(0.0, 1.0) var fold_radial: float = 0.0     ## Fan, petal, starfish
@export_range(0.0, 1.0) var fold_spiral: float = 0.0     ## Shell, coil, scroll
@export_range(0.0, 1.0) var fold_bilateral: float = 0.0  ## Wing, jaw, symmetric limbs
@export_range(0.0, 1.0) var fold_nested: float = 0.0     ## Russian doll, chambered
@export_range(0.0, 1.0) var fold_chaotic: float = 0.0    ## Misfold, fungal, tangled
```

Same treatment for fold_material:

```gdscript
# ── FOLD MATERIAL (tendency vector) ───────────────────────────
@export_range(0.0, 1.0) var fold_shell: float = 0.0      ## Hard plates, chitin, bone
@export_range(0.0, 1.0) var fold_membrane: float = 0.0   ## Leaf, leather, cartilage, wing
@export_range(0.0, 1.0) var fold_flesh: float = 0.0      ## Skin, gut, petal, jelly
```

### Scalar Fold Parameters

```gdscript
# ── FOLD DYNAMICS ─────────────────────────────────────────────
@export_range(0.0, 1.0) var fold_speed: float = 0.5      ## 0=slow bloom 0.5=reactive 1.0=instant
@export_range(0.0, 1.0) var fold_memory: float = 0.7     ## 0=permanently deforms 1.0=always returns
@export_range(0.0, 1.0) var fold_risk: float = 0.15      ## 0=safe 0.5=can jam 1.0=mutates easily
@export_range(0.0, 1.0) var fold_depth: float = 0.5      ## 0=surface only 1.0=full body reorganization
@export_range(0.0, 1.0) var fold_energy: float = 0.5     ## 0=cheap/passive 1.0=metabolically expensive
```

### fold_energy — The Missing Parameter

How metabolically expensive folding is. This connects to:

- Some creatures fold safely but slowly (low energy, low speed)
- Some snap shut but exhaust themselves (high energy, high speed)
- Some stay open only briefly (high energy deployed state)
- Damaged creatures cannot complete deployment (low energy from injury)
- Player feeding/warming gives fold energy
- Cold environments reduce fold energy (hypothermia = can't unfold)

### Kingdom Biases (tendency vectors)

| Kingdom | Topology Bias | Material Bias | Speed | Memory | Energy |
|---------|--------------|---------------|-------|--------|--------|
| Tree | linear+radial | shell | slow | high | low |
| Creature | bilateral+nested | membrane+shell | reactive | medium | medium |
| Flower | radial+spiral | membrane+flesh | rhythmic | low | low |
| Fungus | chaotic+nested | flesh | slow | low | high |
| Hybrid | any | any | any | any | varies |

---

## Fold State Machine <a name="fold-state-machine"></a>

```gdscript
enum FoldState {
    EGG,         # Compressed potential — not yet born
    HATCHING,    # Uncontrolled first unfolding
    FOLDED,      # Compact resting/travel/carry mode
    UNFOLDING,   # Transition to deployed
    DEPLOYED,    # Full body expression — active
    DEFENSIVE,   # Emergency re-fold for protection
    REFOLDING,   # Voluntary return to compact
    MISFOLDED,   # Damaged / corrupted fold pattern
    DORMANT,     # Deep fold — hibernation / death-like
}
```

### State Transitions

```
EGG ──[warmth/time/player care]──> HATCHING ──> FOLDED
FOLDED ──[stimulus/need]──> UNFOLDING ──> DEPLOYED
DEPLOYED ──[threat]──> DEFENSIVE
DEPLOYED ──[rest/carry]──> REFOLDING ──> FOLDED
DEFENSIVE ──[safe]──> REFOLDING ──> FOLDED
Any ──[damage/corruption]──> MISFOLDED
MISFOLDED ──[healing/refold care]──> REFOLDING
FOLDED ──[long rest/no energy]──> DORMANT
DORMANT ──[stimulus]──> UNFOLDING
```

---

## The FoldRig Abstraction <a name="fold-rig"></a>

The formal runtime container. Every foldable creature has a FoldRig that contains
everything needed to animate its fold behavior.

```gdscript
class_name FoldRig
extends Resource

## Solver — typed resource, not a string tag
@export var solver: FoldSolver = null  # BoneFoldSolver, ChainFoldSolver, or ShellFoldSolver

## Structural definition (articulation — how connected things deform)
@export var segments: Array[FoldSegmentData] = []
@export var constraints: Array[FoldConstraintData] = []

## Authored poses — typed resources with metadata
@export var poses: Dictionary = {}  # StringName -> FoldPoseResource

## Material response profile
@export var material_profile: FoldMaterialProfile = null

## Spring dynamics
@export var base_stiffness: float = 10.0
@export var base_damping: float = 0.82
@export var base_fold_speed: float = 0.5

## Energy budget
@export var max_fold_energy: float = 1.0

## Supported states — not every creature supports every state
@export var allowed_fold_states: Array[int] = []  # FoldState enum values
## e.g., some creatures never DORMANT, some can't DEFENSIVE, some always semi-unfolded

## Fold limits
@export var min_fold_amount: float = 0.0   # Some creatures never fully close
@export var max_fold_amount: float = 1.0   # Some creatures never fully open

## Capabilities
@export var supports_misfold: bool = true
@export var supports_latch: bool = false
@export var supports_nesting: bool = false
@export var supports_inversion: bool = false
@export var is_hatchable: bool = false
```

### FoldSolver (base class)

```gdscript
class_name FoldSolver
extends Resource

## Compute fold pose from fold_amount and fold_tension.
## Returns data the pose pipeline can apply.
func compute_fold(fold_amount: float, fold_tension: float, segments: Array[FoldSegmentData]) -> Dictionary:
    return {}  # Override in subclasses

## Subclasses: BoneFoldSolver, ChainFoldSolver, ShellFoldSolver
```

### FoldPoseResource

```gdscript
class_name FoldPoseResource
extends Resource

@export var pose_name: StringName = ""
@export var segment_transforms: Dictionary = {}  # segment_name -> Transform3D
@export var compatible_states: Array[int] = []   # Which FoldStates can use this pose
@export var blend_curve: Curve = null             # Custom ease for blending into this pose
@export var has_latch: bool = false               # Snaps to exact pose at threshold
@export var latch_threshold: float = 0.95         # How close fold_amount must be to latch
@export var symmetry: String = "bilateral"        # bilateral, radial, asymmetric
```

### FoldSegmentData

```gdscript
class_name FoldSegmentData
extends Resource

@export var segment_name: String = ""
@export var fold_axis: Vector3 = Vector3.RIGHT
@export var angle_closed: float = 0.0
@export var angle_open: float = 90.0
@export var parent_segment: String = ""     # Empty = root
@export var parent_min_fold: float = 0.0    # Parent must be this open before child can open
@export var material_type: String = "bone"  # "bone", "membrane", "flesh"
@export var spring_stiffness: float = 10.0
@export var spring_damping: float = 0.82
```

### FoldConstraintData

```gdscript
class_name FoldConstraintData
extends Resource

@export var segment_name: String = ""
@export var min_angle: float = 0.0
@export var max_angle: float = 90.0
@export var latch_angle: float = -1.0       # Snap to this angle if within threshold
@export var latch_threshold: float = 5.0    # Degrees
@export var break_force: float = -1.0       # -1 = unbreakable; positive = can misfold if exceeded
```

### FoldMaterialProfile

```gdscript
class_name FoldMaterialProfile
extends Resource

@export var shell_ratio: float = 0.0   # Hard surface
@export var membrane_ratio: float = 0.0 # Semi-soft
@export var flesh_ratio: float = 0.0    # Soft/biological
@export var crease_visibility: float = 0.5  # How visible fold lines are
@export var wrinkle_response: float = 0.3   # How much surface wrinkles during fold
```

### Each creature has four resources

```
CritterDNA      — what it IS (genome, heritable)
BodyGraph       — how it was BUILT (topology from graph grammar)
FoldRig         — how it MOVES (poses, constraints, solver)
BehaviorProfile — how it ACTS (affect, activity patterns)
```

### Ownership Boundary: BodyGraph vs FoldRig

**BodyGraph owns** (what is connected):
- Topology graph (nodes = body modules, edges = connections)
- Attachment relations (which module connects where)
- Semantic body regions (head, thorax, limb_left_1, tail_segment_3)
- Growth lineage (which grammar rule produced this module)
- Socket types (hinge, ball, fixed, membrane)

**FoldRig owns** (how connected things deform):
- Articulation data (fold axes, angle ranges per segment)
- Fold poses (authored target transforms per state)
- Fold constraints (joint limits, parent-gating, latch rules)
- Solver configuration (which algorithm drives this body)
- Material fold response (wrinkle, crease visibility, surface deformation)
- Per-segment runtime spring parameters

**The generation pipeline**: BodyGraph is created first (from DNA + graph grammar).
FoldRig is derived from BodyGraph (socket types -> fold axes, topology -> solver choice,
module types -> material profile). Some FoldRig data is then hand-tuned by designer.

---

## Authoring Model vs Runtime Model <a name="authoring-runtime"></a>

### Authoring Model — What the designer creates

| Authored Element | Format | Who Creates It |
|-----------------|--------|---------------|
| Fold poses | FoldRig.poses dictionary | Designer or graph grammar |
| Fold hierarchy | FoldSegmentData tree | Designer or graph grammar |
| Fold constraints | FoldConstraintData array | Designer |
| Hatch profile | Egg seed parameters | DNA + designer |
| Misfold variants | Noise/asymmetry rules | Designer |
| VR interaction hooks | Signal connections | Designer |
| Fold gene defaults | CritterDNA values | Kingdom bias + evolution |

### Runtime Model — What the game computes

| Computed Element | Algorithm | Frequency |
|-----------------|-----------|-----------|
| State transitions | FSM | Per event |
| Spring update | Damped spring | Per physics frame |
| Pose blend | Transform interpolation | Per physics frame |
| IK correction | FABRIK | Per physics frame (deployed only) |
| Misfold offset | Noise + asymmetry | Per physics frame (misfolded only) |
| Hit reaction | Impulse decay | Per physics frame (on damage) |
| Bond/fold response | Transmutation delta | Per interaction event |
| Fold energy drain | Metabolism tick | Per second |
| Fold tension update | Force accumulation | Per physics frame |
| Corruption spread | CA step | Per second (misfolded only) |

### Runtime Variables (per creature instance)

```gdscript
# ── Core fold state ───────────────────────────────────────────
var fold_state: FoldState = FoldState.EGG
var fold_amount: float = 0.0         # 0 = maximally folded, 1 = fully deployed
var target_fold: float = 0.0
var fold_velocity: float = 0.0

# ── Fold tension (stored mechanical stress) ───────────────────
var fold_tension: float = 0.0        # Stored energy / stress
# - Compressed creature stores jump force (tension -> kinetic)
# - Over-tension causes misfold risk
# - Healing reduces tension
# - Species signal by increasing visible tension
# - Player squeezing too hard raises tension -> misfold threshold

# ── Fold energy (metabolic budget) ────────────────────────────
var fold_energy: float = 1.0         # Available energy for folding
var fold_energy_max: float = 1.0     # From DNA
# - Each fold transition costs energy
# - Staying deployed costs ongoing energy (for high fold_energy species)
# - Resting in folded state recovers energy
# - Player feeding restores energy
# - Cold/damage reduces max energy

# ── Misfold state ─────────────────────────────────────────────
var misfold_amount: float = 0.0      # 0 = healthy, 1 = fully corrupted
var misfold_seed: int = 0            # For deterministic asymmetry
```

---

## Per-Physics-Frame Update Order <a name="update-order"></a>

```
 1. Read inputs/events (VR hand, damage, environment)
 2. Update affect and activity axes
 3. Evaluate fold FSM transitions
 4. Compute target_fold from state + affect + activity
 5. Consume/recover fold_energy (metabolism tick)
 6. Update fold spring: velocity, fold_amount, fold_tension
 7. Evaluate misfold thresholds (tension > limit && risk > threshold)
 8. Compute solver pose (BoneFoldSolver / ChainFoldSolver / ShellFoldSolver)
 9. Apply IK correction (DEPLOYED state only)
10. Apply misfold offset (MISFOLDED state only)
11. Apply hit reaction (decaying impulse)
12. Apply secondary motion (breathing, idle sway)
13. Commit final pose to scene tree
14. Update VFX / shader params / audio / haptics
```

### Note on fold_tension

Currently one variable handling both stored spring energy (useful) and accumulated
strain (harmful). If these need to separate later:

- **elastic_charge**: useful stored force (jump power, snap speed)
- **stress_load**: harmful accumulated strain (misfold risk, fatigue)

For v1, keep as one variable. The split becomes necessary when creatures need to be
highly charged without being damaged, or highly stressed without useful stored force.

---

## Algorithm Stack <a name="algorithm-stack"></a>

### The Key Separation

- **What form the creature wants to be in** → FSM + affect + activity
- **How the body moves into that form** → Runtime stack (per frame)
- **How the body was generated** → Generation stack (at birth / mutation)

### Runtime Stack (ordered by priority)

#### 1. Finite State Machine
Foundation. Affect, activity, VR interaction, threat, energy all drive transitions.

#### 2. Spring-Damped Fold Update
```gdscript
func update_fold(delta: float) -> void:
    # Energy gate: can't deploy without energy
    if fold_energy <= 0.0 and target_fold > fold_amount:
        target_fold = fold_amount

    # Clamp to rig limits
    target_fold = clamp(target_fold, fold_rig.min_fold_amount, fold_rig.max_fold_amount)

    # Spring dynamics (stiffness and damping from FoldRig)
    var force = (target_fold - fold_amount) * fold_rig.base_stiffness
    fold_velocity += force * delta
    fold_velocity *= fold_rig.base_damping
    fold_amount += fold_velocity * delta
    fold_amount = clamp(fold_amount, 0.0, 1.0)

    # Tension accumulates from motion
    fold_tension += abs(fold_velocity) * delta * 0.1
    fold_tension *= 0.995  # Slow natural decay
    fold_tension = clamp(fold_tension, 0.0, 1.0)

    # Energy cost proportional to motion and DNA fold_energy gene
    fold_energy -= abs(fold_velocity) * delta * dna.fold_energy * 0.01
    fold_energy = clamp(fold_energy, 0.0, fold_energy_max)

    # Misfold risk from over-tension
    if fold_tension > 0.8 and dna.fold_risk > 0.3:
        misfold_amount += (fold_tension - 0.8) * dna.fold_risk * delta
```

#### 3. Hierarchical Fold Tree
Propagate fold transforms through FoldSegment parent-child chains.

#### 4. Pose Interpolation
Main visible folding. Blend between authored poses based on fold_amount.

#### 5. Constraint Enforcement
Joint limits, latch points, parent-gating.

#### 6. FABRIK IK (deployed limbs only)
Ground contact, reach targets after fold opens.

#### 7. Spline/Chain Solver (accordion bodies)
Variable-length spine with compression/extension.

### Generation Stack (at birth / mutation)

#### 8. Graph Grammar for Body Plans

Development stack below graph grammar:

```
1. Species template    (from DNA kingdom + fold topology vector)
2. Body graph generation   (graph grammar rewrite rules)
3. Module instantiation    (segments, limbs, shells from graph nodes)
4. Fold rig assignment     (solver type, segment data from graph edges)
5. Fold pose authoring     (derive folded/deployed poses from topology)
```

Output: a concrete FoldRig resource.

```gdscript
# Generated creature ends with:
{
    "body_graph": [...],           # Topology
    "segment_list": [...],         # Physical pieces
    "attachment_sockets": [...],   # Where things connect
    "default_fold_axes": [...],    # Per-segment fold direction
    "allowed_fold_states": [...],  # Which states this body supports
    "deform_profile": {...},       # How it deforms under stress
    "materials": [...]             # Surface properties
}
```

#### 9. Cellular Automata (corruption/healing surfaces)
#### 10. Reaction-Diffusion (surface patterning)
#### 11. Blend Shapes (soft detail)
#### 12. Shape Matching / PBD (advanced, defer)

---

## Layered Pose Pipeline <a name="pose-pipeline"></a>

**Critical architecture**: Do not use a single `set_bone_global_pose_override()`.
Use a layered pipeline where each layer contributes additively.

```
final_pose = base_pose + fold_contribution + IK_correction + misfold_offset + hit_reaction + secondary_motion
```

### Layer Definitions

| Layer | Source | Priority | When Active |
|-------|--------|----------|-------------|
| **Base pose** | Authored rest pose from FoldRig | Always | Always |
| **Fold contribution** | FoldRig solver (bone/chain/shell) | Always | When fold_amount != rest |
| **IK correction** | FABRIK on deployed limbs | After fold | DEPLOYED state only |
| **Misfold offset** | Noise + asymmetry per segment | Additive | MISFOLDED state only |
| **Hit reaction** | Impulse with exponential decay | Additive | On damage event |
| **Secondary motion** | Jiggle, breathing, idle sway | Additive | Always (scaled by activity) |

### Implementation

```gdscript
func compute_final_pose(delta: float) -> void:
    # Layer 1: Base
    var pose := rig.get_base_pose()

    # Layer 2: Fold
    var fold_pose := rig.solver.compute_fold(fold_amount, fold_tension)
    pose = pose.blend(fold_pose, 1.0)

    # Layer 3: IK (only when deployed)
    if fold_state == FoldState.DEPLOYED:
        var ik_correction := ik_solver.solve(pose, ground_targets)
        pose = pose.apply_ik(ik_correction)

    # Layer 4: Misfold (additive noise)
    if misfold_amount > 0.01:
        var misfold_offset := compute_misfold_noise(misfold_amount, misfold_seed)
        pose = pose.add_offset(misfold_offset)

    # Layer 5: Hit reaction (decaying impulse)
    if hit_impulse > 0.01:
        pose = pose.add_offset(hit_direction * hit_impulse)
        hit_impulse *= 0.85

    # Layer 6: Secondary motion
    pose = pose.add_offset(compute_breathing(delta) + compute_idle_sway(delta))

    apply_pose(pose)
```

---

## Shape Families vs Behavior Families <a name="shape-behavior"></a>

**Critical distinction**: A single geometry family supports multiple behaviors.
An accordion body can be locomotion, defense, OR communication.

### Geometric Fold Families

| Family | Geometry | Examples |
|--------|----------|----------|
| **Curl** | Spiral disc / roll | Pill bug, snail, rolled leaf |
| **Accordion** | Linear pleat segments | Worm, bellows, telescope |
| **Wing-wrap** | Bilateral membrane fold | Moth, bat, flower bud |
| **Nested shell** | Concentric layers | Hermit crab, onion, matryoshka |
| **Radial bloom** | Fan/star opening | Starfish, flower, parachute |
| **Inversion** | Inside-out flip | Sea cucumber, glove, pouch |
| **Pleat/ribbon** | Zigzag flat fold | Origami, fan, carpet |

### Behavioral Fold Families

| Family | Purpose | Which Geometries? |
|--------|---------|-------------------|
| **Incubate** | Egg warmth, protection | nested, curl, wing-wrap |
| **Defend** | Armor, shield, lockdown | curl, nested, wing-wrap |
| **Carry** | Transport, inventory | curl, nested, accordion |
| **Hide** | Camouflage, stealth, dormancy | any (flatten) |
| **Deploy** | Attack, locomotion, tool use | accordion, bloom, wing-wrap |
| **Signal** | Communication, display, attract | bloom, accordion, pleat |
| **Heal** | Refold, repair, nurture | any (smooth, latch) |
| **Misfold** | Corruption, disease, mutation | any (distorted) |

### Cross-Mapping Examples

| Creature | Geometry | Behavior 1 | Behavior 2 | Behavior 3 |
|----------|----------|-----------|-----------|-----------|
| Miura Crawler | accordion | deploy (locomotion) | hide (flatten) | defend (compress) |
| Shell Librarian | nested shell | carry (memory chambers) | signal (display lore) | defend (close up) |
| Pocket Moth | wing-wrap | signal (luminous display) | carry (dust/organisms) | hide (folded packet) |
| Bridge Eel | pleat/ribbon | deploy (bridge tool) | carry (roll transport) | signal (wave pattern) |

---

## Creature Archetypes <a name="creature-archetypes"></a>

### Mapping to Existing Origami Creatures

| Existing Creature | Geometry Family | Fold Topology Vector (dominant) |
|-------------------|----------------|-------------------------------|
| Miura Crawler | accordion | bilateral=0.8, linear=0.6 |
| Kaleidocycle Enemy | bloom (rotational) | radial=0.9, spiral=0.3 |
| Kresling Spire | accordion (vertical) | spiral=0.7, linear=0.5 |
| Scissor Stalker | pleat/ribbon | bilateral=0.9, linear=0.4 |
| Origami Droideka | nested shell | radial=0.6, nested=0.8 |
| Armadillo Droideka | nested shell + curl | bilateral=0.5, nested=0.7, spiral=0.3 |
| Waterbomb Enemy | wing-wrap | bilateral=0.7, radial=0.4 |
| Shell Roller | curl | spiral=0.9, bilateral=0.2 |
| Spring Hopper | accordion | linear=0.9, bilateral=0.3 |
| Goomba Box | wing-wrap (simple) | bilateral=0.8 |

### New Folding Creatures

1. **Seedling Accordion**: linear=0.8, radial=0.3. Membrane+flesh. High energy cost.
2. **Pocket Moth**: bilateral=0.9, nested=0.3. Membrane. Low energy, fragile.
3. **Shell Librarian**: nested=0.9, spiral=0.4. Shell. High memory, low risk.
4. **Misfold Hound**: bilateral=0.6, chaotic=0.7. Flesh+bone. Corrupted fold_memory.
5. **Bridge Eel**: linear=0.9. Membrane+bone. High fold_energy cost when deployed.
6. **Bloom Surgeon**: radial=0.8, bilateral=0.3. Membrane. Precise constraints.

---

## VR Interaction Verbs <a name="vr-interaction-verbs"></a>

### Core Four (Phase 3 — implement first)

| Verb | VR Action | Fold Effect | Tension/Energy |
|------|-----------|-------------|---------------|
| **Compress** | Squeeze with grip | Package mode, store spring energy | Tension ++ |
| **Fan open** | Pull two points apart | Deploy wings/frills | Energy -- |
| **Tuck** | Push parts inward | Compact for transport | Tension -- |
| **Smooth** | Stroke wrinkled surface | Heal / calm misfold | Misfold --, Tension -- |

### Extended Set (later phases)

| Verb | VR Action | Fold Effect |
|------|-----------|-------------|
| Cradle | Hold egg near chest | Heartbeat response, incubation |
| Peel | Pull membrane edges | Reveal hidden layers |
| Invert | Turn inside-out | Expose internal organs/tools |
| Curl | Guide spiral motion | Defensive mode |
| Wrap | Guide folding around | Package mode |
| Latch | Align + snap | Lock fold in place |

### Transmutation Bond Integration

| Transmutation Interaction | Fold Verb | Effect |
|--------------------------|-----------|--------|
| observe (+0.02) | Watch fold patterns | Learn fold language |
| touch (+0.05) | Feel fold texture | Discover material type |
| feed (+0.10) | Offer warmth / energy | Restore fold_energy |
| proximity (+0.005) | Be near folded creature | Passive tension reduction |
| protect (+0.12) | Shield from corruption | Block misfold spread |

---

## Folding Zoo — All-Stage Showcase Map <a name="folding-zoo"></a>

A dedicated map demonstrating every fold state, geometry family, behavior family,
and VR interaction. The zoo is organized as a walk-through progression matching
the game's fold arc.

### Zoo Layout (12x12 grid)

```
Row 0-1:  ENTRANCE + Overview infoboard
Row 2-3:  EGG CHAMBER — Incubation stations, egg varieties
Row 4-5:  HATCH THEATER — Live hatching demonstrations
Row 6-7:  GEOMETRY GALLERY — One pen per fold family (7 pens)
Row 8-9:  BEHAVIOR RING — Same creatures, different behaviors
Row 10:   MISFOLD WARD — Corruption, healing, refold care
Row 11:   FOLD LANGUAGE AMPHITHEATER — Communication displays
```

### Exhibit Design

#### Zone 1: Egg Chamber (rows 2-3)

| Station | Egg Type | Player Interaction | What It Teaches |
|---------|----------|-------------------|-----------------|
| Warm Nest | Spiral egg | Cradle near chest | fold_energy from warmth |
| Vibration Pad | Segmented egg | Shake gently | fold_speed imprinting |
| Cold Stone | Soft egg | Observe (no touch) | High fold_risk from neglect |
| Light Bath | Nested egg | Rotate in light | fold_memory development |

#### Zone 2: Hatch Theater (rows 4-5)

Live hatch events cycling every 60 seconds. Each shows a different hatch pattern:
- Explosive crack (high fold_speed, shell material)
- Slow peel (low fold_speed, membrane material)
- Spiral unwind (spiral topology)
- Nested reveal (nested topology — layers open sequentially)
- Misfold hatch (high fold_risk — something goes wrong)

#### Zone 3: Geometry Gallery (rows 6-7)

Seven pens, one per geometric fold family. Each contains one creature demonstrating
its fold family with VR interaction handles.

| Pen | Geometry Family | Creature | Player Can... |
|-----|----------------|----------|--------------|
| 1 | Curl | Shell Roller variant | Roll it, unroll it, watch legs emerge |
| 2 | Accordion | Miura Crawler (existing) | Compress for jump, extend for reach |
| 3 | Wing-wrap | Pocket Moth | Unfold wings, see luminous pattern |
| 4 | Nested shell | Shell Librarian | Rotate layers, open memory chambers |
| 5 | Radial bloom | Bloom Surgeon | Watch petals fan open, tool limbs deploy |
| 6 | Inversion | Pouch Creature (new) | Turn inside-out, reveal internal organs |
| 7 | Pleat/ribbon | Bridge Eel | Unroll into bridge, roll back up |

#### Zone 4: Behavior Ring (rows 8-9)

Same accordion creature shown in 7 behavioral modes:

| Enclosure | Behavior | What Creature Does | fold_tension / fold_energy visible |
|-----------|----------|-------------------|----------------------------------|
| A | Incubate | Wrapped around its own egg | Low tension, medium energy |
| B | Defend | Locked into ball, rattling | High tension, high energy |
| C | Carry | Folded with resource inside | Low tension, low energy |
| D | Hide | Flattened, camouflaged | Zero tension, zero energy |
| E | Deploy | Full locomotion, reaching | Medium tension, draining energy |
| F | Signal | Rhythmic fold display | Oscillating tension, low energy |
| G | Heal | Smooth-pulsing near wounded creature | Negative tension flow |

#### Zone 5: Misfold Ward (row 10)

| Bed | Condition | Visual | Player Heals By... |
|-----|-----------|--------|-------------------|
| 1 | Jammed hinge | One limb stuck half-open, trembling | Smooth + gentle fan-open |
| 2 | Over-compressed | Body crushed into wrong shape | Slow, careful fan-open |
| 3 | Tangled | Multiple segments knotted | Methodical tuck + smooth |
| 4 | Corrupted surface | CA-spread dark patches | Smooth repeatedly |
| 5 | Wrong crease | Folds on wrong axis | Re-orient with both hands |

#### Zone 6: Fold Language Amphitheater (row 11)

Creatures communicate through fold patterns. Player sits center while creatures
around the ring perform fold-displays that convey meaning:

- Greeting: slow bilateral unfold, hold, refold
- Warning: rapid accordion compress-release
- Invitation: spiral unwind toward player
- Distress: asymmetric trembling, partial misfold
- Joy: full radial bloom, sustained

### Zoo as Debug Harness

The zoo is not just pedagogical — it is a serious development instrument.

**Debug overlay (toggle with slider or push button):**
- Per-creature readout: fold_amount, fold_tension, fold_energy, misfold_amount
- Three-axis display: current affect / activity / fold_state
- Solver visualization: active constraints highlighted, fold axes drawn
- Segment-level: per-segment spring state, latch status
- Hatch replay: trigger any hatch pattern on demand
- Global controls: master fold_amount slider, tension injection, energy drain

**Test scenarios (push-button activated):**
- Force all creatures to DEPLOYED
- Force all creatures to MISFOLDED
- Trigger mass hatch event
- Inject tension spike (test misfold threshold)
- Drain all energy (test energy-gated folding)
- Reset all to EGG state

### Zoo as Fold Progression

The zoo walk IS the game's fold arc:

| Zone | Phase | What Player Learns |
|------|-------|-------------------|
| Egg Chamber | 1. Egg | Potential, care, incubation |
| Hatch Theater | 2. Hatch | Vulnerability, first unfolding |
| Geometry Gallery | 3. Package/Deploy | Body types, VR verbs |
| Behavior Ring | 4. Deploy | Same body, many purposes |
| Misfold Ward | 5. Misfold | Damage, healing, care |
| Amphitheater | 6. Refold | Communication, co-creation |

### Zoo map_data.json Structure

```json
{
  "name": "Folding_Zoo",
  "size": [12, 12],
  "description": "All fold stages, geometry families, and behaviors in one walk-through",
  "layers": {
    "structure": { ... },
    "utilities": {
      "infoboards": [
        { "position": [1, 0], "content": "fold_overview" },
        { "position": [0, 2], "content": "egg_folding" },
        { "position": [0, 4], "content": "hatch_patterns" },
        { "position": [0, 6], "content": "geometry_families" },
        { "position": [0, 8], "content": "behavior_families" },
        { "position": [0, 10], "content": "misfold_healing" },
        { "position": [0, 11], "content": "fold_language" }
      ],
      "sliders": [
        { "position": [11, 6], "param": "global_fold_amount", "label": "Fold Amount" },
        { "position": [11, 7], "param": "global_fold_tension", "label": "Tension" },
        { "position": [11, 8], "param": "global_fold_energy", "label": "Energy" }
      ]
    },
    "interactables": {
      "fold_creatures": [
        { "position": [2, 2], "type": "egg_station", "egg_type": "spiral" },
        { "position": [4, 2], "type": "egg_station", "egg_type": "segmented" },
        { "position": [6, 2], "type": "egg_station", "egg_type": "soft" },
        { "position": [8, 2], "type": "egg_station", "egg_type": "nested" },
        { "position": [2, 6], "type": "fold_pen", "geometry": "curl" },
        { "position": [4, 6], "type": "fold_pen", "geometry": "accordion" },
        { "position": [6, 6], "type": "fold_pen", "geometry": "wing_wrap" },
        { "position": [8, 6], "type": "fold_pen", "geometry": "nested_shell" },
        { "position": [2, 7], "type": "fold_pen", "geometry": "radial_bloom" },
        { "position": [4, 7], "type": "fold_pen", "geometry": "inversion" },
        { "position": [6, 7], "type": "fold_pen", "geometry": "pleat_ribbon" }
      ]
    }
  }
}
```

---

## Implementation Phases <a name="implementation-phases"></a>

### Phase 1: Minimal Fold Runtime

Build only:
- `FoldCritter` base class (FSM + spring + fold_amount + fold_tension + fold_energy)
- `FoldRig` resource (segments, poses, solver_type)
- Two poses: folded / deployed
- One solver: BoneFoldRig
- Wire to one existing creature (refactor MiuraCrawler)

### Phase 2: Three Solvers

- `BoneFoldRig` — shells, wings, limbs (hierarchical segments)
- `ChainFoldRig` — accordion bodies, tails, necks (spline-based)
- `ShellFoldRig` — nested layers, chambered creatures

### Phase 3: Four VR Verbs

- Compress, Fan open, Tuck, Smooth
- Each modifies fold_amount, fold_tension, or misfold_amount
- Haptic feedback on latch points

### Phase 4: Egg + Hatch

- Egg state, incubation mechanics
- Hatch event, care imprint
- fold_energy determines hatch success

### Phase 5: Misfold + Healing

- Corruption parameter, asymmetry noise
- Jammed constraints, wrong-pose interpolation
- Healing through VR smooth verb

### Phase 6: Folding Zoo Map

- Build zoo layout with all exhibits
- One creature per geometry family
- Behavior ring demonstrations
- Global fold parameter sliders

### Phase 7: Procedural Generation

- Graph grammar for body plans
- Fold-aware body graph -> FoldRig generation
- Biome influence on fold topology

---

## Integration Map <a name="integration-map"></a>

| Existing System | File | Integration Point |
|----------------|------|-------------------|
| HazardCreatureBase | `commons/hazards/hazard_creature_base.gd` | FoldCritter wraps or extends; affect axis maps to personality |
| CritterDNA | `algorithms/nature_system/dna/critter_dna.gd` | Add fold topology vectors + dynamics scalars |
| CreatureMorphology | `algorithms/nature_system/morphology/creature_morphology.gd` | Spine system -> fold-aware; output includes FoldRig |
| CritterTraitMapper | `algorithms/nature_system/dna/critter_trait_mapper.gd` | Map fold genes to shader params |
| TransmutationManager | `algorithms/nature_system/systems/transmutation_manager.gd` | Bond interactions = fold interactions |
| EvolutionSystem | `algorithms/nature_system/systems/evolution_system.gd` | Fold topology vectors participate in crossover |
| HazardManager | `commons/managers/HazardManager.gd` | Personality -> affect axis (no longer 1:1 with fold) |
| EcosystemManager | `commons/managers/EcosystemManager.gd` | Biome fold pressure, fold ecology |
| BecomingCatalyst | `commons/hazards/becoming_catalyst/becoming_catalyst.gd` | Crystal absorption as fold |
| soft_stages.json | `commons/maps/soft_stages.json` | Stage drives fold complexity unlocks |
| MiuraCrawler | `commons/hazards/miura_crawler/miura_crawler.gd` | First refactor target -> FoldCritter |
| ProximitySpawner | `commons/hazards/proximity_spawner.gd` | Spawn in folded state |

---

*v2.1: All v2 content plus: typed FoldSolver (not string), FoldPoseResource with metadata,
BodyGraph/FoldRig ownership boundary, explicit per-frame update order, allowed_fold_states
per creature, fold_tension future split note, zoo as debug harness, min/max fold limits.*

*Last updated: 2026-04-03*
