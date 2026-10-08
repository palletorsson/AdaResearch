extends SceneTree

## Headless authoring entry point for one museum cartridge.
## Usage:
##   godot --headless --path . --script res://commons/testing/compile_em_cartridge.gd \
##     -- --cartridge-map=Point_One --cartridge-chapter=primitives


func _initialize() -> void:
	call_deferred("_run")


func _arg(prefix: String, fallback: String) -> String:
	for av in OS.get_cmdline_user_args():
		var arg := String(av)
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())
	return fallback


func _run() -> void:
	var map_name := _arg("--cartridge-map=", "Point_One")
	var chapter := _arg("--cartridge-chapter=", "primitives")
	var prior_compiled_at := ""
	var index_path := "res://ada_run/em_cartridges/index.json"
	if FileAccess.file_exists(index_path):
		var old_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(index_path))
		if old_v is Dictionary and (old_v as Dictionary).get("entries") is Dictionary:
			prior_compiled_at = String(((old_v as Dictionary)["entries"] as Dictionary).get(
				map_name, {}).get("compiled_at", ""))
	var packed := load("res://commons/scenes/endless_museum.tscn") as PackedScene
	if packed == null:
		push_error("[em-cartridge-compile] museum scene missing")
		quit(1)
		return
	var museum := packed.instantiate() as Node3D
	museum.set("start_map", map_name)
	museum.set("start_chapter", chapter)
	museum.set("_first_chapter", chapter)
	museum.set("_cartridge_write", true)
	museum.set("_lazy_pending", 0)
	get_root().add_child(museum)
	var waited := 0.0
	while not bool(museum.get("_museum_ready")) and waited < 30.0:
		await create_timer(0.1).timeout
		waited += 0.1
	if not bool(museum.get("_museum_ready")):
		push_error("[em-cartridge-compile] museum did not become ready")
		museum.queue_free()
		quit(1)
		return
	museum.call("_compile_initial_cartridge")
	# The compile is deliberately deferred until after readiness. Wait for the
	# index row rather than guessing how long PackedScene serialization takes.
	waited = 0.0
	while waited < 20.0:
		await create_timer(0.1).timeout
		waited += 0.1
		if not FileAccess.file_exists(index_path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(index_path))
		if parsed is Dictionary and (parsed as Dictionary).get("entries") is Dictionary \
				and ((parsed as Dictionary)["entries"] as Dictionary).has(map_name):
			var row: Dictionary = ((parsed as Dictionary)["entries"] as Dictionary)[map_name]
			if String(row.get("compiled_at", "")) == prior_compiled_at:
				continue
			var scene_path := String(row.get("scene", ""))
			if FileAccess.file_exists(scene_path):
				print("[em-cartridge-compile] PASS %s · %s -> %s (%d bytes)" % [
					chapter, map_name, scene_path, int(row.get("bytes", 0))])
				museum.queue_free()
				quit(0)
				return
	push_error("[em-cartridge-compile] no completed index row for %s" % map_name)
	museum.queue_free()
	quit(1)
