extends Node3D
## The first earned form. The capability autoload keeps it across halls.
## Near, empty hands source a point; either hand's trigger sends that form.

const JOIN_DISTANCE := 0.24
const PART_DISTANCE := 0.32
const FORM_SECONDS := 0.15
const GLOW := preload("res://commons/hazards/becoming_catalyst/first_catalyst_glow.gdshader")

var unlocked := false
var formed := false
var sphere: MeshInstance3D
var left_glow: MeshInstance3D
var right_glow: MeshInstance3D
var _left: XRController3D
var _right: XRController3D
var _origin: XROrigin3D
var _seek_left := 0.0
var _together := 0.0
var _cooldown := 0.0
var projectiles: Array[RigidBody3D] = []
## Optional scene-owned input adapter for desktop encounter practice.
var desktop_source: Node
signal form_sent(projectile: RigidBody3D)

func _ready() -> void:
	name = "FirstCatalystAbility"
	add_to_group("first_catalyst_ability")
	sphere = MeshInstance3D.new()
	sphere.name = "CalledPoint"
	var mesh := SphereMesh.new()
	mesh.radius = 0.07
	mesh.height = 0.14
	mesh.radial_segments = 32
	mesh.rings = 16
	sphere.mesh = mesh
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.009, 0.011, 0.015)
	finish.roughness = 0.12
	finish.metallic_specular = 0.8
	finish.clearcoat_enabled = true
	finish.clearcoat = 0.8
	sphere.material_override = finish
	add_child(sphere)
	left_glow = make_glow(0.075)
	left_glow.name = "LeftHandGlow"
	add_child(left_glow)
	right_glow = make_glow(0.075)
	right_glow.name = "RightHandGlow"
	add_child(right_glow)
	var rim := make_glow(0.074)
	rim.name = "PointRim"
	sphere.add_child(rim)
	_hide_all()

static func make_glow(radius: float) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius; mesh.height = radius * 2.0
	mesh.radial_segments = 24; mesh.rings = 12
	body.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = GLOW
	body.material_override = material
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return body

func set_unlocked(value: bool) -> void:
	unlocked = value
	if not value and is_instance_valid(sphere):
		_hide_all()

func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if not unlocked:
		return
	if is_instance_valid(desktop_source) and desktop_source.is_inside_tree():
		desktop_source.update_ability(self, delta)
		return
	if not is_instance_valid(_left) or not is_instance_valid(_right):
		_hide_all()
		_seek_left -= delta
		if _seek_left <= 0.0:
			_seek_left = 0.5
			_resolve_hands()
		return
	var tracking := _left.get_is_active() and _right.get_is_active()
	tracking = tracking and _left.get_has_tracking_data() and _right.get_has_tracking_data()
	tracking = tracking and _left.is_visible_in_tree() and _right.is_visible_in_tree()
	# Staging keeps its menu rig alive and tracked. Only the CURRENT origin owns
	# the player's world-space hands; the first rig in the tree may be kilometres away.
	tracking = tracking and is_instance_valid(_origin) and _origin.current
	if not tracking:
		_hide_all()
		_seek_left -= delta
		if _seek_left <= 0.0:
			_seek_left = 0.5
			_resolve_hands()
		return
	update_hands(_left.global_transform, _right.global_transform, tracking,
		_hands_empty(), delta)

## XR supplies tracked controller poses. Desktop practice supplies camera-relative
## poses through its scene-owned adapter; both use the same sourcing and shots.
func update_hands(left: Transform3D, right: Transform3D, tracked: bool, empty: bool, delta: float) -> void:
	if not unlocked or not tracked:
		_hide_all()
		return
	left_glow.global_transform = left
	right_glow.global_transform = right
	left_glow.show()
	right_glow.show()
	var separation := left.origin.distance_to(right.origin)
	var near := separation <= (PART_DISTANCE if formed else JOIN_DISTANCE)
	var sourcing := clampf((0.55 - separation) / 0.35, 0.0, 1.0) if empty else 0.0
	for glow in [left_glow, right_glow]:
		glow.material_override.set_shader_parameter("strength", lerpf(0.16, 1.0, sourcing))
		glow.scale = Vector3.ONE * lerpf(1.0, 1.35, sourcing)
	if not empty or not near:
		formed = false
		_together = 0.0
		sphere.hide()
		return
	_together += maxf(delta, 0.0)
	formed = _together >= FORM_SECONDS
	sphere.visible = formed
	sphere.global_position = (left.origin + right.origin) * 0.5
	# Keep the familiar point's diameter; only tighten it when the hands touch.
	sphere.scale = Vector3.ONE * clampf(separation / 0.18, 0.45, 1.0)

func _hide_all() -> void:
	formed = false
	_together = 0.0
	sphere.hide()
	left_glow.hide()
	right_glow.hide()

func _resolve_hands() -> void:
	for controller in [_left, _right]:
		if is_instance_valid(controller):
			var callback := _on_trigger.bind(controller)
			if controller.button_pressed.is_connected(callback): controller.button_pressed.disconnect(callback)
	_left = null
	_right = null
	_origin = null
	# Match both hands within ONE origin, so preview rigs cannot be mixed.
	for origin in get_tree().root.find_children("*", "XROrigin3D", true, false):
		if not origin.current or not origin.is_visible_in_tree():
			continue
		var left: XRController3D = null
		var right: XRController3D = null
		for controller in origin.find_children("*", "XRController3D", true, false):
			var tracker := str(controller.tracker).to_lower()
			if "left" in tracker:
				left = controller
			elif "right" in tracker:
				right = controller
		if left != null and right != null and left.get_is_active() and right.get_is_active():
			_left = left
			_right = right
			_origin = origin
			for controller in [_left, _right]:
				controller.button_pressed.connect(_on_trigger.bind(controller))
			return

func _on_trigger(action: String, controller: XRController3D) -> void:
	if is_instance_valid(desktop_source): return
	if action != "trigger_click" or not is_instance_valid(controller): return
	if not controller.get_is_active() or not _hands_empty(): return
	if not is_instance_valid(_left) or not is_instance_valid(_right): return
	if not _left.get_has_tracking_data() or not _right.get_has_tracking_data(): return
	if _left.global_position.distance_to(_right.global_position) > PART_DISTANCE: return
	send_form(-controller.global_basis.z.normalized())

func send_form(direction: Vector3) -> RigidBody3D:
	if not unlocked or not formed or not sphere.visible or _cooldown > 0.0 or direction.length_squared() < 0.01: return null
	var game := get_node_or_null("/root/GameManager")
	if game != null and game._death_sequence_running: return null
	_cooldown = 0.35
	# Runtime load: the autoload starts before XRTools' dependency registration.
	var shot: RigidBody3D = load("res://commons/artifacts/ignorance_gallery/form_projectile.gd").new()
	shot.form = sphere.mesh.duplicate()
	shot.direction = direction.normalized()
	shot.speed = 6.0; shot.lifetime = 4.0; shot.projectile_scale = 0.45
	for body in get_tree().get_nodes_in_group("player_body"):
		if body is PhysicsBody3D: shot.add_collision_exception_with(body)
	var host: Node = get_tree().current_scene
	if host == null: host = get_tree().root
	var pose := Transform3D(Basis.IDENTITY, sphere.global_position + shot.direction * 0.18)
	shot.transform = host.global_transform.affine_inverse() * pose if host is Node3D else pose
	host.add_child(shot)
	projectiles = projectiles.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	if projectiles.size() >= 8: projectiles.pop_front().queue_free()
	projectiles.append(shot)
	form_sent.emit(shot)
	return shot

func clear_shots() -> void:
	for shot in projectiles:
		if is_instance_valid(shot): shot.queue_free()
	projectiles.clear()

func _hands_empty() -> bool:
	for controller in [_left, _right]:
		for pickup in controller.find_children("*", "Node", true, false):
			# XRTools' own runtime class contract avoids preloading its player-body
			# dependency before XRToolsUserSettings exists during autoload startup.
			if pickup.has_method("is_xr_class") and pickup.is_xr_class("XRToolsFunctionPickup") and is_instance_valid(pickup.get("picked_up_object")):
				return false
	return true
