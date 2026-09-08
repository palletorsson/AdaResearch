extends SceneTree

## Can the desktop crosshair actually GRAB this artifact where you can SEE it?
##
## 2026-09-08, Palle, with a screenshot of the crosshair dead centre on the pink
## gun in its cabinet: "when clicking on the gun nothing happens".
##
## DesktopInteractionPointer._find_grabbable casts ONE ray on GRAB_MASK
## (layers 3/18/19) and takes the first body it hits. So a pickable is grabbable
## exactly where its COLLISION SHAPE is — never where its mesh is. An artifact
## that inherits a base pickable's collider and then builds a bigger body around
## it (pink_gun hides grab_stick's cube and grows rings and a muzzle past it)
## looks grabbable across its whole silhouette and answers on a fraction of it.
##
## No headset, no map, no museum: instance the scene, put it in a physics world,
## and fire the pointer's own ray at a grid of points across the mesh AABB.
## Prints the collider box, the visible box, and the HIT FRACTION — the share of
## the silhouette that answers a click.
##
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_grab_reach.gd -- \
##     --scene=res://commons/artifacts/pink_gun/pink_gun.tscn

const GRAB_MASK := 393220   # DesktopInteractionPointer.GRAB_MASK: layers 3, 18, 19

var _scene: String = "res://commons/artifacts/pink_gun/pink_gun.tscn"
var _rot_y: float = 0.0
var _config: Dictionary = {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			_scene = a.substr(8)
		elif a.begins_with("--rot-y="):
			_rot_y = float(a.substr(8))
		elif a.begins_with("--config="):
			# k=v,k=v — applied via apply_grid_config, like a map token's #tail
			for pair in a.substr(9).split(",", false):
				var kv: PackedStringArray = pair.split("=", false, 1)
				if kv.size() == 2:
					_config[kv[0]] = kv[1]
	# deferred: change_scene/autoloads are not up during _init
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(_scene):
		print("probe: no scene at %s" % _scene)
		quit(2)
		return
	var holder := Node3D.new()
	root.add_child(holder)
	var n: Node3D = (load(_scene) as PackedScene).instantiate() as Node3D
	holder.add_child(n)
	if not _config.is_empty() and n.has_method("apply_grid_config"):
		n.call("apply_grid_config", _config)
	if _rot_y != 0.0:
		n.rotation_degrees = Vector3(0, _rot_y, 0)
	await physics_frame
	await physics_frame
	await create_timer(0.4).timeout   # let _ready/_rebuild finish

	# ── the body the ray must hit ────────────────────────────────────────
	var rb: RigidBody3D = null
	for x in _all(n):
		if x is RigidBody3D:
			rb = x
			break
	if rb == null:
		print("probe: no RigidBody3D — nothing for the grab ray to hit at all")
		quit(1)
		return
	var on_mask: bool = (rb.collision_layer & GRAB_MASK) != 0
	print("probe: body=%s layer=%d on_grab_mask=%s freeze=%s" % [rb.name, rb.collision_layer, on_mask, rb.freeze])

	# ── collider extent vs mesh extent, both in world space ──────────────
	var col := AABB()
	var got_col := false
	for x in _all(rb):
		if x is CollisionShape3D and (x as CollisionShape3D).shape != null:
			var cs := x as CollisionShape3D
			var box: AABB = cs.shape.get_debug_mesh().get_aabb()
			var wb: AABB = cs.global_transform * box
			col = wb if not got_col else col.merge(wb)
			got_col = true
			print("probe:   shape=%s %s size=%s" % [cs.name, cs.shape.get_class(), str(box.size)])
	var vis := AABB()
	var got_vis := false
	for x in _all(n):
		if x is MeshInstance3D and (x as MeshInstance3D).mesh != null and (x as MeshInstance3D).is_visible_in_tree():
			var mi := x as MeshInstance3D
			var wb2: AABB = mi.global_transform * mi.get_aabb()
			vis = wb2 if not got_vis else vis.merge(wb2)
			got_vis = true
	if not got_col or not got_vis:
		print("probe: collider=%s mesh=%s — cannot compare" % [got_col, got_vis])
		quit(1)
		return
	print("probe: COLLIDER box size=%s centre=%s" % [str(col.size), str(col.get_center())])
	print("probe: VISIBLE  box size=%s centre=%s" % [str(vis.size), str(vis.get_center())])
	var cv: float = col.size.x * col.size.y * col.size.z
	var vv: float = vis.size.x * vis.size.y * vis.size.z
	print("probe: collider is %.1f%% of the visible volume" % (100.0 * cv / maxf(vv, 1e-9)))

	# ── the pointer's own ray, fired at the silhouette from the front ────
	# A visitor faces the gun and puts the crosshair somewhere on it. Sample the
	# mesh AABB's face and ask: does the grab ray find a body?
	var space := holder.get_world_3d().direct_space_state
	var steps := 11
	var hits := 0
	var total := 0
	var miss_rows: Array[String] = []
	for iy in range(steps):
		var row := ""
		for ix in range(steps):
			var fx: float = float(ix) / float(steps - 1)
			var fy: float = float(iy) / float(steps - 1)
			var target := Vector3(
				vis.position.x + vis.size.x * fx,
				vis.position.y + vis.size.y * (1.0 - fy),
				vis.get_center().z)
			var from := target + Vector3(0, 0, vis.size.z * 0.5 + 1.0)
			var q := PhysicsRayQueryParameters3D.create(from, target - Vector3(0, 0, 1.0), GRAB_MASK)
			q.collide_with_bodies = true
			q.collide_with_areas = false
			var hit := space.intersect_ray(q)
			total += 1
			if hit.is_empty():
				row += "."
			else:
				row += "#"
				hits += 1
		miss_rows.append(row)
	print("probe: GRABBABLE SILHOUETTE, seen from the front (# = a click here grabs, . = nothing):")
	for r in miss_rows:
		print("probe:   " + r)
	print("probe: %d of %d sample points answer the grab ray (%.0f%%)" % [hits, total, 100.0 * float(hits) / float(total)])
	quit(0)


func _all(x: Node) -> Array:
	var out: Array = [x]
	for c in x.get_children():
		out.append_array(_all(c))
	return out
