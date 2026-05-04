extends SceneTree

## Headless batch normalizer.
##
## For every dressing-room JSON:
##   1. Look up the artifact's scene path in the registry.
##   2. Instantiate the scene off-tree, measure its mesh AABB.
##   3. Set footprint = [ceil(width), ceil(depth), ceil(height)] in cells.
##   4. Clamp artifact_offset.y so the lowest mesh point sits at y >= 0
##      (the artifact never clips into or floats above the floor).
##   5. Center on X/Z (offset.x = -aabb.center.x, offset.z = -aabb.center.z).
##   6. If the offset patch would have to exceed ESCALATION_THRESHOLD_M, log
##      an entry to doc/reports/dressing_room_escalations.md instead of
##      papering over the artifact bug.
##
## Run:
##   godot --xr-mode off --headless --script res://commons/artifacts/catalog/normalize_dressing_rooms_batch.gd

const ROOMS_DIR := "res://commons/artifacts/dressing_rooms/"
const REGISTRY_DIR := "res://commons/artifacts/registry/"
const ESCALATION_REPORT_PATH := "res://doc/reports/dressing_room_escalations.md"
const ESCALATION_THRESHOLD_M := 0.3
const FOOTPRINT_CELL_M := 1.0
const FOOTPRINT_MIN_CELLS := 1
const FOOTPRINT_MAX_CELLS := 6

var _registry_cache: Dictionary = {}   # lookup_name → entry dict
var _escalations: Array = []
var _stats := {
	"total": 0, "missing_scene": 0, "load_failed": 0, "no_meshes": 0,
	"changed": 0, "unchanged": 0, "escalated": 0,
}


func _init() -> void:
	print("[normalize] starting batch sweep")
	_load_registry()
	var sandbox := Node3D.new()
	get_root().add_child(sandbox)
	var dir := DirAccess.open(ROOMS_DIR)
	if dir == null:
		push_error("could not open " + ROOMS_DIR)
		quit(1)
		return
	var rooms: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json") and not fname.begins_with("_"):
			rooms.append(fname.get_basename())
		fname = dir.get_next()
	dir.list_dir_end()
	rooms.sort()
	print("[normalize] %d rooms found" % rooms.size())

	for i in range(rooms.size()):
		_process_room(rooms[i], sandbox)
		if (i + 1) % 100 == 0:
			print("  ...processed %d / %d" % [i + 1, rooms.size()])

	sandbox.queue_free()
	_write_escalation_report()
	_print_summary()
	quit(0)


func _load_registry() -> void:
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		push_error("could not open " + REGISTRY_DIR)
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var raw := FileAccess.get_file_as_string(REGISTRY_DIR + fname)
			var parsed = JSON.parse_string(raw)
			if parsed is Dictionary:
				var arts: Variant = parsed.get("artifacts", parsed)
				if arts is Dictionary:
					for key in arts.keys():
						var entry = arts[key]
						if entry is Dictionary:
							var lookup: String = entry.get("lookup_name", key)
							if lookup is String and not lookup.is_empty():
								_registry_cache[lookup] = entry
		fname = dir.get_next()
	dir.list_dir_end()
	print("[normalize] registry: %d artifacts indexed" % _registry_cache.size())


func _process_room(lookup: String, sandbox: Node3D) -> void:
	_stats.total += 1
	var room_path := ROOMS_DIR + lookup + ".json"
	var raw := FileAccess.get_file_as_string(room_path)
	if raw.is_empty():
		_stats.load_failed += 1
		return
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		_stats.load_failed += 1
		return
	var d: Dictionary = parsed

	var info: Dictionary = _registry_cache.get(lookup, {})
	var scene_path: String = String(info.get("scene", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		_stats.missing_scene += 1
		return
	var ps: PackedScene = load(scene_path) as PackedScene
	if ps == null:
		_stats.load_failed += 1
		return
	var inst = ps.instantiate()
	if inst == null:
		_stats.load_failed += 1
		return
	sandbox.add_child(inst)
	var aabb: AABB = _compute_aabb(inst, sandbox)
	sandbox.remove_child(inst)
	inst.queue_free()

	if aabb.size.length_squared() < 1e-6:
		_stats.no_meshes += 1
		return

	# ── Apply rules ──────────────────────────────────────────────────
	var changed := false
	var reasons: Array[String] = []

	# Footprint from AABB (cells, ceil).
	var fw: int = clampi(int(ceil(aabb.size.x / FOOTPRINT_CELL_M)),
		FOOTPRINT_MIN_CELLS, FOOTPRINT_MAX_CELLS)
	var fd: int = clampi(int(ceil(aabb.size.z / FOOTPRINT_CELL_M)),
		FOOTPRINT_MIN_CELLS, FOOTPRINT_MAX_CELLS)
	var fh: int = clampi(int(ceil(aabb.size.y / FOOTPRINT_CELL_M)),
		FOOTPRINT_MIN_CELLS, FOOTPRINT_MAX_CELLS)
	var fp_now: Array = d.get("footprint", [1, 1, 1])
	var fp_target := [fw, fd, fh]
	if fp_now != fp_target:
		d["footprint"] = fp_target
		changed = true

	# Offset (x, y, z): center on X/Z, clamp y so lowest point >= 0.
	var off: Array = d.get("artifact_offset", [0.0, 0.0, 0.0])
	while off.size() < 3:
		off.append(0.0)
	var cx: float = -aabb.get_center().x
	var cz: float = -aabb.get_center().z
	var dy: float = -aabb.position.y
	var prev_off := Vector3(float(off[0]), float(off[1]), float(off[2]))
	var new_off := Vector3(cx, dy, cz)
	if (prev_off - new_off).length() > 0.005:
		d["artifact_offset"] = [new_off.x, new_off.y, new_off.z]
		changed = true

	# Escalation: if any axis would need to be patched by > threshold,
	# the artifact's mesh origin is wrong — escalate.
	if absf(cx) > ESCALATION_THRESHOLD_M:
		reasons.append("AABB centre offset on X by %.2f m — recentre mesh in artifact" % -cx)
	if absf(cz) > ESCALATION_THRESHOLD_M:
		reasons.append("AABB centre offset on Z by %.2f m — recentre mesh in artifact" % -cz)
	if absf(aabb.position.y) > ESCALATION_THRESHOLD_M:
		reasons.append("AABB.y min = %.2f — body sinks into / floats above floor" % aabb.position.y)

	if not reasons.is_empty():
		_stats.escalated += 1
		_escalations.append({
			"lookup": lookup,
			"scene": scene_path,
			"reasons": reasons,
			"aabb_min": [aabb.position.x, aabb.position.y, aabb.position.z],
			"aabb_size": [aabb.size.x, aabb.size.y, aabb.size.z],
		})
		# Also tag in the room's notes so the catalog filter surfaces it.
		var notes: Dictionary = d.get("notes", {}) if d.get("notes") is Dictionary else {}
		var tags: Array = notes.get("tags", [])
		if not tags.has("artifact-needs-fix"):
			tags.append("artifact-needs-fix")
		notes["tags"] = tags
		var prior_text := String(notes.get("text", ""))
		var new_line: String = "[auto] " + reasons[0]
		if not prior_text.contains(new_line):
			notes["text"] = (prior_text + ("\n" if not prior_text.is_empty() else "") + new_line)
		d["notes"] = notes
		changed = true

	if changed:
		_stats.changed += 1
		var f := FileAccess.open(room_path, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(d, "\t"))
			f.close()
	else:
		_stats.unchanged += 1


# Compute the AABB of all MeshInstance3D under `inst`, expressed in inst's
# local frame (so it doesn't depend on where in the scene tree it lives).
func _compute_aabb(inst: Node, sandbox: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	var stack: Array = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var mi: MeshInstance3D = n
			# Convert mesh AABB into the same frame as `inst`.
			var rel: Transform3D = sandbox.global_transform.affine_inverse() * mi.global_transform
			var aabb := rel * mi.get_aabb()
			if first:
				combined = aabb
				first = false
			else:
				combined = combined.merge(aabb)
		for c in n.get_children():
			stack.append(c)
	return combined


func _write_escalation_report() -> void:
	if _escalations.is_empty():
		return
	var dir_path: String = ESCALATION_REPORT_PATH.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var f: FileAccess = FileAccess.open(ESCALATION_REPORT_PATH, FileAccess.WRITE)
	if f == null:
		print("[normalize] cannot open escalation report: ", ESCALATION_REPORT_PATH)
		return
	var ts := Time.get_datetime_string_from_system()
	# Stable sort by lookup_name so diffs are readable.
	_escalations.sort_custom(func(a, b): return String(a.lookup) < String(b.lookup))
	f.store_string("# Dressing-room escalations\n\n")
	f.store_string("> Auto-generated by `normalize_dressing_rooms_batch.gd` on %s.\n" % ts)
	f.store_string("> Each entry below means the dressing-room offset patch would exceed\n")
	f.store_string("> %.2f m to make the artifact land correctly. That is a *symptom* —\n" % ESCALATION_THRESHOLD_M)
	f.store_string("> fix the artifact's mesh origin / spawn position in the .tscn / .gd\n")
	f.store_string("> instead of relying on the offset.\n\n")
	f.store_string("**Total: %d artifacts.**\n\n" % _escalations.size())
	for esc in _escalations:
		var lookup: String = String(esc.lookup)
		var scene: String = String(esc.scene)
		var reasons: Array = esc.reasons
		var amin: Array = esc.aabb_min
		var asize: Array = esc.aabb_size
		f.store_string("## `%s`\n\n" % lookup)
		if scene != "":
			f.store_string("- scene: `%s`\n" % scene)
		f.store_string("- AABB min:  (%.2f, %.2f, %.2f)\n" % [amin[0], amin[1], amin[2]])
		f.store_string("- AABB size: (%.2f, %.2f, %.2f)\n" % [asize[0], asize[1], asize[2]])
		f.store_string("- reasons:\n")
		for r in reasons:
			f.store_string("  - %s\n" % str(r))
		f.store_string("\n")
	f.close()
	print("[normalize] wrote %d escalations → %s" % [_escalations.size(), ESCALATION_REPORT_PATH])


func _print_summary() -> void:
	print("\n[normalize] === summary ===")
	print("  total rooms:    %d" % _stats.total)
	print("  changed:        %d" % _stats.changed)
	print("  unchanged:      %d" % _stats.unchanged)
	print("  escalated:      %d" % _stats.escalated)
	print("  missing scene:  %d" % _stats.missing_scene)
	print("  empty meshes:   %d" % _stats.no_meshes)
	print("  load failed:    %d" % _stats.load_failed)
