extends Node3D
class_name PerlinTerrainGenerator

@export var use_fade: bool = false  # Toggle fade effect
@export var use_edges: bool = true

var time_offset = 0.0  # Time-based offset for animation
@onready var noise_plane: MeshInstance3D = $NoisePlane
var fnoise = NoiseHelper.setup_noise(1, 0.07)

func _ready():
	TimerHelper.create_timer(self, 0.5, Callable(self, "_on_timer_timeout"))
	noise_plane.mesh.set_orientation(1)
	# Set subdivisions dynamically
	noise_plane.mesh. subdivide_width = 20  # Number of subdivisions along X-axis
	noise_plane.mesh.subdivide_depth = 20  # Number of subdivisions along Z-axis

	generate_terrain()
	


func _on_timer_timeout():
	time_offset += 0.5
	generate_terrain()

func generate_terrain():
	var new_mesh = MeshHelper.apply_noise_to_mesh(noise_plane, fnoise, time_offset, use_fade, use_edges)
	if new_mesh:
		noise_plane.mesh = new_mesh
