extends Node3D

# 0 every cell alike   1 chessboard   2 stripes   3 hue from x + z
@export_enum("every cell alike", "(x + z) % 2 chessboard", "x % 3 stripes", "hue from x + z") var rhythm := 1

var n := 8                              # cubes along one side
var spacing := 0.5                      # metres from one cube's middle to the next
var light := Color(0.62, 0.55, 0.4)     # two colours of our own
var dark := Color(0.08, 0.16, 0.2)
var ghost_x := 5                        # the cell that is there for the eye and not for a body
var ghost_z := 5
var cubes: Array[MeshInstance3D] = []

func _ready() -> void:
	var scene: PackedScene = load("res://parts/cube_part.tscn")
	for z in range(n):
		for x in range(n):
			var cube: MeshInstance3D = scene.instantiate()
			add_child(cube)
			cube.position = Vector3(x * spacing, 0.25, z * spacing)
			var material := StandardMaterial3D.new()
			material.albedo_color = colour_of(x, z)
			cube.material_override = material
			if x == ghost_x and z == ghost_z:
				cube.get_node("Body/CollisionShape3D").disabled = true
			cubes.append(cube)

func colour_of(x: int, z: int) -> Color:
	if rhythm == 0:
		return light
	if rhythm == 1:
		if (x + z) % 2 == 0:
			return light
		return dark
	if rhythm == 2:
		if x % 3 == 0:
			return dark
		return light
	return Color.from_hsv(float(x + z) / (2 * n), 0.8, 0.6)

func count_materials() -> int:
	var seen: Array = []
	for cube in cubes:
		if not seen.has(cube.material_override):
			seen.append(cube.material_override)
	return seen.size()
