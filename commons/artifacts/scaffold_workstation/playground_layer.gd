class_name PlaygroundLayer
extends RefCounted
## General Intellect Playground Layer runtime helper.
## Reads commons/data/playground_layer.json, computes exact cumulative sequence
## unlocks per tower floor, generates Random Walk playgrounds, and builds
## walkable Randomness (Spiky) & Noise (Smooth configurable) basin surfaces at
## both 1:16 miniature and 1:4 physical VR glass-box scale.

const SPEC_PATH := "res://commons/data/playground_layer.json"
const Bauhaus := preload("res://commons/artifacts/scaffold_workstation/bauhaus_kit.gd")
const SoundJumpPadScript := preload("res://commons/artifacts/scaffold_workstation/sound_jump_pad.gd")

const SURFACE_MODES: Array[String] = ["flat", "spikes", "noise"]
const PATTERN_MODES: Array[String] = ["plain", "checker", "diamond", "stripe"]
const ARRAY_MODES: Array[String] = ["1x", "1d", "2d", "3d"]
const ISO_FORMS: Array[String] = ["tunnel", "crossing", "dome", "spiral_ramp", "gutter_ramp", "basin"]
const NOISE_GENERATORS: Array[String] = ["simplex", "perlin", "cellular"]
const NOISE_PRESETS: Array[Dictionary] = [
	{"id": "simplex_med", "label": "SMPLX M", "generator": "simplex", "octaves": 3, "amplitude": 0.72, "frequency": 0.24, "seed": 42},
	{"id": "perlin_high", "label": "PRLN HI", "generator": "perlin", "octaves": 4, "amplitude": 1.05, "frequency": 0.30, "seed": 77},
	{"id": "cellular_step", "label": "CELLULR", "generator": "cellular", "octaves": 2, "amplitude": 0.88, "frequency": 0.28, "seed": 19},
	{"id": "simplex_low", "label": "SMPLX L", "generator": "simplex", "octaves": 2, "amplitude": 0.42, "frequency": 0.16, "seed": 11},
]
const PENTATONIC_HZ: Array[float] = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25]

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
	if floor_idx >= 161:
		return "MIND MAP · CITIES & NEGOTIATION"
	if floor_idx >= 145:
		return "ISOSURFACE & BOOLEAN SPACES"
	if floor_idx >= 121:
		return "L-SYSTEMS · BOTANICAL PROPS"
	if floor_idx >= 114:
		return "FRACTALS · MENGER SPONGE"
	if floor_idx >= 106:
		return "CELLULAR AUTOMATA · NEIGHBOURS"
	if floor_idx >= 89:
		return "WALKABLE NOISE BASIN"
	if floor_idx >= 74:
		return "RANDOM WALK & SPIKE BASIN"
	if floor_idx >= 62:
		return "WAVEFUNCTIONS · BIG PIPES"
	if floor_idx >= 45:
		return "FORCES · JUMP & SOUND PADS"
	if floor_idx >= 37:
		return "PATTERNED PANELS"
	if floor_idx >= 28:
		return "COLOUR PALETTES & SPRAY"
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


# ── Cellular Automata (F106+): Neighbour-cell Conway B3/S23 playground evolution ──

static func step_cellular_automata(records: Array[Dictionary], generation: int) -> Dictionary:
	# Grid domain of 2m quad bays: x in [-4..3] (8 cols), z in [-2..1] (4 rows).
	const MIN_X := -4
	const MAX_X := 3
	const MIN_Z := -2
	const MAX_Z := 1
	var alive: Dictionary = {}
	for r in records:
		if str(r.get("kind", "")) == "quad" and r.get("plane", []) == [0, 2]:
			var ax: int = clampi(int(roundf(float(r.at[0]))), MIN_X, MAX_X)
			var az: int = clampi(int(roundf(float(r.at[2]))), MIN_Z, MAX_Z)
			alive[Vector2i(ax, az)] = true

	var next_alive: Dictionary = {}
	if alive.size() < 3:
		# Seed a rich asymmetric Bauhaus R-Pentomino + beacon cluster so step 1 immediately delights!
		for c: Vector2i in [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-2, 0)]:
			next_alive[c] = true
	else:
		for x in range(MIN_X, MAX_X + 1):
			for z in range(MIN_Z, MAX_Z + 1):
				var cell := Vector2i(x, z)
				var n := 0
				for dx in [-1, 0, 1]:
					for dz in [-1, 0, 1]:
						if dx == 0 and dz == 0:
							continue
						if alive.has(Vector2i(x + dx, z + dz)):
							n += 1
				var was_alive: bool = alive.has(cell)
				if (was_alive and (n == 2 or n == 3)) or (not was_alive and n == 3):
					next_alive[cell] = true
		if next_alive.is_empty():
			for c: Vector2i in [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1)]:
				next_alive[c] = true

	var quads: Array[Vector3] = []
	var ramps: Array[Dictionary] = []
	var south_cell := Vector2i(0, MIN_Z)
	var found_south := false
	for c: Vector2i in next_alive.keys():
		var n_live := 0
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if next_alive.has(c + d):
				n_live += 1
		# Interior high-neighbour cells rise to 2 m (1.0), perimeter cells sit at 1 m (0.5).
		var elev: float = 1.0 if n_live >= 3 else 0.5
		quads.append(Vector3(float(c.x), elev, float(c.y)))
		if not found_south or c.y > south_cell.y:
			south_cell = c
			found_south = true

	if found_south:
		var ramp_z: float = minf(2.5, float(south_cell.y) + 1.5)
		ramps.append({"kind": "wedge", "at": [float(south_cell.x) + 0.5, 0.0, ramp_z], "turn": [0, 2, 0]})

	return {
		"quads": quads,
		"ramps": ramps,
		"alive_count": next_alive.size(),
		"generation": generation + 1,
	}


# ── Fractals (F114+): Recursive Menger Sponge Playground (walkable pavilion + Level-2 MultiMesh monument) ──

static func generate_menger_sponge_plan(seed_val: int, caps: Dictionary) -> Dictionary:
	# Walkable 3x3 Bauhaus Menger court: outer 8 cells elevated around hollow central shaft (0,0),
	# plus 4 corner towers rising to 2m and central carved crossing tunnels!
	var quads: Array[Vector3] = []
	var ramps: Array[Dictionary] = []
	var objects: Array[Dictionary] = []
	var cx := -1
	var cz := -1
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0:
				continue  # Central vertical Menger void!
			var bx := float(cx + dx)
			var bz := float(cz + dz)
			quads.append(Vector3(bx, 0.5, bz))
			if abs(dx) == 1 and abs(dz) == 1:
				# 4 fractal corner piers rise to Level 2 (2m)!
				quads.append(Vector3(bx, 1.0, bz))
	# Entry ramps on South (+Z) and East (+X) leading cleanly onto the Menger court.
	ramps.append({"kind": "wedge", "at": [-0.5, 0.0, 1.5], "turn": [0, 2, 0]})
	ramps.append({"kind": "wedge", "at": [1.5, 0.0, -0.5], "turn": [0, 3, 0]})
	# Recursive Level-2 Menger Sponge sculpture standing in the East showcase court (400 sub-cubes in 1 MultiMesh draw call!).
	objects.append({"kind": "menger_block", "at": [3.0, 0.0, -0.5], "turn": [0, seed_val % 4, 0], "depth": 2})
	if bool(caps.get("lsystem_plants", false)):
		objects.append({"kind": "lsystem_plant", "at": [-3.5, 0.0, -1.5], "turn": [0, 0, 0]})
		objects.append({"kind": "lsystem_plant", "at": [-3.5, 0.0, 1.5], "turn": [0, 1, 0]})
	return {"quads": quads, "ramps": ramps, "objects": objects, "seed": seed_val}


static func _menger_subcubes(depth: int) -> Array[Dictionary]:
	# Returns normalized [{pos: Vector3 in [-0.5..0.5], size: float}] for a unit Menger cube.
	var cells: Array[Dictionary] = [{"pos": Vector3.ZERO, "size": 1.0}]
	for _d in clampi(depth, 1, 2):
		var next: Array[Dictionary] = []
		for c in cells:
			var p: Vector3 = c.pos
			var s: float = float(c.size) / 3.0
			for x in [-1, 0, 1]:
				for y in [-1, 0, 1]:
					for z in [-1, 0, 1]:
						var zeros: int = (1 if x == 0 else 0) + (1 if y == 0 else 0) + (1 if z == 0 else 0)
						if zeros >= 2:
							continue  # Carve the 3 orthogonal Menger tunnels!
						next.append({"pos": p + Vector3(x, y, z) * s, "size": s})
		cells = next
	return cells


static var _menger_cache: Dictionary = {}


static func build_menger_sponges_multimesh(
	parent: Node3D,
	items: Array[Dictionary],
	unit: float,
	offset: Vector3,
	phase: String,
	with_collider: bool = false,
	cast_shadows: bool = false
) -> Dictionary:
	if items.is_empty():
		return {"multimeshes": 0, "instances": 0, "draw_calls": 0}
	var xforms: Array[Transform3D] = []
	var sb: StaticBody3D = null
	if with_collider:
		sb = StaticBody3D.new()
		sb.name = "MengerColliders"
		sb.collision_layer = 1
		parent.add_child(sb)

	var span: float = 1.45 * unit  # ~2.9 m grand climbable fractal pavilion at 1:1 VR scale
	for ob in items:
		var depth: int = clampi(int(ob.get("depth", 2)), 1, 2)
		if not _menger_cache.has(depth):
			_menger_cache[depth] = _menger_subcubes(depth)
		var subcubes: Array = _menger_cache[depth]
		var origin: Vector3 = Vector3(float(ob.at[0]), float(ob.at[1]), float(ob.at[2])) * unit + offset
		var rot_y: float = float(ob.get("turn", [0, 0, 0])[1]) * PI * 0.5
		var base_xform := Transform3D(Basis(Vector3.UP, rot_y), origin + Vector3(0.0, span * 0.5, 0.0))
		for c in subcubes:
			var sc: float = float(c.size) * span * 0.985
			var local_xf := Transform3D(Basis.from_scale(Vector3.ONE * sc), (c.pos as Vector3) * span)
			xforms.append(base_xform * local_xf)
		if with_collider and sb != null:
			# Level-1 20-box compound collider matches walkable outer ribs & hollow cross tunnels cleanly!
			if not _menger_cache.has(1):
				_menger_cache[1] = _menger_subcubes(1)
			var col_cubes: Array = _menger_cache[1]
			var sub_s: float = span / 3.0
			var shared_box := BoxShape3D.new()
			shared_box.size = Vector3.ONE * sub_s
			for cc in col_cubes:
				var cs := CollisionShape3D.new()
				cs.shape = shared_box
				cs.transform = base_xform * Transform3D(Basis.IDENTITY, (cc.pos as Vector3) * span)
				sb.add_child(cs)

	var mat: Material = Bauhaus.mat("quad", phase) if phase == "monochrome" else Bauhaus.mat("pyramid", phase)
	Bauhaus.add_box_multimesh(parent, "MM_MengerSponges", xforms, mat, cast_shadows)
	return {"multimeshes": 1, "instances": xforms.size(), "draw_calls": 1}


# ── Wavefunctions (F62+): Big Pipe System MultiMesh batcher (2 draw calls for ALL pipe tunnels!) ──

static func build_big_pipes_multimesh(
	parent: Node3D,
	items: Array[Dictionary],
	unit: float,
	offset: Vector3,
	phase: String,
	with_collider: bool = false,
	cast_shadows: bool = false
) -> Dictionary:
	if items.is_empty():
		return {"multimeshes": 0, "instances": 0, "draw_calls": 0}
	var stave_xforms: Array[Transform3D] = []
	var flange_xforms: Array[Transform3D] = []
	var sb: StaticBody3D = null
	if with_collider:
		sb = StaticBody3D.new()
		sb.name = "BigPipeColliders"
		sb.collision_layer = 1
		parent.add_child(sb)

	var length: float = 1.0 * unit        # 2 m pipe module
	var radius: float = 0.44 * unit       # 1.76 m walkable/crawlable inner bore!
	var stave_w: float = 0.36 * unit
	var stave_t: float = 0.055 * unit
	var flange_w: float = 0.42 * unit
	var flange_t: float = 0.085 * unit
	var flange_len: float = 0.09 * unit

	var floor_shape: BoxShape3D = null
	var wall_shape: BoxShape3D = null
	if with_collider:
		floor_shape = BoxShape3D.new()
		floor_shape.size = Vector3(radius * 1.4, stave_t, length)
		wall_shape = BoxShape3D.new()
		wall_shape.size = Vector3(stave_t, radius * 1.7, length)

	for ob in items:
		var origin: Vector3 = Vector3(float(ob.at[0]), float(ob.at[1]), float(ob.at[2])) * unit + offset
		var rot_y: float = float(ob.get("turn", [0, 0, 0])[1]) * PI * 0.5
		var center_xf := Transform3D(Basis(Vector3.UP, rot_y), origin + Vector3(0.0, radius + stave_t * 0.5, 0.0))
		# 8 octagonal industrial pipe staves forming a real hollow walkable Bauhaus tube!
		for s_idx in 8:
			var ang: float = float(s_idx) * (TAU / 8.0)
			var dir := Vector3(sin(ang), cos(ang), 0.0)
			var stave_rot := Basis(Vector3.BACK, -ang)
			var sx := Transform3D(stave_rot * Basis.from_scale(Vector3(stave_w, stave_t, length)), dir * radius)
			stave_xforms.append(center_xf * sx)
			for fz in [-length * 0.45, length * 0.45]:
				var fx := Transform3D(stave_rot * Basis.from_scale(Vector3(flange_w, flange_t, flange_len)), dir * (radius + stave_t * 0.45) + Vector3(0.0, 0.0, fz))
				flange_xforms.append(center_xf * fx)

		if with_collider and sb != null:
			# Hollow walk-through collider: bottom deck, top deck (walkable roof!), left wall, right wall.
			for sy in [-radius, radius]:
				var cs := CollisionShape3D.new()
				cs.shape = floor_shape
				cs.transform = center_xf * Transform3D(Basis.IDENTITY, Vector3(0.0, sy, 0.0))
				sb.add_child(cs)
			for sx_pos in [-radius, radius]:
				var cs := CollisionShape3D.new()
				cs.shape = wall_shape
				cs.transform = center_xf * Transform3D(Basis.IDENTITY, Vector3(sx_pos, 0.0, 0.0))
				sb.add_child(cs)

	var body_mat: Material = Bauhaus.mat("quad", phase) if phase == "monochrome" else Bauhaus.mat("rod", phase)
	var flange_mat: Material = Bauhaus.mat("frame", phase)
	Bauhaus.add_box_multimesh(parent, "MM_BigPipes_Body", stave_xforms, body_mat, cast_shadows)
	Bauhaus.add_box_multimesh(parent, "MM_BigPipes_Flanges", flange_xforms, flange_mat, cast_shadows)
	return {"multimeshes": 2, "instances": stave_xforms.size() + flange_xforms.size(), "draw_calls": 2}


# ── L-Systems (F121+): Procedural Branching Plant Props batched in 2 MultiMesh draw calls! ──

static func build_lsystem_plants_multimesh(
	parent: Node3D,
	items: Array[Dictionary],
	unit: float,
	offset: Vector3,
	phase: String,
	with_collider: bool = false,
	cast_shadows: bool = false
) -> Dictionary:
	if items.is_empty():
		return {"multimeshes": 0, "instances": 0, "draw_calls": 0}
	var stem_xforms: Array[Transform3D] = []
	var leaf_xforms: Array[Transform3D] = []
	var sb: StaticBody3D = null
	var trunk_shape: BoxShape3D = null
	if with_collider:
		sb = StaticBody3D.new()
		sb.name = "LSystemPlantColliders"
		sb.collision_layer = 1
		parent.add_child(sb)
		trunk_shape = BoxShape3D.new()
		trunk_shape.size = Vector3(0.16, 0.72, 0.16) * unit

	for idx in items.size():
		var ob: Dictionary = items[idx]
		var origin: Vector3 = Vector3(float(ob.at[0]), float(ob.at[1]), float(ob.at[2])) * unit + offset
		var species: int = int(ob.get("turn", [0, 0, 0])[1]) % 4
		var rot_y: float = float(species) * PI * 0.5
		var base_xf := Transform3D(Basis(Vector3.UP, rot_y), origin)
		# Crisp Bauhaus planter plinth grounding the L-system cleanly onto the grid!
		stem_xforms.append(base_xf * Transform3D(Basis.from_scale(Vector3(0.28, 0.08, 0.28) * unit), Vector3(0.0, 0.04 * unit, 0.0)))
		_grow_lsystem_branch(base_xf * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.08 * unit, 0.0)), 0.36 * unit, 0.048 * unit, 3, species, stem_xforms, leaf_xforms)
		if with_collider and sb != null:
			var cs := CollisionShape3D.new()
			cs.shape = trunk_shape
			cs.transform = base_xf * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.36 * unit, 0.0))
			sb.add_child(cs)

	var stem_mat: Material = Bauhaus.mat("frame", phase)
	var leaf_mat: Material = Bauhaus.mat("quad", phase) if phase == "monochrome" else Bauhaus.mat("pyramid", phase)
	Bauhaus.add_box_multimesh(parent, "MM_LSystem_Stems", stem_xforms, stem_mat, cast_shadows)
	Bauhaus.add_box_multimesh(parent, "MM_LSystem_Canopy", leaf_xforms, leaf_mat, cast_shadows)
	return {"multimeshes": 2, "instances": stem_xforms.size() + leaf_xforms.size(), "draw_calls": 2}


static func _grow_lsystem_branch(xf: Transform3D, seg_len: float, thick: float, depth: int, species: int, stems: Array[Transform3D], leaves: Array[Transform3D]) -> void:
	# Segment along local +Y from 0 to seg_len
	stems.append(xf * Transform3D(Basis.from_scale(Vector3(thick, seg_len, thick)), Vector3(0.0, seg_len * 0.5, 0.0)))
	var tip_xf := xf * Transform3D(Basis.IDENTITY, Vector3(0.0, seg_len, 0.0))
	if depth <= 1:
		var lf := seg_len * 0.72
		leaves.append(tip_xf * Transform3D(Basis.from_scale(Vector3(lf, lf * 0.42, lf)), Vector3(0.0, lf * 0.15, 0.0)))
		return
	var tilt: float = deg_to_rad(28.0 + float(species) * 5.0)
	var twist: float = deg_to_rad(120.0 if species % 2 == 0 else 90.0)
	var branches: int = 3 if (depth == 3 or species % 2 == 0) else 2
	for b in branches:
		var yaw: float = float(b) * twist + float(depth) * 0.65
		var child_rot := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tilt)
		_grow_lsystem_branch(tip_xf * Transform3D(child_rot, Vector3.ZERO), seg_len * 0.68, thick * 0.72, depth - 1, species, stems, leaves)


# ── Forces (F45+): Sound Jump Pad visual + live acoustic chime trigger ──

static func build_sound_jump_pad(ob: Dictionary, unit: float, phase: String, is_live: bool, offset: Vector3 = Vector3.ZERO) -> Node3D:
	var root := Node3D.new()
	root.name = "Live_sound_jump_pad" if is_live else "MiniObj_sound_jump_pad"
	var at_v := Vector3(float(ob.at[0]), float(ob.at[1]), float(ob.at[2]))
	root.position = at_v * unit + offset
	root.rotation.y = float(ob.get("turn", [0, 0, 0])[1]) * PI * 0.5

	var mono: bool = (phase == "monochrome")
	var m_base: Material = Bauhaus.mat("frame", phase)
	var m_ring: Material = Bauhaus.mat("quad", "monochrome") if mono else Bauhaus.paint_mat("22d3ee")
	var m_core: Material = Bauhaus.mat("slate", phase) if mono else Bauhaus.paint_mat("f472b6")
	var s: float = unit * 0.5

	var base_mi := MeshInstance3D.new()
	var base_bm := BoxMesh.new()
	base_bm.size = Vector3(s * 0.92, s * 0.07, s * 0.92)
	base_mi.mesh = base_bm
	base_mi.position = Vector3(0.0, s * 0.035, 0.0)
	base_mi.material_override = m_base
	base_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(base_mi)

	var ring_mi := MeshInstance3D.new()
	ring_mi.name = "SoundRing"
	var tor := TorusMesh.new()
	tor.inner_radius = s * 0.28
	tor.outer_radius = s * 0.38
	tor.rings = 16
	tor.ring_segments = 8
	ring_mi.mesh = tor
	ring_mi.position = Vector3(0.0, s * 0.09, 0.0)
	ring_mi.material_override = m_ring
	ring_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring_mi)

	var core_mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = s * 0.20
	cyl.bottom_radius = s * 0.22
	cyl.height = s * 0.05
	cyl.radial_segments = 12
	core_mi.mesh = cyl
	core_mi.position = Vector3(0.0, s * 0.095, 0.0)
	core_mi.material_override = m_core
	core_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(core_mi)

	if is_live:
		var pad := Node3D.new()
		pad.name = "SoundPadTrigger"
		pad.set_script(SoundJumpPadScript)
		var note_idx: int = posmod(int(roundf(at_v.x * 2.0)), PENTATONIC_HZ.size())
		pad.set("pitch_hz", PENTATONIC_HZ[note_idx])
		pad.set("_ring_mesh", ring_mi)
		pad.scale = Vector3.ONE * (unit / 2.0)
		root.add_child(pad)
	return root
