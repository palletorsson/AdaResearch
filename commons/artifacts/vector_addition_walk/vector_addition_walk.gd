# vector_addition_walk.gd
# Player-scale vector addition — walk inside a 3m coordinate grid
# Grab vector endpoints at body height, see parallelogram + component projections
#
# @identity
# essence: A + B = C at body scale. You ARE inside the vector space.
# desire: Walk along the X-axis to feel the X-component. Addition becomes spatial, not symbolic.
# critical_parameter: Grid size vs vector length — vectors must fit inside the walkable volume.
# triggers: Handle grab → vectors update, preset buttons → snap configurations
# emerges: The parallelogram from ghost arrows. Component projections along axes.
# needs: VR grabbable handles [has], preset buttons [has], 3D grid [has]
# relationships: Room-scale version of vector_addition_demo. Pairs with basis_vectors_rig.
# truth: You don't observe vector addition. You stand inside it.

extends Node3D

class_name VectorAdditionWalk

# --- Configuration ---

@export var grid_size: float = 3.0          # walkable volume in meters
@export var grid_divisions: int = 6         # lines per axis (0.5m spacing at default)
@export var max_vector_length: float = 2.5  # max arrow length in meters
@export var arrow_thickness: float = 0.025  # thick enough to see at room scale

## Vector A — defaults give a nice visible parallelogram
@export var vector_a: Vector3 = Vector3(1.5, 0.5, 0.0):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_vectors()

## Vector B
@export var vector_b: Vector3 = Vector3(0.3, 1.2, 0.8):
	set(value):
		vector_b = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_vectors()

# --- Internals ---

var _arrow_a: Node3D
var _arrow_b: Node3D
var _arrow_result: Node3D
var _arrow_a_ghost: Node3D
var _arrow_b_ghost: Node3D
var _handle_a: Node3D
var _handle_b: Node3D

var _label_a: Label3D
var _label_b: Label3D
var _label_result: Label3D
var _formula_panel: Node3D
var _control_panel: Node3D

var _grid_mesh: MeshInstance3D
var _projection_mesh: MeshInstance3D

var _time: float = 0.0

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")


func _ready() -> void:
	_build_3d_grid()
	_build_axes()
	_create_arrows()
	_create_handles()
	_create_labels()
	_create_control_panel()
	_build_projection_mesh()
	_update_vectors()


# ────────────────────────────────────────────────────────────
# 3D GRID — ImmediateMesh lines for the walkable coordinate space
# ────────────────────────────────────────────────────────────

func _build_3d_grid() -> void:
	_grid_mesh = MeshInstance3D.new()
	_grid_mesh.name = "Grid3D"

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_grid_mesh.material_override = mat

	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var half := grid_size / 2.0
	var step := grid_size / float(grid_divisions)

	# Floor grid (XZ plane at y=0)
	var floor_color := Color(0.3, 0.35, 0.4, 0.3)
	var floor_major := Color(0.4, 0.45, 0.5, 0.45)

	for i in range(grid_divisions + 1):
		var pos := -half + i * step
		var is_center := absf(pos) < 0.01
		var is_major := i % 2 == 0
		var col: Color = floor_major if (is_major or is_center) else floor_color

		# X-parallel lines on floor
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(Vector3(-half, 0, pos))
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(Vector3(half, 0, pos))

		# Z-parallel lines on floor
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(Vector3(pos, 0, -half))
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(Vector3(pos, 0, half))

	# Back wall grid (XY plane at z=-half) — very faint
	var wall_color := Color(0.25, 0.3, 0.35, 0.12)
	for i in range(grid_divisions + 1):
		var pos := -half + i * step
		# Vertical lines
		mesh.surface_set_color(wall_color)
		mesh.surface_add_vertex(Vector3(pos, 0, -half))
		mesh.surface_set_color(wall_color)
		mesh.surface_add_vertex(Vector3(pos, grid_size, -half))
		# Horizontal lines
		var y_pos := i * step
		if y_pos <= grid_size:
			mesh.surface_set_color(wall_color)
			mesh.surface_add_vertex(Vector3(-half, y_pos, -half))
			mesh.surface_set_color(wall_color)
			mesh.surface_add_vertex(Vector3(half, y_pos, -half))

	# Side wall grid (YZ plane at x=-half) — very faint
	for i in range(grid_divisions + 1):
		var pos := -half + i * step
		# Vertical lines
		mesh.surface_set_color(wall_color)
		mesh.surface_add_vertex(Vector3(-half, 0, pos))
		mesh.surface_set_color(wall_color)
		mesh.surface_add_vertex(Vector3(-half, grid_size, pos))
		# Horizontal lines
		var y_pos := i * step
		if y_pos <= grid_size:
			mesh.surface_set_color(wall_color)
			mesh.surface_add_vertex(Vector3(-half, y_pos, -half))
			mesh.surface_set_color(wall_color)
			mesh.surface_add_vertex(Vector3(-half, y_pos, half))

	mesh.surface_end()
	_grid_mesh.mesh = mesh
	add_child(_grid_mesh)

	# Ground plane — semi-transparent dark floor
	var ground := MeshInstance3D.new()
	ground.name = "GroundPlane"
	var plane := PlaneMesh.new()
	plane.size = Vector2(grid_size, grid_size)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.06, 0.06, 0.08, 0.7)
	ground_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ground_mat.metallic = 0.1
	ground_mat.roughness = 0.9
	ground.material_override = ground_mat
	ground.position.y = -0.005
	add_child(ground)

	# Origin marker — bright white sphere at (0,0,0)
	var origin := MeshInstance3D.new()
	origin.name = "Origin"
	var origin_mesh := SphereMesh.new()
	origin_mesh.radius = 0.04
	origin_mesh.height = 0.08
	origin.mesh = origin_mesh
	var origin_mat := StandardMaterial3D.new()
	origin_mat.albedo_color = Color.WHITE
	origin_mat.emission_enabled = true
	origin_mat.emission = Color.WHITE
	origin_mat.emission_energy_multiplier = 0.8
	origin.material_override = origin_mat
	add_child(origin)


# ────────────────────────────────────────────────────────────
# AXES — colored axis lines with labels at room scale
# ────────────────────────────────────────────────────────────

func _build_axes() -> void:
	var axes := VectorVisuals.create_axes(self, grid_size / 2.0)
	# Scale up the axis thickness for room scale
	axes.name = "RoomAxes"


# ────────────────────────────────────────────────────────────
# ARROWS — A, B, result, plus ghost copies for parallelogram
# ────────────────────────────────────────────────────────────

func _create_arrows() -> void:
	_arrow_a = VectorVisuals.create_arrow(self, "ArrowA", VectorVisuals.COLORS["vec_a"], arrow_thickness)
	_arrow_b = VectorVisuals.create_arrow(self, "ArrowB", VectorVisuals.COLORS["vec_b"], arrow_thickness)
	_arrow_result = VectorVisuals.create_arrow(self, "ArrowResult", VectorVisuals.COLORS["result"], arrow_thickness)
	_arrow_a_ghost = VectorVisuals.create_arrow(self, "ArrowAGhost", VectorVisuals.COLORS["vec_a"], arrow_thickness, true)
	_arrow_b_ghost = VectorVisuals.create_arrow(self, "ArrowBGhost", VectorVisuals.COLORS["vec_b"], arrow_thickness, true)


# ────────────────────────────────────────────────────────────
# HANDLES — grabbable spheres at vector endpoints (body scale)
# ────────────────────────────────────────────────────────────

func _create_handles() -> void:
	_handle_a = VectorVisuals.create_handle(self, "HandleA", VectorVisuals.COLORS["vec_a"], 0.1)
	_handle_a.position = vector_a

	_handle_b = VectorVisuals.create_handle(self, "HandleB", VectorVisuals.COLORS["vec_b"], 0.1)
	_handle_b.position = vector_b


# ────────────────────────────────────────────────────────────
# LABELS — floating billboard text for vectors + formula panel
# ────────────────────────────────────────────────────────────

func _create_labels() -> void:
	# Exhibition plate — at edge of grid, eye height
	VectorVisuals.create_exhibition_plate(self, "TitlePlate",
		"VECTOR ADDITION",
		"Walk inside. Grab the handles.\nA + B = C",
		Vector3(0, 1.2, grid_size / 2.0 + 0.3),
		Vector2(0.8, 0.2))

	# Formula panel — side of grid, facing inward
	_formula_panel = VectorVisuals.create_panel(self, "FormulaPanel", "",
		Vector3(grid_size / 2.0 + 0.25, 1.2, 0),
		Vector2(0.7, 0.35), 14, HORIZONTAL_ALIGNMENT_LEFT)
	_formula_panel.rotation_degrees = Vector3(0, -90, 0)

	# Vector labels
	_label_a = VectorVisuals.create_vector_label(self, "LabelA", "A", VectorVisuals.COLORS["vec_a"])
	_label_a.font_size = 28
	_label_a.pixel_size = 0.003

	_label_b = VectorVisuals.create_vector_label(self, "LabelB", "B", VectorVisuals.COLORS["vec_b"])
	_label_b.font_size = 28
	_label_b.pixel_size = 0.003

	_label_result = VectorVisuals.create_vector_label(self, "LabelResult", "A+B", VectorVisuals.COLORS["result"])
	_label_result.font_size = 28
	_label_result.pixel_size = 0.003


# ────────────────────────────────────────────────────────────
# CONTROL PANEL — preset buttons at waist height
# ────────────────────────────────────────────────────────────

func _create_control_panel() -> void:
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.85, grid_size / 2.0 + 0.4)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	# Panel backing
	var backing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.15, 0.015)
	backing.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.04, 0.06, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.2
	backing.material_override = mat
	backing.position.z = -0.01
	_control_panel.add_child(backing)

	var presets := [
		["ORTHO", Vector3(2.0, 0, 0), Vector3(0, 1.5, 0)],
		["ACUTE", Vector3(1.5, 0.5, 0), Vector3(0.5, 1.5, 0)],
		["3D",    Vector3(1.2, 0.5, 0.6), Vector3(0.4, 1.0, 0.8)],
		["RESET", Vector3(1.5, 0.5, 0.0), Vector3(0.3, 1.2, 0.8)],
	]

	for i in range(presets.size()):
		var btn := PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.2 + i * 0.13, 0, 0.01)
		btn.scale = Vector3(1.0, 1.0, 1.0)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i][0])

		var va: Vector3 = presets[i][1]
		var vb: Vector3 = presets[i][2]
		var area := btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b: bool) -> void: _apply_preset(va, vb))


func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 11
	lbl.outline_size = 4
	lbl.outline_modulate = Color(0, 0, 0, 0.6)
	lbl.position = Vector3(0, -0.035, 0.015)
	btn.add_child(lbl)


func _apply_preset(va: Vector3, vb: Vector3) -> void:
	vector_a = va
	vector_b = vb
	_handle_a.position = vector_a
	_handle_b.position = vector_b


# ────────────────────────────────────────────────────────────
# COMPONENT PROJECTIONS — dashed lines along axes
# ────────────────────────────────────────────────────────────

func _build_projection_mesh() -> void:
	_projection_mesh = MeshInstance3D.new()
	_projection_mesh.name = "Projections"
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_projection_mesh.material_override = mat
	add_child(_projection_mesh)


func _rebuild_projections() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Component projections for vector A
	_draw_dashed_line(mesh, Vector3.ZERO, Vector3(vector_a.x, 0, 0),
		VectorVisuals.COLORS["axis_x"], 0.05)
	_draw_dashed_line(mesh, Vector3(vector_a.x, 0, 0), Vector3(vector_a.x, vector_a.y, 0),
		VectorVisuals.COLORS["axis_y"], 0.05)
	_draw_dashed_line(mesh, Vector3(vector_a.x, vector_a.y, 0), vector_a,
		VectorVisuals.COLORS["axis_z"], 0.05)

	# Component projections for result (A+B)
	var result := vector_a + vector_b
	_draw_dashed_line(mesh, Vector3.ZERO, Vector3(result.x, 0, 0),
		Color(VectorVisuals.COLORS["result"], 0.4), 0.08)
	_draw_dashed_line(mesh, Vector3(result.x, 0, 0), Vector3(result.x, result.y, 0),
		Color(VectorVisuals.COLORS["result"], 0.4), 0.08)
	_draw_dashed_line(mesh, Vector3(result.x, result.y, 0), result,
		Color(VectorVisuals.COLORS["result"], 0.4), 0.08)

	mesh.surface_end()
	_projection_mesh.mesh = mesh


func _draw_dashed_line(mesh: ImmediateMesh, from: Vector3, to: Vector3,
		color: Color, dash_length: float) -> void:
	var direction := to - from
	var total_length := direction.length()
	if total_length < 0.01:
		return

	var dir := direction.normalized()
	var drawn := 0.0
	var drawing := true

	while drawn < total_length:
		var segment := minf(dash_length, total_length - drawn)
		if drawing:
			mesh.surface_set_color(color)
			mesh.surface_add_vertex(from + dir * drawn)
			mesh.surface_set_color(color)
			mesh.surface_add_vertex(from + dir * (drawn + segment))
		drawn += segment
		drawing = not drawing


# ────────────────────────────────────────────────────────────
# UPDATE — position all arrows, ghosts, labels, projections
# ────────────────────────────────────────────────────────────

func _update_vectors() -> void:
	var result := vector_a + vector_b

	# Main arrows from origin
	VectorVisuals.position_arrow(_arrow_a, Vector3.ZERO, vector_a, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_b, Vector3.ZERO, vector_b, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_result, Vector3.ZERO, result, arrow_thickness)

	# Ghost arrows for parallelogram
	VectorVisuals.position_arrow(_arrow_a_ghost, vector_b, vector_b + vector_a, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_b_ghost, vector_a, vector_a + vector_b, arrow_thickness)

	# Labels — offset slightly toward viewer
	_label_a.position = vector_a * 0.5 + Vector3(0, 0.15, 0.15)
	_label_b.position = vector_b * 0.5 + Vector3(0, 0.15, 0.15)
	_label_result.position = result * 0.5 + Vector3(0, 0.2, 0.2)

	# Formula panel
	var formula_label := VectorVisuals.get_panel_label(_formula_panel)
	if formula_label:
		formula_label.text = "A = (%.1f, %.1f, %.1f)  |A| = %.2f\n" % [vector_a.x, vector_a.y, vector_a.z, vector_a.length()]
		formula_label.text += "B = (%.1f, %.1f, %.1f)  |B| = %.2f\n\n" % [vector_b.x, vector_b.y, vector_b.z, vector_b.length()]
		formula_label.text += "A + B = (%.1f, %.1f, %.1f)\n" % [result.x, result.y, result.z]
		formula_label.text += "|A + B| = %.2f" % result.length()

	# Component projections
	_rebuild_projections()


# ────────────────────────────────────────────────────────────
# PROCESS — handle pulse animation + VR handle tracking
# ────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_time += delta

	VectorVisuals.pulse_handle(_handle_a, delta, _time)
	VectorVisuals.pulse_handle(_handle_b, delta, _time + 1.0)
	VectorVisuals.pulse_arrow(_arrow_result, delta, _time)

	# Track handle position changes (VR grab)
	if _handle_a.position.distance_to(vector_a) > 0.01:
		vector_a = _handle_a.position
	if _handle_b.position.distance_to(vector_b) > 0.01:
		vector_b = _handle_b.position


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_preset(Vector3(2.0, 0, 0), Vector3(0, 1.5, 0))
			KEY_2: _apply_preset(Vector3(1.5, 0.5, 0), Vector3(0.5, 1.5, 0))
			KEY_3: _apply_preset(Vector3(1.2, 0.5, 0.6), Vector3(0.4, 1.0, 0.8))
			KEY_R: _apply_preset(Vector3(1.5, 0.5, 0.0), Vector3(0.3, 1.2, 0.8))


# ────────────────────────────────────────────────────────────
# PUBLIC API
# ────────────────────────────────────────────────────────────

func set_vectors(a: Vector3, b: Vector3) -> void:
	vector_a = a
	vector_b = b
	_handle_a.position = vector_a
	_handle_b.position = vector_b


func get_result() -> Vector3:
	return vector_a + vector_b


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		if key in self:
			set(key, config_data[key])
