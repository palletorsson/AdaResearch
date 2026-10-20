extends Node3D
const Loom = preload("res://commons/artifacts/jacquard_weaver/jacquard_weaver.gd")
const Layers = preload("res://commons/artifacts/jacquard_weaver/weave_layers.gd")
var loom: Node3D
var layers: Node3D

func _ready() -> void:
	loom=Loom.new(); loom.position=Vector3(-1.7,0,0); add_child(loom)
	layers=Layers.new(); layers.position=Vector3(2.12,0,-.8); add_child(layers)
	layers.sample_requested.connect(func():loom.weave_sample(96))
	loom.cloth_changed.connect(layers.set_history)
	layers.pattern_requested.connect(loom.select_sample)
	loom.sample_changed.connect(layers.set_pattern)
	layers.set_history(loom.program.snapshot())
