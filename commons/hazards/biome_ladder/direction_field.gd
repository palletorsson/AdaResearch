extends Node3D
## Arrows and sampling read the same tile transform, in the encounter's reference frame.
var tiles: Array[MeshInstance3D] = []
var arrows: Array[MeshInstance3D] = []

func _ready() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# A flat filled arrow pointing +Z (toward the arrival), above the tile surface.
	for p in [Vector3(-0.035, 0, -0.48), Vector3(0.035, 0, -0.48), Vector3(-0.035, 0, 0.16),
		Vector3(0.035, 0, -0.48), Vector3(0.035, 0, 0.16), Vector3(-0.035, 0, 0.16),
		Vector3(-0.19, 0, 0.16), Vector3(0.19, 0, 0.16), Vector3(0, 0, 0.48)]:
		mesh.surface_add_vertex(p)
	mesh.surface_end()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(0.04, 0.04, 0.04)
	for tile in tiles:
		var arrow := MeshInstance3D.new(); arrow.mesh = mesh; arrow.material_override = material
		arrow.name = "DirectionArrow"; arrow.position.y = tile.mesh.size.y * 0.5 + 0.009
		arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tile.add_child(arrow); arrows.append(arrow)

func sample(world_position: Vector3) -> Vector3:
	var local := to_local(world_position)
	var column := floori((local.x + 6.0) / 2.0)
	var row := floori((local.z + 12.0) / 2.0)
	var direction := Vector3.BACK
	if column >= 0 and column < 6 and row >= 0 and row < 12:
		direction = direction.rotated(Vector3.UP, tiles[row * 6 + column].rotation.y)
	return (global_basis * direction).normalized()

func preview(start: Vector3, duration: float, speed: float) -> PackedVector3Array:
	var points := PackedVector3Array([start])
	var at := start
	for i in range(28):
		at += sample(at) * speed * duration / 28.0
		points.append(at)
	return points
