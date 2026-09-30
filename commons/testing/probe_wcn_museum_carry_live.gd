extends Node
## LIVE PROBE — can the museum's own desktop walker pick up and carry the pickables
## in a hall? (2026-09-30, Palle: "can you make it possible to move pick up
## pickable objects on the desktop?")
##
## The museum walker has carried a desktop hand since 427fc48b6 (2026-08-14):
## em_desktop_pointer.gd, which is DesktopInteractionPointer mounted on the walker —
## right mouse button grabs a body on GRAB_MASK under the crosshair, the body floats
## in front of the view, the wheel sets the distance, right mouse button again puts
## it down. Built only when the museum is not in VR, so a headset never runs it.
##
## This probe asks whether it works, body by body, in the real museum: it opens the
## museum at a hall, finds every RigidBody3D under that hall on the grab layers,
## stands the WALKER (not a test rig) on a walk cell a few metres from each, aims the
## walker's own view at it, and sends a real right-button press through
## Input.parse_input_event. Then it turns the view 30 degrees and measures whether
## the body followed, and presses again to put it down. Nothing here calls the
## pointer's grab directly or emits an artifact's signal.
##
## Run under project startup (autoloads present), through the live launcher:
##   godot --path . --xr-mode off --headless res://commons/testing/probe_live.tscn -- \
##     --probe=museum_carry --chapter=primitives --hall=Point_Lines --max=8
## Report: user://probe_museum_carry_<hall>.json, and one line per body in the log.

const GRAB_MASK := 393220
const EYE_FALLBACK := 1.65

var checks := 0
var failures: Array = []
var rows: Array = []


func _ready() -> void:
	# the launcher adds this probe while root is still setting up its children;
	# adding the museum from here would fail, so start one frame later
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
	print("[museum-carry] ", "PASS " if ok else "FAIL ", message)


func _arg(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--" + key + "="):
			return s.get_slice("=", 1)
	return fallback


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _collect(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is RigidBody3D and ((c as CollisionObject3D).collision_layer & GRAB_MASK) != 0:
			out.append(c)
		_collect(c, out)


## The artifact a body belongs to: the child of the hall segment it hangs under.
func _owner_root(seg: Node, b: Node) -> Node:
	var n: Node = b
	while n != null and n.get_parent() != null and n.get_parent() != seg:
		n = n.get_parent()
	return n if n != null else b


func _aim(em: Node, player: Node3D, cam: Camera3D, target: Vector3, yaw_extra: float = 0.0) -> void:
	var eye: Vector3 = cam.global_position
	var d: Vector3 = target - eye
	var yaw: float = atan2(-d.x, -d.z) + yaw_extra
	var pitch: float = atan2(d.y, Vector2(d.x, d.z).length()) if yaw_extra == 0.0 else float(em.get("_pitch"))
	em.set("_yaw", yaw)
	em.set("_pitch", pitch)
	player.rotation = Vector3(0.0, yaw, 0.0)
	cam.rotation = Vector3(pitch, 0.0, 0.0)
	var feel: Variant = em.get("_feel")
	if feel is Object and is_instance_valid(feel) and (feel as Object).has_method("resync_view"):
		(feel as Object).call("resync_view", yaw, pitch)


func _rmb() -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_RIGHT
		ev.pressed = pressed
		ev.position = get_viewport().get_visible_rect().size * 0.5
		Input.parse_input_event(ev)
		await get_tree().process_frame


## A walk cell 1.2..2.8 m from the body, from which a ray at eye height reaches it
## first. The walk map is the museum's own: _walk_cells keys are world cells whose
## centre is (x + 0.5, z + 0.5), _walk_h their floor height.
func _stand_for(em: Node, player: Node3D, b: Node3D, eye_h: float) -> Variant:
	var cells: Dictionary = em.get("_walk_cells")
	var heights: Dictionary = em.get("_walk_h")
	var space := player.get_world_3d().direct_space_state
	var bp: Vector3 = b.global_position
	var best: Variant = null
	var best_d: float = 1e9
	for k in cells:
		var c: Vector2i = k
		var cp := Vector3(float(c.x) + 0.5, float(heights.get(c, 0.0)), float(c.y) + 0.5)
		var dh: float = Vector2(cp.x - bp.x, cp.z - bp.z).length()
		if dh < 1.2 or dh > 2.8:
			continue
		var eye := cp + Vector3(0, eye_h, 0)
		var q := PhysicsRayQueryParameters3D.create(eye, bp)
		q.exclude = [player.get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var col: Node = hit.get("collider")
		if col != b and not b.is_ancestor_of(col) and not (col is Node and (col as Node).is_ancestor_of(b)):
			continue
		var score: float = absf(dh - 1.8)
		if score < best_d:
			best_d = score
			best = cp
	return best


func run() -> void:
	var chapter := _arg("chapter", "primitives")
	var hall := _arg("hall", "Point_Lines")
	var max_n := int(_arg("max", "8"))
	var ctl := "user://probe_museum_carry_control.json"
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": chapter, "dollhouse": 0}))
	f.close()
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL", ctl)
	em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", ctl + ".unused-hand")
	em.set("start_chapter", chapter)
	em.set("start_map", hall)
	get_tree().root.add_child(em)
	get_tree().current_scene = em

	# the hall, and its bodies once the deferred stamps have drained
	var seg: Node3D = null
	var bodies: Array = []
	var stable := 0
	var last_n := -1
	for fr in range(2400):
		await get_tree().process_frame
		if seg == null:
			var segs: Variant = em.get("_segments")
			if segs is Array:
				for s_v in (segs as Array):
					if s_v is Dictionary and String((s_v as Dictionary).get("map", "")) == hall \
							and is_instance_valid((s_v as Dictionary).get("node")):
						seg = (s_v as Dictionary)["node"]
		if seg != null and fr % 30 == 0:
			bodies = []
			_collect(seg, bodies)
			stable = stable + 1 if bodies.size() == last_n else 0
			last_n = bodies.size()
			if stable >= 4 and fr > 300:
				break
	check(seg != null, "the museum built %s" % hall)
	var player: CharacterBody3D = em.get("_player")
	var cam: Camera3D = em.get("_cam")
	var hand: Node = player.get_node_or_null("DesktopHand") if player != null else null
	check(hand != null and hand.has_method("is_holding"), "the walker carries the desktop hand")
	if seg == null or hand == null or cam == null:
		_finish(em, hall)
		return
	print("[museum-carry] %s: %d bodies on the grab layers" % [hall, bodies.size()])

	var per_root: Dictionary = {}
	var tried := 0
	for b_v in bodies:
		if tried >= max_n:
			break
		var b: RigidBody3D = b_v
		if not is_instance_valid(b):
			continue
		var root: Node = _owner_root(seg, b)
		var rk := str(root.name)
		if int(per_root.get(rk, 0)) >= 2:
			continue
		per_root[rk] = int(per_root.get(rk, 0)) + 1
		tried += 1
		var row := {"body": str(b.name), "artifact": rk, "class": b.get_class(),
			"script": str(b.get_script().resource_path) if b.get_script() != null else "",
			"pickable": b.has_method("pick_up"), "frozen_before": b.freeze}
		var eye_h: float = maxf(0.5, cam.global_position.y - player.global_position.y)
		if eye_h < 0.5:
			eye_h = EYE_FALLBACK
		var stand: Variant = _stand_for(em, player, b, eye_h)
		if stand == null:
			row["result"] = "no walk cell 1.2-2.8 m away can see it"
			rows.append(row)
			print("[museum-carry] SKIP %s / %s: %s" % [rk, b.name, row["result"]])
			continue
		player.global_position = (stand as Vector3) + Vector3(0, 0.05, 0)
		player.velocity = Vector3.ZERO
		em.set("_last_ground", player.global_position)
		await _frames(12)
		_aim(em, player, cam, b.global_position)
		await _frames(6)
		_aim(em, player, cam, b.global_position)
		await get_tree().process_frame
		var seen: Variant = hand.call("_find_grabbable")
		row["ray_finds"] = str((seen as Node).name) if seen is Node else ""
		row["ray_finds_it"] = seen == b
		var p0: Vector3 = b.global_position
		await _rmb()
		await _frames(3)
		row["held"] = bool(hand.call("is_holding"))
		var held_node: Variant = hand.get("_held")
		row["held_is_it"] = held_node == b
		if row["held"]:
			_aim(em, player, cam, b.global_position, 0.52)
			await _frames(30)
			var expected: Vector3 = cam.global_position + (-cam.global_basis.z) * float(hand.get("_hold_distance"))
			var hn: Node3D = held_node as Node3D
			row["moved_m"] = snappedf(p0.distance_to(hn.global_position), 0.01)
			row["off_the_hold_point_m"] = snappedf(hn.global_position.distance_to(expected), 0.01)
			await _rmb()
			await _frames(3)
			row["dropped"] = not bool(hand.call("is_holding"))
		var ok: bool = bool(row.get("held_is_it", false)) and float(row.get("moved_m", 0.0)) > 0.3 \
			and float(row.get("off_the_hold_point_m", 99.0)) < 0.35 and bool(row.get("dropped", false))
		row["result"] = "carried" if ok else ("held but not following the view" if row["held"] else "not picked up")
		rows.append(row)
		print("[museum-carry] %s %s / %s (%s): ray %s, held %s, moved %s m, off %s m, dropped %s" % [
			"OK  " if ok else "FAIL", rk, b.name, row["script"].get_file(), row["ray_finds"], row["held"],
			row.get("moved_m", "-"), row.get("off_the_hold_point_m", "-"), row.get("dropped", "-")])
	var carried := rows.filter(func(r): return r["result"] == "carried").size()
	check(tried > 0, "%d bodies tried" % tried)
	print("[museum-carry] %s: %d of %d tried were carried; %d skipped" % [hall, carried, tried,
		rows.filter(func(r): return String(r["result"]).begins_with("no walk")).size()])
	_finish(em, hall)


func _finish(em: Node, hall: String) -> void:
	var out := "user://probe_museum_carry_%s.json" % hall
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"hall": hall, "checks": checks, "failures": failures, "rows": rows}, "\t"))
	f.close()
	print("[museum-carry] report -> %s" % ProjectSettings.globalize_path(out))
	if is_instance_valid(em):
		em.queue_free()
	for i in range(10):
		await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
