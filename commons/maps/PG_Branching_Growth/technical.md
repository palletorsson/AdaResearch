# PG Branching Growth — Technical

The map stages two branching strategies side by side. On the rule side, a deterministic recursion grows a tree by repeated bifurcation. On the noise side, growth follows 3D Perlin field lines through a volumetric noise function.

```gdscript
class_name RuleBasedBranch extends Node3D

@export var branch_angle: float = 25.0  # degrees
@export var length_scale: float = 0.7
@export var max_depth: int = 6

func grow(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth >= max_depth:
        return
    var end := start + direction * length
    draw_segment(start, end)
    var axis := direction.cross(Vector3.UP).normalized()
    var left := direction.rotated(axis, deg_to_rad(branch_angle))
    var right := direction.rotated(axis, deg_to_rad(-branch_angle))
    grow(end, left, length * length_scale, depth + 1)
    grow(end, right, length * length_scale, depth + 1)
```

## Noise-Driven Growth

```gdscript
class_name NoiseFieldGrowth extends Node3D

@export var noise_scale: float = 0.3
@export var step_size: float = 0.1

var noise := FastNoiseLite.new()

func grow_step(start: Vector3) -> Vector3:
    # Compute gradient of the noise field numerically
    var h := 0.01
    var dx := noise.get_noise_3dv(start + Vector3(h, 0, 0)) - noise.get_noise_3dv(start - Vector3(h, 0, 0))
    var dy := noise.get_noise_3dv(start + Vector3(0, h, 0)) - noise.get_noise_3dv(start - Vector3(0, h, 0))
    var dz := noise.get_noise_3dv(start + Vector3(0, 0, h)) - noise.get_noise_3dv(start - Vector3(0, 0, h))
    var gradient := Vector3(dx, dy, dz).normalized()
    return start + gradient * step_size
```

## Complexity

The rule-based branch at depth D produces 2^D leaf segments; the total segment count is 2^(D+1) − 1. For D=6 that is 127 segments. Time and space are both O(2^D). Beyond D=15 the structure becomes unrenderable.

Noise-driven growth is O(N·S) for N paths and S steps per path. The noise lookup dominates; a good noise implementation (hashed or precomputed lookup table) runs at nanoseconds per sample.

## Comparison

Rule-based branching is repeatable and controllable: given the same parameters, the tree is identical. Noise-driven growth is reproducible with a fixed seed but looks organic because the field's irregularities propagate into the path. The map displays both side by side and exposes their parameter knobs so the learner can see how each strategy reaches a similar final shape through different means.

## Self-Avoidance

Neither algorithm above avoids self-intersection. Real botanical growth has mechanisms to prevent branches from overlapping — apical dominance, growth hormones, physical contact. Procedural implementations add self-avoidance through repulsion from existing branches, which makes the output more realistic but also more expensive to compute.

Within the sequence, Branching_Growth is the comparison chapter. PG_Caves_Mazes will next pivot from additive to subtractive generation.

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
