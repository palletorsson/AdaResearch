extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name ProjectionShadow

## @identity
## lineage: vector projection made playable — proj_n(a) = (a · n̂) n̂ — the third
##   operations toy (with dot_aligner and torque_crank) for the embodied vectors-forces arc.
## essence: a sun overhead, an object floating off a rail; the object's shadow lands on the
##   rail, and the shadow's distance from the origin IS a · n̂ — the projection of the
##   object's position onto the axis. The part that doesn't reach the rail is the rejection.
## truth: a projection is the part of one vector that lives along another — the shadow it
##   casts; what's left over is what makes it different.
##
## A ToyConsole: the readout lives on the monitor, the PROJECTION slider drives the demo.
## DNA: projection 0..1 swings the object from perpendicular (no shadow) to along the rail.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var projection: float = 0.7
@export var color_a: Color = Color(0.52, 0.56, 0.62)     # rail / axis n̂
@export var color_b: Color = Color(0.40, 0.82, 0.96)     # the vector a
@export var accent: Color = Color(0.98, 0.82, 0.32)      # the projection shadow
@export var sun_color: Color = Color(1.0, 0.92, 0.62)    # the light
@export var complexity: int = 6

## AXIS — HOW MUCH OF THE ARITHMETIC THE BENCH DRAWS. Adopted word for word (and value for
## value, in order) from [[transform_composition_workbench]], and already carried by its
## siblings on this bench — [[dot_aligner]], [[vector_add]], [[vector_sub]]. Projection is
## the dot product wearing a different hat, so it takes the dot's word rather than a new one.
## The values are not borrowed empty: each names something this object genuinely has.
##
##   outcome     the shadow alone. a, the floating object, the sun, its rays and the
##               perpendicular drop all leave the render layers; an amber length sits on
##               the rail with nothing on screen to say what cast it. A projection is a
##               number on an axis — the vector it came from is not your business.
##   trace       the legacy lineage, byte for byte — a sun overhead, three rays falling
##               past the object, the dashed drop landing on the foot. Projection as an
##               ACT: light does it to you, and you can watch it happen.
##   operands    the lamp goes dark and the geometry answers instead. The angle α is swept
##               between the rail n̂ and a from their shared tail, and a right-angle
##               gnomon is planted where the drop meets the rail. Both ingredients from
##               one origin plus the perpendicularity that DEFINES a projection — the
##               shadow is a fact about an angle, not about where you put the lamp.
##   expression  the algebra promoted over the geometry — a light board above the rail
##               writing (a·n̂)n̂ = |a| cos α with the numbers substituted, between two
##               emissive rules in the accent colour.
##
## The amber shadow bar and the sun own the hottest pixels in any frame: outcome takes the
## sun out and leaves the bar, operands takes the sun out and answers for it, so the two
## disturb the frame in opposite directions from the same removal.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("projection"): projection = clampf(float(config_data["projection"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("workings"):
		var _w: String = String(config_data["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	sun_color = _parse_color(config_data.get("sun_color", sun_color), sun_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "PROJECTION SHADOW", "slider": "PROJECTION"}

func _param_get() -> float:
	return projection

func _param_set(v: float) -> void:
	projection = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("ProjectionShadowRig")
	_rng.seed = hash(seed)

	# --- the geometry -----------------------------------------------------------
	var reach: float = _rng.randf_range(1.2, 1.45)            # |a|
	var origin: Vector3 = Vector3.ZERO
	var alpha: float = acos(clampf(projection, 0.0, 1.0))     # angle of a from the rail
	var px: float = reach * projection                       # a·n̂
	var py: float = reach * sqrt(maxf(1.0 - projection * projection, 0.0))  # rejection height
	var p: Vector3 = origin + Vector3(px, py, 0.0)           # the object
	var foot: Vector3 = origin + Vector3(px, 0.0, 0.0)       # shadow lands = (a·n̂)n̂

	var steel := _steel_mat(color_a)

	# --- the rail (axis n̂) + origin marker --------------------------------------
	var rail_len: float = reach + 0.35
	rig.add_child(_box(Vector3(rail_len * 0.5, 0.0, 0.0), Vector3(rail_len, 0.05, 0.18), steel))
	rig.add_child(_arrow(Vector3(0.0, 0.05, 0.0), Vector3(rail_len, 0.05, 0.0), 0.018, _glow_mat(color_a, 0.6)))
	rig.add_child(_sphere(origin + Vector3(0.0, 0.05, 0.0), 0.05, _glow_mat(Color(0.9, 0.9, 0.95), 0.6)))

	# --- the vector a + the object ----------------------------------------------
	var arrow_a: Node3D = _arrow(origin + Vector3(0.0, 0.05, 0.0), p, 0.03, _glow_mat(color_b, 1.4))
	var object_box: Node3D = _box(p, Vector3(0.20, 0.20, 0.20), _glow_mat(color_b.lerp(Color.WHITE, 0.25), 0.8))
	rig.add_child(arrow_a)
	rig.add_child(object_box)

	# --- the sun + rays straight down -------------------------------------------
	# Held under one identity Node3D so WORKINGS can reach the whole lamp at once. The
	# holder is at the origin and its children keep their absolute rig-local positions,
	# which is exactly what _arrow and _dashed already do, so _subtree_aabb and _settle
	# see the same box they always did.
	var lamp := Node3D.new()
	lamp.name = "SunLamp"
	rig.add_child(lamp)
	var sun_pos: Vector3 = p + Vector3(0.0, 0.95, 0.0)
	lamp.add_child(_sphere(sun_pos, 0.16, _glow_mat(sun_color, 4.5)))
	var ray_mat := _glow_mat(sun_color, 0.5)
	for dx in [-0.07, 0.0, 0.07]:
		lamp.add_child(_cylinder_between(sun_pos + Vector3(dx, 0.0, 0.0), foot + Vector3(dx, 0.0, 0.0), 0.004, ray_mat))

	# --- the projection (shadow): O → foot --------------------------------------
	rig.add_child(_box(Vector3(px * 0.5, 0.028, 0.0), Vector3(maxf(px, 0.02), 0.06, 0.22), _glow_mat(accent, 1.4 + 1.6 * projection)))
	rig.add_child(_sphere(foot + Vector3(0.0, 0.04, 0.0), 0.07, _glow_mat(accent, 2.4)))
	rig.add_child(_box(foot + Vector3(0.0, 0.03, 0.0), Vector3(0.22, 0.012, 0.22), _shadow_mat()))

	# --- the rejection (perpendicular drop) -------------------------------------
	var reject: Node3D = null
	if py > 0.03:
		reject = _dashed(p, foot, 0.014, _glow_mat(color_b.lerp(Color(0.2, 0.2, 0.24), 0.5), 0.5))
		rig.add_child(reject)

	# --- readout -> the monitor --------------------------------------------------
	set_readout("PROJ  (a · n̂) n̂\n\na · n̂ = %.2f\nα = %d°" % [px, int(roundf(rad_to_deg(alpha)))],
		Color(1.0, 0.85, 0.5))

	_settle(rig)

	# WORKINGS dressing, appended AFTER _settle so the legacy geometry keeps the exact fit
	# and placement it has today — nothing above this line moves. "trace" falls through and
	# adds nothing at all.
	match _workings_value():
		"outcome":
			_workings_outcome(arrow_a, object_box, lamp, reject)
		"operands":
			_workings_operands(rig, origin, p, foot, reach)
		"expression":
			_workings_expression(rig, rail_len, py, reach, px, alpha)
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


## OUTCOME — the shadow alone. The vector a, the floating object, the whole lamp and the
## perpendicular drop leave the render layers. What remains is the rail, the origin marker
## and an amber length lying on it: the projection as a bare number on an axis, with nothing
## in frame to say which vector it is the shadow of. The rail stays because it is the
## coordinate the answer is stated in, not part of the arithmetic — and because it is the
## widest MeshInstance3D here, so the capture keeps a stable box to fit.
func _workings_outcome(arrow_a: Node3D, object_box: Node3D, lamp: Node3D, reject: Node3D) -> void:
	_unlayer(arrow_a)
	_unlayer(object_box)
	_unlayer(lamp)
	if reject != null:
		_unlayer(reject)


## OPERANDS — the lamp goes dark and the geometry answers in its place. The angle α is swept
## between the rail n̂ and a from the tail they share, and a right-angle gnomon is planted
## where the drop meets the rail. Both ingredients from one origin, plus the perpendicularity
## that DEFINES a projection: the shadow's length is a fact about that angle, and would be
## the same length if you moved the lamp or took it away.
func _workings_operands(rig: Node3D, origin: Vector3, p: Vector3, foot: Vector3, reach: float) -> void:
	var lamp: Node = rig.get_node_or_null("SunLamp")
	if lamp != null:
		_unlayer(lamp)

	# n̂ redrawn as a vector from the shared tail, so the rail reads as an operand
	var tail: Vector3 = origin + Vector3(0.0, 0.05, 0.0)
	var unit_mat := _glow_mat(color_a.lerp(Color.WHITE, 0.3), 1.5)
	rig.add_child(_arrow(tail, tail + Vector3(1.0, 0.0, 0.0), 0.022, unit_mat))
	rig.add_child(_sphere(tail + Vector3(1.0, 0.0, 0.0), 0.045, unit_mat))

	# the α arc between n̂ and a
	var arc_mat := _glow_mat(color_b.lerp(accent, 0.4), 1.6)
	var to_a: Vector3 = (p - tail).normalized()
	var span: float = Vector3.RIGHT.angle_to(to_a)
	var radius: float = clampf(reach * 0.34, 0.18, 0.55)
	var steps: int = clampi(complexity + 4, 6, 16)
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var dir: Vector3 = Vector3.RIGHT.rotated(Vector3.BACK, span * t).normalized()
		rig.add_child(_sphere(tail + dir * radius, 0.017, arc_mat))

	# the right-angle gnomon at the foot: the corner mark, drawn in the drop's own quadrant
	var g: float = 0.15
	var gm := _glow_mat(Color(0.90, 0.93, 1.0), 1.4)
	var corner: Vector3 = foot + Vector3(0.0, 0.03, 0.0)
	rig.add_child(_cylinder_between(corner + Vector3(0.0, g, 0.0), corner + Vector3(-g, g, 0.0), 0.011, gm))
	rig.add_child(_cylinder_between(corner + Vector3(-g, 0.0, 0.0), corner + Vector3(-g, g, 0.0), 0.011, gm))


## EXPRESSION — the algebra promoted over the geometry. A light Braun plate stands above the
## rail and writes the identity out with the numbers substituted, held between two emissive
## rules in the accent colour so the writing owns hot pixels of its own.
func _workings_expression(rig: Node3D, rail_len: float, py: float, reach: float,
		px: float, alpha: float) -> void:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	# clear of the sun, whose top sits at py + 1.11; the board's half-height is 0.29
	board.position = Vector3(rail_len * 0.5, py + 1.55, 0.0)
	rig.add_child(board)
	board.add_child(_box(Vector3.ZERO, Vector3(2.10, 0.58, 0.03), _panel_mat(PANEL_LIGHT)))
	board.add_child(_box(Vector3(0.0, 0.29, 0.02), Vector3(2.10, 0.032, 0.02), _glow_mat(accent, 1.9)))
	board.add_child(_box(Vector3(0.0, -0.29, 0.02), Vector3(2.10, 0.032, 0.02), _glow_mat(accent, 1.9)))
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "(a · n̂) n̂  =  |a| cos α\n%.2f × cos %d°  =  %.2f" % [
		reach, int(roundf(rad_to_deg(alpha))), px]
	l.font_size = 40
	l.pixel_size = 0.0038
	l.modulate = TEXT_DARK
	l.outline_size = 6
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.03)
	board.add_child(l)


# --- toy-specific helper ----------------------------------------------------

func _shadow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.05, 0.07)
	m.roughness = 1.0
	return m
