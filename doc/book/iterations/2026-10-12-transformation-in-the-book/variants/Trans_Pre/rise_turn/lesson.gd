extends Node3D

var cube := MeshInstance3D.new()
var start := Vector3(0, 1.3, 0)
var rise := 0.35
var turn_speed := 45.0
var pulse := 0.0
var period := 4.0
var elapsed := 0.0

func _ready() -> void:
    assert(period > 0.0 and pulse >= 0.0 and pulse < 1.0)
    cube.mesh = BoxMesh.new()
    add_child(cube)
    cube.position = start

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
    var t := pingpong(2.0 * elapsed / period + 0.5, 1.0)
    cube.position = start + Vector3.UP * lerpf(-rise, rise, t)
    cube.rotation_degrees.y = turn_speed * elapsed
    cube.scale = Vector3.ONE * lerpf(1.0 - pulse, 1.0 + pulse, t)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("em_walker") or body.is_in_group("player_body"):
        print("Collected")
        queue_free()
