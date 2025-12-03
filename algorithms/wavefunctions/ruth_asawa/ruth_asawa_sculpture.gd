@tool
extends MeshInstance3D

@export_category("Mesh Settings")
@export_range(10, 200, 1) var u_resolution: int = 60
@export_range(10, 200, 1) var v_resolution: int = 100
@export var radius_curve: Curve
@export var height: float = 10.0
@export var max_radius: float = 2.0
@export var wireframe: bool = true

@export_category("Animation")
@export var auto_rotate: bool = true
@export var rotation_speed: float = 0.5

func _ready():
	if not radius_curve:
		_create_default_curve()
	generate_surface()

func _process(delta):
	if auto_rotate:
		rotation.y += rotation_speed * delta

func _create_default_curve():
	radius_curve = Curve.new()
	# Create a lobed shape similar to the reference
	radius_curve.add_point(Vector2(0.0, 0.2))
	radius_curve.add_point(Vector2(0.1, 0.8)) # Lobe 1
	radius_curve.add_point(Vector2(0.2, 0.1)) # Pinch
	radius_curve.add_point(Vector2(0.35, 0.9)) # Lobe 2
	radius_curve.add_point(Vector2(0.5, 0.15)) # Pinch
	radius_curve.add_point(Vector2(0.7, 1.0)) # Lobe 3 (Big)
	radius_curve.add_point(Vector2(0.85, 0.2)) # Pinch
	radius_curve.add_point(Vector2(1.0, 0.4)) # Bottom

func generate_surface():
	var st := SurfaceTool.new()
	
	if wireframe:
		st.begin(Mesh.PRIMITIVE_LINES)
	else:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var u_max := TAU
	
	# Generate vertices
	for i in range(v_resolution + 1):
		var v_ratio = float(i) / float(v_resolution)
		var y = (v_ratio - 0.5) * height # Center vertically
		
		# Sample radius from curve
		var r = 1.0
		if radius_curve:
			r = radius_curve.sample(v_ratio) * max_radius
		
		for j in range(u_resolution + 1):
			var u_ratio = float(j) / float(u_resolution)
			var u = u_ratio * u_max
			
			var x = r * cos(u)
			var z = r * sin(u)
			
			# Add some "woven" offset for wireframe look if desired, 
			# but simple grid is fine for now.
			
			st.set_uv(Vector2(u_ratio, v_ratio))
			st.add_vertex(Vector3(x, -y, z)) # Invert y to match curve top-down logic usually

	# Generate indices
	for i in range(v_resolution):
		for j in range(u_resolution):
			var current = i * (u_resolution + 1) + j
			var next_row = (i + 1) * (u_resolution + 1) + j
			
			if wireframe:
				# Horizontal line
				st.add_index(current)
				st.add_index(current + 1)
				
				# Vertical line
				st.add_index(current)
				st.add_index(next_row)
			else:
				# Triangles
				st.add_index(current)
				st.add_index(current + 1)
				st.add_index(next_row)
				
				st.add_index(current + 1)
				st.add_index(next_row + 1)
				st.add_index(next_row)

	if not wireframe:
		st.generate_normals()
		st.generate_tangents()

	var generated_mesh := st.commit()
	if generated_mesh:
		var material := StandardMaterial3D.new()
		if wireframe:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_color = Color(0.3, 0.3, 0.3) # Dark wire
		else:
			material.albedo_color = Color(0.6, 0.6, 0.6)
			material.metallic = 0.5
			material.roughness = 0.5
			material.cull_mode = BaseMaterial3D.CULL_DISABLED # Show both sides
			
		generated_mesh.surface_set_material(0, material)
		mesh = generated_mesh
