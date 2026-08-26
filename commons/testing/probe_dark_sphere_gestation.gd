extends SceneTree
## THE GESTATION, RUNGS ONE AND TWO (2026-08-24, Palle: "it could be inert form
## from the beginning. If we shoot the DS in point a point appears and falls to
## the ground. If we shoot the DS in line a line falls out and breaks to pieces").
##
## Proves the hook end to end:
##   1. the sphere carries a HIT BODY on the catalyst's own layer (2) with mask 0
##   2. the stage is DERIVED from where it stands — a pearl or a map name — and
##      "point lines" reads as a LINE, not a point, though it carries both words
##   3. shooting it in the point place drops a point that FALLS
##   4. shooting it in the line place drops a line that BREAKS TO PIECES
##   5. a place that has taught nothing yields nothing and leaves the egg whole
##   6. the yield outlives the egg (it belongs to the room, not the sphere)
## godot --headless --path . --xr-mode off --script res://commons/testing/probe_dark_sphere_gestation.gd

const OUT := "res://ada_run/gestation_probe.txt"
const DS := "res://commons/artifacts/dark_sphere/dark_sphere.tscn"


func _initialize() -> void:
	call_deferred("_run")


## a sphere standing in a named place: the museum stamps em_pearl on the hall,
## so a host node carrying that meta is exactly what the artifact walks up to
func _sphere_in(place: String) -> Node3D:
	var host := Node3D.new()
	host.name = "Hall_" + place.replace(" ", "_")
	if place != "":
		host.set_meta("em_pearl", place)
	get_root().add_child(host)
	var s: Node3D = (load(DS) as PackedScene).instantiate() as Node3D
	host.add_child(s)
	return s


func _run() -> void:
	var fails: Array = []
	var notes: Array = []

	# ── 1. the hit body, on the catalyst's layer
	var s_point: Node3D = _sphere_in("point")
	await create_timer(0.8).timeout
	var body: Node = s_point.find_child("GestationHit", true, false)
	if body == null:
		fails.append("no GestationHit body — the catalyst cannot hit a dark sphere")
	else:
		var sb := body as StaticBody3D
		if sb.collision_layer != 2:
			fails.append("hit body on layer %d, the catalyst looks at 2" % sb.collision_layer)
		elif sb.collision_mask != 0:
			fails.append("hit body has mask %d — it will shove the world's cubes" % sb.collision_mask)
		else:
			notes.append("the sphere carries a hit body on layer 2, mask 0")

	# ── 2 + 3. the point place drops a point, and it falls
	if not s_point.has_method("hit_by_catalyst_mode"):
		fails.append("dark_sphere does not answer hit_by_catalyst_mode — the catalyst dispatches by NAME")
		_report(fails, notes)
		return
	notes.append("it answers the catalyst's duck-typed call")
	s_point.call("hit_by_catalyst_mode", Color(1, 0.4, 0.9), "transformation")
	await create_timer(0.1).timeout
	var host_p: Node = s_point.get_parent()
	var pt: Node = host_p.find_child("YieldPoint", true, false)
	if pt == null:
		fails.append("shot in the point place and no point appeared")
	else:
		var y0: float = (pt as Node3D).global_position.y
		await create_timer(0.9).timeout
		var y1: float = (pt as Node3D).global_position.y
		if y1 >= y0 - 0.02:
			fails.append("the point did not fall (%.2f -> %.2f)" % [y0, y1])
		else:
			notes.append("a point appears and FALLS (%.2f -> %.2f m)" % [y0, y1])
		# 6. the yield belongs to the room
		if pt.get_parent() == s_point:
			fails.append("the yield hangs off the egg — it would be freed with it")
		else:
			notes.append("the yield belongs to the room, not the egg")

	# ── 2 + 4. the line place drops a line that breaks
	var s_line: Node3D = _sphere_in("point lines")
	await create_timer(0.8).timeout
	if String(s_line.call("_gest_stage")) != "line":
		fails.append("'point lines' derived as '%s' — it carries both words and must read as a LINE" % String(s_line.call("_gest_stage")))
	else:
		notes.append("'point lines' derives as a line, not a point")
	s_line.call("hit_by_catalyst_mode", Color(0.4, 1, 0.9), "transformation")
	await create_timer(0.1).timeout
	var host_l: Node = s_line.get_parent()
	var segs: Array = []
	for n in host_l.get_children():
		if str(n.name).begins_with("YieldLine"):
			segs.append(n)
	if segs.size() < 3:
		fails.append("shot in the line place and got %d piece(s)" % segs.size())
	else:
		# ONE line at birth: every piece on the same axis, level
		var spread0: float = 0.0
		for n in segs:
			spread0 = maxf(spread0, absf((n as Node3D).global_position.z - (segs[0] as Node3D).global_position.z))
		await create_timer(1.0).timeout
		var spread1: float = 0.0
		var fell := true
		for n in segs:
			spread1 = maxf(spread1, absf((n as Node3D).global_position.z - (segs[0] as Node3D).global_position.z))
			if (n as Node3D).global_position.y > 0.04:
				fell = false
		if not fell:
			notes.append("%d pieces, still falling" % segs.size())
		if spread1 <= spread0 + 0.001:
			fails.append("the line did not break — the pieces stayed a rod")
		else:
			notes.append("a line falls out and BREAKS TO PIECES (%d, spread %.3f -> %.3f m)" % [
				segs.size(), spread0, spread1])

	# ── 5. a place that has taught nothing leaves the egg whole
	var s_none: Node3D = _sphere_in("melencolia")
	await create_timer(0.8).timeout
	if String(s_none.call("_gest_stage")) != "":
		fails.append("a place with no rung derived '%s'" % String(s_none.call("_gest_stage")))
	s_none.call("hit_by_catalyst_mode", Color.WHITE, "transformation")
	await create_timer(0.2).timeout
	var made := 0
	for n in (s_none.get_parent() as Node).get_children():
		if str(n.name).begins_with("Yield"):
			made += 1
	if made > 0:
		fails.append("a place that has taught nothing still yielded %d thing(s)" % made)
	else:
		notes.append("a place that has taught nothing yields nothing, and the egg stays whole")

	_report(fails, notes)


func _report(fails: Array, notes: Array) -> void:
	var report := "DARK SPHERE GESTATION PROBE\n"
	for n in notes:
		report += "  ok   %s\n" % n
	for f in fails:
		report += "  FAIL %s\n" % f
	report += "%d fail(s)\n" % fails.size()
	var fh := FileAccess.open(OUT, FileAccess.WRITE)
	fh.store_string(report)
	fh.close()
	print(report)
	quit(1 if not fails.is_empty() else 0)
