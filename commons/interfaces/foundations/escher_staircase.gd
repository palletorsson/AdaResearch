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
#   scaffold  BUILDS THERE.  That same open quarter, rigged — posts, three ledgers,
#                            crossed bracing and a landing hung in the interval the
#                            stair cannot cross. The impossible span becomes a place
#                            to stand rather than a defeat.
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
		# sixteen. _total_steps is deliberately NOT reduced: the ledger still counts
		# a full circuit the geometry no longer provides, and every consumer of
		# _steps already guards on _steps.size().
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
	_update_highlight()
	_update_counter()
	_paradox_label.text = "Locally coherent\nGlobally impossible"

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
	_paradox_label = null
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_total_steps = steps_per_side * 4
	_create_staircase()
	_create_seam()
	_create_labels()
	_create_highlight()

## The height of a step under a non-legacy seam. Everything here is read out of
## step_height and steps_per_side; no new quantity is introduced.
##   hairline / gap / scaffold — every step rises by exactly step_height, so the run
##     is locally AND globally consistent everywhere it exists, and the whole
##     impossibility is left to the single joint (or the single absence) that has to
##     close it. This is the point of bounding a contradiction: to make the rest
##     clean enough that the seam is the only thing left to look at.
##   field — the ring is level. Each step's rise is paid back at its own joint, so
##     sixteen risers add up to nothing and you arrive where you started having
##     climbed the whole way, which is what the boards have always claimed.
func _seam_step_y(side: int, index: int) -> float:
	if seam == "field":
		return step_height
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

## hairline — one joint carries everything. Sixteen honest risers climb to
## steps_per_side * 4 * step_height and a single black blade the full height of the
## stair takes it all back at the closing corner. The two treads it joins are inlaid
## dark so the joint is named at both ends rather than merely occurring there.
func _build_closing_riser() -> void:
	var last: MeshInstance3D = _steps[_steps.size() - 1]
	var first: MeshInstance3D = _steps[0]
	var top: float = maxf(last.position.y, first.position.y) + step_height * 0.5

	var plate := MeshInstance3D.new()
	plate.name = "SeamClosingRiser"
	var box := BoxMesh.new()
	box.size = Vector3(step_depth * 1.15, top + 0.04, step_depth * 0.24)
	plate.mesh = box
	plate.material_override = _seam_material(SEAM_DARK)
	plate.position = Vector3(
		last.position.x,
		(top + 0.04) * 0.5 - 0.02,
		last.position.z + step_width * 0.5 + step_depth * 0.12)
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

## The two faces where the run was cut. Darkened so the missing quarter reads as a
## refusal and not as an object somebody forgot to finish — gap and scaffold share
## them, because scaffold does not repair the hole, it moves into it.
func _build_cut_ends() -> void:
	_cut_face(_steps[_steps.size() - 1], 1.0)
	_cut_face(_steps[0], -1.0)

func _cut_face(step: MeshInstance3D, dir: float) -> void:
	var cap := MeshInstance3D.new()
	cap.name = "SeamCut_%s" % step.name
	var box := BoxMesh.new()
	box.size = Vector3(0.05, step_height * 2.6, step_depth * 1.45)
	cap.mesh = box
	cap.material_override = _seam_material(SEAM_DARK)
	cap.rotation.y = step.rotation.y
	# Lifted so the face stands proud of its own tread — a severed end, not a kerb.
	var along: Vector3 = step.transform.basis.x * ((step_width * 0.5 + 0.025) * dir)
	cap.position = step.position + along + Vector3(0, step_height * 0.6, 0)
	_add_seam_node(cap)

## scaffold — the open quarter, rigged. Three posts, three ledgers, crossed bracing
## and a landing hung at mid height in the interval the stair cannot cross. Nothing
## here closes the loop; it makes the not-closing a place to stand, which is the
## difference between treating a limit as a defeat and treating it as a habitat.
func _build_scaffold() -> void:
	var htop: float = _steps[_steps.size() - 1].position.y + step_height
	if htop <= step_height * 2.0:
		htop = step_height * float(steps_per_side) * 3.0
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

	var levels: Array[float] = [0.30, 0.62, 0.94]
	for i in range(levels.size()):
		var led := MeshInstance3D.new()
		led.name = "SeamLedger_%d" % i
		var lb := BoxMesh.new()
		lb.size = Vector3(0.05, 0.05, z1 - z0)
		led.mesh = lb
		led.material_override = mat
		led.position = Vector3(sx, htop * levels[i], (z0 + z1) * 0.5)
		_add_seam_node(led)

	_brace(Vector3(sx, 0.04, z0), Vector3(sx, htop * 0.94, z1), mat)
	_brace(Vector3(sx, 0.04, z1), Vector3(sx, htop * 0.94, z0), mat)

	var deck := MeshInstance3D.new()
	deck.name = "SeamLanding"
	var db := BoxMesh.new()
	db.size = Vector3(step_depth * 1.6, 0.05, (z1 - z0) * 0.55)
	deck.mesh = db
	deck.material_override = mat
	deck.position = Vector3(sx, htop * 0.62 + 0.05, (z0 + z1) * 0.5)
	_add_seam_node(deck)

## field — every joint is a seam. A dark blade stands at each of the sixteen joints,
## rising above its own tread, and because the ring is level none of them is the
## guilty one. The figure stops being a staircase with a flaw and becomes a level
## circuit made entirely of risers.
func _build_rift_blades() -> void:
	var n: int = _steps.size()
	for i in range(n):
		var a: MeshInstance3D = _steps[i]
		var b: MeshInstance3D = _steps[(i + 1) % n]
		var blade := MeshInstance3D.new()
		blade.name = "SeamRift_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(step_width * 0.16, step_height * 3.0, step_depth * 1.28)
		blade.mesh = box
		blade.material_override = _seam_material(SEAM_DARK)
		blade.rotation.y = a.rotation.y
		blade.position = Vector3(
			(a.position.x + b.position.x) * 0.5,
			step_height * 1.5,
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
