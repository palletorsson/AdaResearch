extends Node3D
class_name ModulorManDemo

## Le Corbusier's Modulor figure, and the apparatus that decides what it is FOR.
##
## The root of modulor_man_demo.tscn carried no script at all, which meant
## GridInteractablesComponent — which calls apply_grid_config on the ROOT — had nothing to
## call. Every knob in this scene was unreachable from any map token. This script is that
## missing root, and the axis it carries is the one the scene was already arguing silently.

# @identity
# essence: figure = polyline(MODULOR_UNITS) — a body drawn once, then asked what it is a measure OF
# desire: stand in front of the Modulor and see the moment a person becomes a ruler
# critical_parameter: measure — body | scale | canon | module | crowd, the apparatus laid over the figure
# triggers: _ready() reads the axis and appends the apparatus after the figure exists
# emerges: the same 2.26 m outline reads as a person, a dimension, an ideal, a building grid or an exclusion
# needs: the continuous line figure [present, from modulor_man_interactive]; the annotation apparatus [built here]
# relationships: the demo wrapper around [[modulor_man_interactive]]; shares its directory and its line with [[line_builder_3d]], whose axis is slack
# truth: a standard human is not a fact about humans. It is a decision about which ones the building will fit.

# ── DNA ───────────────────────────────────────────────────────────────────────

## AXIS — WHAT THE BODY IS PUT FORWARD AS A MEASURE OF. Not the pose, not the colour, not
## the thickness of the line: the figure is drawn identically at every value, the same
## thirty-four Modulor points, the same grabbable vertices, in the same order. What changes
## is the apparatus around it, and the apparatus is the whole claim — because a raised arm
## at 2.26 m is a gesture until something in the frame says it is a dimension.
##
##   body    the legacy lineage, byte for byte — the continuous line and its grabbable
##           vertices, no annotation of any kind. A drawn person. The height happens to be
##           1.83 m, and nothing in the frame says that number matters.
##   scale   every dimension label in the scene turned on (2.26 Arm Raised, 1.83 Standing,
##           1.13 Navel, and the Blue-series limbs), plus a graduated rule standing beside
##           the figure with a tick at each Red-series height. The body as a set of
##           readings: a person converted to numbers, one limb at a time.
##   canon   the Vitruvian frame — a 1.83 m square standing on the ground around the figure
##           and a circle centred on the navel at 1.13 m, whose radius therefore touches the
##           floor and reaches the raised hand at 2.26 m exactly. The older claim Le
##           Corbusier is arguing with: that the body is already perfect geometry, and
##           proportion is discovered rather than legislated.
##   module  the series drawn as datum lines running clean through and past the figure —
##           Red in red, Blue in blue, Le Corbusier's own colour code — with the Blue-series
##           squares nested off to one side. The body has become a building grid, and the
##           lines no longer stop where the person does. This is the Modulor's actual use.
##   crowd   the standard against the population it claims. Five more figures stand behind
##           in rank at 1.55, 1.68, 1.83, 1.96 and 2.10 m, the same outline scaled, with the
##           1.83 datum drawn straight through them. One of them fits the ruler. The others
##           are what "universal" cost.
##
## STRICTLY ADDITIVE. "body" builds nothing at all and is the default, so all seven existing
## placements render exactly as before — including the ten Label3D nodes that ship
## `visible = false` and stay that way at every value but `scale`. Nothing here touches the
## figure's points, so the grab spheres a player reaches for are in the same places at every
## value: the axis stages the apparatus AROUND the body and stops there.
@export_enum("body", "scale", "canon", "module", "crowd") var measure: String = "body"
const MEASURES: PackedStringArray = ["body", "scale", "canon", "module", "crowd"]

# ── The Modulor's own numbers ─────────────────────────────────────────────────
# Read straight off modulor_man_interactive.gd, which is the figure this wraps. Kept as
# constants rather than reached for through the child, so the apparatus builds even when the
# figure has not finished spawning its points.

const ARM_RAISED := 2.26          # Red 226
const STANDING := 1.83            # Red 183
const SOLAR_PLEXUS := 1.40        # Red 140
const NAVEL := 1.13               # Red 113
const RED_SERIES: PackedFloat32Array = [2.26, 1.83, 1.40, 1.13]
const BLUE_SERIES: PackedFloat32Array = [0.86, 0.70, 0.46, 0.43, 0.27, 0.18]

const RED_INK := Color(0.86, 0.24, 0.18)
const BLUE_INK := Color(0.22, 0.44, 0.88)
const BONE := Color(0.88, 0.86, 0.80)

const HOST := "ModulorMeasure"

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	var _m: String = str(measure).strip_edges().to_lower()
	measure = _m if MEASURES.has(_m) else "body"
	_build_measure()


## Config entry point — the one this root never had. Reads a single key and ignores every
## other, because composers hand this dictionary round wholesale. An unknown word keeps the
## standing value; a dictionary without "measure" does nothing at all.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("measure"):
		return
	var want: String = str(config_data["measure"]).strip_edges().to_lower()
	if not MEASURES.has(want):
		return
	if want == measure and get_node_or_null(HOST) != null:
		return
	measure = want
	_build_measure()


# ── MEASURE ───────────────────────────────────────────────────────────────────
# Everything below lives inside one host node appended AFTER the figure, so deleting the
# host restores the legacy scene exactly. Nothing reads or writes the figure's points.

func _build_measure() -> void:
	var old: Node = get_node_or_null(HOST)
	if old != null:
		remove_child(old)
		old.queue_free()
	_set_labels(measure == "scale")
	if measure == "body" or not MEASURES.has(measure):
		return                          # the legacy lineage builds nothing at all
	var host := Node3D.new()
	host.name = HOST
	add_child(host)
	match measure:
		"scale":
			_measure_scale(host)
		"canon":
			_measure_canon(host)
		"module":
			_measure_module(host)
		"crowd":
			_measure_crowd(host)
		_:
			pass


## The ten dimension labels the scene ships with, authored `visible = false`. They are leaf
## Label3D nodes with no children, so toggling them cannot hide a subtree by accident.
func _set_labels(on: bool) -> void:
	for child in get_children():
		if child is Label3D:
			(child as Label3D).visible = on


## SCALE — the body as a set of readings. A graduated rule stands clear of the figure on the
## right with a tick at every Red-series height, the four canonical ones running long and
## bright; the scene's own dimension labels carry the numbers on the left. Between them the
## person is bracketed by measurement on both sides.
func _measure_scale(host: Node3D) -> void:
	# Clear of the scene's own LimbLabel column, which sits at x = 0.6 to 0.75 and would
	# otherwise have the return bars drawing through the middle of the words.
	var rule_x: float = 1.15
	var mat: StandardMaterial3D = _mat(BONE, 0.55, 0.10)
	var lit: StandardMaterial3D = _lit(RED_INK, 1.6)
	# The stile: one clean vertical from the floor to the raised hand.
	_box(host, Vector3(rule_x, ARM_RAISED * 0.5, 0.0), Vector3(0.022, ARM_RAISED, 0.022), mat)
	# Minor graduations every 10 cm — the rule reads as an instrument, not a post.
	for i in range(1, 23):
		var y: float = float(i) * 0.1
		_box(host, Vector3(rule_x + 0.035, y, 0.0), Vector3(0.052, 0.006, 0.010), mat)
	# Major ticks at the Red series, standing proud and lit.
	for r in RED_SERIES:
		var h: float = float(r)
		_box(host, Vector3(rule_x + 0.075, h, 0.0), Vector3(0.140, 0.014, 0.014), lit)
		# a short return toward the figure, set back in Z so it passes BEHIND the labels
		# rather than z-fighting with them
		_box(host, Vector3(rule_x - 0.30, h, -0.10), Vector3(0.420, 0.007, 0.007), mat)
	# The foot, so the rule reads as standing on the same ground as the person.
	_box(host, Vector3(rule_x, 0.008, 0.0), Vector3(0.26, 0.016, 0.16), mat)


## CANON — the Vitruvian frame. The square is the standing height, 1.83 m on a side, sitting
## on the ground. The circle is centred on the navel at 1.13 m with a radius of 1.13, which
## puts its bottom on the floor and its top at 2.26 — the raised hand. That coincidence is
## the whole of the pre-modern argument, and it is drawn here rather than asserted.
func _measure_canon(host: Node3D) -> void:
	var ink: StandardMaterial3D = _lit(RED_INK, 1.1)
	var half: float = STANDING * 0.5
	var t: float = 0.018
	# the square
	_box(host, Vector3(0.0, 0.0, 0.0), Vector3(STANDING + t, t, t), ink)
	_box(host, Vector3(0.0, STANDING, 0.0), Vector3(STANDING + t, t, t), ink)
	_box(host, Vector3(-half, STANDING * 0.5, 0.0), Vector3(t, STANDING, t), ink)
	_box(host, Vector3(half, STANDING * 0.5, 0.0), Vector3(t, STANDING, t), ink)
	# the circle, standing in the figure's own plane
	var ring := TorusMesh.new()
	ring.inner_radius = NAVEL - 0.010
	ring.outer_radius = NAVEL + 0.010
	ring.rings = 48
	ring.ring_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = ring
	mi.material_override = _lit(BONE, 0.7)
	mi.position = Vector3(0.0, NAVEL, 0.0)
	mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	host.add_child(mi)
	# the navel itself, marked — the centre the whole construction turns on
	_box(host, Vector3(0.0, NAVEL, 0.06), Vector3(0.05, 0.05, 0.05), ink)


## MODULE — the series as datum lines, running clean through the figure and out past it in
## both directions, in Le Corbusier's own two colours. Off to the right the Blue series is
## drawn as nested squares sharing a corner: the module the body authorises, waiting to be
## a window, a door, a ceiling. The lines no longer stop where the person does.
func _measure_module(host: Node3D) -> void:
	var red: StandardMaterial3D = _lit(RED_INK, 1.15)
	var blue: StandardMaterial3D = _lit(BLUE_INK, 1.15)
	var span: float = 3.2
	for r in RED_SERIES:
		var y: float = float(r)
		_box(host, Vector3(0.0, y, -0.02), Vector3(span, 0.016, 0.016), red)
	for b in BLUE_SERIES:
		var y2: float = float(b)
		_box(host, Vector3(0.0, y2, -0.02), Vector3(span * 0.82, 0.011, 0.011), blue)
	# The nested Blue squares, sharing their bottom-left corner on the floor at the right.
	var ox: float = 1.02
	var t: float = 0.012
	for b2 in BLUE_SERIES:
		var s: float = float(b2)
		_box(host, Vector3(ox + s * 0.5, 0.0, 0.10), Vector3(s, t, t), blue)
		_box(host, Vector3(ox + s * 0.5, s, 0.10), Vector3(s, t, t), blue)
		_box(host, Vector3(ox, s * 0.5, 0.10), Vector3(t, s, t), blue)
		_box(host, Vector3(ox + s, s * 0.5, 0.10), Vector3(t, s, t), blue)
	# The 1.83 datum given a head — the one line the whole grid is measured from.
	_box(host, Vector3(-span * 0.5, STANDING, -0.02), Vector3(0.05, 0.09, 0.05), red)
	_box(host, Vector3(span * 0.5, STANDING, -0.02), Vector3(0.05, 0.09, 0.05), red)


## CROWD — the standard against the population it claims to describe. Four more outlines of
## the same figure stand in a rank to the right, scaled to 1.55, 1.68, 1.96 and 2.10 m, with
## the 1.83 datum run in red from the hero straight through the lot. Two heads clear the
## line and two fall short of it, and the one body that meets it exactly is the one already
## standing there — which is the argument.
##
## They stand BESIDE the figure rather than behind it. A rank of five centred on the hero
## puts its middle member directly behind him at x = 0, and the camera (yaw 0.62, pitch
## -0.26) would have hidden the one that mattered behind the body it was being compared to.
##
## Nothing is randomised: the heights are a written list and the outline is the same
## arithmetic the figure itself runs, so every boot draws the same five people.
func _measure_crowd(host: Node3D) -> void:
	var heights: PackedFloat32Array = [1.55, 1.68, 1.96, 2.10]
	var step: float = 0.74
	var x0: float = 1.02
	for i in range(heights.size()):
		var s: float = float(heights[i]) / STANDING
		var body := MeshInstance3D.new()
		body.mesh = _polyline_mesh(_figure_points(), 0.013)
		body.material_override = _lit(Color(0.46, 0.47, 0.52), 0.42)
		body.position = Vector3(x0 + float(i) * step, 0.0, 0.0)
		body.scale = Vector3(s, s, s)
		host.add_child(body)
		# A short foot mark under each, so the rank reads as people standing on one floor
		# rather than drawings floating at different sizes.
		_box(host, Vector3(x0 + float(i) * step, 0.006, 0.0), Vector3(0.42, 0.012, 0.20),
			_mat(BONE, 0.8, 0.05))
	var x_left: float = -0.62
	var x_right: float = x0 + float(heights.size() - 1) * step + 0.52
	# The datum they are all measured against, run out past both ends of the rank.
	_box(host, Vector3((x_left + x_right) * 0.5, STANDING, 0.0),
		Vector3(x_right - x_left, 0.018, 0.018), _lit(RED_INK, 1.3))
	# A stop at each end, so the line reads as a dimension and not as a shelf.
	for ex in [x_left, x_right]:
		_box(host, Vector3(float(ex), STANDING, 0.0), Vector3(0.05, 0.11, 0.05),
			_lit(RED_INK, 1.3))


# ── Figure geometry (for `crowd` only) ────────────────────────────────────────
# The same arithmetic modulor_man_interactive.gd runs on the same constants. It is repeated
# rather than reached for because the child builds its outline from spawned grab spheres,
# and a rank of five extra figures must not be five more sets of pickables.

func _figure_points() -> PackedVector3Array:
	var p := PackedVector3Array()
	var foot: float = 0.27
	var lower_leg: float = 0.43
	var shoulder: float = 0.46 / 2.0
	var hip: float = 0.18
	var forearm: float = 0.43
	var upper_arm: float = 0.27
	var hand: float = 0.18
	var shoulder_y: float = STANDING - 0.22
	var knee_y: float = lower_leg
	p.append(Vector3(-hip, 0.0, 0.0))
	p.append(Vector3(-hip - foot * 0.7, 0.0, foot * 0.5))
	p.append(Vector3(-hip, 0.0, 0.0))
	p.append(Vector3(-hip, knee_y, 0.0))
	p.append(Vector3(-hip, NAVEL, 0.0))
	p.append(Vector3(0.0, NAVEL, 0.0))
	p.append(Vector3(0.0, SOLAR_PLEXUS, 0.0))
	p.append(Vector3(shoulder, shoulder_y, 0.0))
	var right_elbow_y: float = shoulder_y - upper_arm
	p.append(Vector3(shoulder + 0.15, right_elbow_y, 0.0))
	var right_hand_y: float = right_elbow_y - forearm
	p.append(Vector3(shoulder + 0.25, right_hand_y, 0.0))
	p.append(Vector3(shoulder + 0.3, right_hand_y - hand, 0.0))
	p.append(Vector3(shoulder + 0.25, right_hand_y, 0.0))
	p.append(Vector3(shoulder + 0.15, right_elbow_y, 0.0))
	p.append(Vector3(shoulder, shoulder_y, 0.0))
	p.append(Vector3(-shoulder, shoulder_y, 0.0))
	var left_elbow_y: float = shoulder_y + upper_arm * 0.8
	p.append(Vector3(-shoulder - 0.15, left_elbow_y, 0.0))
	p.append(Vector3(-shoulder - 0.05, ARM_RAISED, 0.0))
	p.append(Vector3(-shoulder, ARM_RAISED + hand * 0.5, 0.0))
	p.append(Vector3(-shoulder - 0.05, ARM_RAISED, 0.0))
	p.append(Vector3(-shoulder - 0.15, left_elbow_y, 0.0))
	p.append(Vector3(-shoulder, shoulder_y, 0.0))
	var neck_top: float = shoulder_y + 0.08
	p.append(Vector3(0.0, neck_top, 0.0))
	var head_radius: float = (STANDING - neck_top) * 0.5
	var head_center_y: float = neck_top + head_radius
	for angle in range(0, 360, 45):
		var rad: float = deg_to_rad(float(angle))
		p.append(Vector3(sin(rad) * head_radius, head_center_y + cos(rad) * head_radius, 0.0))
	p.append(Vector3(0.0, neck_top, 0.0))
	p.append(Vector3(0.0, SOLAR_PLEXUS, 0.0))
	p.append(Vector3(hip, NAVEL, 0.0))
	p.append(Vector3(hip, knee_y, 0.0))
	p.append(Vector3(hip, 0.0, 0.0))
	p.append(Vector3(hip + foot * 0.7, 0.0, foot * 0.5))
	p.append(Vector3(hip, 0.0, 0.0))
	return p


## A tube swept along a polyline — the same construction modulor_man.gd uses for the hero
## figure, so the rank reads as the same drawing at other sizes.
func _polyline_mesh(pts: PackedVector3Array, thickness: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides: int = 6
	for i in range(pts.size() - 1):
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		if p1.distance_to(p2) < 0.0001:
			continue
		var dir: Vector3 = (p2 - p1).normalized()
		var up: Vector3 = Vector3.UP
		if absf(dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right: Vector3 = dir.cross(up).normalized()
		var fwd: Vector3 = right.cross(dir).normalized()
		for side in range(sides):
			var a1: float = (float(side) / float(sides)) * TAU
			var a2: float = (float(side + 1) / float(sides)) * TAU
			var o1: Vector3 = (right * cos(a1) + fwd * sin(a1)) * thickness
			var o2: Vector3 = (right * cos(a2) + fwd * sin(a2)) * thickness
			st.add_vertex(p1 + o1)
			st.add_vertex(p2 + o1)
			st.add_vertex(p2 + o2)
			st.add_vertex(p1 + o1)
			st.add_vertex(p2 + o2)
			st.add_vertex(p1 + o2)
	st.generate_normals()
	return st.commit()


# ── helpers ───────────────────────────────────────────────────────────────────

func _box(host: Node3D, centre: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = centre
	host.add_child(mi)


func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _lit(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
