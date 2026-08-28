extends SceneTree
## BAKE A HALL'S PASSAGE INTO ITS MAP.
##
## Palle, after a day of chasing geometry that exists only at build time: "just add
## them in as is into the map. That means extending the map with the passage and
## that will make them editable."
##
## The passage rows are appended past the map's last row at BUILD time, which is
## why nothing could edit them as ordinary cells. This writes them into the map
## instead, then sets map_info.museum.passage.kind = "none" — a mode the museum
## already has ("the halls meet at their own doors; no added rows") — so the
## builder adds nothing and the map's own rows ARE the passage.
##
## THE MUSEUM DOES THE DERIVING, NOT THIS SCRIPT. _derive_map_row and
## _authored_passages are called on the real endless_museum.gd, instantiated but
## never added to the tree, so nothing builds and there is exactly ONE
## implementation of the rule. A Python twin of _authored_passages would drift the
## way long_museum.py's geometry did — same hall, two answers, both confident.
##
##   godot --headless --path . --xr-mode off \
##       --script res://commons/testing/bake_passage_into_map.gd -- --map=Point_One
##   ... add --apply to write. Without it, nothing is touched.

func _initialize() -> void:
	var map_name := ""
	var apply := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			map_name = a.split("=", 1)[1]
		elif a == "--apply":
			apply = true
	if map_name == "":
		print("bake_passage_into_map: --map=<Name> [--apply]")
		quit(2)
		return

	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var em: Node = ps.instantiate()          # never added to the tree: nothing builds

	var row: Dictionary = em.call("_derive_map_row", map_name)
	if row.is_empty():
		print("bake: %s — the museum cannot derive a hall from that map" % map_name)
		quit(3)
		return
	var tile0: Array = row["tile"]
	var museum_d: Dictionary = row.get("museum", {}) if row.get("museum") is Dictionary else {}
	var decl: Dictionary = museum_d.get("passage", {}) if museum_d.get("passage") is Dictionary else {}
	var h0: int = tile0.size()
	var kind := String(decl.get("kind", "chicane")).to_lower()
	print("bake: %s — %d tile rows, passage %s" % [map_name, h0, JSON.stringify(decl)])
	if kind == "none":
		print("bake: already baked (kind none) — nothing to do")
		quit(0)
		return

	var tile1: Array = em.call("_authored_passages", tile0, decl)
	print("bake: the museum would build %d rows (%d appended)" % [tile1.size(), tile1.size() - h0])

	# the map, read as text so nothing but the cells we touch can change
	var path := "res://commons/maps/%s/map_data.json" % map_name
	var doc_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (doc_v is Dictionary):
		print("bake: %s has no readable map_data.json" % map_name)
		quit(3)
		return
	var doc: Dictionary = doc_v
	var layers: Dictionary = doc.get("layers", {})
	var structure: Array = layers.get("structure", [])
	var utilities: Array = layers.get("utilities", [])
	var inter: Array = layers.get("interactables", [])
	var map_w: int = (structure[0] as Array).size() if not structure.is_empty() else 0

	# 1. the CARVED openings: _authored_passages also opens the first and last row
	#    so the halls can be entered. Only cells that actually changed are written,
	#    because a tile "4" cannot say whether the map meant 2, 3 or "w".
	var carved := 0
	for r in range(mini(h0, structure.size())):
		var t0: Array = tile0[r]
		var t1: Array = tile1[r]
		for c in range(mini(t0.size(), (structure[r] as Array).size())):
			if String(t0[c]) == String(t1[c]):
				continue
			(structure[r] as Array)[c] = _map_value(String(t1[c]))
			carved += 1

	# 2. the appended rows become real map rows
	var added := 0
	for r in range(h0, tile1.size()):
		var trow: Array = tile1[r]
		var srow: Array = []
		var urow: Array = []
		var irow: Array = []
		for c in range(map_w):
			srow.append(_map_value(String(trow[c])) if c < trow.size() else "0")
			urow.append(" ")
			irow.append(" ")
		structure.append(srow)
		utilities.append(urow)
		inter.append(irow)
		added += 1

	# 3. and the museum is told to add nothing, or it would append them again
	if not doc.has("map_info"):
		doc["map_info"] = {}
	var mi: Dictionary = doc["map_info"]
	var mus: Dictionary = mi.get("museum", {}) if mi.get("museum") is Dictionary else {}
	var was := JSON.stringify(mus.get("passage", {}))
	mus["passage"] = {"kind": "none", "_baked": "the passage rows are IN this map now (bake_passage_into_map.gd); was " + was}
	mi["museum"] = mus
	doc["map_info"] = mi

	print("bake: %d carved cell(s), %d row(s) appended -> map is now %d rows" % [carved, added, structure.size()])
	if not apply:
		print("bake: DRY RUN — pass --apply to write")
		quit(0)
		return

	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		print("bake: cannot open %s" % tmp)
		quit(4)
		return
	f.store_string(JSON.stringify(doc, "\t") + "\n")
	f.close()
	var da := DirAccess.open(path.get_base_dir())
	if da == null or da.rename(tmp.get_file(), path.get_file()) != OK:
		print("bake: could not replace the map")
		quit(4)
		return
	print("bake: WROTE %s — run tools/compact_map_json.py to restore compact rows" % path)
	quit(0)


## tile "4"/"1"/"0" is map "2"/"1"/"0" — the same mapping _rule_cell uses.
func _map_value(t: String) -> String:
	if t.begins_with("4"):
		return "2"
	if t.begins_with("0"):
		return "0"
	if t.begins_with("p"):
		return t
	return "1"
