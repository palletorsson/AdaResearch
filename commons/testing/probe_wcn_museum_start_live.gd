extends Node
## LIVE PROBE — does a chapter start put the desktop visitor IN the first hall,
## free to walk? (2026-09-30, Palle: "the desktop app is not working after the
## last edits")
##
## The portal stream's authored-entry rule (Codex, 2026-09-28) returned an
## invalid entry for any first hall whose s/sp was blocked, skipped the entrance
## landing, and failed adopt_current: "The entrance has no clear supported
## landing." 15 of 25 chapter starts held the visitor in the loading cell at
## x = -1000 with the stream busy for good. Every log line looked like a museum
## that had built its hall ("first hall complete"), so nothing but the visitor's
## own position said it was broken.
##
## This probe boots the museum at a chapter the way --em-chapter does, waits for
## the portal stream to go idle, and asks five things:
##   1. the stream is not busy (movement is not locked),
##   2. the walker stands inside the first hall's span, not in the loading cell,
##   3. it stands on a floor, after any drop has finished,
##   4. the entrance a fall returns to is a supported floor (VR fall recovery
##      only acts on one),
##   5. a real W key press (Input.parse_input_event) moves it.
##
## Run under project startup (autoloads present), through the live launcher:
##   godot --path . --xr-mode off --headless res://commons/testing/probe_live.tscn -- \
##     --probe=museum_start --chapter=randomness
## Report: user://probe_museum_start_<chapter>.json, and a verdict line in the log.

var checks := 0
var failures: Array = []


func _ready() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
	print("[museum-start] ", "PASS " if ok else "FAIL ", message)


func _arg(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--" + key + "="):
			return s.get_slice("=", 1)
	return fallback


func _key_w(pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_W
	ev.physical_keycode = KEY_W
	ev.pressed = pressed
	Input.parse_input_event(ev)


func run() -> void:
	var chapter := _arg("chapter", "primitives")
	var ctl := "user://probe_museum_start_control_%s.json" % chapter
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": chapter, "dollhouse": 0}))
	f.close()
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL", ctl)
	em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", ctl + ".unused-hand")
	em.set("start_chapter", chapter)
	em.set("start_map", "")
	get_tree().root.add_child(em)
	get_tree().current_scene = em

	var report := {"chapter": chapter}
	var t0 := Time.get_ticks_msec()
	var stream: Node = null
	var idle_at := -1
	var settled := 0
	var player: CharacterBody3D = null
	var last_y := 1.0e9
	# up to 90 s: the hall builds in 4-7 s headless, and a drop-in lands in a few s
	while Time.get_ticks_msec() - t0 < 90000:
		await get_tree().physics_frame
		if stream == null:
			stream = em.get("_portal_stream")
		if player == null:
			player = em.get("_player")
		if stream == null or player == null:
			continue
		if bool(stream.get("busy")):
			idle_at = -1
			continue
		if idle_at < 0:
			idle_at = Time.get_ticks_msec()
		# settled = on the floor and not moving vertically for 30 physics frames
		var y := player.global_position.y
		settled = settled + 1 if player.is_on_floor() and absf(y - last_y) < 0.002 else 0
		last_y = y
		if settled >= 30:
			break
	report["boot_ms"] = Time.get_ticks_msec() - t0
	check(stream != null, "the museum made a portal stream")
	check(player != null, "the museum made a desktop walker")
	if stream == null or player == null:
		_finish(em, chapter, report)
		return
	var segs: Array = em.get("_segments")
	var seg: Dictionary = segs[0] if not segs.is_empty() and segs[0] is Dictionary else {}
	report["map"] = String(seg.get("map", ""))
	report["phase"] = String(stream.get("phase"))
	report["busy"] = bool(stream.get("busy"))
	var p := player.global_position
	report["at"] = [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)]
	report["on_floor"] = player.is_on_floor()
	var z0 := float(seg.get("z0", 0.0))
	var z1 := float(seg.get("z1", 0.0))
	var w := float(seg.get("w", 0.0))
	report["hall_span"] = {"x": [0.0, w], "z": [z0, z1]}
	check(not report["busy"], "%s: the portal stream is idle (phase '%s'), so movement is not locked" % [chapter, report["phase"]])
	check(p.x > -1.0 and p.x < w + 1.0 and p.z > z0 - 1.0 and p.z < z1 + 1.0,
		"%s: the walker is inside %s's span, at %s, not in the loading cell" % [chapter, report["map"], str(report["at"])])
	check(report["on_floor"] and p.y > -1.0, "%s: the walker stands on a floor (y %.2f)" % [chapter, p.y])
	# VR fall recovery returns the body to _arrival only while _supported(_arrival)
	# holds, so an entrance point in the air switches recovery off for the hall.
	var arrival: Vector3 = stream.get("_arrival")
	report["arrival"] = [snappedf(arrival.x, 0.01), snappedf(arrival.y, 0.01), snappedf(arrival.z, 0.01)]
	var supported := bool(stream.call("_supported", arrival))
	if not supported:
		report["arrival_blockers"] = _blockers(player, arrival)
		print("[museum-start] %s: what fails _supported at the entrance: %s" % [chapter, str(report["arrival_blockers"])])
	check(supported, "%s: the entrance a fall returns to, %s, is a supported floor" % [chapter, str(report["arrival"])])

	# a real W press, one second: the walker should cover ground
	var before := player.global_position
	_key_w(true)
	for i in range(60):
		await get_tree().physics_frame
	_key_w(false)
	await get_tree().physics_frame
	var moved := Vector2(player.global_position.x - before.x, player.global_position.z - before.z).length()
	report["walk_m"] = snappedf(moved, 0.01)
	check(moved > 0.3, "%s: a W press moves the walker (%.2f m in 1 s)" % [chapter, moved])
	_finish(em, chapter, report)


## The two halves of em_portal_stream._supported, named: what the floor ray hits
## (it must be a StaticBody3D facing up) and what overlaps the body capsule.
func _blockers(player: Node3D, p: Vector3) -> Dictionary:
	var space := player.get_world_3d().direct_space_state
	var ray := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.15, 0), p - Vector3(0, 0.2, 0)))
	var floor_hit := "nothing" if ray.is_empty() else "%s (%s) normal.y %.2f" % [
		(ray["collider"] as Node).name, (ray["collider"] as Node).get_class(), (ray["normal"] as Vector3).y]
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = capsule
	q.transform.origin = p + Vector3(0, 0.95, 0)
	q.exclude = [player.get_rid()]
	var overlaps: Array = []
	for hit in space.intersect_shape(q, 8):
		var n: Node = hit.get("collider")
		overlaps.append("%s (%s)" % [n.get_path(), n.get_class()])
	return {"floor_ray": floor_hit, "capsule_overlaps": overlaps}


func _finish(em: Node, chapter: String, report: Dictionary) -> void:
	report["checks"] = checks
	report["failures"] = failures
	var out := "user://probe_museum_start_%s.json" % chapter
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	f.close()
	print("[museum-start] %s %s: %d checks, %d failed -> %s" % [
		"OK  " if failures.is_empty() else "FAIL", chapter, checks, failures.size(), ProjectSettings.globalize_path(out)])
	if is_instance_valid(em):
		em.queue_free()
	for i in range(10):
		await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
