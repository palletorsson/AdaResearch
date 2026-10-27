extends "res://algorithms/randomness/random_object_spawner.gd"
## Trial-only adapter (randomness_04) for the original random_object_spawner
## (f1_random_object_spawner_5_6 and _6_6). Spawning, capacity, timing, the wood-knock
## synthesis and every random draw are the source's own.
##
## Two seams, read from the source (static) and checked by the native case `spawner`:
## 1. spawn_cube() calls play_wood_sound(new_cube.position): a LOCAL position, which the
##    source assigns to wood_sound.global_position. Every knock therefore sounded near
##    world (0, 1, 0), above the roof, not at the arriving cube; Void floors stand 6-30 m
##    below. Here the same position is mapped through this placement's own transform, so
##    it stays right when the editor moves or turns the placement.
## 2. The template cube is hidden and the first arrival comes after about one second.
##    The exporter snapshots before that, so the placement exported no model.
##    prepare_editor_preview() (exporter only) shows the hidden template at the spawn
##    point with a label. It is a marker, not an arrival.
func play_wood_sound(at_position: Vector3) -> void:
	super.play_wood_sound(to_global(at_position))

func prepare_editor_preview() -> void:
	for cube in spawned_cubes:
		if is_instance_valid(cube) and cube.is_visible_in_tree(): return
	if has_node("SpawnPointMarker"): return
	var marker := Node3D.new()
	marker.name = "SpawnPointMarker"
	add_child(marker)
	var cube := MeshInstance3D.new()
	var mesh := BoxMesh.new();mesh.size = Vector3.ONE * .1
	cube.mesh = mesh;cube.position = spawn_position
	var wood := StandardMaterial3D.new();wood.albedo_color = Color(.62, .45, .27)
	cube.material_override = wood;marker.add_child(cube)
	var label := Label3D.new()
	label.text = "RANDOM ARRIVALS AT THIS POINT\nCAPACITY %d / FIRST CUBE AFTER ~1 s IN GODOT" % capacity
	label.font_size = 28;label.pixel_size = .0015;label.position = spawn_position + Vector3(0, .25, 0)
	marker.add_child(label)
