extends Node3D
## A full-scale, walkable plan: five by five one-metre cells, with a flush top.
## A cell is an area; the six boundary lines along each axis are not five points.
const SIDE := 5
const PITCH := 1.0

func _ready() -> void:
	var light := StandardMaterial3D.new()
	light.albedo_color = Color(0.64, 0.72, 0.71)
	light.roughness = 0.9
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.35, 0.46, 0.48)
	dark.roughness = 0.9
	var tile := BoxMesh.new()
	tile.size = Vector3(0.988, 0.06, 0.988)
	for z in range(SIDE):
		for x in range(SIDE):
			var mesh := MeshInstance3D.new()
			mesh.name = "Cell_%d_%d" % [x,z]
			mesh.mesh = tile
			mesh.material_override = light if (x+z)%2 == 0 else dark
			# Lift the visible paint 6 mm above the host floor to avoid coplanar flicker.
			# The continuous walkable collider remains flush at y=0.
			mesh.position = Vector3(x-2, -0.024, z-2)
			add_child(mesh)
	var body := StaticBody3D.new()
	body.name = "PlanFloor"
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5, 0.06, 5)
	shape.shape = box
	shape.position.y = -0.03
	body.add_child(shape)
	for axis in range(2):
		for index in range(SIDE):
			var label := Label3D.new()
			label.text = str(index)
			label.font_size = 40
			label.pixel_size = 0.003
			label.modulate = Color(0.08,0.15,0.18)
			label.rotation_degrees.x = -90
			label.position = Vector3(index-2,0.01,-2.3) if axis == 0 else Vector3(-2.3,0.01,index-2)
			add_child(label)
