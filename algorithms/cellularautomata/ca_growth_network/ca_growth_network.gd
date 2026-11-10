@tool
extends Node3D

# @identity
# essence: growth_tip += attractor_force / distance^2, with stochastic branching
# desire: To reach — tendrils seeking invisible attractors, branching when the signal is ambiguous
# critical_parameter: attractor_strength — how powerfully distant goals bend the growth direction
# triggers: Many attractors → dense bush; few → sparse reaching arms; high branch_probability → fractal explosion
# emerges: Root-like, vascular networks from simple force-toward-goal logic — no branching pattern was specified
# needs: VR attractor controls [missing], growth speed slider [missing]
# relationships: Contrasts with line_network_ca (random vs directed growth). Feeds into CA_BeyondBinary.
# truth: Growth toward a goal, with noise, is enough to produce every vascular pattern in nature.

# Growth CA with Attractors - Organic root/slime network growth
# Grows from seed points toward attractors, creating branching networks

@export_category("Grid Settings")
@export var grid_size: int = 32
@export var cell_size: float = 0.2
@export var center_obstacle_size: int = 8  # Size of central cube obstacle

@export_category("Growth Settings")
@export var seed_count: int = 4  # Number of starting seed points
@export var attractor_count: int = 8  # Number of attractor points
@export var attractor_strength: float = 2.0
@export var growth_probability: float = 0.3
@export var branch_probability: float = 0.15
@export var max_growth_distance: float = 20.0
@export var avoid_self_intersection: bool = true

@export_category("Simulation")
@export var generation_interval: float = 0.1
@export var auto_play: bool = true
@export var max_generations: int = 150

@export_category("Visuals")
@export var gradient: Gradient
@export var color_seed: Color = Color(0.4, 0.2, 0.1)
@export var color_branch: Color = Color(0.2, 0.6, 0.3)
@export var color_tip: Color = Color(0.3, 0.8, 0.4)

# 2026-11-10. What the network grows from and toward, made visible; and a network that keeps growing.
@export_category("Growth Repairs")
## A tip whose growth roll fails WAITS and tries again; it dies after this many failed tries in a row. The tip was
## dropped on the first failure (growth_probability 0.35), so the whole network died out within a few steps.
@export_range(1, 30) var tip_patience: int = 8
## An attractor a tip reaches is used up and lights; growth moves on to the next. (They pulled forever.)
@export var consume_attractors: bool = true
@export var show_core: bool = true          # the obstacle the network wraps, drawn (it was invisible)
@export var show_attractors: bool = true    # the goals, faint until reached
@export var cycle: bool = true              # after the last generation, hold, then grow a new one
@export_range(0.0, 30.0, 0.5) var hold_seconds: float = 4.0

var grid: Dictionary = {}  # Vector3i -> cell_data {age: int, is_tip: bool, attractors_reached: Array}
var attractors: Array[Vector3] = []  # World positions of attractors
var seeds: Array[Vector3i] = []  # Grid positions of seeds
var active_tips: Array[Vector3i] = []  # Current growth tips
var generation: int = 0
var timer: float = 0.0
var is_growing: bool = false

var multi_mesh_instance: MultiMeshInstance3D
var _core: MeshInstance3D
var _goal_marks: MultiMeshInstance3D
var _reached: Array[bool] = []
var _hold := 0.0

func _ready() -> void:
	# Try to get existing MultiMeshInstance3D node, or create one
	if has_node("MultiMeshInstance3D"):
		multi_mesh_instance = get_node("MultiMeshInstance3D")
		_colour_cells()
	else:
		_setup_multimesh()

	if not gradient:
		_setup_default_gradient()

	if auto_play and not Engine.is_editor_hint():
		start_growth()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if is_growing:
		timer += delta
		if timer >= generation_interval:
			timer = 0.0
			grow_step()
	elif cycle and generation > 0:
		_hold += delta
		if _hold >= hold_seconds:
			start_growth()

func _setup_multimesh() -> void:
	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.name = "MultiMeshInstance3D"
	add_child(multi_mesh_instance)

	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BoxMesh.new()
	multimesh.mesh.size = Vector3(cell_size, cell_size, cell_size) * 0.9
	multimesh.use_colors = true
	multimesh.instance_count = 0
	multi_mesh_instance.multimesh = multimesh
	_colour_cells()

func _colour_cells() -> void:
	# The per-cell colours (seed, branch by age, tip) were written to the MultiMesh and never shown: the
	# material did not read them, so every cell stood grey.
	if multi_mesh_instance == null:
		return
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.6
	multi_mesh_instance.material_override = mat

func _setup_default_gradient() -> void:
	gradient = Gradient.new()
	# Default gradient has 2 points at 0.0 and 1.0
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, color_seed)
	gradient.set_offset(1, 1.0)
	gradient.set_color(1, color_tip)
	gradient.add_point(0.5, color_branch)

func start_growth() -> void:
	generation = 0
	grid.clear()
	active_tips.clear()
	seeds.clear()
	attractors.clear()

	# Create central cube obstacle
	_create_obstacle()

	# Place attractors around the obstacle
	_place_attractors()

	# Place seeds on obstacle surface
	_place_seeds()

	_hold = 0.0
	_reached.clear()
	for i in attractors.size():
		_reached.append(false)
	if not Engine.is_editor_hint():
		_build_core_and_goals()
	is_growing = true
	_update_multimesh()

func _create_obstacle() -> void:
	# Create a cube in the center as an obstacle
	var half_size = center_obstacle_size / 2
	var center = grid_size / 2

	for x in range(-half_size, half_size):
		for y in range(-half_size, half_size):
			for z in range(-half_size, half_size):
				var pos = Vector3i(center + x, center + y, center + z)
				grid[pos] = {
					"age": -1,  # -1 means obstacle
					"is_tip": false,
					"attractors_reached": []
				}

func _place_attractors() -> void:
	# Place attractors in a sphere around the central obstacle
	var center = Vector3(grid_size / 2.0, grid_size / 2.0, grid_size / 2.0)
	var radius = grid_size * 0.4

	for i in range(attractor_count):
		var angle1 = randf() * TAU
		var angle2 = randf() * PI
		var r = radius * (0.7 + randf() * 0.3)

		var x = center.x + r * sin(angle2) * cos(angle1)
		var y = center.y + r * sin(angle2) * sin(angle1)
		var z = center.z + r * cos(angle2)

		# Grid units -> the world units every growth step measures in. They were left in grid units: centred
		# on (16, 16, 16) "metres", 27 m from every tip and past max_growth_distance, so no attractor ever
		# pulled and every direction was random.
		var offset := grid_size / 2.0
		attractors.append(Vector3(x - offset, y - offset, z - offset) * cell_size)

func _place_seeds() -> void:
	# Place seeds on the surface of the obstacle cube
	var half_size = center_obstacle_size / 2
	var center = grid_size / 2

	for i in range(seed_count):
		var face = randi() % 6
		var u = randi_range(-half_size + 1, half_size - 1)
		var v = randi_range(-half_size + 1, half_size - 1)

		var pos: Vector3i
		match face:
			0: pos = Vector3i(center + half_size, center + u, center + v)  # +X
			1: pos = Vector3i(center - half_size - 1, center + u, center + v)  # -X
			2: pos = Vector3i(center + u, center + half_size, center + v)  # +Y
			3: pos = Vector3i(center + u, center - half_size - 1, center + v)  # -Y
			4: pos = Vector3i(center + u, center + v, center + half_size)  # +Z
			_: pos = Vector3i(center + u, center + v, center - half_size - 1)  # -Z

		if not grid.has(pos):
			grid[pos] = {
				"age": 0,
				"is_tip": true,
				"attractors_reached": []
			}
			active_tips.append(pos)
			seeds.append(pos)

func grow_step() -> void:
	if generation >= max_generations or active_tips.is_empty():
		is_growing = false
		return

	var new_tips: Array[Vector3i] = []

	# Each active tip tries to grow
	for tip_pos in active_tips:
		if not grid.has(tip_pos):
			continue

		var cell = grid[tip_pos]
		if not cell.is_tip:
			continue

		# Find best direction based on attractors - the best FREE one. The single strongest axis was often
		# blocked (the pull of goals all round the core points straight through it), and a blocked tip only
		# waited and died.
		var best_dir = _free_growth_direction(tip_pos)
		var grew := false

		if best_dir != Vector3i.ZERO:
			var new_pos = tip_pos + best_dir

			# Check if we can grow here
			if _can_grow_at(new_pos, tip_pos):
				grew = true
				# Grow
				grid[new_pos] = {
					"age": generation,
					"is_tip": true,
					"attractors_reached": []
				}
				new_tips.append(new_pos)

				# Current tip is no longer a tip
				grid[tip_pos].is_tip = false

				# Branching: sometimes create additional growth points
				if randf() < branch_probability:
					var branch_dir = _find_alternative_direction(tip_pos, best_dir)
					if branch_dir != Vector3i.ZERO:
						var branch_pos = tip_pos + branch_dir
						if _can_grow_at(branch_pos, tip_pos):
							grid[branch_pos] = {
								"age": generation,
								"is_tip": true,
								"attractors_reached": []
							}
							new_tips.append(branch_pos)

		if not grew:
			# A failed roll is a pause, not a death: wait, try again, give up after tip_patience tries.
			cell["tries"] = int(cell.get("tries", 0)) + 1
			if cell.tries < tip_patience:
				new_tips.append(tip_pos)
			else:
				cell.is_tip = false
		elif consume_attractors:
			_consume_near(tip_pos + best_dir)

	active_tips = new_tips
	generation += 1
	_update_multimesh()

func _free_growth_direction(pos: Vector3i) -> Vector3i:
	var want := _attractor_force(pos)
	var aim := want.normalized() if want.length() > 0.0001 else Vector3.ZERO
	var best := Vector3i.ZERO
	var best_score := -INF
	for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
		var n := pos + d
		if not _room_at(n, pos):
			continue
		var score := aim.dot(Vector3(d)) + randf() * 0.6
		if score > best_score:
			best_score = score
			best = d
	return best

func _attractor_force(pos: Vector3i) -> Vector3:
	var world_pos := _grid_to_world(pos)
	var total := Vector3.ZERO
	for ai in attractors.size():
		if consume_attractors and ai < _reached.size() and _reached[ai]:
			continue
		var dist := world_pos.distance_to(attractors[ai])
		if dist < max_growth_distance and dist > 0.1:
			total += (attractors[ai] - world_pos).normalized() * attractor_strength / (dist * dist + 1.0)
	return total

func _find_best_growth_direction(pos: Vector3i) -> Vector3i:
	# Calculate weighted direction toward nearest attractors
	var world_pos = _grid_to_world(pos)
	var total_force = Vector3.ZERO
	var valid_attractors = 0

	for ai in attractors.size():
		if consume_attractors and ai < _reached.size() and _reached[ai]:
			continue
		var attractor: Vector3 = attractors[ai]
		var dist = world_pos.distance_to(attractor)

		# Only consider attractors within range
		if dist < max_growth_distance and dist > 0.1:
			var direction = (attractor - world_pos).normalized()
			var strength = attractor_strength / (dist * dist + 1.0)
			total_force += direction * strength
			valid_attractors += 1

	if valid_attractors == 0 or total_force.length() < 0.01:
		# Random direction if no attractors in range
		return _random_direction()

	# Convert force to discrete direction
	return _vector_to_direction(total_force)

func _find_alternative_direction(_pos: Vector3i, avoid_dir: Vector3i) -> Vector3i:
	# Find a direction different from avoid_dir for branching
	var directions = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]

	directions.shuffle()

	for dir in directions:
		if dir != avoid_dir and dir != -avoid_dir:
			return dir

	return Vector3i.ZERO

func _vector_to_direction(v: Vector3) -> Vector3i:
	# Convert a continuous vector to the strongest discrete direction
	var abs_v = Vector3(abs(v.x), abs(v.y), abs(v.z))

	if abs_v.x > abs_v.y and abs_v.x > abs_v.z:
		return Vector3i(1 if v.x > 0 else -1, 0, 0)
	elif abs_v.y > abs_v.z:
		return Vector3i(0, 1 if v.y > 0 else -1, 0)
	else:
		return Vector3i(0, 0, 1 if v.z > 0 else -1)

func _random_direction() -> Vector3i:
	var directions = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	return directions[randi() % directions.size()]

func _can_grow_at(pos: Vector3i, from_pos: Vector3i) -> bool:
	# Check bounds
	if pos.x < 0 or pos.x >= grid_size or \
	   pos.y < 0 or pos.y >= grid_size or \
	   pos.z < 0 or pos.z >= grid_size:
		return false

	# Check if already occupied
	if grid.has(pos):
		return false

	# Optionally avoid growing too close to existing cells (except parent)
	if avoid_self_intersection:
		var neighbor_count = 0
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					if dx == 0 and dy == 0 and dz == 0:
						continue
					var neighbor = pos + Vector3i(dx, dy, dz)
					# The core is not part of the clump: counting its cells refused every step along its face.
					if neighbor != from_pos and grid.has(neighbor) and grid[neighbor].age >= 0:
						neighbor_count += 1

		# Don't grow if too many neighbors (prevents thick clumps)
		if neighbor_count > 3:
			return false

	return randf() < growth_probability

## The structural half of _can_grow_at, without the growth roll: is there room at pos?
func _room_at(pos: Vector3i, from_pos: Vector3i) -> bool:
	if pos.x < 0 or pos.x >= grid_size or pos.y < 0 or pos.y >= grid_size or pos.z < 0 or pos.z >= grid_size or grid.has(pos):
		return false
	if not avoid_self_intersection:
		return true
	var neighbor_count := 0
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var neighbor: Vector3i = pos + Vector3i(dx, dy, dz)
				if neighbor != pos and neighbor != from_pos and grid.has(neighbor) and grid[neighbor].age >= 0:
					neighbor_count += 1
	return neighbor_count <= 3

func _grid_to_world(pos: Vector3i) -> Vector3:
	var offset = grid_size / 2.0
	return Vector3(
		(pos.x - offset) * cell_size,
		(pos.y - offset) * cell_size,
		(pos.z - offset) * cell_size
	)

func _update_multimesh() -> void:
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return

	var mm = multi_mesh_instance.multimesh
	var cells = []

	# Collect all non-obstacle cells
	for pos in grid.keys():
		var cell = grid[pos]
		if cell.age >= 0:  # Skip obstacles
			cells.append(pos)

	mm.instance_count = cells.size()

	var idx = 0
	for pos in cells:
		var cell = grid[pos]
		var world_pos = _grid_to_world(pos)

		var t = Transform3D(Basis(), world_pos)
		mm.set_instance_transform(idx, t)

		# Color based on age and whether it's a tip
		var color: Color
		if cell.is_tip:
			color = color_tip
		elif cell.age == 0:
			color = color_seed
		else:
			var ratio = float(cell.age) / float(max(generation, 1))
			color = gradient.sample(ratio)

		mm.set_instance_color(idx, color)
		idx += 1

func _consume_near(pos: Vector3i) -> void:
	var w := _grid_to_world(pos)
	for ai in attractors.size():
		if ai < _reached.size() and not _reached[ai] and w.distance_to(attractors[ai]) < cell_size * 2.5:
			_reached[ai] = true
			if _goal_marks and _goal_marks.multimesh:
				_goal_marks.multimesh.set_instance_color(ai, Color(1.0, 0.85, 0.35))

func _build_core_and_goals() -> void:
	var side := center_obstacle_size * cell_size
	# The core's cells span [-half, half) around the grid centre, a half cell off the world centre.
	var core_centre := _grid_to_world(Vector3i(grid_size / 2, grid_size / 2, grid_size / 2)) - Vector3.ONE * cell_size * 0.5
	if show_core:
		if _core == null:
			_core = MeshInstance3D.new()
			_core.name = "Core"
			add_child(_core)
			var box := BoxMesh.new()
			_core.mesh = box
			var cm := StandardMaterial3D.new()
			cm.albedo_color = Color(0.16, 0.12, 0.1)
			cm.roughness = 0.9
			_core.material_override = cm
		(_core.mesh as BoxMesh).size = Vector3.ONE * side * 0.98
		_core.position = core_centre
	if show_attractors:
		if _goal_marks == null:
			_goal_marks = MultiMeshInstance3D.new()
			_goal_marks.name = "Attractors"
			add_child(_goal_marks)
			var gm := StandardMaterial3D.new()
			gm.vertex_color_use_as_albedo = true
			gm.vertex_color_is_srgb = true
			gm.emission_enabled = true
			gm.emission = Color(0.6, 0.5, 0.25)
			gm.emission_energy_multiplier = 0.6
			_goal_marks.material_override = gm
			_goal_marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		var sm := SphereMesh.new()
		sm.radius = cell_size * 0.45
		sm.height = cell_size * 0.9
		sm.radial_segments = 10
		sm.rings = 5
		mm.mesh = sm
		mm.instance_count = attractors.size()
		for ai in attractors.size():
			mm.set_instance_transform(ai, Transform3D(Basis(), attractors[ai]))
			mm.set_instance_color(ai, Color(0.35, 0.33, 0.3))
		_goal_marks.multimesh = mm

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("cycle"):
		cycle = str(config.cycle).to_lower() in ["true", "1", "on"]
	if config.has("show_attractors"):
		show_attractors = str(config.show_attractors).to_lower() in ["true", "1", "on"]
