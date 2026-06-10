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
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
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

	var lift := 0.04
	var O := Vector3(0.0, lift, 0.0)
	var pa := _v3(a, lift)
	var pc := _v3(c, lift)
	var mat_g := _glow_mat(color_guide, 0.5)

	# ground cross-hair so the plane reads
	rig.add_child(_dashed(O + Vector3(-SPAN, 0, 0), O + Vector3(SPAN, 0, 0), 0.006, mat_g))
	rig.add_child(_dashed(O + Vector3(0, 0, -SPAN), O + Vector3(0, 0, SPAN), 0.006, mat_g))

	# component rectangle: cx = ax±bx along X, then cy up to c
	rig.add_child(_dashed(O, O + Vector3(c.x, 0, 0), 0.007, mat_g))
	rig.add_child(_dashed(O + Vector3(c.x, 0, 0), pc, 0.007, mat_g))

	# the head-to-tail construction
	rig.add_child(_arrow(O, pa, 0.026, _glow_mat(color_a, 1.4)))               # a from origin
	rig.add_child(_arrow(pa, pc, 0.024, _glow_mat(color_b, 1.4)))              # b (or −b) from a's tip
	rig.add_child(_arrow(O, pc, 0.032, _glow_mat(color_c, 1.8)))              # resultant

	# subtraction: ghost the original +b at the origin so −b reads as a flip
	if sub:
		rig.add_child(_arrow(O, _v3(b, lift), 0.018, _glow_mat(color_neg, 0.8)))

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


# math plane (x, y) -> console-top plane (x, lift, y)
func _v3(v: Vector2, lift: float) -> Vector3:
	return Vector3(v.x, lift, v.y)
