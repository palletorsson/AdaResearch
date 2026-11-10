extends Node3D

# Fibonacci Sequences Visualization
# Mathematical recursion patterns in nature and computation

# @identity
# essence: F(n) = F(n-1) + F(n-2), visualized as towers, golden spiral, sunflower, pinecone, nautilus, and recursive tree
# desire: To reveal the golden ratio everywhere — towers grow logarithmically, spirals unfurl, seeds pack, shells expand
# critical_parameter: golden_ratio ((1+sqrt(5))/2) — the single number that governs spiral growth, seed packing angle (137.508), and tower ratio convergence
# triggers: sequence_timer cycles through current_index highlighting towers; time drives spiral animation and natural pattern updates
# emerges: The sunflower seed packing — 144 seeds placed at golden angle intervals create visible spiral arms from a single placement rule
# needs: VR section toggle [missing], golden angle visualization [missing]
# relationships: Mathematical foundation for golden_rectangle, fibonacci_terrain, romanesco, and fibonacci_pagoda; the sequence they all implement
# truth: The Fibonacci sequence is not about numbers — it is about the fact that growth, when it remembers its last two steps, spirals.
#
# BUILT ONCE, ANIMATED CHEAPLY (2026-11-10). Until now _process freed and rebuilt every view every frame - ~630 CSG
# nodes, each with a new material - so a floor holding this work ran at ~2 fps (491 ms a frame measured alone, worst
# 1.3 s; floor 123 of the Void tower). The views are built once with shared meshes and materials; the frame only
# moves the highlight from tower to tower (a material swap) and breathes the spiral's spheres (a scale). The builders
# keep their names, containers and dimensions: golden_mapping_lesson (floor 122) and fractal_procedure_gallery
# (Fractal_Synthesis) call them to stage held examples. The scene's screen panel (a stub UI) is gone.

var lesson_enabled := false

var time := 0.0
var sequence_timer := 0.0
var current_index := 0
var fibonacci_numbers := [1, 1]
var golden_ratio := (1 + sqrt(5)) / 2

var _built := false
var _towers: Array[MeshInstance3D] = []
var _tower_materials: Array[Material] = []
var _lit_tower := -1
var _spiral_spheres: Array[MeshInstance3D] = []
var _meshes := {}      # shared meshes by shape and size
var _materials := {}   # shared materials by colour and flags

const SPIRAL_SPHERE := 0.05   # the spiral's spheres are built at this radius and breathe by scale

func _ready() -> void:
	generate_fibonacci_sequence(20)
	# The Void sets a placement's config as config_* metas before _ready: a lesson placement never shows the default views.
	if str(get_meta("config_lesson", "false")) == "true":
		lesson_enabled = true

func _process(delta: float) -> void:
	if lesson_enabled: return
	if not _built:
		_built = true
		visualize_number_sequence()
		create_golden_spiral()
		show_natural_patterns()
		demonstrate_recursion()
	time += delta
	sequence_timer += delta

	if sequence_timer > 0.8:
		sequence_timer = 0.0
		current_index = (current_index + 1) % fibonacci_numbers.size()
	_light_tower(current_index)
	for i in _spiral_spheres.size():
		var s := _spiral_spheres[i]
		if is_instance_valid(s):
			s.scale = Vector3.ONE * (_spiral_radius(i) / SPIRAL_SPHERE)

func generate_fibonacci_sequence(count: int) -> void:
	fibonacci_numbers = [1, 1]

	for i in range(2, count):
		var next_fib = fibonacci_numbers[i-1] + fibonacci_numbers[i-2]
		fibonacci_numbers.append(next_fib)

# --- shared resources -------------------------------------------------------------------------------------------------

func _sphere(radius: float) -> SphereMesh:
	var key := "s%.4f" % radius
	if not _meshes.has(key):
		var m := SphereMesh.new(); m.radius = radius; m.height = radius * 2.0
		m.radial_segments = 12; m.rings = 6   # CSGSphere3D's own facets: ~260 default spheres would be a million triangles
		_meshes[key] = m
	return _meshes[key]

func _box(size: Vector3) -> BoxMesh:
	var key := "b%.4f,%.4f,%.4f" % [size.x, size.y, size.z]
	if not _meshes.has(key):
		var m := BoxMesh.new(); m.size = size
		_meshes[key] = m
	return _meshes[key]

func _cylinder(radius: float, height: float) -> CylinderMesh:
	var key := "c%.4f,%.3f" % [radius, height]
	if not _meshes.has(key):
		var m := CylinderMesh.new(); m.top_radius = radius; m.bottom_radius = radius; m.height = height
		m.radial_segments = 8; m.rings = 0   # CSGCylinder3D's 8 sides
		_meshes[key] = m
	return _meshes[key]

func _material(color: Color, emission := 0.0, alpha := false) -> StandardMaterial3D:
	var key := "%s|%.2f|%s" % [color.to_html(), emission, alpha]
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		if emission > 0.0:
			m.emission_enabled = true
			m.emission = Color(color.r, color.g, color.b) * emission
		if alpha:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materials[key] = m
	return _materials[key]

func _part(container: Node3D, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	container.add_child(node)
	return node

## A connector from a to b in its container's LOCAL frame. The original called look_at_from_position() BEFORE
## add_child, which Godot then reads as local; after add_child it would read a and b as GLOBAL and every connector
## would be placed wrong wherever the container is not at the world origin (all of the tower).
func _connector(container: Node3D, radius: float, a: Vector3, b: Vector3, material: Material) -> MeshInstance3D:
	var mid := (a + b) * 0.5
	var node := _part(container, _cylinder(radius, a.distance_to(b)), material, mid)
	node.transform = Transform3D(Basis.looking_at(b - mid, Vector3.UP), mid)
	node.rotate_object_local(Vector3.RIGHT, PI / 2)
	return node

func _clear(container: Node3D) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

# --- the towers -------------------------------------------------------------------------------------------------------

func _tower_material(i: int) -> Material:
	var ratio_to_golden = float(fibonacci_numbers[i]) / pow(golden_ratio, i)
	return _material(Color(0.3 + ratio_to_golden * 0.7, 0.7, 1.0 - ratio_to_golden * 0.5))

func _light_tower(index: int) -> void:
	if index == _lit_tower: return
	if _lit_tower >= 0 and _lit_tower < _towers.size() and is_instance_valid(_towers[_lit_tower]):
		_towers[_lit_tower].material_override = _tower_materials[_lit_tower]
	if index >= 0 and index < _towers.size() and is_instance_valid(_towers[index]):
		_towers[index].material_override = _material(Color(1.0, 0.2, 0.2), 0.6)
	_lit_tower = index

func visualize_number_sequence() -> void:
	var container = $NumberSequence
	_clear(container)
	_towers.clear(); _tower_materials.clear(); _lit_tower = -1

	# Show Fibonacci sequence as growing towers (ordered along Z instead of X)
	for i in range(min(15, fibonacci_numbers.size())):
		var number = fibonacci_numbers[i]
		var height = log(number) * 0.5 + 0.5  # Logarithmic scale
		var material := _tower_material(i)
		_towers.append(_part(container, _box(Vector3(0.6, height, 0.6)), material, Vector3(0, height * 0.5, i * 0.8 - 6)))
		_tower_materials.append(material)

		# Show the addition relationship
		if i >= 2:
			create_addition_visualization(container, i)
	_light_tower(current_index)

func create_addition_visualization(container: Node3D, index: int) -> void:
	# Visualize Fib(n) = Fib(n-1) + Fib(n-2)
	var conn_material := _material(Color(0.8, 0.8, 0.2, 0.7), 0.0, true)
	# Order connections along Z instead of X
	_part(container, _cylinder(0.02, 0.8), conn_material, Vector3(0.3, 2.5, (index - 1) * 0.8 - 6 + 0.4)).rotation_degrees = Vector3(0, 0, -45)
	_part(container, _cylinder(0.02, 1.6), conn_material, Vector3(0.6, 2.5, (index - 2) * 0.8 - 6 + 0.8)).rotation_degrees = Vector3(0, 0, -30)

# --- the golden spiral ------------------------------------------------------------------------------------------------

func _spiral_radius(i: int) -> float:
	return 0.05 + sin(time + i * 0.1) * 0.02

func create_golden_spiral() -> void:
	var container = $GoldenSpiral
	_clear(container)
	_spiral_spheres.clear()

	# Create Fibonacci spiral using golden ratio
	var spiral_points = []
	var radius = 0.1
	var angle = 0.0

	for i in range(80):
		# Golden spiral equation
		var current_radius = radius * pow(golden_ratio, angle / (2 * PI))
		var x = cos(angle) * current_radius
		var z = sin(angle) * current_radius
		var y = angle * 0.1  # Slight vertical progression

		spiral_points.append(Vector3(x, y, z))
		angle += 0.2

		# Create spiral segment
		var hue := Color.from_hsv(float(i) / 80.0 * 0.6 + 0.1, 0.8, 1.0)
		var sphere := _part(container, _sphere(SPIRAL_SPHERE), _material(hue, 0.4), Vector3(x, y, z))
		sphere.scale = Vector3.ONE * (_spiral_radius(i) / SPIRAL_SPHERE)
		_spiral_spheres.append(sphere)

	# Connect spiral points
	var conn_material := _material(Color(0.8, 0.8, 0.8, 0.6), 0.0, true)
	for i in range(spiral_points.size() - 1):
		_connector(container, 0.02, spiral_points[i], spiral_points[i + 1], conn_material)

# --- the natural patterns ---------------------------------------------------------------------------------------------

func show_natural_patterns() -> void:
	var container = $NaturalPatterns
	_clear(container)

	# Create sunflower seed pattern (Fibonacci spirals)
	create_sunflower_pattern(container, Vector3(-3, 0, 0))

	# Create pinecone pattern
	create_pinecone_pattern(container, Vector3(0, 0, 0))

	# Create nautilus shell pattern
	create_nautilus_pattern(container, Vector3(3, 0, 0))

func create_sunflower_pattern(container: Node3D, center: Vector3) -> void:
	var seed_count = 144  # Fibonacci number
	var golden_angle = 2 * PI / (golden_ratio * golden_ratio)
	var mesh := _sphere(0.03)
	var material := _material(Color(0.9, 0.7, 0.2), 0.3)

	for i in range(seed_count):
		var angle = i * golden_angle
		var radius = sqrt(i) * 0.1
		_part(container, mesh, material, center + Vector3(cos(angle) * radius, 0, sin(angle) * radius))

func create_pinecone_pattern(container: Node3D, center: Vector3) -> void:
	var spiral_count = 8  # Fibonacci number
	var layers = 13       # Another Fibonacci number
	var mesh := _box(Vector3(0.1, 0.15, 0.05))
	var material := _material(Color(0.6, 0.4, 0.2))

	for layer in range(layers):
		var layer_radius = 0.5 + layer * 0.1
		var layer_height = layer * 0.2

		for spiral in range(spiral_count):
			var angle = (float(spiral) / spiral_count) * 2 * PI + layer * 0.3
			var scale_part := _part(container, mesh, material, center + Vector3(cos(angle) * layer_radius, layer_height, sin(angle) * layer_radius))
			scale_part.rotation_degrees = Vector3(0, angle * 57.3, 30)

func create_nautilus_pattern(container: Node3D, center: Vector3) -> void:
	var chambers = 8  # Based on Fibonacci growth
	var growth_rate = golden_ratio
	var initial_radius = 0.1
	var material := _material(Color(0.9, 0.7, 0.9, 0.7), 0.2, true)

	for chamber in range(chambers):
		var chamber_radius = initial_radius * pow(growth_rate, float(chamber) / 4.0)
		var angle = chamber * PI / 2
		_part(container, _sphere(chamber_radius), material, center + Vector3(cos(angle) * chamber_radius * 0.5, 0, sin(angle) * chamber_radius * 0.5))

# --- the recursion ----------------------------------------------------------------------------------------------------

func demonstrate_recursion() -> void:
	var container = $RecursionVisualization
	_clear(container)

	# Visualize recursive tree structure
	create_recursive_tree(container, Vector3.ZERO, 0, 5)

func create_recursive_tree(container: Node3D, position: Vector3, depth: int, max_depth: int) -> void:
	if depth >= max_depth:
		return

	# Create node for current recursion level
	var depth_ratio = float(depth) / max_depth
	_part(container, _sphere(0.3 * (1.0 - float(depth) / max_depth)), _material(Color.from_hsv(depth_ratio * 0.3, 0.8, 1.0), 0.4), position)

	# Create Fibonacci-based branches
	if depth < max_depth - 1:
		var branch_count = fibonacci_numbers[min(depth + 1, fibonacci_numbers.size() - 1)] % 4 + 1
		var branch_length = 2.0 * (1.0 - float(depth) / max_depth)
		var conn_material := _material(Color(0.6, 0.4, 0.2))

		for branch in range(branch_count):
			var angle = (float(branch) / branch_count) * 2 * PI + depth * golden_ratio
			var branch_pos = position + Vector3(
				cos(angle) * branch_length,
				-1.5,
				sin(angle) * branch_length
			)

			# Create connection
			_connector(container, 0.05, position, branch_pos, conn_material)

			# Recursive call
			create_recursive_tree(container, branch_pos, depth + 1, max_depth)


func apply_grid_config(config: Dictionary) -> void:
	if str(config.get("lesson","false")) != "true": return
	lesson_enabled=true
	_install_lesson.call_deferred()

func _install_lesson() -> void:
	if has_node("GoldenLesson"): return
	var desk=load("res://commons/artifacts/golden_mapping_lesson/golden_mapping_lesson.gd").new()
	desk.name="GoldenLesson";desk.kind="numbers";add_child(desk)
