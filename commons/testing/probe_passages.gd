extends SceneTree
## THE PASSAGE DECLARATION, TESTED (2026-08-24, Palle: "yes add the
## museum.passage declaration so halls can own their crossings"). Calls the
## museum's own _authored_passages with each kind and reads the rows back —
## a declaration that does not change the shape is decoration, so every
## assertion here is about the CELLS, not the config.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_passages.gd

const OUT := "res://ada_run/passages_probe.txt"


func _initialize() -> void:
	call_deferred("_run")


func _rowstr(row: Array) -> String:
	var s := ""
	for v in row:
		s += "." if String(v) == "1" else "#"
	return s


func _run() -> void:
	var fails: Array = []
	var notes: Array = []
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	# no tree: _authored_passages is pure tile arithmetic
	var base: Array = []
	for r in range(6):
		var row: Array = []
		for c in range(11):
			row.append("4" if (c == 0 or c == 10 or r == 0 or r == 5) else "1")
		base.append(row)

	var cases: Array = [
		{"name": "default (silent hall)", "decl": {}, "rows": 3, "want_path": 2},
		{"name": "width 3", "decl": {"width": 3}, "rows": 3, "want_path": 3},
		{"name": "straight", "decl": {"kind": "straight", "width": 3}, "rows": 3, "want_path": 3},
		{"name": "hall", "decl": {"kind": "hall", "width": 3, "offset": 4}, "rows": 4, "want_path": 3},
		{"name": "none", "decl": {"kind": "none"}, "rows": 0, "want_path": 0},
	]
	var shapes: Dictionary = {}
	for c_v in cases:
		var c: Dictionary = c_v
		var out: Array = inst.call("_authored_passages", base, c["decl"])
		var added: int = out.size() - base.size()
		if added != int(c["rows"]):
			fails.append("%s: added %d row(s), wanted %d" % [c["name"], added, int(c["rows"])])
			continue
		if added == 0:
			notes.append("%s: no rows added (the halls meet at their doors)" % c["name"])
			shapes[c["name"]] = "-"
			continue
		var first: Array = out[base.size()]
		var last: Array = out[out.size() - 1]
		var n_first: int = 0
		var n_last: int = 0
		for v in first:
			if String(v) == "1":
				n_first += 1
		for v in last:
			if String(v) == "1":
				n_last += 1
		if n_first != int(c["want_path"]) or n_last != int(c["want_path"]):
			fails.append("%s: doors %d/%d wide, wanted %d" % [c["name"], n_first, n_last, int(c["want_path"])])
		# the DOGLEG: a chicane's two doors must not share a column;
		# a straight passage's must line up exactly
		var col_first: int = -1
		var col_last: int = -1
		for i in range(first.size()):
			if String(first[i]) == "1" and col_first < 0:
				col_first = i
			if String(last[i]) == "1" and col_last < 0:
				col_last = i
		var straight: bool = String(c["decl"].get("kind", "chicane")) == "straight"
		if straight and col_first != col_last:
			fails.append("%s: doors at %d and %d — a straight passage must line up" % [c["name"], col_first, col_last])
		if not straight and col_first == col_last:
			fails.append("%s: doors both at column %d — no dogleg, the corner is gone" % [c["name"], col_first])
		var lines: Array = []
		for r in range(base.size(), out.size()):
			lines.append(_rowstr(out[r]))
		shapes[c["name"]] = " / ".join(lines)
		notes.append("%s: %d row(s), doors %d wide at cols %d→%d" % [c["name"], added, n_first, col_first, col_last])

	var report := "PASSAGE DECLARATION PROBE\n"
	for nt in notes:
		report += "  ok   %s\n" % nt
	for fl in fails:
		report += "  FAIL %s\n" % fl
	report += "\nshapes (. = walk, # = wall)\n"
	for k in shapes.keys():
		report += "  %-22s %s\n" % [k, shapes[k]]
	report += "%d fail(s)\n" % fails.size()
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(report)
	f.close()
	print(report)
	quit(1 if not fails.is_empty() else 0)
