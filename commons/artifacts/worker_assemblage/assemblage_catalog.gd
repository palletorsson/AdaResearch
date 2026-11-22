extends RefCounted
## Canonical Endless Museum Dream-Body & Worker Formation Catalog.
## Single source of truth linking Void Tower floors/stages -> WorkerBeing BiomeGrammar stages
## -> Endless Museum DreamBodies sculptural families, native DNA axes, plinth grounding,
## and Concept Order #1 monochrome-before-Color rendering.

const DreamBodiesScript := preload("res://commons/artifacts/dream_bodies/dream_bodies.gd")
const Bauhaus := preload("res://commons/artifacts/scaffold_workstation/bauhaus_kit.gd")
const BODY_DIR := "res://commons/artifacts/dream_bodies/bodies/"

## Curated 12-family Atelier Archive spanning the Endless Museum's sculptural worker lineage.
## Every entry is a verified builder in DreamBodies.FIGURES with an expressive default DNA pose.
const ATELIER_ARCHETYPES: Array[Dictionary] = [
	{"figure": "asawa_wire", "seed": 11, "opts": {"winding": "figure", "strand": "fibre"}, "label": "ASAWA CORD", "lineage": "LINE & LATTICE"},
	{"figure": "tatlin_red", "seed": 17, "opts": {"monument": "tower", "sheet": "thread"}, "label": "TATLIN FRAME", "lineage": "CONSTRUCTIVIST RIG"},
	{"figure": "pierced_screen", "seed": 23, "opts": {"piercing": "arp", "wearer": "threading"}, "label": "PIERCED SCREEN", "lineage": "PLANAR APERTURE"},
	{"figure": "pink_scaffold", "seed": 19, "opts": {"plate": "torn", "armature": "leaning"}, "label": "PLATE SCAFFOLD", "lineage": "ANGULAR SHELL"},
	{"figure": "stijl_robot", "seed": 7, "opts": {"assembly": "danced", "crown": "helmet"}, "label": "STIJL ROBOT", "lineage": "BAUHAUS SLAB WORKER"},
	{"figure": "panel_robot", "seed": 13, "opts": {"panelling": "floating", "assembly": "walker"}, "label": "PANEL ROBOT", "lineage": "MODULAR CHASSIS"},
	{"figure": "hadid_shell", "seed": 29, "opts": {"bore": "holes", "figure": "standing"}, "label": "PARAMETRIC SHELL", "lineage": "TRANSFORMED VOLUME"},
	{"figure": "ceramic_puppet", "seed": 31, "opts": {"stringing": "strung", "vestment": "maze_cloth"}, "label": "CERAMIC PUPPET", "lineage": "ARTICULATED JOINTS"},
	{"figure": "masked_dancer", "seed": 37, "opts": {"rite": "mid_step", "shell": "eared"}, "label": "MASKED DANCER", "lineage": "PATTERNED BODY"},
	{"figure": "mosaic_body", "seed": 41, "opts": {"tessera": "bedded", "companion": "none"}, "label": "MOSAIC BODY", "lineage": "TESSERAE GRID"},
	{"figure": "panton_pop", "seed": 43, "opts": {"mould": "shell", "crown": "ball"}, "label": "PANTON MOULD", "lineage": "COLOUR CANTILEVER"},
	{"figure": "brass_stamen", "seed": 47, "opts": {"assembly": "braced", "crown": "lens"}, "label": "BRASS STAMEN", "lineage": "FORCE ARMATURE"},
]

const FORMATION_ORDER: Array[String] = ["dyad", "assemblage", "trio", "solo"]


## Resolve floor index (0..209) to its WorkerBeing BiomeGrammar stage and Endless Museum sculptural lineage.
static func lineage_for_floor(floor_idx: int, stage_override: String = "") -> Dictionary:
	var entry: Dictionary
	if floor_idx >= 209:
		entry = {
			"code": "ATELIER",
			"chapter": "PREFAB ARCHIVE · WORKER FORMATIONS",
			"stage": "color",
			"monochrome": false,
			"figures": [
				{"figure": "stijl_robot", "seed": 7, "opts": {"assembly": "danced", "crown": "helmet"}, "role": "PRIMARY FORM"},
				{"figure": "panel_robot", "seed": 13, "opts": {"panelling": "floating", "assembly": "walker"}, "role": "MODULAR TWIN"},
				{"figure": "asawa_wire", "seed": 11, "opts": {"winding": "figure", "strand": "fibre"}, "role": "WIRE ORIGIN"},
			],
		}
	elif floor_idx <= 2:
		entry = {
			"code": "01 / SEED",
			"chapter": "POINT ONE · SEED & WOUND CORD",
			"stage": "Point_One",
			"monochrome": true,
			"figures": [
				{"figure": "asawa_wire", "seed": 11, "opts": {"winding": "skein", "strand": "fossil"}, "role": "ORIGIN SKEIN"},
				{"figure": "pierced_screen", "seed": 5, "opts": {"piercing": "arp", "wearer": "negative"}, "role": "DATUM FIELD"},
			],
		}
	elif floor_idx <= 4:
		entry = {
			"code": "02 / LINE",
			"chapter": "POINT LINES · CORD & ARMATURE",
			"stage": "Point_Lines",
			"monochrome": true,
			"figures": [
				{"figure": "asawa_wire", "seed": 14, "opts": {"winding": "figure", "strand": "fibre"}, "role": "WIRE FRAME"},
				{"figure": "tatlin_red", "seed": 17, "opts": {"monument": "tower", "sheet": "thread"}, "role": "LINEAR RIG"},
			],
		}
	elif floor_idx == 5:
		entry = {
			"code": "03 / TRIANGLE",
			"chapter": "TRIANGLES · SCREEN & SCAFFOLD",
			"stage": "Point_Triangle_Context",
			"monochrome": true,
			"figures": [
				{"figure": "pierced_screen", "seed": 23, "opts": {"piercing": "arp", "wearer": "threading"}, "role": "PLANAR SHEET"},
				{"figure": "pink_scaffold", "seed": 19, "opts": {"plate": "torn", "armature": "leaning"}, "role": "TRIANGULATED RIG"},
			],
		}
	elif floor_idx == 6:
		entry = {
			"code": "04 / SOLIDS",
			"chapter": "POLYHEDRA · SKELETAL JOINTS",
			"stage": "Primitives_Polythedra",
			"monochrome": true,
			"figures": [
				{"figure": "stijl_robot", "seed": 9, "opts": {"assembly": "skeletal", "crown": "cage"}, "role": "SLAB ARMATURE"},
				{"figure": "porcelain_doll", "seed": 12, "opts": {"winding": "cage", "figure": "reaching"}, "role": "JOINTED STUDY"},
			],
		}
	elif floor_idx <= 12:
		entry = {
			"code": "05 / QUADS",
			"chapter": "CUBE & QUAD · MODULAR WORKER",
			"stage": "Point_Animatedcube",
			"monochrome": true,
			"figures": [
				{"figure": "stijl_robot", "seed": 7, "opts": {"assembly": "danced", "crown": "helmet"}, "role": "SLAB WORKER"},
				{"figure": "panel_robot", "seed": 13, "opts": {"panelling": "floating", "assembly": "walker"}, "role": "PANEL CHASSIS"},
			],
		}
	elif floor_idx <= 27:
		entry = {
			"code": "06 / MOTION",
			"chapter": "TRANSFORMATION · SHIFTING SHELLS",
			"stage": "transformation",
			"monochrome": true,
			"figures": [
				{"figure": "panel_robot", "seed": 21, "opts": {"panelling": "shed", "assembly": "twinned"}, "role": "DISPLACED FORM"},
				{"figure": "hadid_shell", "seed": 29, "opts": {"bore": "holes", "figure": "standing"}, "role": "HOLLOW BODY"},
				{"figure": "stijl_robot", "seed": 15, "opts": {"assembly": "exploded", "crown": "chorus"}, "role": "EXPLODED STUDY"},
			],
		}
	elif floor_idx <= 36:
		entry = {
			"code": "07 / COLOUR",
			"chapter": "COLOUR · BAUHAUS & CHORUS",
			"stage": "color",
			"monochrome": false,
			"figures": [
				{"figure": "stijl_robot", "seed": 7, "opts": {"assembly": "danced", "crown": "helmet"}, "role": "COLOUR WORKER"},
				{"figure": "panton_pop", "seed": 43, "opts": {"mould": "shell", "crown": "ball"}, "role": "POP CANTILEVER"},
				{"figure": "masked_dancer", "seed": 37, "opts": {"rite": "mid_step", "shell": "eared"}, "role": "PAINTED FORM"},
			],
		}
	elif floor_idx <= 44:
		entry = {
			"code": "08 / PATTERN",
			"chapter": "PATTERN · TESSERAE & PRINT",
			"stage": "tiling",
			"monochrome": false,
			"figures": [
				{"figure": "mosaic_body", "seed": 41, "opts": {"tessera": "bedded", "companion": "none"}, "role": "MOSAIC BODY"},
				{"figure": "masked_dancer", "seed": 37, "opts": {"rite": "mid_step", "shell": "eared"}, "role": "DIAMOND LATTICE"},
				{"figure": "kruger_suit", "seed": 19, "opts": {"wearer": "kneeling", "flat": "leaning"}, "role": "GRAPHIC SUIT"},
			],
		}
	elif floor_idx <= 95:
		entry = {
			"code": "09 / FORCES",
			"chapter": "FORCES & WAVES · BRASS ARMATURE",
			"stage": "forces",
			"monochrome": false,
			"figures": [
				{"figure": "brass_stamen", "seed": 47, "opts": {"assembly": "braced", "crown": "lens"}, "role": "BRASS RIG"},
				{"figure": "paik_light", "seed": 33, "opts": {"broadcast": "scatter", "crowd": "one"}, "role": "SIGNAL BODY"},
			],
		}
	elif floor_idx <= 155:
		entry = {
			"code": "10 / GROWTH",
			"chapter": "RULES & GROWTH · CRYSTAL & CORAL",
			"stage": "fractals",
			"monochrome": false,
			"figures": [
				{"figure": "crystal_suit", "seed": 53, "opts": {"crust": "spire", "panels": "leaning"}, "role": "RULE CRUST"},
				{"figure": "coral_polyp", "seed": 59, "opts": {"colony": "single", "frond": "branch"}, "role": "BRANCH COLONY"},
			],
		}
	else:
		entry = {
			"code": "11 / SYNTHESIS",
			"chapter": "SOFT & IMPLICIT · FUSED FORM",
			"stage": "full",
			"monochrome": false,
			"figures": [
				{"figure": "hicks_fiber", "seed": 61, "opts": {"fibre": "roving", "wearer": "mannequin"}, "role": "FIBRE SHELL"},
				{"figure": "gehry_metal", "seed": 67, "opts": {"sheet": "crumple", "gesture": "lean"}, "role": "FOLDED ALLOY"},
			],
		}

	var out: Dictionary = entry.duplicate(true)
	if not stage_override.is_empty() and stage_override != "auto":
		out["stage"] = stage_override
	return out


## Validate a DreamBodies figure name against DreamBodies.FIGURES.
static func is_valid_figure(fig: String) -> bool:
	return DreamBodiesScript.FIGURES.has(fig.to_lower())


## Return the native DNA axes dictionary for any DreamBodies builder.
static func axes_for(fig: String) -> Dictionary:
	var clean: String = fig.to_lower()
	if not is_valid_figure(clean):
		return {}
	var path: String = BODY_DIR + clean + ".gd"
	if not ResourceLoader.exists(path):
		return {}
	var s: Script = load(path) as Script
	if s == null or not s.has_method("axes"):
		return {}
	var ax: Variant = s.call("axes")
	return ax if ax is Dictionary else {}


## Human-readable short title for any figure name.
static func figure_title(fig: String) -> String:
	for entry in ATELIER_ARCHETYPES:
		if String(entry.get("figure", "")) == fig:
			return String(entry.get("label", fig.replace("_", " ").to_upper()))
	return fig.replace("_", " ").to_upper()


## Build one Endless Museum DreamBodies sculpture synchronously, centered on XZ, grounded flush at y = 0,
## normalized gracefully toward `target_height` (Modulor human-worker height), with optional Concept Order #1
## monochrome architectural finish.
static func build_sculpture(fig: String, seed_val: int, opts: Dictionary = {}, target_height: float = 1.82, monochrome: bool = false) -> Node3D:
	var clean: String = fig.to_lower()
	if not is_valid_figure(clean):
		clean = "stijl_robot"
	var wrapper := Node3D.new()
	wrapper.name = "DreamSculpture_" + clean

	var path: String = BODY_DIR + clean + ".gd"
	var s: Script = load(path) as Script
	if s == null or not s.has_method("build"):
		push_warning("[worker_assemblage] missing DreamBodies builder: %s" % clean)
		return wrapper

	var inner := Node3D.new()
	inner.name = "SculptureInner"
	wrapper.add_child(inner)

	var argc: int = 2
	for m in s.get_script_method_list():
		if String(m.get("name", "")) == "build":
			argc = (m.get("args", []) as Array).size()
			break
	if argc >= 3:
		s.call("build", inner, seed_val, opts)
	else:
		s.call("build", inner, seed_val)

	# Measure exact local bounds so every single one of the 52 museum sculptures stands centered and flush on y = 0.
	var bounds: AABB = _measure_local_aabb(inner)
	if bounds.size.y > 0.05:
		var scale_factor: float = clampf(target_height / bounds.size.y, 0.52, 1.55)
		inner.scale = Vector3.ONE * scale_factor
		var cx: float = bounds.position.x + bounds.size.x * 0.5
		var cz: float = bounds.position.z + bounds.size.z * 0.5
		inner.position = Vector3(-cx * scale_factor, -bounds.position.y * scale_factor, -cz * scale_factor)

	if monochrome:
		apply_monochrome_pass(inner)

	wrapper.set_meta("dream_figure", clean)
	wrapper.set_meta("dream_seed", seed_val)
	wrapper.set_meta("dream_opts", opts.duplicate(true))
	wrapper.set_meta("dream_monochrome", monochrome)
	return wrapper


## Compute combined AABB of all MeshInstance3D descendants in `root`'s local coordinate space (works pre-tree!).
static func _measure_local_aabb(root: Node3D) -> AABB:
	var combined := AABB()
	var has_any := false
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var pair: Array = stack.pop_back()
		var node: Node = pair[0]
		var xf: Transform3D = pair[1]
		for child in node.get_children():
			if child is Node3D:
				var c3 := child as Node3D
				var cxf: Transform3D = xf * c3.transform
				if c3 is MeshInstance3D and (c3 as MeshInstance3D).mesh != null:
					var maabb: AABB = (c3 as MeshInstance3D).mesh.get_aabb()
					var tx_aabb: AABB = _transform_aabb(cxf, maabb)
					if not has_any:
						combined = tx_aabb
						has_any = true
					else:
						combined = combined.merge(tx_aabb)
				stack.append([c3, cxf])
	return combined


static func _transform_aabb(xf: Transform3D, aabb: AABB) -> AABB:
	var p := aabb.position
	var s := aabb.size
	var corners: Array[Vector3] = [
		Vector3(p.x, p.y, p.z),
		Vector3(p.x + s.x, p.y, p.z),
		Vector3(p.x, p.y + s.y, p.z),
		Vector3(p.x, p.y, p.z + s.z),
		Vector3(p.x + s.x, p.y + s.y, p.z),
		Vector3(p.x + s.x, p.y, p.z + s.z),
		Vector3(p.x, p.y + s.y, p.z + s.z),
		Vector3(p.x + s.x, p.y + s.y, p.z + s.z),
	]
	var out := AABB(xf * corners[0], Vector3.ZERO)
	for i in range(1, corners.size()):
		out = out.expand(xf * corners[i])
	return out


## Architectural 4-tone Bauhaus monochrome finish for pre-Color floors (F0..F27).
## Preserves sculptural contrast, metallic sheen, and procedural texture patterns without leaking hues!
static func apply_monochrome_pass(root: Node) -> void:
	var cache: Dictionary = {}
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var src_mat: Material = mi.material_override
			if src_mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
				src_mat = mi.get_surface_override_material(0)
				if src_mat == null:
					src_mat = mi.mesh.surface_get_material(0)
			mi.material_override = _monochrome_material_for(src_mat, cache)
		for c in n.get_children():
			stack.append(c)


static func _monochrome_material_for(src: Material, cache: Dictionary) -> StandardMaterial3D:
	if src != null and cache.has(src):
		return cache[src] as StandardMaterial3D

	var out := StandardMaterial3D.new()
	if src is StandardMaterial3D:
		var sm := src as StandardMaterial3D
		var col := sm.albedo_color
		var lum: float = col.r * 0.299 + col.g * 0.587 + col.b * 0.114
		var tone: Color
		if lum < 0.22:
			tone = Color("18191c")
		elif lum < 0.48:
			tone = Color("3a3c41")
		elif lum < 0.74:
			tone = Color("a0a2a6")
		else:
			tone = Color("ededeb")
		tone.a = col.a
		out.albedo_color = tone
		out.roughness = clampf(sm.roughness, 0.25, 0.88)
		out.metallic = clampf(sm.metallic * 0.75, 0.0, 0.65)
		out.cull_mode = sm.cull_mode
		if sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			out.transparency = sm.transparency
		if sm.albedo_texture != null:
			var gray_tex := _desaturate_texture(sm.albedo_texture)
			if gray_tex != null:
				out.albedo_texture = gray_tex
				out.albedo_color = Color(0.95, 0.95, 0.94, col.a)
				out.uv1_scale = sm.uv1_scale
				out.uv1_triplanar = sm.uv1_triplanar
				out.texture_filter = sm.texture_filter
		if sm.emission_enabled:
			out.emission_enabled = true
			out.emission = Color("e8eaee")
			out.emission_energy_multiplier = minf(sm.emission_energy_multiplier, 0.8)
	else:
		out.albedo_color = Color("d8dce0")
		out.roughness = 0.62

	if src != null:
		cache[src] = out
	return out


static func _desaturate_texture(tex: Texture2D) -> ImageTexture:
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return null
	var copy: Image = img.duplicate() as Image
	if copy.is_compressed():
		copy.decompress()
	var w: int = copy.get_width()
	var h: int = copy.get_height()
	for y in h:
		for x in w:
			var c: Color = copy.get_pixel(x, y)
			var g: float = clampf(c.r * 0.299 + c.g * 0.587 + c.b * 0.114, 0.0, 1.0)
			# Crisp architectural contrast curve around 0.52 so dot-grids & diamonds stay razor sharp.
			g = clampf((g - 0.5) * 1.25 + 0.5, 0.08, 0.95)
			copy.set_pixel(x, y, Color(g, g, g, c.a))
	return ImageTexture.create_from_image(copy)


## Harmonize plinth architectural accent trim with the Color Palette Chooser.
static func accent_for_palette(palette_id: String, monochrome: bool) -> Color:
	if monochrome:
		return Color("2b2f37")
	var pid: String = Bauhaus.resolve_palette(palette_id)
	match pid:
		"monochrome": return Color("2b2f37")
		"bauhaus": return Color("d8432e")
		"queer": return Color("e88aa8")
		"albers": return Color("f2a830")
		"mondrian": return Color("2658a8")
		"memphis": return Color("18b2a8")
		_: return Color("d8432e")
