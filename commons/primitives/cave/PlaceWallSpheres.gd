# res://cave/PlaceWallSpheres.gd
extends Node3D

@export var cave_path: NodePath = NodePath("Cave")
@export var preferred_sphere_name: String = "Blob_01"
@export var point_count: int = 10

@export var inset: float = 0.35
@export var child_radius_range := Vector2(0.6, 1.8)
@export var union_probability: float = 0.5
@export var seed: int = 424242
@export var use_collision: bool = true
@export var material_color: Color = Color(0.55, 0.5, 0.48)

func _ready() -> void:
	var cave := get_node_or_null(cave_path)
	if cave == null:
		push_error("PlaceWallSpheres: Cave node not found at '%s'." % cave_path)
		return
	var target := _find_target_sphere(cave)
	if target == null:
		push_error("PlaceWallSpheres: No CSGSphere3D found under Cave.")
		return
	_place_spheres_on_inner_wall(cave, target)

func _find_target_sphere(cave: Node) -> CSGSphere3D:
	var preferred := cave.get_node_or_null(preferred_sphere_name)
	if preferred is CSGSphere3D:
		return preferred as CSGSphere3D
	var largest: CSGSphere3D = null
	var max_r := -INF
	for c in cave.get_children():
		if c is CSGSphere3D:
			var s := c as CSGSphere3D
			if s.radius > max_r:
				max_r = s.radius
				largest = s
	return largest

func _place_spheres_on_inner_wall(cave: Node, sphere: CSGSphere3D) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = material_color
	mat.roughness = 1.0

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	for i in point_count:
		var dir := _uniform_dir_on_sphere(rng)          
		var center := sphere.global_transform.origin + dir * (sphere.radius - inset)

		var child := CSGSphere3D.new()
		child.name = "WallOrb_%02d" % i
		child.radius = rng.randf_range(child_radius_range.x, child_radius_range.y)

		var do_union := rng.randf() < union_probability
		child.operation = CSGShape3D.OPERATION_UNION if do_union else CSGShape3D.OPERATION_SUBTRACTION

		child.position = center + dir * (-0.15 * child.radius)  # ensure intersection
		child.smooth_faces = true
		child.material = mat
		child.use_collision = use_collision

		cave.add_child(child)

func _uniform_dir_on_sphere(rng: RandomNumberGenerator) -> Vector3:
	var u := rng.randf()
	var v := rng.randf_range(-1.0, 1.0)
	var phi := TAU * u
	var s := sqrt(1.0 - v * v)
	return Vector3(cos(phi) * s, v, sin(phi) * s)
