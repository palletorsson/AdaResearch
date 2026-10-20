# BooleanNeck.gd — a bar bitten from both sides until it stops being one bar
#
# @identity
# essence: a slab with a row of spheres subtracted from it, biting in from above and below, so the material narrows to a neck at each bite and parts when a bite goes too deep
# desire: learner meets subtraction as something that changes WHAT A THING IS, not how it looks — the same operation that thins a bar also decides how many bars there are
# critical_parameter: gap — how deep the bites go (open / narrow / pinched / severed); under it row decides how the bites are arranged along the bar
# triggers: none; the profile is re-measured and the component count re-derived whenever gap or row changes
# emerges: the recognition that connectivity is a consequence of geometry and not a separate fact about it — nobody cut the bar in two, they only made a hole slightly too big
# relationships: the boolean case of [[bridge_cut]], where the separator was a single edge; here it is the last millimetre of material at a neck
# truth: a difference operation is a connectivity operation, and the moment it becomes one is not marked anywhere in the operation itself
extends Node3D
class_name BooleanNeck

## BUILT WITH CSG, BECAUSE THE QUESTION WAS WHETHER IT COULD BE.
##
## Palle, 2026-10-13, reading the "local annuli join ordered arms" figure: "Can
## we make that form with booleans?" So the body is a CSGCombiner3D holding a
## CSGBox3D with CSGSphere3D cutters in subtraction mode. The form really is the
## difference; it is not a mesh drawn to look like one.
##
## THE VERDICT IS NOT READ BACK OUT OF THE CSG. Godot will not hand you the
## component count of a CSG result, so the number of pieces is derived
## analytically from the same radii and centres that position the cutters: at
## each sample along the bar the remaining half-thickness is the slab's minus
## the deepest penetration there, and a run of positive thickness is a piece.
##
## That is two implementations of one rule, which is the shape of a known trap
## in this project -- long_museum.py re-derived the museum's geometry in Python
## and drifted from the engine by three rows per hall. The mitigation here is
## that both read the SAME array of cutter positions and radii, computed once in
## _layout(), rather than each deciding where the cutters go. If they ever
## disagree, that array is the single place to look.

const GAPS := {"open": 0.55, "narrow": 0.84, "pinched": 0.985, "severed": 1.18}
const ROWS := ["even", "staggered", "paired", "single"]

@export_enum("open", "narrow", "pinched", "severed") var gap: String = "narrow":
	set(v):
		gap = v
		if is_inside_tree():
			_rebuild()

@export_enum("even", "staggered", "paired", "single") var row: String = "even":
	set(v):
		row = v
		if is_inside_tree():
			_rebuild()

@export var bar_length: float = 0.46
@export var bar_half_height: float = 0.045
@export var bar_depth: float = 0.07
@export var show_readout: bool = true

@export var bar_color: Color = Color(0.16, 0.42, 0.40)
@export var cut_color: Color = Color(0.88, 0.42, 0.18)
@export var severed_color: Color = Color(0.92, 0.75, 0.22)

const SAMPLES := 400

## [x, y, radius] per cutter. The ONE source both the CSG and the profile read.
var _cutters: Array = []
var _pieces: int = 1
var _min_neck: float = 0.0
var _built: Node3D


func _ready() -> void:
	_built = Node3D.new()
	_built.name = "Built"
	add_child(_built)
	_rebuild()


# ------------------------------------------------------------- the one array

func _layout() -> void:
	_cutters.clear()
	var depth: float = GAPS.get(gap, 0.84)
	# radius chosen so that `depth` is the fraction of the bar's half-height the
	# cutter removes when centred on the surface: at 1.0 it just touches the
	# midline from one side, and two opposing cutters at 1.0 meet exactly there
	var r := bar_half_height * depth + bar_half_height * 0.55
	var off := bar_half_height + bar_half_height * 0.55     # centre sits outside
	match row:
		"even":
			for i in range(4):
				var x := -bar_length * 0.5 + bar_length * (float(i) + 0.5) / 4.0
				_cutters.append([x, off, r])
				_cutters.append([x, -off, r])
		"staggered":
			for i in range(6):
				var x := -bar_length * 0.5 + bar_length * (float(i) + 0.5) / 6.0
				_cutters.append([x, off if i % 2 == 0 else -off, r])
		"paired":
			for i in range(2):
				var cx := -bar_length * 0.26 + bar_length * 0.52 * float(i)
				for d in [-1.0, 1.0]:
					_cutters.append([cx + d * bar_length * 0.055, off, r])
					_cutters.append([cx + d * bar_length * 0.055, -off, r])
		"single":
			_cutters.append([0.0, off, r])
			_cutters.append([0.0, -off, r])


## Remaining half-thickness above and below the midline, sampled along the bar.
## A run where BOTH sides still have material is one piece.
func _measure() -> void:
	var solid: Array[bool] = []
	_min_neck = bar_half_height * 2.0
	for i in range(SAMPLES):
		var x := -bar_length * 0.5 + bar_length * float(i) / float(SAMPLES - 1)
		var top := bar_half_height
		var bot := -bar_half_height
		for c in _cutters:
			var cx: float = c[0]
			var cy: float = c[1]
			var r: float = c[2]
			var dx := absf(x - cx)
			if dx >= r:
				continue
			var half := sqrt(r * r - dx * dx)       # the cutter's extent in y here
			if cy > 0.0:
				top = minf(top, cy - half)
			else:
				bot = maxf(bot, cy + half)
		var thick := top - bot
		_min_neck = minf(_min_neck, maxf(thick, 0.0))
		solid.append(thick > 0.0)
	var pieces := 0
	var was := false
	for s in solid:
		if s and not was:
			pieces += 1
		was = s
	_pieces = pieces


# ----------------------------------------------------------------- the body

func _rebuild() -> void:
	if _built == null:
		return
	for c in _built.get_children():
		c.queue_free()

	_layout()
	_measure()

	var comb := CSGCombiner3D.new()
	comb.name = "Boolean"
	comb.use_collision = false
	_built.add_child(comb)

	var bar := CSGBox3D.new()
	bar.size = Vector3(bar_length, bar_half_height * 2.0, bar_depth)
	var m := StandardMaterial3D.new()
	m.albedo_color = severed_color if _pieces != 1 else bar_color
	m.metallic = 0.25
	m.roughness = 0.45
	m.emission_enabled = true
	m.emission = m.albedo_color
	m.emission_energy_multiplier = 0.22
	bar.material = m
	comb.add_child(bar)

	for c in _cutters:
		var s := CSGSphere3D.new()
		s.radius = c[2]
		s.radial_segments = 24
		s.rings = 12
		s.operation = CSGShape3D.OPERATION_SUBTRACTION
		s.position = Vector3(c[0], c[1], 0.0)
		comb.add_child(s)

	# the cutters again, as faint wire ghosts, so the subtraction is legible as
	# an operation and not just as a result
	for c in _cutters:
		var g := SphereMesh.new()
		g.radius = c[2]
		g.height = c[2] * 2.0
		g.radial_segments = 20
		g.rings = 10
		var gi := MeshInstance3D.new()
		gi.mesh = g
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(cut_color.r, cut_color.g, cut_color.b, 0.12)
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.cull_mode = BaseMaterial3D.CULL_DISABLED
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gi.mesh.material = gm
		gi.position = Vector3(c[0], c[1], 0.0)
		_built.add_child(gi)

	if show_readout:
		var plate := Label3D.new()
		plate.text = _verdict()
		plate.font_size = 40
		plate.pixel_size = 0.00042
		plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		plate.modulate = severed_color if _pieces != 1 else bar_color
		plate.position = Vector3(0, bar_half_height * 2.0 + 0.10, 0)
		_built.add_child(plate)

	# CSG is not a MeshInstance3D, so the capture AABB cannot see the bar at all
	var anchor := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(bar_length * 1.1, bar_half_height * 5.0, bar_depth * 1.4)
	anchor.mesh = bm
	anchor.layers = 0
	anchor.name = "ExtentAnchor"
	_built.add_child(anchor)


func _verdict() -> String:
	var mm := _min_neck * 1000.0
	if _pieces == 1:
		return "ONE BAR\nthinnest neck %.1f mm" % mm
	return "%d PIECES\nthe neck reached zero" % _pieces


# ------------------------------------------------------------- the map's hand

func apply_grid_config(config_data: Dictionary) -> void:
	var dirty := false
	if config_data.has("gap"):
		var g := str(config_data["gap"]).to_lower().strip_edges()
		if GAPS.has(g):
			gap = g
			dirty = true
	if config_data.has("row"):
		var r := str(config_data["row"]).to_lower().strip_edges()
		if ROWS.has(r):
			row = r
			dirty = true
	if config_data.has("show_readout"):
		show_readout = bool(config_data["show_readout"])
		dirty = true
	if dirty and is_inside_tree():
		_rebuild()


## Readable by a probe, so the claim is testable without reading pixels.
func piece_count() -> int:
	return _pieces


func thinnest_neck() -> float:
	return _min_neck
