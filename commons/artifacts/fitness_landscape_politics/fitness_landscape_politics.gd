# fitness_landscape_politics.gd
# Same swarm, switchable fitness landscapes. Reveals that "optimal" is a political choice.
#
# @identity
# essence: 30 PSO particles on 3 switchable fitness landscapes — convergence (corporate), spread (ecological), novelty (artistic) — same agents, different power structures
# desire: to make the learner feel the moment the swarm reorganizes when you switch landscapes, and realize that "optimal" was never neutral
# critical_parameter: landscape_mode — switching it does not change the particles, only what counts as success, and the swarm obeys
# triggers: pressing CONVERGE makes the swarm collapse to center; pressing SPREAD makes it explode outward; pressing NOVELTY makes it seek edges and gaps
# emerges: the transition animations between landscapes — particles hesitate, reorient, sometimes oscillate before committing to the new definition of success
# needs: [has] three landscape buttons via ArtifactControls; [has] inertia slider; [has] terrain recolor; [missing] no history trace; no fitness graph
# relationships: placed in SwarmIntelligence_Particle_Swarm_Optimization alongside self_organizing_patterns; responds to the critical.md question "whose fitness function?"
# truth: the swarm always optimizes — the question is never whether to optimize but who wrote the objective function

extends Node3D

class_name FitnessLandscapePolitics

enum Landscape { CONVERGE, SPREAD, NOVELTY }

## Number of particles in the swarm
@export_range(10, 60) var particle_count: int = 30

## Current fitness landscape
@export var current_landscape: Landscape = Landscape.CONVERGE

## PSO inertia weight (0=reactive, 1=stubborn)
@export_range(0.0, 1.0, 0.05) var inertia: float = 0.6:
	set(value):
		inertia = clampf(value, 0.0, 1.0)

## Arena size in meters
@export var arena_size: float = 3.0

# Internal state
var _particles: Array[Dictionary] = []  # {pos, vel, best_pos, best_fitness}
var _global_best_pos: Vector3 = Vector3.ZERO
var _global_best_fitness: float = -INF
var _multi_mesh_instance: MultiMeshInstance3D
var _multi_mesh: MultiMesh
var _terrain_mesh: MeshInstance3D
var _terrain_im: ImmediateMesh
var _controls: Node
var _landscape_label: Label3D
var _novelty_archive: Array[Vector3] = []  # for novelty search
var _time: float = 0.0

const COGNITIVE_WEIGHT := 1.5
const SOCIAL_WEIGHT := 1.5
const MAX_SPEED := 2.0
const TERRAIN_RES := 32


func _ready() -> void:
	_build_terrain()
	_build_particles()
	_build_controls()
	_build_labels()
	_init_swarm()
	_color_terrain()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	_time += delta
	_update_swarm(delta)
	_update_multimesh()


# ── Terrain ─────────────────────────────────────────────────

func _build_terrain() -> void:
	_terrain_im = ImmediateMesh.new()
	_terrain_mesh = MeshInstance3D.new()
	_terrain_mesh.name = "Terrain"
	_terrain_mesh.mesh = _terrain_im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_terrain_mesh.material_override = mat
	_terrain_mesh.position = Vector3(0, -0.05, 0)
	add_child(_terrain_mesh)


func _color_terrain() -> void:
	_terrain_im.clear_surfaces()
	_terrain_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var half := arena_size * 0.5
	var step := arena_size / float(TERRAIN_RES)

	for ix in range(TERRAIN_RES):
		for iz in range(TERRAIN_RES):
			var x0 := -half + ix * step
			var z0 := -half + iz * step
			var x1 := x0 + step
			var z1 := z0 + step

			# Fitness at corners
			var f00 := _terrain_fitness(Vector3(x0, 0, z0))
			var f10 := _terrain_fitness(Vector3(x1, 0, z0))
			var f01 := _terrain_fitness(Vector3(x0, 0, z1))
			var f11 := _terrain_fitness(Vector3(x1, 0, z1))

			# Triangle 1
			_terrain_im.surface_set_color(_fitness_color(f00))
			_terrain_im.surface_add_vertex(Vector3(x0, 0, z0))
			_terrain_im.surface_set_color(_fitness_color(f10))
			_terrain_im.surface_add_vertex(Vector3(x1, 0, z0))
			_terrain_im.surface_set_color(_fitness_color(f01))
			_terrain_im.surface_add_vertex(Vector3(x0, 0, z1))

			# Triangle 2
			_terrain_im.surface_set_color(_fitness_color(f10))
			_terrain_im.surface_add_vertex(Vector3(x1, 0, z0))
			_terrain_im.surface_set_color(_fitness_color(f11))
			_terrain_im.surface_add_vertex(Vector3(x1, 0, z1))
			_terrain_im.surface_set_color(_fitness_color(f01))
			_terrain_im.surface_add_vertex(Vector3(x0, 0, z1))

	_terrain_im.surface_end()


func _terrain_fitness(pos: Vector3) -> float:
	# Normalized 0-1 fitness for terrain coloring
	match current_landscape:
		Landscape.CONVERGE:
			var d := Vector2(pos.x, pos.z).length()
			return clampf(1.0 - d / (arena_size * 0.5), 0.0, 1.0)
		Landscape.SPREAD:
			var d := Vector2(pos.x, pos.z).length()
			return clampf(d / (arena_size * 0.5), 0.0, 1.0)
		Landscape.NOVELTY:
			# Edges and corners score higher
			var edge_x := absf(pos.x) / (arena_size * 0.5)
			var edge_z := absf(pos.z) / (arena_size * 0.5)
			return clampf(maxf(edge_x, edge_z), 0.0, 1.0)
	return 0.0


func _fitness_color(f: float) -> Color:
	# Low fitness = dark blue, high fitness = bright yellow
	var c := Color(0.1, 0.1, 0.3, 0.5).lerp(Color(1.0, 0.9, 0.2, 0.6), f)
	return c


# ── Particles ───────────────────────────────────────────────

func _build_particles() -> void:
	_multi_mesh = MultiMesh.new()
	_multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_multi_mesh.use_colors = true
	_multi_mesh.instance_count = particle_count

	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	sphere.radial_segments = 8
	sphere.rings = 4
	_multi_mesh.mesh = sphere

	_multi_mesh_instance = MultiMeshInstance3D.new()
	_multi_mesh_instance.name = "Particles"
	_multi_mesh_instance.multimesh = _multi_mesh

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	_multi_mesh_instance.material_override = mat

	add_child(_multi_mesh_instance)


func _init_swarm() -> void:
	_particles.clear()
	_global_best_fitness = -INF
	_novelty_archive.clear()

	var half := arena_size * 0.4
	for i in range(particle_count):
		var pos := Vector3(
			randf_range(-half, half),
			0.15,
			randf_range(-half, half)
		)
		var vel := Vector3(
			randf_range(-0.5, 0.5),
			0,
			randf_range(-0.5, 0.5)
		)
		var fit := _evaluate_fitness(pos)
		_particles.append({
			"pos": pos,
			"vel": vel,
			"best_pos": pos,
			"best_fitness": fit,
		})
		if fit > _global_best_fitness:
			_global_best_fitness = fit
			_global_best_pos = pos


func _evaluate_fitness(pos: Vector3) -> float:
	match current_landscape:
		Landscape.CONVERGE:
			# Minimize distance to center = maximize negative distance
			return -Vector2(pos.x, pos.z).length()
		Landscape.SPREAD:
			# Maximize distance from center
			return Vector2(pos.x, pos.z).length()
		Landscape.NOVELTY:
			# Maximize distance from nearest archived point
			if _novelty_archive.is_empty():
				return 10.0
			var min_dist := INF
			for archived in _novelty_archive:
				var d := pos.distance_to(archived)
				if d < min_dist:
					min_dist = d
			return min_dist
	return 0.0


func _update_swarm(delta: float) -> void:
	var half := arena_size * 0.5

	for p in _particles:
		var r1 := randf()
		var r2 := randf()

		# PSO velocity update
		var cognitive: Vector3 = COGNITIVE_WEIGHT * r1 * (p["best_pos"] - p["pos"])
		var social: Vector3 = SOCIAL_WEIGHT * r2 * (_global_best_pos - p["pos"])
		p["vel"] = inertia * p["vel"] + cognitive + social

		# Clamp speed
		var spd: float = p["vel"].length()
		if spd > MAX_SPEED:
			p["vel"] = p["vel"] / spd * MAX_SPEED

		# Keep on XZ plane
		p["vel"].y = 0

		# Move
		p["pos"] += p["vel"] * delta
		p["pos"].y = 0.15

		# Boundary wrap
		p["pos"].x = wrapf(p["pos"].x, -half, half)
		p["pos"].z = wrapf(p["pos"].z, -half, half)

		# Evaluate
		var fit := _evaluate_fitness(p["pos"])
		if fit > p["best_fitness"]:
			p["best_fitness"] = fit
			p["best_pos"] = p["pos"]
		if fit > _global_best_fitness:
			_global_best_fitness = fit
			_global_best_pos = p["pos"]

	# For novelty search, periodically archive positions
	if current_landscape == Landscape.NOVELTY:
		if Engine.get_frames_drawn() % 30 == 0 and _particles.size() > 0:
			var rand_p: Dictionary = _particles[randi() % _particles.size()]
			_novelty_archive.append(rand_p["pos"])
			if _novelty_archive.size() > 200:
				_novelty_archive.pop_front()


func _update_multimesh() -> void:
	for i in range(min(particle_count, _particles.size())):
		var p: Dictionary = _particles[i]
		var t := Transform3D()
		t.origin = p["pos"]
		_multi_mesh.set_instance_transform(i, t)

		# Color by fitness
		var fit := _evaluate_fitness(p["pos"])
		var norm_fit := clampf(remap(fit, -arena_size, arena_size, 0.0, 1.0), 0.0, 1.0)
		var col: Color
		match current_landscape:
			Landscape.CONVERGE:
				col = Color(0.2, 0.4, 1.0).lerp(Color(1.0, 1.0, 0.2), norm_fit)
			Landscape.SPREAD:
				col = Color(0.2, 0.6, 0.2).lerp(Color(0.1, 1.0, 0.4), norm_fit)
			Landscape.NOVELTY:
				col = Color(0.6, 0.1, 0.6).lerp(Color(1.0, 0.5, 1.0), norm_fit)
			_:
				col = Color.WHITE
		_multi_mesh.set_instance_color(i, col)


# ── Controls ────────────────────────────────────────────────

func _build_controls() -> void:
	_controls = ArtifactControls.new()
	_controls.name = "Controls"
	_controls.position = Vector3(2.2, 1.2, 0.0)
	add_child(_controls)

	_controls.add_button("CONVERGE", func():
		_switch_landscape(Landscape.CONVERGE)
	)
	_controls.add_button("SPREAD", func():
		_switch_landscape(Landscape.SPREAD)
	)
	_controls.add_button("NOVELTY", func():
		_switch_landscape(Landscape.NOVELTY)
	)
	_controls.add_slider("INERTIA", inertia, func(v: float):
		inertia = v
	)


func _build_labels() -> void:
	_landscape_label = Label3D.new()
	_landscape_label.name = "LandscapeLabel"
	_landscape_label.font_size = 36
	_landscape_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_landscape_label.position = Vector3(0, 2.0, 0)
	_landscape_label.modulate = Color(1, 1, 1, 0.9)
	add_child(_landscape_label)
	_update_landscape_label()

	var sub := Label3D.new()
	sub.name = "Subtitle"
	sub.text = "Same swarm. Different definition of success."
	sub.font_size = 20
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sub.position = Vector3(0, 1.8, 0)
	sub.modulate = Color(0.8, 0.8, 0.8, 0.7)
	add_child(sub)


func _switch_landscape(mode: Landscape) -> void:
	current_landscape = mode
	# Reset personal bests and global best for new landscape
	_global_best_fitness = -INF
	_novelty_archive.clear()
	for p in _particles:
		var fit := _evaluate_fitness(p["pos"])
		p["best_fitness"] = fit
		p["best_pos"] = p["pos"]
		if fit > _global_best_fitness:
			_global_best_fitness = fit
			_global_best_pos = p["pos"]
	_color_terrain()
	_update_landscape_label()


func _update_landscape_label() -> void:
	if not _landscape_label:
		return
	match current_landscape:
		Landscape.CONVERGE:
			_landscape_label.text = "CONVERGE — Corporate fitness\nMinimize distance to center. One answer."
			_landscape_label.modulate = Color(0.4, 0.6, 1.0, 0.9)
		Landscape.SPREAD:
			_landscape_label.text = "SPREAD — Ecological fitness\nMaximize diversity. Distance is value."
			_landscape_label.modulate = Color(0.3, 0.9, 0.4, 0.9)
		Landscape.NOVELTY:
			_landscape_label.text = "NOVELTY — Artistic fitness\nSeek the unvisited. Surprise is value."
			_landscape_label.modulate = Color(0.9, 0.5, 1.0, 0.9)
