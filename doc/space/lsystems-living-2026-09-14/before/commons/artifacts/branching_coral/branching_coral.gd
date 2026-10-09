# branching_coral.gd
# Marine L-system coral — organic branching structure with coral/seaweed visual language.
# Multiple axiom starts produce a bushy colony. Color gradient from deep purple/brown
# at the base to bright pink/coral at branch tips.
#
# @identity
# essence: F → FF[+F][-F][>F][<F] from multiple shoot origins with 3D pitch/roll branching
# desire: To grow a coral colony — multiple shoots from a shared base, each branching in all directions with organic randomness
# critical_parameter: num_shoots — the number of independent growth starts that together form the colony's bushy silhouette
# triggers: More shoots → denser colony; higher angle_variation → wilder, more organic forms; fewer iterations → sparse polyps
# emerges: Colony morphology from independent shoots sharing a base — the whole is bushier than any individual shoot
# needs: VR shoot/angle/iteration controls [missing], Label3D [has]
# relationships: Appears in LSystems_Competition and LSystems_Living. Contrasts with lsystem_tree (single trunk vs multi-shoot colony).
# truth: A coral is not one tree — it is many grammars growing from the same rock.

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

## DNA — growth form. The grammar itself, not the size of the thing it grows.
## A reef is not one shape: the same turtle reading a different production, at a
## different fork angle, off a differently-tilted holdfast, is a staghorn thicket
## or a flat sea fan or a table plate. "staghorn" IS the shipped rule set.
## Named growth_form, not form, because three siblings in this family
## (recursive_tree, branching_growth_algorithm, space_colonization_algorithm)
## already use "form" as a VALUE of their staging axis `aftermath`.
@export_enum("staghorn", "fan", "table", "whip", "brain") var growth_form: String = "staghorn"

## DNA — what the colour gradient is reporting. In the shipped coral the gradient
## from purple-brown base to pink tip is a readout of RECURSION DEPTH: you can see
## how deep in the grammar a segment sits. Bleaching does not reshape the colony,
## it deletes that readout — the branch is still there and no longer says where it is.
@export_enum("living", "bleached", "fluorescent", "encrusted") var condition: String = "living"

const CONDITIONS: Array[String] = ["living", "bleached", "fluorescent", "encrusted"]

# Coral L-system rules — wider branching, denser forking than trees
const CORAL_RULES := {
	"F": "FF[+F][-F][>F][<F]",
	"G": "GG[+G][-G]F",
}

# Growth forms. "staghorn" reproduces the shipped constants exactly: the rules are
# CORAL_RULES, every scale is 1.0, spread 0.6 and out 0.3 are the literals that were
# baked into _grow_shoot, lift 1.0 is the Y of the old base_dir.
const FORMS := {
	"staghorn": {
		"rules": {"F": "FF[+F][-F][>F][<F]", "G": "GG[+G][-G]F"},
		"angle_scale": 1.0, "decay_scale": 1.0, "spread": 0.6, "out": 0.3, "lift": 1.0,
	},
	"fan": {
		# No roll symbols: branching stays in the shoot's own plane, and the shoots
		# barely spread — a sea fan, one surface held up into the current.
		"rules": {"F": "F[+F][-F]F[+F][-F]", "G": "GG[+G][-G]"},
		"angle_scale": 0.78, "decay_scale": 1.12, "spread": 0.05, "out": 0.12, "lift": 1.0,
	},
	"table": {
		# Holdfast tilted almost flat and shoots thrown right around: a plate coral,
		# growing sideways for light rather than upward for height.
		"rules": {"F": "FF[+F][-F]F", "G": "GG[+G][-G]"},
		"angle_scale": 0.62, "decay_scale": 1.18, "spread": 1.0, "out": 1.0, "lift": 0.22,
	},
	"whip": {
		# Long runs between rare forks — sea whips. The grammar barely branches.
		"rules": {"F": "FFF[+F]F", "G": "GGG[-G]"},
		"angle_scale": 0.42, "decay_scale": 1.25, "spread": 0.35, "out": 0.18, "lift": 1.0,
	},
	"brain": {
		# Fork angle past 60 degrees folds the branch back over itself and the colony
		# closes into a mound instead of opening into a thicket.
		"rules": {"F": "F[+F][-F][>F][<F]", "G": "G[+G][-G]G"},
		"angle_scale": 1.95, "decay_scale": 0.92, "spread": 1.0, "out": 0.55, "lift": 0.45,
	},
}

var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _info_label: Label3D
var _rng: RandomNumberGenerator
# 77 is the seed the shipped coral was drawn with. Every shoot reseeds off this
# base, so the colony is fully determined — no fixture seed is needed to pin a
# sweep, and two values of an axis differ only by the axis.
var _base_seed: int = 77
var _built: bool = false


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = _base_seed
	_create_display()
	_create_rock_base()
	_create_label()
	_generate()
	_built = true


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


func _form_data() -> Dictionary:
	var f: Variant = FORMS.get(growth_form)
	if f is Dictionary:
		return f
	return FORMS["staghorn"]


## base / mid / tip. "living" returns the exported colours and the mid tone that was
## a literal inside _draw_coral, so the default is pixel-identical to the shipped coral.
func _palette() -> Array:
	match condition:
		"bleached":
			return [Color(0.74, 0.73, 0.70), Color(0.87, 0.86, 0.84), Color(0.97, 0.97, 0.95)]
		"fluorescent":
			return [Color(0.05, 0.18, 0.38), Color(0.10, 0.85, 0.72), Color(0.90, 1.0, 0.25)]
		"encrusted":
			return [Color(0.10, 0.12, 0.09), Color(0.24, 0.29, 0.14), Color(0.42, 0.47, 0.22)]
		"living":
			return [base_color, Color(0.8, 0.35, 0.3), tip_color]
		_:
			return [base_color, Color(0.8, 0.35, 0.3), tip_color]


func _grow_shoot(shoot_idx: int) -> Array:
	var fd: Dictionary = _form_data()
	var rules: Dictionary = fd["rules"]

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
			if rules.has(c):
				next += rules[c]
			else:
				next += c
		current_string = next
		if current_string.length() > 50000:
			break

	# Turtle interpretation with shoot-specific starting direction
	var spread: float = float(fd["spread"])
	var out_bias: float = float(fd["out"])
	var lift: float = float(fd["lift"])
	var shoot_angle: float = (float(shoot_idx) / float(num_shoots)) * TAU * spread - 0.5 * spread * TAU
	var base_dir := Vector3(sin(shoot_angle) * out_bias, lift, cos(shoot_angle) * out_bias).normalized()
	# Slight random tilt per shoot
	_rng.seed = _base_seed + shoot_idx * 13
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

	# staghorn scales both by 1.0, so the default arithmetic is the shipped arithmetic.
	var decay: float = clampf(length_decay * float(fd["decay_scale"]), 0.1, 0.95)
	var depth: int = 0
	var current_length: float = base_length
	var current_angle: float = base_angle * float(fd["angle_scale"])
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
				current_length *= decay
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

	# The three gradient stops are a READOUT OF RECURSION DEPTH, not decoration:
	# a segment's colour says how deep in the grammar it sits. "living" returns the
	# exported colours plus the accent that used to be a literal here, so the
	# default draws exactly the colours the shipped coral drew.
	var pal: Array = _palette()
	var col_base: Color = pal[0]
	var mid_color: Color = pal[1]
	var col_tip: Color = pal[2]

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for seg in segments:
		var p1: Vector3 = (seg[0] - center) * scale_factor
		var p2: Vector3 = (seg[1] - center) * scale_factor
		var d: int = seg[2]

		var t: float = clampf(float(d) / float(max_depth), 0.0, 1.0)

		# Two-stage gradient: base → mid → tip
		var col: Color
		if t < 0.5:
			col = col_base.lerp(mid_color, t * 2.0)
		else:
			col = mid_color.lerp(col_tip, (t - 0.5) * 2.0)

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
##
## Guarded on two counts. An unknown enum value is IGNORED rather than assigned,
## because a silent fallback to the default is how a sweep publishes N identical
## frames and calls the axis inert. And the rebuild only runs when a value actually
## changed and _ready has already built once — an unconditional _generate() here
## would redraw all 6 shipped placements on every config pass.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	var changed: bool = false

	if config_data.has("growth_form") or config_data.has("form"):
		var raw_form: String = str(config_data.get("growth_form", config_data.get("form", ""))).strip_edges().to_lower()
		if FORMS.has(raw_form) and raw_form != growth_form:
			growth_form = raw_form
			changed = true
	if config_data.has("condition"):
		var raw_cond: String = str(config_data["condition"]).strip_edges().to_lower()
		if raw_cond in CONDITIONS and raw_cond != condition:
			condition = raw_cond
			changed = true

	if config_data.has("iterations"):
		var v_iter: int = clampi(int(config_data["iterations"]), 1, 5)
		if v_iter != iterations:
			iterations = v_iter
			changed = true
	if config_data.has("base_angle"):
		var v_angle: float = float(config_data["base_angle"])
		if not is_equal_approx(v_angle, base_angle):
			base_angle = v_angle
			changed = true
	if config_data.has("num_shoots"):
		var v_shoots: int = clampi(int(config_data["num_shoots"]), 1, 8)
		if v_shoots != num_shoots:
			num_shoots = v_shoots
			changed = true
	if config_data.has("length_decay"):
		var v_decay: float = clampf(float(config_data["length_decay"]), 0.4, 0.9)
		if not is_equal_approx(v_decay, length_decay):
			length_decay = v_decay
			changed = true
	if config_data.has("display_size"):
		var v_size: float = float(config_data["display_size"])
		if not is_equal_approx(v_size, display_size):
			display_size = v_size
			changed = true
	if config_data.has("seed"):
		var v_seed: int = int(config_data["seed"])
		if v_seed != _base_seed:
			_base_seed = v_seed
			changed = true

	# Before _ready the mesh does not exist yet; _ready will build with the new
	# values anyway, so there is nothing to rebuild and _rng is still null.
	if changed and _built:
		_generate()
