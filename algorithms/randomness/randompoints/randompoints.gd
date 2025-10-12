extends Node3D

@export var num_points: int = 30
@export var area_size: Vector3 = Vector3(1.0, 1.0, 1.0)  # 1x1x1
@export var gaussian_std_fraction: float = 0.25  # std as fraction of half-extent

var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point_color_with_text.tscn")

func _ready():
	randomize()
	spawn_points()

func spawn_points():
	var half_extents := area_size * 0.5
	for i in range(num_points):
		var p := point_scene.instantiate()
		p.name = "Point_%d" % i
		add_child(p)
		# Sample from a 3D Gaussian centered at origin and clamp within box
		var sx := half_extents.x * gaussian_std_fraction
		var sy := half_extents.y * gaussian_std_fraction
		var sz := half_extents.z * gaussian_std_fraction
		var pos := Vector3(
			clamp(_randn(0.0, sx), -half_extents.x, half_extents.x),
			clamp(_randn(0.0, sy), -half_extents.y, half_extents.y),
			clamp(_randn(0.0, sz), -half_extents.z, half_extents.z)
		)
		p.position = pos

# Box–Muller transform for normal distribution
func _randn(mean: float, std: float) -> float:
	var u1 = clamp(randf(), 1e-6, 1.0 - 1e-6)
	var u2 := randf()
	var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return mean + std * z
