# VerletCloth.gd
# VR Interactive Verlet Integration Cloth for Godot 4
extends MeshInstance3D

class_name VerletCloth

# Cloth parameters
@export var cloth_width: int = 20
@export var cloth_height: int = 20
@export var cloth_size: float = 2.0
@export var damping: float = 0.99
@export var gravity: float = -9.8
@export var constraint_iterations: int = 3
@export var constraint_strength: float = 1.0

# VR hand tracking
@export var left_hand_controller: XRController3D
@export var right_hand_controller: XRController3D
@export var hand_collision_radius: float = 0.08

# Cloth point class
class ClothPoint:
	var position: Vector3
	var old_position: Vector3
	var acceleration: Vector3
	var pinned: bool
	var mass: float
	
	func _init(pos: Vector3, is_pinned: bool = false):
		position = pos
		old_position = pos
		acceleration = Vector3.ZERO
		pinned = is_pinned
		mass = 1.0
	
	func update(delta_time: float, gravity_force: float, damping_factor: float):
		if pinned:
			return
		
		# Verlet integration
		var velocity = (position - old_position) * damping_factor
		old_position = position
		
		# Apply gravity
		acceleration.y = gravity_force
		
		# Update position using Verlet integration
		position += velocity + acceleration * delta_time * delta_time
		
		# Reset acceleration
		acceleration = Vector3.ZERO

# Cloth constraint class
class ClothConstraint:
	var point1: ClothPoint
	var point2: ClothPoint
	var rest_length: float
	var strength: float
	
	func _init(p1: ClothPoint, p2: ClothPoint, constraint_strength: float = 1.0):
		point1 = p1
		point2 = p2
		rest_length = p1.position.distance_to(p2.position)
		strength = constraint_strength
	
	func satisfy():
		var delta = point2.position - point1.position
		var distance = delta.length()
		if distance == 0:
			return
		
		var difference = (rest_length - distance) / distance
		var translate = delta * difference * 0.5 * strength
		
		if not point1.pinned:
			point1.position -= translate
		if not point2.pinned:
			point2.position += translate

# Cloth simulation variables
var points: Array[ClothPoint] = []
var constraints: Array[ClothConstraint] = []
var cloth_mesh: ArrayMesh
var vertices: PackedVector3Array
var normals: PackedVector3Array
var uvs: PackedVector2Array
var indices: PackedInt32Array
var spacing: float

# Wind and external forces
var wind_force: Vector3 = Vector3.ZERO
var wind_timer: float = 0.0

func _ready():
	spacing = cloth_size / cloth_width
	init_cloth()
	create_mesh()
	
	# Connect VR controller signals if available
	if left_hand_controller:
		left_hand_controller.button_pressed.connect(_on_left_hand_button_pressed)
		left_hand_controller.button_released.connect(_on_left_hand_button_released)
	
	if right_hand_controller:
		right_hand_controller.button_pressed.connect(_on_right_hand_button_pressed)
		right_hand_controller.button_released.connect(_on_right_hand_button_released)

func init_cloth():
	points.clear()
	constraints.clear()
	
	# Create cloth points
	for y in range(cloth_height + 1):
		for x in range(cloth_width + 1):
			var pos_x = (x - cloth_width / 2.0) * spacing
			var pos_y = 1.0 + (cloth_height - y) * spacing
			var pos_z = 0.0
			
			# Pin top corners and some top edge points for realistic hanging
			var is_pinned = (y == 0 and (x == 0 or x == cloth_width or x % 4 == 0))
			
			points.append(ClothPoint.new(Vector3(pos_x, pos_y, pos_z), is_pinned))
	
	# Create constraints
	for y in range(cloth_height + 1):
		for x in range(cloth_width + 1):
			var index = y * (cloth_width + 1) + x
			
			# Horizontal constraints
			if x < cloth_width:
				constraints.append(ClothConstraint.new(points[index], points[index + 1], constraint_strength))
			
			# Vertical constraints
			if y < cloth_height:
				constraints.append(ClothConstraint.new(points[index], points[index + cloth_width + 1], constraint_strength))
			
			# Diagonal constraints for stability
			if x < cloth_width and y < cloth_height:
				constraints.append(ClothConstraint.new(points[index], points[index + cloth_width + 2], constraint_strength * 0.5))
				constraints.append(ClothConstraint.new(points[index + 1], points[index + cloth_width + 1], constraint_strength * 0.5))

func create_mesh():
	cloth_mesh = ArrayMesh.new()
	
	# Initialize arrays
	vertices = PackedVector3Array()
	normals = PackedVector3Array()
	uvs = PackedVector2Array()
	indices = PackedInt32Array()
	
	# Create vertices and UVs
	for i in range(points.size()):
		vertices.append(points[i].position)
		var x = i % (cloth_width + 1)
		var y = i / (cloth_width + 1)
		uvs.append(Vector2(float(x) / cloth_width, float(y) / cloth_height))
	
	# Create indices for triangles
	for y in range(cloth_height):
		for x in range(cloth_width):
			var top_left = y * (cloth_width + 1) + x
			var top_right = top_left + 1
			var bottom_left = (y + 1) * (cloth_width + 1) + x
			var bottom_right = bottom_left + 1
			
			# First triangle
			indices.append(top_left)
			indices.append(bottom_left)
			indices.append(top_right)
			
			# Second triangle
			indices.append(top_right)
			indices.append(bottom_left)
			indices.append(bottom_right)
	
	# Calculate initial normals
	calculate_normals()
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	cloth_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = cloth_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED # Double-sided for VR
	material.albedo_color = Color(0.3, 0.3, 0.8, 0.9)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	set_surface_override_material(0, material)

func _physics_process(delta):
	# Add some random wind
	wind_timer += delta
	if wind_timer > 2.0:
		wind_force = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.5
		wind_timer = 0.0
	
	# Update cloth physics
	update_cloth_physics(delta)
	
	# Handle VR hand collisions
	handle_vr_collisions()
	
	# Update mesh
	update_mesh()

func update_cloth_physics(delta_time: float):
	# Update all points
	for point in points:
		point.update(delta_time, gravity, damping)
		
		# Apply wind force
		if not point.pinned:
			point.acceleration += wind_force * 0.1
	
	# Satisfy constraints multiple times for stability
	for iteration in range(constraint_iterations):
		for constraint in constraints:
			constraint.satisfy()

func handle_vr_collisions():
	var hand_positions = []
	
	# Get hand positions from VR controllers
	if left_hand_controller and left_hand_controller.is_button_pressed("trigger"):
		hand_positions.append(left_hand_controller.global_position)
	
	if right_hand_controller and right_hand_controller.is_button_pressed("trigger"):
		hand_positions.append(right_hand_controller.global_position)
	
	# Check collisions with each hand
	for hand_pos in hand_positions:
		for point in points:
			var distance = point.position.distance_to(hand_pos)
			if distance < hand_collision_radius:
				# Push point away from hand
				var direction = (point.position - hand_pos).normalized()
				point.position = hand_pos + direction * hand_collision_radius
				
				# Add some dampening to prevent jittering
				point.old_position = point.position

func update_mesh():
	# Update vertex positions
	for i in range(points.size()):
		vertices[i] = points[i].position
	
	# Recalculate normals
	calculate_normals()
	
	# Update mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	cloth_mesh.clear_surfaces()
	cloth_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func calculate_normals():
	normals.clear()
	normals.resize(vertices.size())
	
	# Initialize all normals to zero
	for i in range(normals.size()):
		normals[i] = Vector3.ZERO
	
	# Calculate face normals and accumulate
	for i in range(0, indices.size(), 3):
		var i1 = indices[i]
		var i2 = indices[i + 1]
		var i3 = indices[i + 2]
		
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		var v3 = vertices[i3]
		
		var normal = (v2 - v1).cross(v3 - v1).normalized()
		
		normals[i1] += normal
		normals[i2] += normal
		normals[i3] += normal
	
	# Normalize all vertex normals
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()

# VR interaction methods
func grab_cloth_at_position(world_pos: Vector3, radius: float = 0.1) -> ClothPoint:
	var closest_point: ClothPoint = null
	var closest_distance: float = INF
	
	for point in points:
		var distance = point.position.distance_to(world_pos)
		if distance < radius and distance < closest_distance:
			closest_distance = distance
			closest_point = point
	
	if closest_point:
		closest_point.pinned = true
		closest_point.position = world_pos
	
	return closest_point

func release_cloth_point(point: ClothPoint):
	if point:
		point.pinned = false

func add_wind_force(force: Vector3):
	wind_force = force

func set_gravity(new_gravity: float):
	gravity = new_gravity

# VR controller button handlers
func _on_left_hand_button_pressed(button: String):
	if button == "grip":
		var grab_pos = left_hand_controller.global_position
		grab_cloth_at_position(grab_pos, hand_collision_radius * 1.5)

func _on_left_hand_button_released(button: String):
	if button == "grip":
		# Release any grabbed points near the hand
		var hand_pos = left_hand_controller.global_position
		for point in points:
			if point.pinned and point.position.distance_to(hand_pos) < hand_collision_radius * 2:
				release_cloth_point(point)

func _on_right_hand_button_pressed(button: String):
	if button == "grip":
		var grab_pos = right_hand_controller.global_position
		grab_cloth_at_position(grab_pos, hand_collision_radius * 1.5)

func _on_right_hand_button_released(button: String):
	if button == "grip":
		# Release any grabbed points near the hand
		var hand_pos = right_hand_controller.global_position
		for point in points:
			if point.pinned and point.position.distance_to(hand_pos) < hand_collision_radius * 2:
				release_cloth_point(point)

# Utility methods for external control
func pin_corner(corner: String):
	match corner:
		"top_left":
			points[0].pinned = true
		"top_right":
			points[cloth_width].pinned = true
		"bottom_left":
			points[cloth_height * (cloth_width + 1)].pinned = true
		"bottom_right":
			points[cloth_height * (cloth_width + 1) + cloth_width].pinned = true

func unpin_corner(corner: String):
	match corner:
		"top_left":
			points[0].pinned = false
		"top_right":
			points[cloth_width].pinned = false
		"bottom_left":
			points[cloth_height * (cloth_width + 1)].pinned = false
		"bottom_right":
			points[cloth_height * (cloth_width + 1) + cloth_width].pinned = false

func reset_cloth():
	init_cloth()
	create_mesh()
