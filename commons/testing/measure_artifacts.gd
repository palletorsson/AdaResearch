# measure_artifacts.gd — Batch AABB measurement for all registered artifacts
# Loads every artifact scene, measures its bounding box, outputs dimensions JSON.
#
# Usage:
#   godot --path . --xr-mode off --no-window \
#     --script res://commons/testing/measure_artifacts.gd \
#     -- --outdir=res://ada_run
#
# Flags:
#   --outdir=<path>      Output directory (default: res://ada_run)
#   --registry=<name>    Only measure artifacts from this registry (default: all)

extends SceneTree

const REGISTRY_DIR := "res://commons/artifacts/registry/"

var _outdir: String = "res://ada_run"
var _registry_filter: String = ""
var _start_time: int = 0
## Seconds an artifact gets to finish building before it is frozen and read.
## 0.35 s is the figure probe_aabb_hogs.gd already needed for the same reason.
var _settle: float = 0.35
## Only measure these lookup_names (comma-separated). For the negative tests.
var _only: Dictionary = {}
var _last_measure: Dictionary = {}
## Set when a second reading shows the artifact is still growing — a simulation
## running, not geometry settling.
var _unstable: bool = false
## No artifact is half a kilometre. Beyond this a number is evidence of a fault,
## never a body, and must not overwrite whatever the registry already holds.
const IMPLAUSIBLE_M := 500.0


func _finite(a: AABB) -> bool:
	for v in [a.size.x, a.size.y, a.size.z, a.position.x, a.position.y, a.position.z]:
		if is_nan(v) or is_inf(v):
			return false
	return true

func _initialize() -> void:
	_parse_args()
	call_deferred("_run")

func _parse_args() -> void:
	for raw_arg in OS.get_cmdline_user_args():
		var arg: String = String(raw_arg).strip_edges()
		if not arg.begins_with("--") or arg.find("=") <= 2:
			continue
		var eq_idx: int = arg.find("=")
		var key: String = arg.substr(2, eq_idx - 2)
		var value: String = arg.substr(eq_idx + 1).strip_edges()
		match key:
			"outdir":
				_outdir = value
			"registry":
				_registry_filter = value
			"settle":
				_settle = value.to_float()
			"only":
				for name in value.split(",", false):
					_only[String(name).strip_edges()] = true

# ══════════════════════════════════════════════════════════════════
# MAIN PIPELINE
# ══════════════════════════════════════════════════════════════════

func _run() -> void:
	_start_time = Time.get_ticks_msec()
	print("measure_artifacts: Starting...")

	# 1. Load all artifacts from registries
	var artifacts: Dictionary = _load_all_artifacts()
	print("measure_artifacts: Found %d unique artifacts" % artifacts.size())

	# 2. Measure each artifact
	var holder := Node3D.new()
	holder.name = "MeasurementHolder"
	root.add_child(holder)
	await process_frame

	var results: Array = []
	var measured: int = 0
	var skipped: int = 0
	var errors: int = 0

	var lookup_names: Array = artifacts.keys()
	lookup_names.sort()
	if not _only.is_empty():
		lookup_names = lookup_names.filter(func(n): return _only.has(String(n)))
		print("measure_artifacts: --only restricts this run to %d artifact(s)"
			% lookup_names.size())

	# Resume support: if we have a partial report, skip everything up to
	# and including the last entry it contains.
	var checkpoint_path: String = _outdir.path_join("artifact_measurements.checkpoint.json")
	var skip_list_path: String = _outdir.path_join("artifact_measurements.skip_list.txt")
	var done_set: Dictionary = {}
	if FileAccess.file_exists(checkpoint_path):
		var prior := _load_json(checkpoint_path)
		var prior_arts: Array = prior.get("artifacts", []) as Array
		for r in prior_arts:
			if r is Dictionary and r.has("lookup_name"):
				done_set[r["lookup_name"]] = true
				results.append(r)
		print("measure_artifacts: resuming, %d previously measured" % done_set.size())
	# Skip list: artifacts known to crash Godot. One lookup_name per line.
	var skip_set: Dictionary = {}
	if FileAccess.file_exists(skip_list_path):
		var sf := FileAccess.open(skip_list_path, FileAccess.READ)
		while sf and not sf.eof_reached():
			var line: String = sf.get_line().strip_edges()
			if not line.is_empty() and not line.begins_with("#"):
				skip_set[line] = true
		if sf: sf.close()
		print("measure_artifacts: skip-list loaded, %d names" % skip_set.size())

	for lookup_name in lookup_names:
		if done_set.has(lookup_name):
			continue
		if skip_set.has(lookup_name):
			results.append({
				"lookup_name": lookup_name,
				"scene": (artifacts[lookup_name] as Dictionary).get("scene", ""),
				"registry": (artifacts[lookup_name] as Dictionary).get("_registry_source", ""),
				"error": "skipped_crashes_godot",
			})
			skipped += 1
			continue
		var entry: Dictionary = artifacts[lookup_name]
		var scene_path: String = entry.get("scene", "")

		# Write progress marker so we know who was being processed if Godot crashes.
		_write_progress(_outdir.path_join("artifact_measurements.progress.txt"),
			"%s\n%s\n" % [lookup_name, scene_path])

		if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			skipped += 1
			continue

		var packed: PackedScene = ResourceLoader.load(scene_path)
		if not packed:
			errors += 1
			results.append({
				"lookup_name": lookup_name,
				"scene": scene_path,
				"error": "failed_to_load",
				"registry": entry.get("_registry_source", ""),
			})
			continue

		var instance: Node = packed.instantiate()
		if not instance:
			errors += 1
			continue

		holder.add_child(instance)

		# ORDER MATTERS, and it used to be wrong. Processing was disabled here,
		# BEFORE the artifact had a chance to build — so every artifact that
		# grows its geometry in _process (or over a tween) was frozen at nothing
		# and then measured. Two process frames photographs a half-built
		# artifact; the correspondence gate caught bias_visualizer recorded at
		# 0.55 m against a real 1.98 m, and neural_network_visualization at
		# 0.6 m deep against a real 5.43 m. Let it build, THEN freeze it, THEN
		# measure — the freeze still does its original job of stopping a
		# simulation from drifting mid-measurement.
		await process_frame
		await process_frame
		if _settle > 0.0:
			await create_timer(_settle).timeout
		_disable_processing_recursive(instance)
		await process_frame

		# Letting it BUILD also lets it RUN. The first version of this fix
		# produced heights of 1003 m for the cellular automata and 9.4e19 for
		# evolving_bloops — a simulation walking away during the settle window,
		# recorded as a body. So take a second reading a moment later: if the
		# box is still growing, the artifact is not settling, it is running, and
		# neither reading describes it. Marked unstable, and the merge refuses
		# to write it over a prior value.
		var target_probe: Node3D = instance as Node3D if instance is Node3D else null
		if target_probe != null:
			var first_box: AABB = _measure_body(target_probe)
			await create_timer(0.15).timeout
			var second_box: AABB = _measure_body(target_probe)
			var grew: float = (second_box.size - first_box.size).length()
			_unstable = grew > 0.25 or not _finite(second_box)

		var target: Node3D = instance as Node3D if instance is Node3D else null
		if not target:
			for child in instance.get_children():
				if child is Node3D:
					target = child
					break

		if target:
			var aabb: AABB = _measure_body(target)

			# The old code discarded anything over 100 m as "nonsense", which
			# is how a genuinely 100 m artifact (scale_lines, standing in 22
			# live maps) came to be recorded as ZERO — indistinguishable from a
			# failure, and a large part of the 226 artifacts that measure zero.
			# The two causes it was really guarding against — particle boxes and
			# hidden geometry — are now excluded at the source, so an extreme
			# number here is evidence rather than noise. Keep it, and flag it.
			if aabb.size.length() > 100.0:
				_last_measure["oversize"] = true
			if _unstable:
				_last_measure["unstable"] = true
			var worst: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
			if _unstable or worst > IMPLAUSIBLE_M or not _finite(aabb):
				_last_measure["implausible"] = true
				_last_measure["implausible_reason"] = (
					"still growing at the second reading" if _unstable
					else "%.1f m on one axis — evidence of a fault, not a body" % worst)

			var size_x: float = snapped(aabb.size.x, 0.01)
			var size_y: float = snapped(aabb.size.y, 0.01)
			var size_z: float = snapped(aabb.size.z, 0.01)
			var max_dim: float = maxf(size_x, maxf(size_y, size_z))

			# Grid cells: ceil to nearest integer, minimum 1
			var grid_w: int = maxi(1, ceili(size_x))
			var grid_h: int = maxi(1, ceili(size_y))
			var grid_d: int = maxi(1, ceili(size_z))

			results.append({
				"lookup_name": lookup_name,
				"scene": scene_path,
				"registry": entry.get("_registry_source", ""),
				"aabb_size": [size_x, size_y, size_z],
				"aabb_center": [
					snapped(aabb.get_center().x, 0.01),
					snapped(aabb.get_center().y, 0.01),
					snapped(aabb.get_center().z, 0.01),
				],
				"grid_cells": [grid_w, grid_d],  # width x depth (XZ plane)
				"max_dimension_m": snapped(max_dim, 0.01),
				"interaction": entry.get("interaction", ""),
				"category": entry.get("category", ""),
				"tags": entry.get("tags", []),
				# How the number was reached, beside the number. A fallback that
				# cannot say it is a fallback is the fault that let [1,1,1] pass
				# as a measurement.
				"provenance": _last_measure.duplicate(true),
			})
		else:
			results.append({
				"lookup_name": lookup_name,
				"scene": scene_path,
				"registry": entry.get("_registry_source", ""),
				"error": "no_node3d",
			})

		instance.queue_free()
		await process_frame

		measured += 1
		if measured % 25 == 0:
			var elapsed: float = (Time.get_ticks_msec() - _start_time) / 1000.0
			print("measure_artifacts: %d / %d measured (%.1fs)" % [measured, lookup_names.size(), elapsed])
			# Flush checkpoint every 25 artifacts so crashes don't lose much.
			_write_json(checkpoint_path, {
				"generated": Time.get_datetime_string_from_system(true),
				"artifacts": results,
			})

	# 3. Build report
	var report := {
		"generated": Time.get_datetime_string_from_system(true),
		"total_artifacts": lookup_names.size(),
		"measured": measured,
		"skipped": skipped,
		"errors": errors,
		"artifacts": results,
	}

	# Size distribution summary
	var size_buckets := { "tiny": 0, "small": 0, "medium": 0, "large": 0, "huge": 0 }
	for r in results:
		if r.has("error"):
			continue
		var max_d: float = r.get("max_dimension_m", 0.0)
		if max_d <= 0.3:
			size_buckets["tiny"] += 1
		elif max_d <= 1.0:
			size_buckets["small"] += 1
		elif max_d <= 2.0:
			size_buckets["medium"] += 1
		elif max_d <= 4.0:
			size_buckets["large"] += 1
		else:
			size_buckets["huge"] += 1
	report["size_distribution"] = size_buckets

	# 4. Write output
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_outdir))
	var out_path: String = _outdir.path_join("artifact_measurements.json")
	_write_json(out_path, report)

	var elapsed_total: float = (Time.get_ticks_msec() - _start_time) / 1000.0
	print("")
	print("═══════════════════════════════════════════")
	print("measure_artifacts: COMPLETE")
	print("  Measured: %d" % measured)
	print("  Skipped:  %d (no scene)" % skipped)
	print("  Errors:   %d" % errors)
	print("  Time:     %.1fs" % elapsed_total)
	print("")
	print("  Size distribution:")
	print("    tiny  (≤0.3m): %d" % size_buckets["tiny"])
	print("    small (≤1.0m): %d" % size_buckets["small"])
	print("    medium(≤2.0m): %d" % size_buckets["medium"])
	print("    large (≤4.0m): %d" % size_buckets["large"])
	print("    huge  (>4.0m): %d" % size_buckets["huge"])
	print("")
	var abs_path: String = ProjectSettings.globalize_path(out_path)
	print("  Output: %s" % abs_path)
	print("═══════════════════════════════════════════")

	quit(0)

# ══════════════════════════════════════════════════════════════════
# REGISTRY LOADING
# ══════════════════════════════════════════════════════════════════

func _load_all_artifacts() -> Dictionary:
	var all_artifacts: Dictionary = {}

	# Load all registries from registry/ directory
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir:
		dir.list_dir_begin()
		var fname: String = dir.get_next()
		while fname != "":
			if fname.ends_with(".json"):
				if _registry_filter.is_empty() or fname.begins_with(_registry_filter):
					var path: String = REGISTRY_DIR.path_join(fname)
					var data := _load_json(path)
					if data.has("artifacts"):
						var arts = data["artifacts"]
						if arts is Dictionary:
							for key in arts:
								var entry: Dictionary = arts[key]
								var lname: String = entry.get("lookup_name", key)
								entry["_registry_source"] = fname
								all_artifacts[lname] = entry
						elif arts is Array:
							for entry in arts:
								if entry is Dictionary:
									var lname: String = entry.get("lookup_name", "")
									if not lname.is_empty():
										entry["_registry_source"] = fname
										all_artifacts[lname] = entry
			fname = dir.get_next()
		dir.list_dir_end()

	return all_artifacts

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("measure_artifacts: Failed to parse %s" % path)
		return {}
	if json.data is Dictionary:
		return json.data
	return {}

# ══════════════════════════════════════════════════════════════════
# AABB MEASUREMENT (from check_aabb_below_ground.gd)
# ══════════════════════════════════════════════════════════════════

## The artifact's BODY, in its own frame AT ITS OWN SCALE, with provenance.
##
## Fixed 2026-08-12. This used to end `root.global_transform.affine_inverse() * body`,
## which is the root's OWN space — so an artifact that sets its own root scale in
## `_ready()` had that scale divided straight back out of the recorded box.
## CoordinateSystem3M sets `scale = Vector3(1.5, 1.5, 1.5)`; the registry recorded
## 4.75 x 3.35 x 3.35 while the body a player walks around is 7.13 x 5.02 x 5.02.
##
## The scale belongs IN the number, because that is how the number is CONSUMED.
## `GridSystem.cube_size` is 1.0, so one grid cell is one world metre, and
## `sync_footprints.py` ceils `grid_cells` straight into `spatial_needs.
## footprint_cells`. `GridInteractablesComponent.gd:1080` applies a map token's
## scale as `artifact_object.scale *= scale_factor` — MULTIPLICATIVE — so the
## artifact's own root scale is present in the world body of every placement, and
## not one of the ~40 consumers of these numbers multiplies by anything. Recording
## root-local and storing the factor beside it was the alternative; it would have
## required every one of those consumers to learn a new field. The root scale is
## set in the artifact's own code, which makes it as intrinsic to the artifact as
## its mesh sizes. It goes in the number.
##
## But only the SCALE. The root's translation and rotation are still divided out,
## and measuring proved why: `XRToolsPickable` extends RigidBody3D, so
## `edible_mushroom` and the three grab cubes FALL about 1.5 m during the settle
## window, and `ruth_asawa_sculpture` spins on `rotation.y += rotation_speed *
## delta`. Their world placement is a function of when you looked, not a property
## of the artifact — a registry written from it would not reproduce between runs.
## Scale is authored, static and reproducible; the rigid part is not.
##
## The removal now happens PER MESH rather than on the merged box, which fixes a
## second fault of the old line for free: un-rotating an already-axis-aligned box
## can only grow it, so every artifact with a self-rotation was over-reported.
## `ruth_asawa_sculpture` measured 7.67 m wide that way against a true 5.54 m.
##
## Provenance carries `root_scale` and the exact old `root_local_size`, so the
## change stays auditable from the data alone.
##
## Rewritten 2026-08-11 against doc/plans/capture_measure_faults.md, which
## documented five faults in the dressing-room twin of this function. Three of
## them lived here too, and this path is the one that writes the registry every
## placement tool reads. What changed:
##
##   * particles no longer contribute `visibility_aabb`. That property defaults
##     to an 8x8x8 box, and propagating it is what produced the [8,8,1] epidemic
##     across 19 artifacts. Effects are SHOWN, not stood on — reported apart.
##   * hidden geometry is no longer body. `visible = false` means the player
##     never meets it.
##   * a top-level node has left the artifact's frame (set_as_top_level detaches
##     it), so it no longer drags the box back toward the world origin.
##   * text is reported as signage. It is authored to be read, not occupied.
##   * the result says how it was reached, so a fallback can never again be
##     mistaken for a measurement.
##
## Walks in GLOBAL space and converts per mesh, which also removes the
## old double-application of `child.transform` on nested subtrees.
func _measure_body(root: Node3D) -> AABB:
	# The recording frame: rigidly pinned to the artifact's own origin, carrying
	# the artifact's own scale. `ref` is the root's transform with the scale
	# taken out of the basis, so `ref_inv * mesh_global` leaves scale * mesh.
	var root_xform: Transform3D = root.global_transform
	var root_scale: Vector3 = root_xform.basis.get_scale()
	var ref_inv: Transform3D = Transform3D(
		root_xform.basis.orthonormalized(), root_xform.origin).affine_inverse()

	var body := AABB()
	# The old root-local box, accumulated in parallel purely so provenance can
	# state what this measurement used to be. Nothing consumes it.
	var body_root_local := AABB()
	var signage := AABB()
	var effects := AABB()
	var has_body := false
	var has_signage := false
	var has_effects := false
	var counted := 0
	var skipped_invisible := 0
	var skipped_top_level: Array[String] = []
	var widest := 0.0
	var widest_name := ""

	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n == null:
			continue
		for c in n.get_children():
			stack.push_back(c)
		if not (n is GeometryInstance3D):
			continue
		var vi := n as GeometryInstance3D

		if not vi.is_visible_in_tree():
			skipped_invisible += 1
			continue
		if vi.top_level:
			skipped_top_level.append(String(vi.name))
			continue

		var local := AABB()
		if vi is MultiMeshInstance3D:
			var mm = (vi as MultiMeshInstance3D).multimesh
			if mm == null or mm.instance_count <= 0:
				continue
			local = mm.get_aabb()
		elif vi is CSGShape3D:
			var meshes: Array = (vi as CSGShape3D).get_meshes()
			if meshes.size() < 2 or not (meshes[1] is Mesh):
				continue
			local = (meshes[1] as Mesh).get_aabb()
		else:
			local = vi.get_aabb()
		if local.size.length_squared() < 0.0001:
			continue

		var global_box: AABB = vi.global_transform * local
		var world: AABB = ref_inv * global_box

		if vi is Label3D or vi is Sprite3D:
			signage = world if not has_signage else signage.merge(world)
			has_signage = true
			continue
		if vi is GPUParticles3D or vi is CPUParticles3D:
			effects = world if not has_effects else effects.merge(world)
			has_effects = true
			continue

		var reach: float = Vector2(world.size.x, world.size.z).length()
		if reach > widest:
			widest = reach
			widest_name = String(vi.name)
		counted += 1
		body = world if not has_body else body.merge(world)
		body_root_local = (global_box if not has_body else body_root_local.merge(global_box))
		has_body = true

	# What this measurement used to say, computed exactly the old way: merge in
	# global space, then un-transform the merged box by the full root transform.
	var root_local: AABB = root_xform.affine_inverse() * body_root_local

	_last_measure = {
		"counted_meshes": counted,
		"skipped_invisible": skipped_invisible,
		"skipped_top_level": skipped_top_level,
		"widest_single_mesh_m": snappedf(widest, 0.001),
		"widest_single_mesh": widest_name,
		"signage": _aabb_dict(signage) if has_signage else null,
		"effects": _aabb_dict(effects) if has_effects else null,
		"fallback": not has_body,
		"settle_s": _settle,
		# The frame the number is in, said out loud, and the root transform that
		# used to be silently divided out of it.
		"frame": "root_rigid_scaled",
		"root_scale": [snappedf(root_scale.x, 0.0001), snappedf(root_scale.y, 0.0001),
			snappedf(root_scale.z, 0.0001)],
		"root_scale_applied": not root_scale.is_equal_approx(Vector3.ONE),
		# Reported, NOT applied — both are contaminated by physics settling and by
		# any animation running during the settle window.
		"root_position_unapplied": [snappedf(root_xform.origin.x, 0.001),
			snappedf(root_xform.origin.y, 0.001), snappedf(root_xform.origin.z, 0.001)],
		"root_rotation_deg_unapplied": [
			snappedf(rad_to_deg(root_xform.basis.get_euler().x), 0.01),
			snappedf(rad_to_deg(root_xform.basis.get_euler().y), 0.01),
			snappedf(rad_to_deg(root_xform.basis.get_euler().z), 0.01)],
		"root_local_size": [snappedf(root_local.size.x, 0.001),
			snappedf(root_local.size.y, 0.001), snappedf(root_local.size.z, 0.001)],
	}
	if not has_body:
		_last_measure["fallback_reason"] = (
			"no visible, non-signage, non-effect geometry in the subtree"
			+ (" (%d hidden, %d top-level skipped)" % [skipped_invisible, skipped_top_level.size()]))
		return AABB()
	return body


func _aabb_dict(a: AABB) -> Dictionary:
	return {
		"center": [snappedf(a.get_center().x, 0.001), snappedf(a.get_center().y, 0.001),
			snappedf(a.get_center().z, 0.001)],
		"size": [snappedf(a.size.x, 0.001), snappedf(a.size.y, 0.001), snappedf(a.size.z, 0.001)],
	}


## Kept so any other caller in the tree keeps working; body is what it measured.
func _get_combined_aabb(node: Node3D) -> AABB:
	return _measure_body(node)

# ══════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════

func _disable_processing_recursive(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_internal(false)
	node.set_physics_process_internal(false)
	for child in node.get_children():
		_disable_processing_recursive(child)

func _write_progress(path: String, body: String) -> void:
	var abs_path: String = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(body)
		file.close()


func _write_json(path: String, data: Dictionary) -> void:
	var abs_path: String = ProjectSettings.globalize_path(path)
	var dir_path: String = abs_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()
	else:
		push_error("measure_artifacts: Cannot write %s" % path)
