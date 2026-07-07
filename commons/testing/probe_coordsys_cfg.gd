extends SceneTree

## Directly test CoordinateSystem3M.apply_grid_config the way the grid calls
## it (after _ready), with the exact Point One token configs. Checks whether
## display_scale, axis_length, and tick_step:0.0 actually take — and whether
## the axes REBUILD without ticks (apply_grid_config currently only sets the
## var, it doesn't re-run create_axis, so ticks built in _ready may persist).
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_coordsys_cfg.gd

const CS := "res://algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _count_ticks(node: Node) -> int:
	var n := 0
	if node.name.to_lower().find("tick") != -1:
		n += 1
	for c in node.get_children():
		n += _count_ticks(c)
	return n


func _run() -> void:
	var world := Node3D.new()
	get_root().add_child(world)
	var c: Node3D = load(CS).instantiate()
	world.add_child(c)
	for i in range(10):
		await process_frame
	print("[cfg] after _ready: tick_step=%s scale=%s ticks=%d" %
		[c.get("tick_step"), c.scale, _count_ticks(c)])

	# Apply the exact Point One config.
	c.call("apply_grid_config", {"display_scale": 6.0, "axis_length": 6.0, "tick_step": 0.0})
	for i in range(10):
		await process_frame
	print("[cfg] after apply_grid_config(display_scale:6, tick_step:0):")
	print("[cfg]   tick_step=%s scale=%s axis_length=%s ticks=%d" %
		[c.get("tick_step"), c.scale, c.get("axis_length"), _count_ticks(c)])
	print("[cfg] (if ticks>0 here, apply_grid_config doesn't rebuild axes — bug)")
	quit(0)
