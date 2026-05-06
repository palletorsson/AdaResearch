# FoldedStrip.gd - Creates an editable strip of triangles acting like folded paper
extends Node3D

# @identity
# essence: triangle_strip(24) — alternating-height vertices forming a pleated ribbon of connected faces
# desire: learner feels how topology (which vertices connect) differs from geometry (where vertices are)
# critical_parameter: alternating high/low vertex heights — remove alternation and the pleat disappears
# triggers: dragging any of the 24 vertex grab spheres — adjacent triangles deform because they share edges
# emerges: mesh topology as a constraint — shared edges mean vertices drag each other's neighbours
# needs: [has 24 grabbable vertex handles [has], missing global fold-height or frequency slider]
# relationships: extends triangleprofiles into 3D; shows how strip topology enables organic forms
# truth: topology (which vertices are connected) is more fundamental than geometry (where they sit)

@export var color_main: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var color_alt: Color = Color(0.8, 0.2, 0.3, 1.0)

var vertex_color: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var sphere_scale: float = 0.3
@export var strip_y_offset: float = 0.25
@export var num_triangles: int = 24
@export var strip_length: float = 4.0
@export var base_y: float = 0.0
@export var height: float = 0.5

## Freeze behavior options
@export var alter_freeze : bool = false

var strip_mesh: MeshInstance3D
var drag_points: DragPointSet
var vertex_positions: Array[Vector3] = []

func _ready():
	strip_mesh = MeshInstance3D.new()
	strip_mesh.name = "StripMesh"
	add_child(strip_mesh)

	_initialize_straight_strip()
	_setup_drag_points()
	update_mesh()

func _initialize_straight_strip():
	# Create a straight strip along the X axis with alternating heights
	vertex_positions.clear()

	var num_verts = num_triangles + 2
	var segment_width = strip_length / float(num_verts - 1)
	var start_x = -strip_length / 2.0

	for i in range(num_verts):
		var x = start_x + i * segment_width

		# Alternate between front/back Z positions and vary height to make it stand
		# Even indices: front row (z positive), Odd indices: back row (z negative)
		var z_offset: float
		var y_val: float

		if i % 2 == 0:
			# Front row - lower, extends forward
			z_offset = 0.15
			y_val = base_y + height * 0.3 + strip_y_offset
		else:
			# Back row - higher, extends backward
			z_offset = -0.15
			y_val = base_y + height + strip_y_offset

		vertex_positions.append(Vector3(x, y_val, z_offset))

func _setup_drag_points():
	drag_points = DragPointSet.new()
	drag_points.name = "GrabPoints"
	add_child(drag_points)
	drag_points.point_moved.connect(_on_point_moved)

	var point_configs: Array = []
	for i in range(vertex_positions.size()):
		var col = color_main if (i % 2 == 0) else color_alt
		point_configs.append({
			"id": i,
			"name": "Grab_%02d" % i,
			"position": vertex_positions[i],
			"meta": {"point_index": i},
			"scale": sphere_scale,
			"color": col
		})

	drag_points.setup(point_configs, {
		"freeze_on_drop": true,
		"unfreeze_on_pickup": true
	})

func update_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.metallic_specular = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	strip_mesh.material_override = mat
	
	for i in range(num_triangles):
		if i + 2 >= vertex_positions.size():
			break
			
		var p0 = vertex_positions[i]
		var p1 = vertex_positions[i+1]
		var p2 = vertex_positions[i+2]
		
		# Alternating colors: Main vs Alt
		# Each fold (v0-v1-v2) is one triangle in the strip
		var col = color_main
		if i % 2 != 0:
			col = color_alt
			
		if i % 2 == 0:
			add_double_sided_triangle(st, p0, p1, p2, col)
		else:
			add_double_sided_triangle(st, p0, p1, p2, col)

	strip_mesh.mesh = st.commit()

func add_double_sided_triangle(st: SurfaceTool, v1, v2, v3, color: Color):
	var edge1 = v2 - v1
	var edge2 = v3 - v1
	var normal = edge1.cross(edge2).normalized()
	
	# Front
	st.set_color(color)
	st.set_normal(normal)
	st.set_uv(Vector2(0,0))
	st.add_vertex(v1)
	st.set_color(color)
	st.set_normal(normal)
	st.set_uv(Vector2(1,0))
	st.add_vertex(v2)
	st.set_color(color)
	st.set_normal(normal)
	st.set_uv(Vector2(0,1))
	st.add_vertex(v3)
	
	# Back
	st.set_color(color)
	st.set_normal(-normal)
	st.set_uv(Vector2(0,0))
	st.add_vertex(v1)
	st.set_color(color)
	st.set_normal(-normal)
	st.set_uv(Vector2(0,1))
	st.add_vertex(v3)
	st.set_color(color)
	st.set_normal(-normal)
	st.set_uv(Vector2(1,0))
	st.add_vertex(v2)

func apply_paper_material(mesh_instance: MeshInstance3D, color: Color):
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.95) # Paper white
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED # Render both sides anyway

	# To make it look cool, maybe use the shader?
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		var sm = ShaderMaterial.new()
		sm.shader = shader
		sm.set_shader_parameter("wireframe_color", Color.BLACK)
		sm.set_shader_parameter("fill_color", Color(0.95, 0.95, 1.0)) # White-blue paper
		mesh_instance.material_override = sm
	else:
		mesh_instance.material_override = material

func reset_strip():
	_initialize_straight_strip()
	if drag_points:
		drag_points.set_points_positions(vertex_positions)
	update_mesh()

func _on_point_moved(index: int, position: Vector3, meta: Dictionary) -> void:
	var point_index: int = int(meta.get("point_index", index))
	if point_index >= 0 and point_index < vertex_positions.size():
		if vertex_positions[point_index] != position:
			vertex_positions[point_index] = position
			update_mesh()

func _on_point_picked_up(_index: int, _pickable, _meta: Dictionary) -> void: pass
func _on_point_dropped(_index: int, _pickable, _meta: Dictionary) -> void: pass

func print_help():
	print("=== Folded Strip (Editable) ===")
	print("Drag any vertex sphere to reshape the strip.")
	print("R: Reset to standing position")
