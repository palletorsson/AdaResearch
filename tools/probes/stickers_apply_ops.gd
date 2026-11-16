extends SceneTree
## THE RULES AGAINST THE SERVER'S: StickerData.apply_ops (commons/stickers/sticker_data.gd, the GDScript port) on a base
## placements document and a list of ops, written out for comparison with ada_encyclopedia/src/lib/stickers.ts applyOps
## run on the SAME files (tools/probes/stickers_cardboard_runner.ts ops; tools/probes/stickers_cardboard_parity.py runs
## both and compares). The two documents must agree number for number: every result (its error's words too), every
## stored at / n / up (settle on a board, by the board's DEPTH and, on a cardboard wall, its BACK when boards are given;
## snap90 and fixed turns read by turnOf against the stored normal), every z, every thread (tie - between two walls of one
## construction too, when the constructions are given - untie with who cut it, retie, word), every stroke (scribble with
## its clamp, erase with who erased it, unerase), the applied list and the revision. Reads its inputs, writes only
## <out.json>.
##   godot --headless --path . --xr-mode off --script res://tools/probes/stickers_apply_ops.gd -- \
##       <base placements.json> <ops.json> <designs.json> <out.json> [<boards.json> | -] [<constructions.json>] [--sd=<path>]
## Without <boards.json> (or with "-") every board is flat paper, as applyOps without its `boards` argument; without
## <constructions.json> two boards are two boards (no `walls`). The constructions are read as the server reads them for
## its ops (stickers-store.ts: wallsOf(cleanConstructionsDoc(raw)), WITHOUT the boards); one that does not clean stops
## the probe (exit 3), as the route then refuses every op. --sd=<path> puts a scratch copy of another sticker_data.gd
## under test (to show which differences a missing rule makes); an apply_ops that takes no walls is called without them.
## Point it at COPIES of commons/data/stickers/*.json: it never reads the truth on its own and never writes it. Doubles
## are written in full (JSON.stringify full_precision), so a comparison reads back the very numbers computed.

const NOW := "2026-11-13T12:00:00Z"
const BY := "vr:parity"

func _initialize() -> void:
	var a: Array = []
	var sd_path := "res://commons/stickers/sticker_data.gd"
	for x in OS.get_cmdline_user_args():
		if x.begins_with("--sd="):
			sd_path = x.substr(5)
		else:
			a.append(x)
	if a.size() < 4:
		push_error("stickers_apply_ops: give <base.json> <ops.json> <designs.json> <out.json> [<boards.json>|-] [<constructions.json>] [--sd=<path>]")
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
	var boards: Variant = null
	if a.size() >= 5 and str(a[4]) != "-":
		var boards_doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[4]))
		if not boards_doc is Dictionary:
			push_error("stickers_apply_ops: <boards.json> does not read as a boards document")
			quit(3)
			return
		boards = {}
		for b in (boards_doc as Dictionary).get("boards", []):
			if b is Dictionary:
				boards[str(b.get("id", ""))] = b
	var SD: Script = load(sd_path)
	if SD == null:
		push_error("stickers_apply_ops: %s does not load" % sd_path)
		quit(4)
		return
	var walls: Variant = null
	if a.size() >= 6:
		var cons_doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(a[5]))
		# read by the script under test when it can, else by the repo's (an older port has no constructions)
		var reader: Script = SD if _arity(SD, "clean_constructions_doc") > 0 else load("res://commons/stickers/sticker_data.gd")
		var c: Dictionary = reader.clean_constructions_doc(cons_doc)
		if not c.has("doc"):
			push_error("stickers_apply_ops: <constructions.json> does not clean: %s" % str(c.get("error", "")))
			quit(3)
			return
		walls = reader.walls_of(c.doc)
	var out: Dictionary
	if _arity(SD, "apply_ops") >= 7:
		out = SD.apply_ops(base, ops, BY, NOW, designs, boards, walls)
	else:
		print("stickers_apply_ops: %s's apply_ops takes no walls; called without them" % sd_path)
		out = SD.apply_ops(base, ops, BY, NOW, designs, boards)
	var f := FileAccess.open(a[3], FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "", false, true))
	f.close()
	var refused := (out.results as Array).filter(func(r): return not bool(r.ok)).size()
	var skipped := (out.results as Array).filter(func(r): return bool(r.ok) and bool(r.get("skipped", false))).size()
	print("stickers_apply_ops: %d results (%d refused, %d skipped), changed %s, revision %d, threads %d, strokes %d, walls %s" % [
		(out.results as Array).size(), refused, skipped, out.changed, int(out.doc.revision), (out.doc.get("threads", []) as Array).size(),
		(out.doc.get("strokes", []) as Array).size(), "none" if walls == null else str((walls as Dictionary).size())])
	quit(0)

## How many arguments a static function of `s` takes (0 when it has none of that name).
static func _arity(s: Script, fn: String) -> int:
	for m in s.get_script_method_list():
		if str(m.get("name", "")) == fn:
			return (m.get("args", []) as Array).size()
	return 0
