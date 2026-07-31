# russell_set_box.gd
# Russell's Paradox visualized as an interactive box
# "The set of all sets that do not contain themselves"
# Does this set contain itself? If yes → contradiction. If no → contradiction.
#
# The box that cannot decide if it contains itself
# Opening it reveals... another box. Which contains... another box.

extends Node3D

class_name RussellSetBox

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
## The `outside` vocabulary — allow-list, normaliser and the four shared builders — is
## defined once in the plaque and read from here. Preloaded rather than reached through
## its class_name so a headless run cannot miss it.
const Outside = preload("res://commons/interfaces/foundations/godel_statement_plaque.gd")

# @identity
# essence: S = { x | x ∉ x }; S ∈ S ↔ S ∉ S — Russell's paradox as infinite regress
# desire: open the box and find another box inside, and another, forever — feel the paradox as infinite nesting
# critical_parameter: max_visible_depth — how many nested boxes before the infinite regress indicator
# triggers: click/interact opens next layer; each opening reveals a smaller box; at max depth the ∞ symbol appears; paradox text escalates
# emerges: the visceral experience that self-reference creates bottomless contradiction
# needs: VR click interaction [has], XR ray pickable [has]
# relationships: contrasts godel_statement_plaque (arithmetic vs set-theoretic self-reference); contrasts florensky_sphere (contradiction as paradox vs contradiction as truth); unlocks escher_staircase (spatial self-reference)
# truth: naive set theory is inconsistent — the set of all sets that do not contain themselves destroyed the foundations of mathematics in 1901

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-31) — ONE AXIS, TWO FILES. The vocabulary lives in
# godel_statement_plaque.gd and this file preloads it; see the long note at the head
# of that script for why the axis is this and not a register or an exposure. The
# short version: these two are the same crisis stated twice, arithmetic and
# set-theoretic, and this box's own deepest line already says the plaque's truth
# verbatim — every formal system has an outside.
#
#   outside   WHAT THIS OBJECT DOES ABOUT THE PART IT CANNOT HOLD
#             quotation · margin · breach · omission · habitat
#
# WHAT THE BOX CANNOT REPRESENT is not the same object as the plaque's, and that is
# the point of running one axis across both. The plaque cannot hold the TRUTH of its
# sentence. The box cannot hold S. It nests five deep and stops; S is at no depth,
# because the regress does not bottom out and the membership question has no answer
# at any layer you reach. Today the box handles this the way a good exhibit does: a
# tidy closed nest, the paradox printed on a tag beside it, the regress bounded at
# five and hidden until clicked. In a STILL — which is the only evidence the DNA
# loop has — the shipped object is one closed box with a caption. Nothing about it
# fails to close. That is a stance, and this promotion makes it one of five.
#
#   quotation  HIDES it.       One closed box, lid on, the paradox on a tag beside
#                              it. The regress is real and entirely invisible.
#   margin     BOUNDS it.      The nest's own five footprints — size·0.7^i, read out
#                              of _create_nested_boxes(), not invented — laid out on
#                              the floor in a row, blank, under a datum rule with a
#                              stop at each end. The depth is admitted, counted and
#                              empty. The box itself is untouched.
#   breach     EXHIBITS it.    The outer shell in two pieces, sprung apart with the
#                              floor showing through the split and fragments beside
#                              it, the inner colour lit along the break. A container
#                              whose wall has failed cannot say what is inside it.
#   omission   LEAVES A HOLE.  Eleven of the shell's twelve edges and no shell. The
#                              lid still sits on top of an outline. The boundary is
#                              built, the body is not, and the one upright missing is
#                              the front-right — the corner where in and out would
#                              have been decided.
#   habitat    BUILDS THERE.   The nest as shipped, standing in a field of forty-odd
#                              boxes of its own kind at its own 0.7 ratios, none
#                              inside any other. Self-membership stops being a lid
#                              you lift and becomes a plain you are standing on.
#
# outside=quotation is the legacy lineage: _stage_outside() returns on its first line
# and every existing placement builds exactly what it built before.
#
# WHAT IT COST. The closed lid is no longer neutral. Beside four bodies that do not
# hold together it reads as composure — a claim that the trouble is safely inside —
# and the artifact can no longer be innocent about that. And `margin` in particular
# spends something real: it puts the regress on the floor where a still can see it,
# which weakens the discovery the interaction was built for. That is the trade, and
# it is why it is one value and not the default.
#
# NOT ROUTED THROUGH outside: the set-builder statement, the five escalating paradox
# lines and their order, the ∞ indicator, max_visible_depth, the open/close
# interaction, the signals, and the colour gradient's meaning. Every value shows the
# same statement on the same tag in the same place. This pass stages the argument; it
# does not edit it.
# ─────────────────────────────────────────────────────────────────────────────

signal paradox_observed(depth: int)
signal box_opened(depth: int)
signal infinite_regress_detected()

## Box dimensions (outer)
@export var size: float = 0.3
@export var wall_thickness: float = 0.02

## How many nested boxes to show before infinite indicator
@export var max_visible_depth: int = 5

## Box colors - gradient from outer to inner
@export var outer_color: Color = Color(0.6, 0.3, 0.2)
@export var inner_color: Color = Color(0.2, 0.1, 0.4)

## Label on the box
@export var show_label: bool = true

## THE AXIS — what this object does about its own outside. quotation is the legacy
## lineage: a closed nest with the paradox printed beside it. The other four give the
## regress a measured size on the floor, split the shell, build the shell's boundary and
## not the shell, or stand the box in a field of its own kind. The five words and what
## they mean are shared with godel_statement_plaque.gd; see OUTSIDES there.
@export_enum("quotation", "margin", "breach", "omission", "habitat") var outside: String = "quotation"

# Internal state
var _boxes: Array[MeshInstance3D] = []
var _current_depth: int = 0
var _is_open: Array[bool] = []
var _animation_time: float = 0.0
var _lid_rotations: Array[float] = []
var _main_label: Node3D
var _paradox_label: Node3D
var _paradox_label_pos: Vector3 = Vector3.ZERO
var _paradox_label_color: Color = Color(0.7, 0.7, 0.6, 0.8)
var _interactable: Area3D

func _ready() -> void:
	_create_nested_boxes()
	_create_labels()
	_create_interactable()
	_stage_outside()
	print("RussellSetBox: Ready — 'Does this set contain itself?'")

func apply_grid_config(config: Dictionary) -> void:
	# GUARD FIRST, ON THE KEYS THIS ARTIFACT ACTUALLY CONSUMES. Everything below ends in
	# an unconditional teardown that frees every child and resets _current_depth, so an
	# unrelated key from any wrapper would discard the layers the player has opened.
	# An is_empty() check is not enough — a config carrying only #mount: would still
	# reach the teardown. The kin file godel_statement_plaque.gd guards the same way,
	# on the one key it consumes; this one consumes six.
	var consumed: PackedStringArray = ["outside", "size", "max_visible_depth",
			"show_label", "outer_color", "inner_color"]
	var touches_mine := false
	for k in consumed:
		if config.has(k):
			touches_mine = true
			break
	if not touches_mine:
		return
	if config.has("outside"):
		outside = Outside.normalise_outside(str(config["outside"]), outside)
	if config.has("size"):
		size = float(config["size"])
	if config.has("max_visible_depth"):
		max_visible_depth = int(config["max_visible_depth"])
	if config.has("show_label"):
		show_label = bool(config["show_label"])
	if config.has("outer_color"):
		outer_color = Color(config["outer_color"])
	if config.has("inner_color"):
		inner_color = Color(config["inner_color"])
	# Rebuild from scratch with the new configuration.
	_boxes.clear()
	_is_open.clear()
	_lid_rotations.clear()
	_current_depth = 0
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_create_nested_boxes()
	_create_labels()
	_create_interactable()
	_stage_outside()

## THE ONE BRANCH — and on the legacy word it is one comparison and a return, so the
## nest, the lids, the tags and the ∞ board are built by exactly the code that built
## them before and nothing runs after it. Every other value is a post-pass: it works on
## the finished nest rather than replacing the builder, which is why _create_nested_boxes()
## did not have to be touched at all.
func _stage_outside() -> void:
	if outside == "quotation" or _boxes.is_empty():
		return
	match outside:
		"margin":
			_build_outside_margin()
		"breach":
			_build_outside_breach()
		"omission":
			_build_outside_omission()
		"habitat":
			_build_outside_habitat()

## THE REGRESS ADMITTED, COUNTED AND EMPTY. The five footprints the nest actually uses
## — size · 0.7^i, the same expression _create_nested_boxes() scales by — laid out on the
## floor in front of the box as blank plates in descending order, under a datum rule with
## a stop at either end. The depth of the nest is stated as a width. Nothing is opened,
## nothing is revealed, and the plates carry no contents: this value bounds the outside,
## it does not show what is in it.
func _build_outside_margin() -> void:
	var floor_y: float = -size * 0.3
	var gap: float = size * 0.10
	var total: float = 0.0
	for i in range(max_visible_depth):
		total += size * pow(0.7, i)
	total += gap * float(maxi(0, max_visible_depth - 1))

	var row := Node3D.new()
	row.name = "OutsideMeasure"
	row.position = Vector3(0.0, 0.0, size * 1.15)
	add_child(row)

	var blank: StandardMaterial3D = Outside.outside_mat(
		Color(0.66, 0.65, 0.62), 0.0, 0.15, 0.75)
	var cursor: float = -total * 0.5
	for i in range(max_visible_depth):
		var s: float = size * pow(0.7, i)
		row.add_child(Outside.outside_box(
			Vector3(cursor + s * 0.5, floor_y + size * 0.028, 0.0),
			Vector3(s, size * 0.055, s), blank))
		cursor += s + gap

	Outside.outside_measure(row, total + gap * 2.0, size * 0.62,
		floor_y + 0.004, Color(0.86, 0.80, 0.62), true)

## THE WALL FAILS. The outer shell is rebuilt as two pieces sprung apart, the floor
## showing through the split, the inner colour lit along the break and fragments on the
## ground beside it. The pieces are children of the shell node, so visibility, the lid
## animation and every index into _boxes keep working exactly as before. A container
## whose wall has failed cannot answer a question about what is inside it.
func _build_outside_breach() -> void:
	var floor_y: float = -size * 0.3
	var body: StandardMaterial3D = Outside.outside_mat(outer_color, 0.0, 0.2, 0.8)
	var shell: MeshInstance3D = _boxes[0]
	shell.mesh = null

	# The split is 16% of the shell's width and the halves are five to six degrees out of
	# true with each other, one of them sagging. Deliberately past the point of reading as
	# a seam: at capture distance a hairline is one pixel, and a value a still cannot see
	# is not a value.
	var half: float = size * 0.46
	var left: MeshInstance3D = Outside.outside_box(
		Vector3(-size * 0.30, 0.0, 0.0), Vector3(half, size * 0.6, size), body)
	left.rotation_degrees = Vector3(0.0, 5.0, 3.5)
	shell.add_child(left)

	var right: MeshInstance3D = Outside.outside_box(
		Vector3(size * 0.32, -size * 0.05, size * 0.03),
		Vector3(half, size * 0.6, size), body)
	right.rotation_degrees = Vector3(0.0, -6.5, -5.0)
	shell.add_child(right)

	var lit: StandardMaterial3D = Outside.outside_mat(
		inner_color.lightened(0.30), 0.8, 0.1, 0.6)
	shell.add_child(Outside.outside_box(
		Vector3(size * 0.012, 0.0, 0.0),
		Vector3(size * 0.030, size * 0.50, size * 0.92), lit))

	var shards: Array = [
		[Vector3(size * 0.78, floor_y + size * 0.020, size * 0.42),
			Vector3(size * 0.26, size * 0.040, size * 0.17), Vector3(0.0, 24.0, 0.0)],
		[Vector3(-size * 0.66, floor_y + size * 0.018, size * 0.60),
			Vector3(size * 0.19, size * 0.036, size * 0.14), Vector3(0.0, -37.0, 0.0)],
		[Vector3(size * 0.20, floor_y + size * 0.022, size * 0.86),
			Vector3(size * 0.22, size * 0.044, size * 0.12), Vector3(0.0, 9.0, 0.0)],
	]
	for sh in shards:
		var piece: MeshInstance3D = Outside.outside_box(sh[0], sh[1], body)
		piece.rotation_degrees = sh[2]
		add_child(piece)

## THE BOUNDARY BUILT, THE BODY NOT. The shell's twelve edges minus one, in the shell's
## own colour, and no shell — the lid still resting on an outline, the tags still saying
## what the set is. The missing edge is number 7, the front-right upright: the corner a
## reader stands nearest and the one place the outline would have had to close for inside
## and outside to be different things.
func _build_outside_omission() -> void:
	var shell: MeshInstance3D = _boxes[0]
	shell.mesh = null
	var rods: StandardMaterial3D = Outside.outside_mat(
		outer_color.lightened(0.22), 0.25, 0.4, 0.5)
	Outside.outside_cage(shell, Vector3(size, size * 0.6, size), size * 0.030, rods, 7)

## THE OUTSIDE AS THE LARGER PLACE. The nest exactly as shipped, standing in a field of
## boxes of its own kind at its own 0.7 scale, none inside any other, cleared in front so
## the tags stay readable. The question stops being a lid you lift and becomes ground you
## are standing on.
func _build_outside_habitat() -> void:
	var field := Node3D.new()
	field.name = "OutsideField"
	field.position = Vector3(0.0, -size * 0.3, 0.0)
	add_child(field)
	var count: int = Outside.outside_field(field,
		Vector3(size * 0.55, size * 0.33, size * 0.55), 9, 7,
		Vector2(size * 0.72, size * 0.72), outer_color, inner_color,
		Vector2(size * 1.13, size * 1.13), size * 1.53, 1901, true)
	print("RussellSetBox: outside=habitat — %d boxes, none containing another" % count)

func _create_nested_boxes() -> void:
	for i in range(max_visible_depth):
		var scale_factor = pow(0.7, i)
		var box_size = size * scale_factor
		
		# Box body (open top)
		var box = MeshInstance3D.new()
		box.name = "Box_%d" % i
		
		# Create box without top using ArrayMesh
		var mesh = _create_open_box_mesh(box_size, wall_thickness * scale_factor)
		box.mesh = mesh
		
		var mat = StandardMaterial3D.new()
		var t = float(i) / float(max_visible_depth - 1) if max_visible_depth > 1 else 0.0
		mat.albedo_color = outer_color.lerp(inner_color, t)
		mat.metallic = 0.2
		mat.roughness = 0.8
		box.material_override = mat
		
		# Position nested inside parent
		box.position.y = wall_thickness * i * 0.5
		
		# Initially hide inner boxes
		box.visible = (i == 0)
		
		add_child(box)
		_boxes.append(box)
		_is_open.append(false)
		_lid_rotations.append(0.0)
		
		# Create lid for each box
		_create_lid(i, box_size, scale_factor)
	
	# Infinite regress indicator (innermost) — integrated 2D-in-3D board
	var infinite_indicator = BakedText.make_text_block(
		["∞", "...", "{ S | S ∉ S }"],
		Color(0.85, 0.7, 1.0), 0.05, 0.34, 0.014, false)
	infinite_indicator.name = "InfiniteIndicator"
	infinite_indicator.position = Vector3(0, size * 0.1, 0)
	infinite_indicator.visible = false
	add_child(infinite_indicator)

func _create_open_box_mesh(box_size: float, thickness: float) -> BoxMesh:
	# Simplified: just use a box mesh, we'll handle "open" via lid
	var mesh = BoxMesh.new()
	mesh.size = Vector3(box_size, box_size * 0.6, box_size)
	return mesh

func _create_lid(index: int, box_size: float, scale_factor: float) -> void:
	var lid = MeshInstance3D.new()
	lid.name = "Lid_%d" % index
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(box_size, wall_thickness * scale_factor, box_size)
	lid.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	var t = float(index) / float(max_visible_depth - 1) if max_visible_depth > 1 else 0.0
	mat.albedo_color = outer_color.lerp(inner_color, t) * 1.1
	mat.metallic = 0.3
	mat.roughness = 0.6
	lid.material_override = mat
	
	# Position on top of box
	lid.position.y = box_size * 0.3 + wall_thickness * index * 0.5
	lid.visible = (index == 0)
	
	add_child(lid)

func _create_labels() -> void:
	if not show_label:
		return
	
	# Main label on box — the paradox statement, as an integrated display board
	_main_label = BakedText.make_tag(
		"S = { x | x ∉ x }", Color(0.95, 0.88, 0.78), 0.06,
		Color(0.08, 0.09, 0.11), true, Color(0.86, 0.40, 0.16))
	_main_label.name = "MainLabel"
	_main_label.position = Vector3(0, size * 0.5 + 0.1, size * 0.5 + 0.02)
	add_child(_main_label)

	# Paradox explanation — rebuilt on each depth change (see _update_paradox_text)
	_paradox_label_pos = Vector3(0, -size * 0.4, size * 0.5 + 0.02)
	_rebuild_paradox_label("Does S contain itself?")

func _create_interactable() -> void:
	_interactable = Area3D.new()
	_interactable.name = "InteractableArea"
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(size, size, size)
	collision.shape = shape
	_interactable.add_child(collision)
	
	_interactable.input_event.connect(_on_input_event)
	_interactable.input_ray_pickable = true
	
	add_child(_interactable)

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		open_next_layer()

func _process(delta: float) -> void:
	_animation_time += delta
	
	# Animate lids opening
	for i in range(max_visible_depth):
		var lid = get_node_or_null("Lid_%d" % i)
		if lid and _is_open[i]:
			var target_rotation = -PI * 0.6
			_lid_rotations[i] = lerp(_lid_rotations[i], target_rotation, delta * 3.0)
			
			# Rotate around back edge
			var box_size = size * pow(0.7, i)
			lid.rotation.x = _lid_rotations[i]
			lid.position.z = -box_size * 0.5 * (1.0 - cos(_lid_rotations[i]))

func open_next_layer() -> void:
	if _current_depth >= max_visible_depth:
		# Already at max depth - show infinite regress
		var indicator = get_node_or_null("InfiniteIndicator")
		if indicator:
			indicator.visible = true
		emit_signal("infinite_regress_detected")
		_update_paradox_text()
		print("RussellSetBox: Infinite regress — the paradox has no resolution")
		return
	
	# Open current lid
	_is_open[_current_depth] = true
	emit_signal("box_opened", _current_depth)
	
	_current_depth += 1
	
	# Reveal next box
	if _current_depth < max_visible_depth:
		_boxes[_current_depth].visible = true
		var next_lid = get_node_or_null("Lid_%d" % _current_depth)
		if next_lid:
			next_lid.visible = true
	
	_update_paradox_text()
	emit_signal("paradox_observed", _current_depth)
	
	print("RussellSetBox: Opened layer %d — another box inside!" % _current_depth)

func _rebuild_paradox_label(text: String) -> void:
	# Rebuild the paradox display board with new text (baked, so it can't
	# mutate in place like a Label3D — swap the whole tag).
	if _paradox_label and is_instance_valid(_paradox_label):
		_paradox_label.queue_free()
	_paradox_label = BakedText.make_tag(
		text, _paradox_label_color, 0.045,
		Color(0.08, 0.09, 0.11), true, Color(0.55, 0.30, 0.60))
	if _paradox_label:
		_paradox_label.name = "ParadoxLabel"
		_paradox_label.position = _paradox_label_pos
		add_child(_paradox_label)

func _update_paradox_text() -> void:
	if not show_label:
		return

	var text: String
	match _current_depth:
		0:
			text = "Does S contain itself?"
		1:
			text = "If S ∈ S, then S ∉ S (by definition)"
		2:
			text = "If S ∉ S, then S ∈ S (by definition)"
		3:
			text = "Therefore S ∈ S ↔ S ∉ S"
		4:
			text = "CONTRADICTION"
		_:
			text = "The paradox has no resolution. Every formal system has an outside."
	_rebuild_paradox_label(text)

func reset() -> void:
	_current_depth = 0
	for i in range(max_visible_depth):
		_is_open[i] = false
		_lid_rotations[i] = 0.0
		if i > 0:
			_boxes[i].visible = false
		var lid = get_node_or_null("Lid_%d" % i)
		if lid:
			lid.visible = (i == 0)
			lid.rotation.x = 0
			lid.position.z = 0
	
	var indicator = get_node_or_null("InfiniteIndicator")
	if indicator:
		indicator.visible = false
	
	_update_paradox_text()
