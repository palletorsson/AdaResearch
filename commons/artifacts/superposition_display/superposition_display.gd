# superposition_display.gd
# Visual representation of quantum superposition |ψ⟩ = α|0⟩ + β|1⟩

extends Node3D
class_name SuperpositionDisplay

# @identity
# essence: |ψ⟩ = α|0⟩ + β|1⟩; α oscillates as sin(t·speed), β = 1 - α; both states simultaneously present
# desire: see two basis states |0⟩ and |1⟩ breathe in and out of opacity while the superposition sphere pulses between them
# critical_parameter: remainder — where the display puts the part of the state it cannot draw (core | twin | seam | haze | witness); vantage — whether the argument is an object in front of you or a room around you (specimen | stele | chamber). _speed is tempo, not stance: it sets how fast the amplitudes trade.
# triggers: VR slider adjusts oscillation speed; opacity of |0⟩ and |1⟩ spheres anti-correlate continuously; apply_grid_config({remainder, vantage})
# emerges: the visual proof that superposition is not flickering between states — it is occupying both simultaneously
# needs: VR horizontal slider for speed [has]
# relationships: paired with schrodinger_box (abstract vs physical superposition) — the two share ONE `remainder`/`vantage` vocabulary, read through schrodinger_box.gd's own normalisers; contrasts florensky_sphere (quantum vs paraconsistent logic)
# truth: superposition is not uncertainty about which state the system is in — it is the system genuinely being in both

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-31). A CONVERGENCE, not a new axis.
#
# schrodinger_box was promoted on 2026-07-27 with `remainder` and `vantage`, and
# its @identity already claims that "the two share one remainder/vantage
# vocabulary". Until this file that claim was false — the display had no axis at
# all and apply_grid_config() was a bare `pass`. This makes it true.
#
# THE BURDEN OF PROOF WAS ON DIVERGENCE AND DIVERGENCE LOST. The pair are not
# neighbours by accident: every map that places one places the other (Florensky_
# Paraconsistent, its corridor and composed twins, SpeculativeComputation_
# Paraconsistent_Engineering, two curation bays), the registry clusters them, and
# the two @identity blocks name each other as "abstract vs physical". They are the
# same argument twice — a physical apparatus and a diagram — and the question the
# box's axis asks is exactly the question this file has to answer with three
# spheres instead of a lid:
#
#   remainder   WHERE THE OBJECT PUTS THE PART OF THE STATE IT CANNOT SHOW
#               core · twin · seam · haze · witness
#   vantage     WHETHER THE LIMIT IS AN OBJECT IN FRONT OF YOU OR A ROOM AROUND YOU
#               specimen · stele · chamber
#
# Nothing is degraded and nothing falls through to a silent wildcard: all five
# remainder values and all three vantage values build distinct geometry here. The
# spellings are the box's, character for character, and the tokens are parsed by
# the box's own static readers so a map that learns one word has learnt both
# artifacts.
#
# WHY NOT THE OBVIOUS AXIS — the trap this artifact sets. Everything about a
# superposition display wants to be staged as a BEFORE and an AFTER: two things at
# once, waiting, then a measurement, then one thing. That is invisible in a still,
# and worse, it is the classical picture wearing quantum notation — it says there
# was always going to be a fact and the display was merely early. This file
# already leans that way: the legacy build makes α and β trade opacity over time,
# which renders "both at once" as "alternately mostly one". The axis therefore
# does not touch the clock. It asks what the picture does in ONE FRAME with the
# thing it cannot draw, and every value answers differently while standing still.
#
# WHAT EACH VALUE DOES WITH THE PART IT CANNOT REPRESENT — the sieve's third
# question, and the test of whether this is a family or a menu. For a display, the
# unrepresentable is the "+" in α|0⟩ + β|1⟩: not either basis state, and not a
# third state either.
#
#   core     HIDES it.   The legacy build. A solid purple body stands at the
#                        origin between |0⟩ and |1⟩ — the sum drawn as an object,
#                        sealed, glowing, definite. It is the most classical claim
#                        in the family: "both at once" as a thing you could open.
#   twin     BOUNDS it.  There is nothing left over, because both outcomes are
#                        actual. The middle body is gone; two open cells stand
#                        where the diagram was, each holding one fully opaque,
#                        permanently visible occupant in its own basis colour, and
#                        a bright wall runs between them that neither can see
#                        across. Two definite worlds, walled.
#   seam     LEAVES A HOLE. The remainder IS the join. The two halves of the
#                        diagram are held apart on four bright posts and the "+"
#                        between them is an unlit, unfilled slot — the display
#                        marks the cut it cannot justify instead of drawing a body
#                        over it.
#   haze     BUILDS THERE. There was never an inside to seal. The enclosure the
#                        diagram implies is drawn as edges only, and the space
#                        outside it is already populated: thirty-four faint
#                        half-outcomes in the two basis colours, drifting in the
#                        room. The dark spot is habitat, not hole — the
#                        environment was measuring before you arrived.
#   witness  EXHIBITS it. The remainder is you. The display grows a shell with no
#                        front — it opens toward whoever is asking — and where the
#                        middle body stood there is a polished plate under a warm
#                        rim, handing the room back. There is no view from nowhere,
#                        and the picture says so by putting the asker in it.
#
# `vantage` is the second thing a limit can differ in: whether you are shown it or
# standing in it.
#
#   specimen  legacy: 0.7 m across, below your eyeline, a diagram you look down on
#   stele     lifted 1.7x to eye height against an upright slab — it addresses you
#   chamber   scaled 3.4x inside a three-walled shell — you are inside the diagram
#
# WHERE THIS FILE DIVERGES FROM THE BOX, and why each divergence is about the
# body and not about the argument:
#   · The control panel does NOT ride the vantage scale. It stays a direct child
#     of the root at its authored place, because a slider scaled 3.4x is a slider
#     nobody can reach, and `chamber` is the one variant that expects you to walk
#     in and stand at it. The box has no controls and so had no such choice.
#   · Slate and plate where the box uses wood. The pair's own @identity calls the
#     difference "abstract vs physical"; a diagram that grew a cabinet would stop
#     being the abstract half of the pair. The construction is the box's; the
#     material register is this one's.
#   · chamber scales 3.4x, not the box's 3.8x, because this body is 0.7 m wide
#     against the box's 0.4 m and 3.8x would put the basis states through the
#     walls. Like the box's, `chamber` is deliberately larger than the registry
#     footprint [1,1,1]: a map that opts into it is asking for a room and should
#     give the artifact the cells.
#   · `twin` hides the two oscillating basis spheres and builds opaque occupants
#     in their place, where the box hides its solid body. Same move, different
#     thing to hide: an occupant whose opacity is still trading is not a definite
#     outcome, and the branch reading needs both branches definite.
#
# ─────────────────────────────────────────────────────────────────────────────
# REPAIR (2026-07-31). THE REGISTER AXIS WAS FIFTEEN TIMES LOUDER THAN THE
# ARGUMENT AXIS. A proportion fix. No word, no value and no claim changed.
#
# doc/reports/sweep_superposition_display_bite.json, measured on the build above:
# hold `vantage` at chamber and the five `remainder` values differ from each
# other by 0.71%-1.57% of frame — every pair UNDER the 2% bite floor. Vary
# `vantage` instead and the same sweep moves 9%-13%. On a third of the family the
# argument the artifact exists to make was not visible at all, and what the sheet
# was actually reporting was the size of the room.
#
# THE MECHANISM IS NOT THE ONE IT LOOKS LIKE. `_shell` is a child of `_body`, so
# the remainder geometry does ride the vantage scale — it is not left behind at
# 1.0 while the diagram grows to 3.4. What it was left behind BY is the frame.
# capture_config_sweep.gd fits its camera to each variant's bounding-box DIAGONAL
# (`radius = aabb.size.length() * 0.5`), and at `chamber` that diagonal is the
# ROOM's: 4.6 x 2.9 x 4.6 of slab is 7.3 m corner to corner, wrapped around a
# remainder body at most 0.8 m wide before staging. So the shell was proportioned
# to the DIAGRAM while the picture was proportioned to the ROOM, and the walls —
# byte-identical across all five values — kept the rest of the frame. The five
# variants were photographs of the same room with a small disagreement in it.
#
# TWO THINGS CHANGE, BOTH RATIOS.
#
#   1. `reach` — the remainder geometry now grows with the staging it stands in
#      (specimen 1.0 · stele 1.2 · chamber 1.55), applied as one uniform scale on
#      Shell. Uniform matters: layout and mass grow together, so every internal
#      relation each value's comment claims — the halves held apart, the cut
#      between them, the shell that clears the basis states, the wall neither
#      cell can see across — is preserved exactly. The bound is the wall: at 1.55
#      `twin`, the widest body, reaches 2.145 m against an inner wall face at
#      2.23 m. Larger than that and the argument starts poking out of its own
#      room, which would inflate the frame and hand the score back to `vantage`.
#
#   2. `chamber` loses DEPTH, 4.6 m to 2.6 m. The diagram is flat. Depth was
#      contributing 42% of the room's squared diagonal — nearly half the framing
#      cost — to hold nothing at all. Three walls, a floor, the basis states 2.2 m
#      apart, and you inside them: every word `chamber` says is still true of a
#      4.6 x 2.9 x 2.6 room. Width is untouched, because width is what the
#      argument uses. The frame tightens from 7.30 m to 6.17 m.
#
# Together: 1.55² x 1.40 = 3.4x the changed area at chamber, which lifts the
# quietest pair (core vs seam, 0.71%) over the floor and puts the loud ones at
# 4-6% — the same band `remainder` already occupies at `specimen`.
#
# `haze` IS THE EXCEPTION AND SAYS WHY. It is the one value whose body was
# already room-scale: its ghosts spread 2.3 m at chamber, which is the wall.
# Giving it layout reach would push the cloud through the walls, grow the AABB,
# and buy a score by rescaling the room — the exact fraud being repaired. So haze
# takes reach in MASS only: the positions below are divided by reach so the cloud
# lands where it always landed, and `_cloud_fit()` then seats it inside the
# shallower room. What was invisible in haze was never the spread of its ghosts.
# It was that each one rendered about eleven pixels wide.
#
# WHAT THIS DOES NOT TOUCH: the five words, the three words, the alias tables,
# the formula, the ket labels, the colours, the oscillation, the slider, and what
# any value MEANS. A remainder that could only be seen by standing close was
# still making its argument. It was making it where the camera was not.
# ─────────────────────────────────────────────────────────────────────────────

# R1 — THE DEFAULT REPRODUCES THE SHIPPED BUILD EXACTLY. remainder=core and
# vantage=specimen: _apply_staging() frees nothing (both refs are null), writes
# three `visible = true` on nodes that are already visible, writes an identity
# scale and position onto a Body node that already holds them, records the two
# tokens, and RETURNS before Stage or Shell is created. Not one node is built, not
# one material touched. _create_states() and _create_label() are statement for
# statement what they were, with `add_child` reading `_body.add_child`; because
# Body sits at the identity transform on the default, every world transform is
# unchanged. _process(), _setup_controls() and _on_speed_changed() are untouched,
# and the panel is still a direct child of the root. apply_grid_config() was
# `pass` and now returns immediately unless the dictionary carries `remainder` or
# `vantage` — which is why curation_station's {"emissive": false} call still does
# exactly the nothing it did before.
#
# THE REPAIR DID NOT SPEND THIS. _reach() and _cloud_fit() are called from
# _stage_remainder() and _stage_vantage() only, and both of those sit BELOW the
# `remainder == "core" and vantage == "specimen"` return — the default still exits
# before either is ever evaluated. The corpus census that found zero live
# placements carrying any of these tokens therefore covers the repair too: every
# shipped placement of this artifact renders the same pixels as before.
#
# AND THE NEGATIVE TEST IS STRONGER THAN THE DEFAULT. reach is 1.0 and _cloud_fit
# is the identity at `specimen`, so ALL FIVE specimen variants — not just the
# default pair — must come back pixel-identical to the sweep that measured the
# fault: core/specimen, twin/specimen, seam/specimen, haze/specimen,
# witness/specimen, whose ten pairwise deltas were 2.96%-5.71%. If any of those
# ten numbers moves, the repair leaked out of the two vantages it was aimed at.
#
# WHAT IS FORECLOSED. `core` is now one opinion among five rather than the
# unmarked way a superposition diagram looks, and that costs something real: the
# innocent reading — three spheres as a neutral illustration of a formula — is
# harder to hold once the middle sphere is legible as a CHOICE about where the
# irreducible goes. Also foreclosed: reading the oscillation as the artifact's
# argument. Four of the five values make their whole claim standing still, which
# quietly says the animation was never carrying it.
#
# NOT ROUTED THROUGH EITHER AXIS, on purpose: the formula, the ket labels, the
# blue |0⟩ / orange |1⟩ colour assignment, the sinusoidal α/β trade, the slider
# and its 0.5..8.0 range, and the sentence "Both states at once until
# measurement". Where the sum is kept is a staging question. What the sum IS
# belongs to the curriculum, and this pass does not get a vote.
# ─────────────────────────────────────────────────────────────────────────────

## THE VOCABULARY'S HOME IS THE KIN'S FILE. schrodinger_box.gd owns
## REMAINDER_ALIASES / VANTAGE_ALIASES and the two static readers; this file calls
## them rather than keeping a second table, so a map that writes `branch` or
## `mirror` or `room` reaches the same value on both artifacts and the pair cannot
## drift apart on what the words mean. The two @export_enum lines below are the one
## thing that has to be written out twice — an annotation argument must be a
## literal — and _pick_axis() is what keeps that from mattering.
const RemainderAxis = preload("res://commons/artifacts/schrodinger_box/schrodinger_box.gd")

## AXIS 1 — where the display puts the part of the state it cannot draw.
## core (legacy default) | twin | seam | haze | witness. Shared verbatim with
## schrodinger_box; parses through RemainderAxis.remainder_name().
@export_enum("core", "twin", "seam", "haze", "witness") var remainder: String = "core"
## AXIS 2 — whether the limit is an object in front of you or a room around you.
## specimen (legacy default) | stele | chamber.
@export_enum("specimen", "stele", "chamber") var vantage: String = "specimen"

## The allow-lists a map token is checked against AFTER alias expansion. A word
## outside them falls back to the value already held rather than reaching the
## builders and silently matching nothing — a value that no-ops on one sibling of
## a shared vocabulary is the defect this project has had to fix twice.
const REMAINDERS: PackedStringArray = ["core", "twin", "seam", "haze", "witness"]
const VANTAGES: PackedStringArray = ["specimen", "stele", "chamber"]

## Read out of _create_states() below, never invented: the basis states sit at ±SEP
## on x with radius R_STATE, the superposition body at the origin, and the two
## basis colours are the ones the legacy build already paints. Every variant is
## built from these, so none of them can say anything the shipped diagram does not.
const SEP := 0.25
const R_STATE := 0.08
const COL_0 := Color(0.3, 0.5, 1.0)
const COL_1 := Color(1.0, 0.5, 0.3)

var RackTpl = load("res://commons/audio/rack_templates/RackTemplates.gd")

var _state_0: MeshInstance3D
var _state_1: MeshInstance3D
var _superposition: MeshInstance3D
var _label: Label3D
var _time: float = 0.0
var _speed: float = 2.0
var _slider: Node3D

# The diagram, at diagram scale. Identity transform in the legacy build; `vantage`
# moves and scales this and nothing else, so the original create functions keep
# their original numbers. The control panel is deliberately NOT inside it.
var _body: Node3D
# Remainder geometry that belongs to the DIAGRAM (rides the vantage scale).
var _shell: Node3D
# Vantage geometry that belongs to the ROOM (does not ride it).
var _stage: Node3D
var _built_remainder: String = ""
var _built_vantage: String = ""

func _ready():
	remainder = _pick_axis(RemainderAxis.remainder_name(remainder), REMAINDERS, "core")
	vantage = _pick_axis(RemainderAxis.vantage_name(vantage), VANTAGES, "specimen")
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	_create_states()
	_create_label()
	_setup_controls()
	_apply_staging()

func _create_states():
	# |0⟩ state
	_state_0 = MeshInstance3D.new()
	var s0 = SphereMesh.new()
	s0.radius = 0.08
	s0.height = 0.16
	_state_0.mesh = s0
	_state_0.position = Vector3(-0.25, 0, 0)
	var mat0 = StandardMaterial3D.new()
	mat0.albedo_color = Color(0.3, 0.5, 1.0, 0.6)
	mat0.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_state_0.material_override = mat0
	_body.add_child(_state_0)

	var lbl0 = Label3D.new()
	lbl0.text = "|0⟩"
	lbl0.pixel_size = 0.001
	lbl0.font_size = 14
	lbl0.position = Vector3(-0.25, 0.15, 0)
	_body.add_child(lbl0)

	# |1⟩ state
	_state_1 = MeshInstance3D.new()
	var s1 = SphereMesh.new()
	s1.radius = 0.08
	s1.height = 0.16
	_state_1.mesh = s1
	_state_1.position = Vector3(0.25, 0, 0)
	var mat1 = StandardMaterial3D.new()
	mat1.albedo_color = Color(1.0, 0.5, 0.3, 0.6)
	mat1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_state_1.material_override = mat1
	_body.add_child(_state_1)

	var lbl1 = Label3D.new()
	lbl1.text = "|1⟩"
	lbl1.pixel_size = 0.001
	lbl1.font_size = 14
	lbl1.position = Vector3(0.25, 0.15, 0)
	_body.add_child(lbl1)

	# Superposition (between them)
	_superposition = MeshInstance3D.new()
	var ss = SphereMesh.new()
	ss.radius = 0.1
	ss.height = 0.2
	_superposition.mesh = ss
	_superposition.position = Vector3(0, 0, 0)
	var mats = StandardMaterial3D.new()
	mats.albedo_color = Color(0.7, 0.4, 0.9, 0.7)
	mats.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mats.emission_enabled = true
	mats.emission = Color(0.5, 0.3, 0.7)
	mats.emission_energy_multiplier = 0.5
	_superposition.material_override = mats
	_body.add_child(_superposition)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	_label.text = "SUPERPOSITION\n|ψ⟩ = α|0⟩ + β|1⟩\n\nBoth states at once\nuntil measurement"
	_label.position = Vector3(0, -0.25, 0)
	_body.add_child(_label)

func _process(delta):
	_time += delta
	# Oscillate superposition
	var alpha = 0.5 + 0.3 * sin(_time * _speed)
	var beta = 1.0 - alpha

	var mat0 = _state_0.material_override as StandardMaterial3D
	var mat1 = _state_1.material_override as StandardMaterial3D
	mat0.albedo_color.a = 0.3 + 0.4 * alpha
	mat1.albedo_color.a = 0.3 + 0.4 * beta

func _setup_controls():
	var panel = RackTpl.create_panel("SUPERPOSITION", [
		[{"type": "slider_h", "label": "Speed", "default": 0.25}],
	])
	panel.position = Vector3(0, 0.5, 0.6)
	panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(panel)

	_slider = panel.find_child("Param_0", true, false)
	if _slider and _slider.has_signal("slider_moved"):
		_slider.slider_moved.connect(_on_speed_changed)

func _on_speed_changed():
	var val = _slider.get_normalized_value()
	_speed = 0.5 + val * 7.5

# ─────────────────────────────────────────────────────────────────────────────
# STAGING
# ─────────────────────────────────────────────────────────────────────────────

## Rebuild the two staging layers from the current axis values. Idempotent, and on
## the legacy pair it does nothing but write flags and transforms it already holds.
func _apply_staging() -> void:
	_drop(_shell)
	_shell = null
	_drop(_stage)
	_stage = null
	_state_0.visible = true
	_state_1.visible = true
	_superposition.visible = true
	_body.scale = Vector3.ONE
	_body.position = Vector3.ZERO
	_built_remainder = remainder
	_built_vantage = vantage

	if remainder == "core" and vantage == "specimen":
		return

	_stage = Node3D.new()
	_stage.name = "Stage"
	add_child(_stage)
	_shell = Node3D.new()
	_shell.name = "Shell"
	_body.add_child(_shell)
	_stage_vantage()
	_stage_remainder()

## Unparent BEFORE queue_free. A deferred free leaves the old lineage in the tree
## for the rest of the frame, and a capture that lands in that frame photographs
## two variants at once.
func _drop(n: Node) -> void:
	if n == null or not is_instance_valid(n):
		return
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	n.queue_free()

func _stage_vantage() -> void:
	var stone: StandardMaterial3D = _surface(Color(0.20, 0.20, 0.22), 0.88, 0.0, 0.0)
	match vantage:
		"stele":
			# Lifted to eye height against an upright slab: the diagram posted in
			# public, addressing you at your own height rather than lying under it.
			_body.scale = Vector3.ONE * 1.7
			_body.position = Vector3(0, 1.32, 0)
			_slab(_stage, Vector3(1.34, 2.15, 0.16), Vector3(0, 1.075, -0.40), stone)
			_slab(_stage, Vector3(1.66, 0.09, 0.72), Vector3(0, 0.045, -0.14), stone)
		"chamber":
			# No exterior to retreat to. Three walls and a floor at room scale, the
			# basis states 2.2 m apart at eye height in the middle of them. The
			# control panel stays behind at hand height, unscaled, so there is
			# something to stand at once you are inside.
			#
			# 2.6 m DEEP, NOT 4.6. See the REPAIR header. The diagram is flat, so
			# the two metres of depth this room used to carry held nothing and cost
			# 42% of the squared diagonal the sweep camera frames by — which is most
			# of why `remainder` was unreadable in here. Width is left alone, because
			# width is the dimension the argument uses. y drops 1.55 -> 1.45 so the
			# tallest remainder body (`twin`, +1.29 m above centre at reach 1.55)
			# clears the wall head instead of growing the room back through the roof.
			_body.scale = Vector3.ONE * 3.4
			_body.position = Vector3(0, 1.45, 0)
			_slab(_stage, Vector3(4.6, 0.08, 2.6), Vector3(0, 0.04, 0), stone)
			_slab(_stage, Vector3(4.6, 2.9, 0.14), Vector3(0, 1.45, -1.3), stone)
			_slab(_stage, Vector3(0.14, 2.9, 2.6), Vector3(-2.3, 1.45, 0), stone)
			_slab(_stage, Vector3(0.14, 2.9, 2.6), Vector3(2.3, 1.45, 0), stone)

func _stage_remainder() -> void:
	var signs: Array[float] = [-1.0, 1.0]
	# THE REPAIR, in one line. UNIFORM, so layout and mass grow together and every
	# internal relation the values claim below survives untouched — the halves held
	# apart, the cut between them, the shell that clears the basis states. 1.0 at
	# specimen, where nothing was wrong and so nothing may move.
	var reach: float = _reach()
	_shell.scale = Vector3.ONE * reach

	match remainder:
		"twin":
			# Both outcomes are actual, so there is no sum left over to draw. The
			# middle body goes; two open cells stand where the diagram was, each
			# with one definite, permanently visible occupant, and a bright wall
			# between them that neither can see across.
			_superposition.visible = false
			_state_0.visible = false
			_state_1.visible = false
			var cell: StandardMaterial3D = _surface(Color(0.30, 0.31, 0.34), 0.85, 0.0, 0.0)
			for s in signs:
				var branch: Color = COL_0 if s < 0.0 else COL_1
				_slab(_shell, Vector3(0.30, 0.30, 0.014), Vector3(s * SEP, 0.035, -0.12), cell)
				_slab(_shell, Vector3(0.30, 0.012, 0.24), Vector3(s * SEP, -0.10, -0.01), cell)
				_slab(_shell, Vector3(0.014, 0.30, 0.24), Vector3(s * (SEP + 0.15), 0.035, -0.01), cell)
				_ball(_shell, 0.09, Vector3(s * SEP, 0.0, 0.0), _surface(branch, 0.45, 0.0, 1.0))
			var wall: StandardMaterial3D = _surface(Color(0.88, 0.90, 0.96), 0.30, 0.2, 1.4)
			_slab(_shell, Vector3(0.012, 0.42, 0.30), Vector3(0, 0.035, -0.01), wall)

		"seam":
			# The remainder is the join. The halves are held apart on four bright
			# posts and the "+" between them is an unlit, unfilled slot — the cut
			# marked instead of papered over.
			_superposition.visible = false
			var face: StandardMaterial3D = _surface(Color(0.32, 0.30, 0.28), 0.85, 0.05, 0.0)
			for sh in signs:
				_slab(_shell, Vector3(0.22, 0.34, 0.13), Vector3(sh * SEP, 0.02, -0.16), face)
			var nothing: StandardMaterial3D = _surface(Color(0.02, 0.02, 0.03), 1.0, 0.0, 0.0)
			nothing.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_slab(_shell, Vector3(0.28, 0.32, 0.12), Vector3(0, 0.02, -0.16), nothing)
			var post: StandardMaterial3D = _surface(Color(0.86, 0.93, 1.00), 0.22, 0.4, 2.4)
			# A HAIRLINE IS NOT AREA. The posts are 14 mm square: at diagram scale
			# in a 1.2 m frame that is a readable bright line, and at chamber it was
			# five pixels. Reach already lengthens them; this thickens them too, so
			# what holds the halves apart is still visible from where the room puts
			# you. Identity at specimen — the shipped post is exactly 0.014.
			var post_t: float = 0.014 * reach
			for py in signs:
				for pz in signs:
					_slab(_shell, Vector3(0.34, post_t, post_t),
						Vector3(0, 0.02 + py * 0.17, -0.16 + pz * 0.055), post)

		"haze":
			# Nothing here was ever isolated. The enclosure the diagram implies is
			# drawn as edges only, and the space outside it is already full of faint
			# half-outcomes in the two basis colours.
			var bar: StandardMaterial3D = _surface(Color(0.48, 0.50, 0.55), 0.8, 0.1, 0.0)
			# The enclosure is the diagram's own extent plus a hand's width, so the
			# cage is the boundary this picture already implies rather than a new one.
			#
			# HAZE OPTS OUT OF LAYOUT REACH, and it is the only value that does.
			# Its body was already room-scale — at chamber the ghosts reach 2.3 m,
			# which is the wall — so scaling the layout would push the cloud through
			# the walls, grow the AABB, and buy a score by rescaling the room, which
			# is the fraud this repair exists to remove. Dividing by reach cancels
			# the Shell scale above, so hw/hh/hd land in world exactly where they
			# always landed. What haze takes is MASS: t2 carries reach, so the bars
			# thicken with the staging. Nothing here was ever too small a boundary.
			# It was too fine a line to survive being photographed from a doorway.
			var hw: float = (SEP + R_STATE + 0.05) / reach
			var hh: float = 0.20 / reach
			var hd: float = 0.15 / reach
			var oy: float = 0.02 / reach
			var t2: float = 0.013 * reach
			for cy in signs:
				for cz in signs:
					_slab(_shell, Vector3(hw * 2.0, t2, t2), Vector3(0, oy + cy * hh, cz * hd), bar)
				for cx in signs:
					_slab(_shell, Vector3(t2, t2, hd * 2.0), Vector3(cx * hw, oy + cy * hh, 0), bar)
			for ex in signs:
				for ez in signs:
					_slab(_shell, Vector3(t2, hh * 2.0, t2), Vector3(ex * hw, oy, ez * hd), bar)
			var ghost_0: StandardMaterial3D = _surface(Color(COL_0.r, COL_0.g, COL_0.b, 0.50), 0.6, 0.0, 0.7)
			ghost_0.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var ghost_1: StandardMaterial3D = _surface(Color(COL_1.r, COL_1.g, COL_1.b, 0.42), 0.6, 0.0, 0.6)
			ghost_1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var rng := RandomNumberGenerator.new()
			rng.seed = 20260731
			# Same seed, same four draws in the same order, so it stays the same
			# cloud — thirty-four half-outcomes, not a new scatter. rad and gy are
			# divided by reach and land where they always did; rr is NOT, so each
			# ghost grows with the staging. That is the whole of haze's repair: at
			# chamber a ghost was about eleven pixels across in a 760 px frame, and
			# thirty-four invisible things look exactly like an axis doing nothing.
			# The cap is deliberate — the largest ghost reaches 0.23 m against the
			# basis states' 0.27 m, so a half-outcome never outweighs an outcome.
			var cloud: Vector3 = _cloud_fit()
			for i in range(34):
				var ang: float = rng.randf() * TAU
				var rad: float = (0.30 + rng.randf() * 0.34) / reach
				var gy: float = (0.02 + (rng.randf() - 0.42) * 0.44) / reach
				var rr: float = 0.017 + rng.randf() * 0.026
				_ball(_shell, rr, Vector3(cos(ang) * rad * cloud.x, gy * cloud.y,
					sin(ang) * rad * cloud.z), ghost_0 if (i % 2 == 0) else ghost_1)

		"witness":
			# There is no view from nowhere. The diagram grows a shell with no front
			# — it opens toward whoever is asking — and where the middle body stood
			# there is a polished plate under a warm rim, returning the room.
			_superposition.visible = false
			var slate: StandardMaterial3D = _surface(Color(0.26, 0.27, 0.30), 0.82, 0.05, 0.0)
			var t3: float = 0.016
			# Wide enough to clear the basis states, so the shell encloses the whole
			# diagram and the only face it lacks is the one you are standing at.
			var wh: float = SEP + R_STATE + 0.06
			_slab(_shell, Vector3(wh * 2.0, t3, 0.28), Vector3(0, -0.19, -0.05), slate)
			_slab(_shell, Vector3(wh * 2.0, 0.40, t3), Vector3(0, 0.01, -0.18), slate)
			for ws in signs:
				_slab(_shell, Vector3(t3, 0.40, 0.28), Vector3(ws * wh, 0.01, -0.05), slate)
			var plate: StandardMaterial3D = _surface(Color(0.94, 0.96, 0.99), 0.04, 1.0, 0.55)
			_slab(_shell, Vector3(0.32, 0.30, 0.014), Vector3(0, 0.01, 0.02), plate)
			var rim: StandardMaterial3D = _surface(Color(0.98, 0.88, 0.58), 0.28, 0.5, 1.8)
			# The warm rim is the thing that says the opening is FOR you. It was
			# 11 mm — the same hairline problem as seam's posts, and the same fix:
			# reach lengthens it, this thickens it, and it is exactly 0.011 at
			# specimen where it was already readable.
			var rim_t: float = 0.011 * reach
			for ry in signs:
				_slab(_shell, Vector3(wh * 2.0, rim_t, rim_t), Vector3(0, 0.01 + ry * 0.20, 0.09), rim)
			for rx in signs:
				_slab(_shell, Vector3(rim_t, 0.40, rim_t), Vector3(rx * wh, 0.01, 0.09), rim)

# ── proportion ───────────────────────────────────────────────────────────────

## HOW MUCH OF THE FRAME THE REMAINDER IS ALLOWED TO CLAIM. The measured repair:
## see the REPAIR header. `remainder` is the argument axis and `vantage` is only
## the register, but held at chamber the five remainder values differed from each
## other by 0.71%-1.57% while vantage moved 9%-13% — the frame shouting over the
## thing inside it. This is the missing proportion. The remainder geometry grows
## with the staging it stands in, so the argument keeps its share of the picture
## wherever the picture is taken from.
##
## The numbers are bounded by the walls, not chosen for taste. At chamber, 1.55
## puts `twin` — the widest of the five bodies — at 2.145 m against an inner wall
## face at 2.23 m. Past that the argument leaves its own room, the bounding box
## grows, the camera pulls back, and the score goes straight back to `vantage`.
## At stele, 1.2 keeps `seam`'s faces inside the slab they are cut from.
##
## 1.0 at specimen is load-bearing, not a default: specimen was never the problem,
## and every specimen variant must render pixel-identical to the run that measured
## the fault. That is the negative test.
func _reach() -> float:
	match vantage:
		"stele":
			return 1.2
		"chamber":
			return 1.55
	return 1.0


## `haze`'s cloud fitted to the room it is drifting in. Identity everywhere but
## chamber, so specimen and stele keep the scatter they shipped with. At chamber
## the room lost two metres of depth (see _stage_vantage), and a cloud that used
## to have 4.6 m to spread through would now hang out through the back wall and
## out the open front — geometry outside the room inflates the bounding box the
## sweep frames by, which is the exact leak being repaired. 0.90 x 0.45 seats the
## outermost ghost at 2.19 m against a 2.23 m wall and 1.21 m against a 1.23 m
## one, so all five chamber variants finally share ONE frame and their deltas are
## about the argument rather than about the camera.
func _cloud_fit() -> Vector3:
	if vantage == "chamber":
		return Vector3(0.90, 1.0, 0.45)
	return Vector3.ONE


# ── small builders ───────────────────────────────────────────────────────────

static func _surface(c: Color, rough: float, metal: float, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m

func _slab(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _ball(parent: Node3D, r: float, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

## Alias expansion happens in the kin's file; the allow-list check happens here. A
## word that survives neither keeps whatever value is already set, so a typo in a
## map token renders the shipped diagram rather than an empty Shell that looks like
## an axis doing nothing.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = str(raw).strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback

## MAP CONFIG — `superposition_display#remainder:twin#vantage:stele`.
## ONLY the two axis words are read. This method was a bare `pass`, so every token
## any map has ever sent it did nothing; a generic "set whatever property the key
## names" loop would quietly hand map data the power to write `scale`, `visible`
## or `position` on an artifact that never offered them. curation_station's
## {"emissive": false} still lands here and still does exactly nothing.
## GridInteractablesComponent calls this deferred, after _ready() has already built
## one lineage, so a word that changes anything has to rebuild.
func apply_grid_config(config_data: Dictionary) -> void:
	if not (config_data.has("remainder") or config_data.has("vantage")):
		return
	if config_data.has("remainder"):
		remainder = _pick_axis(
			RemainderAxis.remainder_name(str(config_data["remainder"])), REMAINDERS, remainder)
	if config_data.has("vantage"):
		vantage = _pick_axis(
			RemainderAxis.vantage_name(str(config_data["vantage"])), VANTAGES, vantage)
	if _body != null and (remainder != _built_remainder or vantage != _built_vantage):
		_apply_staging()
