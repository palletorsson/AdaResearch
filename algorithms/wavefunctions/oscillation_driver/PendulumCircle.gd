extends Node3D

## Pendulum Circle Demo
## Demonstrates compound motion: A rotating circle attached to a swinging pendulum
## "The circle rotation hangs on a pendulum"
## Agent-VisualizationExpert: Complex wave function visualization
## Protocol: IACP v2.2

# The Primary Driver (Pendulum)
@onready var pendulum_pivot: Node3D = $PendulumPivot
@onready var rod: MeshInstance3D = $PendulumPivot/Rod
@onready var bob_center: Node3D = $PendulumPivot/BobCenter

# The Secondary Driver (Circle)
@onready var circle_pivot: Node3D = $PendulumPivot/BobCenter/CirclePivot
@onready var ball: MeshInstance3D = $PendulumPivot/BobCenter/CirclePivot/Ball
@onready var raycast: RayCast3D = $PendulumPivot/BobCenter/CirclePivot/Ball/RayCast3D

# The Product (Complex Trail)
@onready var trail_mesh: ImmediateMesh
@onready var trail_instance: MeshInstance3D = $Trail

# Ground Label
@onready var ground_label: Label3D = $GroundLabel

# Physics Parameters (Pendulum)
@export var pendulum_length: float = 2.5
@export var gravity: float = 9.8
@export var initial_angle: float = 30.0 # Degrees
@export var pendulum_damping: float = 0.1

# Motion Parameters (Circle)
@export var circle_radius: float = 0.8
@export var rotation_speed: float = 5.0 # Radians per second

# Visualization Parameters
@export var time_speed: float = 2.0 # Speed of the "conveyor belt" (Z-axis)
@export var max_trail_length: int = 500

var time: float = 0.0
var pendulum_angle: float = 0.0
var pendulum_velocity: float = 0.0
var trail_points: Array[Vector3] = []

func _ready():
	_setup_visuals()
	
	# Initialize pendulum
	pendulum_angle = deg_to_rad(initial_angle)
	
	# Setup structure dimensions
	rod.position.y = -pendulum_length / 2.0
	rod.mesh.height = pendulum_length
	bob_center.position.y = -pendulum_length
	ball.position.x = circle_radius
	
	# Enable raycast
	raycast.enabled = true

func _setup_visuals():
	trail_mesh = ImmediateMesh.new()
	trail_instance.mesh = trail_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 1.0, 0.5) # Spring Green trail
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.use_point_size = true
	material.point_size = 2.0
	trail_instance.material_override = material

func _process(delta):
	time += delta
	
	# --- 1. PENDULUM PHYSICS ---
	# Acceleration = -(g/L) * sin(theta)
	var accel = -(gravity / pendulum_length) * sin(pendulum_angle)
	
	pendulum_velocity += accel * delta
	pendulum_velocity *= (1.0 - pendulum_damping * delta)
	pendulum_angle += pendulum_velocity * delta
	
	# Apply to pivot
	pendulum_pivot.rotation.z = pendulum_angle
	
	# --- 2. CIRCLE ROTATION ---
	# Rotate the circle pivot relative to the pendulum
	circle_pivot.rotate_z(rotation_speed * delta)
	
	# --- 3. TRAIL GENERATION ---
	# Get local position of the ball relative to this PendulumCircle node
	# Hierarchy: PendulumCircle (Root) -> PendulumPivot -> BobCenter -> CirclePivot -> Ball
	# So ball.global_position is World. We need it in Root's local space.
	# Since "this" is the root, we can use to_local() or transform * ball.position (if ball was direct child)
	# Safest way for deep hierarchy:
	var ball_local_pos = to_local(ball.global_position)
	
	# Add new point (using X and Y from ball, Z starts at 0)
	# Note: We use the local X and Y, but Z is part of the time-scrolling mechanism,
	# so we might want to reset Z to 0 relative to the "origin" plane or keep its physical Z offset?
	# In this demo, the circle rotates in Z-plane but the whole thing might be swinging.
	# Let's stick to the pattern: X/Y = Value, Z = Time.
	# However, the ball physically moves in Z due to pendulum swing if it's 3D.
	# But the trail is usually "unrolled" time.
	trail_points.push_front(Vector3(ball_local_pos.x, ball_local_pos.y, 0.0))
	
	# Move all existing points along Z (Time flowing away)
	for i in range(trail_points.size()):
		trail_points[i].z -= time_speed * delta
	
	# Limit trail
	if trail_points.size() > max_trail_length:
		trail_points.pop_back()
	
	# Render
	_draw_trail()
	
	# --- 4. RAYCAST TO GROUND ---
	_update_ground_interaction()

func _draw_trail():
	trail_mesh.clear_surfaces()
	
	if trail_points.is_empty():
		return
		
	trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in trail_points:
		trail_mesh.surface_add_vertex(p)
	trail_mesh.surface_end()

func _update_ground_interaction():
	if raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		var collider = raycast.get_collider()
		
		# Position label at hit point, slightly above ground
		ground_label.global_position = hit_point + Vector3(0, 0.01, 0)
		
		# Convert to local space for display
		var local_hit = to_local(hit_point)
		
		# Update label text with coordinates
		ground_label.text = "Point: (%.2f, %.2f)" % [local_hit.x, local_hit.z]
		ground_label.visible = true
		
		# Try to draw on the surface
		var drawable = _find_drawable(collider)
		if drawable:
			drawable.draw_at_world_position(hit_point, Color.BLACK)
			ground_label.text += "\nDrawing..."
	else:
		ground_label.visible = false

func _find_drawable(node: Node) -> Node:
	if not node:
		return null
	if node.has_method("draw_at_world_position"):
		return node
	for child in node.get_children():
		if child.has_method("draw_at_world_position"):
			return child
	return null

