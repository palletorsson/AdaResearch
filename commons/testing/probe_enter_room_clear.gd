extends SceneTree
## CAN PALLE CLEAR A CELL IN THE ENTER ROOM?
##
## Palle, of the strips left behind by a wall that no longer exists: "remove the
## extra list that are part of an old wall ... the editing of passages is still
## something I want." The enter room had no erase: "4" built a partition, "1"
## opened a side doorway, and nothing took anything away.
##
## The negative test for the repair, both directions:
##   1. with NO ruling, a chosen vestibule cell has geometry standing on it
##   2. with a "1" ruling on that same cell, nothing stands there
##   3. and the floor SURVIVES — clearing a cell is not opening a hole
##
## It injects its own EM_CONTROL and its own overrides path, so the live session's
## files are never touched.
##
##   godot --headless --path . --xr-mode off \
##       --script res://commons/testing/probe_enter_room_clear.gd

const TRIAL_CTL := "res://ada_run/_trial_enter_clear_control.json"
const TRIAL_OVR := "res://ada_run/_trial_enter_clear_overrides.json"

## FOUND, not chosen. The first attempt named a cell by hand and the probe reported
## SKIP: nothing stood on (8, 2), so ruling it clear would have proved nothing while
## printing a pass. The unruled build is searched for a cell that actually carries
## standing geometry, and THAT is the one the ruling has to empty.
var CELL := Vector2i(0, 0)

## The PEARL is the strong key: a ruling whose pearl is empty is skipped outright
## (endless_museum.gd:6312), which is how the first run of this probe wrote a
## ruling, built a museum, and measured no change — the ruling was never read. It
## is taken from the built segment rather than typed.
var PEARL := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("CAN PALLE CLEAR A CELL IN THE ENTER ROOM?")
	CELL = await _find_occupied_cell()
	if CELL == Vector2i(-999, -999):
		print("  SKIP no enter-room cell carries standing geometry — nothing to clear")
		quit(0)
		return
	var before: Dictionary = await _build({"overrides": []})
	if PEARL == "":
		print("  SKIP the segment carries no pearl — a ruling could not key to it")
		quit(0)
		return
	var ruling := {"kind": "cell", "chapter": "", "pearl": PEARL,
		"token": "cell:" + PEARL, "from": [CELL.x, CELL.y - 4], "value": "1",
		"provenance": "hand"}
	var after: Dictionary = await _build({"overrides": [ruling]})

	var fails := 0
	print("  the cell: enter room (%d, %d)" % [CELL.x, CELL.y])
	if int(before["standing"]) <= 0:
		print("  SKIP nothing stood on that cell to begin with — the test proves nothing")
		quit(0)
		return
	print("  ok   1. unruled, %d thing(s) stand on it" % int(before["standing"]))

	if int(after["standing"]) == 0:
		print("  ok   2. ruled clear, %d stand on it" % int(after["standing"]))
	else:
		print("  FAIL 2. ruled clear and %d still stand" % int(after["standing"]))
		fails += 1

	if int(after["floor"]) > 0:
		print("  ok   3. the floor survived (%d deck box(es) under the cell)" % int(after["floor"]))
	else:
		print("  FAIL 3. the floor went with it — that is a hole, not a cleared cell")
		fails += 1

	print("  %s" % ("PASS" if fails == 0 else "%d FAILURE(S)" % fails))
	quit(1 if fails > 0 else 0)


## Which enter-room cell actually carries something standing? Searches x -3..17 over
## the four vestibule rows, skipping the side-wall columns (0 is one of them) since
## "1" already means "open a doorway" there.
func _find_occupied_cell() -> Vector2i:
	# the search must see an UNRULED museum: the last run left its trial file behind
	# and the first version of this probe read it, so the "before" build already
	# carried the ruling it was supposed to be the baseline for.
	var f0 := FileAccess.open(TRIAL_OVR, FileAccess.WRITE)
	f0.store_string(JSON.stringify({"overrides": []}))
	f0.close()
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("EM_CONTROL", TRIAL_CTL)
	inst.set("_overrides_path", TRIAL_OVR)
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	for i in range(10):
		await create_timer(0.3).timeout

	for ch in inst.get_children():
		if String(ch.name).begins_with("Seg0") and ch.has_meta("em_pearl"):
			PEARL = String(ch.get_meta("em_pearl"))
			break
	print("  the segment's pearl: '%s'" % PEARL)

	var best := Vector2i(-999, -999)
	var best_n: int = 0
	for cx in range(-3, 18):
		if cx == 0:
			continue
		for cz in range(0, 4):
			CELL = Vector2i(cx, cz)
			var o := {"standing": 0, "floor": 0}
			_count(inst, o)
			if int(o["standing"]) > best_n and int(o["floor"]) > 0:
				best_n = int(o["standing"])
				best = Vector2i(cx, cz)
	inst.queue_free()
	await create_timer(0.4).timeout
	if best_n > 0:
		print("  searched the enter room: (%d, %d) carries the most, %d piece(s)" % [best.x, best.y, best_n])
	return best


## Build a museum with these overrides and count what stands on CELL.
func _build(ovr: Dictionary) -> Dictionary:
	var f := FileAccess.open(TRIAL_OVR, FileAccess.WRITE)
	f.store_string(JSON.stringify(ovr))
	f.close()

	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("EM_CONTROL", TRIAL_CTL)
	inst.set("_overrides_path", TRIAL_OVR)
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	for i in range(10):
		await create_timer(0.3).timeout

	var out := {"standing": 0, "floor": 0}
	_count(inst, out)
	inst.queue_free()
	await create_timer(0.4).timeout
	return out


## ARCHITECTURE COLLIDERS, not meshes.
##
## Two things this probe got wrong before it got it right, both worth keeping:
## _flush_boxes merges the museum's boxes into one mesh per MATERIAL, so after the
## build there is no per-cell mesh to count at all — a mesh count sees only
## instanced props and is blind to every wall and strip the museum draws. And an
## instanced prop brings its OWN colliders (the lobby's elevator corner is 96 of
## them), which never went through _add_col and so measure nothing about this
## change. _add_col puts one unmerged shape per call on the segment's own
## StaticBody3D. That is the per-piece record, and it is the same funnel the
## refusal sits in.
func _count(n: Node, out: Dictionary) -> void:
	var cs := n as CollisionShape3D
	if cs != null and cs.shape is BoxShape3D:
		var par := cs.get_parent()
		var gpar: Node = par.get_parent() if par != null else null
		var is_arch: bool = par is StaticBody3D and gpar != null and String(gpar.name).begins_with("Seg")
		if is_arch:
			var s: Vector3 = (cs.shape as BoxShape3D).size
			var c: Vector3 = cs.global_position
			var hit: bool = abs(c.x - (CELL.x + 0.5)) < 0.5 + s.x * 0.5 and abs(c.z - (CELL.y + 0.5)) < 0.5 + s.z * 0.5
			if hit and s.x <= 3.0 and s.z <= 3.0:
				if c.y + s.y * 0.5 > 0.02:
					out["standing"] = int(out["standing"]) + 1
				else:
					out["floor"] = int(out["floor"]) + 1
	for c2 in n.get_children():
		_count(c2, out)