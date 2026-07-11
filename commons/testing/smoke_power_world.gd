extends SceneTree

## Headless smoke test for world-side catalyst power touchpoints:
##   1. NEUTRALIZER — a chromatic FRIEND inside a DangerZone mutes per-tick
##      damage; removing the friend restores it.
##   2. BRIDGER — BridgerTendril.try_grow spans the nearest zone with a
##      walkable "path_passable" strip, and refuses a second tendril on the
##      same zone.
## Prints PASS/FAIL, quits 0/1.

const DANGER_ZONE := preload("res://commons/hazards/DangerZone.gd")
const BRIDGER_TENDRIL := preload("res://commons/hazards/catalyst_foe/bridger_tendril.gd")

var _damage_ticks: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== power_world smoke test ===")
	var root := Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	# Stand-in player at origin.
	var player := Node3D.new()
	player.name = "Player"
	player.add_to_group("player")
	root.add_child(player)
	player.global_position = Vector3.ZERO

	# Fire zone 2m from the player.
	var zone = DANGER_ZONE.create_from_notation("h:fire")
	if zone == null:
		print("FAIL: create_from_notation('h:fire') returned null")
		quit(1); return
	root.add_child(zone)
	zone.global_position = Vector3(2, 0, 0)
	zone.damage_dealt.connect(_on_damage_dealt)

	if not zone.is_in_group("danger_zone"):
		print("FAIL: DangerZone did not join group 'danger_zone' in _ready")
		quit(1); return
	print("- zone joined group 'danger_zone'")

	# Chromatic friend stub standing inside the zone (just the two vars the
	# neutralizer scan reads — seeded friends in test maps work the same way).
	var stub := GDScript.new()
	stub.source_code = "extends Node3D\nvar _personality: String = \"friend\"\nvar _locked_mode_id: String = \"chromatic\"\n"
	stub.reload()
	var friend: Node3D = stub.new()
	friend.name = "ChromaFriendStub"
	friend.add_to_group("catalyst_foe")
	root.add_child(friend)
	friend.global_position = zone.global_position

	# Let the zone's periodic neutralizer scan pick the friend up.
	await create_timer(0.6).timeout

	# Simulate damage ticks directly: player inside, tick interval exceeded.
	var gm = get_root().get_node_or_null("GameManager")
	var health_before = _read_health(gm)
	zone.player_inside = true
	zone.damage_timer = 0.0
	_damage_ticks = 0
	zone._process_fire(zone.tick_interval + 0.5)
	zone._process_fire(zone.tick_interval + 0.5)
	if _damage_ticks != 0:
		print("FAIL: zone dealt %d damage tick(s) while chroma friend inside" % _damage_ticks)
		quit(1); return
	var health_after = _read_health(gm)
	if health_before != null and health_after != null and float(health_after) < float(health_before):
		print("FAIL: GameManager health dropped while neutralized (%s -> %s)" % [health_before, health_after])
		quit(1); return
	print("- neutralizer ok: 0 damage ticks with friend inside")

	# Remove the friend — the zone must bite again after the next scan.
	friend.queue_free()
	await create_timer(0.6).timeout
	_damage_ticks = 0
	zone._process_fire(zone.tick_interval + 0.5)
	if _damage_ticks < 1:
		print("FAIL: zone dealt no damage after friend removed")
		quit(1); return
	print("- zone bites again after friend removed (%d tick)" % _damage_ticks)

	# BRIDGER: grow a tendril across the zone (zone is 2m from player, < 6m).
	var grew: bool = BRIDGER_TENDRIL.try_grow(self, Vector3(1, 0, 1), player.global_position)
	if not grew:
		print("FAIL: try_grow returned false with a bridgeable zone 2m away")
		quit(1); return
	var tendrils: Array = get_nodes_in_group("path_passable")
	if tendrils.is_empty():
		print("FAIL: no 'path_passable' node in tree after try_grow")
		quit(1); return
	# Strip must span the zone extent + 1m each side (zone box is 1m wide -> >= 3m).
	var span: float = _tendril_span(tendrils[0])
	if span < 2.9:
		print("FAIL: tendril span %.2f m too short to cross the zone" % span)
		quit(1); return
	print("- tendril grown, span %.2f m, in group 'path_passable'" % span)

	# One tendril per zone: second call must refuse.
	if BRIDGER_TENDRIL.try_grow(self, Vector3(1, 0, 1), player.global_position):
		print("FAIL: second try_grow grew a duplicate tendril on the same zone")
		quit(1); return
	print("- second try_grow refused (one tendril per zone)")

	print("PASS: neutralizer mutes/restores damage, bridger spans zone once")
	quit(0)


func _on_damage_dealt(_amount: float, _danger_type) -> void:
	_damage_ticks += 1


func _read_health(gm):
	# Returns the GameManager's health if a known property exists, else null.
	if gm == null:
		return null
	for prop in ["current_health", "health", "player_health"]:
		if prop in gm:
			return gm.get(prop)
	return null


func _tendril_span(tendril: Node) -> float:
	# Depth-first search for the walkable strip's BoxShape3D; returns its length.
	var stack: Array = [tendril]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CollisionShape3D and (n as CollisionShape3D).shape is BoxShape3D:
			return ((n as CollisionShape3D).shape as BoxShape3D).size.z
		for c in n.get_children():
			stack.append(c)
	return 0.0
