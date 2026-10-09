extends "res://commons/artifacts/ignorance_gallery/point_body.gd"
## The learned point gains an action. Its sphere and grab boundary remain the same.
const THRUST := 11.0 # acceleration, m/s², per held point
var firing := false
var desktop_pointer: Node3D
var jet: MeshInstance3D

func _ready() -> void:
	super()
	release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
	mass = 0.6
	var black := StandardMaterial3D.new()
	black.albedo_color = Color("17191c")
	black.metallic = 0.35
	black.roughness = 0.12
	get_child(0).material_override = black
	jet = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.065; cone.bottom_radius = 0.0; cone.height = 0.48
	jet.mesh = cone; jet.position.z = -0.36; jet.rotation.x = PI / 2.0
	var light := StandardMaterial3D.new()
	light.albedo_color = Color("e99cbd"); light.emission_enabled = true
	light.emission = light.albedo_color; light.emission_energy_multiplier = 2.0
	jet.material_override = light; jet.visible = false; add_child(jet)
	action_pressed.connect(func(_p): firing = held())
	action_released.connect(func(_p): firing = false)
	dropped.connect(func(_p): firing = false)

func held() -> bool:
	return is_picked_up() or is_instance_valid(desktop_pointer)

func on_desktop_grab(pointer: Node3D) -> void:
	desktop_pointer = pointer

func on_desktop_drop(_pointer: Node3D = null) -> void:
	desktop_pointer = null; firing = false; freeze = false; sleeping = false

func receiver() -> CharacterBody3D:
	if is_instance_valid(desktop_pointer):
		var n: Node = desktop_pointer
		while n != null:
			if n is CharacterBody3D: return n
			n = n.get_parent()
	var controller := get_picked_up_by_controller()
	if controller != null:
		var origin: Node = XRHelpers.get_xr_origin(controller)
		if origin == null: return null
		for n in get_tree().get_nodes_in_group("player_body"):
			if n is XRToolsPlayerBody and origin.is_ancestor_of(n): return n
	return null

func acceleration() -> Vector3:
	if not firing or not held(): return Vector3.ZERO
	# Aim the nozzle (-Z) down/back; recoil points in the opposite direction.
	var aim: Node3D = get_picked_up_by_controller()
	if aim == null and is_instance_valid(desktop_pointer): aim = desktop_pointer.get("_camera")
	if aim == null: aim = get_picked_up_by()
	if aim == null: aim = self
	return aim.global_basis.z.normalized() * THRUST

func _process(_delta: float) -> void:
	jet.visible = firing and held()
	if jet.visible:
		var direction := -acceleration().normalized()
		jet.global_position = global_position + direction * 0.36
		jet.global_basis = Basis(Quaternion(Vector3.UP, -direction))
