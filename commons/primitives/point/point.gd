# PointScene.gd - Pickable point with position display
# Label follows the point and appears underneath it in the scene tree
extends Node3D

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

func get_position_text() -> String:
	# Use the grab sphere's global position since the label is now a child of it
	var pos = global_position
	if grab_sphere:
		pos = grab_sphere.global_position

	# Format numbers to always show exactly one decimal place
	return "x:%.1f y:%.1f z:%.1f" % [pos.x, pos.y, pos.z]

func _process(delta):
	# Update position text continuously
	if position_label:
		position_label.text = get_position_text()

# Public method to set position and update display
func set_point_position(new_position: Vector3):
	position = new_position
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
