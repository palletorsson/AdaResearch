extends Node3D
## The five classical column outlines - Vessel, Reed, Bell, Spindle, Cairn - as a lane of colour pillars.
##
## Palle, 22 November 2026: "move the old pillar to one of the color maps and put gradient color on them", then
## "can they match their position". Until that day these outlines stood on the tower's columns floor, which now
## holds the black alien family (commons/void/columns_study.gd).
##
## On the pillar colour floor (Color_Pillar) the room is a colour space: hue across, saturation along, value up,
## and every pillar is the colour of the place it stands on, dark at the foot and full at the ceiling. This row
## stands in the lane the field leaves empty and takes the same rule: each column asks the field
## (pillarcolorcollection.sample_space) for the hue and saturation of its own position, and runs from value 0 at
## the height where the field's value begins to value 1 at its top. Move the row and the colours follow.
## Where no field is found (a bench, another floor) the `hues` below are used instead.
const Columns = preload("res://commons/artifacts/resolution_colonnade/resolution_colonnade_museum.gd")
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const BASE_HEIGHT := Columns.PLINTH_HEIGHT
const WAIT_FOR_FIELD := 4.0

## Metres between two columns of the row (along local X): the field's own pillar rows are three metres apart.
@export var spacing := 3.0
## The top of a column above the floor: where the field's value reaches 1, under its colour ceiling.
@export var top := 5.45
## Where the field's value leaves 0, above the floor (pillarcolorcollection value_span.x in its Void gallery).
@export var value_from := 0.545
@export_range(4, 64, 1) var sides := 16
@export_range(2, 64, 1) var divisions := 8
@export_range(0.5, 1.05, 0.01) var width := 0.8
## Without a field: hues of the five columns, in row order, as turns of the colour wheel.
@export var hues: Array[float] = [0.0, 0.10, 0.33, 0.57, 0.80]
@export_range(0.0, 1.0, 0.01) var saturation := 0.9
## false, as the pillars of that floor: the colours are drawn by the rule, the room's light does not change them.
@export var lit := false

var field: Node3D
var built := false
var _waited := 0.0


func _ready() -> void:
	for key in ["spacing", "top", "value_from", "sides", "divisions", "width", "saturation", "lit"]:
		if has_meta("config_" + key): set(key, get_meta("config_" + key))


## The field may be built after this row, and the row is placed after it enters the tree: look until it is there.
func _process(delta: float) -> void:
	if built:
		set_process(false)
		return
	_waited += delta
	field = _find_field()
	if field != null or _waited >= WAIT_FOR_FIELD: build()


## The colour field of the floor this row stands on: the nearest node above that answers sample_space.
func _find_field() -> Node3D:
	var floor_root: Node = self
	while floor_root != null and not floor_root.has_meta("void_floor_index"): floor_root = floor_root.get_parent()
	var scope: Node = floor_root if floor_root != null else get_tree().root
	for node in scope.find_children("*", "Node3D", true, false):
		if node != self and node.has_method("sample_space") and node.get_child_count() > 0: return node as Node3D
	return null


func build() -> void:
	built = true
	var factory := Columns.new()
	factory.finish = "gradient"
	factory.gradient_lit = lit
	factory.gradient_start = maxf(0.0, value_from - BASE_HEIGHT)
	var names: Array[String] = Columns.Totem.names(0)
	for i in names.size():
		var at := Vector3((i - (names.size() - 1) * 0.5) * spacing, 0, 0)
		var colour := Color.from_hsv(hues[i % hues.size()], saturation, 1.0)
		if field != null: colour = field.call("sample_space", field.to_local(to_global(at)))
		factory.gradient_low = Color.from_hsv(colour.h, colour.s, 0.0)
		factory.gradient_high = Color.from_hsv(colour.h, colour.s, 1.0)
		factory._column("Column", Vector3.ZERO, sides, divisions, i, top - BASE_HEIGHT, width, names[i].to_upper())
		var group := Node3D.new()
		group.name = names[i]
		group.position = at
		add_child(group)
		for child in factory.get_children():
			# The museum's plinth is as wide as a classical capital. Here the foot stands on a dark base its own width.
			if child.name == "Plinth_Column": child.free()
			else: child.reparent(group, false)
		var foot := 0.86 * width * 2.0 + 0.06
		Kit.block(group, Vector3(foot, BASE_HEIGHT, foot), Vector3(0, BASE_HEIGHT * 0.5, 0), Color("15161a"), true)
		group.get_node("Plaque_Column").position.y = 0.97
		for child in group.get_children():
			if child is Label3D:
				child.position.y = 0.97
				child.font_size = 27
				child.pixel_size = 0.00175
				child.text = "%s\nHUE %.2f / SATURATION %.2f / VALUE UP\n%d SIDES / %d DIVISIONS" % [names[i].to_upper(), colour.h, colour.s, sides, divisions]
		Kit.block(group, Vector3(0.035, 0.74, 0.035), Vector3(0, 0.59, -0.95), Color("343038"), false)
		group.set_meta("sample_color", colour)
		group.set_meta("editor_label", "%s / hue %.2f / saturation %.2f / value up" % [names[i], colour.h, colour.s])
	factory.free()
	set_meta("matches_field", field != null)
