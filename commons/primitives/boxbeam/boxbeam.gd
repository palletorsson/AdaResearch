# BoxBeam.gd - Hollow rectangular beam/tube
#
# @identity
# essence: a hollow rectangular beam — a portal frame whose walkable opening is defined by its wall thickness
# desire: learner reads the frame as a boundary they can pass through, where the emptiness is the whole point
# critical_parameter: thickness against width/height — how much solid remains once the opening is subtracted
# triggers: builds its beam mesh + collision on ready; rebuilds via update_beam when dimensions change
# emerges: the understanding that a frame is defined by what it removes — the hole is designed, not left over
# needs: [builds hollow beam + collision [has], missing a live handle to resize the opening in place]
# relationships: a thickened line bent into a closed loop; kin to the portal/limit motifs and boxframe
# truth: a frame is a boundary you can pass through — the hollow is the point, the solid only holds it open
extends MeshInstance3D

@export_group("Box Profile Dimensions")
@export var height: float = 2.5  # Height of the portal (Y axis)
@export var width: float = 2.0   # Width of opening (X axis)
@export var depth: float = 0.3   # Depth/thickness in Z (how deep the frame is)
@export var thickness: float = 0.15  # Wall thickness of the frame

@export_group("Settings")
@export var create_on_ready: bool = true
@export var base_color: Color = Color(0.7, 0.7, 0.75)  # Light gray-blue

func _ready():
	if create_on_ready:
		create_beam()

func create_beam() -> void:
	# Preserve any rotation applied externally (e.g., by grid system)
	# Only reset scale
	scale = Vector3.ONE

	# Calculate dimensions
	# Inner opening: width x height (walkable area)
	# Outer dimensions include thickness on all sides
	var half_w = width / 2.0
	var half_h = height / 2.0
	var half_d = depth / 2.0
	var t = thickness

	# Vertices for a hollow rectangular frame (portal)
	# Front face outer corners (0-3), front face inner corners (4-7)
	# Back face outer corners (8-11), back face inner corners (12-15)
	var scaled_vertices = [
		# Front outer (0-3): bottom-left, bottom-right, top-right, top-left
		Vector3(-half_w - t, -half_h - t, half_d),
		Vector3(half_w + t, -half_h - t, half_d),
		Vector3(half_w + t, half_h + t, half_d),
		Vector3(-half_w - t, half_h + t, half_d),
		# Front inner (4-7): bottom-left, bottom-right, top-right, top-left
		Vector3(-half_w, -half_h, half_d),
		Vector3(half_w, -half_h, half_d),
		Vector3(half_w, half_h, half_d),
		Vector3(-half_w, half_h, half_d),
		# Back outer (8-11): bottom-left, bottom-right, top-right, top-left
		Vector3(-half_w - t, -half_h - t, -half_d),
		Vector3(half_w + t, -half_h - t, -half_d),
		Vector3(half_w + t, half_h + t, -half_d),
		Vector3(-half_w - t, half_h + t, -half_d),
		# Back inner (12-15): bottom-left, bottom-right, top-right, top-left
		Vector3(-half_w, -half_h, -half_d),
		Vector3(half_w, -half_h, -half_d),
		Vector3(half_w, half_h, -half_d),
		Vector3(-half_w, half_h, -half_d),
	]

	# Face definitions (quads as vertex indices)
	var faces = [
		# Front face - 4 strips between outer and inner
		[0, 1, 5, 4],   # Bottom strip
		[1, 2, 6, 5],   # Right strip
		[2, 3, 7, 6],   # Top strip
		[3, 0, 4, 7],   # Left strip
		# Back face - 4 strips between outer and inner
		[9, 8, 12, 13],   # Bottom strip
		[10, 9, 13, 14],  # Right strip
		[11, 10, 14, 15], # Top strip
		[8, 11, 15, 12],  # Left strip
		# Outer walls (connecting front outer to back outer)
		[0, 8, 9, 1],   # Bottom outer
		[1, 9, 10, 2],  # Right outer
		[2, 10, 11, 3], # Top outer
		[3, 11, 8, 0],  # Left outer
		# Inner walls (connecting front inner to back inner)
		[4, 5, 13, 12],  # Bottom inner
		[5, 6, 14, 13],  # Right inner
		[6, 7, 15, 14],  # Top inner
		[7, 4, 12, 15],  # Left inner
	]

	# Create mesh using SurfaceTool
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Convert quads to triangles
	for face in faces:
		var v0 = scaled_vertices[face[0]]
		var v1 = scaled_vertices[face[1]]
		var v2 = scaled_vertices[face[2]]
		var v3 = scaled_vertices[face[3]]

		# Calculate normal
		var edge1 = v1 - v0
		var edge2 = v3 - v0
		var normal = edge1.cross(edge2).normalized()

		# First triangle (v0, v1, v2)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v0)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v1)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v2)

		# Second triangle (v0, v2, v3)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v0)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v2)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v3)

	# Generate normals and create mesh
	surface_tool.generate_normals()
	mesh = surface_tool.commit()

	# Apply material
	apply_queer_material()

	# No rotation - keep upright as a portal/doorframe
	# The beam is now oriented with Y as height, X as width, Z as depth

	# Add collision
	var collision_body := create_collision()

	print("Portal frame created: Opening=%.2fx%.2f, Depth=%.2f, Wall=%.2f" % [width, height, depth, thickness])

func apply_queer_material():
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("base_color", base_color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)
		material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.4
		standard_material.roughness = 0.5
		mesh.surface_set_material(0, standard_material)

func create_collision() -> StaticBody3D:
	# Create parent static body
	var static_body = StaticBody3D.new()
	static_body.name = "BoxBeamCollision"
	add_child(static_body)

	var outer_w = width + thickness * 2
	var outer_h = height + thickness * 2
	var inner_w = width
	var inner_h = height

	# Left wall
	var left_col = CollisionShape3D.new()
	var left_box = BoxShape3D.new()
	left_box.size = Vector3(thickness, outer_h, depth)
	left_col.shape = left_box
	left_col.position = Vector3(-inner_w / 2 - thickness / 2, 0, 0)
	static_body.add_child(left_col)

	# Right wall
	var right_col = CollisionShape3D.new()
	var right_box = BoxShape3D.new()
	right_box.size = Vector3(thickness, outer_h, depth)
	right_col.shape = right_box
	right_col.position = Vector3(inner_w / 2 + thickness / 2, 0, 0)
	static_body.add_child(right_col)

	# Top wall
	var top_col = CollisionShape3D.new()
	var top_box = BoxShape3D.new()
	top_box.size = Vector3(inner_w, thickness, depth)
	top_col.shape = top_box
	top_col.position = Vector3(0, inner_h / 2 + thickness / 2, 0)
	static_body.add_child(top_col)

	# Bottom wall
	var bottom_col = CollisionShape3D.new()
	var bottom_box = BoxShape3D.new()
	bottom_box.size = Vector3(inner_w, thickness, depth)
	bottom_col.shape = bottom_box
	bottom_col.position = Vector3(0, -inner_h / 2 - thickness / 2, 0)
	static_body.add_child(bottom_col)

	return static_body

# Optional: Update mesh when parameters change in editor
func _process(_delta):
	if Engine.is_editor_hint() and mesh != null:
		# Only recreate if in editor (for live updates)
		pass

# Call this to update the beam with new parameters
func update_beam():
	create_beam()
