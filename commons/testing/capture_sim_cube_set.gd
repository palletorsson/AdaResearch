# capture_sim_cube_set.gd — closeup catalog shots of the five sim-cube
# families (CubeWrapperLibrary), props-dna-gallery style: same camera rig,
# lighting and framing as capture_props_dna_gallery.gd. Output goes straight
# to the encyclopedia: public/sim-cube-set/<family>.png + manifest.json
# (GalleryView convention).
#   godot --path . --xr-mode off --no-window --script res://commons/testing/capture_sim_cube_set.gd
extends SceneTree

const CubeLib := preload("res://commons/grid/CubeWrapperLibrary.gd")

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)
const CAMERA_FOV: float = 32.0
const CAMERA_YAW: float = 0.55
const CAMERA_PITCH: float = -0.30
const FRAME_PADDING: float = 1.9

const SUBTITLES := {
	"gridglass": "glazed · steel · grid-lined — discrete worlds",
	"tank": "liquid tint · brass · hovering — continuous physics",
	"cage": "mesh bars · dark — agents, things that could get out",
	"shadowbox": "one open face · backlit — luminous curves",
	"openframe": "edges only · lab-white — growth, things that breathe",
	"table_display_1m": "1m table · frameless vertical panel — 2D content edge to edge",
	"table_display_2m": "2m table · frameless vertical panel — 2D content edge to edge",
	"podium": "the operating stand — a small interactive at hand height",
	"plinth": "the display column — small things held to the eye",
	"frame": "freestanding framed panel · hovering — flat work, wall-free",
}

var _viewport: SubViewport
var _camera: Camera3D
var _holder: Node3D
var _entries: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out_dir := ProjectSettings.globalize_path("res://").path_join("../ada_encyclopedia/public/sim-cube-set")
	DirAccess.make_dir_recursive_absolute(out_dir)

	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.own_world_3d = true
	var iso_world := World3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.15
	env.ssao_enabled = true
	env.ssao_intensity = 0.5
	env.glow_enabled = true
	env.glow_intensity = 0.40
	env.glow_bloom = 0.12
	iso_world.environment = env
	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.97, 0.92)
	key.rotation_degrees = Vector3(-35, 25, 0)
	key.shadow_enabled = true
	_viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.light_color = Color(0.85, 0.90, 1.0)
	fill.rotation_degrees = Vector3(-15, -120, 0)
	_viewport.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.60
	rim.rotation_degrees = Vector3(-80, 180, 0)
	_viewport.add_child(rim)

	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	_camera.near = 0.02
	_camera.far = 80.0
	_camera.current = true
	_viewport.add_child(_camera)
	_holder = Node3D.new()
	_viewport.add_child(_holder)

	var lib := CubeLib.new()
	for fam in CubeLib.FAMILIES:
		var node: Node3D = lib.build(fam)
		_holder.add_child(node)
		await create_timer(0.2).timeout
		var aabb: AABB = _combined_aabb(node)
		var center: Vector3 = aabb.position + aabb.size * 0.5
		var max_dim: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		var dist: float = max_dim * FRAME_PADDING + 0.5
		var offset := Vector3(
			sin(CAMERA_YAW) * cos(CAMERA_PITCH),
			-sin(CAMERA_PITCH),
			cos(CAMERA_YAW) * cos(CAMERA_PITCH)
		) * dist
		_camera.global_position = center + offset
		_camera.look_at(center, Vector3.UP)
		for i in 4:
			await process_frame
		var img: Image = _viewport.get_texture().get_image()
		var path := out_dir.path_join(fam + ".png")
		img.save_png(path)
		print("captured ", path)
		_entries.append({"id": fam, "image": "/sim-cube-set/" + fam + ".png",
			"label": fam, "subtitle": SUBTITLES.get(fam, ""),
			"notes": "wrapper family", "prop": "sim_cube"})
		for child in _holder.get_children():
			child.queue_free()
		await create_timer(0.05).timeout

	var manifest := {
		"version": 1,
		"description": "The five sim-cube wrapper families (CubeWrapperLibrary): one chassis — base plate, label plate, touch corner, accent line — five expressions, so housed simulations stay recognizable by nature. 2m housings on 1m cube plinths.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"fov_deg": CAMERA_FOV, "yaw_rad": CAMERA_YAW,
			"pitch_rad": CAMERA_PITCH,
			"framing": "AABB-orbit, %.2f×max_dim padding" % FRAME_PADDING},
		"entries": _entries,
	}
	var f := FileAccess.open(out_dir.path_join("manifest.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d cube-set entries" % _entries.size())
	quit(0)


func _combined_aabb(node: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var cur = stack.pop_back()
		if cur is VisualInstance3D:
			var a: AABB = cur.global_transform * cur.get_aabb()
			if first:
				aabb = a
				first = false
			else:
				aabb = aabb.merge(a)
		for child in cur.get_children():
			stack.append(child)
	return aabb

