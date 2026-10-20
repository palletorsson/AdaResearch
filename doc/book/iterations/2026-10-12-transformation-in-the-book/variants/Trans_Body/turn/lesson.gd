extends Node3D

var cube := MeshInstance3D.new()
var player: Node3D
var near_distance := 1.0
var far_distance := 4.0
var minimum := 0.25
var turn_instead := true

func _ready() -> void:
    assert(far_distance > near_distance and near_distance >= 0.0)
    assert(minimum > 0.0 and minimum <= 1.0)
    cube.mesh = BoxMesh.new()
    add_child(cube)
    cube.position.y = 0.5
    player = get_tree().get_first_node_in_group("player_body") as Node3D
    if player == null:
        player = get_tree().get_first_node_in_group("em_walker") as Node3D

func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    var separation := player.global_position - global_position
    separation.y = 0.0
    respond(separation.length())

func respond(distance: float) -> void:
    var closeness := 1.0 - clampf((distance - near_distance) / (far_distance - near_distance), 0.0, 1.0)
    if turn_instead:
        cube.scale = Vector3.ONE
        cube.position.y = 0.5
        cube.rotation_degrees.y = 90.0 * closeness
    else:
        var factor := lerpf(1.0, minimum, closeness)
        cube.rotation_degrees.y = 0.0
        cube.scale = Vector3.ONE * factor
        cube.position.y = factor * 0.5
