# capture_pattern_dna.gd — sweep the pattern genome. For each tradition x
# variant, render one full-frame plate with the variant's genes and save
# user://pattern_dna/<tradition>__<variant>.png + manifest.json.
extends SceneTree

const DNA := "res://commons/artifacts/pattern_atlas_gallery/pattern_dna.json"
const SHADER_DIR := "res://commons/artifacts/pattern_atlas_gallery/shaders/"
const OUT := "user://pattern_dna"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var dna = JSON.parse_string(FileAccess.get_file_as_string(DNA))
	var stage := Node3D.new()
	root.add_child(stage)
	var cam := Camera3D.new()
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.86
	cam.position = Vector3(0, 0, 1.5)
	stage.add_child(cam)
	var plate := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.5, 1.05)
	plate.mesh = qm
	stage.add_child(plate)

	var abs_dir := ProjectSettings.globalize_path(OUT)
	if not DirAccess.dir_exists_absolute(abs_dir):
		DirAccess.make_dir_recursive_absolute(abs_dir)

	var entries: Array = []
	for trad in dna.traditions:
		var shader = load(SHADER_DIR + trad + ".gdshader")
		if shader == null:
			continue
		for vname in dna.variants:
			var v = dna.variants[vname]
			var mat := ShaderMaterial.new()
			mat.shader = shader
			for g in ["g_scale", "g_weight", "g_wobble"]:
				if v.has(g):
					mat.set_shader_parameter(g, float(v[g]))
			plate.material_override = mat
			await process_frame
			await process_frame
			var img: Image = root.get_texture().get_image()
			if img:
				var fname := "%s__%s.png" % [trad, vname]
				if img.save_png(abs_dir.path_join(fname)) == OK:
					entries.append({"tradition": trad, "variant": vname, "file": fname})
					print("  ok ", fname)
	var f := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"count": entries.size(), "entries": entries,
		"variants": dna.variants, "genes": dna.genes}, " "))
	f.close()
	print("pattern_dna: ", entries.size(), " captures")
	quit()
