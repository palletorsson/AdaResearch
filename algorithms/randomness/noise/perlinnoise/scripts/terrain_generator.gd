extends Node3D
class_name PerlinTerrainGenerator

# @identity
# essence: mesh_vertex.y = MeshHelper.apply_noise_to_mesh(noise, time_offset) — Perlin noise applied to a subdivided plane mesh, animated by advancing time_offset on a 0.5s timer
# desire: to watch terrain breathe — to see a landscape slowly undulate in real-time and understand that time is just another axis in the noise field
# critical_parameter: use_fade — toggles a fade effect that softens the terrain edges; with edges=true the terrain wraps cleanly, revealing that noise can be constrained to tile
# triggers: a 0.5s timer fires every cycle, advancing time_offset by 0.5 and regenerating the mesh — the terrain animates in visible 0.5s steps rather than frame-by-frame
# emerges: the periodic timer creates a visible rhythm to the terrain animation — an unintended clock that makes the noise feel like it breathes in beats
# needs: no VR controls [missing]; use_fade and use_edges are editor exports only; animation is automatic [has]; MeshHelper.apply_noise_to_mesh provides the coupling to noise [has]
# relationships: uses the same noise library (NoiseHelper) as other algorithms in the perlinnoise folder; simpler than noiseterrain.gd (no domain warping, no UI); perlin_noise_terrain token in registry points to this script
# truth: noise-animated terrain reveals that the landscape and its future are encoded in the same function — slide time_offset and you are not changing the terrain, you are looking at a different cross-section of a 3D noise field

@export var use_fade: bool = false  # Toggle fade effect
@export var use_edges: bool = true

var time_offset = 0.0  # Time-based offset for animation
@onready var noise_plane: MeshInstance3D = $NoisePlane
var fnoise = NoiseHelper.setup_noise(1, 0.07)

func _ready() -> void:
	TimerHelper.create_timer(self, 0.5, Callable(self, "_on_timer_timeout"))
	noise_plane.mesh.set_orientation(1)
	# Set subdivisions dynamically
	noise_plane.mesh. subdivide_width = 20  # Number of subdivisions along X-axis
	noise_plane.mesh.subdivide_depth = 20  # Number of subdivisions along Z-axis

	generate_terrain()
	


func _on_timer_timeout() -> void:
	time_offset += 0.5
	generate_terrain()

func generate_terrain() -> void:
	var new_mesh = MeshHelper.apply_noise_to_mesh(noise_plane, fnoise, time_offset, use_fade, use_edges)
	if new_mesh:
		noise_plane.mesh = new_mesh

func apply_grid_config(config: Dictionary) -> void:
	pass
