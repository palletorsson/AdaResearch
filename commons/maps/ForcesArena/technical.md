# Forces Arena — Technical

Three arenas apply accumulated vector and forces knowledge under pressure: drone combat, a destruction sandbox with fracture algorithms, and an exhibition gallery.

## Drone Combat

The enemy drone uses the same subtraction-normalise-dot-product operations the learner studied, turned against them.

```gdscript
class_name EnemyDrone extends CharacterBody3D

@export var max_speed: float = 8.0
@export var fire_alignment_threshold: float = 0.95

var target: Node3D

func _physics_process(delta: float) -> void:
    if target == null: return
    var to_target: Vector3 = target.global_position - global_position
    var desired_dir: Vector3 = to_target.normalized()
    velocity = velocity.lerp(desired_dir * max_speed, 0.1)
    move_and_slide()
    var forward: Vector3 = -global_transform.basis.z
    if forward.dot(desired_dir) > fire_alignment_threshold:
        fire_at_target()
```

## Fracture Algorithms

Eight fracture rules decompose impacted geometry. The simplest is Voronoi partitioning.

```gdscript
class_name VoronoiFracture

func fracture(mesh: MeshInstance3D, impact_point: Vector3, cell_count: int) -> Array:
    var seed_points: Array = []
    for i in range(cell_count):
        seed_points.append(impact_point + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)))
    var shards: Array = []
    for seed in seed_points:
        var shard_mesh := construct_voronoi_cell(mesh, seed, seed_points)
        shards.append(shard_mesh)
    return shards
```

Cantor recursion divides the mesh into thirds and keeps the endpoints. Planar cuts use a plane equation to split vertices into above and below. CSG booleans subtract one mesh from another using constructive solid geometry.

## Exhibition Gallery

The gallery renders every vector-and-forces artifact from earlier maps as a browsable plinth.

```gdscript
class_name Gallery extends Node3D

var artifacts: Array = []  # list of scene paths

func populate() -> void:
    for path in artifacts:
        var plinth := PLINTH_SCENE.instantiate()
        var item := load(path).instantiate()
        plinth.add_child(item)
        add_child(plinth)
        arrange_on_grid(plinth)
```

## Complexity

Drone combat is O(1) per frame per drone. Fracture algorithms are O(V·C) where V is vertex count and C is cell count — expensive enough that the map caps fractures at a few dozen cells and pre-bakes the heavy work. The gallery is O(N) for N artifacts on load, zero per frame after.

Within the sequence, Arena is the synthesis. The catalyst chamber that follows will convert the accumulated skill from combat to care.

## Drone AI States

The enemy drone uses a simple state machine: Idle, Pursuing, Firing, Evading, Returning. State transitions depend on the target's proximity and alignment.

```gdscript
enum State { IDLE, PURSUING, FIRING, EVADING, RETURNING }

var current_state: State = State.IDLE

func update_state(target_distance: float, target_alignment: float, health: float) -> void:
    match current_state:
        State.IDLE:
            if target_distance < pursuit_range:
                current_state = State.PURSUING
        State.PURSUING:
            if target_alignment > fire_threshold:
                current_state = State.FIRING
            elif health < 0.3:
                current_state = State.EVADING
        State.FIRING:
            if target_alignment < fire_threshold * 0.9:
                current_state = State.PURSUING
        State.EVADING:
            if target_distance > safe_distance:
                current_state = State.RETURNING
        State.RETURNING:
            if health > 0.7:
                current_state = State.PURSUING
```

More sophisticated AI uses behaviour trees or utility-based action selection; the state machine is adequate for the map's pressure-testing purpose.

## Fracture Algorithm Comparison

Voronoi fracture produces angular, irregular shards — looks like shattered stone. Cantor recursion produces nested shards — looks like pulverised powder. Planar cuts produce flat-faced pieces — looks like cleaved wood. CSG booleans produce precisely shaped holes — looks like drilled metal.

```gdscript
class_name FractureAlgorithm extends Resource

enum Type { VORONOI, CANTOR, PLANAR_CUT, CSG_BOOLEAN, CRACK_PROPAGATION, SHATTER, SHEAR, SPLINTER }

func fracture(mesh: Mesh, impact: Vector3, type: Type) -> Array:
    match type:
        Type.VORONOI: return voronoi(mesh, impact)
        Type.CANTOR: return cantor(mesh, impact, 3)
        Type.PLANAR_CUT: return planar_cut(mesh, random_plane(impact))
        # ...
    return []
```

## Gallery Interaction

The exhibition gallery makes every artifact grabbable and examinable. The learner can pull an artifact off its plinth, inspect it from all angles, and drop it back. Each artifact retains the interaction affordances it had in its original map.

```gdscript
class_name GalleryPlinth extends Area3D

@export var artifact_scene: PackedScene
var artifact_instance: Node3D

func _ready() -> void:
    artifact_instance = artifact_scene.instantiate()
    artifact_instance.add_to_group("grabbable")
    add_child(artifact_instance)

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("learner"):
        show_label_for(artifact_instance)
```

## Performance Budget

Three simultaneous arenas plus a gallery strain the rendering budget. The map uses distance-based LOD — reducing geometric detail on distant arenas — and disables physics on arenas the learner is not in. Inactive arenas reduce to static snapshots, allowing the active arena to use more of the frame budget.

## Save State

Completing the arena unlocks the catalyst chamber. The unlock is recorded in the game's global save state, so leaving and returning to the arena retains progress.
