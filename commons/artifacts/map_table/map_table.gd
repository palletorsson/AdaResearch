extends Node3D
class_name MapTable

# @identity
# essence: a heavy wooden table with a parchment map laid flat on top — gridded,
#   dotted with obstacles, with an emissive Portal-blue path crossing diagonally
#   from a red start marker to a red end marker. In the lab's grammar, the
#   map_table IS PATHFINDING (Dijkstra / A*) in object form. Grid = graph. Cells
#   = nodes. Obstacles = closed nodes. Path = the cost-minimising traversal that
#   the algorithm picks.
# desire: every lab that teaches search needs an artifact that refuses to be
#   a 2D diagram. The table makes the algorithm physical — you stand at it,
#   you LOOK DOWN at it, you see the obstacles and the route around them at
#   the same time. A planner's eye-view, real-size
# critical_parameter: grid_size + obstacle_count — together they ARE the algorithm's
#   key knob. grid_size is the graph resolution; obstacle_count is the constraint
#   density. The algorithm doesn't change. The instance does. The path responds
# triggers: _ready() builds table base + legs + parchment + grid lines + obstacles
#   + emissive path + start/end markers + accent stripe; apply_grid_config rebuilds
# emerges: a sparse grid reads NAVIGATION PUZZLE. A dense grid reads MAZE. An
#   uncluttered map with one big detour reads OBSTACLE COURSE. Same script, the
#   algorithm's character changes with the obstacle field
# needs: tabletop + 4 legs [present]; parchment surface [present]; optional grid
#   lines [present]; obstacles [present]; emissive path dots [present]; start +
#   end markers [present]; accent stripe along table edge [present]
# relationships: peer to probability_box (both lay an algorithm flat on a wooden
#   surface — box samples, table searches); sibling to data_tablet (both are
#   reading-tools — tablet is digital, table is physical); cousin to large_table
#   (large_table is generic furniture; map_table is large_table that has BECOME
#   an instrument); the lab's confession that ALL planning needs a board
# truth: pathfinding is the claim that there is a CHEAPEST route through a
#   weighted graph and that you can FIND it without trying every possible route.
#   The table IS that rule embodied — the obstacles ARE the closed set, the
#   emissive path IS the open set's traversal, the start and end markers ARE
#   the source and sink. To stand at the table is to occupy the algorithm.

## A wooden tactical table with a parchment grid map, obstacles, and an
## emissive path from start corner to end corner.
##
## Built procedurally from DNA exports. Origin is at the bottom center of
## the table base, faces +Z. The path is plausibility-driven, not actually
## A*-computed; the table NAMES the algorithm rather than running it.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var table_width: float = 1.40
@export var table_depth: float = 0.90
@export var table_height: float = 0.85

@export_group("Color")
@export var table_color: Color = Color(0.35, 0.25, 0.18)
@export var map_color: Color = Color(0.85, 0.82, 0.72)
@export var grid_color: Color = Color(0.45, 0.35, 0.25)
@export var obstacle_color: Color = Color(0.15, 0.15, 0.18)
@export var path_color: Color = Color(0.20, 0.55, 0.95)
@export var marker_color: Color = Color(0.95, 0.20, 0.20)
@export var accent_color: Color = Color(0.95, 0.55, 0.0)

@export_group("Grid")
@export var grid_visible: bool = true
@export_range(4, 40) var grid_size: int = 12

@export_group("Obstacles")
@export_range(0, 15) var obstacle_count: int = 5

@export_group("Path")
@export var path_visible: bool = true
@export var path_glow: float = 1.2
@export var start_marker_visible: bool = true
@export var end_marker_visible: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const TABLETOP_THICKNESS: float = 0.04
const LEG_THICKNESS: float = 0.05
const MAP_THICKNESS: float = 0.008
const GRID_LINE_THICKNESS: float = 0.003
const GRID_LINE_HEIGHT: float = 0.0015
const OBSTACLE_HEIGHT_FACTOR: float = 0.6  # vs cell size
const PATH_DOT_COUNT: int = 11
const PATH_DOT_SIZE_FACTOR: float = 0.55   # vs cell size
const MARKER_RADIUS_FACTOR: float = 0.45
const ACCENT_STRIP_HEIGHT: float = 0.008
const ACCENT_STRIP_DEPTH: float = 0.004

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_map_table()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_map_table()


func _read_metadata_overrides() -> void:
	if has_meta("config_table_width"):
		table_width = float(str(get_meta("config_table_width")))
	if has_meta("config_table_depth"):
		table_depth = float(str(get_meta("config_table_depth")))
	if has_meta("config_table_height"):
		table_height = float(str(get_meta("config_table_height")))
	if has_meta("config_table_color"):
		table_color = _parse_color(str(get_meta("config_table_color")), table_color)
	if has_meta("config_map_color"):
		map_color = _parse_color(str(get_meta("config_map_color")), map_color)
	if has_meta("config_grid_visible"):
		grid_visible = _parse_bool(str(get_meta("config_grid_visible")), grid_visible)
	if has_meta("config_grid_size"):
		grid_size = int(str(get_meta("config_grid_size")))
	if has_meta("config_grid_color"):
		grid_color = _parse_color(str(get_meta("config_grid_color")), grid_color)
	if has_meta("config_obstacle_count"):
		obstacle_count = int(str(get_meta("config_obstacle_count")))
	if has_meta("config_obstacle_color"):
		obstacle_color = _parse_color(str(get_meta("config_obstacle_color")), obstacle_color)
	if has_meta("config_path_visible"):
		path_visible = _parse_bool(str(get_meta("config_path_visible")), path_visible)
	if has_meta("config_path_color"):
		path_color = _parse_color(str(get_meta("config_path_color")), path_color)
	if has_meta("config_path_glow"):
		path_glow = float(str(get_meta("config_path_glow")))
	if has_meta("config_marker_color"):
		marker_color = _parse_color(str(get_meta("config_marker_color")), marker_color)
	if has_meta("config_start_marker_visible"):
		start_marker_visible = _parse_bool(str(get_meta("config_start_marker_visible")), start_marker_visible)
	if has_meta("config_end_marker_visible"):
		end_marker_visible = _parse_bool(str(get_meta("config_end_marker_visible")), end_marker_visible)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_map_table() -> void:
	_built = true
	_build_legs()
	_build_tabletop()
	_build_map_surface()
	if grid_visible:
		_build_grid_lines()
	if obstacle_count > 0:
		_build_obstacles()
	if path_visible:
		_build_path_dots()
	_build_markers()
	_build_accent_stripe()


func _build_legs() -> void:
	var root := Node3D.new()
	root.name = "Legs"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = table_color.darkened(0.15)
	mat.roughness = 0.7
	mat.metallic = 0.05

	var leg_h: float = table_height - TABLETOP_THICKNESS
	var leg_y: float = leg_h * 0.5
	var x_off: float = table_width * 0.5 - LEG_THICKNESS * 0.8
	var z_off: float = table_depth * 0.5 - LEG_THICKNESS * 0.8

	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var leg := MeshInstance3D.new()
			leg.name = "Leg_%d_%d" % [sx, sz]
			var mesh := BoxMesh.new()
			mesh.size = Vector3(LEG_THICKNESS, leg_h, LEG_THICKNESS)
			leg.mesh = mesh
			leg.material_override = mat
			leg.position = Vector3(float(sx) * x_off, leg_y, float(sz) * z_off)
			root.add_child(leg)


func _build_tabletop() -> void:
	var top := MeshInstance3D.new()
	top.name = "Tabletop"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(table_width, TABLETOP_THICKNESS, table_depth)
	top.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = table_color
	mat.roughness = 0.65
	mat.metallic = 0.05
	top.material_override = mat
	top.position = Vector3(0.0, table_height - TABLETOP_THICKNESS * 0.5, 0.0)
	add_child(top)


func _build_map_surface() -> void:
	var m := MeshInstance3D.new()
	m.name = "Map"
	var mesh := BoxMesh.new()
	# Parchment slightly inset from the tabletop edge.
	var pad: float = 0.04
	var w: float = max(0.1, table_width - pad * 2.0)
	var d: float = max(0.1, table_depth - pad * 2.0)
	mesh.size = Vector3(w, MAP_THICKNESS, d)
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = map_color
	mat.roughness = 0.85
	mat.metallic = 0.0
	m.material_override = mat
	m.position = Vector3(0.0, table_height + MAP_THICKNESS * 0.5, 0.0)
	add_child(m)


func _build_grid_lines() -> void:
	var root := Node3D.new()
	root.name = "Grid"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = grid_color
	mat.roughness = 0.8
	mat.metallic = 0.0

	var pad: float = 0.04
	var w: float = max(0.1, table_width - pad * 2.0)
	var d: float = max(0.1, table_depth - pad * 2.0)
	var n_x: int = clampi(grid_size, 2, 40)
	# Match cell aspect to map aspect.
	var cell_size: float = w / float(n_x)
	var n_z: int = max(2, int(round(d / cell_size)))
	var y: float = table_height + MAP_THICKNESS + GRID_LINE_HEIGHT * 0.5

	# Lines parallel to X (vary in Z), inclusive of borders.
	for i in range(n_z + 1):
		var line := MeshInstance3D.new()
		line.name = "GridX_%d" % i
		var lm := BoxMesh.new()
		lm.size = Vector3(w, GRID_LINE_HEIGHT, GRID_LINE_THICKNESS)
		line.mesh = lm
		line.material_override = mat
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var z: float = -d * 0.5 + float(i) * (d / float(n_z))
		line.position = Vector3(0.0, y, z)
		root.add_child(line)

	# Lines parallel to Z (vary in X).
	for j in range(n_x + 1):
		var line2 := MeshInstance3D.new()
		line2.name = "GridZ_%d" % j
		var lm2 := BoxMesh.new()
		lm2.size = Vector3(GRID_LINE_THICKNESS, GRID_LINE_HEIGHT, d)
		line2.mesh = lm2
		line2.material_override = mat
		line2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var x: float = -w * 0.5 + float(j) * (w / float(n_x))
		line2.position = Vector3(x, y, 0.0)
		root.add_child(line2)


func _build_obstacles() -> void:
	var root := Node3D.new()
	root.name = "Obstacles"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = obstacle_color
	mat.roughness = 0.6
	mat.metallic = 0.2

	var pad: float = 0.04
	var w: float = max(0.1, table_width - pad * 2.0)
	var d: float = max(0.1, table_depth - pad * 2.0)
	var cell_size: float = w / float(max(2, grid_size))
	var obs_h: float = cell_size * OBSTACLE_HEIGHT_FACTOR
	var y: float = table_height + MAP_THICKNESS + obs_h * 0.5

	var n: int = clampi(obstacle_count, 0, 15)
	for i in range(n):
		var ob := MeshInstance3D.new()
		ob.name = "Obstacle_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(cell_size * 0.85, obs_h, cell_size * 0.85)
		ob.mesh = bm
		ob.material_override = mat
		# Deterministic position avoiding the two diagonal corners.
		var hx: float = float(((i * 73856093 + 19349663) % 1000)) / 1000.0
		var hz: float = float(((i * 83492791 + 11939) % 1000)) / 1000.0
		# Keep obstacles in the central band (avoid the start/end corners).
		var x_pos: float = (hx - 0.5) * w * 0.7
		var z_pos: float = (hz - 0.5) * d * 0.7
		ob.position = Vector3(x_pos, y, z_pos)
		root.add_child(ob)


func _build_path_dots() -> void:
	var root := Node3D.new()
	root.name = "Path"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = path_color
	mat.emission_enabled = true
	mat.emission = path_color
	mat.emission_energy_multiplier = max(0.0, path_glow) * 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var pad: float = 0.04
	var w: float = max(0.1, table_width - pad * 2.0)
	var d: float = max(0.1, table_depth - pad * 2.0)
	var cell_size: float = w / float(max(2, grid_size))
	var dot_size: float = cell_size * PATH_DOT_SIZE_FACTOR
	var y: float = table_height + MAP_THICKNESS + dot_size * 0.5 + 0.002

	# Start corner at -X, -Z. End corner at +X, +Z.
	var start_pos := Vector3(-w * 0.45, y, -d * 0.45)
	var end_pos := Vector3(w * 0.45, y, d * 0.45)
	for i in range(PATH_DOT_COUNT):
		var t: float = float(i) / float(PATH_DOT_COUNT - 1)
		# Bezier-ish arc — a gentle bulge toward +X-Z that "navigates" obstacles.
		var lin: Vector3 = start_pos.lerp(end_pos, t)
		# Lateral deflection peaking at t=0.5.
		var bulge: float = sin(t * PI) * d * 0.25
		var dot_pos := Vector3(lin.x + bulge * 0.4, lin.y, lin.z - bulge * 0.4)
		var dot := MeshInstance3D.new()
		dot.name = "PathDot_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(dot_size, dot_size * 0.6, dot_size)
		dot.mesh = bm
		dot.material_override = mat
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dot.position = dot_pos
		root.add_child(dot)


func _build_markers() -> void:
	var pad: float = 0.04
	var w: float = max(0.1, table_width - pad * 2.0)
	var d: float = max(0.1, table_depth - pad * 2.0)
	var cell_size: float = w / float(max(2, grid_size))
	var r: float = cell_size * MARKER_RADIUS_FACTOR
	var y: float = table_height + MAP_THICKNESS + r * 0.5 + 0.002

	var mat := StandardMaterial3D.new()
	mat.albedo_color = marker_color
	mat.emission_enabled = true
	mat.emission = marker_color
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	if start_marker_visible:
		var s := MeshInstance3D.new()
		s.name = "StartMarker"
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		s.mesh = sm
		s.material_override = mat
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		s.position = Vector3(-w * 0.45, y, -d * 0.45)
		add_child(s)

	if end_marker_visible:
		var e := MeshInstance3D.new()
		e.name = "EndMarker"
		var em := SphereMesh.new()
		em.radius = r
		em.height = r * 2.0
		e.mesh = em
		e.material_override = mat
		e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		e.position = Vector3(w * 0.45, y, d * 0.45)
		add_child(e)


func _build_accent_stripe() -> void:
	# Emissive stripe along the front edge of the tabletop.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStripe"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(table_width * 0.92, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(
		0.0,
		table_height - TABLETOP_THICKNESS * 0.5,
		table_depth * 0.5 + ACCENT_STRIP_DEPTH * 0.5
	)
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


func _parse_bool(s: String, fallback: bool) -> bool:
	var v := s.to_lower()
	if v in ["true", "1", "yes", "on"]:
		return true
	if v in ["false", "0", "no", "off"]:
		return false
	return fallback
