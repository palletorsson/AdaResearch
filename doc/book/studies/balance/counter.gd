extends Node3D
## Counts what has fallen from the table. It listens to the table's signal.

const Look := preload("res://supplied/look.gd")

var falls := 0
var words: Label3D

func _ready() -> void:
	words = Look.label("fallen: 0")
	add_child(words)
	$"../Table".fallen.connect(count)

func count(body: RigidBody3D) -> void:
	falls += 1
	words.text = "fallen: %d, the last %s" % [falls, body.name]
