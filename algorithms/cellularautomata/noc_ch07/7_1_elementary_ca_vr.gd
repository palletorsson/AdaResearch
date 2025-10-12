extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_ACTIVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_INACTIVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_fishtank_glass.tres")

@export var rule_number: int = 30
@export var rows_visible: int = 36
@export var update_interval: float = 0.2

const GRID_WIDTH := 64
const CELL_WIDTH := 0.9 / GRID_WIDTH

var _sim_root: Node3D
var _rows: Array[PackedByteArray] = []
var _row_meshes: Array[MeshInstance3D] = []
var _timer: float = 0.0
var _next_row_index: int = 1
var _status_label: Label3D

func _ready() -> void:
	randomize()
	_setup_environment()
	_initialize_rows()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)

	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	var controller_root := Node3D.new()
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var rule_controller := CONTROLLER_SCENE.instantiate()
	rule_controller.parameter_name = "Rule"
	rule_controller.min_value = 0
	rule_controller.max_value = 255
	rule_controller.step_size = 1
	rule_controller.default_value = rule_number
	rule_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(rule_controller)
	rule_controller.value_changed.connect(func(v: float) -> void:
		rule_number = int(v)
		_initialize_rows()
	)
	rule_controller.set_value(rule_number)

	_update_status()

func _initialize_rows() -> void:
	for mesh in _row_meshes:
		mesh.queue_free()
	_row_meshes.clear()
	_rows.clear()

	_rows.resize(rows_visible)
	for r in range(rows_visible):
		var row := PackedByteArray()
		row.resize(GRID_WIDTH)
		for c in range(GRID_WIDTH):
			row[c] = 0
		_rows[r] = row

	_rows[0][GRID_WIDTH / 2] = 1
	_next_row_index = 1

	for r in range(rows_visible):
		var mesh := MeshInstance3D.new()
		mesh.position = Vector3(0, 0.15 + r * 0.02, 0)
		_sim_root.add_child(mesh)
		_row_meshes.append(mesh)
		_update_row_mesh(r)

	_timer = 0.0

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_step_generation()

func _step_generation() -> void:
	if _next_row_index < rows_visible:
		_generate_row(_next_row_index)
		_update_row_mesh(_next_row_index)
		_next_row_index += 1
	else:
		_scroll_rows()
		_generate_row(rows_visible - 1)
		_update_row_mesh(rows_visible - 1)

func _generate_row(index: int) -> void:
	var prev := _rows[(index - 1 + rows_visible) % rows_visible]
	var current := _rows[index % rows_visible]
	for c in range(GRID_WIDTH):
		var left := prev[(c - 1 + GRID_WIDTH) % GRID_WIDTH]
		var center := prev[c]
		var right := prev[(c + 1) % GRID_WIDTH]
		var neighborhood := (left << 2) | (center << 1) | right
		current[c] = (rule_number >> neighborhood) & 1

func _scroll_rows() -> void:
	for r in range(rows_visible - 1):
		_rows[r] = _rows[r + 1].duplicate()
		_update_row_mesh(r)

func _update_row_mesh(index: int) -> void:
	var row := _rows[index]
	var surface := ImmediateMesh.new()
	surface.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in range(GRID_WIDTH):
		if row[c] == 0:
			continue
		surface.surface_set_color(Color(1.0, 0.7, 0.95))
		var x0 := -0.45 + c * CELL_WIDTH
		var x1 := x0 + CELL_WIDTH
		var y0 := 0
		var y1 := 0.015
		# Triangle 1
		surface.surface_add_vertex(Vector3(x0, y0, 0))
		surface.surface_add_vertex(Vector3(x1, y0, 0))
		surface.surface_add_vertex(Vector3(x1, y1, 0))
		# Triangle 2
		surface.surface_add_vertex(Vector3(x0, y0, 0))
		surface.surface_add_vertex(Vector3(x1, y1, 0))
		surface.surface_add_vertex(Vector3(x0, y1, 0))
	surface.surface_end()
	_row_meshes[index].mesh = surface

func _update_status() -> void:
	_status_label.text = "Rule %d" % rule_number
