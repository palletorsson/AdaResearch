# ===========================================================================
# NOC Example 1.3: Exercise 1.3: 3D Bouncing Ball
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing -> GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================
#
# @identity
# essence: p += v; v += g; if(wall) v *= -e. Position accumulates velocity, velocity accumulates gravity, walls reverse and damp.
# desire: To trap motion in a box and watch it slowly die — each bounce lower than the last, energy leaking into the walls.
# critical_parameter: _elasticity (0.9) — the fraction of speed kept per bounce. At 1.0 the ball bounces forever; below 1.0 it decays exponentially.
# triggers: Automatic — ball launches with initial velocity, gravity pulls down every frame, boundary collision reverses and damps per-axis
# emerges: The parabolic arc between bounces. The trail drawing the ball’s history as a fading line. The slow settling as elasticity drains energy.
# needs: Auto-running simulation [has], trail visualization [has]. Missing: VR grab to relaunch, elasticity slider, gravity toggle.
# relationships: Simplest dynamics artifact in forces. Foundation for exercise_1_8 (adds attraction). Contrasts with momentum_collision (two bodies vs one).
# truth: A bouncing ball is a clock that runs down. Each bounce measures how much the universe forgot.

class_name BouncingBall3DVR
extends Node3D

const MAT_TRAIL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var ball_radius: float = 0.06
@export var elasticity: float = 0.9
@export var gravity_strength: float = 0.015
@export var box_size: float = 0.9
@export_color_no_alpha var ball_color: Color = Color(1.0, 0.4, 0.7)
@export_color_no_alpha var box_color: Color = Color(0.4, 0.7, 1.0, 0.5)

# ═══════════════════════════════════════════════════════════════════════════
# DNA
#
#   evidence   what the demo puts on the table as proof that a rule is moving
#              the ball. The shipped build already draws the last 150 positions
#              as a fading line, so unlike its Motion 101 neighbours this artifact
#              is BORN at `trace` and `result` is the value that takes something
#              away — the ball and the box and nothing of where it has been.
#              This is the same past-tense trace three_body_problem ships at, not
#              example_1_7's integrated future: a history, not a prediction.
#              longhand puts the working beside the answer — g and v as arrows at
#              the release state, the reflection drawn as a pair of speed arrows
#              whose LENGTH RATIO is e, and the apex ladder h(n) = h0 e^(2n)
#              computed at build time from e alone. axiom drops the history for
#              the rule: a slate on the inside of the back wall carrying the three
#              lines of the update and the one line they amount to.
#
#   regime     which restitution regime the box is in — the @identity's own
#              critical_parameter, which until now was a float nobody could reach
#              and nothing anywhere DREW. stock leaves the export exactly where it
#              was placed; the other three are the textbook cases.
#
# The two are orthogonal in the code and NOT in the photograph, which is worth
# stating rather than discovering in a bite report. At evidence = result there is
# no history on screen and a still catches one arbitrary instant of one ball, so
# regime x result is close to inert and honestly so. It bites everywhere else: at
# trace the trail IS the decay, and at longhand the ladder is drawn from e
# directly — elastic is seven rungs at one height, dead is seven rungs on the floor.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "trace"
@export_enum("stock", "elastic", "dead", "inelastic") var regime: String = "stock"

## Allow-lists. An unknown word in a map token keeps the shipped build rather than
## stranding a placement with a blank exhibit or a frozen ball.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]
const REGIMES: PackedStringArray = ["stock", "elastic", "dead", "inelastic"]

## Nodes built by longhand / axiom. Freed before any rebuild; never constructed on
## the shipped path.
var _evidence_parts: Array[Node3D] = []
## The elasticity this placement was shipped or authored with, so `stock` can put it
## back after a map has asked for another regime.
var _stock_elasticity: float = -1.0

var _sim_root: Node3D
var _ball: MeshInstance3D
var _position: Vector3 = Vector3(0, 0.5, 0)
var _velocity: Vector3 = Vector3(0.12, 0.08, 0.1)
var _gravity: Vector3
var _bounds_min: Vector3
var _bounds_max: Vector3
var _trail_points: Array[Vector3] = []
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _max_trail_length: int = 150

func _ready() -> void:
	_read_grid_config_meta()
	_stock_elasticity = elasticity
	_apply_regime()
	var half := box_size / 2.0
	_bounds_min = Vector3(-half, 0.05, -half)
	_bounds_max = Vector3(half, box_size + 0.05, half)
	_gravity = Vector3(0, -gravity_strength, 0)
	_setup_environment()
	_spawn_ball()
	_create_wireframe_box()
	_setup_trail()
	_apply_evidence()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

func _spawn_ball() -> void:
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0
	_ball.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ball_color
	mat.emission_enabled = true
	mat.emission = ball_color * 0.5
	mat.emission_energy_multiplier = 1.5
	mat.metallic = 0.3
	mat.roughness = 0.4
	_ball.material_override = mat
	_sim_root.add_child(_ball)

func _create_wireframe_box() -> void:
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(box_color, 0.5)
	edge_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	edge_mat.emission_enabled = true
	edge_mat.emission = box_color
	edge_mat.emission_energy_multiplier = 0.6
	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var corners: Array[Vector3] = [
		_bounds_min,
		Vector3(_bounds_max.x, _bounds_min.y, _bounds_min.z),
		Vector3(_bounds_max.x, _bounds_min.y, _bounds_max.z),
		Vector3(_bounds_min.x, _bounds_min.y, _bounds_max.z),
		Vector3(_bounds_min.x, _bounds_max.y, _bounds_min.z),
		Vector3(_bounds_max.x, _bounds_max.y, _bounds_min.z),
		_bounds_max,
		Vector3(_bounds_min.x, _bounds_max.y, _bounds_max.z),
	]
	var edges := [
		[0,1],[1,2],[2,3],[3,0],
		[4,5],[5,6],[6,7],[7,4],
		[0,4],[1,5],[2,6],[3,7],
	]
	for i in range(edges.size()):
		var a: Vector3 = corners[edges[i][0]]
		var b: Vector3 = corners[edges[i][1]]
		var edge := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.005
		cyl.bottom_radius = 0.005
		cyl.height = a.distance_to(b)
		cyl.radial_segments = 4
		edge.mesh = cyl
		edge.material_override = edge_mat
		edge.position = (a + b) / 2.0
		var dir := (b - a).normalized()
		if dir.length() > 0.001:
			var up := Vector3.UP
			var right := dir.cross(up).normalized()
			if right.length() < 0.001:
				right = Vector3.RIGHT
				up = right.cross(dir).normalized()
			else:
				up = right.cross(dir).normalized()
			edge.transform.basis = Basis(right, dir, up)
		_sim_root.add_child(edge)

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	_trail_instance.material_override = MAT_TRAIL
	_sim_root.add_child(_trail_instance)

func _process(_delta: float) -> void:
	_velocity += _gravity
	_position += _velocity

	if _position.x - ball_radius < _bounds_min.x or _position.x + ball_radius > _bounds_max.x:
		_velocity.x *= -elasticity
		_position.x = clamp(_position.x, _bounds_min.x + ball_radius, _bounds_max.x - ball_radius)

	if _position.y - ball_radius < _bounds_min.y or _position.y + ball_radius > _bounds_max.y:
		_velocity.y *= -elasticity
		_position.y = clamp(_position.y, _bounds_min.y + ball_radius, _bounds_max.y - ball_radius)

	if _position.z - ball_radius < _bounds_min.z or _position.z + ball_radius > _bounds_max.z:
		_velocity.z *= -elasticity
		_position.z = clamp(_position.z, _bounds_min.z + ball_radius, _bounds_max.z - ball_radius)

	_ball.position = _position

	_trail_points.append(_position)
	if _trail_points.size() > _max_trail_length:
		_trail_points.remove_at(0)

	_update_trail()

func _update_trail() -> void:
	_trail_mesh.clear_surfaces()
	# `result` is the one value that keeps no history. The points are still
	# accumulated so that a map switching evidence at runtime does not start
	# the ball's memory over.
	if evidence == "result":
		return
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points:
		_trail_mesh.surface_add_vertex(point)
	_trail_mesh.surface_end()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════════════
# EVIDENCE · REGIME
# ═══════════════════════════════════════════════════════════════════════════

## Grid config arrives twice and by two routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config(),
## and the capture harness calls apply_grid_config() before the scene enters the
## tree. Reading the metadata on the way in means the exhibit is built once,
## correctly, instead of built as `trace` and then torn down.
## Nearest carrier wins, and each key stops on its own: this artifact is placed as the
## mount of a curation_station in two maps, and a container must not be able to reach
## past the bench it is holding.
func _read_grid_config_meta() -> void:
	var node: Node = self
	var got_evidence: bool = false
	var got_regime: bool = false
	while node != null:
		if not got_evidence and node.has_meta("config_evidence"):
			evidence = str(node.get_meta("config_evidence"))
			got_evidence = true
		if not got_regime and node.has_meta("config_regime"):
			regime = str(node.get_meta("config_regime"))
			got_regime = true
		if got_evidence and got_regime:
			return
		node = node.get_parent()


## Config from map_data.json tokens: #evidence:longhand · #regime:elastic
##
## GUARDED ON CHANGE. A placement carrying any other token arrives with neither key,
## and the grid reaches this twice for one placement; an unguarded rebuild would tear
## down and re-raise the exhibit on both, for nothing.
func apply_grid_config(config: Dictionary) -> void:
	var was_evidence: String = evidence
	var was_regime: String = regime

	if config.has("evidence"):
		evidence = str(config["evidence"])
	if config.has("regime"):
		regime = str(config["regime"])

	if evidence == was_evidence and regime == was_regime:
		return

	# Before _ready() the ball does not exist yet and _ready() will do all of this.
	if not is_instance_valid(_ball):
		return

	if regime != was_regime:
		_apply_regime()
	_apply_evidence()


## The coefficient of restitution the walls run at.
##
## `stock` is a genuine no-op: it puts back the value this placement was authored
## with, which for every shipped placement is the export default 0.9. The other
## three are the textbook cases, and `inelastic` is 0.55 — bouncing_ball's number
## for the same word, so a map that asks both benches for `inelastic` gets one
## answer rather than two.
func _apply_regime() -> void:
	var want: String = String(regime).strip_edges().to_lower()
	if not REGIMES.has(want):
		want = "stock"
	regime = want

	if _stock_elasticity < 0.0:
		_stock_elasticity = elasticity

	match want:
		"elastic":
			elasticity = 1.0
		"dead":
			elasticity = 0.0
		"inelastic":
			elasticity = 0.55
		_:
			elasticity = _stock_elasticity


const EV_MAG_V := 2.0            # longhand: magnification for v
const EV_MAG_G := 20.0           # longhand: magnification for g (0.015 is a quarter of a pixel)
const EV_RUNGS := 7              # longhand: apexes drawn in the decay ladder
const EV_CHALK := Color(0.88, 0.90, 0.95)
const EV_INK := Color(0.98, 0.74, 0.26)
const EV_SLATE := Color(0.16, 0.17, 0.20)


func _apply_evidence() -> void:
	var want: String = String(evidence).strip_edges().to_lower()
	if not EVIDENCES.has(want):
		want = "trace"                       # an unknown word keeps the shipped build
	evidence = want

	for part in _evidence_parts:
		if is_instance_valid(part):
			part.queue_free()
	_evidence_parts.clear()

	if is_instance_valid(_trail_instance):
		_trail_instance.visible = want != "result"

	if want == "trace":
		return                               # THE SHIPPED BUILD: the live trail, nothing added
	if want == "result":
		return                               # the same scene with its memory switched off

	var root := Node3D.new()
	root.name = "Evidence_%s" % want
	add_child(root)
	_evidence_parts.append(root)

	match want:
		"longhand":
			_ev_longhand(root)
		"axiom":
			_ev_axiom(root)
		_:
			pass


## The apex heights this ball is going to reach, above the floor, predicted here at
## build time from e alone. h(n+1) = e^2 h(n) is on the geometry the moment the
## artifact exists, so `longhand` does not have to wait and watch to be right.
func _ev_apex_heights() -> Array[float]:
	var g: float = maxf(gravity_strength, 0.0001)
	var first: float = (_position.y - _bounds_min.y) + (_velocity.y * _velocity.y) / (2.0 * g)
	var out: Array[float] = []
	var h: float = first
	for i in range(EV_RUNGS):
		out.append(h)
		h = h * elasticity * elasticity
	return out


## LONGHAND — the working instead of the answer. Everything the three lines of the
## update consume is put on the geometry at the release state: g and v as arrows
## (magnified, and labelled as such, because at true scale g is a fifth of a
## millimetre), the wall reflection drawn as an incoming and an outgoing speed arrow
## whose length ratio IS e, and the apex ladder whose rung ratio is e squared. The
## squaring drawn twice, once as speed and once as height. Everything is inside the
## wireframe box that was already there, so the capture AABB does not move.
func _ev_longhand(root: Node3D) -> void:
	var at: Vector3 = _position

	_ev_arrow(root, at, _velocity * EV_MAG_V, 0.008, _ev_mat(EV_INK, 1.0))
	root.add_child(_ev_text("v  x%d" % int(EV_MAG_V),
		at + _velocity * EV_MAG_V + Vector3(0.02, 0.02, 0.0), 14, EV_INK))

	_ev_arrow(root, at, _gravity * EV_MAG_G, 0.006, _ev_mat(EV_CHALK, 0.8))
	root.add_child(_ev_text("g  x%d" % int(EV_MAG_G),
		at + _gravity * EV_MAG_G + Vector3(0.02, -0.02, 0.0), 13, EV_CHALK))

	# The reflection, drawn where it happens. Down at speed s, up at speed s*e —
	# and the whole artifact is the difference between those two arrow lengths.
	var s: float = 0.22
	var foot: Vector3 = Vector3(_bounds_max.x - 0.10, _bounds_min.y, _bounds_min.z + 0.10)
	_ev_arrow(root, foot + Vector3(0.0, s, 0.0), Vector3(0.0, -s, 0.0), 0.007, _ev_mat(EV_CHALK, 0.8))
	_ev_arrow(root, foot + Vector3(0.05, 0.0, 0.0), Vector3(0.0, s * elasticity, 0.0),
		0.007, _ev_mat(EV_INK, 1.0))
	root.add_child(_ev_text("v' = -e v   e = %.2f" % elasticity,
		foot + Vector3(-0.02, s + 0.03, 0.0), 13, EV_INK))

	# The ladder: where the top of each bounce will be, drawn on the back wall.
	var heights: Array[float] = _ev_apex_heights()
	var mat: StandardMaterial3D = _ev_mat(EV_INK, 0.9)
	var faint: StandardMaterial3D = _ev_mat(EV_CHALK, 0.3)
	for i in range(heights.size()):
		var y: float = _bounds_min.y + heights[i]
		if y > _bounds_max.y:
			y = _bounds_max.y
		var rung_mat: StandardMaterial3D = faint
		if i == 0:
			rung_mat = mat
		var rung: MeshInstance3D = _ev_box(
			Vector3(0.0, y, _bounds_min.z + 0.012),
			Vector3(box_size * 0.72, 0.004, 0.004),
			rung_mat)
		root.add_child(rung)
	root.add_child(_ev_text("h(n+1) = e^2 h(n)",
		Vector3(-box_size * 0.36, _bounds_min.y + heights[0] + 0.02, _bounds_min.z + 0.014),
		14, EV_INK))


## AXIOM — the instance gives way to the rule. A slate on the inside of the back wall
## carries the three lines the ball obeys and the one line they amount to; the history
## is switched off, because a rule does not have a past. Drawn INSIDE the box for the
## same reason the ladder is: an overlay wider than the wireframe would enlarge the
## union AABB and re-zoom every frame in the sweep, including the default one.
func _ev_axiom(root: Node3D) -> void:
	var plate := Node3D.new()
	plate.position = Vector3(0.0, _bounds_min.y + box_size * 0.55, _bounds_min.z + 0.02)
	root.add_child(plate)

	var pw: float = box_size * 0.80
	var ph: float = box_size * 0.46
	plate.add_child(_ev_box(Vector3(0.0, 0.0, -0.006), Vector3(pw + 0.03, ph + 0.03, 0.008),
		_ev_mat(Color(0.28, 0.24, 0.20), 0.0)))
	plate.add_child(_ev_box(Vector3.ZERO, Vector3(pw, ph, 0.006), _ev_mat(EV_SLATE, 0.0)))

	# ASCII on purpose: Label3D falls back to the project font, and an operator that
	# renders as a tofu box is worse evidence than a plain line of code.
	plate.add_child(_ev_text("v += g", Vector3(-pw * 0.42, ph * 0.30, 0.008), 20, EV_CHALK))
	plate.add_child(_ev_text("p += v", Vector3(-pw * 0.42, ph * 0.12, 0.008), 20, EV_CHALK))
	plate.add_child(_ev_text("wall: v *= -e", Vector3(-pw * 0.42, ph * -0.06, 0.008), 20, EV_INK))
	plate.add_child(_ev_text("h(n+1) = e^2 h(n)     e = %.2f" % elasticity,
		Vector3(-pw * 0.42, ph * -0.30, 0.008), 16, EV_INK))

	# The one line the box cannot cross, and only e = 1 gets to keep: the release apex.
	var heights: Array[float] = _ev_apex_heights()
	var ceiling: float = minf(_bounds_min.y + heights[0], _bounds_max.y)
	root.add_child(_ev_box(Vector3(0.0, ceiling, _bounds_max.z - 0.012),
		Vector3(box_size * 0.9, 0.003, 0.003), _ev_mat(EV_CHALK, 0.5)))


# ── Small builders (ev_-prefixed so nothing in the demo can collide) ──────

## A shaft along `vec`, oriented with Basis.looking_at rather than look_at() so it does
## not care whether the node is in the tree or where the map put the artifact.
func _ev_arrow(root: Node3D, from: Vector3, vec: Vector3, thick: float, m: StandardMaterial3D) -> void:
	var length: float = vec.length()
	if length < 0.001:
		return
	var up: Vector3 = Vector3.UP
	if absf(vec.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(thick, thick, length)
	mi.mesh = bm
	mi.material_override = m
	mi.transform = Transform3D(Basis.looking_at(vec, up), from + vec * 0.5)
	root.add_child(mi)

	root.add_child(_ev_box(from + vec, Vector3(thick * 2.2, thick * 2.2, thick * 2.2), m))


func _ev_mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _ev_box(p: Vector3, s: Vector3, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	return mi


func _ev_text(content: String, p: Vector3, size: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.font_size = size
	l.pixel_size = 0.0012
	l.modulate = c
	l.position = p
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return l
