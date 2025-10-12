extends VREntity
class_name Walker3D

@export var step_size: float = 0.05
@export var plane_height: float = -0.45
@export var max_trail_points: int = 300
@export var trail_width: float = 0.01

var rng := RandomNumberGenerator.new()
var trail_line: Line3D

func _ready() -> void:
	super()
	position_v = Vector3.ZERO
	position_v.y = plane_height
	velocity = Vector3.ZERO
	acceleration = Vector3.ZERO
	update_transform()
	create_trail()
	drop_trail_point()

func create_trail() -> void:
	trail_line = Line3D.new()
	trail_line.width = trail_width
	trail_line.default_color = accent_pink
	trail_line.texture_mode = Line3D.TEXTURE_MODE_TILE
	trail_line.material_override = create_trail_material()
	add_child(trail_line)

func create_trail_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = accent_pink
	mat.emission_enabled = true
	mat.emission = accent_pink * 0.7
	mat.emission_energy_multiplier = 0.9
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.2
	return mat

func set_step_size(value: float) -> void:
	step_size = max(value, 0.005)

func set_plane_height(value: float) -> void:
	plane_height = value
	position_v.y = plane_height
	update_transform()

func step_random() -> void:
	var step_vector := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
	if step_vector.length_squared() == 0.0:
		step_vector = Vector3(0.0, 0.0, step_size)
	else:
		step_vector = step_vector.normalized() * step_size

	position_v += step_vector
	if fish_tank:
		position_v = fish_tank.constrain_position(position_v)
	position_v.y = plane_height
	update_transform()
	drop_trail_point()

func drop_trail_point() -> void:
	if not trail_line:
		return
	trail_line.add_point(position_v)
	if trail_line.get_point_count() > max_trail_points:
		trail_line.remove_point(0)

func reset_path(origin: Vector3 = Vector3.ZERO) -> void:
	position_v = origin
	position_v.y = plane_height
	velocity = Vector3.ZERO
	acceleration = Vector3.ZERO
	update_transform()
	if trail_line:
		trail_line.clear_points()
	drop_trail_point()

func set_trail_color(color: Color) -> void:
	if trail_line:
		trail_line.default_color = color
	if trail_line.material_override is StandardMaterial3D:
		var mat := trail_line.material_override as StandardMaterial3D
		mat.albedo_color = color
		mat.emission = color * 0.7

func seed(value: int) -> void:
	rng.seed = value


func set_trail_visible(visible: bool) -> void:
	if trail_line:
		trail_line.visible = visible

func is_trail_visible() -> bool:
	return trail_line != null and trail_line.visible

