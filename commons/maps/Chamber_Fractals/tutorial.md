# Chamber Fractals

Catalyst projectiles branch. Hydra regrows.

Build the fractal catalyst.

```gdscript
class_name FractalCatalyst extends Node3D

@export var branch_depth: int = 2
@export var branches_per_hit: int = 4

func fire(aim: Vector3) -> void:
    var projectile := FRACTAL_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = aim * 10.0
    projectile.branch_depth = branch_depth
    projectile.branches_per_hit = branches_per_hit
    get_tree().root.add_child(projectile)
```

Each projectile carries its own depth. On impact, it branches.

Projectile on impact.

```gdscript
class_name FractalProjectile extends RigidBody3D

@export var branch_depth: int = 2
@export var branches_per_hit: int = 4

func _on_body_entered(body: Node) -> void:
    if branch_depth > 0:
        spawn_branches()
    queue_free()

func spawn_branches() -> void:
    for i in branches_per_hit:
        var angle: float = i * TAU / branches_per_hit
        var direction := Vector3(cos(angle), randf_range(-0.3, 0.3), sin(angle))
        var child := FRACTAL_PROJECTILE_SCENE.instantiate()
        child.global_position = global_position
        child.linear_velocity = direction * 6.0
        child.branch_depth = branch_depth - 1
        child.branches_per_hit = branches_per_hit
        get_tree().root.add_child(child)
```

Branches spawn with decremented depth. At depth 0, the branch simply dies.

Build the hydra.

```gdscript
class_name FractalHydra extends CharacterBody3D

@export var initial_heads: int = 3

var heads: Array = []

func _ready() -> void:
    for _i in initial_heads:
        spawn_head()

func spawn_head() -> Node3D:
    var head := HYDRA_HEAD_SCENE.instantiate()
    head.global_position = global_position + Vector3(randfn(0, 0.5), randf_range(0.3, 1.5), randfn(0, 0.5))
    add_child(head)
    heads.append(head)
    return head
```

Initial heads scatter around the hydra. Each head is an independent target.

Regrow on head loss.

```gdscript
@export var regrowth_factor: int = 2

func _on_head_destroyed(head: Node3D) -> void:
    heads.erase(head)
    for _i in regrowth_factor:
        spawn_head()
```

Each destroyed head spawns regrowth_factor new ones. The hydra's head count grows.

Limit total heads.

```gdscript
@export var max_heads: int = 30

func spawn_head() -> Node3D:
    if heads.size() >= max_heads:
        return null
    # ... normal spawn
```

Performance guard. Without the cap, the hydra could grow unboundedly and tank the scene.

Track recursion depth via science screen.

```gdscript
class_name FractalScienceScreen extends Node3D

var projectile_depths_seen: Dictionary = {}
var head_counts_over_time: Array = []

func log_projectile(depth: int) -> void:
    projectile_depths_seen[depth] = projectile_depths_seen.get(depth, 0) + 1

func _process(_delta: float) -> void:
    head_counts_over_time.append(hydra.heads.size())
    if head_counts_over_time.size() > 300:
        head_counts_over_time.pop_front()
```

Track everything. The screen shows depth and head count over time.

You can now build the fractal catalyst with branching projectiles, the fractal hydra with regrowth, cap total heads, and log the encounter's data to the science screen. The Fractals sequence closes with infinite regress as combat.

Convert iteration to pixel coordinates.

```gdscript
func complex_to_pixel(c: Vector2, bounds: Rect2, resolution: Vector2i) -> Vector2i:
    return Vector2i(
        int((c.x - bounds.position.x) / bounds.size.x * resolution.x),
        int((c.y - bounds.position.y) / bounds.size.y * resolution.y)
    )
```

Maps math-space to image-space. Inverse of pixel-to-complex used in rendering.
