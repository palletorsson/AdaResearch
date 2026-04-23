extends Node3D

# @identity
# essence: a miniature 1:10 scale interactive diorama of the current map's grid — layout_data[z][x] = height rendered as stacked cubes you can grab, move, and stack to reshape the terrain in real time
# desire: to make the 2D array that defines every map touchable — to hold the data structure in your hands, see indices as spatial coordinates, and feel that editing an array cell is moving a physical block
# critical_parameter: max_model_size — the model dynamically scales so any map fits within this bounding dimension (default 1.0m); a 10×10 map = 0.1m cells, a 20×15 map = 0.05m cells
# triggers: dropping a GridModelCube fires cube_dropped → GridModel calls structure_component.stack_remove(from) + stack_add(to) → the real terrain rebuilds; structure_component.cube_changed updates the model back
# emerges: students discover that the map IS a 2D array — every column is an address [x,z], every height is a value, and reshaping terrain is just writing to array cells
# needs: GridSystem in group "grid_system" [runtime]; GridStructureComponent with enable_editing/stack_add/stack_remove [has]; GridModelCube pickable [has]; XRToolsPickable [framework]
# relationships: builds on grid_2d_4x4 (2D array with labels); extends grid_editor concept (miniature ↔ fullscale); connects to GridSystem (the actual map renderer)
# truth: a map is a 2D array made walkable — this artifact reverses the abstraction, letting you hold the array and write to it by moving blocks

class_name GridModel

# Height-based colors: 0=dark → 5=red (shared with GridModelCube)
const HEIGHT_COLORS: Array[Color] = [
	Color(0.15, 0.15, 0.2, 1.0),   # 0: dark
	Color(0.2, 0.4, 0.8, 1.0),     # 1: cool blue
	Color(0.2, 0.7, 0.3, 1.0),     # 2: green
	Color(0.9, 0.8, 0.2, 1.0),     # 3: yellow
	Color(0.9, 0.5, 0.1, 1.0),     # 4: orange
	Color(0.9, 0.2, 0.15, 1.0),    # 5: red
]

# Configuration
@export var max_model_size: float = 1.0
@export var model_elevation: float = 1.3  # Y offset for VR reachability
@export var show_array_panel: bool = true
@export var show_index_labels: bool = true
@export var spawner_count: int = 4  # Number of spawner cubes along model edge

# References to the live grid system
var _grid_system: Node = null
var _structure_component: Node = null
var _data_component: Node = null

# Model state
var _cell_size: float = 0.1
var _map_width: int = 0
var _map_depth: int = 0
var _map_max_height: int = 6
var _layout_mirror: Array = []  # Local copy: _layout_mirror[z][x] = height (int)
var _model_container: Node3D
var _cube_columns: Dictionary = {}  # "x_z" -> {cubes: Array[Node], pickable: GridModelCube}
var _spawner_cubes: Array = []
var _syncing: bool = false
var _initialized: bool = false

# Cube scene
var _cube_scene: PackedScene

# Array panel nodes
var _panel_container: Node3D
var _panel_labels: Array = []  # Array of Label3D for each row

# Grid lines node
var _grid_lines: MeshInstance3D


func _ready() -> void:
	_cube_scene = preload("res://algorithms/arrays/grid_model/grid_model_cube.tscn")

	# Create model container at desk height
	_model_container = Node3D.new()
	_model_container.name = "ModelContainer"
	_model_container.position = Vector3(0, model_elevation, 0)
	add_child(_model_container)

	# Try to find the GridSystem
	_find_grid_system()


func _find_grid_system() -> void:
	_grid_system = get_tree().get_first_node_in_group("grid_system")
	if not _grid_system:
		# Grid not loaded yet — wait for it
		get_tree().node_added.connect(_on_node_added)
		return

	# Check if data is loaded
	_data_component = _grid_system.data_component
	_structure_component = _grid_system.structure_component

	if _data_component and _data_component.is_data_loaded():
		_initialize_model()
	else:
		# Wait for map generation
		if _grid_system.has_signal("map_generation_complete"):
			_grid_system.map_generation_complete.connect(_on_map_loaded, CONNECT_ONE_SHOT)


func _on_node_added(node: Node) -> void:
	if node.is_in_group("grid_system"):
		get_tree().node_added.disconnect(_on_node_added)
		_grid_system = node
		_data_component = _grid_system.data_component
		_structure_component = _grid_system.structure_component
		if _grid_system.has_signal("map_generation_complete"):
			_grid_system.map_generation_complete.connect(_on_map_loaded, CONNECT_ONE_SHOT)


func _on_map_loaded() -> void:
	if not _initialized:
		_data_component = _grid_system.data_component
		_structure_component = _grid_system.structure_component
		_initialize_model()


func _initialize_model() -> void:
	if _initialized:
		return
	_initialized = true

	# Enable editing on the structure component
	var structure_data = _data_component.get_structure_data()
	if not structure_data:
		push_warning("GridModel: No structure data available")
		return

	_structure_component.enable_editing(structure_data)

	# Read dimensions
	var dims = _data_component.get_grid_dimensions()
	_map_width = dims.x
	_map_depth = dims.z
	_map_max_height = dims.y

	# Compute cell size to fit within max_model_size
	_compute_cell_size()

	# Build local mirror of layout_data
	_build_layout_mirror()

	# Build the visual model
	_build_model()

	# Build grid lines (base plate)
	_build_grid_lines()

	# Build index labels
	if show_index_labels:
		_build_index_labels()

	# Build 2D array panel
	if show_array_panel:
		_build_array_panel()

	# Add spawner cubes
	_build_spawners()

	# Connect to structure_component.cube_changed for bidirectional sync
	if _structure_component.has_signal("cube_changed"):
		_structure_component.cube_changed.connect(_on_big_grid_changed)

	print("GridModel: Initialized %dx%d map at cell_size=%.3f" % [_map_width, _map_depth, _cell_size])


func _compute_cell_size() -> void:
	var max_horizontal = max(_map_width, _map_depth)
	if max_horizontal <= 0:
		_cell_size = 0.1
		return

	_cell_size = max_model_size / float(max_horizontal)
	_cell_size = clampf(_cell_size, 0.02, 0.15)

	# If vertical extent exceeds model size, shrink further
	if _map_max_height * _cell_size > max_model_size:
		_cell_size = max_model_size / float(_map_max_height)
		_cell_size = maxf(_cell_size, 0.02)


func _build_layout_mirror() -> void:
	_layout_mirror = []
	for z in range(_map_depth):
		var row: Array = []
		for x in range(_map_width):
			var h = _structure_component.get_height_at(x, z)
			row.append(h)
		_layout_mirror.append(row)


## Build the miniature cube model from layout_mirror
func _build_model() -> void:
	for z in range(_map_depth):
		for x in range(_map_width):
			var height = _layout_mirror[z][x]
			_build_column(x, z, height)


## Build a column of cubes at grid position (x, z) with given height
func _build_column(x: int, z: int, height: int) -> void:
	var key = "%d_%d" % [x, z]

	# Clear existing column if any
	if _cube_columns.has(key):
		_clear_column(key)

	var column_data = {"cubes": [], "pickable": null}

	for y in range(height):
		if y == height - 1:
			# Top cube is pickable
			var cube = _spawn_pickable_cube(x, z, y)
			column_data["cubes"].append(cube)
			column_data["pickable"] = cube
		else:
			# Lower cubes are static meshes
			var static_cube = _spawn_static_cube(x, z, y)
			column_data["cubes"].append(static_cube)

	_cube_columns[key] = column_data


func _spawn_pickable_cube(x: int, z: int, y: int) -> GridModelCube:
	var cube = _cube_scene.instantiate() as GridModelCube
	cube.name = "Cube_%d_%d_%d" % [x, z, y]
	cube.cell_size = _cell_size
	cube.grid_x = x
	cube.grid_z = z
	cube.stack_y = y
	cube.map_width = _map_width
	cube.map_depth = _map_depth
	cube.grid_model = self
	cube.is_spawner = false

	_model_container.add_child(cube)
	cube.snap_to_grid(x, z, y)

	# Connect signals
	cube.cube_dropped.connect(_on_mini_cube_dropped)
	cube.cube_lifted.connect(_on_mini_cube_lifted)

	return cube


func _spawn_static_cube(x: int, z: int, y: int) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Static_%d_%d_%d" % [x, z, y]
	mesh_inst.mesh = BoxMesh.new()
	mesh_inst.scale = Vector3.ONE * _cell_size

	# Height-based color
	var color_idx = clampi(y, 0, HEIGHT_COLORS.size() - 1)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = HEIGHT_COLORS[color_idx]
	mat.emission_enabled = true
	mat.emission = HEIGHT_COLORS[color_idx] * 0.3
	mat.emission_energy_multiplier = 0.5
	mesh_inst.material_override = mat

	mesh_inst.position = Vector3(
		(x + 0.5) * _cell_size,
		(y + 0.5) * _cell_size,
		(z + 0.5) * _cell_size
	)

	_model_container.add_child(mesh_inst)
	return mesh_inst


func _clear_column(key: String) -> void:
	if not _cube_columns.has(key):
		return
	var column_data = _cube_columns[key]
	for cube in column_data["cubes"]:
		if is_instance_valid(cube):
			cube.queue_free()
	_cube_columns.erase(key)


## Called when the player drops a mini cube
func _on_mini_cube_dropped(from_x: int, from_z: int, to_x: int, to_z: int) -> void:
	# Clamp to bounds
	to_x = clampi(to_x, 0, _map_width - 1)
	to_z = clampi(to_z, 0, _map_depth - 1)

	_syncing = true

	if from_x == to_x and from_z == to_z:
		# Dropped back in same column — just re-snap
		_rebuild_column(from_x, from_z)
	else:
		# Remove from source, add to target
		var removed = _structure_component.stack_remove(from_x, from_z)
		if removed:
			var added = _structure_component.stack_add(to_x, to_z)
			if not added:
				# Target full — put it back
				_structure_component.stack_add(from_x, from_z)

		# Update mirror
		_layout_mirror[from_z][from_x] = _structure_component.get_height_at(from_x, from_z)
		_layout_mirror[to_z][to_x] = _structure_component.get_height_at(to_x, to_z)

		# Rebuild affected columns
		_rebuild_column(from_x, from_z)
		_rebuild_column(to_x, to_z)

	# Update array panel
	if show_array_panel:
		_update_array_panel()

	_syncing = false


func _on_mini_cube_lifted(x: int, z: int, stack_y: int) -> void:
	# Cube is being held — could show visual feedback on source column
	pass


## Called when the big GridSystem changes (from external source or our own sync)
func _on_big_grid_changed(pos: Vector3i, added: bool) -> void:
	if _syncing:
		return  # Our own change, already handled

	# External change — update mirror and rebuild column
	var x = pos.x
	var z = pos.z
	if z >= 0 and z < _map_depth and x >= 0 and x < _map_width:
		_layout_mirror[z][x] = _structure_component.get_height_at(x, z)
		_rebuild_column(x, z)
		if show_array_panel:
			_update_array_panel()


## Rebuild a single column from current mirror state
func _rebuild_column(x: int, z: int) -> void:
	var height = _layout_mirror[z][x] if (z < _layout_mirror.size() and x < _layout_mirror[z].size()) else 0
	_build_column(x, z, height)


## Get height at grid column (called by GridModelCube for ghost positioning)
func get_column_height(x: int, z: int) -> int:
	x = clampi(x, 0, _map_width - 1)
	z = clampi(z, 0, _map_depth - 1)
	if z < _layout_mirror.size() and x < _layout_mirror[z].size():
		return _layout_mirror[z][x]
	return 0


# ─── Spawner Cubes ───────────────────────────────────────────

func _build_spawners() -> void:
	# Place spawners along the -X edge of the model (left side)
	var spawner_x = -1  # One cell outside the model
	var z_step = max(1, _map_depth / spawner_count)

	for i in range(spawner_count):
		var sz = clampi(i * z_step, 0, _map_depth - 1)
		var cube = _cube_scene.instantiate() as GridModelCube
		cube.name = "Spawner_%d" % i
		cube.cell_size = _cell_size
		cube.grid_x = spawner_x
		cube.grid_z = sz
		cube.stack_y = 0
		cube.map_width = _map_width
		cube.map_depth = _map_depth
		cube.grid_model = self
		cube.is_spawner = true

		_model_container.add_child(cube)
		cube.position = Vector3(
			(spawner_x + 0.5) * _cell_size,
			0.5 * _cell_size,
			(sz + 0.5) * _cell_size
		)

		cube.cube_dropped.connect(_on_spawner_dropped)
		_spawner_cubes.append(cube)


func _spawn_replacement_spawner(x: int, z: int) -> void:
	# Replace a used spawner at its original position
	var cube = _cube_scene.instantiate() as GridModelCube
	cube.name = "Spawner_replacement"
	cube.cell_size = _cell_size
	cube.grid_x = x
	cube.grid_z = z
	cube.stack_y = 0
	cube.map_width = _map_width
	cube.map_depth = _map_depth
	cube.grid_model = self
	cube.is_spawner = true

	_model_container.add_child(cube)
	cube.position = Vector3(
		(x + 0.5) * _cell_size,
		0.5 * _cell_size,
		(z + 0.5) * _cell_size
	)

	cube.cube_dropped.connect(_on_spawner_dropped)
	_spawner_cubes.append(cube)


## A spawner cube was dropped — add height to the target column
func _on_spawner_dropped(from_x: int, from_z: int, to_x: int, to_z: int) -> void:
	to_x = clampi(to_x, 0, _map_width - 1)
	to_z = clampi(to_z, 0, _map_depth - 1)

	_syncing = true

	var added = _structure_component.stack_add(to_x, to_z)
	if added:
		_layout_mirror[to_z][to_x] = _structure_component.get_height_at(to_x, to_z)
		_rebuild_column(to_x, to_z)

	# The spawner cube that was dropped is no longer a spawner — remove it
	# (it became a regular cube in _on_picked_up and we don't need the node anymore
	# since _rebuild_column creates proper cubes)
	# Find and free the dropped cube
	for cube in _spawner_cubes:
		if is_instance_valid(cube) and not cube.is_spawner and cube.is_picked_up() == false:
			# This is the cube that was just dropped — check if it's at the target position
			var gx = cube._local_to_grid_xz(cube.position)
			if gx.x == to_x and gx.y == to_z:
				cube.queue_free()
				_spawner_cubes.erase(cube)
				break

	if show_array_panel:
		_update_array_panel()

	_syncing = false


# ─── Grid Lines (Base Plate) ─────────────────────────────────

func _build_grid_lines() -> void:
	_grid_lines = MeshInstance3D.new()
	_grid_lines.name = "GridLines"

	var im = ImmediateMesh.new()
	_grid_lines.mesh = im

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.5, 0.5, 0.5, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_grid_lines.material_override = mat

	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var total_x = _map_width * _cell_size
	var total_z = _map_depth * _cell_size

	# Draw XZ grid lines on the floor (Y=0)
	for x in range(_map_width + 1):
		var px = x * _cell_size
		im.surface_add_vertex(Vector3(px, 0, 0))
		im.surface_add_vertex(Vector3(px, 0, total_z))

	for z in range(_map_depth + 1):
		var pz = z * _cell_size
		im.surface_add_vertex(Vector3(0, 0, pz))
		im.surface_add_vertex(Vector3(total_x, 0, pz))

	# Draw bounding box edges
	var max_h = _map_max_height * _cell_size
	var corners = [
		Vector3(0, 0, 0), Vector3(total_x, 0, 0),
		Vector3(total_x, 0, total_z), Vector3(0, 0, total_z),
		Vector3(0, max_h, 0), Vector3(total_x, max_h, 0),
		Vector3(total_x, max_h, total_z), Vector3(0, max_h, total_z),
	]
	# Vertical edges
	for i in range(4):
		im.surface_add_vertex(corners[i])
		im.surface_add_vertex(corners[i + 4])

	im.surface_end()

	_model_container.add_child(_grid_lines)


# ─── Index Labels ─────────────────────────────────────────────

func _build_index_labels() -> void:
	for z in range(_map_depth):
		for x in range(_map_width):
			var label = Label3D.new()
			label.text = "[%d,%d]" % [x, z]
			label.font_size = max(16, int(48 * _cell_size))
			label.pixel_size = 0.002
			label.outline_size = 4
			label.outline_modulate = Color(0, 0, 0, 1)
			label.modulate = Color(0.8, 0.8, 0.9, 0.8)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true

			# Position just above the base
			label.position = Vector3(
				(x + 0.5) * _cell_size,
				-0.01,  # Just below floor level
				(z + 0.5) * _cell_size
			)

			_model_container.add_child(label)


# ─── 2D Array Panel ──────────────────────────────────────────

func _build_array_panel() -> void:
	_panel_container = Node3D.new()
	_panel_container.name = "ArrayPanel"

	# Position panel to the right of the model
	var panel_x = (_map_width + 1.5) * _cell_size
	_panel_container.position = Vector3(panel_x, 0, 0)

	_model_container.add_child(_panel_container)

	# Title label
	var title = Label3D.new()
	title.text = "layout_data[z][x]"
	title.font_size = max(20, int(56 * _cell_size))
	title.pixel_size = 0.002
	title.outline_size = 4
	title.outline_modulate = Color(0, 0, 0, 1)
	title.modulate = Color(0.5, 1.0, 1.0, 1.0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.no_depth_test = true
	title.position = Vector3(0, (_map_depth + 1) * _cell_size * 0.4, 0)
	_panel_container.add_child(title)

	# Column headers (x indices)
	var header = Label3D.new()
	var header_text = "     "
	for x in range(_map_width):
		header_text += " x=%d" % x
	header.text = header_text
	header.font_size = max(16, int(40 * _cell_size))
	header.pixel_size = 0.002
	header.outline_size = 3
	header.outline_modulate = Color(0, 0, 0, 1)
	header.modulate = Color(0.7, 0.7, 0.8, 1.0)
	header.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	header.no_depth_test = true
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.position = Vector3(0, _map_depth * _cell_size * 0.35, 0)
	_panel_container.add_child(header)

	# Row labels
	_panel_labels = []
	for z in range(_map_depth):
		var row_label = Label3D.new()
		row_label.font_size = max(16, int(40 * _cell_size))
		row_label.pixel_size = 0.002
		row_label.outline_size = 3
		row_label.outline_modulate = Color(0, 0, 0, 1)
		row_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		row_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		row_label.no_depth_test = true
		row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

		row_label.position = Vector3(0, (_map_depth - 1 - z) * _cell_size * 0.35, 0)
		_panel_container.add_child(row_label)
		_panel_labels.append(row_label)

	_update_array_panel()


func _update_array_panel() -> void:
	if _panel_labels.is_empty():
		return

	for z in range(min(_map_depth, _panel_labels.size())):
		var row_text = "z=%d [ " % z
		for x in range(_map_width):
			var h = _layout_mirror[z][x] if (z < _layout_mirror.size() and x < _layout_mirror[z].size()) else 0
			row_text += "%d " % h
		row_text += "]"
		_panel_labels[z].text = row_text


# ─── Cleanup ─────────────────────────────────────────────────

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	if config.has("max_model_size"):
		max_model_size = float(config["max_model_size"])
	if config.has("model_elevation"):
		model_elevation = float(config["model_elevation"])
	if config.has("show_array_panel"):
		show_array_panel = config["show_array_panel"]
	if config.has("show_index_labels"):
		show_index_labels = config["show_index_labels"]
	if config.has("spawner_count"):
		spawner_count = int(config["spawner_count"])
