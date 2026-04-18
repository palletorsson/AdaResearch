extends Node3D
class_name XYZSliderPlate

# @identity
# essence: three sliders (X, Y, Z) that move a point through space — coordinates made tangible
# desire: learner builds the intuition that position = three independent numbers by moving each axis alone
# critical_parameter: the live coordinate display — numbers change as sliders move, connecting gesture to math
# triggers: each slider controls one axis; the point moves in real-time; label updates continuously
# emerges: axis independence — moving X doesn't change Y; the three dimensions are orthogonal
# needs: slider_horizontal [has]; Label3D [has]; target point [has]
# relationships: complements interactive_point_origin (grab = all axes at once); this separates them
# truth: a coordinate is three independent measurements — the slider plate makes independence visible

## Dieter Rams plate with X, Y, Z sliders that drive a visible point.
## The point is a glowing sphere that moves in world space as you adjust sliders.
## Coordinate label updates live. Uses RackTemplates for the Rams aesthetic.

@export_group("Range")
@export var min_value: float = -1.0
@export var max_value: float = 1.0
@export var start_position: Vector3 = Vector3(0.0, 0.5, 0.0)

@export_group("Point Appearance")
@export var point_radius: float = 0.025
@export var point_color: Color = Color(0.3, 0.8, 1.0)  # cyan
@export var line_to_origin: bool = true

@export_group("Display")
@export var panel_tilt: float = -25.0  # degrees, angled toward player
@export var panel_offset: Vector3 = Vector3(0, 0, 0.25)  # in front of point

# Internal
var _panel: Node3D
var _slider_x: Node
var _slider_y: Node
var _slider_z: Node
var _point_mesh: MeshInstance3D
var _point_material: StandardMaterial3D
var _coord_label: Label3D       # billboard above point
var _display_label: Label3D     # Rams text display on panel
var _display_container: Node3D
var _origin_line: MeshInstance3D
var _origin_cylinder: CylinderMesh
var _origin_line_mat: StandardMaterial3D
var _current_pos: Vector3


func _ready() -> void:
	_current_pos = start_position
	_build_point()
	_build_coord_label()
	if line_to_origin:
		_build_origin_line()
	_build_panel()
	_update_point()


func _process(_delta: float) -> void:
	_read_sliders()
	_update_point()


# ── Point ────────────────────────────────────────────────────────────

func _build_point() -> void:
	_point_mesh = MeshInstance3D.new()
	_point_mesh.name = "TargetPoint"
	var sphere := SphereMesh.new()
	sphere.radius = point_radius
	sphere.height = point_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	_point_mesh.mesh = sphere
	_point_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_point_material = StandardMaterial3D.new()
	_point_material.albedo_color = point_color
	_point_material.emission_enabled = true
	_point_material.emission = point_color
	_point_material.emission_energy_multiplier = 1.5
	_point_mesh.material_override = _point_material
	add_child(_point_mesh)


func _build_coord_label() -> void:
	_coord_label = Label3D.new()
	_coord_label.name = "CoordLabel"
	_coord_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_coord_label.font_size = 32
	_coord_label.pixel_size = 0.001
	_coord_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	_coord_label.outline_size = 4
	_coord_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	add_child(_coord_label)


func _build_origin_line() -> void:
	_origin_line = MeshInstance3D.new()
	_origin_line.name = "OriginLine"
	_origin_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_origin_cylinder = CylinderMesh.new()
	_origin_cylinder.top_radius = 0.002
	_origin_cylinder.bottom_radius = 0.002
	_origin_cylinder.radial_segments = 6
	_origin_cylinder.rings = 1
	_origin_line.mesh = _origin_cylinder

	_origin_line_mat = StandardMaterial3D.new()
	_origin_line_mat.albedo_color = Color(point_color, 0.5)
	_origin_line_mat.emission_enabled = true
	_origin_line_mat.emission = point_color
	_origin_line_mat.emission_energy_multiplier = 0.6
	_origin_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_origin_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_origin_line.material_override = _origin_line_mat
	add_child(_origin_line)


# ── Panel ────────────────────────────────────────────────────────────

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var RackPassive: GDScript = load("res://commons/interactables/RackPassiveElements.gd")
	var x_norm := _val_to_norm(start_position.x)
	var y_norm := _val_to_norm(start_position.y)
	var z_norm := _val_to_norm(start_position.z)

	_panel = RackTpl.create_panel("COORDINATES", [
		[{"type": "slider_h", "label": "X", "default": x_norm}],
		[{"type": "slider_h", "label": "Y", "default": y_norm}],
		[{"type": "slider_h", "label": "Z", "default": z_norm}],
	])
	_panel.position = panel_offset
	_panel.rotation_degrees.x = panel_tilt
	add_child(_panel)

	# Add Rams text display above the panel for coordinate readout
	_display_container = Node3D.new()
	_display_container.name = "CoordDisplay"
	# Position above the panel title
	_display_container.position = Vector3(0, 0.16, 0.006)
	_panel.add_child(_display_container)
	RackPassive.build_text_display_static(_display_container, 1, "(0.00, 0.00, 0.00)")
	# Get the label reference so we can update it
	_display_label = _display_container.find_child("TextContent", true, false) as Label3D

	# Find sliders by child index (Param_0, Param_1, Param_2)
	_slider_x = _panel.find_child("Param_0", true, false)
	_slider_y = _panel.find_child("Param_1", true, false)
	_slider_z = _panel.find_child("Param_2", true, false)

	# Connect signals
	if _slider_x and _slider_x.has_signal("slider_moved"):
		_slider_x.slider_moved.connect(_on_slider_changed)
	if _slider_y and _slider_y.has_signal("slider_moved"):
		_slider_y.slider_moved.connect(_on_slider_changed)
	if _slider_z and _slider_z.has_signal("slider_moved"):
		_slider_z.slider_moved.connect(_on_slider_changed)

	# Color the slider labels to match axis colors
	_color_slider_label(_slider_x, Color(1.0, 0.3, 0.3))  # X = red
	_color_slider_label(_slider_y, Color(0.3, 1.0, 0.3))  # Y = green
	_color_slider_label(_slider_z, Color(0.3, 0.5, 1.0))  # Z = blue


func _color_slider_label(slider: Node, color: Color) -> void:
	if not slider:
		return
	var label := slider.get_node_or_null("Frame/LabelName") as Label3D
	if label:
		label.modulate = color


# ── Slider Reading ───────────────────────────────────────────────────

func _on_slider_changed(_position) -> void:
	_read_sliders()


func _read_sliders() -> void:
	if _slider_x and _slider_x.has_method("get_normalized_value"):
		_current_pos.x = _norm_to_val(_slider_x.get_normalized_value())
	if _slider_y and _slider_y.has_method("get_normalized_value"):
		_current_pos.y = _norm_to_val(_slider_y.get_normalized_value())
	if _slider_z and _slider_z.has_method("get_normalized_value"):
		_current_pos.z = _norm_to_val(_slider_z.get_normalized_value())


func _val_to_norm(val: float) -> float:
	return clampf((val - min_value) / (max_value - min_value), 0.0, 1.0)


func _norm_to_val(norm: float) -> float:
	return min_value + norm * (max_value - min_value)


# ── Update ───────────────────────────────────────────────────────────

func _update_point() -> void:
	# Move point
	if _point_mesh:
		_point_mesh.position = _current_pos

	# Update billboard label above point
	var coord_text := "(%.2f, %.2f, %.2f)" % [_current_pos.x, _current_pos.y, _current_pos.z]
	if _coord_label:
		_coord_label.text = coord_text
		_coord_label.position = _current_pos + Vector3(0, point_radius + 0.04, 0)

	# Update Rams text display on panel
	if _display_label:
		_display_label.text = coord_text

	# Update line to origin
	if _origin_line and _origin_cylinder:
		var dist := _current_pos.length()
		if dist < 0.001:
			_origin_line.visible = false
		else:
			_origin_line.visible = true
			_origin_cylinder.height = dist
			var midpoint := _current_pos / 2.0
			_origin_line.position = midpoint
			var direction := _current_pos.normalized()
			var up := Vector3.UP
			if absf(direction.dot(up)) > 0.99:
				up = Vector3.RIGHT
			_origin_line.look_at(_current_pos, up)
			_origin_line.rotate_object_local(Vector3.RIGHT, PI / 2.0)


# ── Grid Config ──────────────────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("min_value"):
		min_value = config_data["min_value"]
	if config_data.has("max_value"):
		max_value = config_data["max_value"]
	if config_data.has("start_position"):
		var sp = config_data["start_position"]
		if sp is Array and sp.size() == 3:
			start_position = Vector3(sp[0], sp[1], sp[2])
	if config_data.has("line_to_origin"):
		line_to_origin = config_data["line_to_origin"]
