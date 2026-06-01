extends SceneTree

## Verify klee_walking_point rests ON the floor: with the artifact origin at
## floor level (y=0), every trail/head point's world Y must be >= 0 (nothing
## sinks below the floor). Reports the min Y before/after the lift.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_klee_floor.gd

const KLEE := "res://commons/primitives/klee_walking_point/klee_walking_point.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	get_root().add_child(world)
	var node: Node3D = load(KLEE).instantiate()
	# Origin at floor level, like the map places it.
	node.global_position = Vector3.ZERO
	world.add_child(node)
	for i in range(10):
		await process_frame

	# Lowest world Y across all child mesh points.
	var min_y: float = INF
	var max_y: float = -INF
	for c in node.get_children():
		if c is MeshInstance3D:
			var y: float = (c as Node3D).global_position.y
			min_y = minf(min_y, y)
			max_y = maxf(max_y, y)
	print("[klee] lift_to_floor=%s  trail/head world Y: min=%.3f max=%.3f" %
		[node.get("lift_to_floor"), min_y, max_y])
	var ok: bool = min_y >= -0.001
	print("[klee] RESULT: %s (min Y must be >= 0 — nothing below the floor)" %
		("PASS" if ok else "FAIL — still sinks below floor"))
	quit(0 if ok else 1)
