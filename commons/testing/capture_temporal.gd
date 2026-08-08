## capture_temporal.gd — photograph an artifact TWICE and keep both.
##
## WHY THIS EXISTS. Every quality gate in this project is a single still:
## cabinet_sweep writes one PNG per variant, artifact_dna_critic diffs two PNGs of
## DIFFERENT variants, the galleries publish stills, tools/render_lint.py measures
## stills. A defect that lives in TIME is therefore structurally unmeasurable by all
## of them, and one has been accumulating unpenalised.
##
## A blind investigation found seven artifacts writing a fresh `randf` into a MATERIAL
## on a path that runs every rendered frame. line_builder_3d re-rolls
## glow_intensity in `_create_line_material()` from `_process`, so its emission
## flickers at framerate across 72 placements, and a new ShaderMaterial and ArrayMesh
## are allocated per frame. Nothing could score it: photograph it once and it looks
## fine, photograph it twice and the two photographs disagree.
##
## Worse, in that artifact the sanctioned cure for unseeded randf — a seed export plus
## `dna.fixture` — had been used to branch AROUND the flicker on the MEASUREMENT path.
## The bench was pinned clean while the product kept strobing. An instrument that only
## ever looks at the pinned path cannot see that, by construction.
##
## So: settle, shoot, wait, shoot again. A stable artifact returns two identical
## frames. Anything that moves without being asked to move shows up as a difference,
## and tools/temporal_lint.py turns that difference into a number.
##
## THIS MEASURES INSTABILITY, NOT ANIMATION. Plenty of artifacts here are meant to move
## — a pendulum swings, a soft body settles, a simulation runs. The question this asks
## is narrower and is asked of the DEFAULT state an artifact ships in: does the surface
## change when nothing asked it to. Read the number beside the artifact, never alone.
##
## Usage:
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/capture_temporal.gd -- \
##     --scene=res://path/to.tscn --out=res://ada_run/temporal --label=name [--gap=1.0]
extends SceneTree

const RES := 640
const FOV := 34.0
const YAW := 0.62
const PITCH := -0.26
const PAD := 1.9
## Long enough for a build to finish and a first physics tick to pass, short enough
## that the watchdog never sees a stall.
const SETTLE := 1.2


func _initialize() -> void:
	var scene_path := ""
	var out_dir := "res://ada_run/temporal"
	var label := ""
	var gap := 1.0
	# THE SWEEP APPLIES THESE AND THIS DID NOT, so the two benches disagreed about how
	# big an artifact is. Measured: interactive_point_origin_force filled 4.65% of the
	# frame in its published bite report and 0.50% here, and four artifacts were called
	# "too empty to judge" on the strength of that difference. dna.framing moves the
	# camera in for an axis that lives in a detail; dna.fixture is what makes an artifact
	# whose _ready() is gated build anything at all. An instrument that ignores both is
	# not looking at the same object the rest of the toolchain is.
	var framing := 1.0
	var fixture_json := ""
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if a.begins_with("--scene="):
			scene_path = a.substr(8)
		elif a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--label="):
			label = a.substr(8)
		elif a.begins_with("--gap="):
			gap = maxf(0.1, float(a.substr(6)))
		elif a.begins_with("--framing="):
			framing = clampf(float(a.substr(10)), 0.05, 20.0)
		elif a.begins_with("--fixture="):
			fixture_json = a.substr(10)
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_error("capture_temporal: no scene at " + scene_path)
		quit(2)
		return
	if label == "":
		label = scene_path.get_file().get_basename()
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run(scene_path, out_dir, label, gap, framing, fixture_json)


func _run(scene_path: String, out_dir: String, label: String, gap: float,
		framing: float, fixture_json: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(RES, RES)
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.055, 0.070)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.rotation_degrees = Vector3(-42, -35, 0)
	vp.add_child(key)
	var cam := Camera3D.new()
	cam.fov = FOV
	cam.environment = env
	vp.add_child(cam)
	cam.current = true

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("capture_temporal: could not load " + scene_path)
		quit(2)
		return
	var inst: Node = packed.instantiate()
	# Fixture BEFORE add_child, the sweep's own rule: _ready() must build with it.
	if fixture_json != "":
		var j := JSON.new()
		if j.parse(fixture_json) == OK and j.data is Dictionary:
			for k in (j.data as Dictionary):
				var holder: Node = _holder_of(inst, String(k))
				if holder != null:
					holder.set(String(k), (j.data as Dictionary)[k])
				inst.set_meta("config_%s" % String(k), (j.data as Dictionary)[k])
	vp.add_child(inst)
	await create_timer(SETTLE).timeout

	var box := _subtree_aabb(inst)
	var c := box.get_center()
	var radius: float = maxf(box.size.length() * 0.5, 0.2)
	var dist: float = radius / tan(deg_to_rad(FOV * 0.5)) * PAD * framing
	var dir := Vector3(sin(YAW) * cos(PITCH), -sin(PITCH), cos(YAW) * cos(PITCH))
	cam.position = c + dir * dist
	cam.look_at(c, Vector3.UP)

	await process_frame
	await process_frame
	var a: Image = vp.get_texture().get_image()
	a.save_png("%s/%s__t0.png" % [out_dir, label])
	# The whole point: let TIME pass with nothing asked of the artifact.
	await create_timer(gap).timeout
	await process_frame
	var b: Image = vp.get_texture().get_image()
	b.save_png("%s/%s__t1.png" % [out_dir, label])

	var f := FileAccess.open("%s/_done.txt" % out_dir, FileAccess.WRITE)
	if f:
		f.store_string("temporal %s gap=%.2f\n" % [label, gap])
		f.close()
	print("TEMPORAL %s  two frames %.2fs apart" % [label, gap])
	quit(0)


## Breadth-first, the same rule capture_config_sweep uses: the node that OWNS the
## property, which is often not the root.
func _holder_of(node: Node, key: String) -> Node:
	if key in node:
		return node
	var queue: Array = [node]
	while not queue.is_empty():
		var n: Node = queue.pop_front()
		for c in n.get_children():
			if key in c:
				return c
			queue.append(c)
	return null


func _subtree_aabb(node: Node) -> AABB:
	var out := AABB()
	var have := false
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi := n as MeshInstance3D
			var b: AABB = mi.global_transform * mi.get_aabb()
			out = b if not have else out.merge(b)
			have = true
		for ch in n.get_children():
			stack.append(ch)
	return out if have else AABB(Vector3.ZERO, Vector3.ONE)
