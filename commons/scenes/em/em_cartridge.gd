class_name EmCartridge
extends RefCounted

## Versioned, preassembled Endless Museum hall packages.
##
## A cartridge is a PackedScene plus a small index row. It contains the actual
## generated hall subtree—batched architecture, collisions, lights, artifacts,
## and dressing—together with the stream cursor on both sides of the hall. The
## runtime can therefore instantiate it and continue the endless sequence
## without re-running the spatial negotiation that produced it.

const SCHEMA := "adaresearch.em_cartridge.v1"
const AUTHOR_DIR := "res://ada_run/em_cartridges"
const SHIPPED_DIR := "res://commons/data/museum/cartridges"
const INDEX_FILE := "index.json"
const CONTENT_CHUNKS := 8


static func source_stamp(paths: PackedStringArray) -> int:
	var stamp := 0
	for path in paths:
		if FileAccess.file_exists(path):
			stamp = maxi(stamp, int(FileAccess.get_modified_time(path)))
	return stamp


static func _slug(value: String) -> String:
	var out := ""
	for i in range(value.length()):
		var c := value.substr(i, 1).to_lower()
		out += c if c.is_valid_identifier() or c.is_valid_int() else "_"
	while "__" in out:
		out = out.replace("__", "_")
	return out.strip_edges().trim_prefix("_").trim_suffix("_")


static func _index_path(root: String) -> String:
	return root.path_join(INDEX_FILE)


static func _read_index(root: String) -> Dictionary:
	var path := _index_path(root)
	if not FileAccess.file_exists(path):
		return {"schema": SCHEMA, "entries": {}}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary and String((parsed as Dictionary).get("schema", "")) == SCHEMA \
			and (parsed as Dictionary).get("entries") is Dictionary:
		return parsed as Dictionary
	return {"schema": SCHEMA, "entries": {}}


static func _write_index(root: String, doc: Dictionary) -> bool:
	var absolute := ProjectSettings.globalize_path(root)
	if DirAccess.make_dir_recursive_absolute(absolute) != OK and not DirAccess.dir_exists_absolute(absolute):
		return false
	var file := FileAccess.open(_index_path(root), FileAccess.WRITE)
	if file == null:
		return false
	doc["schema"] = SCHEMA
	doc["at"] = Time.get_datetime_string_from_system(false, true)
	file.store_string(JSON.stringify(doc, "\t"))
	file.close()
	return true


static func _own_tree(node: Node, root: Node) -> void:
	for child in node.get_children():
		(child as Node).owner = root
		# Keep authored artifacts as PackedScene instances. Recursing into them
		# flattens their generated descendants into the cartridge; their scripts
		# then build those descendants again on load, producing a larger package,
		# duplicate runtime nodes, and a severe first-frame pipeline burst.
		if String((child as Node).scene_file_path) == "":
			_own_tree(child, root)


static func _clear_owners(node: Node) -> void:
	node.owner = null
	for child in node.get_children():
		_clear_owners(child)


static func _is_content(child: Node) -> bool:
	return child.has_meta("em_cartridge_token") or child.has_meta("em_cartridge_deferred")


## Packs one completed hall and registers it atomically in the authoring index.
## `manifest` must include map, pre_snap, post_snap, z0, z1, and walk records.
static func compile(seg: Node3D, manifest: Dictionary, sources: PackedStringArray,
		root: String = AUTHOR_DIR) -> Dictionary:
	if seg == null or not is_instance_valid(seg):
		return {"ok": false, "error": "invalid segment"}
	var map_name := String(manifest.get("map", ""))
	if map_name == "":
		return {"ok": false, "error": "segment has no map name"}
	var slug := _slug(map_name)
	if slug == "":
		return {"ok": false, "error": "map name has no safe cartridge key"}
	var absolute := ProjectSettings.globalize_path(root)
	if DirAccess.make_dir_recursive_absolute(absolute) != OK and not DirAccess.dir_exists_absolute(absolute):
		return {"ok": false, "error": "cannot create cartridge directory"}
	var scene_path := root.path_join(slug + ".scn")
	manifest["schema"] = SCHEMA
	manifest["source_stamp"] = source_stamp(sources)
	manifest["compiled_at"] = Time.get_datetime_string_from_system(false, true)
	seg.set_meta("em_cartridge_manifest", manifest)
	# Keep the architecture cartridge free of content resources. Loading one
	# full PackedScene still asks the renderer to prepare every referenced mesh
	# and shader at once, even if content nodes are detached before add_child.
	# One small content cartridge per direct child lets runtime admit those
	# resources through its frame budget while architecture appears immediately.
	var content: Array = []
	for child_v in seg.get_children():
		var child := child_v as Node
		if _is_content(child):
			seg.remove_child(child)
			content.append(child)
	_own_tree(seg, seg)
	var packed := PackedScene.new()
	var pack_err := packed.pack(seg)
	if pack_err != OK:
		return {"ok": false, "error": "PackedScene.pack failed", "code": pack_err}
	var save_err := ResourceSaver.save(packed, scene_path)
	if save_err != OK:
		return {"ok": false, "error": "ResourceSaver.save failed", "code": save_err}
	var content_paths: Array = []
	var content_bytes := 0
	# A file per object made a medium hall issue 85 concurrent reads on Quest.
	# Eight packages preserve progressive admission without turning the Android
	# asset store into the bottleneck.
	var chunk_size := maxi(1, ceili(float(content.size()) / float(CONTENT_CHUNKS)))
	for chunk_start in range(0, content.size(), chunk_size):
		var chunk_i := content_paths.size()
		var wrapper := Node3D.new()
		wrapper.name = "CartridgeContent%02d" % chunk_i
		var chunk_end := mini(content.size(), chunk_start + chunk_size)
		for i in range(chunk_start, chunk_end):
			var child: Node = content[i]
			_clear_owners(child)
			wrapper.add_child(child)
			child.owner = wrapper
			if String(child.scene_file_path) == "":
				_own_tree(child, wrapper)
		var content_packed := PackedScene.new()
		var content_err := content_packed.pack(wrapper)
		if content_err != OK:
			return {"ok": false, "error": "content pack failed", "index": chunk_i, "code": content_err}
		var content_path := root.path_join("%s_content_%02d.scn" % [slug, chunk_i])
		content_err = ResourceSaver.save(content_packed, content_path)
		if content_err != OK:
			return {"ok": false, "error": "content save failed", "index": chunk_i, "code": content_err}
		content_paths.append(content_path)
		content_bytes += FileAccess.get_file_as_bytes(content_path).size()
		var packaged_children := wrapper.get_children()
		for child_v in packaged_children:
			var child := child_v as Node
			wrapper.remove_child(child)
			_clear_owners(child)
			seg.add_child(child)
			child.owner = seg
		wrapper.free()
	var index := _read_index(root)
	var entries: Dictionary = index.get("entries", {})
	# Retire only files previously owned by this exact cartridge row. A smaller
	# recompilation must not leave obsolete packages for em_ship to copy.
	if entries.get(map_name) is Dictionary:
		for old_v in ((entries[map_name] as Dictionary).get("content", []) as Array):
			var old_path := String(old_v)
			if old_path not in content_paths and old_path.begins_with(root.path_join(slug + "_content_")):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(old_path))
	entries[map_name] = {
		"scene": scene_path,
		"source_stamp": manifest["source_stamp"],
		"compiled_at": manifest["compiled_at"],
		"chapter": manifest.get("chapter", ""),
		"pearl": manifest.get("pearl", ""),
		"content": content_paths,
		"content_count": content_paths.size(),
		"bytes": FileAccess.get_file_as_bytes(scene_path).size() + content_bytes,
	}
	index["entries"] = entries
	if not _write_index(root, index):
		return {"ok": false, "error": "scene saved but index write failed", "scene": scene_path}
	return {"ok": true, "scene": scene_path, "entry": entries[map_name]}


## Finds an authoring cartridge first, then a cartridge copied into the export.
## Authoring cartridges are rejected when any declared source is newer. Shipped
## cartridges are an export-time snapshot and are trusted as a set.
static func find(map_name: String, sources: PackedStringArray) -> Dictionary:
	for root in [AUTHOR_DIR, SHIPPED_DIR]:
		var index := _read_index(root)
		var entries: Dictionary = index.get("entries", {})
		if not entries.has(map_name):
			continue
		var entry: Dictionary = (entries[map_name] as Dictionary).duplicate(true)
		var scene_path := String(entry.get("scene", ""))
		if root == SHIPPED_DIR:
			scene_path = root.path_join(scene_path.get_file())
		if not ResourceLoader.exists(scene_path):
			continue
		if root == AUTHOR_DIR and int(entry.get("source_stamp", 0)) < source_stamp(sources):
			continue
		entry["scene"] = scene_path
		var content_paths: Array = []
		for content_v in (entry.get("content", []) as Array):
			var content_path := String(content_v)
			if root == SHIPPED_DIR:
				content_path = root.path_join(content_path.get_file())
			if ResourceLoader.exists(content_path):
				content_paths.append(content_path)
		entry["content"] = content_paths
		entry["root"] = root
		return entry
	return {}


static func instantiate(entry: Dictionary) -> Node3D:
	var scene_path := String(entry.get("scene", ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return null
	# Architecture and content packages deliberately share authored meshes and
	# materials. REPLACE can retire a RID while another threaded package still
	# refers to it; REUSE keeps that shared resource graph coherent.
	var packed := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
	return packed.instantiate() as Node3D if packed != null else null
