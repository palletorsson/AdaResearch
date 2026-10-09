extends XROrigin3D
## Prepared XR Tools rig. All nodes exist before PlayerBody discovers providers.

signal reset_requested

var camera := XRCamera3D.new()
var left := XRController3D.new()
var right := XRController3D.new()
var body := XRToolsPlayerBody.new()
var pickups: Array[XRToolsFunctionPickup] = []

func _init() -> void:
    camera.name = "Camera"
    add_child(camera)
    _add_controller(left, "left_hand", "LeftHandController")
    _add_controller(right, "right_hand", "RightHandController")
    var move := XRToolsMovementDirect.new()
    move.strafe = true
    move.max_speed = 2.0
    move.add_to_group("movement_providers")
    left.add_child(move)
    var turn := XRToolsMovementTurn.new()
    turn.turn_mode = XRToolsMovementTurn.TurnMode.SNAP
    turn.step_turn_angle = 30.0
    turn.add_to_group("movement_providers")
    right.add_child(turn)
    body.name = "PlayerBody"
    body.collision_layer = 524288
    body.collision_mask = 1
    body.player_calibrate_height = false
    # Move relative to the view; hand alignment should not steer the student's walk.
    body.body_forward_mix = 0.0
    add_child(body)
    _own_children(self)

func _ready() -> void:
    current = true

func _own_children(branch: Node) -> void:
    # XR Tools searches owned children, as it does in its supplied packed scenes.
    for child in branch.get_children():
        child.owner = self
        _own_children(child)

func _add_controller(controller: XRController3D, tracker_name: String, node_name: String) -> void:
    controller.name = node_name
    controller.tracker = tracker_name
    controller.pose = "grip"
    add_child(controller)
    var pickup := XRToolsFunctionPickup.new()
    pickup.ranged_enable = false
    pickup.grab_distance = 0.2
    controller.add_child(pickup)
    pickups.append(pickup)
    # Simple markers make the pickup position visible without teaching a hand rig.
    var marker := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.035
    sphere.height = 0.07
    marker.mesh = sphere
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("d96695")
    marker.material_override = material
    pickup.add_child(marker)
    controller.button_pressed.connect(_on_button_pressed)

func _process(_delta: float) -> void:
    left.visible = left.get_is_active()
    right.visible = right.get_is_active()

func _on_button_pressed(button: String) -> void:
    if button == "by_button":
        reset_requested.emit()

func set_input_active(active: bool) -> void:
    body.enabled = active
    for pickup in pickups:
        var held := pickup.picked_up_object
        if not active and is_instance_valid(held):
            held.set_meta("ada_release_cleanup", true)
        pickup.enabled = active
        if not active:
            pickup.drop_object()
        if is_instance_valid(held):
            held.remove_meta("ada_release_cleanup")
