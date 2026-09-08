extends SceneTree

## DO TRANS_PIT'S HAZARDS GET THE NUMBERS THEIR MAP GIVES THEM?
##
## 2026-09-08, Astra's brief item 3: "Investigate the stationary grower blocks:
## trace min, max and speed from map token to runtime; repair any lost
## configuration and demonstrate growth."
##
## The map says, three times over:
##     grower_block#min:0.3#max:3.5#speed:0.3
## and grower_block.gd:42 computes its size as
##     lerpf(min_scale, max_scale, t)
## so if min and max arrive equal the block is a constant, and a constant block is
## a stationary one. That is the reported symptom.
##
## THE TWO ENGINES DISAGREE, WHICH IS WHY THIS NEEDS MEASURING RATHER THAN
## READING. GridInteractablesComponent._parse_config_token (:1680) reads
## `#key:value` as the tutorial shorthand — an id and a rotation — whenever the key
## is not in CONFIG_PARAM_NAMES and the value parses as a float. `min` and `max`
## are not in that list; `speed` is. The key then arrives as the BOOLEAN `true`,
## and grower_block.gd:92 does `float(config_data["min"])` with no guard, so
## min_scale and max_scale both become 1.0. The museum's lane has no such branch:
## ada_run/em_plan.json carries this hall's config as
## {"min": "0.3", "max": "3.5", "speed": "0.3"}, strings, intact.
##
## So the prediction is that the same three blocks breathe in the endless museum
## and stand still in the grid. This probe walks the GRID lane, which is the one
## the prediction says is broken, and reports what the live nodes actually hold.
##
## It fails on purpose while the defect stands: it asserts that the numbers on the
## map reached the artifact. Repairing it means naming `min`, `max`, `distance`
## and `pause` in CONFIG_PARAM_NAMES — a grid change with its own negative test —
## or respelling the tokens with words. Not done here; this is the evidence.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_pit_hazard_config.gd

const CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const MAP := "Trans_Pit"
const REPORT := "res://ada_run/pit_hazard_config_probe.txt"

## What commons/maps/Trans_Pit/map_data.json actually asks for.
const WANT_GROWER := {"min": 0.3, "max": 3.5, "speed": 0.3}

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if change_scene_to_file(CATALOG) != OK:
		_check(false, "the catalog loads", "catalog scene would not load")
		_finish()
		return
	await process_frame
	await process_frame
	var ok: bool = bool(current_scene.call("load_map_fresh", MAP))
	_check(ok, "%s loads in the GRID lane" % MAP, "%s did not load" % MAP)
	if not ok:
		_finish()
		return
	for i in range(180):
		await process_frame

	var growers: Array[Node] = []
	var pushers: Array[Node] = []
	_collect(root, growers, pushers)
	_say("found %d grower_block(s) and %d pusher_block(s)" % [growers.size(), pushers.size()])
	_check(growers.size() > 0, "  the growers are in the hall", "no grower_block was built at all")
	if growers.is_empty():
		_finish()
		return

	# ── what the artifact is holding ──────────────────────────────────
	for n in growers:
		_say("  grower at %s  min_scale=%.3f  max_scale=%.3f  grow_speed=%.3f"
			% [str(n.global_position.round()), float(n.get("min_scale")),
				float(n.get("max_scale")), float(n.get("grow_speed"))])
	var g: Node = growers[0]
	_check(is_equal_approx(float(g.get("min_scale")), WANT_GROWER["min"]),
		"  min_scale is the map's 0.30: %.3f" % float(g.get("min_scale")),
		"min_scale is %.3f and the map says 0.30 — #min: was eaten by the grid's shorthand branch" % float(g.get("min_scale")))
	_check(is_equal_approx(float(g.get("max_scale")), WANT_GROWER["max"]),
		"  max_scale is the map's 3.50: %.3f" % float(g.get("max_scale")),
		"max_scale is %.3f and the map says 3.50 — #max: was eaten by the grid's shorthand branch" % float(g.get("max_scale")))
	_check(is_equal_approx(float(g.get("grow_speed")), WANT_GROWER["speed"]),
		"  grow_speed is the map's 0.30: %.3f" % float(g.get("grow_speed")),
		"grow_speed is %.3f, and `speed` IS in CONFIG_PARAM_NAMES, so this one should have arrived" % float(g.get("grow_speed")))

	# ── DOES IT ACTUALLY MOVE? the symptom, not the cause ─────────────
	# Watched rather than reasoned about: a block whose exports are equal is a
	# constant, but only the built mesh proves the visitor sees a constant.
	var lo := INF
	var hi := -INF
	for i in range(300):
		await process_frame
		await physics_frame
		var s: float = _size_of(g)
		if s > 0.0:
			lo = minf(lo, s)
			hi = maxf(hi, s)
	_say("  over 5 s the block's built size ran %.3f .. %.3f m (swing %.3f)" % [lo, hi, hi - lo])
	_check(hi - lo > 0.05, "  it breathes",
		"the block never changed size by more than %.3f m in five seconds — it is stationary, which is what Astra reported" % (hi - lo))

	# ── the pushers, same fault, smaller symptom ──────────────────────
	for n in pushers:
		_say("  pusher at %s  push_distance=%.2f (map says 3)  push_speed=%.2f  pause_time=%.2f"
			% [str(n.global_position.round()), float(n.get("push_distance")),
				float(n.get("push_speed")), float(n.get("pause_time"))])
	if not pushers.is_empty():
		var p: Node = pushers[0]
		_check(float(p.get("push_distance")) > 2.0,
			"  the pushers travel the 3 m the map asks for",
			"push_distance is %.2f and the map says 3 — `distance` is not in CONFIG_PARAM_NAMES either, so these stones move a third of their stroke" % float(p.get("push_distance")))

	_finish()


## Its built size, read off whatever mesh it made rather than off an export, so a
## block that lies about itself cannot pass.
func _size_of(n: Node) -> float:
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.mesh != null:
				return (mi.global_transform.basis * mi.mesh.get_aabb().size).length()
		for k in c.get_children():
			stack.append(k)
	return 0.0


func _collect(n: Node, growers: Array[Node], pushers: Array[Node]) -> void:
	var tok := ""
	if n.has_meta("artifact_lookup_name"):
		tok = str(n.get_meta("artifact_lookup_name"))
	if tok == "grower_block" and n is Node3D:
		growers.append(n)
		return
	if tok == "pusher_block" and n is Node3D:
		pushers.append(n)
		return
	for c in n.get_children():
		_collect(c, growers, pushers)


func _say(line: String) -> void:
	_lines.append("[probe] %s" % line)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
