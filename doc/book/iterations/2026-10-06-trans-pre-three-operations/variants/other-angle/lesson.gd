extends Node3D

var cube := MeshInstance3D.new()
var start := Vector3(0, 1, 0)
var turn_degrees := -30.0
var size_factor := 1.0
var rise := 0.0
var duration := 2.0
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0 and size_factor > 0.0)
    cube.mesh = BoxMesh.new()
    add_child(cube)
    cube.position = start
    cube.rotation_degrees.y = turn_degrees
    cube.scale = Vector3.ONE * size_factor

    var sensor := Area3D.new()
    sensor.collision_layer = 0
    sensor.collision_mask = 1
    sensor.set_collision_mask_value(20, true)
    cube.add_child(sensor)
    var hitbox := CollisionShape3D.new()
    hitbox.shape = BoxShape3D.new()
    sensor.add_child(hitbox)
    sensor.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
    elapsed += delta
    var t: float = minf(elapsed / duration, 1.0)
    cube.position = start + Vector3.UP * rise * t

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("em_walker") or body.is_in_group("player_body"):
        print("Collected")
        queue_free()
