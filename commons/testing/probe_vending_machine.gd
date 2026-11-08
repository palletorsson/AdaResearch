extends Node3D
## THE VENDING MACHINES ON A BENCH (2026-11-06): a prefabs machine and a tools machine on a floor, no Void, a fake hand in
## the inventory_hands group. Proves, with numbers: (A) the prefabs machine shows one slot per non-tool item and the
## tools machine the eight tools, the tape in all nine of its configurations; (B) every unlocked slot has a pick shell,
## and the miniatures have meshes in their own colours (no override); (C) the beach ball's tape reads its association
## line and the masking tape's its configuration; (D) grabbing the beach ball's slot collects it (the fake hand, the
## collected file) and the shell is back on its shelf a frame later; grabbing the masking tape's slot sets the hand's
## tape knob before collecting; (E) the glass has no collider and the cabinet's one collider leaves the front free.
## Writes ada_run/vending/{bench.png, report.json}.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_vending_machine.tscn

const Items = preload("res://commons/player/inventory_items.gd")
const Machine = preload("res://commons/artifacts/vending_machine/vending_machine.tscn")

class FakeHand extends Node:
	var got: Array = []
	var knobs: Dictionary = {}
	func collect(id: String) -> bool: got.append(id); return true
	func set_knob_for(id: String, key: String, value: Variant) -> void: knobs["%s.%s" % [id, key]] = value

var report := {"checks": [], "slots": {}}

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/vending"); DirAccess.make_dir_recursive_absolute(out_dir)
	Items.collected_path = "user://probe_vending_collected.json"
	if FileAccess.file_exists(Items.collected_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(Items.collected_path))
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color("d8d2c8"); e.ambient_light_energy = .7; env.environment = e; add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 25, 0); sun.light_energy = 1.0; add_child(sun)
	var floor_body := StaticBody3D.new(); var fs := CollisionShape3D.new(); var fb := BoxShape3D.new(); fb.size = Vector3(10, .1, 10); fs.shape = fb; floor_body.add_child(fs)
	var fm := MeshInstance3D.new(); var fmesh := BoxMesh.new(); fmesh.size = Vector3(10, .1, 10); fm.mesh = fmesh; floor_body.add_child(fm); floor_body.position.y = -.05; add_child(floor_body)
	var hand := FakeHand.new(); hand.name = "FakeHand"; hand.add_to_group("inventory_hands"); add_child(hand)
	var prefabs: Node3D = Machine.instantiate(); prefabs.name = "Prefabs"; prefabs.set_meta("config_kind", "prefabs"); add_child(prefabs); prefabs.position = Vector3(-1.05, 0, 0)
	var tools: Node3D = Machine.instantiate(); tools.name = "Tools"; tools.set_meta("config_kind", "tools"); add_child(tools); tools.position = Vector3(1.0, 0, 0)
	var cam := Camera3D.new(); cam.transform = Transform3D(Basis(), Vector3(0, 1.45, 3.1)).looking_at(Vector3(0, 1.0, 0)); cam.fov = 62; add_child(cam); cam.current = true
	# the machines stock a few slots per frame once their scenes are in (2026-11-07): wait for both, then the seating
	for i in 600:
		if bool(prefabs.get("stocked")) and bool(tools.get("stocked")): break
		await get_tree().process_frame
	for i in 25: await get_tree().process_frame
	# A — the stock
	var p_slots := prefabs.get_children().filter(func(c): return str(c.name).begins_with("Slot_"))
	var t_slots := tools.get_children().filter(func(c): return str(c.name).begins_with("Slot_"))
	var tapes := t_slots.filter(func(c): return str(c.name).begins_with("Slot_tape_"))
	var all_items: int = Items.items().filter(func(it): return bool(it.get("vending", true))).size()   # "vending": false is never stocked (2026-11-08)
	_check("A prefabs machine: %d slots = %d items less the %d tools; tools machine: %d slots, %d of them tapes" % [p_slots.size(), all_items, 8, t_slots.size(), tapes.size()], p_slots.size() == all_items - 8 and t_slots.size() == 7 + 9 and tapes.size() == 9)
	var t_ids: Array = t_slots.map(func(c): return str(c.name).trim_prefix("Slot_"))
	var p_ids: Array = p_slots.map(func(c): return str(c.name).trim_prefix("Slot_"))
	# 2026-11-08 ("vending": false): the red and blue points of Point One are on no shelf; the beach ball stands in below
	_check("the rubber ball and the marble are on no shelf (%s)" % str(p_ids.filter(func(i): return i in ["rubberball", "marble"])), not ("rubberball" in p_ids) and not ("marble" in p_ids))
	_check("the tools machine holds the measuring stick, both planks, the tapes, the rubber, the pin, the weight and the clock (%s)" % [", ".join(t_ids)], "measuringstick" in t_ids and "plank2" in t_ids and "tape_1" in t_ids and not ("beachball" in t_ids))
	# B — shells and miniatures, in their own colours
	var shells := 0; var with_mesh := 0; var without: Array = []; var unlocked := 0; var overridden := 0
	for m in [prefabs, tools]:
		for s in m.get_children():
			if not str(s.name).begins_with("Slot_"): continue
			var key := str(s.name).trim_prefix("Slot_")
			var locked: bool = not m.slots.has(key)
			if not locked: unlocked += 1
			var shell: Node = s.get_node_or_null("Pick")
			if shell != null and shell.has_signal("picked_up"): shells += 1
			var meshes: Array = s.get_node("Turn").find_children("*", "MeshInstance3D", true, false).filter(func(x): return x.mesh != null and (x as Node3D).is_visible_in_tree())
			report.slots[key] = {"machine": m.name, "locked": locked, "shell": shell != null, "meshes": meshes.size()}
			if meshes.size() > 0: with_mesh += 1
			else: without.append(key)
			if not locked and meshes.any(func(x): return x.material_override != null and (x.material_override as StandardMaterial3D) != null and (x.material_override as StandardMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and (x.material_override as StandardMaterial3D).albedo_color.a < .9): overridden += 1
	var total: int = p_slots.size() + t_slots.size()
	_check("B every unlocked slot has a pick shell (%d shells / %d unlocked)" % [shells, unlocked], shells == unlocked and unlocked > 0)
	_check("B the miniatures have meshes (%d of %d; none: %s)" % [with_mesh, total, ", ".join(without)], with_mesh >= total * 0.8)
	_check("B unlocked miniatures keep their own colours (%d carry a shade)" % overridden, overridden == 0)
	# C — the tape lines
	var ball: Node3D = prefabs.get_node_or_null("Slot_beachball")
	var said: String = ball.get_node("Print").text if ball != null and ball.has_node("Print") else ""
	_check("C the beach ball's tape reads its association (\"%s\")" % said.replace("\n", " / "), said.contains("beach_ball = association(config(sphere))"))
	var masking: Node3D = tools.get_node_or_null("Slot_tape_7")
	var said_m: String = masking.get_node("Print").text if masking != null and masking.has_node("Print") else ""
	var hazard: Node3D = tools.get_node_or_null("Slot_tape_2")
	var said_h: String = hazard.get_node("Print").text if hazard != null and hazard.has_node("Print") else ""
	_check("C the tapes' labels name their configuration (\"%s\"; \"%s\")" % [said_m.replace("\n", " / "), said_h.replace("\n", " / ")], said_m.contains("masking") and said_h.contains("printed (words), hazard"))
	# D — the grab
	var shell: RigidBody3D = ball.get_node_or_null("Pick") if ball != null else null
	var home: Transform3D = shell.global_transform if shell != null else Transform3D()
	if shell != null:
		shell.global_position += Vector3(0, .3, .4)   # a hand took it somewhere
		shell.picked_up.emit(shell)
	for i in 4: await get_tree().physics_frame
	_check("D grabbing the beach ball's slot collects it: the hand got %s, the collected file says %s" % [str(hand.got), str(Items.is_collected("beachball"))], hand.got == ["beachball"] and Items.is_collected("beachball"))
	var back: float = shell.global_position.distance_to(home.origin) if shell != null else INF
	_check("D the shell is back on its shelf (%.3f m from home)" % back, back < .001)
	var m_shell: RigidBody3D = masking.get_node_or_null("Pick") if masking != null else null
	if m_shell != null: m_shell.picked_up.emit(m_shell)
	for i in 4: await get_tree().physics_frame
	_check("D grabbing the masking tape's slot sets the hand's tape knob (%s) and collects the tape (%s)" % [str(hand.knobs), str(hand.got)], hand.knobs.get("tape.kind") == "masking" and hand.got == ["beachball", "tape"])
	# E — the glass and the collider
	var pane: Node = prefabs.get_node_or_null("Cabinet/Glass")
	var pane_free: bool = pane != null and pane.find_children("*", "CollisionShape3D", true, false).is_empty()
	var colliders: Array = prefabs.get_node("Cabinet").find_children("*", "CollisionShape3D", false, false)
	var depth_ok: bool = colliders.size() == 1 and (colliders[0].shape as BoxShape3D).size.z <= 0.62 - 0.2
	_check("E the glass has no collider and the cabinet's one collider leaves the front %.2f m free" % [0.62 - (colliders[0].shape as BoxShape3D).size.z if colliders.size() == 1 else 0.0], pane_free and depth_ok)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("bench.png"))
	var passed: int = report.checks.filter(func(c): return c.ok).size()
	report["passed"] = passed == report.checks.size()
	FileAccess.open("res://ada_run/vending/report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("[probe_vending_machine] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if report.passed else 1)

func _check(what: String, ok: bool) -> void:
	report.checks.append({"what": what, "ok": ok})
	print("[probe_vending_machine] %s  %s" % ["ok  " if ok else "FAIL", what])
