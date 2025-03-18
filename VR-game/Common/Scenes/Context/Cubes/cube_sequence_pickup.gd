extends Node3D

# Preload the cube scene
var cube_scene = preload("res://adaresearch/Common/Scenes/Context/Cubes/cube_scene.tscn")

# Constants for the sequence
const CUBE_SPACING = 1.5
const OSCILLATION_SPEED = 2.0
const OSCILLATION_HEIGHT = 0.5
const ROTATION_SPEED = 1.0
const SCALE_SPEED = 1.5
const SCALE_INTENSITY = 0.1  # Reduced from 0.2 for more subtle scaling

# Names and descriptions for each transformation type
const TRANSFORMATION_TYPES = {
	"translation": "Translation - Moving an object in 3D space (X, Y, Z)",
	"rotation": "Rotation - Turning an object around its center axes",
	"scale": "Scale - Changing an object's size along each axis",
	"combined": "Combined - Multiple transformations working together"
}

# References to our cubes
var static_cube
var rotating_cube
var oscillating_cube
var random_cubes = []

# Visualization aids
var axis_markers = {}
var labels = {}

func _ready():
	# Create coordinate axes
	create_axes()
	
	# Start the sequence with explanatory text
	create_static_cube()
	await get_tree().create_timer(1.0).timeout
	create_rotating_cube()
	await get_tree().create_timer(1.0).timeout
	create_oscillating_cube()
	await get_tree().create_timer(1.0).timeout
	create_random_oscillating_cubes()

func create_axes():
	# Create axes visualization to show X, Y, Z directions
	var axes = Node3D.new()
	axes.name = "CoordinateAxes"
	add_child(axes)
	
	# Create X axis (red)
	var x_axis = CSGCylinder3D.new()
	x_axis.radius = 0.05
	x_axis.height = 10.0
	x_axis.rotation_degrees.z = 90
	x_axis.position = Vector3(5, 0, 0)
	var x_material = StandardMaterial3D.new()
	x_material.albedo_color = Color(1, 0, 0)  # Red
	x_material.emission_enabled = true
	x_material.emission = Color(1, 0, 0, 0.5)
	x_axis.material = x_material
	axes.add_child(x_axis)
	
	# Create Y axis (green)
	var y_axis = CSGCylinder3D.new()
	y_axis.radius = 0.05
	y_axis.height = 10.0
	y_axis.position = Vector3(0, 5, 0)
	var y_material = StandardMaterial3D.new()
	y_material.albedo_color = Color(0, 1, 0)  # Green
	y_material.emission_enabled = true
	y_material.emission = Color(0, 1, 0, 0.5)
	y_axis.material = y_material
	axes.add_child(y_axis)
	
	# Create Z axis (blue)
	var z_axis = CSGCylinder3D.new()
	z_axis.radius = 0.05
	z_axis.height = 10.0
	z_axis.rotation_degrees.x = 90
	z_axis.position = Vector3(0, 0, 5)
	var z_material = StandardMaterial3D.new()
	z_material.albedo_color = Color(0, 0, 1)  # Blue
	z_material.emission_enabled = true
	z_material.emission = Color(0, 0, 1, 0.5)
	z_axis.material = z_material
	axes.add_child(z_axis)
	
	# Add axis labels
	add_axis_label("X", Vector3(10, 0, 0), Color(1, 0, 0))
	add_axis_label("Y", Vector3(0, 10, 0), Color(0, 1, 0))
	add_axis_label("Z", Vector3(0, 0, 10), Color(0, 0, 1))

func add_axis_label(text, position, color):
	var label_3d = Label3D.new()
	label_3d.text = text
	label_3d.font_size = 64
	label_3d.modulate = color
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.position = position
	add_child(label_3d)

func create_transformation_marker(cube, transformation_type):
	# Add a floating label above the cube to explain the transformation
	var label = Label3D.new()
	label.text = TRANSFORMATION_TYPES[transformation_type]
	label.font_size = 24
	label.position = Vector3(0, 1.5, 0)  # Position above the cube
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cube.add_child(label)
	
	# Store the label reference
	labels[transformation_type] = label

func create_static_cube():
	# Create a simple static cube (demonstrates initial position/translation)
	static_cube = cube_scene.instantiate()
	static_cube.transform.origin = Vector3(-4.5, 1, -3)  # Position in front of player
	
	# Start with zero scale and animate up
	static_cube.scale = Vector3.ZERO
	add_child(static_cube)
	
	# Create transformation marker
	create_transformation_marker(static_cube, "translation")
	
	# Animate the scale
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(static_cube, "scale", Vector3.ONE, 0.5)
	
	# Add positional animation to demonstrate pure translation
	var position_tween = create_tween()
	position_tween.set_loops()  # Make it repeat indefinitely
	position_tween.tween_property(static_cube, "position:y", 1.5, 1.0)
	position_tween.tween_property(static_cube, "position:y", 0.5, 1.0)
	
	# Add visual trails to show the movement path
	_add_motion_trail(static_cube, "translation")

func create_rotating_cube():
	# Create a cube that rotates (demonstrates rotation)
	rotating_cube = cube_scene.instantiate()
	rotating_cube.transform.origin = Vector3(-1.5, 1, -3)  # Next to the first cube
	
	# Start with zero scale and animate up
	rotating_cube.scale = Vector3.ZERO
	add_child(rotating_cube)
	
	# Create transformation marker
	create_transformation_marker(rotating_cube, "rotation")
	
	# Animate the scale
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(rotating_cube, "scale", Vector3.ONE, 0.5)
	
	# Add visual aids to show rotation axes
	_add_rotation_axes(rotating_cube)

func create_oscillating_cube():
	# Create a cube that scales up and down
	oscillating_cube = cube_scene.instantiate()
	oscillating_cube.transform.origin = Vector3(1.5, 1, -3)  # Next to the rotating cube
	
	# Start with standard scale
	add_child(oscillating_cube)
	
	# Create transformation marker
	create_transformation_marker(oscillating_cube, "scale")
	
	# Add visual indicators for scale changes
	_add_scale_indicators(oscillating_cube)

func create_random_oscillating_cubes():
	# Create three cubes with random oscillation phase that also rotate
	for i in range(3):
		var cube = cube_scene.instantiate()
		cube.transform.origin = Vector3(4.5 + i * CUBE_SPACING, 1, -3)
		
		# Store random phase offsets for different transformations
		cube.set_meta("phase_offset", randf() * TAU)
		cube.set_meta("scale_offset", randf() * TAU)
		cube.set_meta("rotation_offset", randf() * TAU)
		
		# Give each cube a distinctive color
		if cube.has_node("MeshInstance3D"):
			var mesh_instance = cube.get_node("MeshInstance3D")
			var material = mesh_instance.get_surface_material(0)
			if material:
				# Try to modify existing material
				var new_material = material.duplicate()
				var hue = 0.1 + (i * 0.3)  # Spread colors across spectrum
				new_material.albedo_color = Color.from_hsv(hue, 0.8, 1.0)
				new_material.emission = Color.from_hsv(hue, 0.6, 0.8)
				mesh_instance.set_surface_override_material(0, new_material)
		
		# Start with zero scale and animate up
		cube.scale = Vector3.ZERO
		add_child(cube)
		random_cubes.append(cube)
		
		# Animate the scale with a slight delay between cubes
		await get_tree().create_timer(0.2).timeout
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(cube, "scale", Vector3.ONE, 0.5)
	
	# Add combined transformation marker to the middle cube (if there are 3)
	if random_cubes.size() >= 2:
		create_transformation_marker(random_cubes[1], "combined")

func _add_motion_trail(cube, type):
	# Add a trail effect to show the movement path
	var trail = Node3D.new()
	trail.name = "MotionTrail"
	cube.add_child(trail)
	
	# Store the trail node
	axis_markers[type + "_trail"] = trail

func _add_rotation_axes(cube):
	# Add visual indicators for rotation axes
	var axes = Node3D.new()
	axes.name = "RotationAxes"
	cube.add_child(axes)
	
	# X axis rotation indicator (red ring)
	var x_ring = CSGTorus3D.new()
	x_ring.inner_radius = 0.8
	x_ring.outer_radius = 0.85
	x_ring.ring_sides = 32
	x_ring.rotation_degrees.y = 90
	var x_material = StandardMaterial3D.new()
	x_material.albedo_color = Color(1, 0, 0, 0.7)  # Red with some transparency
	x_material.emission_enabled = true
	x_material.emission = Color(1, 0, 0, 0.3)
	x_ring.material = x_material
	axes.add_child(x_ring)
	
	# Y axis rotation indicator (green ring)
	var y_ring = CSGTorus3D.new()
	y_ring.inner_radius = 0.8
	y_ring.outer_radius = 0.85
	y_ring.ring_sides = 32
	y_ring.rotation_degrees.x = 90
	var y_material = StandardMaterial3D.new()
	y_material.albedo_color = Color(0, 1, 0, 0.7)  # Green with some transparency
	y_material.emission_enabled = true
	y_material.emission = Color(0, 1, 0, 0.3)
	y_ring.material = y_material
	axes.add_child(y_ring)
	
	# Z axis rotation indicator (blue ring)
	var z_ring = CSGTorus3D.new()
	z_ring.inner_radius = 0.8
	z_ring.outer_radius = 0.85
	z_ring.ring_sides = 32
	var z_material = StandardMaterial3D.new()
	z_material.albedo_color = Color(0, 0, 1, 0.7)  # Blue with some transparency
	z_material.emission_enabled = true
	z_material.emission = Color(0, 0, 1, 0.3)
	z_ring.material = z_material
	axes.add_child(z_ring)
	
	# Store the axes node
	axis_markers["rotation_axes"] = axes

func _add_scale_indicators(cube):
	# Add visual indicators for scale changes
	var indicators = Node3D.new()
	indicators.name = "ScaleIndicators"
	cube.add_child(indicators)
	
	# Create box outlines that show the min/max scale
	var min_box = CSGBox3D.new()
	min_box.size = Vector3(0.9, 0.9, 0.9)  # Slightly smaller than cube
	min_box.material = StandardMaterial3D.new()
	min_box.material.albedo_color = Color(1, 1, 0, 0.3)  # Yellow, semi-transparent
	min_box.material.emission_enabled = true
	min_box.material.emission = Color(1, 1, 0, 0.1)
	indicators.add_child(min_box)
	
	var max_box = CSGBox3D.new()
	max_box.size = Vector3(1.1, 1.1, 1.1)  # Slightly larger than cube
	max_box.material = StandardMaterial3D.new()
	max_box.material.albedo_color = Color(1, 0.5, 0, 0.3)  # Orange, semi-transparent
	max_box.material.emission_enabled = true
	max_box.material.emission = Color(1, 0.5, 0, 0.1)
	indicators.add_child(max_box)
	
	# Store the indicators node
	axis_markers["scale_indicators"] = indicators

func _process(delta):
	# Update the trailing dots for translation cube
	if static_cube and "translation_trail" in axis_markers:
		_update_motion_trail(static_cube, axis_markers["translation_trail"], delta)
	
	# Handle the rotating cube
	if rotating_cube:
		rotating_cube.rotate_y(ROTATION_SPEED * delta)
	
	# Handle the oscillating/scaling cube
	if oscillating_cube:
		var t = Time.get_ticks_msec() / 1000.0
		
		# Apply scaling effect
		var scale_factor = 1.0 + sin(t * SCALE_SPEED) * SCALE_INTENSITY
		oscillating_cube.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# Handle the randomly phased oscillating cubes with rotation and scale pulsing
	for cube in random_cubes:
		var phase_offset = cube.get_meta("phase_offset")
		var scale_offset = cube.get_meta("scale_offset")
		var rotation_offset = cube.get_meta("rotation_offset")
		var t = Time.get_ticks_msec() / 1000.0
		
		# Apply oscillation (translation)
		cube.transform.origin.y = 1 + sin(t * OSCILLATION_SPEED + phase_offset) * OSCILLATION_HEIGHT
		
		# Apply rotation
		var rotation_multiplier = 0.8 + (cube.get_index() * 0.2)  # Creates slight variation
		cube.rotate_y(ROTATION_SPEED * delta * rotation_multiplier)
		#cube.rotate_x(ROTATION_SPEED * delta * 0.5 * rotation_multiplier)
		
		# Apply scale pulsing
		var scale_factor = 1.0 + sin(t * SCALE_SPEED + scale_offset) * SCALE_INTENSITY
		cube.scale = Vector3(scale_factor, scale_factor, scale_factor)

func _update_motion_trail(object, trail_node, delta):
	# Create a dot every few frames to show the motion path
	if Engine.get_frames_drawn() % 10 == 0:
		var dot = CSGSphere3D.new()
		dot.radius = 0.05
		dot.position = Vector3.ZERO
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 1, 1, 0.5)
		material.emission_enabled = true
		material.emission = Color(1, 1, 1, 0.2)
		dot.material = material
		
		trail_node.add_child(dot)
		
		# Position the dot at the cube's world position
		dot.global_transform.origin = object.global_transform.origin
		
		# Limit the number of trail dots
		if trail_node.get_child_count() > 20:
			var oldest = trail_node.get_child(0)
			oldest.queue_free()
