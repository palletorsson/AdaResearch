@tool
extends Node3D

# Throne Chair: Imposing, royal design using procedural geometry

@export var base_color: Color = Color(0.4, 0.1, 0.1) # Dark Red/Royal
@export var gold_color: Color = Color(1.0, 0.84, 0.0) # Gold

func _ready():
	_create_throne()

func _create_throne():
	for child in get_children():
		child.queue_free()
		
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Thrive Geometry Construction
	# 1. Solid Base (Block)
	_add_box(st, Vector3(0, 0.2, 0), Vector3(0.8, 0.4, 0.8))
	
	# 2. Seat Cushion (Slightly inset)
	_add_box(st, Vector3(0, 0.45, 0), Vector3(0.7, 0.1, 0.7))
	
	# 3. High Back (Tall slab)
	_add_box(st, Vector3(0, 1.2, -0.35), Vector3(0.8, 1.6, 0.1))
	
	# 4. Armrests (Side blocks)
	_add_box(st, Vector3(-0.35, 0.6, 0.1), Vector3(0.1, 0.4, 0.6)) # Left
	_add_box(st, Vector3(0.35, 0.6, 0.1), Vector3(0.1, 0.4, 0.6))  # Right
	
	# 5. "Crown" Spikes on top of back
	# Center Spike
	_add_pyramid(st, Vector3(0, 2.1, -0.35), Vector3(0.2, 0.2, 0.1))
	# Side Spikes
	_add_pyramid(st, Vector3(-0.3, 2.05, -0.35), Vector3(0.15, 0.15, 0.1))
	_add_pyramid(st, Vector3(0.3, 2.05, -0.35), Vector3(0.15, 0.15, 0.1))

	var mesh_instance = MeshInstance3D.new()
	st.generate_normals()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "ThroneMesh"
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.metallic = 0.1
	mat.roughness = 0.6
	mesh_instance.material_override = mat
	add_child(mesh_instance)
	
	# Add Gold Trim (node based for simplicity)
	var trim_mesh = BoxMesh.new()
	trim_mesh.size = Vector3(0.82, 1.62, 0.12) # Slightly larger than back
	var trim = MeshInstance3D.new()
	trim.mesh = trim_mesh
	trim.position = Vector3(0, 1.2, -0.35)
	
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = gold_color
	gold_mat.metallic = 1.0
	gold_mat.roughness = 0.2
	trim.material_override = gold_mat
	
	# We want the trim to outline, so we make it scale slightly differently or use multiple pieces.
	# Let's just create gold pillars for the back sides
	trim.queue_free() # Nevermind box trim
	
	_create_gold_pillar(Vector3(-0.4, 1.2, -0.35), Vector3(0.05, 1.6, 0.05), gold_mat)
	_create_gold_pillar(Vector3(0.4, 1.2, -0.35), Vector3(0.05, 1.6, 0.05), gold_mat)
	
	# Collision
	var body = StaticBody3D.new()
	add_child(body)
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.8, 2.0, 0.8)
	shape.shape = box
	shape.position = Vector3(0, 1.0, 0)
	body.add_child(shape)

func _create_gold_pillar(pos, size, mat):
	var m = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.position = pos
	m.material_override = mat
	add_child(m)

func _add_box(st: SurfaceTool, center: Vector3, size: Vector3):
	var half = size * 0.5
	var v = [
		center + Vector3(-half.x, -half.y, half.z), # 0: BLF
		center + Vector3(half.x, -half.y, half.z),  # 1: BRF
		center + Vector3(half.x, half.y, half.z),   # 2: TRF
		center + Vector3(-half.x, half.y, half.z),  # 3: TLF
		center + Vector3(-half.x, -half.y, -half.z),# 4: BLB
		center + Vector3(half.x, -half.y, -half.z), # 5: BRB
		center + Vector3(half.x, half.y, -half.z),  # 6: TRB
		center + Vector3(-half.x, half.y, -half.z)  # 7: TLB
	]
	
	# Front
	_add_quad(st, v[0], v[1], v[2], v[3])
	# Back
	_add_quad(st, v[5], v[4], v[7], v[6])
	# Left
	_add_quad(st, v[4], v[0], v[3], v[7])
	# Right
	_add_quad(st, v[1], v[5], v[6], v[2])
	# Top
	_add_quad(st, v[3], v[2], v[6], v[7])
	# Bottom
	_add_quad(st, v[4], v[5], v[1], v[0])

func _add_pyramid(st: SurfaceTool, center: Vector3, size: Vector3):
	var half = size * 0.5
	var top = center + Vector3(0, half.y, 0)
	var v = [
		center + Vector3(-half.x, -half.y, half.z),
		center + Vector3(half.x, -half.y, half.z),
		center + Vector3(half.x, -half.y, -half.z),
		center + Vector3(-half.x, -half.y, -half.z)
	]
	
	_add_tri(st, v[0], v[1], top)
	_add_tri(st, v[1], v[2], top)
	_add_tri(st, v[2], v[3], top)
	_add_tri(st, v[3], v[0], top)
	_add_quad(st, v[3], v[2], v[1], v[0]) # Base

func _add_quad(st, a, b, c, d):
	_add_tri(st, a, b, c)
	_add_tri(st, a, c, d)

func _add_tri(st, a, b, c):
	# Calculate normal
	var n = (b - a).cross(c - a).normalized()
	st.set_normal(n)
	st.set_uv(Vector2(0, 0)); st.add_vertex(a)
	st.set_normal(n)
	st.set_uv(Vector2(1, 0)); st.add_vertex(b)
	st.set_normal(n)
	st.set_uv(Vector2(1, 1)); st.add_vertex(c)
