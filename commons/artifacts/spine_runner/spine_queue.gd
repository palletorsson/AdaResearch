extends RefCounted
class_name SpineQueue

## Flat ordered list of map names traversing the spine in curriculum order.
## Reads commons/maps/curriculum_spine.json for sequence order, then each
## sequence JSON for its map list. Result: ~500 map names end-to-end.

const SPINE_PATH := "res://commons/maps/curriculum_spine.json"
const SEQUENCES_DIR := "res://commons/maps/sequences/"


static func build() -> Array[String]:
	var out: Array[String] = []
	var spine_txt := FileAccess.get_file_as_string(SPINE_PATH)
	if spine_txt.is_empty():
		push_warning("SpineQueue: spine json missing")
		return out
	var sj := JSON.new()
	if sj.parse(spine_txt) != OK:
		return out
	var spine_data = sj.data
	if not (spine_data is Dictionary): return out
	var spine: Dictionary = spine_data.get("spine", {})
	var seqs: Array = spine.get("sequences", [])
	# Sort by `order` field
	seqs.sort_custom(func(a, b): return int(a.get("order", 999)) < int(b.get("order", 999)))

	for seq in seqs:
		var seq_name := str(seq.get("name", ""))
		if seq_name.is_empty(): continue
		var path := "%s%s.json" % [SEQUENCES_DIR, seq_name]
		var txt := FileAccess.get_file_as_string(path)
		if txt.is_empty(): continue
		var j := JSON.new()
		if j.parse(txt) != OK: continue
		var data = j.data
		if not (data is Dictionary): continue
		var sequences: Dictionary = data.get("sequences", {})
		var entry: Dictionary = sequences.get(seq_name, {})
		var maps: Array = entry.get("maps", [])
		for m in maps:
			out.append(str(m))
	return out


static func build_test() -> Array[String]:
	## Test queue = all 13 primitives maps (all have generated corridor JSON).
	return [
		"Point_One",
		"Point_Line",
		"Point_Lines",
		"Point_Trace",
		"Point_Line_Grid",
		"Point_Triangle",
		"Point_Triangle_Context",
		"Primitives_Polythedra",
		"Point_Animatedcube",
		"Primitives_Ignorance",
		"Primitives_Portals",
		"Primitives_Melencolia",
		"Chamber_Primitives",
	]
