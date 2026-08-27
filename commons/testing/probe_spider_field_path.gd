extends SceneTree
## THREE CLAIMS FROM THE GENEALOGY, MEASURED (2026-08-26).
##
## The source-reading pass produced three findings that would each change what
## ships. None of them can be settled by reading, and one of them lands on a
## placement made an hour ago:
##
##   A. THE FIELD PATH. probe_head_crab_deploy called apply_grid_config BEFORE
##      add_child and watched crab_scale become 0.11. GridInteractablesComponent
##      calls it AFTER the node is in the tree, so _ready has already built and
##      scaled the rig. If the setter does not rebuild, the arena's small teal
##      crab is not small. This is the fixture-stood-on-the-happy-cell case.
##   B. THE COLLIDER. The registry files it under "hazard". The reading found
##      no physics body anywhere in the chain.
##   C. THE FLOOR. Every plant is written to y = 0.0 absolute. Both arena crabs
##      stand on structure cells of height 1, seated at 0.5 m.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const TXT := "res://ada_run/spider_field_path.txt"

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _extent(n: Node3D) -> float:
	var box := AABB()
	var has := false
	var stack: Array = [n]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		if q is VisualInstance3D:
			var vi: VisualInstance3D = q
			var wb: AABB = vi.global_transform * vi.get_aabb()
			if wb.size.length() > 0.0001 and wb.size.length() < 4.0:
				box = wb if not has else box.merge(wb)
				has = true
		for ch in q.get_children(): stack.append(ch)
	return box.size.length() if has else 0.0

func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(80, 0.4, 80); cs.shape = bx; cs.position = Vector3(0, -0.2, 0)
	fb.add_child(cs); st.add_child(fb)
	# a raised deck at 0.5 m, which is what a structure cell of height 1 seats at
	var deck := StaticBody3D.new(); var dcs := CollisionShape3D.new(); var dbx := BoxShape3D.new()
	dbx.size = Vector3(6, 1.0, 6); dcs.shape = dbx; dcs.position = Vector3(20, 0.0, 0)
	deck.add_child(dcs); st.add_child(deck)
	var dm := MeshInstance3D.new(); var dbm := BoxMesh.new()
	dbm.size = Vector3(6, 1.0, 6); dm.mesh = dbm; dm.position = Vector3(20, 0.0, 0)
	st.add_child(dm)
	var w := CharacterBody3D.new(); w.name = "Walker"; w.add_to_group("em_walker")
	st.add_child(w); w.global_position = Vector3(0, 0, -14)

	# ── A. THE FIELD PATH ──────────────────────────────────────────────────
	_say("A. DOES #scale REACH IT ON THE PATH A MAP ACTUALLY USES")
	var a: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D   # default
	st.add_child(a); a.global_position = Vector3(0, 0, 0)
	var b: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D   # BEFORE tree
	b.call("apply_grid_config", {"scale": "0.11"})
	st.add_child(b); b.global_position = Vector3(6, 0, 0)
	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D   # AFTER tree
	st.add_child(c); c.global_position = Vector3(12, 0, 0)
	await create_timer(1.4).timeout
	c.call("apply_grid_config", {"scale": "0.11"})
	await create_timer(0.8).timeout
	var ea := _extent(a); var eb := _extent(b); var ec := _extent(c)
	_say("   default (0.15)            extent %.4f m   crab_scale %.3f" % [ea, float(a.get("crab_scale"))])
	_say("   configured BEFORE tree    extent %.4f m   crab_scale %.3f" % [eb, float(b.get("crab_scale"))])
	_say("   configured AFTER  tree    extent %.4f m   crab_scale %.3f" % [ec, float(c.get("crab_scale"))])
	var want: float = eb / maxf(ea, 0.0001)
	var got: float = ec / maxf(ea, 0.0001)
	_say("   ratio to default: before %.3f   after %.3f   (0.11/0.15 = 0.733)" % [want, got])
	if absf(got - want) > 0.04:
		_say("   FAIL — the field path does NOT resize the animal. The arena's small")
		_say("          teal crab ships at full size; only its accent took.")
	else:
		_say("   ok — the field path resizes it too")
	_say("")

	# ── B. THE COLLIDER ────────────────────────────────────────────────────
	_say("B. WHAT CAN IT TOUCH")
	var counts := {}
	var stack: Array = [a]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		for k in ["StaticBody3D", "CharacterBody3D", "RigidBody3D", "Area3D", "CollisionShape3D", "SpringArm3D"]:
			if q.get_class() == k: counts[k] = int(counts.get(k, 0)) + 1
		for ch in q.get_children(): stack.append(ch)
	var ks: Array = counts.keys(); ks.sort()
	if ks.is_empty(): _say("   no physics node of any kind in the whole animal")
	for k in ks: _say("   %-20s %d" % [k, counts[k]])
	_say("   -> it %s" % ("can be touched" if (counts.has("Area3D") or counts.has("StaticBody3D") or counts.has("RigidBody3D")) else "passes through the visitor: no body, no area, no damage"))
	_say("")

	# ── C. THE FLOOR ───────────────────────────────────────────────────────
	_say("C. WHERE THE FEET GO WHEN THE FLOOR IS NOT AT ZERO")
	var d: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(d); d.global_position = Vector3(20, 0.5, 0)   # standing on the deck
	await create_timer(2.4).timeout
	var feet: Array = d.get("_feet")
	var lo := 99.0; var hi := -99.0
	for f in feet:
		if f == null or not is_instance_valid(f): continue
		var y: float = (f as Node3D).global_position.y
		lo = minf(lo, y); hi = maxf(hi, y)
	_say("   deck top at y = 0.500 m")
	_say("   foot world y ranged %.3f .. %.3f" % [lo, hi])
	if lo < 0.25:
		_say("   FAIL — the feet plant at world zero, half a metre through the deck.")
		_say("          Four SpringArm3D probes hang under it, unread.")
	else:
		_say("   ok — the feet found the deck")
	var f2 := FileAccess.open(TXT, FileAccess.WRITE)
	f2.store_string("\n".join(PackedStringArray(_l)) + "\n"); f2.close()
	quit(0)
