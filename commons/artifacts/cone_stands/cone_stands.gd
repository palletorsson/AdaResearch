extends Node3D
## CONES UNDER THE CUBES (Palle, 2026-11-04: "in the array map put cones that are physical under each pickup cube in
## 1D and 2D array", and a picture of the cone). Each pick-up cube of the named arrays on this floor gets a traffic cone
## (traffic_cone.gd: solid, two white bands, square plate) standing on whatever is under it - the slab, a ledge - and the
## cube is seated on the cone's tip: its bob stopped, its spin kept (an idling cube bobbed 0.2 m and would have passed
## into the cone). The cones stay when a cube is collected: the address survives the absence. The arrays' own code is
## not touched; this finds their cubes in the floor and stands beside them.
##   config: targets (comma-separated artifact ids on this floor), height (m), style, base

const Cone = preload("res://commons/artifacts/traffic_cone/traffic_cone.gd")
const CUBE_SCRIPT := "res://commons/scenes/mapobjects/pick_up_cube.gd"

@export var targets := "row,grid"
@export var height := 0.45
@export var style := "bands"
@export var base := "square"

var cones: Array[Node3D] = []
var seated: Array[Node3D] = []

func apply_grid_config(config: Dictionary) -> void:
	if config.has("targets"): targets = str(config.targets)
	if config.has("height"): height = clampf(float(config.height), .1, 2.0)
	if config.has("style"): style = str(config.style)
	if config.has("base"): base = str(config.base)

func _ready() -> void:
	for key in ["targets", "height", "style", "base"]:
		if has_meta("config_" + key): apply_grid_config({key: get_meta("config_" + key)})
	# the arrays build their cubes as they stand up; wait until every named array has some (or give up)
	for i in 90:
		await get_tree().process_frame
		if not is_inside_tree(): return
		if _cubes().size() > 0 and _all_targets_built(): break
	_stand()

func _floor_root() -> Node:
	return get_parent().get_parent() if get_parent() != null else null

func _targets() -> Array:
	var out: Array = []
	var root := _floor_root()
	if root == null: return out
	for id in targets.split(",", false):
		var m := root.get_node_or_null(NodePath(id.strip_edges()))
		if m != null: out.append(m)
	return out

func _all_targets_built() -> bool:
	for m in _targets():
		if not (m as Node).find_children("*", "Node3D", true, false).any(func(n): return n.get_script() != null and n.get_script().resource_path == CUBE_SCRIPT): return false
	return true

func _cubes() -> Array:
	var out: Array = []
	for m in _targets():
		for n in (m as Node).find_children("*", "Node3D", true, false):
			if n.get_script() != null and n.get_script().resource_path == CUBE_SCRIPT and not bool(n.get("has_been_collected")): out.append(n)
	return out

## Each cube: its body's bottom measured now (the mesh moves with the cube), the surface found under it by a ray past
## the cube and the cones already stood, a cone there, and the cube lifted onto its tip.
func _stand() -> void:
	var space := get_world_3d().direct_space_state
	for cube in _cubes():
		var mesh: MeshInstance3D = cube.find_child("CubeBaseMesh", true, false)
		if mesh == null: continue
		var bottom_off: float = (mesh.global_transform * mesh.get_aabb()).position.y - cube.global_position.y
		var rest_y: float = float(cube.get("original_y")) if cube.get("original_y") != null else cube.global_position.y
		var from := Vector3(cube.global_position.x, rest_y + bottom_off + .05, cube.global_position.z)
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 6.0, 1)
		q.exclude = cones.map(func(c): return (c.get_node("Body") as CollisionObject3D).get_rid())
		var hit := space.intersect_ray(q)
		if hit.is_empty(): continue
		var cone: Node3D = Cone.new()
		cone.style = style;cone.height = height;cone.base = base;cone.body = "static"
		cone.name = "Cone_%d" % cones.size()
		add_child(cone);cone.global_position = hit.position
		cones.append(cone)
		# seated: the bob stopped, the spin kept, its body's bottom on the tip
		var seat_y: float = hit.position.y + height - bottom_off + .002
		cube.set("bob_height", 0.0)
		if cube.get("original_y") != null: cube.set("original_y", seat_y)
		cube.global_position.y = seat_y
		seated.append(cube)
	print("[cone_stands] %d cones under the cubes of %s" % [cones.size(), targets])
