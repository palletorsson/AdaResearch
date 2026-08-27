extends SceneTree
## THE SPIDER, IN THE FIRST TRANSFORMATION ROOM (2026-08-27, Palle: "move the
## spider to transformation map one").
##
## Loaded through the project's own catalog, not built on a bench: the map token
## has to resolve, the grid has to seat it, and it has to find a visitor in a
## room whose middle is three open pools. A bench floor would prove none of it.
const CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const TXT := "res://ada_run/crab_in_trans.txt"

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _find(n: Node) -> Node3D:
	var st: Array = [n]
	while not st.is_empty():
		var q: Node = st.pop_back()
		var sc = q.get_script()
		if sc != null and String(sc.resource_path).contains("head_crab"):
			return q as Node3D
		for c in q.get_children(): st.append(c)
	return null

func _run() -> void:
	if change_scene_to_file(CATALOG) != OK:
		_say("FAIL no catalog"); quit(1); return
	await process_frame
	await process_frame
	var cat: Node = current_scene
	if cat == null or not bool(cat.call("load_map_fresh", "Trans_Introduction")):
		_say("FAIL Trans_Introduction would not load"); quit(1); return
	await create_timer(3.0).timeout

	var crab: Node3D = _find(get_root())
	_say("TRANS_INTRODUCTION")
	_say("  head_crab in the built map: %s" % ("yes, at " + str(crab.global_position) if crab != null else "NO"))
	var fails: Array = []
	if crab == null:
		fails.append("the token did not become an animal")
	else:
		_say("  detect_m %.1f (the token asks for 14)" % float(crab.get("detect_m")))
		var feet: Array = crab.get("_feet")
		var lo := 99.0
		for f in feet:
			if f != null and is_instance_valid(f): lo = minf(lo, (f as Node3D).global_position.y)
		_say("  floor it learned %.3f, feet at %.3f" % [float(crab.get("_floor_y")), lo])

		# a visitor a few metres away, in the same north room
		var p := Node3D.new()
		p.name = "PlayerBody"
		p.add_to_group("player")
		p.set_script(preload("res://commons/testing/probe_crab_bite_dummy.gd"))
		current_scene.add_child(p)
		p.global_position = crab.global_position + Vector3(-3.5, 0.6, 0.5)
		var start: float = crab.global_position.distance_to(p.global_position)
		var t := 0.0
		while t < 20.0 and int(p.get("hits")) == 0:
			await create_timer(0.05).timeout
			t += 0.05
		var bit: bool = int(p.get("hits")) > 0
		_say("  a visitor %.2f m away: bitten after %.2f s — %s" % [start, t, str(bit)])
		if not bit:
			fails.append("it never reached a visitor 3.5 m away in the same room")

	_say("")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("it stands in the first transformation room and hunts there"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() else 1)
