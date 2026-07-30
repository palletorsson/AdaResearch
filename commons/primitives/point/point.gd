# PointScene.gd - Pickable point with position display
# Label follows the point and appears underneath it in the scene tree
extends Node3D

# @identity
# essence: a single grabbable point that reports its own (x,y,z) — position without extension, made visible
# desire: the learner picks up a point, moves it, and watches its coordinates update — feeling location as three numbers
# critical_parameter: the global position of the grab sphere — the live label reads from it every frame
# triggers: grab the sphere and move it; _process recomputes the position text continuously
# emerges: the realization that a "point" is nothing but an address — a dimensionless triple in space
# needs: [has grabbable sphere + live position label [has], missing a snap-to-grid mode to feel quantization]
# relationships: the seed of the whole primitives sequence — a line joins two points, a triangle closes three, a cube stacks eight
# truth: a point is position without extension — everything is built from nothing

# --- DNA (promoted 2026-07-29, stage 2) ------------------------------------------------
# The point had no exports at all: a hard-coded Label3D, billboarded, yellow, 0.1 above the
# sphere, printing the sphere's GLOBAL position under the caption "local position:". Two of
# those constants are arguments, not styling.
#
# frame — which origin the point measures itself from. "world" prints the shipped string
#   (caption and all, including its inherited lie); "local" makes the caption true by
#   reporting displacement from where the point was placed, so at rest it reads (0.0, 0.0,
#   0.0) and only moving gives it a number; "grid" quantises to whole cells — the snap-to-grid
#   reading the @identity above names as missing; "mute" keeps the point and takes the address
#   away, which is the counter-claim: position without report.
# attach — how the address binds to the world. "float" is the shipped billboard that always
#   turns to the reader; "stake" fixes the tag in world orientation so you must walk around
#   it; "plate" lays it flat on the ground beneath, where the address belongs to the place
#   rather than to the thing.
#
# Defaults frame=world + attach=float reproduce the pre-promotion label exactly — the same
# format string, the same global position, the same offset, billboard and colour — so the
# maps already placing a point are unchanged.
@export_enum("world", "local", "grid", "mute") var frame: String = "world"
@export_enum("float", "stake", "plate") var attach: String = "float"

var position_label: Label3D
var grab_sphere: Node3D
var point_sphere: MeshInstance3D

func _ready():
	setup_point_scene()

func setup_point_scene():
	# Get references to the pickable sphere from scene
	grab_sphere = get_node("GrabSphere")
	point_sphere = grab_sphere.get_node("MeshInstance3D")

	# Create main position label
	position_label = Label3D.new()
	position_label.name = "PositionLabel"
	position_label.position = Vector3(0, 0.1, 0)  # Over the sphere
	position_label.font_size = 14
	position_label.modulate = Color.YELLOW  # Yellow for better visibility
	position_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	position_label.text = get_position_text()

	# Add outline for better readability
	position_label.outline_size = 2
	position_label.outline_modulate = Color.BLACK

	# Add label as child of the grab sphere so it follows the point
	grab_sphere.add_child(position_label)

	_apply_label_style()

func _apply_label_style() -> void:
	# Posture of the readout only — never rebuilds the label, so a config arriving after
	# _ready re-poses the same node instead of replacing it.
	if position_label == null:
		return
	position_label.visible = frame != "mute"
	match attach:
		"stake":
			position_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			position_label.position = Vector3(0.0, 0.22, 0.0)
			position_label.rotation_degrees = Vector3.ZERO
			position_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		"plate":
			position_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			position_label.position = Vector3(0.0, -0.06, 0.0)
			position_label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			position_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_:
			position_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			position_label.position = Vector3(0.0, 0.1, 0.0)
			position_label.rotation_degrees = Vector3.ZERO
			position_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

func get_position_text() -> String:
	# Use the grab sphere's global position since the label is now a child of it
	var pos = global_position
	if grab_sphere:
		pos = grab_sphere.global_position

	# if/elif rather than match: every branch returns, and the analyzer must be able to see
	# that without relying on a wildcard being read as exhaustive.
	if frame == "mute":
		return ""
	if frame == "local":
		var offset: Vector3 = pos - global_position
		return "offset: (%.1f, %.1f, %.1f)" % [offset.x, offset.y, offset.z]
	if frame == "grid":
		return "cell: (%d, %d, %d)" % [int(round(pos.x)), int(round(pos.y)), int(round(pos.z))]

	# Format numbers to always show exactly one decimal place
	return "local position: (%.1f, %.1f, %.1f)" % [pos.x, pos.y, pos.z]

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	var changed: bool = false
	if config_data.has("frame"):
		var want_frame: String = str(config_data["frame"]).strip_edges().to_lower()
		if want_frame in ["world", "local", "grid", "mute"] and want_frame != frame:
			frame = want_frame
			changed = true
	if config_data.has("attach"):
		var want_attach: String = str(config_data["attach"]).strip_edges().to_lower()
		if want_attach in ["float", "stake", "plate"] and want_attach != attach:
			attach = want_attach
			changed = true

	# Guarded: only when a value actually changed, and only once the label exists.
	if changed and position_label != null:
		_apply_label_style()
		position_label.text = get_position_text()

func _process(_delta):
	# Update position text continuously
	if position_label:
		position_label.text = get_position_text()

# Public method to set position and update display
func set_point_position(new_position: Vector3):
	global_position = new_position
	if grab_sphere:
		grab_sphere.global_position = new_position
	if position_label:
		position_label.text = get_position_text()

# Public method to change color (delegates to point_color if available)
func set_point_color(color: Color):
	# Find or create point_color node
	var point_color = get_node_or_null("PointColor")
	if not point_color:
		# Legacy fallback if point_color module not added
		if point_sphere:
			var material: StandardMaterial3D
			if point_sphere.material_override and point_sphere.material_override is StandardMaterial3D:
				material = point_sphere.material_override as StandardMaterial3D
			else:
				material = StandardMaterial3D.new()
				material.emission_enabled = true
				material.flags_unshaded = true
				point_sphere.material_override = material
			material.albedo_color = color
			material.emission = color * 0.8
	else:
		point_color.set_color(color)

# Public method to get the pickable sphere (for external scripts)
func get_pickable_sphere() -> Node3D:
	return grab_sphere

# Public method to check if sphere is being grabbed
func is_grabbed() -> bool:
	if grab_sphere and grab_sphere.has_method("is_picked_up"):
		return grab_sphere.is_picked_up()
	return false

# Public method to toggle label visibility
func set_label_visible(visible: bool):
	if position_label:
		position_label.visible = visible

# Public method to adjust label offset from the point
func set_label_offset(offset: Vector3):
	if position_label:
		position_label.position = offset

# Public method to set label color
func set_label_color(color: Color):
	if position_label:
		position_label.modulate = color
