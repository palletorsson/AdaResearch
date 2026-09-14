extends Node3D

## THE RULER THAT CHANGES WHAT IT IS NOT LOOKING AT.
##
## 2026-09-01, Palle: "put two points together and it creates a ruler that can
## measure. Two objects in front of you — one can be used to measure 0.5, but
## when you measure one object the other scales."
##
## Two points gave the room a distance. Fix the distance and carry it around and
## the distance becomes a UNIT, which is the whole of metrology in one gesture:
## a ruler is not a special object, it is a segment somebody decided to stop
## adjusting. This artifact is that decision, made once, in your hands.
##
## AND THEN IT DOES THE THING THE ROOM HAS BEEN ARGUING TOWARDS. Reading the
## SUBJECT does not change the subject. It changes the WITNESS — the other block,
## the one you are not looking at, standing off to the side. The number on the
## readout is true. The world is different because you read it. Nothing in the
## measurement records that, which is the same sentence the laser section ends on
## and this is where you can watch it happen.
##
## The displacement is the point and it is not decoration:
##
##   - you cannot see the effect while you are causing it, because looking at the
##     witness means not having the ruler on the subject
##   - the subject is honest throughout: it never changes, so nothing about the
##     reading is wrong
##   - the only way to catch it is to look away from your own instrument
##
## An observer effect you can walk around. The witness carries a label saying what
## it is, because a room that punishes you for not noticing is a different and
## worse room than one that tells you and lets you watch.

const TextScreenScript = preload("res://commons/ui/text_screen.gd")

## The unit. 0.5 m, because it is the length the room's own text names.
@export var unit_m: float = 0.5
## How far apart subject and witness stand, metres.
@export var spread_m: float = 1.1
@export var subject_color: Color = Color(0.72, 0.70, 0.66)
@export var witness_color: Color = Color(0.42, 0.55, 0.68)
@export var rule_color: Color = Color(0.86, 0.78, 0.42)
## How far past the subject's face the rule's tip still counts as touching it.
@export var reach_pad_m: float = 0.10
## What one reading does to the witness. Below 1 it shrinks, above 1 it grows.
## Was hard-coded 0.5, which halved the witness on EVERY call and put it on the
## floor in three readings — before any visitor could take a second look.
@export var witness_step: float = 0.72
## Below this the witness stops shrinking. A witness scaled to nothing is a
## witness that has left, and the argument needs it present to be watched.
const WITNESS_MIN := 0.18
const WITNESS_MAX := 2.4

signal measured(reading_m: float, witness_scale: float)
## The visitor tried to read somewhere that is not the subject. Nothing changed.
signal refused(why: String)

var _subject: Node3D
var _witness: Node3D
var _readout
var _end_a: Node3D
var _end_b: Node3D
var _last_reading := 0.0
## The held rule (a child instance of two_point_rule.tscn) and its measuring end.
var _rule: Node3D
var _tip: Node3D
## ONE PRESS, ONE READING. Cleared when the tip leaves the subject, so a visitor
## who holds the trigger down gets one reading, and a visitor who steps away and
## comes back gets another. There is no shared latch helper in this repo — every
## other artifact either rate-limits (pink_gun._cooldown), polls an overlap
## (pattern_machine_a._last_toggled) or never re-arms (pick_up_cube) — so this
## boolean is the whole mechanism and deliberately not a class.
var _armed := true
## Killed before a new one starts: two readings in quick succession used to leave
## two tweens racing on the same property.
var _witness_tw: Tween
## Nodes _build() made, so a rebuild frees its own work and NOT the Rule child
## the scene carries. `for c in get_children(): c.queue_free()` used to take the
## rule with it.
var _built: Array[Node] = []


func _ready() -> void:
	# the Rule is resolved first: _build parents the rule's end marks to it
	_wire_rule()
	_build()


## Connect the held rule's deliberate activation.
##
## action_pressed is the ONE edge-triggered channel that reaches an artifact in
## both lanes: in VR XRToolsFunctionPickup's trigger_click calls action() on the
## held body (function_pickup.gd:496), and on desktop DesktopInteractionPointer
## calls the same method on LMB (:315). Both end on pickable.gd:178 emitting this
## signal, so one connect serves both and nothing shared needs changing.
##
## IT MUST BE CONNECTED BEFORE THE FIRST CLICK. DesktopInteractionPointer._fires
## (:88-91) refuses to call action() at all unless the signal ALREADY has a
## listener — a lazy connect on first grab would make the desktop lane dead.
func _wire_rule() -> void:
	_rule = get_node_or_null("Rule") as Node3D
	if _rule == null:
		push_warning("two_point_ruler: no Rule child — the ruler can be looked at but not used")
		return
	_tip = _rule.get_node_or_null("Tip") as Node3D
	if not _rule.has_signal("action_pressed"):
		push_warning("two_point_ruler: the Rule child is not a pickable — no reading is possible")
		return
	if not _rule.is_connected("action_pressed", _on_rule_action):
		_rule.connect("action_pressed", _on_rule_action)


## The visitor pressed, holding the rule. One press is one reading.
func _on_rule_action(_who: Variant = null) -> void:
	if not _armed:
		return                      # the input is still held down from the last one
	if not tip_on_subject():
		# REFUSED, and nothing moves. A reading taken in mid-air is not a reading.
		if _readout != null and is_instance_valid(_readout):
			_readout.body = "bring the rule to the pale block"
		refused.emit("the rule was not on the subject")
		return
	_armed = false
	measure()


## Is the rule's measuring end on the subject?
##
## PURE GEOMETRY, and that is forced rather than preferred. An Area3D cannot see
## the rule: on desktop DesktopInteractionPointer zeroes a carried body's
## collision_layer AND mask (:503-507) for exactly the span in which a reading is
## possible, and in VR pickable.gd:311 moves it to the picked-up layer. The
## Subject has no collider at all — _block() returns a bare Node3D holding a mesh.
## So this is point-in-box in the subject's own frame, the same trick
## palm_scanner._controller_in_box uses, and it behaves identically in both lanes.
func tip_on_subject() -> bool:
	if _subject == null or not is_instance_valid(_subject):
		return false
	if _tip == null or not is_instance_valid(_tip):
		return false
	var half: float = _subject_width_m() * 0.5 + maxf(0.0, reach_pad_m)
	var local: Vector3 = _subject.global_transform.affine_inverse() * _tip.global_position
	return absf(local.x) <= half and absf(local.y) <= half and absf(local.z) <= half


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("unit_m"):
		unit_m = float(config_data["unit_m"])
	if config_data.has("spread_m"):
		spread_m = float(config_data["spread_m"])
	if _subject:
		_build()


func _build() -> void:
	# Free only what a previous _build made. `for c in get_children()` took the
	# Rule child with it, so a map that sets unit_m through apply_grid_config
	# destroyed the very thing the visitor picks up.
	for c in _built:
		if is_instance_valid(c):
			c.queue_free()
	_built.clear()

	# THE RULE IS NOT DRAWN HERE ANY MORE. It used to be two marks and a bar
	# painted at (0, 1, -0.5) because nothing could be held; the Rule child
	# (two_point_rule.tscn) now stands at that transform and IS the segment. If
	# this still drew one, picking the real rule up would leave a ghost of it
	# hanging in the air — two rules, one of them a picture.
	#
	# _mark() is kept: the two end dots are what make the held thing read as a
	# SEGMENT somebody stopped adjusting rather than a stick, so they are built
	# as children of the Rule and travel with it.
	if _rule != null and is_instance_valid(_rule):
		_end_a = _mark_on(_rule, Vector3(-unit_m * 0.5, 0.0, 0.0))
		_end_b = _mark_on(_rule, Vector3(unit_m * 0.5, 0.0, 0.0))

	# THE SUBJECT — measured, and never altered by being measured.
	_subject = _block(Vector3(-spread_m * 0.5, 0.0, 0.0), unit_m, subject_color)
	_subject.name = "Subject"
	# THE WITNESS — not measured, and the only thing that changes.
	_witness = _block(Vector3(spread_m * 0.5, 0.0, 0.0), unit_m, witness_color)
	_witness.name = "Witness"

	_readout = TextScreenScript.new()
	_readout.mode = 0
	_readout.width_m = 0.5
	_readout.title = "READS"
	_readout.body = "bring the rule to the pale block"
	_readout.position = Vector3(0, 1.36, -0.5)
	add_child(_readout)
	_built.append(_readout)

	_label(_witness, "the other block")
	_readout.body = "bring the rule to the pale block"


## THE SUBJECT'S TRUE WIDTH IN WORLD METRES, measured off the mesh it is actually
## built from and the transform it actually stands under.
##
## Not `unit_m`. measure() used to return that constant verbatim, so the readout
## was a claim rather than a reading and the artifact's own argument — "the number
## on the readout is true" — had never been checked against anything. It is
## accidentally right at scale 1, because _block() draws a cube of side unit_m,
## and wrong under any placed scale. Point_Lines places `two_point_ruler:0:0`
## with no scale, which is why nobody had caught it.
func _subject_width_m() -> float:
	if _subject == null or not is_instance_valid(_subject):
		return 0.0
	for c in _subject.get_children():
		var mi := c as MeshInstance3D
		if mi != null and mi.mesh != null:
			# the mesh's own extent, taken into the world through every scale
			# between it and the room
			return mi.get_aabb().size.x * mi.global_transform.basis.get_scale().x
	return 0.0


## Take the reading. The subject is unchanged; the witness is not.
##
## Called by a hand through _on_rule_action, or by a probe. Returns the reading in
## metres, measured off the subject — that is the point of the whole artifact.
func measure() -> float:
	if _subject == null or not is_instance_valid(_subject):
		return 0.0
	var reading: float = _subject_width_m()
	_last_reading = reading

	# The displacement. The number describes the SUBJECT and is applied to the
	# WITNESS, and nothing anywhere records that the two are different objects.
	var s: float = clampf(_witness.scale.x * witness_step, WITNESS_MIN, WITNESS_MAX)
	if is_instance_valid(_witness):
		# kill the previous one first: two readings in quick succession left two
		# tweens racing the same property and the witness landed wherever the
		# loser finished
		if _witness_tw != null and _witness_tw.is_valid():
			_witness_tw.kill()
		_witness_tw = create_tween()
		_witness_tw.tween_property(_witness, "scale", Vector3(s, s, s), 0.35)

	if _readout != null and is_instance_valid(_readout):
		_readout.body = "%.2f m\n(the pale block, unchanged)" % reading

	measured.emit(reading, s)
	return reading


## RE-ARM BY LEAVING. Polled rather than signalled because the zone is geometry,
## not an Area3D — see tip_on_subject() for why it has to be. Cheap: two nodes and
## a transform, and only while a Rule exists.
##
## This is also what makes a HELD input harmless. action_pressed fires once per
## press in both lanes, but a lane that ever repeated it would still get one
## reading, because _armed only returns on the frame the tip is off the subject.
func _process(_delta: float) -> void:
	if _rule == null or not is_instance_valid(_rule):
		return
	if not _armed and not tip_on_subject():
		_armed = true


## Is a further reading available right now? For probes and for the readout.
func armed() -> bool:
	return _armed


func reading() -> float:
	return _last_reading


func witness_scale() -> float:
	return _witness.scale.x if _witness != null and is_instance_valid(_witness) else 0.0


func subject_scale() -> float:
	return _subject.scale.x if _subject != null and is_instance_valid(_subject) else 0.0


## One end of the rule, parented to whatever carries it.
func _mark_on(parent: Node3D, at: Vector3) -> Node3D:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.026
	sm.height = 0.052
	m.mesh = sm
	m.position = at
	m.material_override = _mat(rule_color, 0.3, 0.2)
	parent.add_child(m)
	_built.append(m)
	return m


func _block(at: Vector3, size: float, col: Color) -> Node3D:
	var holder := Node3D.new()
	holder.position = at + Vector3(0, size * 0.5, 0)
	add_child(holder)
	_built.append(holder)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size, size, size)
	m.mesh = bm
	m.material_override = _mat(col, 0.62, 0.0)
	holder.add_child(m)
	return holder


func _label(on: Node3D, text: String) -> void:
	var t = TextScreenScript.new()
	t.mode = 0
	t.width_m = 0.34
	t.title = ""
	t.body = text
	t.position = Vector3(0, unit_m * 0.9, 0.0)
	on.add_child(t)


func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m
