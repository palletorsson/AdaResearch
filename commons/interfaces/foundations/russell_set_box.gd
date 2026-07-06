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

# @identity
# essence: S = { x | x ∉ x }; S ∈ S ↔ S ∉ S — Russell's paradox as infinite regress
# desire: open the box and find another box inside, and another, forever — feel the paradox as infinite nesting
# critical_parameter: max_visible_depth — how many nested boxes before the infinite regress indicator
# triggers: click/interact opens next layer; each opening reveals a smaller box; at max depth the ∞ symbol appears; paradox text escalates
# emerges: the visceral experience that self-reference creates bottomless contradiction
# needs: VR click interaction [has], XR ray pickable [has]
# relationships: contrasts godel_statement_plaque (arithmetic vs set-theoretic self-reference); contrasts florensky_sphere (contradiction as paradox vs contradiction as truth); unlocks escher_staircase (spatial self-reference)
# truth: naive set theory is inconsistent — the set of all sets that do not contain themselves destroyed the foundations of mathematics in 1901

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
	print("RussellSetBox: Ready — 'Does this set contain itself?'")

func apply_grid_config(config: Dictionary) -> void:
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
