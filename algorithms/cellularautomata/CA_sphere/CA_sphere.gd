extends Node3D

# @identity
# essence: vertex(t+1) = evolve(mode, neighbors) where mode in {CA, random_walk, hill_seeking}
# desire: To deform a sphere three different ways — watch topology warp under CA birth/death, random drift, and gravitational attraction
# critical_parameter: evolution_mode — switches between three fundamentally different deformation algorithms on the same mesh
# triggers: Mode switch → sphere resets and begins new deformation; iteration limit → evolution halts, form is frozen
# emerges: Organic, tumor-like growths on a sphere surface from vertex-level CA rules that know nothing about shape
# needs: VR mode selector [missing], iteration control [missing], keyboard input [has]
# relationships: Feeds into CA_SoftRules. Demonstrates CA on non-planar topology — contrasts with flat grid automata.
# truth: The same rules on a sphere produce forms no flat grid ever could — topology is a hidden variable.

# Multi-Algorithm Sphere Evolution System
# Three different approaches: Cellular Automata, Random Walk, Hill Seeking

@export_enum("Cellular_Automata", "Random_Walk", "Hill_Seeking") var evolution_mode: int = 0
@export var sphere_subdivisions: int = 3
@export var max_iterations: int = 20
@export var auto_evolve: bool = true   # was false: no placement ever started it, so every visitor met a still blue ball
@export var evolution_speed: float = 1.0

# The lattice (2026-11-10). "geodesic" (default): a subdivided icosahedron - every cell has six neighbours (twelve
# have five) and there is no seam. "uv": the original SphereMesh, whose seam and pole vertices are duplicated, so
# the automaton's lattice was torn along a meridian and pinched at the poles.
@export_enum("geodesic", "uv") var lattice: String = "geodesic"
# On a six-neighbour lattice Conway's B3/S23 settles into a still life within ~20 generations (measured on this
# sphere); hexagonal Life B2/S34 keeps moving for hundreds. The uv lattice keeps the ca_* rule below.
@export var geodesic_rule: String = "B2/S34"
@export_range(0.5, 12.0, 0.5) var geodesic_speed: float = 3.0     # generations a second
@export var geodesic_generations: int = 160                       # then a fresh soup
@export var cycle: bool = true                                     # after the last step, hold, then begin again
@export_range(0.0, 30.0, 0.5) var hold_seconds: float = 3.0

# Cellular Automata parameters
@export_group("Cellular Automata")
@export var ca_growth_rate: float = 0.15
@export var ca_survival_min: int = 2
@export var ca_survival_max: int = 3
@export var ca_birth_count: int = 3

# Random Walk parameters
@export_group("Random Walk")
@export var walk_step_size: float = 0.05
@export var walk_expansion_rate: float = 0.02
@export var walk_direction_change: float = 0.3

# Hill Seeking parameters
@export_group("Hill Seeking")
@export var hill_seek_strength: float = 0.08
@export var hill_seek_radius: float = 0.5
@export var hill_attraction_power: float = 2.0

# Mesh components
var mesh_instance: MeshInstance3D
var vertices: PackedVector3Array
var indices: PackedInt32Array
var original_positions: PackedVector3Array

# Algorithm-specific data
var vertex_states: Array[bool]
var vertex_neighbors: Array[Array]
var walker_positions: PackedVector3Array
var walker_directions: PackedVector3Array
var vertex_expansions: PackedFloat32Array
var hill_peaks: PackedVector3Array

# Evolution tracking
var current_iteration: int = 0
var evolution_timer: Timer
var is_evolving: bool = false
var sphere_material: StandardMaterial3D

# geodesic lattice
var _geo := false
var _birth := {}
var _survive := {}
var _age: PackedInt32Array
var _dead_for: PackedInt32Array
var _height: PackedFloat32Array
var _colors: PackedColorArray
const GEO_SLICES := 4
var _phase := -1                     # where a running generation is: rule slices, relief slices, mesh
var _state: PackedByteArray          # the geodesic automaton (vertex_states only seeds it)
var _next_state: PackedByteArray
var _palette: PackedColorArray
var _nb_start: PackedInt32Array
var _nb: PackedInt32Array
var _born_on: PackedByteArray
var _lives_on: PackedByteArray

func _ready() -> void:
	_geo = lattice == "geodesic" and evolution_mode == 0
	_parse_rule()
	setup_material()
	setup_mesh()
	generate_initial_sphere()
	build_neighbor_topology()
	initialize_algorithms()
	setup_evolution_timer()

func setup_material() -> void:
	sphere_material = StandardMaterial3D.new()
	sphere_material.albedo_color = Color.WHITE if _geo else Color(0.2, 0.6, 0.8, 1.0)
	sphere_material.vertex_color_use_as_albedo = _geo
	sphere_material.vertex_color_is_srgb = true
	sphere_material.metallic = 0.3
	sphere_material.roughness = 0.4
	sphere_material.emission_enabled = true
	sphere_material.emission = Color(0.1, 0.3, 0.4) * 0.2

func setup_mesh() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.material_override = sphere_material
	add_child(mesh_instance)

func setup_evolution_timer() -> void:
	evolution_timer = Timer.new()
	evolution_timer.wait_time = 1.0 / (geodesic_speed if _geo else evolution_speed)
	evolution_timer.timeout.connect(_on_evolution_step)
	add_child(evolution_timer)
	
	if auto_evolve:
		start_evolution()

func surface_get_arrays_from_mesh(mesh: Mesh) -> Array:
	var a: Array = []
	a.resize(Mesh.ARRAY_MAX)
	var s_arr: Array = mesh.surface_get_arrays(0)
	a[Mesh.ARRAY_VERTEX] = s_arr[Mesh.ARRAY_VERTEX]
	a[Mesh.ARRAY_INDEX] = s_arr[Mesh.ARRAY_INDEX]
	return a

func generate_initial_sphere() -> void:
	if _geo:
		_build_geodesic(sphere_subdivisions + 1)
		update_mesh()
		return
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.height = 2.0
	sphere_mesh.radial_segments = int(pow(2, sphere_subdivisions)) * 8
	sphere_mesh.rings = int(pow(2, sphere_subdivisions)) * 4
	
	var arrays = surface_get_arrays_from_mesh(sphere_mesh)
	vertices = arrays[Mesh.ARRAY_VERTEX]
	indices = arrays[Mesh.ARRAY_INDEX]
	original_positions = vertices.duplicate()
	
	update_mesh()

func build_neighbor_topology() -> void:
	var vertex_count = vertices.size()
	vertex_neighbors.clear()
	vertex_neighbors.resize(vertex_count)
	
	for i in range(vertex_count):
		vertex_neighbors[i] = []
	
	for i in range(0, indices.size(), 3):
		var v0 = indices[i]
		var v1 = indices[i + 1]
		var v2 = indices[i + 2]
		
		add_unique_neighbor(v0, v1)
		add_unique_neighbor(v0, v2)
		add_unique_neighbor(v1, v0)
		add_unique_neighbor(v1, v2)
		add_unique_neighbor(v2, v0)
		add_unique_neighbor(v2, v1)

func add_unique_neighbor(vertex: int, neighbor: int) -> void:
	if not vertex_neighbors[vertex].has(neighbor):
		vertex_neighbors[vertex].append(neighbor)

func initialize_algorithms() -> void:
	var vertex_count = vertices.size()
	
	vertex_states.clear()
	vertex_states.resize(vertex_count)
	for i in range(vertex_count):
		vertex_states[i] = randf() > 0.7
	
	walker_positions = original_positions.duplicate()
	walker_directions.clear()
	walker_directions.resize(vertex_count)
	vertex_expansions.clear()
	vertex_expansions.resize(vertex_count)
	
	for i in range(vertex_count):
		walker_directions[i] = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		vertex_expansions[i] = 0.0
	
	if _geo:
		_age = PackedInt32Array(); _age.resize(vertex_count)
		_dead_for = PackedInt32Array(); _dead_for.resize(vertex_count); _dead_for.fill(99)
		_height = PackedFloat32Array(); _height.resize(vertex_count)
		_colors = PackedColorArray(); _colors.resize(vertex_count)
		_geo_prepare()
		for i in range(vertex_count):
			_colors[i] = _palette[1] if _state[i] == 1 else _palette[13]

	hill_peaks.clear()
	var num_peaks = randi_range(3, 6)
	hill_peaks.resize(num_peaks)
	for i in range(num_peaks):
		hill_peaks[i] = Vector3(
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5)
		)

func evolve_cellular_automata() -> void:
	var new_states = vertex_states.duplicate()
	
	for i in range(vertices.size()):
		var alive_neighbors = count_alive_neighbors(i)
		var current_state = vertex_states[i]
		
		if current_state:
			new_states[i] = (alive_neighbors >= ca_survival_min and alive_neighbors <= ca_survival_max)
		else:
			new_states[i] = (alive_neighbors == ca_birth_count)
	
	vertex_states = new_states
	
	for i in range(vertices.size()):
		var original_pos = original_positions[i]
		var direction = original_pos.normalized()
		
		if vertex_states[i]:
			var growth = direction * ca_growth_rate * (1.0 + current_iteration * 0.05)
			vertices[i] = original_pos + growth
		else:
			var shrink = direction * ca_growth_rate * 0.2
			vertices[i] = original_pos - shrink
		
		var noise_offset = Vector3(
			randf_range(-0.01, 0.01),
			randf_range(-0.01, 0.01),
			randf_range(-0.01, 0.01)
		) * current_iteration * 0.05
		
		vertices[i] += noise_offset

func count_alive_neighbors(vertex_index: int) -> int:
	var count = 0
	for neighbor_idx in vertex_neighbors[vertex_index]:
		if vertex_states[neighbor_idx]:
			count += 1
	return count

func evolve_random_walk() -> void:
	for i in range(vertices.size()):
		var current_direction = walker_directions[i]
		var direction_change = Vector3(
			randf_range(-walk_direction_change, walk_direction_change),
			randf_range(-walk_direction_change, walk_direction_change),
			randf_range(-walk_direction_change, walk_direction_change)
		)
		
		walker_directions[i] = (current_direction + direction_change).normalized()
		walker_positions[i] += walker_directions[i] * walk_step_size
		vertex_expansions[i] += walk_expansion_rate
		
		var original_pos = original_positions[i]
		var expansion_direction = original_pos.normalized()
		var expansion = expansion_direction * vertex_expansions[i]
		var walk_offset = (walker_positions[i] - original_positions[i]) * 0.25
		
		vertices[i] = original_pos + expansion + walk_offset

func evolve_hill_seeking() -> void:
	for i in range(vertices.size()):
		var current_pos = vertices[i]
		var total_force = Vector3.ZERO
		var nearest_peak_distance = INF
		
		for peak in hill_peaks:
			var to_peak = peak - current_pos
			var distance = to_peak.length()
			
			if distance < nearest_peak_distance:
				nearest_peak_distance = distance
			
			if distance > 0.01 and distance < hill_seek_radius:
				var attraction = hill_seek_strength * pow(1.0 / distance, hill_attraction_power)
				total_force += to_peak.normalized() * attraction
		
		vertices[i] += total_force
		
		if nearest_peak_distance < hill_seek_radius:
			var expansion_factor = 1.0 - (nearest_peak_distance / hill_seek_radius)
			var radial_expansion = original_positions[i].normalized() * expansion_factor * 0.08
			vertices[i] += radial_expansion

func update_mesh() -> void:
	if _geo and _colors.size() == vertices.size():
		_update_geodesic_mesh()
		return
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Add vertices
	var coloured := _geo and _colors.size() == vertices.size()
	for i in range(vertices.size()):
		if coloured:
			st.set_color(_colors[i])
		st.add_vertex(vertices[i])
	
	# Add indices
	for idx in indices:
		st.add_index(idx)
	
	# Generate normals and commit
	st.generate_normals()
	mesh_instance.mesh = st.commit()

func start_evolution() -> void:
	if not is_evolving:
		is_evolving = true
		current_iteration = 0
		evolution_timer.start()
		
		var mode_names = ["Cellular Automata", "Random Walk", "Hill Seeking"]

func stop_evolution() -> void:
	if is_evolving:
		is_evolving = false
		evolution_timer.stop()

func reset_sphere() -> void:
	vertices = original_positions.duplicate()
	current_iteration = 0
	initialize_algorithms()
	update_mesh()
	sphere_material.albedo_color = Color.WHITE if _geo else Color(0.2, 0.6, 0.8, 1.0)

func single_evolution_step() -> void:
	if _geo:
		# The whole generation at once (a key press, a probe). The timer runs it a slice a frame instead.
		for ph in range(2 * GEO_SLICES + 1):
			_geo_phase(ph)
		_phase = -1
		_after_geo_step()
		return
	if current_iteration < max_iterations:
		match evolution_mode:
			0:
				evolve_cellular_automata()
			1:
				evolve_random_walk()
			2:
				evolve_hill_seeking()
		
		update_mesh()
		current_iteration += 1
		
		var progress = float(current_iteration) / max_iterations
		var colors = [Color.CYAN, Color.GREEN, Color.ORANGE]
		var target_color = colors[evolution_mode]
		sphere_material.albedo_color = Color.WHITE.lerp(target_color, progress * 0.7)
		
		
		if current_iteration >= max_iterations:
			stop_evolution()
			_begin_again()

func _on_evolution_step() -> void:
	if _geo:
		if _phase < 0:
			_phase = 0   # a generation, spread over the next frames
		return
	single_evolution_step()

func set_evolution_mode(mode: int) -> void:
	evolution_mode = mode
	reset_sphere()
	var mode_names = ["Cellular Automata", "Random Walk", "Hill Seeking"]

func _input(event: InputEvent) -> void:
	# The keys belong to the work only when it IS the scene. Placed in a world they reached it from anywhere:
	# in the desktop tower Space toggled it and an arrow key switched its mode and reset it, floors away.
	if get_tree().current_scene != self:
		return
	if event.is_action_pressed("ui_accept"):
		single_evolution_step()
	elif event.is_action_pressed("ui_cancel"):
		reset_sphere()
	elif event.is_action_pressed("ui_select"):
		if is_evolving:
			stop_evolution()
		else:
			start_evolution()
	elif event.is_action_pressed("ui_up"):
		evolution_mode = (evolution_mode + 1) % 3
		set_evolution_mode(evolution_mode)
	elif event.is_action_pressed("ui_down"):
		evolution_mode = (evolution_mode - 1 + 3) % 3
		set_evolution_mode(evolution_mode)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("lattice") and str(config.lattice) in ["geodesic", "uv"]:
		lattice = str(config.lattice)
	if config.has("rule"):
		geodesic_rule = str(config.rule)
	if config.has("auto_evolve"):
		auto_evolve = str(config.auto_evolve).to_lower() in ["true", "1", "on"]
	if config.has("evolution_mode"):
		evolution_mode = clampi(int(config.evolution_mode), 0, 2)


# ---------------- geodesic lattice ----------------
func _parse_rule() -> void:
	# "B2/S34": born with 2 live neighbours, survives with 3 or 4.
	_birth.clear(); _survive.clear()
	for part in geodesic_rule.to_upper().split("/"):
		var target := _birth if part.begins_with("B") else (_survive if part.begins_with("S") else {})
		for ch in part.substr(1):
			if ch.is_valid_int():
				target[int(ch)] = true
	if _birth.is_empty() and _survive.is_empty():
		_birth = {2: true}; _survive = {3: true, 4: true}

func _build_geodesic(level: int) -> void:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var verts: Array[Vector3] = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for i in verts.size():
		verts[i] = verts[i].normalized()
	var faces: Array = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2],
		[10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10],
		[8, 6, 7], [9, 8, 1]]
	for _l in range(clampi(level, 1, 5)):
		var cache := {}
		var next: Array = []
		for f in faces:
			var m := []
			for e in [[f[0], f[1]], [f[1], f[2]], [f[2], f[0]]]:
				var key := Vector2i(mini(e[0], e[1]), maxi(e[0], e[1]))
				if not cache.has(key):
					verts.append(((verts[e[0]] + verts[e[1]]) * 0.5).normalized())
					cache[key] = verts.size() - 1
				m.append(cache[key])
			next.append([f[0], m[0], m[2]]); next.append([f[1], m[1], m[0]]); next.append([f[2], m[2], m[1]]); next.append([m[0], m[1], m[2]])
		faces = next
	vertices = PackedVector3Array(verts)
	original_positions = vertices.duplicate()
	indices = PackedInt32Array()
	for f in faces:
		# Godot's front faces wind clockwise seen from outside.
		indices.append_array([f[0], f[2], f[1]])

func _build_palette() -> void:
	# Index: a live cell by its age 1..8, a dead one 9 + generations since it died (0..4); 13 = long dead.
	_palette = PackedColorArray(); _palette.resize(14)
	_palette[0] = Color(1.0, 0.78, 0.32)
	_palette[1] = Color(1.0, 0.78, 0.32)                                                  # just born
	for a in range(2, 9):
		_palette[a] = Color(0.3, 0.82, 1.0).lerp(Color(0.93, 0.97, 1.0), clampf((a - 1) / 6.0, 0.0, 1.0))
	for d in range(5):
		_palette[9 + d] = Color(0.2, 0.42, 0.62).lerp(Color(0.05, 0.1, 0.24), d / 4.0)   # the ghost of a cell

func _process(_delta: float) -> void:
	if _phase < 0:
		return
	_geo_phase(_phase)
	_phase += 1
	if _phase > 2 * GEO_SLICES:
		_phase = -1
		_after_geo_step()

func _geo_phase(ph: int) -> void:
	var n := vertices.size()
	if ph < GEO_SLICES:
		_geo_rule(ph * n / GEO_SLICES, (ph + 1) * n / GEO_SLICES)
	elif ph < 2 * GEO_SLICES:
		if ph == GEO_SLICES:
			_geo_commit()
		var q := ph - GEO_SLICES
		_geo_relief(q * n / GEO_SLICES, (q + 1) * n / GEO_SLICES)
	else:
		_update_geodesic_mesh()

func _geo_prepare() -> void:
	var n := vertices.size()
	# Flatten the neighbour lists once: a generation reads them 2562 x 6 times.
	_nb_start = PackedInt32Array(); _nb = PackedInt32Array()
	for i in range(n):
		_nb_start.append(_nb.size())
		_nb.append_array(PackedInt32Array(vertex_neighbors[i]))
	_nb_start.append(_nb.size())
	_born_on = PackedByteArray(); _born_on.resize(16)
	_lives_on = PackedByteArray(); _lives_on.resize(16)
	for k in range(16):
		_born_on[k] = 1 if _birth.has(k) else 0
		_lives_on[k] = 1 if _survive.has(k) else 0
	_state = PackedByteArray(); _state.resize(n)
	_next_state = PackedByteArray(); _next_state.resize(n)
	for i in range(n):
		_state[i] = 1 if vertex_states[i] else 0
	_build_palette()
	_phase = -1

func _geo_rule(from: int, to: int) -> void:
	for i in range(from, to):
		var alive := 0
		for k in range(_nb_start[i], _nb_start[i + 1]):
			alive += _state[_nb[k]]
		_next_state[i] = _lives_on[alive] if _state[i] == 1 else _born_on[alive]

func _geo_commit() -> void:
	var swap := _state
	_state = _next_state
	_next_state = swap
	for i in range(_state.size()):
		var target := 0.0
		if _state[i] == 1:
			_age[i] += 1
			_dead_for[i] = 0
			target = 0.04 + 0.022 * mini(_age[i], 8)
		else:
			_age[i] = 0
			_dead_for[i] = mini(_dead_for[i] + 1, 99)
		_height[i] = _height[i] * 0.55 + target * 0.45

func _geo_relief(from: int, to: int) -> void:
	# One smoothing pass: a colony stands as a mound, not as needles.
	for i in range(from, to):
		var sum := 0.0
		var a := _nb_start[i]
		var b := _nb_start[i + 1]
		for k in range(a, b):
			sum += _height[_nb[k]]
		vertices[i] = original_positions[i] * (1.0 + 0.5 * _height[i] + 0.5 * sum / float(maxi(1, b - a)))
		_colors[i] = _palette[mini(_age[i], 8)] if _state[i] == 1 else _palette[9 + mini(_dead_for[i], 4)]

func _after_geo_step() -> void:
	current_iteration += 1
	if current_iteration >= geodesic_generations or _state.count(1) == 0:
		stop_evolution()
		_begin_again()

func _update_geodesic_mesh() -> void:
	# Smooth normals from the faces around each cell; the index list never changes.
	var n := vertices.size()
	var normals := PackedVector3Array(); normals.resize(n)
	for f in range(0, indices.size(), 3):
		var i0 := indices[f]
		var i1 := indices[f + 1]
		var i2 := indices[f + 2]
		var fn := (vertices[i2] - vertices[i0]).cross(vertices[i1] - vertices[i0])
		normals[i0] += fn
		normals[i1] += fn
		normals[i2] += fn
	for i in range(n):
		normals[i] = normals[i].normalized()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = mesh

func _begin_again() -> void:
	if not cycle or not is_inside_tree():
		return
	await get_tree().create_timer(hold_seconds).timeout
	if not is_inside_tree():
		return
	reset_sphere()
	start_evolution()

