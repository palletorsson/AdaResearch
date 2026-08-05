# CubeSpawner.gd - Main spawner that shoots cubes at the player
extends Node3D

@export var projectile_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var projectile_speed: float = 10.0
@export var spawn_range: float = 15.0
@export var target_prediction: float = 0.5  # How much to lead the target
@export var max_projectiles: int = 20
@export var auto_start: bool = true

enum SpawnMode {
	FORWARD,
	FALLING_FIELD
}

@export_group("Falling Field")
@export var spawn_mode: SpawnMode = SpawnMode.FORWARD
@export var field_size_meters: Vector2 = Vector2(8.0, 8.0)
@export var field_center_offset: Vector3 = Vector3.ZERO
@export var field_spawn_height: float = 7.0
@export var field_fall_speed_range: Vector2 = Vector2(1.8, 3.0)
@export var field_initial_horizontal_speed: float = 0.35
@export var field_horizontal_jitter: float = 0.25
@export var field_jitter_interval: float = 0.4
@export var field_vertical_speed_variation: float = 0.2

## AXIS — WARNING: how much the hazard tells you BEFORE it costs you anything. Adopted
## word for word from [[kaleidocycle_enemy]], [[miura_crawler]], [[scissor_stalker]],
## [[path_cube]], [[path_pyramid]] and [[path_wedge]]: one vocabulary across the hazards,
## because a room cannot coherently cage its crawlers and leave the thing that shoots at
## them unannounced. This is the sharpest case in the family for a different reason than
## the kaleidocycle — the spawner is not the danger, it is the SOURCE of the danger, and
## between two firings it is a box on the floor doing nothing at all. What the room says
## about a box that is currently idle is not a property of the box.
##
##   none    the red emitter alone, with the plume and the label it always had —
##           THE LEGACY BODY, byte for byte.
##   stain   scorch soaked into the floor under the muzzle and two burn runs bled off
##           one side, and nothing above it. You can only read it standing where it has
##           already been firing.
##   cage    a bolted bar frame and a filed yellow tag. Somebody catalogued this and
##           fenced it, and it fires through the bars on exactly the same clock.
##   beacon  a lit mast up out of the emitter with a lamp head, plus a glowing outline
##           burnt onto the floor: readable from the doorway, before you are in range.
##   shroud  a canvas wrap strapped over the whole emitter. The timer is still running
##           underneath it. The world knows and has decided you should not.
##
## APPEARANCE ONLY. spawn_interval, projectile_speed, max_projectiles, target_prediction,
## spawn_mode and every field_* number are byte-identical across all five values, and no
## value adds or removes a collider. A hazard that hides itself is not a gentler hazard.
@export_group("Warning")
const WARNING_VALUES: PackedStringArray = ["none", "stain", "cage", "beacon", "shroud"]
@export_enum("none", "stain", "cage", "beacon", "shroud") var warning: String = "none"

@export_group("Determinism")
## Seed for the falling-field spawn scatter. -1 = randomize on every boot, which is what
## this spawner has always done and remains the default. Any value >= 0 makes the field
## repeat exactly, so a capture, a regression shot or a bug report can be re-run and get
## the same cubes in the same places.
@export var field_seed: int = -1
## Hold the idle animation still. Default false = the legacy behaviour: the emitter pulses
## between 1.0 and 1.2 scale on a looping tween and the warning plume emits, both of which
## land at an arbitrary phase in any single frame. Set true (a still capture wants
## `{"idle_still": true}` as a dna.fixture) to skip both, so the frame shows the housing
## and not what time it was. UNTYPED on purpose — a fixture that arrives as the string
## "true" would be rejected by a typed bool before _ready and silently do nothing.
@export var idle_still = false

# Visual components
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var spawn_timer: Timer = $SpawnTimer
@onready var warning_particles: GPUParticles3D = $WarningParticles
@onready var spawn_point: Marker3D = $SpawnPoint

# Audio
@onready var spawn_sound: AudioStreamPlayer3D = $SpawnSound
@onready var warning_sound: AudioStreamPlayer3D = $WarningSound

var player_node: Node3D
var active_projectiles: Array[Node3D] = []
var is_active: bool = false
var _rng := RandomNumberGenerator.new()

# Signals
signal projectile_spawned(projectile: Node3D)
signal player_hit(damage: int)
signal spawner_activated()
signal spawner_deactivated()

func _ready():
	# LEGACY STREAM PRESERVED: field_seed defaults to -1, so this is still the same
	# unseeded randomize() call in the same place, drawing the same way.
	if field_seed < 0:
		_rng.randomize()
	else:
		_rng.seed = field_seed
	var w: String = str(warning).strip_edges().to_lower()
	warning = w if WARNING_VALUES.has(w) else "none"
	_setup_spawner()
	_find_player()

	if auto_start:
		activate_spawner()

	# WARNING dressing LAST, so every child added above keeps its index and the emitter,
	# the timer, the marker, the plume, the two audio players and the label are all
	# exactly where they were. "none" falls through and adds nothing at all.
	_build_warning()

func _setup_spawner():
	"""Initialize the spawner components"""
	# Create projectile scene if not set
	if not projectile_scene:
		projectile_scene = preload("res://commons/primitives/cubes/projectile_cube.tscn")
	
	# Setup timer
	if not spawn_timer:
		spawn_timer = Timer.new()
		add_child(spawn_timer)
	
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_projectile)
	spawn_timer.autostart = false
	
	# Setup visual components
	if not mesh_instance:
		_create_spawner_visual()
	
	if not spawn_point:
		spawn_point = Marker3D.new()
		spawn_point.name = "SpawnPoint"
		add_child(spawn_point)
		spawn_point.position = Vector3(0, 0.5, 0)

func _create_spawner_visual():
	"""Create the visual representation of the spawner"""
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)
	
	# Create a menacing-looking spawner
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.2, 1.2, 1.2)
	mesh_instance.mesh = box_mesh
	
	# Create warning material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission = Color(1.0, 0.3, 0.0)
	material.emission_energy = 2.0
	material.metallic = 0.8
	material.roughness = 0.2
	mesh_instance.material_override = material
	
	# Add warning particles
	warning_particles = GPUParticles3D.new()
	warning_particles.name = "WarningParticles"
	add_child(warning_particles)
	warning_particles.emitting = false
	
	# Setup particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.initial_velocity_min = 2.0
	particle_material.initial_velocity_max = 5.0
	particle_material.gravity = Vector3(0, -9.8, 0)
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	warning_particles.process_material = particle_material
	warning_particles.amount = 50

func _find_player():
	"""Find the player node in the scene"""
	# Try multiple common player node patterns
	var potential_players = [
		get_tree().get_first_node_in_group("player"),
		get_tree().current_scene.find_child("XROrigin3D", true, false),
		get_tree().current_scene.find_child("Player", true, false),
		get_tree().current_scene.find_child("PlayerBody", true, false)
	]
	
	for potential_player in potential_players:
		if potential_player:
			player_node = potential_player
			print("CubeSpawner: Found player - %s" % player_node.name)
			break
	
	if not player_node:
		print("CubeSpawner: WARNING - No player found!")

func activate_spawner():
	"""Start spawning projectiles"""
	if not is_active:
		is_active = true
		spawn_timer.start()
		_play_warning_effects()
		spawner_activated.emit()
		print("CubeSpawner: Activated - spawning every %.1f seconds" % spawn_interval)

func deactivate_spawner():
	"""Stop spawning projectiles"""
	if is_active:
		is_active = false
		spawn_timer.stop()
		_stop_warning_effects()
		spawner_deactivated.emit()
		print("CubeSpawner: Deactivated")

func _play_warning_effects():
	"""Play visual and audio warnings"""
	# idle_still defaults to false, so this whole function is the legacy one.
	if _still():
		return
	if warning_particles:
		warning_particles.emitting = true

	if warning_sound:
		warning_sound.play()

	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(mesh_instance, "scale", Vector3(1.2, 1.2, 1.2), 0.5)
	tween.tween_property(mesh_instance, "scale", Vector3(1.0, 1.0, 1.0), 0.5)


## Truthy for a bool `true`, an int 1 or the strings "true"/"1"/"yes"/"on". A fixture key
## can arrive from JSON as any of those, and the one that arrives as a String is exactly
## the one a typed bool would have thrown away without saying so.
func _still() -> bool:
	if idle_still is bool:
		return idle_still
	return str(idle_still).strip_edges().to_lower() in ["true", "1", "yes", "on"]

func _stop_warning_effects():
	"""Stop visual effects"""
	if warning_particles:
		warning_particles.emitting = false
	
	# Stop pulsing
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3(1.0, 1.0, 1.0), 0.2)

func _spawn_projectile():
	"""Spawn a projectile in the specified direction"""
	if not is_active or not projectile_scene:
		return
	
	# Clean up old projectiles
	_cleanup_projectiles()
	
	# Check projectile limit
	if active_projectiles.size() >= max_projectiles:
		print("CubeSpawner: Max projectiles reached (%d)" % max_projectiles)
		return
	
	# Create projectile
	var projectile = projectile_scene.instantiate()
	if not projectile:
		print("CubeSpawner: Failed to instantiate projectile")
		return
	
	# Add to scene
	get_tree().current_scene.add_child(projectile)

	if spawn_mode == SpawnMode.FALLING_FIELD:
		_configure_falling_field_projectile(projectile)
	else:
		_configure_forward_projectile(projectile)
	
	# Track projectile
	active_projectiles.append(projectile)
	
	# Connect cleanup signal
	if projectile.has_signal("projectile_destroyed"):
		projectile.projectile_destroyed.connect(_on_projectile_destroyed.bind(projectile))
	
	# Play spawn sound
	if spawn_sound and spawn_sound.stream:
		spawn_sound.play()
	
	projectile_spawned.emit(projectile)
	print("CubeSpawner: Spawned projectile #%d (mode=%s)" % [active_projectiles.size(), "field" if spawn_mode == SpawnMode.FALLING_FIELD else "forward"])

func _configure_forward_projectile(projectile: Node3D) -> void:
	projectile.global_position = spawn_point.global_position

	# Set direction - shoot in Z direction (forward)
	var direction = Vector3(0, 0, -1)

	# Apply spawner's rotation to direction
	direction = global_transform.basis * direction

	if projectile.has_method("setup_projectile"):
		projectile.setup_projectile(direction, projectile_speed, self)
	elif "velocity" in projectile:
		projectile.velocity = direction * projectile_speed

func _configure_falling_field_projectile(projectile: Node3D) -> void:
	var half_w = max(field_size_meters.x * 0.5, 0.1)
	var half_d = max(field_size_meters.y * 0.5, 0.1)
	var field_origin = global_position + field_center_offset
	var spawn_pos = field_origin + Vector3(
		_rng.randf_range(-half_w, half_w),
		field_spawn_height,
		_rng.randf_range(-half_d, half_d)
	)
	projectile.global_position = spawn_pos

	var min_fall_speed = max(0.2, min(field_fall_speed_range.x, field_fall_speed_range.y))
	var max_fall_speed = max(min_fall_speed, max(field_fall_speed_range.x, field_fall_speed_range.y))
	var fall_speed = _rng.randf_range(min_fall_speed, max_fall_speed)
	var initial_velocity = Vector3(
		_rng.randf_range(-field_initial_horizontal_speed, field_initial_horizontal_speed),
		-fall_speed,
		_rng.randf_range(-field_initial_horizontal_speed, field_initial_horizontal_speed)
	)

	if projectile.has_method("set_falling_field_profile"):
		projectile.set_falling_field_profile(
			initial_velocity,
			field_horizontal_jitter,
			field_jitter_interval,
			field_vertical_speed_variation
		)
	elif projectile.has_method("setup_projectile"):
		var direction = initial_velocity.normalized() if initial_velocity.length() > 0.001 else Vector3.DOWN
		projectile.setup_projectile(direction, initial_velocity.length(), self)
	elif "velocity" in projectile:
		projectile.velocity = initial_velocity

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)

func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	if config_data.has("mode"):
		var mode_value = str(config_data["mode"]).strip_edges().to_lower()
		if mode_value in ["field", "falling", "falling_field", "rain", "rain_field"]:
			spawn_mode = SpawnMode.FALLING_FIELD
		else:
			spawn_mode = SpawnMode.FORWARD

	# Boolean shorthand support: #field
	if config_data.has("field"):
		spawn_mode = SpawnMode.FALLING_FIELD
		var field_value = config_data["field"]
		if typeof(field_value) != TYPE_BOOL:
			field_size_meters = _parse_field_size(str(field_value), field_size_meters)

	if config_data.has("spawn_interval"):
		set_spawn_interval(_to_float(config_data["spawn_interval"], spawn_interval))
	if config_data.has("max_projectiles"):
		max_projectiles = int(_to_float(config_data["max_projectiles"], float(max_projectiles)))
	if config_data.has("projectile_speed"):
		set_projectile_speed(_to_float(config_data["projectile_speed"], projectile_speed))

	if config_data.has("field_size"):
		field_size_meters = _parse_field_size(str(config_data["field_size"]), field_size_meters)
	if config_data.has("field_width"):
		field_size_meters.x = max(0.5, _to_float(config_data["field_width"], field_size_meters.x))
	if config_data.has("field_depth"):
		field_size_meters.y = max(0.5, _to_float(config_data["field_depth"], field_size_meters.y))
	if config_data.has("field_x"):
		field_size_meters.x = max(0.5, _to_float(config_data["field_x"], field_size_meters.x))
	if config_data.has("field_z"):
		field_size_meters.y = max(0.5, _to_float(config_data["field_z"], field_size_meters.y))
	if config_data.has("field_height"):
		field_spawn_height = max(0.5, _to_float(config_data["field_height"], field_spawn_height))

	if config_data.has("fall_min"):
		field_fall_speed_range.x = max(0.2, _to_float(config_data["fall_min"], field_fall_speed_range.x))
	if config_data.has("fall_max"):
		field_fall_speed_range.y = max(0.2, _to_float(config_data["fall_max"], field_fall_speed_range.y))

	if config_data.has("drift"):
		field_initial_horizontal_speed = max(0.0, _to_float(config_data["drift"], field_initial_horizontal_speed))
	if config_data.has("jitter"):
		field_horizontal_jitter = max(0.0, _to_float(config_data["jitter"], field_horizontal_jitter))
	if config_data.has("jitter_interval"):
		field_jitter_interval = max(0.05, _to_float(config_data["jitter_interval"], field_jitter_interval))
	if config_data.has("vertical_variation"):
		field_vertical_speed_variation = max(0.0, _to_float(config_data["vertical_variation"], field_vertical_speed_variation))

	if config_data.has("field_seed"):
		field_seed = int(_to_float(config_data["field_seed"], float(field_seed)))
		if field_seed >= 0:
			_rng.seed = field_seed

	# WARNING last, and gated on the key: a config that says nothing about it cannot
	# disturb the dressing already standing. An unrecognised word keeps the current
	# value — a typo must not silently uncage a live hazard.
	if config_data.has("warning"):
		var w: String = str(config_data["warning"]).strip_edges().to_lower()
		if WARNING_VALUES.has(w) and w != warning:
			warning = w
			_build_warning()

func _to_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var text = str(value).strip_edges()
	return float(text) if text.is_valid_float() else fallback

func _parse_field_size(value: String, fallback: Vector2) -> Vector2:
	var normalized = value.strip_edges().to_lower()
	normalized = normalized.replace("x", " ")
	normalized = normalized.replace(",", " ")
	normalized = normalized.replace(";", " ")
	var parts = normalized.split(" ", false)
	if parts.size() >= 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
		return Vector2(max(0.5, float(parts[0])), max(0.5, float(parts[1])))
	if parts.size() == 1 and parts[0].is_valid_float():
		var s = max(0.5, float(parts[0]))
		return Vector2(s, s)
	return fallback

func _get_predicted_player_position() -> Vector3:
	"""Calculate where the player will be when projectile arrives"""
	if not player_node:
		return Vector3.ZERO
	
	var player_position = player_node.global_position
	
	# Add some height to target the player's center
	player_position.y += 1.0
	
	# Try to predict player movement
	if "velocity" in player_node and target_prediction > 0:
		var player_velocity = player_node.velocity
		var distance = global_position.distance_to(player_position)
		var travel_time = distance / projectile_speed
		var predicted_offset = player_velocity * travel_time * target_prediction
		player_position += predicted_offset
	
	return player_position

func _cleanup_projectiles():
	"""Remove null references from projectile array"""
	active_projectiles = active_projectiles.filter(func(p): return is_instance_valid(p))

func _on_projectile_destroyed(projectile: Node3D):
	"""Handle projectile destruction"""
	var index = active_projectiles.find(projectile)
	if index >= 0:
		active_projectiles.remove_at(index)

# Public interface methods
func set_spawn_interval(interval: float):
	"""Change how often projectiles spawn"""
	spawn_interval = interval
	spawn_timer.wait_time = interval
	print("CubeSpawner: Spawn interval set to %.1f seconds" % interval)

func set_projectile_speed(speed: float):
	"""Change projectile speed"""
	projectile_speed = speed
	print("CubeSpawner: Projectile speed set to %.1f" % speed)

func clear_all_projectiles():
	"""Remove all active projectiles"""
	for projectile in active_projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	active_projectiles.clear()
	print("CubeSpawner: Cleared all projectiles")

# ─── WARNING dressing ─────────────────────────────────────────────────────────────────
# The bodies for the axis declared at the top of this file. They were MISSING: _ready and
# configure both called _build_warning() and no such function existed anywhere in the
# script, which in GDScript 4 is a resolution error at parse time, so CubeSpawner.gd did
# not load and all ten placements of cube_projectile_spawner stood empty. The declaration
# gate cannot see this class of fault — the export is real and its values are real; it is
# the builder that is absent. Same shape as dna_specimen, one step further along.
#
# The vocabulary, the colours and the `hazard_warning` group are kaleidocycle_enemy.gd's,
# reused and not re-invented, so the seven hazards that share the word photograph as one
# apparatus at seven scales. Every box is sized from the emitter's own AABB, so a resized
# spawner keeps its dressing in proportion.
const WARN_STAIN_OUTER := Color(0.24, 0.19, 0.13)
const WARN_STAIN_CORE := Color(0.09, 0.075, 0.055)
const WARN_BAR := Color(0.52, 0.50, 0.44)
const WARN_TAG := Color(0.86, 0.72, 0.12)
const WARN_MAST := Color(0.38, 0.38, 0.40)
const WARN_LAMP := Color(1.0, 0.62, 0.12)
const WARN_CLOTH := Color(0.40, 0.38, 0.33)
const WARN_STRAP := Color(0.15, 0.14, 0.13)


## Rebuildable: configure() reaches this after _ready, so drop the previous dressing first
## (remove_child before queue_free — the sweep measures the AABB on the very next frame).
## "none" falls through the match and builds no node at all, which is why the default costs
## the ten existing placements exactly zero children and zero index shifts.
func _build_warning() -> void:
	for child in get_children():
		if child.is_in_group("hazard_warning"):
			remove_child(child)
			child.queue_free()
	var b: AABB = _warn_bounds()
	match warning:
		"stain":
			_warn_stain(b)
		"cage":
			_warn_cage(b)
		"beacon":
			_warn_beacon(b)
		"shroud":
			_warn_shroud(b)
		_:
			pass


## The emitter's real extent, read from the mesh instead of guessed off the shipped 1.2 m.
## The idle tween scales mesh_instance between 1.0 and 1.2 and is deliberately NOT read
## here: the dressing must not breathe with the housing, or a still would photograph the
## cage at whatever size the pulse happened to be.
func _warn_bounds() -> AABB:
	if mesh_instance != null and mesh_instance.mesh != null:
		var m: AABB = mesh_instance.mesh.get_aabb()
		m.position += mesh_instance.position
		return m
	return AABB(Vector3(-0.6, -0.6, -0.6), Vector3(1.2, 1.2, 1.2))


## How high a cover has to reach to actually cover. The shipped placard hangs at y 1.5 well
## above the 1.2 m housing, and a wrap that stopped at the crown would leave the hazard sign
## legible — a shroud that announces itself is not a shroud. Read, never mutated: no legacy
## child is touched by any value.
func _warn_cover_top(b: AABB) -> float:
	var top: float = b.position.y + b.size.y
	var placard: Node = get_node_or_null("Label3D")
	if placard is Node3D:
		top = maxf(top, (placard as Node3D).position.y + 0.22)
	return top


## STAIN — the notice written on the floor. Scorch soaked in under the housing with a darker
## core, and two burn runs bled off toward -Z, which is where this thing actually fires.
## Nothing stands up: you can only read it from inside the room it has been firing into.
func _warn_stain(b: AABB) -> void:
	var r: float = maxf(maxf(b.size.x, b.size.z) * 0.5, 0.05)
	var c: Vector3 = b.get_center()
	var y: float = b.position.y - 0.006
	_warn_add(Vector3(c.x, y, c.z), Vector3(r * 3.4, 0.012, r * 3.4),
		_warn_mat(WARN_STAIN_OUTER, 1.0, 0.0))
	_warn_add(Vector3(c.x, y + 0.007, c.z), Vector3(r * 2.1, 0.012, r * 2.1),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(c.x + r * 0.30, y + 0.004, c.z - r * 1.5),
		Vector3(r * 0.30, 0.012, r * 1.1), _warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(c.x - r * 0.70, y + 0.004, c.z - r * 1.25),
		Vector3(r * 0.22, 0.012, r * 0.8), _warn_mat(WARN_STAIN_CORE, 1.0, 0.0))


## CAGE — the notice as paperwork. Four posts, two rails, one filed yellow tag. Somebody
## catalogued this and fenced it, and it fires through the bars on exactly the same clock.
func _warn_cage(b: AABB) -> void:
	var r: float = maxf(maxf(b.size.x, b.size.z) * 0.5, 0.05)
	var c: Vector3 = b.get_center()
	var bot: float = b.position.y - 0.005
	var top: float = b.position.y + b.size.y + r * 0.55
	var hx: float = r * 1.36
	var bar: StandardMaterial3D = _warn_mat(WARN_BAR, 0.45, 0.55)
	var thick: float = maxf(r * 0.09, 0.025)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_warn_add(Vector3(c.x + float(sx) * hx, (bot + top) * 0.5, c.z + float(sz) * hx),
				Vector3(thick, top - bot, thick), bar)
	for ry in [top, bot + (top - bot) * 0.45]:
		var y: float = float(ry)
		for s in [-1.0, 1.0]:
			var o: float = float(s) * hx
			_warn_add(Vector3(c.x, y, c.z + o), Vector3(hx * 2.0 + thick, thick * 0.8, thick * 0.8), bar)
			_warn_add(Vector3(c.x + o, y, c.z), Vector3(thick * 0.8, thick * 0.8, hx * 2.0 + thick), bar)
	_warn_add(Vector3(c.x + hx + thick * 0.6, bot + (top - bot) * 0.72, c.z),
		Vector3(0.016, r * 0.42, r * 0.62), _warn_mat(WARN_TAG, 0.7, 0.0))


## BEACON — the notice as broadcast. A lit mast up out of the housing with a lamp head and a
## shade, and a glowing outline burnt onto the floor around it. Readable from the doorway,
## which is the only rung of the five that reaches you before you are in range.
func _warn_beacon(b: AABB) -> void:
	var r: float = maxf(maxf(b.size.x, b.size.z) * 0.5, 0.05)
	var c: Vector3 = b.get_center()
	var crown: float = b.position.y + b.size.y
	var mast_h: float = r * 2.0
	var mast: StandardMaterial3D = _warn_mat(WARN_MAST, 0.4, 0.6)
	var lamp: StandardMaterial3D = _warn_emissive(WARN_LAMP, 3.2)
	var thick: float = maxf(r * 0.10, 0.03)
	_warn_add(Vector3(c.x, crown + mast_h * 0.5, c.z), Vector3(thick, mast_h, thick), mast)
	_warn_add(Vector3(c.x, crown + mast_h + r * 0.20, c.z),
		Vector3(r * 0.52, r * 0.30, r * 0.52), lamp)
	_warn_add(Vector3(c.x, crown + mast_h + r * 0.42, c.z),
		Vector3(r * 0.74, thick * 0.7, r * 0.74), mast)
	var hx: float = r * 1.55
	var y: float = b.position.y - 0.004
	for s in [-1.0, 1.0]:
		var o: float = float(s) * hx
		_warn_add(Vector3(c.x, y, c.z + o), Vector3(hx * 2.0, 0.02, thick), lamp)
		_warn_add(Vector3(c.x + o, y, c.z), Vector3(thick, 0.02, hx * 2.0), lamp)


## SHROUD — the notice withheld. Canvas strapped over the housing and up past the placard,
## so the machine and its own sign go under together. The timer is still running underneath
## it, on the same interval, with the same collider: the world knows and has decided you
## should not.
func _warn_shroud(b: AABB) -> void:
	var r: float = maxf(maxf(b.size.x, b.size.z) * 0.5, 0.05)
	var c: Vector3 = b.get_center()
	var cloth: StandardMaterial3D = _warn_mat(WARN_CLOTH, 0.95, 0.0)
	var strap: StandardMaterial3D = _warn_mat(WARN_STRAP, 0.85, 0.1)
	var bot: float = b.position.y - 0.01
	var top: float = _warn_cover_top(b) + 0.06
	var h: float = maxf(top - bot, 0.05)
	var mid: float = (bot + top) * 0.5
	var w: float = r * 2.28
	_warn_add(Vector3(c.x, mid, c.z), Vector3(w, h, w), cloth)
	_warn_add(Vector3(c.x, top + 0.03, c.z), Vector3(w * 0.30, 0.06, w * 0.30), cloth)
	_warn_add(Vector3(c.x, bot, c.z), Vector3(w + 0.07, 0.05, w + 0.07), cloth)
	for s in [-1.0, 1.0]:
		var o: float = float(s) * w * 0.5
		_warn_add(Vector3(c.x, mid, c.z + o), Vector3(w + 0.01, h * 0.22, 0.012), strap)
		_warn_add(Vector3(c.x + o, mid, c.z), Vector3(0.012, h * 0.22, w + 0.01), strap)


func _warn_add(center: Vector3, box_size: Vector3, mat: Material) -> void:
	var bm: BoxMesh = BoxMesh.new()
	bm.size = box_size
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	mi.add_to_group("hazard_warning")
	add_child(mi)


func _warn_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _warn_emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


# Debug methods
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_P:  # P to toggle spawner
			if is_active:
				deactivate_spawner()
			else:
				activate_spawner()
		elif event.keycode == KEY_O:  # O to spawn single projectile
			_spawn_projectile()
		elif event.keycode == KEY_C:  # C to clear projectiles
			clear_all_projectiles()
