extends Node3D

## Lissajous 3D Demo
## Demonstrates complex harmonic motion by combining oscillations on 3 axes
## Formula: x = A*sin(a*t + d), y = B*sin(b*t), z = C*sin(c*t)
## Agent-VisualizationExpert: Math visualization
## Protocol: IACP v2.2

# The Driver (The Ball)
@onready var ball: MeshInstance3D = $Ball

# The Product (The Knot Trail)
@onready var trail_mesh: ImmediateMesh
@onready var trail_instance: MeshInstance3D = $Trail

# Parameters
@export_group("Frequencies")
@export var freq_x: float = 3.0
@export var freq_y: float = 2.0
@export var freq_z: float = 4.0

@export_group("Amplitudes")
@export var amp_x: float = 2.0
@export var amp_y: float = 1.5
@export var amp_z: float = 2.0

@export_group("Phase Shifts")
@export var phase_x: float = 0.0
@export var phase_y: float = 1.57 # PI/2
@export var phase_z: float = 0.0

@export var max_trail_length: int = 1000
@export var speed: float = 1.0

var time: float = 0.0
var trail_points: Array[Vector3] = []

func _ready():
	_setup_visuals()

func _setup_visuals():
	trail_mesh = ImmediateMesh.new()
	trail_instance.mesh = trail_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.5, 0.0) # Orange Neon
	material.emission_enabled = true
	material.emission = Color(1.0, 0.5, 0.0)
	material.emission_energy_multiplier = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.use_point_size = true
	material.point_size = 2.0
	trail_instance.material_override = material

func _process(delta):
	time += delta * speed
	
	# --- CALCULATE LISSAJOUS POSITION ---
	var x = sin(time * freq_x + phase_x) * amp_x
	var y = sin(time * freq_y + phase_y) * amp_y
	var z = sin(time * freq_z + phase_z) * amp_z
	
	var pos = Vector3(x, y, z)
	ball.position = pos
	
	# --- TRAIL GENERATION ---
	# Unlike previous demos, we don't scroll Z. The shape exists in static space.
	# Using local position relative to the Lissajous3D node
	# The ball's position is already set locally via ball.position = pos
	
	trail_points.push_front(pos)
	
	if trail_points.size() > max_trail_length:
		trail_points.pop_back()
	
	_draw_trail()

func _draw_trail():
	trail_mesh.clear_surfaces()
	if trail_points.is_empty(): return
	
	trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in trail_points:
		trail_mesh.surface_add_vertex(p)
	trail_mesh.surface_end()
