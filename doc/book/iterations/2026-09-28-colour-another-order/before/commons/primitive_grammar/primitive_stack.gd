# primitive_stack.gd — Bauhaus-descended primitive-composition renderer.
# Takes a config declaring a layout (vertical_stack / pendant_thread /
# under_plate / wall_grid) and a list of primitives with colors/sizes,
# produces a Node3D with the arranged shapes.
#
# The algorithmic family this covers: Siedhoff-Buscher's Bauspiel,
# Coco Reynolds' Art Pendant Light, Vignelli's Metafora Coffee Table,
# Dorothee Becker's Uten.Silo, Lady Lamp. Same alphabet, different layouts.
#
# Alphabet: sphere, cube, cuboid, cylinder, cone, hemisphere, wedge, disc,
# bipyramid, prism. 10 primitives, each built from Godot's primitive meshes
# or ArrayMesh for the few that don't have direct equivalents.

extends RefCounted

const LSystemSimPS    = preload("res://commons/lsystem_grammar/lsystem_sim.gd")
const LSystemTurtlePS = preload("res://commons/lsystem_grammar/lsystem_turtle.gd")
const CAPruneOpPS     = preload("res://commons/graph_grammar/operations/ca_prune_op.gd")
const RDSimPS         = preload("res://commons/rd_grammar/rd_sim.gd")


# ─── Palettes ──────────────────────────────────────────────────

const PALETTES: Dictionary = {
	"bauhaus":  [Color(0.76, 0.22, 0.18), Color(0.94, 0.77, 0.18), Color(0.10, 0.12, 0.18),
	             Color(0.14, 0.31, 0.44), Color(0.21, 0.38, 0.25), Color(0.93, 0.92, 0.88)],
	"wood":     [Color(0.45, 0.30, 0.20), Color(0.60, 0.42, 0.26), Color(0.75, 0.58, 0.35),
	             Color(0.32, 0.22, 0.16), Color(0.86, 0.74, 0.52)],
	"mono":     [Color(0.08, 0.08, 0.1), Color(0.92, 0.92, 0.93), Color(0.45, 0.45, 0.48)],
	"pastel":   [Color(0.95, 0.75, 0.72), Color(0.85, 0.9, 0.75), Color(0.72, 0.82, 0.9),
	             Color(0.88, 0.82, 0.95), Color(0.95, 0.88, 0.7)],
	"metafora": [Color(0.4, 0.22, 0.18), Color(0.86, 0.75, 0.55), Color(0.1, 0.1, 0.12),
	             Color(0.7, 0.7, 0.72)],
}


## Build the Node3D tree from a config dict.
static func build(cfg: Dictionary) -> Node3D:
	var layout: String = str(cfg.get("layout", "vertical_stack"))
	match layout:
		"vertical_stack": return _build_vertical_stack(cfg)
		"pendant_thread": return _build_pendant_thread(cfg)
		"under_plate":    return _build_under_plate(cfg)
		"wall_grid":      return _build_wall_grid(cfg)
		"scatter":        return _build_scatter(cfg)
		"table_cross":    return _build_table_cross(cfg)
		"table_pedestal": return _build_table_pedestal(cfg)
		"revolution":        return _build_revolution(cfg)
		"revolution_petals": return _build_revolution_petals(cfg)
		"compose":           return _build_compose(cfg)
		"lsystem_scatter":   return _build_lsystem_scatter(cfg)
		"ca_scatter":        return _build_ca_scatter(cfg)
		"rd_scatter":        return _build_rd_scatter(cfg)
	return _build_vertical_stack(cfg)


# ─── Layout: vertical stack (Bauhaus totem) ──────────────────

static func _build_vertical_stack(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "VerticalStack"
	var alphabet: Array = cfg.get("alphabet", ["sphere", "cube", "cylinder", "cone", "hemisphere"])
	var palette_name: String = str(cfg.get("palette", "bauhaus"))
	var palette: Array = PALETTES.get(palette_name, PALETTES["bauhaus"])
	var base_scale: float = float(cfg.get("base_scale", 0.3))
	var scale_variation: float = float(cfg.get("scale_variation", 0.3))
	var seed_val: int = int(cfg.get("seed", 7))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Optional explicit sequence overrides random alphabet picks.
	# When sequence is provided, its length determines count.
	var sequence = cfg.get("sequence", null)
	var count: int
	if sequence != null:
		count = sequence.size()
	else:
		count = int(cfg.get("count", 4))

	var y_cursor: float = 0.0
	for i in count:
		var shape: String
		var color: Color
		var size_factor: float
		if sequence != null and i < sequence.size():
			var item: Dictionary = sequence[i]
			shape = str(item.get("shape", "cube"))
			var col_val = item.get("color", null)
			color = _parse_color(col_val, palette, rng)
			size_factor = float(item.get("scale", 1.0))
		else:
			shape = alphabet[rng.randi() % alphabet.size()]
			color = palette[rng.randi() % palette.size()]
			size_factor = 1.0 + rng.randf_range(-scale_variation, scale_variation)
		var size: float = base_scale * size_factor
		var entry: Dictionary = _make_primitive(shape, size, color)
		var mi: MeshInstance3D = entry["mesh"]
		var height: float = entry["height"]
		mi.position = Vector3(0, y_cursor + height * 0.5, 0)
		root.add_child(mi)
		y_cursor += height
	return root


# ─── Layout: pendant thread (Coco Reynolds) ──────────────────

static func _build_pendant_thread(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "PendantThread"
	var alphabet: Array = cfg.get("alphabet", ["disc", "bipyramid", "sphere"])
	var palette_name: String = str(cfg.get("palette", "wood"))
	var palette: Array = PALETTES.get(palette_name, PALETTES["wood"])
	var count: int = int(cfg.get("count", 12))
	var base_scale: float = float(cfg.get("base_scale", 0.06))
	var cord_length: float = float(cfg.get("cord_length", 2.4))
	var bulb_radius: float = float(cfg.get("bulb_radius", 0.12))
	var seed_val: int = int(cfg.get("seed", 7))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Hanging cord (thin dark cylinder)
	var cord := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.004; cm.bottom_radius = 0.004
	cm.height = cord_length; cm.radial_segments = 6
	cord.mesh = cm
	cord.position = Vector3(0, -cord_length * 0.5, 0)
	var cord_mat := StandardMaterial3D.new()
	cord_mat.albedo_color = Color(0.1, 0.08, 0.07)
	cord.material_override = cord_mat
	root.add_child(cord)

	# Beads threaded on cord, spaced evenly with size variation
	var start_y: float = 0.0
	var end_y: float = -cord_length + bulb_radius * 2.2
	var bead_spacing: float = (start_y - end_y) / float(count + 1)
	for i in count:
		var shape: String = alphabet[rng.randi() % alphabet.size()]
		var color: Color = palette[rng.randi() % palette.size()]
		var size_factor: float = 1.0 + rng.randf_range(-0.4, 0.6)
		var size: float = base_scale * size_factor
		var entry: Dictionary = _make_primitive(shape, size, color)
		var mi: MeshInstance3D = entry["mesh"]
		mi.position = Vector3(0, start_y - bead_spacing * float(i + 1), 0)
		root.add_child(mi)

	# Glowing bulb at bottom
	var bulb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = bulb_radius; bm.height = bulb_radius * 2.0
	bm.radial_segments = 20; bm.rings = 10
	bulb.mesh = bm
	bulb.position = Vector3(0, end_y - bulb_radius, 0)
	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(1.0, 0.85, 0.55, 0.7)
	bulb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1.0, 0.85, 0.55)
	bulb_mat.emission_energy_multiplier = 2.5
	bulb_mat.roughness = 0.3
	bulb.material_override = bulb_mat
	root.add_child(bulb)
	return root


# ─── Layout: under plate (Vignelli Metafora) ─────────────────

static func _build_under_plate(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "UnderPlate"
	var palette_name: String = str(cfg.get("palette", "metafora"))
	var palette: Array = PALETTES.get(palette_name, PALETTES["metafora"])
	var legs: Array = cfg.get("legs", [
		{"shape": "sphere"}, {"shape": "cylinder"}, {"shape": "cube"}, {"shape": "wedge"}
	])
	var leg_size: float = float(cfg.get("leg_size", 0.22))
	var plate_radius: float = float(cfg.get("plate_radius", 0.75))
	var plate_thickness: float = float(cfg.get("plate_thickness", 0.02))
	var plate_color_arr = cfg.get("plate_color", [0.95, 0.95, 0.93])
	var plate_color := Color(float(plate_color_arr[0]), float(plate_color_arr[1]), float(plate_color_arr[2]))
	var seed_val: int = int(cfg.get("seed", 7))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Distribute legs around a circle
	for i in legs.size():
		var leg: Dictionary = legs[i]
		var shape: String = str(leg.get("shape", "sphere"))
		var col_val = leg.get("color", null)
		var color: Color = _parse_color(col_val, palette, rng)
		var size: float = leg_size * float(leg.get("scale", 1.0))
		var entry: Dictionary = _make_primitive(shape, size, color)
		var mi: MeshInstance3D = entry["mesh"]
		var angle: float = (float(i) / float(legs.size())) * TAU
		var r: float = plate_radius * 0.65
		mi.position = Vector3(cos(angle) * r, entry["height"] * 0.5, sin(angle) * r)
		root.add_child(mi)

	# Glass plate on top (suggest with a thin cylinder)
	var plate := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = plate_radius; pm.bottom_radius = plate_radius
	pm.height = plate_thickness; pm.radial_segments = 48
	plate.mesh = pm
	plate.position = Vector3(0, leg_size + plate_thickness * 0.5, 0)
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = Color(plate_color.r, plate_color.g, plate_color.b, 0.25)
	plate_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plate_mat.roughness = 0.15
	plate_mat.metallic = 0.0
	plate.material_override = plate_mat
	root.add_child(plate)
	return root


# ─── Layout: wall grid (Becker Uten.Silo) ────────────────────

static func _build_wall_grid(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "WallGrid"
	var cols: int = int(cfg.get("cols", 6))
	var rows: int = int(cfg.get("rows", 5))
	var cell: float = float(cfg.get("cell_size", 0.18))
	var alphabet: Array = cfg.get("alphabet", ["cube", "cylinder", "hemisphere", "wedge", "cuboid"])
	var palette_name: String = str(cfg.get("palette", "mono"))
	var palette: Array = PALETTES.get(palette_name, PALETTES["mono"])
	var seed_val: int = int(cfg.get("seed", 7))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Backing panel
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(cell * float(cols) + 0.05, cell * float(rows) + 0.05, 0.02)
	panel.mesh = pm
	panel.position = Vector3(0, 0, -0.02)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.92, 0.92, 0.92)
	panel.material_override = pmat
	root.add_child(panel)

	for y in rows:
		for x in cols:
			# Skip random cells to produce organic empty pockets
			if rng.randf() < 0.15:
				continue
			var shape: String = alphabet[rng.randi() % alphabet.size()]
			var color: Color = palette[rng.randi() % palette.size()]
			var size: float = cell * (0.7 + rng.randf_range(-0.1, 0.2))
			var entry: Dictionary = _make_primitive(shape, size, color)
			var mi: MeshInstance3D = entry["mesh"]
			var px: float = (float(x) - float(cols - 1) * 0.5) * cell
			var py: float = (float(y) - float(rows - 1) * 0.5) * cell
			mi.position = Vector3(px, py, entry["height"] * 0.5)
			root.add_child(mi)
	return root


# ─── Layout: scatter (generic primitives floating) ───────────

static func _build_scatter(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Scatter"
	var count: int = int(cfg.get("count", 10))
	var alphabet: Array = cfg.get("alphabet", ["sphere", "cube", "cylinder", "cone", "hemisphere"])
	var palette_name: String = str(cfg.get("palette", "bauhaus"))
	var palette: Array = PALETTES.get(palette_name, PALETTES["bauhaus"])
	var extent: float = float(cfg.get("extent", 1.5))
	var seed_val: int = int(cfg.get("seed", 7))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for i in count:
		var shape: String = alphabet[rng.randi() % alphabet.size()]
		var color: Color = palette[rng.randi() % palette.size()]
		var size: float = 0.12 + rng.randf_range(-0.04, 0.08)
		var entry: Dictionary = _make_primitive(shape, size, color)
		var mi: MeshInstance3D = entry["mesh"]
		mi.position = Vector3(
			rng.randf_range(-extent, extent),
			rng.randf_range(0.0, extent),
			rng.randf_range(-extent, extent),
		)
		root.add_child(mi)
	return root


# ─── Primitive factory ────────────────────────────────────────

static func _make_primitive(shape: String, size: float, color: Color) -> Dictionary:
	var mi := MeshInstance3D.new()
	var mesh: Mesh
	var height: float = size
	match shape:
		"sphere":
			var m := SphereMesh.new()
			m.radius = size * 0.5; m.height = size
			m.radial_segments = 24; m.rings = 12
			mesh = m
			height = size
		"cube":
			var m := BoxMesh.new()
			m.size = Vector3(size, size, size)
			mesh = m
			height = size
		"cuboid":
			var m := BoxMesh.new()
			m.size = Vector3(size * 1.3, size * 0.5, size * 1.3)
			mesh = m
			height = size * 0.5
		"cylinder":
			var m := CylinderMesh.new()
			m.top_radius = size * 0.4; m.bottom_radius = size * 0.4
			m.height = size; m.radial_segments = 24
			mesh = m
			height = size
		"cone":
			var m := CylinderMesh.new()
			m.top_radius = 0.0; m.bottom_radius = size * 0.5
			m.height = size * 1.2; m.radial_segments = 24
			mesh = m
			height = size * 1.2
		"hemisphere":
			var m := SphereMesh.new()
			m.radius = size * 0.5; m.height = size * 0.5
			m.radial_segments = 24; m.rings = 8
			m.is_hemisphere = true
			mesh = m
			height = size * 0.5
		"disc":
			var m := CylinderMesh.new()
			m.top_radius = size * 0.5; m.bottom_radius = size * 0.5
			m.height = size * 0.15; m.radial_segments = 24
			mesh = m
			height = size * 0.15
		"wedge":
			mesh = _wedge_mesh(size)
			height = size
		"bipyramid":
			mesh = _bipyramid_mesh(size)
			height = size * 1.2
		"prism":
			mesh = _prism_mesh(size)
			height = size
		_:
			var m := BoxMesh.new()
			m.size = Vector3(size, size, size)
			mesh = m
			height = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.0
	mi.material_override = mat
	return {"mesh": mi, "height": height}


# ─── VR-budget helpers: unit meshes for MultiMesh scatter layouts ──
#
# Each scatter layout places many instances of the same shape. Using
# individual MeshInstance3D nodes costs one draw call per instance —
# prohibitive in VR (100+ instances = 100+ draw calls). MultiMeshInstance3D
# collapses N instances into a single draw call.
#
# _make_unit_mesh(shape) returns a size=1.0 Mesh for the shape; scatter
# builders then per-instance-scale via set_instance_transform.

static func _make_unit_mesh(shape: String) -> Mesh:
	var entry: Dictionary = _make_primitive(shape, 1.0, Color.WHITE)
	var mi: MeshInstance3D = entry["mesh"]
	var mesh: Mesh = mi.mesh
	mi.queue_free()   # discard the wrapper MeshInstance3D; keep the Mesh
	return mesh


# Build a single-shape MultiMeshInstance3D.
# instances = Array of {pos: Vector3, scale: Vector3, color: Color}
static func _make_multimesh_scatter(shape: String, instances: Array,
		node_name: String = "Scatter") -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _make_unit_mesh(shape)
	mm.instance_count = instances.size()
	for i in instances.size():
		var inst: Dictionary = instances[i]
		var pos: Vector3 = inst["pos"]
		var sc: Vector3 = inst.get("scale", Vector3.ONE)
		var col: Color = inst.get("color", Color.WHITE)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(sc), pos))
		mm.set_instance_color(i, col)
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	mat.metallic = 0.0
	mmi.material_override = mat
	return mmi


static func _wedge_mesh(size: float) -> ArrayMesh:
	# Right triangular prism lying on its side — like a slice of cheese
	var h: float = size * 0.5
	var verts := PackedVector3Array([
		# Bottom triangle
		Vector3(-size * 0.5, -h, -size * 0.5),
		Vector3( size * 0.5, -h, -size * 0.5),
		Vector3(-size * 0.5, -h,  size * 0.5),
		# Top triangle (apex)
		Vector3(-size * 0.5,  h, -size * 0.5),
		Vector3(-size * 0.5,  h,  size * 0.5),
	])
	var indices := PackedInt32Array([
		0, 1, 2,            # bottom
		3, 0, 4, 4, 0, 2,   # left face
		3, 4, 0, 0, 4, 2,   # duplicate OK
		0, 3, 1,            # front (slanted)
		1, 3, 4, 1, 4, 2,   # slanted top
	])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


static func _bipyramid_mesh(size: float) -> ArrayMesh:
	# Double-tipped diamond — two square pyramids glued at base
	var r: float = size * 0.5
	var h: float = size * 0.6
	var verts := PackedVector3Array([
		Vector3( 0,  h, 0),   # top apex
		Vector3( r,  0, 0),
		Vector3( 0,  0, r),
		Vector3(-r,  0, 0),
		Vector3( 0,  0,-r),
		Vector3( 0, -h, 0),   # bottom apex
	])
	var indices := PackedInt32Array([
		0, 1, 2,  0, 2, 3,  0, 3, 4,  0, 4, 1,   # top
		5, 2, 1,  5, 3, 2,  5, 4, 3,  5, 1, 4,   # bottom
	])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


static func _prism_mesh(size: float) -> ArrayMesh:
	# Triangular prism standing on one triangular face
	var r: float = size * 0.5
	var h: float = size
	var verts := PackedVector3Array([
		Vector3( 0,  0,  r),
		Vector3(-r,  0, -r * 0.577),
		Vector3( r,  0, -r * 0.577),
		Vector3( 0,  h,  r),
		Vector3(-r,  h, -r * 0.577),
		Vector3( r,  h, -r * 0.577),
	])
	var indices := PackedInt32Array([
		0, 1, 2,   3, 5, 4,
		0, 3, 1,   1, 3, 4,
		1, 4, 2,   2, 4, 5,
		2, 5, 0,   0, 5, 3,
	])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


# ─── Layout: table_cross (Johanna Grawunder XXX Table) ───────
# Two translucent colored panels crossing in an X shape, round disc top.
# Subtractive color mixing where the panels overlap — alpha transparency
# is sufficient because the render order blends back-to-front.

static func _build_table_cross(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "TableCross"
	var panels: Array = cfg.get("panels", [
		{"color": "#ff6a3d", "alpha": 0.6},
		{"color": "#d63384", "alpha": 0.6},
	])
	var height: float = float(cfg.get("height", 0.42))
	var width: float = float(cfg.get("width", 0.8))
	var panel_thickness: float = float(cfg.get("panel_thickness", 0.018))
	var top_radius: float = float(cfg.get("top_radius", 0.5))
	var top_color_arr = cfg.get("top_color", [0.95, 0.55, 0.3])
	var top_alpha: float = float(cfg.get("top_alpha", 0.55))

	# Panel 1 — aligned with X axis
	for i in panels.size():
		var p: Dictionary = panels[i]
		var col_str = p.get("color", "#ff6a3d")
		var alpha: float = float(p.get("alpha", 0.6))
		var color := Color(col_str) if col_str is String else Color(float(col_str[0]), float(col_str[1]), float(col_str[2]))
		color.a = alpha
		var panel := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(width, height, panel_thickness)
		panel.mesh = m
		# Alternate 0° / 90° around Y so panels cross
		var angle: float = (float(i) / float(panels.size())) * PI
		panel.rotation = Vector3(0, angle, 0)
		panel.position = Vector3(0, height * 0.5, 0)
		panel.material_override = _translucent_material(color)
		root.add_child(panel)

	# Top disc — thin cylinder
	var top := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = top_radius; tm.bottom_radius = top_radius
	tm.height = 0.025; tm.radial_segments = 48
	top.mesh = tm
	top.position = Vector3(0, height + 0.012, 0)
	var top_color := Color(float(top_color_arr[0]), float(top_color_arr[1]), float(top_color_arr[2]), top_alpha)
	top.material_override = _translucent_material(top_color)
	root.add_child(top)
	return root


# ─── Layout: table_pedestal (Ana Kraš Slon Round Table) ──────
# Round wooden top on cylindrical pedestal with vertical stripes.

static func _build_table_pedestal(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "TablePedestal"
	var height: float = float(cfg.get("height", 0.72))
	var top_radius: float = float(cfg.get("top_radius", 0.45))
	var top_thickness: float = float(cfg.get("top_thickness", 0.04))
	var top_color_arr = cfg.get("top_color", [0.78, 0.55, 0.4])
	var pedestal_radius: float = float(cfg.get("pedestal_radius", 0.22))
	var stripe_count: int = int(cfg.get("stripe_count", 24))
	var stripe_colors = cfg.get("stripe_colors", [[0.08, 0.08, 0.1], [0.96, 0.96, 0.94]])

	# Pedestal — many thin vertical box-stripes wrapped around a circle
	var stripe_y: float = (height - top_thickness) * 0.5
	var stripe_h: float = height - top_thickness
	for i in stripe_count:
		var angle: float = (float(i) / float(stripe_count)) * TAU
		var col_idx: int = i % stripe_colors.size()
		var col_val = stripe_colors[col_idx]
		var col := Color(float(col_val[0]), float(col_val[1]), float(col_val[2]))
		var stripe := MeshInstance3D.new()
		var sm := BoxMesh.new()
		# Chord width so stripes touch: ~2πr / N
		var chord: float = (TAU * pedestal_radius) / float(stripe_count) * 1.05
		sm.size = Vector3(chord, stripe_h, 0.02)
		stripe.mesh = sm
		stripe.position = Vector3(cos(angle) * pedestal_radius, stripe_y, sin(angle) * pedestal_radius)
		# Rotate so stripe face faces outward
		stripe.rotation = Vector3(0, -angle + PI * 0.5, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = 0.65
		stripe.material_override = mat
		root.add_child(stripe)

	# Round top
	var top := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = top_radius; tm.bottom_radius = top_radius
	tm.height = top_thickness; tm.radial_segments = 48
	top.mesh = tm
	top.position = Vector3(0, height - top_thickness * 0.5, 0)
	var top_mat := StandardMaterial3D.new()
	top_mat.albedo_color = Color(float(top_color_arr[0]), float(top_color_arr[1]), float(top_color_arr[2]))
	top_mat.roughness = 0.6
	top.material_override = top_mat
	root.add_child(top)
	return root


static func _translucent_material(color_with_alpha: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color_with_alpha
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	m.roughness = 0.18
	m.metallic = 0.0
	m.refraction_enabled = false
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _parse_color(val, palette: Array, rng: RandomNumberGenerator) -> Color:
	if val == null:
		return palette[rng.randi() % palette.size()]
	if val is String:
		return Color(val as String)
	if val is Array and val.size() >= 3:
		return Color(float(val[0]), float(val[1]), float(val[2]))
	return palette[rng.randi() % palette.size()]


# ─── Layout: revolution (lamp shade from profile curve) ──────
# Revolve a 2D profile [(y, radius), ...] around the Y axis, optionally
# adding vertical ribs (fluting). The profile is the DNA — each lamp
# family is a different profile curve.
#
# Params:
#   profile       — list of [y, radius] keypoints (interpolated linearly)
#   segments      — radial resolution (default 48)
#   height_samples — vertical resolution (default 32, interpolates profile)
#   ribs          — vertical flute count (default 0 — smooth)
#   rib_amount    — how much the radius modulates per rib (default 0.08)
#   color         — material color
#   alpha         — 1.0 opaque, <1.0 translucent
#   emission      — emission energy (default 0.0)

static func _build_revolution(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Revolution"
	var profile: Array = cfg.get("profile", [[0, 0.2], [0.5, 0.4], [1.0, 0.1]])
	var segments: int = int(cfg.get("segments", 48))
	var h_samples: int = int(cfg.get("height_samples", 32))
	var ribs: int = int(cfg.get("ribs", 0))
	var rib_amount: float = float(cfg.get("rib_amount", 0.08))
	var color_arr = cfg.get("color", [0.95, 0.95, 0.92])
	var alpha: float = float(cfg.get("alpha", 1.0))
	var emission: float = float(cfg.get("emission", 0.0))

	var mesh := _build_revolution_mesh(profile, segments, h_samples, ribs, rib_amount, 1.0)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _shade_material(
		Color(float(color_arr[0]), float(color_arr[1]), float(color_arr[2]), alpha),
		emission,
	)
	root.add_child(mi)
	return root


# ─── Layout: revolution_petals (Pipistrello-style N petals) ──

static func _build_revolution_petals(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "RevolutionPetals"
	var profile: Array = cfg.get("profile", [[0, 0.05], [0.3, 0.35], [0.6, 0.45], [1.0, 0.35]])
	var petal_count: int = int(cfg.get("petal_count", 4))
	var petal_arc: float = float(cfg.get("petal_arc", 0.75))  # fraction of full circle each petal covers
	var segments: int = int(cfg.get("segments", 16))
	var h_samples: int = int(cfg.get("height_samples", 28))
	var color_arr = cfg.get("color", [0.96, 0.96, 0.94])
	var alpha: float = float(cfg.get("alpha", 0.95))
	var emission: float = float(cfg.get("emission", 0.5))
	var base_color_arr = cfg.get("base_color", [0.08, 0.08, 0.1])
	var base_radius: float = float(cfg.get("base_radius", 0.08))
	var base_height: float = float(cfg.get("base_height", 0.3))

	# Narrow base stem (chrome/tulip)
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = base_radius * 0.6; sm.bottom_radius = base_radius
	sm.height = base_height; sm.radial_segments = 24
	stem.mesh = sm
	stem.position = Vector3(0, base_height * 0.5, 0)
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(float(base_color_arr[0]), float(base_color_arr[1]), float(base_color_arr[2]))
	stem_mat.metallic = 0.7
	stem_mat.roughness = 0.25
	stem.material_override = stem_mat
	root.add_child(stem)

	# Petals — each one is a partial revolution covering petal_arc of the circle
	var petal_arc_rad: float = petal_arc * TAU / float(petal_count)
	for i in petal_count:
		var center_angle: float = (float(i) / float(petal_count)) * TAU
		var mesh := _build_partial_revolution_mesh(
			profile, segments, h_samples,
			center_angle - petal_arc_rad * 0.5,
			center_angle + petal_arc_rad * 0.5,
		)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = Vector3(0, base_height, 0)
		mi.material_override = _shade_material(
			Color(float(color_arr[0]), float(color_arr[1]), float(color_arr[2]), alpha),
			emission,
		)
		root.add_child(mi)
	return root


# ─── Mesh builders for revolutions ─────────────────────────────

static func _build_revolution_mesh(profile: Array, segments: int,
		h_samples: int, ribs: int, rib_amount: float, radius_scale: float) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	# Sample profile at h_samples heights (interpolate between keypoints)
	var sampled: Array = _resample_profile(profile, h_samples)
	for i in sampled.size():
		var pt: Array = sampled[i]
		var y: float = pt[0]
		var r: float = pt[1] * radius_scale
		for j in segments:
			var a: float = (float(j) / float(segments)) * TAU
			var rib_mod: float = 1.0
			if ribs > 0:
				rib_mod = 1.0 + cos(a * float(ribs)) * rib_amount
			var rr: float = r * rib_mod
			verts.append(Vector3(cos(a) * rr, y, sin(a) * rr))
			normals.append(Vector3(cos(a), 0, sin(a)))
	for i in sampled.size() - 1:
		for j in segments:
			var j2: int = (j + 1) % segments
			var a: int = i * segments + j
			var b: int = i * segments + j2
			var c: int = (i + 1) * segments + j2
			var d: int = (i + 1) * segments + j
			indices.append_array([a, b, c, a, c, d])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


static func _build_partial_revolution_mesh(profile: Array, segments: int,
		h_samples: int, angle_start: float, angle_end: float) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var sampled: Array = _resample_profile(profile, h_samples)
	for i in sampled.size():
		var pt: Array = sampled[i]
		var y: float = pt[0]
		var r: float = pt[1]
		for j in segments + 1:
			var t: float = float(j) / float(segments)
			var a: float = lerp(angle_start, angle_end, t)
			verts.append(Vector3(cos(a) * r, y, sin(a) * r))
			normals.append(Vector3(cos(a), 0, sin(a)))
	var stride: int = segments + 1
	for i in sampled.size() - 1:
		for j in segments:
			var a: int = i * stride + j
			var b: int = i * stride + j + 1
			var c: int = (i + 1) * stride + j + 1
			var d: int = (i + 1) * stride + j
			indices.append_array([a, b, c, a, c, d])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


static func _resample_profile(profile: Array, n: int) -> Array:
	# Sample profile at n uniformly-spaced heights between y_min and y_max.
	# Linear interpolation between keypoints.
	var y_min: float = float(profile[0][0])
	var y_max: float = float(profile[profile.size() - 1][0])
	var out: Array = []
	for i in n:
		var y: float = lerp(y_min, y_max, float(i) / float(n - 1))
		# Find surrounding keypoints
		var r: float = float(profile[0][1])
		for k in profile.size() - 1:
			var a: Array = profile[k]
			var b: Array = profile[k + 1]
			if y >= float(a[0]) and y <= float(b[0]):
				var t: float = 0.0
				if float(b[0]) > float(a[0]):
					t = (y - float(a[0])) / (float(b[0]) - float(a[0]))
				r = lerp(float(a[1]), float(b[1]), t)
				break
		out.append([y, r])
	return out


# ─── Layout: compose (cross-fertilization) ────────────────────
# Stack N sub-configs at specified y-offsets. Each sub-config is a
# complete primitive_stack config (any layout). The compose node becomes
# the parent; each child inherits position from its y-offset.
#
# Example: {"parts": [
#     {"y": 0, "config": {layout: "table_pedestal", ...}},
#     {"y": 0.72, "config": {layout: "revolution", ...}},
# ]}
# → striped pedestal with a lathed lamp shade on top of it.
#
# Params:
#   parts — list of {y, config} entries; config recurses into build()

static func _build_compose(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Compose"
	var parts: Array = cfg.get("parts", [])
	for p in parts:
		var y_off: float = float(p.get("y", 0.0))
		var sub_cfg = p.get("config", null)
		if sub_cfg == null or not (sub_cfg is Dictionary):
			continue
		var sub_root: Node3D = build(sub_cfg)
		sub_root.position = Vector3(0, y_off, 0)
		root.add_child(sub_root)
	return root


static func _shade_material(color: Color, emission: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if color.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.3
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = Color(color.r, color.g, color.b)
		m.emission_energy_multiplier = emission
	return m


# ─── Layout: lsystem_scatter — DNA bridge from L-system ──────
# Walk an L-system turtle and place a primitive at each segment midpoint,
# leaf marker, and branch point. Primitives pulled from the configured
# alphabet. Sizes/colors can map by segment depth.
#
# This is the bridge that makes the L-system string DNA for primitive_stack:
# the same grammar that draws a tree becomes a sculpture of placed cubes,
# spheres, cylinders — whatever the alphabet says.
static func _build_lsystem_scatter(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "LSystemScatter"

	var ls: Dictionary = cfg.get("lsystem", {})
	var axiom: String = String(ls.get("axiom", "F"))
	var rules: Dictionary = ls.get("rules", {})
	var iters: int = int(ls.get("iterations", 3))
	var seed_val: int = int(ls.get("seed", 0))
	var has_stoch := false
	for k in rules.keys():
		if rules[k] is Array: has_stoch = true; break
	var s: String
	if has_stoch:
		s = LSystemSimPS.rewrite_stochastic(axiom, rules, iters, seed_val)
	else:
		s = LSystemSimPS.rewrite(axiom, rules, iters)
	var walk: Dictionary = LSystemTurtlePS.walk(s, {
		"angle_deg":   float(ls.get("angle_deg", 25.7)),
		"step_len":    float(ls.get("step_len", 0.25)),
		"step_shrink": float(ls.get("step_shrink", 0.72)),
		"seed":        seed_val,
	})
	var segments: Array = walk["segments"]
	var leaves: Array = walk["leaves"]
	var branch_pts: Array = walk["branch_points"]

	# Alphabet: which primitive for segment / branch / leaf
	var seg_shape: String = String(cfg.get("segment_shape", "sphere"))
	var branch_shape: String = String(cfg.get("branch_shape", "cube"))
	var leaf_shape: String = String(cfg.get("leaf_shape", "sphere"))

	var palette_name: String = String(cfg.get("palette", "bauhaus"))
	var palette: Array = PALETTES.get(palette_name, PALETTES["bauhaus"])
	var trunk_color: Color = _to_color(palette[0])
	var tip_color: Color = _to_color(palette[-1])

	var base_size: float = float(cfg.get("primitive_size", 0.06))
	var size_by_depth: bool = bool(cfg.get("size_by_depth", true))

	var max_depth := 1
	for seg in segments:
		max_depth = max(max_depth, int(seg[2]))

	# Bucket instances by shape. Three shapes (segment / branch / leaf) →
	# three MultiMeshInstance3D nodes → 3 draw calls total regardless of
	# how many turtle segments the L-system emits. Previously: 1 draw
	# call per segment + per branch point + per leaf (often 200+).
	var seg_instances: Array = []
	for seg in segments:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var d: int = int(seg[2])
		var t: float = clampf(float(d) / float(max_depth), 0.0, 1.0)
		var col := trunk_color.lerp(tip_color, t)
		var sz := base_size
		if size_by_depth:
			sz *= lerp(1.0, 0.35, t)
		seg_instances.append({
			"pos": (a + b) * 0.5,
			"scale": Vector3(sz, sz, sz),
			"color": col,
		})
	if seg_instances.size() > 0:
		root.add_child(_make_multimesh_scatter(seg_shape, seg_instances, "Segments"))

	var branch_color: Color = _to_color(palette[min(1, palette.size() - 1)])
	var branch_instances: Array = []
	for bp in branch_pts:
		branch_instances.append({
			"pos": bp,
			"scale": Vector3.ONE * (base_size * 0.9),
			"color": branch_color,
		})
	if branch_instances.size() > 0:
		root.add_child(_make_multimesh_scatter(branch_shape, branch_instances, "BranchPoints"))

	var leaf_instances: Array = []
	for lp in leaves:
		leaf_instances.append({
			"pos": lp,
			"scale": Vector3.ONE * (base_size * 1.1),
			"color": tip_color,
		})
	if leaf_instances.size() > 0:
		root.add_child(_make_multimesh_scatter(leaf_shape, leaf_instances, "Leaves"))

	return root


static func _to_color(v) -> Color:
	if v is Array and v.size() >= 3:
		var a: float = 1.0 if v.size() < 4 else float(v[3])
		return Color(float(v[0]), float(v[1]), float(v[2]), a)
	if v is Color: return v
	return Color.WHITE


# ─── Layout: ca_scatter — DNA bridge from cellular automata ───
# Run a 2D CA, place a primitive at every alive cell. Height optionally
# driven by neighbor count at the final step (denser = taller).
#
# The same {ca: {rule, grid_size, density}} block works as a seed in
# graph-grammar and a topology in soft-body — here it's a layout.
static func _build_ca_scatter(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "CAScatter"

	var ca: Dictionary = cfg.get("ca", {})
	var rule_name: String = String(ca.get("rule", "conway"))
	var N: int = int(ca.get("grid_size", 24))
	var iters: int = int(ca.get("iterations", 12))
	var density: float = float(ca.get("density", 0.45))
	var seed_val: int = int(ca.get("seed", 7))
	var cell: float = float(ca.get("cell_size", 0.12))

	var CA_RULES := {
		"conway":             {"B": [3],       "S": [2, 3]},
		"highlife":           {"B": [3, 6],    "S": [2, 3]},
		"seeds":              {"B": [2],       "S": []},
		"life_without_death": {"B": [3],       "S": [0, 1, 2, 3, 4, 5, 6, 7, 8]},
		"day_and_night":      {"B": [3, 6, 7, 8], "S": [3, 4, 6, 7, 8]},
	}
	var r_def: Dictionary = CA_RULES.get(rule_name, CA_RULES["conway"])
	var grid: PackedInt32Array = CAPruneOpPS._simulate_ca(
		N, r_def["B"], r_def["S"], iters, density, seed_val)

	var shape: String = String(cfg.get("shape", "cube"))
	var palette_name: String = String(cfg.get("palette", "bauhaus"))
	var palette: Array = PALETTES.get(palette_name, PALETTES["bauhaus"])
	var base_size: float = float(cfg.get("primitive_size", 0.08))
	var height_from_neighbors: bool = bool(cfg.get("height_from_neighbors", true))
	var height_scale: float = float(cfg.get("height_scale", 0.4))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Collect instance specs first, then emit as a single MultiMeshInstance3D.
	# VR budget: this layout used to produce N individual MeshInstance3D nodes,
	# one draw call each. Now: 1 draw call total.
	var instances: Array = []
	for row in N:
		for col in N:
			if grid[row * N + col] == 0: continue
			var h: float = base_size
			if height_from_neighbors:
				var n: int = 0
				for dr in [-1, 0, 1]:
					for dc in [-1, 0, 1]:
						if dr == 0 and dc == 0: continue
						var rr: int = row + dr; var cc: int = col + dc
						if rr < 0 or rr >= N or cc < 0 or cc >= N: continue
						if grid[rr * N + cc] == 1: n += 1
				h = base_size + float(n) * height_scale * base_size
			var color: Color = palette[rng.randi() % palette.size()]
			var x: float = (float(col) - float(N - 1) * 0.5) * cell
			var z: float = (float(row) - float(N - 1) * 0.5) * cell
			var sy: float = (h / max(base_size, 0.001)) if height_from_neighbors else 1.0
			instances.append({
				"pos": Vector3(x, h * 0.5, z),
				"scale": Vector3(base_size, base_size * sy, base_size),
				"color": color,
			})
	root.add_child(_make_multimesh_scatter(shape, instances, "CACells"))
	return root


# ─── Layout: rd_scatter — DNA bridge from Reaction-Diffusion ───
# Run Gray-Scott, place a primitive at every above-threshold cell.
# Height scaled by V concentration — ridges rise, valleys stay flat.
# Same {rd: {preset | F, K, iterations, ...}} block as graph-grammar and soft-body.
static func _build_rd_scatter(cfg: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "RDScatter"

	var rd: Dictionary = cfg.get("rd", {})
	var N: int = int(rd.get("grid_size", 64))
	var cell: float = float(rd.get("cell_size", 0.08))
	var threshold: float = float(rd.get("threshold", 0.22))

	var field: PackedFloat32Array = RDSimPS.simulate(rd)

	var shape: String = String(cfg.get("shape", "sphere"))
	var palette_name: String = String(cfg.get("palette", "bauhaus"))
	var palette: Array = PALETTES.get(palette_name, PALETTES["bauhaus"])
	var base_size: float = float(cfg.get("primitive_size", 0.05))
	var height_from_v: bool = bool(cfg.get("height_from_v", true))
	var height_amp: float = float(cfg.get("height_amp", 0.6))

	# Collect + emit as single MultiMeshInstance3D. VR-budget: 1 draw call.
	var instances: Array = []
	for row in N:
		for col in N:
			var v: float = field[row * N + col]
			if v <= threshold: continue
			var t: float = clampf(v * 2.0, 0.0, 1.0)
			var col_c: Color = palette[0].lerp(palette[-1], t)
			var x: float = (float(col) - float(N - 1) * 0.5) * cell
			var z: float = (float(row) - float(N - 1) * 0.5) * cell
			var h: float = (v * height_amp) if height_from_v else base_size
			var sy: float = max(h / max(base_size, 0.001), 0.05) if height_from_v else 1.0
			var pos_y: float = (h * 0.5) if height_from_v else 0.0
			instances.append({
				"pos": Vector3(x, pos_y, z),
				"scale": Vector3(base_size, base_size * sy, base_size),
				"color": col_c,
			})
	root.add_child(_make_multimesh_scatter(shape, instances, "RDCells"))
	return root
