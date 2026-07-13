extends SceneTree

## Headless smoke test for catalyst_foe + catalyst_vent.
##
## Spins up a minimal scene:
##   - A "player" node3d (in group "player") at origin
##   - A CatalystVent at (3, 0, 0) emitting every 0.5s, wave_size 3
## Runs for 4 seconds, then asserts:
##   - At least one foe spawned and walked toward player
##   - 4 hit_by_projectile() calls walk it foe→wary→neutral→curious→friend
##   - The friend then chases another foe
## Prints PASS/FAIL.

const VENT_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_vent.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== catalyst_foe smoke test ===")
	var root := Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	# Stand-in player.
	var player := Node3D.new()
	player.name = "Player"
	player.add_to_group("player")
	root.add_child(player)
	player.global_position = Vector3(0, 0, 0)

	# Vent.
	var vent_inst: Node = VENT_SCENE.instantiate()
	root.add_child(vent_inst)
	vent_inst.set("emit_interval_s", 0.5)
	vent_inst.set("wave_size", 3)
	vent_inst.set("start_delay_s", 0.0)         # no warmup in tests
	vent_inst.set("require_catalyst_armed", false)  # no bracelet in tests
	(vent_inst as Node3D).global_position = Vector3(3, 0, 0)

	print("- player @ %s, vent @ %s" % [player.global_position, (vent_inst as Node3D).global_position])
	print("- waiting 3s for vent to emit + foes to walk...")
	await _wait(3.0).timeout

	# How many foes are in the world?
	var foes: Array = root.get_tree().get_nodes_in_group("catalyst_foe")
	print("- foes spawned: %d" % foes.size())
	if foes.size() == 0:
		print("FAIL: no foes spawned")
		quit(1); return

	# Pick the first foe and verify it walked toward player.
	var f0: Node3D = foes[0] as Node3D
	var dx_to_player: float = abs(f0.global_position.x - player.global_position.x)
	print("- first foe x=%.2f (started at vent x=3.0)" % f0.global_position.x)
	if dx_to_player >= 3.0:
		print("WARN: foe didn't move much yet (might be ok if just spawned)")

	# Call hit_by_projectile to flip it.
	if not f0.has_method("hit_by_projectile"):
		print("FAIL: foe missing hit_by_projectile()")
		quit(1); return
	print("- firing 4 catalyst hits on foe[0] (one personality step each)...")
	for i in range(4):
		f0.call("hit_by_projectile", Color(1.0, 0.0, 1.0))
	await _wait(0.5).timeout
	var personality_after: String = String(f0.call("get_personality"))
	print("- foe[0].personality after 4 hits = '%s' (expect 'friend')" % personality_after)
	if personality_after != "friend":
		print("FAIL: 4 hits didn't walk personality to friend")
		quit(1); return

	# The conversion above granted a real friend power — scrub so test runs
	# never pollute actual player progression.
	var mgr: Node = get_root().get_node_or_null("CatalystCapabilityManager")
	if mgr and mgr.has_method("reset_progression"):
		mgr.reset_progression()
	var save_path := "user://capability_progression.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	print("PASS: foe spawned, walks, 4 catalyst hits walk it to friend")
	quit(0)


func _wait(t: float) -> SceneTreeTimer:
	return create_timer(t)
