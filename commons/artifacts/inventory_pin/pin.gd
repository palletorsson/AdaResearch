extends Node3D
class_name InventoryPin
## THE PIN (the inventory policy of 2026-10-30, after Garry's Mod's physgun right click): a push pin, a red head
## on a steel shaft, standing on its point. The inventory's tool for freezing a placed thing where it is - mid-air
## included - or releasing a frozen one to be a body again. It does nothing by itself: the hand
## (commons/player/inventory_hand.gd pin_at) does the work when this is the current item. Gravity is an item's
## DEFAULT at placement; the pin is the override, a verb on the placed thing.

@export var shaft := 0.03
@export var head := 0.012
@export var head_radius := 0.012
@export var colour := Color("e03a3a")
@export var steel := Color("d8d8d8")

func _ready() -> void:
	_build()

func apply_grid_config(config: Dictionary) -> void:
	shaft = clampf(float(config.get("shaft", shaft)), .01, .1)
	head = clampf(float(config.get("head", head)), .004, .04)
	head_radius = clampf(float(config.get("head_radius", head_radius)), .004, .04)
	if is_inside_tree():
		for c in get_children():c.queue_free()
		_build()

func _build() -> void:
	var needle := MeshInstance3D.new();needle.name = "Shaft";var cm := CylinderMesh.new();cm.top_radius = .0015;cm.bottom_radius = .0004;cm.height = shaft;cm.radial_segments = 8;needle.mesh = cm
	var sm := StandardMaterial3D.new();sm.albedo_color = steel;sm.metallic = .9;sm.roughness = .3;needle.material_override = sm;needle.position.y = shaft / 2;add_child(needle)
	var cap := MeshInstance3D.new();cap.name = "Head";var hm := CylinderMesh.new();hm.top_radius = head_radius;hm.bottom_radius = head_radius * .8;hm.height = head;hm.radial_segments = 16;cap.mesh = hm
	var hmat := StandardMaterial3D.new();hmat.albedo_color = colour;hmat.roughness = .35;cap.material_override = hmat;cap.position.y = shaft + head / 2;add_child(cap)
	var label := Label3D.new();label.text = "PIN";label.font_size = 24;label.pixel_size = .0005;label.modulate = Color("fff1f1")
	label.position = Vector3(0, shaft + head + .001, 0);label.rotation.x = -PI / 2;add_child(label)
