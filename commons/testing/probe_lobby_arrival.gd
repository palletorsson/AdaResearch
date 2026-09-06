extends SceneTree

## Did the roof come off, did the ceiling close, and does the visitor arrive
## standing on the floor? (2026-09-04)
##
## Palle, in the headset: "I want the VR to start in this position, not on the
## roof, remove the roof and add the ceiling again." Three claims, and every one
## of them is invisible to the thing that would normally check it:
##
##   * The build print says the roof branch was SKIPPED. It does not say the deck
##     is gone — a deck laid by some other pass would print nothing and stand there.
##   * The ceiling closing is the ABSENCE of a keep-out. Absence prints nothing at
##     all, and the hall is ceilinged whether or not the hole was punched.
##   * The arrival point is read by _vr_drop_in(), which returns on the first line
##     without a headset. A desktop run therefore exercises none of it, which is
##     exactly how a museum can boot green with the visitor still on the roof.
##
## So this asks the PHYSICS SERVER instead of the log. It boots the museum, waits
## for the hall's own lobby config to arrive (which is what _lobby_map going
## non-empty means — before that every _L("lobby", ...) is answering out of
## em_layout.json, and this map's keys are not in em_layout.json), and then:
##
##   1. reads _drop_point() and asserts it is on the FLOOR of the drop cell
##   2. casts UP from there — expects a ceiling, and nothing at old roof height
##   3. casts DOWN from head height — expects floor within a centimetre of 0
##   4. stands the player's own capsule there — expects it to fit
##
##   godot --path . --xr-mode off --script res://commons/testing/probe_lobby_arrival.gd
##       -- --em-segments=2

const MUSEUM := "res://commons/scenes/endless_museum.tscn"
const PLAYER := "res://commons/scenes/desktop_player.tscn"
const REPORT := "res://ada_run/lobby_arrival_probe.txt"
const WALL_H := 4.0
const VESTIBULE_H := 4

var _lines: Array[String] = []
var _fails: Array[String] = []
var _cap_r: float = 0.30
var _cap_h: float = 1.80


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_read_envelope()
	var mus: Node3D = (load(MUSEUM) as PackedScene).instantiate() as Node3D
	root.add_child(mus)

	# THE BUILD IS ASYNCHRONOUS AND THE CONFIG ARRIVES WITH IT. _lobby_map is
	# filled during segment 0's peek; before that the museum answers every lobby
	# question out of em_layout.json, whose lobby block holds nothing but prose.
	# Reading the drop point too early therefore returns the pre-roof default and
	# looks like a pass.
	var waited: int = 0
	while waited < 3600:
		await process_frame
		waited += 1
		var lm: Variant = mus.get("_lobby_map")
		if lm is Dictionary and not (lm as Dictionary).is_empty():
			break
	var lobby: Dictionary = mus.get("_lobby_map") if mus.get("_lobby_map") is Dictionary else {}
	if lobby.is_empty():
		_fails.append("the museum never loaded Point_One's lobby config in %d frames" % waited)
		_finish()
		return
	_lines.append("[probe] the hall's lobby config arrived after %d frame(s): roof=%s drop_hole=%s drop=(%s, %s)" % [
		waited, str(lobby.get("roof", "<unset>")), str(lobby.get("drop_hole", "<unset>")),
		str(lobby.get("drop_x", "?")), str(lobby.get("drop_z", "?"))])
	for _i in range(30):
		await physics_frame

	# WHICH FRAME IS THE DROP POINT IN? _drop_hole() lays its deck with _box(seg, …)
	# and _trim_keep_out() cuts the ceiling with rects, both in SEGMENT-local cells;
	# _drop_point()'s result is assigned to _player.position and rig.global_position,
	# which are WORLD. If segment 0 does not sit at the world origin those are two
	# different rooms, and every reading below is off by the difference. So the
	# difference is measured and printed rather than assumed either way.
	var seg0: Node3D = null
	for c in mus.get_children():
		if c is Node3D and String(c.name).begins_with("Seg0"):
			seg0 = c
			break
	if seg0 == null:
		for c in mus.get_children():
			for g in c.get_children():
				if g is Node3D and String(g.name).begins_with("Seg0"):
					seg0 = g
					break
	_lines.append("[probe] segment 0 stands at world %s — segment-local z %s world z" % [
		str(seg0.global_transform.origin) if seg0 != null else "<not found>",
		("minus %.2f =" % seg0.global_transform.origin.z) if seg0 != null and absf(seg0.global_transform.origin.z) > 0.01 else "=="])

	var hx: float = float(lobby.get("drop_x", 6.0))
	var hz: float = float(lobby.get("drop_z", 1.0)) + float(VESTIBULE_H)
	# WORLD, so no vestibule term: segment 0 stands at world z = -VESTIBULE_H, which
	# the line above just measured rather than took on faith.
	var want := Vector3(hx + 0.5, 0.0, float(lobby.get("drop_z", 1.0)) + 0.5)

	# ── 1. where the visitor is put ──────────────────────────────────────
	var p: Vector3 = mus.call("_drop_point")
	_check(p.distance_to(want) < 0.01,
		"arrival at (%.2f, %.2f, %.2f) — the floor of the drop cell, map (%d, %d)"
			% [p.x, p.y, p.z, int(hx), int(hz) - VESTIBULE_H],
		"arrival at (%.2f, %.2f, %.2f), wanted (%.2f, %.2f, %.2f) — %s"
			% [p.x, p.y, p.z, want.x, want.y, want.z,
				"still on the roof" if p.y > 1.0 else "back in the enter room" if p.z < float(VESTIBULE_H) else "somewhere else"])

	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state

	# ── 2. the ceiling closes over the cell ──────────────────────────────
	# NOT a raycast. The ceiling is a MultiMeshInstance3D with no collider, so a
	# ray up from the arrival point finds nothing whether the hole is open or
	# shut — the null this probe returned on its first run, which is a fact about
	# the instrument and not about the museum.
	#
	# And NOT the panels' origins either. em_detail.gd:1935 has the note in blood:
	# a panel lying ACROSS the opening has its origin somewhere else, so an
	# origin test dropped nothing, left the hole roofed, and a probe testing
	# origins the same way agreed there was nothing there. EXTENT, both ends.
	#
	# The control is inside the run: the eight cells around the drop cell never
	# had a hole in them, so if the drop cell is covered as thickly as they are,
	# the hole is shut. A number that can be wrong, rather than a boolean.
	await _wait_for_ceiling(mus)
	var cov: Dictionary = _ceiling_census(mus, want)
	var here: int = int(cov.get("here", -1))
	var neigh: Array = cov.get("neighbours", [])
	var covered: int = 0
	for n_v in neigh:
		if int(n_v) > 0:
			covered += 1
	_lines.append("[probe] what stands over the arrival cell: %s" % [
		String(" | ").join(cov.get("what", PackedStringArray())) if not (cov.get("what", PackedStringArray()) as PackedStringArray).is_empty() else "nothing"])
	# THE CLAIM IS ABOUT THE ARRIVAL CELL, and nothing else. An earlier version also
	# demanded `here >= min(neighbours)`, which sounds stricter and is not a test at
	# all: the coffered ceiling leaves a 550 mm slot open in every 3 m bay, so some
	# neighbour is always 0 and the clause was satisfied by arithmetic whatever the
	# museum did. Measured both ways on this map: 1 panel with the roof off, 0 with
	# it on. That one number is the whole gate; the neighbours are context.
	_check(here > 0,
		"ceiling over the arrival cell: %d panel(s) — the drop hole is closed (%d of the 8 cells around it covered; the coffer leaves slots open by design)" % [
			here, covered],
		"nothing over the arrival cell, with %d of the 8 around it covered — the ceiling is still cut open where the visitor stands" % covered)

	# THE DECK. It stood at WALL_H + roof_rise_m, so a ray starting ABOVE the
	# ceiling and running up must now find open air. This is the claim the log
	# cannot make: a skipped branch prints, a deck built by anything else does not.
	# NINE CELLS, NOT ONE. The arrival cell is the cell the deck leaves OUT — it is
	# the hole — so a ray up from it finds open air whether or not the roof was
	# built, and the single-cell version of this check passed for the wrong reason.
	# Its neighbours are the deck itself; if any of them is occupied at roof height
	# the roof is still standing.
	var roof_y: float = WALL_H + float(lobby.get("roof_rise_m", 0.35))
	var found_at := PackedStringArray()
	for dx in [-1.0, 0.0, 1.0]:
		for dz in [-1.0, 0.0, 1.0]:
			var c: Vector3 = p + Vector3(dx, 0.0, dz)
			var above := PhysicsRayQueryParameters3D.create(
				Vector3(c.x, roof_y - 0.4, c.z), Vector3(c.x, roof_y + 2.0, c.z))
			var hr: Dictionary = space.intersect_ray(above)
			if not hr.is_empty():
				found_at.append("(%.1f, %.1f) at y%.2f" % [c.x, c.z, float(hr.get("position", Vector3.ZERO).y)])
	_check(found_at.is_empty(),
		"nothing between %.2f m and %.2f m over the arrival cell or any of its eight neighbours — the deck and its parapet are gone"
			% [roof_y - 0.4, roof_y + 2.0],
		"%d of the nine cells still carry something at roof height: %s — the roof did not come off"
			% [found_at.size(), String("; ").join(found_at)])

	# ── 3. down: floor under the feet ────────────────────────────────────
	var down := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.6, 0), p + Vector3(0, -3.0, 0))
	var hit_dn: Dictionary = space.intersect_ray(down)
	var floor_y: float = float(hit_dn.get("position", Vector3(0, -99, 0)).y) if not hit_dn.is_empty() else -99.0
	_check(not hit_dn.is_empty() and absf(floor_y - p.y) < 0.12,
		"floor at %.3f m, %.0f mm under the arrival point" % [floor_y, absf(floor_y - p.y) * 1000.0],
		"no floor under the arrival point" if hit_dn.is_empty()
			else "the floor is at %.2f m and the visitor is put at %.2f m — a %.2f m %s"
				% [floor_y, p.y, absf(floor_y - p.y), "drop" if p.y > floor_y else "burial"])

	# ── 4. and the body fits ─────────────────────────────────────────────
	# margin 0.0 deliberately: the default 0.04 m reports a body RESTING on a
	# floor as intersecting it, which has reported "stuck" for every honest
	# standing position this project has ever measured.
	var cap := CapsuleShape3D.new()
	cap.radius = _cap_r
	cap.height = _cap_h
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), p + Vector3(0, _cap_h * 0.5 + 0.06, 0))
	q.margin = 0.0
	var hits: Array = space.intersect_shape(q, 4)
	var names := PackedStringArray()
	for h in hits:
		names.append(str(h.get("collider", "?")))
	_check(hits.is_empty(),
		"the player's own capsule (r %.2f, h %.2f) stands clear at the arrival point" % [_cap_r, _cap_h],
		"the capsule is inside %d thing(s) at the arrival point: %s" % [hits.size(), String(", ").join(names)])

	# ── 5. and the HEADSET goes there, not just the walker ───────────────
	# Everything above measured the museum a desktop run builds. The request was
	# about VR, and the VR lane is one function this run never enters: _vr_drop_in
	# returns on its first line without _vr. Two things can still be checked
	# without a headset, and they are the two that can be wrong.
	#
	# First the GATE. _vr_drop_in is keyed on drop_hole, not on roof — if it had
	# been keyed on the roof, taking the roof off would have left the rig wherever
	# staging put it, which in this map is the world origin: inside the basin.
	var gate_ok: bool = float(lobby.get("drop_hole", 0.0)) > 0.5 and float(lobby.get("enabled", 0.0)) > 0.5
	_check(gate_ok,
		"the headset is still placed with the roof off: lobby enabled and drop_hole %s" % str(lobby.get("drop_hole", "<unset>")),
		"_vr_drop_in will return early (enabled=%s drop_hole=%s) and the rig stays at the world origin — which this map sinks as a basin" % [
			str(lobby.get("enabled", "<unset>")), str(lobby.get("drop_hole", "<unset>"))])

	# Then the ARITHMETIC. A room-scale visitor stands away from their own origin,
	# so putting the ORIGIN on the target leaves the eye somewhere else — which at
	# seven metres up was a miss and on the floor is standing in a wall. Feed
	# _vr_drop a rig whose eye is 1.4 m off in both axes and check where the eye
	# ends up, not where the origin does.
	var rig0 := Vector3(3.0, 0.0, -11.0)
	var eye0: Vector3 = rig0 + Vector3(1.4, 1.65, -1.4)
	var moved: Vector3 = mus.call("_vr_drop", rig0, eye0, p)
	var eye1: Vector3 = moved + (eye0 - rig0)
	_check(absf(eye1.x - p.x) < 0.001 and absf(eye1.z - p.z) < 0.001,
		"a room-scale rig standing 1.98 m off its own origin lands its EYE on (%.2f, %.2f) — not its origin" % [eye1.x, eye1.z],
		"the eye lands at (%.2f, %.2f) against an arrival point of (%.2f, %.2f) — %.2f m out" % [
			eye1.x, eye1.z, p.x, p.z, Vector2(eye1.x - p.x, eye1.z - p.z).length()])

	_finish()


## The dress is a QUEUED pass — em_detail runs after the shell is standing, so a
## census taken when the floor first appears counts an unbuilt ceiling and calls
## it a hole. Wait for the bucket itself, and say so if it never arrives.
func _wait_for_ceiling(mus: Node) -> void:
	for _i in range(2400):
		if not _ceiling_nodes(mus).is_empty():
			for _j in range(10):
				await process_frame
			return
		await process_frame
	_lines.append("[probe] no Ceiling bucket after 2400 frames — the census below counts an undressed hall")


func _ceiling_nodes(n: Node) -> Array[MultiMeshInstance3D]:
	var out: Array[MultiMeshInstance3D] = []
	if n is MultiMeshInstance3D and (n.name == "Ceiling" or n.name == "ArrisCeiling"):
		out.append(n)
	for c in n.get_children():
		out.append_array(_ceiling_nodes(c))
	return out


## How many ceiling boxes stand over each of nine cells: the arrival cell and its
## eight neighbours. Read from `em_xforms` rather than from the MultiMesh, because
## instance transforms read back as identity under the dummy renderer.
func _ceiling_census(mus: Node, world: Vector3) -> Dictionary:
	var cells: Array[Vector3] = [world]
	for dx in [-1.0, 0.0, 1.0]:
		for dz in [-1.0, 0.0, 1.0]:
			if dx != 0.0 or dz != 0.0:
				cells.append(world + Vector3(dx, 0.0, dz))
	var counts: Array[int] = []
	counts.resize(cells.size())
	counts.fill(0)
	var what := PackedStringArray()
	for mmi in _ceiling_nodes(mus):
		var xf_v: Variant = mmi.get_meta("em_xforms", [])
		if not (xf_v is Array):
			continue
		# the bucket hangs under its segment, so its transforms are segment-local
		var to_local: Transform3D = mmi.global_transform.affine_inverse()
		for i in range(cells.size()):
			var lp: Vector3 = to_local * cells[i]
			for t_v in (xf_v as Array):
				var t: Transform3D = t_v
				var sc: Vector3 = t.basis.get_scale()
				if absf(lp.x - t.origin.x) <= absf(sc.x) * 0.5 and absf(lp.z - t.origin.z) <= absf(sc.z) * 0.5:
					counts[i] += 1
					if i == 0:
						what.append("%s/%s %.1f x %.2f x %.2f at y%.2f z%.2f" % [
							str(mmi.get_parent().name), str(mmi.name),
							absf(sc.x), absf(sc.y), absf(sc.z), t.origin.y, t.origin.z])
	var neigh: Array[int] = []
	for i in range(1, counts.size()):
		neigh.append(counts[i])
	return {"here": counts[0], "neighbours": neigh, "what": what}


func _read_envelope() -> void:
	if not ResourceLoader.exists(PLAYER):
		return
	var pl: Node = (load(PLAYER) as PackedScene).instantiate()
	for cs in _shapes(pl):
		if cs.shape is CapsuleShape3D:
			_cap_r = (cs.shape as CapsuleShape3D).radius
			_cap_h = (cs.shape as CapsuleShape3D).height
			break
	_lines.append("[probe] envelope read from the player: capsule r %.2f m, h %.2f m" % [_cap_r, _cap_h])
	pl.free()


func _shapes(n: Node) -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	if n is CollisionShape3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_shapes(c))
	return out


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL",
		"" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)
