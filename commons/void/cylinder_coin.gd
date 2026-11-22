extends RefCounted
## The same stamped cylinder is used on the plinth and in the pickup lessons.

const Kit := preload("res://commons/artifacts/primitive_encounters/geometry.gd")

static func model(radius: float, thickness: float, monochrome: bool = false) -> Node3D:
	var coin := Node3D.new()
	coin.name = "CylinderCoin"
	var metal := Kit.material(Color("1c1e22") if monochrome else Color("a5a6a3"))
	metal.metallic = 0.25 if monochrome else 0.65
	metal.roughness = 0.42 if monochrome else 0.35
	var face := Kit.material(Color("f2f2ee") if monochrome else Color("d2d4cc"))
	face.metallic = 0.08 if monochrome else 0.48
	face.roughness = 0.48 if monochrome else 0.35
	_disc(coin, radius, thickness, 0.0, metal)
	for side in [-1.0, 1.0]:
		_disc(coin, radius * 0.83, thickness * 0.12, side * thickness * 0.49, face)
		var stamp := Kit.label(coin, "I" if side > 0 else "○", Vector3(0,0,side*thickness*0.57), 64)
		stamp.rotation.y = 0.0 if side > 0 else PI
		stamp.pixel_size = radius / 105.0
		if monochrome:
			stamp.modulate = Color("14161a")
			stamp.outline_modulate = Color("f2f2ee")
	return coin

static func _disc(parent: Node3D, radius: float, thickness: float, z: float, finish: Material) -> void:
	var disk := CylinderMesh.new()
	disk.top_radius = radius
	disk.bottom_radius = radius
	disk.height = thickness
	disk.radial_segments = 32
	var view := MeshInstance3D.new()
	view.mesh = disk
	view.material_override = finish
	view.rotation.x = PI / 2.0
	view.position.z = z
	parent.add_child(view)
