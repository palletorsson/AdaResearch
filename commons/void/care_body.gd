extends Node3D
## Ada's appearance follows the existing Void walker and XR rig.
const Android := preload("res://commons/void/ada_android.gd")
const Look := preload("res://commons/void/ada_look.gd")
const HEAD_LAYERS := 1 << 19
signal profile_changed
@export var appearance_path := "user://void_ada_body.cfg"
var camera: Camera3D
var feet: CharacterBody3D
var torso: Android
var _yaw := 0.0
var _headwear_mount: Node3D
var _controllers: Array[XRController3D] = []
var _hand_skeletons: Array[Skeleton3D] = []
var _wrist_bones: Array[int] = []
var _desktop_hand: Node3D
var headwear: Node3D
var _dance_mode: String = ""
var _dance_bpm: float = 128.0
var _dance_beat: float = 0.0


func configure(head: Camera3D, body: CharacterBody3D) -> void:
	camera = head
	feet = body
	add_to_group("void_care_bodies")
	var rig := camera.get_parent() as XROrigin3D
	if rig != null:
		for path in ["LeftHand", "RightHand"]:
			var controller := rig.get_node_or_null(path) as XRController3D
			_controllers.append(controller)
			var wrist_name := "Wrist_L" if path == "LeftHand" else "Wrist_R"
			var skeleton := _find_wrist_skeleton(controller, wrist_name)
			_hand_skeletons.append(skeleton)
			_wrist_bones.append(skeleton.find_bone(wrist_name) if skeleton != null else -1)
	else:
		_desktop_hand = feet.get_node_or_null("DesktopHand") as Node3D
	torso = Android.new()
	torso.name = "AdaAndroid"
	add_child(torso)
	torso.assemble(HEAD_LAYERS, rig != null)
	_headwear_mount = torso.headwear_mount
	camera.set_cull_mask_value(20, false)
	var saved := ConfigFile.new()
	if not appearance_path.is_empty() and saved.load(appearance_path) == OK:
		var profile: Variant = saved.get_value("ada", "proportions", {})
		if profile is Dictionary:
			set_profile(profile)
		var appearance := Look.read(saved.get_value("ada", "look", {}))
		if not appearance.is_empty():
			torso.set_look(appearance)
	# BADGE TEE HOOK (2026-11-17): Ada wears the last collected badge on a t-shirt; see commons/void/badge_tee.gd.
	load("res://commons/void/badge_tee.gd").wear(self)


func get_profile() -> Dictionary:
	return torso.profile.duplicate()


func set_profile(proportions: Dictionary) -> void:
	torso.set_proportions(proportions)
	profile_changed.emit()


func get_look() -> Dictionary:
	return torso.look.duplicate(true)


func set_look(value: Dictionary) -> void:
	var look := Look.read(value)
	if not look.is_empty():
		torso.set_look(look)
		profile_changed.emit()


func save_profile() -> bool:
	return _write_profile(get_profile(), torso.look)


func _write_profile(proportions: Dictionary, appearance: Dictionary) -> bool:
	if appearance_path.is_empty():
		return false
	var save := ConfigFile.new()
	save.set_value("ada", "proportions", proportions)
	save.set_value("ada", "look", appearance)
	return save.save(appearance_path) == OK


func load_web_fit(path: String = "user://ada-web-fit.json") -> bool:
	var source := FileAccess.open(path, FileAccess.READ)
	if source == null or source.get_length() > 4096:
		return false
	var record: Variant = JSON.parse_string(source.get_as_text())
	if not record is Dictionary or record.get("schema") not in ["ada.body-fit/1", "ada.body-fit/2", "ada.body-fit/3"] or not record.get("fit") is Dictionary:
		return false
	var appearance := torso.look
	if record.schema != "ada.body-fit/1":
		appearance = Look.read(record.get("look"))
		if appearance.is_empty():
			return false
	var fit: Dictionary = {}
	for key in Android.PROFILE_LIMITS:
		var value: Variant = record.fit.get(key)
		var limits: Vector2 = Android.PROFILE_LIMITS[key]
		if not (value is float or value is int) or not is_finite(value) or value < limits.x - 0.00001 or value > limits.y + 0.00001:
			return false
		fit[key] = clampf(value, limits.x, limits.y)
	if not _write_profile(fit, appearance):
		return false
	torso.set_look(appearance)
	set_profile(fit)
	return true


func _find_wrist_skeleton(controller: Node3D, wrist_name: String) -> Skeleton3D:
	if controller != null:
		for skeleton: Skeleton3D in controller.find_children("*", "Skeleton3D", true, false):
			if skeleton.find_bone(wrist_name) >= 0:
				return skeleton
	return null


func _wrist_world(index: int) -> Vector3:
	var skeleton := _hand_skeletons[index]
	if is_instance_valid(skeleton) and _wrist_bones[index] >= 0:
		return skeleton.to_global(skeleton.get_bone_global_pose(_wrist_bones[index]).origin)
	return _controllers[index].global_position


func set_headwear(piece: Node3D) -> void:
	if is_instance_valid(headwear):
		_headwear_mount.remove_child(headwear)
		headwear.queue_free()
	headwear = piece
	if piece != null:
		_headwear_mount.add_child(piece)


func set_dance_mode(mode: String, bpm: float = 128.0) -> void:
	_dance_mode = mode
	_dance_bpm = maxf(60.0, bpm)
	if is_instance_valid(torso):
		torso.dance_mode = mode


func get_dance_mode() -> String:
	return _dance_mode


func _physics_process(delta: float) -> void:
	if camera == null or torso == null:
		return
	var body_scale := float(feet.get_meta("ada_body_scale", 1.0))
	var back := Vector3(camera.global_basis.z.x, 0.0, camera.global_basis.z.z)
	if back.length_squared() > 0.001:
		_yaw = lerp_angle(_yaw, atan2(back.x, back.z), 1.0 - exp(-7.0 * delta))
	var dance_yaw := 0.0
	var dance_bob := 0.0
	if not _dance_mode.is_empty():
		_dance_beat += delta * (_dance_bpm / 60.0)
		torso.dance_mode = _dance_mode
		torso.dance_beat = _dance_beat
		dance_yaw = sin(_dance_beat * PI) * 0.14
		dance_bob = absf(sin(_dance_beat * PI)) * 0.032 * body_scale
	else:
		torso.dance_mode = ""
	torso.global_position = Vector3(camera.global_position.x, feet.global_position.y + dance_bob, camera.global_position.z) + back.normalized() * 0.12 * body_scale
	torso.global_rotation = Vector3(0.0, _yaw + dance_yaw, 0.0)
	var height := clampf((camera.global_position.y - feet.global_position.y) / body_scale, 1.15, 2.0)
	torso.scale = Vector3(1.0, height / 1.65, 1.0) * body_scale
	var inverse := torso.global_basis.orthonormalized().inverse()
	var gaze := inverse * camera.global_basis.orthonormalized()
	var planar_velocity := inverse * Vector3(feet.velocity.x, 0.0, feet.velocity.z) / body_scale
	var hands: Array = []
	for i in _controllers.size():
		var controller := _controllers[i]
		var wrist: Variant = null
		if is_instance_valid(controller) and controller.get_is_active():
			wrist = torso.to_local(_wrist_world(i))
		hands.append(wrist)
	if is_instance_valid(_desktop_hand) and _dance_mode.is_empty():
		var wrist: Variant = _desktop_hand.avatar_wrist_target()
		if wrist is Vector3:
			hands = [null, torso.to_local(wrist)]
	torso.pose(delta, planar_velocity, feet.is_on_floor(), gaze, hands, true, feet.get_rid())
