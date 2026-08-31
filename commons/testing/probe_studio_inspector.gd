extends SceneTree

## DOES THE STUDIO'S DRESS PANEL EXIST, AND DOES IT WRITE?
##
## 2026-08-31, Palle: "I like museum studio can I get a new inspector panel where
## I can set plinth , offset etc etc". A panel that compiles is not a panel that
## works, and the last two UI additions in this session could not be driven
## headlessly at all. This one can: probe_studio.gd already showed the studio can
## be instantiated and its selection set from outside, so the panel can be built,
## read back, and USED.
##
## Three questions, and the third is the one that matters:
##
##   1 built     selecting a body puts controls in the box — an OptionButton for
##               the plinth and two SpinBoxes
##   2 reads     the dropdown opens on the height the plan row actually carries,
##               rather than on the top of its own list
##   3 WRITES    calling what the dropdown calls changes the plan row, and the
##               value that lands is the one that was picked
##
## It restores the row it touched, so the plan is as it found it.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_studio_inspector.gd

var _fails: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var s: Node3D = (load("res://commons/scenes/museum_studio.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(s)
	await create_timer(7.0).timeout

	var recs: Array = s.call("_records")
	print("")
	print("STUDIO DRESS PANEL")
	print("  %d record(s) in the hall" % recs.size())

	var body: Dictionary = {}
	for r in recs:
		if String(s.call("_kind", r)) == "body":
			body = r
			break
	if body.is_empty():
		print("  no body to select — cannot test")
		quit(2)
		return

	s.set("_sel", body)
	s.set("_sel_key", s.call("_key_of", body))
	s.call("_show_selection")
	await process_frame

	var box: VBoxContainer = s.get("_insp_box")
	if box == null:
		_bad("1 built", "there is no _insp_box at all")
		quit(1)
		return

	var opts: Array = []
	var spins: Array = []
	_walk(box, opts, spins)
	_ok("1 built", "%d dropdown(s), %d spinner(s) for %s"
		% [opts.size(), spins.size(), String(body.get("token", "?"))], opts.size() >= 1 and spins.size() >= 2)

	var row: Dictionary = s.call("_plan_row_for", body)
	var was: float = float(row.get("support_height_m", 0.0))
	if opts.size() > 0:
		var ob: OptionButton = opts[0]
		var shown: String = ob.get_item_text(ob.selected)
		var want: String = "none" if was < 0.05 else "%.2f m" % was
		_ok("2 reads", "row says %s, dropdown shows %s" % [want, shown], shown == want)

	# 3 — call exactly what item_selected calls, with a height the row does not have
	var supports: Array = s.get("STUDIO_SUPPORTS")
	var pick: int = 0
	for i in range(supports.size()):
		if absf(float(supports[i]) - was) > 0.2:
			pick = i
			break
	var target: float = float(supports[pick])
	s.call("_studio_pick_support", pick)
	await create_timer(6.0).timeout

	var after: float = -1.0
	var seen: int = 0
	for a in (s.call("_row") as Dictionary).get("artifacts", []):
		var ad: Dictionary = a
		if String(ad.get("token", "")) != String(body.get("token", "")):
			continue
		seen += 1
		print("      candidate cell %s (record %s)  support=%s"
			% [str(ad.get("tile_cell", [])), str(body.get("tile_cell", [])), str(ad.get("support_height_m", "-"))])
		after = float(ad.get("support_height_m", 0.0))
	if seen == 0:
		print("      the row carries NO artifact named %s" % String(body.get("token", "")))
	_ok("3 WRITES", "%.2f -> %.2f (asked %.2f)" % [was, after, target], absf(after - target) < 0.01)

	# put it back
	var back: int = 0
	for i in range(supports.size()):
		if absf(float(supports[i]) - was) < 0.03:
			back = i
	s.call("_studio_pick_support", back)
	await create_timer(6.0).timeout
	print("  restored to %.2f" % was)

	print("")
	print("  %d FAILED" % _fails)
	quit(1 if _fails > 0 else 0)


func _walk(n: Node, opts: Array, spins: Array) -> void:
	for c in n.get_children():
		if c is OptionButton:
			opts.append(c)
		elif c is SpinBox:
			spins.append(c)
		_walk(c, opts, spins)


func _ok(what: String, detail: String, good: bool) -> void:
	if not good:
		_fails += 1
	print("  %-10s %s   %s" % [what, "ok  " if good else "FAIL", detail])


func _bad(what: String, detail: String) -> void:
	_fails += 1
	print("  %-10s FAIL   %s" % [what, detail])
