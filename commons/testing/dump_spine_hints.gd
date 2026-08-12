extends SceneTree

## Call spine_hints() on every artifact that implements it, and write the result.
##
## `doc/SPATIAL_PIPELINE.md` §3 places `spine_hints()` in the ownership
## hierarchy as "a provider into the spatial contract", and §4 puts it in the
## resolution order between the registry defaults and the dressing room. It was
## missing from `tools/spatial_contract.py` because a *method on a scene* is
## invisible to a census of JSON files — which is how six data stores were found
## and a seventh, authoritative one was not.
##
## It has to be CALLED, not parsed. §3: it owns "dynamic/runtime hints that
## cannot reliably be represented statically". Reading the literal out of the
## source would be a static answer to a question the doctrine defines as
## dynamic, and would silently miss any artifact that computes its hints.
##
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/dump_spine_hints.gd -- \
##     --out=res://ada_run/spine_hints.json

const REGISTRY_DIR := "res://commons/artifacts/registry"

var _out: String = "res://ada_run/spine_hints.json"
var _settle: float = 0.2


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var a := String(arg)
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--settle="):
			_settle = float(a.substr(9))
	_run.call_deferred()


func _scenes() -> Dictionary:
	"""lookup_name -> scene path, across every registry file."""
	var out: Dictionary = {}
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return out
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var parsed = JSON.parse_string(
			FileAccess.get_file_as_string("%s/%s" % [REGISTRY_DIR, f]))
		if not (parsed is Dictionary):
			continue
		var arts = (parsed as Dictionary).get("artifacts", {})
		if not (arts is Dictionary):
			continue
		for key in (arts as Dictionary):
			var e = (arts as Dictionary)[key]
			if not (e is Dictionary):
				continue
			var scene := String((e as Dictionary).get("scene", ""))
			if scene != "" and ResourceLoader.exists(scene):
				out[String((e as Dictionary).get("lookup_name", key))] = scene
	return out


## Vector2i and friends do not survive JSON. Reduce to plain values so the
## Python side reads numbers rather than "(2, 1)".
func _plain(v: Variant) -> Variant:
	if v is Vector2i:
		return [int((v as Vector2i).x), int((v as Vector2i).y)]
	if v is Vector2:
		return [float((v as Vector2).x), float((v as Vector2).y)]
	if v is Vector3:
		return [float((v as Vector3).x), float((v as Vector3).y), float((v as Vector3).z)]
	if v is Array:
		var out: Array = []
		for item in v:
			out.append(_plain(item))
		return out
	if v is Dictionary:
		var d: Dictionary = {}
		for k in v:
			d[String(k)] = _plain(v[k])
		return d
	return v


func _run() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var scenes := _scenes()
	var hints: Dictionary = {}
	var checked := 0
	var failed: Array = []

	for lookup in scenes:
		var packed: PackedScene = load(scenes[lookup]) as PackedScene
		if packed == null:
			continue
		var inst: Node = packed.instantiate()
		if inst == null:
			continue
		checked += 1
		if not inst.has_method("spine_hints"):
			inst.free()
			continue
		root.add_child(inst)
		await process_frame
		if _settle > 0.0:
			await create_timer(_settle).timeout
		var got: Variant = null
		got = inst.call("spine_hints")
		if got is Dictionary:
			hints[lookup] = _plain(got)
			hints[lookup]["_scene"] = scenes[lookup]
		else:
			failed.append(lookup)
		inst.queue_free()
		await process_frame

	var payload := {
		"schema": "adaresearch.spine_hints_dump.v1",
		"_readme": ("spine_hints() as CALLED, not parsed — the doctrine defines "
			+ "it as dynamic. Regenerate after touching any artifact that "
			+ "implements it. Read by tools/spatial_contract.py."),
		"artifacts_checked": checked,
		"implementors": hints.size(),
		"returned_non_dictionary": failed,
		"hints": hints,
	}
	var f := FileAccess.open(_out, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	print("[spine_hints] %d artifacts checked, %d implement spine_hints() -> %s"
		% [checked, hints.size(), _out])
	for lookup in hints:
		var h: Dictionary = hints[lookup]
		print("   %-32s role=%-11s footprint=%s rot=%s height=%s" % [
			lookup, str(h.get("role", "-")), str(h.get("footprint", "-")),
			str(h.get("rotation_y", "-")), str(h.get("height", "-"))])
	quit(0)
