## probe_biome_object.gd — the biome object builds every kingdom by ecology, on its own
## ground, the same for the same seed.
##
## Checks: three DNAs build; each has water, mineral, fungus, flora, fauna and cover; every
## living cell is inside the footprint; the pool sits at the water level and the crystals
## on the surface; a wetter DNA grows more fungus and more cover than a drier one; the same
## seed gives the same counts twice and a different seed does not; the record is written;
## a build stays under two seconds. Gen 1: the floor under the water cells is flat, the disc's
## top stands above the terrain at the basin centre and all round it at half the disc's
## radius, the reeds' feet stand on the shore, and the ground carries paint layers. Gen 2: the
## tree nearest the water is at least as old as the farthest; every path mat's stored position
## lies within 0.5 m of the segment basin centre -> trunk and inside the footprint; the last
## mat of every path stands within 0.5 m of its trunk; a body stands at every stored path
## position (the dispatcher read _pos); the ground carries at least four paint layers. Gen 3:
## the tree nearest the water has a node scale >= the farthest tree's and >= 1.5; every tree's
## scaled canopy (the AABB of its mesh children through the root's scale) stays inside the
## footprint, and so does every crystal shard; no mineral cell lies within 2.5 cells of a water
## cell or on the outer ring; the
## state records ms_tree / ms_flower / ms_fungus / ms_creature and their sum is under the build.
## Gen 4 (a fourth DNA, s17_m60_r60_w90, joins: the one whose unclamped succession gives inten
## 5): the ground's LAST paint layer is the shade, with at least one cell wherever a tree
## stands, every cell dry land at 0.02 < v <= 0.85 and the oldest trunk's own cell at v >= 0.5;
## no flower cell within 0.85 rs of any trunk (rs = 0.6·(0.6 + 0.2·inten)·k); in the wettest
## world at least one flower on the oldest tree's drip line (0.85..1.6 rs); no tree past inten 4.
## Gen 5: every world with a mineral cell has scree shards, and each shard's surface height is
## at or below its cluster's surface height + 0.05 (the scree runs DOWN); no shard stands on a
## water cell or outside the footprint (its position and its mesh's AABB), and every shard
## stands on the ground (its centre between the surface and one shard-height above it); the
## scree count recorded is the shards standing; every trail heads toward the water's side (the
## last shard's displacement from its cluster has a positive dot with the basin's direction —
## the bare gradient rule fails this on 11 of 16 clusters); the ground carries a "rock" paint
## layer before the shade with a painted cell at every cluster's cell; no mineral cell is
## within 3.0 cells of a water cell.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_biome_object.gd
extends SceneTree

const OBJ := preload("res://commons/artifacts/biome_object/biome_object.gd")

var _checks := 0
var _fails := 0
var _root: Node3D
var _slot := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("  FAIL  ", msg)


func _init() -> void:
	_root = Node3D.new()
	get_root().add_child(_root)
	_run()


func _run() -> void:
	await process_frame
	var a = await _grow(7, 0.5, 0.5, 0.6)
	var b = await _grow(11, 0.85, 0.3, 0.7)
	var c = await _grow(13, 0.25, 0.85, 0.4)
	var d4 = await _grow(17, 0.6, 0.6, 0.9)
	var wettest = a
	for o in [b, c, d4]:
		if float(o.moisture) > float(wettest.moisture):
			wettest = o
	for o in [a, b, c, d4]:
		var st: Dictionary = o.get_state()
		var cnt: Dictionary = st["counts"]
		var lab := String(st["label"])
		_check(int(cnt["water"]) > 0, "%s: water" % lab)
		_check(int(cnt["mineral"]) > 0, "%s: mineral" % lab)
		_check(int(cnt["fungus"]) + int(cnt["fungus_path"]) > 0, "%s: fungus" % lab)
		_check(int(cnt["tree"]) > 0 and int(cnt["flower"]) > 0, "%s: trees and flowers" % lab)
		_check(int(cnt["creature"]) > 0, "%s: creatures" % lab)
		_check(int(cnt["cover"]) > 30, "%s: cover (%d)" % [lab, int(cnt["cover"])])
		_check(int(cnt["connections"]) > 0, "%s: the network touches the wood (%d)" % [lab, int(cnt["connections"])])
		_check((st["kingdoms_present"] as Array).size() == 6, "%s: six layers present %s" % [lab, str(st["kingdoms_present"])])
		_check(int(st["build_ms"]) < 2000, "%s: built in %d ms" % [lab, int(st["build_ms"])])
		var half: float = float(o.size) * 0.5 + 0.01
		var inside := true
		var on_surface := true
		for ch in o._patch.get_children():
			if ch is Node3D and ch.name != "Ground" and ch.name != "Dispatcher" and not String(ch.name).begins_with("Cover"):
				var p: Vector3 = ch.position
				if absf(p.x) > half or absf(p.z) > half:
					if inside:
						print("    outside: %s at (%.2f, %.2f, %.2f)" % [ch.name, p.x, p.y, p.z])
					inside = false
				if String(ch.name).begins_with("Crystal") and absf(p.y - o._h_at(p.x, p.z)) > 0.05:
					on_surface = false
		_check(inside, "%s: every body inside the footprint" % lab)
		_check(on_surface, "%s: crystals stand on the surface" % lab)
		var pool: Node3D = o._patch.get_node_or_null("Pool")
		_check(pool != null and absf(pool.position.y - o._water_level()) < 0.001, "%s: the pool sits at the water level" % lab)
		# gen 1: a flat floor under every water cell
		var floor_flat := true
		for wk in o._water.keys():
			if o._h_cell(wk.x, wk.y) > 0.02 * o._max_h + 0.0005:
				floor_flat = false
		_check(floor_flat, "%s: a flat floor under the water" % lab)
		# gen 1: the disc's top at or above the terrain at the basin centre and at 0.5 r (8 bearings)
		var disc: MeshInstance3D = (pool.get_node_or_null("Disc") as MeshInstance3D) if pool != null else null
		var above := disc != null
		if disc != null:
			var cm: CylinderMesh = disc.mesh as CylinderMesh
			var top: float = pool.position.y + disc.position.y + cm.height * 0.5
			var half_r: float = cm.top_radius * 0.5
			var worst: float = o._h_at(pool.position.x, pool.position.z)
			for k in range(8):
				var ang: float = TAU * float(k) / 8.0
				worst = maxf(worst, o._h_at(pool.position.x + cos(ang) * half_r, pool.position.z + sin(ang) * half_r))
			above = top >= worst
			if not above:
				print("    disc top %.3f under the terrain at %.3f" % [top, worst])
		_check(above, "%s: the water stands above its floor at the centre and at half the disc" % lab)
		# gen 1: the reeds' feet on the shore
		var reeds_on_shore := true
		var reeds_inside := true
		if pool != null:
			for rd in pool.get_children():
				if String(rd.name).begins_with("Reed") and rd is MeshInstance3D:
					var rcm: CylinderMesh = rd.mesh as CylinderMesh
					var foot: float = pool.position.y + rd.position.y - rcm.height * 0.5
					var ground_y: float = o._h_at(pool.position.x + rd.position.x, pool.position.z + rd.position.z)
					if absf(foot - ground_y) > 0.02:
						reeds_on_shore = false
					if absf(pool.position.x + rd.position.x) > half or absf(pool.position.z + rd.position.z) > half:
						reeds_inside = false
		_check(reeds_on_shore, "%s: the reeds stand on the shore" % lab)
		_check(reeds_inside, "%s: the reeds stand inside the footprint" % lab)
		# gen 1: the moisture is painted on the ground
		var ground = o._patch.get_node_or_null("Ground")
		_check(ground != null and (ground._paint_layers as Array).size() > 0, "%s: the ground carries paint layers" % lab)
		_check(int(cnt.get("paint", 0)) > 0, "%s: painted cells (%d)" % [lab, int(cnt.get("paint", 0))])
		# ... and the paint reached the composed texture: count its covered pixels
		var painted_px := -1
		if ground != null and ground.mesh_instance != null and ground.mesh_instance.material_override is ShaderMaterial:
			var tex = (ground.mesh_instance.material_override as ShaderMaterial).get_shader_parameter("paint_tex")
			if tex is Texture2D:
				var img: Image = (tex as Texture2D).get_image()
				if img != null:
					painted_px = 0
					for py in range(img.get_height()):
						for px in range(img.get_width()):
							if img.get_pixel(px, py).a > 0.001:
								painted_px += 1
		_check(painted_px > 0, "%s: the paint texture carries the moisture (%d px covered)" % [lab, painted_px])
		# gen 2 (a): succession — the tree nearest the water is at least as old as the farthest;
		# nearest and farthest found here by _water_dist, not read off the sorted list
		var near_t := Vector2i(-1, -1)
		var far_t := Vector2i(-1, -1)
		var near_d := 999.0
		var far_d := -1.0
		for t in o._trees:
			var d: float = o._water_dist(t.x, t.y)
			if d < near_d:
				near_d = d
				near_t = t
			if d > far_d:
				far_d = d
				far_t = t
		var near_i: int = int(o._cells[near_t]["inten"]) if o._cells.has(near_t) else -1
		var far_i: int = int(o._cells[far_t]["inten"]) if o._cells.has(far_t) else 99
		_check(o._trees.size() > 0 and near_i >= far_i, "%s: the shore tree is at least as old as the frontier tree (inten %d at %.1f m vs %d at %.1f m)" % [lab, near_i, near_d, far_i, far_d])
		_check(o._trees.size() > 0 and o._trees[0] == near_t, "%s: _trees[0] is the shore tree" % lab)
		# gen 2 (b): every path mat within 0.5 m of the segment basin centre -> trunk, inside the footprint
		# gen 2 (c): the last mat of every path within 0.5 m of its trunk
		var basin_w: Vector2 = o._basin_c - Vector2(float(o.size), float(o.size)) * 0.5
		var on_line := true
		var last_touch := true
		var n_path := 0
		var reached := 0
		for t in o._paths.keys():
			var path: Array = o._paths[t]
			if path.is_empty():
				continue
			reached += 1
			var trunk: Vector2 = o._pos[t]
			for k in path:
				var p: Vector2 = o._pos[k]
				n_path += 1
				var dseg: float = _seg_dist(p, basin_w, trunk)
				if dseg > 0.5 + 0.001 or absf(p.x) > half or absf(p.y) > half:
					if on_line:
						print("    off the line: mat %s at (%.2f, %.2f), %.2f m from the segment to tree %s" % [str(k), p.x, p.y, dseg, str(t)])
					on_line = false
			var lp: Vector2 = o._pos[path.back()]
			if lp.distance_to(trunk) > 0.5:
				if last_touch:
					print("    short of the trunk: last mat %.2f m from tree %s" % [lp.distance_to(trunk), str(t)])
				last_touch = false
		print("    [probe_biome_object] %s: paths reach %d of %d trees with %d mats" % [lab, reached, o._trees.size(), n_path])
		_check(on_line, "%s: every path mat stands on the line inside the footprint (%d mats)" % [lab, n_path])
		_check(reached == o._trees.size() and last_touch, "%s: every tree is reached and the last mat touches the trunk (%d of %d trees reached)" % [lab, reached, o._trees.size()])
		_check(int(cnt["fungus_path"]) == n_path, "%s: the path count is the mats stored (%d vs %d)" % [lab, int(cnt["fungus_path"]), n_path])
		# ... and the handoff: a body of the patch stands at every stored path position
		var standing := true
		for t in o._paths.keys():
			for k in o._paths[t]:
				var p: Vector2 = o._pos[k]
				var found := false
				for ch in o._patch.get_children():
					if ch is Node3D and absf(ch.position.x - p.x) < 0.02 and absf(ch.position.z - p.y) < 0.02:
						found = true
						break
				if not found:
					if standing:
						print("    no body at stored path position %s (%.2f, %.2f)" % [str(k), p.x, p.y])
					standing = false
		_check(standing, "%s: a body stands at every stored path position" % lab)
		# gen 2 (d): four paint layers — dry, wet, shore, silt
		_check(ground != null and (ground._paint_layers as Array).size() >= 4, "%s: the ground carries at least four paint layers (%d)" % [lab, (ground._paint_layers as Array).size() if ground != null else 0])
		# gen 3 (a): the shore tree is the biggest body — its NODE scale (after the footprint cap)
		# is at least the frontier tree's and at least 1.5
		var near_n: Node3D = o._patch.get_node_or_null("PaintedTree_%d_%d" % [near_t.x, near_t.y]) as Node3D
		var far_n: Node3D = o._patch.get_node_or_null("PaintedTree_%d_%d" % [far_t.x, far_t.y]) as Node3D
		var near_k: float = near_n.scale.x if near_n != null else -1.0
		var far_k: float = far_n.scale.x if far_n != null else 99.0
		_check(near_n != null and far_n != null and near_k >= far_k and near_k >= 1.5, "%s: the shore tree is scaled %.2f, the frontier tree %.2f (shore >= frontier, shore >= 1.5)" % [lab, near_k, far_k])
		# gen 3 (b): every tree's scaled canopy inside the footprint — the AABB of each mesh child
		# (the merged branches; the leaves are a MultiMesh, which reads back identity headless)
		# carried into the patch frame through the root's transform, scale included
		var canopy_in := true
		var n_tree_nodes := 0
		var widest := 0.0
		for t in o._trees:
			var tn: Node3D = o._patch.get_node_or_null("PaintedTree_%d_%d" % [t.x, t.y]) as Node3D
			if tn == null:
				canopy_in = false
				continue
			n_tree_nodes += 1
			var stack: Array = [tn]
			while not stack.is_empty():
				var nd: Node = stack.pop_back()
				for ch2 in nd.get_children():
					stack.append(ch2)
					if ch2 is MeshInstance3D and (ch2 as MeshInstance3D).mesh != null and not ch2.is_queued_for_deletion():
						var rel: Transform3D = tn.global_transform.affine_inverse() * (ch2 as Node3D).global_transform
						var bb: AABB = (tn.transform * rel) * (ch2 as MeshInstance3D).mesh.get_aabb()
						widest = maxf(widest, maxf(maxf(absf(bb.position.x), absf(bb.end.x)), maxf(absf(bb.position.z), absf(bb.end.z))))
						if bb.position.x < -half or bb.end.x > half or bb.position.z < -half or bb.end.z > half:
							if canopy_in:
								print("    canopy out: %s scale %.2f spans x %.2f..%.2f z %.2f..%.2f" % [tn.name, tn.scale.x, bb.position.x, bb.end.x, bb.position.z, bb.end.z])
							canopy_in = false
		print("    [probe_biome_object] %s: shore tree x%.2f, frontier tree x%.2f, widest canopy reach %.2f m of %.2f" % [lab, near_k, far_k, widest, half])
		_check(canopy_in and n_tree_nodes == o._trees.size(), "%s: every scaled canopy stays inside the footprint (%d trees, widest reach %.2f m of %.2f)" % [lab, n_tree_nodes, widest, half])
		# gen 3: the grown spires too — every shard's AABB, through its holder, inside the footprint
		var shards_in := true
		var shard_reach := 0.0
		for ch in o._patch.get_children():
			if ch is Node3D and String(ch.name).begins_with("Crystal"):
				for sh in ch.get_children():
					if sh is MeshInstance3D and (sh as MeshInstance3D).mesh != null:
						var bb2: AABB = ((ch as Node3D).transform * (sh as Node3D).transform) * (sh as MeshInstance3D).mesh.get_aabb()
						shard_reach = maxf(shard_reach, maxf(maxf(absf(bb2.position.x), absf(bb2.end.x)), maxf(absf(bb2.position.z), absf(bb2.end.z))))
						if bb2.position.x < -half or bb2.end.x > half or bb2.position.z < -half or bb2.end.z > half:
							if shards_in:
								print("    shard out: %s spans x %.2f..%.2f z %.2f..%.2f" % [ch.name, bb2.position.x, bb2.end.x, bb2.position.z, bb2.end.z])
							shards_in = false
		_check(shards_in, "%s: every crystal shard stays inside the footprint (widest reach %.2f m of %.2f)" % [lab, shard_reach, half])
		# gen 3 (c): no mineral cell within 2.5 cells of a water cell, none on the outer ring
		var min_off := true
		for mk in o._cells.keys():
			if String(o._cells[mk]["kingdom"]) == "mineral":
				if o._water_dist(mk.x, mk.y) < 2.5 or mk.x < 1 or mk.y < 1 or mk.x > o.size - 2 or mk.y > o.size - 2:
					if min_off:
						print("    mineral %s at %.2f cells from the water" % [str(mk), o._water_dist(mk.x, mk.y)])
					min_off = false
		_check(min_off, "%s: every mineral cell is 2.5 cells from the water and off the outer ring (%d minerals)" % [lab, int(cnt["mineral"])])
		# gen 3 (d): the state records each kingdom's spawn time and their sum is under the build
		var ms_sum: int = 0
		var ms_all := true
		for mkey in ["ms_tree", "ms_flower", "ms_fungus", "ms_creature"]:
			if not cnt.has(mkey):
				ms_all = false
			else:
				ms_sum += int(cnt[mkey])
		_check(ms_all and ms_sum < int(st["build_ms"]), "%s: ms per kingdom recorded, sum %d under the build's %d" % [lab, ms_sum, int(st["build_ms"])])
		# gen 4 (a): the canopy casts a layer — the ground's LAST paint layer is named "shade",
		# with at least one cell wherever a tree stands, every cell dry land at 0.02 < v <= 0.85,
		# and the oldest tree's own cell at v >= 0.5 (its trunk is at most 0.42 m off the centre)
		var layers: Array = (ground._paint_layers as Array) if ground != null else []
		var shade: Dictionary = {}
		for ly in layers:
			if ly is Dictionary and String((ly as Dictionary).get("name", "")) == "shade":
				shade = ly
		var shade_last: bool = not layers.is_empty() and layers.back() is Dictionary and String((layers.back() as Dictionary).get("name", "")) == "shade"
		var shade_cells: Array = ((shade["brush"] as Dictionary)["cells"] as Array) if shade.has("brush") else []
		var shade_ok := true
		var v_trunk := 0.0
		for sc2 in shade_cells:
			var sk := Vector2i(int(sc2[0]), int(sc2[1]))
			var sv: float = float(sc2[2])
			if o._water.has(sk) or sv <= 0.02 or sv > 0.85 + 0.0001:
				if shade_ok:
					print("    shade cell %s v %.3f (water %s)" % [str(sk), sv, str(o._water.has(sk))])
				shade_ok = false
			if not o._trees.is_empty() and sk == o._trees[0]:
				v_trunk = sv
		_check(not shade.is_empty() and shade_last, "%s: the ground's last paint layer is the shade (%d layers)" % [lab, layers.size()])
		_check(o._trees.is_empty() or shade_cells.size() >= 1, "%s: the shade has cells under the trees (%d cells)" % [lab, shade_cells.size()])
		_check(shade_ok and (o._trees.is_empty() or v_trunk >= 0.5), "%s: every shade cell is dry land at 0.02 < v <= 0.85 and the oldest trunk's cell reads %.2f" % [lab, v_trunk])
		# gen 4 (b): no flower within 0.85 rs of any trunk, rs = 0.6·(0.6 + 0.2·inten)·k — the
		# meadow's drip line; (c) in the wettest world at least one flower on the oldest tree's
		# drip line (0.85..1.6 rs); (d) no tree past inten 4 — one species of canopy
		var under := 0
		var drip0 := 0
		var n_flower := 0
		for fk in o._cells.keys():
			if String(o._cells[fk]["kingdom"]) != "flower":
				continue
			n_flower += 1
			var fc: Vector3 = o._cell_world(fk.x, fk.y)
			var fp := Vector2(fc.x, fc.z)
			var u := 99.0
			for t in o._trees:
				var rs: float = 0.6 * (0.6 + 0.2 * float(int(o._cells[t]["inten"]))) * float(o._cells[t].get("k", 1.0))
				u = minf(u, fp.distance_to(o._pos[t]) / rs)
			if u < 0.85:
				if under == 0:
					print("    flower %s at u %.2f rs of a trunk" % [str(fk), u])
				under += 1
			if not o._trees.is_empty():
				var t0: Vector2i = o._trees[0]
				var rs0: float = 0.6 * (0.6 + 0.2 * float(int(o._cells[t0]["inten"]))) * float(o._cells[t0].get("k", 1.0))
				var u0: float = fp.distance_to(o._pos[t0]) / rs0
				if u0 >= 0.85 and u0 <= 1.6:
					drip0 += 1
		var inten_max := 0
		for t in o._trees:
			inten_max = maxi(inten_max, int(o._cells[t]["inten"]))
		print("    [probe_biome_object] %s: %d flowers, %d under a canopy (u < 0.85), %d on the oldest tree's drip line, %d shade cells, max tree inten %d" % [lab, n_flower, under, drip0, shade_cells.size(), inten_max])
		_check(under == 0, "%s: no flower cell within 0.85 rs of a trunk (%d under)" % [lab, under])
		if o == wettest:
			_check(drip0 >= 1, "%s: the wettest world's oldest tree has flowers on its drip line (%d)" % [lab, drip0])
		_check(inten_max <= 4, "%s: no tree past inten 4 (max %d)" % [lab, inten_max])
		# gen 5 (a): the scree runs DOWN — every Scree_<x>_<z>_<i> mesh of the patch (an object
		# mesh, like the spires) has a surface height at or below its cluster's + 0.05, the
		# cluster read back as the Crystal_<x>_<z> holder; (b) no shard on a water cell or
		# outside the footprint — its position and its mesh's AABB through its own transform —
		# and each stands on the ground: its centre between the surface and one shard-height up
		var n_scree := 0
		var scree_down := true
		var scree_off_water := true
		var scree_in := true
		var scree_on_ground := true
		var scree_reach := 0.0
		var worst_rise := -99.0
		for ch in o._patch.get_children():
			if not (ch is MeshInstance3D) or not String(ch.name).begins_with("Scree_"):
				continue
			n_scree += 1
			var parts: PackedStringArray = String(ch.name).split("_")
			var ck := Vector2i(int(parts[1]), int(parts[2]))
			var holder: Node3D = o._patch.get_node_or_null("Crystal_%d_%d" % [ck.x, ck.y]) as Node3D
			var sp: Vector3 = ch.position
			var hs: float = o._h_at(sp.x, sp.z)
			if holder == null:
				if scree_down:
					print("    scree %s has no cluster" % ch.name)
				scree_down = false
			else:
				var hc: float = o._h_at(holder.position.x, holder.position.z)
				worst_rise = maxf(worst_rise, hs - hc)
				if hs > hc + 0.05:
					if scree_down:
						print("    scree climbs: %s on a surface at %.3f, its cluster's at %.3f" % [ch.name, hs, hc])
					scree_down = false
			var sk := Vector2i(int(floor(sp.x + float(o.size) * 0.5)), int(floor(sp.z + float(o.size) * 0.5)))
			if o._water.has(sk):
				if scree_off_water:
					print("    scree on the water: %s at (%.2f, %.2f), cell %s" % [ch.name, sp.x, sp.z, str(sk)])
				scree_off_water = false
			var bb3: AABB = (ch as Node3D).transform * (ch as MeshInstance3D).mesh.get_aabb()
			scree_reach = maxf(scree_reach, maxf(maxf(absf(bb3.position.x), absf(bb3.end.x)), maxf(absf(bb3.position.z), absf(bb3.end.z))))
			if absf(sp.x) > half or absf(sp.z) > half or bb3.position.x < -half or bb3.end.x > half or bb3.position.z < -half or bb3.end.z > half:
				if scree_in:
					print("    scree out: %s spans x %.2f..%.2f z %.2f..%.2f" % [ch.name, bb3.position.x, bb3.end.x, bb3.position.z, bb3.end.z])
				scree_in = false
			var pmz: PrismMesh = (ch as MeshInstance3D).mesh as PrismMesh
			var lift_max: float = pmz.size.y if pmz != null else 1.0
			if sp.y < hs - 0.001 or sp.y > hs + lift_max + 0.001:
				if scree_on_ground:
					print("    scree off the ground: %s centre %.3f, surface %.3f" % [ch.name, sp.y, hs])
				scree_on_ground = false
		var n_cluster := 0
		var min_3 := true
		var toward_water := true
		var n_trails := 0
		for mk in o._cells.keys():
			if String(o._cells[mk]["kingdom"]) != "mineral":
				continue
			n_cluster += 1
			if o._water_dist(mk.x, mk.y) < 3.0:
				if min_3:
					print("    mineral %s at %.2f cells from the water" % [str(mk), o._water_dist(mk.x, mk.y)])
				min_3 = false
			# gen 5 (e): the trail heads toward the water's side — the LAST shard placed (the
			# highest index), read back from the patch, displaced from its cluster with a positive
			# dot on the basin's direction
			var holder2: Node3D = o._patch.get_node_or_null("Crystal_%d_%d" % [mk.x, mk.y]) as Node3D
			var last: Node3D = null
			var last_i := -1
			for ch in o._patch.get_children():
				if ch is Node3D and String(ch.name).begins_with("Scree_%d_%d_" % [mk.x, mk.y]):
					var si: int = int(String(ch.name).split("_")[3])
					if si > last_i:
						last_i = si
						last = ch
			if holder2 != null and last != null:
				n_trails += 1
				var pc := Vector2(holder2.position.x, holder2.position.z)
				var tb: Vector2 = (basin_w - pc).normalized()
				var run: Vector2 = Vector2(last.position.x, last.position.z) - pc
				if run.dot(tb) <= 0.0:
					if toward_water:
						print("    scree from %s runs away from the water: (%.2f, %.2f) against basin (%.2f, %.2f)" % [str(mk), run.x, run.y, tb.x, tb.y])
					toward_water = false
		# gen 5 (c): the rock layer — named "rock", before the shade, a painted cell (v > 0) at
		# every cluster's own cell
		var rock: Dictionary = {}
		var rock_idx := -1
		var shade_idx := -1
		for li in range(layers.size()):
			if layers[li] is Dictionary:
				var nm := String((layers[li] as Dictionary).get("name", ""))
				if nm == "rock":
					rock = layers[li]
					rock_idx = li
				elif nm == "shade":
					shade_idx = li
		var rock_cells: Array = ((rock["brush"] as Dictionary)["cells"] as Array) if rock.has("brush") else []
		var rock_at_cluster := true
		for mk in o._cells.keys():
			if String(o._cells[mk]["kingdom"]) != "mineral":
				continue
			var found := false
			for rc in rock_cells:
				if int(rc[0]) == mk.x and int(rc[1]) == mk.y and float(rc[2]) > 0.0:
					found = true
					break
			if not found:
				if rock_at_cluster:
					print("    no rock painted under the cluster at %s" % str(mk))
				rock_at_cluster = false
		print("    [probe_biome_object] %s: %d clusters, %d scree shards (reach %.2f m of %.2f, worst rise %.3f), %d rock cells" % [lab, n_cluster, n_scree, scree_reach, half, worst_rise, rock_cells.size()])
		_check(n_cluster == 0 or n_scree > 0, "%s: a world with a mineral cell has scree (%d clusters, %d shards)" % [lab, n_cluster, n_scree])
		_check(scree_down, "%s: every scree shard's surface is at or below its cluster's + 0.05 (worst rise %.3f)" % [lab, worst_rise])
		_check(scree_off_water and scree_in, "%s: no scree shard on a water cell or outside the footprint (reach %.2f m of %.2f)" % [lab, scree_reach, half])
		_check(scree_on_ground, "%s: every scree shard stands on the ground" % lab)
		_check(int(cnt.get("scree", -1)) == n_scree, "%s: the scree count is the shards standing (%d vs %d)" % [lab, int(cnt.get("scree", -1)), n_scree])
		_check(toward_water, "%s: every scree trail heads toward the water's side (%d trails)" % [lab, n_trails])
		_check(not rock.is_empty() and shade_idx >= 0 and rock_idx < shade_idx, "%s: the ground carries a rock paint layer before the shade (rock at %d, shade at %d)" % [lab, rock_idx, shade_idx])
		_check(rock_at_cluster, "%s: rock is painted wherever a cluster stands (%d cells)" % [lab, rock_cells.size()])
		# gen 5 (d): the ridge is 3.0 cells from the water
		_check(min_3, "%s: every mineral cell is 3.0 cells from the water (%d minerals)" % [lab, n_cluster])
	for o in [a, b, c, d4]:
		_check_cover(o)
	var ca: Dictionary = _world_counts(a.get_state()["counts"])
	var cb: Dictionary = _world_counts(b.get_state()["counts"])
	var cc: Dictionary = _world_counts(c.get_state()["counts"])
	_check(int(cb["fungus"]) >= int(cc["fungus"]), "wetter grows at least as much rim fungus (%d vs %d)" % [int(cb["fungus"]), int(cc["fungus"])])
	_check(int(cb["cover"]) > int(cc["cover"]), "wetter grows more cover (%d vs %d)" % [int(cb["cover"]), int(cc["cover"])])
	_check(int(cc["mineral"]) >= int(cb["mineral"]), "higher relief grows at least as many crystals (%d vs %d)" % [int(cc["mineral"]), int(cb["mineral"])])
	var twin = await _grow(7, 0.5, 0.5, 0.6)
	_check(str(_world_counts(twin.get_state()["counts"])) == str(ca), "the same seed grows the same counts")
	_check(var_to_str(twin._cover_tufts) == var_to_str(a._cover_tufts), "cover group transforms and colours replay exactly at a translated instance")
	_check(twin._basin_c == a._basin_c, "the same seed digs the basin in the same place")
	var other = await _grow(8, 0.5, 0.5, 0.6)
	_check(other._basin_c != a._basin_c or str(_world_counts(other.get_state()["counts"])) != str(ca), "a different seed grows a different world")
	_check(FileAccess.file_exists("res://ada_run/biome_rsi/state/%s.json" % a.label()), "the record is written")
	print("[probe_biome_object] %d checks, %d failed" % [_checks, _fails])
	quit(0 if _fails == 0 else 1)


## gen 3: the counts that describe the WORLD — the ms_<kingdom> timings are wall-clock and
## differ between two builds of the same seed, so the determinism check leaves them out.
func _world_counts(cnt: Dictionary) -> Dictionary:
	var out := {}
	for k in cnt.keys():
		if not String(k).begins_with("ms_"):
			out[k] = cnt[k]
	return out


func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var l2: float = ab.length_squared()
	if l2 < 0.000001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _grow(seed: int, moisture: float, relief: float, wildness: float):
	var o = OBJ.new()
	o.seed = seed
	o.moisture = moisture
	o.relief = relief
	o.wildness = wildness
	o.position = Vector3(float(_slot) * 30.0, 0.0, 0.0)
	_slot += 1
	_root.add_child(o)
	await process_frame
	await process_frame
	return o


## Generation 6: inspect the CPU plan that feeds the MultiMeshes. The headless dummy
## renderer does not reliably read GPU transforms back; draw counts are checked separately.
func _check_cover(o) -> void:
	var lab: String = o.label()
	var members := 0
	var grouped := 0
	var litter := 0
	var in_bounds := true
	var supported := true
	var dry := true
	var bare_rock := true
	var inner_canopy := true
	var coherent := true
	var flat_litter := true
	var half: float = float(o.size) * 0.5
	for tuft: Dictionary in o._cover_tufts:
		var kind: String = tuft.type
		var mesh: Mesh = o.Cover.mesh_for("fern" if kind == "litter" else kind)
		var group: Array = tuft.members
		if group.size() > 1: grouped += 1
		for member in group:
			members += 1
			var xf: Transform3D = member[0]
			var p := Vector2(xf.origin.x, xf.origin.z)
			var box: AABB = xf * mesh.get_aabb()
			in_bounds = in_bounds and box.position.x >= -half - 0.001 and box.end.x <= half + 0.001 and box.position.z >= -half - 0.001 and box.end.z <= half + 0.001
			coherent = coherent and p.distance_to(tuft.centre) <= float(tuft.radius) + 0.001 and member[1] == group[0][1]
			supported = supported and absf(box.position.y - o._h_at(p.x, p.y)) <= 0.03
			var cell := Vector2i(int(floor(p.x + half)), int(floor(p.y + half)))
			dry = dry and not o._water.has(cell) and o._h_at(p.x, p.y) >= o._water_level() + 0.019
			bare_rock = bare_rock and float(o._rock.get(cell, 0.0)) < 0.35
			for cp in o._clusters:
				bare_rock = bare_rock and p.distance_to(cp) >= 0.799
			if kind == "litter":
				litter += 1
				var sheltered := false
				for tree in o._trees:
					if p.distance_to(o._pos[tree]) < float(o._canopy.get(tree, 0.0)) * 0.35 + 0.001:
						sheltered = true
				inner_canopy = inner_canopy and sheltered
				flat_litter = flat_litter and absf(xf.basis.z.normalized().dot(Vector3.UP)) > 0.99
	var rendered := 0
	for child in o._patch.get_children():
		if child is MultiMeshInstance3D and String(child.name).begins_with("Cover_"):
			rendered += child.multimesh.instance_count
	var counts: Dictionary = o.get_state().counts
	_check(grouped > 0 and coherent, "%s: grouped cover shares a local centre and colour" % lab)
	_check(members == rendered and members == int(counts.cover) and members <= 864, "%s: cover plan matches bounded draw count (%d)" % [lab, members])
	_check(in_bounds and supported, "%s: cover mesh bounds inside plate, feet at sampled surface" % lab)
	_check(dry and bare_rock, "%s: displaced members respect water, scree and crystal exclusions" % lab)
	_check(inner_canopy and flat_litter and litter == int(counts.cover_litter), "%s: litter is flat under an inner canopy (%d pieces)" % [lab, litter])
	if o.seed == 11:
		_check(litter > 0, "wet-world inner canopy produces a visible litter layer")
	# Exact fixture matches have generation-5 records: preserve every other kingdom count.
	var parent := "res://ada_run/biome_rsi/gen_5/state_%s.json" % lab
	if FileAccess.file_exists(parent):
		var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(parent))
		for key in ["water", "mineral", "scree", "fungus", "fungus_path", "tree", "flower", "creature", "connections", "paint"]:
			_check(counts[key] == old.counts[key], "%s: parent %s count preserved" % [lab, key])
	print("    [cover] %s: %d tufts, %d members, %d litter, %d ms" % [lab, o._cover_tufts.size(), members, litter, int(counts.ms_cover)])
