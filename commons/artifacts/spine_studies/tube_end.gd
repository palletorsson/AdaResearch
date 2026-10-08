extends "res://commons/artifacts/spine_studies/tension_handle.gd"
## A persistent pickup at either end of a retained stroke. No new player input.
var stroke_index := 0
var at_start := false
var port_index := 0

func _ready() -> void:
	super()
	scale = Vector3.ONE * 0.72
