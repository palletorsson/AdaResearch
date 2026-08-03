extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name BounceWell

## @identity
## lineage: restitution made playable — h' = e·h, the bounce that keeps a fraction of its
##   height — a forces toy for the embodied vectors-forces arc (the clean console rebuild
##   of the old bouncing-ball sim).
## essence: a ball dropped into a well bounces, and each bounce returns to e times the last
##   height; frozen stroboscopically, the arcs shrink geometrically and bunch toward the
##   rest. e = 1 is a perpetual bounce, e = 0 a dead thud.
## truth: a bounce is a negotiation with the floor — how much of your fall you are allowed
##   to keep; restitution is the floor's mercy, between nothing and everything.
##
## A ToyConsole: the readout lives on the monitor, the RESTITUTION slider drives the demo.
## DNA: restitution 0..1 from dead thud to perpetual bounce.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var restitution: float = 0.6
@export var color_a: Color = Color(0.52, 0.56, 0.62)     # floor / rig
@export var color_b: Color = Color(0.40, 0.82, 0.96)     # the ball + arcs
@export var accent: Color = Color(0.98, 0.72, 0.30)      # apex markers / height ticks
@export var complexity: int = 6

## AXIS — HOW MUCH OF THE ARITHMETIC THE BENCH DRAWS. Adopted word for word (and value
## for value, in order) from [[transform_composition_workbench]] and shared across the
## whole vector subject.
##
##   outcome     the heights alone. The incoming drop and every stroboscopic arc leave
##               the render layers; the floor, the apex balls, their ticks and the rest
##               marker remain. A bounce series is a list of numbers — the flights
##               between them are not shown.
##   trace       the legacy lineage, byte for byte — the drop and all the arcs strobed
##               out as ~100 fading spheres. The answer is a path.
##   operands    the ingredients laid out. Each apex height is carried left to a shared
##               gauge column as a rule, and a bracket between consecutive rules shows
##               the SAME multiplier being applied again — the e in h' = e·h, over and
##               over, which is the only thing the series actually is.
##   expression  the algebra promoted over the geometry — a light board writing h' = e·h
##               with e substituted and the first heights spelled out, between two
##               emissive rules in the accent colour.
##
## The arcs are the pivot: ~100 emissive spheres are the brightest mass in any frame, and
## outcome is the only value that takes them out.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("restitution"): restitution = clampf(float(config_data["restitution"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("workings"):
		var _w: String = String(config_data["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "BOUNCE WELL", "slider": "RESTITUTION"}

func _param_get() -> float:
	return restitution

func _param_set(v: float) -> void:
	restitution = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("BounceWellRig")
	_rng.seed = hash(seed)

	var e: float = clampf(restitution, 0.05, 0.97)
	var bounces: int = clampi(complexity + 3, 5, 9)
	var h0: float = 0.95
	var base_w: float = 0.6
	var steel := _steel_mat(color_a)

	# --- the floor + a drop guide -----------------------------------------------
	# total span first, so we can size the floor
	var total_w: float = 0.0
	for i in range(bounces):
		total_w += base_w * sqrt(maxf(pow(e, float(i)), 0.03))
	rig.add_child(_box(Vector3(total_w * 0.5, -0.03, 0.0), Vector3(total_w + 0.5, 0.06, 0.5), steel))
	rig.add_child(_box(Vector3(-0.18, h0 * 0.5, 0.0), Vector3(0.05, h0, 0.18), steel))   # drop tower

	# --- incoming drop ----------------------------------------------------------
	var flight := Node3D.new()
	flight.name = "Flight"
	rig.add_child(flight)
	var drop_seg: int = 6
	for j in range(drop_seg + 1):
		var t: float = float(j) / float(drop_seg)
		var y: float = h0 * (1.0 - t * t)
		flight.add_child(_sphere(Vector3(lerpf(-0.05, 0.06, t), y, 0.0), 0.04, _glow_mat(color_b, lerpf(0.6, 1.2, t))))

	# --- the bounce series: apex heights decay by e -----------------------------
	var x: float = 0.0
	var apex_xs: Array = []
	for i in range(bounces):
		var hi: float = h0 * pow(e, float(i))
		var wi: float = base_w * sqrt(maxf(hi / h0, 0.03))
		var fade: float = float(i) / float(bounces - 1)
		var arc_mat := _glow_mat(color_b.lerp(Color(0.16, 0.18, 0.22), fade * 0.7), lerpf(1.2, 0.4, fade))
		var steps: int = 9
		for j in range(steps + 1):
			var t: float = float(j) / float(steps)
			var px: float = x + wi * t
			var py: float = 4.0 * hi * t * (1.0 - t)
			flight.add_child(_sphere(Vector3(px, py, 0.0), 0.035, arc_mat))
		# apex ball + a faint height tick
		var apex_x: float = x + wi * 0.5
		apex_xs.append(apex_x)
		rig.add_child(_sphere(Vector3(apex_x, hi, 0.0), 0.085, _glow_mat(accent, 2.2)))
		rig.add_child(_box(Vector3(apex_x, hi * 0.5, 0.0), Vector3(0.006, hi, 0.006), _glow_mat(accent.lerp(Color(0.2, 0.2, 0.24), 0.5), 0.4)))
		x += wi

	# rest marker where the bouncing dies
	rig.add_child(_sphere(Vector3(x, 0.04, 0.0), 0.06, _glow_mat(accent, 2.6)))

	set_readout("RESTITUTION\n\nh' = e·h\ne = %.2f" % e, Color(1.0, 0.82, 0.5))
	_settle(rig)

	# WORKINGS dressing, appended AFTER _settle so the legacy geometry keeps the exact
	# fit and placement it has today. "trace" falls through and adds nothing.
	match _workings_value():
		"outcome":
			_unlayer(flight)
		"operands":
			_workings_operands(rig, e, h0, bounces, apex_xs)
		"expression":
			_workings_expression(rig, e, h0, total_w)
		_:
			pass                                   # "trace" — the legacy lineage


# --- WORKINGS ---------------------------------------------------------------
# One axis, four values, shared word for word with the rest of the vector subject.
# Removal is always `layers = 0` on the MeshInstance3D leaves — never `visible = false`,
# which in Godot takes a holder's whole subtree with it.

func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "trace"


func _unlayer(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 0
	for child in n.get_children():
		_unlayer(child)


## OPERANDS — the ingredients laid out. Every apex height is carried back to a shared
## gauge column at the left as a horizontal rule, so the whole series is stacked on one
## axis; a bracket between each pair of rules is the SAME multiplier applied again. The
## bench stops being a bouncing ball and becomes a geometric sequence with its ratio shown.
func _workings_operands(rig: Node3D, e: float, h0: float, bounces: int, apex_xs: Array) -> void:
	var gx: float = -0.42
	var rule := _glow_mat(accent.lerp(color_b, 0.35), 1.4)
	var step := _glow_mat(accent, 2.4)
	# the gauge column itself
	rig.add_child(_box(Vector3(gx, h0 * 0.5, 0.0), Vector3(0.018, h0 + 0.06, 0.018), rule))
	for i in range(bounces):
		var hi: float = h0 * pow(e, float(i))
		var ax: float = float(apex_xs[i]) if i < apex_xs.size() else 0.0
		rig.add_child(_box(Vector3((gx + ax) * 0.5, hi, 0.0), Vector3(maxf(ax - gx, 0.02), 0.012, 0.012), rule))
		if i > 0:
			# the ×e bracket: the drop from the previous rule to this one, on the gauge
			var prev: float = h0 * pow(e, float(i - 1))
			rig.add_child(_box(Vector3(gx - 0.09, (prev + hi) * 0.5, 0.0),
				Vector3(0.024, maxf(prev - hi, 0.01), 0.024), step))


## EXPRESSION — the algebra promoted over the geometry. A light Braun plate above the
## series writes the recurrence out with e substituted and the first heights spelled, held
## between two emissive rules so the writing owns hot pixels of its own.
func _workings_expression(rig: Node3D, e: float, h0: float, total_w: float) -> void:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = Vector3(total_w * 0.5, h0 + 0.68, 0.0)
	rig.add_child(board)
	board.add_child(_box(Vector3.ZERO, Vector3(2.10, 0.52, 0.03), _panel_mat(PANEL_LIGHT)))
	board.add_child(_box(Vector3(0.0, 0.26, 0.02), Vector3(2.10, 0.030, 0.02), _glow_mat(accent, 1.9)))
	board.add_child(_box(Vector3(0.0, -0.26, 0.02), Vector3(2.10, 0.030, 0.02), _glow_mat(accent, 1.9)))
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "h′  =  e · h      e = %.2f\n%.2f → %.2f → %.2f → %.2f" % [
		e, h0, h0 * e, h0 * e * e, h0 * e * e * e]
	l.font_size = 40
	l.pixel_size = 0.0034
	l.modulate = TEXT_DARK
	l.outline_size = 6
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.03)
	board.add_child(l)
