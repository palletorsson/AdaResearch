extends Node3D
const Loom = preload("res://commons/artifacts/jacquard_weaver/jacquard_weaver.gd")
const Layers = preload("res://commons/artifacts/jacquard_weaver/weave_layers.gd")
var loom: Node3D
var layers: Node3D
@export var cloth_save_path: String = "user://ada_tailor_cloth.json"
var save_caption: Label3D

func _ready() -> void:
	loom=Loom.new(); loom.position=Vector3(-1.7,0,0); add_child(loom)
	layers=Layers.new(); layers.position=Vector3(2.12,0,-.8); add_child(layers)
	layers.sample_requested.connect(func():loom.weave_sample(96))
	loom.cloth_changed.connect(layers.set_history)
	layers.pattern_requested.connect(loom.select_sample)
	loom.sample_changed.connect(layers.set_pattern)
	layers.set_history(loom.program.snapshot())
	var button: Node3D=preload("res://commons/interactables/push_button.tscn").instantiate()
	button.name="SaveCloth";button.position=Vector3(.7,1.08,1.5);button.scale=Vector3.ONE*.85;add_child(button)
	button.get_node("InteractableAreaButton").button_pressed.connect(func(_b):save_cloth())
	save_caption=preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd").label(self,"SAVE CLOTH\nFOR THE CUTTING TABLE",Vector3(.7,.88,1.55),10)

func save_cloth() -> bool:
	var data: Dictionary={"version":1,"name":layers.sample_name,"picks":loom.program.snapshot()}
	var ok: bool=preload("res://commons/artifacts/garment_cutting_table/cloth_record.gd").save_record(data,cloth_save_path)
	save_caption.text="CLOTH SAVED\nLOAD IT IN THE GARMENT HALL" if ok else "WEAVE AT LEAST TWO PICKS\nTHEN SAVE CLOTH"
	return ok
