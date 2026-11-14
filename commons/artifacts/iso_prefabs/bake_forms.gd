extends SceneTree
## BAKE THE ISOSURFACE PREFABS (Boolean_Verbs; the boolean floor, 2026-11-13)
##
## tools/iso_prefabs.py marches each form's signed-distance expression into a mesh and writes it - with vertex colour as
## DATA (r a difference cut the face, g an intersection trimmed it, b a smooth union's band, a ambient occlusion baked from
## the field), a coarser march for collision - to ada_run/iso_prefabs/<form>.bin (format ISO2). This turns those
## into what the game loads: forms/<form>.res, one ArrayMesh per form, simplified by the engine's own meshoptimizer to a
## triangle budget, with its distance LODs, and carrying in its metadata what the artifact needs to stand it up - the
## collision faces (simplified the same way) or, for a convex form, the points of its hull - and the form's title,
## verb, expression and principle for its plaque.
##
##   python tools/iso_prefabs.py export
##   godot --headless --path . --xr-mode off --script res://commons/artifacts/iso_prefabs/bake_forms.gd [-- form ...]
##
## The meshes are derived: regenerate both steps after a change to a form. forms/report.json says what each became.
const SOURCE := "res://ada_run/iso_prefabs/"
const TARGET := "res://commons/artifacts/iso_prefabs/forms/"
## Triangles a form may keep near the eye, by its size, and for collision.
const BUDGET_SMALL := 3500
const BUDGET_LARGE := 9000
const COLLISION_BUDGET := 2400


func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE + "manifest.json"))
	var only := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TARGET))
	var report := {}
	var old_report: Variant = JSON.parse_string(FileAccess.get_file_as_string(TARGET + "report.json")) if FileAccess.file_exists(TARGET + "report.json") else null
	if old_report is Dictionary: report = old_report
	# JSON reads every number back as a float: whole ones go back to ints, so rebaking one form changes only its row
	for form in report:
		if report[form] is Dictionary:
			for key in report[form]:
				var v: Variant = report[form][key]
				if v is float and is_equal_approx(v, roundf(v)): report[form][key] = int(v)
	for form in manifest:
		if not only.is_empty() and not only.has(form): continue
		report[form] = _bake(str(form), manifest[form])
		print("[bake_forms] ", form, " ", JSON.stringify(report[form]))
	var file := FileAccess.open(TARGET + "report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t", false))
	file.close()
	quit()


func _bake(form: String, info: Dictionary) -> Dictionary:
	var f := FileAccess.open(SOURCE + form + ".bin", FileAccess.READ)
	if f == null or f.get_buffer(4).get_string_from_ascii() != "ISO2":
		return {"error": "no bin"}
	var nv := f.get_32()
	var ni := f.get_32()
	var ns := f.get_32()
	var nh := f.get_32()
	var pos := f.get_buffer(nv * 12).to_float32_array()
	var nrm := f.get_buffer(nv * 12).to_float32_array()
	var col := f.get_buffer(nv * 16).to_float32_array()
	var idx := f.get_buffer(ni * 4).to_int32_array()
	var soup := f.get_buffer(ns * 12).to_float32_array()
	var hull := f.get_buffer(nh * 12).to_float32_array()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	verts.resize(nv)
	normals.resize(nv)
	colours.resize(nv)
	for i in nv:
		verts[i] = Vector3(pos[3 * i], pos[3 * i + 1], pos[3 * i + 2])
		normals[i] = Vector3(nrm[3 * i], nrm[3 * i + 1], nrm[3 * i + 2])
		colours[i] = Color(col[4 * i], col[4 * i + 1], col[4 * i + 2], col[4 * i + 3])
	# the bench winds each face counter-clockwise seen from outside; Godot's front faces are clockwise
	for t in ni / 3:
		var keep := idx[3 * t + 1]
		idx[3 * t + 1] = idx[3 * t + 2]
		idx[3 * t + 2] = keep
	var size: Array = info.get("dimensions", [1, 1, 1])
	var large: bool = float(size[0]) * float(size[2]) > 2.0 or float(size[1]) > 1.6
	var budget: int = int(info.get("budget", 0)) if int(info.get("budget", 0)) > 0 else (BUDGET_LARGE if large else BUDGET_SMALL)
	var near := _simplify(verts, normals, colours, idx, budget)
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, near.arrays)
	im.generate_lods(25.0, 60.0, [])
	var mesh: ArrayMesh = im.get_mesh()
	mesh.resource_name = form
	for key in ["title", "verb", "expression", "principle", "rigid", "mass", "dimensions", "aabb"]:
		if info.has(key): mesh.set_meta(key, info[key])
	if info.get("centroid") is Array:
		var c: Array = info["centroid"]
		mesh.set_meta("centroid", Vector3(float(c[0]), float(c[1]), float(c[2])))
	mesh.set_meta("form", form)
	var extras: Dictionary = info.get("extras", {}) if info.get("extras") is Dictionary else {}
	if extras.has("paths"):                     # a carving: the path(s) its cutters were set along, for the demo's orange line
		var paths := []
		for path in extras["paths"]:
			var line := PackedVector3Array()
			for q in path: line.append(Vector3(float(q[0]), float(q[1]), float(q[2])))
			paths.append(line)
		mesh.set_meta("paths", paths)
		mesh.set_meta("line", bool(extras.get("line", true)))
		for key in ["seed", "cutters", "pattern"]:
			if extras.has(key): mesh.set_meta(key, extras[key])
	if extras.has("shader") and str(extras["shader"]) != "": mesh.set_meta("skin_shader", str(extras["shader"]))
	if extras.has("walks"):                     # the passes: each pass's line on the floor, so a probe can walk it
		var walks := {}
		for name in extras["walks"]:
			var line := PackedVector2Array()
			for q in extras["walks"][name]: line.append(Vector2(float(q[0]), float(q[1])))
			walks[name] = line
		mesh.set_meta("walks", walks)
	if extras.has("chamber"): mesh.set_meta("chamber", Vector3(float(extras["chamber"][0]), float(extras["chamber"][1]), float(extras["chamber"][2])))
	if nh > 0:
		var points := PackedVector3Array()
		for i in nh: points.append(Vector3(hull[3 * i], hull[3 * i + 1], hull[3 * i + 2]))
		mesh.set_meta("hull_points", points)
	var faces := PackedVector3Array()
	if ns > 0:
		faces = _collision(soup, int(info.get("collision_budget", COLLISION_BUDGET)))
		mesh.set_meta("collision_faces", faces)
	var path := TARGET + form + ".res"
	var err := ResourceSaver.save(mesh, path, ResourceSaver.FLAG_COMPRESS)
	return {"triangles_marched": ni / 3, "triangles_near": int(near.arrays[Mesh.ARRAY_INDEX].size() / 3), "vertices": mesh.surface_get_array_len(0),
		"collision_triangles": faces.size() / 3, "hull_points": nh, "bytes": FileAccess.get_file_as_bytes(path).size(), "saved": err == OK}


## The first of the engine's own simplifications with no more than `budget` triangles, its vertices compacted.
func _simplify(verts: PackedVector3Array, normals: PackedVector3Array, colours: PackedColorArray, idx: PackedInt32Array, budget: int) -> Dictionary:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = idx
	if idx.size() / 3 <= budget:
		return {"arrays": arrays}
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
	im.generate_lods(25.0, 60.0, [])
	var out: Array = im.get_surface_arrays(0)
	var best: PackedInt32Array = out[Mesh.ARRAY_INDEX]
	for l in im.get_surface_lod_count(0):
		var lod := im.get_surface_lod_indices(0, l)
		best = lod
		if lod.size() / 3 <= budget: break
	var remap := {}
	var v2 := PackedVector3Array()
	var n2 := PackedVector3Array()
	var c2 := PackedColorArray()
	var i2 := PackedInt32Array()
	var ov: PackedVector3Array = out[Mesh.ARRAY_VERTEX]
	var on: PackedVector3Array = out[Mesh.ARRAY_NORMAL]
	var oc: PackedColorArray = out[Mesh.ARRAY_COLOR]
	i2.resize(best.size())
	for k in best.size():
		var v: int = best[k]
		if not remap.has(v):
			remap[v] = v2.size()
			v2.append(ov[v])
			n2.append(on[v])
			c2.append(oc[v])
		i2[k] = remap[v]
	var compact := []
	compact.resize(Mesh.ARRAY_MAX)
	compact[Mesh.ARRAY_VERTEX] = v2
	compact[Mesh.ARRAY_NORMAL] = n2
	compact[Mesh.ARRAY_COLOR] = c2
	compact[Mesh.ARRAY_INDEX] = i2
	return {"arrays": compact}


## The coarse march's triangles, welded, simplified to the collision budget, back to a soup of faces.
func _collision(soup: PackedFloat32Array, budget: int) -> PackedVector3Array:
	var at := {}
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	for i in soup.size() / 3:
		var p := Vector3(soup[3 * i], soup[3 * i + 1], soup[3 * i + 2])
		var key := Vector3i(roundi(p.x * 2000.0), roundi(p.y * 2000.0), roundi(p.z * 2000.0))
		if not at.has(key):
			at[key] = verts.size()
			verts.append(p)
		idx.append(at[key])
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for t in idx.size() / 3:
		var a := verts[idx[3 * t]]
		var n := (verts[idx[3 * t + 1]] - a).cross(verts[idx[3 * t + 2]] - a)
		for k in 3: normals[idx[3 * t + k]] += n
	for i in normals.size(): normals[i] = normals[i].normalized() if normals[i].length() > 0.0 else Vector3.UP
	var colours := PackedColorArray()
	colours.resize(verts.size())
	colours.fill(Color.WHITE)
	var near := _simplify(verts, normals, colours, idx, budget)
	var v: PackedVector3Array = near.arrays[Mesh.ARRAY_VERTEX]
	var i2: PackedInt32Array = near.arrays[Mesh.ARRAY_INDEX]
	var faces := PackedVector3Array()
	faces.resize(i2.size())
	for k in i2.size(): faces[k] = v[i2[k]]
	return faces
