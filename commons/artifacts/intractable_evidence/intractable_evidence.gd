# intractable_evidence.gd
# Bayes' denominator, written in full and never evaluated.

extends Node3D
class_name IntractableEvidence

# @identity
# essence: P(h|D) = P(D|h)·P(h) / Σ_h P(D|h)·P(h) — a finite numerator over a sum across every hypothesis
# desire: learner sees a formula that is CORRECT and UNRUNNABLE and stops hearing those as one word
# critical_parameter: regime — whether the sum over hypotheses closes, strains, stays open, or is replaced by a sample
# triggers: static display; the shrinking row IS the sum, the counter says how far it got
# emerges: that "we know the right answer" and "we can compute the right answer" come apart, and every working system lives on the second side
# needs: [no VR controls — a hypothesis-count dial is the obvious extension; regime is set from the map token]
# relationships: stands with constructive_proof (existence without construction) and excluded_middle_demo in Brouwer_Intuitionism; the computational twin of godel_statement_plaque; sister to complexity_dial_workbench, which measures the same gap in steps rather than in terms
# truth: the term nobody can compute is the one called the evidence

# ── WHY THIS IS IN BROUWER'S ROOM AND NOT GÖDEL'S ────────────────────────────
#
# Gödel's sentence is true and unprovable. This is narrower and, for anyone who
# builds things, worse: the posterior is fully specified, provably the right way
# to hold a belief, and for any interesting hypothesis space it cannot be
# evaluated. Nothing is missing from the statement. What is missing is the run.
#
# That is Brouwer's objection with a machine attached. Classical mathematics
# accepts an object it can name; intuitionism demands one it can construct. The
# evidence term is the purest specimen available: written on one line, and no
# construction, ever, for the spaces we care about. constructive_proof, two
# cells south in this same room, states the same complaint about ∃x. This states
# it about a denominator that the entire field agrees is correct.
#
# The name is the joke and the joke is load-bearing. Σ_h P(D|h)·P(h) is called
# the EVIDENCE. It is the one term nobody computes.

# ── STAGE-2 DNA — ONE AXIS: `regime` ─────────────────────────────────────────
#
# The axis is the state of the sum, and each value is a different silhouette,
# which is the whole reason it can be photographed.
#
#   closed        few enough hypotheses that the row ENDS. Eight tiles, all in
#                 the produced colour, a stop-block after the last one, and the
#                 posterior plate lit. This is the textbook case, and it is the
#                 case that never occurs outside a textbook.
#   strained      the row runs long, the near terms produced and the far ones
#                 claimed, and the counter reports a fraction that is already
#                 hopeless. The posterior plate is grey: no answer yet exists.
#   open          the row shrinks toward its limit with no stop-block and every
#                 tile claimed. The counter's target is not a number, it is 2^N.
#                 THE DEFAULT, because it is the argument.
#   approximated  the row is gone. Six tiles remain, lifted clear of the rail at
#                 the positions they held in it, in a third colour, and the
#                 posterior plate is LIT in that same third colour. An answer was
#                 produced. It is not the answer written beside it.
#
# THE COLOUR RULE, and it carries the argument on its own:
#   blue  = produced          (constructive_proof's witness colour, deliberately)
#   grey  = claimed, not built (constructive_proof's unproduced colour)
#   amber = answered, but not this question
# Only `closed` is blue and only `approximated` is amber. `approximated` is the
# one every deployed system is standing in, which is why it gets a colour of its
# own rather than being allowed to borrow the blue.
#
# NOT AN AXIS: the numerator. It is small, finite and complete at every value,
# because that is the point. If it changed, a measured bite here could be a bite
# in the easy half of the fraction.

## The state of the sum over hypotheses.
@export_enum("closed", "strained", "open", "approximated") var regime: String = "open"

## Exponent printed as the target term count, 2^N. Ignored by `closed`, which
## states a real number because its sum really does close.
@export var hypothesis_bits: int = 12

## Overall size. The artifact is authored at roughly 2.5 m wide and 1.6 m tall.
@export var plate_scale: float = 1.0

const REGIMES: PackedStringArray = ["closed", "strained", "open", "approximated"]

## constructive_proof's witness blue. Same room, same claim, same colour.
const PRODUCED_COLOR: Color = Color(0.30, 0.60, 0.90)
## constructive_proof's unproduced grey.
const CLAIMED_COLOR: Color = Color(0.45, 0.45, 0.50)
## Answered by other means. Nothing else in the room is this colour.
const APPROXIMATE_COLOR: Color = Color(0.95, 0.62, 0.16)

# THREE TONAL STEPS, and the first build had none: plinth, mount and panel were
# all within 0.07 of each other, so the object photographed as one grey slab and
# the sweep's subject detector — which counts pixels differing from the corner
# background — could only see the lit plates, putting the "subject" at 13.6% of
# a frame the artifact was actually filling. Dark-on-dark is not a measurement
# problem to be reframed around, it is the object failing to have a body. So:
# a pale stone plinth, bright machined edges, and a panel kept dark enough that
# the blue and the amber still carry.
const PANEL_COLOR: Color = Color(0.155, 0.168, 0.205)
const MOUNT_COLOR: Color = Color(0.44, 0.46, 0.52)
const BASE_COLOR: Color = Color(0.335, 0.335, 0.355)
const RAIL_COLOR: Color = Color(0.56, 0.58, 0.63)
const INK: Color = Color(0.93, 0.95, 0.99)
const INK_DIM: Color = Color(0.62, 0.65, 0.72)

# ── LAYOUT ───────────────────────────────────────────────────────────────────
#
# TWO REBUILDS, BOTH DRIVEN BY A PHOTOGRAPH, and the notes are kept because the
# discarded versions were each wrong in a way worth not repeating.
#
# Build 1 stacked the four parts vertically on one post. A column of plates is
# not an equation, it is a totem, and nothing told the reader that the bottom
# plate divided anything.
#
# Build 2 laid the equation out left to right and sent the denominator receding
# into -Z. That reads correctly and photographs badly: the sum's whole argument
# lived in a perspective foreshortening, so it was legible from exactly one
# standpoint and looked like a comb from every other. The corpus has a rule
# about axes that are only alive from one camera position.
#
# Build 3, this one, runs the sum LATERALLY and lets it shrink. Each tile and
# each gap is STEP_RATIO of the last, so the row converges to a limit point it
# never reaches while the counter beside it says 2^N. The bounded object holding
# an unbounded count is now a fact about the geometry rather than a trick of the
# lens, it is true from every angle, and it is Zeno's picture, which is the right
# borrowed picture for a room about what cannot be completed.
#
# Everything mounts on one back panel standing on one base, so the artifact has
# a silhouette and reads as a single instrument instead of parts on sticks.

const BASE_SIZE: Vector3 = Vector3(2.50, 0.45, 0.66)
const BASE_AT: Vector3 = Vector3(0.10, 0.225, -0.06)

const PANEL_SIZE: Vector3 = Vector3(2.30, 1.17, 0.06)
const PANEL_AT: Vector3 = Vector3(0.10, 1.035, -0.20)
## The mount plate behind the panel, showing as a thin lip all round.
const MOUNT_INSET: float = 0.05

## Everything readable sits just proud of the panel face.
const FACE_Z: float = -0.145
const TEXT_Z: float = -0.105

const POSTERIOR_AT: Vector3 = Vector3(-0.80, 1.17, FACE_Z)
const EQUALS_AT: Vector3 = Vector3(-0.46, 1.17, TEXT_Z)
const NUMERATOR_AT: Vector3 = Vector3(-0.10, 1.34, FACE_Z)
const BAR_AT: Vector3 = Vector3(-0.10, 1.17, FACE_Z)

## The row's left end and its height. It runs +X and shrinks.
const ROW_X0: float = -0.38
const ROW_Y: float = 0.99

## First gap and first tile width, metres. Everything to the right shrinks by
## STEP_RATIO, so the row is bounded at ROW_X0 + FIRST_STEP / (1 - STEP_RATIO)
## = 1.26, which is the panel's right edge. The sum runs out of panel and stops
## growing at the same place, and that coincidence is on purpose.
const FIRST_STEP: float = 0.115
const STEP_RATIO: float = 0.93
const TILE_HEIGHT_RATIO: float = 1.55

## Which indices survive into `approximated`, and which way each is lifted clear
## of the rail. Fixed, never sampled: an unseeded randf would make five captures
## of this artifact five different objects.
const SAMPLE_INDICES: PackedInt32Array = [2, 7, 13, 20, 28, 36]
const SAMPLE_LIFT: float = 0.13

var _body: Node3D
var _built: bool = false

func _ready() -> void:
	_build()
	_built = true


func apply_grid_config(config_data: Dictionary) -> void:
	var dirty := false
	if config_data.has("regime"):
		var want := String(config_data["regime"])
		if want in REGIMES and want != regime:
			regime = want
			dirty = true
	if config_data.has("hypothesis_bits"):
		var bits := int(config_data["hypothesis_bits"])
		if bits > 0 and bits != hypothesis_bits:
			hypothesis_bits = bits
			dirty = true
	for key in ["plate_scale", "scale", "size"]:
		if config_data.has(key):
			var s := float(config_data[key])
			if s > 0.0 and not is_equal_approx(s, plate_scale):
				plate_scale = s
				dirty = true
			break
	if dirty and _built:
		_build()


## Everything the axis decides, in one place, so the builders below stay dumb.
func _spec() -> Dictionary:
	match regime:
		"closed":
			return {
				"drawn": 8,
				"produced_upto": 8,
				"capped": true,
				"sampled": false,
				"posterior": PRODUCED_COLOR,
				"lit": true,
				"target": "8",
				"caption": "the sum closes.\nthe posterior is produced.",
			}
		"strained":
			return {
				"drawn": 26,
				"produced_upto": 5,
				"capped": false,
				"sampled": false,
				"posterior": CLAIMED_COLOR,
				"lit": false,
				"target": _target_text(),
				"caption": "still summing.\nthe answer is not yet a thing.",
			}
		"approximated":
			return {
				"drawn": 40,
				"produced_upto": 0,
				"capped": false,
				"sampled": true,
				"posterior": APPROXIMATE_COLOR,
				"lit": true,
				"target": _target_text(),
				"caption": "answered.\nnot the answer beside it.",
			}
		_:
			return {
				"drawn": 40,
				"produced_upto": 0,
				"capped": false,
				"sampled": false,
				"posterior": CLAIMED_COLOR,
				"lit": false,
				"target": _target_text(),
				"caption": "written, never evaluated.",
			}


func _target_text() -> String:
	return "2^%d" % hypothesis_bits


func _build() -> void:
	if _body != null and is_instance_valid(_body):
		_body.queue_free()
	_body = Node3D.new()
	_body.name = "Body"
	_body.scale = Vector3.ONE * plate_scale
	add_child(_body)

	var spec := _spec()
	_build_case()
	_build_equation()
	_build_denominator(spec)
	_build_posterior(spec)
	_build_readout(spec)


func _material(albedo: Color, lit: bool, roughness: float = 0.42) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = roughness
	m.metallic = 0.0
	if lit:
		m.emission_enabled = true
		m.emission = albedo
		m.emission_energy_multiplier = 0.85
	return m


func _plate(size: Vector3, at: Vector3, albedo: Color, lit: bool, node_name: String,
		roughness: float = 0.42) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = at
	mi.material_override = _material(albedo, lit, roughness)
	_body.add_child(mi)
	return mi


func _text(content: String, at: Vector3, font_size: int, albedo: Color, node_name: String,
		align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label3D:
	var l := Label3D.new()
	l.name = node_name
	l.text = content
	l.pixel_size = 0.001
	l.font_size = font_size
	l.modulate = albedo
	l.position = at
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.horizontal_alignment = align
	l.outline_size = 0
	_body.add_child(l)
	return l


## Base, mount plate and panel. One silhouette, standing on the floor.
func _build_case() -> void:
	_plate(BASE_SIZE, BASE_AT, BASE_COLOR, false, "Base", 0.55)
	# a bright lip along the base's top front edge, so the object has a horizon
	_plate(Vector3(BASE_SIZE.x, 0.012, 0.02),
			Vector3(BASE_AT.x, BASE_AT.y + BASE_SIZE.y * 0.5, BASE_AT.z + BASE_SIZE.z * 0.5),
			RAIL_COLOR, false, "BaseLip", 0.35)
	_plate(Vector3(PANEL_SIZE.x + MOUNT_INSET, PANEL_SIZE.y + MOUNT_INSET, 0.03),
			PANEL_AT + Vector3(0.0, 0.0, -0.04), MOUNT_COLOR, false, "MountPlate", 0.5)
	_plate(PANEL_SIZE, PANEL_AT, PANEL_COLOR, false, "Panel", 0.78)


## The half of Bayes' rule that costs nothing, over the bar, beside the equals.
func _build_equation() -> void:
	_plate(Vector3(0.50, 0.17, 0.035), NUMERATOR_AT, PRODUCED_COLOR, true, "Numerator")
	_text("P(D|h) · P(h)", NUMERATOR_AT + Vector3(0.0, 0.0, 0.04), 21, INK, "NumeratorText")
	_plate(Vector3(0.64, 0.022, 0.03), BAR_AT, Color(0.86, 0.88, 0.92), false, "FractionBar")
	_text("=", EQUALS_AT, 56, Color(0.88, 0.90, 0.94), "Equals")
	_text("THE EVIDENCE", Vector3(-0.80, 1.50, TEXT_Z), 18, Color(0.54, 0.57, 0.64), "Title")


## The sum, running right and shrinking toward a limit it never reaches.
func _build_denominator(spec: Dictionary) -> void:
	var drawn: int = int(spec["drawn"])
	var produced_upto: int = int(spec["produced_upto"])
	var sampled: bool = bool(spec["sampled"])

	# The rail the terms stand on, so the row is a measured run and not a comb.
	# It stops where the series does, which is where the panel stops.
	var rail_len: float = FIRST_STEP / (1.0 - STEP_RATIO)
	_plate(Vector3(rail_len, 0.014, 0.05),
			Vector3(ROW_X0 + rail_len * 0.5, ROW_Y - 0.085, FACE_Z - 0.005),
			RAIL_COLOR, false, "Rail", 0.35)

	var step := FIRST_STEP
	var width := FIRST_STEP * 0.82
	var x := ROW_X0
	var last_x := x
	var last_w := width

	for i in drawn:
		var keep := true
		var lift := 0.0
		if sampled:
			keep = SAMPLE_INDICES.has(i)
			if keep:
				lift = SAMPLE_LIFT * (1.0 if (SAMPLE_INDICES.find(i) % 2) == 0 else 0.52)
		if keep:
			var produced := sampled or i < produced_upto
			var albedo := CLAIMED_COLOR
			if sampled:
				albedo = APPROXIMATE_COLOR
			elif produced:
				albedo = PRODUCED_COLOR
			var h := width * TILE_HEIGHT_RATIO
			_plate(Vector3(width, h, width * 0.78),
					Vector3(x + width * 0.5, ROW_Y - 0.085 + h * 0.5 + lift, FACE_Z),
					albedo, sampled or produced, "Term%d" % i)
		last_x = x + width
		last_w = width
		x += step
		step *= STEP_RATIO
		width *= STEP_RATIO

	# `closed` is the only value whose sum has an end, so it is the only one that
	# gets a stop-block. The others simply stop where the drawing stopped, which
	# is a different fact and must not be allowed to look like the same one.
	if bool(spec["capped"]):
		_plate(Vector3(0.03, 0.20, 0.07),
				Vector3(last_x + 0.03, ROW_Y - 0.085 + 0.10, FACE_Z),
				PRODUCED_COLOR, true, "StopBlock")

	var sigma := "Σ  P(D|h) · P(h)"
	if bool(spec["sampled"]):
		sigma = "Σ  over a sample"
	_text(sigma, Vector3(-0.10, 0.76, TEXT_Z), 18, Color(0.80, 0.83, 0.88), "DenominatorText")


## What comes out. Colour and light are the verdict.
func _build_posterior(spec: Dictionary) -> void:
	var albedo: Color = spec["posterior"]
	var lit: bool = bool(spec["lit"])
	_plate(Vector3(0.54, 0.25, 0.04), POSTERIOR_AT, albedo, lit, "Posterior")
	var ink := INK if lit else INK_DIM
	_text("P(h | D)", POSTERIOR_AT + Vector3(0.0, 0.0, 0.04), 27, ink, "PosteriorText")


## How far the sum got, and what it was supposed to reach. Set on the panel
## under the equation rather than on a hanging placard: build 2 put these on the
## leg and the capture came back with three slivers nobody could read standing.
func _build_readout(spec: Dictionary) -> void:
	var head := ""
	if bool(spec["sampled"]):
		head = "%d SAMPLED OF %s" % [SAMPLE_INDICES.size(), spec["target"]]
	else:
		head = "%d / %s TERMS SUMMED" % [int(spec["drawn"]), spec["target"]]
	_plate(Vector3(0.008, 0.34, 0.014), Vector3(0.36, 1.24, FACE_Z),
			RAIL_COLOR, false, "ReadoutTick", 0.35)
	_text(head, Vector3(0.44, 1.33, TEXT_Z), 25, Color(0.90, 0.92, 0.96),
			"Counter", HORIZONTAL_ALIGNMENT_LEFT)
	_text(String(spec["caption"]), Vector3(0.44, 1.17, TEXT_Z), 17, INK_DIM,
			"Caption", HORIZONTAL_ALIGNMENT_LEFT)
