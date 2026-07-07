extends SceneTree
## Batch DNA-pair capture for /staging-review: for each artifact in
## ada_run/staging_pairs_job.json, render the CURRENT staged dressing room and a
## PROPOSED better-DNA variant (posture + footprint overrides, in-memory only —
## never saved) — all in ONE Godot boot so a batch of 10 takes ~1.5 min, not 13.
##
##   job: { "artifacts": [ { "name": "aalto_vase", "posture": "pedestal", "pad": [5,3] } ] }
##   out: user://staging_pairs/<name>_current.png + <name>_proposed.png
##
## Run:
##   godot --path . --xr-mode off --resolution 640x560 \
##     --script res://commons/testing/capture_staging_pairs.gd -- --float

const JOB := "res://ada_run/staging_pairs_job.json"
const OUT_DIR := "user://staging_pairs"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var job = _read(JOB)
	if not (job is Dictionary):
		push_error("capture_staging_pairs: no job file at " + JOB)
		quit(1)
		return
	var arts: Array = job.get("artifacts", [])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var err := change_scene_to_file("res://commons/artifacts/catalog/DressingRoomCatalog3D.tscn")
	if err != OK:
		push_error("capture_staging_pairs: failed to load catalog scene")
		quit(2)
		return
	await process_frame
	await process_frame
	await create_timer(4.0).timeout
	var cat = current_scene
	var done := 0
	for a in arts:
		if not (a is Dictionary):
			continue
		var art_name := str(a.get("name", ""))
		var idx: int = cat._rooms.find(art_name)
		if idx < 0:
			print("capture_staging_pairs: skip (no room): ", art_name)
			continue
		# CURRENT — the room exactly as recorded, staged.
		cat._index = idx
		cat._load_room(art_name)
		cat._staged = true
		cat._rebuild_with_rotation()
		await create_timer(1.6).timeout
		await process_frame
		root.get_texture().get_image().save_png("%s/%s_current.png" % [OUT_DIR, art_name])
		# PROPOSED — better DNA applied in-memory (posture + pad); never saved.
		var p := str(a.get("posture", ""))
		if p != "":
			cat._current_room_data["posture"] = p
		var pad = a.get("pad", null)
		if pad is Array and (pad as Array).size() >= 2:
			cat._resize_pad(maxi(1, int(pad[0])), maxi(1, int(pad[1])))
		cat._rebuild_with_rotation()
		await create_timer(1.4).timeout
		await process_frame
		root.get_texture().get_image().save_png("%s/%s_proposed.png" % [OUT_DIR, art_name])
		done += 1
		print("capture_staging_pairs: pair done: ", art_name)
	print("PAIRS_DONE ", done)
	quit(0)

func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))
