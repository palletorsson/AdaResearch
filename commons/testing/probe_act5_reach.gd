# probe_act5_reach.gd — can a visitor standing on the deck actually be in the field?
#
# Vectors_Act5_ForceAsPlace is named for a crossing you make by setting a force
# field and stepping into it. Two things made that impossible and neither was
# visible in any single file:
#
#   1. the grid grounds a body by its lowest geometry, and this cube's corner
#      spheres hang 5 cm below its origin - so grounding lifted the CONTAINMENT
#      volume, which starts at the origin, 5 cm clear of the deck
#   2. _point_inside tested absf(local.y) < h, which excludes a body standing on
#      the volume's own base by exactly zero
#
# Fixed by declaring auto_ground false (the artifact grounds itself: its volume
# runs from its origin upward) and by making the vertical test inclusive at the
# base. This probe asserts the fix from the engine rather than from arithmetic.
#
#   godot --path . --xr-mode off --no-window \
#     --script res://commons/testing/probe_act5_reach.gd

extends SceneTree

const SCENE := "res://commons/artifacts/force_field_zone/force_field_zone.tscn"
const DECK_Y := 0.5           # surface_world_y(1) for a height-1 floor cell
const SETTLE := 0.6


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = ResourceLoader.load(SCENE)
	if packed == null:
		print("PROBE FAIL: cannot load %s" % SCENE)
		quit(1)
		return
	var zone: Node3D = packed.instantiate() as Node3D
	root.add_child(zone)
	await process_frame
	await process_frame
	await create_timer(SETTLE).timeout

	var size: float = float(zone.get("size"))
	print("zone size = %.2f m" % size)

	var fails: int = 0

	# --- what the grid would do, both ways ---------------------------------
	var box := _merged_aabb(zone)
	var lowest: float = box.position.y
	print("lowest geometry sits %.3f m below the origin" % (-lowest))
	if absf(lowest) < 0.001:
		print("  note: nothing hangs below the origin, so grounding would be harmless")

	# GROUNDED (the old behaviour): origin lifted by -min_y
	var grounded_origin: float = DECK_Y + (-lowest)
	# SELF-GROUNDED (auto_ground false): origin sits on the deck
	var honest_origin: float = DECK_Y

	for pair in [[grounded_origin, "auto_ground TRUE  (the old placement)"],
				 [honest_origin, "auto_ground FALSE (as now declared)"]]:
		var oy: float = pair[0]
		zone.global_position = Vector3(0.0, oy, 0.0)
		await process_frame
		var feet := Vector3(0.0, DECK_Y, 0.0)
		var inside: bool = zone.call("_point_inside", feet)
		print("%-38s origin y %.2f  feet y %.2f  ->  %s"
			% [pair[1], oy, DECK_Y, "INSIDE" if inside else "OUTSIDE"])
		if oy == honest_origin and not inside:
			print("  PROBE FAIL: with the artifact grounding itself, a body standing on")
			print("              the deck is STILL outside its own field.")
			fails += 1

	# --- and the margins, so the fix is not a knife edge -------------------
	zone.global_position = Vector3(0.0, honest_origin, 0.0)
	await process_frame
	print("")
	print("clearance around the base, origin at the deck:")
	for dy in [-0.05, -0.02, -0.01, 0.0, 0.01, 0.10, 1.00, 4.99, 5.01]:
		var p := Vector3(0.0, DECK_Y + dy, 0.0)
		print("   feet %+.2f m from the deck : %s"
			% [dy, "in" if zone.call("_point_inside", p) else "out"])

	# a body 1 cm below the deck (a controller resting with a gap) must be in
	if not zone.call("_point_inside", Vector3(0.0, DECK_Y - 0.01, 0.0)):
		print("PROBE FAIL: 1 cm below the deck reads as outside; the tolerance is too tight")
		fails += 1
	# and a body a metre above the top must not be
	if zone.call("_point_inside", Vector3(0.0, DECK_Y + size + 1.0, 0.0)):
		print("PROBE FAIL: a metre above the ceiling reads as inside")
		fails += 1
	# the sides stay strict
	if zone.call("_point_inside", Vector3(size, DECK_Y + 1.0, 0.0)):
		print("PROBE FAIL: a body a full width to the side reads as inside")
		fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(0 if fails == 0 else 1)


func _merged_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is VisualInstance3D):
			continue
		var vi := n as VisualInstance3D
		if not vi.is_visible_in_tree() or vi.top_level:
			continue
		var local: AABB = vi.get_aabb()
		if local.size.length_squared() < 0.0001:
			continue
		var world: AABB = vi.global_transform * local
		if first:
			box = world
			first = false
		else:
			box = box.merge(world)
	# express relative to the node's own origin
	box.position -= node.global_position
	return box
