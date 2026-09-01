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
## Below this the witness stops shrinking. A witness scaled to nothing is a
## witness that has left, and the argument needs it present to be watched.
const WITNESS_MIN := 0.18
const WITNESS_MAX := 2.4

signal measured(reading_m: float, witness_scale: float)

var _subject: Node3D
var _witness: Node3D
var _readout
var _end_a: Node3D
var _end_b: Node3D
var _last_reading := 0.0


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("unit_m"):
		unit_m = float(config_data["unit_m"])
	if config_data.has("spread_m"):
		spread_m = float(config_data["spread_m"])
	if _subject:
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()

	# THE RULER: two ends and the fixed span between them. It is drawn as two
	# marks and a bar rather than a ruler-shaped object, so that what you are
	# holding still reads as a segment somebody stopped adjusting.
	_end_a = _mark(Vector3(-unit_m * 0.5, 1.0, -0.5))
	_end_b = _mark(Vector3(unit_m * 0.5, 1.0, -0.5))
	var bar := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(unit_m, 0.012, 0.012)
	bar.mesh = bm
	bar.position = Vector3(0, 1.0, -0.5)
	bar.material_override = _mat(rule_color, 0.35, 0.1)
	add_child(bar)

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

	_label(_witness, "the other block")


## Take the reading. The subject is unchanged; the witness is not.
##
## Called by a hand, a probe, or anything that means it. Returns the reading in
## metres, which is honest — that is the point of the whole artifact.
func measure() -> float:
	if _subject == null or not is_instance_valid(_subject):
		return 0.0
	var reading: float = unit_m
	_last_reading = reading

	# The displacement. The number describes the SUBJECT and is applied to the
	# WITNESS, and nothing anywhere records that the two are different objects.
	var s: float = clampf(_witness.scale.x * (reading / maxf(unit_m, 0.0001)) * 0.5,
			WITNESS_MIN, WITNESS_MAX)
	if is_instance_valid(_witness):
		var tw := create_tween()
		tw.tween_property(_witness, "scale", Vector3(s, s, s), 0.35)

	if _readout != null and is_instance_valid(_readout):
		_readout.body = "%.2f m\n(the pale block, unchanged)" % reading

	measured.emit(reading, s)
	print("two_point_ruler: read %.2f m off the subject; the witness is now %.2f"
		% [reading, s])
	return reading


func reading() -> float:
	return _last_reading


func witness_scale() -> float:
	return _witness.scale.x if _witness != null and is_instance_valid(_witness) else 0.0


func subject_scale() -> float:
	return _subject.scale.x if _subject != null and is_instance_valid(_subject) else 0.0


func _mark(at: Vector3) -> Node3D:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.026
	sm.height = 0.052
	m.mesh = sm
	m.position = at
	m.material_override = _mat(rule_color, 0.3, 0.2)
	add_child(m)
	return m


func _block(at: Vector3, size: float, col: Color) -> Node3D:
	var holder := Node3D.new()
	holder.position = at + Vector3(0, size * 0.5, 0)
	add_child(holder)
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
