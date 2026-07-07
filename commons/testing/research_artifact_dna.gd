@tool
extends SceneTree
# Auto-research: capture every registered artifact in standard contexts.
#
# Reads commons/artifacts/registry/*.json, iterates artifacts, and for
# each one captures two variants:
#   bare       — artifact alone, orbit camera, no hands, no context
#   with_hands — artifact in FPV view, hands visible as scale + embodied
#                reference (the way a VR player would actually see it)
#
# The point: every artifact gets a face. Some artifacts are held (small
# orbs, tools); some are walked-to (creatures, vents, plates); some are
# placed in maps. The two variants make both readings visible.
#
# Output: user://artifact_dna/<category>/<lookup_name>/{bare,with_hands}.png
#
# CLI:
#   --category=<name>   only capture artifacts in this category
#   --limit=<N>         stop after N artifacts (for testing)
#   --include=<list>    comma-separated lookup_names; capture only these
#
# Examples:
#   godot_console --path . --xr-mode off --no-window \
#     --script res://commons/testing/research_artifact_dna.gd \
#     -- --category=hazards --limit=5
#
#   godot_console ... --script res://.../research_artifact_dna.gd \
#     -- --include=catalyst_foe,catalyst_vent,orb_test_rig

const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")
const REGISTRY_DIR := "res://commons/artifacts/registry/"

var _category_filter: String = ""
var _limit: int = -1
var _include_filter: Array[String] = []


func _init() -> void:
	_parse_args()
	# Debug — surface what made it through arg parsing so we can spot
	# Godot-vs-user-arg issues quickly.
	print("[artifact_dna] cmdline_args = %s" % str(OS.get_cmdline_args()))
	print("[artifact_dna] user_args = %s" % str(OS.get_cmdline_user_args()))
	print("[artifact_dna] category_filter=%s limit=%d include=%s" % [_category_filter, _limit, str(_include_filter)])

	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("artifact_dna")

	var artifacts: Array = _load_registry_artifacts()
	print("[artifact_dna] registry yielded %d artifacts" % artifacts.size())

	var count := 0
	var failed := 0
	for artifact in artifacts:
		if _category_filter != "" and artifact["category"] != _category_filter:
			continue
		if _include_filter.size() > 0 and not (artifact["lookup_name"] as String) in _include_filter:
			continue
		if _limit > 0 and count >= _limit:
			break

		var ok: bool = await _capture_artifact(artifact)
		if ok:
			count += 1
		else:
			failed += 1

	print("[artifact_dna] complete — %d captured, %d failed" % [count, failed])
	quit()


func _parse_args() -> void:
	# Try both — Godot 4 splits args at `--`. cmdline_user_args is the
	# safer source for script-specific flags, but we also scan the full
	# list as a fallback.
	var args: Array = []
	for a in OS.get_cmdline_user_args():
		args.append(a)
	for a in OS.get_cmdline_args():
		args.append(a)

	for a in args:
		if typeof(a) != TYPE_STRING:
			continue
		var s: String = a
		if s.begins_with("--category="):
			_category_filter = s.substr("--category=".length())
		elif s.begins_with("--limit="):
			_limit = int(s.substr("--limit=".length()))
		elif s.begins_with("--include="):
			var raw: String = s.substr("--include=".length())
			for item in raw.split(","):
				var trimmed: String = item.strip_edges()
				if trimmed != "":
					_include_filter.append(trimmed)


# Walk every registry json (skip .bak) and flatten into a list of
# {lookup_name, category, name, scene} dicts.
func _load_registry_artifacts() -> Array:
	var artifacts: Array = []
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		push_error("Cannot open registry dir: " + REGISTRY_DIR)
		return artifacts

	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json") and not fname.ends_with(".bak"):
			var path := REGISTRY_DIR + fname
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var text := file.get_as_text()
				file.close()
				var parsed = JSON.parse_string(text)
				if parsed is Dictionary and parsed.has("artifacts"):
					var entries = parsed["artifacts"]
					if entries is Dictionary:
						for key in entries:
							var entry = entries[key]
							if entry is Dictionary and entry.has("scene"):
								artifacts.append({
									"lookup_name": key,
									"category": entry.get("category", "uncategorized"),
									"name": entry.get("name", key),
									"scene": entry["scene"],
								})
		fname = dir.get_next()
	return artifacts


func _capture_artifact(artifact: Dictionary) -> bool:
	var scene_path: String = artifact["scene"]
	var lookup: String = artifact["lookup_name"]
	var category: String = artifact["category"]

	if not ResourceLoader.exists(scene_path):
		print("[artifact_dna] SKIP %s — scene missing: %s" % [lookup, scene_path])
		return false

	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		print("[artifact_dna] SKIP %s — load failed: %s" % [lookup, scene_path])
		return false

	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("artifact_dna/%s/%s" % [category, lookup])

	var bare_ok: bool = await _capture_variant(scene, lookup, category, "bare", false)
	var hands_ok: bool = await _capture_variant(scene, lookup, category, "with_hands", true)
	return bare_ok or hands_ok


func _capture_variant(
	scene: PackedScene, lookup: String, category: String,
	variant: String, with_hands: bool
) -> bool:
	var root := Node3D.new()
	root.name = "ArtifactDna_%s_%s" % [lookup, variant]
	VRCaptureRig.build_environment(root)

	# Instantiate the artifact at a standard position.
	var artifact_inst: Node = scene.instantiate()
	if artifact_inst == null:
		print("[artifact_dna] FAIL %s/%s — instantiate returned null" % [lookup, variant])
		return false

	# Most artifacts are Node3D. If not, wrap defensively.
	var artifact_node: Node3D = null
	if artifact_inst is Node3D:
		artifact_node = artifact_inst as Node3D
	else:
		# Skip artifacts that aren't spatial — they don't render.
		artifact_inst.queue_free()
		print("[artifact_dna] SKIP %s/%s — not a Node3D" % [lookup, variant])
		return false

	# Standard position: roughly in front of where the camera will be.
	# AABB-based lift happens after the tree is built so we can measure
	# the actual rendered extents of the artifact.
	var artifact_pos := Vector3(0, 0, -1.5)
	artifact_node.position = artifact_pos
	root.add_child(artifact_node)

	# Try to disable any motion / AI behaviour so the artifact sits still
	# for the capture. Best-effort — not every artifact supports it.
	if artifact_node.has_method("apply_grid_config"):
		artifact_node.call("apply_grid_config", {
			"speed": 0.0, "chase_speed": 0.0, "detection_radius": 0.0,
		})

	# Add to tree FIRST so _ready() runs and procedural meshes build,
	# then we can measure AABB and frame the camera.
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	# Let procedural meshes build before we measure them.
	for _i in range(20):
		await process_frame

	# Lift artifact so its AABB bottom touches the floor (y=0). This
	# fixes the "floor quad cuts the artifact in half" problem for
	# artifacts whose origin is at center-mass rather than at the base.
	var aabb := _compute_visible_aabb(artifact_node)
	if aabb.size.length() > 0.001:
		var lift := -aabb.position.y  # aabb.position is the min corner
		artifact_node.position.y += lift
		# Re-measure for camera framing.
		await process_frame
		aabb = _compute_visible_aabb(artifact_node)

	# Camera + hands depending on variant — added AFTER AABB known so
	# the orbit camera can frame the actual artifact extents.
	if with_hands:
		_add_hands(root)
		var cam := VRCaptureRig.first_person_camera(
			1.62, Vector3(0, 1.20, -1.50), 80.0)
		root.add_child(cam)
	else:
		# Orbit-style hero camera, framed against the artifact's AABB so
		# tiny things get close-ups and big things get pulled back.
		var cam := _build_framed_camera(aabb)
		root.add_child(cam)

	# Settle frames — some artifacts continue building / animating.
	for _i in range(25):
		await process_frame

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[artifact_dna] FAIL %s/%s — null image" % [lookup, variant])
		return false

	var out_path := "user://artifact_dna/%s/%s/%s.png" % [category, lookup, variant]
	img.save_png(out_path)
	print("[artifact_dna] saved %s/%s/%s" % [category, lookup, variant])
	return true


# Place both hands in a relaxed-forward pose, visible at the bottom of
# the FPV frame as scale + embodied reference.
func _add_hands(root: Node3D) -> void:
	var aim_dir := Vector3(0, -0.20, -1).normalized()
	var basis := VRCaptureRig.hand_basis(aim_dir, 1.0, true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF,
		Vector3(-0.22, 1.30, -0.55), basis, "Default pose", true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.RIGHT_HAND_GLTF,
		Vector3(+0.22, 1.30, -0.55), basis, "Default pose", false)


# Walk the subtree under `node` and return the combined world-space
# AABB of every VisualInstance3D descendant. Excludes the floor (which
# lives on `root`, not under `node`) so we measure only the artifact.
func _compute_visible_aabb(node: Node) -> AABB:
	var instances: Array = []
	_collect_visual_instances(node, instances)
	if instances.is_empty():
		return AABB()
	var combined: AABB = AABB()
	var first := true
	for v in instances:
		var vi: VisualInstance3D = v
		var local_aabb: AABB = vi.get_aabb()
		# Skip degenerate / empty AABBs (some VisualInstance3Ds report
		# zero-size during early frames).
		if local_aabb.size.length() < 0.0001:
			continue
		var global_aabb: AABB = vi.global_transform * local_aabb
		if first:
			combined = global_aabb
			first = false
		else:
			combined = combined.merge(global_aabb)
	return combined


func _collect_visual_instances(node: Node, result: Array) -> void:
	if node is VisualInstance3D:
		# Skip Camera3Ds (they're VisualInstance3D in Godot 4) and
		# OmniLights — we want geometry, not light/camera placement.
		if not (node is Camera3D) and not (node is Light3D):
			result.append(node)
	for child in node.get_children():
		_collect_visual_instances(child, result)


# Build an orbit-style camera that frames the given AABB. Distance and
# eye offset scale with the artifact size so tiny things get close-ups
# and big things get pulled back enough to fit in frame.
func _build_framed_camera(aabb: AABB) -> Camera3D:
	# Fallback if AABB is degenerate.
	if aabb.size.length() < 0.001:
		return VRCaptureRig.build_camera(
			Vector3(1.30, 1.85, -0.10),
			Vector3(0, 0.50, -1.50),
			55.0)

	var center: Vector3 = aabb.position + aabb.size * 0.5
	var diag: float = aabb.size.length()
	# Distance: roughly 1.3× the diagonal, with a floor so very small
	# artifacts don't get clipped by the near plane.
	var distance: float = max(diag * 1.3, 1.0)

	# Eye offset: front-right-above the artifact (hero angle).
	# Direction normalized so distance fully controls magnitude.
	var eye_dir: Vector3 = Vector3(0.55, 0.55, 0.65).normalized()
	var eye: Vector3 = center + eye_dir * distance
	return VRCaptureRig.build_camera(eye, center, 55.0)
