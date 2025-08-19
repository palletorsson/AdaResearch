extends Node3D

# Paint node 
var paint_container: Node3D
var canvas: MeshInstance3D

# Canvas properties
var canvas_size: Vector2 = Vector2(10, 6)
var background_color: Color = Color.WHITE

# Drip painting parameters
var max_line_width: float = 0.35
var new_size_influence: float = 0.5
var mid_point_push: float = 0.25

# Viscosity simulation
var paint_viscosity_types = [
	{"name": "Thin", "drip_speed": 2.0, "spread_factor": 1.5, "color_opacity": 0.8, "gravity_effect": 1.2},
	{"name": "Medium", "drip_speed": 1.0, "spread_factor": 1.0, "color_opacity": 0.9, "gravity_effect": 1.0},
	{"name": "Thick", "drip_speed": 0.6, "spread_factor": 0.7, "color_opacity": 1.0, "gravity_effect": 0.8}
]

# Automatic painting variables
var stroke_timer: Timer
var stroke_interval: float = 0.5  # Time between new strokes
var stroke_duration: float = 1.5   # Duration of each stroke
var active_strokes = []
var max_active_strokes = 3
var canvas_bounds = Rect2(-5, -3, 10, 6)  # Canvas boundaries in local space

# Animation tracking
var time_elapsed: float = 0.0

func _ready():
	randomize()
	
	# Create 3D canvas
	create_canvas()
	
	# Create container for all paint splatters
	paint_container = Node3D.new()
	paint_container.name = "Paint"
	add_child(paint_container)
	
	# Set up camera
	setup_camera()
	
	# Set up stroke timer
	setup_timer()

func setup_camera():
	# Create camera if not exists
	if not has_node("Camera3D"):
		var camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
		
	var camera = $Camera3D
	camera.position = Vector3(0, 0, 8)
	camera.current = true

func create_canvas():
	# Create a plane mesh for the canvas
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(canvas_size.x, canvas_size.y)
	
	# Create canvas mesh instance
	canvas = MeshInstance3D.new()
	canvas.name = "Canvas"
	canvas.mesh = plane_mesh
	
	# Create material for canvas
	var material = StandardMaterial3D.new()
	material.albedo_color = background_color
	material.roughness = 1.0
	canvas.material_override = material
	
	# Add canvas to scene
	add_child(canvas)
	
	# Rotate to face camera
	canvas.rotation_degrees.x = -90

func setup_timer():
	# Create timer for generating new strokes
	stroke_timer = Timer.new()
	stroke_timer.wait_time = stroke_interval
	stroke_timer.one_shot = false
	stroke_timer.autostart = true
	stroke_timer.connect("timeout", Callable(self, "_on_stroke_timer_timeout"))
	add_child(stroke_timer)

func _on_stroke_timer_timeout():
	# Start a new stroke if we haven't reached max active strokes
	if active_strokes.size() < max_active_strokes:
		start_new_stroke()

func _process(delta):
	time_elapsed += delta
	
	# Update active strokes
	var strokes_to_remove = []
	for i in range(active_strokes.size()):
		var stroke = active_strokes[i]
		
		# Update stroke progress
		stroke.time += delta
		var progress = stroke.time / stroke.duration
		
		if progress >= 1.0:
			# Stroke completed
			strokes_to_remove.append(stroke)
		else:
			# Continue animating stroke
			animate_stroke(stroke, progress)
	
	# Remove completed strokes
	for stroke in strokes_to_remove:
		active_strokes.erase(stroke)

func start_new_stroke():
	# Generate random start and end points within canvas bounds
	var start_pos = random_point_on_canvas()
	
	# Select random viscosity type
	var viscosity = paint_viscosity_types[randi() % paint_viscosity_types.size()]
	
	# Generate random control points
	var control_points = []
	var num_control_points = randi_range(3, 8)
	
	# First control point is start position
	control_points.append(start_pos)
	
	# Generate middle control points with some coherence
	var current_pos = start_pos
	for i in range(1, num_control_points):
		# Random movement direction but with some continuity
		var angle = randf_range(0, TAU)
		var distance = randf_range(0.5, 2.0)
		
		# Apply gravity effect based on viscosity
		# Add slight downward bias to simulate gravity
		var gravity_bias = Vector3(0, -0.2 * viscosity.gravity_effect, 0)
		var new_pos = current_pos + Vector3(cos(angle) * distance, sin(angle) * distance, 0) + gravity_bias
		
		# Ensure point is within canvas bounds
		new_pos.x = clamp(new_pos.x, canvas_bounds.position.x, canvas_bounds.position.x + canvas_bounds.size.x)
		new_pos.y = clamp(new_pos.y, canvas_bounds.position.y, canvas_bounds.position.y + canvas_bounds.size.y)
		
		control_points.append(new_pos)
		current_pos = new_pos
	
	# Create a curve from the control points
	var curve = Curve3D.new()
	for point in control_points:
		curve.add_point(point)
	
	# Random size and color for this stroke
	var stroke_width = randf_range(0.1, max_line_width) * viscosity.spread_factor
	var stroke_color = Color(randf(), randf(), randf(), viscosity.color_opacity)
	
	# Create stroke data
	var stroke = {
		"curve": curve,
		"color": stroke_color,
		"width": stroke_width,
		"time": 0.0,
		"duration": (stroke_duration + randf_range(-0.5, 0.5)) / viscosity.drip_speed,
		"node": Node3D.new(),
		"last_rendered_point": 0.0,
		"viscosity": viscosity
	}
	
	# Add node to scene
	paint_container.add_child(stroke.node)
	active_strokes.append(stroke)

func animate_stroke(stroke, progress):
	# How far along the curve we should be
	var target_point = progress
	
	# Only render new points (don't repeat what we've already drawn)
	var start_t = stroke.last_rendered_point
	var end_t = target_point
	
	# Nothing to draw if we're at the same point
	if abs(end_t - start_t) < 0.01:
		return
	
	# Number of points to render - affected by viscosity
	var viscosity = stroke.viscosity
	var steps = int(max(2, (end_t - start_t) * 20 * viscosity.drip_speed))
	
	for i in range(steps):
		var t = start_t + (end_t - start_t) * (float(i) / float(steps))
		var pos = stroke.curve.sample_baked(t * stroke.curve.get_baked_length())
		
		# Width tapers at the end
		var width_mod = 1.0 - pow(t, 2) * 0.5
		var point_width = stroke.width * width_mod
		
		# Add a paint splat at this point
		add_splat(stroke.node, pos, point_width, stroke.color)
		
		# Add drips based on viscosity and slope
		# If stroke is moving more downward, add more drips for thinner paint
		var curve_length = stroke.curve.get_baked_length()
		if curve_length > 0.1:
			var tangent = get_curve_tangent_at(stroke.curve, t)
			
			# Check if the stroke is moving downward
			if tangent.y > 0.1:
				# More drips for thinner paint on downward strokes
				var drip_probability = 0.2 / viscosity.spread_factor * tangent.y
				
				if randf() < drip_probability:
					add_paint_drip(stroke.node, pos, point_width, stroke.color, tangent, viscosity)
		
		# Add random splatters around main stroke - adjusted by viscosity
		var splatter_chance = 0.3 * viscosity.spread_factor
		if randf() < splatter_chance:
			add_random_splatters(stroke.node, pos, point_width, stroke.color, viscosity)
	
	# Remember where we left off
	stroke.last_rendered_point = end_t

func add_random_splatters(parent, pos, width, color, viscosity):
	# Number of splatters to add - affected by viscosity
	var count = randi_range(1, int(3 * viscosity.spread_factor))
	
	for i in range(count):
		# Random direction and distance from main point
		var angle = randf_range(0, TAU)
		var distance = width * randf_range(1.0, 5.0) * viscosity.spread_factor
		
		# Calculate position of splatter with a slight downward bias based on viscosity
		var gravity_bias = Vector3(0, 0.2 * viscosity.gravity_effect, 0) 
		var splat_pos = pos + Vector3(cos(angle) * distance, sin(angle) * distance, 0.01) + gravity_bias
		
		# Add splatter with random size
		var splat_size = width * randf_range(0.1, 0.5) * viscosity.spread_factor
		add_splat(parent, splat_pos, splat_size, color)
		
func add_paint_drip(parent, pos, width, color, direction, viscosity):
	# Create a drip that goes downward from the position
	var drip_length = randf_range(0.2, 1.0) / viscosity.spread_factor
	
	# Create mini-curve for the drip
	var drip_curve = Curve3D.new()
	drip_curve.add_point(pos)
	
	# Middle control point with some randomness
	var mid_point = pos + Vector3(
		randf_range(-0.2, 0.2), 
		drip_length * 0.5, 
		0.01
	)
	drip_curve.add_point(mid_point)
	
	# End point is directly below with gravity influence
	var end_point = pos + Vector3(
		randf_range(-0.3, 0.3) * viscosity.gravity_effect, 
		drip_length,
		0.01
	)
	drip_curve.add_point(end_point)
	
	# Create drip with points along the curve
	var steps = int(5 + 10 / viscosity.drip_speed)
	for i in range(steps):
		var t = float(i) / float(steps - 1)
		var drip_pos = drip_curve.sample_baked(t * drip_curve.get_baked_length())
		
		# Drips get thinner as they go down
		var drip_size = width * (1.0 - t * 0.9) * 0.3
		add_splat(parent, drip_pos, drip_size, color)
		
func get_curve_tangent_at(curve, t):
	var curve_length = curve.get_baked_length()
	var pos1 = curve.sample_baked(max(0, t - 0.01) * curve_length)
	var pos2 = curve.sample_baked(min(1, t + 0.01) * curve_length)
	return (pos2 - pos1).normalized()

func add_splat(parent: Node3D, position: Vector3, size: float, color: Color):
	# Create sphere for splatter
	var mesh = SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2
	
	var splat_instance = MeshInstance3D.new()
	splat_instance.mesh = mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	
	splat_instance.material_override = material
	splat_instance.position = position
	
	# Slightly random scale for more natural look
	var random_scale = randf_range(0.8, 1.2)
	splat_instance.scale = Vector3(random_scale, random_scale, random_scale * 0.3) # Flatten in Z
	
	parent.add_child(splat_instance)

func random_point_on_canvas() -> Vector3:
	# Generate a random point within canvas bounds
	var x = randf_range(canvas_bounds.position.x, canvas_bounds.position.x + canvas_bounds.size.x)
	var y = randf_range(canvas_bounds.position.y, canvas_bounds.position.y + canvas_bounds.size.y)
	return Vector3(x, y, 0.01)  # Small Z offset to appear above canvas

func _input(event):
	# Space key to clear canvas
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		clear_canvas()

func clear_canvas():
	# Remove all paint nodes and active strokes
	for child in paint_container.get_children():
		child.queue_free()
	active_strokes.clear()

func randf_range(min_val: float, max_val: float) -> float:
	return min_val + (max_val - min_val) * randf()

func randi_range(min_val: int, max_val: int) -> int:
	return min_val + randi() % (max_val - min_val + 1)
