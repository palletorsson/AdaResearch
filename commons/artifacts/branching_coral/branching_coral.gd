# branching_coral.gd
# Marine L-system coral — organic branching structure with coral/seaweed visual language.
# Multiple axiom starts produce a bushy colony. Color gradient from deep purple/brown
# at the base to bright pink/coral at branch tips.

extends Node3D

class_name BranchingCoral

## Display settings
@export var display_size: float = 0.7
@export var base_color: Color = Color(0.35, 0.15, 0.25)
@export var tip_color: Color = Color(0.95, 0.45, 0.55)

## L-system configuration
@export var iterations: int = 4
@export var base_length: float = 0.08
@export var base_angle: float = 35.0
@export var length_decay: float = 0.7
@export var angle_variation: float = 12.0

## Multiple coral colony starts
@export var num_shoots: int = 5

# Coral L-system rules — wider branching, denser forking than trees
const CORAL_RULES := {
	"F": "FF[+F][-F][>F][<F]",
	"G": "GG[+G][-G]F",
}

var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _info_label: Label3D
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 77
	_create_display()
	_create_rock_base()
	_create_label()
	_generate()


func _create_display() -> void:
	_immediate_mesh = ImmediateMesh.new()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "CoralDisplay"
	_mesh_instance.mesh = _immediate_mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = mat

	add_child(_mesh_instance)


func _create_rock_base() -> void:
	var rock := MeshInstance3D.new()
	rock.name = "RockBase"

	var box := BoxMesh.new()
	box.size = Vector3(display_size * 0.5, 0.04, display_size * 0.4)
	rock.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.24, 0.22)
	mat.roughness = 0.95
	mat.metallic = 0.05
	rock.material_override = mat

	rock.position = Vector3(0, -0.02, 0)
	add_child(rock)


func _create_label() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 22
	_info_label.modulate = Color(0.85, 0.75, 0.8)
	_info_label.position = Vector3(0, display_size + 0.06, 0)
	add_child(_info_label)


func _generate() -> void:
	# Collect segments from multiple shoot starts
	var all_segments: Array = []
	var global_max_depth: int = 0

	for shoot_idx in range(num_shoots):
		# Each shoot gets a slightly different starting direction and rules
		var shoot_data := _grow_shoot(shoot_idx)
		var segments: Array = shoot_data[0]
		var max_depth: int = shoot_data[1]
		all_segments.append_array(segments)
		if max_depth > global_max_depth:
			global_max_depth = max_depth

	_draw_coral(all_segments, global_max_depth)
	_update_label()


func _grow_shoot(shoot_idx: int) -> Array:
	# Rewrite L-system string
	var axiom: String
	if shoot_idx % 2 == 0:
		axiom = "F"
	else:
		axiom = "G"

	var current_string := axiom
	var iter_count := iterations
	# Vary iteration count slightly for organic feel
	if shoot_idx > 2:
		iter_count = maxi(iterations - 1, 2)

	for _i in range(iter_count):
		var next := ""
		for c in current_string:
			if CORAL_RULES.has(c):
				next += CORAL_RULES[c]
			else:
				next += c
		current_string = next
		if current_string.length() > 50000:
			break

	# Turtle interpretation with shoot-specific starting direction
	var shoot_angle := (float(shoot_idx) / float(num_shoots)) * TAU * 0.6 - 0.3 * TAU
	var base_dir := Vector3(sin(shoot_angle) * 0.3, 1.0, cos(shoot_angle) * 0.3).normalized()
	# Slight random tilt per shoot
	_rng.seed = 77 + shoot_idx * 13
	base_dir = base_dir.rotated(Vector3.RIGHT, _rng.randf_range(-0.15, 0.15))
	base_dir = base_dir.rotated(Vector3.FORWARD, _rng.randf_range(-0.15, 0.15))

	var pos := Vector3(
		_rng.randf_range(-0.02, 0.02),
		0.0,
		_rng.randf_range(-0.02, 0.02)
	)
	var dir := base_dir
	var right := dir.cross(Vector3.UP)
	if right.length_squared() < 0.01:
		right = Vector3.RIGHT
	right = right.normalized()
	var up := right.cross(dir).normalized()

	var depth: int = 0
	var current_length: float = base_length
	var current_angle: float = base_angle
	var angle_rad: float = deg_to_rad(current_angle)

	var stack: Array = []
	var segments: Array = []
	var max_depth: int = 0

	for c in current_string:
		match c:
			"F", "G":
				var new_pos := pos + dir * current_length
				segments.append([pos, new_pos, depth])
				pos = new_pos
			"+":
				# Turn left (yaw around branch-local up)
				var varied := angle_rad + deg_to_rad(_rng.randf_range(-angle_variation, angle_variation))
				var axis := dir.cross(right)
				if axis.length_squared() < 0.01:
					axis = up
				axis = axis.normalized()
				dir = dir.rotated(axis, varied).normalized()
				right = right.rotated(axis, varied).normalized()
			"-":
				# Turn right
				var varied := angle_rad + deg_to_rad(_rng.randf_range(-angle_variation, angle_variation))
				var axis := dir.cross(right)
				if axis.length_squared() < 0.01:
					axis = up
				axis = axis.normalized()
				dir = dir.rotated(axis, -varied).normalized()
				right = right.rotated(axis, -varied).normalized()
			">":
				# Roll clockwise (pitch forward)
				var varied := angle_rad + deg_to_rad(_rng.randf_range(-angle_variation, angle_variation))
				dir = dir.rotated(right, varied).normalized()
				up = up.rotated(right, varied).normalized()
			"<":
				# Roll counter-clockwise (pitch backward)
				var varied := angle_rad + deg_to_rad(_rng.randf_range(-angle_variation, angle_variation))
				dir = dir.rotated(right, -varied).normalized()
				up = up.rotated(right, -varied).normalized()
			"[":
				stack.append({
					"pos": pos,
					"dir": dir,
					"right": right,
					"up": up,
					"depth": depth,
					"length": current_length,
					"angle": current_angle,
					"angle_rad": angle_rad
				})
				depth += 1
				if depth > max_depth:
					max_depth = depth
				current_length *= length_decay
				current_angle *= 0.92
				angle_rad = deg_to_rad(current_angle)
			"]":
				if stack.size() > 0:
					var state: Dictionary = stack.pop_back()
					pos = state["pos"]
					dir = state["dir"]
					right = state["right"]
					up = state["up"]
					depth = state["depth"]
					current_length = state["length"]
					current_angle = state["angle"]
					angle_rad = state["angle_rad"]

	return [segments, max_depth]


func _draw_coral(segments: Array, max_depth: int) -> void:
	if not _immediate_mesh:
		return
	_immediate_mesh.clear_surfaces()
	if segments.is_empty():
		return

	# Compute bounds for centering and scaling
	var min_bounds := Vector3(INF, INF, INF)
	var max_bounds := Vector3(-INF, -INF, -INF)
	for seg in segments:
		var s: Vector3 = seg[0]
		var e: Vector3 = seg[1]
		min_bounds = min_bounds.min(s).min(e)
		max_bounds = max_bounds.max(s).max(e)

	var bounds_size := max_bounds - min_bounds
	var max_dim: float = maxf(maxf(bounds_size.x, bounds_size.y), maxf(bounds_size.z, 0.001))
	var scale_factor: float = display_size * 0.7 / max_dim
	var center := (min_bounds + max_bounds) / 2.0
	# Shift so coral base sits near y=0
	center.y = min_bounds.y

	if max_depth == 0:
		max_depth = 1

	# Secondary accent color for variety — warmer orange-coral at mid-depth
	var mid_color := Color(0.8, 0.35, 0.3)

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for seg in segments:
		var p1: Vector3 = (seg[0] - center) * scale_factor
		var p2: Vector3 = (seg[1] - center) * scale_factor
		var d: int = seg[2]

		var t: float = clampf(float(d) / float(max_depth), 0.0, 1.0)

		# Two-stage gradient: base → mid → tip
		var col: Color
		if t < 0.5:
			col = base_color.lerp(mid_color, t * 2.0)
		else:
			col = mid_color.lerp(tip_color, (t - 0.5) * 2.0)

		# Lighten tips for glow feel
		col = col.lightened(t * 0.2)

		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(p1)
		_immediate_mesh.surface_set_color(col)
		_immediate_mesh.surface_add_vertex(p2)

	_immediate_mesh.surface_end()


func _update_label() -> void:
	if not _info_label:
		return
	_info_label.text = "Branching Coral\nIter: %d | Shoots: %d | Angle: %.0f°" % [
		iterations, num_shoots, base_angle
	]


## Grid system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("iterations"):
		iterations = clampi(int(config_data["iterations"]), 1, 5)
	if config_data.has("base_angle"):
		base_angle = float(config_data["base_angle"])
	if config_data.has("num_shoots"):
		num_shoots = clampi(int(config_data["num_shoots"]), 1, 8)
	if config_data.has("length_decay"):
		length_decay = clampf(float(config_data["length_decay"]), 0.4, 0.9)
	if config_data.has("display_size"):
		display_size = float(config_data["display_size"])
	if config_data.has("seed"):
		_rng.seed = int(config_data["seed"])
	_generate()
