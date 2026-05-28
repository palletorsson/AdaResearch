@tool
extends Node3D

# @identity
# essence: X=red, Y=green, Z=blue axes at 3m length — the standard right-handed coordinate frame made visible, now built from the CoordinateLine primitive so every axis carries the same tick-mark ruler vocabulary
# desire: learner stands inside the coordinate system and feels orientation as embodied direction
# critical_parameter: axis_length = 3.0 — at half-scale (scale 0.5) these appear as 1.5m axes in world space
# triggers: runtime adds info panel and gyroscope gadget showing orientation relative to viewer
# emerges: the arbitrary nature of axis conventions — right-handed vs left-handed, Y-up vs Z-up are choices; AND tick marks make the chosen frame's scale legible
# needs: [has info panel [has], has gyroscope gadget [has], CoordinateLine primitive as shared axis vocabulary [present, 2026-05-19]]
# relationships: used in vectors sequence; embedded by xyz_slider_plate as the workspace coordinate frame; the gyroscope gadget adds interactive orientation feedback; consumes CoordinateLine primitive (three instances, one per axis, rotated to +X/+Y/+Z)
# truth: a coordinate system is a choice of three mutually perpendicular directions with an agreed origin — and the rulers along those directions tell you what the choice actually measures

# Coordinate System Visualization
# Illustrates X, Y, Z axes with 3m length.

const GyroscopeGadgetScript = preload("res://algorithms/vectors/shared/gadgets/gyroscope_gadget.gd")
const CoordinateLineScript = preload("res://commons/primitives/line/coordinate_line.gd")

@export var axis_length: float = 3.0
@export var axis_thickness: float = 0.02 # Thinner lines
## Spacing for tick marks along each axis, in axis-length units. Default 0.5
## gives ticks every 0.5 m along a 3 m axis — six ticks per axis, marking the
## scale clearly. Set to 0.0 to suppress ticks.
@export var tick_step: float = 0.5
## Uniform scale applied in _ready(). 0.5 = half-size exhibition default
## (was the hardcoded value). 1.5 = 3× exhibition size, useful inside
## taller rooms where the coordinate frame should fill the space.
## Driveable from map_data via `CoordinateSystem3M:0:0#display_scale:1.5`.
@export var display_scale: float = 1.5

var gyroscope: Node3D

func _ready() -> void:
	# Uniform display scale — controlled by the display_scale @export
	# (default 1.5 = 3× the original exhibition half-size).
	scale = Vector3(display_scale, display_scale, display_scale)

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
	# Build a CoordinateLine instance for the shaft + arrow + ticks. Its internal
	# geometry is along +X; we rotate the whole node to point at `direction`.
	# This replaces the inline CylinderMesh+cone duplication that used to live
	# here. The migration ensures tick marks propagate to every consumer
	# (xyz_slider_plate, etc.) without changes there.
	var axis_node: Node3D = Node3D.new()
	axis_node.script = CoordinateLineScript
	axis_node.length = axis_length
	axis_node.thickness = axis_thickness
	axis_node.color = color
	axis_node.arrow_size = axis_thickness * 4.0       # match the old cone proportions
	axis_node.from_origin = true                       # axis starts at origin, extends +length
	axis_node.unshaded = true                          # match the old unshaded look
	axis_node.alpha = 0.5                              # match the old 50% transparent look
	axis_node.show_ticks = tick_step > 0.0
	axis_node.tick_step = tick_step
	axis_node.tick_size = axis_thickness * 2.5         # tick crosses are a bit wider than the shaft
	axis_node.tick_thickness = axis_thickness * 0.6    # tick bars thinner than the shaft

	# Rotate axis_node from local +X to the world direction. Three cases for the
	# standard right-handed frame; falls back to a general from-+X rotation for
	# any other unit vector.
	if direction == Vector3.RIGHT:
		pass                                            # identity — already points along +X
	elif direction == Vector3.UP:
		axis_node.rotate(Vector3.FORWARD, deg_to_rad(-90.0))   # +X → +Y
	elif direction == Vector3.BACK:
		axis_node.rotate(Vector3.UP, deg_to_rad(90.0))         # +X → +Z (Godot Vector3.BACK = +Z)
	else:
		var from := Vector3.RIGHT
		var d := direction.normalized()
		if from.cross(d).length_squared() > 1e-8:
			var rot_axis := from.cross(d).normalized()
			var angle := from.angle_to(d)
			axis_node.rotate(rot_axis, angle)
	add_child(axis_node)

	# Label (Label3D) — kept here so the label-positioning logic stays a
	# CoordinateSystem3M concern. CoordinateLine doesn't ship a label.
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
	# map_data tokens: CoordinateSystem3M:0:0#display_scale:1.5
	if config.has("display_scale"):
		display_scale = float(config["display_scale"])
		scale = Vector3(display_scale, display_scale, display_scale)
	if config.has("axis_length"):
		axis_length = float(config["axis_length"])
	if config.has("axis_thickness"):
		axis_thickness = float(config["axis_thickness"])
	if config.has("tick_step"):
		tick_step = float(config["tick_step"])
