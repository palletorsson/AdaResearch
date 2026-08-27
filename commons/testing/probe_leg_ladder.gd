extends SceneTree
## THE LADDER, MEASURED ON THE RIGHT NODE (2026-08-27).
##
## The first version of this probe read the ROOT's global_position and reported
## "7 of 7 never moved without input". That was false and it was the trap this
## directory already documents: the script lives on a `Body` CHILD of a bare
## Node3D root, so the patrol writes the Body and the root never moves. Five of
## the six had been pacing the whole time. Measuring the wrong node is how a
## family gets diagnosed with a disease it does not have.
##
## It also clipped every footprint with an 8 m box filter, which cut the legs
## off animals that are seven metres tall.
##
## Now: find the scripted node, turn the pace on the way a map token would, and
## ask the three questions the room depends on — does it move by itself, does
## the leash hold it, and do its feet land on the deck it stands on.
const DIR := "res://commons/hazards/octapod_crawler/"
const NAMES := ["one_leg", "two_leg_critter", "three_leg_critter", "four_leg_critter",
	"five_leg_critter", "six_leg_critter", "octapod_ik"]
const TXT := "res://ada_run/leg_ladder.txt"
const JSN := "res://ada_run/leg_ladder.json"
const DECK_TOP := 0.5
const REACH := 1.5

var _l: Array = []
var _rows: Array = []

func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

## the node that actually carries the walker script — never the .tscn root
func _scripted(n: Node) -> Node3D:
	# NOT merely "the first scripted node". The roots now carry a config
	# forwarder, so that rule returns the root — the very trap this probe was
	# rewritten to avoid, re-armed by the fix that gave the roots a script.
	# The node that owns the gait is the one that owns the gait's properties.
	var stack: Array = [n]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		if q is Node3D and q.get_script() != null and q.get("driven_by_player") != null:
			return q as Node3D
		for c in q.get_children(): stack.append(c)
	return null

func _extent(n: Node3D) -> Vector3:
	var box := AABB(); var has := false
	var stack: Array = [n]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		if q is VisualInstance3D:
			var vi: VisualInstance3D = q
			var wb: AABB = vi.global_transform * vi.get_aabb()
			# only a runaway backdrop is excluded; these animals are 7 m tall
			if wb.size.length() > 0.0001 and wb.size.length() < 60.0:
				box = wb if not has else box.merge(wb)
				has = true
		for c in q.get_children(): stack.append(c)
	return box.size if has else Vector3.ZERO

func _feet_of(n: Node) -> Array:
	var out: Array = []
	var stack: Array = [n]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		var nm := String(q.name).to_lower()
		if q is Node3D and (nm.begins_with("foottarget") or nm.begins_with("foot_")):
			out.append(q)
		for c in q.get_children(): stack.append(c)
	return out

func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	var deck := StaticBody3D.new(); var dcs := CollisionShape3D.new(); var dbx := BoxShape3D.new()
	dbx.size = Vector3(400, 1.0, 60); dcs.shape = dbx; dcs.position = Vector3(90, 0.0, 0)
	deck.add_child(dcs); st.add_child(deck)
	var dm := MeshInstance3D.new(); var dbm := BoxMesh.new()
	dbm.size = Vector3(400, 1.0, 60); dm.mesh = dbm; dm.position = Vector3(90, 0.0, 0)
	st.add_child(dm)

	_say("THE LADDER ON A DECK WHOSE TOP IS AT %.3f — pace on, no input" % DECK_TOP)
	_say("")
	var x := 0.0
	var live: Array = []
	for nm in NAMES:
		var path: String = DIR + nm + ".tscn"
		if not ResourceLoader.exists(path):
			_say("%-20s no scene" % nm); continue
		var inst: Node = (load(path) as PackedScene).instantiate()
		if inst == null:
			_say("%-20s would not instantiate" % nm); continue
		st.add_child(inst)
		if inst is Node3D: (inst as Node3D).global_position = Vector3(x, DECK_TOP, 0)
		var body: Node3D = _scripted(inst)
		if body != null and body.get("driven_by_player") != null:
			body.set("driven_by_player", false)
			body.set("pace_reach", REACH)
			# a bench specimen: 7.3 m of critter under a 3 m wall is not an exhibit
			body.call("apply_grid_config", {"walker_scale": "0.16", "patrol_speed": "0.25"})
		live.append({"nm": nm, "root": inst, "body": body, "x": x})
		x += 24.0
	await create_timer(2.2).timeout

	for e in live:
		var ed: Dictionary = e
		var b: Node3D = ed["body"]
		ed["p0"] = b.global_position if b != null else (ed["root"] as Node3D).global_position
		ed["feet"] = _feet_of(ed["root"])

	await create_timer(9.0).timeout

	for e in live:
		var ed: Dictionary = e
		var root: Node3D = ed["root"]
		var b: Node3D = ed["body"]
		var nm := String(ed["nm"])
		var sz: Vector3 = _extent(root)
		var moved: float = 0.0
		var drift: float = 0.0
		var paced: String = "no script"
		if b != null:
			moved = b.global_position.distance_to(ed["p0"] as Vector3)
			var home: Vector3 = b.get("_pace_home") if b.get("_pace_home") != null else (ed["p0"] as Vector3)
			var away: Vector3 = b.global_position - home
			away.y = 0.0
			drift = away.length()
			paced = "%.2f m from home" % drift
		var ft: Array = ed["feet"]
		var lo := 99.0
		for f in ft:
			if f != null and is_instance_valid(f): lo = minf(lo, (f as Node3D).global_position.y)
		_say("%-20s body %-16s legs %d" % [nm, ("yes" if b != null else "NO SCRIPT"), ft.size()])
		_say("    size      %.2f x %.2f x %.2f m" % [sz.x, sz.z, sz.y])
		_say("    walked    %.2f m in 9 s, %s" % [moved, paced])
		if ft.is_empty():
			_say("    feet      none")
		else:
			_say("    feet at   %.3f  (deck %.3f)  %s" % [lo, DECK_TOP, "OK" if absf(lo - DECK_TOP) < 0.2 else "OFF THE DECK"])
		if b != null and drift > REACH * 1.6:
			_say("    LEASH BROKEN — %.2f m out on a %.2f m reach" % [drift, REACH])
		_rows.append({"name": nm, "has_script": b != null, "legs": ft.size(),
			"size": [sz.x, sz.z, sz.y], "walked_9s": moved, "drift": drift, "foot_y": lo})
		_say("")

	var scripted := 0; var walked := 0; var grounded := 0; var leashed := 0
	for r in _rows:
		var rd: Dictionary = r
		if bool(rd["has_script"]): scripted += 1
		if float(rd["walked_9s"]) > 0.15: walked += 1
		if absf(float(rd["foot_y"]) - DECK_TOP) < 0.2: grounded += 1
		if float(rd["drift"]) <= REACH * 1.6: leashed += 1
	_say("SUMMARY of %d: %d scripted, %d paced on their own, %d standing on the deck, %d inside the leash"
		% [_rows.size(), scripted, walked, grounded, leashed])
	var f2 := FileAccess.open(TXT, FileAccess.WRITE)
	f2.store_string("\n".join(PackedStringArray(_l)) + "\n"); f2.close()
	var j := FileAccess.open(JSN, FileAccess.WRITE)
	j.store_string(JSON.stringify({"rows": _rows}, "\t")); j.close()
	quit(0)
