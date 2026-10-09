# lsystem_tree.gd
# Simple deterministic L-system tree for the Grammar Lab.
# Uses the classic plant rule F -> F[+F]F[-F]F with a 25.7 degree
# branching angle, rendered as line segments with a brown-to-green
# depth gradient.
#
# @identity
# essence: F → F[+F]F[-F]F at 25.7° — the classic Lindenmayer plant in one rule
# desire: To stand as the canonical L-system tree — the simplest grammar that produces a convincing plant
# critical_parameter: base_angle (25.7°) — Lindenmayer's original angle, balancing spread and density perfectly
# triggers: Changing iterations → sapling to forest giant; adjusting angle → palm to pine to bush
# emerges: Branching depth creates a brown-to-green gradient — trunk becomes canopy through recursion alone
# needs: VR iteration/angle controls [missing], Label3D [has]
# relationships: Appears in LSystems_Grammar_Lab, LSystems_Growth, and LSystems_Living. The reference tree for the whole sequence.
# truth: One rule, one angle, one axiom — a tree grows.

extends Node3D

class_name LSystemTree

## Display settings
@export var display_size: float = 0.6
@export var trunk_color: Color = Color(0.45, 0.28, 0.12)
@export var tip_color: Color = Color(0.2, 0.65, 0.15)

## L-system configuration
@export var iterations: int = 4
@export var base_angle: float = 25.7
@export var base_length: float = 0.1

## DNA — how much of the derivation is on show.
## The shipped tree draws only the last generation: the rule is printed on the label
## and never seen. "result" is that tree, byte for byte.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## DNA — how the branching plane turns as the grammar descends.
## The shipped turtle only ever rotates about one axis, so the classic plant is a flat
## drawing. "planar" is that drawing, byte for byte.
@export_enum("planar", "fanned", "whorled", "spiral") var habit: String = "planar"

const EVIDENCE_VALUES := ["result", "trace", "longhand", "axiom"]

## Degrees of roll applied to the branching plane at every push. planar = 0 is the
## shipped turtle; the roll is skipped entirely at that value.
const HABIT_ROLL := {
	"planar": 0.0,
	"fanned": 30.0,
	"whorled": 90.0,
	"spiral": 137.5,
}

var _axiom: String = "F"
var _rules: Dictionary = {"F": "F[+F]F[-F]F"}
var _current_string: String = ""
var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _info_label: Label3D


func _ready() -> void:
	_create_display()
	_create_base()
	_create_label()
	_generate()


func _create_display() -> void:
	_immediate_mesh = ImmediateMesh.new()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "LSystemTreeDisplay"
	_mesh_instance.mesh = _immediate_mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = mat

	add_child(_mesh_instance)


func _create_base() -> void:
	var base := MeshInstance3D.new()
	base.name = "Base"

	var cylinder := CylinderMesh.new()
	cylinder.top_radius = display_size * 0.35
	cylinder.bottom_radius = display_size * 0.4
	cylinder.height = 0.03
	base.mesh = cylinder

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.1, 0.08)
	mat.metallic = 0.4
	mat.roughness = 0.6
	base.material_override = mat

	base.position = Vector3(0, -0.015, 0)
	add_child(base)


func _create_label() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 22
	_info_label.modulate = Color(0.85, 0.85, 0.8)
	_info_label.position = Vector3(0, display_size + 0.08, 0)
	add_child(_info_label)


func _generate() -> void:
	var gens: Array = _derive()
	_current_string = String(gens[gens.size() - 1])
	_draw_tree(gens)
	_update_label()


## Every generation of the rewrite, gens[0] = the axiom.
##
## The shipped code kept only the last string. Keeping them all costs one array of
## strings and is what lets `trace` and `longhand` show the derivation at all; the
## last element is identical to what the old loop left in _current_string, including
## the 80000-character bail-out.
func _derive() -> Array:
	var gens: Array = [_axiom]
	var current: String = _axiom

	for _i in range(iterations):
		var next: String = ""
		for c in current:
			if _rules.has(c):
				next += _rules[c]
			else:
				next += c
		current = next
		gens.append(current)
		if current.length() > 80000:
			break

	return gens


## Walk one generation's string with the turtle.
## Returns {"segments": [[start, end, depth], ...], "max_depth": int}.
func _turtle(source: String) -> Dictionary:
	# Turtle state
	var pos := Vector3.ZERO
	var dir := Vector3.UP
	var right := Vector3.RIGHT
	var up := Vector3.FORWARD
	var depth: int = 0
	var current_length: float = base_length

	# Stack stores turtle state
	var stack: Array = []

	# Collect line segments with depth info for coloring
	var segments: Array = []  # [start, end, depth]
	var max_depth: int = 0

	var angle_rad: float = deg_to_rad(base_angle)
	# planar keeps this at exactly zero, and the roll below is then never executed.
	var roll_rad: float = deg_to_rad(float(HABIT_ROLL.get(habit, 0.0)))

	for c in source:
		match c:
			"F":
				var new_pos := pos + dir * current_length
				segments.append([pos, new_pos, depth])
				pos = new_pos
			"+":
				var axis := dir.cross(right)
				if axis.length_squared() < 0.01:
					axis = up
				axis = axis.normalized()
				dir = dir.rotated(axis, angle_rad).normalized()
				right = right.rotated(axis, angle_rad).normalized()
			"-":
				var axis := dir.cross(right)
				if axis.length_squared() < 0.01:
					axis = up
				axis = axis.normalized()
				dir = dir.rotated(axis, -angle_rad).normalized()
				right = right.rotated(axis, -angle_rad).normalized()
			"[":
				stack.append({
					"pos": pos,
					"dir": dir,
					"right": right,
					"up": up,
					"depth": depth,
					"length": current_length,
				})
				depth += 1
				if depth > max_depth:
					max_depth = depth
				# Shorten branches at deeper levels
				current_length *= 0.72
				# Roll the branching plane. Skipped entirely when habit == "planar",
				# so the shipped turtle is untouched down to the last float.
				if roll_rad != 0.0:
					right = right.rotated(dir, roll_rad).normalized()
			"]":
				if stack.size() > 0:
					var state: Dictionary = stack.pop_back()
					pos = state["pos"]
					dir = state["dir"]
					right = state["right"]
					up = state["up"]
					depth = state["depth"]
					current_length = state["length"]

	return {"segments": segments, "max_depth": max_depth}


## Which generations get drawn, how dark, and in which column.
##
## Every value returns generation 1 or later: generation 0 is a single bare segment
## and carries no picture, so nothing selects it.
func _figures_for(gens: Array) -> Array:
	var last: int = gens.size() - 1
	var figures: Array = []

	match evidence:
		"axiom":
			# One application of F -> F[+F]F[-F]F. The production itself, not its limit.
			var g: int = mini(1, last)
			figures.append({"gen": g, "shade": 1.0, "column": 0})
		"trace":
			# The growth history nested inside the finished plant, at one origin.
			for i in range(1, last):
				figures.append({"gen": i, "shade": 0.35, "column": 0})
			figures.append({"gen": last, "shade": 1.0, "column": 0})
		"longhand":
			# Every rewrite laid out left to right, all at one scale.
			for i in range(1, last + 1):
				figures.append({"gen": i, "shade": 1.0, "column": i - 1})
		_:
			figures.append({"gen": last, "shade": 1.0, "column": 0})

	return figures


func _draw_tree(gens: Array) -> void:
	if not _immediate_mesh:
		return
	_immediate_mesh.clear_surfaces()
	if gens.is_empty():
		return

	var figures: Array = _figures_for(gens)
	if figures.is_empty():
		return

	# Walk each chosen generation.
	var columns: int = 1
	for fig in figures:
		var walked: Dictionary = _turtle(String(gens[int(fig["gen"])]))
		fig["segments"] = walked["segments"]
		fig["max_depth"] = maxi(int(walked["max_depth"]), 1)
		columns = maxi(columns, int(fig["column"]) + 1)

	# Column offsets. Only `longhand` has more than one column, and with one column
	# the shift is skipped outright so the arithmetic below is the shipped arithmetic.
	var shift: Array = []
	for _c in range(columns):
		shift.append(0.0)

	if columns > 1:
		var lo: Array = []
		var hi: Array = []
		for _k in range(columns):
			lo.append(INF)
			hi.append(-INF)
		for fig in figures:
			var ci: int = int(fig["column"])
			var col_lo: float = lo[ci]
			var col_hi: float = hi[ci]
			for seg in fig["segments"]:
				var s: Vector3 = seg[0]
				var e: Vector3 = seg[1]
				col_lo = minf(col_lo, minf(s.x, e.x))
				col_hi = maxf(col_hi, maxf(s.x, e.x))
			lo[ci] = col_lo
			hi[ci] = col_hi

		var cursor: float = 0.0
		for ci in range(columns):
			var col_lo2: float = lo[ci]
			var col_hi2: float = hi[ci]
			if col_lo2 == INF:
				continue
			shift[ci] = cursor - col_lo2
			cursor += (col_hi2 - col_lo2) + base_length * 2.0

	# Compute bounds for centering and scaling
	var min_bounds := Vector3(INF, INF, INF)
	var max_bounds := Vector3(-INF, -INF, -INF)
	for fig in figures:
		var dx: float = shift[int(fig["column"])]
		var slide: Vector3 = Vector3(dx, 0.0, 0.0)
		for seg in fig["segments"]:
			var s: Vector3 = seg[0]
			var e: Vector3 = seg[1]
			min_bounds = min_bounds.min(s + slide).min(e + slide)
			max_bounds = max_bounds.max(s + slide).max(e + slide)

	if min_bounds.x == INF:
		return

	var bounds_size := max_bounds - min_bounds
	var max_dim: float = maxf(maxf(bounds_size.x, bounds_size.y), maxf(bounds_size.z, 0.001))
	var scale_factor: float = display_size * 0.75 / max_dim
	# Anchor at bottom-center so tree base sits near y=0
	var center := (min_bounds + max_bounds) / 2.0
	center.y = min_bounds.y

	# Draw all segments with depth-based coloring
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for fig in figures:
		var dx2: float = shift[int(fig["column"])]
		var slide2: Vector3 = Vector3(dx2, 0.0, 0.0)
		var max_depth: int = int(fig["max_depth"])
		var shade: float = float(fig["shade"])
		for seg in fig["segments"]:
			var s2: Vector3 = seg[0]
			var e2: Vector3 = seg[1]
			var p1: Vector3 = (s2 + slide2 - center) * scale_factor
			var p2: Vector3 = (e2 + slide2 - center) * scale_factor
			var d: int = seg[2]

			var t: float = clampf(float(d) / float(max_depth), 0.0, 1.0)
			# Brown trunk to green tips gradient
			var col: Color = trunk_color.lerp(tip_color, t)
			col = col.lightened(t * 0.15)
			# Ghosted earlier generations. Untouched at shade 1.0.
			if shade < 0.999:
				col = col.darkened(1.0 - shade)

			_immediate_mesh.surface_set_color(col)
			_immediate_mesh.surface_add_vertex(p1)
			_immediate_mesh.surface_set_color(col)
			_immediate_mesh.surface_add_vertex(p2)

	_immediate_mesh.surface_end()


func _update_label() -> void:
	if not _info_label:
		return
	var segment_count: int = _current_string.count("F")
	var text: String = "L-System Tree\nRule: F->F[+F]F[-F]F\nIter: %d | Angle: %.1f° | Segments: %d" % [
		iterations, base_angle, segment_count
	]
	# The shipped label is three lines. Only a non-default axis adds to it.
	if evidence != "result":
		text += "\nEvidence: %s" % evidence
	if habit != "planar":
		text += "\nHabit: %s" % habit
	_info_label.text = text


## Grid system integration
##
## Guarded on both counts: the key has to be present AND the value has to differ.
## The shipped version rebuilt unconditionally, so any unrelated config key on a map
## token re-ran the whole rewrite; several placements pass layout keys this artifact
## has never read.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("iterations"):
		var wanted_iterations: int = clampi(int(config_data["iterations"]), 1, 6)
		if wanted_iterations != iterations:
			iterations = wanted_iterations
			changed = true

	if config_data.has("base_angle"):
		var wanted_angle: float = float(config_data["base_angle"])
		if not is_equal_approx(wanted_angle, base_angle):
			base_angle = wanted_angle
			changed = true

	if config_data.has("base_length"):
		var wanted_length: float = clampf(float(config_data["base_length"]), 0.01, 0.5)
		if not is_equal_approx(wanted_length, base_length):
			base_length = wanted_length
			changed = true

	if config_data.has("display_size"):
		var wanted_size: float = float(config_data["display_size"])
		if not is_equal_approx(wanted_size, display_size):
			display_size = wanted_size
			changed = true

	if config_data.has("evidence"):
		# Map config values arrive as strings; an unknown one is ignored rather than
		# silently rendering the default under a name that was never reached.
		var wanted_evidence: String = str(config_data["evidence"]).strip_edges().to_lower()
		if wanted_evidence != evidence and EVIDENCE_VALUES.has(wanted_evidence):
			evidence = wanted_evidence
			changed = true

	if config_data.has("habit"):
		var wanted_habit: String = str(config_data["habit"]).strip_edges().to_lower()
		if wanted_habit != habit and HABIT_ROLL.has(wanted_habit):
			habit = wanted_habit
			changed = true

	# Before _ready the exports are enough — _ready generates once, with these values.
	if changed and _immediate_mesh != null:
		_generate()
