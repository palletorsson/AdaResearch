# FractalProjectile.gd
# verb: split
# Sphere that splits into 3 smaller copies at a timer or on hit.
# Recursion depth 2 max → up to 9 sub-projectiles.
# One becomes many — self-similarity across scale.
extends CatalystProjectile

const MAX_DEPTH := 2
const SPLIT_TIME := 1.0
const SPLIT_COUNT := 3
const SPREAD_ANGLE := 0.52  # ~30 degrees

var _split_timer: float = 0.0
var _has_split: bool = false

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.08 * projectile_scale
	sphere.height = 0.16 * projectile_scale
	_mesh_instance.mesh = sphere
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	add_child(_mesh_instance)

func _update_trajectory(delta: float) -> void:
	if has_hit or _has_split:
		return
	_split_timer += delta
	if _split_timer >= SPLIT_TIME:
		_split()

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	if not _has_split:
		_split()

func _split() -> void:
	if _has_split:
		return
	_has_split = true

	var depth: int = get_meta("fractal_depth", 0)
	if depth >= MAX_DEPTH:
		return  # No more recursion

	var forward := linear_velocity.normalized()
	if forward.length_squared() < 0.01:
		forward = direction.normalized()

	# Find a perpendicular axis
	var perp: Vector3
	if abs(forward.dot(Vector3.UP)) < 0.99:
		perp = forward.cross(Vector3.UP).normalized()
	else:
		perp = forward.cross(Vector3.RIGHT).normalized()

	# Inline child creation to avoid circular preload
	var child_script: GDScript = load("res://commons/hazards/becoming_catalyst/modes/fractal_projectile.gd")
	var scene_root := get_tree().current_scene
	for i in SPLIT_COUNT:
		var angle := (TAU / SPLIT_COUNT) * i
		var rotated_perp := perp.rotated(forward, angle)
		var child_dir := forward.rotated(rotated_perp, SPREAD_ANGLE).normalized()

		var child_depth := depth + 1
		var scale_factor := pow(0.6, child_depth)
		var hue := fmod(0.6 + child_depth * 0.12, 1.0)

		var child := CatalystProjectile.new()
		child.speed = 11.0
		child.lifetime = 3.5
		child.projectile_scale = scale_factor
		child.color_primary = Color.from_hsv(hue, 0.7, 1.0)
		child.color_secondary = Color.from_hsv(fmod(hue + 0.1, 1.0), 0.5, 0.8)
		child.emission_energy = 1.8
		child.direction = child_dir
		child.set_meta("fractal_depth", child_depth)
		child.set_script(child_script)

		scene_root.add_child(child)
		child.global_position = global_position
