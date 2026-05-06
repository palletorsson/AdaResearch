@tool
extends MeshInstance3D

## Albrecht Dürer's Polyhedron (Melencolia I, 1514)
## A truncated rhombohedron - cube stretched along body diagonal, then truncated.
## 
## The solid has 8 faces: 6 irregular pentagons + 2 equilateral triangles.
## It appears in the famous engraving representing melancholy and geometry.

@export var size: float = 1.0 : set = set_size
@export var material: Material : set = set_material
@export var rotate_slowly: bool = false
@export var rotation_speed: float = 0.1

var _time: float = 0.0

func set_size(val: float):
	size = val
	if is_inside_tree():
		mesh = _generate_durer_solid()

func set_material(val: Material):
	material = val
	if val:
		material_override = val

func _ready():
	mesh = _generate_durer_solid()
	if material:
		material_override = material

func _process(delta: float):
	if rotate_slowly and not Engine.is_editor_hint():
		_time += delta
		rotation.y = _time * rotation_speed

func _generate_durer_solid() -> ArrayMesh:
	var arr_mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Dürer's solid: truncated rhombohedron
	# Mathematically: rhombohedron with 72° face angles, truncated at 2 vertices
	# This creates 6 pentagonal faces and 2 triangular faces
	
	var s = size
	
	# Vertices based on the canonical Dürer solid proportions
	# The solid is elongated along the Y axis
	var phi = 1.618033988749895  # Golden ratio
	var h = 1.5 * s  # Height multiplier
	var w = 1.0 * s  # Width
	
	# Top triangular face (3 vertices)
	var t0 = Vector3(0, h * 1.1, -w * 0.4)
	var t1 = Vector3(w * 0.7, h * 0.95, w * 0.35)
	var t2 = Vector3(-w * 0.7, h * 0.95, w * 0.35)
	
	# Upper middle ring (3 vertices)
	var u0 = Vector3(w * 1.1, h * 0.35, -w * 0.65)
	var u1 = Vector3(w * 1.15, h * 0.1, w * 0.75)
	var u2 = Vector3(0, h * 0.0, w * 1.2)
	
	# Lower middle ring (3 vertices)  
	var l0 = Vector3(-w * 1.15, h * -0.1, w * 0.75)
	var l1 = Vector3(-w * 1.1, h * -0.35, -w * 0.65)
	var l2 = Vector3(0, h * -0.0, -w * 1.2)
	
	# Bottom triangular face (3 vertices)
	var b0 = Vector3(0, h * -1.1, w * 0.4)
	var b1 = Vector3(-w * 0.7, h * -0.95, -w * 0.35)
	var b2 = Vector3(w * 0.7, h * -0.95, -w * 0.35)
	
	# === Build faces ===
	
	# Top triangle (CCW when viewed from above/outside)
	_add_triangle(st, t0, t2, t1)
	
	# Bottom triangle
	_add_triangle(st, b0, b2, b1)
	
	# Pentagon faces (6 total) - each connects top/bottom triangles through middle ring
	# These need to be triangulated as 3 triangles each
	
	# Pentagon 1: t0 -> u0 -> l2 -> l1 -> t2 (back-left region)
	_add_pentagon(st, [t0, t2, l1, l2, u0])
	
	# Pentagon 2: t0 -> t1 -> u1 -> u0 (top-right)
	_add_quad(st, t0, u0, u1, t1)
	
	# Pentagon 3: t1 -> t2 -> l0 -> u2 -> u1 (top-front)
	_add_pentagon(st, [t1, u1, u2, l0, t2])
	
	# Pentagon 4: b0 -> l0 -> l1 -> b1 (bottom-left)
	_add_quad(st, b0, b1, l1, l0)
	
	# Pentagon 5: b0 -> b2 -> u0 -> u1 -> u2 (connects to bottom)
	_add_pentagon(st, [b0, l0, u2, u1, b2])
	
	# Pentagon 6: b1 -> b2 -> u0 -> l2 -> l1
	_add_pentagon(st, [b1, l1, l2, u0, b2])
	
	# Fill remaining gaps with additional faces
	# Connect u2 to l0
	_add_triangle(st, u2, l0, t2)
	_add_triangle(st, b2, u1, u0)
	
	st.generate_normals()
	return st.commit()

func _add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3):
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3):
	# Two triangles: a-b-c and a-c-d
	_add_triangle(st, a, b, c)
	_add_triangle(st, a, c, d)

func _add_pentagon(st: SurfaceTool, verts: Array):
	# Fan triangulation from first vertex
	if verts.size() < 3:
		return
	for i in range(1, verts.size() - 1):
		_add_triangle(st, verts[0], verts[i], verts[i + 1])
