extends SceneTree

## Catalyst Collision Lab
##
## Five headless tests that exercise the projectile → foe contact path,
## the contracts that go with it, and the ways collision can fail.
## Each test builds an isolated scene, lets physics simulate, and asserts.
##
## Run:
##   godot --xr-mode off --headless --script res://commons/testing/catalyst_collision_lab.gd
##
## Note: skipped test for "projectile passes through own catalyst" because
## becoming_catalyst.tscn depends on godot-xr-tools/pickable which doesn't
## compile in headless. The skip path itself is verified by reading the
## catalyst_projectile.gd source (the `is_in_group("catalyst")` early-return).

const FOE_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const ProjectileScript := preload("res://commons/hazards/becoming_catalyst/catalyst_projectile.gd")

var _results: Array = []  # list of {name, ok, msg}


func _initialize() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	print("=== catalyst collision lab ===")
	await _test_1_projectile_hits_foe()
	await _test_2_projectile_blocked_by_world()
	await _test_4_per_mode_dispatch()
	await _test_5_projectile_expires_without_hit()
	await _test_6_projectile_aimed_too_high()
	_summary()


# ── Helpers ──────────────────────────────────────────────────────────

func _make_root(label: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Lab_" + label
	get_root().add_child(root)
	# stand-in player so foe._physics_process doesn't crash
	var player := Node3D.new()
	player.add_to_group("player")
	root.add_child(player)
	player.global_position = Vector3(0, 0, 100)
	return root


func _spawn_foe_at(root: Node3D, pos: Vector3) -> Node:
	var f: Node = FOE_SCENE.instantiate()
	root.add_child(f)
	(f as Node3D).global_position = pos
	# Keep the foe stationary for the duration of these tests.
	(f as Node).set("require_catalyst_armed", false)
	(f as Node).set("step_period_s", 999.0)  # effectively never moves
	return f


func _spawn_projectile(root: Node3D, mode_id: String, pos: Vector3, direction: Vector3) -> Node:
	# Match the reference factory in mode_primitives.create_projectile:
	#   var proj := CatalystProjectile.new()    # inherit base setup
	#   proj.set_script(load(".../mode_X_projectile.gd"))
	#   set props
	#   parent.add_child(proj)
	#   proj.global_position = pos
	# Crucially: instantiate as CatalystProjectile (not bare RigidBody3D)
	# so the base script's setup is part of the chain.
	var p: Node = ProjectileScript.new()  # = CatalystProjectile.new()
	var script_path := "res://commons/hazards/becoming_catalyst/modes/%s_projectile.gd" % mode_id
	if ResourceLoader.exists(script_path):
		p.set_script(load(script_path))
	p.set("speed", 12.0)
	p.set("lifetime", 4.0)
	p.set("direction", direction.normalized())
	p.set("color_primary", Color(1, 0, 1))
	root.add_child(p)
	(p as Node3D).global_position = pos
	return p


func _wait_frames(n: int) -> void:
	for _i in n:
		await get_root().get_tree().process_frame


func _record(name: String, ok: bool, msg: String = "") -> void:
	_results.append({"name": name, "ok": ok, "msg": msg})
	var prefix := "PASS" if ok else "FAIL"
	if msg.is_empty():
		print("  [%s] %s" % [prefix, name])
	else:
		print("  [%s] %s — %s" % [prefix, name, msg])


# ── Tests ────────────────────────────────────────────────────────────

# 1. Direct hit: foe in front of projectile, no obstruction.
func _test_1_projectile_hits_foe() -> void:
	var root := _make_root("01_direct_hit")
	var foe := _spawn_foe_at(root, Vector3(0, 0, 0))
	await _wait_frames(3)
	var proj := _spawn_projectile(root, "primitives", Vector3(-2, 0, 0), Vector3(1, 0, 0))
	# Run ~60 frames to let physics carry the projectile across the gap.
	await _wait_frames(60)
	var state: int = int((foe as Node).get("state"))
	# state enum: 0 = FOE, 1 = FRIEND
	_record("1. projectile hits foe → foe converts to FRIEND",
		state == 1,
		"state was %d (expected 1=FRIEND); foe at %s, projectile may have missed" % [
			state, (foe as Node3D).global_position])
	root.queue_free()
	await _wait_frames(2)


# 2. World wall blocks the projectile before it reaches the foe.
func _test_2_projectile_blocked_by_world() -> void:
	var root := _make_root("02_world_blocks")
	var foe := _spawn_foe_at(root, Vector3(0, 0, 0))
	# Wall at x=-1 between projectile at x=-2 and foe at x=0.
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, 2, 2)
	col.shape = shape
	wall.add_child(col)
	root.add_child(wall)
	wall.position = Vector3(-1, 0, 0)
	await _wait_frames(3)
	var proj := _spawn_projectile(root, "primitives", Vector3(-2, 0, 0), Vector3(1, 0, 0))
	await _wait_frames(60)
	var state: int = int((foe as Node).get("state"))
	_record("2. projectile blocked by world wall → foe stays FOE",
		state == 0,
		"state was %d (expected 0=FOE; wall should have absorbed the hit)" % state)
	root.queue_free()
	await _wait_frames(2)


# 4. Each mode projectile dispatches to the right foe_mode enum.
func _test_4_per_mode_dispatch() -> void:
	var cases: Array = [
		{"mode": "primitives",     "expected": 0, "label": "GOO"},
		{"mode": "transformation", "expected": 1, "label": "TRANSPORT"},
		{"mode": "swarm",          "expected": 2, "label": "SWARM"},
		{"mode": "cellular",       "expected": 3, "label": "DRAINFRIEND"},
	]
	var fails: int = 0
	var detail: Array = []
	for c in cases:
		var root := _make_root("04_" + c["mode"])
		var foe := _spawn_foe_at(root, Vector3(0, 0, 0))
		await _wait_frames(3)
		var proj := _spawn_projectile(root, c["mode"], Vector3(-2, 0, 0), Vector3(1, 0, 0))
		await _wait_frames(60)
		var foe_mode: int = int((foe as Node).get("foe_mode"))
		var state: int = int((foe as Node).get("state"))
		if state != 1 or foe_mode != int(c["expected"]):
			fails += 1
			detail.append("%s: state=%d foe_mode=%d (expected state=1 mode=%d=%s)"
				% [c["mode"], state, foe_mode, int(c["expected"]), c["label"]])
		root.queue_free()
		await _wait_frames(2)
	var msg: String = ""
	if fails > 0:
		msg = "%d/%d failed: %s" % [fails, cases.size(), "; ".join(detail)]
	else:
		msg = "all 4 modes (goo/transport/swarm/drainfriend) dispatched correctly"
	_record("4. per-mode dispatch", fails == 0, msg)


# 5. Projectile in empty scene flies into the void. Must expire cleanly.
func _test_5_projectile_expires_without_hit() -> void:
	var root := _make_root("05_empty_void")
	await _wait_frames(2)
	var proj := _spawn_projectile(root, "primitives", Vector3(0, 0, 0), Vector3(1, 0, 0))
	proj.set("lifetime", 0.5)
	# 60 frames @ 60fps = ~1 second. Lifetime=0.5s; should expire.
	await _wait_frames(60)
	var still_alive: bool = is_instance_valid(proj) and (proj as Node).is_inside_tree()
	_record("5. projectile expires cleanly when it hits nothing",
		not still_alive,
		"projectile still in tree after ~1s (lifetime=0.5s)")
	root.queue_free()
	await _wait_frames(2)


# 6. Projectile flies over the foe — common VR aim mistake. Foe stays.
func _test_6_projectile_aimed_too_high() -> void:
	var root := _make_root("06_too_high")
	var foe := _spawn_foe_at(root, Vector3(0, 0.15, 0))
	await _wait_frames(3)
	# Projectile at y=2 (well above the foe's 0.3m height).
	var proj := _spawn_projectile(root, "primitives", Vector3(-2, 2.0, 0), Vector3(1, 0, 0))
	await _wait_frames(60)
	var state: int = int((foe as Node).get("state"))
	_record("6. projectile aimed too high → foe stays FOE",
		state == 0,
		"state was %d (expected 0=FOE; projectile flew above)" % state)
	root.queue_free()
	await _wait_frames(2)


# ── Summary ──────────────────────────────────────────────────────────

func _summary() -> void:
	var total: int = _results.size()
	var passed: int = 0
	for r in _results:
		if r["ok"]: passed += 1
	print("")
	print("=== summary: %d / %d tests passed ===" % [passed, total])
	if passed < total:
		print("FAILED tests:")
		for r in _results:
			if not r["ok"]:
				print("  - %s" % r["name"])
				print("    %s" % r.get("msg", ""))
	quit(0 if passed == total else 1)
