extends Node3D
## The chessboard, as a guest of the room: a small floor of cubes, four by four.
## It is the lesson's chessboard.gd with three things changed. The cube part is
## read from this folder and is 0.3 m on an edge: sixteen of them fit on one
## place, and a walker can step onto them. The two colours are two of the course
## look, written out here as hex, because a guest names nothing outside its
## folder. And there is one rule, not four: colour_of(). It is yours to replace.

var n := 4                              # cubes along one side
var spacing := 0.3                      # metres from one cube's middle to the next
var light := Color("c6ff3d")            # BODY, the look's lime
var dark := Color("22d9ff")             # SECOND, the look's cyan
var ghost_x := 0                        # the cell that is there for the eye and not for a body
var ghost_z := 3
var cubes: Array[MeshInstance3D] = []

func _ready() -> void:
	var scene: PackedScene = load("res://guests/chessboard/cube_part.tscn")
	for z in range(n):
		for x in range(n):
			var cube: MeshInstance3D = scene.instantiate()
			add_child(cube)
			cube.position = Vector3(x * spacing, 0.15, z * spacing)
			var material := StandardMaterial3D.new()
			material.albedo_color = colour_of(x, z)
			material.roughness = 0.8
			cube.material_override = material
			if x == ghost_x and z == ghost_z:
				cube.get_node("Body/CollisionShape3D").disabled = true
			cubes.append(cube)

func colour_of(x: int, z: int) -> Color:
	if (x + z) % 2 == 0:
		return light
	return dark
