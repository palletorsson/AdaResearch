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
	if r.kind == "point":
		if r.get("_seated", false):
			var seated := BoxShape3D.new()
			seated.size = Vector3(.12, .08, .12) * unit
			return seated
		var b := BoxShape3D.new()
		b.size = Vector3(.12, .12, .12) * unit
		return b
	return Legacy.shape_for(raw, unit)


static func visual(raw: Dictionary, unit: float, phase: String = "monochrome") -> MeshInstance3D:
	var r: Dictionary = Model.as_face(raw)
	var kind: String = str(r.kind)
	var root := MeshInstance3D.new()
	root.name = "Bauhaus_" + kind

	if kind == "point":
		_build_point(root, r, unit, phase)
	elif kind in ["rod", "rod_short"]:
		_build_rod(root, kind, unit, phase)
	elif kind == "diag":
		_build_diag(root, r, unit, phase)
	elif Model.is_macro(kind):
		_build_macro_rod(root, kind, unit, phase)
	elif kind == "quad":
		_build_quad(root, float(r.get("span", 1.0)), unit, phase)
	elif kind == "panel":
		_build_panel(root, int(r.get("half", 0)), float(r.get("span", 1.0)), unit, phase)
	elif kind == "wedge":
		_build_wedge(root, Model.prefab_span(r), unit, phase)
	elif kind == "pyramid":
		_build_pyramid(root, Model.prefab_span(r), unit, phase)
	else:
		root.free()
		return Legacy.visual(raw, unit, phase)
	return root


static func _build_point(root: MeshInstance3D, r: Dictionary, unit: float, phase: String) -> void:
	var seated: bool = bool(r.get("_seated", false))
	var box := BoxMesh.new()
	if seated:
		# Flush under a walkable surface: extends down from y=0 so a walker never snags.
		box.size = Vector3(.115, .078, .115) * unit
		root.mesh = box
		root.material_override = mat("joint", phase)
		var cap := _child_box(root, "SeatedCap", Vector3(0, -.039, 0) * unit, Vector3(.128, .016, .128) * unit, mat("slate", phase))
		cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return
	box.size = Vector3(.115, .115, .115) * unit
	root.mesh = box
	root.material_override = mat("joint", phase)
	# Six architectural axial socket collars make the orthogonal grid rule visibly legible.
	for axis: Vector3i in Model.AXES:
		for dir in [-1, 1]:
			var s := Vector3(.052, .052, .052) * unit
			if axis.x != 0:
				s.x = .014 * unit
			elif axis.y != 0:
				s.y = .014 * unit
			else:
				s.z = .014 * unit
			_child_box(root, "Socket", Vector3(axis) * float(dir) * .061 * unit, s, mat("slate", phase))


static func _build_rod(root: MeshInstance3D, kind: String, unit: float, phase: String) -> void:
	var length: float = (.5 if kind == "rod_short" else 1.0) * unit
	var thickness: float = .068 * unit
	var beam := BoxMesh.new()
	beam.size = Vector3(thickness, length, thickness)
	root.mesh = beam
	root.material_override = mat("rod", phase)
	# Subtle end-collars anchor the bar visually into its two corner joints.
	var collar_s := Vector3(.082 * unit, .024 * unit, .082 * unit)
	for side in [-1.0, 1.0]:
		_child_box(root, "EndCollar", Vector3(0, side * (length * 0.5 - .055 * unit), 0), collar_s, mat("slate", phase))


static func _build_diag(root: MeshInstance3D, r: Dictionary, unit: float, phase: String) -> void:
	var length: float = Model.vec(r.at).distance_to(Model.vec(r.end)) * unit
	var thickness: float = .048 * unit
	var brace := BoxMesh.new()
	brace.size = Vector3(thickness, length, thickness)
	root.mesh = brace
	root.material_override = mat("diag", phase)


static func _build_macro_rod(root: MeshInstance3D, kind: String, unit: float, phase: String) -> void:
	var length: float = float(Model.MACRO_UNITS[kind])
	var n: int = int(roundf(length * 2.0))
	for i in n:
		_child_box(root, "Seg", Vector3(0, (-length * 0.5 + 0.25 + i * 0.5) * unit, 0),
			Vector3(.068, .5, .068) * unit, mat("rod", phase))
		if i < n - 1:
			_child_box(root, "Node", Vector3(0, (-length * 0.5 + 0.5 + i * 0.5) * unit, 0),
				Vector3(.115, .115, .115) * unit, mat("joint", phase))


static func _build_quad(root: MeshInstance3D, span: float, unit: float, phase: String) -> void:
	# Walkable top sits at local y = +0.018*unit (exact grid height in Model.pose).
	var w: float = span * unit
	var thick: float = .036 * unit
	var slab := BoxMesh.new()
	slab.size = Vector3(w, thick, w)
	root.mesh = slab
	root.material_override = mat("quad", phase)

	# Crisp matte-black perimeter trim flush with the walkable deck top (Trans_Pre signature).
	var trim_w: float = maxf(.028 * unit, 0.003)
	var trim_h: float = maxf(.007 * unit, 0.0012)
	var top_y: float = thick * 0.5 + trim_h * 0.32
	var half: float = w * 0.5 - trim_w * 0.5
	var trim_mat := mat("trim", phase)
	_child_box(root, "TrimN", Vector3(0, top_y, -half), Vector3(w, trim_h, trim_w), trim_mat)
	_child_box(root, "TrimS", Vector3(0, top_y, half), Vector3(w, trim_h, trim_w), trim_mat)
	_child_box(root, "TrimW", Vector3(-half, top_y, 0), Vector3(trim_w, trim_h, w), trim_mat)
	_child_box(root, "TrimE", Vector3(half, top_y, 0), Vector3(trim_w, trim_h, w), trim_mat)

	# Clean dark architectural fascia rim around the underside edge.
	var fascia_h: float = .010 * unit
	var bot_y: float = -thick * 0.5 + fascia_h * 0.5
	_child_box(root, "FasciaN", Vector3(0, bot_y, -half), Vector3(w + .002, fascia_h, trim_w * 0.8), mat("slate", phase))
	_child_box(root, "FasciaS", Vector3(0, bot_y, half), Vector3(w + .002, fascia_h, trim_w * 0.8), mat("slate", phase))


static func _build_panel(root: MeshInstance3D, half: int, span: float, unit: float, phase: String) -> void:
	var verts := Legacy.vertices(half, unit, span)
	root.mesh = Kit.mesh(verts, [[0, 2, 1], [3, 4, 5], [0, 1, 4, 3], [1, 2, 5, 4], [2, 0, 3, 5]])
	root.material_override = mat("panel", phase)

	# Three physical matte-black edge trims hugging the triangle top perimeter (including diagonal).
	var trim_w: float = maxf(.026 * unit, 0.0028)
	var trim_h: float = maxf(.007 * unit, 0.0012)
	var trim_mat := mat("trim", phase)
	for i in 3:
		var a: Vector3 = verts[i + 3]
		var b: Vector3 = verts[(i + 1) % 3 + 3]
		var edge_len: float = a.distance_to(b)
		if edge_len < 0.0001:
			continue
		var mid: Vector3 = (a + b) * 0.5 + Vector3(0, trim_h * 0.32, 0)
		var bar := _child_box(root, "TriTrim%d" % i, mid, Vector3(trim_w, trim_h, edge_len), trim_mat)
		var dir: Vector3 = (b - a).normalized()
		bar.quaternion = Quaternion(Vector3.BACK, dir)


static func _build_wedge(root: MeshInstance3D, span: float, unit: float, phase: String) -> void:
	var verts := Legacy.prefab_vertices("wedge", unit, span)
	root.mesh = Kit.mesh(verts, Kit.wedge_faces())
	root.material_override = mat("wedge", phase)

	# Crisp matte-black cheek trim rails hugging both sloped sides (matching Trans_Pre _ramp_x).
	# Kit.wedge vertices: 0=(-hw,0,-hd), 1=(hw,0,-hd), 2=(hw,0,hd), 3=(-hw,0,hd), 4=(hw,h,hd), 5=(-hw,h,hd)
	# Wait: check exact low/high Z from verts directly so trim always hugs the true slope!
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
	var trim_mat := mat("trim", phase)
	var mid_z: float = (min_z + max_z) * 0.5
	var mid_y: float = max_y * 0.5 + rail_h * 0.35
	for sx in [min_x + rail_w * 0.5, max_x - rail_w * 0.5]:
		var rail := _child_box(root, "RampTrim", Vector3(sx, mid_y, mid_z), Vector3(rail_w, rail_h, slope_len), trim_mat)
		rail.rotation.x = pitch_x
	# High-end landing bar + low-end nose bar
	_child_box(root, "HighTrim", Vector3((min_x + max_x) * 0.5, max_y + rail_h * 0.25, max_z - rail_w * 0.5),
		Vector3(max_x - min_x, rail_h * 0.6, rail_w), trim_mat)


static func _build_pyramid(root: MeshInstance3D, span: float, unit: float, phase: String) -> void:
	var verts := Legacy.prefab_vertices("pyramid", unit, span)
	root.mesh = Kit.mesh(verts, [[0, 3, 2, 1], [0, 1, 4], [1, 2, 4], [2, 3, 4], [3, 0, 4]])
	root.material_override = mat("pyramid", phase)
	var width: float = absf(verts[1].x - verts[0].x)
	var collar_h: float = maxf(.022 * unit, 0.003)
	_child_box(root, "BasePlinth", Vector3(0, collar_h * 0.5, 0), Vector3(width + .012 * unit, collar_h, width + .012 * unit), mat("trim", phase))


static func _child_box(parent: Node3D, node_name: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material
	mi.position = at
	parent.add_child(mi)
	return mi


## Applies a crisp Bauhaus ghost tint (amber/white for placement preview, coral-red for removal).
static func apply_ghost(node: Node, colour: Color, emission_energy: float = 0.55) -> void:
	if node is MeshInstance3D:
		var gm := StandardMaterial3D.new()
		gm.albedo_color = colour
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		gm.roughness = 0.32
		gm.emission_enabled = true
		gm.emission = Color(colour.r, colour.g, colour.b, 1.0)
		gm.emission_energy_multiplier = emission_energy
		node.material_override = gm
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
