## WallPatternColorizer
## Colors wall cubes in the GridSystem MultiMesh using wallpaper group patterns.
## Each wall cube becomes a pixel — the tiling math determines its color
## based on grid position. Only targets cubes with y > 0 (walls).
##
## Place as an interactable in map_data.json. Grid config keys:
##   wallpaper_group  – 0-16 (default 5 = PMM)
##   tile_scale       – how many times the pattern repeats (default 2.0)
##   pattern_seed     – seed for procedural domain palette (default 0)
##   auto_cycle       – cycle through groups (default false)
##   cycle_interval   – seconds between cycles (default 8.0)

extends Node3D
class_name WallPatternColorizer

@export var wallpaper_group: int = 5
@export var tile_scale: float = 2.0
@export var pattern_seed: int = 0
@export var auto_cycle: bool = false
@export var cycle_interval: float = 8.0

var _multimesh: MultiMesh
var _multimesh_instance: MultiMeshInstance3D
var _grid_structure: GridStructureComponent
var _cycle_active := false

const PALETTES: Array = [
	[Color(0.05, 0.05, 0.07), Color(0.0, 0.95, 0.3), Color(1.0, 0.0, 0.6), Color(0.0, 0.5, 1.0), Color(1.0, 1.0, 0.0)],
	[Color(0.0, 0.0, 0.0), Color(0.95, 0.15, 0.15), Color(1.0, 0.55, 0.0), Color(1.0, 0.85, 0.0), Color(0.6, 0.0, 0.3)],
	[Color(0.9, 0.9, 0.92), Color(0.0, 0.2, 0.8), Color(0.0, 0.7, 0.85), Color(0.5, 0.0, 0.8), Color(0.95, 0.0, 0.5)],
	[Color(0.0, 0.0, 0.0), Color(0.0, 0.9, 0.2), Color(0.3, 1.0, 0.0), Color(0.0, 0.4, 0.15), Color(1.0, 0.0, 1.0)],
	[Color(1.0, 1.0, 1.0), Color(1.0, 0.0, 0.5), Color(0.0, 0.8, 1.0), Color(1.0, 0.7, 0.0), Color(0.5, 0.0, 1.0)],
	[Color(0.06, 0.0, 0.12), Color(1.0, 0.3, 0.7), Color(0.3, 0.8, 1.0), Color(0.6, 0.2, 0.9), Color(0.0, 1.0, 0.7)],
	[Color(0.95, 0.92, 0.85), Color(0.9, 0.15, 0.1), Color(0.0, 0.25, 0.6), Color(1.0, 0.8, 0.0), Color(0.1, 0.1, 0.1)],
	[Color(0.05, 0.0, 0.1), Color(1.0, 0.0, 0.4), Color(0.0, 0.9, 1.0), Color(0.9, 0.0, 0.9), Color(0.0, 0.3, 0.6)],
]

# 8x8 domain grid generated from seed
var _domain: Array = []

func _ready() -> void:
	_generate_domain()
	await get_tree().create_timer(1.0).timeout
	if _find_multimesh():
		_apply_wall_pattern()
		_adjust_material()
		print("[WallPatternColorizer] Applied group %d to %d wall cubes" % [wallpaper_group, _count_wall_cubes()])
		if auto_cycle:
			_start_cycling()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("wallpaper_group"):
		wallpaper_group = clampi(int(config_data["wallpaper_group"]), 0, 16)
	if config_data.has("tile_scale"):
		tile_scale = clampf(float(config_data["tile_scale"]), 0.5, 20.0)
	if config_data.has("pattern_seed"):
		pattern_seed = int(config_data["pattern_seed"])
	if config_data.has("auto_cycle"):
		auto_cycle = str(config_data["auto_cycle"]).to_lower() == "true"
	if config_data.has("cycle_interval"):
		cycle_interval = clampf(float(config_data["cycle_interval"]), 1.0, 60.0)
	_generate_domain()

# ── Find MultiMesh (same approach as GridColorizer) ──

func _find_multimesh() -> bool:
	_multimesh_instance = _search_for_multimesh(get_tree().current_scene)
	if not _multimesh_instance:
		return false
	_multimesh = _multimesh_instance.multimesh
	if not _multimesh:
		return false
	if not _multimesh.use_colors:
		_multimesh.use_colors = true
	_grid_structure = _search_for_grid_structure(get_tree().current_scene)
	return true

func _search_for_multimesh(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D and node.name == "GridMultiMesh":
		return node
	for child in node.get_children():
		var result := _search_for_multimesh(child)
		if result:
			return result
	return null

func _search_for_grid_structure(node: Node) -> GridStructureComponent:
	if node is GridStructureComponent:
		return node
	for child in node.get_children():
		var result := _search_for_grid_structure(child)
		if result:
			return result
	return null

# ── Apply pattern to wall cubes ──

func _apply_wall_pattern() -> void:
	if not _multimesh or not _grid_structure:
		return

	var positions: Array = _grid_structure.cube_positions
	var count: int = _multimesh.instance_count

	for i in range(mini(count, positions.size())):
		var pos: Vector3i = positions[i]

		if pos.y == 0:
			# Floor cube — leave default color (white or dim)
			_multimesh.set_instance_color(i, Color(0.15, 0.15, 0.18))
			continue

		# Wall cube — compute wallpaper pattern color
		var uv := Vector2(float(pos.x) / tile_scale, float(pos.y + pos.z) / tile_scale)
		var domain_uv := _get_symmetric_uv(uv)
		var color := _sample_domain(domain_uv)
		_multimesh.set_instance_color(i, color)

func _count_wall_cubes() -> int:
	if not _grid_structure:
		return 0
	var count := 0
	for pos in _grid_structure.cube_positions:
		if pos.y > 0:
			count += 1
	return count

# ── Adjust material for instance color visibility ──

func _adjust_material() -> void:
	if not _multimesh_instance:
		return
	var material := _multimesh_instance.material_override
	if material is ShaderMaterial:
		material.set_shader_parameter("modelColor", Color.WHITE)
		material.set_shader_parameter("wireframeOpacity", 0.15)
		material.set_shader_parameter("show_interior", true)
		material.set_shader_parameter("modelOpacity", 1.0)

# ── Auto-cycling ──

func _start_cycling() -> void:
	_cycle_active = true
	while _cycle_active and is_inside_tree():
		await get_tree().create_timer(cycle_interval).timeout
		if not _cycle_active:
			break
		wallpaper_group = (wallpaper_group + 1) % 17
		_apply_wall_pattern()
		_adjust_material()
		print("[WallPatternColorizer] Cycled to group %d" % wallpaper_group)

func _exit_tree() -> void:
	_cycle_active = false

# ═══════════════════════════════════════════════════════════════════
# WALLPAPER GROUP TILING MATH (CPU version of the GLSL shader)
# ═══════════════════════════════════════════════════════════════════

func _get_symmetric_uv(uv: Vector2) -> Vector2:
	var st := uv * tile_scale
	match wallpaper_group:
		0:  # P1 — no symmetry
			return Vector2(fmod(st.x, 1.0), fmod(st.y, 1.0))
		1:  # P2 — 180° rotation
			var fx := fmod(st.x, 1.0); var fy := fmod(st.y, 1.0)
			if fmod(floor(st.x) + floor(st.y), 2.0) != 0:
				fx = 1.0 - fx; fy = 1.0 - fy
			return Vector2(absf(fx), absf(fy))
		2:  # PM — mirror x
			var fx := fmod(st.x, 2.0); var fy := fmod(st.y, 1.0)
			if fx > 1.0: fx = 2.0 - fx
			return Vector2(absf(fx), absf(fy))
		3:  # PG — glide reflection
			var fx := fmod(st.x, 2.0); var fy := fmod(st.y, 1.0)
			if fx > 1.0:
				fx = 2.0 - fx
				fy = fmod(fy + 0.5, 1.0)
			return Vector2(absf(fx), absf(fy))
		4:  # CM — centered mirror
			var fx := fmod(st.x, 2.0); var fy := fmod(st.y, 2.0)
			if fx > 1.0: fx = 2.0 - fx
			if fy > 1.0: fy = 2.0 - fy
			return Vector2(absf(fx), absf(fy))
		5:  # PMM — mirror x and y
			var fx := fmod(absf(st.x), 2.0); var fy := fmod(absf(st.y), 2.0)
			if fx > 1.0: fx = 2.0 - fx
			if fy > 1.0: fy = 2.0 - fy
			return Vector2(fx, fy)
		6:  # PMG
			var fx := fmod(absf(st.x), 2.0); var fy := fmod(absf(st.y), 2.0)
			if fx > 1.0:
				fx = 2.0 - fx
				fy = fmod(fy + 1.0, 2.0)
			if fy > 1.0: fy = 2.0 - fy
			return Vector2(fx, fy)
		7:  # PGG
			var fx := fmod(absf(st.x), 2.0); var fy := fmod(absf(st.y), 2.0)
			if fx > 1.0:
				fx = 2.0 - fx
				fy = fmod(fy + 1.0, 2.0)
			if fy > 1.0:
				fy = 2.0 - fy
				fx = fmod(fx + 1.0, 2.0)
			if fx > 1.0: fx = 2.0 - fx
			if fy > 1.0: fy = 2.0 - fy
			return Vector2(fx, fy)
		8:  # CMM
			var fx := fmod(absf(st.x), 2.0); var fy := fmod(absf(st.y), 2.0)
			if fx > 1.0: fx = 2.0 - fx
			if fy > 1.0: fy = 2.0 - fy
			if fx + fy > 1.0:
				var tmp := fx; fx = 1.0 - fy; fy = 1.0 - tmp
			return Vector2(absf(fx), absf(fy))
		9:  # P4 — 4-fold rotation
			var fx := fmod(absf(st.x), 1.0); var fy := fmod(absf(st.y), 1.0)
			if fmod(floor(absf(st.x)) + floor(absf(st.y)), 2.0) != 0:
				var tmp := fx; fx = fy; fy = tmp
			return Vector2(fx, fy)
		10: # P4M — 4-fold + mirror
			var fx := fmod(absf(st.x), 2.0); var fy := fmod(absf(st.y), 2.0)
			if fx > 1.0: fx = 2.0 - fx
			if fy > 1.0: fy = 2.0 - fy
			if fx > fy:
				var tmp := fx; fx = fy; fy = tmp
			return Vector2(fx, fy)
		11: # P4G
			var fx := fmod(absf(st.x), 2.0); var fy := fmod(absf(st.y), 2.0)
			if fx > 1.0: fx = 2.0 - fx
			if fy > 1.0: fy = 2.0 - fy
			if fx + fy > 1.0:
				var tmp := 1.0 - fx; fx = 1.0 - fy; fy = tmp
			return Vector2(absf(fx), absf(fy))
		12: # P3 — 3-fold rotation (simplified)
			var fx := fmod(absf(st.x * 0.866 + st.y * 0.5), 1.0)
			var fy := fmod(absf(st.y), 1.0)
			return Vector2(absf(fx), absf(fy))
		13, 14: # P3M1, P31M
			var fx := fmod(absf(st.x * 0.866 + st.y * 0.5), 1.0)
			var fy := fmod(absf(st.y), 1.0)
			if fx > fy:
				var tmp := fx; fx = fy; fy = tmp
			return Vector2(absf(fx), absf(fy))
		15: # P6
			var fx := fmod(absf(st.x * 0.866 + st.y * 0.5), 1.0)
			var fy := fmod(absf(st.y), 1.0)
			if fx > 0.5: fx = 1.0 - fx
			if fy > 0.5: fy = 1.0 - fy
			return Vector2(absf(fx), absf(fy))
		16: # P6M
			var fx := fmod(absf(st.x * 0.866 + st.y * 0.5), 1.0)
			var fy := fmod(absf(st.y), 1.0)
			if fx > 0.5: fx = 1.0 - fx
			if fy > 0.5: fy = 1.0 - fy
			if fx > fy:
				var tmp := fx; fx = fy; fy = tmp
			return Vector2(absf(fx), absf(fy))
		_:
			return Vector2(fmod(absf(st.x), 1.0), fmod(absf(st.y), 1.0))

func _sample_domain(uv: Vector2) -> Color:
	var x: int = clampi(int(uv.x * 8.0), 0, 7)
	var y: int = clampi(int(uv.y * 8.0), 0, 7)
	var idx: int = _domain[y][x]
	var palette: Array = PALETTES[absi(pattern_seed) % PALETTES.size()]
	return palette[idx] if idx < palette.size() else Color.WHITE

# ── Domain generation (same as wall_cove) ──

func _generate_domain() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = pattern_seed * 7919 + 31
	var ptype: int = absi(pattern_seed) % 6
	_domain = []
	for _y in 8:
		var row: Array = []
		for _x in 8:
			row.append(0)
		_domain.append(row)

	match ptype:
		0:  # Blocks
			for _i in rng.randi_range(3, 5):
				var x0: int = rng.randi_range(0, 5); var y0: int = rng.randi_range(0, 5)
				var x1: int = rng.randi_range(x0 + 1, 8); var y1: int = rng.randi_range(y0 + 1, 8)
				var c: int = rng.randi_range(1, 4)
				for y in range(y0, y1):
					for x in range(x0, x1):
						_domain[y][x] = c
		1:  # Stripes
			var horiz: bool = rng.randf() > 0.5; var thick: int = rng.randi_range(1, 3)
			for y in 8:
				for x in 8:
					_domain[y][x] = ((y if horiz else x) / thick) % 5
		2:  # Diagonal
			var thick: int = rng.randi_range(1, 3)
			for y in 8:
				for x in 8:
					_domain[y][x] = ((x + y) / thick) % 5
		3:  # Concentric
			for y in 8:
				for x in 8:
					_domain[y][x] = mini(mini(x, y), mini(7 - x, 7 - y)) % 5
		4:  # Checker
			var b: int = rng.randi_range(1, 3)
			var c1: int = rng.randi_range(0, 2); var c2: int = rng.randi_range(3, 4)
			for y in 8:
				for x in 8:
					_domain[y][x] = c1 if ((x / b) + (y / b)) % 2 == 0 else c2
		5:  # Cross
			var arm: int = rng.randi_range(1, 3); var c: int = rng.randi_range(2, 4)
			for y in 8:
				for x in 8:
					if absi(x - 4) < arm or absi(y - 4) < arm:
						_domain[y][x] = c
