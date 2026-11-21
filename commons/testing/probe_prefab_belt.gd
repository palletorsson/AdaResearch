extends Node3D
## THE PREFAB BELT ON A BENCH (2026-11-21): one belt told it stands on floor 7, one off the tower, a fake hand.
## Proves, with numbers: (A) the timeline is the vending stock less the tools, in floor order; (B) the floor-7 belt
## starts with one earlier tray and then the first thing floor 7 gives; (C) an earlier tray prints its association
## line and can be taken, this floor's tray prints no line and can be taken, a later tray is a closed box with its
## floor and no pick; (D) a key steps one tray and the band stops at both ends; (E) the lever rolls the band while
## off its middle and the band rests on a whole tray when it returns; (F) a grab collects into the hand.
## Writes ada_run/prefab_belt/{bench.png, stepped.png, report.json}.
## Run: godot --path . --xr-mode off --resolution 1600x900 res://commons/testing/probe_prefab_belt.tscn

const Items = preload("res://commons/player/inventory_items.gd")
const Belt = preload("res://commons/artifacts/prefab_belt/prefab_belt.tscn")
const Vending = preload("res://commons/artifacts/vending_machine/vending_machine.gd")
const TOOLS := ["tape", "rubber", "pin", "test", "measuringstick", "plank", "plank2", "clock"]

class FakeHand extends Node:
	var got: Array = []
	func collect(id: String) -> bool: got.append(id); return true

var report := {"checks": []}
var out_dir := ""

func _ready() -> void:
	out_dir = ProjectSettings.globalize_path("res://ada_run/prefab_belt"); DirAccess.make_dir_recursive_absolute(out_dir)
	Items.collected_path = "user://probe_prefab_belt_collected.json"
	if FileAccess.file_exists(Items.collected_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(Items.collected_path))
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color("d8d2c8"); e.ambient_light_energy = .7; env.environment = e; add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 25, 0); sun.light_energy = 1.0; add_child(sun)
	var fm := MeshInstance3D.new(); var fmesh := BoxMesh.new(); fmesh.size = Vector3(12, .1, 8); fm.mesh = fmesh; fm.position.y = -.05; add_child(fm)
	var hand := FakeHand.new(); hand.add_to_group("inventory_hands"); add_child(hand)
	var belt: Node3D = Belt.instantiate(); belt.name = "Floor7"; belt.set_meta("config_floor", 7); add_child(belt)
	var cam := Camera3D.new(); cam.transform = Transform3D(Basis(), Vector3(0, 1.75, 2.5)).looking_at(Vector3(0, 1.0, 0)); cam.fov = 60; add_child(cam); cam.current = true
	await _settle(belt)

	# A - the timeline
	var st: Dictionary = belt.get_state()
	var ids: Array = st.ids
	var want: int = Items.items().filter(func(it): return bool(it.get("vending", true)) and not (str(it.get("id", "")) in TOOLS)).size()
	var floors: Array = ids.map(func(id): var f: Variant = Items.item(id).get("floor", 0); return int(f) if f != null else 0)
	var sorted := true
	for i in range(1, floors.size()): sorted = sorted and floors[i] >= floors[i - 1]
	_check("A timeline: %d items = the %d stocked non-tools, floors ascending %s (%d..%d)" % [ids.size(), want, sorted, floors[0], floors[-1]], ids.size() == want and sorted)

	# B - the start on floor 7
	var w: Array = st.window
	report["window_start"] = w
	_check("B floor 7: four trays [%s], states [%s]" % [", ".join(w.map(func(x): return str(x.id))), ", ".join(w.map(func(x): return str(x.state)))],
		w.size() == 4 and w[0].state == "earlier" and w[1].state == "here" and int(Items.item(str(w[1].id)).get("floor", 0)) == 7)

	# C - what each kind of tray shows
	var earlier: Dictionary = belt.trays[int(w[0].index)]; var here: Dictionary = belt.trays[int(w[1].index)]
	_check("C earlier tray '%s' prints %s and has a pick" % [w[0].id, str(earlier.words).replace("\n", " | ")], earlier.has("shell"))
	_check("C this floor's tray '%s' prints %s (no line) and has a pick" % [w[1].id, str(here.words).replace("\n", " | ")], here.has("shell") and not str(here.words).contains("association("))
	var with_line := -1; var later := -1
	for i in ids.size():
		var it := Items.item(ids[i])
		if with_line < 0 and floors[i] < 7 and Vending.tape_line(it) != "": with_line = i
		if later < 0 and floors[i] > 7: later = i
	belt.jump(with_line); await _settle(belt)
	var t: Dictionary = belt.trays[with_line]
	_check("C an earlier associated thing '%s' prints %s" % [ids[with_line], str(t.words).replace("\n", " | ")], str(t.words).contains("association(") and t.has("shell"))
	await _shot("earlier.png")
	var wide: Transform3D = cam.transform
	cam.transform = Transform3D(Basis(), Vector3(-.25, 1.6, 1.05)).looking_at(Vector3(-.25, .98, .1))
	await _shot("earlier_close.png")
	cam.transform = wide
	belt.jump(later); await _settle(belt)
	t = belt.trays[later]
	_check("C a later thing '%s' prints '%s', a closed box, no pick, no miniature" % [ids[later], str(t.words)],
		str(t.words) == "FLOOR %d" % floors[later] and not t.has("shell") and t.node.get_node_or_null("ClosedBox") != null and t.node.get_node_or_null("Turn") == null)
	await _shot("later.png")

	# D - the keys
	belt.jump(int(w[0].index)); await _settle(belt)
	await _shot("bench.png")
	var p0: float = belt.pos
	belt.get_node("Machine/StepLater").pressed.emit()
	await get_tree().create_timer(.2).timeout
	var mid: float = belt.pos
	await get_tree().create_timer(.8).timeout
	_check("D LATER key: %.2f -> %.2f (mid-roll %.2f)" % [p0, belt.pos, mid], is_equal_approx(belt.pos, p0 + 1.0) and mid > p0 and mid < p0 + 1.0)
	await _settle(belt)
	await _shot("stepped.png")
	belt.get_node("Machine/StepEarlier").pressed.emit(); await get_tree().create_timer(1.0).timeout
	_check("D EARLIER key back to %.2f" % belt.pos, is_equal_approx(belt.pos, p0))
	belt.jump(0); belt.step(-1); await get_tree().create_timer(.3).timeout
	var low: float = belt.pos
	belt.jump(9999); belt.step(1); await get_tree().create_timer(.3).timeout
	_check("D the band stops at both ends: %.2f and %.2f (last start %d)" % [low, belt.pos, belt.last_start()], low == 0.0 and belt.pos == float(belt.last_start()))

	# E - the lever
	belt.jump(3); await get_tree().create_timer(.2).timeout
	belt.lever.set_angle_degrees(-30)
	await get_tree().create_timer(1.0).timeout
	var rolled: float = belt.pos
	var up_is_later: bool = rolled > 3.0
	belt.lever.set_angle_degrees(0)
	await get_tree().create_timer(1.0).timeout
	_check("E lever -30 deg (handle up) for 1 s: 3.00 -> %.2f, rolling; at 0 the band rests on %.2f" % [rolled, belt.pos], absf(rolled - 3.0) > .8 and is_equal_approx(belt.pos, roundf(belt.pos)) and not belt._rolling)
	var tip: Node3D = belt.lever.hinge
	belt.lever.set_angle_degrees(30); await get_tree().process_frame
	var handle: Node3D = belt.lever.find_child("HandleMesh", true, false)
	var up_y: float = handle.global_position.y if handle != null else 0.0
	belt.lever.set_angle_degrees(-30); await get_tree().process_frame
	var down_y: float = handle.global_position.y if handle != null else 0.0
	belt.lever.set_angle_degrees(0)
	report["lever"] = {"plus_is_later": up_is_later, "handle_y_at_plus": up_y, "handle_y_at_minus": down_y, "hinge": str(tip.name)}
	_check("E -30 deg lifts the handle (%.3f against %.3f at +30) and rolls later (%s): the print 'UP: LATER' is true" % [down_y, up_y, up_is_later], up_is_later and down_y > up_y)

	# G - the things stay on their trays while the band moves (Palle's picture, 2026-11-21): roll with the lever
	# there and back, step twice, then measure every made thing against the middle of its tray
	belt.jump(22); await _settle(belt)
	var rest: Dictionary = belt.seat_errors()
	belt.lever.set_angle_degrees(-30); await get_tree().create_timer(1.2).timeout
	var rolling: Dictionary = belt.seat_errors()
	belt.lever.set_angle_degrees(30); await get_tree().create_timer(1.2).timeout
	belt.lever.set_angle_degrees(0); await get_tree().create_timer(.8).timeout
	belt.step(1); await get_tree().create_timer(.8).timeout
	belt.step(-1); await get_tree().create_timer(.8).timeout
	await _settle(belt)
	var after: Dictionary = belt.seat_errors()
	var worst := func(d: Dictionary) -> float: return (d.values().max() if not d.is_empty() else 0.0)
	report["seat"] = {"rest": rest, "rolling": rolling, "after": after}
	_check("G off the middle of the tray: %.3f m at rest, %.3f m while rolling, %.3f m after rolling and stepping (%d things)" % [worst.call(rest), worst.call(rolling), worst.call(after), after.size()],
		worst.call(rest) < .01 and worst.call(after) < .01 and after.size() >= 4)
	await _shot("after_rolling.png")

	# F - a grab
	belt.jump(int(w[0].index)); await _settle(belt)
	var pick: RigidBody3D = belt.trays[int(w[1].index)].shell
	pick.picked_up.emit(pick)
	await get_tree().create_timer(.3).timeout
	_check("F grabbing '%s' collects it (hand %s, file %s)" % [w[1].id, str(hand.got), Items.is_collected(str(w[1].id))], hand.got == [str(w[1].id)] and Items.is_collected(str(w[1].id)))

	# an off-tower belt: every tray earlier
	var free_belt: Node3D = Belt.instantiate(); free_belt.name = "OffTower"; free_belt.position = Vector3(0, 0, -2.2); add_child(free_belt)
	await _settle(free_belt)
	var fw: Array = free_belt.get_state().window
	_check("off the tower: starts at 0, all earlier [%s]" % ", ".join(fw.map(func(x): return str(x.id))), free_belt.pos == 0.0 and fw.all(func(x): return x.state == "earlier"))

	var passed: int = report.checks.filter(func(c): return c.ok).size()
	report["passed"] = passed; report["total"] = report.checks.size()
	var f := FileAccess.open(out_dir + "/report.json", FileAccess.WRITE); f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[probe_prefab_belt] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _settle(belt: Node3D) -> void:
	for i in 600:
		var w: Array = belt.window()
		if w.size() > 0 and w.all(func(x): return bool(x.made)): break
		await get_tree().process_frame
	for i in 30: await get_tree().process_frame

func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/" + file)

func _check(what: String, ok: bool) -> void:
	report.checks.append({"what": what, "ok": ok})
	print(("  ok   " if ok else "  FAIL ") + what)
