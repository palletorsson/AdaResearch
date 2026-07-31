# godel_statement_plaque.gd
# A self-referential artifact that demonstrates Gödel's incompleteness
# The plaque displays a statement that refers to itself
# Grabbing/interacting cycles through increasingly self-referential statements
#
# "This statement is unprovable within this system"
# — The sentence that broke mathematics (1931)

extends Node3D

class_name GodelStatementPlaque

# @identity
# essence: G: ¬∃p: Proves(p, G) — a sentence that asserts its own unprovability
# desire: cycle through nine statements of increasing self-reference, feel the paradox tighten
# critical_parameter: current_index — at index 4+ the plaque pulses gold, the paradox is live
# triggers: click/grab advances to next statement; index >= 4 fires paradox_triggered signal; glow intensifies on hover
# emerges: the vertigo of self-reference — each statement is more dangerous than the last
# needs: VR area interaction [has], mouse click [has], XR grab [has conceptual]
# relationships: unlocks escher_staircase (visual Godel); contrasts russell_set_box (set-theoretic vs arithmetic self-reference); depends on excluded_middle_demo
# truth: every sufficiently powerful formal system contains true statements it cannot prove — completeness and consistency are mutually exclusive

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-31) — ONE AXIS, TWO FILES. russell_set_box.gd
# carries the same `outside` token with the same five values. The pair is the
# foundations crisis stated twice — arithmetic self-reference and set-theoretic
# self-reference — and both files' truth lines land on the same sentence, which
# russell_set_box also prints on its own face at max depth: EVERY FORMAL SYSTEM
# HAS AN OUTSIDE. It would be incoherent for the two of them to speak different
# vocabularies about that one word.
#
#   outside   WHAT THIS OBJECT DOES ABOUT THE PART IT CANNOT HOLD
#             quotation · margin · breach · omission · habitat
#
# WHY THIS, AND NOT A REGISTER OR AN EXPOSURE AXIS. A register axis asks what
# kind of room a thing belongs in. An exposure axis asks how much of a mechanism
# is on show. Neither question reaches this object: it has no mechanism, and its
# argument is not about where it is kept. It is a claim about a LIMIT — and today
# it makes that claim in the safest form available. A complete, framed, numbered,
# well-made bronze plate that QUOTES an undecidable sentence. The incompleteness
# is the text; the object itself is in perfect order. That is a genuine stance and
# a defensible one, and the whole content of this promotion is that it becomes ONE
# stance among five instead of the only one the artifact is able to take.
#
# WHAT EACH VALUE DOES WITH THE PART IT CANNOT REPRESENT — the sieve's third
# question, and what decides whether this is a family or a menu. The part is the
# same under every value: the TRUTH of G. The plate can carry the sentence. It
# cannot carry the fact that the sentence is true and unprovable, because that
# fact is precisely what lies outside any system strong enough to state it.
#   quotation  HIDES it.       An intact body. Frame, plate, sentence, and the
#                              index reading 1/9 — a closed set of nine, counted,
#                              nothing missing. The outside is a line of text on
#                              an object that has no trouble of its own.
#   margin     BOUNDS it.      The body stays whole and gives the outside a SIZE:
#                              the inscription retreats to a raised panel, and
#                              half the plate is left as ruled, bracketed, empty
#                              metal. The system reaches this far. The rest is
#                              measured and blank.
#   breach     EXHIBITS it.    The body fails at the claim. The plate is in two
#                              pieces, offset and out of true, the frame has lost
#                              its bottom rail and sprung its right one, and
#                              fragments hang at the foot of the break. The
#                              sentence is untouched and still centred; the thing
#                              carrying it has come apart.
#   omission   LEAVES A HOLE.  Eleven of the twelve edges of the plaque, in frame
#                              brass, and no plaque. The boundary is built, the
#                              body is not, and the sentence hangs in the empty
#                              rectangle with the room showing through where the
#                              plate should be. The statement is true and there
#                              is nothing holding it.
#   habitat    BUILDS THERE.   The intact plaque, and around it eighty-odd blank
#                              plates of its own kind, some faintly lit, running
#                              well past the frame. The unproven is not a defect
#                              at the edge of the system; it is the larger place,
#                              populated, with the one inscribed plate as a small
#                              bright island in it.
#
# outside=quotation is the legacy lineage, statement for statement: _ready() calls
# _create_plaque(), which is untouched, and every other value takes the other side
# of a single branch. All existing placements are unaffected.
#
# WHAT IT COST. The plaque can no longer be innocent about its own composure.
# Under quotation the intact frame used to be simply how a plaque is made; now it
# is legible as a CLAIM — nothing wrong here, the trouble is in the text — because
# four other bodies stand next to it that do not make that claim. That is a real
# foreclosure and it cannot be undone by choosing the default. There is also a
# reading this axis makes harder: the plaque as a neutral display surface that
# happens to hold logic. It is now always saying something about its own footing.
#
# NOT ROUTED THROUGH outside: the nine statements, their notes, the index readout,
# the fonts, sizes, positions and colours of all three labels, the hover glow, and
# the paradox threshold at index 4. Every value shows the SAME sentence at the SAME
# size in the SAME place — what changes is what is behind it and whether that thing
# holds together. This pass stages the curriculum's final claims; it does not edit
# them.
# ─────────────────────────────────────────────────────────────────────────────

signal statement_changed(statement: String, index: int)
signal paradox_triggered()

## Current statement index
@export var current_index: int = 0

## Plaque dimensions
@export var width: float = 0.6
@export var height: float = 0.4
@export var depth: float = 0.05

## Text properties
@export var text_color: Color = Color(0.9, 0.85, 0.7)
@export var plaque_color: Color = Color(0.15, 0.12, 0.1)
@export var glow_color: Color = Color(1.0, 0.9, 0.5)

## Enable grabbable
@export var grabbable: bool = true

## THE AXIS — what this object does about its own outside (see the promotion note
## above). quotation is the legacy lineage: an intact, framed, numbered body with the
## limit written on it. The other four give the outside a measured size, let it break
## the body, leave the body unbuilt inside its own boundary, or build in it.
@export_enum("quotation", "margin", "breach", "omission", "habitat") var outside: String = "quotation"

## THE VOCABULARY LIVES HERE, ONCE. russell_set_box.gd preloads this script and reads
## this list, normalise_outside() and the four shared builders at the bottom of the file
## out of it, so the two artifacts cannot drift apart on what the five words are or what
## they build. The @export_enum line above is the one thing written out twice — an
## annotation argument has to be a literal — and normalise_outside() is what keeps that
## from mattering: a word in one annotation and not in this list falls back to the legacy
## body instead of rendering something the registry never declared. This list is also
## what tools/apply_dna_block.py derives the registry declaration from.
const OUTSIDES: PackedStringArray = ["quotation", "margin", "breach", "omission", "habitat"]

## The statements — each more self-referential than the last
var statements: Array[String] = [
	"This statement exists.",
	"This statement refers to itself.",
	"This statement cannot be proven true.",
	"This statement is unprovable within this system.",
	"If this statement is provable, then it is false.",
	"I am lying.",
	"The set of all statements not containing themselves...",
	"∃x: ¬Provable(x) ∧ True(x)",
	"G: ¬∃p: Proves(p, G)",
]

var statement_notes: Array[String] = [
	"Existence — the starting point",
	"Self-reference — the dangerous turn",
	"The claim Gödel encoded",
	"The incompleteness theorem",
	"The paradox made formal",
	"The Liar Paradox — ancient Greece",
	"Russell's Paradox — 1901",
	"Formal logic notation",
	"Gödel sentence G — 1931",
]

# Internal
var _plaque_mesh: MeshInstance3D
var _text_label: Label3D
var _note_label: Label3D
var _glow_effect: OmniLight3D
var _interactable: Area3D
var _animation_time: float = 0.0
var _is_glowing: bool = false
## Every node `outside` owns. Recorded as the difference in this node's children across
## _build_body(), so _create_plaque() itself did not have to be touched to get handles.
## A `#outside:` token arriving after _ready() frees exactly these and builds the other
## lineage — the three labels, the glow and the interaction area are never in this list
## and are never rebuilt.
var _body_nodes: Array[Node] = []
var _built: bool = false

func _ready() -> void:
	_build_body()
	_create_text()
	_create_glow()
	_create_interactable()
	_update_display()
	print("GodelStatementPlaque: Ready — 'Every formal system has an outside'")

func _create_plaque() -> void:
	_plaque_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(width, height, depth)
	_plaque_mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = plaque_color
	mat.metallic = 0.3
	mat.roughness = 0.7
	_plaque_mesh.material_override = mat
	
	add_child(_plaque_mesh)
	
	# Frame
	var frame = MeshInstance3D.new()
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(width + 0.04, height + 0.04, depth * 0.5)
	frame.mesh = frame_mesh
	frame.position.z = -depth * 0.3
	
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.4, 0.35, 0.2)
	frame_mat.metallic = 0.6
	frame_mat.roughness = 0.4
	frame.material_override = frame_mat
	
	add_child(frame)

## THE ONE BRANCH. quotation runs _create_plaque() and nothing else, exactly as
## _ready() used to; the other four run their own builder. The before/after diff is
## bookkeeping only — it records which children belong to `outside` so a map token can
## swap lineages later — and it adds no geometry on either path.
func _build_body() -> void:
	var before: Array = get_children()
	if outside == "quotation":
		_create_plaque()
	else:
		_build_body_outside()
	for c in get_children():
		if not before.has(c):
			_body_nodes.append(c)
	_built = true

func _build_body_outside() -> void:
	match outside:
		"margin":
			_build_margin()
		"breach":
			_build_breach()
		"omission":
			_build_omission()
		"habitat":
			_build_habitat()
		_:
			_create_plaque()

## THE INTACT PLATE with the outside given a size. The whole legacy body is built
## first — nothing is taken away — and then the inscription retreats onto a raised
## panel so that the metal around it becomes readable as ground the system does not
## reach. A datum rule along the bottom and a stop at either end are what make that
## emptiness a MEASUREMENT rather than a blank: this far, no further, and the width
## of the rest is stated. The note and the index end up below the rule, in the margin,
## which is where marginalia belong.
func _build_margin() -> void:
	_create_plaque()

	var panel_w: float = width * 0.83
	var panel_h: float = height * 0.61
	var panel_y: float = height * 0.14
	# EVERYTHING THIS VALUE ADDS STAYS BEHIND z=0.035, where _create_text() puts the
	# three labels. The plate face is at depth*0.5 = 0.025, so there is exactly a
	# centimetre of room in front of it and the panel, its lip and the rule all have to
	# fit inside that or they occlude the sentence they exist to frame.
	var face_z: float = depth * 0.5

	var panel_mat: StandardMaterial3D = outside_mat(plaque_color.lightened(0.18), 0.0, 0.25, 0.55)
	add_child(outside_box(Vector3(0.0, panel_y, face_z + 0.003),
		Vector3(panel_w, panel_h, 0.006), panel_mat))

	# a thin lipped border so the panel reads as seated in the plate, not painted on
	var lip: StandardMaterial3D = outside_mat(Color(0.4, 0.35, 0.2).lightened(0.10), 0.0, 0.6, 0.4)
	var lip_t: float = 0.010
	for sy in [-1.0, 1.0]:
		add_child(outside_box(Vector3(0.0, panel_y + sy * (panel_h * 0.5 + lip_t * 0.5), face_z + 0.0035),
			Vector3(panel_w + lip_t * 2.0, lip_t, 0.007), lip))
	for sx in [-1.0, 1.0]:
		add_child(outside_box(Vector3(sx * (panel_w * 0.5 + lip_t * 0.5), panel_y, face_z + 0.0035),
			Vector3(lip_t, panel_h, 0.007), lip))

	# the measured empty field: rule + stops, in the frame's own brass
	var gauge := Node3D.new()
	gauge.name = "OutsideMeasure"
	gauge.position = Vector3(0.0, -height * 0.05, 0.0)
	add_child(gauge)
	outside_measure(gauge, width * 0.97, height * 0.85, face_z + 0.002,
		Color(0.4, 0.35, 0.2).lightened(0.30), false)

## THE BODY FAILS AT THE CLAIM. Two pieces of plate, offset and out of true, with the
## room showing through the split; the frame has lost its bottom rail entirely and its
## right rail has sprung outward; fragments hang at the foot of the break. The sentence,
## the note and the index keep their exact positions — the argument is untouched and the
## thing carrying it is not.
func _build_breach() -> void:
	# The split is 13% of the plate's width and the halves disagree by seven and a half
	# degrees. Both numbers are deliberately past the point of looking like a chip or a
	# seam: at the distance a capture frames this object from, a hairline crack is one
	# pixel and reads as nothing, and a value that reads as nothing is not a value.
	var half_w: float = width * 0.47
	var body: StandardMaterial3D = outside_mat(plaque_color, 0.0, 0.3, 0.7)

	var left: MeshInstance3D = outside_box(
		Vector3(-width * 0.29, height * 0.02, -0.004), Vector3(half_w, height, depth), body)
	left.rotation_degrees.z = 3.0
	add_child(left)

	var right: MeshInstance3D = outside_box(
		Vector3(width * 0.31, -height * 0.05, 0.006), Vector3(half_w, height, depth), body)
	right.rotation_degrees.z = -4.5
	add_child(right)

	# the exposed interior of the break, catching the plaque's own glow colour
	var lit: StandardMaterial3D = outside_mat(glow_color.darkened(0.35), 0.9, 0.1, 0.6)
	var seam: MeshInstance3D = outside_box(
		Vector3(width * 0.010, 0.0, -0.012), Vector3(0.012, height * 0.9, depth * 0.4), lit)
	seam.rotation_degrees.z = -1.6
	add_child(seam)

	# three rails of four — the bottom one is simply not there
	var frame_mat: StandardMaterial3D = outside_mat(Color(0.4, 0.35, 0.2), 0.0, 0.6, 0.4)
	var rail_t: float = 0.02
	var fz: float = -depth * 0.3
	add_child(outside_box(Vector3(0.0, height * 0.5 + rail_t * 0.5, fz),
		Vector3(width + rail_t * 2.0, rail_t, depth * 0.5), frame_mat))
	add_child(outside_box(Vector3(-(width * 0.5 + rail_t * 0.5), 0.0, fz),
		Vector3(rail_t, height + rail_t * 2.0, depth * 0.5), frame_mat))
	var sprung: MeshInstance3D = outside_box(
		Vector3(width * 0.5 + rail_t * 1.6, -height * 0.02, fz + 0.014),
		Vector3(rail_t, height + rail_t * 2.0, depth * 0.5), frame_mat)
	sprung.rotation_degrees.z = -5.5
	add_child(sprung)

	# fragments at the foot of the break
	var shards: Array = [
		[Vector3(width * 0.33, -height * 0.59, depth * 1.1), Vector3(0.090, 0.048, 0.014), Vector3(12.0, 20.0, 31.0)],
		[Vector3(-width * 0.23, -height * 0.63, depth * 1.7), Vector3(0.062, 0.040, 0.013), Vector3(20.0, -34.0, -17.0)],
		[Vector3(width * 0.03, -height * 0.57, depth * 0.6), Vector3(0.075, 0.036, 0.012), Vector3(6.0, 9.0, 52.0)],
	]
	for s in shards:
		var piece: MeshInstance3D = outside_box(s[0], s[1], body)
		piece.rotation_degrees = s[2]
		add_child(piece)

## THE BOUNDARY BUILT, THE BODY NOT. Eleven of the plaque's twelve edges in frame brass
## and no plate at all, so the sentence hangs in an empty rectangle with the room showing
## through where its support should be. The omitted edge is the bottom front one, the rail
## a reader stands closest to. A statement that is true and has nothing under it.
func _build_omission() -> void:
	var frame_mat: StandardMaterial3D = outside_mat(Color(0.4, 0.35, 0.2), 0.12, 0.6, 0.4)
	outside_cage(self, Vector3(width + 0.04, height + 0.04, depth), 0.014, frame_mat, 1)

## THE OUTSIDE AS THE LARGER PLACE. The intact plaque, and around it a field of blank
## plates of its own kind — same stock, same proportion, no inscription — running well
## past the frame and set back from it. A seventh of them carry a low light, which is the
## only way a still can say the field is inhabited rather than stacked. The proven is the
## small bright island; the unproven is the ground it stands on.
func _build_habitat() -> void:
	_create_plaque()

	var field := Node3D.new()
	field.name = "OutsideField"
	add_child(field)
	var count: int = outside_field(field,
		Vector3(0.100, 0.068, 0.014), 13, 9, Vector2(0.115, 0.105),
		plaque_color.lightened(0.06), Color(0.4, 0.35, 0.2).darkened(0.35),
		Vector2(width * 0.58, height * 0.58), 0.0, 1931, false)
	print("GodelStatementPlaque: outside=habitat — %d unwritten plates" % count)

func _create_text() -> void:
	# Main statement
	_text_label = Label3D.new()
	_text_label.text = ""
	_text_label.font_size = 48
	_text_label.position = Vector3(0, 0.05, depth / 2 + 0.01)
	_text_label.pixel_size = 0.001
	_text_label.width = width * 900
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.modulate = text_color
	_text_label.outline_size = 8
	_text_label.outline_modulate = Color.BLACK
	add_child(_text_label)
	
	# Note/explanation
	_note_label = Label3D.new()
	_note_label.text = ""
	_note_label.font_size = 24
	_note_label.position = Vector3(0, -height / 2 + 0.05, depth / 2 + 0.01)
	_note_label.pixel_size = 0.001
	_note_label.modulate = Color(0.6, 0.6, 0.5, 0.8)
	_note_label.outline_size = 4
	_note_label.outline_modulate = Color.BLACK
	add_child(_note_label)
	
	# Index indicator
	var index_label = Label3D.new()
	index_label.name = "IndexLabel"
	index_label.text = ""
	index_label.font_size = 18
	index_label.position = Vector3(width / 2 - 0.05, -height / 2 + 0.03, depth / 2 + 0.01)
	index_label.pixel_size = 0.001
	index_label.modulate = Color(0.5, 0.5, 0.4, 0.6)
	add_child(index_label)

func _create_glow() -> void:
	_glow_effect = OmniLight3D.new()
	_glow_effect.light_color = glow_color
	_glow_effect.light_energy = 0.0
	_glow_effect.omni_range = 0.5
	_glow_effect.position.z = depth
	add_child(_glow_effect)

func _create_interactable() -> void:
	_interactable = Area3D.new()
	_interactable.name = "InteractableArea"
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(width, height, depth + 0.1)
	collision.shape = shape
	_interactable.add_child(collision)
	
	_interactable.input_event.connect(_on_input_event)
	_interactable.mouse_entered.connect(_on_hover_start)
	_interactable.mouse_exited.connect(_on_hover_end)
	
	add_child(_interactable)
	
	# Make it pickable for XR
	_interactable.input_ray_pickable = true

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_statement()

func _on_hover_start() -> void:
	_is_glowing = true

func _on_hover_end() -> void:
	_is_glowing = false

func _process(delta: float) -> void:
	_animation_time += delta
	
	# Glow effect on hover
	var target_energy = 0.5 if _is_glowing else 0.0
	_glow_effect.light_energy = lerp(_glow_effect.light_energy, target_energy, delta * 5.0)
	
	# Subtle pulse on paradox statements (index >= 4)
	if current_index >= 4:
		var pulse = sin(_animation_time * 2.0) * 0.5 + 0.5
		_text_label.modulate = text_color.lerp(glow_color, pulse * 0.3)
	else:
		_text_label.modulate = text_color

func _update_display() -> void:
	if current_index < statements.size():
		_text_label.text = statements[current_index]
		_note_label.text = statement_notes[current_index]
		
		var index_label = get_node_or_null("IndexLabel")
		if index_label:
			index_label.text = "%d/%d" % [current_index + 1, statements.size()]
		
		emit_signal("statement_changed", statements[current_index], current_index)
		
		# Trigger paradox event on the self-referential statements
		if current_index >= 4:
			emit_signal("paradox_triggered")

func advance_statement() -> void:
	current_index = (current_index + 1) % statements.size()
	_update_display()
	
	# Visual feedback
	_glow_effect.light_energy = 1.0
	
	print("GodelStatementPlaque: '%s'" % statements[current_index])

func previous_statement() -> void:
	current_index = (current_index - 1 + statements.size()) % statements.size()
	_update_display()

func set_statement(index: int) -> void:
	current_index = clamp(index, 0, statements.size() - 1)
	_update_display()

func get_current_statement() -> String:
	return statements[current_index] if current_index < statements.size() else ""

# For XR grab interaction
func _on_grabbed() -> void:
	advance_statement()

## MAP CONFIG — `godel_statement_plaque#outside:breach`. This artifact had no config
## method at all until now, so every existing token on a placement reached the grid's
## metadata fallback and nothing else; this method keeps that true for all of them by
## returning on the first line unless the key is `outside`. GridInteractablesComponent
## calls it deferred, after _ready() has already built one lineage, so a word that
## changes anything has to free its own nodes and build again — and it frees only what
## _build_body() recorded, never the labels, the glow or the interaction area.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("outside"):
		return
	var before: String = outside
	outside = normalise_outside(str(config_data["outside"]), outside)
	if outside == before or not _built:
		return
	for n in _body_nodes:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_body_nodes.clear()
	_build_body()
	print("GodelStatementPlaque: outside=%s" % outside)

# ─────────────────────────────────────────────────────────────────────────────
# THE SHARED VOCABULARY. Everything below is static and russell_set_box.gd calls it
# through a preload of this file. One allow-list, one normaliser, four builders, two
# artifacts — because the pair are the same crisis stated twice and a `breach` that
# meant one thing on the plaque and another in the box would be two axes wearing one
# name. Each file supplies only its own dimensions and its own palette; the gestures
# are held in common.
# ─────────────────────────────────────────────────────────────────────────────

## Accept a value only if it names something both files actually build. A typo in a map
## token falls back to the shipped body rather than stranding a placement with an object
## that argues nothing — and it is what keeps the two @export_enum lines from mattering
## if one of them ever drifts.
static func normalise_outside(raw: String, fallback: String = "quotation") -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if OUTSIDES.has(v) else fallback

static func outside_mat(color: Color, emissive_energy: float,
		metallic: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emissive_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emissive_energy
	return mat

## Builds a box; does NOT parent it. The caller owns where it goes, because one of these
## objects hangs on a wall and the other stands on the floor.
static func outside_box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	return mi

## THE BOUNDARY WITHOUT THE BODY — `omission` in both files. Twelve edges of a box, minus
## one, so the object states exactly where it would be and builds none of it, and cannot
## even close the outline it does draw. Edge order is fixed and documented because the
## caller chooses which one goes missing and that choice is part of the argument:
##   0..3   along X   (0, ∓y, ∓z)   0 bottom-back, 1 bottom-front, 2 top-back, 3 top-front
##   4..7   along Y   (∓x, 0, ∓z)   the four uprights, 7 = right-front
##   8..11  along Z   (∓x, ∓y, 0)   the four side rails
## Pass omit = -1 to build the whole cage.
static func outside_cage(mount: Node3D, size: Vector3, rod: float,
		mat: Material, omit: int) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var edges: Array = []
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			edges.append([Vector3(0.0, sy * hy, sz * hz), Vector3(size.x, rod, rod)])
	for sx in [-1.0, 1.0]:
		for sz2 in [-1.0, 1.0]:
			edges.append([Vector3(sx * hx, 0.0, sz2 * hz), Vector3(rod, size.y, rod)])
	for sx2 in [-1.0, 1.0]:
		for sy2 in [-1.0, 1.0]:
			edges.append([Vector3(sx2 * hx, sy2 * hy, 0.0), Vector3(rod, rod, size.z)])
	for i in range(edges.size()):
		if i == omit:
			continue
		mount.add_child(outside_box(edges[i][0], edges[i][1], mat))

## WHAT MAKES AN EMPTY ZONE A MEASURED ONE — `margin` in both files. A datum rule along
## it and a stop at either end. Without these two marks blank ground is just blank; with
## them the object is stating a width and claiming to have reached its limit at a place
## it can point to. `flat` lays the gesture on the floor (the box's margin is a strip of
## ground) instead of standing it in a face (the plaque's is a band of metal), so the two
## read as the same claim in the plane each object actually works in.
static func outside_measure(mount: Node3D, w: float, h: float, off: float,
		color: Color, flat: bool) -> void:
	var rule: StandardMaterial3D = outside_mat(color, 0.35, 0.5, 0.45)
	var stop: StandardMaterial3D = outside_mat(color.lightened(0.30), 0.9, 0.4, 0.35)
	if flat:
		mount.add_child(outside_box(Vector3(0.0, off, h * 0.5),
			Vector3(w, 0.006, h * 0.07), rule))
		for sx in [-1.0, 1.0]:
			mount.add_child(outside_box(Vector3(sx * w * 0.5, off, 0.0),
				Vector3(w * 0.012, 0.010, h), stop))
	else:
		mount.add_child(outside_box(Vector3(0.0, -h * 0.5, off),
			Vector3(w, h * 0.055, 0.006), rule))
		for sx2 in [-1.0, 1.0]:
			mount.add_child(outside_box(Vector3(sx2 * w * 0.5, 0.0, off),
				Vector3(w * 0.014, h, 0.008), stop))

## THE OUTSIDE AS THE LARGER PLACE — `habitat` in both files. A jittered grid of bodies
## of the object's own kind, cleared where the original stands so it is not buried, and
## seeded so a still is reproducible from one capture to the next. `flat` lays the field
## on the ground (the box's kin stand around it) rather than in a plane (the plaque's kin
## hang beside it). `front` additionally clears a corridor on the viewer's side, because
## a field that occludes the object's own labels is not an argument, it is a wall.
## Returns how many bodies it built — the count is the claim, so the caller can print it.
static func outside_field(mount: Node3D, unit: Vector3, cols: int, rows: int,
		pitch: Vector2, tone_a: Color, tone_b: Color, clear: Vector2,
		front: float, seed_value: int, flat: bool) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var built: int = 0
	for iy in range(rows):
		for ix in range(cols):
			var u: float = (float(ix) - float(cols - 1) * 0.5) * pitch.x
			var v: float = (float(iy) - float(rows - 1) * 0.5) * pitch.y
			if absf(u) < clear.x and absf(v) < clear.y:
				continue
			if front > 0.0 and v > 0.0 and absf(u) < front:
				continue
			var s: float = rng.randf_range(0.78, 1.22)
			var tone: Color = tone_a.lerp(tone_b, rng.randf())
			var glow: float = 0.0
			if rng.randf() < 0.14:
				glow = 0.45
			var mat: StandardMaterial3D = outside_mat(tone, glow, 0.35, 0.65)
			var pos: Vector3
			var box_size: Vector3
			if flat:
				box_size = Vector3(unit.x * s, unit.y * s, unit.z * s)
				pos = Vector3(u + rng.randf_range(-0.014, 0.014), box_size.y * 0.5,
					v + rng.randf_range(-0.014, 0.014))
			else:
				box_size = Vector3(unit.x * s, unit.y * s, unit.z)
				pos = Vector3(u + rng.randf_range(-0.008, 0.008),
					v + rng.randf_range(-0.008, 0.008), rng.randf_range(-0.060, -0.022))
			var mi: MeshInstance3D = outside_box(pos, box_size, mat)
			if flat:
				mi.rotation.y = rng.randf_range(-0.24, 0.24)
			mount.add_child(mi)
			built += 1
	return built
