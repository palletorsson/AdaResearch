extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ImpossibleTrident

## @identity
## name: Impossible Trident
## lineage: the blivet / "devil's fork" / poiuyt — an impossible object first
##   widely printed in 1964. Two round prongs at the base resolve into three
##   rectangular prongs at the top with no consistent junction between them.
## essence: a U-channel diagram standing on the floor. Read the BASE and you count
##   TWO round prongs; read the TOP and you count THREE flat prongs. The middle is
##   drawn so each end is locally correct — and globally cannot exist. A faint amber
##   highlight crawls along the contradictory edge so the impossibility keeps reading.
## truth: two prongs become three; the drawing is consistent locally and impossible
##   globally — every junction is fine on its own, no assembly of them is.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent_amber: Color = Color(1.0, 0.70, 0.22)
@export var spin_period: float = 14.0
@export var trace_period: float = 3.2

var _body: Node3D
var _trace_root: Node3D
var _t: float = 0.0

# Geometry of the figure (local to _body, which is lifted onto the floor).
const SPAN: float = 0.62          # half-width of the channel
const Y_TOP: float = 0.46         # top of the prongs
const Y_BOT: float = -0.46        # bottom (base plate sits here)
const PRONG_LEN: float = 0.40     # how far the prongs stick out toward viewer


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# --- chalk ring on the floor (no bench) ---
	var ring_mat := _glow_mat(wire_purple, 0.5)
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.58, 0.012, ring_mat))

	# the whole figure rides on a slowly rotating body, lifted so the base
	# plate sits near the floor and the prongs reach ~1.1m.
	_body = Node3D.new()
	_body.position = Vector3(0.0, 0.62, 0.0)
	add_child(_body)

	var steel := _steel_mat(Color(0.78, 0.82, 0.90))
	var wire := _glow_mat(wire_purple, 0.8)
	var white := _matte_mat(cool_white, 0.55)

	# === THE THREE TOP PRONGS (rectangular) ===
	# Three flat tines across the span. They are unambiguous at the top.
	var xs: Array[float] = [-SPAN, 0.0, SPAN]
	for i in range(3):
		var x: float = xs[i]
		# a flat rectangular prong extending toward the viewer (+z)
		_body.add_child(_box(Vector3(x, Y_TOP - 0.02, PRONG_LEN * 0.5), Vector3(0.10, 0.05, PRONG_LEN), white))
		# crisp top edge wire so it reads as a drawn rectangle
		_body.add_child(_box(Vector3(x, Y_TOP + 0.012, PRONG_LEN * 0.5), Vector3(0.11, 0.008, PRONG_LEN), wire))
		# rounded tip cap (small, keeps the "three flat tines" silhouette)
		_body.add_child(_box(Vector3(x, Y_TOP - 0.02, PRONG_LEN + 0.01), Vector3(0.10, 0.05, 0.02), wire))

	# === THE TWO BASE PRONGS (round) ===
	# Only two round cylinders at the base — the channel between the outer two
	# tines is "solid", so the middle tine has nowhere to be born from.
	var base_xs: Array[float] = [-SPAN * 0.5, SPAN * 0.5]
	for j in range(2):
		var bx: float = base_xs[j]
		_body.add_child(_cylinder_between(
			Vector3(bx, Y_BOT + 0.05, 0.0),
			Vector3(bx, Y_BOT + 0.05, PRONG_LEN),
			0.055, steel))
		# rounded cap so they read as round rods
		_body.add_child(_sphere(Vector3(bx, Y_BOT + 0.05, PRONG_LEN), 0.055, steel))

	# === THE BASE PLATE / SHANK ===
	# The flat back wall that the round prongs leave and the flat prongs arrive at.
	# This is the surface where the count silently changes from 2 to 3.
	_body.add_child(_box(Vector3(0.0, (Y_TOP + Y_BOT) * 0.5, -0.02), Vector3(SPAN * 2.0 + 0.12, Y_TOP - Y_BOT, 0.04), white))
	# its drawn outline
	_body.add_child(_box(Vector3(0.0, Y_TOP, -0.02), Vector3(SPAN * 2.0 + 0.14, 0.008, 0.05), wire))
	_body.add_child(_box(Vector3(0.0, Y_BOT, -0.02), Vector3(SPAN * 2.0 + 0.14, 0.008, 0.05), wire))

	# The contradictory connecting walls: each base rod's far edge becomes the
	# GAP between top tines, and vice-versa. We draw both interpretations as thin
	# bridging walls so the eye keeps trying (and failing) to assemble them.
	# bridge A: left base rod -> spans to where there are TWO gaps above it
	_body.add_child(_box(Vector3(-SPAN * 0.5, 0.0, PRONG_LEN * 0.5), Vector3(0.008, Y_TOP - Y_BOT, PRONG_LEN), wire))
	_body.add_child(_box(Vector3(SPAN * 0.5, 0.0, PRONG_LEN * 0.5), Vector3(0.008, Y_TOP - Y_BOT, PRONG_LEN), wire))
	# bridge B: the central top tine's underside wall — it descends INTO the solid
	# channel between the two round rods (the impossible part).
	_body.add_child(_box(Vector3(0.0, 0.0, PRONG_LEN * 0.5), Vector3(0.06, Y_TOP - Y_BOT, 0.008), wire))

	# --- the crawling amber highlight along the contradictory edge ---
	_trace_root = Node3D.new()
	_body.add_child(_trace_root)

	# --- labels ---
	add_child(_billboard_label("IMPOSSIBLE TRIDENT", Vector3(0.0, 1.5, 0.0), 32, cool_white))
	add_child(_billboard_label("count the base: 2   count the top: 3", Vector3(0.0, 1.36, 0.0), 16, accent_amber))
	# small standing tallies near each end of the figure
	add_child(_billboard_label("2", Vector3(0.0, 0.20, 0.0), 30, accent_amber))
	add_child(_billboard_label("3", Vector3(0.0, 1.18, 0.0), 30, accent_amber))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# slow rotation so the impossibility reads from changing angles
	if is_instance_valid(_body):
		_body.rotation.y = (_t / spin_period) * TAU
		# gentle nod so the depth ambiguity flickers
		_body.rotation.x = sin(_t * 0.6) * 0.07

	# the amber highlight crawls along the seam between "2 round" and "3 flat"
	if is_instance_valid(_trace_root):
		for c in _trace_root.get_children():
			_trace_root.remove_child(c)
			c.queue_free()
		var phase: float = fmod(_t, trace_period) / trace_period
		# the seam runs across the base plate in +z then sweeps along the span
		var sweep_x: float = lerp(-SPAN, SPAN, phase)
		var glow: float = 1.6 + 0.8 * sin(_t * 5.0)
		var trace_mat := _glow_mat(accent_amber, glow)
		# a short bright segment riding the contradictory vertical edge
		_trace_root.add_child(_box(
			Vector3(sweep_x, 0.0, PRONG_LEN * 0.5),
			Vector3(0.018, (Y_TOP - Y_BOT) * 0.9, 0.018),
			trace_mat))
		# a bright dot tracing the top rim back-and-forth, marking the tine it haunts
		var dot_x: float = lerp(-SPAN, SPAN, absf(phase * 2.0 - 1.0))
		_trace_root.add_child(_sphere(Vector3(dot_x, Y_TOP + 0.02, PRONG_LEN * 0.5), 0.03, trace_mat))
