@tool
extends Node3D

# Coordinate System Visualization
# Illustrates X, Y, Z axes with 3m length.

const GyroscopeGadgetScript = preload("res://algorithms/vectors/shared/gadgets/gyroscope_gadget.gd")

@export var axis_length: float = 3.0
@export var axis_thickness: float = 0.02 # Thinner lines

var gyroscope: Node3D

func _ready() -> void:
	# Half-size for exhibition display
	scale = Vector3(0.5, 0.5, 0.5)

	# Clear existing children to avoid duplication if running in tool mode updates
	for child in get_children():
		child.queue_free()

	create_axis(Vector3.RIGHT, Color.RED, "X")
	create_axis(Vector3.UP, Color.GREEN, "Y")
	create_axis(Vector3.BACK, Color.BLUE, "Z")

	# Info frame and gadget only at runtime (not in editor tool mode)
	if not Engine.is_editor_hint():
		_add_info_frame()
		_add_gyroscope()

func _add_info_frame() -> void:
	var sc := 0.33  # Match SCENE_SCALE from VectorSceneBase
	var panel_pos := Vector3(0, 1.2, -0.5) * sc
	var panel_size := Vector2(1.4, 0.8) * sc
	var title_height := 0.12 * sc
	var gap := 0.025 * sc

	var panel := Node3D.new()
	panel.name = "InfoPanel"
	panel.position = panel_pos
	add_child(panel)

	# Title bar
	var title_panel := Node3D.new()
	title_panel.name = "TitlePanel"
	title_panel.position.y = panel_size.y / 2.0 + title_height / 2.0 + gap
	panel.add_child(title_panel)

	var title_backing := MeshInstance3D.new()
	var title_box := BoxMesh.new()
	title_box.size = Vector3(panel_size.x, title_height, 0.01 * sc)
	title_backing.mesh = title_box
	var title_mat := StandardMaterial3D.new()
	title_mat.albedo_color = Color(0.06, 0.07, 0.1, 0.95)
	title_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	title_mat.render_priority = -10
	title_backing.material_override = title_mat
	title_panel.add_child(title_backing)

	var title_label := Label3D.new()
	title_label.text = "COORDINATE SYSTEM"
	title_label.pixel_size = 0.0015
	title_label.font_size = 28
	title_label.modulate = Color.WHITE
	title_label.no_depth_test = true
	title_label.render_priority = 100
	title_label.outline_size = 4
	title_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.position.z = 0.08 * sc
	title_panel.add_child(title_label)

	# Main backing
	var backing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(panel_size.x, panel_size.y, 0.01 * sc)
	backing.mesh = box
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.04, 0.05, 0.07, 0.95)
	back_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	back_mat.render_priority = -10
	backing.material_override = back_mat
	panel.add_child(backing)

	# Formula
	var content_top := panel_size.y / 2.0 - 0.03 * sc
	var formula_label := Label3D.new()
	formula_label.text = "P = (x, y, z)"
	formula_label.pixel_size = 0.0015
	formula_label.font_size = 22
	formula_label.modulate = Color(0.85, 0.95, 1.0)
	formula_label.no_depth_test = true
	formula_label.render_priority = 100
	formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formula_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	formula_label.position = Vector3(0, content_top, 0.08 * sc)
	panel.add_child(formula_label)

	# Accent line
	var accent := MeshInstance3D.new()
	var accent_box := BoxMesh.new()
	accent_box.size = Vector3(panel_size.x * 0.6, 0.002 * sc, 0.005 * sc)
	accent.mesh = accent_box
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.4, 0.7, 1.0)
	accent_mat.emission_enabled = true
	accent_mat.emission = Color(0.3, 0.5, 0.8)
	accent_mat.emission_energy_multiplier = 1.5
	accent.material_override = accent_mat
	accent.position = Vector3(0, content_top - 0.05 * sc, 0.003 * sc)
	panel.add_child(accent)

	# Description
	var desc_label := Label3D.new()
	desc_label.text = "Three perpendicular axes define 3D space"
	desc_label.pixel_size = 0.0015
	desc_label.font_size = 16
	desc_label.modulate = Color(0.55, 0.6, 0.65)
	desc_label.no_depth_test = true
	desc_label.render_priority = 100
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.position = Vector3(0, content_top - 0.12 * sc, 0.08 * sc)
	panel.add_child(desc_label)

func _add_gyroscope() -> void:
	gyroscope = GyroscopeGadgetScript.new()
	gyroscope.position = Vector3(-1.5, 0.5, 0)
	add_child(gyroscope)

func create_axis(direction: Vector3, color: Color, label_text: String) -> void:
	# 1. The Shaft (Cylinder)
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = axis_thickness
	mesh.bottom_radius = axis_thickness
	mesh.height = axis_length
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Transparency settings
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.5 # 50% Transparent
	
	mesh_instance.material_override = material
	
	# Position: The cylinder is centered at (0,0,0) by default.
	# We want it to start at (0,0,0) and go to direction * length.
	# So center should be at direction * (length / 2).
	mesh_instance.position = direction * (axis_length / 2.0)
	
	# Orientation: Cylinder is Y-aligned by default.
	# We need to rotate it to match 'direction'.
	if direction != Vector3.UP:
		var up = Vector3.UP
		var axis = up.cross(direction).normalized()
		var angle = up.angle_to(direction)
		mesh_instance.rotate(axis, angle)
		
	add_child(mesh_instance)
	
	# 2. The Tip (Cone)
	var cone_instance = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = axis_thickness * 2.5
	cone.height = axis_thickness * 4.0
	cone_instance.mesh = cone
	cone_instance.material_override = material
	
	cone_instance.position = direction * axis_length
	if direction != Vector3.UP:
		var up = Vector3.UP
		var axis = up.cross(direction).normalized()
		var angle = up.angle_to(direction)
		cone_instance.rotate(axis, angle)
		
	add_child(cone_instance)
	
	# 3. The Label (Label3D)
	var label = Label3D.new()
	label.text = label_text
	label.modulate = color
	label.font_size = 64
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = direction * (axis_length + 0.2)
	add_child(label)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
