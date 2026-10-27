extends "res://commons/artifacts/wall_pattern_gallery/wall_pattern_gallery.gd"
## The original no-grid preview corridor, retained as one editable assembly.
## Its overlays used absolute museum-grid positions; Void mounts are local.
func _build_stand_in_cubes(positions: Array, cube_size: float) -> void:
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color(.28,.29,.32);mat.roughness=.85
	for gp in positions:
		var cube:=MeshInstance3D.new()
		var box:=BoxMesh.new();box.size=Vector3.ONE*cube_size
		cube.mesh=box;cube.material_override=mat
		cube.position=Vector3(gp)*cube_size
		cube.name="StandIn_%d_%d_%d"%[gp.x,gp.y,gp.z]
		add_child(cube)

func _add_overlay(world_pos: Vector3, cube_size: float, material: ShaderMaterial, gp: Vector3i) -> void:
	var first := get_child_count()
	super._add_overlay(world_pos,cube_size,material,gp)
	for i in range(first,get_child_count()):
		var face:Node3D=get_child(i)
		var local_at:Vector3=face.global_position
		face.transform=Transform3D(Basis.IDENTITY,local_at)

func _add_lights(grid_origin: Vector3, z_values: Array, total_size: float) -> void:
	var first := get_child_count()
	super._add_lights(grid_origin,z_values,total_size)
	for i in range(first,get_child_count()):
		var lamp:Node3D=get_child(i)
		lamp.position=lamp.global_position
