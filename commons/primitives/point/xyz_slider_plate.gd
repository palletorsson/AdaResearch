extends Node3D
class_name XYZSliderPlate

# @identity
# essence: three sliders (X, Y, Z) that move a point through a visible coordinate frame — coordinates made tangible, and the axes the point moves along made literal
# desire: learner builds the intuition that position = three independent numbers by moving each axis alone, AND sees the geometric coordinate frame the numbers refer to
# critical_parameter: the live coordinate display — numbers change as sliders move, connecting gesture to math; panel_scale sizes the controls for VR-hand comfort
# triggers: each slider controls one axis; the point moves in real-time inside the embedded CoordinateSystem3M frame; label updates continuously
# emerges: axis independence — moving X doesn't change Y; the three dimensions are orthogonal AND visually distinct (X red, Y green, Z blue)
# needs: slider_horizontal [has]; Label3D [has]; target point [has]; CoordinateSystem3M embedded for visible axes [present, 2026-05-19]; VR-hand-sized controls [present, 2026-05-19]
# relationships: complements interactive_point_origin (grab = all axes at once); embeds CoordinateSystem3M as visual reference frame; this separates the three independent measurements while still showing them in their shared frame
# truth: a coordinate is three independent measurements — the slider plate makes independence visible AND the frame they measure in geometric

## Dieter Rams plate with X, Y, Z sliders that drive a visible point.
## The point is a glowing sphere that moves in world space as you adjust sliders.
## Coordinate label updates live. Uses RackTemplates for the Rams aesthetic.

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

@export_group("Housing")
## Cabinet grammar (vertical dialect, body = "slider lectern"). The slider panel
## used to hang in mid-air at waist height with nothing beneath it; the lectern
## is the body it stands on, so the interface is part of an object rather than a
## floating widget. Set false to recover the old bare-panel behaviour.
@export var console_body: bool = true
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "XY-03"
## The billboard coordinate readout that used to hover above the moving point.
## Off by default: text belongs to the body (G1), and the lectern's own readout
## carries the same numbers. Set true to restore the in-place label.
@export var billboard_coords: bool = false

@export_group("Range")
## Workspace coordinate range. Default 0..4 aligns with CoordinateSystem3M's
## one-sided axes (+X +Y +Z from origin), so the point moves in a 4m cube
## that is exactly bounded by the visible axes. Each axis becomes the
## boundary of its slider's range.
@export var min_value: float = 0.0
@export var max_value: float = 4.0
## Where the point first appears. Default puts it in the visible positive
## octant, well away from the panel where the player's hands are.
@export var start_position: Vector3 = Vector3(1.5, 1.5, 1.5)

@export_group("Point Appearance")
## Larger radius — at 4m range the point can be 2-3m from the player, so it
## must be visible at distance. ~5cm sphere reads cleanly across the workspace.
@export var point_radius: float = 0.06
@export var point_color: Color = Color(0.3, 0.8, 1.0)  # cyan
@export var line_to_origin: bool = true

@export_group("Display")
@export var panel_tilt: float = -25.0  # degrees, angled toward player
## Default puts the panel at waist height (1.0m) just outside the +Z corner
## of the 4m workspace cube — the player stands further out, reaching toward
## the panel while looking past it into the coordinate frame.
@export var panel_offset: Vector3 = Vector3(0, 1.0, 4.5)
## VR-hand-size scale for the slider panel. 1.0 = standard rack-panel size
## (~4cm controls). 2.0 = chunky for VR hands AND legible against the 4m axes.
@export var panel_scale: float = 2.0

@export_group("Coordinate System")
## Embed a CoordinateSystem3M (X red / Y green / Z blue axes) inside the
## workspace so the point can be seen moving through a visible coordinate frame.
@export var show_coordinate_system: bool = true
## Scale applied to the embedded coordinate system. CoordinateSystem3M is 3m
## native × 0.5 self-scale = 1.5m effective. coord_system_scale = 2.67 gives
## ≈ 4m axes — matching the default workspace range, so each axis is exactly
## the boundary of its slider. The whole frame stands on the ground (artifact
## root at y=0) with the Y axis rising 4m straight up.
@export var coord_system_scale: float = 2.67

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
var _coord_system: Node3D    # embedded CoordinateSystem3M (visual axis frame)
var _current_pos: Vector3


func _ready() -> void:
	_current_pos = start_position
	_build_point()
	_build_coord_label()
	if line_to_origin:
		_build_origin_line()
	if show_coordinate_system:
		_build_coordinate_system()    # embed CoordinateSystem3M visual axes
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
	if not billboard_coords:
		return
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
	# Thicker line — the workspace is now up to 4m across, a hairline
	# wouldn't be visible at distance.
	_origin_cylinder.top_radius = 0.012
	_origin_cylinder.bottom_radius = 0.012
	_origin_cylinder.radial_segments = 8
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


# ── Coordinate system embed ──────────────────────────────────────────

func _build_coordinate_system() -> void:
	# Load CoordinateSystem3M scene and add it as a child of XYZSliderPlate.
	# It self-scales to 0.5 in its own _ready() — we wrap it in a Node3D so
	# we can apply an additional scale (coord_system_scale) without fighting
	# its self-scale logic.
	var scene := load("res://algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn")
	if not scene:
		push_warning("XYZSliderPlate: CoordinateSystem3M.tscn missing")
		return
	var wrapper := Node3D.new()
	wrapper.name = "CoordinateAxes"
	# THE PHENOMENON, not the interface. Its axis tick labels ("X", "Y", "Z", the
	# unit marks) are pinned to axis geometry 4 m out — they belong to the measured
	# frame, exactly as the dice and balls belong to their own artifacts. Marked so
	# the grammar's no-orphan-text rule measures the interface, not the subject.
	wrapper.set_meta("phenomenon", true)
	wrapper.scale = Vector3.ONE * coord_system_scale
	add_child(wrapper)
	_coord_system = scene.instantiate()
	if _coord_system:
		wrapper.add_child(_coord_system)


# ── Panel ────────────────────────────────────────────────────────────

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var RackPassive: GDScript = load("res://commons/interactables/RackPassiveElements.gd")
	var x_norm := _val_to_norm(start_position.x)
	var y_norm := _val_to_norm(start_position.y)
	var z_norm := _val_to_norm(start_position.z)

	# Frameless when housed: the lectern's wedge shoulder IS the faceplate, and the
	# cap's sign band already says COORDINATES. RackTemplates' _add_panel ships a
	# cream plate and a copper accent strip (0.75,0.38,0.13) that reads as a second
	# manufacturer once the panel sits inside this body (G4).
	_panel = RackTpl.create_panel("" if console_body else "COORDINATES", [
		[{"type": "slider_h", "label": "X", "default": x_norm}],
		[{"type": "slider_h", "label": "Y", "default": y_norm}],
		[{"type": "slider_h", "label": "Z", "default": z_norm}],
	], console_body)
	# Scale up for VR-hand-comfortable controls
	_panel.scale = Vector3.ONE * panel_scale

	if console_body:
		# The panel is seated on a lectern that stands on the floor; the readout
		# is seated in the lectern's backboard. _build_console() parents both.
		_build_console(RackPassive)
	else:
		_panel.position = panel_offset
		_panel.rotation_degrees.x = panel_tilt
		add_child(_panel)
		_display_container = Node3D.new()
		_display_container.name = "CoordDisplay"
		_display_container.position = Vector3(0, 0.16, 0.006)
		_panel.add_child(_display_container)
		RackPassive.build_text_display_static(_display_container, 1, "(0.00, 0.00, 0.00)")
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


## THE LECTERN. A body for the sliders to stand on: a column from the floor up to
## the working height, a wedge shoulder the panel is seated on, and a backboard
## carrying the coordinate readout in a milled pocket under a sign band. Built at
## panel_offset's x/z so the console stands where the panel used to hover, and the
## player still reads past it into the coordinate frame.
func _build_console(RackPassive: GDScript) -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_accent: Color = pal["accent"]
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, wear)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_body.lightened(0.10))
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# Panel footprint in world metres (RackTemplates records its own size).
	var pw: float = float(_panel.get_meta("panel_w", 0.22)) * panel_scale
	var ph: float = float(_panel.get_meta("panel_h", 0.30)) * panel_scale
	var body_w: float = pw + 0.10
	var body_d: float = maxf(ph * 0.55, 0.30)
	var work_h: float = maxf(panel_offset.y, 0.80)   # slider height above floor

	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	cab.position = Vector3(panel_offset.x, 0.0, panel_offset.z)
	add_child(cab)

	var face_z: float = body_d * 0.5

	# column — the mass that reaches the floor (G2)
	cab.add_child(HangarKit.box(
		Vector3(0, work_h * 0.5, 0), Vector3(body_w, work_h, body_d), shell))
	# recessed toe kick + grime where it meets the floor
	cab.add_child(HangarKit.box(
		Vector3(0, 0.028, 0), Vector3(body_w - 0.10, 0.056, body_d - 0.10), dark))
	var gb: MeshInstance3D = HangarKit.grime_band(body_w * 0.88, 0.05, face_z + 0.003, col_body)
	if gb:
		gb.position.y = 0.072
		cab.add_child(gb)
	# side flanks
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(
			Vector3(sx * (body_w * 0.5 + 0.016), work_h * 0.5, 0.0),
			Vector3(0.032, work_h, body_d + 0.018), steel))
	# ember line under the working lip (G7)
	cab.add_child(HangarKit.box(
		Vector3(0, work_h - 0.012, face_z + 0.004),
		Vector3(body_w * 0.98, 0.007, 0.006), accent))
	# asset code stencilled on the column
	var code: MeshInstance3D = HangarKit.stencil(
		unit_code, Vector2(0.10, 0.026), col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-body_w * 0.5 + 0.09, work_h - 0.10, face_z + 0.004)
		cab.add_child(code)

	# wedge shoulder — the sloped shelf the slider panel rests on, so the
	# controls meet the body instead of hanging in air
	var shoulder: MeshInstance3D = HangarKit.wedge(
		body_w * 0.94, 0.10, body_d * 0.92, body_d * 0.30, steel)
	if shoulder:
		shoulder.position = Vector3(0.0, work_h + 0.04, -body_d * 0.42)
		cab.add_child(shoulder)

	# seat the panel on the shoulder, keeping its authored rake. Imported panels
	# ship Braun cream + copper; harmonize before seating so the controls speak
	# this body's palette (the X/Y/Z label colours are saturated and survive).
	_panel.position = Vector3(0.0, work_h + 0.10, face_z * 0.10)
	_panel.rotation_degrees.x = panel_tilt
	HangarKit.harmonize(_panel, finish)
	cab.add_child(_panel)

	# Backboard rising behind the sliders — carries the readout and the sign. It
	# must CLEAR the seated panel, which is panel_scale times its authored size:
	# sized from the panel's real height, or the sliders hide the readout.
	var clear: float = ph * 0.55 + 0.06
	var back_h: float = clear + 0.30
	var back_y: float = work_h + back_h * 0.5
	var back_z: float = -body_d * 0.5 + 0.035
	cab.add_child(HangarKit.box(
		Vector3(0, back_y, back_z), Vector3(body_w, back_h, 0.07), shell))
	# cap + sign band baked flush into it (G1: the title is part of the body)
	cab.add_child(HangarKit.box(
		Vector3(0, work_h + back_h + 0.026, back_z),
		Vector3(body_w + 0.04, 0.052, 0.10), steel))
	var sign: MeshInstance3D = HangarKit.stencil(
		"COORDINATES", Vector2(body_w * 0.80, 0.028), col_accent.lightened(0.35))
	if sign:
		sign.position = Vector3(0, work_h + back_h + 0.026, back_z + 0.052)
		cab.add_child(sign)

	# readout seated in a milled pocket on the backboard: pocket, lit face,
	# canonical glass, ember lip — then the live Label3D reads against it
	var scr_w: float = body_w * 0.78
	var scr_h: float = 0.15
	var scr_y: float = work_h + clear + 0.14      # above the panel it reports on
	var scr_z: float = back_z + 0.035
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y, scr_z + 0.002), Vector3(scr_w + 0.026, scr_h + 0.030, 0.014), dark))
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y, scr_z + 0.009),
		Vector3(scr_w, scr_h, 0.005), HangarKit.emissive(pal["screen"], 0.45)))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.04, 0.05, 0.08)
	glass.roughness = 0.15
	glass.emission_enabled = true
	glass.emission = Color(0.05, 0.08, 0.12)
	glass.emission_energy_multiplier = 0.5
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y, scr_z + 0.0135), Vector3(scr_w, scr_h, 0.004), glass))
	cab.add_child(HangarKit.box(
		Vector3(0, scr_y + scr_h * 0.5 + 0.010, scr_z + 0.011),
		Vector3(scr_w + 0.026, 0.005, 0.005), accent))

	_display_container = Node3D.new()
	_display_container.name = "CoordDisplay"
	_display_container.position = Vector3(0, scr_y, scr_z + 0.020)
	cab.add_child(_display_container)
	RackPassive.build_text_display_static(_display_container, 1, "(0.00, 0.00, 0.00)")
	_display_label = _display_container.find_child("TextContent", true, false) as Label3D


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
	if config_data.has("panel_scale"):
		panel_scale = float(config_data["panel_scale"])
	if config_data.has("show_coordinate_system"):
		show_coordinate_system = bool(config_data["show_coordinate_system"])
	if config_data.has("coord_system_scale"):
		coord_system_scale = float(config_data["coord_system_scale"])
	if config_data.has("console_body"):
		console_body = bool(config_data["console_body"])
	if config_data.has("finish"):
		finish = str(config_data["finish"])
	if config_data.has("billboard_coords"):
		billboard_coords = bool(config_data["billboard_coords"])
