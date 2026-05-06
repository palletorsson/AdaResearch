# Forces Arena

Three arenas. Drone combat, fracture sandbox, gallery. Apply everything you've learned.

Set up an enemy drone.

```gdscript
class_name EnemyDrone extends CharacterBody3D

@export var max_speed: float = 6.0
@export var fire_cone: float = 5.0  # degrees

var target: Node3D

func _physics_process(delta: float) -> void:
    if target == null: return
    var to_target: Vector3 = (target.global_position - global_position).normalized()
    velocity = velocity.lerp(to_target * max_speed, 0.1)
    move_and_slide()
    if should_fire(): fire_at(target)
```

Simple pursuit AI. Velocity smoothly interpolates toward the desired direction.

Check firing alignment.

```gdscript
func should_fire() -> bool:
    var forward: Vector3 = -global_transform.basis.z
    var to_target: Vector3 = (target.global_position - global_position).normalized()
    return forward.dot(to_target) > cos(deg_to_rad(fire_cone))
```

Same dot-product check the learner used in VectorApplied. The drone is running the learner's code against them.

Fracture a mesh with Voronoi cells.

```gdscript
func voronoi_fracture(mesh: ArrayMesh, impact_point: Vector3, cell_count: int) -> Array:
    var seeds: Array = []
    for _i in cell_count:
        var offset := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
        seeds.append(impact_point + offset)
    var shards: Array = []
    for seed in seeds:
        shards.append(extract_voronoi_cell(mesh, seed, seeds))
    return shards
```

Random seed points around the impact. Each cell becomes one shard.

Drop the shards as rigid bodies.

```gdscript
func spawn_shards_as_rigid_bodies(shards: Array, impact_velocity: Vector3) -> void:
    for shard_mesh in shards:
        var body := RigidBody3D.new()
        var mesh_inst := MeshInstance3D.new()
        mesh_inst.mesh = shard_mesh
        body.add_child(mesh_inst)
        body.linear_velocity = impact_velocity * randf_range(0.3, 1.5)
        add_child(body)
```

Each shard is a rigid body with inherited velocity. The impact disperses them.

Populate the gallery.

```gdscript
const GALLERY_ARTIFACTS := [
    "res://commons/primitives/vector_arrow.tscn",
    "res://commons/primitives/force_spring.tscn",
    "res://commons/forces/chaos_pendulum.tscn",
    # ... more artifacts
]

func populate_gallery() -> void:
    for i in GALLERY_ARTIFACTS.size():
        var plinth := PLINTH_SCENE.instantiate()
        var artifact := load(GALLERY_ARTIFACTS[i]).instantiate()
        plinth.add_child(artifact)
        plinth.position = Vector3(i * 2, 0, 0)
        add_child(plinth)
```

Each artifact on its own plinth. The learner walks the line and can pick any of them up.

Check arena completion.

```gdscript
func is_arena_complete(arena_id: String) -> bool:
    var save = get_tree().get_first_node_in_group("save_manager")
    return save.is_milestone_reached(arena_id + "_complete")
```

Three separate arenas, three separate completion flags. Completing all three unlocks the catalyst chamber.

You can now fight drones that use the same vector operations you've learned, fracture geometry with eight algorithms, and browse the sequence's accumulated artifacts. Chamber_Forces will next convert combat into care.

Track score across arenas.

```gdscript
var arena_scores: Dictionary = {}  # arena_id -> score

func submit_score(arena_id: String, score: int) -> void:
    arena_scores[arena_id] = max(arena_scores.get(arena_id, 0), score)

func total_score() -> int:
    return arena_scores.values().reduce(func(a, b): return a + b, 0)
```

Highest score per arena is kept. The total across three arenas becomes the learner's sequence-level score.
