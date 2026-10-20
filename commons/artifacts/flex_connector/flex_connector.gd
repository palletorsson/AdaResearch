# FlexConnector.gd — two rigid poles, one soft link, and the question of whether it fits
#
# @identity
# essence: two static poles enter a bounded region from the walls and stop; a flexible connector joins their ends, and the piece asks whether that link can be made without leaving the region
# desire: learner stops reading a connection as a line on a diagram and meets it as a physical length that has to go somewhere — slack has to be put down inside the boundary or it escapes
# critical_parameter: approach — whether the two poles arrive from different sides of the region or the same side; under it slack decides how much extra connector there is to accommodate
# triggers: none; the curve is resampled and re-tested against the region whenever approach or slack changes
# emerges: the recognition that connecting is not free — the same two endpoints are easy to join from one configuration and impossible from another, with nothing changed but which side things came from
# relationships: the third scale in the separation family after [[markov_blanket_room]] (a shell of cells) and [[bridge_cut]] (a single edge); here the separator is a region and the question is containment
# truth: a connection has a length, and a length has to fit
extends Node3D
class_name FlexConnector

## WHAT THE SOURCE FIGURE SAYS, AND WHAT WAS PHYSICALISED.
##
## The two drawings read "Different sides" and "Same side". A small region D is
## entered by two chains, blue, which stop at points a and b on its boundary; a
## short red arc inside D joins them. The whole content of the pair is that the
## SAME join is a different problem depending on where a and b sit relative to
## each other.
##
## Palle's reading, 2026-10-13: "This is very physical. Can make a connector.
## Blue are static poles, gray are side walls, red is a flex connector."
##
## So: the poles are rigid and anchored in the walls, the connector is soft and
## has a fixed length set by `slack`, and the region is real. The claim the
## piece makes is CONTAINMENT, not connection -- the two ends can always be
## joined by a long enough curve, but a long enough curve may not fit. Every
## sample of the curve is tested against the region and the plate reports
## INSIDE or ESCAPES, with the escaping part drawn in a different colour.
##
## This is the third scale of the same question the other two ask. A Markov
## blanket is a separating shell; a bridge is a separating edge; here the
## separator is the region's own boundary, and what is being separated is a
## length from somewhere to put itself.

const APPROACHES := ["different", "same"]
const SLACKS := {"taut": 1.0, "easy": 1.22, "loose": 1.55, "coiled": 2.1}

@export_enum("different", "same") var approach: String = "different":
	set(v):
		approach = v
		if is_inside_tree():
			_rebuild()

@export_enum("taut", "easy", "loose", "coiled") var slack: String = "easy":
	set(v):
		slack = v
		if is_inside_tree():
			_rebuild()

## Radius of the region the connector must stay inside. The poles stop on it.
@export var region_radius: float = 0.17
@export var pole_radius: float = 0.012
@export var cord_radius: float = 0.007
@export var wall_distance: float = 0.42
@export var show_readout: bool = true

@export var pole_color: Color = Color(0.10, 0.16, 0.72)
@export var wall_color: Color = Color(0.62, 0.62, 0.62)
@export var cord_color: Color = Color(0.82, 0.14, 0.14)
@export var escape_color: Color = Color(1.0, 0.72, 0.10)

const SAMPLES := 48

var _a := Vector3.ZERO
var _b := Vector3.ZERO
var _curve: Array[Vector3] = []
var _outside: int = 0
var _length: float = 0.0
var _built: Node3D


func _ready() -> void:
	_built = Node3D.new()
	_built.name = "Built"
	add_child(_built)
	_rebuild()


# ------------------------------------------------------------ the two cases

func _anchors() -> void:
	var r := region_radius
	if approach == "different":
		# the figure's first case: one chain arrives high on the right, the
		# other low on the left, so a and b sit most of a turn apart
		_a = Vector3(cos(deg_to_rad(28.0)), sin(deg_to_rad(28.0)), 0.0) * r
		_b = Vector3(cos(deg_to_rad(248.0)), sin(deg_to_rad(248.0)), 0.0) * r
	else:
		# the figure's second case: both chains arrive from below, so a and b
		# are close together on the same arc and the join is a short hop
		_a = Vector3(cos(deg_to_rad(242.0)), sin(deg_to_rad(242.0)), 0.0) * r
		_b = Vector3(cos(deg_to_rad(298.0)), sin(deg_to_rad(298.0)), 0.0) * r


## A quadratic curve whose control point is pushed away from the chord until the
## arc is about `slack` times the straight-line distance. Not a catenary: this
## is a connector under no gravity, and what matters is only that extra length
## has to bulge somewhere.
func _solve_curve() -> void:
	var want: float = SLACKS.get(slack, 1.0)
	var chord := _a.distance_to(_b)
	var mid := (_a + _b) * 0.5
	# push AWAY from the region centre, which is where a real cord would go:
	# the short way across is already occupied by the poles meeting
	var outward := mid.normalized() if mid.length() > 1e-5 else Vector3.UP
	var lo := 0.0
	var hi := region_radius * 4.0
	var push := 0.0
	for _i in range(24):                 # bisection on the bulge
		push = (lo + hi) * 0.5
		var l := _measure(mid + outward * push)
		if l < want * chord:
			lo = push
		else:
			hi = push
	_curve = _sample(mid + outward * push)
	_length = _measure(mid + outward * push)
	_outside = 0
	for p in _curve:
		if p.length() > region_radius * 1.001:
			_outside += 1


func _sample(ctrl: Vector3) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for i in range(SAMPLES + 1):
		var t := float(i) / float(SAMPLES)
		var u := 1.0 - t
		pts.append(_a * (u * u) + ctrl * (2.0 * u * t) + _b * (t * t))
	return pts


func _measure(ctrl: Vector3) -> float:
	var l := 0.0
	var prev := _a
	for i in range(1, SAMPLES + 1):
		var t := float(i) / float(SAMPLES)
		var u := 1.0 - t
		var p := _a * (u * u) + ctrl * (2.0 * u * t) + _b * (t * t)
		l += prev.distance_to(p)
		prev = p
	return l


# ----------------------------------------------------------------- the body

func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = emit
	return m


func _rod(a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> void:
	var d := b - a
	if d.length() < 1e-6:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = d.length()
	cyl.radial_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = mat
	var mid := (a + b) * 0.5
	mi.position = mid
	if absf(d.normalized().dot(Vector3.UP)) < 0.999:
		mi.look_at_from_position(mid, mid + d.normalized(), Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	_built.add_child(mi)


func _rebuild() -> void:
	if _built == null:
		return
	for c in _built.get_children():
		c.queue_free()

	_anchors()
	_solve_curve()

	var wm := _mat(wall_color, 0.05)
	var pm := _mat(pole_color, 0.45)
	var cm := _mat(cord_color, 0.8)
	var em := _mat(escape_color, 1.3)

	# the two gray side walls the poles are anchored in
	for s in [-1.0, 1.0]:
		var plate := BoxMesh.new()
		plate.size = Vector3(0.012, region_radius * 3.4, region_radius * 1.6)
		var mi := MeshInstance3D.new()
		mi.mesh = plate
		mi.material_override = wm
		mi.position = Vector3(s * wall_distance, 0, 0)
		_built.add_child(mi)

	# each pole runs from its wall to its anchor point, with one bend, the way
	# the chains in the figure do
	for pair in [[_a, 1.0], [_b, -1.0]]:
		var end: Vector3 = pair[0]
		var s: float = pair[1]
		var wall := Vector3(s * wall_distance, end.y + s * region_radius * 0.9, 0)
		var knee := Vector3(s * region_radius * 1.9, end.y, 0)
		_rod(wall, knee, pole_radius, pm)
		_rod(knee, end, pole_radius, pm)

	# the flexible connector, drawn segment by segment so the part that leaves
	# the region can be coloured differently -- a cord that escapes and is drawn
	# in one colour is a cord you have to measure to catch
	for i in range(_curve.size() - 1):
		var p: Vector3 = _curve[i]
		var q: Vector3 = _curve[i + 1]
		var out: bool = p.length() > region_radius * 1.001 \
			or q.length() > region_radius * 1.001
		_rod(p, q, cord_radius, em if out else cm)

	# the region itself, as a thin ring on the floor of the piece
	var ring := TorusMesh.new()
	ring.inner_radius = region_radius * 0.985
	ring.outer_radius = region_radius * 1.015
	ring.rings = 48
	var rm := MeshInstance3D.new()
	rm.mesh = ring
	rm.material_override = _mat(Color(0.45, 0.45, 0.48), 0.1)
	rm.rotation_degrees = Vector3(90, 0, 0)
	_built.add_child(rm)

	if show_readout:
		var plate3 := Label3D.new()
		plate3.text = _verdict()
		plate3.font_size = 40
		plate3.pixel_size = 0.00042
		plate3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		plate3.modulate = escape_color if _outside > 0 else cord_color
		plate3.position = Vector3(0, region_radius * 2.5, 0)
		_built.add_child(plate3)

	var anchor := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(wall_distance * 2.1, region_radius * 3.6, region_radius * 1.6)
	anchor.mesh = bm
	anchor.layers = 0                      # measured, never drawn
	anchor.name = "ExtentAnchor"
	_built.add_child(anchor)


func _verdict() -> String:
	var ratio := _length / maxf(_a.distance_to(_b), 1e-5)
	if _outside == 0:
		return "FITS INSIDE\ncord %.2fx the chord" % ratio
	return "ESCAPES\n%d of %d samples outside\ncord %.2fx the chord" \
		% [_outside, _curve.size(), ratio]


# ------------------------------------------------------------- the map's hand

func apply_grid_config(config_data: Dictionary) -> void:
	var dirty := false
	if config_data.has("approach"):
		var w := str(config_data["approach"]).to_lower().strip_edges()
		if APPROACHES.has(w):
			approach = w
			dirty = true
	if config_data.has("slack"):
		var s := str(config_data["slack"]).to_lower().strip_edges()
		if SLACKS.has(s):
			slack = s
			dirty = true
	if config_data.has("show_readout"):
		show_readout = bool(config_data["show_readout"])
		dirty = true
	if dirty and is_inside_tree():
		_rebuild()


## Readable by a probe, so the claim is testable without reading pixels.
func fits_inside() -> bool:
	return _outside == 0


func samples_outside() -> int:
	return _outside


func cord_ratio() -> float:
	return _length / maxf(_a.distance_to(_b), 1e-5)
