# PointScene.gd - Pickable point with position display
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
	
	# Create position label
	position_label = Label3D.new()
	position_label.name = "PositionLabel"
	position_label.position = Vector3(0, 0.35, 0)  # Above the sphere
	position_label.font_size = 16
	position_label.modulate = Color.WHITE
	position_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	position_label.text = get_position_text()
	
	add_child(position_label)

func get_position_text() -> String:
	# Use the grab sphere's position if it exists, otherwise use this node's position
	var pos = position
	if grab_sphere:
		pos = grab_sphere.global_position
	
	# Format numbers to always show exactly one decimal place
	return "x: %.1f y: %.1f z: %.1f" % [pos.x, pos.y, pos.z]

func _process(_delta):
	# Update position text continuously, especially important when sphere is grabbed and moved
	if position_label:
		position_label.text = get_position_text()

# Public method to set position and update display
func set_point_position(new_position: Vector3):
	position = new_position
	if grab_sphere:
		grab_sphere.global_position = new_position
	if position_label:
		position_label.text = get_position_text()

# Public method to change color
func set_point_color(color: Color):
	if point_sphere:
		# Create new material or modify existing one
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

# Public method to get the pickable sphere (for external scripts)
func get_pickable_sphere() -> Node3D:
	return grab_sphere

# Public method to check if sphere is being grabbed
func is_grabbed() -> bool:
	if grab_sphere and grab_sphere.has_method("is_picked_up"):
		return grab_sphere.is_picked_up()
	return false
