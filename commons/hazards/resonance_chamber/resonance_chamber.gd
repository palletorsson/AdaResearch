extends Area3D
class_name ResonanceChamber
## Procedural audio sequence hazard — a transparent chamber with standing wave bars.
## Horizontal bars sit at standing-wave node positions inside a rectangular frame.
## Damage occurs when the player overlaps with a node bar.
## Frequency changes periodically, shifting all node positions.

signal enemy_destroyed(enemy: Node3D)

@export_group("Chamber")
@export var chamber_width: float = 3.0
@export var chamber_height: float = 2.0
@export var chamber_depth: float = 3.0

@export_group("Wave")
@export var bar_count: int = 8
@export var frequency_change_interval: float = 8.0
@export var min_harmonic: int = 1
@export var max_harmonic: int = 5

@export_group("Combat")
@export var damage_per_second: float = 12.0
@export var bar_thickness: float = 0.1

@export_group("Appearance")
@export var frame_color: Color = Color(0.4, 0.6, 0.9, 0.15)
@export var bar_color: Color = Color(0.2, 0.5, 1.0)
@export var bar_emission: Color = Color(0.3, 0.6, 1.0)

# State
var _player_node: Node3D = null
var _player_inside: bool = false
var _damage_accumulator: float = 0.0
var _time: float = 0.0
var _freq_timer: float = 0.0
var _current_harmonic: int = 2
var _target_harmonic: int = 2

# Visual
var _frame_mesh: MeshInstance3D = null
var _bars: Array[MeshInstance3D] = []
var _bar_mats: Array[StandardMaterial3D] = []
var _bar_positions: Array[float] = []  # Target X positions (local)
var _label: Label3D = null


func _ready() -> void:
	# Collision for the whole chamber
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(chamber_width, chamber_height, chamber_depth)
	col.shape = shape
	col.position = Vector3(0.0, chamber_height * 0.5, 0.0)
	add_child(col)

	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2  # Player layer

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_build_frame()
	_build_bars()
	_build_label()
	_calculate_node_positions()
	_find_player()
	add_to_group("enemy")


func _process(delta: float) -> void:
	_time += delta
	_freq_timer += delta

	# Change frequency periodically
	if _freq_timer >= frequency_change_interval:
		_freq_timer = 0.0
		_target_harmonic = randi_range(min_harmonic, max_harmonic)
		if _target_harmonic == _current_harmonic:
			_target_harmonic = wrapi(_current_harmonic + 1, min_harmonic, max_harmonic + 1)
		_current_harmonic = _target_harmonic
		_calculate_node_positions()

	# Animate bars toward target positions and pulse emission
	var wave_freq: float = _current_harmonic * 0.5  # Visual oscillation rate
	for i in range(_bars.size()):
		var bar: MeshInstance3D = _bars[i]
		var target_x: float = _bar_positions[i] if i < _bar_positions.size() else 0.0

		# Smoothly move bars to node positions
		bar.position.x = lerpf(bar.position.x, target_x, delta * 3.0)

		# Pulse emission intensity
		var phase: float = _time * wave_freq * TAU + float(i) * 0.8
		var intensity: float = 1.0 + 2.0 * (0.5 + 0.5 * sin(phase))
		_bar_mats[i].emission_energy_multiplier = intensity

	# Update label
	if _label:
		var wavelength: float = chamber_width / float(_current_harmonic) if _current_harmonic > 0 else chamber_width
		_label.text = "n=%d  f=%d  lambda=%.2fm" % [_current_harmonic, _current_harmonic, wavelength]

	# Damage — check if player overlaps any bar
	if _player_inside and is_instance_valid(_player_node):
		var player_local: Vector3 = to_local(_player_node.global_position)
		var touching_bar: bool = false

		for i in range(_bars.size()):
			if i >= _bar_positions.size():
				break
			var bar_x: float = _bars[i].position.x
			if absf(player_local.x - bar_x) < bar_thickness * 1.5:
				touching_bar = true
				break

		if touching_bar:
			_damage_accumulator += delta * damage_per_second
			if _damage_accumulator >= 1.0:
				var dmg: float = floor(_damage_accumulator)
				_damage_accumulator -= dmg
				var gm = get_node_or_null("/root/GameManager")
				if gm and gm.has_method("apply_health_damage"):
					gm.apply_health_damage(dmg)


func _calculate_node_positions() -> void:
	# Standing wave nodes: positions where sin(n * PI * x / width) = 0
	# These are at x = k * width / n for k = 0..n
	_bar_positions.clear()
	var half_w: float = chamber_width * 0.5
	for k in range(1, _current_harmonic):  # Skip boundaries (k=0 and k=n)
		var x_pos: float = (float(k) / float(_current_harmonic)) * chamber_width - half_w
		_bar_positions.append(x_pos)

	# If we have more bars than node positions, stack extras at center
	while _bar_positions.size() < _bars.size():
		_bar_positions.append(0.0)


func _build_frame() -> void:
	# Transparent box for the chamber walls
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(chamber_width, chamber_height, chamber_depth)

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color
	frame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	frame_mat.emission_enabled = true
	frame_mat.emission = Color(0.3, 0.5, 0.8)
	frame_mat.emission_energy_multiplier = 0.3
	frame_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_frame_mesh = MeshInstance3D.new()
	_frame_mesh.mesh = frame_mesh
	_frame_mesh.set_surface_override_material(0, frame_mat)
	_frame_mesh.position = Vector3(0.0, chamber_height * 0.5, 0.0)
	add_child(_frame_mesh)


func _build_bars() -> void:
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(bar_thickness, bar_thickness, chamber_depth * 0.9)

	for i in range(bar_count):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = bar_color
		mat.emission_enabled = true
		mat.emission = bar_emission
		mat.emission_energy_multiplier = 1.5

		var mi := MeshInstance3D.new()
		mi.mesh = bar_mesh
		mi.set_surface_override_material(0, mat)
		# Distribute evenly to start; will be repositioned by _calculate_node_positions
		var t: float = float(i + 1) / float(bar_count + 1)
		mi.position = Vector3(
			t * chamber_width - chamber_width * 0.5,
			chamber_height * 0.5,
			0.0
		)
		add_child(mi)

		_bars.append(mi)
		_bar_mats.append(mat)


func _build_label() -> void:
	_label = Label3D.new()
	_label.text = "RESONANCE"
	_label.font_size = 24
	_label.pixel_size = 0.003
	_label.modulate = Color(0.5, 0.7, 1.0)
	_label.position = Vector3(0.0, chamber_height + 0.3, 0.0)
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
	if config.has("harmonic"):
		_current_harmonic = int(config["harmonic"])
		_calculate_node_positions()

func apply_grid_config(config: Dictionary) -> void:
	configure(config)
