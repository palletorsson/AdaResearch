extends Node3D
## PATTERN TEMPLE - a Moorish court built from primitives, every surface a pattern receiver.
## Palle, 2026-10-09: "primitives plus pattern bonanza ... a Moorish temple where we can control
## pattern on different walls." Quads, boxes, cylinders, a hemisphere and a ring carry
## wallpaper_tile.gdshader. One desk targets a surface and dresses it: SOURCE (zellige, stars,
## lattice, khatam, brick, three rasters from the tiling halls, every package the Pattern Studio
## has saved), GROUP (the 17 wallpaper groups), PALETTE, SEED (another roll of the same source),
## AGE (dirt, wear, dust, cracks, chips, sun fade together), ALL (this dressing on every surface).
const Pattern = preload("res://commons/artifacts/regularity/tiling_pattern.gd")
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const Loader = preload("res://commons/patterns/pattern_loader.gd")
const PatternGen = preload("res://commons/artifacts/pattern_compositor/pattern_compositor.gd")
const WALLPAPER = preload("res://commons/resourses/shaders/wallpaper_tile.gdshader")
const GROUP_NAMES := ["P1", "P2", "PM", "PG", "CM", "PMM", "PMG", "PGG", "CMM", "P4", "P4M", "P4G", "P3", "P3M1", "P31M", "P6", "P6M"]
const SURFACES := ["FLOOR", "FAR WALL", "EAST WALL", "WEST WALL", "ENTRANCE WALL", "COLUMNS", "DOME", "FRIEZE"]
const PALETTES := [
	["ALHAMBRA", [Color(0.93, 0.90, 0.80), Color(0.05, 0.20, 0.55), Color(0.10, 0.60, 0.60), Color(0.90, 0.65, 0.10), Color(0.08, 0.07, 0.08)]],
	["TERRACOTTA", [Color(0.92, 0.86, 0.74), Color(0.72, 0.32, 0.18), Color(0.12, 0.10, 0.10), Color(0.45, 0.52, 0.30), Color(0.85, 0.60, 0.20)]],
	["AZUL", [Color(0.96, 0.96, 0.94), Color(0.10, 0.15, 0.45), Color(0.05, 0.35, 0.75), Color(0.30, 0.75, 0.85), Color(0.85, 0.70, 0.25)]],
	["MIDNIGHT", [Color(0.06, 0.05, 0.08), Color(0.85, 0.70, 0.25), Color(0.90, 0.88, 0.80), Color(0.10, 0.45, 0.45), Color(0.60, 0.10, 0.15)]],
]
## name, kind, group index (domain) or rule (raster), seed base / exception, tile metres
const SOURCES_FIXED := [
	["ZELLIGE", "domain", 10, 3, 0.5],
	["STARS", "domain", 16, 4, 0.6],
	["LATTICE", "domain", 11, 2, 0.4],
	["KHATAM", "domain", 9, 7, 0.5],
	["BRICK", "domain", 3, 0, 0.3],
	["RULE: QUARTER TURN", "raster", 2, 0, 0.5],
	["RULE: SHIFT ROWS", "raster", 4, 0, 0.5],
	["RULE: ONE EXCEPTION", "raster", 5, 1, 0.5],
]
const AGES := [0.0, 0.25, 0.5, 0.75, 1.0]
const HALF := 7.0
const WALL_H := 6.0
const DOOR := 3.2
const RING := 4.2
var sources: Array = []
var dressing: Array = []      # per surface: {source, group (-1 = the source's own), palette, seed, age}
var materials: Array = []
var meshes: Array = []
var extents: Array = []       # metres per surface, for surface_metres
var marks: Array = []         # where the target marker hovers, per surface
var target := 1
var readout: Label
var marker: MeshInstance3D
var _gen: Node = null
var _pending: Dictionary = {}

func _ready() -> void:
	_gen = PatternGen.new()
	sources = SOURCES_FIXED.duplicate(true)
	for path in _studio_packages():
		sources.append(["STUDIO: " + path.get_file().get_basename().replace("_", " ").to_upper(), "package", 0, 0, 0.5, path])
	var starts := [0, 1, 2, 2, 3, 4, 1, 4]
	for i in SURFACES.size():
		dressing.append({"source": starts[i], "group": -1, "palette": [0, 0, 2, 2, 1, 1, 3, 1][i], "seed": 0, "age": 0})
		var m := ShaderMaterial.new()
		m.shader = WALLPAPER
		materials.append(m)
		meshes.append([])
		extents.append(Vector2.ONE)
		marks.append(Vector3.ZERO)
	_build_court()
	_build_desk()
	if not _pending.is_empty():
		apply_grid_config(_pending)
		_pending = {}
	for i in SURFACES.size():
		_dress(i)
	_move_marker()

## Map-token keys: age (0-4, every surface), target (surface index), source / group / palette
## (indices, every surface). The museum may call this before _ready.
func apply_grid_config(config: Dictionary) -> void:
	if materials.is_empty():
		_pending = config.duplicate()
		return
	for d in dressing:
		if config.has("age"): d["age"] = clampi(int(config["age"]), 0, AGES.size() - 1)
		if config.has("source"): d["source"] = posmod(int(config["source"]), sources.size())
		if config.has("group"): d["group"] = clampi(int(config["group"]), -1, GROUP_NAMES.size() - 1)
		if config.has("palette"): d["palette"] = posmod(int(config["palette"]), PALETTES.size())
	if config.has("target"): target = posmod(int(config["target"]), SURFACES.size())
	for i in SURFACES.size():
		_dress(i)
	_move_marker()

# ── the court ────────────────────────────────────────────────────────────────

func _build_court() -> void:
	_receiver(0, _quad("Floor", Vector2(2 * HALF, 2 * HALF), Vector3(0, 0.03, 0), Vector3(-90, 0, 0)), Vector2(2 * HALF, 2 * HALF))
	marks[0] = Vector3(0, 0.6, 2.0)
	_wall(1, Vector3(0, WALL_H / 2, HALF), 180.0, 2 * HALF)
	marks[1] = Vector3(0, 3.0, HALF - 0.4)
	_wall(2, Vector3(HALF, WALL_H / 2, 0), -90.0, 2 * HALF)
	marks[2] = Vector3(HALF - 0.4, 3.0, 0)
	_wall(3, Vector3(-HALF, WALL_H / 2, 0), 90.0, 2 * HALF)
	marks[3] = Vector3(-HALF + 0.4, 3.0, 0)
	var side := (2 * HALF - DOOR) / 2.0
	_wall(4, Vector3(-(DOOR / 2 + side / 2), WALL_H / 2, -HALF), 0.0, side)
	_wall(4, Vector3(DOOR / 2 + side / 2, WALL_H / 2, -HALF), 0.0, side)
	marks[4] = Vector3(-DOOR / 2 - side / 2, 3.0, -HALF + 0.4)
	# the door's corbelled arch: six courses of teeth closing over the opening
	var top := 2.4
	for c in 6:
		var t := minf(0.3 * (c + 1), DOOR / 2.0)
		var y := 2.4 + 0.4 * c + 0.2
		top = y + 0.2
		for sgn in [-1.0, 1.0]:
			var tooth := _box("Arch%d%s" % [c, "L" if sgn < 0 else "R"], Vector3(t, 0.4, 0.5), Vector3(sgn * (DOOR / 2.0 - t / 2.0), y, -HALF))
			_receiver(7, tooth, Vector2(2.0, 0.4))
	_receiver(4, _quad("EntranceTop", Vector2(DOOR, WALL_H - top), Vector3(0, top + (WALL_H - top) / 2, -HALF + 0.01), Vector3(0, 0, 0)), Vector2(2 * HALF, WALL_H))
	marks[7] = Vector3(0, top + 0.3, -HALF + 0.6)
	# eight columns in a ring, capitals, a ring beam and the dome they carry
	for k in 8:
		var a := k * PI / 4.0 + PI / 8.0
		var at := Vector3(RING * cos(a), 0, RING * sin(a))
		var col := MeshInstance3D.new()
		col.name = "Column%d" % k
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.28
		cyl.bottom_radius = 0.3
		cyl.height = 4.4
		col.mesh = cyl
		col.position = at + Vector3(0, 2.2, 0)
		add_child(col)
		_receiver(5, col, Vector2(1.8, 4.4))
		_receiver(7, _box("Capital%d" % k, Vector3(0.8, 0.3, 0.8), at + Vector3(0, 4.55, 0)), Vector2(2.0, 0.4))
		_collider(Vector3(0.6, 4.4, 0.6), at + Vector3(0, 2.2, 0))
	marks[5] = Vector3(RING * cos(PI / 8.0), 4.9, RING * sin(PI / 8.0))
	# an octagonal entablature: eight lintels, column to column (FRIEZE)
	var chord := 2.0 * RING * sin(PI / 8.0)
	for k in 8:
		var a0 := k * PI / 4.0 + PI / 8.0
		var a1 := a0 + PI / 4.0
		var mid := Vector3(RING * (cos(a0) + cos(a1)) / 2.0, 4.9, RING * (sin(a0) + sin(a1)) / 2.0)
		var lintel := _box("Lintel%d" % k, Vector3(chord + 0.4, 0.4, 0.5), mid)
		lintel.rotation.y = -atan2(sin(a1) - sin(a0), cos(a1) - cos(a0))
		_receiver(7, lintel, Vector2(2.0, 0.4))
	var dome := MeshInstance3D.new()
	dome.name = "Dome"
	var sphere := SphereMesh.new()
	sphere.radius = RING + 0.45
	sphere.height = 3.2
	sphere.is_hemisphere = true
	sphere.flip_faces = true      # the pattern faces inward, where the visitor looks up
	sphere.radial_segments = 48
	sphere.rings = 24
	dome.mesh = sphere
	dome.position = Vector3(0, 5.1, 0)
	add_child(dome)
	_receiver(6, dome, Vector2(2 * PI * (RING + 0.45), 6.0))
	var shell := MeshInstance3D.new()          # the outer skin, so the dome is a dome from outside
	shell.name = "DomeShell"
	var outer := SphereMesh.new()
	outer.radius = RING + 0.5
	outer.height = 3.25
	outer.is_hemisphere = true
	outer.radial_segments = 48
	outer.rings = 24
	shell.mesh = outer
	shell.position = Vector3(0, 5.1, 0)
	add_child(shell)
	_receiver(6, shell, Vector2(2 * PI * (RING + 0.45), 6.0))
	marks[6] = Vector3(0, 6.6, 0)
	marker = MeshInstance3D.new()
	marker.name = "TargetMarker"
	var ball := SphereMesh.new()
	ball.radius = 0.14
	ball.height = 0.28
	marker.mesh = ball
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.85, 0.3)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.75, 0.2)
	glow.emission_energy_multiplier = 2.5
	marker.material_override = glow
	add_child(marker)

func _wall(surface: int, at: Vector3, yaw: float, width: float) -> void:
	var facing := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
	Kit.box(self, "Backing", at - facing * 0.07, _oriented(Vector3(width, WALL_H, 0.12), yaw), Color(0.08, 0.08, 0.08))
	_receiver(surface, _quad("Wall%d" % surface, Vector2(width, WALL_H), at, Vector3(0, yaw, 0)), Vector2(2 * HALF, WALL_H))
	# the same dressing on the outer face: the court is a temple from outside as well
	_receiver(surface, _quad("Outer%d" % surface, Vector2(width, WALL_H), at - facing * 0.14, Vector3(0, yaw + 180.0, 0)), Vector2(2 * HALF, WALL_H))
	_collider(_oriented(Vector3(width, WALL_H, 0.3), yaw), at - facing * 0.1)

func _oriented(size: Vector3, yaw: float) -> Vector3:
	return size if absf(fmod(yaw, 180.0)) < 1.0 else Vector3(size.z, size.y, size.x)

func _quad(title: String, size: Vector2, at: Vector3, turn: Vector3) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := QuadMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.position = at
	n.rotation_degrees = turn
	add_child(n)
	return n

func _box(title: String, size: Vector3, at: Vector3) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.position = at
	add_child(n)
	return n

func _collider(size: Vector3, at: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = at
	add_child(body)

func _receiver(surface: int, mesh: MeshInstance3D, extent: Vector2) -> void:
	mesh.material_override = materials[surface]
	meshes[surface].append(mesh)
	extents[surface] = extent

# ── the desk ────────────────────────────────────────────────────────────────

func _build_desk() -> void:
	var p := Kit.panel(self, "DRESS THE TEMPLE", Vector3(0, 1.2, -2.6), 0.0)
	p.position.y += 0.2 # Keep the second row and its labels above the support.
	p.layout_columns = 4
	p.add_button("TARGET").pressed.connect(next_target)
	p.add_button("SOURCE").pressed.connect(_step.bind("source", 0))
	p.add_button("GROUP").pressed.connect(next_group)
	p.add_button("PALETTE").pressed.connect(_step.bind("palette", PALETTES.size()))
	p.add_button("SEED").pressed.connect(_step.bind("seed", 1000))
	p.add_button("AGE").pressed.connect(_step.bind("age", AGES.size()))
	p.add_button("ALL").pressed.connect(dress_all)
	p.add_button("CLEAN").pressed.connect(clean_all)
	readout = p.add_readout("")

func next_target() -> void:
	target = (target + 1) % SURFACES.size()
	_move_marker()
	_update_readout()

## -1 is the source's own group; then P1 .. P6M.
func next_group() -> void:
	dressing[target]["group"] = ((int(dressing[target]["group"]) + 2) % (GROUP_NAMES.size() + 1)) - 1
	_dress(target)

func clean_all() -> void:
	for d in dressing:
		d["age"] = 0
	for i in SURFACES.size():
		_dress(i)

func _step(key: String, count: int) -> void:
	if count <= 0: count = sources.size()    # SOURCE: the list grows with the studio's packages
	dressing[target][key] = (int(dressing[target][key]) + 1) % count
	_dress(target)

func dress_all() -> void:
	var d: Dictionary = dressing[target]
	for i in SURFACES.size():
		if i == target: continue
		dressing[i] = d.duplicate()
		_dress(i)

func _move_marker() -> void:
	if marker: marker.position = marks[target]

# ── dressing a surface ───────────────────────────────────────────────────────

func _dress(i: int) -> void:
	var d: Dictionary = dressing[i]
	var src: Array = sources[posmod(int(d["source"]), sources.size())]
	var m: ShaderMaterial = materials[i]
	var palette: Array = PALETTES[int(d["palette"]) % PALETTES.size()][1]
	var kind: String = src[1]
	var cells := 1.0
	var tile_m: float = float(src[4])
	if kind == "domain":
		m.set_shader_parameter("domain_texture", _domain_texture(int(src[3]) + 8 * int(d["seed"]), palette))
		m.set_shader_parameter("wallpaper_group", int(src[2]) if int(d["group"]) < 0 else int(d["group"]))
	elif kind == "raster":
		m.set_shader_parameter("domain_texture", _raster_texture(int(src[2]), int(d["seed"]) % 4, int(src[3]) == 1, palette))
		m.set_shader_parameter("wallpaper_group", 0 if int(d["group"]) < 0 else int(d["group"]))
		cells = 8.0
	else:
		var pkg = Loader.load_package(str(src[5]))
		if pkg != null:
			Loader.apply_to_material(m, pkg)
		if int(d["group"]) >= 0:
			m.set_shader_parameter("wallpaper_group", int(d["group"]))
	m.set_shader_parameter("cell_count", cells)
	m.set_shader_parameter("surface_metres", extents[i])
	m.set_shader_parameter("tile_scale", 1.0 / (tile_m * cells))
	m.set_shader_parameter("tile_shape", 0)
	m.set_shader_parameter("grout_width", 0.012)
	m.set_shader_parameter("grout_color", Vector3(0.08, 0.07, 0.07))
	m.set_shader_parameter("roughness", 0.85)
	m.set_shader_parameter("emission_strength", 0.0)
	var a: float = AGES[int(d["age"]) % AGES.size()]
	m.set_shader_parameter("stain_amount", 0.6 * a)
	m.set_shader_parameter("wear_amount", 0.5 * a)
	m.set_shader_parameter("dust_amount", 0.7 * a)
	m.set_shader_parameter("crack_density", 0.5 * a)
	m.set_shader_parameter("chip_amount", 0.2 * a)
	m.set_shader_parameter("fade_amount", 0.3 * a)
	_update_readout()

func _domain_texture(seed_v: int, palette: Array) -> ImageTexture:
	var flat: Array = _gen._generate_domain(seed_v)
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			var idx := y * 8 + x
			var ci: int = int(flat[idx]) if idx < flat.size() else 0
			img.set_pixel(x, y, palette[ci % palette.size()])
	return ImageTexture.create_from_image(img)

func _raster_texture(rule: int, phase: int, exception: bool, palette: Array) -> ImageTexture:
	var img: Image = Pattern.image_for(rule, phase, exception)
	var ink: Color = palette[1]
	var paper: Color = palette[0]
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, ink if img.get_pixel(x, y).r < 0.5 else paper)
	return ImageTexture.create_from_image(img)

func _studio_packages() -> Array:
	var found: Array = []
	_scan("res://commons/patterns", found, 0)
	found.sort()
	return found.slice(0, 8)

func _scan(dir_path: String, found: Array, depth: int) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null or depth > 2: return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var path := dir_path.path_join(name)
		if dir.current_is_dir():
			if not name.begins_with("."): _scan(path, found, depth + 1)
		elif name.ends_with(".json"):
			found.append(path)
		name = dir.get_next()
	dir.list_dir_end()

func _update_readout() -> void:
	if readout == null or dressing.is_empty(): return
	var d: Dictionary = dressing[target]
	var src: Array = sources[posmod(int(d["source"]), sources.size())]
	var group_i: int = int(d["group"])
	if group_i < 0:
		group_i = int(src[2]) if src[1] == "domain" else 0
	readout.text = "%s | %s | %s | %s\nseed %d | age %.2f" % [SURFACES[target], src[0], GROUP_NAMES[clampi(group_i, 0, GROUP_NAMES.size() - 1)], PALETTES[int(d["palette"]) % PALETTES.size()][0], int(d["seed"]), AGES[int(d["age"]) % AGES.size()]]
