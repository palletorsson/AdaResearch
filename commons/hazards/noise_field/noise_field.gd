extends Area3D
class_name NoiseField
## Noise sequence hazard — a 10x10 grid of tiles driven by FastNoiseLite.
## Tile height and color shift from green (safe) to red (danger) based on noise value.
## Noise scrolls over time creating a structured, shifting danger zone.
## Tiles above a threshold deal damage to the player standing on them.

signal enemy_destroyed(enemy: Node3D)

@export_group("Grid")
@export var grid_size: int = 10
@export var tile_size: float = 0.3
@export var tile_gap: float = 0.02
@export var height_scale: float = 0.5

@export_group("Noise")
@export var scroll_speed: float = 0.4
@export var noise_frequency: float = 0.8
@export var damage_threshold: float = 0.3

@export_group("Combat")
@export var damage_per_second: float = 10.0

@export_group("Appearance")
@export var safe_color: Color = Color(0.1, 0.8, 0.2)
@export var danger_color: Color = Color(1.0, 0.15, 0.05)

# State
var _noise: FastNoiseLite = null
var _player_node: Node3D = null
var _player_inside: bool = false
var _damage_accumulator: float = 0.0
var _time: float = 0.0

# Visual
var _tiles: Array[MeshInstance3D] = []
var _tile_mats: Array[StandardMaterial3D] = []
var _label: Label3D = null


func _ready() -> void:
	# Collision setup — covers the entire grid
	var total_span: float = grid_size * (tile_size + tile_gap)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(total_span, 1.5, total_span)
	col.shape = shape
	col.position = Vector3(total_span * 0.5 - (tile_size + tile_gap) * 0.5, 0.75, total_span * 0.5 - (tile_size + tile_gap) * 0.5)
	add_child(col)

	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2  # Player layer

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Setup noise
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = noise_frequency
	_noise.seed = randi()

	_build_grid()
	_build_label()
	_find_player()
	add_to_group("enemy")


func _process(delta: float) -> void:
	_time += delta

	# Scroll the noise offset
	_noise.offset.x = _time * scroll_speed

	# Update each tile
	var step: float = tile_size + tile_gap
	for row in range(grid_size):
		for col_idx in range(grid_size):
			var idx: int = row * grid_size + col_idx
			var noise_val: float = (_noise.get_noise_2d(float(col_idx), float(row)) + 1.0) * 0.5  # Normalize 0..1

			# Height
			var h: float = noise_val * height_scale
			_tiles[idx].position.y = h * 0.5
			_tiles[idx].scale.y = max(0.05, h / tile_size)

			# Color interpolation: green (safe) -> red (danger)
			var t: float = clampf(noise_val, 0.0, 1.0)
			var c: Color = safe_color.lerp(danger_color, t)
			_tile_mats[idx].albedo_color = c
			if noise_val > damage_threshold:
				_tile_mats[idx].emission = danger_color
				_tile_mats[idx].emission_energy_multiplier = 1.0 + (noise_val - damage_threshold) * 3.0
			else:
				_tile_mats[idx].emission = safe_color * 0.3
				_tile_mats[idx].emission_energy_multiplier = 0.5

	# Update label
	if _label:
		_label.text = "NOISE  freq=%.2f  scroll=%.1f  thresh=%.1f" % [noise_frequency, scroll_speed, damage_threshold]

	# Damage player if standing on a hot tile
	if _player_inside and is_instance_valid(_player_node):
		var player_pos: Vector3 = _player_node.global_position
		var local_pos: Vector3 = player_pos - global_position
		var step_val: float = tile_size + tile_gap
		var col_f: int = int(clampf(local_pos.x / step_val + 0.5, 0, grid_size - 1))
		var row_f: int = int(clampf(local_pos.z / step_val + 0.5, 0, grid_size - 1))
		var noise_at_player: float = (_noise.get_noise_2d(float(col_f), float(row_f)) + 1.0) * 0.5

		if noise_at_player > damage_threshold:
			_damage_accumulator += delta * damage_per_second * (noise_at_player - damage_threshold) * 3.0
			if _damage_accumulator >= 1.0:
				var dmg: float = floor(_damage_accumulator)
				_damage_accumulator -= dmg
				var gm = get_node_or_null("/root/GameManager")
				if gm and gm.has_method("apply_health_damage"):
					gm.apply_health_damage(dmg)


func _build_grid() -> void:
	var step: float = tile_size + tile_gap
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(tile_size, tile_size, tile_size)

	for row in range(grid_size):
		for col_idx in range(grid_size):
			var mat := StandardMaterial3D.new()
			mat.albedo_color = safe_color
			mat.emission_enabled = true
			mat.emission = safe_color * 0.3
			mat.emission_energy_multiplier = 0.5

			var mi := MeshInstance3D.new()
			mi.mesh = tile_mesh
			mi.set_surface_override_material(0, mat)
			mi.position = Vector3(col_idx * step, 0.0, row * step)
			add_child(mi)

			_tiles.append(mi)
			_tile_mats.append(mat)


func _build_label() -> void:
	_label = Label3D.new()
	_label.text = "NOISE"
	_label.font_size = 24
	_label.pixel_size = 0.003
	_label.modulate = Color(0.9, 0.9, 0.2)
	var total_span: float = grid_size * (tile_size + tile_gap)
	_label.position = Vector3(total_span * 0.5, 1.2, -0.3)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_player_node = body
		_damage_accumulator = 0.0

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false


func _find_player() -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	for candidate in [
		get_tree().get_first_node_in_group("player"),
		scene.find_child("XROrigin3D", true, false),
		scene.find_child("Player", true, false),
	]:
		if candidate is Node3D:
			_player_node = candidate
			return


# ── Damage Interface ────────────────────────────────────────────────────
func take_damage(amount: float) -> void:
	pass  # Zone hazard — indestructible

func apply_damage(amount: float) -> void:
	pass

func damage(amount: float) -> void:
	pass

func configure(config: Dictionary) -> void:
	if config.has("damage"):
		damage_per_second = float(config["damage"])
	if config.has("threshold"):
		damage_threshold = float(config["threshold"])
	if config.has("scroll_speed"):
		scroll_speed = float(config["scroll_speed"])

func apply_grid_config(config: Dictionary) -> void:
	configure(config)
