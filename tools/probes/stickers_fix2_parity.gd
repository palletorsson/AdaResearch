extends SceneTree
## THE CURVED PRINT, DUMPED for three.js to be held against it (sticker-decal.ts). Headless, --script: the layer's
## static print (curved_mesh at lift 0) of a set of records on the bench's sphere (r 0.3) and cylinder (r 0.22, h 0.6),
## written as JSON {cases: [{key, surface, rec, size, verts, uvs, idx}]} for a node / three.js runner to compare by
## UV. It reads the design from res://commons/data/stickers/designs.json (read only) and makes no StickerData node: it
## writes nothing but its own output, posts nothing.
##   godot --headless --path . --xr-mode off --script res://tools/probes/stickers_fix2_parity.gd -- \
##     --out=<file.json> [--layer=<path of a sticker_layer.gd, default the repo's>] [--design=swatch_silence_pink]

const StickerData := preload("res://commons/stickers/sticker_data.gd")

func _initialize() -> void:
	var out_path := ""
	var layer_path := "res://commons/stickers/sticker_layer.gd"
	var design_id := "swatch_silence_pink"
	for a in OS.get_cmdline_user_args():
		var value: String = a.substr(a.find("=") + 1) if a.contains("=") else ""
		if a.begins_with("--out="):
			out_path = value
		elif a.begins_with("--layer="):
			layer_path = value
		elif a.begins_with("--design="):
			design_id = value
	var layer: Script = load(layer_path)
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/stickers/designs.json"))
	var d: Dictionary = {}
	for x in (doc.designs as Array):
		if str(x.id) == design_id:
			d = x
	var sphere := {"shape": "sphere", "r": 0.3}
	var cyl := {"shape": "cylinder", "r": 0.22, "h": 0.6}
	var n50 := Vector3(0.0, sin(deg_to_rad(50.0)), cos(deg_to_rad(50.0)))
	var c25 := Vector3(sin(deg_to_rad(25.0)), 0.0, cos(deg_to_rad(25.0)))
	var cases: Array = []
	for size in [0.18, 0.25, 0.4]:
		cases.append(["sphere_front_%s" % size, sphere, [0.0, 0.0, 0.3], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], size])
		cases.append(["sphere_50deg_%s" % size, sphere, StickerData.arr3(n50 * 0.3), StickerData.arr3(n50), StickerData.up_at_turn(StickerData.arr3(n50), 0.0), size])
		cases.append(["cylinder_side_%s" % size, cyl, [0.0, 0.0, 0.22], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], size])
		cases.append(["cylinder_25deg_%s" % size, cyl, StickerData.arr3(c25 * 0.22), StickerData.arr3(c25), [0.0, 1.0, 0.0], size])
	cases.append(["cylinder_by_rim_0.25", cyl, [0.0, 0.2, 0.22], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], 0.25])
	cases.append(["cylinder_by_rim_0.4", cyl, [0.0, 0.17, 0.22], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], 0.4])
	var rows: Array = []
	var t0 := Time.get_ticks_usec()
	for c in cases:
		var rec := {"at": c[2], "n": c[3], "up": c[4], "size": c[5]}
		var g: Dictionary = layer.curved_mesh(rec, d, 0.0, c[1])
		var verts: Array = []
		for v in (g.verts as PackedVector3Array):
			verts.append([v.x, v.y, v.z])
		var uvs: Array = []
		for uv in (g.uvs as PackedVector2Array):
			uvs.append([uv.x, uv.y])
		rows.append({"key": c[0], "surface": c[1], "rec": rec, "size": c[5], "verts": verts, "uvs": uvs, "idx": Array(g.idx)})
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"layer": layer_path, "design": {"id": design_id, "w": d.get("w"), "h": d.get("h"), "cut": d.get("cut")}, "ms": ms, "cases": rows}))
	f.close()
	print("[stickers_fix2_parity] %d cases in %.1f ms -> %s" % [rows.size(), ms, out_path])
	quit(0)
