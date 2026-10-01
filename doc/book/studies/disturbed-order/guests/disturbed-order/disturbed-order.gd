extends Node3D
## The guest of Disturbed order: a patch of Schotter floor, 1.24 m square.
## Twenty-five cubes of 0.2 m stand in a grid and are turned and slid by a
## seeded generator, more with every column: the first column is in order,
## the last may turn by `amplitude` degrees. The same seed returns the same
## patch. A body can step onto it: every cube has a collider that turns with it.
## A cube turns about its own middle, so a turned cube dips a little under
## the ground. The colour is written out: a guest names nothing outside its folder.

const BODY := Color("c6ff3d")   # the kit's BODY colour, written out
const EDGE := 0.2               # metres: one cube
const SPACING := 0.26           # metres from one cube's middle to the next

@export var amplitude := 45.0    # degrees: the most a cube of the last column may turn
@export var seed_value := 1968   # the patch's name: change it, look, keep the one you want

var columns := 5
var rows := 5
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = seed_value
	var mesh := BoxMesh.new()
	mesh.size = Vector3(EDGE, EDGE, EDGE)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	mesh.material = paint
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	# The patch is built round the guest's origin: the first cube stands in this corner.
	var corner := Vector3(-(columns - 1) * SPACING / 2.0, EDGE / 2.0, -(rows - 1) * SPACING / 2.0)
	for x in range(columns):
		var amount := float(x) / (columns - 1)                   # 0 in the first column, 1 in the last
		var turn := deg_to_rad(amplitude) * amount               # the most a cube of this column may turn
		var slide := EDGE / 2.0 * amplitude / 90.0 * amount      # and the most it may slide, in metres
		for z in range(rows):
			var cube := MeshInstance3D.new()
			cube.mesh = mesh
			cube.position = corner + Vector3(x * SPACING, 0.0, z * SPACING)
			cube.position += Vector3(rng.randf_range(-slide, slide), 0.0, rng.randf_range(-slide, slide))
			cube.rotation = Vector3(rng.randf_range(-turn, turn), rng.randf_range(-turn, turn), rng.randf_range(-turn, turn))
			var body := StaticBody3D.new()
			var collider := CollisionShape3D.new()
			collider.shape = shape
			body.add_child(collider)
			cube.add_child(body)
			add_child(cube)
	print("Disturbed order: seed ", rng.seed, ", amplitude ", amplitude)
