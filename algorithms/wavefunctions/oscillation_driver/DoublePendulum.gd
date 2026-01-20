extends Node3D

## Double Pendulum Demo
## Demonstrates Chaos Theory: Sensitive dependence on initial conditions
## A double pendulum is a simple physical system that exhibits rich dynamic behavior
## Agent-VisualizationExpert: Chaos visualization
## Protocol: IACP v2.2

# The Driver (Double Pendulum)
@onready var pivot: Node3D = $Pivot
@onready var rod1: MeshInstance3D = $Pivot/Rod1
@onready var joint1: Node3D = $Pivot/Joint1
@onready var rod2: MeshInstance3D = $Pivot/Joint1/Rod2
@onready var bob2: MeshInstance3D = $Pivot/Joint1/Bob2
@onready var raycast: RayCast3D = $Pivot/Joint1/Bob2/RayCast3D

# The Product (Chaotic Trail)
@onready var trail_mesh: ImmediateMesh
@onready var trail_instance: MeshInstance3D = $Trail

# Physics Parameters
@export var m1: float = 10.0 # Mass 1
@export var m2: float = 10.0 # Mass 2
@export var l1: float = 1.5 # Length 1
@export var l2: float = 1.5 # Length 2
@export var g: float = 9.81
@export var damping: float = 0.000 # Small damping to keep it stable long-term

# Initial State
@export var theta1_start: float = 90.0 # Degrees
@export var theta2_start: float = 90.0 # Degrees

# Visualization Parameters
@export var time_speed: float = 1.0 # Speed of Z-axis movement
@export var max_trail_length: int = 1000
# State variables
var theta1: float = 0.0
var theta2: float = 0.0
var omega1: float = 0.0
var omega2: float = 0.0
var trail_points: Array[Vector3] = []

func _ready():
	_setup_visuals()

	# Initialize angles
	theta1 = deg_to_rad(theta1_start)
	theta2 = deg_to_rad(theta2_start)

	# Setup visual lengths
	rod1.position.y = -l1 / 2.0
	rod1.mesh.height = l1
	joint1.position.y = -l1

	rod2.position.y = -l2 / 2.0
	rod2.mesh.height = l2
	bob2.position.y = -l2

	# Enable raycast for canvas drawing
	if raycast:
		raycast.enabled = true

func _setup_visuals():
	trail_mesh = ImmediateMesh.new()
	trail_instance.mesh = trail_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.2, 0.0) # Orange-Red chaotic trail
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.use_point_size = true
	material.point_size = 2.0
	trail_instance.material_override = material

func _process(delta):
	# --- PHYSICS SIMULATION ---
	# Double Pendulum Equations of Motion
	# Numerator/Denominator breakdown for readability
	
	var num1 = -g * (2 * m1 + m2) * sin(theta1)
	var num2 = -m2 * g * sin(theta1 - 2 * theta2)
	var num3 = -2 * sin(theta1 - theta2) * m2
	var num4 = omega2 * omega2 * l2 + omega1 * omega1 * l1 * cos(theta1 - theta2)
	var den = l1 * (2 * m1 + m2 - m2 * cos(2 * theta1 - 2 * theta2))
	
	var alpha1 = (num1 + num2 + num3 * num4) / den
	
	num1 = 2 * sin(theta1 - theta2)
	num2 = (omega1 * omega1 * l1 * (m1 + m2))
	num3 = g * (m1 + m2) * cos(theta1)
	num4 = omega2 * omega2 * l2 * m2 * cos(theta1 - theta2)
	den = l2 * (2 * m1 + m2 - m2 * cos(2 * theta1 - 2 * theta2))
	
	var alpha2 = (num1 * (num2 + num3 + num4)) / den
	
	# Integrate
	omega1 += alpha1 * delta
	omega2 += alpha2 * delta
	
	# Damping
	omega1 *= (1.0 - damping)
	omega2 *= (1.0 - damping)
	
	theta1 += omega1 * delta
	theta2 += omega2 * delta
	
	# --- VISUALIZATION UPDATE ---
	# Apply rotations
	pivot.rotation.z = theta1
	joint1.rotation.z = theta2 - theta1 # Relative rotation
	
	# --- DRIVE PRODUCT CUBE ---
	if has_node("ProductCube"):
		var cube = $ProductCube
		
		# Drive Rotation from Chaos
		# Use the two angles to drive X and Y rotation
		cube.rotation.x = theta1
		cube.rotation.y = theta2
		cube.rotation.z = theta1 + theta2
		
		# Drive Scale from Chaos
		# Use the distance of bob2 from the pivot center
		# The further out the pendulum swings, the larger the cube gets
		var bob_pos = bob2.global_position
		var pivot_pos = pivot.global_position
		var dist = bob_pos.distance_to(pivot_pos)
		
		# Map distance (approx 0 to 3.0) to scale (0.5 to 2.0)
		var scale_factor = 0.5 + (dist / (l1 + l2)) * 1.5
		cube.scale = Vector3.ONE * scale_factor

	# --- TRAIL GENERATION ---
	var bob_pos = bob2.global_position
	
	# Add point
	trail_points.push_front(Vector3(bob_pos.x, bob_pos.y, 0.0))
	
	# Move existing points (Time flow)
	for i in range(trail_points.size()):
		trail_points[i].z -= time_speed * delta
	
	# Limit trail
	if trail_points.size() > max_trail_length:
		trail_points.pop_back()
	
	_draw_trail()
	_update_drawing()

func _draw_trail():
	trail_mesh.clear_surfaces()
	if trail_points.is_empty(): return
	
	trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in trail_points:
		trail_mesh.surface_add_vertex(p)
	trail_mesh.surface_end()

# --- DRAWING ON CANVAS ---
var hue_timer: float = 0.0
@export var color_cycle_speed: float = 0.01  # Slower = more color variation on canvas
@onready var product_cube: MeshInstance3D = $ProductCube

func _update_drawing():
	if not raycast: return
	
	if raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		var collider = raycast.get_collider()
		
		# Cycle color (slower speed for more variety)
		hue_timer += get_process_delta_time() * color_cycle_speed
		if hue_timer > 1.0: hue_timer -= 1.0
		var current_color = Color.from_hsv(hue_timer, 1.0, 1.0)
		
		# Update ProductCube color to match
		_update_cube_color(current_color)
		
		# Try to draw with larger brush
		var drawable = _find_drawable(collider)
		if drawable:
			if drawable.has_method("draw_point"):
				var uv = drawable.get_uv_from_world_pos(hit_point)
				drawable.draw_point(uv, current_color, 25)  # Larger brush size
			else:
				drawable.draw_at_world_position(hit_point, current_color)

func _find_drawable(node: Node) -> Node:
	if not node: return null
	if node.has_method("draw_at_world_position"): return node
	for child in node.get_children():
		if child.has_method("draw_at_world_position"): return child
	return null

func _update_cube_color(color: Color):
	"""Update the ProductCube to match the current painting color"""
	if not product_cube:
		return
	
	var material = product_cube.get_active_material(0)
	if not material:
		material = StandardMaterial3D.new()
		product_cube.material_override = material
	
	if material is StandardMaterial3D:
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.5
