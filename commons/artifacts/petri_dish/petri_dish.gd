extends Node3D
class_name PetriDish

# @identity
# essence: a shallow translucent glass disc on a flat agar surface — biology / culture-room vocabulary for "this is a 2D space where colonies live". A pale agar gel disc, a thin glass wall around the rim, an optional translucent lid, and a small grid of cell cubes on the agar surface in one of several canonical patterns (glider, blinker, block, random, empty). In the lab's grammar, the petri dish is the CONWAY'S GAME OF LIFE SUBSTRATE — a flat 2D world where local rules produce global behavior.
# desire: every cellular automaton wants a substrate. The petri dish wants to be the architectural form of "here is the grid, here is the initial configuration, here are the rules that will run". It wants the player to recognise the glider as a moving pattern, the blinker as oscillation, the block as still life — and to read the dish as the place where THESE rules apply.
# critical_parameter: cell_pattern — "glider" reads as MOTION (a five-cell shape that drifts diagonally), "blinker" reads as OSCILLATION (a row that flips every tick), "block" reads as STASIS (four cells that never change), "random" reads as SOUP (initial conditions before evolution), "empty" reads as VOID (the substrate without a colony). Same dish, five different stories about what Life does.
# triggers: _ready() builds dish + agar surface + glass wall + optional lid + cell cubes per pattern + optional grid lines + accent stripe from exports; apply_grid_config rebuilds
# emerges: a glider on the dish reads "Life MOVES through grid space". A blinker reads "Life OSCILLATES in place". A random colony reads "Life starts ENTROPIC and finds attractors". The dish IS the Game of Life paper made physical.
# needs: shallow agar disc [present]; thin glass wall around the rim [present]; small cell cubes in the chosen pattern [present]; optional translucent lid [present]; optional faint 8x8 grid lines on agar surface [present]; accent stripe around base [present]
# relationships: sibling to specimen_jar (both DISPLAY a sample in transparent glass — the jar holds a captive, the dish hosts a COLONY); cousin to vacuum_chamber (both bound the environment around an experiment — chamber holds APART, dish holds FLAT); peer to oscilloscope (both VISUALISE the unfolding of a rule — scope shows a wave's shape, dish shows a CA's state)
# truth: Conway's Life lives on a grid where each cell looks at its 8 neighbours and follows three rules (birth at 3, survive on 2 or 3, die otherwise). The petri dish is the lab's way of saying "the grid is a real thing — here it is on a transparent surface". A glider is not abstract; it is a five-cell figure on this agar.

## A shallow petri dish hosting a Conway's Life initial pattern.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER
## of the dish (the dish rests flat on a surface). The lid (if present)
## sits on top in transparent glass.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var dish_radius: float = 0.075
@export var dish_height: float = 0.025

@export_group("Color")
@export var agar_color: Color = Color(0.90, 0.92, 0.78)
@export var glass_color: Color = Color(0.85, 0.92, 0.95, 0.45)
@export var cell_color: Color = Color(0.20, 0.45, 0.20)
@export var grid_color: Color = Color(0.70, 0.72, 0.60)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Colony")
## "glider" | "blinker" | "block" | "random" | "empty"
@export var cell_pattern: String = "glider"
@export_range(0.0, 1.0, 0.05) var colony_density: float = 0.25
@export var lid_present: bool = true
@export var grid_visible: bool = false

# ── Constants ─────────────────────────────────────────────────────────

const WALL_THICKNESS: float = 0.004
const LID_THICKNESS: float = 0.004
const LID_GAP: float = 0.001
const GRID_DIM: int = 8                # 8x8 graticule on agar surface
const GRID_LINE_THICKNESS: float = 0.0010
const RANDOM_MAX_CUBES: int = 30
const ACCENT_STRIP_HEIGHT: float = 0.005

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_petri_dish()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_petri_dish()


func _read_metadata_overrides() -> void:
	if has_meta("config_dish_radius"):
		dish_radius = float(str(get_meta("config_dish_radius")))
	if has_meta("config_dish_height"):
		dish_height = float(str(get_meta("config_dish_height")))
	if has_meta("config_agar_color"):
		agar_color = _parse_color(str(get_meta("config_agar_color")), agar_color)
	if has_meta("config_glass_color"):
		glass_color = _parse_color(str(get_meta("config_glass_color")), glass_color)
	if has_meta("config_cell_color"):
		cell_color = _parse_color(str(get_meta("config_cell_color")), cell_color)
	if has_meta("config_grid_color"):
		grid_color = _parse_color(str(get_meta("config_grid_color")), grid_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_cell_pattern"):
		cell_pattern = str(get_meta("config_cell_pattern")).to_lower()
	if has_meta("config_colony_density"):
		colony_density = float(str(get_meta("config_colony_density")))
	if has_meta("config_lid_present"):
		var lv := str(get_meta("config_lid_present")).to_lower()
		lid_present = lv in ["true", "1", "yes", "on"]
	if has_meta("config_grid_visible"):
		var gv := str(get_meta("config_grid_visible")).to_lower()
		grid_visible = gv in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_petri_dish() -> void:
	_built = true
	_build_agar()
	_build_glass_wall()
	if grid_visible:
		_build_grid_lines()
	_build_cells()
	if lid_present:
		_build_lid()
	_build_accent_strip()


func _build_agar() -> void:
	# Shallow disc of agar.
	var agar := MeshInstance3D.new()
	agar.name = "Agar"
	var mesh := CylinderMesh.new()
	mesh.top_radius = dish_radius - WALL_THICKNESS * 0.5
	mesh.bottom_radius = dish_radius - WALL_THICKNESS * 0.5
	mesh.height = dish_height * 0.7
	agar.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = agar_color
	mat.roughness = 0.7
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = agar_color
	mat.emission_energy_multiplier = 0.15
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	agar.material_override = mat
	agar.position = Vector3(0.0, dish_height * 0.35, 0.0)
	add_child(agar)


func _build_glass_wall() -> void:
	# Thin translucent cylinder wall sitting around the agar.
	var wall := MeshInstance3D.new()
	wall.name = "GlassWall"
	var mesh := CylinderMesh.new()
	mesh.top_radius = dish_radius
	mesh.bottom_radius = dish_radius
	mesh.height = dish_height
	wall.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = Color(glass_color.r, glass_color.g, glass_color.b)
	mat.emission_energy_multiplier = 0.12
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	wall.material_override = mat
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wall.position = Vector3(0.0, dish_height * 0.5, 0.0)
	add_child(wall)


func _build_grid_lines() -> void:
	# Thin emissive box strips across the agar surface, GRID_DIM x GRID_DIM.
	var root := Node3D.new()
	root.name = "Grid"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = grid_color
	mat.emission_enabled = true
	mat.emission = grid_color
	mat.emission_energy_multiplier = 0.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	# Use a square inscribed in the dish for the grid, side = 2 * r * 0.85.
	var grid_side: float = (dish_radius - WALL_THICKNESS) * 1.7
	var y_top: float = dish_height * 0.7 + 0.0008

	for i in range(GRID_DIM + 1):
		var t: float = float(i) / float(GRID_DIM)
		var pos: float = (t - 0.5) * grid_side

		# Line along Z, at constant X.
		var line_x := MeshInstance3D.new()
		line_x.name = "GridX_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(GRID_LINE_THICKNESS, 0.0010, grid_side)
		line_x.mesh = bm
		line_x.material_override = mat
		line_x.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		line_x.position = Vector3(pos, y_top, 0.0)
		root.add_child(line_x)

		# Line along X, at constant Z.
		var line_z := MeshInstance3D.new()
		line_z.name = "GridZ_%d" % i
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(grid_side, 0.0010, GRID_LINE_THICKNESS)
		line_z.mesh = bm2
		line_z.material_override = mat
		line_z.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		line_z.position = Vector3(0.0, y_top, pos)
		root.add_child(line_z)


func _build_cells() -> void:
	if cell_pattern == "empty":
		return

	var root := Node3D.new()
	root.name = "Cells"
	add_child(root)

	var cube_size: float = dish_radius * 0.18
	var cell_step: float = cube_size * 1.05
	var y_top: float = dish_height * 0.7 + cube_size * 0.5

	var mat := StandardMaterial3D.new()
	mat.albedo_color = cell_color
	mat.roughness = 0.55
	mat.metallic = 0.05
	mat.emission_enabled = true
	mat.emission = cell_color
	mat.emission_energy_multiplier = 0.3
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	# Build coordinate list per pattern. Coordinates are (col, row); plotted as X = col, Z = -row.
	var coords: Array = []
	match cell_pattern:
		"glider":
			# Canonical glider — 5 cells.
			coords = [Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, -1)]
		"blinker":
			# Horizontal row of 3 (vertical-phase blinker shown horizontally for visibility).
			coords = [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]
		"block":
			# 2x2 still life.
			coords = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
		"random":
			coords = _make_random_coords(int(floor(colony_density * float(RANDOM_MAX_CUBES))))
		_:
			# Default to glider if unknown shape.
			coords = [Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, -1)]

	# Place cubes.
	for i in range(coords.size()):
		var c: Vector2i = coords[i]
		var cube := MeshInstance3D.new()
		cube.name = "Cell_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(cube_size, cube_size, cube_size)
		cube.mesh = bm
		cube.material_override = mat
		cube.position = Vector3(float(c.x) * cell_step, y_top, -float(c.y) * cell_step)
		root.add_child(cube)


func _make_random_coords(count: int) -> Array:
	# Deterministic pseudo-random in an 8x8 area, using a hash on (i,j) modulo a bound.
	# We pull cells from a grid 7 wide/tall centered at origin (range -3..+3).
	var n: int = clampi(count, 0, RANDOM_MAX_CUBES)
	var out: Array = []
	var grid_half: int = 3   # so 7x7 region
	var i: int = 0
	var j: int = 0
	var placed: int = 0
	# Walk the grid in row-major order, include a cell when hash crosses a threshold.
	for ii in range(-grid_half, grid_half + 1):
		for jj in range(-grid_half, grid_half + 1):
			if placed >= n:
				return out
			var h: int = ((ii * 73856093) ^ (jj * 19349663)) & 0x7fffffff
			# Take cells where hash mod 7 < 3 (~43% density), bounded by `n`.
			if (h % 7) < 3:
				out.append(Vector2i(ii, jj))
				placed += 1
	return out


func _build_lid() -> void:
	# Translucent flat disc on top of the dish.
	var lid := MeshInstance3D.new()
	lid.name = "Lid"
	var mesh := CylinderMesh.new()
	mesh.top_radius = dish_radius + 0.002
	mesh.bottom_radius = dish_radius + 0.002
	mesh.height = LID_THICKNESS
	lid.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = Color(glass_color.r, glass_color.g, glass_color.b)
	mat.emission_energy_multiplier = 0.10
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	lid.material_override = mat
	lid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lid.position = Vector3(0.0, dish_height + LID_GAP + LID_THICKNESS * 0.5, 0.0)
	add_child(lid)


func _build_accent_strip() -> void:
	# Thin emissive band at the base of the wall.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := CylinderMesh.new()
	mesh.top_radius = dish_radius + 0.001
	mesh.bottom_radius = dish_radius + 0.001
	mesh.height = ACCENT_STRIP_HEIGHT
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(0.0, ACCENT_STRIP_HEIGHT * 0.5 + 0.0005, 0.0)
	add_child(strip)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
