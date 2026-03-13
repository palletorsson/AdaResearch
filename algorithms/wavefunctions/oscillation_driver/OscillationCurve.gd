extends Node3D

## Oscillation Curve Demo
## Demonstrates an oscillator driving a curve generation (Time -> Space)
## Agent-VisualizationExpert: Wave function visualization
## Protocol: IACP v2.2

# The Driver
@onready var driver_ball: MeshInstance3D = $DriverBall
# The Product (Curve)
@onready var trail_mesh: ImmediateMesh
@onready var trail_instance: MeshInstance3D = $Trail

# Parameters
@export var frequency: float = 1.0
@export var amplitude: float = 1.5
@export var speed: float = 2.0 # Speed of movement along X axis
@export var max_points: int = 200

var time: float = 0.0
var points: Array[Vector3] = []

func _ready() -> void:
	_setup_visuals()

func _setup_visuals() -> void:
	trail_mesh = ImmediateMesh.new()
	trail_instance.mesh = trail_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 1.0, 0.5) # Green trail
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.use_point_size = true
	material.point_size = 4.0
	trail_instance.material_override = material

func _process(delta: float) -> void:
	time += delta
	
	# --- THE DRIVER ---
	# 1. Oscillate Y (The "Value")
	var signal_value = sin(time * frequency)
	var y_pos = signal_value * amplitude
	
	# 2. Move X (The "Timeline")
	# We move the ball back and forth or scroll the world?
	# Let's keep the ball at X=0 and scroll the curve (like an oscilloscope)
	
	# Update Ball Position
	driver_ball.position.y = y_pos
	
	# --- THE PRODUCT (CURVE) ---
	# Add new point at current ball position
	# driver_ball is a direct child, and we are moving it in local Y.
	# So driver_ball.position is already local.
	# However, if we want to be safe against parent transforms, we just use position as is
	# because trail is drawn in local space of the same parent.
	points.push_front(Vector3(0, y_pos, 0))
	
	# Move all existing points to the right (Time flowing)
	for i in range(points.size()):
		points[i].x += speed * delta
	
	# Limit trail length
	if points.size() > max_points:
		points.pop_back()
	
	# Render Curve
	_draw_trail()

func _draw_trail() -> void:
	trail_mesh.clear_surfaces()
	
	if points.is_empty():
		return
		
	trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		trail_mesh.surface_add_vertex(p)
	trail_mesh.surface_end()
