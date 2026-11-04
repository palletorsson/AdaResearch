class_name AssociationTape
extends Node3D
## THE ASSOCIATION, WRITTEN (Palle, 2026-11-03): "where we first encounter a form we should add an associative object,
## and the writing like association(config(cylinder)) on a tape on the wall or the floor."
##
## A strip of the printed tape's ivory, 7.5 cm wide, laid on the floor (or, mount wall, upright on a wall), printed
## with one line - the term's expression, e.g. `fire_extinguisher = association(config(cylinder))`. It is authored, not
## laid by a hand like the roll's runtime strips (commons/artifacts/tape_roll), so a hall can carry its own sentence.
## Its length follows the words. No collider: it is ink on the floor, never a step.
##   config: text, mount floor|wall, ink (hex)

@export var text := "association(config(cylinder))"
@export_enum("floor", "wall") var mount := "floor"
@export var ink := Color("2b2b2b")

const WIDTH := 0.075
const IVORY := Color("efe7d2")
const CHAR_M := 0.031   # metres per character at the print's size

var strip: MeshInstance3D
var words: Label3D

func apply_grid_config(config: Dictionary) -> void:
	if config.has("text"): text = str(config.text)
	if config.has("mount") and str(config.mount) in ["floor", "wall"]: mount = str(config.mount)
	if config.has("ink") and Color.html_is_valid(str(config.ink)): ink = Color.html(str(config.ink))
	if is_inside_tree(): _build()

func _ready() -> void:
	for key in ["text", "mount", "ink"]:
		if has_meta("config_" + key): apply_grid_config({key: get_meta("config_" + key)})
	_build()

func _build() -> void:
	for c in get_children(): c.queue_free()
	var length := maxf(.3, text.length() * CHAR_M + .16)
	var holder := Node3D.new(); holder.name = "Strip"; add_child(holder)
	if mount == "floor":
		holder.position.y = .004
	else:
		holder.position = Vector3(0, 1.2, .004); holder.rotation_degrees.x = 90   # upright, reading off the wall
	strip = MeshInstance3D.new(); strip.name = "Tape"
	var box := BoxMesh.new(); box.size = Vector3(length, .002, WIDTH); strip.mesh = box
	var m := StandardMaterial3D.new(); m.albedo_color = IVORY; m.roughness = .85; strip.material_override = m
	holder.add_child(strip)
	words = Label3D.new(); words.name = "Print"; words.text = text; words.modulate = ink
	words.font_size = 44; words.pixel_size = .00105; words.outline_size = 0
	words.rotation_degrees.x = -90; words.position.y = .0015   # flat on the tape, reading from its +z side
	words.double_sided = false
	holder.add_child(words)

func get_state() -> Dictionary:
	return {"text": text, "mount": mount, "length": (strip.mesh as BoxMesh).size.x if strip else 0.0}
