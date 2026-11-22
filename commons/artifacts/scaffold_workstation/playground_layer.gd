class_name PlaygroundLayer
extends RefCounted
## General Intellect Playground Layer runtime helper.
## Reads commons/data/playground_layer.json, computes exact cumulative sequence
## unlocks per tower floor, generates Random Walk playgrounds, and builds
## walkable Randomness (Spiky) & Noise (Smooth configurable) basin surfaces at
## both 1:16 miniature and 1:4 physical VR glass-box scale.

const SPEC_PATH := "res://commons/data/playground_layer.json"
const Bauhaus := preload("res://commons/artifacts/scaffold_workstation/bauhaus_kit.gd")

const SURFACE_MODES: Array[String] = ["flat", "spikes", "noise"]
const PATTERN_MODES: Array[String] = ["plain", "checker", "diamond", "stripe"]
const ARRAY_MODES: Array[String] = ["1x", "1d", "2d", "3d"]
const ISO_FORMS: Array[String] = ["tunnel", "crossing", "dome", "spiral_ramp", "gutter_ramp", "basin"]
const NOISE_GENERATORS: Array[String] = ["simplex", "perlin", "cellular"]

static var _spec_cache: Dictionary = {}


static func spec() -> Dictionary:
	if _spec_cache.is_empty() and FileAccess.file_exists(SPEC_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPEC_PATH))
		if parsed is Dictionary:
			_spec_cache = parsed as Dictionary
	return _spec_cache


## Cumulative capability flags unlocked at a given Void Tower floor (F0..F209).
## Strictly honors Concept Order #1 (monochrome before F28, no kinetic objects before F13, etc.).
static func capabilities_for_floor(floor_idx: int) -> Dictionary:
	var f: int = floor_idx
	return {
		"floor": f,
		"base_primitives": true,
		"kinetic_objects": f >= 13,          # Transformation F13+: placeable Package, Power Coin, Proximity Bomb
		"arrays": f >= 23,                   # Arrays F23+: 1D / 2D / 3D array stamping
		"color_palettes": f >= 28,           # Color F28+: 6-Palette Chooser + spray coats
		"panel_patterns": f >= 37,           # Tiling/Pattern F37+: procedural panel patterns
		"force_pads": f >= 45,               # Forces F45+: Jump Forward Pads & Sound Jump Pads
		"big_pipes": f >= 62,                # Wavefunctions F62+: Big Pipe Systems
		"random_walk": f >= 74,              # Randomness F74+: Random Walk generator & Spiky Basin surface
		"noise_surface": f >= 89,            # Noise F89+: Configurable walkable smooth Noise surface
		"ca_neighbors": f >= 106,            # CA F106+: Neighbour-cell control
		"fractals_menger": f >= 114,         # Fractals F114+: Menger Sponge playgrounds
		"lsystem_plants": f >= 121,          # L-Systems F121+: Playground botanical props
		"softbodies": f >= 136,              # Softbodies F136+: Deformable pads & canopies
		"iso_cutouts": f >= 145,             # Isosurfaces / Booleans F145+: 4x4x4 carved cutout prefabs
		"mindmap_mode": f >= 161,            # Cities & Beyond F161+: Thinking mind-map negotiation
		"full_atelier": f >= 208,
	}


static func sequence_title_for_floor(floor_idx: int) -> String:
	if floor_idx >= 208:
		return "ATELIER · GENERAL INTELLECT SANDBOX"
	if floor_idx >= 145:
		return "ISOSURFACE & BOOLEAN SPACES"
	if floor_idx >= 89:
		return "WALKABLE NOISE BASIN"
	if floor_idx >= 74:
		return "RANDOM WALK & SPIKE BASIN"
	if floor_idx >= 45:
		return "FORCES · JUMP & SOUND PADS"
	if floor_idx >= 37:
		return "PATTERNED PANELS"
	if floor_idx >= 28:
		return "COLOUR PALETTES & COATS"
	if floor_idx >= 23:
		return "1D · 2D · 3D ARRAYS"
	if floor_idx >= 13:
		return "TRANSFORMATION · KINETIC OBJECTS"
	return "PRIMITIVES · BASE GRAMMAR"


## Expand one anchor address into 1D / 2D / 3D array offsets (in 2 m address units).
static func array_offsets(array_mode: String, rot_quarter: int) -> Array[Vector3]:
	var dir_x := Vector3(1.0, 0.0, 0.0).rotated(Vector3.UP, -rot_quarter * PI * 0.5).round()
	var dir_z := Vector3(0.0, 0.0, 1.0).rotated(Vector3.UP, -rot_quarter * PI * 0.5).round()
	match array_mode:
		"1d":
			return [Vector3.ZERO, dir_x, dir_x * 2.0]
		"2d":
			return [Vector3.ZERO, dir_x, dir_z, dir_x + dir_z]
		"3d":
			return [
				Vector3.ZERO, dir_x, dir_z, dir_x + dir_z,
				Vector3(0, 0.5, 0), dir_x + Vector3(0, 0.5, 0), dir_z + Vector3(0, 0.5, 0), dir_x + dir_z + Vector3(0, 0.5, 0),
			]
		_:
			return [Vector3.ZERO]


## Procedural procedural Texture2D for Pattern-sequence panels (F37+ & F209).
static var _pattern_cache: Dictionary = {}

static func pattern_material(base_col: Color, pattern_mode: String, phase: String) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [base_col.to_html(false), pattern_mode, phase]
	if _pattern_cache.has(key):
		return _pattern_cache[key] as StandardMaterial3D

	var mat := StandardMaterial3D.new()
	mat.roughness = 0.56
	mat.metallic = 0.04
	if pattern_mode == "plain":
		mat.albedo_color = base_col
		_pattern_cache[key] = mat
		return mat

	var ink := Color("181a20")
	var contrast := ink if (base_col.r * 0.299 + base_col.g * 0.587 + base_col.b * 0.114) > 0.42 else Color("f2f2ee")
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var alt := false
			match pattern_mode:
				"checker":
					alt = ((x / 16) + (y / 16)) % 2 == 1
				"diamond":
					var dx: int = absi((x % 32) - 16)
					var dy: int = absi((y % 32) - 16)
					alt = (dx + dy) < 12
				"stripe":
					alt = ((x + y) / 8) % 2 == 1
			img.set_pixel(x, y, contrast if alt else base_col)
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.albedo_color = Color.WHITE
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_scale = Vector3(2.0, 2.0, 1.0)
	_pattern_cache[key] = mat
	return mat


## Generate a walkable Bauhaus Random Walk Playground course inside the 20m x 14m domain.
## Returns {quad_cells: Array[Vector3], ramps: Array[Dictionary], objects: Array[Dictionary]}
## so StudioWorkstation can stamp pure canonical model.gd records + gameplay objects cleanly!
static func generate_random_walk_plan(rng_seed: int, caps: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	var visited: Dictionary = {}
	var path: Array[Vector2i] = []
	var cur := Vector2i(-3, 1)
	path.append(cur)
	visited["%d,%d" % [cur.x, cur.y]] = true

	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0)]
	for _step in 14:
		var cands: Array[Vector2i] = []
		for d in dirs:
			var nx: int = cur.x + d.x
			var nz: int = cur.y + d.y
			if nx < -4 or nx > 3 or nz < -2 or nz > 1:
				continue
			var k := "%d,%d" % [nx, nz]
			if visited.has(k):
				continue
			# Mild eastward bias so the random walk sweeps across the 20 m court gracefully.
			cands.append(Vector2i(nx, nz))
			if d.x > 0:
				cands.append(Vector2i(nx, nz))
		if cands.is_empty():
			break
		cur = cands[rng.randi_range(0, cands.size() - 1)]
		path.append(cur)
		visited["%d,%d" % [cur.x, cur.y]] = true
		if path.size() >= 8:
			break

	var quads: Array[Vector3] = []
	var ramps: Array[Dictionary] = []
	var objects: Array[Dictionary] = []

	for idx in path.size():
		var c: Vector2i = path[idx]
		var elev: float = 0.5 if idx < 5 else 1.0
		quads.append(Vector3(float(c.x), elev, float(c.y)))

	# Entry ramp leading onto first quad from south (+Z).
	var first_c: Vector2i = path[0]
	ramps.append({"kind": "wedge", "at": [float(first_c.x) + 0.5, 0.0, float(first_c.y) + 1.5], "turn": [0, 2, 0]})

	# Landmark pyramid flanking the walk.
	var last_c: Vector2i = path[path.size() - 1]
	ramps.append({"kind": "pyramid", "at": [clampf(float(last_c.x) + 0.5, -4.0, 4.0), 0.0, -2.5], "turn": [0, 0, 0]})

	# Populate Transformation / Forces / Isosurface interactive elements along the random walk!
	if bool(caps.get("kinetic_objects", false)):
		if path.size() >= 2:
			var p_coin: Vector2i = path[1]
			objects.append({"kind": "coin", "at": [float(p_coin.x) + 0.5, 0.5, float(p_coin.y) + 0.5], "turn": [0, 0, 0]})
		if path.size() >= 4:
			var p_pkg: Vector2i = path[3]
			objects.append({"kind": "package", "at": [float(p_pkg.x) + 0.5, 0.5, float(p_pkg.y) + 0.5], "turn": [0, 0, 0]})
		if path.size() >= 6:
			var p_bomb: Vector2i = path[5]
			objects.append({"kind": "bomb", "at": [float(p_bomb.x) + 0.5, 1.0, float(p_bomb.y) + 0.5], "turn": [0, 0, 0]})
	if bool(caps.get("force_pads", false)) and path.size() >= 5:
		var p_pad: Vector2i = path[4]
		objects.append({"kind": "jump_pad", "at": [float(p_pad.x) + 0.5, 0.5, float(p_pad.y) + 0.5], "turn": [0, 0, 0]})
	if bool(caps.get("iso_cutouts", false)):
		objects.append({"kind": "iso_cutout", "at": [-2.5, 0.0, -2.0], "turn": [0, 0, 0], "form": ISO_FORMS[rng.randi_range(0, ISO_FORMS.size() - 1)]})

	return {"quads": quads, "ramps": ramps, "objects": objects, "seed": rng_seed, "steps": path.size()}


## Build a walkable Basin Surface (Randomness spiky obstacle surface OR configurable smooth Noise surface)
## scaled to fit either the 1:16 tabletop miniature (`with_collider = false`) or the 1:4 physical glass box (`with_collider = true`).
static func build_basin_surface(mode: String, field_w: float, field_d: float, center_z: float, relief_scale: float, phase: String, cfg: Dictionary = {}, with_collider: bool = false) -> Node3D:
	var host := Node3D.new()
	host.name = "BasinSurface_" + mode
	if mode == "flat":
		return host

	var cols: int = 24 if mode == "spikes" else 28
	var rows: int = 16 if mode == "spikes" else 20
	var seed_val: int = int(cfg.get("seed", 42))
	var amp_m: float = float(cfg.get("amplitude", 0.55 if mode == "spikes" else 0.72)) * relief_scale
	var freq: float = float(cfg.get("frequency", 0.24))
	var octaves: int = clampi(int(cfg.get("octaves", 3)), 1, 4)
	var gen: String = str(cfg.get("generator", "simplex"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var fn := FastNoiseLite.new()
	fn.seed = seed_val
	fn.frequency = freq
	fn.fractal_type = FastNoiseLite.FRACTAL_FBM
	fn.fractal_octaves = octaves
	match gen:
		"perlin": fn.noise_type = FastNoiseLite.TYPE_PERLIN
		"cellular": fn.noise_type = FastNoiseLite.TYPE_CELLULAR
		_: fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	# Sample height grid (edges smoothly taper to 0 so START pad & glass-box rim always meet cleanly!).
	var heights: Array[float] = []
	heights.resize((cols + 1) * (rows + 1))
	for j in range(rows + 1):
		var v: float = float(j) / float(rows)
		var ez: float = sin(v * PI)
		for i in range(cols + 1):
			var u: float = float(i) / float(cols)
			var ex: float = sin(u * PI)
			var env: float = clampf(minf(ex, ez) * 2.4, 0.0, 1.0)
			var h: float = 0.0
			if mode == "spikes":
				# Independent RandomSpace exponential/uniform draw -> sharp, hard-to-walk spikes!
				var draw: float = rng.randf()
				var spike: float = -log(maxf(0.04, 1.0 - draw)) * 0.38
				h = clampf(spike, 0.0, 1.25) * amp_m * env
			else:
				# Smooth correlated NoiseSpace fBm relief -> organic walkable undulating hills!
				var nval: float = fn.get_noise_2d(u * 10.0, v * 7.0) * 0.5 + 0.5
				h = nval * amp_m * env
			heights[j * (cols + 1) + i] = h

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base_low := Color("2b2f37") if phase == "monochrome" else Bauhaus.swatch_colors(phase)[0].darkened(0.25)
	var base_high := Color("ededeb") if phase == "monochrome" else Bauhaus.swatch_colors(phase)[2]
	if mode == "spikes":
		base_low = Color("1b1e24") if phase == "monochrome" else Color("2b2f37")
		base_high = Color("cfd4d8") if phase == "monochrome" else Bauhaus.swatch_colors(phase)[1]

	var max_h: float = maxf(0.001, amp_m)
	for j in rows:
		for i in cols:
			var p00 := _grid_pt(i, j, cols, rows, field_w, field_d, center_z, heights)
			var p10 := _grid_pt(i + 1, j, cols, rows, field_w, field_d, center_z, heights)
			var p11 := _grid_pt(i + 1, j + 1, cols, rows, field_w, field_d, center_z, heights)
			var p01 := _grid_pt(i, j + 1, cols, rows, field_w, field_d, center_z, heights)
			_add_tri(st, p00, p10, p11, base_low, base_high, max_h)
			_add_tri(st, p00, p11, p01, base_low, base_high, max_h)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "SurfaceMesh"
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.72 if mode == "noise" else 0.52
	mat.metallic = 0.08 if mode == "spikes" else 0.02
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	host.add_child(mi)

	if with_collider:
		var sb := StaticBody3D.new()
		sb.name = "SurfaceCollider"
		sb.collision_layer = 1
		var cs := CollisionShape3D.new()
		cs.shape = mesh.create_trimesh_shape()
		sb.add_child(cs)
		host.add_child(sb)

	return host


static func _grid_pt(i: int, j: int, cols: int, rows: int, w: float, d: float, cz: float, hs: Array[float]) -> Vector3:
	var x: float = -w * 0.5 + (float(i) / float(cols)) * w
	var z: float = cz - d * 0.5 + (float(j) / float(rows)) * d
	var y: float = hs[j * (cols + 1) + i]
	return Vector3(x, y, z)


static func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, low: Color, high: Color, max_h: float) -> void:
	for p in [a, b, c]:
		st.set_color(low.lerp(high, clampf(p.y / max_h, 0.0, 1.0)))
		st.add_vertex(p)
