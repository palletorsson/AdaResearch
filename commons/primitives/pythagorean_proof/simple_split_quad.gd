# simple_split_quad.gd - Simple black and pink triangle split quad
extends Node3D

# Simple triangle components
var black_triangle: MeshInstance3D
var pink_triangle: MeshInstance3D

# Colors
var black_color: Color = Color.BLACK
var pink_color: Color = Color.DEEP_PINK

# Quad size
@export var quad_size: float = 1.2

func _ready():
	create_split_quad()
	print("Simple Split Quad created!")
	print("Black triangle + Pink triangle = Perfect quad alignment")
	print("Static triangles - Black and Pink with Purple outlines")

func create_split_quad():
	# Create the split quad using two triangles
	var half_size = quad_size * 0.5
	
	# Create black triangle (bottom-left to top-right diagonal)
	black_triangle = create_triangle_mesh(
		[
			Vector3(-half_size, -half_size, 0.0),  # Bottom-left
			Vector3(half_size, -half_size, 0.0),   # Bottom-right
			Vector3(-half_size, half_size, 0.0)    # Top-left
		],
		black_color,
		"BlackTriangle"
	)
	
	# Create pink triangle (top-right to bottom-left diagonal)
	pink_triangle = create_triangle_mesh(
		[
			Vector3(half_size, half_size, 0.0),    # Top-right
			Vector3(-half_size, half_size, 0.0),   # Top-left (shared)
			Vector3(half_size, -half_size, 0.0)    # Bottom-right (shared)
		],
		pink_color,
		"PinkTriangle"
	)
	
	add_child(black_triangle)
	add_child(pink_triangle)

func create_triangle_mesh(vertices: Array, color: Color, name: String) :
	# Create a triangle mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = name
	
	# Create the mesh using SurfaceTool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Calculate normal
	var edge1 = vertices[1] - vertices[0]
	var edge2 = vertices[2] - vertices[0]
	var normal = edge1.cross(edge2).normalized()
	
	# Add front face
	st.set_normal(normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.set_color(color)
	st.add_vertex(vertices[0])
	
	st.set_normal(normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.set_color(color)
	st.add_vertex(vertices[1])
	
	st.set_normal(normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.set_color(color)
	st.add_vertex(vertices[2])
	
	# Add back face for double-sided rendering
	st.set_normal(-normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.set_color(color)
	st.add_vertex(vertices[0])
	
	st.set_normal(-normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.set_color(color)
	st.add_vertex(vertices[2])
	
	st.set_normal(-normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.set_color(color)
	st.add_vertex(vertices[1])
	
	# Generate normals and commit
	st.generate_normals()
	mesh_instance.mesh = st.commit()
	
	# Create base material for triangle fill
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
	material.emission_enabled = true
	material.emission = color * 0.1
	
	# Add some shine to make colors pop
	material.metallic = 0.3
	material.roughness = 0.7
	
	mesh_instance.material_override = material
	
	# Add purple wireframe outline
	add_purple_outline(mesh_instance)

func add_purple_outline(mesh_instance: MeshInstance3D):
	# Create purple wireframe overlay
	var wireframe_instance = MeshInstance3D.new()
	wireframe_instance.name = "PurpleOutline"
	
	# Use the same mesh but with wireframe material
	wireframe_instance.mesh = mesh_instance.mesh
	
	# Create purple wireframe material
	var purple_color = Color(0.8, 0.3, 0.9)  # Purple outline
	var wireframe_material = StandardMaterial3D.new()
	wireframe_material.albedo_color = purple_color
	wireframe_material.emission_enabled = true
	wireframe_material.emission = purple_color * 0.4
	wireframe_material.wireframe = true
	wireframe_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	wireframe_material.flags_transparent = true
	wireframe_material.albedo_color.a = 0.9
	
	wireframe_instance.material_override = wireframe_material
	
	# Position slightly in front to avoid z-fighting
	wireframe_instance.position = Vector3(0, 0, 0.001)
	
	mesh_instance.add_child(wireframe_instance)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				# Recreate the split quad
				remove_triangles()
				create_split_quad()
				print("Split quad recreated with purple outlines!")
			KEY_SPACE:
				# Toggle visibility
				toggle_triangle_visibility()
			KEY_O:
				# Toggle outline visibility
				toggle_outline_visibility()

func toggle_outline_visibility():
	# Toggle purple outline visibility
	if black_triangle:
		var outline = black_triangle.get_node_or_null("PurpleOutline")
		if outline:
			outline.visible = !outline.visible
	
	if pink_triangle:
		var outline = pink_triangle.get_node_or_null("PurpleOutline")
		if outline:
			outline.visible = !outline.visible

func remove_triangles():
	if black_triangle:
		remove_child(black_triangle)
		black_triangle.queue_free()
	if pink_triangle:
		remove_child(pink_triangle)
		pink_triangle.queue_free()

func toggle_triangle_visibility():
	if black_triangle:
		black_triangle.visible = !black_triangle.visible
	if pink_triangle:
		pink_triangle.visible = !pink_triangle.visible
