extends SceneTree
## THE WALLS WEAR THE GROUP (2026-08-25, Palle: "many pattern maker artifacts
## have the same base. Can we connect them to the wall and floor making of the
## endless museum"). Builds a hall that declares museum.pattern and asks the
## built geometry what its walls and floors are made of — a texture, or the
## plaster it always was.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_hall_pattern.gd -- --map=Symmetry_Seventeen --chapter=color

const OUT := "res://ada_run/hall_pattern.txt"


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _run() -> void:
	var map_name := _arg("map", "Symmetry_Seventeen")
	var chapter := _arg("chapter", "color")
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_hp_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("start_chapter", chapter)
	inst.set("start_map", map_name)
	var ctl := FileAccess.open("res://ada_run/_trial_hp_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": chapter, "first_map": map_name,
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.5).timeout
	inst.call("flush_stamps")
	await create_timer(1.5).timeout

	var rep := "THE HALL'S PATTERN — %s\n" % map_name
	var seg: Node3D = null
	for s_v in inst.get("_segments"):
		var sd: Dictionary = s_v
		if String(sd.get("map", "")) == map_name:
			seg = sd.get("node")
	if seg == null:
		rep += "  FAIL the hall never built\n"
	else:
		# every distinct material the hall's boxes are made of
		var seen: Dictionary = {}
		# THE ARCHITECTURE IS A MULTIMESH (2026-08-25). _box batches every wall,
		# floor and podium by MATERIAL and _flush_boxes emits one
		# MultiMeshInstance3D per material — so counting MeshInstance3D counts
		# the ARTIFACTS and almost none of the building. Three runs of this
		# probe reported "2 meshes" and read as a half-working feature.
		var surfaces: Array = []
		for mm_v in seg.find_children("*", "MultiMeshInstance3D", true, false):
			var mmi := mm_v as MultiMeshInstance3D
			var n: int = mmi.multimesh.instance_count if mmi.multimesh != null else 0
			surfaces.append({"mat": mmi.material_override if mmi.material_override != null
				else (mmi.multimesh.mesh.surface_get_material(0) if mmi.multimesh != null
				and mmi.multimesh.mesh != null else null), "n": n})
		for sv2 in surfaces:
			var sd2: Dictionary = sv2
			var mat2: Variant = sd2["mat"]
			if not (mat2 is Material):
				continue
			var id2b: int = (mat2 as Material).get_instance_id()
			var tex2: Texture2D = (mat2 as StandardMaterial3D).albedo_texture if mat2 is StandardMaterial3D else null
			if seen.has(id2b):
				seen[id2b]["n"] += int(sd2["n"])
			else:
				seen[id2b] = {"n": int(sd2["n"]), "tex": tex2 != null,
					"size": ("%dx%d" % [tex2.get_width(), tex2.get_height()]) if tex2 != null else "-",
					"uv": str((mat2 as StandardMaterial3D).uv1_scale) if mat2 is StandardMaterial3D else "-"}
		for mi_v in seg.find_children("*", "MeshInstance3D", true, false):
			var mi := mi_v as MeshInstance3D
			var mat := mi.get_active_material(0)
			if mat == null:
				continue
			var id: int = mat.get_instance_id()
			if seen.has(id):
				seen[id]["n"] += 1
				continue
			var tex: Texture2D = null
			if mat is StandardMaterial3D:
				tex = (mat as StandardMaterial3D).albedo_texture
			seen[id] = {"n": 1, "tex": tex != null,
				"size": ("%dx%d" % [tex.get_width(), tex.get_height()]) if tex != null else "-",
				"uv": str((mat as StandardMaterial3D).uv1_scale) if mat is StandardMaterial3D else "-"}
		# ONLY THE MUSEUM'S OWN (2026-08-25): every wall card, screen and
		# artifact carries a texture of its own, and counting those made the
		# first run report thirty patterned materials when two meshes had
		# actually changed. The museum renders at 192 square; nothing else does.
		var want_size := "192x192"   # a Vector2 stringifies as (192.0, 192.0)
		var mine := 0
		var mine_meshes := 0
		for id in seen:
			var e: Dictionary = seen[id]
			if String(e["size"]) == want_size:
				mine += 1
				mine_meshes += int(e["n"])
				rep += "  hall surface  %5d mesh(es)  %s  uv %s
" % [e["n"], e["size"], e["uv"]]
		rep += "  %d material(s) in the hall; %d are the museum's pattern, on %d mesh(es)
" % [
			seen.size(), mine, mine_meshes]
		# WHAT THE HALL IS MOSTLY MADE OF, so a small number can be read: the
		# museum draws floors and wall runs as a FEW LARGE SLABS, so "2 meshes"
		# may be the whole floor or may be nothing at all
		var rank: Array = []
		for id2 in seen:
			rank.append({"n": int((seen[id2] as Dictionary)["n"]), "id": id2,
				"size": String((seen[id2] as Dictionary)["size"])})
		rank.sort_custom(func(a, b): return int(a["n"]) > int(b["n"]))
		# NAME THE ROLE, do not guess it: match each material instance against
		# the museum's own pool, so "60 meshes of something" becomes "60 meshes
		# of _sm(\"wall_white\")" and the fix has an address
		var roles: Array = ["wall", "wall_white", "deck", "floor", "podium", "plinth",
			"corner", "skin", "ceiling", "seam", "prop", "glass", "frame", "card"]
		var role_of: Dictionary = {}
		for r_v in roles:
			var rm: Variant = inst.call("_sm", String(r_v))
			if rm is Material:
				role_of[(rm as Material).get_instance_id()] = String(r_v)
		rep += "  the hall's biggest surfaces:
"
		for k in range(mini(6, rank.size())):
			rep += "    %5d mesh(es)  texture %-8s  role %s
" % [int(rank[k]["n"]),
				String(rank[k]["size"]), String(role_of.get(int(rank[k]["id"]), "(not a pool material)"))]
		rep += "  %s
" % ("PASS the architecture wears the pattern base" if mine_meshes >= 2
			else "FAIL only %d mesh(es) changed - wrong role" % mine_meshes)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
