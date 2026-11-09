extends "res://tools/probes/void_game_probe.gd"
## HOW MANY WORKS OVERFLOW THE TOWER (Palle, 2026-11-09: "When we converted the artifacts from the endless museum, some
## of them were too big to fit the void tower, so they stand a bit strange in the tower. Can we conduct a survey of how
## many of the artifacts are overflowing"). Every floor in --floors is visited as a player would reach it; every mounted
## work's meshes are measured in the world (its placement, scale, facing and config all applied) and written raw:
## the box against the building (42 x 18 m, the slab, the headroom up to the floor above), the shafts and columns,
## whether it came from the museum and whether it is a deliberate exterior extension. tools/void_size_survey.py runs
## the floors in parallel chunks and turns the raw rows into the report.
var floors: Array = []

func world_box(host: Node3D) -> AABB:
	var result := AABB(); var first := true
	for node in host.find_children("*", "GeometryInstance3D", true, false):
		var g := node as GeometryInstance3D
		if not _counts(host, g): continue
		var bounds := _part_box(g)
		if bounds.size.length() < .001: continue
		result = bounds if first else result.merge(bounds); first = false
	return result

## Is there floor under the work? A 5 x 5 grid of rays over its footprint, from 0.4 m above the slab down to 0.4 m
## below it, ignoring the work's own bodies: "under" = samples with ground, "outside" = samples past the 42 x 18 m
## slab, "outside_held" = those of them that still find ground (a landing, a balcony, an extension).
func ground(host: Node3D, b: AABB, level: float) -> Dictionary:
	var space := game.get_world_3d().direct_space_state
	var own: Array[RID] = []
	for c in host.find_children("*", "CollisionObject3D", true, false): own.append((c as CollisionObject3D).get_rid())
	var hw: float = float(game.building.spec.width) / 2.0; var hd: float = float(game.building.spec.depth) / 2.0
	var under := 0; var outside := 0; var held := 0
	for i in 5:
		for j in 5:
			var x := lerpf(b.position.x + .05, b.end.x - .05, i / 4.0); var z := lerpf(b.position.z + .05, b.end.z - .05, j / 4.0)
			var q := PhysicsRayQueryParameters3D.create(Vector3(x, level + .4, z), Vector3(x, level - .4, z))
			q.exclude = own
			var hit := space.intersect_ray(q)
			var has := not hit.is_empty()
			if has: under += 1
			if absf(x) > hw + .05 or absf(z) > hd + .05:
				outside += 1
				if has: held += 1
	return {"under": under, "outside": outside, "outside_held": held}

## The three largest visible parts of a work (name, class, world box relative to the floor): what makes it big.
func largest(host: Node3D, level: float) -> Array:
	var parts := []
	for node in host.find_children("*", "GeometryInstance3D", true, false):
		var g := node as GeometryInstance3D
		if not _counts(host, g): continue
		var bounds := _part_box(g)
		if bounds.size.length() < .001: continue
		parts.append({"name": str(host.get_path_to(node)).right(70), "class": node.get_class(),
			"mesh": (node.mesh.get_class() if node is MeshInstance3D and node.mesh else ""),
			"box": [snappedf(bounds.position.x, .01), snappedf(bounds.position.y - level, .01), snappedf(bounds.position.z, .01),
				snappedf(bounds.end.x, .01), snappedf(bounds.end.y - level, .01), snappedf(bounds.end.z, .01)],
			"extent": snappedf(maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)), .01)})
	parts.sort_custom(func(a, b): return a.extent > b.extent)
	return parts.slice(0, 3)

## A part that takes up room in THIS floor: visible, drawn, in the tower's own world (a film's picture is a scene in a
## SubViewport - its own world, whose coordinates mean nothing here), and not an edge overlay that only traces its mesh.
## A part's world box. A box carried through a turned transform grows (a cylinder's box at 45 degrees is 1.41 times
## its width), so a turned part with a modest mesh is measured from its vertices instead: round stays round.
func _part_box(g: GeometryInstance3D) -> AABB:
	var mesh: Mesh = null
	var xforms: Array[Transform3D] = []
	if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
		mesh = (g as MeshInstance3D).mesh; xforms.append(g.global_transform)
	elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null and (g as MultiMeshInstance3D).multimesh.instance_count > 0:
		var mm := (g as MultiMeshInstance3D).multimesh
		if mm.mesh == null or mm.transform_format != MultiMesh.TRANSFORM_3D: return g.global_transform * mm.get_aabb()
		mesh = mm.mesh
		# only the instances that are drawn: visible_instance_count, and not one parked at zero scale
		var shown: int = mm.instance_count if mm.visible_instance_count < 0 else mini(mm.visible_instance_count, mm.instance_count)
		for i in shown:
			var it := mm.get_instance_transform(i)
			if absf(it.basis.determinant()) < 1e-9: continue
			xforms.append(g.global_transform * it)
		if xforms.is_empty(): return AABB()
	elif g is CSGShape3D:
		return g.global_transform * (g as CSGShape3D).get_aabb()
	else:
		return AABB()
	var local := mesh.get_aabb()
	var turned := false
	for t in xforms:
		var b := t.basis.orthonormalized()
		for axis in [b.x, b.y, b.z]:
			if absf(absf(axis.x) + absf(axis.y) + absf(axis.z) - 1.0) > .02: turned = true
	if not turned or mesh is ImmediateMesh:
		var r := xforms[0] * local
		for t in xforms: r = r.merge(t * local)
		return r
	var faces := mesh.get_faces()
	if faces.size() * xforms.size() > 400000:
		var r2 := xforms[0] * local
		for t in xforms: r2 = r2.merge(t * local)
		return r2
	var lo := Vector3.INF; var hi := -Vector3.INF
	for t in xforms:
		for v in faces:
			var w := t * v
			lo = lo.min(w); hi = hi.max(w)
	return AABB(lo, hi - lo)

func _counts(host: Node3D, g: GeometryInstance3D) -> bool:
	if not g.is_visible_in_tree() or g.layers == 0: return false
	if g.get_viewport() != host.get_viewport(): return false
	# a soft body's vertices live in the physics world, not under its transform: its mesh box is not where it hangs
	if g is SoftBody3D: return false
	var n := str(g.name)
	return not (n.begins_with("EdgeOutline") or n.begins_with("MeshInspectionEdges"))

func _extension(mount: Node) -> bool:
	if mount.is_in_group("void_exterior_walk") or mount.is_in_group("void_floor_extension"): return true
	for n in mount.find_children("*", "Node", true, false):
		if n.is_in_group("void_floor_extension") or n.is_in_group("void_exterior_walk"): return true
	return false

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--floors="):
			for s in arg.trim_prefix("--floors=").split(","): floors.append(int(s))
	Engine.physics_ticks_per_second = 60
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = floors[0]
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(90)
	var spec = game.building.spec
	var survey := {"building": {"width": spec.width, "depth": spec.depth, "slab": spec.slab_thickness, "shafts": spec.shafts,
		"shaft_width": spec.shaft_width, "shaft_depth": spec.shaft_depth, "column_x": spec.column_x, "column_z": spec.column_z,
		"column_width": spec.column_width}, "floors": {}}
	for f in floors:
		var t0 := Time.get_ticks_msec()
		game.place_player(game.spawn_for(f))
		var data: Dictionary = game.building.content.data.floors[f]
		var items: Array = data.get("artifacts", []) + data.get("copies", [])
		for i in 900:
			await frames(1)
			if i > 60 and items.all(func(a): return game.building.content.exhibits.has("%d/%s" % [f, a.id])): break
		await frames(45)   # works that build a frame or a second after _ready
		var level: float = float(spec.levels[f])
		var ceiling: float = INF if f == 0 else float(spec.levels[f - 1]) - float(spec.slab_thickness)
		var rows := []
		for a in items:
			var key := "%d/%s" % [f, a.id]
			var mount: Node3D = game.building.content.exhibits.get(key)
			var cfg: Dictionary = a.get("config", {}) if a.get("config", {}) is Dictionary else {}
			var row := {"id": a.id, "token": a.artifact, "at": a.position, "height": a.get("height", 0), "scale": a.get("scale", 1),
				"facing": a.get("facing", 0), "museum": str(a.id).begins_with("museum-") or cfg.has("museum_origin"),
				"copy": a in data.get("copies", [])}
			if mount == null or not is_instance_valid(mount):
				row["mounted"] = false; rows.append(row); continue
			var b := world_box(mount)
			row["mounted"] = true
			row["soft_bodies"] = mount.find_children("*", "SoftBody3D", true, false).size()
			row["extension"] = _extension(mount)
			if b.size.length() < .01:
				row["box"] = null
			else:
				row["box"] = [snappedf(b.position.x, .01), snappedf(b.position.y - level, .01), snappedf(b.position.z, .01),
					snappedf(b.end.x, .01), snappedf(b.end.y - level, .01), snappedf(b.end.z, .01)]
				row["parts"] = largest(mount, level)
				row["ground"] = ground(mount, b, level)
			rows.append(row)
		survey.floors[str(f)] = {"map": str(data.get("map", "")), "title": str(data.get("title", "")), "level": level,
			"headroom": snappedf(ceiling - level, .01) if ceiling < INF else null, "works": rows, "ms": Time.get_ticks_msec() - t0}
		FileAccess.open(out.path_join("survey.json"), FileAccess.WRITE).store_string(JSON.stringify(survey, " ", false))
		check("floor %d %s: %d works measured" % [f, data.get("map", ""), rows.size()], true)
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": true, "checks": checks, "failed": failed}, "  "))
	print("[void_size_survey] %d floors" % floors.size())
	quit(0)
