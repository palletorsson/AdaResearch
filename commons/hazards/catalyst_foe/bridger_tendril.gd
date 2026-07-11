# bridger_tendril.gd
# BRIDGER power (branching lineage): a catalyst friend grows a walkable
# organic strip across the nearest DangerZone so the player can cross
# without taking damage.
#
# Contract (catalyst_foe preloads this script and calls):
#   BridgerTendril.try_grow(tree, friend_pos, player_pos) -> bool
#
# Rules:
#   - only zones in group "danger_zone" within 6m of the player qualify
#   - instant_kill zones (h:death) are refused — death is not negotiable
#   - only ONE live tendril per zone (tracked via meta "bridger_tendril")
#   - the tendril is a child of the zone's parent, so it dies with the map
#   - auto-frees after 30s
# Defensive everywhere; callable headless.

extends RefCounted

const LIFETIME_S := 30.0
const MAX_ZONE_DISTANCE_M := 6.0
const STRIP_WIDTH := 0.8
const STRIP_THICKNESS := 0.15
const TOP_ABOVE_FLOOR := 0.18
const LANDING_EACH_SIDE_M := 1.0
const LEAF_GREEN := Color(0.40, 0.64, 0.12)  # BRANCH hue


static func try_grow(tree: SceneTree, friend_pos: Vector3, player_pos: Vector3) -> bool:
	if tree == null:
		return false

	var zone: Node3D = _nearest_bridgeable_zone(tree, player_pos)
	if zone == null:
		return false

	# One live tendril per zone.
	if zone.has_meta("bridger_tendril"):
		var existing = zone.get_meta("bridger_tendril")
		if existing != null and is_instance_valid(existing):
			return false

	# Geometry: span the zone's extent + 1m landing each side, aligned from
	# the player side across the zone center.
	var center: Vector3 = zone.global_position
	var col: CollisionShape3D = _find_zone_shape(zone)
	if col:
		center = col.global_position
	var half_extent: float = _zone_half_extent(zone)
	var span: float = half_extent * 2.0 + LANDING_EACH_SIDE_M * 2.0

	var dir: Vector3 = center - player_pos
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		# Player standing on the zone center — fall back to friend approach.
		dir = center - friend_pos
		dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	dir = dir.normalized()

	var tendril: Node3D = _build_tendril(span)

	# Child of the zone's parent so it dies with the map.
	var parent: Node = zone.get_parent()
	if parent == null:
		parent = zone
	parent.add_child(tendril)

	# Top surface ~0.18m above the zone's floor y, centered on the zone,
	# strip length running along local Z (looking_at points -Z along dir).
	var floor_y: float = zone.global_position.y
	var origin := Vector3(center.x, floor_y + TOP_ABOVE_FLOOR - STRIP_THICKNESS * 0.5, center.z)
	tendril.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), origin)

	zone.set_meta("bridger_tendril", tendril)

	# Auto-free after LIFETIME_S; weakref so a map unload can't double-free.
	var wr: WeakRef = weakref(tendril)
	tree.create_timer(LIFETIME_S).timeout.connect(func() -> void:
		var n = wr.get_ref()
		if n != null and is_instance_valid(n):
			n.queue_free()
	)
	return true


static func _nearest_bridgeable_zone(tree: SceneTree, player_pos: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d: float = MAX_ZONE_DISTANCE_M
	for zone in tree.get_nodes_in_group("danger_zone"):
		if not is_instance_valid(zone) or not (zone is Node3D):
			continue
		if ("instant_kill" in zone) and zone.get("instant_kill"):
			continue  # h:death cannot be bridged
		var d: float = (zone as Node3D).global_position.distance_to(player_pos)
		if d <= best_d:
			best_d = d
			best = zone as Node3D
	return best


static func _find_zone_shape(zone: Node) -> CollisionShape3D:
	var col = zone.get_node_or_null("CollisionShape3D")
	if col and col is CollisionShape3D:
		return col
	for child in zone.get_children():
		if child is CollisionShape3D:
			return child
	return null


static func _zone_half_extent(zone: Node) -> float:
	# Horizontal half-extent from the zone's collision shape; safe fallback.
	var col: CollisionShape3D = _find_zone_shape(zone)
	if col and col.shape:
		var shape: Shape3D = col.shape
		if shape is BoxShape3D:
			var s: Vector3 = (shape as BoxShape3D).size
			return max(s.x, s.z) * 0.5
		if shape is SphereShape3D:
			return (shape as SphereShape3D).radius
		if shape is CylinderShape3D:
			return (shape as CylinderShape3D).radius
	return 0.5


static func _build_tendril(span: float) -> Node3D:
	var tendril := Node3D.new()
	tendril.name = "BridgerTendril"
	tendril.add_to_group("path_passable")

	# Walkable strip — collision layer 1 (world/walkable).
	var body := StaticBody3D.new()
	body.name = "TendrilBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(STRIP_WIDTH, STRIP_THICKNESS, span)
	col.shape = shape
	body.add_child(col)
	tendril.add_child(body)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = LEAF_GREEN
	mat.emission_enabled = true
	mat.emission = LEAF_GREEN
	mat.emission_energy_multiplier = 0.9

	# Organic look: overlapping slightly-offset green pieces.
	var main := MeshInstance3D.new()
	main.name = "VineMain"
	var main_mesh := BoxMesh.new()
	main_mesh.size = Vector3(STRIP_WIDTH * 0.85, STRIP_THICKNESS * 0.8, span)
	main.mesh = main_mesh
	main.material_override = mat
	tendril.add_child(main)

	var rib := MeshInstance3D.new()
	rib.name = "VineRib"
	var rib_mesh := CapsuleMesh.new()
	rib_mesh.radius = 0.09
	rib_mesh.height = max(span * 0.9, 0.4)
	rib.mesh = rib_mesh
	rib.material_override = mat
	rib.rotation_degrees = Vector3(90, 0, 0)  # capsule Y axis → along strip Z
	rib.position = Vector3(0.18, 0.03, 0.0)
	tendril.add_child(rib)

	var shoot := MeshInstance3D.new()
	shoot.name = "VineShoot"
	var shoot_mesh := BoxMesh.new()
	shoot_mesh.size = Vector3(0.28, STRIP_THICKNESS * 0.5, span * 0.8)
	shoot.mesh = shoot_mesh
	shoot.material_override = mat
	shoot.position = Vector3(-0.2, 0.05, span * 0.04)
	shoot.rotation_degrees = Vector3(0, 3.0, 0)
	tendril.add_child(shoot)

	return tendril
