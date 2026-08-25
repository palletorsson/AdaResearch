# Direct Godot 4.6 contract smoke for architectural wall collision truth.
extends SceneTree

const PIECE_SCENE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const CONTRACT_PATH := "res://commons/data/museum_wall_physics_contract.json"
const FAMILIES := ["solid", "feature", "service", "endcap"]
const EXPECTED_SURFACE_SHAPES := {
	"solid": {"stone": 4},
	"feature": {"stone": 3, "bronze": 2},
	"service": {"stone": 3, "painted_metal": 3, "bronze": 1},
	"endcap": {"stone": 5, "bronze": 3},
}
const EXPECTED_BODIES := {"solid": 1, "feature": 2, "service": 3, "endcap": 2}
const FORBIDDEN_DUPLICATE_BODIES := ["WallCollision", "ServiceFixtureCollision", "EndcapReturnCollision"]

var _failures := 0
var _physics_contract: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_physics_contract = _load_contract()
	_check(not _physics_contract.is_empty(), "physics contract loaded")
	var test_root := Node3D.new()
	get_root().add_child(test_root)
	for family in FAMILIES:
		var family_shape_count := -1
		for width in range(1, 5):
			var piece := _spawn_piece(test_root, family, width, 0, true)
			var contract := piece.get_node_or_null("PieceContract") as Node3D
			_check(contract != null, "%s w%d PieceContract" % [family, width])
			if contract == null:
				continue
			var bodies := _descendants_of_type(contract, "StaticBody3D")
			var shapes := _descendants_of_type(contract, "CollisionShape3D")
			_check(bodies.size() == int(EXPECTED_BODIES[family]), "%s w%d canonical body count" % [family, width])
			var expected_total := _expected_total_shapes(family)
			_check(shapes.size() == expected_total, "%s w%d exact shape count" % [family, width])
			if family_shape_count < 0:
				family_shape_count = shapes.size()
			_check(shapes.size() == family_shape_count, "%s w%d width-invariant shape count" % [family, width])
			_check(_surface_bodies_ok(contract, family), "%s w%d canonical surface bodies" % [family, width])
			_check(_mesh_roles_ok(contract), "%s w%d explicit mesh roles and targets" % [family, width])
			_check(_no_duplicate_bodies(contract), "%s w%d no duplicate helper/body coverage" % [family, width])
			_check(_collision_report_ok(contract, expected_total), "%s w%d collision report" % [family, width])

	for family in FAMILIES:
		_check(_lod_shape_identity(test_root, family, 2), "%s shared LOD-invariant Shape3D RIDs" % family)

	for family in FAMILIES:
		var disabled := _spawn_piece(test_root, family, 2, 0, false)
		var disabled_contract := disabled.get_node_or_null("PieceContract") as Node3D
		_check(disabled_contract != null and _descendants_of_type(disabled_contract, "StaticBody3D").is_empty(), "%s collision=false is zero bodies" % family)
		_check(disabled_contract != null and _descendants_of_type(disabled_contract, "CollisionShape3D").is_empty(), "%s collision=false is zero shapes" % family)

	print("MUSEUM_WALL_ARCHITECTURAL_COLLISION_ZONES_TEST failures=%d shared_shape_cache=%d shared_physics_cache=%d" % [_failures, MuseumWallPiece._shared_collision_shapes.size(), MuseumWallPiece._shared_physics_materials.size()])
	test_root.queue_free()
	quit(0 if _failures == 0 else 1)


func _spawn_piece(parent: Node3D, family: String, width: int, lod: int, collision_enabled: bool) -> Node3D:
	var piece := PIECE_SCENE.instantiate() as MuseumWallPiece
	piece.kind = family
	piece.width_cells = width
	piece.height = 4.0
	piece.finish = "uffizi_stone"
	piece.flip = family == "endcap" and width % 2 == 0
	piece.detail_seed = 4067
	piece.lod_level = lod
	piece.enable_collision = collision_enabled
	parent.add_child(piece)
	return piece


func _surface_bodies_ok(contract: Node3D, family: String) -> bool:
	var expected: Dictionary = EXPECTED_SURFACE_SHAPES[family]
	var seen := {}
	for node in _descendants_of_type(contract, "StaticBody3D"):
		var body := node as StaticBody3D
		var surface_id := str(body.get_meta("physics_surface_id", ""))
		if not expected.has(surface_id) or seen.has(surface_id):
			return false
		seen[surface_id] = true
		if body.name != _body_name(surface_id):
			return false
		if body.physics_material_override == null:
			return false
		var surface_spec: Dictionary = (_physics_contract.get("surfaces", {}) as Dictionary).get(surface_id, {})
		if surface_spec.is_empty():
			return false
		if not is_equal_approx(body.physics_material_override.friction, float(surface_spec["friction"])):
			return false
		if not is_equal_approx(body.physics_material_override.bounce, float(surface_spec["bounce"])):
			return false
		for key in ["impact", "decal", "breakability"]:
			if str(body.get_meta(key, "")) != str(surface_spec[key]):
				return false
		for alias in ["physics_surface_id", "surface_id", "surface_type", "surface_audio"]:
			if str(body.get_meta(alias, "")) != surface_id:
				return false
		var body_shapes := 0
		for child in body.get_children():
			if child is CollisionShape3D:
				var collision := child as CollisionShape3D
				if not collision.shape is BoxShape3D:
					return false
				body_shapes += 1
		if body_shapes != int(expected[surface_id]):
			return false
	return seen.size() == expected.size()


func _mesh_roles_ok(contract: Node3D) -> bool:
	for node in _descendants_of_type(contract, "MeshInstance3D"):
		var mesh := node as MeshInstance3D
		var role := str(mesh.get_meta("collision_role", ""))
		if role == "visual_only":
			if not str(mesh.get_meta("physics_surface_id", "")).is_empty() or not str(mesh.get_meta("collision_target", "")).is_empty():
				return false
		elif role == "solid":
			var surface_id := str(mesh.get_meta("physics_surface_id", ""))
			var target := str(mesh.get_meta("collision_target", ""))
			if surface_id not in ["stone", "bronze", "painted_metal"] or target.is_empty():
				return false
			var body := contract.find_child(target, true, false) as StaticBody3D
			if body == null or str(body.get_meta("physics_surface_id", "")) != surface_id:
				return false
		else:
			return false
	return true


func _lod_shape_identity(parent: Node3D, family: String, width: int) -> bool:
	var rid_lists: Array = []
	for lod in range(3):
		var piece := _spawn_piece(parent, family, width, lod, true)
		var contract := piece.get_node("PieceContract") as Node3D
		var rids: Array = []
		for node in _descendants_of_type(contract, "CollisionShape3D"):
			var collision := node as CollisionShape3D
			rids.append(collision.shape.get_rid().get_id())
		rid_lists.append(rids)
	return rid_lists[0] == rid_lists[1] and rid_lists[1] == rid_lists[2]


func _collision_report_ok(contract: Node3D, expected_shapes: int) -> bool:
	var report: Dictionary = contract.get_meta("collision_report", {})
	return str(report.get("owner", "")) == "MuseumWallPiece" \
		and str(report.get("profile", "")) == "museum_surface_zones_v2" \
		and int(report.get("shape_count", -1)) == expected_shapes \
		and int(report.get("decorative_colliders", -1)) == 0 \
		and bool(report.get("shared_shape_resources", false))


func _no_duplicate_bodies(contract: Node3D) -> bool:
	for forbidden in FORBIDDEN_DUPLICATE_BODIES:
		if contract.find_child(forbidden, true, false) != null:
			return false
	return true


func _expected_total_shapes(family: String) -> int:
	var total := 0
	for count in (EXPECTED_SURFACE_SHAPES[family] as Dictionary).values():
		total += int(count)
	return total


func _body_name(surface_id: String) -> String:
	match surface_id:
		"bronze": return "CollisionBronze"
		"painted_metal": return "CollisionPaintedMetal"
		_: return "CollisionStone"


func _load_contract() -> Dictionary:
	var file := FileAccess.open(CONTRACT_PATH, FileAccess.READ)
	if file == null:
		return {}
	var decoded: Variant = JSON.parse_string(file.get_as_text())
	return decoded if decoded is Dictionary else {}


func _descendants_of_type(root: Node, class_name_filter: String) -> Array[Node]:
	var found: Array[Node] = []
	_collect_type(root, class_name_filter, found)
	return found


func _collect_type(node: Node, class_name_filter: String, found: Array[Node]) -> void:
	for child in node.get_children():
		if child.is_class(class_name_filter):
			found.append(child)
		_collect_type(child, class_name_filter, found)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		_failures += 1
		push_error("FAIL: %s" % label)
