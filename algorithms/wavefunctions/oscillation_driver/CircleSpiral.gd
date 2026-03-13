extends Node3D

## Circle Spiral Demo
## Demonstrates a rotating driver creating a spiral (helix) in time
## Circular Motion + Linear Time = Spiral
## Agent-VisualizationExpert: Wave function visualization
## Protocol: IACP v2.2

# The Driver (Rotating Ball)
@onready var pivot: Node3D = $Pivot
@onready var ball: MeshInstance3D = $Pivot/Ball

# The Product (Spiral Trail)
@onready var trail_mesh: ImmediateMesh
@onready var trail_instance: MeshInstance3D = $Trail

# Parameters
@export var radius: float = 0.5
@export var rotation_speed: float = 2.0 # Radians per second
@export var time_speed: float = 2.0 # Speed of the "conveyor belt" (Z-axis)
@export var max_trail_length: int = 400

var time: float = 0.0
var trail_points: Array[Vector3] = []
var end_pivots: Array[Node3D] = []

func _ready() -> void:
	_setup_visuals()
	
	# Setup ball position
	ball.position.x = radius
	
	# Adjust ball size relative to radius
	if ball.mesh is SphereMesh:
		ball.mesh.radius = radius * 0.15
		ball.mesh.height = ball.mesh.radius * 2.0

	# Adjust ReferenceCircle size
	var ref_circle = get_node_or_null("ReferenceCircle")
	if ref_circle and ref_circle.mesh is TorusMesh:
		ref_circle.mesh.inner_radius = radius * 0.95
		ref_circle.mesh.outer_radius = radius * 1.05
		
	# Create End Assemblies
	_create_ring_assembly(-3.0, "EndAssembly1")
	_create_ring_assembly(-6.0, "EndAssembly2")

func _create_ring_assembly(z_pos: float, assembly_name: String) -> void:
	# Root for the end assembly
	var end_root = Node3D.new()
	end_root.name = assembly_name
	end_root.position.z = z_pos
	add_child(end_root)
	
	# 1. Static Reference Ring
	var ref_circle_original = get_node_or_null("ReferenceCircle")
	if ref_circle_original:
		var end_ref_circle = MeshInstance3D.new()
		end_ref_circle.name = "ReferenceCircle"
		end_ref_circle.mesh = ref_circle_original.mesh.duplicate() # Duplicate so they don't share instance if we modify one
		end_ref_circle.transform = ref_circle_original.transform # Copy orientation
		end_root.add_child(end_ref_circle)

	# 2. Rotating Pivot
	var new_pivot = Node3D.new()
	new_pivot.name = "Pivot"
	end_root.add_child(new_pivot)
	end_pivots.append(new_pivot)
	
	# Set initial phase lag
	# Time to reach z_pos (which is negative) is abs(z_pos)/time_speed
	# Phase lag = duration * rotation_speed
	var phase_lag = (abs(z_pos) / time_speed) * rotation_speed
	new_pivot.rotation.z = -phase_lag

	# 3. Ball
	var end_ball = MeshInstance3D.new()
	end_ball.name = "Ball"
	end_ball.mesh = ball.mesh.duplicate()
	end_ball.transform = ball.transform # Copy position (radius)
	new_pivot.add_child(end_ball)

func _setup_visuals() -> void:
	trail_mesh = ImmediateMesh.new()
	trail_instance.mesh = trail_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.0, 0.8) # Magenta spiral
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.use_point_size = true
	material.point_size = 3.0
	trail_instance.material_override = material

func _process(delta: float) -> void:
	time += delta
	
	# --- THE DRIVER (Rotation) ---
	# Rotate the pivot
	pivot.rotate_z(rotation_speed * delta)
	
	# Rotate the end pivots
	for p in end_pivots:
		p.rotate_z(rotation_speed * delta)
	
	# --- THE PRODUCT (Spiral) ---
	# The "Value" is the Ball's current position relative to the pivot parent (Local Space)
	# We use the pivot's rotation to find where the ball is in the local frame of the CircleSpiral node
	# Actually, simpler: The ball's position is local to Pivot. Pivot is child of CircleSpiral.
	# So we need the ball's position in CircleSpiral's local space.
	
	# Get ball position in CircleSpiral's local space
	var ball_local_pos = pivot.transform * ball.position
	
	# Add new point at the ball's current location (Z=0 relative to start)
	trail_points.push_front(Vector3(ball_local_pos.x, ball_local_pos.y, 0.0))
	
	# Move all existing points along Z (Time flowing away)
	for i in range(trail_points.size()):
		trail_points[i].z -= time_speed * delta
	
	# Limit trail
	if trail_points.size() > max_trail_length:
		trail_points.pop_back()
	
	# Render
	_draw_trail()

func _draw_trail() -> void:
	trail_mesh.clear_surfaces()
	
	if trail_points.is_empty():
		return
		
	trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in trail_points:
		trail_mesh.surface_add_vertex(p)
	trail_mesh.surface_end()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

