extends Node3D

# @identity
# essence: pheromone[x,y] = clamp(pheromone[x,y] + deposit, 0, 5) * evaporation_rate + diffuse(neighbors) — communication through substrate, not signal
# desire: to watch invisible ant highways materialize as green-white trails on a tiny floor tile — to see communication happen without any message being sent
# critical_parameter: evaporation_rate (0.99 default, meaning 1% decay per step) — faster decay forces ants to constantly reinforce trails or lose them; slower decay produces permanent glowing scars
# triggers: with sensor_distance=0 ants move randomly and trails are uniform noise; as sensor_distance grows, trails snap into focused bright corridors — the phase transition of stigmergy
# emerges: circular drift loops where ants follow their own old trail around a closed ring, reinforcing it until it dominates the entire grid — a positive feedback trap
# needs: [missing] no VR controls; evaporation_rate, deposit_amount, and num_ants are exported but not wired to any VR sliders; learner can only observe, not experiment
# relationships: demonstrates the environmental memory mechanism that AntColonyOptimization uses for pathfinding; contrasts with boid_flocking (medium-based vs. agent-based communication)
# truth: stigmergy proves that coordination does not require awareness — the environment itself is the shared mind

class_name StigmergyGrid

## Ant pheromone grid with real-time evaporation — ants deposit trails,
## pheromones fade over time, demonstrating indirect communication (stigmergy).

# --- Configuration ---

@export var grid_size: int = 64
@export var world_size: float = 0.8
@export var num_ants: int = 15
@export var evaporation_rate: float = 0.99
@export var diffusion_rate: float = 0.05
@export var deposit_amount: float = 1.0
@export var sensor_distance: float = 3.0
@export var sensor_angle: float = PI / 6.0  ## 30 degrees
@export var ant_speed: float = 1.0
@export var turn_speed: float = 0.5

# --- Internal ---

var _pheromone: Array[float] = []
var _pheromone_back: Array[float] = []
var _ant_x: Array[float] = []
var _ant_y: Array[float] = []
var _ant_angle: Array[float] = []

var _floor_mesh: MeshInstance3D
var _floor_material: StandardMaterial3D
var _info_label: Label3D
var _rng: RandomNumberGenerator

var _update_timer: float = 0.0
const UPDATE_INTERVAL: float = 1.0 / 30.0  ## 30 fps simulation


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = hash("stigmergy")

	_init_grid()
	_init_ants()
	_create_floor_mesh()
	_create_info_label()
	_update_texture()


func _init_grid() -> void:
	var total = grid_size * grid_size
	_pheromone.resize(total)
	_pheromone_back.resize(total)
	for i in range(total):
		_pheromone[i] = 0.0
		_pheromone_back[i] = 0.0


func _init_ants() -> void:
	_ant_x.resize(num_ants)
	_ant_y.resize(num_ants)
	_ant_angle.resize(num_ants)

	var center := grid_size / 2.0
	for i in range(num_ants):
		_ant_x[i] = center + _rng.randf_range(-grid_size * 0.3, grid_size * 0.3)
		_ant_y[i] = center + _rng.randf_range(-grid_size * 0.3, grid_size * 0.3)
		_ant_angle[i] = _rng.randf() * TAU


func _create_floor_mesh() -> void:
	_floor_mesh = MeshInstance3D.new()
	_floor_mesh.name = "PheromoneFloor"

	var quad = QuadMesh.new()
	quad.size = Vector2(world_size, world_size)
	_floor_mesh.mesh = quad

	_floor_mesh.rotation_degrees.x = -90
	_floor_mesh.position.y = 0.005

	_floor_material = StandardMaterial3D.new()
	_floor_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_floor_material.roughness = 0.9
	_floor_material.metallic = 0.0
	_floor_material.emission_enabled = true
	_floor_material.emission_energy_multiplier = 0.3
	_floor_mesh.material_override = _floor_material

	add_child(_floor_mesh)


func _create_info_label() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 20
	_info_label.position = Vector3(0, 0.01, -world_size / 2.0 - 0.06)
	_info_label.text = "STIGMERGY\nAnts: %d" % num_ants
	add_child(_info_label)


func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer < UPDATE_INTERVAL:
		return
	_update_timer = 0.0

	_step_ants()
	_evaporate_and_diffuse()
	_update_texture()


func _step_ants() -> void:
	var gs := grid_size
	for i in range(num_ants):
		var ax := _ant_x[i]
		var ay := _ant_y[i]
		var angle := _ant_angle[i]

		# Sense pheromone at three positions: left, ahead, right
		var sense_left := _sense(ax, ay, angle + sensor_angle)
		var sense_ahead := _sense(ax, ay, angle)
		var sense_right := _sense(ax, ay, angle - sensor_angle)

		# Turn toward strongest signal
		if sense_ahead >= sense_left and sense_ahead >= sense_right:
			pass  # keep going straight
		elif sense_left > sense_right:
			angle += turn_speed
		elif sense_right > sense_left:
			angle -= turn_speed
		else:
			# Equal left and right — random jitter
			angle += _rng.randf_range(-turn_speed, turn_speed)

		# Add small random wandering
		angle += _rng.randf_range(-0.1, 0.1)

		# Move forward
		ax += cos(angle) * ant_speed
		ay += sin(angle) * ant_speed

		# Wrap around
		ax = fmod(ax + gs, gs)
		ay = fmod(ay + gs, gs)

		# Deposit pheromone
		var gx := int(ax) % gs
		var gy := int(ay) % gs
		var idx := gy * gs + gx
		_pheromone[idx] = minf(_pheromone[idx] + deposit_amount, 5.0)

		# Store updated ant state
		_ant_x[i] = ax
		_ant_y[i] = ay
		_ant_angle[i] = angle


func _sense(ax: float, ay: float, angle: float) -> float:
	var sx := ax + cos(angle) * sensor_distance
	var sy := ay + sin(angle) * sensor_distance
	var gs := grid_size

	var gx := int(fmod(sx + gs, gs)) % gs
	var gy := int(fmod(sy + gs, gs)) % gs
	return _pheromone[gy * gs + gx]


func _evaporate_and_diffuse() -> void:
	var gs := grid_size
	var diff := diffusion_rate
	var evap := evaporation_rate
	var center_weight := 1.0 - diff

	# Diffuse into back buffer, then swap
	for y in range(gs):
		for x in range(gs):
			var idx := y * gs + x

			# 3x3 blur kernel (von Neumann + corners)
			var sum := _pheromone[idx] * center_weight
			var neighbor_weight := diff / 8.0

			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx := (x + dx + gs) % gs
					var ny := (y + dy + gs) % gs
					sum += _pheromone[ny * gs + nx] * neighbor_weight

			# Evaporate
			_pheromone_back[idx] = sum * evap

	# Swap buffers
	var temp := _pheromone
	_pheromone = _pheromone_back
	_pheromone_back = temp


func _update_texture() -> void:
	var gs := grid_size
	var image := Image.create(gs, gs, false, Image.FORMAT_RGBA8)

	for y in range(gs):
		for x in range(gs):
			var val := _pheromone[y * gs + x]
			var color := _pheromone_to_color(val)
			image.set_pixel(x, y, color)

	var texture := ImageTexture.create_from_image(image)
	_floor_material.albedo_texture = texture
	_floor_material.emission_texture = texture


func _pheromone_to_color(val: float) -> Color:
	# Map pheromone concentration to color:
	# 0 = black, low = dark green, mid = bright green,
	# high = yellow, very high = white
	var t := clampf(val / 3.0, 0.0, 1.0)

	if t < 0.33:
		# Black → dark green
		var s := t / 0.33
		return Color(0.0, s * 0.4, 0.0)
	elif t < 0.66:
		# Dark green → bright green/yellow
		var s := (t - 0.33) / 0.33
		return Color(s * 0.8, 0.4 + s * 0.6, 0.0)
	else:
		# Yellow → white
		var s := (t - 0.66) / 0.34
		return Color(0.8 + s * 0.2, 1.0, s * 1.0)


## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("num_ants"):
		num_ants = int(config_data["num_ants"])
	if config_data.has("evaporation_rate"):
		evaporation_rate = float(config_data["evaporation_rate"])
	if config_data.has("deposit_amount"):
		deposit_amount = float(config_data["deposit_amount"])
	if config_data.has("sensor_distance"):
		sensor_distance = float(config_data["sensor_distance"])
