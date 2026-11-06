extends Node3D
class_name InventoryLoadTest
## THE LOAD TEST TOOL (Palle, 2026-11-06: build in edit mode, then "a separate test lets physics loose"): a cast-iron
## weight with a ring, 5 cm - the kind hung on a structure to see whether it holds. Worn as a miniature on the right
## hand like the rubber and the pin; the trigger on a piece of the playground kit tests the whole structure it belongs
## to (commons/artifacts/playground_kit/kit_test.gd): what the bars and the floor do not hold falls and swings on hinged
## rods; fired again, everything goes back on its nodes. It does nothing by itself and is never placed.

@export var size := 0.05
@export var iron := Color("2b2b2e")
@export var ring := Color("b9b9b9")

func _ready() -> void:
	_build()

func apply_grid_config(config: Dictionary) -> void:
	size = clampf(float(config.get("size", size)), .02, .2)
	if is_inside_tree():
		for c in get_children():c.queue_free()
		_build()

func _build() -> void:
	# the weight: a truncated cone, broad at the foot, with the mass written in the iron
	var body := MeshInstance3D.new();body.name = "Iron";var cm := CylinderMesh.new()
	cm.bottom_radius = size * .5;cm.top_radius = size * .32;cm.height = size * .7;cm.radial_segments = 20;body.mesh = cm
	var im := StandardMaterial3D.new();im.albedo_color = iron;im.metallic = .55;im.roughness = .7;body.material_override = im
	body.position.y = size * .35;add_child(body)
	var top := MeshInstance3D.new();top.name = "Ring";var tm := TorusMesh.new()
	tm.inner_radius = size * .1;tm.outer_radius = size * .17;tm.rings = 16;tm.ring_segments = 8;top.mesh = tm
	var rm := StandardMaterial3D.new();rm.albedo_color = ring;rm.metallic = .9;rm.roughness = .25;top.material_override = rm
	top.rotation_degrees.x = 90;top.position.y = size * .7 + size * .14;add_child(top)
	var mark := Label3D.new();mark.name = "Mark";mark.text = "1 kg";mark.font_size = 64;mark.pixel_size = size * .0045
	mark.modulate = Color("d8d8d8");mark.position = Vector3(0, size * .33, size * .43);mark.rotation_degrees.x = -12;add_child(mark)
