extends SceneTree

## Headless smoke test for friend-side lineage powers (catalyst_foe).
##
## Seeds friends of specific lineages via apply_grid_config plus a fake
## player and fake foes, then asserts:
##   (e) SHIELD   — absorb_hit() true, then false during cooldown
##   (c) SPLITTER — drag_one_friend_back victim spawns a clone, no step-back
##   (b) DECOY    — a chasing foe's chosen target is the chaos friend
##   (a) CALMER   — timed slow applies AND restores to base speed
##   (d) ESCORT   — a contacting foe is shoved away from the player
## Prints PASS/FAIL, quit(0/1). Each phase runs in its own cluster that is
## freed before the next phase so group scans never cross-contaminate.

const FOE_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")

var _root: Node = null
var _player: Node3D = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== power_creature smoke test ===")
	_root = Node.new()
	_root.name = "TestRoot"
	get_root().add_child(_root)

	# Stand-in player.
	_player = Node3D.new()
	_player.name = "Player"
	_player.add_to_group("player")
	_root.add_child(_player)
	_player.global_position = Vector3.ZERO

	if not await _test_shield():
		_fail("shield absorb_hit"); return
	if not await _test_splitter():
		_fail("splitter clone"); return
	if not await _test_decoy():
		_fail("decoy retarget"); return
	if not await _test_calmer():
		_fail("calmer slow/restore"); return
	if not await _test_escort():
		_fail("escort shove"); return

	_scrub_progression_save()
	print("PASS: shield, splitter, decoy, calmer, escort all behave")
	quit(0)


func _fail(what: String) -> void:
	_scrub_progression_save()
	print("FAIL: %s" % what)
	quit(1)


## Conversions in this test grant real friend powers, which the autoloaded
## CatalystCapabilityManager persists to disk — scrub so test runs never
## pollute actual player progression.
func _scrub_progression_save() -> void:
	var mgr: Node = get_root().get_node_or_null("CatalystCapabilityManager")
	if mgr and mgr.has_method("reset_progression"):
		mgr.reset_progression()
	var save_path := "user://capability_progression.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


# ── (e) SHIELD — absorb true, then false during cooldown ────────────────

func _test_shield() -> bool:
	print("- shield (primitives): absorb_hit true then false...")
	var cluster := Node3D.new()
	_root.add_child(cluster)
	_player.global_position = Vector3.ZERO
	# "goo" foe_mode canonicalises to the "primitives" lineage.
	var shield = _spawn(cluster, Vector3(2, 0, 0),
		{"initial_state": "friend", "foe_mode": "goo"})
	if not shield.has_method("absorb_hit"):
		print("  missing absorb_hit()")
		await _free_cluster(cluster)
		return false
	var first: bool = bool(shield.call("absorb_hit"))
	var second: bool = bool(shield.call("absorb_hit"))
	print("  first=%s (expect true), second=%s (expect false)" % [first, second])
	await _free_cluster(cluster)
	return first and not second


# ── (c) SPLITTER — fractal victim clones instead of stepping back ───────

func _test_splitter() -> bool:
	print("- splitter (fractal): drag victim spawns clone, keeps friend...")
	var cluster := Node3D.new()
	_root.add_child(cluster)
	_player.global_position = Vector3(50, 0, 0)  # keep everyone patrolling
	var fractal = _spawn(cluster, Vector3(1, 0, 0),
		{"initial_state": "friend", "foe_mode": "fractal",
		 "chase_speed": 0.05, "speed": 0.05})
	var drainer = _spawn(cluster, Vector3(3, 0, 0),
		{"initial_state": "foe", "chase_speed": 0.05, "speed": 0.05})
	var before: int = get_nodes_in_group("catalyst_foe").size()
	drainer.call("drag_one_friend_back")
	var after: int = get_nodes_in_group("catalyst_foe").size()
	var still_friend: bool = String(fractal.call("get_personality")) == "friend"
	# Find the clone: a fractal friend that is neither original nor drainer.
	var clone_ok := false
	for n in get_nodes_in_group("catalyst_foe"):
		if n == fractal or n == drainer:
			continue
		if str(n.get("_personality")) == "friend" \
				and str(n.get("_locked_mode_id")) == "fractal":
			clone_ok = true
			break
	print("  count %d→%d (expect +1), victim still friend=%s, clone friend/fractal=%s" % [
		before, after, still_friend, clone_ok])
	await _free_cluster(cluster)
	return after == before + 1 and still_friend and clone_ok


# ── (b) DECOY — foe's chosen target is the chaos friend ─────────────────

func _test_decoy() -> bool:
	print("- decoy (chaos): chasing foe retargets onto the friend...")
	var cluster := Node3D.new()
	_root.add_child(cluster)
	_player.global_position = Vector3(0, 0, 3)  # close enough to trigger chase
	var foe = _spawn(cluster, Vector3(0, 0, 0),
		{"initial_state": "foe", "chase_speed": 0.05, "speed": 0.05})
	var decoy = _spawn(cluster, Vector3(2, 0, 0),
		{"initial_state": "friend", "foe_mode": "chaos",
		 "chase_speed": 0.05, "speed": 0.05})
	# PATROL→DETECT (0.4s)→CHASE, retarget within 0.5s of chasing.
	await _wait(1.4).timeout
	var target = foe.get("_decoy_target")
	print("  foe._decoy_target is chaos friend: %s" % (target == decoy))
	await _free_cluster(cluster)
	return target == decoy


# ── (a) CALMER — slow applies AND restores ──────────────────────────────

func _test_calmer() -> bool:
	print("- calmer (waveform): pulse halves chase_speed, then restores...")
	var cluster := Node3D.new()
	_root.add_child(cluster)
	_player.global_position = Vector3(500, 0, 0)  # far away, foe just patrols
	var foe = _spawn(cluster, Vector3(0, 0, 0), {"initial_state": "foe"})
	var calmer = _spawn(cluster, Vector3(1, 0, 0),
		{"initial_state": "friend", "foe_mode": "wave"})
	var base_speed: float = float(foe.get("chase_speed"))
	calmer.call("_pulse_calm")  # deterministic pulse (auto-pulse is 2.5s)
	var slowed: float = float(foe.get("chase_speed"))
	# Move the calmer out of range so later auto-pulses can't re-slow.
	(calmer as Node3D).global_position = Vector3(600, 0, 0)
	await _wait(2.5).timeout  # slow lasts 2.0s — base class restores
	var restored: float = float(foe.get("chase_speed"))
	print("  base=%.2f slowed=%.2f (expect %.2f) restored=%.2f" % [
		base_speed, slowed, base_speed * 0.5, restored])
	await _free_cluster(cluster)
	var slow_ok: bool = absf(slowed - base_speed * 0.5) < 0.01
	var restore_ok: bool = absf(restored - base_speed) < 0.01
	return slow_ok and restore_ok


# ── (d) ESCORT — contacting foe is shoved away from the player ──────────

func _test_escort() -> bool:
	print("- escort (swarm): contacting foe gets shoved off...")
	var cluster := Node3D.new()
	_root.add_child(cluster)
	_player.global_position = Vector3.ZERO
	var escort = _spawn(cluster, Vector3(0, 0, 2),
		{"initial_state": "friend", "foe_mode": "swarm",
		 "chase_speed": 0.05, "speed": 0.05})
	var foe = _spawn(cluster, Vector3(0.3, 0, 2),
		{"initial_state": "foe", "chase_speed": 0.05, "speed": 0.05})
	var start: Vector3 = (foe as Node3D).global_position
	await _wait(0.5).timeout
	var moved: float = (foe as Node3D).global_position.distance_to(start)
	var away_ok: bool = (foe as Node3D).global_position.distance_to(_player.global_position) \
		> start.distance_to(_player.global_position)
	print("  foe moved %.2fm (expect ~2m, away from player=%s), escort=%s" % [
		moved, away_ok, escort != null])
	await _free_cluster(cluster)
	return moved > 1.0 and away_ok


# ── Plumbing ────────────────────────────────────────────────────────────

func _spawn(cluster: Node3D, pos: Vector3, config: Dictionary):
	var n = FOE_SCENE.instantiate()
	# Position BEFORE add_child so _ready sees the right patrol origin.
	(n as Node3D).position = pos
	cluster.add_child(n)
	if not config.is_empty():
		n.call("apply_grid_config", config)
	return n


func _free_cluster(cluster: Node3D) -> void:
	cluster.queue_free()
	# Two frames so freed nodes leave their groups before the next phase.
	await process_frame
	await process_frame


func _wait(t: float) -> SceneTreeTimer:
	return create_timer(t)
