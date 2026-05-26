## Batch-export every artifact in a registry to .glb files for the
## encyclopedia's lab editor to use as real 3D meshes (instead of
## hashed colour boxes + flat sprite billboards).
##
## Output lands in user://artifact_gltf/ — Godot's sandbox. A shell
## post-step copies the .glb files + manifest.json into
## ada_encyclopedia/public/artifact-gltf/. The AdaResearch repo gains
## nothing but this script.
##
## Each artifact is given SETTLE_FRAMES frames of run time after
## instantiation so _ready() and any procedural mesh building can
## finish before we snapshot the scene tree to GLTF.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/export_artifacts_gltf.gd -- \
##     --registry=lab [--max=N] [--out=user://artifact_gltf]
##
## Output:
##   <out>/<lookup_name>.glb       per successful export
##   <out>/manifest.json           index + sizes + status
##   <out>/_export_log.txt         per-artifact log (success/failure)

extends SceneTree

const SETTLE_FRAMES: int = 60       # ~1 second at 60 fps
const REGISTRY_DIR: String = "res://commons/artifacts/registry/"

var _registry_name: String = "lab"
var _output_dir: String = "user://artifact_gltf"
var _max_count: int = -1            # -1 = export every artifact in registry


func _initialize() -> void:
	for raw_arg in OS.get_cmdline_user_args():
		var arg := String(raw_arg).strip_edges()
		if arg.begins_with("--registry="):
			_registry_name = arg.split("=", true, 1)[1]
		elif arg.begins_with("--out="):
			_output_dir = arg.split("=", true, 1)[1]
		elif arg.begins_with("--max="):
			_max_count = int(arg.split("=", true, 1)[1])
	_run.call_deferred()


func _run() -> void:
	var registry_path: String = "%s%s.json" % [REGISTRY_DIR, _registry_name]
	if not FileAccess.file_exists(registry_path):
		push_error("Registry not found: %s" % registry_path)
		quit(1)
		return

	var raw: String = FileAccess.get_file_as_string(registry_path)
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_error("Failed to parse registry: %s" % registry_path)
		quit(1)
		return

	var artifacts: Dictionary = parsed.get("artifacts", {})
	if not (artifacts is Dictionary):
		push_error("Registry has no 'artifacts' dictionary")
		quit(1)
		return

	var lookup_names: Array = artifacts.keys()
	if _max_count > 0:
		lookup_names = lookup_names.slice(0, _max_count)

	# Ensure output directory exists
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	print("[gltf-export] registry=%s count=%d settle=%d output=%s" % [
		_registry_name, lookup_names.size(), SETTLE_FRAMES,
		ProjectSettings.globalize_path(_output_dir)
	])

	var success := 0
	var failed := 0
	var manifest_entries: Array = []
	var log_lines: Array[String] = []

	for i in range(lookup_names.size()):
		var lookup: String = String(lookup_names[i])
		var entry: Dictionary = artifacts[lookup]
		var scene_path: String = String(entry.get("scene", ""))

		var prefix := "[%3d/%3d]" % [i + 1, lookup_names.size()]

		if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			failed += 1
			var line := "%s SKIP %s — no scene at '%s'" % [prefix, lookup, scene_path]
			print(line)
			log_lines.append(line)
			continue

		var packed: PackedScene = load(scene_path)
		if packed == null:
			failed += 1
			var line2 := "%s FAIL %s — load failed for '%s'" % [prefix, lookup, scene_path]
			print(line2)
			log_lines.append(line2)
			continue

		var instance: Node = packed.instantiate()
		if instance == null:
			failed += 1
			var line3 := "%s FAIL %s — instantiate returned null" % [prefix, lookup]
			print(line3)
			log_lines.append(line3)
			continue
		if not (instance is Node3D):
			instance.queue_free()
			failed += 1
			var line4 := "%s SKIP %s — not Node3D (%s)" % [prefix, lookup, instance.get_class()]
			print(line4)
			log_lines.append(line4)
			continue

		# Mount under a temp root so _ready fires + scripts have a tree
		var temp_root := Node3D.new()
		temp_root.name = "ExportTempRoot"
		get_root().add_child(temp_root)
		temp_root.add_child(instance)

		# Settle — let _ready and procedural mesh generation finish
		for j in range(SETTLE_FRAMES):
			await get_root().get_tree().process_frame

		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_scene(instance, state)

		var ok := false
		var size := 0
		if err == OK:
			var output_path := "%s/%s.glb" % [_output_dir, lookup]
			err = doc.write_to_filesystem(state, output_path)
			if err == OK:
				var f := FileAccess.open(output_path, FileAccess.READ)
				if f:
					size = f.get_length()
					f.close()
				ok = true
				manifest_entries.append({
					"lookup_name": lookup,
					"url": "/artifact-gltf/%s.glb" % lookup,
					"size_bytes": size,
					"scene": scene_path,
				})

		if ok:
			success += 1
			var line5 := "%s OK   %s (%d bytes)" % [prefix, lookup, size]
			print(line5)
			log_lines.append(line5)
		else:
			failed += 1
			var line6 := "%s FAIL %s — gltf export err=%d" % [prefix, lookup, err]
			print(line6)
			log_lines.append(line6)

		temp_root.queue_free()
		await get_root().get_tree().process_frame

	# Merge with existing manifest.json if present — later runs against
	# different registries should APPEND to the index, not replace it.
	# Dedupe by lookup_name (the current run's entry wins so re-exports
	# refresh).
	var manifest_path := "%s/manifest.json" % _output_dir
	var existing_entries: Array = []
	var existing_registries: Array = []
	if FileAccess.file_exists(manifest_path):
		var existing_raw: String = FileAccess.get_file_as_string(manifest_path)
		var existing_parsed = JSON.parse_string(existing_raw)
		if existing_parsed is Dictionary:
			existing_entries = existing_parsed.get("entries", [])
			if not (existing_entries is Array):
				existing_entries = []
			existing_registries = existing_parsed.get("registries", [])
			if not (existing_registries is Array):
				existing_registries = []
	# Build a set of lookup_names from THIS run, then drop any matching
	# entries from the existing list before appending.
	var current_names: Dictionary = {}
	for e in manifest_entries:
		current_names[String(e.get("lookup_name", ""))] = true
	var merged: Array = []
	for e in existing_entries:
		if not (e is Dictionary):
			continue
		var ln: String = String(e.get("lookup_name", ""))
		if current_names.has(ln):
			continue
		merged.append(e)
	for e in manifest_entries:
		merged.append(e)
	# Track which registries have ever been exported into this manifest.
	var registries_set: Dictionary = {}
	for r in existing_registries:
		registries_set[String(r)] = true
	registries_set[_registry_name] = true

	var manifest := {
		"version": 1,
		"registries": registries_set.keys(),
		"settle_frames": SETTLE_FRAMES,
		"last_exported_registry": _registry_name,
		"last_exported_at": Time.get_datetime_string_from_system(),
		"count": merged.size(),
		"entries": merged,
	}
	var mf := FileAccess.open(manifest_path, FileAccess.WRITE)
	mf.store_string(JSON.stringify(manifest, "\t"))
	mf.close()
	print("[gltf-export] manifest now has %d total entries across registries %s" % [merged.size(), str(registries_set.keys())])

	# Write log
	var log_path := "%s/_export_log.txt" % _output_dir
	var lf := FileAccess.open(log_path, FileAccess.WRITE)
	lf.store_string("\n".join(log_lines))
	lf.close()

	print("\n[gltf-export] DONE: %d success, %d failed of %d artifacts" % [
		success, failed, lookup_names.size()
	])
	print("[gltf-export] manifest: %s" % ProjectSettings.globalize_path(manifest_path))
	quit(0)
