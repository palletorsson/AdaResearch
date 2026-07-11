extends SceneTree

## Headless smoke test for player-side friend-power touchpoints.
##
## Checks:
##   (a) a shield-friend stub (primitives lineage, in group "catalyst_foe",
##       within 4m of the player) absorbs damage — GameManager health unchanged
##   (b) with the stub removed, damage applies again
##   (c) FriendPowerGuard.check_launcher returns ZERO with 0-1 forces friends
##       and a non-zero upward impulse with 2 clustered ones
##
## Prints PASS/FAIL, quits 0/1. Autoloads (GameManager etc.) are present in
## --script runs.

const FriendPowerGuardScript := preload("res://commons/managers/FriendPowerGuard.gd")


class FriendStub extends Node3D:
	var _personality: String = "friend"
	var _locked_mode_id: String = "primitives"
	var absorb_calls: int = 0
	func absorb_hit() -> bool:
		absorb_calls += 1
		return true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== power manager smoke test ===")
	var gm: Node = root.get_node_or_null("/root/GameManager")
	if gm == null:
		print("FAIL: GameManager autoload missing")
		quit(1); return

	# Remove DeathEffect so immunity / hurt visuals can't interfere headless.
	var death_fx: Node = root.get_node_or_null("/root/DeathEffect")
	if death_fx:
		death_fx.get_parent().remove_child(death_fx)
		death_fx.free()

	var test_root := Node.new()
	test_root.name = "PowerTestRoot"
	root.add_child(test_root)

	# Stand-in player.
	var player := Node3D.new()
	player.name = "Player"
	player.add_to_group("player")
	test_root.add_child(player)
	player.global_position = Vector3.ZERO

	# --- (a) shield friend absorbs the hit ---------------------------------
	var shield := FriendStub.new()
	shield.name = "ShieldFriendStub"
	shield.add_to_group("catalyst_foe")
	test_root.add_child(shield)
	shield.global_position = Vector3(1, 0, 0)  # within 4m shield range

	gm.set_health(100.0)
	var health_before: float = gm.get_health()
	gm.apply_health_damage(25.0)
	if absf(gm.get_health() - health_before) > 0.001 or shield.absorb_calls != 1:
		print("FAIL: (a) shield did not absorb — health %.1f -> %.1f, absorb_calls=%d" % [
			health_before, gm.get_health(), shield.absorb_calls])
		_cleanup(gm, test_root)
		quit(1); return
	print("- (a) shield absorbed: health unchanged at %.1f, absorb_calls=1" % gm.get_health())

	# --- (b) shield gone -> damage applies again ----------------------------
	shield.remove_from_group("catalyst_foe")
	test_root.remove_child(shield)
	shield.free()
	gm.apply_health_damage(25.0)
	if absf(gm.get_health() - (health_before - 25.0)) > 0.001:
		print("FAIL: (b) damage did not apply without shield — health=%.1f (expected %.1f)" % [
			gm.get_health(), health_before - 25.0])
		_cleanup(gm, test_root)
		quit(1); return
	print("- (b) shield gone: damage applied, health=%.1f" % gm.get_health())

	# --- (c) launcher cluster check -----------------------------------------
	var imp0: Vector3 = FriendPowerGuardScript.check_launcher(self, player.global_position)
	if imp0 != Vector3.ZERO:
		print("FAIL: (c) launcher fired with 0 friends: %s" % imp0)
		_cleanup(gm, test_root)
		quit(1); return

	var f1 := FriendStub.new()
	f1.name = "ForcesFriend1"
	f1._locked_mode_id = "forces"
	f1.add_to_group("catalyst_foe")
	test_root.add_child(f1)
	f1.global_position = Vector3(0.5, 0, 0)

	var imp1: Vector3 = FriendPowerGuardScript.check_launcher(self, player.global_position)
	if imp1 != Vector3.ZERO:
		print("FAIL: (c) launcher fired with only 1 friend: %s" % imp1)
		_cleanup(gm, test_root)
		quit(1); return

	var f2 := FriendStub.new()
	f2.name = "ForcesFriend2"
	f2._locked_mode_id = "forces"
	f2.add_to_group("catalyst_foe")
	test_root.add_child(f2)
	f2.global_position = Vector3(0, 0, 0.5)

	var imp2: Vector3 = FriendPowerGuardScript.check_launcher(self, player.global_position)
	if imp2 == Vector3.ZERO or imp2.y <= 0.0:
		print("FAIL: (c) launcher did not fire with 2 clustered friends: %s" % imp2)
		_cleanup(gm, test_root)
		quit(1); return
	print("- (c) launcher: ZERO with 0-1 friends, %s with 2 clustered friends" % imp2)

	_cleanup(gm, test_root)
	print("PASS: shield absorbs + releases, launcher gates on 2-friend cluster")
	quit(0)


func _cleanup(gm: Node, test_root: Node) -> void:
	# Restore GameManager health state and drop the cached player reference.
	if gm:
		gm.set("current_player", null)
		if gm.has_method("reset_level_state"):
			gm.call("reset_level_state")
	if is_instance_valid(test_root):
		root.remove_child(test_root)
		test_root.free()
