# MobiusWorld.gd - Walkable Möbius strip surface
# A non-orientable world where walking a full loop flips your orientation
# Works with XRToolsMovementWallWalk for lizard-feet walking on any surface
#
# Usage: Place in scene, ensure player has MovementWallWalk enabled
# The collision layer 4 (wall-walk) allows the player to stick to the surface

extends Node3D
class_name MobiusWorld

# Möbius strip parameters
@export var u_steps: int = 128  # Resolution around the strip
@export var v_steps: int = 24   # Resolution across width
@export var radius: float = 30.0  # Major radius (center of strip)
@export var width: float = 8.0   # Half-width of the strip

# Visual settings
@export var base_color: Color = Color(0.2, 0.25, 0.35)
@export var wireframe_color: Color = Color(0.5, 0.6, 0.8)
@export var emission_color: Color = Color(0.3, 0.4, 0.6)

# Wall-walk collision layer (layer 4, mask 0b1000 = 8)
const WALL_WALK_LAYER: int = 8

# Components
var mesh_instance: MeshInstance3D
var static_body: StaticBody3D

signal world_ready

func _ready():
	create_mobius_world()
	emit_signal("world_ready")

func create_mobius_world():
	create_mesh()
	create_collision()

func create_mesh():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var u_step_size = TAU / float(u_steps)
	var v_step_size = 2.0 / float(v_steps)  # -1 to 1

	# Generate vertices grid
	var vertices = []
	var normals_grid = []

	for i in range(u_steps + 1):
		var row = []
		var normal_row = []
		for j in range(v_steps + 1):
			var u = i * u_step_size
			var v = -1.0 + j * v_step_size

			var pos = get_point(u, v)
			row.append(pos)

			var normal = calculate_normal_at(u, v)
			normal_row.append(normal)

		vertices.append(row)
		normals_grid.append(normal_row)

	# Create faces
	for i in range(u_steps):
		for j in range(v_steps):
			var v0 = vertices[i][j]
			var v1 = vertices[i + 1][j]
			var v2 = vertices[i + 1][j + 1]
			var v3 = vertices[i][j + 1]

			var n0 = normals_grid[i][j]
			var n1 = normals_grid[i + 1][j]
			var n2 = normals_grid[i + 1][j + 1]
			var n3 = normals_grid[i][j + 1]

			# First triangle
			surface_tool.set_normal(n0)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(n1)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(n2)
			surface_tool.add_vertex(v2)

			# Second triangle
			surface_tool.set_normal(n0)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(n2)
			surface_tool.add_vertex(v2)
			surface_tool.set_normal(n3)
			surface_tool.add_vertex(v3)

	surface_tool.generate_normals()
	var generated_mesh = surface_tool.commit()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = generated_mesh
	mesh_instance.name = "MobiusMesh"
	add_child(mesh_instance)

	apply_material()

func get_point(u: float, v: float) -> Vector3:
	# Möbius strip parametric equations
	# The half-twist: rotate cross-section by u/2
	var x = (radius + v * width * cos(u / 2.0)) * cos(u)
	var y = (radius + v * width * cos(u / 2.0)) * sin(u)
	var z = v * width * sin(u / 2.0)
	return Vector3(x, z, y)  # Reorder for horizontal strip

func calculate_normal_at(u: float, v: float) -> Vector3:
	var epsilon = 0.01
	var p = get_point(u, v)
	var pu = get_point(u + epsilon, v)
	var pv = get_point(u, v + epsilon)

	var du = (pu - p).normalized()
	var dv = (pv - p).normalized()

	return du.cross(dv).normalized()

func apply_material():
	if not mesh_instance:
		return

	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("modelColor", base_color)
		material.set_shader_parameter("wireframeColor", wireframe_color)
		material.set_shader_parameter("emissionColor", emission_color)
		material.set_shader_parameter("width", 2.0)
		material.set_shader_parameter("emission_strength", 0.8)
		material.set_shader_parameter("show_interior", true)
		mesh_instance.material_override = material
	else:
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.3
		standard_material.roughness = 0.5
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.mesh.surface_set_material(0, standard_material)

func create_collision():
	static_body = StaticBody3D.new()
	static_body.name = "MobiusCollision"
	# Layer 4 for wall-walk, plus layer 1 for normal collisions
	static_body.collision_layer = 1 | WALL_WALK_LAYER
	static_body.collision_mask = 0
	add_child(static_body)

	# Create trimesh collision from mesh
	if mesh_instance and mesh_instance.mesh:
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
		collision_shape.name = "CollisionShape"
		static_body.add_child(collision_shape)

func configure(data: Dictionary) -> void:
	if data.has("radius"):
		radius = float(data["radius"])
	if data.has("width"):
		width = float(data["width"])
	if data.has("u_steps"):
		u_steps = int(data["u_steps"])
	if data.has("v_steps"):
		v_steps = int(data["v_steps"])
	if data.has("color"):
		var c = data["color"]
		if c is Array and c.size() >= 3:
			base_color = Color(c[0], c[1], c[2])

	# Regenerate if already in tree
	if is_inside_tree():
		for child in get_children():
			child.queue_free()
		await get_tree().process_frame
		create_mobius_world()
