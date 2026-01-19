# PlayerCustomization - Progressive avatar building system
# Manages unlockable player features: hands, colors, dress, accessories, etc.
# Add to XROrigin3D to control player appearance

class_name PlayerCustomization
extends Node

signal feature_unlocked(feature_name: String)
signal feature_activated(feature_name: String)
signal feature_deactivated(feature_name: String)
signal color_changed(part: String, color: Color)

# Feature definitions - what can be unlocked
enum Feature {
	HANDS,           # Base hands (always unlocked)
	SKIN_COLOR,      # Change skin/hand color
	NAIL_COLOR,      # Change nail color
	DRESS_BASIC,     # Basic Elphaba dress
	DRESS_WICKED,    # Multi-layer Wicked gown
	BODY_TORSO,      # Visible torso
	BODY_LEGS,       # Visible legs
	ACCESSORIES,     # Hats, jewelry, etc.
}

# Scenes for loadable features
const DRESS_BASIC_SCENE = preload("res://algorithms/wavefunctions/dancing_body/ElphabaDress.tscn")
const DRESS_WICKED_SCENE = preload("res://algorithms/wavefunctions/dancing_body/WickedGown.tscn")

@export_group("Initial State")
@export var unlocked_features: Array[String] = ["hands"]  # Features unlocked by default

@export_group("Colors")
@export var skin_color: Color = Color(0.87, 0.72, 0.53)  # Default skin tone
@export var nail_color: Color = Color(0.8, 0.6, 0.6)     # Default nail color
@export var dress_color: Color = Color(0.0, 0.3, 0.1)    # Elphaba green

@export_group("Debug")
@export var debug_mode: bool = false

# Runtime state
var _active_features: Dictionary = {}  # feature_name -> node instance
var _unlocked: Dictionary = {}         # feature_name -> bool
var _xr_origin: XROrigin3D
var _left_hand: Node3D
var _right_hand: Node3D
var _camera: XRCamera3D

func _ready():
	call_deferred("_initialize")

func _initialize():
	# Find XR components
	_xr_origin = _find_xr_origin()
	if not _xr_origin:
		push_error("PlayerCustomization: Could not find XROrigin3D!")
		return

	_camera = _xr_origin.get_node_or_null("XRCamera3D")
	_left_hand = _xr_origin.get_node_or_null("LeftHand")
	_right_hand = _xr_origin.get_node_or_null("RightHand")

	# Initialize unlocked features
	for feature in unlocked_features:
		_unlocked[feature.to_lower()] = true

	# Hands are always unlocked and active
	_unlocked["hands"] = true
	_active_features["hands"] = true

	_log("Initialized with features: %s" % _unlocked.keys())

func _find_xr_origin() -> XROrigin3D:
	# Check if we're a child of XROrigin
	var parent = get_parent()
	while parent:
		if parent is XROrigin3D:
			return parent
		parent = parent.get_parent()

	# Search in tree
	return get_tree().get_first_node_in_group("xr_origin") as XROrigin3D

# ============ UNLOCK SYSTEM ============

func unlock_feature(feature_name: String) -> bool:
	"""Unlock a feature for the player. Returns true if newly unlocked."""
	var key = feature_name.to_lower()

	if _unlocked.get(key, false):
		_log("Feature '%s' already unlocked" % feature_name)
		return false

	_unlocked[key] = true
	_log("Unlocked feature: %s" % feature_name)
	feature_unlocked.emit(feature_name)
	return true

func is_unlocked(feature_name: String) -> bool:
	return _unlocked.get(feature_name.to_lower(), false)

func get_unlocked_features() -> Array:
	var result = []
	for key in _unlocked:
		if _unlocked[key]:
			result.append(key)
	return result

# ============ ACTIVATION SYSTEM ============

func activate_feature(feature_name: String) -> bool:
	"""Activate an unlocked feature. Returns true if successful."""
	var key = feature_name.to_lower()

	if not is_unlocked(key):
		_log("Cannot activate '%s' - not unlocked!" % feature_name)
		return false

	if _active_features.has(key):
		_log("Feature '%s' already active" % feature_name)
		return true

	match key:
		"dress_basic":
			return _activate_dress(DRESS_BASIC_SCENE, key)
		"dress_wicked":
			return _activate_dress(DRESS_WICKED_SCENE, key)
		"skin_color":
			_apply_skin_color(skin_color)
			_active_features[key] = true
			feature_activated.emit(feature_name)
			return true
		"nail_color":
			_apply_nail_color(nail_color)
			_active_features[key] = true
			feature_activated.emit(feature_name)
			return true
		_:
			_log("Unknown feature: %s" % feature_name)
			return false

func deactivate_feature(feature_name: String) -> bool:
	"""Deactivate an active feature. Returns true if successful."""
	var key = feature_name.to_lower()

	if not _active_features.has(key):
		_log("Feature '%s' not active" % feature_name)
		return false

	var instance = _active_features[key]

	# Remove node if it's a Node
	if instance is Node:
		instance.queue_free()

	_active_features.erase(key)
	_log("Deactivated feature: %s" % feature_name)
	feature_deactivated.emit(feature_name)
	return true

func is_active(feature_name: String) -> bool:
	return _active_features.has(feature_name.to_lower())

func toggle_feature(feature_name: String) -> bool:
	"""Toggle a feature on/off. Returns new state (true = active)."""
	if is_active(feature_name):
		deactivate_feature(feature_name)
		return false
	else:
		activate_feature(feature_name)
		return true

# ============ DRESS SYSTEM ============

func _activate_dress(scene: PackedScene, key: String) -> bool:
	if not _xr_origin:
		print("PlayerCustomization: ERROR - No XROrigin found!")
		return false

	# Remove existing dress if any
	_remove_existing_dress()

	# Instance new dress
	var dress = scene.instantiate()
	dress.name = "PlayerDress"

	# Disable internal skeleton following - we position it manually
	if "follow_skeleton" in dress:
		dress.follow_skeleton = false

	# Add to XROrigin
	_xr_origin.add_child(dress)

	# Position at hip level - use camera Y position minus offset for hip height
	# Camera is typically at eye level (~1.6-1.9m), hip is about 0.9-1.0m
	var hip_y = 1.0  # Default hip height
	if _camera:
		# Hip is roughly 55% of camera height
		hip_y = _camera.position.y * 0.55
		print("PlayerCustomization: Camera Y=%.2f, calculated hip Y=%.2f" % [_camera.position.y, hip_y])

	dress.position = Vector3(0, hip_y, 0)
	print("PlayerCustomization: Dress added at position %s" % dress.position)

	_active_features[key] = dress
	_log("Activated dress: %s" % key)
	feature_activated.emit(key)
	return true

func _remove_existing_dress():
	for key in ["dress_basic", "dress_wicked"]:
		if _active_features.has(key):
			var old_dress = _active_features[key]
			if old_dress is Node:
				old_dress.queue_free()
			_active_features.erase(key)

func set_dress_color(primary: Color, secondary: Color = Color.BLACK):
	"""Change the dress colors."""
	dress_color = primary

	for key in ["dress_basic", "dress_wicked"]:
		if _active_features.has(key):
			var dress = _active_features[key]
			if dress.has_method("set_colors"):
				dress.set_colors(primary, secondary)
			elif "primary_color" in dress:
				dress.primary_color = primary
				dress.secondary_color = secondary
				if dress.has_method("apply_material"):
					dress.apply_material()

# ============ COLOR SYSTEM ============

func set_skin_color(color: Color):
	"""Change the player's skin color."""
	skin_color = color
	_apply_skin_color(color)
	color_changed.emit("skin", color)

func set_nail_color(color: Color):
	"""Change the player's nail color."""
	nail_color = color
	_apply_nail_color(color)
	color_changed.emit("nail", color)

func _apply_skin_color(color: Color):
	"""Apply skin color to hand materials."""
	_apply_color_to_hands("skin", color)

func _apply_nail_color(color: Color):
	"""Apply nail color to hand materials."""
	_apply_color_to_hands("nail", color)

func _apply_color_to_hands(part: String, color: Color):
	"""Find and update hand materials."""
	for hand in [_left_hand, _right_hand]:
		if not hand:
			continue

		# Find hand mesh instances
		var meshes = _find_mesh_instances(hand)
		for mesh in meshes:
			_update_hand_material(mesh, part, color)

func _find_mesh_instances(node: Node) -> Array:
	var result = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_mesh_instances(child))
	return result

func _update_hand_material(mesh: MeshInstance3D, part: String, color: Color):
	"""Update material on a hand mesh."""
	# This depends on how your hand materials are set up
	# You may need to customize this based on your hand shader/material structure

	var mat = mesh.get_active_material(0)
	if not mat:
		return

	# Try to update shader parameter
	if mat is ShaderMaterial:
		match part:
			"skin":
				if mat.get_shader_parameter("skin_color") != null:
					mat.set_shader_parameter("skin_color", color)
				elif mat.get_shader_parameter("albedo") != null:
					mat.set_shader_parameter("albedo", color)
			"nail":
				if mat.get_shader_parameter("nail_color") != null:
					mat.set_shader_parameter("nail_color", color)

	# Try StandardMaterial3D
	elif mat is StandardMaterial3D:
		if part == "skin":
			mat.albedo_color = color

# ============ CONVENIENCE METHODS ============

func unlock_and_activate(feature_name: String) -> bool:
	"""Unlock and immediately activate a feature."""
	unlock_feature(feature_name)
	return activate_feature(feature_name)

func give_dress():
	"""Shortcut to unlock and activate the basic dress."""
	unlock_and_activate("dress_basic")

func give_wicked_gown():
	"""Shortcut to unlock and activate the Wicked gown."""
	unlock_and_activate("dress_wicked")

# ============ SAVE/LOAD ============

func get_save_data() -> Dictionary:
	"""Get data for saving player customization state."""
	return {
		"unlocked": _unlocked.duplicate(),
		"active": _active_features.keys(),
		"skin_color": skin_color,
		"nail_color": nail_color,
		"dress_color": dress_color,
	}

func load_save_data(data: Dictionary):
	"""Restore customization state from save data."""
	if data.has("unlocked"):
		_unlocked = data["unlocked"]

	if data.has("skin_color"):
		skin_color = data["skin_color"]
	if data.has("nail_color"):
		nail_color = data["nail_color"]
	if data.has("dress_color"):
		dress_color = data["dress_color"]

	# Reactivate features
	if data.has("active"):
		for feature in data["active"]:
			if feature != "hands":  # Hands are always active
				activate_feature(feature)

# ============ DEBUG ============

func _log(message: String):
	# Always print for now to debug issues
	print("PlayerCustomization: %s" % message)

# Quick test - call from console or another script
func test_dress():
	print("PlayerCustomization: TEST - Attempting to add dress...")
	print("  XROrigin: %s" % (_xr_origin.get_path() if _xr_origin else "NOT FOUND"))
	print("  Camera: %s" % (_camera.get_path() if _camera else "NOT FOUND"))
	give_dress()
