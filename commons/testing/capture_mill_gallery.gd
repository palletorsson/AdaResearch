# capture_mill_gallery.gd — one-run batch capturer for the pattern_mill DNA gallery.
# All variants share the mill's geometry (only the woven pattern differs), so a
# single fixed camera frames every one. Reads the delegate variants straight from
# the registry, applies each one's DNA via apply_grid_config, and saves a PNG.
extends SceneTree

const SCENE := "res://commons/artifacts/pattern_mill/pattern_mill.tscn"
const REGISTRY := "res://commons/artifacts/registry/pattern_mill.json"
const OUT_DIR := "user://mill_gallery/"


func _initialize() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	# Pull the delegate variants from the registry.
	var f := FileAccess.open(REGISTRY, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	var variants: Array = []
	for key in data.get("artifacts", {}).keys():
		var e = data["artifacts"][key]
		if str(e.get("delegate_to", "")) == "pattern_mill":
			variants.append({"id": key, "params": e.get("delegate_params", {})})
	print("[mill_gallery] variants: ", variants.size())

	var root := get_root()

	# Environment + lights (soft, like the multi-angle captures).
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
	cam.position = Vector3(0.85, 1.5, 3.15)
	root.add_child(cam)
	cam.look_at(Vector3(0.0, 0.82, 0.25), Vector3.UP)
	cam.fov = 48
	cam.make_current()

	var ps := load(SCENE) as PackedScene
	for v in variants:
		var inst = ps.instantiate()
		root.add_child(inst)
		if inst.has_method("apply_grid_config"):
			inst.apply_grid_config(v["params"])
		# Let _ready (deferred rebuild) + texture bake + a few draws settle.
		await create_timer(1.4).timeout
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path: String = OUT_DIR + str(v["id"]) + ".png"
		var err := img.save_png(path)
		print("[mill_gallery] %s -> %s (err %d)" % [str(v["id"]), path, err])
		inst.queue_free()
		await create_timer(0.3).timeout

	print("[mill_gallery] DONE")
	quit()
