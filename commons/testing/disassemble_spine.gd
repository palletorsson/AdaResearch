extends SceneTree
## Disassemble the spine (Palle, 25 Oct: "can we disassemble to extract the element and
## categorize every artifact in the spine?"). For every artifact a sequence places, instantiate
## its scene, let it build for two frames, and read the ELEMENTS off the tree it actually made:
## meshes by shape and size, colliders by shape, bodies, joints, lights, labels, particles,
## multimeshes (a replicate with its count), and whether a script runs per frame (an engine).
## One JSON line per artifact, flushed at once, so a run the watchdog kills keeps what it did;
## a token already in the ledger is skipped, so the run resumes.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/disassemble_spine.gd -- --seq=<name> [--out=res://ada_run/disassembly]
##   --seq=modular reads the mod_ tokens (the grammar's terms) the same way
##
## Driven by tools/disassemble_spine.py, which runs the 25 sequences under the 16-second
## watchdog, marks the artifact a kill interrupted as "hang", and categorises the result.

const SPAWNLISTS := "res://commons/data/void_spawnlists.json"

var _seq := ""
var _out := "res://ada_run/disassembly"


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seq="):
			_seq = a.trim_prefix("--seq=")
		elif a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
	call_deferred("_run")


func _run() -> void:
	var f := FileAccess.open(SPAWNLISTS, FileAccess.READ)
	if f == null:
		print("DISASSEMBLE no spawnlists")
		quit(1)
		return
	var sl: Dictionary = JSON.parse_string(f.get_as_text())
	var items: Dictionary = sl.get("items", {})
	var tokens: Array = []
	if _seq == "modular":
		# the grammar's own terms, read by the SAME reader as the artifacts (one measure for both)
		for k in items:
			var key := str(k)
			if key.begins_with("mod_") and key.find("handmade_pallet") < 0:
				tokens.append(key)
	for seq in sl["trees"][0]["children"]:
		if _seq != "" and str(seq["id"]) != _seq:
			continue
		for m in seq["children"]:
			for t in m["items"]:
				var tok: String = str(t).split("@")[0]
				if not tokens.has(tok):
					tokens.append(tok)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	var ledger_path := "%s/%s.jsonl" % [_out, _seq if _seq != "" else "all"]
	var done := {}
	if FileAccess.file_exists(ledger_path):
		var lf := FileAccess.open(ledger_path, FileAccess.READ)
		while not lf.eof_reached():
			var line := lf.get_line().strip_edges()
			if line == "":
				continue
			var row: Variant = JSON.parse_string(line)
			if row is Dictionary and row.has("token"):
				done[row["token"]] = true
		lf.close()
	var out: FileAccess
	if FileAccess.file_exists(ledger_path):
		out = FileAccess.open(ledger_path, FileAccess.READ_WRITE)
		out.seek_end()
	else:
		out = FileAccess.open(ledger_path, FileAccess.WRITE)
	if out == null:
		print("DISASSEMBLE cannot open ledger ", ledger_path)
		quit(1)
		return
	var marker_path := "%s/_in_progress.txt" % _out
	var n_done := 0
	for tok in tokens:
		if done.has(tok):
			continue
		var info: Dictionary = items.get(tok, items.get("kit:" + tok, items.get("prop:" + tok, {})))
		var scene_path: String = str(info.get("scene", ""))
		# the marker names the artifact in progress, so a kill can be charged to it
		var mk := FileAccess.open(marker_path, FileAccess.WRITE)
		mk.store_string(JSON.stringify({"seq": _seq, "token": tok, "scene": scene_path}))
		mk.close()
		var row := await _disassemble(tok, scene_path)
		out.store_line(JSON.stringify(row))
		out.flush()
		n_done += 1
	var mk2 := FileAccess.open(marker_path, FileAccess.WRITE)
	mk2.store_string("")
	mk2.close()
	out.close()
	print("DISASSEMBLE seq=%s artifacts=%d new=%d" % [_seq, tokens.size(), n_done])
	quit(0)


func _disassemble(tok: String, scene_path: String) -> Dictionary:
	var row := {"token": tok, "scene": scene_path, "ok": false}
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		row["error"] = "no scene"
		return row
	var ps: Variant = load(scene_path)
	if not (ps is PackedScene):
		row["error"] = "not a PackedScene"
		return row
	var inst: Node = (ps as PackedScene).instantiate()
	if tok.begins_with("mod_"):
		inst.set("term", tok.substr(4))   # a modular token's registry config, as a map would apply it
	root.add_child(inst)
	await process_frame
	await process_frame
	var e := {"nodes": 0, "meshes": [], "colliders": [], "bodies": {}, "joints": 0, "lights": 0, "labels": 0,
		"particles": 0, "multimesh": [], "engine": false, "scripts": [], "classes": {}, "audio": 0, "cameras": 0, "viewports": 0}
	_walk(inst, e, Transform3D.IDENTITY)
	# the whole thing's bounds, from its meshes
	var box := AABB()
	var has := false
	for m in e["meshes"]:
		var c: Array = m["centre"]
		var s: Array = m["size"]
		var b := AABB(Vector3(c[0] - s[0] / 2.0, c[1] - s[1] / 2.0, c[2] - s[2] / 2.0), Vector3(s[0], s[1], s[2]))
		box = b if not has else box.merge(b)
		has = true
	row["ok"] = true
	row["elements"] = e
	row["bounds"] = [snapped(box.size.x, 0.001), snapped(box.size.y, 0.001), snapped(box.size.z, 0.001)] if has else null
	inst.queue_free()
	await process_frame
	return row


func _walk(n: Node, e: Dictionary, xform: Transform3D) -> void:
	e["nodes"] += 1
	var cls := n.get_class()
	e["classes"][cls] = int(e["classes"].get(cls, 0)) + 1
	var t: Transform3D = xform
	if n is Node3D:
		t = xform * (n as Node3D).transform
	var script: Variant = n.get_script()
	if script != null and script is Script:
		var path: String = (script as Script).resource_path
		var short := path.get_file()
		if not e["scripts"].has(short):
			e["scripts"].append(short)
		if n.has_method("_process") or n.has_method("_physics_process"):
			# only scripts that OVERRIDE a tick are engines; Node always "has" the method
			var sc: Script = script
			var code: String = sc.source_code if sc.has_method("get_source_code") or true else ""
			if code.find("func _process(") >= 0 or code.find("func _physics_process(") >= 0:
				e["engine"] = true
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var mi := n as MeshInstance3D
		var aabb: AABB = t * mi.mesh.get_aabb()
		var shape := mi.mesh.get_class().replace("Mesh", "").to_lower()
		if shape == "array" or shape == "immediate":
			shape = "custom"
		var col := ""
		var mat: Material = mi.material_override if mi.material_override != null else mi.mesh.surface_get_material(0) if mi.mesh.get_surface_count() > 0 else null
		if mat == null and mi.get_surface_override_material_count() > 0:
			mat = mi.get_surface_override_material(0)
		if mat is BaseMaterial3D:
			col = (mat as BaseMaterial3D).albedo_color.to_html(false)
		elif mat is ShaderMaterial:
			col = "shader"
		# a hand-made or generated mesh records its triangle count: a surface from a function
		# (terrain, isosurface, procedural skin) has hundreds; a hand-wound tetrahedron has four
		var tris := 0
		if not (mi.mesh is PrimitiveMesh):
			tris = mi.mesh.get_faces().size() / 3
		e["meshes"].append({"shape": shape, "size": [snapped(aabb.size.x, 0.001), snapped(aabb.size.y, 0.001), snapped(aabb.size.z, 0.001)],
			"centre": [snapped(aabb.get_center().x, 0.001), snapped(aabb.get_center().y, 0.001), snapped(aabb.get_center().z, 0.001)], "color": col, "tris": tris})
	elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
		var mm := (n as MultiMeshInstance3D).multimesh
		e["multimesh"].append({"count": mm.instance_count, "shape": (mm.mesh.get_class().replace("Mesh", "").to_lower() if mm.mesh != null else "none")})
	elif n is CollisionShape3D and (n as CollisionShape3D).shape != null:
		e["colliders"].append((n as CollisionShape3D).shape.get_class().replace("Shape3D", "").to_lower())
	elif n is CollisionPolygon3D:
		e["colliders"].append("polygon")
	elif n is PhysicsBody3D:
		var k := "static" if n is StaticBody3D else ("rigid" if n is RigidBody3D else ("character" if n is CharacterBody3D else "body"))
		e["bodies"][k] = int(e["bodies"].get(k, 0)) + 1
	elif n is Area3D:
		e["bodies"]["area"] = int(e["bodies"].get("area", 0)) + 1
	elif n is Joint3D:
		e["joints"] += 1
	elif n is Light3D:
		e["lights"] += 1
	elif n is Label3D or n is Label or n is RichTextLabel:
		e["labels"] += 1
	elif n is GPUParticles3D or n is CPUParticles3D:
		e["particles"] += 1
	elif n is AudioStreamPlayer or n is AudioStreamPlayer3D:
		e["audio"] += 1
	elif n is Camera3D:
		e["cameras"] += 1
	elif n is SubViewport:
		e["viewports"] += 1
	for c in n.get_children():
		_walk(c, e, t)
