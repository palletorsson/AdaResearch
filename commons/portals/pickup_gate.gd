# pickup_gate.gd
# A gate/portal that blocks passage until a certain number of pickup cubes are collected
# Instantiated like: pickup_gate#pickups:5 or pickup_gate#count:3

extends Node3D

class_name PickupGate

# Parameters - set via grid instantiation
@export var required_pickups: int = 1  # Number of pickups needed to open the gate
@export var gate_color: Color = Color(1.0, 0.0, 0.0, 0.5)  # Red semi-transparent by default
@export var gate_open_color: Color = Color(0.0, 1.0, 0.0, 0.3)  # Green transparent when open

# Internal state
var is_open: bool = false
var blocking_mesh: MeshInstance3D = null
var collision_body: StaticBody3D = null
var collision_shape: CollisionShape3D = null
var label: Label3D = null

func _ready() -> void:
	print("PickupGate: Initialized, requires %d pickups" % required_pickups)

	# Find child nodes
	blocking_mesh = find_child("BlockingMesh", true, false) as MeshInstance3D
	collision_body = find_child("StaticBody3D", true, false) as StaticBody3D
	collision_shape = find_child("CollisionShape3D", true, false) as CollisionShape3D
	label = find_child("Label3D", true, false) as Label3D

	# Connect to GameManager signals
	if GameManager:
		GameManager.score_updated.connect(_on_score_updated)
	else:
		push_error("PickupGate: GameManager not found!")

	# Defer initial check to allow configuration to be applied first
	call_deferred("_initial_gate_check")

func _initial_gate_check() -> void:
	# Called deferred after _ready() to allow configuration to be applied first
	print("PickupGate: Performing initial gate check with %d required pickups" % required_pickups)
	if GameManager:
		_check_and_update_gate(GameManager.get_score())
	_update_label()

func _on_score_updated(new_score: int) -> void:
	print("PickupGate: Score updated to %d (need %d)" % [new_score, required_pickups])
	_check_and_update_gate(new_score)

func _check_and_update_gate(current_score: int) -> void:
	if current_score >= required_pickups and not is_open:
		_open_gate()
	elif current_score < required_pickups and is_open:
		_close_gate()

	# Always update the label
	_update_label()

func _open_gate() -> void:
	is_open = true
	print("PickupGate: OPENING GATE!")

	# Remove collision body IMMEDIATELY (so player can pass through right away)
	if collision_body and is_instance_valid(collision_body):
		print("  Removing collision body...")
		# Disable collision layers instantly (belt and suspenders approach)
		collision_body.collision_layer = 0
		collision_body.collision_mask = 0
		# Then queue for removal
		collision_body.queue_free()
		collision_body = null
		collision_shape = null
	else:
		print("  WARNING: collision_body not found!")

	# Remove blocking mesh
	if blocking_mesh and is_instance_valid(blocking_mesh):
		# Just remove it directly - no fade animation with shader materials
		blocking_mesh.queue_free()
		blocking_mesh = null

	# Update label
	_update_label()

	# Play open sound
	_play_open_sound()

func _close_gate() -> void:
	is_open = false
	print("PickupGate: CLOSING GATE")

	# Show blocking mesh
	if blocking_mesh:
		blocking_mesh.visible = true
		blocking_mesh.modulate.a = gate_color.a

	# Enable collision
	if collision_shape:
		collision_shape.disabled = false

	# Update label
	_update_label()

func _update_label() -> void:
	if not label:
		return

	var current_score = 0
	if GameManager:
		current_score = GameManager.get_score()

	if is_open:
		label.text = "GATE OPEN\n✓"
		label.modulate = Color.GREEN
	else:
		var remaining = required_pickups - current_score
		label.text = "Collect %d more\n(%d/%d)" % [remaining, current_score, required_pickups]
		label.modulate = Color.ORANGE

func _play_open_sound() -> void:
	# Create a simple success sound
	var sound_player = AudioStreamPlayer3D.new()
	add_child(sound_player)

	sound_player.unit_size = 5.0
	sound_player.max_distance = 30.0
	sound_player.volume_db = -3.0

	# Generate a rising tone success sound
	var sample_rate = 44100
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate

	var data = PackedByteArray()
	var duration = 0.4
	var samples = int(duration * sample_rate)

	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = t / duration

		# Rising frequency sweep
		var freq = lerp(440.0, 880.0, progress)
		var envelope = (1.0 - progress) * 0.6  # Fade out

		var sample_value = sin(TAU * freq * t) * envelope
		var sample_int = int(sample_value * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	stream.data = data
	sound_player.stream = stream
	sound_player.play()

	# Clean up after playing
	sound_player.finished.connect(func(): sound_player.queue_free())

# Public API - called by GridInteractablesComponent to set parameters
func set_required_pickups(count: int) -> void:
	required_pickups = max(1, count)
	print("PickupGate: Required pickups set to %d" % required_pickups)
	_update_label()

# Helper for grid spawning - parse parameters from token like "pickup_gate:5"
func parse_parameters(params: Array) -> void:
	if params.size() > 0:
		var count_str = str(params[0])
		if count_str.is_valid_int():
			set_required_pickups(int(count_str))

# Called by GridInteractablesComponent when using # syntax
# Supports: pickup_gate#pickups:5 or pickup_gate#count:3
func apply_grid_config(config: Dictionary) -> void:
	print("PickupGate: Applying grid config: %s" % config)

	# Check for pickup count configuration
	if config.has("pickups"):
		var count_str = str(config["pickups"])
		if count_str.is_valid_int():
			set_required_pickups(int(count_str))
			print("  Set required pickups from 'pickups' key: %d" % required_pickups)

	# Also support "count" as alias
	if config.has("count"):
		var count_str = str(config["count"])
		if count_str.is_valid_int():
			set_required_pickups(int(count_str))
			print("  Set required pickups from 'count' key: %d" % required_pickups)

	# Support color configuration
	if config.has("color"):
		var color_str = str(config["color"]).to_lower()
		match color_str:
			"red":
				gate_color = Color(1.0, 0.0, 0.0, 0.5)
			"blue":
				gate_color = Color(0.0, 0.0, 1.0, 0.5)
			"green":
				gate_color = Color(0.0, 1.0, 0.0, 0.5)
			"yellow":
				gate_color = Color(1.0, 1.0, 0.0, 0.5)

		# Update mesh color if already created
		if blocking_mesh and blocking_mesh.material_override:
			blocking_mesh.material_override.albedo_color = gate_color

	# Re-check gate state after configuration is applied
	if GameManager:
		_check_and_update_gate(GameManager.get_score())
	_update_label()
