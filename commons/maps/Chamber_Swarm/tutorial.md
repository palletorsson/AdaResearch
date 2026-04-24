# Chamber Swarm

Two flocks in one volume. Reynolds rules on both sides.

Build the swarm catalyst.

```gdscript
class_name SwarmCatalyst extends Node3D

@export var boid_count: int = 8

func fire(aim: Vector3) -> Array:
    var boids: Array = []
    for _i in boid_count:
        var boid := BoidProjectile.new()
        boid.global_position = global_position + Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
        boid.velocity = aim * 8.0 + Vector3(randfn(0, 0.5), randfn(0, 0.5), randfn(0, 0.5))
        get_tree().root.add_child(boid)
        boids.append(boid)
    return boids
```

Each catalyst shot spawns eight boids. They follow each other via local Reynolds rules.

Build the swarm hive creature.

```gdscript
class_name SwarmHive extends CharacterBody3D

@export var hive_size: int = 20
var hive_boids: Array = []

func _ready() -> void:
    for _i in hive_size:
        var boid := BoidHiveMember.new()
        boid.global_position = global_position + Vector3(randfn(0, 0.5), randfn(0, 0.5), randfn(0, 0.5))
        boid.velocity = Vector3.ZERO
        add_child(boid)
        hive_boids.append(boid)
```

Twenty boids around the hive. Their collective centroid is the hive's body.

Run Reynolds rules for both flocks.

```gdscript
func _physics_process(delta: float) -> void:
    for boid in get_tree().get_nodes_in_group("boid_projectile"):
        apply_reynolds(boid, get_nearby_boids(boid, 2.0))
    for boid in hive_boids:
        apply_reynolds(boid, get_nearby_boids(boid, 2.0))
```

Both flocks use the same physics. Different parameter sets give each its character.

Detect flock interaction.

```gdscript
func get_nearby_boids(self_boid: Node3D, radius: float) -> Array:
    var nearby: Array = []
    for other in get_tree().get_nodes_in_group("all_boids"):
        if other == self_boid: continue
        if self_boid.global_position.distance_to(other.global_position) < radius:
            nearby.append(other)
    return nearby
```

Cross-flock awareness. Each boid sees any boid within radius, regardless of flock.

Apply Reynolds.

```gdscript
func apply_reynolds(boid: Node3D, neighbours: Array) -> void:
    if neighbours.is_empty(): return
    var sep := compute_separation(boid, neighbours)
    var ali := compute_alignment(boid, neighbours)
    var coh := compute_cohesion(boid, neighbours)
    boid.velocity += (sep * 1.5 + ali + coh) * 0.1
    boid.velocity = boid.velocity.limit_length(5.0)
```

Standard Reynolds' three rules. Weights tuned for visible behaviour.

Log alignment.

```gdscript
func alignment_score() -> float:
    var alignment_vector := Vector3.ZERO
    for boid in get_tree().get_nodes_in_group("all_boids"):
        alignment_vector += boid.velocity.normalized()
    var total_count: int = get_tree().get_nodes_in_group("all_boids").size()
    return alignment_vector.length() / total_count
```

Sum of unit velocity vectors. Near 1.0 means everyone's aligned; near 0.0 means random directions.

Detect a witness miura.

```gdscript
func spawn_miura_witness() -> void:
    var miura := preload("res://commons/transformation/miura_crawler.tscn").instantiate()
    miura.position = Vector3(3, 0, -4)
    miura.set_curious_posture(true)
    add_child(miura)
```

The befriended miura from an earlier chamber appears. It watches the two flocks without joining either.

You can now build the swarm catalyst, spawn a swarm hive, run Reynolds rules across both flocks, detect cross-flock neighbours, log alignment, and spawn a miura witness. The Swarm Intelligence sequence closes with two self-organising systems in contact.
