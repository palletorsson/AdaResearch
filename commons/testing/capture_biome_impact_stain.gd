extends SceneTree

## Photographs the ground answering catalyst fire.
##
## Builds a bare floor with a biome layer, marks impacts in a widening
## pattern with different mode tints, and shoots the floor from above at
## four stages: clean, three shots, ten shots, and after the fade.
## Output: user://biome_stain/<stage>.png

const BiomeScript := preload("res://commons/grid/GridBiomeComponent.gd")
const OUT_DIR := "user://biome_stain"

func _initialize() -> void:
	get_root().size = Vector2i(760, 760)
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	var stage := Node3D.new()
	get_root().add_child(stage)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.07, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.7)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-70, -30, 0)
	sun.light_energy = 0.7
	stage.add_child(sun)

	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.environment = env
	stage.add_child(cam)
	cam.make_current()

	# 14x14 floor, one declared seed so the layer is live
	var n := 14
	var structure: Array = []
	var biome: Array = []
	for r in n:
		var srow: Array = []
		var brow: Array = []
		for c in n:
			srow.append("1")
			brow.append("flora:scatter:seed" if (c == 2 and r == 2) else " ")
		structure.append(srow)
		biome.append(brow)

	# visible floor slab under the stain
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(n, 0.2, n)
	floor_mesh.mesh = box
	floor_mesh.position = Vector3((n - 1) * 0.5, -0.1, (n - 1) * 0.5)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.13, 0.14, 0.17)
	fmat.roughness = 0.9
	floor_mesh.material_override = fmat
	stage.add_child(floor_mesh)

	var comp = BiomeScript.new()
	stage.add_child(comp)
	comp.initialize(stage, 1.0, 0.0)
	comp.generate(biome, structure, 0, {"presence": true})
	await process_frame

	var center := Vector3((n - 1) * 0.5, 0, (n - 1) * 0.5)
	cam.global_position = center + Vector3(0.1, 12.5, 6.5)
	cam.look_at(center, Vector3.UP)

	var shoot := func(label: String) -> void:
		await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("%s/%s.png" % [OUT_DIR, label])
		print("captured %s" % label)

	await shoot.call("0_clean")

	# three shots: chromatic magenta, forces amber, waveform cyan
	var TINTS := {
		"chromatic": Color(0.95, 0.35, 0.85),
		"forces": Color(1.0, 0.78, 0.25),
		"waveform": Color(0.3, 0.85, 0.95),
		"branching": Color(0.45, 0.95, 0.4),
	}
	comp.mark_impact(Vector3(4, 0.4, 5), TINTS["chromatic"])
	comp.mark_impact(Vector3(7, 0.4, 4), TINTS["forces"])
	comp.mark_impact(Vector3(9, 0.4, 8), TINTS["waveform"])
	await shoot.call("1_three_shots")

	# a firefight: a walked line of chromatic fire plus a branching cluster
	for i in 5:
		comp.mark_impact(Vector3(3 + i, 0.4, 9), TINTS["chromatic"])
	for i in 4:
		comp.mark_impact(Vector3(10 + (i % 2), 0.4, 10 + int(i / 2)), TINTS["branching"])
	await shoot.call("2_firefight")

	# age everything past the fade and let the clock reap it
	var fade: float = 8.0
	for m in (comp.get("_impacts") as Array):
		m["born_s"] = float(Time.get_ticks_msec()) * 0.001 - (fade + 1.0)
	comp._process(0.5)
	await shoot.call("3_faded")

	print("DONE -> %s" % OUT_DIR)
	quit(0)
