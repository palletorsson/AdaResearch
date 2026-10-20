extends XRToolsPickable
## The same pickup interface as the point; the held body now carries a weft pass.
var loom: Node3D
var desktop_held := false

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 1
	var shell := MeshInstance3D.new()
	var shape := CapsuleMesh.new()
	shape.radius = 0.025
	shape.height = 0.22
	shell.mesh = shape
	shell.rotation.z = PI / 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("d89853")
	mat.metallic = 0.45
	mat.roughness = 0.3
	shell.material_override = mat
	add_child(shell)
	var boundary := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.22, 0.06, 0.065)
	boundary.shape = box
	add_child(boundary)

func _ready() -> void:
	super()
	action_pressed.connect(func(_item):
		if is_instance_valid(loom): loom.beat())
	dropped.connect(func(_item):
		if is_instance_valid(loom): loom.release_shuttle())

func held() -> bool:
	return desktop_held or is_picked_up()

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true

func on_desktop_drop(_pointer: Node = null) -> void:
	desktop_held = false
	if is_instance_valid(loom): loom.release_shuttle()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(loom) and held():
		loom.sample_shuttle(loom.to_local(global_position))
