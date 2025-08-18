extends Node3D

var time = 0.0
var field_resolution = 40
var field_size = 8.0
var sdf_points = []
var primitive_shapes = []

func _ready():
	create_primitive_shapes()
	generate_sdf_field()
	setup_materials()

func create_primitive_shapes():
	# Create shapes that will generate the SDF
	var sphere = CSGSphere3D.new()
	sphere.radius = 1.0
	sphere.position = Vector3(-2, 1, 0)
	$PrimitiveShapes.add_child(sphere)
	primitive_shapes.append({"type": "sphere", "position": Vector2(-2, 1), "radius": 1.0, "object": sphere})
	
	var box = CSGBox3D.new()
	box.size = Vector3(1.5, 1.5, 0.2)
	box.position = Vector3(2, -1, 0)
	$PrimitiveShapes.add_child(box)
	primitive_shapes.append({"type": "box", "position": Vector2(2, -1), "size": Vector2(0.75, 0.75), "object": box})

func generate_sdf_field():
	var field_parent = $SDFField
	
	for x in range(field_resolution):
		for y in range(field_resolution):
			var world_x = -field_size/2 + (x / float(field_resolution - 1)) * field_size
			var world_y = -field_size/2 + (y / float(field_resolution - 1)) * field_size
			var world_pos = Vector2(world_x, world_y)
			
			var distance = calculate_sdf_distance(world_pos)
			
			var point = CSGSphere3D.new()
			point.radius = 0.05
			point.position = Vector3(world_x, world_y, 0)
			field_parent.add_child(point)
			
			sdf_points.append({"position": world_pos, "distance": distance, "object": point})

func calculate_sdf_distance(pos: Vector2) -> float:
	var min_distance = INF
	
	for shape in primitive_shapes:
		var distance = 0.0
		
		match shape.type:
			"sphere":
				distance = pos.distance_to(shape.position) - shape.radius
			"box":
				var d = Vector2(abs(pos.x - shape.position.x), abs(pos.y - shape.position.y)) - shape.size
				distance = Vector2(max(d.x, 0), max(d.y, 0)).length() + min(max(d.x, d.y), 0)
		
		min_distance = min(min_distance, distance)
	
	return min_distance

func setup_materials():
	# Setup primitive shape materials
	for shape in primitive_shapes:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
		material.emission_enabled = true
		material.emission = Color(0.3, 0.2, 0.05, 1.0)
		shape.object.material_override = material
	
	update_sdf_visualization()

func update_sdf_visualization():
	for point in sdf_points:
		var material = StandardMaterial3D.new()
		var distance = point.distance
		
		# Color based on distance
		if distance < 0:
			# Inside - red gradient
			var intensity = min(abs(distance) / 2.0, 1.0)
			material.albedo_color = Color(1.0, 0.2 + intensity * 0.6, 0.2, 1.0)
		elif distance < 1.0:
			# Near boundary - yellow gradient
			var intensity = distance
			material.albedo_color = Color(1.0, 1.0, 0.2 + intensity * 0.6, 1.0)
		else:
			# Far - blue gradient
			var intensity = 1.0 - min(distance / 3.0, 1.0)
			material.albedo_color = Color(0.2, 0.2 + intensity * 0.6, 1.0, 1.0)
		
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.4
		point.object.material_override = material

func _process(delta):
	time += delta
	
	# Animate primitive shapes
	for i in range(primitive_shapes.size()):
		var shape = primitive_shapes[i]
		var wave = sin(time * 2.0 + i * PI) * 0.5
		
		if shape.type == "sphere":
			shape.position.x = -2 + wave
			shape.object.position.x = shape.position.x
		else:
			shape.position.y = -1 + wave
			shape.object.position.y = shape.position.y
	
	# Regenerate SDF field
	for point in sdf_points:
		point.distance = calculate_sdf_distance(point.position)
	
	update_sdf_visualization()
	animate_indicators()

func animate_indicators():
	# Field resolution indicator
	var resolution_height = (field_resolution / 50.0) * 2.0 + 0.5
	$FieldResolution.height = resolution_height
	$FieldResolution.position.y = -3 + resolution_height/2
	
	# Distance range indicator  
	var max_distance = 0.0
	for point in sdf_points:
		max_distance = max(max_distance, abs(point.distance))
	
	var range_height = min(max_distance / 5.0, 1.0) * 2.0 + 0.5
	$DistanceRange.size.y = range_height
	$DistanceRange.position.y = -3 + range_height/2
