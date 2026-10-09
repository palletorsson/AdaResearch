extends "free_point.gd"
var firing := false

func _ready() -> void:
    super()
    freeze = true
    gravity_scale = 1.0
    add_to_group("ada_thrust_points")
    action_pressed.connect(func(_hand): firing = is_picked_up())
    action_released.connect(func(_hand): firing = false)
    dropped.connect(func(_hand): firing = false)

func held() -> bool:
    return is_picked_up()

func receiver() -> CharacterBody3D:
    var controller := get_picked_up_by_controller()
    if controller == null:
        return null
    var origin := XRHelpers.get_xr_origin(controller)
    for body in get_tree().get_nodes_in_group("player_body"):
        if origin != null and body is XRToolsPlayerBody and origin.is_ancestor_of(body):
            return body
    return null

func acceleration() -> Vector3:
    var controller := get_picked_up_by_controller()
    if not firing or not held() or controller == null:
        return Vector3.ZERO
    return -controller.global_basis.z.normalized() * 11.0
