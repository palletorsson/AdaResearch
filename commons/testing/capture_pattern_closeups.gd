# capture_pattern_closeups.gd — photograph every pattern shader INSIDE Godot,
# full-frame closeup at canonical genes. These renders are the canonical
# images of the patterns (the rule as the engine sees it).
extends SceneTree

const DIRS := [
	"res://commons/artifacts/pattern_atlas_gallery/shaders/",
	"res://commons/artifacts/mamma_monster_gallery/shaders/",
]
const OUT := "user://pattern_closeups"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var cam := Camera3D.new()
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.62                              # CLOSEUP: crop inside the plate
	cam.position = Vector3(0, 0, 1.2)
	stage.add_child(cam)
	var plate := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.5, 1.05)
	plate.mesh = qm
	stage.add_child(plate)

	var abs_dir := ProjectSettings.globalize_path(OUT)
	if not DirAccess.dir_exists_absolute(abs_dir):
		DirAccess.make_dir_recursive_absolute(abs_dir)

	var files: Array = []
	for dir_path in DIRS:
		var d := DirAccess.open(dir_path)
		if d == null:
			continue
		for f in d.get_files():
			if f.ends_with(".gdshader"):
				files.append(dir_path + f)
	files.sort()

	var done: Array = []
	for path in files:
		var shader = load(path)
		if shader == null:
			continue
		var mat := ShaderMaterial.new()
		mat.shader = shader
		plate.material_override = mat
		for i in 3:
			await process_frame
		var img: Image = root.get_texture().get_image()
		if img:
			var name := String(path).get_file().replace(".gdshader", "")
			if img.save_png(abs_dir.path_join(name + ".png")) == OK:
				done.append(name)
				print("  ok ", name)
	var f := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"count": done.size(), "shaders": done}, " "))
	f.close()
	print("closeups: ", done.size())
	quit()
