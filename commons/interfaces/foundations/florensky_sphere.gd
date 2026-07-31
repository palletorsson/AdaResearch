# florensky_sphere.gd
# Pavel Florensky's paraconsistent logic visualized
# "A and not-A" — truth that holds contradiction without collapse
#
# Florensky (mathematician-priest, 1882-1937) argued that
# mystical/mathematical truth can be paradoxical:
# The infinite cannot be described positively, only by what it is NOT.
#
# This sphere simultaneously IS and IS NOT
# It holds both states without resolution — the queer signature

extends Node3D

class_name FlorenskySphere

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: A ∧ ¬A held on one surface without collapse — Pavel Florensky's PARACONSISTENCY made a body. A double-faced sphere whose skin reads from both sides at once (blue assertion A oscillating into red negation ¬A), the limit turned from a wall you hit into a habitat you can stand inside. Origin at the sphere's centre; the boundary is the whole point — it is livable both ways.
# desire: to be looked at until the looker stops needing the contradiction resolved. To oscillate as BOTH, to be observed and collapse to a single face for a breath, and to return — teaching that the settled answer is the temporary state and the held tension is home.
# critical_parameter: current_state — BOTH (A ∧ ¬A) is the resting state, not the exception; observation collapses it to A or ¬A only briefly; NEITHER is the apophatic limit ¬(A ∨ ¬A), the infinite described only by what it is not. seam — WHERE the contradiction is put: nowhere marked (none), on one great circle (hairline), in an open void the skin will not close (gap), in structure built across that void (scaffold), or in every joint at once so no joint can be pointed at (field).
# triggers: left-click / VR interact collapses the superposition to a random single face; a 2-second timer returns it to BOTH; right-click cycles all four logical states; hover brightens the glow.
# emerges: the felt experience that contradiction is not destruction but a MODE OF BEING — the crisis-chapter voltage where classical logic's blow-up (from A ∧ ¬A everything follows) refuses to fire, and the boundary becomes a place to think from instead of a place thinking ends.
# needs: a double-faced transparent skin whose inner and outer surfaces both catch light (culling disabled) [present]; an inner emissive core that pulses under the skin [present]; a VR / mouse pickable area [present]; a state label carrying the logical symbols [present].
# relationships: contrasts schrodinger_box (quantum indeterminacy vs LOGICAL paraconsistency); contrasts russell_set_box (contradiction as fatal paradox vs contradiction as inhabited truth); the theological hinge of the foundations-crisis chapters — Florensky the mathematician-priest reading the antinomy as revelation, not error; unlocks qfep_formula_3d (the QFEP oscillation IS this logic).
# truth: A and not-A can both be true. This is not a failure of logic but a description of reality that classical logic cannot contain. Florensky held the limit as a boundary that reads from both sides — and made the contradiction somewhere to live.

signal state_observed(is_A: bool, is_not_A: bool)
signal superposition_entered()
signal superposition_collapsed()

## Sphere parameters
@export var radius: float = 0.3
@export var detail: int = 32

## State A color (assertion)
@export var color_A: Color = Color(0.2, 0.4, 1.0, 0.8)  # Blue

## State not-A color (negation)
@export var color_not_A: Color = Color(1.0, 0.3, 0.2, 0.8)  # Red

## Superposition color (A and not-A)
@export var color_both: Color = Color(0.8, 0.3, 1.0, 0.8)  # Purple

## Current logical state
enum LogicState { A, NOT_A, BOTH, NEITHER }
@export var current_state: LogicState = LogicState.BOTH

## Enable observation (collapses superposition temporarily)
@export var allow_observation: bool = true

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-31) — ONE AXIS, TWO FILES.
# escher_staircase.gd carries the same `seam` token with the same five values and
# preloads this script for the word list. The pair is one argument in two bodies:
# paraconsistency, where the contradiction is everywhere and survives, beside
# impossible geometry, where the contradiction is at one joint and hides. It would
# be incoherent for them to speak different vocabularies about the same question,
# and the question they share is not WHETHER there is a contradiction — both say
# yes — but WHERE IT IS PUT.
#
#   seam   WHERE THE CONTRADICTION IS PUT
#          none · hairline · gap · scaffold · field
#
# WHY THIS, AND NOT A REGISTER OR AN EXPOSURE AXIS. This is not furniture in a room
# and not an instrument you operate; nothing here is housed and nothing here is
# disclosed. It is an argument that a boundary can be lived on from both sides. Its
# limit is not that the logic fails — paraconsistency is precisely the claim that it
# does not — but that a contradiction has to be SOMEWHERE, and today's build puts it
# nowhere. A perfectly closed sphere, one continuous skin, no joint, no mark, and
# the contradiction carried entirely by an oscillating albedo: decoration on a
# complete-looking object. doc/CONSERVATION_OF_THE_IRREDUCIBLE.md §5 is the law
# under that observation — you can move the pile, you cannot make it vanish — and §6
# is the ethic: prefer the worn, show the seam. This axis is the object's own
# freedom about where to put its pile, made settable.
#
# The five words are not invented here either. The @identity block above already
# names them, in this order, as the second half of critical_parameter; that line was
# written before any of this was buildable and it is what this promotion cashes out.
#
# WHAT EACH VALUE DOES WITH THE PART IT CANNOT REPRESENT — the sieve's third
# question, which is what decides whether this is a family or a menu:
#   none      HIDES it.      The skin closes perfectly. The contradiction has no
#                            location, so it cannot be pointed at, refused, or
#                            inhabited. It has been pushed below perception, into
#                            colour, where §3 says power operates unexamined.
#   hairline  BOUNDS it.     Assertion and negation become two visible hemispheres
#                            and the contradiction is admitted to be exactly one
#                            great circle wide — a sunk black groove between two
#                            raised caps. Localised, survivable, and everywhere
#                            else the object is consistent.
#   gap       LEAVES A HOLE. The skin is built as an open shell missing a lune of
#                            longitude, cut edges darkened. There is no material
#                            where the contradiction is. The boundary refuses to
#                            close rather than lie about closing.
#   scaffold  BUILDS THERE.  The same hole, rigged: rails down both cut meridians,
#                            rungs across the opening, a deck seated inside it.
#                            The limit as habitat — the thing the @identity means
#                            by "somewhere to live", made of struts.
#   field     EXHIBITS it.   The whole skin fractures into ninety-six plates with a
#                            rift at every joint, the core showing through all of
#                            them. Contradiction is not at a place, it is the
#                            material. No joint can be pointed at because they all
#                            can, which is the paraconsistent maximum.
#
# seam=none is the legacy lineage, node for node: SphereMesh at `radius` with
# `detail` segments, the same double-faced CULL_DISABLED skin, the same inner core,
# glow, three text boards and pick area, and _create_seam() adds nothing at all. All
# shipped placements are untouched.
#
# WHAT IT COST. The sphere is no longer one primitive — a reader asking "what shape
# is this" now meets a branch. And none's seamlessness, which used to be merely the
# obvious way to build a ball, is now legible as a CLAIM (nothing to locate because
# nothing is anywhere). This object can no longer be innocent about its smoothness.
#
# NOT ROUTED THROUGH seam: the four logical states, the symbols on the state board,
# which colour means assertion and which negation, the collapse-and-return behaviour,
# and every sentence on the three boards. This pass stages the argument; it does not
# edit the logic.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — where the contradiction is put (see the promotion note above).
## none is the legacy lineage and puts it nowhere; the other four give it an address.
@export_enum("none", "hairline", "gap", "scaffold", "field") var seam: String = "none"

## THE VOCABULARY LIVES HERE, ONCE. escher_staircase.gd preloads this script and
## reads this list and normalise_seam() out of it, so the two files cannot drift
## apart on what the five words are. The @export_enum line above is the one thing
## that has to be written out twice — an annotation argument must be a literal — and
## normalise_seam() is what keeps that from mattering: a word in one annotation and
## not in this list falls back to the legacy look instead of rendering something the
## registry never declared. This list is also what tools/apply_dna_block.py derives
## the registry declaration from.
const SEAMS: PackedStringArray = ["none", "hairline", "gap", "scaffold", "field"]

## Half-width of the hairline rift, in degrees of arc. Small enough to read as a
## groove rather than a band, large enough to survive a 512 px capture.
const SEAM_RIFT_DEG := 4.0

## The lune the open skin refuses to cover, and where its centre points. The centre
## is chosen so the opening faces the capture camera and the VR approach direction
## (spatial_needs.player_position = front): a hole aimed at the far side would be a
## claim nobody could witness.
const SEAM_OPEN_DEG := 96.0
const SEAM_OPEN_MID_DEG := 58.0

## field's fracture grid — 12 meridians × 8 parallels = 96 plates, each inset by
## nearly a fifth of its cell so the rift between neighbours is wide enough to read
## at capture size, and standing a tenth of a radius clear of the skin so the plates
## cast into their own rifts. A fracture you have to squint at is not a fracture.
const SEAM_FACET_COLS := 12
const SEAM_FACET_ROWS := 8
const SEAM_FACET_INSET := 0.18
const SEAM_FACET_LIFT := 1.10

const SEAM_DARK := Color(0.02, 0.02, 0.03)
const SEAM_BUILD := Color(0.58, 0.44, 0.24)

# Internal
var _sphere: MeshInstance3D
var _inner_sphere: MeshInstance3D
var _glow: OmniLight3D
var _label: Node3D
var _state_label: Node3D
var _state_label_pos: Vector3 = Vector3.ZERO
var _state_text: String = ""
var _state_color: Color = Color.WHITE
var _animation_time: float = 0.0
var _is_observed: bool = false
var _observation_timer: float = 0.0
const OBSERVATION_DURATION = 2.0

## Every node `seam` owns, so a `#seam:` token arriving after _ready() can free
## exactly what it built. Empty for the whole legacy lineage.
var _seam_nodes: Array[Node] = []
var _built: bool = false

func _ready() -> void:
	_create_sphere()
	_create_inner_sphere()
	_create_seam()
	_create_glow()
	_create_labels()
	_create_interactable()
	_update_visual_state()
	_built = true
	print("FlorenskySphere: Ready — 'A and not-A'")

func _create_sphere() -> void:
	_sphere = MeshInstance3D.new()
	_sphere.name = "OuterSphere"

	# THE AXIS bites first here. gap and scaffold refuse the closed primitive: the
	# skin is an open shell missing a lune of longitude, so the boundary genuinely
	# does not close and the core is visible through the absence. Every other value
	# — none included — keeps the legacy SphereMesh exactly as it was.
	if seam == "gap" or seam == "scaffold":
		_sphere.mesh = _shell_mesh(radius,
			0.0, PI,
			deg_to_rad(SEAM_OPEN_MID_DEG + SEAM_OPEN_DEG * 0.5),
			deg_to_rad(SEAM_OPEN_MID_DEG - SEAM_OPEN_DEG * 0.5 + 360.0),
			maxi(detail / 2, 4), maxi(detail, 8))
	else:
		var mesh = SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2
		mesh.radial_segments = detail
		mesh.rings = detail / 2
		_sphere.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color_both
	mat.metallic = 0.3
	mat.roughness = 0.4
	mat.rim_enabled = true
	mat.rim = 0.5
	mat.rim_tint = 0.3
	# Paraconsistency made visible: the skin is double-faced.
	# Disable culling so the sphere's INNER surface and OUTER surface both
	# render at once — the boundary reads from both sides simultaneously
	# (A ∧ ¬A on one skin, not two objects). Back-lighting lets the far
	# face glow through the near one, so inside-and-outside coexist.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.backlight_enabled = true
	mat.backlight = Color(0.5, 0.5, 0.5)
	_sphere.material_override = mat
	
	add_child(_sphere)

func _create_inner_sphere() -> void:
	_inner_sphere = MeshInstance3D.new()
	_inner_sphere.name = "InnerSphere"
	
	var mesh = SphereMesh.new()
	mesh.radius = radius * 0.6
	mesh.height = radius * 1.2
	mesh.radial_segments = detail
	mesh.rings = detail / 2
	_inner_sphere.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.5
	_inner_sphere.material_override = mat
	
	add_child(_inner_sphere)

func _create_glow() -> void:
	_glow = OmniLight3D.new()
	_glow.light_color = color_both
	_glow.light_energy = 1.0
	_glow.omni_range = 1.0
	add_child(_glow)

func _create_labels() -> void:
	# Title — integrated 2D-in-3D board
	_label = BakedText.make_tag("Florensky Sphere", Color.WHITE, 0.07, Color(0.08, 0.09, 0.11), true)
	if _label:
		_label.position = Vector3(0, radius + 0.3, 0)
		add_child(_label)

	# State display — rebuilt on every state/symbol change (baked text is static)
	_state_label_pos = Vector3(0, 0, radius + 0.1)
	_state_text = "A ∧ ¬A"
	_state_color = color_both
	_rebuild_state_label()

	# Explanation
	var explanation = BakedText.make_tag(
		"Paraconsistent Logic — Truth that holds contradiction",
		Color(0.7, 0.7, 0.7), 0.04, Color(0.08, 0.09, 0.11), true)
	if explanation:
		explanation.position = Vector3(0, -radius - 0.2, 0)
		add_child(explanation)

## Rebuild the state board when its text or color changes (baked text is
## static, so a runtime symbol/state swap means a fresh tag). No-op unless
## the text/color actually differs from what's on screen.
func _rebuild_state_label() -> void:
	if _state_label and is_instance_valid(_state_label):
		_state_label.queue_free()
	_state_label = BakedText.make_tag(_state_text, _state_color, 0.09, Color(0.08, 0.09, 0.11), true)
	if _state_label:
		_state_label.position = _state_label_pos
		add_child(_state_label)

## Set the state board's text/color; rebuilds only if something changed.
func _set_state_label(text: String, color: Color) -> void:
	if text == _state_text and color == _state_color:
		return
	_state_text = text
	_state_color = color
	_rebuild_state_label()

func _create_interactable() -> void:
	var area = Area3D.new()
	area.name = "InteractableArea"
	
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = radius * 1.2
	collision.shape = shape
	area.add_child(collision)
	
	area.input_event.connect(_on_input_event)
	area.mouse_entered.connect(_on_hover_start)
	area.mouse_exited.connect(_on_hover_end)
	area.input_ray_pickable = true
	
	add_child(area)

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			observe()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cycle_state()

func _on_hover_start() -> void:
	_glow.light_energy = 1.5

func _on_hover_end() -> void:
	_glow.light_energy = 1.0

func _process(delta: float) -> void:
	_animation_time += delta
	
	# Handle observation collapse timer
	if _is_observed:
		_observation_timer -= delta
		if _observation_timer <= 0:
			_is_observed = false
			current_state = LogicState.BOTH
			_update_visual_state()
			emit_signal("superposition_entered")
	
	# Animate based on state
	match current_state:
		LogicState.BOTH:
			_animate_superposition()
		LogicState.A, LogicState.NOT_A:
			_animate_collapsed()
		LogicState.NEITHER:
			_animate_void()

func _animate_superposition() -> void:
	# Oscillate between A and not-A colors
	var t = sin(_animation_time * 2.0) * 0.5 + 0.5
	var current_color = color_A.lerp(color_not_A, t)
	
	var mat = _sphere.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = current_color
	
	_glow.light_color = current_color
	
	# Inner sphere pulses
	var inner_mat = _inner_sphere.material_override as StandardMaterial3D
	if inner_mat:
		var pulse = sin(_animation_time * 4.0) * 0.5 + 0.5
		inner_mat.emission_energy_multiplier = 0.3 + pulse * 0.7
	
	# State label flickers between symbols (rebuilds the baked board on change)
	if fmod(_animation_time, 0.5) < 0.25:
		_set_state_label("A ∧ ¬A", color_both)
	else:
		_set_state_label("¬(A ∨ ¬A)", color_both)

func _animate_collapsed() -> void:
	var target_color = color_A if current_state == LogicState.A else color_not_A
	
	var mat = _sphere.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = target_color
	
	_glow.light_color = target_color

func _animate_void() -> void:
	var mat = _sphere.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(0.2, 0.2, 0.2, 0.5)
	
	_glow.light_energy = 0.3

func _update_visual_state() -> void:
	match current_state:
		LogicState.A:
			_set_state_label("A", color_A)
		LogicState.NOT_A:
			_set_state_label("¬A", color_not_A)
		LogicState.BOTH:
			_set_state_label("A ∧ ¬A", color_both)
		LogicState.NEITHER:
			_set_state_label("¬A ∧ ¬(¬A)", Color(0.5, 0.5, 0.5))

func observe() -> void:
	if not allow_observation:
		return
	
	if current_state == LogicState.BOTH:
		# Observation collapses superposition
		_is_observed = true
		_observation_timer = OBSERVATION_DURATION
		
		# Randomly collapse to A or not-A
		current_state = LogicState.A if randf() > 0.5 else LogicState.NOT_A
		_update_visual_state()
		
		emit_signal("superposition_collapsed")
		emit_signal("state_observed", current_state == LogicState.A, current_state == LogicState.NOT_A)
		
		print("FlorenskySphere: Observation collapsed state to %s" % ("A" if current_state == LogicState.A else "¬A"))
		print("FlorenskySphere: Will return to superposition in %.1f seconds" % OBSERVATION_DURATION)

func cycle_state() -> void:
	match current_state:
		LogicState.A:
			current_state = LogicState.NOT_A
		LogicState.NOT_A:
			current_state = LogicState.BOTH
		LogicState.BOTH:
			current_state = LogicState.NEITHER
		LogicState.NEITHER:
			current_state = LogicState.A
	
	_is_observed = false
	_update_visual_state()
	print("FlorenskySphere: State set to %s" % LogicState.keys()[current_state])

func set_state(state: LogicState) -> void:
	current_state = state
	_is_observed = false
	_update_visual_state()

# ─────────────────────────────────────────────────────────────────────────────
# THE SEAM — everything the axis owns, in one place.
# ─────────────────────────────────────────────────────────────────────────────

## Accept a value only if it names something both files actually build. A typo in a
## map token falls back to the shipped look rather than stranding a placement with a
## skin that claims nothing — and it is what keeps the two @export_enum lines from
## mattering if one of them ever drifts.
static func normalise_seam(raw: String, fallback: String = "none") -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if SEAMS.has(v) else fallback

## MAP CONFIG — `florensky_sphere#seam:scaffold`. GridInteractablesComponent calls
## this deferred, so it lands AFTER _ready(). Both guards are load-bearing: a
## placement that names no seam returns before touching anything, and a placement
## that names the seam already in force rebuilds nothing. An unguarded rebuild here
## is the failure that has broken shipped placements in this corpus before.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("seam"):
		return
	var before: String = seam
	seam = normalise_seam(str(config_data["seam"]), seam)
	if seam == before or not _built:
		return
	_rebuild_seam()
	print("FlorenskySphere: seam=%s" % seam)

## The skin itself changes shape between values, so this rebuilds the whole body
## rather than a seam overlay — the same full-rebuild pattern russell_set_box.gd
## uses next door. Dangling label handles are cleared first so nothing reads a
## freed node between the tear-down and the rebuild.
func _rebuild_seam() -> void:
	_seam_nodes.clear()
	_label = null
	_state_label = null
	_state_text = ""
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_create_sphere()
	_create_inner_sphere()
	_create_seam()
	_create_glow()
	_create_labels()
	_create_interactable()
	_update_visual_state()

## Where the contradiction is put. none adds nothing — the legacy sphere is already
## the answer "nowhere", and this function returning early is what makes the default
## byte-for-byte the shipped build.
func _create_seam() -> void:
	match seam:
		"hairline":
			_build_hairline()
		"gap":
			_build_cut_edges()
		"scaffold":
			_build_cut_edges()
			_build_scaffold()
		"field":
			_build_field()

## hairline — the contradiction admitted, and bounded to one great circle.
## Assertion and negation stop sharing every point of the skin and become two raised
## caps in their own colours; between them a black groove, sunk below both, four
## degrees of arc wide. The claim: it is real, it is exactly here, and the rest of
## the surface is consistent.
func _build_hairline() -> void:
	var rift: float = deg_to_rad(SEAM_RIFT_DEG)
	var cap_a := MeshInstance3D.new()
	cap_a.name = "SeamCapA"
	cap_a.mesh = _shell_mesh(radius * 1.05, 0.0, PI * 0.5 - rift, 0.0, TAU, 12, 32)
	cap_a.material_override = _seam_material(color_A, 0.85, true)
	_add_seam_node(cap_a)

	var cap_b := MeshInstance3D.new()
	cap_b.name = "SeamCapNotA"
	cap_b.mesh = _shell_mesh(radius * 1.05, PI * 0.5 + rift, PI, 0.0, TAU, 12, 32)
	cap_b.material_override = _seam_material(color_not_A, 0.85, true)
	_add_seam_node(cap_b)

	var groove := MeshInstance3D.new()
	groove.name = "SeamRift"
	groove.mesh = _shell_mesh(radius * 1.015, PI * 0.5 - rift, PI * 0.5 + rift, 0.0, TAU, 2, 32)
	groove.material_override = _seam_material(SEAM_DARK, 1.0, false)
	_add_seam_node(groove)

## The two meridians where the skin was cut. Darkened so the opening reads as a cut
## and not as an object that was never finished — gap and scaffold share them,
## because scaffold does not repair the hole, it moves into it.
func _build_cut_edges() -> void:
	var half: float = deg_to_rad(SEAM_OPEN_DEG * 0.5)
	var mid: float = deg_to_rad(SEAM_OPEN_MID_DEG)
	var edges: Array[float] = [mid - half, mid + half]
	for i in range(edges.size()):
		var e := MeshInstance3D.new()
		e.name = "SeamCut_%d" % i
		e.mesh = _shell_mesh(radius * 1.012, 0.0, PI,
			edges[i] - deg_to_rad(4.5), edges[i] + deg_to_rad(4.5), 14, 2)
		e.material_override = _seam_material(SEAM_DARK, 1.0, false)
		_add_seam_node(e)

## scaffold — the hole, rigged. Two rails down the cut meridians, seven rungs across
## the opening tapering to nothing at the poles, and a deck seated at the equator
## where a body would stand. Nothing here closes the skin; it makes the not-closing
## habitable, which is what the @identity means by a boundary you can think from.
func _build_scaffold() -> void:
	var half: float = deg_to_rad(SEAM_OPEN_DEG * 0.5)
	var mid: float = deg_to_rad(SEAM_OPEN_MID_DEG)
	var pa: float = mid - half
	var pb: float = mid + half
	var mat: StandardMaterial3D = _seam_material(SEAM_BUILD, 1.0, false)
	mat.metallic = 0.6
	mat.roughness = 0.42

	for i in range(2):
		var rail := MeshInstance3D.new()
		rail.name = "SeamRail_%d" % i
		var p: float = pa if i == 0 else pb
		rail.mesh = _shell_mesh(radius * 1.035, deg_to_rad(12.0), PI - deg_to_rad(12.0),
			p - deg_to_rad(2.4), p + deg_to_rad(2.4), 14, 2)
		rail.material_override = mat
		_add_seam_node(rail)

	var rung_deg: Array[float] = [22.0, 44.0, 66.0, 90.0, 114.0, 136.0, 158.0]
	for i in range(rung_deg.size()):
		var th: float = deg_to_rad(rung_deg[i])
		var p0: Vector3 = _sph(radius * 1.02, th, pa)
		var p1: Vector3 = _sph(radius * 1.02, th, pb)
		var rung := MeshInstance3D.new()
		rung.name = "SeamRung_%d" % i
		var bar := BoxMesh.new()
		bar.size = Vector3(p0.distance_to(p1), 0.013, 0.013)
		rung.mesh = bar
		rung.material_override = mat
		rung.transform = _span(p0, p1)
		_add_seam_node(rung)

	var deck := MeshInstance3D.new()
	deck.name = "SeamDeck"
	# A landing across the mouth of the opening, pushed outward along its own radial
	# axis so it clears the inner core (which lives at radius * 0.6) instead of being
	# buried in it. It reads as a balcony hung in the place where the skin gave up.
	var deck_a: Vector3 = _sph(radius * 1.06, PI * 0.5, pa)
	var deck_b: Vector3 = _sph(radius * 1.06, PI * 0.5, pb)
	var dbox := BoxMesh.new()
	dbox.size = Vector3(deck_a.distance_to(deck_b), 0.016, radius * 0.55)
	deck.mesh = dbox
	deck.material_override = mat
	var dt: Transform3D = _span(deck_a, deck_b)
	dt.origin += dt.basis.z * (radius * 0.22)
	deck.transform = dt
	_add_seam_node(deck)

## field — the fracture everywhere. Ninety-six plates standing proud of the skin
## with a rift at every joint, so the oscillating core shows through all of them at
## once. Nothing is marked as THE seam because everything is one; there is no joint
## a viewer can point at and no consistent region to retreat to.
func _build_field() -> void:
	var shell := MeshInstance3D.new()
	shell.name = "SeamField"
	shell.mesh = _facet_mesh(radius * SEAM_FACET_LIFT,
		SEAM_FACET_ROWS, SEAM_FACET_COLS, SEAM_FACET_INSET)
	# Opaque and lightened, so the plates read as plates and the skin's own colour —
	# still oscillating underneath, untouched — comes through the rifts as light
	# rather than as more of the same surface. The contradiction stops being the
	# colour of the object and becomes the fact that it is in pieces.
	var mat: StandardMaterial3D = _seam_material(color_both.lightened(0.18), 1.0, false)
	mat.metallic = 0.55
	mat.roughness = 0.28
	mat.rim_enabled = true
	mat.rim = 0.6
	shell.material_override = mat
	_add_seam_node(shell)

func _add_seam_node(n: Node3D) -> void:
	add_child(n)
	_seam_nodes.append(n)

func _seam_material(col: Color, alpha: float, backlit: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, alpha)
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mat.roughness = 0.45
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if backlit:
		mat.backlight_enabled = true
		mat.backlight = Color(0.4, 0.4, 0.4)
	return mat

## A point on the sphere: th is polar from +Y, ph is azimuth in the XZ plane.
func _sph(r: float, th: float, ph: float) -> Vector3:
	return Vector3(r * sin(th) * cos(ph), r * cos(th), r * sin(th) * sin(ph))

## A shell patch over a polar and azimuth range — the one builder every seam that
## needs a sphere that is NOT a whole sphere goes through. Double-sided by material,
## like the legacy skin, so an open edge shows its own inside.
func _shell_mesh(r: float, t0: float, t1: float, p0: float, p1: float, rings: int, segs: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	for i in range(rings + 1):
		var ft: float = float(i) / float(rings)
		var th: float = t0 + (t1 - t0) * ft
		for j in range(segs + 1):
			var fp: float = float(j) / float(segs)
			var ph: float = p0 + (p1 - p0) * fp
			var n: Vector3 = _sph(1.0, th, ph)
			verts.append(n * r)
			norms.append(n)
	for i in range(rings):
		for j in range(segs):
			var a: int = i * (segs + 1) + j
			var b: int = a + 1
			var c: int = a + segs + 1
			var d: int = c + 1
			idx.append(a)
			idx.append(c)
			idx.append(b)
			idx.append(b)
			idx.append(c)
			idx.append(d)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

## The same sphere, but every cell of a rows × cols grid becomes its own plate, inset
## from its cell so bare space runs between all of them. Flat normals per plate, so
## each one catches the key light separately and the rifts stay dark.
func _facet_mesh(r: float, rows: int, cols: int, inset: float) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	var base: int = 0
	for i in range(rows):
		var t0: float = PI * (float(i) + inset) / float(rows)
		var t1: float = PI * (float(i) + 1.0 - inset) / float(rows)
		for j in range(cols):
			var p0: float = TAU * (float(j) + inset) / float(cols)
			var p1: float = TAU * (float(j) + 1.0 - inset) / float(cols)
			var q: Array[Vector3] = [
				_sph(r, t0, p0), _sph(r, t0, p1), _sph(r, t1, p1), _sph(r, t1, p0)
			]
			var nrm: Vector3 = (q[0] + q[1] + q[2] + q[3]).normalized()
			for v in q:
				verts.append(v)
				norms.append(nrm)
			idx.append(base + 0)
			idx.append(base + 2)
			idx.append(base + 1)
			idx.append(base + 0)
			idx.append(base + 3)
			idx.append(base + 2)
			base += 4
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

## A transform whose local X spans a to b, with local Z pointing radially outward —
## how every rung and the deck get laid across the opening without a look_at() that
## would need the node in the tree first.
func _span(a: Vector3, b: Vector3) -> Transform3D:
	var mid: Vector3 = (a + b) * 0.5
	var x_ax: Vector3 = (b - a).normalized()
	var z_ax: Vector3 = mid.normalized()
	if z_ax.length() < 0.001:
		z_ax = Vector3.FORWARD
	var y_ax: Vector3 = z_ax.cross(x_ax).normalized()
	z_ax = x_ax.cross(y_ax).normalized()
	return Transform3D(Basis(x_ax, y_ax, z_ax), mid)
