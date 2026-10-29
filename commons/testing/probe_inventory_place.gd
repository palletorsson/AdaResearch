extends Node3D
## The inventory's PLACE hand on a bench: a floor and a wall, an InventoryHand holding the clock. Proves, with
## numbers, that (A) a clock let go with its back near the wall turns to face out of it and freezes there at
## 60 cm; (B) a carrier that may stand, let go above the floor, stands on it; (C) one let go in the air is a
## body and falls; (D) the web page's hand.json (user:// copy) changes the item's knobs on the held clock
## within 2.5 s, and the copy is removed again; (E) grip takes the last one back; (F) the tape item is held as
## the roll itself. It also loads the bracelet script and the panel scene (the compile check a --script probe
## cannot do for XR Tools pickables) and fills the ITEMS tab. Writes ada_run/inventory/{place.png, report.json}.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_inventory_place.tscn

const InventoryHandLib = preload("res://commons/player/inventory_hand.gd")

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/inventory");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-35, 25, 0);sun.light_energy = 1.1;add_child(sun)
	_slab("Floor", Vector3(8, .1, 8), Vector3(0, -.05, 0), Color("8f8a84"))
	_slab("Wall", Vector3(4, 3, .1), Vector3(0, 1.5, -2.05), Color("c9c2b6"))   # its room face at z = -2, looking +Z
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(.9, 1.5, 1.4)).looking_at(Vector3(.1, 1.3, -2));cam.fov = 55;add_child(cam);cam.current = true
	var hand: Node = InventoryHandLib.new();hand.name = "InventoryHand";add_child(hand)
	var report := {"checks": [], "items": []}
	for it in hand.available():report.items.append({"id": it.id, "unlocked": it.unlocked, "coming": it.coming, "knobs": (it.knobs as Array).size()})
	for i in 3:
		await get_tree().physics_frame
	# A — the wall
	hand.set_current("clock")
	var a: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(0, 1.5, -1.78)))
	await get_tree().physics_frame
	var how_a: String = a.settle() if a else "none"
	var ext: Vector3 = a.extent.size if a else Vector3.ZERO
	_check(report, "A wall: settled on the wall, facing out, frozen", a != null and how_a == "wall" and a.freeze and a.global_transform.basis.z.dot(Vector3.FORWARD * -1) > .99 and absf(a.global_position.z - (-2 + (ext.z / 2.0 - a.extent.get_center().z) + .002)) < .01, {"how": how_a, "z": a.global_position.z if a else null, "face": _v(a.global_transform.basis.z) if a else null})
	_check(report, "A size: the counter is ~60 cm across (the item's scale 0.48 on a 1.24 m console)", a != null and ext.x > .58 and ext.x < .68, {"extent": _v(ext)})
	# B — the floor (a carrier allowed to stand)
	var b: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(1.2, .45, -.6)))
	if b:b.mount = "any"
	await get_tree().physics_frame
	var how_b: String = b.settle() if b else "none"
	_check(report, "B floor: a standing item let go above the floor stands on it, frozen", b != null and how_b == "floor" and b.freeze and absf(b.global_position.y - (b.extent.size.y / 2.0 - b.extent.get_center().y) - .002) < .01, {"how": how_b, "y": b.global_position.y if b else null})
	# C — the air
	var c: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(-1.4, 1.6, -.3)))
	await get_tree().physics_frame
	var how_c: String = c.settle() if c else "none"
	var y0: float = c.global_position.y if c else 0.0
	for i in 30:
		await get_tree().physics_frame
	_check(report, "C air: let go in the air it is a body and falls", c != null and how_c == "free" and not c.freeze and c.global_position.y < y0 - .05, {"how": how_c, "fell": (y0 - c.global_position.y) if c else null})
	# D — the web page's hand: a user:// copy with other knobs for the clock in the hand
	hand.held = a
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://inventory"))
	var f := FileAccess.open("user://inventory/hand.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"item": "clock", "config": {"clock": {"reading": "rate", "epoch": "arrival", "target_hz": 72}}}));f.close()
	var t0 := Time.get_ticks_msec();var took := -1
	while Time.get_ticks_msec() - t0 < 2500:
		await get_tree().process_frame
		if a != null and a.work != null and str(a.work.get("reading")) == "rate":took = Time.get_ticks_msec() - t0;break
	_check(report, "D web hand: hand.json (user://) set the held counter to read the rate within 2.5 s", took >= 0 and hand.config_for("clock").get("target_hz") == 72 and str(a.work.get("epoch")) == "arrival", {"took_ms": took, "cfg": hand.config_for("clock")})
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://inventory/hand.json"))
	_check(report, "D copy removed: no user:// hand.json left to shadow the repo's", not FileAccess.file_exists("user://inventory/hand.json"), {})
	# F — the tape is held as the roll itself
	hand.set_current("tape")
	var tp: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(1.6, 1.2, .2)))
	_check(report, "F tape: the tape item is the printed roll itself (an XR Tools pickable, no carrier)", tp != null and tp is XRToolsPickable and str(tp.get("kind")) == "printed", {"node": tp.name if tp else null, "kind": tp.get("kind") if tp else null})
	# E — grip takes the last one back
	var before: int = hand.placed.size();var gone: Node3D = hand.remove_last()
	_check(report, "E grip: remove_last takes back the last placed thing", gone != null and hand.placed.size() == before - 1, {"before": before, "after": hand.placed.size()})
	# the bracelet and the panel compile, and the ITEMS tab fills
	var cat := load("res://commons/hazards/becoming_catalyst/becoming_catalyst.gd")
	var panel: Control = load("res://commons/hazards/becoming_catalyst/tabbed_editor_panel.tscn").instantiate()
	add_child(panel);panel.set_items(hand.available(), "clock")
	var tabs: Array = panel.get("TABS")
	_check(report, "G compile: the bracelet script and the panel load; the panel has an ITEMS tab with the items", cat != null and panel != null and tabs.has("ITEMS") and (panel.get("_item_buttons") as Dictionary).size() == hand.available().size(), {"tabs": tabs, "buttons": (panel.get("_item_buttons") as Dictionary).keys()})
	panel.queue_free()
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("place.png"))
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_inventory_place] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _slab(what: String, size: Vector3, at: Vector3, colour: Color) -> void:
	var body := StaticBody3D.new();body.name = what;body.collision_layer = 1;body.position = at;add_child(body)
	var shape := CollisionShape3D.new();var bs := BoxShape3D.new();bs.size = size;shape.shape = bs;body.add_child(shape)
	var m := MeshInstance3D.new();var bm := BoxMesh.new();bm.size = size;m.mesh = bm
	var mat := StandardMaterial3D.new();mat.albedo_color = colour;m.material_override = mat;body.add_child(m)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_inventory_place] %s  %s" % ["ok  " if ok else "FAIL", what])

func _v(v: Vector3) -> Array:return [snappedf(v.x, .001), snappedf(v.y, .001), snappedf(v.z, .001)]
