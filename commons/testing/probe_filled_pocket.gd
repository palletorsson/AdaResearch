extends SceneTree
## IS THE POCKET DISCOVERED, AND DOES ONE DOOR DRAIN IT?
##
## The pocket must come from the flood fill, not from the layout: open and
## u_bend have zero pocket although u_bend LOOKS like a trap; ring seals nine
## cells of perfectly good floor; one door cell drains all nine; split kills
## the route entirely and a mid-wall door restores it. The u_bend detour must
## cost more steps than the open field, or the walls changed nothing.

const SCENE := "res://commons/artifacts/filled_pocket/filled_pocket.tscn"


func _mk(wall: String, door: String) -> Node:
	var n = load(SCENE).instantiate()
	n.set("wall", wall)
	n.set("door", door)
	get_root().add_child(n)
	return n


func _count(n: Node, cls: String) -> int:
	var k := 0
	if n.get_class() == cls:
		k += 1
	for c in n.get_children():
		k += _count(c, cls)
	return k


func _init() -> void:
	var fails := 0

	var a = _mk("open", "sealed")
	await process_frame
	print("1  open/sealed    route=%d pocket=%d   (route>0, pocket 0)"
		% [a.route_steps(), a.pocket_cells()])
	if a.route_steps() <= 0 or a.pocket_cells() != 0:
		fails += 1
		print("   FAIL the open field should reach everything")

	var b = _mk("u_bend", "sealed")
	await process_frame
	print("2  u_bend/sealed  route=%d pocket=%d   (route > open's %d, pocket 0)"
		% [b.route_steps(), b.pocket_cells(), a.route_steps()])
	if b.pocket_cells() != 0:
		fails += 1
		print("   FAIL a U with an open mouth sealed something -- the flood is wrong")
	if b.route_steps() <= a.route_steps():
		fails += 1
		print("   FAIL the trap cost nothing; the detour must be longer than the field")

	var c = _mk("ring", "sealed")
	await process_frame
	print("3  ring/sealed    route=%d pocket=%d   (route>0, pocket 9)"
		% [c.route_steps(), c.pocket_cells()])
	if c.route_steps() <= 0 or c.pocket_cells() != 9:
		fails += 1
		print("   FAIL the 3x3 interior of a closed 5x5 ring is nine cells, all sealed")

	var d = _mk("ring", "single")
	await process_frame
	print("4  ring/single    route=%d pocket=%d   (pocket 0 -- one door drains it)"
		% [d.route_steps(), d.pocket_cells()])
	if d.pocket_cells() != 0:
		fails += 1
		print("   FAIL one opened cell must reconnect the whole pocket")

	var e = _mk("split", "sealed")
	await process_frame
	print("5  split/sealed   route=%d unreached=%d   (route -1, something beyond reach)"
		% [e.route_steps(), e.pocket_cells()])
	if e.route_steps() != -1 or e.pocket_cells() == 0:
		fails += 1
		print("   FAIL a full wall must kill the route and strand the far side")

	var f = _mk("split", "single")
	await process_frame
	print("6  split/single   route=%d pocket=%d   (route>0 through the door, pocket 0)"
		% [f.route_steps(), f.pocket_cells()])
	if f.route_steps() <= 0 or f.pocket_cells() != 0:
		fails += 1
		print("   FAIL the mid-wall door must reconnect x to y")

	var steals := 0
	for cls in ["Camera3D", "WorldEnvironment", "CanvasLayer", "DirectionalLight3D"]:
		steals += _count(a, cls)
	print("7  steals = %d   (must be 0)" % steals)
	if steals > 0:
		fails += 1

	print("probe_filled_pocket: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)
