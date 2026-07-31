# escher_staircase.gd
# An "impossible staircase" inspired by Escher/Penrose
# Locally coherent, globally impossible
# Visual demonstration of Gödel's incompleteness:
# Each local step is valid, but the global structure is paradoxical
#
# You can walk "up" forever and end where you started
# Or walk "down" forever and also end where you started

extends Node3D

class_name EscherStaircase

# @identity
# essence: each step locally valid; global loop returns to start — the Penrose stairs
# desire: climb "up" forever and arrive where you started — feel the paradox in your legs
# critical_parameter: steps_per_side — more steps make the impossibility more convincing. seam — WHERE the impossibility is put: smoothed into one quiet descending side and never named (none), gathered into a single closing riser you can point at (hairline), refused, so the loop is left open with two cut ends facing each other (gap), that same open interval rigged with a tower and a landing (scaffold), or spread evenly into all sixteen joints so the ring comes out level and no joint can be blamed (field).
# triggers: climb_step() advances the highlight; completing a full loop fires paradox_completed
# emerges: the visceral understanding that local consistency does not guarantee global consistency
# needs: VR step-climbing interaction [missing] — has climb_step() API but no physical trigger
# relationships: visualizes godel_statement_plaque (local proof steps valid, global conclusion impossible); contrasts russell_set_box (self-reference vs spatial paradox)
# truth: locally coherent does not mean globally possible — this is Godel's incompleteness made architectural

signal step_taken(step_index: int, direction: String)
signal paradox_completed()

## Staircase parameters
@export var steps_per_side: int = 4
@export var step_width: float = 0.4
@export var step_height: float = 0.15
@export var step_depth: float = 0.3
@export var inner_radius: float = 0.8

## Colors
@export var step_color: Color = Color(0.7, 0.7, 0.75)
@export var rail_color: Color = Color(0.3, 0.25, 0.2)
@export var glow_color: Color = Color(0.5, 0.8, 1.0)

## Animation
@export var rotate_view: bool = true
@export var rotation_speed: float = 0.1

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-31) — ONE AXIS, TWO FILES.
# florensky_sphere.gd carries the same `seam` token with the same five values, and
# this file preloads it for the word list. The pair is one argument in two bodies:
# paraconsistency, where the contradiction is everywhere and survives, beside
# impossible geometry, where the contradiction is at one joint and hides. What they
# share is not WHETHER there is a contradiction — both say yes — but WHERE IT IS PUT.
#
#   seam   WHERE THE IMPOSSIBILITY IS PUT
#          none · hairline · gap · scaffold · field
#
# WHY THIS, AND NOT A REGISTER OR AN EXPOSURE AXIS. This is not furniture in a room
# and not an instrument you operate. It is an argument that local validity does not
# add up to global possibility, and an impossible figure has one structural fact no
# other artifact tier has: it only works from one place. The trick has to fail
# somewhere, and what the object does at the angles where it fails is the whole
# question. Today it does the one thing that is not a decision — it hides. The
# fourth side's height is quietly lerped back to zero with a squared ease
# (_create_step, side 3), so the impossible interval is smeared across a quarter of
# the figure as a gentle downward ramp, unnamed and unmarked. That is the machine's
# habit exactly as doc/CONSERVATION_OF_THE_IRREDUCIBLE.md §3 describes it: the
# substitution tucked just below where you would catch it. §5 says the pile cannot
# be made to vanish, only moved; §6 says prefer the worn, show the seam. This axis
# is that freedom made settable.
#
# WHAT EACH VALUE DOES WITH THE PART IT CANNOT REPRESENT — the sieve's third
# question, which is what decides whether this is a family or a menu:
#   none      HIDES it.      Sixteen steps, one side sagging back to the floor on a
#                            quadratic ease. Nothing marked. The figure looks
#                            finished and the lie is a curve.
#   hairline  BOUNDS it.     Every one of the sixteen steps rises by exactly
#                            step_height, and the entire accumulated climb is undone
#                            at ONE joint — a single black riser the full height of
#                            the stair, with the two treads either side of it
#                            inlaid dark. One undecidable sentence; the rest of the
#                            arithmetic fine. Gödel, not vandalism.
#   gap       LEAVES A HOLE. The figure refuses to build the lie: the fourth side is
#                            not there. Twelve steps climb honestly and stop, and
#                            the two cut ends face each other across empty air at
#                            different heights. It does not close, and says so by
#                            not closing.
#   scaffold  BUILDS THERE.  That same open quarter, rigged — posts the full height
#                            of the interval, a ledger for every tread the stair
#                            could not lay, crossed bracing, and a landing hung in
#                            the span it cannot cross. The impossible interval
#                            becomes a place to stand rather than a defeat.
#   field     EXHIBITS it.   The descent is divided by sixteen and paid at every
#                            joint, so the ring comes out perfectly level and each
#                            joint is a dark blade standing above its tread. You
#                            climb sixteen risers and gain nothing. Nobody can point
#                            at the guilty joint because they all are.
#
# seam=none is the legacy lineage, step for step: the same _total_steps, the same
# four sides, the same `lerp(target_height, 0.0, wrap_factor * wrap_factor)` on side
# 3, the same four Label3Ds and highlight sphere, and _create_seam() adds nothing.
# All shipped placements are untouched.
#
# WHAT IT COST. The height of a step is no longer readable from one arithmetic line
# — four of the five values route through _seam_step_y() instead. And none's smooth
# sag, which used to be merely how the loop was closed, is now legible as a CHOICE
# to smooth it. This object can no longer be innocent about its fourth side.
#
# NOT ROUTED THROUGH seam: the Gödel reading on the boards, the "locally coherent /
# globally impossible" line, the step and paradox signals, _total_steps, and the
# climb/descend wrap that returns you to the start. Every height these variants
# gather, cut or divide is read out of step_height and steps_per_side, never
# invented. This pass stages the argument; it does not edit the mathematics.
# ─────────────────────────────────────────────────────────────────────────────
#
# ─────────────────────────────────────────────────────────────────────────────
# REPAIR (2026-07-31, same day) — THE PROMOTION HAD MADE THE FIGURE POSSIBLE.
# Two reviewers, reading different lenses, landed on the same fault and they were
# right. The prose above was correct; the code under it was not. _seam_step_y()
# returned a straight `global_index * step_height` for hairline, gap and scaffold —
# a monotonic run, which is an ORDINARY spiral stair — and a single constant for
# field, which is an ORDINARY level walkway. Measured against the legacy build,
# sides 0, 1 and 2 were byte-identical anyway; the only thing four of the five
# values actually did was UN-SAG side 3. The Penrose impossibility survived on one
# setting out of five while all five printed "Globally impossible" and all five
# fired paradox_completed. Making the limit settable had made the limit optional.
#
# WHAT THE REPAIR RESTORES. One quantity is the impossibility and every value now
# spends exactly it: _ring_rise() = steps_per_side * 4 * step_height, the rise of a
# full circuit — the amount by which a closed ring of honest risers fails to close.
#
#   none      SMEARS  _ring_rise() across a quarter as a quadratic sag.  (untouched)
#   hairline  BINDS   _ring_rise() into one joint: the seventeenth tread, which the
#                     rule says IS the first tread, is drawn at _ring_rise() directly
#                     above the first tread, and a single riser of that full height
#                     stands between them. Both sentences about the same tread, drawn.
#   gap       REFUSES it: the fourth side is not built and the two cut ends are lit
#                     at their own two heights, carried into the empty quarter as two
#                     datum rails that run parallel and never meet.
#   scaffold  STANDS  in it: posts the full _ring_rise(), ledgers at the heights the
#                     four missing treads would have had — the lawful continuation,
#                     rigged, climbing away and provably never coming back down.
#   field     DIVIDES it by sixteen: every tread is TILTED so it climbs step_height
#                     along its own length, and every joint drops step_height. Sixteen
#                     risers climbed; the ring closes level. That is the sentence the
#                     docstring already wrote and the code never implemented.
#
# Sixteen honest risers still exist under every value. What varies is where the
# sixteen-riser debt is paid. Nothing about the Gödel reading, the boards, the truth
# statement or the arithmetic changed — only the staging, which is what it was
# always supposed to be.
#
# The ledger got honest too. gap and scaffold have no circuit, so climb_step() no
# longer wraps through four positions that do not exist and then congratulates you
# on a loop: the run holds at the cut end, says the ends stand N risers apart, and
# fires paradox_completed once, because on an open ring the refusal to close IS the
# completed demonstration. seam=none keeps the legacy wrap exactly.
# ─────────────────────────────────────────────────────────────────────────────

## THE VOCABULARY LIVES IN florensky_sphere.gd, ONCE — the kin artifact whose
## @identity named these five words before either of them could build them. This
## file preloads that script rather than restating the list, so the two cannot drift
## apart on what the words are. The @export_enum below is the one thing that has to
## be written out twice (an annotation argument must be a literal), and
## normalise_seam() is what keeps that from mattering: a word in one annotation and
## not in the shared list falls back to the legacy look instead of rendering
## something the registry never declared. The literal below is also what
## tools/apply_dna_block.py derives this artifact's registry declaration from.
const SeamAxis = preload("res://commons/interfaces/foundations/florensky_sphere.gd")

## THE AXIS — where the impossibility is put (see the promotion note above).
## none is the legacy lineage and smooths it away; the other four give it an address.
@export_enum("none", "hairline", "gap", "scaffold", "field") var seam: String = "none"

## The side that carries the impossible interval today, and therefore the side gap
## and scaffold decline to build. Read out of _create_step: side 3 is the one whose
## height is lerped back to the floor.
const SEAM_OPEN_SIDE := 3

const SEAM_DARK := Color(0.02, 0.02, 0.03)
const SEAM_BUILD := Color(0.58, 0.44, 0.24)

# Internal
var _steps: Array[MeshInstance3D] = []
var _current_step: int = 0
var _total_steps: int = 0
var _steps_climbed: int = 0
var _animation_time: float = 0.0
var _paradox_label: Label3D

## Every node `seam` owns, so a `#seam:` token arriving after _ready() can free
## exactly what it built. Empty for the whole legacy lineage.
var _seam_nodes: Array[Node] = []
var _built: bool = false

## Set once, on an open ring (gap / scaffold), when the walk has reached a cut end
## and there is nowhere lawful to put the next tread. Always false under the legacy
## lineage, where the wrap still runs untouched.
var _open_run_declared: bool = false

func _ready() -> void:
	_total_steps = steps_per_side * 4
	_create_staircase()
	_create_seam()
	_create_labels()
	_create_highlight()
	_built = true
	print("EscherStaircase: Ready — 'Locally valid, globally impossible'")

func _create_staircase() -> void:
	# Create 4 sides of stairs that form an impossible loop
	# The trick: each side goes "up" but connects back to start

	for side in range(4):
		var side_rotation = side * PI / 2

		# THE AXIS bites first here. gap and scaffold refuse to build the side that
		# carries the lie, so the loop is left genuinely open — twelve steps, not
		# sixteen. _total_steps stays at the full circuit because it is the RULE's
		# count, not the geometry's, and the difference between them is the whole
		# argument; the walk no longer pretends otherwise (see _walk_open_run).
		if side == SEAM_OPEN_SIDE and (seam == "gap" or seam == "scaffold"):
			continue

		for i in range(steps_per_side):
			var step = _create_step(side, i)
			_steps.append(step)
			add_child(step)

func _create_step(side: int, index: int) -> MeshInstance3D:
	var step = MeshInstance3D.new()
	step.name = "Step_%d_%d" % [side, index]
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(step_width, step_height, step_depth)
	step.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	# Alternate colors slightly for visibility
	var shade = 0.9 + (index % 2) * 0.1
	mat.albedo_color = step_color * shade
	mat.metallic = 0.1
	mat.roughness = 0.8
	step.material_override = mat
	
	# Position the step
	# Each step goes "up" but we use perspective tricks
	var angle = (side * steps_per_side + index) * (TAU / _total_steps)
	var radius = inner_radius + step_depth / 2
	
	# The "impossible" part: height increases linearly but wraps
	# We fake it by making each side appear to go up relative to viewer
	var apparent_height = index * step_height
	
	# Position in a square loop
	var side_angle = side * PI / 2
	var local_progress = float(index) / float(steps_per_side)
	
	var pos = Vector3.ZERO
	match side:
		0:  # Front side (going right)
			pos.x = -inner_radius + local_progress * inner_radius * 2
			pos.z = inner_radius
			pos.y = apparent_height
		1:  # Right side (going back)
			pos.x = inner_radius
			pos.z = inner_radius - local_progress * inner_radius * 2
			pos.y = apparent_height + steps_per_side * step_height
		2:  # Back side (going left)
			pos.x = inner_radius - local_progress * inner_radius * 2
			pos.z = -inner_radius
			pos.y = apparent_height + 2 * steps_per_side * step_height
		3:  # Left side (going front) - wraps back to start height
			pos.x = -inner_radius
			pos.z = -inner_radius + local_progress * inner_radius * 2
			# This is where the impossibility happens
			# Heights should be high, but we lerp back to 0
			var target_height = apparent_height + 3 * steps_per_side * step_height
			var wrap_factor = local_progress
			pos.y = lerp(target_height, 0.0, wrap_factor * wrap_factor)

	# THE AXIS bites second here. Under seam=none the height above stands exactly as
	# it always has, including the squared ease on side 3. The other four values do
	# not touch the plan — the square, the radius, the rotations are untouched — they
	# only decide what the risers add up to.
	if seam != "none":
		pos.y = _seam_step_y(side, index)

	step.position = pos

	# THE AXIS bites third here, and only for field. field's ring is level, so the
	# climb has to live inside the treads: each one is tilted about its own depth
	# axis until its leading edge stands exactly step_height above its trailing edge
	# (asin, so the rise end-to-end is step_height and not merely proportional to it).
	# Sixteen treads that each climb one riser, and — because every tread centre is at
	# the same height — sixteen joints that each drop one riser. Every other value,
	# the legacy lineage included, leaves the tread flat and sets yaw alone.
	#
	# Composed as a basis rather than an euler triple on purpose: tilt-then-yaw has to
	# hold whatever rotation_order is set to, and a tread that tilted about the world
	# axis instead of its own would climb sideways on two of the four sides.
	if seam == "field":
		step.basis = Basis(Vector3.UP, float(side_angle)) * Basis(Vector3.BACK, _field_tilt())
	else:
		step.rotation.y = side_angle

	return step

func _create_labels() -> void:
	# Title
	var title = Label3D.new()
	title.text = "Escher Staircase"
	title.font_size = 32
	title.position = Vector3(0, 2.5, 0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color.WHITE
	title.outline_size = 5
	title.outline_modulate = Color.BLACK
	add_child(title)
	
	# Paradox explanation
	_paradox_label = Label3D.new()
	_paradox_label.text = "Locally coherent\nGlobally impossible"
	_paradox_label.font_size = 20
	_paradox_label.position = Vector3(0, 2.1, 0)
	_paradox_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_paradox_label.modulate = Color(0.8, 0.8, 0.8, 0.9)
	_paradox_label.outline_size = 4
	_paradox_label.outline_modulate = Color.BLACK
	_paradox_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_paradox_label)
	
	# Step counter
	var counter = Label3D.new()
	counter.name = "StepCounter"
	counter.text = "Steps climbed: 0"
	counter.font_size = 18
	counter.position = Vector3(0, -0.5, 0)
	counter.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	counter.modulate = Color(0.7, 0.7, 0.7)
	counter.outline_size = 3
	counter.outline_modulate = Color.BLACK
	add_child(counter)
	
	# Gödel connection
	var godel_note = Label3D.new()
	godel_note.text = "Like Gödel's theorem:\nEvery local step is valid.\nThe global conclusion is impossible."
	godel_note.font_size = 14
	godel_note.position = Vector3(0, -1.0, 0)
	godel_note.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	godel_note.modulate = Color(0.6, 0.6, 0.6, 0.8)
	godel_note.outline_size = 3
	godel_note.outline_modulate = Color.BLACK
	godel_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(godel_note)

	# THE AXIS speaks here, and only when it has something to say. The legacy build
	# has exactly four Label3Ds and keeps exactly four — this returns before adding
	# a fifth. The line it adds does not restate the claim above it; it says WHERE
	# this particular build put the sixteen risers it owes, so that "Globally
	# impossible" is checkable against the object rather than merely asserted by it.
	if seam == "none":
		return
	var seam_note = Label3D.new()
	seam_note.name = "SeamNote"
	seam_note.text = _seam_sentence()
	seam_note.font_size = 13
	seam_note.position = Vector3(0, 1.72, 0)
	seam_note.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	seam_note.modulate = Color(0.62, 0.68, 0.72, 0.85)
	seam_note.outline_size = 3
	seam_note.outline_modulate = Color.BLACK
	seam_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(seam_note)

## What this build did with the sixteen risers it owes. Read out of steps_per_side,
## so a staircase built with a different side length still says something true.
func _seam_sentence() -> String:
	var n: int = steps_per_side * 4
	match seam:
		"hairline":
			return "%d honest risers.\nOne joint takes back all %d." % [n, n]
		"gap":
			return "The fourth side is not built.\nThe cut ends stand %d risers apart." % _cut_end_risers()
		"scaffold":
			return "The fourth side is not built.\nThe rig stands in the interval\nand still does not cross it."
		"field":
			return "Each tread climbs one riser.\nEach joint takes one back.\n%d risers up, and the ring is level." % n
	return ""

func _create_highlight() -> void:
	# Glowing marker for current step
	var highlight = MeshInstance3D.new()
	highlight.name = "StepHighlight"
	var mesh = SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	highlight.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = glow_color
	mat.emission_enabled = true
	mat.emission = glow_color
	mat.emission_energy_multiplier = 2.0
	highlight.material_override = mat
	
	add_child(highlight)
	_update_highlight()

func _update_highlight() -> void:
	var highlight = get_node_or_null("StepHighlight")
	if highlight and _current_step < _steps.size():
		highlight.position = _steps[_current_step].position + Vector3(0, step_height, 0)

func _process(delta: float) -> void:
	_animation_time += delta
	
	if rotate_view:
		rotation.y += delta * rotation_speed
	
	# Pulse the current step
	if _current_step < _steps.size():
		var step = _steps[_current_step]
		var mat = step.material_override as StandardMaterial3D
		if mat:
			var pulse = sin(_animation_time * 3.0) * 0.5 + 0.5
			mat.emission_enabled = true
			mat.emission = glow_color * pulse * 0.3

func climb_step() -> void:
	# Turn off glow on current step
	if _current_step < _steps.size():
		var mat = _steps[_current_step].material_override as StandardMaterial3D
		if mat:
			mat.emission_enabled = false

	# THE AXIS bites in the ledger too. gap and scaffold have no fourth side, so
	# there is no circuit to wrap: walking off the last tread used to advance through
	# four positions that do not exist and then announce a completed loop. Now the
	# run holds at the cut end and says why. Every other value — none included —
	# falls straight through to the legacy wrap below, unchanged.
	if _ring_is_open():
		_walk_open_run(1)
		return

	_current_step = (_current_step + 1) % _total_steps
	_steps_climbed += 1
	
	_update_highlight()
	_update_counter()
	
	emit_signal("step_taken", _current_step, "up")
	
	# Check for paradox completion (full loop)
	if _current_step == 0 and _steps_climbed > 0:
		emit_signal("paradox_completed")
		print("EscherStaircase: PARADOX — climbed %d steps 'up' and returned to start!" % _steps_climbed)
		_paradox_label.text = "PARADOX COMPLETE\nClimbed %d steps up\nReturned to start" % _steps_climbed

func descend_step() -> void:
	if _current_step < _steps.size():
		var mat = _steps[_current_step].material_override as StandardMaterial3D
		if mat:
			mat.emission_enabled = false

	# Same refusal downward: on an open ring there is nothing below the first tread
	# either, and the loop cannot be walked backwards into existence.
	if _ring_is_open():
		_walk_open_run(-1)
		return

	_current_step = (_current_step - 1 + _total_steps) % _total_steps
	_steps_climbed += 1
	
	_update_highlight()
	_update_counter()
	
	emit_signal("step_taken", _current_step, "down")
	
	if _current_step == 0 and _steps_climbed > 0:
		emit_signal("paradox_completed")
		print("EscherStaircase: PARADOX — descended %d steps 'down' and returned to start!" % _steps_climbed)

func _update_counter() -> void:
	var counter = get_node_or_null("StepCounter")
	if counter:
		counter.text = "Steps climbed: %d" % _steps_climbed

func reset() -> void:
	_current_step = 0
	_steps_climbed = 0
	_open_run_declared = false
	_update_highlight()
	_update_counter()
	_paradox_label.text = "Locally coherent\nGlobally impossible"

## gap and scaffold. The walk advances while treads exist and holds at the cut end,
## which is not a failure to implement a loop — it is the loop refusing. The signal
## still fires, once, because on an open ring the demonstration IS the refusal: you
## have walked every tread there is and the ring did not come back. Firing it on a
## silent wrap through four absent positions, as this used to, was the lie.
func _walk_open_run(dir: int) -> void:
	var last: int = _steps.size() - 1
	var target: int = _current_step + dir
	if target >= 0 and target <= last:
		_current_step = target
		_steps_climbed += 1
		_update_highlight()
		_update_counter()
		emit_signal("step_taken", _current_step, "up" if dir > 0 else "down")
		return

	_update_highlight()
	_update_counter()
	if _open_run_declared:
		return
	_open_run_declared = true
	emit_signal("paradox_completed")
	print("EscherStaircase: NO CLOSURE — walked %d treads to the cut end; the fourth side cannot be built" % _steps_climbed)
	if _paradox_label:
		_paradox_label.text = "THE RUN DOES NOT CLOSE\nWalked %d treads to the cut end\nThe ends stand %d risers apart" % [_steps_climbed, _cut_end_risers()]

# ─────────────────────────────────────────────────────────────────────────────
# THE SEAM — everything the axis owns, in one place.
# ─────────────────────────────────────────────────────────────────────────────

## MAP CONFIG — `escher_staircase#seam:gap`. GridInteractablesComponent calls this
## deferred, so it lands AFTER _ready(). Both guards are load-bearing: a placement
## that names no seam returns before touching anything, and a placement that names
## the seam already in force rebuilds nothing. An unguarded rebuild here is the
## failure that has broken shipped placements in this corpus before.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("seam"):
		return
	var before: String = seam
	seam = SeamAxis.normalise_seam(str(config_data["seam"]), seam)
	if seam == before or not _built:
		return
	_rebuild_seam()
	print("EscherStaircase: seam=%s" % seam)

## Step heights and step COUNT both change between values, so this rebuilds the
## whole figure rather than a seam overlay. The climb ledger resets with it — a
## staircase that changed shape under you has no honest step count to carry over.
func _rebuild_seam() -> void:
	_steps.clear()
	_seam_nodes.clear()
	_current_step = 0
	_steps_climbed = 0
	_open_run_declared = false
	_paradox_label = null
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_total_steps = steps_per_side * 4
	_create_staircase()
	_create_seam()
	_create_labels()
	_create_highlight()

## THE ONE QUANTITY. A ring of steps_per_side * 4 treads, each rising step_height,
## comes back to its start steps_per_side * 4 * step_height too high. That number is
## the impossibility. It is not a new quantity — it is steps_per_side and step_height
## read back — and every value of the axis spends exactly it, differing only in where.
func _ring_rise() -> float:
	return float(steps_per_side * 4) * step_height

## The height a level ring sits at: the mean of the honest run, so field's flat
## circuit occupies the same band of the frame the climbing one did rather than
## collapsing to the floor and reading as a different, smaller object.
func _ring_mid() -> float:
	return float(steps_per_side * 4 - 1) * step_height * 0.5

## The tilt that makes ONE tread climb exactly step_height from trailing edge to
## leading edge. asin, not atan: the rise is measured along the tread's own length,
## which is what "each tread is one riser" has to mean if the joints are to absorb
## exactly one riser each. Clamped so an absurd step_height/step_width cannot NaN.
func _field_tilt() -> float:
	if step_width <= 0.0:
		return 0.0
	return asin(clampf(step_height / step_width, -0.98, 0.98))

## gap and scaffold: the run is cut, not closed.
func _ring_is_open() -> bool:
	return seam == "gap" or seam == "scaffold"

## How far apart the two cut ends stand, in risers, when the fourth side is not
## built. The last built tread is at (steps_per_side * 3 - 1) risers; the first is on
## the floor. Used by the boards and by the walk, so both say the same number.
func _cut_end_risers() -> int:
	return steps_per_side * 3 - 1

## The height of a step under a non-legacy seam. Everything here is read out of
## step_height and steps_per_side; no new quantity is introduced.
##   hairline / gap / scaffold — every tread rises exactly one riser above the last,
##     so the run is locally clean everywhere it exists and the entire _ring_rise()
##     debt is left to the one joint that has to close it (hairline) or to the
##     absence where that joint would be (gap, scaffold). Note that for sides 0, 1
##     and 2 this is the legacy height to the last decimal; only side 3 — the side
##     that used to sag secretly back to the floor — is different, and under gap and
##     scaffold it is not built at all.
##   field — the ring is LEVEL, and the climb moves into the treads: _create_step
##     tilts each one by _field_tilt() so it rises step_height along its own length,
##     and because every tread centre sits at _ring_mid() every joint drops
##     step_height. Sixteen risers climbed, sixteen risers paid, nothing gained. The
##     ring closes because the debt was divided by sixteen — NOT because it was
##     waived, which is what returning a bare constant here used to do.
func _seam_step_y(side: int, index: int) -> float:
	if seam == "field":
		return _ring_mid()
	return float(side * steps_per_side + index) * step_height

## Where the impossibility is put. none adds nothing — the legacy quadratic ease on
## side 3 is already the answer "nowhere in particular", and this function returning
## early is what makes the default the shipped build.
func _create_seam() -> void:
	if _steps.is_empty():
		return
	match seam:
		"hairline":
			_build_closing_riser()
		"gap":
			_build_cut_ends()
		"scaffold":
			_build_cut_ends()
			_build_scaffold()
		"field":
			_build_rift_blades()

## hairline — one joint carries everything, and it is BUILT, not marked.
##
## The rule this staircase runs on says two things about the tread that comes after
## the last one. It says that tread is the first tread, because the ring closes. It
## says that tread stands one riser above the last, which puts it _ring_rise() above
## the floor. Both are drawn: a seventeenth tread in the first tread's exact place in
## plan, _ring_rise() higher, with a single riser of that full height standing
## between them. The other fifteen joints show a riser one step_height tall — the
## back face of the tread above — so the comparison is on the object and needs no
## caption. Fifteen ordinary sentences and one that decides nothing.
##
## The two treads the joint identifies are inlaid dark, so the claim is named at both
## ends rather than merely occurring at one.
func _build_closing_riser() -> void:
	var last: MeshInstance3D = _steps[_steps.size() - 1]
	var first: MeshInstance3D = _steps[0]
	var rise: float = _ring_rise()

	# The seventeenth tread, which is the first tread, one riser above the last.
	var ghost := MeshInstance3D.new()
	ghost.name = "SeamClosingTread"
	var gb := BoxMesh.new()
	gb.size = Vector3(step_width, step_height, step_depth)
	ghost.mesh = gb
	ghost.material_override = _seam_material(SEAM_DARK)
	ghost.rotation.y = first.rotation.y
	ghost.position = Vector3(
		first.position.x,
		first.position.y + rise,
		first.position.z)
	_add_seam_node(ghost)

	# The riser between the first tread and itself. Sized like the fifteen others and
	# rise tall — from the top of the tread on the floor to the top of the tread in
	# the air, which is the whole climb standing in the width of one step.
	var plate := MeshInstance3D.new()
	plate.name = "SeamClosingRiser"
	var box := BoxMesh.new()
	box.size = Vector3(step_width * 0.9, rise, step_depth * 0.7)
	plate.mesh = box
	plate.material_override = _seam_material(SEAM_DARK)
	plate.rotation.y = first.rotation.y
	plate.position = Vector3(
		first.position.x,
		first.position.y + step_height * 0.5 + rise * 0.5,
		first.position.z)
	_add_seam_node(plate)

	var joints: Array[MeshInstance3D] = [first, last]
	for s in joints:
		var inlay := MeshInstance3D.new()
		inlay.name = "SeamInlay_%s" % s.name
		var ib := BoxMesh.new()
		ib.size = Vector3(step_width * 0.84, 0.014, step_depth * 0.84)
		inlay.mesh = ib
		inlay.material_override = _seam_material(SEAM_DARK)
		inlay.rotation.y = s.rotation.y
		inlay.position = s.position + Vector3(0, step_height * 0.5 + 0.008, 0)
		_add_seam_node(inlay)

## The two faces where the run was cut, LIT rather than merely darkened — an unlit
## severed end reads as an object somebody forgot to finish, and the whole point of
## gap is that the not-finishing is the argument. gap and scaffold share these,
## because scaffold does not repair the hole, it moves into it.
func _build_cut_ends() -> void:
	var last: MeshInstance3D = _steps[_steps.size() - 1]
	var first: MeshInstance3D = _steps[0]
	# The last tread is cut across its own run, so its severed face is forward along
	# its travel axis. The first tread is not: the ring turns a corner there, and the
	# quarter that is missing arrives at its DEPTH side, not at its heel. Aiming both
	# caps down the same axis, as this used to, put one of them outside the square
	# pointing at nothing. The face is turned a quarter with it.
	_cut_face(last, last.transform.basis.x * (step_width * 0.5 + 0.03), 0.0)
	_cut_face(first, -first.transform.basis.z * (step_depth * 0.5 + 0.03), PI * 0.5)
	_build_cut_datums()

func _cut_face(step: MeshInstance3D, along: Vector3, yaw_turn: float) -> void:
	var cap := MeshInstance3D.new()
	cap.name = "SeamCut_%s" % step.name
	var box := BoxMesh.new()
	box.size = Vector3(0.055, step_height * 3.2, step_depth * 1.6)
	cap.mesh = box
	cap.material_override = _seam_light(glow_color)
	cap.rotation.y = step.rotation.y + yaw_turn
	# Lifted so the face stands proud of its own tread — a severed end, not a kerb.
	cap.position = step.position + along + Vector3(0, step_height * 1.1, 0)
	_add_seam_node(cap)

## The mismatch, carried into the empty quarter so it can be seen rather than
## inferred. Each cut end sends a lit datum rail the length of the side that is not
## there, at its own height. The two rails run parallel across the same air, one on
## the floor and one _cut_end_risers() risers up, and they do not meet — which is the
## whole content of "these ends cannot be joined", stated by two lines and a hole.
## No tread is drawn between them: the rails are light, not something to stand on.
func _build_cut_datums() -> void:
	var span: float = inner_radius * 2.0
	var ends: Array[float] = [-inner_radius, inner_radius]
	var heights: Array[float] = [
		_steps[0].position.y + step_height * 0.5,
		_steps[_steps.size() - 1].position.y + step_height * 0.5]
	for i in range(heights.size()):
		var mat: StandardMaterial3D = _seam_light(glow_color)
		var rail := MeshInstance3D.new()
		rail.name = "SeamDatum_%d" % i
		var rb := BoxMesh.new()
		# Substantial on purpose. These two lines ARE gap's argument — the figure has
		# nothing else in that quarter — and a hairline that survives neither the
		# capture nor the far side of the room would leave the value asserting an
		# interval nobody can see.
		rb.size = Vector3(0.08, 0.08, span)
		rail.mesh = rb
		rail.material_override = mat
		rail.position = Vector3(-inner_radius, heights[i], 0.0)
		_add_seam_node(rail)

		# A tick at each end of the rail, so a level reads as a level and not as a
		# stray beam — the drafting convention for "this height, and it stops here".
		for e in range(ends.size()):
			var tick := MeshInstance3D.new()
			tick.name = "SeamDatumTick_%d_%d" % [i, e]
			var tb := BoxMesh.new()
			tb.size = Vector3(0.08, step_height * 2.4, 0.08)
			tick.mesh = tb
			tick.material_override = mat
			tick.position = Vector3(-inner_radius, heights[i], ends[e])
			_add_seam_node(tick)

## scaffold — the open quarter, rigged. Three posts the full height of the interval,
## one ledger for every tread the stair could not lay, crossed bracing, and a landing
## hung at the middle of the span. Nothing here closes the loop; it makes the
## not-closing a place to stand, which is the difference between treating a limit as
## a defeat and treating it as a habitat.
func _build_scaffold() -> void:
	# The rig is keyed to the interval, not to whatever the last tread happened to
	# reach: posts the full _ring_rise(), so the scaffold occupies the entire height
	# the ring fails to close by, from the floor the low cut end sits on to the level
	# the high end's continuation would have to reach.
	var htop: float = _ring_rise()
	var sx: float = -inner_radius
	var z0: float = -inner_radius + 0.08
	var z1: float = inner_radius - 0.08
	var mat: StandardMaterial3D = _seam_material(SEAM_BUILD)
	mat.metallic = 0.55
	mat.roughness = 0.45

	var posts: Array[float] = [z0, (z0 + z1) * 0.5, z1]
	for i in range(posts.size()):
		var post := MeshInstance3D.new()
		post.name = "SeamPost_%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.035
		cyl.bottom_radius = 0.035
		cyl.height = htop
		post.mesh = cyl
		post.material_override = mat
		post.position = Vector3(sx, htop * 0.5, posts[i])
		_add_seam_node(post)

	# Ledgers at the heights the four missing treads would have had — the run's lawful
	# continuation, rigged. This is what makes the rig an argument rather than a
	# repair: it carries the rule upward, tread height by tread height, past the top
	# of everything built, and the higher it carries it the further it gets from the
	# floor the ring has to come back to. Nothing here joins the two cut ends.
	for i in range(steps_per_side):
		var led := MeshInstance3D.new()
		led.name = "SeamLedger_%d" % i
		var lb := BoxMesh.new()
		lb.size = Vector3(0.05, 0.05, z1 - z0)
		led.mesh = lb
		led.material_override = mat
		led.position = Vector3(sx, float(3 * steps_per_side + i) * step_height, (z0 + z1) * 0.5)
		_add_seam_node(led)

	_brace(Vector3(sx, 0.04, z0), Vector3(sx, htop * 0.96, z1), mat)
	_brace(Vector3(sx, 0.04, z1), Vector3(sx, htop * 0.96, z0), mat)

	# The landing hangs at the middle of the interval: standing room in the exact
	# place the stair cannot go, at a height that belongs to no tread on either side.
	var deck := MeshInstance3D.new()
	deck.name = "SeamLanding"
	var db := BoxMesh.new()
	db.size = Vector3(step_depth * 1.6, 0.05, (z1 - z0) * 0.55)
	deck.mesh = db
	deck.material_override = mat
	deck.position = Vector3(sx, htop * 0.5, (z0 + z1) * 0.5)
	_add_seam_node(deck)

## field — every joint is a seam, and every joint has something to hold. The treads
## are tilted (see _create_step): each one's leading edge stands step_height above
## its own trailing edge, and every tread centre is at _ring_mid(), so at each of the
## sixteen joints the surface DROPS step_height from the edge you leave to the edge
## you arrive on. A blade stands in each of those drops, straddling the discontinuity
## rather than decorating a flat plate — which is what these blades used to do, when
## the ring underneath them was a constant.
##
## Sixteen risers climbed and the ring comes out level. Nobody can point at the
## guilty joint because they all are, and the object stops being a staircase with a
## flaw and becomes a level circuit made entirely of risers.
func _build_rift_blades() -> void:
	var n: int = _steps.size()
	# Where the tread surfaces meet the joint: half a tread thickness above centre,
	# foreshortened by the tilt. The blade is centred there and stands proud of both.
	var lip: float = step_height * 0.5 * cos(_field_tilt())
	for i in range(n):
		var a: MeshInstance3D = _steps[i]
		var b: MeshInstance3D = _steps[(i + 1) % n]
		var blade := MeshInstance3D.new()
		blade.name = "SeamRift_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(step_width * 0.2, step_height * 2.4, step_depth * 1.28)
		blade.mesh = box
		blade.material_override = _seam_material(SEAM_DARK)
		blade.rotation.y = a.rotation.y
		blade.position = Vector3(
			(a.position.x + b.position.x) * 0.5,
			(a.position.y + b.position.y) * 0.5 + lip,
			(a.position.z + b.position.z) * 0.5)
		_add_seam_node(blade)

## A strut spanning a to b. Built from a basis rather than look_at() because the node
## is not in the tree yet when it is placed.
func _brace(a: Vector3, b: Vector3, mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var blen: float = d.length()
	if blen < 0.01:
		return
	var strut := MeshInstance3D.new()
	strut.name = "SeamBrace"
	var box := BoxMesh.new()
	box.size = Vector3(blen, 0.04, 0.04)
	strut.mesh = box
	strut.material_override = mat
	var x_ax: Vector3 = d.normalized()
	var cr: Vector3 = Vector3.RIGHT.cross(x_ax)
	if cr.length() < 0.001:
		cr = Vector3.UP.cross(x_ax)
	var y_ax: Vector3 = cr.normalized()
	var z_ax: Vector3 = x_ax.cross(y_ax).normalized()
	strut.transform = Transform3D(Basis(x_ax, y_ax, z_ax), (a + b) * 0.5)
	_add_seam_node(strut)

func _add_seam_node(n: Node3D) -> void:
	add_child(n)
	_seam_nodes.append(n)

func _seam_material(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.15
	mat.roughness = 0.7
	return mat

## Lit, for the things gap has to make readable rather than merely present: a severed
## end and a datum line are both claims about height, and a claim nobody can see is
## the habit this axis exists to break.
func _seam_light(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.4
	mat.metallic = 0.0
	mat.roughness = 0.35
	return mat
