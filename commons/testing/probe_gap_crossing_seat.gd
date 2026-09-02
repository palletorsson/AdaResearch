extends SceneTree
## THE GAP DOOR SEATS ITS CROSSING (2026-09-02, Palle: "fix the seat on the gap
## crossing too").
##
## The endless museum has two doors that build the same transport scenes.
## _stamp_utility has laid every body's collider top flush with the deck since
## 2026-08-25; _stamp_gaps, which builds the crossing for a pearl's hollow,
## never did — so a cube meant to fill a hole stood with its top half a metre
## proud of the floor you step off onto, and the thing that was supposed to BE
## the crossing made a step of itself.
##
## The museum node is created from its script rather than its scene: _ready is
## what boots a museum, and this probe wants the two functions, not a walk.
##
##   1  _spec_lift splits a trailing #lift: off a crossing spec, and leaves a
##      spec without one alone
##   2  a transport cube dropped at deck level stands PROUD: its collider top is
##      above the deck, which is the fault being fixed
##   3  _gap_seat lays that top on the deck, and moves the cube's cached start
##      and target with it, so the ride does not undo the seat on its first tick
##   4  #lift:1.0 seats the same cube one metre higher, the museum's own
##      extension to the grid's grammar

const MUSEUM := "res://commons/scenes/endless_museum.gd"
const CUBE := "res://commons/scenes/mapobjects/transport_cube.tscn"

var _fails := 0
var _done := false
var _museum: Node3D = null
var _seg: Node3D = null
var _plain: Node3D = null
var _lifted: Node3D = null

func collider_top(node: Node3D) -> float:
	var box := AABB()
	var first := true
	for pb_v in node.find_children("*", "PhysicsBody3D", true, false):
		for cs_v in (pb_v as Node).find_children("*", "CollisionShape3D", true, false):
			var cs := cs_v as CollisionShape3D
			if cs.shape == null or cs.disabled:
				continue
			var ab: AABB = cs.global_transform * cs.shape.get_debug_mesh().get_aabb()
			box = ab if first else box.merge(ab)
			first = false
	if first:
		return NAN
	return box.position.y + box.size.y

func _init() -> void:
	var fails := 0
	var script: GDScript = load(MUSEUM)
	if script == null:
		print("FAIL cannot load %s" % MUSEUM); _fails = 1; return
	_museum = script.new() as Node3D          # the object, not a booted museum

	# 1. the lift suffix, read once for both doors
	var bare: Dictionary = _museum._spec_lift("tc:4:z:auto")
	var raised: Dictionary = _museum._spec_lift("tc:4:z:auto#lift:1.0")
	print("1  'tc:4:z:auto' -> spec %s lift %.2f; 'tc:4:z:auto#lift:1.0' -> spec %s lift %.2f"
		% [bare["spec"], bare["lift"], raised["spec"], raised["lift"]])
	if String(bare["spec"]) != "tc:4:z:auto" or float(bare["lift"]) != 0.0 \
		or String(raised["spec"]) != "tc:4:z:auto" or absf(float(raised["lift"]) - 1.0) > 1e-6:
		print("   FAIL the lift suffix is not read as the utility door reads it"); fails += 1

	# stage two cubes the way _stamp_gaps stages one: local y 0, inside a segment
	_seg = Node3D.new()
	_seg.name = "Segment"
	root.add_child(_seg)
	var scene: PackedScene = load(CUBE)
	for pair in [["Crossing_plain", 4.0], ["Crossing_lifted", 8.0]]:
		var c: Node3D = scene.instantiate() as Node3D
		c.name = String(pair[0])
		c.set("move_distance", 4.0)
		c.set("move_direction", Vector3(0, 0, 1))
		c.position = Vector3(float(pair[1]), 0.0, 3.0)
		_seg.add_child(c)
		if c.name == "Crossing_plain":
			_plain = c
		else:
			_lifted = c
	_fails = fails


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true

	# 2. as built, the crossing stands proud of the deck
	var deck := 0.0
	var top_before := collider_top(_plain)
	print("2  a crossing dropped at deck level: collider top %.3f, deck %.2f (proud by %.3f)"
		% [top_before, deck, top_before - deck])
	if is_nan(top_before) or top_before <= deck + 0.05:
		print("   FAIL the crossing was already flush, so this probe cannot see the fault it was written for")
		_fails += 1

	# 3. the seat lays that top on the deck, and takes the cube's memory with it
	var y_before: float = _plain.position.y
	var init_before: Vector3 = _plain.get("initial_position")
	_museum._gap_seat(_plain, deck)
	var top_after := collider_top(_plain)
	var init_after: Vector3 = _plain.get("initial_position")
	var targ_after: Vector3 = _plain.get("target_position")
	var moved: float = y_before - _plain.position.y
	var memory_moved: float = init_before.y - init_after.y
	print("3  seated: y %.3f -> %.3f (moved %.3f), collider top now %.3f; cached start moved %.3f, target %s"
		% [y_before, _plain.position.y, moved, top_after, memory_moved, targ_after])
	if absf(top_after - deck) > 0.01:
		print("   FAIL the collider top is not on the deck"); _fails += 1
	if absf(memory_moved - moved) > 0.01:
		print("   FAIL the cube's cached start did not move with its body — the first tick of the ride would undo the seat")
		_fails += 1
	if absf((targ_after - init_after).length() - 4.0) > 0.01:
		print("   FAIL the seat changed how far the ride travels"); _fails += 1

	# 4. the museum's own extension: #lift raises the seated top
	_museum._gap_seat(_lifted, 1.0)
	var top_lifted := collider_top(_lifted)
	print("4  the same crossing with #lift:1.0: collider top %.3f (asked 1.00)" % top_lifted)
	if absf(top_lifted - 1.0) > 0.01:
		print("   FAIL lift did not raise the seated crossing"); _fails += 1

	print("")
	print("PROBE %s" % ("OK" if _fails == 0 else "FAILED %d" % _fails))
	quit(_fails)
	return true
