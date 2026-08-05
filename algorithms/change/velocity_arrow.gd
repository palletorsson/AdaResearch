# Velocity Arrow — velocity as the derivative of position
#
# A small puck moves around a closed track. An arrow rides on the puck pointing in its
# direction of motion, with length proportional to speed. When the track curves tightly,
# the arrow rotates fast; when straight, it stays steady.
#
# Bridges the calculus introduced in change → the physics introduced in forces. The
# arrow IS the derivative of position. The next sequence (forces) will say "force changes
# velocity" — and the player will already know what velocity is.
#
# @identity
# essence: a puck circles a closed track with an arrow riding on it, pointing along motion, its length proportional to speed — velocity as the derivative of position
# desire: to let the player meet velocity before forces names it, so "force changes velocity" lands on something already understood
# critical_parameter: speed — how fast the puck circulates, and therefore how long and how quickly-rotating the arrow becomes
# triggers: the puck advances along the ellipse every frame; the arrow re-aims to the instantaneous direction of travel
# emerges: on tight curves the arrow swings fast, on straights it holds steady — the player sees that changing direction is itself a change in velocity
# needs: animated puck + direction arrow [has]; numeric speed readout [missing]; grabbable speed control so the player drives the puck [missing]
# relationships: the bridge artifact from change into forces — velocity = derivative of position here, force = change of velocity next; pairs with slope_tangent_demo
# truth: velocity is the derivative of position — motion is the visible rate at which where-you-are becomes where-you-are-next
# @qfep_term: F (deterministic motion) → ΔF/Δt = velocity.

extends Node3D
class_name VelocityArrow

@export_category("Track Settings")
@export var puck_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var arrow_color: Color = Color(1.0, 0.6, 0.25, 1.0)
@export var track_color: Color = Color(0.3, 0.35, 0.45, 1.0)
@export var track_radius_x: float = 1.4
@export var track_radius_z: float = 0.9
@export var puck_radius: float = 0.12
@export var speed: float = 0.6

## --- DNA (stage 2, promoted 2026-08-05) --------------------------------------------
##
## phase — WHERE ON THE TRACK the velocity is being read. `traverse` is the shipped puck,
##   circulating the whole loop on _process; the other three stop it where this track
##   actually says something different, and they are the only such places it HAS. The
##   bulge in _track_point (`sin(a*2) * 0.15`) exists precisely to make curvature vary,
##   and the numbers it produces are these:
##
##     straight  a = pi/2      curvature 0.311 (minimum), |v| 1.700 (maximum). The longest
##               arrow on the track, barely turning. Rate high, change of rate lowest.
##     bend      a = 0.3241    curvature 2.218 (maximum), |v| 0.878 (near minimum). The
##               shortest arrow, swinging fastest — this is also where k*|v|, the rate the
##               arrow itself rotates, peaks, so `swing` would have been a second name for
##               this one point and is deliberately absent.
##     mirror    a = 3pi/2     the point diametrically opposite `straight`, on the side the
##               bulge does not touch: same-looking piece of ellipse, |v| 1.100 against
##               1.700 and curvature 0.744 against 0.311. The claim is that two places
##               which look symmetric are not moving alike, which is the whole reason this
##               track is not a circle.
##
##   Pinning also makes the artifact photographable at all: `traverse` depends on how many
##   process frames the headless boot managed before the shutter, so two traverse frames
##   are a clock, not a bite. Same reason slope_tangent_demo carries `phase`.
##
## evidence — how much of the working stands beside the moving puck. Family word, taken
##   character for character (result | trace | longhand | axiom, 38 siblings) and with
##   slope_tangent_demo's default, `trace`: the rate drawn at one point and nothing else.
@export_enum("traverse", "straight", "bend", "mirror") var phase: String = "traverse"
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "trace"

const PHASES := ["traverse", "straight", "bend", "mirror"]
const EVIDENCE := ["result", "trace", "longhand", "axiom"]
## Track angle of each station. `traverse` is absent on purpose — a missing key is what
## makes the shipped `fmod(_t, TAU)` line the one that runs.
const PHASE_A := {"straight": 1.5708, "bend": 0.3241, "mirror": 4.7124}

## The angular step the LONGHAND secant is DRAWN over. Deliberately larger than the 0.05 rad
## the finite difference inside _update_puck_and_arrow actually uses: at 0.05 the two sample
## points sit 7 cm apart and the chord is invisible, which is the info_board failure — a
## working drawn at a size no still can hold. The gap between the visible chord and the
## arrow inside it IS the picture longhand is for, and the readout names the step so the
## frame does not lie about which number it drew.
const LONGHAND_STEP: float = 0.42
const LONGHAND_LIFT: Vector3 = Vector3(0.0, 0.15, 0.0)

var _puck: MeshInstance3D
var _arrow: MeshInstance3D
var _t: float = 0.0

# EVIDENCE dressing. All null at `trace` and at `result`, which is why the shipped build is
# three children in three lines and stays that way.
var _sample_from: MeshInstance3D
var _sample_to: MeshInstance3D
var _chord: MeshInstance3D
var _readout: Label3D
var _axiom: Node3D


func _ready() -> void:
	_build_track()
	_build_puck()
	_build_arrow()
	# DNA, LAST: the evidence pass runs after the whole legacy build exists. `trace` leaves
	# the arrow on layer 1 and adds no node, so the shipped lineage keeps its exact three
	# children in their exact order.
	_build_evidence()


func apply_grid_config(config_data: Dictionary) -> void:
	# The three numeric knobs keep their pre-promotion behaviour exactly, including the
	# part of it that never worked: track_radius_x/z are assigned after _ready has already
	# stitched the track mesh, so the drawn ring does not move even though the puck's path
	# does. Nothing here rebuilds for them, because nothing rebuilt for them before.
	if config_data.has("track_radius_x"):
		track_radius_x = float(config_data["track_radius_x"])
	if config_data.has("track_radius_z"):
		track_radius_z = float(config_data["track_radius_z"])
	if config_data.has("speed"):
		speed = float(config_data["speed"])
	# phase is read fresh every frame, so it needs no rebuild at all.
	if config_data.has("phase"):
		var p: String = str(config_data["phase"]).strip_edges().to_lower()
		if PHASES.has(p):
			phase = p
	# evidence decides which nodes exist, so it does — but only when the word validates,
	# only when it actually differs, and only after _ready has built once (_puck is the
	# proof of that, and it is null until then).
	if config_data.has("evidence"):
		var ev: String = str(config_data["evidence"]).strip_edges().to_lower()
		if EVIDENCE.has(ev) and ev != evidence:
			evidence = ev
			if _puck != null:
				_clear_evidence()
				_build_evidence()


func _process(delta: float) -> void:
	_t += delta * speed
	_update_puck_and_arrow()


func _build_track() -> void:
	var track := MeshInstance3D.new()
	track.name = "Track"
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	# Godot 4 removed PRIMITIVE_LINE_LOOP; use a LINE_STRIP and repeat the first
	# point to close the ring.
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var n := 96
	for i in n:
		var a: float = TAU * float(i) / float(n)
		var pos := _track_point(a)
		imm.surface_add_vertex(pos)
	imm.surface_add_vertex(_track_point(0.0))
	imm.surface_end()
	track.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = track_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	track.material_override = mat
	add_child(track)


func _track_point(angle: float) -> Vector3:
	# Asymmetric ellipse with a bulge to vary curvature.
	var x: float = cos(angle) * track_radius_x + sin(angle * 2.0) * 0.15
	var z: float = sin(angle) * track_radius_z
	return Vector3(x, 0.05, z)


func _build_puck() -> void:
	_puck = MeshInstance3D.new()
	_puck.name = "Puck"
	var s := SphereMesh.new()
	s.radius = puck_radius
	s.height = puck_radius * 2.0
	_puck.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = puck_color
	mat.emission_enabled = true
	mat.emission = puck_color
	mat.emission_energy_multiplier = 1.0
	_puck.material_override = mat
	add_child(_puck)


func _build_arrow() -> void:
	_arrow = MeshInstance3D.new()
	_arrow.name = "VelocityArrow"
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 0.04, 0.7)
	_arrow.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = arrow_color
	mat.emission_enabled = true
	mat.emission = arrow_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_arrow.material_override = mat
	add_child(_arrow)


func _update_puck_and_arrow() -> void:
	var a: float = fmod(_t, TAU)
	# PHASE: a named station pins the reading. `traverse` is not a key in PHASE_A, so on
	# the default this lookup misses and the line above is what decides `a`.
	if PHASE_A.has(phase):
		a = float(PHASE_A[phase])
	var p := _track_point(a)
	# Finite-difference velocity: tangent via a small angular step.
	var p_ahead := _track_point(a + 0.05)
	var v := (p_ahead - p) / 0.05  # approximate dP/da
	_puck.position = p + Vector3(0, 0.15, 0)
	var speed_mag := v.length()
	# Place the arrow at the puck, point along velocity, scale length by speed.
	_arrow.position = _puck.position + v.normalized() * 0.35
	var basis := Basis.looking_at(v.normalized(), Vector3.UP)
	_arrow.transform.basis = basis
	_arrow.scale.z = clamp(speed_mag * 0.7, 0.6, 2.2)
	# EVIDENCE dressing rides the puck. Every node it touches is null unless `longhand`
	# or `axiom` built it, so on the two shipped-shaped values this is five null checks.
	_update_evidence(a, p, speed_mag)


# ── EVIDENCE ─────────────────────────────────────────────────────────────────
# One axis, four members, the family word taken character for character. Everything below
# runs AFTER the legacy _ready() body. `trace` adds no node and moves no layer, so the
# shipped artifact is untouched: same track, same puck, same arrow, same finite difference.

func _evidence_value() -> String:
	var e: String = String(evidence).strip_edges().to_lower()
	return e if EVIDENCE.has(e) else "trace"


func _clear_evidence() -> void:
	for n in [_sample_from, _sample_to, _chord, _readout, _axiom]:
		if n != null and is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_sample_from = null
	_sample_to = null
	_chord = null
	_readout = null
	_axiom = null


func _build_evidence() -> void:
	var e: String = _evidence_value()
	if _arrow != null:
		# `layers`, not `visible`: the arrow keeps its box in the capture AABB at every
		# value, so the camera does not refit between `trace` and `result` and the four
		# tiles stay comparable. Godot's visibility would also have taken the whole
		# subtree, which is the trap this codebase keeps paying for.
		_arrow.layers = 0 if (e == "result" or e == "axiom") else 1
	match e:
		"longhand":
			_build_longhand()
		"axiom":
			_build_axiom()
		_:
			# "trace" is the shipped lineage; "result" is the same lineage with the
			# arrow dark. Neither builds a node.
			pass


## LONGHAND — the difference quotient the arrow is the limit of, laid out beside it: the
## two sample points, the chord between them, and the numeric speed readout this file's
## @identity has listed as missing since it was written.
func _build_longhand() -> void:
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.55, 0.85, 1.0, 1.0)
	ink.emission_enabled = true
	ink.emission = Color(0.55, 0.85, 1.0, 1.0)
	ink.emission_energy_multiplier = 1.2
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_chord = MeshInstance3D.new()
	_chord.name = "SecantChord"
	var bar := BoxMesh.new()
	bar.size = Vector3(0.035, 0.035, 1.0)
	_chord.mesh = bar
	_chord.material_override = ink
	add_child(_chord)

	_sample_from = _build_sample("SampleFrom", ink)
	_sample_to = _build_sample("SampleTo", ink)

	_readout = Label3D.new()
	_readout.name = "SpeedReadout"
	_readout.font_size = 48
	_readout.pixel_size = 0.004
	_readout.outline_size = 8
	_readout.outline_modulate = Color(0, 0, 0, 0.85)
	_readout.modulate = Color(0.85, 0.95, 1.0, 1.0)
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_readout)


func _build_sample(sample_name: String, ink: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = sample_name
	var s := SphereMesh.new()
	s.radius = 0.07
	s.height = 0.14
	mi.mesh = s
	mi.material_override = ink
	add_child(mi)
	return mi


## AXIOM — the law written out and no arrow drawn at all. The textbook line instead of the
## demonstration, which is what the rest of the family means by the word.
func _build_axiom() -> void:
	_axiom = Node3D.new()
	_axiom.name = "Axiom"
	_axiom.position = Vector3(0.0, 0.46, 0.0)
	add_child(_axiom)

	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.55, 0.40, 0.02)
	plate.mesh = box
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.81, 0.79, 0.75)
	pm.roughness = 0.92
	plate.material_override = pm
	_axiom.add_child(plate)

	var rule_mat := StandardMaterial3D.new()
	rule_mat.albedo_color = arrow_color
	rule_mat.emission_enabled = true
	rule_mat.emission = arrow_color
	rule_mat.emission_energy_multiplier = 1.8
	for sy in [1.0, -1.0]:
		var rule := MeshInstance3D.new()
		var rb := BoxMesh.new()
		rb.size = Vector3(1.55, 0.028, 0.026)
		rule.mesh = rb
		rule.material_override = rule_mat
		rule.position = Vector3(0.0, float(sy) * 0.20, 0.005)
		_axiom.add_child(rule)

	var l := Label3D.new()
	l.name = "Law"
	l.text = "v = dP/dt"
	l.font_size = 64
	l.pixel_size = 0.0042
	l.modulate = Color(0.17, 0.17, 0.19)
	l.outline_size = 6
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.02)
	_axiom.add_child(l)


func _update_evidence(a: float, p: Vector3, speed_mag: float) -> void:
	if _chord != null:
		var from: Vector3 = p + LONGHAND_LIFT
		var to: Vector3 = _track_point(a + LONGHAND_STEP) + LONGHAND_LIFT
		var d: Vector3 = to - from
		var l: float = d.length()
		_chord.position = (from + to) * 0.5
		if l > 0.001:
			_chord.transform.basis = Basis.looking_at(d / l, Vector3.UP)
		_chord.scale = Vector3(1.0, 1.0, maxf(l, 0.001))
		if _sample_from != null:
			_sample_from.position = from
		if _sample_to != null:
			_sample_to.position = to
	if _readout != null:
		_readout.position = _puck.position + Vector3(0.0, 0.34, 0.0)
		_readout.text = "|v| = %.2f\nchord over da = %.2f" % [speed_mag, LONGHAND_STEP]
