extends Node3D
## One wall of steps from `first` to `second`, mixed in `space`.

const Look := preload("res://supplied/look.gd")
const Oklab := preload("res://oklab.gd")

@export var space := "rgb"               # the space the two colours are mixed in
@export var steps := 9                   # how many steps the wall has
@export var size := Vector2(0.4, 0.45)   # one step: its width and its height, in metres
@export var first := Look.BODY           # the colour of the first step
@export var second := Look.BODY.inverted()   # the colour of the last step

var boxes: Array[MeshInstance3D] = []

func _ready() -> void:
	build()

func build() -> void:
	steps = maxi(steps, 2)
	for i in steps:
		var t := i / float(steps - 1)
		var box := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(size.x, size.y, 0.2)
		box.mesh = mesh
		box.material_override = Look.paint(mix(t))
		box.position = Vector3((i - (steps - 1) / 2.0) * size.x, size.y / 2.0, 0)
		add_child(box)
		box.create_trimesh_collision()
		boxes.append(box)

func mix(t: float) -> Color:
	if space == "rgb":
		return first.lerp(second, t)
	if space == "hsv":
		var turn := second.h - first.h
		if turn > 0.5:
			turn -= 1.0
		elif turn < -0.5:
			turn += 1.0
		var h := fposmod(first.h + turn * t, 1.0)
		return Color.from_hsv(h, lerpf(first.s, second.s, t), lerpf(first.v, second.v, t))
	if space == "linear":
		var light := first.srgb_to_linear().lerp(second.srgb_to_linear(), t)
		return light.linear_to_srgb()
	if space == "oklab":
		return Oklab.mix(first, second, t)
	push_error("wall.gd has no space called " + space)
	return Color.BLACK
