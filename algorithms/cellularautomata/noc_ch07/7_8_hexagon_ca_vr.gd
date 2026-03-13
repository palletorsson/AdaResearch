extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const TERRAIN_SHADER := preload("res://algorithms/cellularautomata/noc_ch07/hex_terrain.gdshader")

@export var radius: int = 20 # Much larger grid
@export var update_interval: float = 0.1 # Faster updates
@export var random_flip: float = 0.01
@export var hex_size: float = 1.0 # Walkable size
@export var max_generations: int = 40 # Stack height
@export var layer_height: float = 0.1 # Step up amount

const HEX_DIRECTIONS := [
	Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
	Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
]

var _sim_root: Node3D
var _cells := {} # Dictionary Vector2 -> bool
var _coords: Array[Vector2] = []
var _multi_mesh: MultiMeshInstance3D
var _timer: float = 0.0
var _generation: int = 0
var _status_label: Label3D
var _static_body: StaticBody3D

func _ready() -> void:
	_setup_environment()
	_initialize_grid()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

	_multi_mesh = MultiMeshInstance3D.new()
	_sim_root.add_child(_multi_mesh)
	
	_static_body = StaticBody3D.new()
	_sim_root.add_child(_static_body)

	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 32
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 5.0, 0) # Higher up
	_sim_root.add_child(_status_label)

	var controller_root := Node3D.new()
	controller_root.position = Vector3(0, 2.0, 0)
	add_child(controller_root)

	var flip_controller := CONTROLLER_SCENE.instantiate()
	flip_controller.parameter_name = "Random Flip"
	flip_controller.min_value = 0.0
	flip_controller.max_value = 0.1
	flip_controller.default_value = random_flip
	controller_root.add_child(flip_controller)
	flip_controller.value_changed.connect(func(v: float) -> void:
		random_flip = clamp(v, 0.0, 0.1)
	)
	flip_controller.set_value(random_flip)

	_update_status()

func _initialize_grid() -> void:
	_cells.clear()
	_coords.clear()

	for q in range(-radius, radius + 1):
		var r_min = max(-radius, -q - radius)
		var r_max = min(radius, -q + radius)
		for r in range(r_min, r_max + 1):
			var coord := Vector2(q, r)
			var alive := randf() < 0.85 # "Quite full seed map"
			_cells[coord] = alive
			_coords.append(coord)
	
	# Setup MultiMesh
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true 
	mm.use_custom_data = true 
	
	var hex_mesh := CylinderMesh.new()
	hex_mesh.radial_segments = 6
	hex_mesh.top_radius = hex_size
	hex_mesh.bottom_radius = hex_size
	hex_mesh.height = layer_height # Thin layers
	
	# Create Shader Material
	var mat = ShaderMaterial.new()
	mat.shader = TERRAIN_SHADER
	
	# Generate Noise Texture
	var noise = FastNoiseLite.new()
	noise.frequency = 0.1
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	mat.set_shader_parameter("noise_tex", noise_tex)
	mat.set_shader_parameter("perturb_strength", hex_size * 0.1) # Reduced perturb for stacking
	
	hex_mesh.material = mat
	mm.mesh = hex_mesh
	
	# Allocate enough instances for all generations
	mm.instance_count = _coords.size() * (max_generations + 1)
	# Initially hide all
	mm.visible_instance_count = 0
	
	_multi_mesh.multimesh = mm
	
	_generation = 0
	_update_visuals_layer(_generation)
	_add_colliders_for_current_layer()

func _hex_to_world(coord: Vector2) -> Vector3:
	# Pointy topped hexes
	var x := (sqrt(3.0) * coord.x + sqrt(3.0) / 2.0 * coord.y) * hex_size
	var z := (3.0 / 2.0 * coord.y) * hex_size
	return Vector3(x, 0, z)

func _process(delta: float) -> void:
	if _generation >= max_generations:
		return
		
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_step_generation()

func _step_generation() -> void:
	var next := {}
	for coord in _coords:
		var neighbors := _count_neighbors(coord)
		var alive = _cells[coord]
		var new_state = alive
		
		# Standard Life-like rules for Hex
		# B2/S34? Or something more terrain-like?
		# Let's stick to a cave-like generation rule: B5678/S345678 (smoothing)
		# Or the original logic:
		if alive and (neighbors == 2 or neighbors == 3):
			new_state = true
		elif not alive and neighbors == 2:
			new_state = true
		else:
			new_state = false
			
		if randf() < random_flip:
			new_state = !new_state
		next[coord] = new_state

	_cells = next
	_generation += 1
	_update_visuals_layer(_generation)
	_add_colliders_for_current_layer()
	_update_status()

func _count_neighbors(coord: Vector2) -> int:
	var total := 0
	for dir in HEX_DIRECTIONS:
		var neighbor = coord + dir
		if _cells.has(neighbor) and _cells[neighbor]:
			total += 1
	return total

func _update_visuals_layer(layer_index: int) -> void:
	var mm = _multi_mesh.multimesh
	var start_idx = layer_index * _coords.size()
	var y_pos = layer_index * layer_height
	
	var active_in_layer = 0
	
	for i in range(_coords.size()):
		var coord = _coords[i]
		var alive = _cells[coord]
		var idx = start_idx + i
		
		if alive:
			var pos = _hex_to_world(coord)
			pos.y = y_pos
			
			var t = Transform3D(Basis(), pos)
			mm.set_instance_transform(idx, t)
			
			# Color gradient based on height/generation
			var hue = float(layer_index) / float(max_generations)
			var color = Color.from_hsv(hue, 0.8, 0.8)
			mm.set_instance_color(idx, color)
			mm.set_instance_custom_data(idx, Color(1.0, 0, 0, 0))
		else:
			# Hide dead cells by scaling to 0
			mm.set_instance_transform(idx, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
	
	# Update visible count to include this new layer
	mm.visible_instance_count = (layer_index + 1) * _coords.size()

func _add_colliders_for_current_layer() -> void:
	# Add colliders for the current layer incrementally
	var shape = CylinderShape3D.new()
	shape.height = layer_height
	shape.radius = hex_size
	
	var y_pos = _generation * layer_height
	
	for coord in _coords:
		if _cells[coord]:
			var pos = _hex_to_world(coord)
			pos.y = y_pos
			
			var col = CollisionShape3D.new()
			col.shape = shape
			col.position = pos
			_static_body.add_child(col)

func _update_status() -> void:
	_status_label.text = "Hex Stack | Layer %d/%d" % [_generation, max_generations]

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

