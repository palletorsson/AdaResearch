extends Node3D

const SEED := 435
const COUNT := 8
@export_range(0.05, 0.4) var x_extent := 0.4
var values: Array[float] = []
var cursor := 0
@onready var colour: StandardMaterial3D = $Colour/Point.material_override.duplicate()

func _ready() -> void:
	$Colour/Point.material_override = colour
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for i in COUNT: values.append(rng.randf())
	replay()

func next_sample() -> void:
	cursor = (cursor + 1) % values.size()
	show_sample()

func replay() -> void:
	cursor = 0
	show_sample()

func show_sample() -> void:
	var u := values[cursor]
	$Move/Point.position.x = lerpf(-x_extent, x_extent, u)
	$Scale/Point.scale = Vector3.ONE * lerpf(0.5, 1.5, u)
	$Rotate/Cube.rotation.y = u * TAU
	colour.albedo_color = Color.from_hsv(u, 0.8, 0.9)
	$Readout.text = "%d / %d   u = %.6f   seed %d" % [cursor + 1, values.size(), u, SEED]
