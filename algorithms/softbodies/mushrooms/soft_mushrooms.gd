extends Node3D

@export var mushroom_count: int = 15
@export var spawn_area_size: Vector2 = Vector2(20, 20)
@export var stem_height_range: Vector2 = Vector2(0.5, 1.5)
@export var stem_radius: float = 0.2
@export var cap_radius_range: Vector2 = Vector2(0.6, 1.2)

func _ready() -> void:
	setup_scene()
	spawn_mushrooms()

func setup_scene() -> void:
	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 5, 15)
	cam.look_at(Vector3(0, 0, 0))
	add_child(cam)
	
	# Light
	var light = DirectionalLight3D.new()
	light.position = Vector3(10, 20, 10)
	light.look_at(Vector3.ZERO)
	light.shadow_enabled = true
	add_child(light)
	
	# Ground removed as per request

func spawn_mushrooms() -> void:
	for i in range(mushroom_count):
		var pos = Vector3(
			randf_range(-spawn_area_size.x/2, spawn_area_size.x/2),
			0,
			randf_range(-spawn_area_size.y/2, spawn_area_size.y/2)
		)
		create_mushroom(pos)

func create_mushroom(pos: Vector3) -> void:
	var stem_h = randf_range(stem_height_range.x, stem_height_range.y)
	var cap_r = randf_range(cap_radius_range.x, cap_radius_range.y)
	
	# 1. Stem (StaticBody)
	var stem = StaticBody3D.new()
	stem.position = pos + Vector3(0, stem_h/2.0, 0)
	
	var stem_mesh = CylinderMesh.new()
	stem_mesh.top_radius = stem_radius * 0.8 # Taper slightly
	stem_mesh.bottom_radius = stem_radius
	stem_mesh.height = stem_h
	
	var stem_vis = MeshInstance3D.new()
	stem_vis.mesh = stem_mesh
	stem.add_child(stem_vis)
	
	var stem_col = CollisionShape3D.new()
	stem_col.shape = CylinderShape3D.new()
	(stem_col.shape as CylinderShape3D).radius = stem_radius
	(stem_col.shape as CylinderShape3D).height = stem_h
	stem.add_child(stem_col)
	
	add_child(stem)
	
	# 2. Cap (SoftBody)
	var cap = SoftBody3D.new()
	
	var cap_mesh = SphereMesh.new()
	cap_mesh.radius = cap_r
	cap_mesh.height = cap_r # Hemisphere-ish (flattened bottom?) No, SphereMesh height controls full height.
	# To make it look like a mushroom cap, maybe we use a full sphere but pin the bottom center?
	# Or a hemisphere. SphereMesh has is_hemisphere? No.
	# We can use a SphereMesh and squash it?
	cap_mesh.height = cap_r * 1.5
	cap_mesh.radial_segments = 16
	cap_mesh.rings = 8
	
	cap.mesh = cap_mesh
	
	# Position cap on top of stem
	# Stem top is at pos.y + stem_h
	# Cap center should be slightly above that?
	cap.position = pos + Vector3(0, stem_h + cap_r * 0.5, 0)
	
	cap.total_mass = 1.0
	cap.linear_stiffness = 0.2
	cap.damping_coefficient = 0.05
	cap.pressure_coefficient = 0.5 # Inflated slightly
	cap.simulation_precision = 5
	
	# Material
	var mat = ShaderMaterial.new()
	mat.shader = load("res://commons/resourses/shaders/mushroom_dots.gdshader")
	
	# Randomize colors
	var hue = randf()
	var base_col = Color.from_hsv(hue, 0.8, 0.8)
	var dot_col = Color.from_hsv(fmod(hue + 0.5, 1.0), 0.2, 1.0) # Complementary-ish, pale
	
	mat.set_shader_parameter("base_color", base_col)
	mat.set_shader_parameter("dot_color", dot_col)
	mat.set_shader_parameter("dot_size", randf_range(0.2, 0.4))
	mat.set_shader_parameter("dot_spacing", randf_range(5.0, 15.0))
	
	cap.material_override = mat
	
	add_child(cap)
	
	# Pin the bottom of the cap to the stem
	call_deferred("_pin_cap_to_stem", cap, stem, cap_mesh.height)

func _pin_cap_to_stem(cap: SoftBody3D, stem: StaticBody3D, height: float) -> void:
	if not is_instance_valid(cap) or not is_instance_valid(stem):
		return
		
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(cap.mesh, 0)
	
	var min_y = INF
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		if v.y < min_y:
			min_y = v.y
			
	# Pin vertices at the bottom
	var pinned_indices = []
	# Pin bottom 25% of the height
	var pin_height_threshold = min_y + (height * 0.25)
	# Pin within a wider radius to ensure we catch vertices
	var pin_radius_sq = (stem_radius * 2.0) ** 2
	
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		if v.y < pin_height_threshold:
			if Vector2(v.x, v.z).length_squared() < pin_radius_sq:
				pinned_indices.append(i)
	
	print("Mushroom at ", stem.position, ": Pinning ", pinned_indices.size(), " vertices.")
	
	if not pinned_indices.is_empty():
		var path = stem.get_path()
		for idx in pinned_indices:
			cap.set_point_pinned(idx, true, path)
		
		# Collision exception
		cap.add_collision_exception_with(stem)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

