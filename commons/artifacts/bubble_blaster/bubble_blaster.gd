extends "res://commons/artifacts/_embodied/pickable_prop.gd"
class_name BubbleBlaster

## @identity
## lineage: a particle launcher with its launch vector drawn on the muzzle — a soap-bubble
##   gun that fires a stream of bubbles and shows the output force/velocity that throws them.
##   An embodied force-display prop (the held thing whose output IS a vector).
## essence: pull the trigger and bubbles pour out a spreading cone; the muzzle wears an
##   arrow for the launch speed and a faint cone for the spread. Crank the output and the
##   arrow stretches, the cone widens, the bubbles fly faster and further.
## truth: every emitter is a little vector field — each particle leaves with a velocity, and
##   the "force" of a spray is just that launch vector, made of thousands of tiny departures.
##
## DNA: output 0..1 dials the launch — the muzzle vector's length, the spread angle, and how
## far/fast the bubbles travel. seed jitters the bubbles.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var output: float = 0.6
@export var body_color: Color = Color(0.98, 0.55, 0.74)   # the pink gun
@export var trim_color: Color = Color(1.0, 0.95, 0.98)    # white trim
@export var force_color: Color = Color(0.40, 0.86, 1.0)   # the output velocity vector
@export var fluid_color: Color = Color(0.98, 0.62, 0.80)  # soap reservoir

## --- DNA (stage 2, promoted 2026-08-05) ---------------------------------------
## HOW MUCH OF THE ARITHMETIC IS SHOWN. transform_composition_workbench's word with its
## four values in the same order, seconded across this bench by dot_aligner, vector_add,
## vector_sub, projection_shadow, launch_arc and torque_crank. A launch velocity is a
## scalar times a direction, which is the same product those benches take apart, so this
## one takes their word instead of inventing a second vocabulary for it.
##   outcome  the launch vector, the dashed spread cone and the readout leave the render
##            layers. A pink gun and a cone of bubbles, with nothing in frame to say what
##            threw them — the spray as a fact you are given rather than derived.
##   trace    the shipped lineage: one mean arrow down the axis, four dashed cone edges,
##            the readout. Adds nothing; this is the fall-through arm.
##   operands the assertion replaced by its ingredients. The single averaged arrow and the
##            dashed envelope go dark and the departures are drawn one by one — a bundle
##            of vectors sharing the nozzle as their tail, plus the half-angle swept as an
##            arc against the axis. "Every emitter is a little vector field" stops being a
##            caption: the one vector is visibly thousands.
##   expression the algebra promoted — a plate above the muzzle writing v_i = v_out · d̂_i
##            with the live numbers substituted.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]

# fire-when-held state
var _bubbles: Array = []          # [{node, mat, ar, radf, phase, size, alpha}]
var _fire_level: float = 0.0      # 0 idle (dim slow drift) -> 1 firing (bright fast stream)
var _fire_target: float = 0.0
var _stream_t: float = 0.0
var _noz: Vector3
var _maxd: float = 1.0
var _spr: float = 0.2


func _ready() -> void:
	super()                                  # pickable.gd._ready — grabbable
	freeze = true
	_ensure_collision(Vector3(1.2, 0.7, 0.4))
	_build()
	# picking it up starts the spray; dropping it stops
	if not grabbed.is_connected(_on_grab): grabbed.connect(_on_grab)
	if not dropped.is_connected(_on_drop): dropped.connect(_on_drop)


func _on_grab(_p: Variant, _by: Variant) -> void:
	_fire_target = 1.0

func _on_drop(_p: Variant) -> void:
	_fire_target = 0.0


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("output"): output = clampf(float(config_data["output"]), 0.0, 1.0)
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	# An unknown word is ignored rather than assigned, so a typo falls back to the
	# shipped picture instead of blanking the launch vector.
	if config_data.has("workings"):
		var _w: String = String(config_data["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
	body_color = _parse_color(config_data.get("body_color", body_color), body_color)
	force_color = _parse_color(config_data.get("force_color", force_color), force_color)
	_build()


func _build() -> void:
	# clear only the Visual child — never the CollisionShape the grab needs
	var old := get_node_or_null("Visual")
	if old: old.queue_free()
	var rig := Node3D.new()
	rig.name = "Visual"
	add_child(rig)
	_rng.seed = hash(seed)

	var v_out: float = lerpf(0.85, 2.0, output)
	var spread: float = lerpf(deg_to_rad(7.0), deg_to_rad(28.0), output)
	var pink := _matte_mat(body_color, 0.5)
	var white := _matte_mat(trim_color, 0.4)

	# --- the gun (points +X) ----------------------------------------------------
	rig.add_child(_box(Vector3(0.0, 0.55, 0.0), Vector3(0.58, 0.20, 0.16), pink))          # barrel body
	rig.add_child(_box(Vector3(0.22, 0.60, 0.0), Vector3(0.18, 0.12, 0.14), pink))          # top rib
	var nozzle := Vector3(0.32, 0.55, 0.0)
	var ring := _torus(nozzle, 0.10, 0.03, white); ring.rotation.z = PI * 0.5
	rig.add_child(ring)                                                                     # muzzle ring
	# trigger handle — a proper pistol grip: hangs down and angles back toward the shooter
	var grip := _box(Vector3(-0.16, 0.32, 0.0), Vector3(0.15, 0.38, 0.13), pink)
	grip.rotation.z = deg_to_rad(-24.0)
	rig.add_child(grip)
	rig.add_child(_box(Vector3(-0.20, 0.16, 0.0), Vector3(0.17, 0.07, 0.12), _matte_mat(body_color.darkened(0.1), 0.5)))  # grip base
	rig.add_child(_box(Vector3(-0.05, 0.46, 0.0), Vector3(0.05, 0.11, 0.06), white))               # trigger
	# soap reservoir under the barrel (translucent, with fluid)
	var tank := _cylinder(Vector3(0.04, 0.33, 0.0), 0.11, 0.26, _glass_mat(Color(0.95, 0.97, 1.0), 0.22))
	tank.rotation.x = PI * 0.5
	rig.add_child(tank)
	var fluid := _cylinder(Vector3(0.04, 0.30, 0.0), 0.10, 0.13, _glass_mat(fluid_color, 0.45))
	fluid.rotation.x = PI * 0.5
	rig.add_child(fluid)
	# the bubble window (round, with foam) on the barrel side
	rig.add_child(_sphere(Vector3(-0.05, 0.55, 0.085), 0.07, _glass_mat(Color(0.9, 0.95, 1.0), 0.3)))

	# --- the bubble stream — a pool _process animates (drifts idle, streams when held) ---
	_bubbles.clear()
	_noz = nozzle
	_maxd = 0.9 * (0.7 + v_out * 0.6)
	_spr = spread
	var stream := Node3D.new(); stream.name = "Stream"; rig.add_child(stream)
	var count: int = int(lerpf(11.0, 26.0, output))
	for i in range(count):
		var hue: float = fposmod(0.55 + float(i) * 0.07, 1.0)
		var mat := _glass_mat(Color.from_hsv(hue, 0.35, 1.0), 0.4)
		var node := _sphere(Vector3.ZERO, 1.0, mat)   # unit sphere, scaled per-frame
		stream.add_child(node)
		_bubbles.append({"node": node, "mat": mat, "ar": _rng.randf_range(0.0, TAU),
			"radf": _rng.randf_range(0.25, 1.0), "phase": float(i) / float(count),
			"size": _rng.randf_range(0.020, 0.055)})
	_place_bubbles()

	# --- the output velocity vector + spread cone -------------------------------
	var v_arrow: Node3D = _arrow(nozzle, nozzle + Vector3(v_out, 0.0, 0.0), 0.028, _glow_mat(force_color, 1.8))
	rig.add_child(v_arrow)
	# The four dashed edges under one identity Node3D so WORKINGS can reach the whole
	# envelope in a single call; _subtree_aabb recurses into Node3D children and does
	# NOT apply their transform, and this holder is never moved, so the settled box
	# below is bit-identical to the one that ships.
	var cone := Node3D.new()
	cone.name = "SpreadCone"
	rig.add_child(cone)
	var cone_mat := _glow_mat(force_color.lerp(Color.WHITE, 0.3), 0.5)
	for ar2 in [0.0, PI * 0.5, PI, PI * 1.5]:
		var edge: Vector3 = nozzle + Vector3(v_out * 0.8, sin(ar2) * tan(spread) * v_out * 0.8, cos(ar2) * tan(spread) * v_out * 0.8)
		cone.add_child(_dashed(nozzle, edge, 0.006, cone_mat))

	# --- readout ----------------------------------------------------------------
	var readout: Label3D = _billboard_label(
		"v_out = %.2f\nspread = %d°\nbubbles = %d" % [v_out, int(roundf(rad_to_deg(spread))), count],
		nozzle + Vector3(0.3, 0.5, 0.0), 28, force_color.lerp(Color.WHITE, 0.3))
	rig.add_child(readout)

	_settle(rig, 1.9)

	# WORKINGS dressing, appended AFTER _settle so the legacy geometry keeps the exact
	# fit and placement it has today — nothing above this line moved. "trace" falls
	# through and adds nothing at all.
	match _workings_value():
		"outcome":
			_workings_outcome(v_arrow, cone, readout)
		"operands":
			_workings_operands(rig, nozzle, v_out, spread, v_arrow, cone)
		"expression":
			_workings_expression(rig, nozzle, v_out, spread)
		_:
			pass                                 # "trace" — the shipped lineage


# --- WORKINGS ---------------------------------------------------------------
# One axis, four values, shared word for word with the rest of the vector subject.
# Removal is always `layers = 0` on the VisualInstance3D leaves — never
# `visible = false`, which in Godot takes a holder's whole subtree with it.

func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "trace"


func _unlayer(n: Node) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = 0
	for child in n.get_children():
		_unlayer(child)


## OUTCOME — the spray with no account of itself. The launch arrow, the dashed envelope
## and the readout leave the render layers, and what is left is a gun and a cone of soap.
## This artifact exists because it wears its launch vector on the side; outcome is the
## picture of it not doing that, which is what every other bubble machine looks like.
func _workings_outcome(v_arrow: Node3D, cone: Node3D, readout: Label3D) -> void:
	_unlayer(v_arrow)
	_unlayer(cone)
	if readout != null:
		_unlayer(readout)


## OPERANDS — the ingredients, from the tail they share. The shipped picture makes one
## claim (a mean arrow) and sketches its limit (four dashed edges); here that claim goes
## dark and the departures are drawn instead: thirteen velocity arrows leaving the nozzle
## along a deterministic golden-angle spiral through the cone, each the same LENGTH — the
## speed is the scalar, the spread is the direction — plus the half-angle swept as an arc
## between the axis and the cone edge, and the axis itself as a thin ray. No RNG is
## touched, so the bundle is the same bundle in every frame.
func _workings_operands(rig: Node3D, nozzle: Vector3, v_out: float, spread: float,
		v_arrow: Node3D, cone: Node3D) -> void:
	_unlayer(v_arrow)
	_unlayer(cone)

	var n: int = 13
	var mat := _glow_mat(force_color, 1.5)
	var reach: float = v_out * 0.62
	for i in range(n):
		# golden-angle spiral over the disc of the cone: even coverage, no randomness
		var t: float = (float(i) + 0.5) / float(n)
		var off: float = tan(spread) * sqrt(t)
		var ang: float = float(i) * 2.399963
		var dir: Vector3 = Vector3(1.0, sin(ang) * off, cos(ang) * off).normalized()
		rig.add_child(_arrow(nozzle, nozzle + dir * reach, 0.014, mat))

	# the axis as a thin ray, and the half-angle measured against it
	var axis_mat := _glow_mat(force_color.lerp(Color.WHITE, 0.45), 1.2)
	rig.add_child(_cylinder_between(nozzle, nozzle + Vector3(v_out * 0.9, 0.0, 0.0), 0.006, axis_mat))
	var edge_dir: Vector3 = Vector3(1.0, tan(spread), 0.0).normalized()
	var arc := Node3D.new()
	arc.name = "SpreadArc"
	rig.add_child(arc)
	var steps: int = 9
	for i in range(steps + 1):
		var f: float = float(i) / float(steps)
		var d: Vector3 = Vector3.RIGHT.slerp(edge_dir, f).normalized()
		arc.add_child(_sphere(nozzle + d * (v_out * 0.55), 0.013, axis_mat))


## EXPRESSION — the algebra promoted over the geometry. A plate above the muzzle writes
## the launch out as a scalar times a direction, with the live numbers substituted, held
## between two emissive rules so the writing owns hot pixels of its own.
func _workings_expression(rig: Node3D, nozzle: Vector3, v_out: float, spread: float) -> void:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = nozzle + Vector3(0.28, 0.90, 0.0)
	rig.add_child(board)
	board.add_child(_box(Vector3.ZERO, Vector3(1.90, 0.52, 0.03), _matte_mat(Color(0.90, 0.88, 0.84), 0.6)))
	board.add_child(_box(Vector3(0.0, 0.26, 0.02), Vector3(1.90, 0.030, 0.02), _glow_mat(force_color, 1.9)))
	board.add_child(_box(Vector3(0.0, -0.26, 0.02), Vector3(1.90, 0.030, 0.02), _glow_mat(force_color, 1.9)))
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "v_i  =  v_out · d̂_i\n%.2f m/s  within  ±%d°" % [v_out, int(roundf(rad_to_deg(spread)))]
	l.font_size = 40
	l.pixel_size = 0.0036
	l.modulate = Color(0.10, 0.10, 0.12)
	l.outline_size = 6
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.03)
	board.add_child(l)


# --- the spray: each bubble flies the nozzle→cone path, recycling -------------
func _place_bubbles() -> void:
	for bdata in _bubbles:
		_place_one(bdata, float(bdata["phase"]))


func _place_one(bdata: Dictionary, ph: float) -> void:
	var dist: float = lerpf(0.05, _maxd, ph)
	var rad: float = tan(_spr) * dist * float(bdata["radf"])
	var ar: float = float(bdata["ar"])
	var node: Node3D = bdata["node"]
	node.position = _noz + Vector3(dist, sin(ar) * rad, cos(ar) * rad)
	node.scale = Vector3.ONE * (float(bdata["size"]) * (0.5 + 0.5 * sin(ph * PI)))   # born, swell, pop
	var mat: StandardMaterial3D = bdata["mat"]
	mat.emission_energy_multiplier = (0.3 + 1.2 * _fire_level) if emissive else 0.0   # glows when firing


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _bubbles.is_empty():
		return
	_fire_level = lerpf(_fire_level, _fire_target, clampf(delta * 4.0, 0.0, 1.0))
	_stream_t += delta * lerpf(0.10, 0.9, _fire_level)        # idle drift → fast stream when held
	for bdata in _bubbles:
		_place_one(bdata, fposmod(float(bdata["phase"]) + _stream_t, 1.0))
