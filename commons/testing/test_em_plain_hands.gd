extends SceneTree
## GATE: plain hands in the VR museum. Instances the STAGED scene (base.tscn
## rig + museum, the thing the menu loads) with the VR path forced, and checks:
## the wrist tools are gone, the pickup + pointer + collision hands remain on
## both hands, and every catalyst body the plan dealt has its pickables off.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var ps: PackedScene = load("res://commons/scenes/endless_museum_staged.tscn")
	var root: Node = ps.instantiate()
	var m: Node = root.find_child("Museum", true, false)
	m.set("_force_vr", true)
	# open at the pearl that deals catalyst_pedestal / vent / prompter box, so
	# the disarm is measured on real bodies, not on an empty set
	m.set("start_chapter", "primitives")
	m.set("start_map", "Point_Triangle_Context")
	get_root().add_child(root)
	await create_timer(5.0).timeout
	var why: Array = []
	for nm in ["HandWorkstationVR", "messageconsole", "WristStatsDisplay", "GravityGun"]:
		var left: Array = root.find_children(nm, "", true, false)
		var alive: int = 0
		for n in left:
			if is_instance_valid(n) and not (n as Node).is_queued_for_deletion(): alive += 1
		if alive > 0: why.append("%s still on the rig (%d)" % [nm, alive])
	for hand in ["LeftHand", "RightHand"]:
		var h: Node = root.find_child(hand, true, false)
		if h == null: why.append("no %s" % hand); continue
		for keep in ["FunctionPickup", "FunctionPointer", "XRToolsCollisionHand"]:
			if h.find_child(keep, true, false) == null: why.append("%s lost %s" % [hand, keep])
		var fp: Node = h.find_child("FunctionPickup", true, false)
		if fp != null and fp.get("enabled") == false: why.append("%s pickup disabled" % hand)
	# catalyst bodies: pickables off; every other pickable: on
	var stack: Array = [m]
	var cat_on: int = 0; var cat_off: int = 0; var other_on: int = 0
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if n.has_method("pick_up") and n.has_method("let_go") and "enabled" in n:
			var tok: String = ""
			var a: Node = n
			while a != null and tok == "":
				if a.has_meta("artifact_lookup_name"): tok = String(a.get_meta("artifact_lookup_name"))
				a = a.get_parent()
			var is_cat: bool = tok.begins_with("catalyst") or tok == "becoming_catalyst" or tok == "wedge_skill_pickup"
			if is_cat:
				if bool(n.get("enabled")): cat_on += 1
				else: cat_off += 1
			elif bool(n.get("enabled")): other_on += 1
	# the staging strip (bare_hands.gd) runs on every menu-loaded scene: after it,
	# the pickups and pointers must still be there — that strip is what took
	# grab away from every VR scene between 08-14 and 08-18
	var bare = load("res://commons/scenes/bare_hands.gd")
	var origin: Node = root.find_child("XROrigin3D", true, false)
	bare.apply(origin)
	for hand in ["LeftHand", "RightHand"]:
		var h2: Node = origin.find_child(hand, true, false)
		for keep in ["FunctionPickup", "FunctionPointer"]:
			var kn: Node = h2.find_child(keep, true, false) if h2 != null else null
			if kn == null or kn.is_queued_for_deletion(): why.append("bare_hands strip removed %s from %s" % [keep, hand])
	if cat_on > 0: why.append("%d catalyst pickable(s) still enabled" % cat_on)
	if cat_off == 0: why.append("no catalyst pickable found — the disarm was not measured (start map wrong?)")
	if other_on == 0: why.append("no ordinary pickable enabled — the visitor cannot grab anything")
	print("EM PLAIN HANDS: wrist tools off, pickup+pointer+collision on both hands, catalyst pickables off %d / on %d, other pickables on %d" % [cat_off, cat_on, other_on])
	for w in why: print("EM PLAIN HANDS: " + String(w))
	print("EM PLAIN HANDS: %s" % ("PASS" if why.is_empty() else "FAIL"))
	quit(0 if why.is_empty() else 1)
