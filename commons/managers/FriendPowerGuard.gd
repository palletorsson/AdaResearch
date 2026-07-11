# FriendPowerGuard.gd
# Player-side friend-power touchpoints. Pure static helpers — no scene presence,
# no autoload. Called from GameManager (shield) and CatalystCapabilityManager
# (launcher).
#
# Design rule: a power is ACTIVE while at least one live FRIEND of its lineage
# is present in the scene. Gate on friend presence + lineage only — do NOT
# hard-require the CatalystCapabilityManager grant, so seeded friends in test
# maps work. Every check must be a zero-cost no-op when no matching friend
# exists.

extends RefCounted

## Max distance (m) from the player at which a shield friend can absorb a hit.
const SHIELD_RANGE_M := 4.0
## Friends this close to the player count as "clustered underfoot".
const LAUNCHER_RANGE_M := 1.2
## Minimum forces-lineage friends underfoot to trigger the launcher.
const LAUNCHER_MIN_FRIENDS := 2
## Upward boost the launcher grants (m/s).
const LAUNCHER_BOOST_MPS := 4.0


## True when node is a live catalyst creature settled at FRIEND with the
## given locked-mode lineage. All accesses defensive — stubs in tests only
## need _personality / _locked_mode_id vars.
static func _is_friend_of_lineage(node: Node, lineage: String) -> bool:
	if not is_instance_valid(node):
		return false
	if not ("_personality" in node) or str(node.get("_personality")) != "friend":
		return false
	if not ("_locked_mode_id" in node) or str(node.get("_locked_mode_id")) != lineage:
		return false
	return true


## SHIELD (primitives lineage): scan for a friend near the player that can
## absorb the incoming hit. The creature owns its own cooldown inside
## absorb_hit() — trust its bool. Returns true if a friend absorbed.
static func try_absorb(tree: SceneTree, player_pos: Vector3) -> bool:
	if tree == null:
		return false
	for node in tree.get_nodes_in_group("catalyst_foe"):
		if not _is_friend_of_lineage(node, "primitives"):
			continue
		if not (node is Node3D) or not node.is_inside_tree():
			continue
		if (node as Node3D).global_position.distance_to(player_pos) > SHIELD_RANGE_M:
			continue
		if not node.has_method("absorb_hit"):
			continue
		if bool(node.call("absorb_hit")):
			return true
	return false


## LAUNCHER (forces lineage): true when >= 2 forces friends cluster underfoot.
## Returns the impulse to apply, or Vector3.ZERO when the power is inactive.
static func check_launcher(tree: SceneTree, player_pos: Vector3) -> Vector3:
	if tree == null:
		return Vector3.ZERO
	var clustered: int = 0
	for node in tree.get_nodes_in_group("catalyst_foe"):
		if not _is_friend_of_lineage(node, "forces"):
			continue
		if not (node is Node3D) or not node.is_inside_tree():
			continue
		if (node as Node3D).global_position.distance_to(player_pos) <= LAUNCHER_RANGE_M:
			clustered += 1
			if clustered >= LAUNCHER_MIN_FRIENDS:
				return Vector3(0.0, LAUNCHER_BOOST_MPS, 0.0)
	return Vector3.ZERO
