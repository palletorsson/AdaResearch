# destructibles_test_scene.gd
# Test scene for all destructible objects
#
# @identity
# essence: impact → destroy(method). Eight destruction methods: instant, health-based, face-peel, Cantor recursion, Voronoi fracture, planar crack, prism shatter. Topology of breaking.
# desire: To throw balls at things and watch them break differently — each destructible teaching a different algorithm for decomposing geometry under impact.
# critical_parameter: The velocity of the thrown ball at impact. It triggers destruction thresholds and determines fragment ejection speeds. Faster throw = more dramatic break.
# triggers: VR grab + throw → ball hits destructible, each type responds differently (instant/health/recursive-split/voronoi-crack/prism-shatter), stats track throws and destroys
# emerges: Cantor boxes splitting into 4, then each quarter splitting again (recursive fractal destruction). Voronoi spheres cracking along Voronoi cell boundaries. Each method feels different.
# needs: Throwable balls [has], 8 destructible types [has], info panel [has]. Missing: VR reset button, slow-motion replay of destruction.
# relationships: Sandbox for all destruction algorithms in the throwing system. Lives in ForcesArena. Tests subsystems used by VectorThrowing targets.
# truth: Destruction is topology change. How something breaks reveals how it was built.
extends "../shared/vector_scene_base.gd"

@export_group("Scene Configuration")
@export var num_balls: int = 5
@export var ball_spawn_height: float = 1.5
@export var ball_spawn_spacing: float = 0.3

# Preloaded scenes
var throw_ball_scene = preload("res://algorithms/vectors/08_vector_throwing/throw_ball.tscn")
var simple_cube_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/simple_destroy_cube.tscn")
var health_cube_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/health_cube.tscn")
var tetrahedron_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/destructible_truncated_tetrahedron.tscn")
var cantor_box_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/cantor_recursion_box.tscn")
var voronoi_sphere_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/voronoi_sphere.tscn")
var voronoi_sphere_proper_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/voronoi_sphere_proper.tscn")
var voronoi_plane_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/voronoi_plane.tscn")
var prism_cube_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/prism_cube.tscn")

# Scene references
var throw_balls: Array[Node3D] = []
var destructibles_container: Node3D = null
var info_label: Label3D = null

# Stats
var total_destroyed: int = 0
var throws_count: int = 0

func _ready() -> void:
	super._ready()
 
	_spawn_throw_balls()
	_spawn_destructibles()
	_create_info_panel()

func _setup_environment() -> void:
	create_axes(2.0)
	create_floor(15.0, Color(0.2, 0.3, 0.4, 0.5))
	_create_origin_marker()

func _spawn_throw_balls() -> void:
	var balls_container = Node3D.new()
	balls_container.name = "ThrowBalls"
	add_child(balls_container)

	for i in range(num_balls):
		var ball = throw_ball_scene.instantiate()
		ball.name = "ThrowBall_%d" % i
		var x_offset = (i - (num_balls - 1) / 2.0) * ball_spawn_spacing
		ball.position = Vector3(x_offset, ball_spawn_height, 0.5)
		var hue = float(i) / float(num_balls)
		var color = Color.from_hsv(hue, 0.8, 1.0)
		if ball.has_method("set_ball_color"):
			ball.set_ball_color(color)
		ball.dropped.connect(_on_ball_thrown.bind(ball))
		balls_container.add_child(ball)
		throw_balls.append(ball)

func _spawn_destructibles() -> void:
	destructibles_container = Node3D.new()
	destructibles_container.name = "Destructibles"
	add_child(destructibles_container)

	var spawn_distance = 3.0
	var y_height = 1.0

	# Row 1: Simple cubes and health cubes
	# Test 1: Simple destroy cube
	var simple_cube_1 = simple_cube_scene.instantiate()
	simple_cube_1.position = Vector3(-2.0, y_height, spawn_distance)
	simple_cube_1.target_destroyed.connect(_on_destructible_destroyed.bind("Simple Cube"))
	destructibles_container.add_child(simple_cube_1)
	_add_label(simple_cube_1.position + Vector3(0, 0.4, 0), "Test 1:\nSimple Destroy")

	var simple_cube_2 = simple_cube_scene.instantiate()
	simple_cube_2.position = Vector3(-1.0, y_height, spawn_distance)
	simple_cube_2.target_color = Color(1.0, 0.5, 0.0)
	simple_cube_2.target_destroyed.connect(_on_destructible_destroyed.bind("Simple Cube"))
	destructibles_container.add_child(simple_cube_2)

	# Test 2: Health cubes (2 hits)
	var health_cube_1 = health_cube_scene.instantiate()
	health_cube_1.position = Vector3(0.0, y_height, spawn_distance)
	health_cube_1.target_destroyed.connect(_on_destructible_destroyed.bind("Health Cube"))
	destructibles_container.add_child(health_cube_1)
	_add_label(health_cube_1.position + Vector3(0, 0.4, 0), "Test 2:\nHealth (2 hits)")

	var health_cube_2 = health_cube_scene.instantiate()
	health_cube_2.position = Vector3(1.0, y_height, spawn_distance)
	health_cube_2.target_destroyed.connect(_on_destructible_destroyed.bind("Health Cube"))
	destructibles_container.add_child(health_cube_2)

	# Row 2: Complex objects
	# Test 4: Truncated tetrahedron
	var tetrahedron = tetrahedron_scene.instantiate()
	tetrahedron.position = Vector3(-2.0, y_height, spawn_distance + 1.5)
	tetrahedron.fully_destroyed.connect(_on_destructible_destroyed.bind("Truncated Tetrahedron"))
	destructibles_container.add_child(tetrahedron)
	_add_label(tetrahedron.position + Vector3(0, 0.5, 0), "Test 4:\nTruncated\nTetrahedron")

	# Test 5: Cantor recursion box
	var cantor_box = cantor_box_scene.instantiate()
	cantor_box.position = Vector3(0.0, y_height, spawn_distance + 1.5)
	cantor_box.box_split.connect(_on_box_split)
	destructibles_container.add_child(cantor_box)
	_add_label(cantor_box.position + Vector3(0, 0.5, 0), "Test 5:\nCantor Box\n(splits 2x)")

	# Test 6: Voronoi sphere (proper implementation)
	var voronoi_sphere = voronoi_sphere_proper_scene.instantiate()
	voronoi_sphere.position = Vector3(2.0, y_height, spawn_distance + 1.5)
	voronoi_sphere.sphere_cracked.connect(_on_destructible_destroyed.bind("Voronoi Sphere"))
	destructibles_container.add_child(voronoi_sphere)
	_add_label(voronoi_sphere.position + Vector3(0, 0.5, 0), "Test 6:\nVoronoi\nSphere (Proper)")

	# Row 3: Planes
	# Test 7: Voronoi planes
	var voronoi_plane_1 = voronoi_plane_scene.instantiate()
	voronoi_plane_1.position = Vector3(-1.5, y_height, spawn_distance + 3.0)
	voronoi_plane_1.rotate_x(deg_to_rad(-20))  # Angle slightly
	voronoi_plane_1.plane_cracked.connect(_on_destructible_destroyed.bind("Voronoi Plane"))
	destructibles_container.add_child(voronoi_plane_1)
	_add_label(voronoi_plane_1.position + Vector3(0, 0.6, 0), "Test 7:\nVoronoi Plane")

	var voronoi_plane_2 = voronoi_plane_scene.instantiate()
	voronoi_plane_2.position = Vector3(1.5, y_height, spawn_distance + 3.0)
	voronoi_plane_2.rotate_x(deg_to_rad(-20))
	voronoi_plane_2.plane_color = Color(1.0, 0.5, 0.8)
	voronoi_plane_2.plane_cracked.connect(_on_destructible_destroyed.bind("Voronoi Plane"))
	destructibles_container.add_child(voronoi_plane_2)

	# Row 4: Prism cube
	# Test 8: Window-sized prism cube
	var prism_cube = prism_cube_scene.instantiate()
	prism_cube.position = Vector3(0, y_height + 0.5, spawn_distance + 4.5)
	prism_cube.prism_destroyed.connect(_on_prism_destroyed)
	prism_cube.cube_fully_destroyed.connect(_on_destructible_destroyed.bind("Prism Cube"))
	destructibles_container.add_child(prism_cube)
	_add_label(prism_cube.position + Vector3(0, 0.7, 0), "Test 8:\nPrism Cube\n(Individual)")

func _add_label(pos: Vector3, text: String) -> void:
	"""Add a floating label above an object"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 20
	label.outline_size = 3
	label.outline_modulate = Color.BLACK
	label.modulate = Color.WHITE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	destructibles_container.add_child(label)

func _create_info_panel() -> void:
	"""Create info display"""
	info_label = Label3D.new()
	info_label.name = "InfoLabel"
	info_label.font_size = 32
	info_label.outline_size = 6
	info_label.outline_modulate = Color.BLACK
	info_label.modulate = Color.YELLOW
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.position = Vector3(0, 2.5, 0)
	add_child(info_label)

	_update_info()

	# Instructions
	var instructions = Label3D.new()
	instructions.font_size = 24
	instructions.outline_size = 4
	instructions.outline_modulate = Color.BLACK
	instructions.modulate = Color(0.8, 0.9, 1.0)
	instructions.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions.position = Vector3(0, 2.0, 0)
	instructions.text = """DESTRUCTIBLES TEST SCENE

Grab and throw balls to test each destructible:

1. Simple Cube - Destroys on hit
2. Health Cube - Needs 2 hits
4. Truncated Tetrahedron - Parts break off
5. Cantor Box - Splits into 4, then 4 again
6. Voronoi Sphere - Cracks into fragments
7. Voronoi Plane - Cracks at impact point"""
	add_child(instructions)

func _on_ball_thrown(_pickable: Node3D, _ball: Node3D) -> void:
	throws_count += 1
	_update_info()

func _on_destructible_destroyed(_target: Variant = null, _impact: Variant = null, _velocity: Variant = null, type: String = "Object") -> void:
	total_destroyed += 1
	print("[Destructibles Test] %s destroyed! Total: %d" % [type, total_destroyed])
	_update_info()

func _on_box_split(_parent: Node3D, _children: Array) -> void:
	print("[Destructibles Test] Cantor box split!")

func _on_prism_destroyed(prism: Node3D, _impact_velocity: Vector3) -> void:
	print("[Destructibles Test] Prism destroyed: ", prism.name)

func _update_info() -> void:
	if info_label:
		info_label.text = "Throws: %d | Destroyed: %d" % [throws_count, total_destroyed]

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
