extends Node3D

# Fibonacci Sequences Visualization
# Mathematical recursion patterns in nature and computation

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence`
# ═══════════════════════════════════════════════════════════════════
#
# WHAT THE OBJECT SHOWS OF ITS OWN ITERATION. Same word, same first three
# values, as sine_wave_controller, wave_interference_tank and koch_curve —
# koch_curve is the near sibling here, because both artifacts are ONE RULE
# APPLIED REPEATEDLY and both ship as a display case of finished products with
# the rule itself nowhere on the object. Sharing the ladder means the two of
# them measure alike, which is the honest outcome for two artifacts asking one
# question.
#
#   result    the shipped display case, byte for byte: fifteen logarithmic
#             towers, an 80-sphere golden spiral at x = 8, a 144-seed sunflower,
#             a 13-layer pinecone, a nautilus, and a four-deep recursion tree.
#             Six products of the rule and no sight of the rule.
#   trace     every generation at once. The other three panels go dark and the
#             sequence is rebuilt as a TERRACE — row n carries the first n+1
#             terms, thirteen rows stepping back in Z at 0.75 m, so the whole
#             history of the computation stands as one staircase instead of one
#             frame of it.
#   longhand  the working shown. Six sums, F(2)..F(7), each built from UNIT
#             CUBES so the arithmetic is literally stacked: F(n-2) blue cubes
#             with F(n-1) green cubes on top, and beside them a red column of
#             F(n) cubes reaching exactly the same height. The identity is not
#             illustrated, it is measured — which the shipped logarithmic towers
#             cannot do, because log F(n-1) + log F(n-2) is not log F(n).
#   axiom     the seed pair alone. Two identical 1 m cubes, F(0) and F(1), on an
#             empty stage. Everything the artifact shows at `result` grows out of
#             those two, and stripped back to them it is nothing but two ones.
#
# All three non-default values ALSO stand the other panels down, so the claim
# is made by one object rather than by a busier version of the same room.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Allow-list. An unknown word in a map token keeps the shipped display case.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

# ── Framing ──────────────────────────────────────────────────────────
# THIS ARTIFACT IS BUILT ENTIRELY FROM CSG NODES, and every AABB walk in the
# project counts MeshInstance3D (and MultiMesh, and CSG when it is a DIRECT
# child). The sweep capturer's walk counts MeshInstance3D only, so it measured
# this 15 m x 10 m sprawl as a 1 m fallback box and framed the camera 5.6 m from
# the origin — a close-up of the middle of the recursion tree. The fix is one
# unrendered box per value (layers = 0), sized to the real extent.
#
# IT IS DELIBERATELY NOT A DIRECT CHILD OF THE ROOT. GridInteractablesComponent
# ._compute_local_aabb walks direct children only; this artifact currently
# exposes none it recognises, so it is not auto-grounded in any of its seven
# maps. A direct-child anchor would start grounding it and move it in all seven.
# Nested one level down, the sweep's subtree walk finds it and the grid's
# shallow walk still does not.
const FRAME_HOLDER := "EvidenceFrame"
## value -> [centre, size] of the unrendered framing box, in metres.
const FRAMES: Dictionary = {
	"result": [Vector3(1.0, -1.3, 0.0), Vector3(15.2, 10.0, 9.0)],
	"trace": [Vector3(-1.2, 1.6, -4.4), Vector3(10.6, 3.6, 10.0)],
	"longhand": [Vector3(0.5, 2.8, 0.0), Vector3(14.2, 6.0, 2.4)],
	"axiom": [Vector3(0.0, 0.6, 0.0), Vector3(5.0, 2.6, 2.6)],
}

# ── Layout of the non-default values, in metres ──────────────────────
const TERRACE_ROWS: int = 13           # trace — one row per generation
const TERRACE_DEPTH: float = 0.75      # trace — Z step between generations
const TOWER_PITCH: float = 0.8         # shipped tower spacing, kept
const SUM_FIRST: int = 2               # longhand — first index with a parent pair
const SUM_LAST: int = 7                # longhand — F(7) = 21 cubes, 5.7 m tall
const SUM_PITCH: float = 2.4           # longhand — spacing between sums
const CUBE: float = 0.25               # longhand — one unit of the sequence
const CUBE_GAP: float = 0.02
const AXIOM_CUBE: float = 1.0          # axiom — the two ones, at human scale

var time := 0.0
var sequence_timer := 0.0
var current_index := 0
var fibonacci_numbers := [1, 1]
var golden_ratio := (1 + sqrt(5)) / 2

func _ready():
	generate_fibonacci_sequence(20)
	# APPENDED LAST. At the shipped value this only stands up the framing box.
	_apply_evidence()

func _process(delta):
	time += delta
	sequence_timer += delta
	
	if sequence_timer > 0.8:
		sequence_timer = 0.0
		current_index = (current_index + 1) % fibonacci_numbers.size()
	
	visualize_number_sequence()
	create_golden_spiral()
	show_natural_patterns()
	demonstrate_recursion()

func generate_fibonacci_sequence(count: int):
	fibonacci_numbers = [1, 1]
	
	for i in range(2, count):
		var next_fib = fibonacci_numbers[i-1] + fibonacci_numbers[i-2]
		fibonacci_numbers.append(next_fib)

func visualize_number_sequence():
	var container = $NumberSequence

	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()

	# `evidence` restages this panel entirely; the shipped towers below are left
	# untouched so the default rebuild is identical frame for frame.
	if evidence != "result":
		_build_evidence_panel(container)
		return

	# Show Fibonacci sequence as growing towers
	for i in range(min(15, fibonacci_numbers.size())):
		var number = fibonacci_numbers[i]
		var height = log(number) * 0.5 + 0.5  # Logarithmic scale
		
		var number_tower = CSGBox3D.new()
		number_tower.size = Vector3(0.6, height, 0.6)
		number_tower.position = Vector3(i * 0.8 - 6, height * 0.5, 0)
		
		var material = StandardMaterial3D.new()
		if i == current_index:
			material.albedo_color = Color(1.0, 0.2, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.2, 0.2) * 0.6
		else:
			var ratio_to_golden = float(fibonacci_numbers[i]) / pow(golden_ratio, i)
			material.albedo_color = Color(0.3 + ratio_to_golden * 0.7, 0.7, 1.0 - ratio_to_golden * 0.5)
		
		number_tower.material_override = material
		container.add_child(number_tower)
		
		# Show the addition relationship
		if i >= 2:
			create_addition_visualization(container, i)

func create_addition_visualization(container: Node3D, index: int):
	# Visualize Fib(n) = Fib(n-1) + Fib(n-2)
	var connection1 = CSGCylinder3D.new()
	connection1.radius = 0.02
	
	connection1.height = 0.8
	connection1.position = Vector3((index - 1) * 0.8 - 6 + 0.4, 2.5, 0.3)
	connection1.rotation_degrees = Vector3(0, 0, -45)
	
	var conn_material = StandardMaterial3D.new()
	conn_material.albedo_color = Color(0.8, 0.8, 0.2, 0.7)
	conn_material.flags_transparent = true
	connection1.material_override = conn_material
	
	container.add_child(connection1)
	
	var connection2 = CSGCylinder3D.new()
	connection2.radius = 0.02
	
	connection2.height = 1.6
	connection2.position = Vector3((index - 2) * 0.8 - 6 + 0.8, 2.5, 0.6)
	connection2.rotation_degrees = Vector3(0, 0, -30)
	
	connection2.material_override = conn_material
	container.add_child(connection2)

func create_golden_spiral():
	var container = $GoldenSpiral

	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()

	if evidence != "result":
		return          # one claim per object

	# Create Fibonacci spiral using golden ratio
	var spiral_points = []
	var radius = 0.1
	var angle = 0.0
	var center = Vector3.ZERO
	
	for i in range(80):
		# Golden spiral equation
		var current_radius = radius * pow(golden_ratio, angle / (2 * PI))
		var x = cos(angle) * current_radius
		var z = sin(angle) * current_radius
		var y = angle * 0.1  # Slight vertical progression
		
		spiral_points.append(Vector3(x, y, z))
		angle += 0.2
		
		# Create spiral segment
		var spiral_segment = CSGSphere3D.new()
		spiral_segment.radius = 0.05 + sin(time + i * 0.1) * 0.02
		spiral_segment.position = Vector3(x, y, z)
		
		var material = StandardMaterial3D.new()
		var color_phase = float(i) / 80.0
		material.albedo_color = Color.from_hsv(color_phase * 0.6 + 0.1, 0.8, 1.0)
		material.emission_enabled = true
		material.emission = Color.from_hsv(color_phase * 0.6 + 0.1, 0.8, 1.0) * 0.4
		spiral_segment.material_override = material
		
		container.add_child(spiral_segment)
	
	# Connect spiral points
	for i in range(spiral_points.size() - 1):
		var connection = CSGCylinder3D.new()
		connection.radius = 0.02
		
		connection.height = spiral_points[i].distance_to(spiral_points[i + 1])
		
		connection.position = (spiral_points[i] + spiral_points[i + 1]) * 0.5
		connection.look_at_from_position(connection.position, spiral_points[i + 1], Vector3.UP)
		connection.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		var conn_material = StandardMaterial3D.new()
		conn_material.albedo_color = Color(0.8, 0.8, 0.8, 0.6)
		conn_material.flags_transparent = true
		connection.material_override = conn_material
		
		container.add_child(connection)

func show_natural_patterns():
	var container = $NaturalPatterns
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()

	if evidence != "result":
		return          # one claim per object

	# Create sunflower seed pattern (Fibonacci spirals)
	create_sunflower_pattern(container, Vector3(-3, 0, 0))
	
	# Create pinecone pattern
	create_pinecone_pattern(container, Vector3(0, 0, 0))
	
	# Create nautilus shell pattern
	create_nautilus_pattern(container, Vector3(3, 0, 0))

func create_sunflower_pattern(container: Node3D, center: Vector3):
	var seed_count = 144  # Fibonacci number
	var golden_angle = 2 * PI / (golden_ratio * golden_ratio)
	
	for i in range(seed_count):
		var angle = i * golden_angle
		var radius = sqrt(i) * 0.1
		
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		
		var seed = CSGSphere3D.new()
		seed.radius = 0.03
		seed.position = center + Vector3(x, 0, z)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.7, 0.2)
		material.emission_enabled = true
		material.emission = Color(0.9, 0.7, 0.2) * 0.3
		seed.material_override = material
		
		container.add_child(seed)

func create_pinecone_pattern(container: Node3D, center: Vector3):
	var spiral_count = 8  # Fibonacci number
	var layers = 13       # Another Fibonacci number
	
	for layer in range(layers):
		var layer_radius = 0.5 + layer * 0.1
		var layer_height = layer * 0.2
		
		for spiral in range(spiral_count):
			var angle = (float(spiral) / spiral_count) * 2 * PI + layer * 0.3
			var x = cos(angle) * layer_radius
			var z = sin(angle) * layer_radius
			
			var scale = CSGBox3D.new()
			scale.size = Vector3(0.1, 0.15, 0.05)
			scale.position = center + Vector3(x, layer_height, z)
			scale.rotation_degrees = Vector3(0, angle * 57.3, 30)
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.6, 0.4, 0.2)
			scale.material_override = material
			
			container.add_child(scale)

func create_nautilus_pattern(container: Node3D, center: Vector3):
	var chambers = 8  # Based on Fibonacci growth
	var growth_rate = golden_ratio
	var initial_radius = 0.1
	
	for chamber in range(chambers):
		var chamber_radius = initial_radius * pow(growth_rate, float(chamber) / 4.0)
		var angle = chamber * PI / 2
		
		var x = cos(angle) * chamber_radius * 0.5
		var z = sin(angle) * chamber_radius * 0.5
		
		var chamber_sphere = CSGSphere3D.new()
		chamber_sphere.radius = chamber_radius
		chamber_sphere.position = center + Vector3(x, 0, z)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.7, 0.9, 0.7)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(0.9, 0.7, 0.9) * 0.2
		chamber_sphere.material_override = material
		
		container.add_child(chamber_sphere)

func demonstrate_recursion():
	var container = $RecursionVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()

	if evidence != "result":
		return          # one claim per object

	# Visualize recursive tree structure
	create_recursive_tree(container, Vector3.ZERO, 0, 5)

func create_recursive_tree(container: Node3D, position: Vector3, depth: int, max_depth: int):
	if depth >= max_depth:
		return
	
	# Create node for current recursion level
	var node = CSGSphere3D.new()
	node.radius = 0.3 * (1.0 - float(depth) / max_depth)
	node.position = position
	
	var material = StandardMaterial3D.new()
	var depth_ratio = float(depth) / max_depth
	material.albedo_color = Color.from_hsv(depth_ratio * 0.3, 0.8, 1.0)
	material.emission_enabled = true
	material.emission = Color.from_hsv(depth_ratio * 0.3, 0.8, 1.0) * 0.4
	node.material_override = material
	
	container.add_child(node)
	
	# Create Fibonacci-based branches
	if depth < max_depth - 1:
		var branch_count = fibonacci_numbers[min(depth + 1, fibonacci_numbers.size() - 1)] % 4 + 1
		var branch_length = 2.0 * (1.0 - float(depth) / max_depth)
		
		for branch in range(branch_count):
			var angle = (float(branch) / branch_count) * 2 * PI + depth * golden_ratio
			var branch_pos = position + Vector3(
				cos(angle) * branch_length,
				-1.5,
				sin(angle) * branch_length
			)
			
			# Create connection
			var connection = CSGCylinder3D.new()
			connection.radius = 0.05
			
			connection.height = position.distance_to(branch_pos)
			
			connection.position = (position + branch_pos) * 0.5
			connection.look_at_from_position(connection.position, branch_pos, Vector3.UP)
			connection.rotate_object_local(Vector3.RIGHT, PI / 2)
			
			var conn_material = StandardMaterial3D.new()
			conn_material.albedo_color = Color(0.6, 0.4, 0.2)
			connection.material_override = conn_material
			
			container.add_child(connection)

			# Recursive call
			create_recursive_tree(container, branch_pos, depth + 1, max_depth)


func apply_grid_config(config: Dictionary) -> void:
	# Only the declared axis is read; every other key in a map token is ignored.
	if config.has("evidence"):
		evidence = str(config["evidence"])
		_apply_evidence()


# ═══════════════════════════════════════════════════════════════════
# `evidence` — APPENDED LAST. Nothing above this line moved.
# ═══════════════════════════════════════════════════════════════════

func _apply_evidence() -> void:
	var want: String = String(evidence).strip_edges().to_lower()
	if not EVIDENCES.has(want):
		want = "result"          # unknown word keeps the shipped display case
	evidence = want
	_stand_frame(want)


## The unrendered framing box. layers = 0, never visible; see the note by FRAMES.
func _stand_frame(want: String) -> void:
	var holder: Node3D = get_node_or_null(FRAME_HOLDER)
	if holder == null:
		holder = Node3D.new()
		holder.name = FRAME_HOLDER
		add_child(holder)
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	var spec: Array = FRAMES.get(want, FRAMES["result"])
	var box := BoxMesh.new()
	box.size = spec[1]
	var anchor := MeshInstance3D.new()
	anchor.name = "FrameAnchor"
	anchor.mesh = box
	anchor.position = spec[0]
	# NEVER visible = false: Godot visibility is hierarchical and the AABB walks
	# do not consult it anyway. layers = 0 renders nothing and still measures.
	anchor.layers = 0
	anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(anchor)


func _build_evidence_panel(container: Node3D) -> void:
	match evidence:
		"trace": _build_terrace(container)
		"longhand": _build_longhand(container)
		"axiom": _build_axiom(container)


## Every generation at once: row n carries the first n+1 terms, stepping back in Z.
func _build_terrace(container: Node3D) -> void:
	for row in range(TERRACE_ROWS):
		var depth_t: float = float(row) / float(max(1, TERRACE_ROWS - 1))
		for i in range(row + 1):
			var number: int = int(fibonacci_numbers[min(i, fibonacci_numbers.size() - 1)])
			var height: float = log(float(number)) * 0.5 + 0.5
			var bar := CSGBox3D.new()
			bar.size = Vector3(0.55, height, 0.55)
			bar.position = Vector3(
				float(i) * TOWER_PITCH - 6.0,
				height * 0.5,
				-float(row) * TERRACE_DEPTH)
			var material := StandardMaterial3D.new()
			# The newest term of each generation is the one that generation adds.
			if i == row:
				material.albedo_color = Color(1.0, 0.45, 0.15)
				material.emission_enabled = true
				material.emission = Color(1.0, 0.45, 0.15) * 0.7
			else:
				material.albedo_color = Color(0.22, 0.42, 0.72).lerp(
					Color(0.55, 0.85, 1.0), depth_t)
			bar.material_override = material
			container.add_child(bar)


## The rule stacked out of unit cubes: F(n-2) + F(n-1) reaching exactly F(n).
func _build_longhand(container: Node3D) -> void:
	var step: float = CUBE + CUBE_GAP
	for n in range(SUM_FIRST, SUM_LAST + 1):
		var group_x: float = float(n - SUM_FIRST) * SUM_PITCH - 6.0
		var lower: int = int(fibonacci_numbers[n - 2])
		var upper: int = int(fibonacci_numbers[n - 1])
		var whole: int = int(fibonacci_numbers[n])
		for k in range(lower):
			_sum_cube(container, group_x, float(k) * step, Color(0.25, 0.55, 1.0))
		for k in range(upper):
			_sum_cube(container, group_x, float(lower + k) * step, Color(0.35, 0.9, 0.45))
		for k in range(whole):
			_sum_cube(container, group_x + 0.9, float(k) * step, Color(1.0, 0.32, 0.25))


func _sum_cube(container: Node3D, x: float, y: float, tint: Color) -> void:
	var cube := CSGBox3D.new()
	cube.size = Vector3(CUBE * 2.4, CUBE, CUBE * 2.4)
	cube.position = Vector3(x, y + CUBE * 0.5, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint * 0.25
	cube.material_override = material
	container.add_child(cube)


## The seed pair alone: F(0) and F(1), two identical ones on an empty stage.
func _build_axiom(container: Node3D) -> void:
	for i in range(2):
		var cube := CSGBox3D.new()
		cube.size = Vector3(AXIOM_CUBE, AXIOM_CUBE, AXIOM_CUBE)
		cube.position = Vector3(
			(float(i) - 0.5) * (AXIOM_CUBE + 0.5), AXIOM_CUBE * 0.5, 0.0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.92, 0.90, 0.84)
		material.emission_enabled = true
		material.emission = Color(0.92, 0.90, 0.84) * 0.18
		cube.material_override = material
		container.add_child(cube)
