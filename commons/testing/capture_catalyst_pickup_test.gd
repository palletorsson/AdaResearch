## Quick test: render the catalyst_pickup in two states (READY vs TAKEN).
##
## Run:
##   "/c/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##     --xr-mode off --no-window \
##     --script res://commons/testing/capture_catalyst_pickup_test.gd
extends SceneTree

const PICKUP_SCENE: String = "res://commons/artifacts/catalyst_pickup/catalyst_pickup.tscn"
const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)

var _vp: SubViewport
var _camera: Camera3D
var _holder: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_vp = SubViewport.new()
	_vp.size = CAPTURE_SIZE
	_vp.own_world_3d = true
	var w := World3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.65)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.15
	w.environment = env
	_vp.world_3d = w
	_vp.msaa_3d = Viewport.MSAA_8X
	_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_vp)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.0
	key.rotation_degrees = Vector3(-40, 30, 0)
	_vp.add_child(key)

	_camera = Camera3D.new()
	_camera.fov = 35.0
	_camera.position = Vector3(0.4, 0.55, 0.9)
	_camera.look_at(Vector3(0.0, 0.45, 0.0), Vector3.UP)
	_vp.add_child(_camera)

	_holder = Node3D.new()
	_vp.add_child(_holder)

	var out_dir := "user://catalyst_pickup_test"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var packed: PackedScene = load(PICKUP_SCENE)
	for state in ["ready", "taken"]:
		var node: Node3D = packed.instantiate()
		node.set("sequence_name", "randomness")
		node.set("label_text", "CHAOS CATALYST")
		node.set("orb_color", Color(0.95, 0.55, 0.20))
		node.set("accent_color", Color(0.95, 0.55, 0.20))
		node.set("claimed", state == "taken")
		_holder.add_child(node)
		await create_timer(0.15).timeout
		await get_root().get_tree().process_frame
		await get_root().get_tree().process_frame
		var img: Image = _vp.get_texture().get_image()
		img.save_png("%s/pickup_%s.png" % [out_dir, state])
		print("[%s] saved" % state)
		for c in _holder.get_children():
			c.queue_free()
		await create_timer(0.05).timeout

	print("DONE")
	quit(0)
