@tool
extends Node3D

# @identity
# essence: B5+/S4+ on a 3D grid → density texture → FogVolume — CA rules become visible atmosphere
# desire: To be walked through — fog that has opinions about where it clumps, thinning and thickening by local rules
# critical_parameter: smooth_factor and birth/survival thresholds (B5/S4) — control whether fog dissipates or aggregates
# triggers: High survival threshold → fog evaporates; low → dense permanent clouds; grid resolution → fine mist vs chunky blocks
# emerges: Cloud-like formations from binary CA rules — no fluid dynamics, yet the fog moves like weather
# needs: VR density controls [missing], rule parameter sliders [missing]
# relationships: Feeds into CA_EdgeOfChaos. Unique in using CA to drive Godot's FogVolume system directly.
# truth: Fog is a cellular automaton — local density rules produce clouds no one shaped.

# Volumetric Fog CA
# Uses a 3D CA to drive a FogVolume's density texture.

@export var grid_size: Vector3i = Vector3i(32, 32, 32)
@export var update_interval: float = 0.1
@export var smooth_factor: float = 0.5

var fog_volume: FogVolume

var current_state: Array = []
var next_state: Array = []
var texture: Texture3D
var image_data: Array[Image] = []
var timer: float = 0.0

func _ready() -> void:
	_initialize_grid()
	_setup_fog()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	timer += delta
	if timer >= update_interval:
		timer = 0.0
		_step()
		_update_texture()

func _initialize_grid() -> void:
	current_state.resize(grid_size.x * grid_size.y * grid_size.z)
	next_state.resize(grid_size.x * grid_size.y * grid_size.z)
	
	for i in range(current_state.size()):
		current_state[i] = 1 if randf() < 0.4 else 0

func _setup_fog() -> void:
	if not fog_volume:
		fog_volume = FogVolume.new()
		fog_volume.size = Vector3(10, 10, 10)
		add_child(fog_volume)
		
	var mat = FogMaterial.new()
	mat.density = 2.0
	mat.albedo = Color(0.8, 0.9, 1.0)
	mat.emission = Color(0.1, 0.2, 0.3)
	fog_volume.material = mat
	
	# Create initial texture
	var img = Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_R8)
	for z in range(grid_size.z):
		image_data.append(img.duplicate())
		
	texture = ImageTexture3D.new()
	texture.create(Image.FORMAT_R8, grid_size.x, grid_size.y, grid_size.z, false, image_data)
	mat.density_texture = texture

func _step() -> void:
	# Simple smoothing / cloud rule
	# B45678/S45678 (High survival/birth = clumping)
	var sx = grid_size.x
	var sy = grid_size.y
	var sz = grid_size.z
	
	for z in range(sz):
		for y in range(sy):
			for x in range(sx):
				var idx = x + y * sx + z * sx * sy
				var neighbors = _count_neighbors(x, y, z)
				var state = current_state[idx]
				
				if state == 1:
					if neighbors >= 4:
						next_state[idx] = 1
					else:
						next_state[idx] = 0
				else:
					if neighbors >= 5: # Harder to be born
						next_state[idx] = 1
					else:
						next_state[idx] = 0
	
	var temp = current_state
	current_state = next_state
	next_state = temp

func _count_neighbors(x, y, z) -> int:
	var count = 0
	var sx = grid_size.x
	var sy = grid_size.y
	var sz = grid_size.z
	
	for dz in range(-1, 2):
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0 and dz == 0: continue
				
				var nx = (x + dx + sx) % sx
				var ny = (y + dy + sy) % sy
				var nz = (z + dz + sz) % sz
				
				if current_state[nx + ny * sx + nz * sx * sy] == 1:
					count += 1
	return count

func _update_texture() -> void:
	# Update images
	var sx = grid_size.x
	var sy = grid_size.y
	var sz = grid_size.z
	
	for z in range(sz):
		var img = image_data[z]
		for y in range(sy):
			for x in range(sx):
				var idx = x + y * sx + z * sx * sy
				var val = 255 if current_state[idx] == 1 else 0
				img.set_pixel(x, y, Color(val/255.0, 0, 0))
	
	# Update Texture3D
	texture.update(image_data)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
