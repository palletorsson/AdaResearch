extends Node3D
class_name InventoryRubber
## THE RUBBER (Palle, 2026-10-30: "we also need rubber to remove specific items"): an eraser, a pink block with
## a dark band, the inventory's tool for taking one placed thing back. It does nothing by itself - the hand
## (commons/player/inventory_hand.gd erase_at) does the work when this is the current item: the right trigger
## on a thing the hand placed removes that thing; on a tape strip, that strip; on the world, nothing.

@export var length := 0.12
@export var width := 0.05
@export var height := 0.03
@export var colour := Color("ee8fb8")
@export var band := Color("2b2b33")

func _ready() -> void:
	_build()

func apply_grid_config(config: Dictionary) -> void:
	length = clampf(float(config.get("length", length)), .04, .3)
	width = clampf(float(config.get("width", width)), .02, .15)
	height = clampf(float(config.get("height", height)), .01, .1)
	if is_inside_tree():
		for c in get_children():c.queue_free()
		_build()

func _build() -> void:
	var body := MeshInstance3D.new();body.name = "Body";var box := BoxMesh.new();box.size = Vector3(length, height, width);body.mesh = box
	var m := StandardMaterial3D.new();m.albedo_color = colour;m.roughness = .92;body.material_override = m;body.position.y = height / 2;add_child(body)
	var strip := MeshInstance3D.new();strip.name = "Band";var sb := BoxMesh.new();sb.size = Vector3(length * .22, height + .002, width + .002);strip.mesh = sb
	var bm := StandardMaterial3D.new();bm.albedo_color = band;bm.roughness = .8;strip.material_override = bm;strip.position = Vector3(-length * .3, height / 2, 0);add_child(strip)
	var label := Label3D.new();label.text = "RUBBER";label.font_size = 28;label.pixel_size = .0007;label.modulate = Color("5a2b44")
	label.position = Vector3(length * .12, height + .001, 0);label.rotation.x = -PI / 2;add_child(label)
