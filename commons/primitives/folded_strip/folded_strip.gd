# FoldedStrip.gd - Creates an editable strip of triangles acting like folded paper
extends Node3D

@export var color_main: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var color_alt: Color = Color(0.8, 0.2, 0.3, 1.0)

var vertex_color: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var sphere_size_multiplier: float = 0.5
@export var strip_y_offset: float = 1.0
@export var num_triangles: int = 24

## Freeze behavior options
@export var alter_freeze : bool = false

var strip_mesh: MeshInstance3D
var drag_points: DragPointSet
var vertex_positions: Array[Vector3] = []

func _ready():
	strip_mesh = MeshInstance3D.new()
	strip_mesh.name = "StripMesh"
	add_child(strip_mesh)

	_initialize_zig_zag_strip()
	update_mesh()

func _initialize_zig_zag_strip():
	# Badakine / Baldachin around a square
	vertex_positions.clear()
	
	var height_top = 2.5
	var height_bot = 0.5
	
	# Square perimeter path
	var side_len = 5.0
	var total_perimeter = side_len * 4.0
	var segment_len = total_perimeter / (num_triangles + 1)
	
	# We walk around a square
	var h = side_len / 2.0
	
	var corners = [
		Vector3(-h, 0, -h),
		Vector3(h, 0, -h),
		Vector3(h, 0, h),
		Vector3(-h, 0, h),
		Vector3(-h, 0, -h) # Loop back
	]
	
	for i in range(num_triangles + 2):
		var pair_idx = floor(i / 2)
		var is_top = (i % 2) != 0
		
		# Distance along perimeter
		var dist = pair_idx * (segment_len * 0.5) # Roughly fit? 
		# Let's map normalized t to the square path
		var t = float(pair_idx) / float((num_triangles + 2)/2) 
		if t > 1.0: t = 1.0
		
		var pos_on_perim = _get_point_on_square_path(t, corners)
		var y = height_bot
		if is_top: y = height_top
		
		vertex_positions.append(Vector3(pos_on_perim.x, y + strip_y_offset, pos_on_perim.z))

func _get_point_on_square_path(t: float, corners: Array[Vector3]) -> Vector3:
	var total_len = 0.0
	var lengths = []
	for i in range(corners.size() - 1):
		var l = corners[i].distance_to(corners[i+1])
		lengths.append(l)
		total_len += l
		
	var target_dist = t * total_len
	var current_dist = 0.0
	
	for i in range(corners.size() - 1):
		var l = lengths[i]
		if current_dist + l >= target_dist:
			var seg_t = (target_dist - current_dist) / l
			return corners[i].lerp(corners[i+1], seg_t)
		current_dist += l
	
	return corners[corners.size()-1]

func update_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
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
	material.roughness = 0.8
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
	_initialize_zig_zag_strip()
	if drag_points:
		drag_points.set_points_positions(vertex_positions)
	update_mesh()

func _on_point_moved(index: int, position: Vector3, _meta: Dictionary) -> void:
	if index < 0 or index >= vertex_positions.size():
		return
	vertex_positions[index] = position
	update_mesh()

func _on_point_picked_up(index: int, _pickable, _meta: Dictionary) -> void: pass
func _on_point_dropped(index: int, _pickable, _meta: Dictionary) -> void: pass

func print_help():
	print("=== Folded Strip (Origami) ===")
	print("Drag any vertex to fold the strip.")
	print("R: Reset to zig-zag")
