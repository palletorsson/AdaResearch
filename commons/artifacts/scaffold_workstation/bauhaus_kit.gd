extends RefCounted
## Canonical plain-but-expressive Bauhaus form language for the playground grid.
## Mirrors Floor 13 Trans_Pre's Static Monochrome Object Play Path before Color
## (#ededeb walkable planes, #131519 structural black frames & trims, #2b2f37 slate fittings)
## and cleanly receives Bauhaus colour from Floor 28+ via construction_materials.gd,
## keeping exact physical dimensions and collision shapes identical in both phases.

const Model = preload("model.gd")
const Legacy = preload("geometry.gd")
const Kit = preload("res://commons/artifacts/primitive_encounters/geometry.gd")

const PALETTE_BAUHAUS := "bauhaus"

const INK_BLACK := Color("131519")
const INK_SLATE := Color("2b2f37")
const INK_WHITE := Color("ededeb")
const INK_ACCENT := Color("fafaf6")

const PALETTE_ORDER := ["monochrome", "bauhaus", "queer", "albers", "mondrian", "memphis"]

const PALETTES := {
	"monochrome": {
		"label": "MONO",
		"title": "Trans_Pre Monochrome",
		"frame": "131519", "slate": "2b2f37", "rod": "131519", "diag": "2b2f37",
		"quad": "ededeb", "panel": "ededeb", "wedge": "ededeb", "pyramid": "ededeb",
	},
	"bauhaus": {
		"label": "BAUHAUS",
		"title": "Kandinsky 1923 Triad",
		"frame": "1b1f27", "slate": "343b46", "rod": "1d64b8", "diag": "174d8f",
		"quad": "f0c430", "panel": "f2ede2", "wedge": "d93b2b", "pyramid": "2b8a6d",
	},
	"queer": {
		"label": "QUEER",
		"title": "Ada Kit / Stonewall",
		"frame": "1c1e26", "slate": "363948", "rod": "22d3ee", "diag": "0ea5c6",
		"quad": "f472b6", "panel": "fde68a", "wedge": "fb7185", "pyramid": "a78bfa",
	},
	"albers": {
		"label": "ALBERS",
		"title": "Albers Relativity",
		"frame": "221f1c", "slate": "423c36", "rod": "5c7a6b", "diag": "455d51",
		"quad": "d9924c", "panel": "e6d5b8", "wedge": "b8543a", "pyramid": "3e6378",
	},
	"mondrian": {
		"label": "MONDRIAN",
		"title": "De Stijl Grid",
		"frame": "101114", "slate": "292b30", "rod": "101114", "diag": "292b30",
		"quad": "f4f3ee", "panel": "f5c828", "wedge": "d62828", "pyramid": "1d4ed8",
	},
	"memphis": {
		"label": "MEMPHIS",
		"title": "Radical Memphis",
		"frame": "171821", "slate": "313344", "rod": "ff3ea5", "diag": "c92a7f",
		"quad": "2ce6c7", "panel": "fff056", "wedge": "ff7847", "pyramid": "6c5ce7",
	},
}

static var _mats: Dictionary = {}
static var _paint_mats: Dictionary = {}
static var _ghost_mats: Dictionary = {}
static var _baked_meshes: Dictionary = {}
static var _shape_cache: Dictionary = {}
static var _unit_box_mesh: BoxMesh = null


static func unit_box() -> BoxMesh:
	if _unit_box_mesh == null:
		_unit_box_mesh = BoxMesh.new()
		_unit_box_mesh.size = Vector3.ONE
	return _unit_box_mesh


static func paint_mat(hex_str: String) -> StandardMaterial3D:
	var key := hex_str.to_lower()
	if _paint_mats.has(key):
		return _paint_mats[key] as StandardMaterial3D
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(key)
	m.roughness = 0.44
	m.metallic = 0.05
	_paint_mats[key] = m
	return m


static func ghost_mat(colour: Color, emission_energy: float = 0.55) -> StandardMaterial3D:
	var key := "%s|%.2f" % [colour.to_html(true), emission_energy]
	if _ghost_mats.has(key):
		return _ghost_mats[key] as StandardMaterial3D
	var gm := StandardMaterial3D.new()
	gm.albedo_color = colour
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	gm.roughness = 0.32
	gm.emission_enabled = true
	gm.emission = Color(colour.r, colour.g, colour.b, 1.0)
	gm.emission_energy_multiplier = emission_energy
	_ghost_mats[key] = gm
	return gm


static func resolve_palette(phase_or_name: String) -> String:
	if PALETTES.has(phase_or_name):
		return phase_or_name
	if phase_or_name == "colour" or phase_or_name == "color":
		return "bauhaus"
	return "monochrome"


static func palette_label(palette_name: String) -> String:
	var pid := resolve_palette(palette_name)
	return str(PALETTES[pid].label)


static func swatch_colors(palette_name: String) -> Array[Color]:
	var pid := resolve_palette(palette_name)
	var p: Dictionary = PALETTES[pid]
	return [Color(p.rod), Color(p.quad), Color(p.wedge), Color(p.pyramid)]


static func mat(role: String, phase: String = "monochrome") -> StandardMaterial3D:
	var pid := resolve_palette(phase)
	var key := "%s/%s" % [pid, role]
	if _mats.has(key):
		return _mats[key]
	var p: Dictionary = PALETTES[pid]
	var m := StandardMaterial3D.new()
	var coloured := pid != "monochrome"
	match role:
		"frame", "trim", "joint":
			m.albedo_color = Color(p.frame)
			m.roughness = 0.62 if coloured else 0.72
			m.metallic = 0.14 if coloured else 0.08
		"slate", "collar":
			m.albedo_color = Color(p.slate)
			m.roughness = 0.60
			m.metallic = 0.16
		"rod":
			m.albedo_color = Color(p.rod)
			m.roughness = 0.46 if coloured else 0.70
			m.metallic = 0.06 if coloured else 0.10
		"diag":
			m.albedo_color = Color(p.diag)
			m.roughness = 0.50 if coloured else 0.66
			m.metallic = 0.10
		"quad":
			m.albedo_color = Color(p.quad)
			m.roughness = 0.48 if coloured else 0.56
			m.metallic = 0.04
		"panel":
			m.albedo_color = Color(p.panel)
			m.roughness = 0.50 if coloured else 0.56
			m.metallic = 0.04
		"wedge":
			m.albedo_color = Color(p.wedge)
			m.roughness = 0.48 if coloured else 0.56
			m.metallic = 0.04
		"pyramid":
			m.albedo_color = Color(p.pyramid)
			m.roughness = 0.46 if coloured else 0.56
			m.metallic = 0.04
		"accent":
			m.albedo_color = INK_ACCENT
			m.roughness = 0.35
			m.emission_enabled = true
			m.emission = Color("ffffff")
			m.emission_energy_multiplier = 0.25
		_:
			m.albedo_color = INK_WHITE
			m.roughness = 0.56
	_mats[key] = m
	return m


static func shape_for(raw: Dictionary, unit: float) -> Shape3D:
	var r: Dictionary = Model.as_face(raw)
	var kind: String = str(r.get("kind", ""))
	var skey := _shape_cache_key(r, unit)
	if _shape_cache.has(skey):
		return _shape_cache[skey] as Shape3D
	var shp: Shape3D
	if kind == "point":
		if r.get("_seated", false):
			var seated := BoxShape3D.new()
			seated.size = Vector3(.12, .08, .12) * unit
			shp = seated
		else:
			var b := BoxShape3D.new()
			b.size = Vector3(.12, .12, .12) * unit
			shp = b
	else:
		shp = Legacy.shape_for(raw, unit)
	_shape_cache[skey] = shp
	return shp


static func _shape_cache_key(r: Dictionary, unit: float) -> String:
	var kind: String = str(r.get("kind", ""))
	var umm: int = int(roundf(unit * 1000.0))
	if kind == "point":
		return "pt|%d|%d" % [1 if r.get("_seated", false) else 0, umm]
	if kind in ["rod", "rod_short"]:
		return "%s|%d" % [kind, umm]
	if kind == "diag":
		var lmm: int = int(roundf(Model.vec(r.at).distance_to(Model.vec(r.end)) * unit * 1000.0))
		return "diag|%d|%d" % [lmm, umm]
	if kind == "quad":
		return "quad|%d|%d" % [int(roundf(float(r.get("span", 1.0)) * 100.0)), umm]
	if kind == "panel":
		return "panel|%d|%d|%d" % [int(r.get("half", 0)), int(roundf(float(r.get("span", 1.0)) * 100.0)), umm]
	if kind in ["wedge", "pyramid"]:
		return "%s|%d|%d" % [kind, int(roundf(Model.prefab_span(r) * 100.0)), umm]
	return "%s|%s|%d" % [kind, str(r.get("span", 1.0)), umm]


## Returns a single cached multi-surface ArrayMesh for any Bauhaus primitive (1 Mesh instead of 4-7 child nodes!).
static func baked_mesh(raw: Dictionary, unit: float, phase: String = "monochrome", panel_mat_override: Material = null, quad_mat_override: Material = null) -> ArrayMesh:
	var r: Dictionary = Model.as_face(raw)
	var kind: String = str(r.get("kind", ""))
	var pid: String = resolve_palette(phase)
	var paint_hex: String = str(r.get("paint", "")).to_lower()
	var custom_mat: Material = null
	var custom_tag := ""
	if not paint_hex.is_empty():
		custom_mat = paint_mat(paint_hex)
		custom_tag = "paint:" + paint_hex
	elif kind == "quad" and quad_mat_override != null:
		custom_mat = quad_mat_override
		custom_tag = "qmat:" + str(quad_mat_override.get_instance_id())
	elif kind == "panel" and panel_mat_override != null:
		custom_mat = panel_mat_override
		custom_tag = "pmat:" + str(panel_mat_override.get_instance_id())

	var gkey := _mesh_geom_key(r, unit)
	var full_key := "%s|%s|%s" % [gkey, pid, custom_tag]
	if _baked_meshes.has(full_key):
		return _baked_meshes[full_key] as ArrayMesh

	var mesh: ArrayMesh = null
	if kind == "point":
		mesh = _bake_point(r, unit, pid, custom_mat)
	elif kind in ["rod", "rod_short"]:
		mesh = _bake_rod(kind, unit, pid, custom_mat)
	elif kind == "diag":
		mesh = _bake_diag(r, unit, pid, custom_mat)
	elif Model.is_macro(kind):
		mesh = _bake_macro_rod(kind, unit, pid, custom_mat)
	elif kind == "quad":
		mesh = _bake_quad(float(r.get("span", 1.0)), unit, pid, custom_mat)
	elif kind == "panel":
		mesh = _bake_panel(int(r.get("half", 0)), float(r.get("span", 1.0)), unit, pid, custom_mat)
	elif kind == "wedge":
		mesh = _bake_wedge(Model.prefab_span(r), unit, pid, custom_mat)
	elif kind == "pyramid":
		mesh = _bake_pyramid(Model.prefab_span(r), unit, pid, custom_mat)
	if mesh != null:
		_baked_meshes[full_key] = mesh
	return mesh


static func _mesh_geom_key(r: Dictionary, unit: float) -> String:
	var kind: String = str(r.get("kind", ""))
	var umm: int = int(roundf(unit * 1000.0))
	if kind == "point":
		return "pt_%d_%d" % [1 if r.get("_seated", false) else 0, umm]
	if kind in ["rod", "rod_short"]:
		return "%s_%d" % [kind, umm]
	if kind == "diag":
		var lmm: int = int(roundf(Model.vec(r.at).distance_to(Model.vec(r.end)) * unit * 1000.0))
		return "diag_%d_%d" % [lmm, umm]
	if Model.is_macro(kind):
		return "%s_%d" % [kind, umm]
	if kind == "quad":
		return "quad_%d_%d" % [int(roundf(float(r.get("span", 1.0)) * 100.0)), umm]
	if kind == "panel":
		return "panel_%d_%d_%d" % [int(r.get("half", 0)), int(roundf(float(r.get("span", 1.0)) * 100.0)), umm]
	if kind in ["wedge", "pyramid"]:
		return "%s_%d_%d" % [kind, int(roundf(Model.prefab_span(r) * 100.0)), umm]
	return "%s_%d" % [kind, umm]


static func visual(raw: Dictionary, unit: float, phase: String = "monochrome", panel_mat_override: Material = null, quad_mat_override: Material = null) -> MeshInstance3D:
	var r: Dictionary = Model.as_face(raw)
	var kind: String = str(r.get("kind", ""))
	var baked := baked_mesh(r, unit, phase, panel_mat_override, quad_mat_override)
	if baked == null:
		return Legacy.visual(raw, unit, phase)
	var root := MeshInstance3D.new()
	root.name = "Bauhaus_" + kind
	root.mesh = baked
	return root


## VR-optimized MultiMesh batcher: renders ANY number of Bauhaus records into O(1) MultiMeshInstance3D draw calls!
## Returns {multimeshes: int, instances: int, draw_calls: int}.
static func populate_multimesh_batch(
	parent: Node3D,
	records: Array[Dictionary],
	unit: float,
	phase: String = "monochrome",
	offset: Vector3 = Vector3.ZERO,
	cast_shadows: bool = true,
	panel_mat_override: Material = null,
	quad_mat_override: Material = null,
	material_override_all: Material = null
) -> Dictionary:
	var buckets: Dictionary = {}       # bucket_key -> {mesh: ArrayMesh, transforms: Array[Transform3D]}
	var fallback_count := 0
	var total_instances := 0

	for raw in records:
		var r: Dictionary = Model.as_face(raw)
		var mesh := baked_mesh(r, unit, phase, panel_mat_override, quad_mat_override)
		var pose := Model.pose(r)
		pose.origin = pose.origin * unit + offset
		if mesh == null:
			var fb := Legacy.visual(raw, unit, phase)
			fb.transform = pose
			if material_override_all != null:
				fb.material_override = material_override_all
			if not cast_shadows:
				fb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(fb)
			fallback_count += 1
			total_instances += 1
			continue
		var bkey: int = mesh.get_instance_id()
		if not buckets.has(bkey):
			buckets[bkey] = {"mesh": mesh, "kind": str(r.get("kind", "part")), "transforms": [] as Array[Transform3D]}
		(buckets[bkey].transforms as Array[Transform3D]).append(pose)
		total_instances += 1

	var mm_count := 0
	var draw_calls := fallback_count
	for bkey in buckets:
		var entry: Dictionary = buckets[bkey]
		var mesh: ArrayMesh = entry.mesh
		var xforms: Array[Transform3D] = entry.transforms
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xforms.size()
		for i in xforms.size():
			mm.set_instance_transform(i, xforms[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "MM_%s_%d" % [str(entry.kind), mm_count]
		mmi.multimesh = mm
		if material_override_all != null:
			mmi.material_override = material_override_all
		if not cast_shadows:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mmi)
		mm_count += 1
		draw_calls += 1 if material_override_all != null else mesh.get_surface_count()

	return {"multimeshes": mm_count, "instances": total_instances, "draw_calls": draw_calls}


## Batch arbitrary architectural boxes (grid bars, steel frames, stems, canopies) into 1 single MultiMeshInstance3D!
static func add_box_multimesh(
	parent: Node3D,
	node_name: String,
	transforms: Array[Transform3D],
	material: Material,
	cast_shadows: bool = false
) -> MultiMeshInstance3D:
	if transforms.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = unit_box()
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = material
	if not cast_shadows:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


static func _append_box(st: SurfaceTool, at: Vector3, size: Vector3, basis_rot: Basis = Basis.IDENTITY) -> void:
	var bm := BoxMesh.new()
	bm.size = size
	st.append_from(bm, 0, Transform3D(basis_rot, at))


static func _commit_surfaces(entries: Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var s_idx := 0
	for item in entries:
		var st: SurfaceTool = item[0]
		var material: Material = item[1]
		st.commit(mesh)
		mesh.surface_set_material(s_idx, material)
		s_idx += 1
	return mesh


static func _bake_point(r: Dictionary, unit: float, phase: String, custom_mat: Material) -> ArrayMesh:
	var seated: bool = bool(r.get("_seated", false))
	var st0 := SurfaceTool.new()
	st0.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st1 := SurfaceTool.new()
	st1.begin(Mesh.PRIMITIVE_TRIANGLES)
	var primary: Material = custom_mat if custom_mat != null else mat("joint", phase)
	if seated:
		_append_box(st0, Vector3.ZERO, Vector3(.115, .078, .115) * unit)
		_append_box(st1, Vector3(0, -.039, 0) * unit, Vector3(.128, .016, .128) * unit)
		return _commit_surfaces([[st0, primary], [st1, mat("slate", phase)]])
	_append_box(st0, Vector3.ZERO, Vector3(.115, .115, .115) * unit)
	for axis: Vector3i in Model.AXES:
		for dir in [-1, 1]:
			var s := Vector3(.052, .052, .052) * unit
			if axis.x != 0:
				s.x = .014 * unit
			elif axis.y != 0:
				s.y = .014 * unit
			else:
				s.z = .014 * unit
			_append_box(st1, Vector3(axis) * float(dir) * .061 * unit, s)
	return _commit_surfaces([[st0, primary], [st1, mat("slate", phase)]])


static func _bake_rod(kind: String, unit: float, phase: String, custom_mat: Material) -> ArrayMesh:
	var length: float = (.5 if kind == "rod_short" else 1.0) * unit
	var thickness: float = .068 * unit
	var st0 := SurfaceTool.new()
	st0.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_box(st0, Vector3.ZERO, Vector3(thickness, length, thickness))
	var st1 := SurfaceTool.new()
	st1.begin(Mesh.PRIMITIVE_TRIANGLES)
	var collar_s := Vector3(.082 * unit, .024 * unit, .082 * unit)
	for side in [-1.0, 1.0]:
		_append_box(st1, Vector3(0, side * (length * 0.5 - .055 * unit), 0), collar_s)
	var primary: Material = custom_mat if custom_mat != null else mat("rod", phase)
	return _commit_surfaces([[st0, primary], [st1, mat("slate", phase)]])


static func _bake_diag(r: Dictionary, unit: float, phase: String, custom_mat: Material) -> ArrayMesh:
	var length: float = Model.vec(r.at).distance_to(Model.vec(r.end)) * unit
	var thickness: float = .048 * unit
	var st0 := SurfaceTool.new()
	st0.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_box(st0, Vector3.ZERO, Vector3(thickness, length, thickness))
	var primary: Material = custom_mat if custom_mat != null else mat("diag", phase)
	return _commit_surfaces([[st0, primary]])


static func _bake_macro_rod(kind: String, unit: float, phase: String, custom_mat: Material) -> ArrayMesh:
	var length: float = float(Model.MACRO_UNITS[kind])
	var n: int = int(roundf(length * 2.0))
	var st0 := SurfaceTool.new()
	st0.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st1 := SurfaceTool.new()
	st1.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		_append_box(st0, Vector3(0, (-length * 0.5 + 0.25 + i * 0.5) * unit, 0), Vector3(.068, .5, .068) * unit)
		if i < n - 1:
			_append_box(st1, Vector3(0, (-length * 0.5 + 0.5 + i * 0.5) * unit, 0), Vector3(.115, .115, .115) * unit)
	var primary: Material = custom_mat if custom_mat != null else mat("rod", phase)
	if n > 1:
		return _commit_surfaces([[st0, primary], [st1, mat("joint", phase)]])
	return _commit_surfaces([[st0, primary]])


static func _bake_quad(span: float, unit: float, phase: String, custom_mat: Material) -> ArrayMesh:
	var w: float = span * unit
	var thick: float = .036 * unit
	var st0 := SurfaceTool.new()
	st0.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_box(st0, Vector3.ZERO, Vector3(w, thick, w))

	var trim_w: float = maxf(.028 * unit, 0.003)
	var trim_h: float = maxf(.007 * unit, 0.0012)
	var top_y: float = thick * 0.5 + trim_h * 0.32
	var half: float = w * 0.5 - trim_w * 0.5
	var st1 := SurfaceTool.new()
	st1.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_box(st1, Vector3(0, top_y, -half), Vector3(w, trim_h, trim_w))
	_append_box(st1, Vector3(0, top_y, half), Vector3(w, trim_h, trim_w))
	_append_box(st1, Vector3(-half, top_y, 0), Vector3(trim_w, trim_h, w))
	_append_box(st1, Vector3(half, top_y, 0), Vector3(trim_w, trim_h, w))
	var fascia_h: float = .010 * unit
	var bot_y: float = -thick * 0.5 + fascia_h * 0.5
	_append_box(st1, Vector3(0, bot_y, -half), Vector3(w + .002, fascia_h, trim_w * 0.8))
	_append_box(st1, Vector3(0, bot_y, half), Vector3(w + .002, fascia_h, trim_w * 0.8))

	var primary: Material = custom_mat if custom_mat != null else mat("quad", phase)
	return _commit_surfaces([[st0, primary], [st1, mat("trim", phase)]])


static func _bake_panel(half: int, span: float, unit: float, phase: String, custom_mat: Material) -> ArrayMesh:
	var verts := Legacy.vertices(half, unit, span)
	var tri_mesh: ArrayMesh = Kit.mesh(verts, [[0, 2, 1], [3, 4, 5], [0, 1, 4, 3], [1, 2, 5, 4], [2, 0, 3, 5]])
	var st0 := SurfaceTool.new()
	st0.begin(Mesh.PRIMITIVE_TRIANGLES)
	st0.append_from(tri_mesh, 0, Transform3D.IDENTITY)

	var trim_w: float = maxf(.026 * unit, 0.0028)
	var trim_h: float = maxf(.007 * unit, 0.0012)
	var st1 := SurfaceTool.new()
	st1.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var a: Vector3 = verts[i + 3]
		var b: Vector3 = verts[(i + 1) % 3 + 3]
		var edge_len: float = a.distance_to(b)
		if edge_len < 0.0001:
			continue
		var mid: Vector3 = (a + b) * 0.5 + Vector3(0, trim_h * 0.32, 0)
		var dir: Vector3 = (b - a).normalized()
		_append_box(st1, mid, Vector3(trim_w, trim_h, edge_len), Basis(Quaternion(Vector3.BACK, dir)))

	var primary: Material = custom_mat if custom_mat != null else mat("panel", phase)
	return _commit_surfaces([[st0, primary], [st1, mat("trim", phase)]])


static func _bake_wedge(span: float, unit: float, phase: String, custom_mat: Material) -> ArrayMesh:
	var verts := Legacy.prefab_vertices("wedge", unit, span)
	var w_mesh: ArrayMesh = Kit.mesh(verts, Kit.wedge_faces())
	var st0 := SurfaceTool.new()
	st0.begin(Mesh.PRIMITIVE_TRIANGLES)
	st0.append_from(w_mesh, 0, Transform3D.IDENTITY)

	var min_x := INF; var max_x := -INF; var min_z := INF; var max_z := -INF; var max_y := 0.0
	for v in verts:
		min_x = minf(min_x, v.x); max_x = maxf(max_x, v.x)
		min_z = minf(min_z, v.z); max_z = maxf(max_z, v.z)
		max_y = maxf(max_y, v.y)
	var run_z: float = max_z - min_z
	var slope_len: float = Vector2(run_z, max_y).length()
	var pitch_x: float = -atan2(max_y, run_z)
	var rail_w: float = maxf(.028 * unit, 0.003)
	var rail_h: float = maxf(.014 * unit, 0.002)
	var mid_z: float = (min_z + max_z) * 0.5
	var mid_y: float = max_y * 0.5 + rail_h * 0.35
	var slope_basis := Basis(Vector3.RIGHT, pitch_x)
	var st1 := SurfaceTool.new()
	st1.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in [min_x + rail_w * 0.5, max_x - rail_w * 0.5]:
		_append_box(st1, Vector3(sx, mid_y, mid_z), Vector3(rail_w, rail_h, slope_len), slope_basis)
	_append_box(st1, Vector3((min_x + max_x) * 0.5, max_y + rail_h * 0.25, max_z - rail_w * 0.5),
		Vector3(max_x - min_x, rail_h * 0.6, rail_w))

	var primary: Material = custom_mat if custom_mat != null else mat("wedge", phase)
	return _commit_surfaces([[st0, primary], [st1, mat("trim", phase)]])


static func _bake_pyramid(span: float, unit: float, phase: String, custom_mat: Material) -> ArrayMesh:
	var verts := Legacy.prefab_vertices("pyramid", unit, span)
	var p_mesh: ArrayMesh = Kit.mesh(verts, [[0, 3, 2, 1], [0, 1, 4], [1, 2, 4], [2, 3, 4], [3, 0, 4]])
	var st0 := SurfaceTool.new()
	st0.begin(Mesh.PRIMITIVE_TRIANGLES)
	st0.append_from(p_mesh, 0, Transform3D.IDENTITY)
	var width: float = absf(verts[1].x - verts[0].x)
	var collar_h: float = maxf(.022 * unit, 0.003)
	var st1 := SurfaceTool.new()
	st1.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_box(st1, Vector3(0, collar_h * 0.5, 0), Vector3(width + .012 * unit, collar_h, width + .012 * unit))
	var primary: Material = custom_mat if custom_mat != null else mat("pyramid", phase)
	return _commit_surfaces([[st0, primary], [st1, mat("trim", phase)]])


## Applies a cached Bauhaus ghost tint (amber/white for placement preview, coral-red for removal) with zero per-frame allocs!
static func apply_ghost(node: Node, colour: Color, emission_energy: float = 0.55) -> void:
	var gm := ghost_mat(colour, emission_energy)
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).material_override = gm
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		apply_ghost(child, colour, emission_energy)


## Dress a grid_playground body (non-workshop parts too) into the matching Bauhaus look.
static func dress_playground_body(body: Node3D, part: Dictionary, phase: String = "monochrome") -> void:
	if str(part.get("source", "")).begins_with("workshop_"):
		return
	if part.get("electrical", false):
		return
	var role := "quad"
	var src := str(part.get("source", ""))
	if src in ["pipe", "fan", "drum", "tc"] or src.begins_with("scaffold_"):
		role = "frame"
	elif src == "wedge":
		role = "wedge"
	elif src == "paddle":
		role = "pyramid"
	for child in body.get_children():
		if child is MeshInstance3D and child.mesh != null:
			child.material_override = mat(role, phase)
