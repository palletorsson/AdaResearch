extends SceneTree

## Find the actual walkable FLOOR-TOP world Y at the you_are_here cell in the
## real map, by raycasting straight down from above the decal. That tells us
## whether y=0.5 (where the decal sits) is on the floor or floating above it.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/probe_floor_top.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file(MAP_CATALOG)
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	catalog.call("load_map_fresh", "Point_One")
	for i in range(180):
		await process_frame

	# Raycast down at the decal's world XZ (3, 6) from y=10.
	var space := catalog.get_world_3d().direct_space_state
	var from := Vector3(3.0, 10.0, 6.0)
	var to := Vector3(3.0, -10.0, 6.0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		print("[top] no floor collider hit at (3,*,6) — decal cell may be VOID/hidden")
	else:
		print("[top] floor-top world Y at decal cell (3,*,6) = %.3f" % hit.position.y)
		print("[top] decal is at y=0.512 → gap above floor = %.3f" % (0.512 - hit.position.y))
	quit(0)
