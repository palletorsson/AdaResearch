extends Node3D

var time = 0.0
var shape_timer = 0.0
var shape_interval = 4.0
var resolution = 30
var current_u = 0.0
var current_v = 0.0

# Parametric shapes
enum ShapeType {
	CIRCLE,
	CONE,
	SPHERE,
	TORUS
}

var current_shape = ShapeType.CIRCLE
var shape_points = []
var parameter_lines = []

func _ready():
	setup_materials()
	generate_current_shape()

func setup_materials():
	# Shape indicator material
	var shape_material = StandardMaterial3D.new()
	shape_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	shape_material.emission_enabled = true
	shape_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$ShapeIndicator.material_override = shape_material
	
	# Parameter U material
	var param_u_material = StandardMaterial3D.new()
	param_u_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	param_u_material.emission_enabled = true
	param_u_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$ParameterU.material_override = param_u_material
	
	# Parameter V material
	var param_v_material = StandardMaterial3D.new()
	param_v_material.albedo_color = Color(0.3, 0.3, 1.0, 1.0)
	param_v_material.emission_enabled = true
	param_v_material.emission = Color(0.1, 0.1, 0.5, 1.0)
	$ParameterV.material_override = param_v_material

func _process(delta):
	time += delta
	shape_timer += delta
	
	if shape_timer >= shape_interval:
		shape_timer = 0.0
		current_shape = (current_shape + 1) % ShapeType.size()
		generate_current_shape()
	
	animate_parametric_shapes()
	animate_indicators()

func generate_current_shape():
	clear_shape_points()
	
	match current_shape:
		ShapeType.CIRCLE:
			generate_circle()
		ShapeType.CONE:
			generate_cone()
		ShapeType.SPHERE:
			generate_sphere()
		ShapeType.TORUS:
			generate_torus()

func clear_shape_points():
	for point in shape_points:
		point.queue_free()
	shape_points.clear()
	
	for line in parameter_lines:
		line.queue_free()
	parameter_lines.clear()

func generate_circle():
	# Parametric circle: x = r*cos(t), y = r*sin(t), z = 0
	var radius = 3.0
	
	for i in range(resolution):
		var t = i * 2.0 * PI / resolution
		var pos = Vector3(
			radius * cos(t),
			radius * sin(t),
			0
		)
		
		create_shape_point(pos, t, 0.0)

func generate_cone():
	# Parametric cone: x = (h-v)*cos(u), y = (h-v)*sin(u), z = v
	var height = 4.0
	var base_radius = 2.0
	
	for v_step in range(resolution / 2):
		var v = v_step * height / (resolution / 2)
		var radius_at_height = base_radius * (height - v) / height
		
		for u_step in range(resolution):
			var u = u_step * 2.0 * PI / resolution
			var pos = Vector3(
				radius_at_height * cos(u),
				radius_at_height * sin(u),
				v - height / 2
			)
			
			create_shape_point(pos, u, v)

func generate_sphere():
	# Parametric sphere: x = r*sin(v)*cos(u), y = r*sin(v)*sin(u), z = r*cos(v)
	var radius = 2.5
	
	for v_step in range(resolution / 2):
		var v = v_step * PI / (resolution / 2)
		
		for u_step in range(resolution):
			var u = u_step * 2.0 * PI / resolution
			var pos = Vector3(
				radius * sin(v) * cos(u),
				radius * sin(v) * sin(u),
				radius * cos(v)
			)
			
			create_shape_point(pos, u, v)

func generate_torus():
	# Parametric torus: x = (R+r*cos(v))*cos(u), y = (R+r*cos(v))*sin(u), z = r*sin(v)
	var major_radius = 2.5  # R
	var minor_radius = 1.0  # r
	
	for v_step in range(resolution / 2):
		var v = v_step * 2.0 * PI / (resolution / 2)
		
		for u_step in range(resolution):
			var u = u_step * 2.0 * PI / resolution
			var pos = Vector3(
				(major_radius + minor_radius * cos(v)) * cos(u),
				(major_radius + minor_radius * cos(v)) * sin(u),
				minor_radius * sin(v)
			)
			
			create_shape_point(pos, u, v)

func create_shape_point(position: Vector3, u_param: float, v_param: float):
	var point = CSGSphere3D.new()
	point.radius = 0.08
	point.position = position
	
	# Material based on parameters
	var point_material = StandardMaterial3D.new()
	var u_intensity = u_param / (2.0 * PI)
	var v_intensity = v_param / (2.0 * PI) if current_shape != ShapeType.CIRCLE else 0.5
	
	point_material.albedo_color = Color(
		0.3 + u_intensity * 0.7,
		0.3 + v_intensity * 0.7,
		0.8,
		1.0
	)
	point_material.emission_enabled = true
	point_material.emission = point_material.albedo_color * 0.4
	point.material_override = point_material
	
	# Store parameter information
	point.set_meta("u_param", u_param)
	point.set_meta("v_param", v_param)
	
	$ShapePoints.add_child(point)
	shape_points.append(point)

func animate_parametric_shapes():
	# Animate parameter sweep
	current_u = fmod(time * 0.5, 2.0 * PI)
	current_v = fmod(time * 0.3, 2.0 * PI)
	
	# Highlight points based on current parameter values
	for point in shape_points:
		var u_param = point.get_meta("u_param", 0.0)
		var v_param = point.get_meta("v_param", 0.0)
		
		# Calculate distance from current parameters
		var u_distance = abs(u_param - current_u)
		var v_distance = abs(v_param - current_v)
		
		# Normalize distances
		u_distance = min(u_distance, 2.0 * PI - u_distance)
		v_distance = min(v_distance, 2.0 * PI - v_distance)
		
		# Highlight if close to current parameters
		var u_highlight = exp(-u_distance * 2.0)
		var v_highlight = exp(-v_distance * 2.0)
		var total_highlight = max(u_highlight, v_highlight)
		
		var scale_factor = 1.0 + total_highlight * 0.8
		point.scale = Vector3.ONE * scale_factor
		
		# Update emission based on highlight
		var material = point.material_override as StandardMaterial3D
		if material:
			var base_emission = material.albedo_color * 0.4
			material.emission = base_emission * (1.0 + total_highlight * 2.0)
	
	# Animate shape transformation
	match current_shape:
		ShapeType.CIRCLE:
			animate_circle_variations()
		ShapeType.CONE:
			animate_cone_variations()
		ShapeType.SPHERE:
			animate_sphere_variations()
		ShapeType.TORUS:
			animate_torus_variations()

func animate_circle_variations():
	# Animate radius variation
	var radius_variation = 1.0 + sin(time * 2.0) * 0.3
	
	for point in shape_points:
		var original_pos = point.position
		var distance_from_origin = Vector2(original_pos.x, original_pos.y).length()
		if distance_from_origin > 0:
			var direction = Vector2(original_pos.x, original_pos.y).normalized()
			point.position = Vector3(
				direction.x * distance_from_origin * radius_variation,
				direction.y * distance_from_origin * radius_variation,
				original_pos.z
			)

func animate_cone_variations():
	# Animate cone opening angle
	var angle_variation = 1.0 + sin(time * 1.5) * 0.4
	
	for point in shape_points:
		var original_pos = point.position
		var height_factor = (original_pos.z + 2.0) / 4.0  # Normalize height
		point.position.x = original_pos.x * angle_variation
		point.position.y = original_pos.y * angle_variation

func animate_sphere_variations():
	# Animate sphere deformation
	for point in shape_points:
		var u_param = point.get_meta("u_param", 0.0)
		var v_param = point.get_meta("v_param", 0.0)
		
		var deformation = 1.0 + sin(u_param * 3.0 + time) * sin(v_param * 2.0 + time) * 0.2
		point.position = point.position.normalized() * 2.5 * deformation

func animate_torus_variations():
	# Animate torus parameters
	var major_variation = 1.0 + sin(time * 1.2) * 0.3
	var minor_variation = 1.0 + cos(time * 1.8) * 0.2
	
	for point in shape_points:
		var u_param = point.get_meta("u_param", 0.0)
		var v_param = point.get_meta("v_param", 0.0)
		
		var major_radius = 2.5 * major_variation
		var minor_radius = 1.0 * minor_variation
		
		point.position = Vector3(
			(major_radius + minor_radius * cos(v_param)) * cos(u_param),
			(major_radius + minor_radius * cos(v_param)) * sin(u_param),
			minor_radius * sin(v_param)
		)

func animate_indicators():
	# Shape indicator
	var shape_scale = 1.0 + sin(time * 3.0) * 0.1
	$ShapeIndicator.scale = Vector3.ONE * shape_scale
	
	# Update shape indicator color based on current shape
	var shape_material = $ShapeIndicator.material_override as StandardMaterial3D
	if shape_material:
		match current_shape:
			ShapeType.CIRCLE:
				shape_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
			ShapeType.CONE:
				shape_material.albedo_color = Color(1.0, 0.4, 0.2, 1.0)
			ShapeType.SPHERE:
				shape_material.albedo_color = Color(0.2, 1.0, 0.4, 1.0)
			ShapeType.TORUS:
				shape_material.albedo_color = Color(0.2, 0.4, 1.0, 1.0)
		
		shape_material.emission = shape_material.albedo_color * 0.3
	
	# Parameter U indicator
	var u_height = (current_u / (2.0 * PI)) * 2.0 + 0.5
	$ParameterU.size.y = u_height
	$ParameterU.position.y = -4 + u_height/2
	
	# Parameter V indicator
	var v_height = (current_v / (2.0 * PI)) * 2.0 + 0.5
	$ParameterV.size.y = v_height
	$ParameterV.position.y = -4 + v_height/2
	
	# Pulsing parameter indicators
	var param_pulse = 1.0 + sin(time * 4.0) * 0.1
	$ParameterU.scale.x = param_pulse
	$ParameterV.scale.x = param_pulse

func get_shape_name() -> String:
	match current_shape:
		ShapeType.CIRCLE:
			return "Circle"
		ShapeType.CONE:
			return "Cone"
		ShapeType.SPHERE:
			return "Sphere"
		ShapeType.TORUS:
			return "Torus"
		_:
			return "Unknown"

func get_parametric_equation() -> String:
	match current_shape:
		ShapeType.CIRCLE:
			return "x = r*cos(t), y = r*sin(t)"
		ShapeType.CONE:
			return "x = (h-v)*cos(u), y = (h-v)*sin(u), z = v"
		ShapeType.SPHERE:
			return "x = r*sin(v)*cos(u), y = r*sin(v)*sin(u), z = r*cos(v)"
		ShapeType.TORUS:
			return "x = (R+r*cos(v))*cos(u), y = (R+r*cos(v))*sin(u), z = r*sin(v)"
		_:
			return "Unknown"
