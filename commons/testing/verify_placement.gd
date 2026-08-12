extends SceneTree

## verify_placement.gd — does the museum that got BUILT match the plan that was
## APPROVED?
##
## Phase 0's keystone gate. Everything upstream of it reasons in 2D cells; the
## player stands in 3D metres; and until now nothing in the repo compared the
## two. Three real faults slipped through every 2D check and were only caught by
## squinting at captures: an artifact whose mesh sits 4.5 m from its own node
## origin, a token suffix that silently switched auto-grounding off, and an
## 8.1 m artifact standing in a 4 m room. Squinting does not scale past three
## artifacts.
##
## The probe loads a compiled map, measures every placed artifact's REAL world
## AABB, converts it to grid cells, and diffs it against the cells the
## negotiator reserved (written into map_info.metadata.placements). It reports
## per-artifact and exits non-zero when the built room disagrees with the plan.
##
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/verify_placement.gd -- \
##     --map=Museum_Spatial_Slice --out=res://ada_run/spatial_slice/correspondence.json
##
## Options:
##   --map=<Name>           map to verify (required)
##   --out=<res://path>     report destination
##   --tolerance-cells=<n>  how many cells of drift are forgiven (default 0)
##   --settle=<seconds>     time to let procedural geometry finish (default 0.6)

const MAP_CATALOG_SCENE := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

var _map: String = ""
var _out: String = "res://ada_run/spatial_slice/correspondence.json"
var _tolerance: int = 0
var _settle: float = 0.6


func _initialize() -> void:
	_parse_args()
	if _map == "":
		push_error("verify_placement: --map=<Name> is required")
		quit(2)
		return
	_run.call_deferred()


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var a := String(arg)
		if a.begins_with("--map="):
			_map = a.substr(6)
		elif a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--tolerance-cells="):
			_tolerance = int(a.substr(18))
		elif a.begins_with("--settle="):
			_settle = float(a.substr(9))


# ── geometry ────────────────────────────────────────────────────────

## World-space AABB over an artifact's whole subtree.
##
## Recursive and in GLOBAL space, unlike capture_multi_angle's framing helper,
## which walks direct children in local space — an artifact whose meshes live
## two nodes down would otherwise measure as nothing. GPUParticles3D is excluded
## for the same reason auto-grounding excludes it: an emitter's AABB is its
## whole emission volume, not its body.
func _world_aabb(node: Node3D) -> Dictionary:
	var out := AABB()
	var found := false
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is GPUParticles3D or n is CPUParticles3D:
			continue
		var piece := AABB()
		var has := false
		if n is MeshInstance3D:
			var mesh = (n as MeshInstance3D).mesh
			if mesh != null:
				piece = mesh.get_aabb()
				has = true
		elif n is MultiMeshInstance3D:
			var mm = (n as MultiMeshInstance3D).multimesh
			if mm != null and mm.instance_count > 0:
				piece = mm.get_aabb()
				has = true
		elif n is CSGShape3D:
			var meshes = (n as CSGShape3D).get_meshes()
			if meshes.size() >= 2 and meshes[1] is Mesh:
				piece = (meshes[1] as Mesh).get_aabb()
				has = true
		if has and n is Node3D:
			var gt: Transform3D = (n as Node3D).global_transform
			var world := gt * piece
			if found:
				out = out.merge(world)
			else:
				out = world
				found = true
		for c in n.get_children():
			stack.append(c)
	return {"aabb": out, "found": found}


func _collect_artifacts(node: Node, out: Array) -> void:
	if node.has_meta("artifact_lookup_name") and node is Node3D:
		out.append(node)
	for c in node.get_children():
		_collect_artifacts(c, out)


func _find_grid(catalog: Node) -> Node3D:
	var g = catalog.get("_grid_system") if "_grid_system" in catalog else null
	return g as Node3D


## The cells an AABB actually covers, in the grid's own local space. Uses the
## same step (cube_size + gutter) the placer uses, so a disagreement here is a
## real disagreement and not a units mismatch.
func _cells_of(aabb: AABB, grid: Node3D, step: float) -> Array:
	var lo := aabb.position
	var hi := aabb.position + aabb.size
	if grid != null and grid.is_inside_tree():
		lo = grid.to_local(lo)
		hi = grid.to_local(hi)
	var x0 := int(round(min(lo.x, hi.x) / step))
	var x1 := int(round(max(lo.x, hi.x) / step))
	var z0 := int(round(min(lo.z, hi.z) / step))
	var z1 := int(round(max(lo.z, hi.z) / step))
	var cells: Array = []
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			cells.append([x, z])
	return cells


func _key(c) -> String:
	return "%d,%d" % [int(c[0]), int(c[1])]


# ── the run ─────────────────────────────────────────────────────────

func _run() -> void:
	var plan := _load_plan()
	if plan.is_empty():
		_fail("no map_data.json or no metadata.placements for '%s' — this gate "
			+ "only verifies maps compiled by the spatial pipeline" % _map)
		return

	if change_scene_to_file(MAP_CATALOG_SCENE) != OK:
		_fail("could not load the map catalog scene")
		return
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	if catalog == null:
		_fail("catalog scene is null")
		return

	if not bool(catalog.call("load_map_fresh", _map)):
		_fail("catalog refused to load map '%s'" % _map)
		return

	var grid := _find_grid(catalog)
	var ready := false
	var elapsed := 0.0
	while elapsed < 30.0 and not ready:
		if grid != null and grid.has_method("is_map_ready") and bool(grid.call("is_map_ready")):
			ready = true
			break
		await create_timer(0.1).timeout
		elapsed += 0.1
	# Procedural artifacts finish building AFTER the map reports ready; two
	# process frames photographs a half-built artifact.
	await create_timer(_settle).timeout
	await process_frame

	if grid == null:
		grid = _find_grid(catalog)
	var step := 1.0
	if grid != null:
		var cs = grid.get("cube_size") if "cube_size" in grid else 1.0
		var gut = grid.get("gutter") if "gutter" in grid else 0.0
		step = float(cs) + float(gut)

	var nodes: Array = []
	_collect_artifacts(catalog, nodes)
	var measured: Dictionary = {}
	for n in nodes:
		var lookup := String((n as Node3D).get_meta("artifact_lookup_name"))
		var m := _world_aabb(n as Node3D)
		if not m["found"]:
			measured[lookup] = {"rendered": false}
			continue
		var box: AABB = m["aabb"]
		var cells := _cells_of(box, grid, step)
		var centre := box.position + box.size * 0.5
		if grid != null and grid.is_inside_tree():
			centre = grid.to_local(centre)
		measured[lookup] = {
			"rendered": true,
			"cells": cells,
			"centre_m": [centre.x, centre.z],
			"top_m": box.position.y + box.size.y,
			"base_m": box.position.y,
			"size_m": [box.size.x, box.size.y, box.size.z],
			"rotation_deg": int(round(rad_to_deg((n as Node3D).global_rotation.y))) % 360,
		}

	# ── diff plan against reality ───────────────────────────────────
	var results: Array = []
	var failures := 0
	var owner_of: Dictionary = {}      # cell key -> lookup, for overlap checks

	for p in plan:
		var lookup := String(p.get("artifact", ""))
		var expected: Array = p.get("expected_cells", [])
		var faults: Array = []
		var got = measured.get(lookup, null)

		if got == null:
			faults.append("planned but never appeared in the built map")
		elif not bool(got.get("rendered", false)):
			faults.append("node exists but rendered no geometry")
		else:
			var exp_set: Dictionary = {}
			for c in expected:
				exp_set[_key(c)] = true
			var got_set: Dictionary = {}
			for c in got["cells"]:
				got_set[_key(c)] = true

			var missing: Array = []
			for k in exp_set.keys():
				if not got_set.has(k):
					missing.append(k)
			var extra: Array = []
			for k in got_set.keys():
				if not exp_set.has(k):
					extra.append(k)

			# Drift = how far the measured body's centre sits from the planned
			# one, in METRES. Comparing discretised cell sets instead would
			# report a phantom half-cell for every even-width artifact, and a
			# gate that cries wolf gets switched off.
			var drift: float = _centre_drift_m(expected, got, step)
			if drift > _tolerance_m():
				faults.append("body centre sits %.2f m from where it was planned" % drift)

			# Size disagreement is the measurement-staleness detector: the plan
			# reserved cells from the registry's AABB, so if the built artifact
			# is materially bigger, the registry is lying and every placement
			# computed from it reserved the wrong amount of room.
			var pw: int = _span(expected, 0)
			var pd: int = _span(expected, 1)
			var mw: float = float(got["size_m"][0])
			var md: float = float(got["size_m"][2])
			if mw > float(pw) + 1.0 or md > float(pd) + 1.0:
				faults.append(("measures %.2f x %.2f m but the plan reserved %d x %d "
					+ "cells from the registry — the registry AABB is stale")
					% [mw, md, pw, pd])

			var planned_h = float(p.get("expected_height_m", 0.0))
			if planned_h > 0.0 and got["top_m"] > planned_h + 0.35:
				faults.append("stands %.2f m, above the %.2f m the plan allowed"
					% [got["top_m"], planned_h])

			var planned_rot := int(p.get("rotation", 0))
			var got_rot := int(got["rotation_deg"])
			if ((got_rot - planned_rot) % 360 + 360) % 360 not in [0, 360]:
				faults.append("built at %d deg, planned %d deg" % [got_rot, planned_rot])

			for k in got_set.keys():
				if owner_of.has(k) and owner_of[k] != lookup:
					faults.append("body overlaps %s at cell %s" % [owner_of[k], k])
					break
			for k in got_set.keys():
				owner_of[k] = lookup

		if faults.size() > 0:
			failures += 1
		results.append({
			"artifact": lookup,
			"result": "PASS" if faults.is_empty() else "FAIL",
			"faults": faults,
			"planned_cells": expected.size(),
			"measured": got if got != null else {},
		})

	var report := {
		"schema": "adaresearch.placement_correspondence.v1",
		"map": _map,
		"tolerance_cells": _tolerance,
		"artifacts_planned": plan.size(),
		"artifacts_measured": measured.size(),
		"failures": failures,
		"result": "PASS" if failures == 0 else "FAIL",
		"artifacts": results,
	}
	_write(report)

	print("")
	print("=== 2D plan vs 3D build: %s ===" % _map)
	for r in results:
		print("  %-34s %s" % [r["artifact"], r["result"]])
		for f in r["faults"]:
			print("      - %s" % f)
	print("  %d planned, %d failed" % [plan.size(), failures])
	quit(0 if failures == 0 else 1)


## Forgiveness, in metres: ONE CELL, plus whatever the caller adds.
##
## Not a fudge — it is the resolution of the thing being checked. A map token
## names a cell (`name:rot:y:scale` has no x or z offset), so sub-cell placement
## is not expressible in map_data.json at all. Two known sub-cell effects live
## inside this budget: an even-width footprint has no cell-centred centre, and
## an artifact whose geometry sits a little off its own origin cannot be
## corrected by an integer token. Demanding better would be demanding precision
## the format cannot deliver, and a gate that fails on the impossible gets
## switched off. A displacement of a whole cell or more is still caught, which
## is what this exists for.
func _tolerance_m() -> float:
	return 1.0 + float(_tolerance)


## How far the built body's centre sits from the planned one, in METRES.
## Planned cells are converted to metres rather than the measurement being
## converted to cells, so no half-cell is lost to rounding.
func _centre_drift_m(expected: Array, got: Dictionary, step: float) -> float:
	if expected.is_empty():
		return 0.0
	var ex := 0.0
	var ez := 0.0
	for c in expected:
		ex += float(c[0])
		ez += float(c[1])
	ex = ex / float(expected.size()) * step
	ez = ez / float(expected.size()) * step
	var c_m: Array = got.get("centre_m", [])
	if c_m.size() < 2:
		return 0.0
	return Vector2(ex - float(c_m[0]), ez - float(c_m[1])).length()


## Width (axis 0) or depth (axis 1) of a planned cell set, in cells.
func _span(cells: Array, axis: int) -> int:
	if cells.is_empty():
		return 0
	var lo: int = int(cells[0][axis])
	var hi: int = lo
	for c in cells:
		lo = mini(lo, int(c[axis]))
		hi = maxi(hi, int(c[axis]))
	return hi - lo + 1


func _load_plan() -> Array:
	var path := "res://commons/maps/%s/map_data.json" % _map
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var info = parsed.get("map_info", {})
	var meta = info.get("metadata", {}) if typeof(info) == TYPE_DICTIONARY else {}
	var placements = meta.get("placements", []) if typeof(meta) == TYPE_DICTIONARY else []
	var out: Array = []
	for p in placements:
		if typeof(p) == TYPE_DICTIONARY and String(p.get("result", "")) == "ACCEPT":
			out.append(p)
	return out


func _write(report: Dictionary) -> void:
	var dir := _out.get_base_dir()
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(_out, FileAccess.WRITE)
	if f == null:
		push_error("verify_placement: cannot write %s" % _out)
		return
	f.store_string(JSON.stringify(report, "\t"))
	f.close()
	print("verify_placement: wrote %s" % _out)


func _fail(msg: String) -> void:
	push_error("verify_placement: %s" % msg)
	_write({
		"schema": "adaresearch.placement_correspondence.v1",
		"map": _map, "result": "ERROR", "error": msg,
	})
	quit(2)
