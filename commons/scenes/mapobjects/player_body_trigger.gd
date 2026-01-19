# PlayerBodyTrigger - Triggers player body customization when entered
# Use in grid: pb:dress, pb:dress_wicked, pb:skin_color#FF0000, etc.

extends Area3D

signal triggered(feature: String)

@export var feature_name: String = "dress"  # What to unlock/activate
@export var color_param: String = ""         # Optional color (hex or name)
@export var one_shot: bool = true            # Only trigger once
@export var show_visual: bool = true         # Show trigger area visually
@export var trigger_message: String = ""     # Optional message to display

@export_group("Visual")
@export var trigger_color: Color = Color(0.2, 0.8, 0.4, 0.3)
@export var trigger_size: Vector3 = Vector3(1.0, 2.0, 1.0)

var _has_triggered: bool = false
var _mesh_instance: MeshInstance3D

func _ready():
	# Setup collision - detect on multiple layers for VR compatibility
	collision_layer = 0
	collision_mask = 0xFFFFFFFF  # Detect ALL layers to catch player body

	# Create collision shape if not exists
	if not has_node("CollisionShape3D"):
		var collision = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = trigger_size
		collision.shape = box
		add_child(collision)

	# Create visual indicator
	if show_visual:
		_create_visual()

	# Connect signals
	body_entered.connect(_on_body_entered)

	# Also monitor Area3D entries (in case player uses Area3D for detection)
	area_entered.connect(_on_area_entered)

	print("PlayerBodyTrigger: Ready - feature='%s', color='%s'" % [feature_name, color_param])

func _on_area_entered(area: Area3D):
	print("PlayerBodyTrigger: Area entered: %s" % area.name)
	# Check if this area belongs to the player (hands, etc.)
	if area.name.contains("Hand") or area.name.contains("Player"):
		_trigger_from_node(area)

func _create_visual():
	_mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = trigger_size
	_mesh_instance.mesh = box

	# Semi-transparent material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = trigger_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance.material_override = mat

	add_child(_mesh_instance)

func _on_body_entered(body: Node3D):
	print("PlayerBodyTrigger: Body entered: %s (class: %s)" % [body.name, body.get_class()])

	if one_shot and _has_triggered:
		return

	# Check if it's the player
	if not _is_player(body):
		return

	_trigger_from_node(body)

func _trigger_from_node(node: Node):
	if one_shot and _has_triggered:
		return

	print("PlayerBodyTrigger: Triggering '%s' from node: %s" % [feature_name, node.name])
	_has_triggered = true

	# Find PlayerCustomization
	var customization = _find_player_customization(node)
	if customization:
		print("PlayerBodyTrigger: Found PlayerCustomization, applying feature...")
		_apply_feature(customization)
	else:
		push_warning("PlayerBodyTrigger: Could not find PlayerCustomization!")
		# Try to give more diagnostic info
		var root = get_tree().current_scene
		if root:
			var xr_origin = root.find_child("XROrigin3D", true, false)
			if xr_origin:
				print("PlayerBodyTrigger: XROrigin found at %s" % xr_origin.get_path())
				for child in xr_origin.get_children():
					print("  - Child: %s" % child.name)
			else:
				print("PlayerBodyTrigger: No XROrigin3D found in scene!")

	# Emit signal for external listeners
	triggered.emit(feature_name)

	# Hide visual after trigger
	if show_visual and _mesh_instance:
		_mesh_instance.visible = false

func _is_player(body: Node3D) -> bool:
	# Check various ways to identify the player
	if body.is_in_group("player"):
		return true
	if body.is_in_group("player_body"):
		return true
	if body.name.contains("Player") or body.name.contains("XR"):
		return true
	if body.get_class() == "XRToolsPlayerBody":
		return true
	return false

func _find_player_customization(body: Node3D) -> Node:
	# Try to find PlayerCustomization in the player hierarchy
	var current = body
	while current:
		var customization = current.get_node_or_null("PlayerCustomization")
		if customization:
			print("PlayerBodyTrigger: Found PlayerCustomization in hierarchy at %s" % customization.get_path())
			return customization
		current = current.get_parent()

	# Try to find XROrigin3D by name pattern
	var root = get_tree().current_scene
	if root:
		var xr_origin = root.find_child("XROrigin3D", true, false)
		if not xr_origin:
			xr_origin = root.find_child("XROrigin*", true, false)
		if xr_origin:
			var customization = xr_origin.get_node_or_null("PlayerCustomization")
			if customization:
				print("PlayerBodyTrigger: Found PlayerCustomization via XROrigin search")
				return customization

	# Try XROrigin3D group
	var xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if xr_origin:
		var customization = xr_origin.get_node_or_null("PlayerCustomization")
		if customization:
			print("PlayerBodyTrigger: Found PlayerCustomization via group")
			return customization

	# Last resort - search entire scene tree
	if root:
		var customization = root.find_child("PlayerCustomization", true, false)
		if customization:
			print("PlayerBodyTrigger: Found PlayerCustomization via full tree search")
			return customization

	return null

func _apply_feature(customization: Node):
	match feature_name.to_lower():
		"dress", "dress_basic":
			customization.give_dress()
			print("PlayerBodyTrigger: Gave player the basic dress!")

		"dress_wicked", "gown":
			customization.give_wicked_gown()
			print("PlayerBodyTrigger: Gave player the Wicked gown!")

		"skin_color", "skin":
			if not color_param.is_empty():
				var color = _parse_color(color_param)
				customization.set_skin_color(color)
				print("PlayerBodyTrigger: Set skin color to %s" % color)
			else:
				customization.unlock_and_activate("skin_color")

		"nail_color", "nail", "nails":
			if not color_param.is_empty():
				var color = _parse_color(color_param)
				customization.set_nail_color(color)
				print("PlayerBodyTrigger: Set nail color to %s" % color)
			else:
				customization.unlock_and_activate("nail_color")

		"dress_color":
			if not color_param.is_empty():
				var color = _parse_color(color_param)
				customization.set_dress_color(color)
				print("PlayerBodyTrigger: Set dress color to %s" % color)

		_:
			# Generic feature unlock
			customization.unlock_and_activate(feature_name)
			print("PlayerBodyTrigger: Unlocked and activated '%s'" % feature_name)

func _parse_color(color_string: String) -> Color:
	# Try named colors first
	match color_string.to_lower():
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		"purple": return Color.PURPLE
		"pink": return Color.PINK
		"orange": return Color.ORANGE
		"cyan": return Color.CYAN
		"white": return Color.WHITE
		"black": return Color.BLACK
		"elphaba", "emerald": return Color(0.0, 0.35, 0.15)

	# Try hex color
	if color_string.begins_with("#"):
		return Color.html(color_string)
	elif color_string.length() == 6:
		return Color.html("#" + color_string)

	return Color.WHITE

# Called by GridUtilitiesComponent to configure from parameters
func configure(params: Array):
	if params.size() > 0:
		feature_name = params[0]

	if params.size() > 1:
		color_param = params[1]

	print("PlayerBodyTrigger: Configured - feature='%s', color='%s'" % [feature_name, color_param])

# Reset trigger (for testing)
func reset_trigger():
	_has_triggered = false
	if _mesh_instance:
		_mesh_instance.visible = show_visual
