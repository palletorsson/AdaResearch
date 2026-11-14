extends SceneTree
## THE EDGE CARVING ON THE BENCH (2026-11-14), headless. The tower ADDS a work and THEN calls apply_grid_config
## (floor_content.gd), and the floor's residency pauses it while it builds (process DISABLED, then INHERIT). Built in
## that order, a carving that builds in _ready and again on its config makes two of everything in one frame: the first
## set is only queued for freeing, so the second is renamed, and the tower photographed seven plinths of words with no
## stone on them (ada_run/improve/stickers/tower3, 11-14). This bench builds every kind in the tower's order and asks:
##   B1  one stone per carving, named Stone, with a mesh; one plinth; three labels (one set of words)
##   B2  the config reached the build (the kind's own label, the reading's own words)
##   B3  every kind's carving bites: more triangles than the plain column
##   B4  the stone keeps its mesh through the residency's pause and restore
## Writes <out>/edge_carving_bench.json, exit code = failed checks.
##   godot --headless --path . --xr-mode off --script res://tools/probes/edge_carving_bench.gd -- --out=<dir>
const Carving := preload("res://commons/artifacts/edge_carving/edge_carving.gd")
const ROW := [["cannot_claim", "cantor_limit"], ["leaves_out", "hand_delight"], ["still_open", "whose_body"], ["not_yet", "held_the_edge"],
	["foreclosed", "fit_the_rails"], ["dark_spot", "body_knows"], ["does_not_fit", "surface_carries"]]


func _initialize() -> void:
	run.call_deferred()


func _faces(stone: CSGShape3D) -> int:
	var meshes: Array = stone.get_meshes()
	if meshes.size() < 2 or meshes[1] == null: return 0
	return (meshes[1] as Mesh).get_faces().size() / 3


func _stones(c: Node) -> Array:
	var out := []
	for n in c.get_children():
		if n is CSGCombiner3D: out.append(n)
	return out


func run() -> void:
	var out := "user://edge_carving_bench"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var world := Node3D.new()
	root.add_child(world)
	# the plain column, for B3's floor: the carving's own cylinder with nothing taken out
	var plain := CSGCombiner3D.new()
	var cyl := CSGCylinder3D.new()
	cyl.radius = Carving.COL_R
	cyl.height = Carving.COL_H
	cyl.sides = 64
	plain.add_child(cyl)
	world.add_child(plain)
	# every kind, in the tower's order: a paused mount, the work added with its defaults, THEN its config, then live
	var mounts := []
	for i in ROW.size():
		var mount := Node3D.new()
		mount.process_mode = Node.PROCESS_MODE_DISABLED
		mount.position = Vector3(i * 2.0, 0, 0)
		world.add_child(mount)
		var c: Node3D = Carving.new()
		c.name = "Artifact"
		mount.add_child(c)
		c.apply_grid_config({"kind": ROW[i][0], "reading": ROW[i][1], "seed": i + 1, "editor_label": "bench"})
		mount.process_mode = Node.PROCESS_MODE_INHERIT
		mounts.append(mount)
	for f in 4: await process_frame
	var plain_faces := _faces(plain)
	var rows := []
	var b1 := true
	var b2 := true
	var b3 := true
	for i in ROW.size():
		var c: Node3D = mounts[i].get_node("Artifact")
		var stones := _stones(c)
		var labels := c.find_children("*", "Label3D", false, false)
		var plinths := c.find_children("*", "StaticBody3D", false, false)
		var faces := _faces(stones[0]) if stones.size() == 1 else -1
		var texts := []
		for l in labels: texts.append((l as Label3D).text)
		var row := {"kind": ROW[i][0], "stones": stones.size(), "names": stones.map(func(s): return str(s.name)),
			"plinths": plinths.size(), "labels": labels.size(), "faces": faces, "texts": texts}
		rows.append(row)
		b1 = b1 and stones.size() == 1 and str(stones[0].name) == "Stone" and faces > 0 and plinths.size() == 1 and labels.size() == 3
		b2 = b2 and labels.size() >= 2 and texts[0] == Carving.KINDS[ROW[i][0]].label and str(texts[1]).length() > 8
		b3 = b3 and faces > plain_faces
	# B4: the residency's pause (process DISABLED, the mount hidden) and restore, then the meshes again
	for m in mounts:
		m.process_mode = Node.PROCESS_MODE_DISABLED
		m.visible = false
	for f in 3: await process_frame
	for m in mounts:
		m.visible = true
		m.process_mode = Node.PROCESS_MODE_INHERIT
	for f in 3: await process_frame
	var b4 := true
	for m in mounts:
		var stones := _stones(m.get_node("Artifact"))
		b4 = b4 and stones.size() == 1 and _faces(stones[0]) > 0
	var checks := [
		{"check": "B1 built in the tower's order (added, then configured), each carving has one stone named Stone with a mesh, one plinth, three labels", "ok": b1},
		{"check": "B2 the config reached the build: the kind's own label and the reading's own words", "ok": b2},
		{"check": "B3 every kind's carving bites: more triangles than the plain column (%d)" % plain_faces, "ok": b3},
		{"check": "B4 each stone keeps its mesh through the residency's pause and restore", "ok": b4},
	]
	var failed := 0
	for c in checks:
		if not c.ok: failed += 1
		print(("ok  " if c.ok else "NO  ") + c.check)
	for r in rows: print("    ", JSON.stringify(r))
	var f := FileAccess.open(out.path_join("edge_carving_bench.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed": failed == 0, "checks": checks, "rows": rows, "plain_faces": plain_faces}, "\t"))
	f.close()
	quit(failed)
