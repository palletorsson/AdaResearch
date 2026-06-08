# capture_loom_styles.gd — capture the new pattern_loom machine styles for the
# gallery. Registry-driven; per-style hand-tuned cameras (each style has a very
# different shape). The machine is centred in frame, so a later centre-crop squares it.
extends SceneTree

const SCENE := "res://commons/artifacts/pattern_loom/pattern_loom.tscn"
const REGISTRY := "res://commons/artifacts/registry/pattern_loom.json"
const OUT := "user://loom_styles/"
const NEW_STYLES := ["drum", "bolt", "fountain"]

# Per-style camera: {pos, look}. Geometry is identical within a style.
# Frontal (x=0) so symmetric machines centre; slight elevation for depth.
const CAMS := {
	"drum":     {"pos": Vector3(0.0, 1.05, 2.5), "look": Vector3(0.0, 0.62, 0.15)},
	"bolt":     {"pos": Vector3(0.0, 1.55, 3.2), "look": Vector3(0.0, 1.45, 0.05)},
	"fountain": {"pos": Vector3(0.0, 1.95, 2.3), "look": Vector3(0.0, 0.3, 0.0)},
}


func _initialize() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var f := FileAccess.open(REGISTRY, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	var variants: Array = []
	for key in data.get("artifacts", {}).keys():
		var e = data["artifacts"][key]
		if str(e.get("delegate_to", "")) == "pattern_loom":
			var p = e.get("delegate_params", {})
			if str(p.get("loom_style", "")) in NEW_STYLES:
				variants.append({"id": key, "params": p, "style": str(p.get("loom_style"))})
	print("[loom_styles] variants: ", variants.size())

	var root := get_root()
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.6, 0.52)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.66)
	env.ambient_light_energy = 0.85
	we.environment = env
	root.add_child(we)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-50, -35, 0)
	key_light.light_energy = 1.2
	root.add_child(key_light)
	var cam := Camera3D.new()
	cam.fov = 50
	root.add_child(cam)
	cam.make_current()

	var ps := load(SCENE) as PackedScene
	for v in variants:
		var inst = ps.instantiate()
		root.add_child(inst)
		if inst.has_method("apply_grid_config"):
			inst.apply_grid_config(v["params"])
		var c = CAMS[v["style"]]
		cam.position = c["pos"]
		cam.look_at(c["look"], Vector3.UP)
		await create_timer(1.4).timeout
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		img.save_png(OUT + str(v["id"]) + ".png")
		print("[loom_styles] saved ", v["id"])
		inst.queue_free()
		await create_timer(0.3).timeout
	print("[loom_styles] DONE")
	quit()
