# BuildEnv - Grammar Discovery RL Environment

Physics-based reinforcement learning environment for discovering construction grammars through trial and error.

## 🎯 Goal

Train an AI agent to discover stable architectural patterns by combining simple primitives into tall, spanning structures using minimal geometry.

## ✨ Key Features

### 1. **Visual Geometry** (FIXED)
All primitives now have visible meshes with distinct colors:
- **Boxes** - Tan (foundational blocks)
- **Beams** - Brown (horizontal spans)
- **Pyramids** - Gold (caps/decorative)
- **Pillars** - Gray/stone (vertical supports)
- **Wedges** - Reddish brown (ramps/angles)
- **Plates** - Light tan (flat surfaces)
- **Arches** - White/limestone (curved elements)

### 2. **Grammar Discovery System**
Automatically discovers and catalogs stable sub-structures:
- Detects repeating patterns (2-5 pieces)
- Builds motif library during training
- Rewards pattern reuse
- Enables hierarchical composition

### 3. **Enhanced Observations** (13 metrics)
```gdscript
{
    # Basic
    n, height, span_x, span_z, ke, com_margin,

    # Structural analysis
    is_stable,              # Stability flag
    connectivity,           # Contact graph size
    symmetry,              # Bilateral symmetry (0-1)
    span_efficiency,       # Span per piece
    height_efficiency,     # Height per piece
    motif_count,           # Recognized patterns
    structural_integrity   # Overall quality
}
```

### 4. **Improved Reward Function**
- **Delta rewards** - Progress-based shaping
- **Grammar bonuses** - Symmetry, connectivity, motif reuse
- **Efficiency metrics** - Height/span per piece ratios
- **Stability rewards** - Low kinetic energy bonus

### 5. **Expanded Primitive Library**
8 construction primitives (was 3):
- 0: Small cube
- 1: Long beam
- 2: Pyramid
- 3: Pillar (cylinder)
- 4: Short beam
- 5: Wedge/ramp
- 6: Flat plate
- 7: Arch segment

## 🚀 Quick Start

### Basic Usage

```gdscript
var env = BuildEnv.new()
add_child(env)

# Configure
env.enable_motif_discovery = true
env.min_motif_pieces = 2
env.max_motif_pieces = 5

# Reset
env.reset()

# Step
var action = {
    "primitive_id": 1,      # Beam
    "x": 0.0,
    "z": 0.0,
    "yaw_bin": 4,          # 90 degrees
    "motif_id": -1         # -1 = single piece
}

var result = env.step(action)
print("Reward: %.2f" % result["reward"])
print("Height: %.2f" % result["obs"]["height"])
```

### Testing in Editor

1. Create a new Scene with Node3D root
2. Add BuildEnv as child node
3. Attach `TestBuildEnv.gd` to root
4. Add Camera3D and DirectionalLight3D
5. Run scene

**Controls:**
- `SPACE` - Place random piece
- `R` - Reset environment
- `T` - Run automated test (all 8 primitives)

## 🧬 How Grammar Discovery Works

### 1. Pattern Detection
When structure stabilizes (KE < threshold):
- Extracts connected sub-graphs
- Identifies groups of 2-5 pieces
- Checks for novelty vs existing library

### 2. Motif Library
Discovered patterns stored with:
```gdscript
{
    "size": 3,
    "pattern": [piece1, piece2, piece3],
    "count": 5,              # Times observed
    "discovered_episode": 42
}
```

### 3. Hierarchical Actions
Agent can use `motif_id` to place entire patterns:
```gdscript
var action = {
    "motif_id": 0,  # Use first discovered motif
    "x": 2.0,
    "z": 1.0
}
```

### 4. Evolution
- Simple patterns discovered early (pillar + beam)
- Patterns compose into structures
- Symmetry and efficiency emerge
- Architectural grammars evolve

## 📊 Metrics & Debugging

### Debug Info
```gdscript
var result = env.step(action)
print(result["info"])
# {
#     "step": 25,
#     "episode": 142,
#     "bodies": 12,
#     "motifs_library": 7,
#     "success_episodes": 23,
#     "graph_edges": 15
# }
```

### Key Observations
- `is_stable` - Boolean stability check
- `connectivity` - How well pieces connect
- `symmetry` - Bilateral symmetry score
- `structural_integrity` - Overall quality (0-1)
- `motif_count` - Recognized patterns present

## 🎓 Expected Learning Trajectory

### Phase 1: Random Stacking (Episodes 0-50)
- Random piece placement
- Frequent collapses
- Low rewards

### Phase 2: Stability Discovery (Episodes 50-200)
- Discovers base patterns
- Learns pillar + beam = span
- First motifs appear

### Phase 3: Pattern Reuse (Episodes 200-500)
- Reuses successful motifs
- Symmetry emerges
- Height/span increase

### Phase 4: Grammar Emergence (Episodes 500+)
- Complex hierarchical structures
- Efficient minimal geometry
- Novel architectural forms

## 🔧 Configuration

```gdscript
@export var arena_size_x: float = 10.0
@export var arena_size_z: float = 10.0
@export var grid_res: float = 0.25
@export var settle_time: float = 0.8
@export var yaw_bins: int = 16
@export var enable_motif_discovery: bool = true
@export var stability_threshold: float = 0.5
@export var min_motif_pieces: int = 2
@export var max_motif_pieces: int = 5
```

## 🐛 Troubleshooting

### No geometry visible
- ✅ **FIXED** - All primitives now have MeshInstance3D
- Ground plane created automatically in `_ready()`
- Add DirectionalLight3D to scene for lighting

### Pieces fall through ground
- Check ground plane collision layer/mask
- Verify RigidBody3D layers match

### No motifs discovered
- Increase `settle_time` for stability
- Lower `stability_threshold`
- Check that structures are actually stable

## 📈 Performance Tips

1. **Reduce settle_time** - Faster episodes (0.3-0.5s)
2. **Limit max pieces** - Early termination at N pieces
3. **Batch environments** - Run multiple in parallel
4. **Cache successful episodes** - Replay for curriculum

## 🎯 RL Integration Examples

### PPO Training Loop
```gdscript
for episode in range(1000):
    env.reset()
    var states = []
    var actions = []
    var rewards = []

    for step in range(128):
        var obs = env.obs()
        var action = policy.predict(obs)
        var result = env.step(action)

        states.append(obs)
        actions.append(action)
        rewards.append(result["reward"])

        if result["done"]:
            break

    policy.update(states, actions, rewards)
```

## 📚 Next Steps

1. **Curriculum Learning** - Start with 3 primitives, add more
2. **Motif Transfer** - Save/load library between runs
3. **Multi-objective** - Height vs span vs efficiency
4. **Human Feedback** - Rate structures for aesthetics
5. **Procedural Goals** - "Build a bridge", "Build a tower"

---

**Version:** 2.0
**Date:** 2025-01-30
**License:** MIT
