extends Node3D

## Oscillation Driver Demo
## Demonstrates the concept of a "Driver" (Oscillator) producing a "Product" (Scale transformation)
## Agent-VisualizationExpert: Wave function visualization
## Protocol: IACP v2.2

# The Driver: An oscillating ball
@onready var driver_ball: MeshInstance3D = $DriverBall
# The Product: A cube being scaled
@onready var product_cube: MeshInstance3D = $ProductCube
# Visualization: A line connecting them
@onready var connection_line: MeshInstance3D = $ConnectionLine

# Parameters
@export var frequency: float = 1.0  # Speed of oscillation
@export var amplitude: float = 1.0  # Height of oscillation
@export var base_scale: float = 1.0 # Minimum scale of the cube

var time: float = 0.0

func _ready():
	_setup_visuals()

func _setup_visuals():
	# Create a simple line mesh if not present
	if connection_line.mesh == null:
		var mesh = ImmediateMesh.new()
		connection_line.mesh = mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 1.0, 0.0) # Yellow connection
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		connection_line.material_override = material

func _process(delta):
	time += delta
	
	# --- THE DRIVER ---
	# Calculate the driving value (signal)
	# sin(time) oscillates between -1 and 1
	var signal_value = sin(time * frequency)
	
	# Map signal to physical position (Driver Action)
	var driver_y = signal_value * amplitude
	driver_ball.position.y = driver_y + 2.0 # Offset up
	
	# --- THE PRODUCT ---
	# Map signal to product property (Cube Scale)
	# Remap -1..1 to 0.5..2.5 for scale
	var scale_factor = base_scale + (signal_value + 1.0) * 0.5
	product_cube.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# --- VISUALIZATION ---
	# Update connection line
	_update_connection()
	
	# Rotate cube for extra flair
	product_cube.rotate_y(delta * 0.5)

func _update_connection():
	var mesh = connection_line.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Draw line from ball to cube
	mesh.surface_add_vertex(driver_ball.position)
	mesh.surface_add_vertex(product_cube.position)
	
	mesh.surface_end()
