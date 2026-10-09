extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name VectorOpConsole

## @identity
## lineage: vector addition & subtraction made playable — a + b (and a − b = a + (−b)) —
##   the entry operations of the embodied vectors-forces arc, the pair that precedes the dot.
## essence: two 2D pads, one per vector. Drag a pad and that vector's tip follows your hand;
##   the two arrows draw head-to-tail and the resultant swings live. The control IS the tip.
## truth: a + b is not two numbers added twice — it is where you arrive if you walk a, then b;
##   a − b is where b's tip must reach to land on a's.
##
## A ToyConsole with a TWO-PAD control bank (synthesis of three surface designs): the pads
## give direct tip placement (grabbed in VR, pointer-dragged on desktop), the monitor shows
## the full component breakdown. op flips the same console between addition and subtraction.

enum Op { ADD, SUB }

@export var op: Op = Op.ADD
@export var seed: int = 0
@export var color_a: Color = Color(0.38, 0.82, 1.00)   # a — cyan
@export var color_b: Color = Color(0.98, 0.64, 0.28)   # b — amber
@export var color_c: Color = Color(0.62, 0.95, 0.58)   # resultant — green
@export var color_neg: Color = Color(0.78, 0.50, 0.98) # the −b ghost (subtraction)
@export var color_guide: Color = Color(0.52, 0.57, 0.66)

## AXIS — HOW MUCH OF THE ARITHMETIC THE BENCH DRAWS. Adopted word for word (and value
## for value, in order) from [[transform_composition_workbench]], which asks the same
## question about composing transforms. One word for the whole vector subject, so a room
## that shows a sum as a walked route cannot show its dot product as a bare answer.
##
##   outcome     only where you ended up. a, the route leg and the component rectangle
##               leave the render layers; the green resultant stands alone from the
##               origin. A sum is a destination, not a journey.
##   trace       the legacy lineage, byte for byte — the TRIANGLE rule: a from the
##               origin, b (or −b) from a's TIP, the resultant closing them. The answer
##               is a walk you took.
##   operands    the PARALLELOGRAM rule instead. The head-to-tail leg goes dark and b is
##               redrawn from the shared origin, with the two dashed sides closing the
##               figure. Both ingredients from one tail; the resultant is the diagonal.
##   expression  the algebra promoted over the geometry — a light board above the plane
##               writing the component sum out with the numbers substituted, between two
##               emissive rules in the resultant's colour.
##
## The arrows are the pivot, the way the lit seam is on station_wall: they own the
## brightest pixels in any frame, and outcome/operands each move one of them.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]

const SPAN := 1.25   # demo-plane half-extent that a pad's full travel maps to

var a: Vector2 = Vector2(0.9, 0.3)
var b: Vector2 = Vector2(0.3, 0.8)


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed)
	a = Vector2(rng.randf_range(0.55, 1.0), rng.randf_range(0.0, 0.45))
	b = Vector2(rng.randf_range(-0.2, 0.45), rng.randf_range(0.5, 0.95))
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("op"):
		op = Op.SUB if String(config_data["op"]).to_lower().begins_with("sub") else Op.ADD
	if config_data.has("workings"):
		var _w: String = String(config_data["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	color_c = _parse_color(config_data.get("color_c", color_c), color_c)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed)
	a = Vector2(rng.randf_range(0.55, 1.0), rng.randf_range(0.0, 0.45))
	b = Vector2(rng.randf_range(-0.2, 0.45), rng.randf_range(0.5, 0.95))
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "VECTOR  a + b" if op == Op.ADD else "VECTOR  a − b"}


# --- the two pads: each places one vector's tip ------------------------------
func _controls() -> Array:
	return [
		{"label": "a-TIP", "kind": "pad",
			"get": func() -> Vector2: return a / SPAN,
			"set": func(v: Vector2) -> void: a = v * SPAN},
		{"label": "b-TIP", "kind": "pad",
			"get": func() -> Vector2: return b / SPAN,
			"set": func(v: Vector2) -> void: b = v * SPAN},
	]


func _build_demo() -> void:
	var rig := _fresh_demo_rig("VectorOpRig")
	var sub: bool = (op == Op.SUB)
	var b_eff: Vector2 = (-b) if sub else b
	var c: Vector2 = a + b_eff

	var O := Vector3.ZERO
	var pa := _v3(a)
	var pc := _v3(c)
	var mat_g := _glow_mat(color_guide, 0.5)

	# a faint backing panel so the standing board reads as a surface (not floating arrows)
	rig.add_child(_box(Vector3(0, 0, -0.02), Vector3(2.0 * SPAN + 0.4, 2.0 * SPAN + 0.4, 0.02), _screen_mat()))

	# cross-hair on the VERTICAL board plane (x across, y up) so the plane stands and reads
	rig.add_child(_dashed(O + Vector3(-SPAN, 0, 0), O + Vector3(SPAN, 0, 0), 0.006, mat_g))
	rig.add_child(_dashed(O + Vector3(0, -SPAN, 0), O + Vector3(0, SPAN, 0), 0.006, mat_g))

	# component rectangle: cx = ax±bx across, then cy up to c
	var rect_x: Node3D = _dashed(O, O + Vector3(c.x, 0, 0), 0.007, mat_g)
	var rect_y: Node3D = _dashed(O + Vector3(c.x, 0, 0), pc, 0.007, mat_g)
	rig.add_child(rect_x)
	rig.add_child(rect_y)

	# the head-to-tail construction, standing on the board
	var arrow_a: Node3D = _arrow(O, pa, 0.026, _glow_mat(color_a, 1.4))        # a from origin
	var arrow_b: Node3D = _arrow(pa, pc, 0.024, _glow_mat(color_b, 1.4))       # b (or −b) from a's tip
	rig.add_child(arrow_a)
	rig.add_child(arrow_b)
	rig.add_child(_arrow(O, pc, 0.032, _glow_mat(color_c, 1.8)))              # resultant

	# subtraction: ghost the original +b at the origin so −b reads as a flip
	var ghost: Node3D = null
	if sub:
		ghost = _arrow(O, _v3(b), 0.018, _glow_mat(color_neg, 0.8))
		rig.add_child(ghost)

	rig.add_child(_sphere(O, 0.05, _glow_mat(Color(0.82, 0.86, 0.95), 0.5)))   # shared tail
	rig.add_child(_sphere(pc, 0.055, _glow_mat(color_c, 1.6)))                 # resultant head

	# --- readout -> the monitor --------------------------------------------------
	var sgn := "+" if not sub else "−"
	var name_s := ("a + b" if not sub else "a − b")
	var ang := fposmod(rad_to_deg(atan2(c.y, c.x)), 360.0)
	set_readout("VECTOR  %s\n\na = (%+.2f, %+.2f)\nb = (%+.2f, %+.2f)\n────────\n%s = (%+.2f, %+.2f)\n|%s| = %.2f  ∠%d°"
		% [name_s, a.x, a.y, b.x, b.y, name_s, c.x, c.y, name_s, c.length(), int(roundf(ang))],
		color_c if not sub else Color(1.0, 0.80, 0.55))

	_settle(rig)

	# WORKINGS dressing, appended AFTER _settle so the legacy geometry keeps the exact
	# fit and placement it has today — nothing above this line moves. "trace" falls
	# through and adds nothing at all.
	match _workings_value():
		"outcome":
			_workings_outcome(arrow_a, arrow_b, ghost, rect_x, rect_y)
		"operands":
			_workings_operands(rig, O, pa, pc, b_eff, arrow_b)
		"expression":
			_workings_expression(rig, a, b, c, sub)
		_:
			pass                                   # "trace" — the legacy lineage


# math plane (x, y) -> the standing board's plane (x across, y up)
func _v3(v: Vector2) -> Vector3:
	return Vector3(v.x, v.y, 0.0)


# --- WORKINGS ---------------------------------------------------------------
# One axis, four values. Nothing here runs on the default. Removal is always
# `layers = 0` on the MeshInstance3D leaves — never `visible = false`, which in
# Godot takes a holder's whole subtree with it.

func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "trace"


func _unlayer(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 0
	for child in n.get_children():
		_unlayer(child)


## OUTCOME — the destination alone. a, the head-to-tail leg, the −b ghost and the
## component rectangle all leave the render layers; the cross-hair stays because it is
## the frame, not the arithmetic. One green arrow from the origin to where you ended up.
func _workings_outcome(arrow_a: Node3D, arrow_b: Node3D, ghost: Node3D,
		rect_x: Node3D, rect_y: Node3D) -> void:
	_unlayer(arrow_a)
	_unlayer(arrow_b)
	_unlayer(rect_x)
	_unlayer(rect_y)
	if ghost != null:
		_unlayer(ghost)


## OPERANDS — the parallelogram rule in place of the triangle rule. The leg standing on
## a's tip goes dark and b is redrawn from the SHARED origin, so both ingredients start
## where the answer starts; two dashed sides close the figure and the resultant becomes
## its diagonal. Addition stops being a walk and becomes a shape.
func _workings_operands(rig: Node3D, O: Vector3, pa: Vector3, pc: Vector3,
		b_eff: Vector2, arrow_b: Node3D) -> void:
	_unlayer(arrow_b)
	var pb: Vector3 = _v3(b_eff)
	var side := _glow_mat(color_guide.lerp(color_b, 0.5), 0.9)
	rig.add_child(_arrow(O, pb, 0.024, _glow_mat(color_b, 1.4)))   # b from the shared tail
	rig.add_child(_dashed(pa, pc, 0.010, side))                    # the copy of b, riding a
	rig.add_child(_dashed(pb, pc, 0.010, side))                    # the copy of a, riding b
	rig.add_child(_sphere(pb, 0.042, _glow_mat(color_b, 1.2)))


## EXPRESSION — the algebra promoted over the geometry. A light Braun plate stands above
## the plane and writes the component sum out with the numbers substituted, held between
## two emissive rules in the resultant's colour so the writing owns hot pixels too.
func _workings_expression(rig: Node3D, va: Vector2, vb: Vector2, vc: Vector2, sub: bool) -> void:
	var sgn: String = "−" if sub else "+"
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = Vector3(0.0, SPAN + 0.42, 0.06)
	rig.add_child(board)
	board.add_child(_box(Vector3.ZERO, Vector3(2.30, 0.62, 0.03), _panel_mat(PANEL_LIGHT)))
	board.add_child(_box(Vector3(0.0, 0.31, 0.02), Vector3(2.30, 0.035, 0.02), _glow_mat(color_c, 1.8)))
	board.add_child(_box(Vector3(0.0, -0.31, 0.02), Vector3(2.30, 0.035, 0.02), _glow_mat(color_c, 1.8)))
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "(%+.2f, %+.2f)  %s  (%+.2f, %+.2f)\n=  (%+.2f, %+.2f)" % [
		va.x, va.y, sgn, vb.x, vb.y, vc.x, vc.y]
	l.font_size = 40
	l.pixel_size = 0.0042
	l.modulate = TEXT_DARK
	l.outline_size = 6
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.03)
	board.add_child(l)
