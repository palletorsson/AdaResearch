extends SceneTree
## THE RULES AGAINST THE SERVER'S: StickerData.apply_ops (commons/stickers/sticker_data.gd, the GDScript port) on a base
## placements document and a list of ops, written out for comparison with ada_encyclopedia/src/lib/stickers.ts applyOps
## run on the SAME files (the 10-line runner in commons/stickers/README.md, "Checks"). The two documents must agree number
## for number: every result, every stored at / n / up (settle on a board, snap90 and fixed turns read by turnOf against
## the stored normal), every z, the applied list and the revision. Reads its three inputs, writes only <out.json>.
##   godot --headless --path . --xr-mode off --script res://tools/probes/stickers_apply_ops.gd -- \
##       <base placements.json> <ops.json> <designs.json> <out.json>
## Point it at COPIES of commons/data/stickers/*.json: it never reads the truth on its own and never writes it.

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 4:
		push_error("stickers_apply_ops: give <base.json> <ops.json> <designs.json> <out.json>")
		quit(2)
		return
	var base: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[0]))
	var ops: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[1]))
	var designs_doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[2]))
	if not base is Dictionary or not ops is Array or not designs_doc is Dictionary:
		push_error("stickers_apply_ops: an input does not read as JSON of the right shape")
		quit(3)
		return
	var designs := {}
	for d in (designs_doc as Dictionary).get("designs", []):
		if d is Dictionary:
			designs[str(d.get("id", ""))] = d
	var SD: Script = load("res://commons/stickers/sticker_data.gd")
	var out: Dictionary = SD.apply_ops(base, ops, "vr:parity", "2026-11-13T12:00:00Z", designs)
	var f := FileAccess.open(a[3], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("stickers_apply_ops: %d results, changed %s, revision %d" % [(out.results as Array).size(), out.changed, int(out.doc.revision)])
	quit(0)
