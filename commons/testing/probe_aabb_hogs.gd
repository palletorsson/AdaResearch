extends SceneTree
## probe_aabb_hogs.gd — which mesh is making the camera stand so far back?
##
## Every capture rig in this project frames its subject from the merged AABB of the
## subject's MeshInstance3D children. That is the right default and it fails silently in
## one specific way: ONE oversized, often nearly-invisible mesh — a shadow quad, a floor
## decal, a ground plane, a debug gizmo — inflates the merged box, the camera retreats to
## fit it, and the actual artifact renders as a thumbnail in an empty field.
##
## The damage is not cosmetic. curation_station (451 placements) measured 0.68% changed
## area between variants that add and remove a 2.6 m wall, and the DNA critic called the
## axis INERT. The axis was fine; the subject was 5% of the frame. A capture problem had
## been promoted to a verdict about a design.
##
## So this reports the merged AABB and then every mesh ranked by how much it contributes,
## with flatness and screen-relevant extent, so an outlier is obvious rather than inferred.
##
## Run:
##   godot --path . --xr-mode off --headless --script res://commons/testing/probe_aabb_hogs.gd \
##       -- --scene=res://commons/artifacts/station/curation_station.tscn [--set=bay=hall]

func _initialize() -> void:
	var scene_path: String = ""
	var sets: Dictionary = {}
	var top: int = 12
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene_path = a.split("=", 1)[1]
		elif a.begins_with("--set="):
			var kv: PackedStringArray = a.split("=", 2)
			if kv.size() >= 3:
				sets[kv[1]] = kv[2]
		elif a.begins_with("--top="):
			top = int(a.split("=", 1)[1])
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		print("probe_aabb_hogs: --scene=res://... required")
		quit(2)
		return
	_run(scene_path, sets, top)


func _run(scene_path: String, sets: Dictionary, top: int) -> void:
	var inst: Node = (load(scene_path) as PackedScene).instantiate()
	for k in sets.keys():
		if k in inst:
			# Set BEFORE add_child so _ready() builds that variant. A value assigned after
			# the node is in the tree is a default wearing a costume.
			inst.set(k, sets[k])
	root.add_child(inst)
	# SETTLE, matching capture_config_sweep.gd. Two process frames is not enough for a
	# composite that defers part of its build: with only two frames this probe reported an
	# identical 209 meshes for every value of every axis INCLUDING with_wall, a legacy flag
	# 451 map placements set — a result that indicted the artifact when the fault was the
	# probe looking too early.
	await create_timer(0.35).timeout
	await process_frame

	var rows: Array = []
	var merged := AABB()
	var have := false
	var stack: Array = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			var wab: AABB = mi.global_transform * mi.get_aabb()
			if have:
				merged = merged.merge(wab)
			else:
				merged = wab
				have = true
			var s: Vector3 = wab.size
			var dims: Array = [s.x, s.y, s.z]
			dims.sort()
			rows.append({
				"name": String(mi.name),
				"path": String(inst.get_path_to(mi)),
				"span": s.length(),
				"size": s,
				"vis": mi.visible,
				# A big-but-paper-thin mesh is the classic offender: a shadow quad or a
				# floor decal reads as enormous to a bounding box and as nothing to a
				# viewer, so flatness is reported next to span rather than left implied.
				"flat": dims[0] < 0.02,
			})
		for c in n.get_children():
			stack.append(c)
	rows.sort_custom(func(a, b): return a["span"] > b["span"])

	print("\nMERGED AABB  pos %s  size %s  diagonal %.2f m"
		% [merged.position, merged.size, merged.size.length()])
	print("%d mesh(es). Largest by world-space diagonal:\n" % rows.size())
	print("%-34s %9s %26s %6s %6s" % ["node", "diag", "size (x,y,z)", "flat", "vis"])
	for i in range(mini(top, rows.size())):
		var r: Dictionary = rows[i]
		print("%-34s %8.2fm  (%6.2f,%6.2f,%6.2f) %6s %6s"
			% [r["name"].left(34), r["span"], r["size"].x, r["size"].y, r["size"].z,
				"FLAT" if r["flat"] else "", "" if r["vis"] else "HIDDEN"])

	# What the box would be if the single biggest mesh were excluded — the number that
	# says whether one outlier is responsible or the artifact is simply large.
	if rows.size() > 1:
		var second := AABB()
		var have2 := false
		var stack2: Array = [inst]
		var skip: String = rows[0]["path"]
		while not stack2.is_empty():
			var n2: Node = stack2.pop_back()
			if n2 is MeshInstance3D and String(inst.get_path_to(n2)) != skip:
				var w2: AABB = (n2 as MeshInstance3D).global_transform * (n2 as MeshInstance3D).get_aabb()
				if have2:
					second = second.merge(w2)
				else:
					second = w2
					have2 = true
			for c2 in n2.get_children():
				stack2.append(c2)
		if have2:
			print("\nwithout '%s': diagonal %.2f m (was %.2f) — %.0f%% smaller"
				% [rows[0]["name"], second.size.length(), merged.size.length(),
					100.0 * (1.0 - second.size.length() / maxf(merged.size.length(), 0.001))])
	quit()
