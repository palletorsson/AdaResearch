extends "res://algorithms/vectors/shared/vector_scene_base.gd"

class_name ForceContainmentBase

## Base class for 1x1x1 meter force demonstration containments
## Agent-SceneBuilder: Provides standardized physics playground
## Protocol: IACP v2.2

# Containment specifications (LOGICAL units - will be scaled)
const CONTAINMENT_SIZE = Vector3(1.0, 1.0, 1.0)
const WALL_THICKNESS = 0.05
const BALL_RADIUS = 0.08
const BALL_MASS = 1.0

# Scene nodes
var containment_root: Node3D
var physics_ball: RigidBody3D
var force_vectors: Dictionary = {}  # name -> Node3D (vector arrow)
var info_label: Label3D

# Cached nodes for performance
var _cached_vector_nodes: Dictionary = {}  # vector_name -> {start, end, line_container}

func _ready():
	super._ready()
	_create_containment()
	_create_physics_ball()
	_create_info_label()
	print("ForceContainmentBase: 1x1x1m containment ready")

func _create_containment():
	"""Create 1x1x1 meter glass box with physics walls"""
	containment_root = Node3D.new()
	containment_root.name = "Containment"
	add_child(containment_root)
	
	# Create walls (6 faces)
	_create_wall(Vector3(0, 0.5, 0), Vector3(1, WALL_THICKNESS, 1), "Floor")  # Bottom
	_create_wall(Vector3(0, -0.5, 0), Vector3(1, WALL_THICKNESS, 1), "Ceiling")  # Top
	_create_wall(Vector3(0.5, 0, 0), Vector3(WALL_THICKNESS, 1, 1), "WallRight")  # +X
	_create_wall(Vector3(-0.5, 0, 0), Vector3(WALL_THICKNESS, 1, 1), "WallLeft")  # -X
	_create_wall(Vector3(0, 0, 0.5), Vector3(1, 1, WALL_THICKNESS), "WallBack")  # +Z
	_create_wall(Vector3(0, 0, -0.5), Vector3(1, 1, WALL_THICKNESS), "WallFront")  # -Z

func _create_wall(pos: Vector3, size: Vector3, wall_name: String):
	"""Create a single wall with collision"""
	var wall = StaticBody3D.new()
	wall.name = wall_name
	wall.position = pos * SCENE_SCALE
	
	# Collision shape
	var collider = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size * SCENE_SCALE
	collider.shape = box
	wall.add_child(collider)
	
	# Visual mesh (transparent glass)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _shared_floor_mesh  # Reuse shared mesh
	mesh_instance.scale = size * SCENE_SCALE
	
	var material = _get_wall_material(wall_name)
	mesh_instance.material_override = material
	wall.add_child(mesh_instance)
	
	containment_root.add_child(wall)

func _get_wall_material(wall_name: String) -> StandardMaterial3D:
	"""Get material for wall (floor is more opaque)"""
	var is_floor = wall_name == "Floor"
	var alpha = 0.8 if is_floor else 0.15
	var color = Color(0.2, 0.3, 0.4, alpha) if is_floor else Color(0.3, 0.5, 0.8, alpha)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # See both sides
	if not is_floor:
		mat.emission_enabled = true
		mat.emission = color * 0.3
	return mat

func _create_physics_ball():
	"""Create physics ball inside containment"""
	var spawn_pos = Vector3(0, 0, 0)  # Center of containment
	physics_ball = create_ball(spawn_pos, BALL_RADIUS, BALL_MASS, Color(0.9, 0.5, 0.8, 1.0))
	physics_ball.name = "PhysicsBall"
	
	# Ensure ball stays inside containment (add slight damping)
	physics_ball.linear_damp = 0.1
	physics_ball.angular_damp = 0.1

func _create_info_label():
	"""Create floating info label above containment"""
	info_label = Label3D.new()
	info_label.text = "Force Demo"
	info_label.position = Vector3(0, 0.7, 0) * SCENE_SCALE
	info_label.font_size = 24
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.modulate = Color(1, 1, 1, 1)
	info_label.outline_size = 3
	info_label.outline_modulate = Color.BLACK
	add_child(info_label)

func create_force_vector(force_name: String, initial_force: Vector3, color: Color, allow_grab: bool = true) -> Node3D:
	"""Create a force vector visualization"""
	var ball_pos = physics_ball.global_position / SCENE_SCALE  # Logical position
	var vector = spawn_vector(ball_pos, initial_force, color, force_name, allow_grab)
	force_vectors[force_name] = vector
	
	# Cache nodes for performance
	_cache_vector_nodes(vector, force_name)
	
	return vector

func get_force_vector(force_name: String) -> Vector3:
	"""Get force vector value (logical units)"""
	if not force_vectors.has(force_name):
		return Vector3.ZERO
	
	var cache = _cached_vector_nodes.get(force_name, {})
	return _get_vector_fast_cached(cache)

func update_force_vector_position():
	"""Update all force vector positions to follow ball"""
	var ball_pos_scaled = physics_ball.global_position
	for vector in force_vectors.values():
		vector.position = ball_pos_scaled

func apply_forces_to_ball(forces: Dictionary):
	"""Apply multiple forces to ball. forces = {name: Vector3 (logical)}"""
	var net_force_logical = Vector3.ZERO
	for force in forces.values():
		net_force_logical += force
	
	# Apply scaled force to physics
	physics_ball.apply_central_force(net_force_logical * SCENE_SCALE)

func reset_ball(position: Vector3 = Vector3.ZERO):
	"""Reset ball to position (logical units)"""
	physics_ball.global_position = position * SCENE_SCALE
	physics_ball.linear_velocity = Vector3.ZERO
	physics_ball.angular_velocity = Vector3.ZERO
	update_force_vector_positions()

func update_info_text(lines: Array):
	"""Update info label with array of strings"""
	info_label.text = "\n".join(lines)

# --- Performance Helpers ---

func _cache_vector_nodes(arrow: Node3D, vector_name: String):
	"""Cache vector nodes for fast access"""
	var cache = {}
	cache["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache["line_container"] = arrow.get_node_or_null("lineContainer")
	_cached_vector_nodes[vector_name] = cache

func _get_vector_fast_cached(cache: Dictionary) -> Vector3:
	"""Get vector value using cached nodes"""
	var start: Node3D = cache.get("start")
	var end: Node3D = cache.get("end")
	if start and end:
		return (end.global_position - start.global_position) / SCENE_SCALE
	return Vector3.ZERO

func _update_vector_fast_cached(cache: Dictionary, vector: Vector3):
	"""Update vector using cached nodes"""
	var end_node: Node3D = cache.get("end")
	if end_node:
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()
