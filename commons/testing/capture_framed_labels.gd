# capture_framed_labels.gd — BEFORE/AFTER gallery of the framed-text principal:
# each subject captured twice, camera aimed at its first hanging Label3D —
# once raw (the floating annotation) and once through LabelFramer (the label
# with a body). Output: ../ada_encyclopedia/public/framed-labels/ + manifest
# (GalleryView convention -> /framed-labels page).
#   godot --path . --xr-mode off --no-window --script res://commons/testing/capture_framed_labels.gd
extends SceneTree

const LabelFramer := preload("res://commons/grid/LabelFramer.gd")

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.055, 0.055, 0.070)

# registry lookups with billboarded hanging labels, headless-safe
const SUBJECTS := [
	"grid_2d_4x4", "grid_3d_4x4x4", "entropy_meter", "magritte_pipe",
	"phase_cube", "closest_pair", "voronoi_visualization", "ftc_bridge",
	"russell_set_box", "xyz_coordinates", "index_visualizer", "strange_attractors",
]

var _viewport: SubViewport
var _camera: Camera3D
var _holder: Node3D
var _entries: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out_dir := ProjectSettings.globalize_path("res://").path_join("../ada_encyclopedia/public/framed-labels")
	DirAccess.make_dir_recursive_absolute(out_dir)

	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.own_world_3d = true
	var world := World3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.35
	world.environment = env
	_viewport.world_3d = world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	get_root().add_child(_viewport)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.2
	key.rotation_degrees = Vector3(-35, 25, 0)
	_viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.5
	fill.light_color = Color(0.85, 0.90, 1.0)
	fill.rotation_degrees = Vector3(-15, -120, 0)
	_viewport.add_child(fill)

	_camera = Camera3D.new()
	_camera.fov = 40.0
	_camera.near = 0.02
	_camera.far = 80.0
	_camera.current = true
	_viewport.add_child(_camera)
	_holder = Node3D.new()
	_viewport.add_child(_holder)

	for name in SUBJECTS:
		var scene_path := _find_scene(name)
		if scene_path == "" or not ResourceLoader.exists(scene_path):
			print("skip (no scene): ", name)
			continue
		var packed = load(scene_path)
		if packed == null:
			continue
		var inst = packed.instantiate()
		if not (inst is Node3D):
			if inst:
				inst.free()
			continue
		_holder.add_child(inst)
		await create_timer(0.4).timeout

		var label := _first_hanging_label(inst)
		if label == null:
			print("skip (no hanging label): ", name)
			inst.queue_free()
			await create_timer(0.05).timeout
			continue

		_aim_at_label(label)
		for i in 4:
			await process_frame
		_viewport.get_texture().get_image().save_png(
				out_dir.path_join(name + "__before.png"))

		LabelFramer.frame_labels(inst)
		_aim_at_label(label)
		for i in 4:
			await process_frame
		_viewport.get_texture().get_image().save_png(
				out_dir.path_join(name + "__after.png"))
		print("captured ", name)
		_entries.append({"id": name + "__before",
			"image": "/framed-labels/" + name + "__before.png",
			"label": name, "subtitle": "hanging (before)",
			"notes": "billboarded Label3D — the floating annotation", "prop": name})
		_entries.append({"id": name + "__after",
			"image": "/framed-labels/" + name + "__after.png",
			"label": name, "subtitle": "framed (after)",
			"notes": "LabelFramer at spawn — bezel + panel body, billboard off", "prop": name})

		inst.queue_free()
		await create_timer(0.05).timeout

	var manifest := {
		"version": 1,
		"description": "The framed-text principal, before/after: every hanging (billboarded) Label3D gets a readout-style body at spawn — de-billboarded, bezel + panel added behind the glyphs, the node kept alive for live text updates. Surface labels are untouched. commons/grid/LabelFramer.gd, hooked in GridInteractablesComponent + sim_cube.",
		"entries": _entries,
	}
	var f := FileAccess.open(out_dir.path_join("manifest.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d framed-label captures" % _entries.size())
	quit(0)


func _first_hanging_label(root: Node) -> Label3D:
	var stack: Array = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is Label3D and str(cur.text).strip_edges() != "" \
				and (cur.billboard != BaseMaterial3D.BILLBOARD_DISABLED
					or cur.has_meta("label_framed")):
			return cur
		for c in cur.get_children():
			stack.append(c)
	return null


func _aim_at_label(label: Label3D) -> void:
	var pos: Vector3 = label.global_position
	var fwd: Vector3 = label.global_transform.basis.z
	if fwd.length() < 0.01:
		fwd = Vector3(0, 0, 1)
	_camera.global_position = pos + fwd.normalized() * 1.0 \
			+ Vector3(0.25, 0.12, 0)
	_camera.look_at(pos, Vector3.UP)


func _find_scene(lookup: String) -> String:
	var dir := DirAccess.open("res://commons/artifacts/registry/")
	if dir == null:
		return ""
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json"):
			var file := FileAccess.open("res://commons/artifacts/registry/" + f, FileAccess.READ)
			if file:
				var parsed = JSON.parse_string(file.get_as_text())
				if parsed is Dictionary and parsed.get("artifacts", {}).has(lookup):
					return str(parsed["artifacts"][lookup].get("scene", ""))
		f = dir.get_next()
	return ""
