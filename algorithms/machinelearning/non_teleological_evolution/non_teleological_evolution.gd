# non_teleological_evolution.gd
# Bodies exist in a space. No fitness function. No selection pressure.
# They reproduce based on proximity and energy (gained by moving to
# unvisited areas, lost by existing). Over generations, forms diversify —
# not toward any goal, just expanding possibility space.
# No "best" creature. No optimization. Just drift, variation, persistence.
#
# @identity
#   essence: evolution without purpose — bodies persisting through drift alone
#   desire: players witness diversification without optimization or progress narratives
#   critical_parameter: energy_decay — how fast creatures lose energy by merely existing
#   triggers: instantiation, runs continuously
#   emerges: the realization that evolution needs no goal to produce complexity
#   needs: [implemented] MultiMesh creatures, energy model, reproduction, death, Label3D stats
#   relationships: evolved_creatures (fitness-driven counterpart), 9_5_evolving_bloops_vr (similar)
#   truth: there is no ladder of progress — only a bush of persistence

extends Node3D

# --- Configuration ---
@export var world_size: float = 2.0
@export var initial_population: int = 30
@export var max_population: int = 120
@export var energy_decay: float = 0.15  # Energy lost per second
@export var energy_from_exploration: float = 0.8  # Energy gained from unvisited cells
@export var reproduction_threshold: float = 3.0
@export var mutation_strength: float = 0.15
@export var grid_resolution: int = 20  # For tracking visited cells

# --- Internal ---
var _creatures: Array = []  # Array of dictionaries
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _visited_grid: Array = []  # 2D bool grid
var _generation_count: int = 0
var _total_born: int = 0
var _total_died: int = 0
var _max_species_diversity: float = 0.0

var _stats_label: Label3D
var _title_label: Label3D
var _no_fitness_label: Label3D

var _creature_mesh: SphereMesh
var _time_elapsed: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = hash("non_teleological")
	_init_visited_grid()
	_create_creature_mesh()
	_create_multimesh()
	_spawn_initial_population()
	_create_labels()
	_create_ground_plane()


func apply_grid_config(config: Dictionary) -> void:
	pass


# ------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------

func _init_visited_grid() -> void:
	_visited_grid.resize(grid_resolution)
	for x in range(grid_resolution):
		_visited_grid[x] = []
		_visited_grid[x].resize(grid_resolution)
		for z in range(grid_resolution):
			_visited_grid[x][z] = false


func _create_creature_mesh() -> void:
	_creature_mesh = SphereMesh.new()
	_creature_mesh.radius = 0.03
	_creature_mesh.height = 0.06
	_creature_mesh.radial_segments = 8
	_creature_mesh.rings = 4


func _create_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.mesh = _creature_mesh
	_multimesh.instance_count = max_population

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.multimesh = _multimesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.3
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)

	# Hide all instances initially
	for i in range(max_population):
		var xf := Transform3D.IDENTITY
		xf.origin = Vector3(0, -100, 0)  # Off-screen
		_multimesh.set_instance_transform(i, xf)
		_multimesh.set_instance_color(i, Color.TRANSPARENT)


func _spawn_initial_population() -> void:
	for i in range(initial_population):
		_spawn_creature(
			Vector3(
				_rng.randf_range(-world_size * 0.4, world_size * 0.4),
				0.03,
				_rng.randf_range(-world_size * 0.4, world_size * 0.4)
			),
			Color(_rng.randf_range(0.3, 1.0), _rng.randf_range(0.3, 1.0), _rng.randf_range(0.3, 1.0)),
			_rng.randf_range(0.02, 0.05),  # size
			_rng.randf_range(0.1, 0.4),     # speed
			1.5  # starting energy
		)


func _spawn_creature(pos: Vector3, col: Color, creature_size: float, speed: float, energy: float) -> void:
	if _creatures.size() >= max_population:
		return
	var creature := {
		"position": pos,
		"color": col,
		"size": creature_size,
		"speed": speed,
		"energy": energy,
		"direction": Vector3(
			_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)
		).normalized(),
		"age": 0.0,
		"generation": _generation_count
	}
	_creatures.append(creature)
	_total_born += 1


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Non-Teleological Evolution"
	_title_label.font_size = 20
	_title_label.modulate = Color(0.9, 0.85, 0.7)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, 0.7, 0)
	_title_label.pixel_size = 0.001
	add_child(_title_label)

	_no_fitness_label = Label3D.new()
	_no_fitness_label.text = "No fitness function. No goal. Just drift."
	_no_fitness_label.font_size = 14
	_no_fitness_label.modulate = Color(0.7, 0.6, 0.5, 0.8)
	_no_fitness_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_no_fitness_label.position = Vector3(0, 0.62, 0)
	_no_fitness_label.pixel_size = 0.001
	add_child(_no_fitness_label)

	_stats_label = Label3D.new()
	_stats_label.text = ""
	_stats_label.font_size = 14
	_stats_label.modulate = Color(0.8, 0.8, 0.75)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.position = Vector3(0, 0.54, 0)
	_stats_label.pixel_size = 0.001
	add_child(_stats_label)


func _create_ground_plane() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(world_size, world_size)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.09, 0.1)
	mat.metallic = 0.3
	mat.roughness = 0.8
	mi.material_override = mat
	add_child(mi)


# ------------------------------------------------------------------
# Simulation loop
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	_time_elapsed += delta

	# Update each creature
	var to_remove: Array[int] = []
	var to_spawn: Array = []

	for i in range(_creatures.size()):
		var c = _creatures[i]

		# Move
		c["age"] += delta
		var wander_angle := _rng.randf_range(-0.5, 0.5)
		var dir: Vector3 = c["direction"]
		dir = dir.rotated(Vector3.UP, wander_angle).normalized()
		c["direction"] = dir
		c["position"] += dir * c["speed"] * delta

		# Wrap around world
		var p: Vector3 = c["position"]
		var half := world_size * 0.5
		if p.x > half: p.x = -half
		if p.x < -half: p.x = half
		if p.z > half: p.z = -half
		if p.z < -half: p.z = half
		c["position"] = p

		# Check visited grid — gain energy from exploration
		var gx := int((p.x + half) / world_size * grid_resolution)
		var gz := int((p.z + half) / world_size * grid_resolution)
		gx = clampi(gx, 0, grid_resolution - 1)
		gz = clampi(gz, 0, grid_resolution - 1)
		if not _visited_grid[gx][gz]:
			_visited_grid[gx][gz] = true
			c["energy"] += energy_from_exploration

		# Lose energy by existing
		c["energy"] -= energy_decay * delta

		# Die if no energy
		if c["energy"] <= 0:
			to_remove.append(i)
			_total_died += 1
			continue

		# Reproduce if enough energy
		if c["energy"] > reproduction_threshold and _creatures.size() + to_spawn.size() < max_population:
			c["energy"] *= 0.5  # Split energy
			var child_color := Color(
				clampf(c["color"].r + _rng.randf_range(-mutation_strength, mutation_strength), 0.1, 1.0),
				clampf(c["color"].g + _rng.randf_range(-mutation_strength, mutation_strength), 0.1, 1.0),
				clampf(c["color"].b + _rng.randf_range(-mutation_strength, mutation_strength), 0.1, 1.0)
			)
			var child_size := clampf(
				c["size"] + _rng.randf_range(-0.005, 0.005), 0.01, 0.08
			)
			var child_speed := clampf(
				c["speed"] + _rng.randf_range(-0.05, 0.05), 0.05, 0.6
			)
			to_spawn.append({
				"pos": c["position"] + Vector3(_rng.randf_range(-0.05, 0.05), 0, _rng.randf_range(-0.05, 0.05)),
				"color": child_color,
				"size": child_size,
				"speed": child_speed,
				"energy": c["energy"]
			})
			_generation_count += 1

	# Remove dead creatures (reverse order)
	to_remove.sort()
	to_remove.reverse()
	for idx in to_remove:
		_creatures.remove_at(idx)

	# Spawn children
	for child_data in to_spawn:
		_spawn_creature(
			child_data["pos"], child_data["color"],
			child_data["size"], child_data["speed"], child_data["energy"]
		)

	# Slowly regenerate visited grid (areas become explorable again)
	if Engine.get_frames_drawn() % 120 == 0:
		var rx := _rng.randi_range(0, grid_resolution - 1)
		var rz := _rng.randi_range(0, grid_resolution - 1)
		_visited_grid[rx][rz] = false

	# Update visuals
	_update_multimesh()
	_update_stats()


func _update_multimesh() -> void:
	for i in range(max_population):
		if i < _creatures.size():
			var c = _creatures[i]
			var xf := Transform3D.IDENTITY
			var s: float = c["size"] / 0.03  # Normalize to base mesh size
			xf = xf.scaled(Vector3(s, s, s))
			xf.origin = c["position"]
			_multimesh.set_instance_transform(i, xf)
			var col: Color = c["color"]
			col.a = clampf(c["energy"] / reproduction_threshold, 0.3, 1.0)
			_multimesh.set_instance_color(i, col)
		else:
			var xf := Transform3D.IDENTITY
			xf.origin = Vector3(0, -100, 0)
			_multimesh.set_instance_transform(i, xf)
			_multimesh.set_instance_color(i, Color.TRANSPARENT)


func _update_stats() -> void:
	# Count unique "species" by color clustering (rough hue binning)
	var hue_bins: Dictionary = {}
	for c in _creatures:
		var hue_bin := int(c["color"].h * 12)
		hue_bins[hue_bin] = hue_bins.get(hue_bin, 0) + 1
	var diversity := hue_bins.size()
	if diversity > _max_species_diversity:
		_max_species_diversity = diversity

	_stats_label.text = "Pop: %d  |  Diversity: %d  |  Born: %d  |  Died: %d  |  Gen: %d" % [
		_creatures.size(), diversity, _total_born, _total_died, _generation_count
	]
