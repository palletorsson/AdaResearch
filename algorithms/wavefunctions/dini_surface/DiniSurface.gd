@tool
extends MeshInstance3D

@export_group("Dini Parameters")
@export var a: float = 1.0: # Radius
	set(value):
		a = value
		if is_inside_tree(): _generate_mesh()

@export var b: float = 0.2: # Twist spacing
	set(value):
		b = value
		if is_inside_tree(): _generate_mesh()

@export_group("Resolution")
@export_range(10, 300) var u_segments: int = 100:
	set(value):
		u_segments = value
		if is_inside_tree(): _generate_mesh()

@export_range(10, 100) var v_segments: int = 50:
	set(value):
		v_segments = value
		if is_inside_tree(): _generate_mesh()

@export_group("Range")
@export var u_min: float = 0.0
@export var u_max: float = 12.56 # 4 * PI
@export var v_min: float = 0.1 # Avoid 0 (singularity)
@export var v_max: float = 2.0

@export var auto_update: bool = true

func _ready() -> void:
	_generate_mesh()

func _generate_mesh() -> void:
	if not auto_update and Engine.is_editor_hint(): return
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate grid of points
	for i in range(u_segments):
		for j in range(v_segments):
			# Calculate UV ratios
			var u_ratio = float(i) / float(u_segments - 1)
			var v_ratio = float(j) / float(v_segments - 1)
			
			# Map to parameter space
			var u = lerp(u_min, u_max, u_ratio)
			var v = lerp(v_min, v_max, v_ratio)
			
			# Calculate vertices for this quad (i,j) -> (i+1, j+1)
			# We need 4 points: (u,v), (u+du, v), (u+du, v+dv), (u, v+dv)
			# Actually, SurfaceTool is easier if we just add vertices and indices, 
			# but adding quads explicitly is robust.
			
			if i < u_segments - 1 and j < v_segments - 1:
				var p1 = _dini(u, v)
				var p2 = _dini(_get_u(i+1), v)
				var p3 = _dini(_get_u(i+1), _get_v(j+1))
				var p4 = _dini(u, _get_v(j+1))
				
				# UVs
				var uv1 = Vector2(u_ratio, v_ratio)
				var uv2 = Vector2(_get_u_ratio(i+1), v_ratio)
				var uv3 = Vector2(_get_u_ratio(i+1), _get_v_ratio(j+1))
				var uv4 = Vector2(u_ratio, _get_v_ratio(j+1))
				
				# Triangle 1
				st.set_uv(uv1)
				st.add_vertex(p1)
				st.set_uv(uv2)
				st.add_vertex(p2)
				st.set_uv(uv3)
				st.add_vertex(p3)
				
				# Triangle 2
				st.set_uv(uv1)
				st.add_vertex(p1)
				st.set_uv(uv3)
				st.add_vertex(p3)
				st.set_uv(uv4)
				st.add_vertex(p4)
	
	st.generate_normals()
	mesh = st.commit()

func _dini(u: float, v: float) -> Vector3:
	var x = a * cos(u) * sin(v)
	var y = a * sin(u) * sin(v)
	
	# z = a * (cos(v) + ln(tan(v/2))) + b * u
	# tan(v/2) can be close to 0, so clamp it slightly
	var tan_half_v = tan(v / 2.0)
	if tan_half_v <= 0: tan_half_v = 0.0001
	
	var z = a * (cos(v) + log(tan_half_v)) + b * u
	
	return Vector3(x, z, y) # Swapped Y/Z for Godot's Y-up

# Helpers
func _get_u(i: int) -> float:
	return lerp(u_min, u_max, float(i) / float(u_segments - 1))

func _get_v(j: int) -> float:
	return lerp(v_min, v_max, float(j) / float(v_segments - 1))

func _get_u_ratio(i: int) -> float:
	return float(i) / float(u_segments - 1)

func _get_v_ratio(j: int) -> float:
	return float(j) / float(v_segments - 1)
