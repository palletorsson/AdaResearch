extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_ACTIVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_INACTIVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_fishtank_glass.tres")

@export var rule_number: int = 30
@export var rows_visible: int = 36
@export var update_interval: float = 0.2

const GRID_WIDTH := 128
const CELL_WIDTH := 0.9 / GRID_WIDTH

var _sim_root: Node3D
var _rows: Array[PackedByteArray] = []
var _multi_mesh: MultiMeshInstance3D
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
	
	# Setup MultiMesh
	_multi_mesh = MultiMeshInstance3D.new()
	_sim_root.add_child(_multi_mesh)
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.mesh.size = Vector3(CELL_WIDTH * 0.95, 0.015, 0.015) # Thin strip like original triangle
	mm.instance_count = rows_visible * GRID_WIDTH
	_multi_mesh.multimesh = mm
	
	# Initialize transforms once
	var idx = 0
	for r in range(rows_visible):
		for c in range(GRID_WIDTH):
			var x = -0.45 + c * CELL_WIDTH + CELL_WIDTH * 0.5
			var y = 0.15 + r * 0.02
			var t = Transform3D(Basis(), Vector3(x, y, 0))
			mm.set_instance_transform(idx, t)
			mm.set_instance_color(idx, Color(0,0,0,0)) # Invisible initially
			idx += 1

	_update_status()

func _initialize_rows() -> void:
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
	
	_update_all_visuals()
	_timer = 0.0

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_step_generation()

func _step_generation() -> void:
	if _next_row_index < rows_visible:
		_generate_row(_next_row_index)
		_next_row_index += 1
	else:
		_scroll_rows()
		_generate_row(rows_visible - 1)
	
	_update_all_visuals()

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

func _update_all_visuals() -> void:
	if not _multi_mesh:
		return
	var mm = _multi_mesh.multimesh
	var idx = 0
	var active_color = Color(1.0, 0.7, 0.95)
	var inactive_color = Color(0,0,0,0)
	
	for r in range(rows_visible):
		var row = _rows[r]
		for c in range(GRID_WIDTH):
			if row[c] == 1:
				mm.set_instance_color(idx, active_color)
			else:
				mm.set_instance_color(idx, inactive_color)
			idx += 1

func _update_status() -> void:
	_status_label.text = "Rule %d" % rule_number

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
