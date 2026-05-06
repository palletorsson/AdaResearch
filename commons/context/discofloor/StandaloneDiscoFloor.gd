# StandaloneDiscoFloor.gd
# Self-contained disco floor with its own tile grid
# Does NOT modify the main GridSystem cubes

# @identity
# essence: MultiMesh of (width × depth) flat tile instances, each independently colored per-step by pattern functions (checkerboard, wave, spiral, snake, rainbow) driven by animation_step advancing every pattern_speed seconds
# desire: to stand on a floor that is computing — to feel the checkerboard pattern as an array of booleans where (x+z)%2 determines your tile's color, or to watch a snake pattern trace a Hamiltonian path through the grid beneath your feet
# critical_parameter: pattern_speed — at 0.08s the animation is continuous and hypnotic; at 0.5s individual tiles visibly switch state one by one; this controls whether the floor reads as a pattern or as a computation
# triggers: start_disco() begins animation; pattern_duration seconds elapse → next Pattern enum value; 10 patterns cycle automatically; walkable=true adds collision geometry so players can actually walk on the tiles
# emerges: when 12×12 tiles animate together at disco speed, individual pattern logic (i.e., a simple modulo or sin function) becomes a physically immersive audiovisual experience — the mathematics disappears into sensation
# needs: MultiMeshInstance3D [has]; collision for walking [has when walkable=true]; auto-cycling patterns [has]; DiscoSequencerBridge [has as sibling for audio sync]; no VR slider to control pattern or speed [missing]
# relationships: paired with StepSequencer in Tutorial_Disco for the "arrays as music" synthesis; uses DiscoSequencerBridge for audio coupling; standalone variant of DiscoFloorController which requires GridSystem
# truth: a disco floor is a 2D array of light values updated over time — every club floor is a physical proof that arrays can be felt, not just computed

extends Node3D
class_name StandaloneDiscoFloor

## Grid Configuration
@export var grid_width: int = 8
@export var grid_depth: int = 8
@export var tile_size: float = 0.5
@export var tile_gap: float = 0.02
@export var base_color: Color = Color.WHITE
@export var floor_height: float = 0.02  # Thin tiles
@export var floor_y_offset: float = 0.5  # Y position of floor surface
@export var walkable: bool = true  # Add collision for walking

## Animation
@export var auto_start: bool = true
@export var pattern_speed: float = 0.08
@export var pattern_duration: float = 8.0  # Seconds per pattern

## Internal
var multimesh_instance: MultiMeshInstance3D
var multimesh: MultiMesh
var tile_colors: Array[Color] = []
var current_pattern: int = 0
var pattern_timer: float = 0.0
var step_timer: float = 0.0
var animation_step: int = 0
var is_running: bool = false

## Pattern definitions
enum Pattern {
	SOLID,
	CHECKERBOARD,
	WAVE_HORIZONTAL,
	WAVE_VERTICAL,
	WAVE_DIAGONAL,
	PULSE_CENTER,
	SPIRAL,
	SNAKE,
	RANDOM_SPARKLE,
	RAINBOW_SWEEP
}

var pattern_names: Array[String] = [
	"Solid", "Checkerboard", "Wave H", "Wave V", 
	"Wave Diag", "Pulse", "Spiral", "Snake", 
	"Sparkle", "Rainbow"
]

signal pattern_changed(pattern_name: String)
signal disco_toggled(is_on: bool)

func _ready() -> void:
	_create_floor_grid()
	if auto_start:
		start_disco()

func _create_floor_grid() -> void:
	"""Create the tile grid using MultiMesh for performance"""
	print("StandaloneDiscoFloor: Creating %dx%d tile grid at Y=%.2f" % [grid_width, grid_depth, floor_y_offset])
	
	# Create MultiMesh
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = grid_width * grid_depth
	
	# Create tile mesh (flat box)
	var tile_mesh = BoxMesh.new()
	tile_mesh.size = Vector3(tile_size - tile_gap, floor_height, tile_size - tile_gap)
	multimesh.mesh = tile_mesh
	
	# Create MultiMeshInstance
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.name = "DiscoTiles"
	multimesh_instance.multimesh = multimesh
	
	# Create emissive material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.3
	mat.vertex_color_use_as_albedo = true
	multimesh_instance.material_override = mat
	
	add_child(multimesh_instance)
	
	# Position tiles
	var offset_x = (grid_width * tile_size) / 2.0 - tile_size / 2.0
	var offset_z = (grid_depth * tile_size) / 2.0 - tile_size / 2.0
	
	tile_colors.resize(grid_width * grid_depth)
	
	for z in range(grid_depth):
		for x in range(grid_width):
			var idx = z * grid_width + x
			var pos = Vector3(
				x * tile_size - offset_x,
				floor_y_offset + floor_height / 2.0,  # Position at floor_y_offset
				z * tile_size - offset_z
			)
			var xform = Transform3D(Basis(), pos)
			multimesh.set_instance_transform(idx, xform)
			multimesh.set_instance_color(idx, base_color)
			tile_colors[idx] = base_color
	
	# Add collision for walking if enabled
	if walkable:
		_create_floor_collision(offset_x, offset_z)
	
	print("StandaloneDiscoFloor: Created %d tiles" % multimesh.instance_count)

func _create_floor_collision(offset_x: float, offset_z: float) -> void:
	"""Create a single collision shape for the entire floor for walking"""
	var floor_body = StaticBody3D.new()
	floor_body.name = "FloorCollision"
	
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	# Create a box that covers the entire floor area
	box_shape.size = Vector3(
		grid_width * tile_size,
		floor_height,
		grid_depth * tile_size
	)
	collision_shape.shape = box_shape
	
	# Position at center of floor
	floor_body.position = Vector3(0, floor_y_offset, 0)
	
	floor_body.add_child(collision_shape)
	add_child(floor_body)
	
	print("StandaloneDiscoFloor: Added walkable floor collision")

func _process(delta: float) -> void:
	if not is_running:
		return
	
	step_timer += delta
	pattern_timer += delta
	
	# Change pattern after duration
	if pattern_timer >= pattern_duration:
		pattern_timer = 0.0
		next_pattern()
	
	# Update current pattern
	if step_timer >= pattern_speed:
		step_timer = 0.0
		_update_pattern()
		animation_step += 1

func _update_pattern() -> void:
	match current_pattern:
		Pattern.SOLID:
			_pattern_solid()
		Pattern.CHECKERBOARD:
			_pattern_checkerboard()
		Pattern.WAVE_HORIZONTAL:
			_pattern_wave_horizontal()
		Pattern.WAVE_VERTICAL:
			_pattern_wave_vertical()
		Pattern.WAVE_DIAGONAL:
			_pattern_wave_diagonal()
		Pattern.PULSE_CENTER:
			_pattern_pulse_center()
		Pattern.SPIRAL:
			_pattern_spiral()
		Pattern.SNAKE:
			_pattern_snake()
		Pattern.RANDOM_SPARKLE:
			_pattern_random_sparkle()
		Pattern.RAINBOW_SWEEP:
			_pattern_rainbow_sweep()

# === PATTERNS ===

func _pattern_solid() -> void:
	var hue = fmod(animation_step * 0.02, 1.0)
	var color = Color.from_hsv(hue, 0.7, 1.0)
	_fill_all(color)

func _pattern_checkerboard() -> void:
	var phase = animation_step % 2
	for z in range(grid_depth):
		for x in range(grid_width):
			var is_light = ((x + z + phase) % 2) == 0
			var color = Color.WHITE if is_light else Color(0.1, 0.1, 0.2)
			_set_tile(x, z, color)

func _pattern_wave_horizontal() -> void:
	for z in range(grid_depth):
		for x in range(grid_width):
			var wave = sin((x + animation_step) * 0.5)
			var brightness = (wave + 1.0) / 2.0
			var color = Color.from_hsv(0.6, 0.3, brightness)
			_set_tile(x, z, color)

func _pattern_wave_vertical() -> void:
	for z in range(grid_depth):
		for x in range(grid_width):
			var wave = sin((z + animation_step) * 0.5)
			var brightness = (wave + 1.0) / 2.0
			var color = Color.from_hsv(0.8, 0.3, brightness)
			_set_tile(x, z, color)

func _pattern_wave_diagonal() -> void:
	for z in range(grid_depth):
		for x in range(grid_width):
			var wave = sin((x + z + animation_step) * 0.4)
			var hue = fmod((x + z) * 0.05 + animation_step * 0.01, 1.0)
			var brightness = (wave + 1.0) / 2.0
			_set_tile(x, z, Color.from_hsv(hue, 0.6, brightness))

func _pattern_pulse_center() -> void:
	var cx = grid_width / 2.0
	var cz = grid_depth / 2.0
	var max_dist = sqrt(cx * cx + cz * cz)
	var pulse_radius = fmod(animation_step * 0.3, max_dist * 2.0)
	
	for z in range(grid_depth):
		for x in range(grid_width):
			var dist = sqrt(pow(x - cx, 2) + pow(z - cz, 2))
			var diff = abs(dist - pulse_radius)
			var brightness = max(0.0, 1.0 - diff * 0.5)
			var hue = fmod(dist * 0.1, 1.0)
			_set_tile(x, z, Color.from_hsv(hue, 0.7, brightness))

func _pattern_spiral() -> void:
	var cx = grid_width / 2.0
	var cz = grid_depth / 2.0
	
	for z in range(grid_depth):
		for x in range(grid_width):
			var angle = atan2(z - cz, x - cx)
			var dist = sqrt(pow(x - cx, 2) + pow(z - cz, 2))
			var spiral = fmod(angle + dist * 0.5 - animation_step * 0.1, TAU)
			var brightness = (sin(spiral * 2) + 1.0) / 2.0
			var hue = fmod(spiral / TAU, 1.0)
			_set_tile(x, z, Color.from_hsv(hue, 0.6, brightness))

func _pattern_snake() -> void:
	_fill_all(Color(0.05, 0.05, 0.1))
	var total = grid_width * grid_depth
	var pos = animation_step % total
	var row = pos / grid_width
	var col = pos % grid_width
	if row % 2 == 1:
		col = grid_width - 1 - col
	if row < grid_depth:
		_set_tile(col, row, Color.LIME)
		# Trail
		for i in range(1, 5):
			var trail_pos = (pos - i + total) % total
			var tr = trail_pos / grid_width
			var tc = trail_pos % grid_width
			if tr % 2 == 1:
				tc = grid_width - 1 - tc
			if tr < grid_depth:
				var fade = 1.0 - (i / 5.0)
				_set_tile(tc, tr, Color(0, fade, 0))

func _pattern_random_sparkle() -> void:
	# Fade existing
	for z in range(grid_depth):
		for x in range(grid_width):
			var idx = z * grid_width + x
			var c = tile_colors[idx]
			c = c.lerp(Color(0.1, 0.1, 0.15), 0.1)
			_set_tile(x, z, c)
	
	# Add random sparkles
	for i in range(3):
		var x = randi() % grid_width
		var z = randi() % grid_depth
		_set_tile(x, z, Color.from_hsv(randf(), 0.8, 1.0))

func _pattern_rainbow_sweep() -> void:
	for z in range(grid_depth):
		for x in range(grid_width):
			var hue = fmod((x + animation_step) * 0.08, 1.0)
			_set_tile(x, z, Color.from_hsv(hue, 0.8, 1.0))

# === HELPERS ===

func _set_tile(x: int, z: int, color: Color) -> void:
	if x < 0 or x >= grid_width or z < 0 or z >= grid_depth:
		return
	var idx = z * grid_width + x
	multimesh.set_instance_color(idx, color)
	tile_colors[idx] = color

func _fill_all(color: Color) -> void:
	for i in range(multimesh.instance_count):
		multimesh.set_instance_color(i, color)
		tile_colors[i] = color

# === PUBLIC API ===

func start_disco() -> void:
	is_running = true
	animation_step = 0
	step_timer = 0.0
	disco_toggled.emit(true)
	print("StandaloneDiscoFloor: Started")

func stop_disco() -> void:
	is_running = false
	_fill_all(base_color)
	disco_toggled.emit(false)
	print("StandaloneDiscoFloor: Stopped")

func toggle_disco() -> void:
	if is_running:
		stop_disco()
	else:
		start_disco()

func next_pattern() -> void:
	current_pattern = (current_pattern + 1) % Pattern.size()
	animation_step = 0
	pattern_changed.emit(pattern_names[current_pattern])
	print("StandaloneDiscoFloor: Pattern -> %s" % pattern_names[current_pattern])

func previous_pattern() -> void:
	current_pattern = (current_pattern - 1 + Pattern.size()) % Pattern.size()
	animation_step = 0
	pattern_changed.emit(pattern_names[current_pattern])

func set_pattern(pattern_index: int) -> void:
	if pattern_index >= 0 and pattern_index < Pattern.size():
		current_pattern = pattern_index
		animation_step = 0
		pattern_changed.emit(pattern_names[current_pattern])

func set_pattern_by_name(name: String) -> void:
	var idx = pattern_names.find(name)
	if idx >= 0:
		set_pattern(idx)

func get_current_pattern_name() -> String:
	return pattern_names[current_pattern]

func get_pattern_count() -> int:
	return Pattern.size()

func get_all_pattern_names() -> Array[String]:
	return pattern_names

func set_speed(speed: float) -> void:
	pattern_speed = clamp(speed, 0.01, 1.0)

func set_grid_size(width: int, depth: int) -> void:
	grid_width = width
	grid_depth = depth
	# Recreate grid
	if multimesh_instance:
		multimesh_instance.queue_free()
	# Remove old collision
	var old_collision = get_node_or_null("FloorCollision")
	if old_collision:
		old_collision.queue_free()
	_create_floor_grid()

func set_floor_height(y_offset: float) -> void:
	floor_y_offset = y_offset
	# Recreate to update positions
	if multimesh_instance:
		multimesh_instance.queue_free()
	var old_collision = get_node_or_null("FloorCollision")
	if old_collision:
		old_collision.queue_free()
	_create_floor_grid()

# === GRID CONFIG API (for GridInteractablesComponent) ===

func apply_grid_config(config: Dictionary) -> void:
	"""Apply configuration from map_data.json # syntax"""
	print("StandaloneDiscoFloor: Applying config: %s" % str(config))
	
	var needs_rebuild := false
	
	# Grid dimensions
	if config.has("width"):
		grid_width = int(config["width"])
		needs_rebuild = true
	if config.has("depth"):
		grid_depth = int(config["depth"])
		needs_rebuild = true
	
	# Tile appearance
	if config.has("tile_size"):
		tile_size = float(config["tile_size"])
		needs_rebuild = true
	if config.has("tile_gap"):
		tile_gap = float(config["tile_gap"])
		needs_rebuild = true
	
	# Floor position and collision
	if config.has("floor_y_offset"):
		floor_y_offset = float(config["floor_y_offset"])
		needs_rebuild = true
	if config.has("walkable"):
		var val = config["walkable"]
		walkable = (str(val).to_lower() == "true" or val == true or val == 1)
		needs_rebuild = true
	
	# Animation settings
	if config.has("pattern_speed"):
		pattern_speed = float(config["pattern_speed"])
	if config.has("pattern_duration"):
		pattern_duration = float(config["pattern_duration"])
	if config.has("auto_start"):
		var val = config["auto_start"]
		auto_start = (str(val).to_lower() == "true" or val == true or val == 1)
	
	# Rebuild if needed
	if needs_rebuild and multimesh_instance:
		multimesh_instance.queue_free()
		var old_collision = get_node_or_null("FloorCollision")
		if old_collision:
			old_collision.queue_free()
		call_deferred("_create_floor_grid")
		if auto_start:
			call_deferred("start_disco")
