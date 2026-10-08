extends "res://commons/artifacts/ignorance_gallery/resolution_point.gd"
## Same PointBody and held-resolution rule as the learner's Godot primitive.
## Museum additions: trigger, return to suspension and the existing catalyst hit protocol.
const Projectile = preload("res://commons/artifacts/ignorance_gallery/form_projectile.gd")
signal form_sent(projectile: RigidBody3D)
var desktop_held := false
var _desktop_pointer: Node
var home: Transform3D
var suspension: Node3D
var readout: Label3D
var projectiles: Array[RigidBody3D] = []
var _return_in := -1.0
var _cooldown := 0.0

func _ready() -> void:
	super()
	home = global_transform
	name = "ResolutionCatalyst"
	add_to_group("catalyst")
	var surface: MeshInstance3D = get_child(0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.035,0.035,0.035)
	material.roughness = 0.18
	material.metallic = 0.2
	surface.material_override = material
	action_pressed.connect(_send_form)
	picked_up.connect(_picked)
	dropped.connect(_dropped)

func is_resolution_held() -> bool:
	return is_picked_up() or desktop_held

func _process(delta: float) -> void:
	advance(delta)
	_cooldown = maxf(0.0,_cooldown-delta)
	if is_instance_valid(readout):
		readout.text = "%d RINGS   /   %d SEGMENTS" % [sphere.rings,sphere.radial_segments]
	if _return_in >= 0.0 and not is_resolution_held():
		_return_in -= delta
		if _return_in <= 0.0: return_home()

func _picked(_body: Node) -> void:
	_return_in = -1.0
	if is_instance_valid(suspension): suspension.hide()

func _dropped(_body: Node) -> void:
	_return_in = 2.0

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true
	_desktop_pointer = _pointer
	_picked(self)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	_desktop_pointer = null
	_dropped(self)

func return_home() -> void:
	if is_resolution_held(): return
	_return_in = -1.0
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = home
	reset_resolution()
	if is_instance_valid(suspension): suspension.show()

func _send_form(_body: Node) -> void:
	if not is_resolution_held() or _cooldown > 0.0: return
	_cooldown = 0.3
	projectiles = projectiles.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	if projectiles.size() >= 8:
		projectiles.pop_front().queue_free()
	var shot := Projectile.new()
	shot.form = sphere.duplicate() as SphereMesh
	shot.direction = -global_basis.z.normalized()
	var controller := get_picked_up_by_controller()
	if controller != null: shot.direction = -controller.global_basis.z.normalized()
	elif desktop_held and is_instance_valid(_desktop_pointer):
		var eye: Camera3D = _desktop_pointer.get("_camera")
		if eye != null: shot.direction = -eye.global_basis.z.normalized()
	shot.speed = 6.0
	shot.lifetime = 4.0
	shot.color_primary = Color(0.85,0.85,0.85)
	shot.color_secondary = Color(0.25,0.25,0.25)
	shot.projectile_scale = 0.45
	shot.add_collision_exception_with(self)
	var host: Node = get_tree().current_scene
	if host == null: host = get_parent()
	# Set the spawn transform before physics enters the tree, outside the held boundary.
	var pose := Transform3D(Basis.IDENTITY,global_position+shot.direction*(RADIUS*2.0+0.04))
	shot.transform = (host as Node3D).global_transform.affine_inverse()*pose if host is Node3D else pose
	host.add_child(shot)
	projectiles.append(shot)
	form_sent.emit(shot)

func _exit_tree() -> void:
	for p in projectiles:
		if is_instance_valid(p): p.queue_free()
	super()
