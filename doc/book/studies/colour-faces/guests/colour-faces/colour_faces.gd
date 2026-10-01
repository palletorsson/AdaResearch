extends Node3D
## The guest of "A colour has many faces": a wall of steps that shows a palette.
## It reads palette.tres, beside it: two colours, a mixing space and a sentence.
## The wall is 1.44 m wide, 1.0 m high and 0.2 m deep, stands on the ground at
## its own origin and has a collider: a walker is stopped by it and a marble
## rests on it. It names nothing outside its folder and declares no class_name.
## Change the palette file and this wall, and whoever else loads the file,
## changes with it.

const PALETTE := preload("res://guests/colour-faces/palette.tres")
const WIDTH := 1.44    # metres, the whole wall
const HEIGHT := 1.0
const DEPTH := 0.2
const INK := Color("ffffff")     # the kit's INK and SHADE, written out
const SHADE := Color("0d0620")

var boxes: Array[MeshInstance3D] = []

func _ready() -> void:
	var count: int = maxi(PALETTE.steps, 2)
	var wide := WIDTH / count
	for i in count:
		var box := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(wide, HEIGHT, DEPTH)
		box.mesh = mesh
		var paint := StandardMaterial3D.new()
		paint.albedo_color = PALETTE.step(i)
		paint.roughness = 0.8
		box.material_override = paint
		box.position = Vector3((i - (count - 1) / 2.0) * wide, HEIGHT / 2.0, 0)
		add_child(box)
		boxes.append(box)
	# The meshes are what the eye gets. This is what a marble and a walker get.
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(WIDTH, HEIGHT, DEPTH)
	collider.shape = shape
	collider.position.y = HEIGHT / 2.0
	body.add_child(collider)
	add_child(body)
	var plate := Label3D.new()
	plate.text = PALETTE.space
	plate.pixel_size = 0.004
	plate.font_size = 48
	plate.modulate = INK
	plate.outline_modulate = SHADE
	plate.outline_size = 12
	plate.position = Vector3(0, HEIGHT + 0.15, 0)
	add_child(plate)
