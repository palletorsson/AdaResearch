extends Node3D
class_name LabRoom

# @identity
# essence: a procedurally-generated white modern test chamber that frames a workbench. The room IS the staging — white tile floor, walls, accent-colored strip naming the QFEP phase, signage, observation glass, and a central plinth where the instrument sits. Half-Life test chamber as architectural vocabulary
# desire: every workbench gets a stage that signals "this is the instrument; the room exists to display it"
# critical_parameter: accent_color — drives the strip, lights, signage tint, and sub-line color. Matches the QFEP phase of the workbench inside.
# triggers: _ready() builds floor, walls, ceiling, accent strip, plinth, signage, and annotations from exports
# emerges: a generic room becomes a specific chamber by changing DNA. Same script, different DNA = different room.
# needs: signage placeholder text [present]; QFEP phase color palette [present in PHASE_COLORS]; mount_point for workbench attachment [present]
# relationships: parent-shape for all workbench artifacts; consumes the same QFEP color palette as the timeline ribbon; sibling to grid maps (the lab IS the stage where the grid's lessons get measured)
# truth: the room is not the experiment. The room is the SIGNAL that an experiment is about to happen.

## A Half-Life-style modern test chamber, procedurally built from a DNA dict.
##
## The room WRAPS a workbench instance — never modifies it. Set
## `mounted_artifact_scene` to a .tscn path and lab_room will instantiate
## it as a child of `mount_point` (centered on the plinth top).
##
## Origin is at the CENTER of the floor. The room extends symmetrically
## in ±X and ±Z, with the signage wall at -Z (front, faced by the player
## who spawns at +Z and looks toward -Z). Glass observation panel is at
## +Z (the player's side).
##
## Accent color drives the strip, signage tint, and the colored omni
## light. Use QFEP timeline phase colors:
##   F_order      Color(0.227, 0.482, 1.0)    # #3A7BFF — blue
##   oscillation  Color(0.490, 1.0,   0.659)  # #7DFFA8 — pale green
##   E_entropy    Color(0.957, 0.635, 0.380)  # #F4A261 — sandy orange
##   lambda_edge  Color(0.902, 0.224, 0.275)  # #E63946 — Shannon red
##   integration  Color(0.608, 0.365, 0.835)  # #9B5DE5 — purple
##   relation     Color(0.984, 0.890, 0.541)  # #FBE38A — pale yellow
##   synthesis    Color(1.0,   1.0,   1.0)    # #FFFFFF — white

# ── DNA: dimensions ───────────────────────────────────────────────────

@export_group("Dimensions")
@export var room_width: float = 6.0
@export var room_depth: float = 6.0
@export var room_height: float = 3.5

@export_group("Accent")
@export var accent_color: Color = Color(0.902, 0.224, 0.275)  # lambda_edge red
@export var floor_color: Color = Color(0.94, 0.94, 0.95)      # near-white
@export var wall_color: Color = Color(0.96, 0.96, 0.97)
@export var ceiling_color: Color = Color(0.88, 0.88, 0.90)

@export_group("Mount")
## A central plinth where a workbench sits.
@export var show_plinth: bool = true
@export var plinth_size: Vector3 = Vector3(1.4, 0.15, 1.4)
@export var plinth_color: Color = Color(0.20, 0.20, 0.22)

@export_group("Mounted artifact")
## Path to a workbench .tscn (or any Node3D scene) to instantiate at the
## mount_point. Empty = no auto-instantiate (use mount_point manually).
@export var mounted_artifact_scene: String = ""
## Optional: path to a lab.json produced by the encyclopedia's
## /lab-editor. When set, LabLoader reads the JSON and instantiates
## each prop at its authored position inside this room. Coexists with
## mounted_artifact_scene — both can be active if needed.
@export var mounted_lab_json: String = ""

@export_group("Signage")
@export var signage_top: String = "TEST CHAMBER λ-S"
@export var signage_sub: String = "Shannon Bound Probe"

@export_group("Lighting")
## 0.0 = warm yellow tint, 1.0 = cool blue tint on the directional light.
@export_range(0.0, 1.0) var light_warmth: float = 0.5
@export var light_energy: float = 0.8
@export var accent_strip_energy: float = 1.4

@export_group("Annotations")
@export var show_wall_annotations: bool = true
@export var annotation_top: String = "the lambda_edge is the math of the in-between"
@export var annotation_bottom: String = "Shannon names the floor — H(p) bits/symbol"

@export_group("Tile grid")
## Draw thin dark grout lines on the floor to subdivide it into tiles.
@export var show_floor_tiles: bool = true
## Side count of the floor tile grid (e.g. 6 → 6×6 tiles).
@export var floor_tile_count: int = 6
@export var grout_color: Color = Color(0.05, 0.05, 0.06)

@export_group("Observation glass")
## Replace the player-side wall (+Z) with a translucent glass panel.
@export var south_wall_is_glass: bool = true
@export var glass_color: Color = Color(0.85, 0.92, 0.98, 0.20)

@export_group("Wall pattern")
## "smooth" = flat panels (current); "panels" = grid of panel seams (Portal 2);
## "concrete" = raw concrete texture (warmer gray, higher roughness).
@export var wall_pattern: String = "smooth"
## Number of vertical panel divisions per wall (only used if wall_pattern == "panels"). 4–12 typical.
@export var panel_columns: int = 6
## Thin dark line marking panel seams (only used if wall_pattern == "panels").
@export var seam_color: Color = Color(0.18, 0.18, 0.22)

@export_group("Observation window")
@export var show_observation_window: bool = false
## Position: which wall hosts the window. "north" = back wall (signage wall), "east"/"west" = side walls.
@export var window_wall: String = "east"
@export var window_size: Vector2 = Vector2(3.0, 1.6)

@export_group("Forward / back windows")
## Large window on the +Z back wall (looks "forward" into the biome
## past the lab). When true, the back wall is rendered solid with the
## window cut into it — overrides south_wall_is_glass.
@export var show_back_window: bool = false
@export var back_window_size: Vector2 = Vector2(5.0, 2.2)
## Smaller window on the -Z front wall (looks "back" the way the
## player came from). Coexists with signage — placed above the door
## or beside the signage band.
@export var show_front_window: bool = false
@export var front_window_size: Vector2 = Vector2(1.6, 0.8)
## Horizontal offset of the small front window from the wall centre,
## so it doesn't collide with the centred signage / sliding door.
@export var front_window_offset_x: float = 0.0
@export var front_window_y: float = 2.45

@export_group("Sliding door")
## Working sliding door with proximity sensor on the upper frame.
## Two panels slide outward when a body enters the sensor radius.
@export var show_sliding_door: bool = false
## Which wall hosts the door. "north"=-Z front, "south"=+Z back,
## "east"=+X, "west"=-X.
@export var door_wall: String = "east"
@export var door_width: float = 1.4
@export var door_height: float = 2.2
@export var door_sensor_radius: float = 2.6
@export var door_open_offset: float = 0.7

@export_group("Ceiling")
## "tile_grid" = the default; "exposed" = visible cable trays + light fixtures;
## "skylight" = bright panels with frosted glass look.
@export var ceiling_style: String = "tile_grid"

# ── Constants ─────────────────────────────────────────────────────────

const WALL_THICKNESS: float = 0.05
const FLOOR_THICKNESS: float = 0.05
const CEILING_THICKNESS: float = 0.05

# ── Internal state ────────────────────────────────────────────────────

var mount_point: Node3D
var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	# Grid system injects config via metadata BEFORE add_child(), and calls
	# apply_grid_config() deferred AFTER _ready(). Read metadata first so
	# the room comes up correctly on the first build.
	_read_metadata_overrides()
	_build_room()


func _read_metadata_overrides() -> void:
	# Strings — direct mapping.
	if has_meta("config_signage_top"):
		signage_top = String(get_meta("config_signage_top"))
	if has_meta("config_signage_sub"):
		signage_sub = String(get_meta("config_signage_sub"))
	if has_meta("config_annotation_top"):
		annotation_top = String(get_meta("config_annotation_top"))
	if has_meta("config_annotation_bottom"):
		annotation_bottom = String(get_meta("config_annotation_bottom"))
	if has_meta("config_mounted_artifact_scene"):
		mounted_artifact_scene = String(get_meta("config_mounted_artifact_scene"))
	if has_meta("config_mounted_lab_json"):
		mounted_lab_json = String(get_meta("config_mounted_lab_json"))

	# Colors as "r,g,b" strings.
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_floor_color"):
		floor_color = _parse_color(String(get_meta("config_floor_color")), floor_color)
	if has_meta("config_wall_color"):
		wall_color = _parse_color(String(get_meta("config_wall_color")), wall_color)

	# Floats / ints.
	if has_meta("config_room_width"):
		room_width = float(String(get_meta("config_room_width")))
	if has_meta("config_room_depth"):
		room_depth = float(String(get_meta("config_room_depth")))
	if has_meta("config_room_height"):
		room_height = float(String(get_meta("config_room_height")))
	if has_meta("config_light_warmth"):
		light_warmth = clampf(float(String(get_meta("config_light_warmth"))), 0.0, 1.0)

	# New: wall pattern / observation window / ceiling style.
	if has_meta("config_wall_pattern"):
		wall_pattern = String(get_meta("config_wall_pattern"))
	if has_meta("config_panel_columns"):
		panel_columns = int(String(get_meta("config_panel_columns")))
	if has_meta("config_seam_color"):
		seam_color = _parse_color(String(get_meta("config_seam_color")), seam_color)
	if has_meta("config_show_observation_window"):
		show_observation_window = bool(get_meta("config_show_observation_window"))
	if has_meta("config_window_wall"):
		window_wall = String(get_meta("config_window_wall"))
	if has_meta("config_ceiling_style"):
		ceiling_style = String(get_meta("config_ceiling_style"))

	# New: forward/back windows + sliding door.
	if has_meta("config_show_back_window"):
		show_back_window = _parse_bool(String(get_meta("config_show_back_window")), show_back_window)
	if has_meta("config_back_window_size"):
		back_window_size = _parse_vec2(String(get_meta("config_back_window_size")), back_window_size)
	if has_meta("config_show_front_window"):
		show_front_window = _parse_bool(String(get_meta("config_show_front_window")), show_front_window)
	if has_meta("config_front_window_size"):
		front_window_size = _parse_vec2(String(get_meta("config_front_window_size")), front_window_size)
	if has_meta("config_front_window_offset_x"):
		front_window_offset_x = float(String(get_meta("config_front_window_offset_x")))
	if has_meta("config_front_window_y"):
		front_window_y = float(String(get_meta("config_front_window_y")))
	if has_meta("config_show_sliding_door"):
		show_sliding_door = _parse_bool(String(get_meta("config_show_sliding_door")), show_sliding_door)
	if has_meta("config_door_wall"):
		door_wall = String(get_meta("config_door_wall"))
	if has_meta("config_door_width"):
		door_width = float(String(get_meta("config_door_width")))
	if has_meta("config_door_height"):
		door_height = float(String(get_meta("config_door_height")))
	if has_meta("config_door_sensor_radius"):
		door_sensor_radius = float(String(get_meta("config_door_sensor_radius")))
	if has_meta("config_door_open_offset"):
		door_open_offset = float(String(get_meta("config_door_open_offset")))
	# Legacy passthrough: explicit "false" disables the default full-glass back wall.
	if has_meta("config_south_wall_is_glass"):
		south_wall_is_glass = _parse_bool(String(get_meta("config_south_wall_is_glass")), south_wall_is_glass)


func apply_grid_config(config_data: Dictionary) -> void:
	# Re-read everything in case metadata wasn't populated before _ready().
	# If the room is already built, rebuild it from scratch so the
	# changes are visible immediately.
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_room()


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_room() -> void:
	_built = true
	_build_floor()
	_build_walls()
	_build_ceiling()
	_build_accent_strip()
	_build_plinth_and_mount()
	_build_signage()
	if show_wall_annotations:
		_build_wall_annotations()
	_build_lighting()
	if mounted_artifact_scene != "":
		_instantiate_mounted_artifact()
	if mounted_lab_json != "":
		_instantiate_mounted_lab_json()


# ── Floor ─────────────────────────────────────────────────────────────

func _build_floor() -> void:
	var floor_node := MeshInstance3D.new()
	floor_node.name = "Floor"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(room_width, FLOOR_THICKNESS, room_depth)
	floor_node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = floor_color
	mat.roughness = 0.6
	mat.metallic = 0.05
	floor_node.material_override = mat
	# Place floor centered at origin, top surface at y=0.
	floor_node.position = Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0)
	add_child(floor_node)

	if show_floor_tiles:
		_build_floor_tile_lines()


func _build_floor_tile_lines() -> void:
	# Thin grout-colored boxes overlaid on the floor — cheap tile grid
	# without baking a texture. floor_tile_count divisions per side.
	if floor_tile_count <= 1:
		return
	var grout := Node3D.new()
	grout.name = "FloorGrout"
	add_child(grout)

	var cell_x := room_width / float(floor_tile_count)
	var cell_z := room_depth / float(floor_tile_count)
	var line_thickness := 0.02
	var line_height := 0.002
	var floor_top_y := 0.001  # very slightly above floor top

	var mat := StandardMaterial3D.new()
	mat.albedo_color = grout_color
	mat.roughness = 0.9
	mat.metallic = 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Lines parallel to X axis (running along width), spaced in Z
	for i in range(1, floor_tile_count):
		var z := -room_depth * 0.5 + i * cell_z
		var line := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(room_width, line_height, line_thickness)
		line.mesh = m
		line.material_override = mat
		line.position = Vector3(0.0, floor_top_y, z)
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		grout.add_child(line)

	# Lines parallel to Z axis (running along depth), spaced in X
	for i in range(1, floor_tile_count):
		var x := -room_width * 0.5 + i * cell_x
		var line := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(line_thickness, line_height, room_depth)
		line.mesh = m
		line.material_override = mat
		line.position = Vector3(x, floor_top_y, 0.0)
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		grout.add_child(line)


# ── Walls ─────────────────────────────────────────────────────────────
# Naming convention: "front" = -Z (signage wall, where the player looks),
#                    "back"  = +Z (glass observation wall, player's side).

func _build_walls() -> void:
	var walls := Node3D.new()
	walls.name = "Walls"
	add_child(walls)

	var wall_mat := _make_wall_material()

	# Front wall (-Z, signage wall, full panel)
	var front := MeshInstance3D.new()
	front.name = "WallFront"
	var fm := BoxMesh.new()
	fm.size = Vector3(room_width, room_height, WALL_THICKNESS)
	front.mesh = fm
	front.material_override = wall_mat
	front.position = Vector3(0.0, room_height * 0.5, -room_depth * 0.5 + WALL_THICKNESS * 0.5)
	walls.add_child(front)

	# East wall (+X)
	var east := MeshInstance3D.new()
	east.name = "WallEast"
	var em := BoxMesh.new()
	em.size = Vector3(WALL_THICKNESS, room_height, room_depth)
	east.mesh = em
	east.material_override = wall_mat
	east.position = Vector3(room_width * 0.5 - WALL_THICKNESS * 0.5, room_height * 0.5, 0.0)
	walls.add_child(east)

	# West wall (-X)
	var west := MeshInstance3D.new()
	west.name = "WallWest"
	var wm := BoxMesh.new()
	wm.size = Vector3(WALL_THICKNESS, room_height, room_depth)
	west.mesh = wm
	west.material_override = wall_mat
	west.position = Vector3(-room_width * 0.5 + WALL_THICKNESS * 0.5, room_height * 0.5, 0.0)
	walls.add_child(west)

	# Back wall (+Z) — three options, in priority order:
	#  1. show_back_window: solid wall with a LARGE window cut into it (NEW)
	#  2. south_wall_is_glass: full-wall glass (legacy)
	#  3. neither: nothing — open observation gap
	if show_back_window:
		_build_back_solid_with_window(walls)
	elif south_wall_is_glass:
		_build_back_glass(walls)

	# Front wall (-Z) — optional small "look back" window.
	if show_front_window:
		_build_front_small_window(walls)

	# Sliding door with proximity sensor.
	if show_sliding_door:
		_build_sliding_door(walls)

	# Panel seams overlaid on the walls (Portal 2 look)
	if wall_pattern == "panels":
		_build_panel_seams(walls)

	# Observation window — translucent emissive overlay on the chosen wall.
	if show_observation_window:
		_build_observation_window(walls)


func _make_wall_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	match wall_pattern:
		"concrete":
			# Raw concrete: warmer gray, higher roughness, no metallic.
			mat.albedo_color = Color(0.55, 0.53, 0.50)
			mat.roughness = 0.85
			mat.metallic = 0.0
		"panels":
			# Clean Aperture panels — same near-white but slightly brighter,
			# very low roughness so the panel seams read as crisp edges.
			mat.albedo_color = wall_color
			mat.roughness = 0.45
			mat.metallic = 0.02
		_:
			# "smooth" / default
			mat.albedo_color = wall_color
			mat.roughness = 0.65
			mat.metallic = 0.0
	return mat


func _build_panel_seams(parent: Node3D) -> void:
	# Decorative thin dark strips overlaid on each wall, at column intervals.
	# These are cosmetic — they sit a hair in front of the wall surface and
	# read as panel seams (Portal 2 / Aperture clean-room look).
	if panel_columns <= 1:
		return
	var seams := Node3D.new()
	seams.name = "PanelSeams"
	parent.add_child(seams)

	var seam_mat := StandardMaterial3D.new()
	seam_mat.albedo_color = seam_color
	seam_mat.roughness = 0.5
	seam_mat.metallic = 0.2
	seam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var vert_thickness := 0.025  # seam line width
	var vert_depth := 0.015      # how far it sticks out from the wall

	# A horizontal seam at mid-height too, splitting each panel into upper/lower
	var horiz_thickness := 0.020

	# ── Front wall (-Z): seams run vertically across width, plus one horizontal
	var cell_x := room_width / float(panel_columns)
	for i in range(1, panel_columns):
		var x := -room_width * 0.5 + i * cell_x
		var line := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(vert_thickness, room_height, vert_depth)
		line.mesh = m
		line.material_override = seam_mat
		line.position = Vector3(x, room_height * 0.5,
			-room_depth * 0.5 + WALL_THICKNESS + vert_depth * 0.5)
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		seams.add_child(line)
	var front_h := MeshInstance3D.new()
	var fhm := BoxMesh.new()
	fhm.size = Vector3(room_width, horiz_thickness, vert_depth)
	front_h.mesh = fhm
	front_h.material_override = seam_mat
	front_h.position = Vector3(0.0, room_height * 0.5,
		-room_depth * 0.5 + WALL_THICKNESS + vert_depth * 0.5)
	front_h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	seams.add_child(front_h)

	# ── East wall (+X): seams run along depth, plus one horizontal
	var depth_columns: int = max(2, int(round(panel_columns * (room_depth / room_width))))
	var cell_z := room_depth / float(depth_columns)
	for i in range(1, depth_columns):
		var z := -room_depth * 0.5 + i * cell_z
		var line := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(vert_depth, room_height, vert_thickness)
		line.mesh = m
		line.material_override = seam_mat
		line.position = Vector3(
			room_width * 0.5 - WALL_THICKNESS - vert_depth * 0.5,
			room_height * 0.5,
			z
		)
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		seams.add_child(line)
	var east_h := MeshInstance3D.new()
	var ehm := BoxMesh.new()
	ehm.size = Vector3(vert_depth, horiz_thickness, room_depth)
	east_h.mesh = ehm
	east_h.material_override = seam_mat
	east_h.position = Vector3(
		room_width * 0.5 - WALL_THICKNESS - vert_depth * 0.5,
		room_height * 0.5,
		0.0
	)
	east_h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	seams.add_child(east_h)

	# ── West wall (-X): mirror of east
	for i in range(1, depth_columns):
		var z := -room_depth * 0.5 + i * cell_z
		var line := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(vert_depth, room_height, vert_thickness)
		line.mesh = m
		line.material_override = seam_mat
		line.position = Vector3(
			-room_width * 0.5 + WALL_THICKNESS + vert_depth * 0.5,
			room_height * 0.5,
			z
		)
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		seams.add_child(line)
	var west_h := MeshInstance3D.new()
	var whm := BoxMesh.new()
	whm.size = Vector3(vert_depth, horiz_thickness, room_depth)
	west_h.mesh = whm
	west_h.material_override = seam_mat
	west_h.position = Vector3(
		-room_width * 0.5 + WALL_THICKNESS + vert_depth * 0.5,
		room_height * 0.5,
		0.0
	)
	west_h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	seams.add_child(west_h)


func _build_observation_window(parent: Node3D) -> void:
	# Translucent darker overlay BoxMesh with slight emission — reads as a
	# window/screen sunk into the wall, not as a hole.
	var win := MeshInstance3D.new()
	win.name = "ObservationWindow"

	# Window glass body
	var win_w: float = window_size.x
	var win_h: float = window_size.y
	var win_y := room_height * 0.5  # centered at chest/eye level

	var glass_thickness := 0.04
	var frame_thickness := 0.06

	var glass_mat := StandardMaterial3D.new()
	# Slightly darker glass that reads as a backlit observation pane.
	glass_mat.albedo_color = Color(0.20, 0.28, 0.36, 0.85)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.20
	glass_mat.metallic = 0.0
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.55, 0.75, 0.95)
	glass_mat.emission_energy_multiplier = 0.45

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.10, 0.10, 0.12)
	frame_mat.roughness = 0.35
	frame_mat.metallic = 0.7

	var mesh := BoxMesh.new()
	mesh.size = Vector3(win_w, win_h, glass_thickness)
	win.mesh = mesh
	win.material_override = glass_mat

	# Position depending on wall.
	# "north" = back wall (+Z, the player-side / glass wall — we still allow
	# placement there, but normally the back wall is the south_wall_is_glass
	# panel; observation window stays on side walls in current 6 cells).
	# Default east — windows look out at the side of the chamber.
	var inset := WALL_THICKNESS + glass_thickness * 0.5 + 0.001
	match window_wall:
		"north":
			# back wall +Z
			win.position = Vector3(0.0, win_y, room_depth * 0.5 - inset)
		"south":
			# front wall -Z (the signage wall — usually not where you want it)
			win.position = Vector3(0.0, win_y, -room_depth * 0.5 + inset)
		"west":
			win.position = Vector3(-room_width * 0.5 + inset, win_y, 0.0)
			win.rotation = Vector3(0.0, PI * 0.5, 0.0)
			mesh.size = Vector3(win_w, win_h, glass_thickness)
		"east", _:
			win.position = Vector3(room_width * 0.5 - inset, win_y, 0.0)
			win.rotation = Vector3(0.0, -PI * 0.5, 0.0)
			mesh.size = Vector3(win_w, win_h, glass_thickness)
	parent.add_child(win)

	# Frame around the window — four thin dark BoxMesh strips.
	var frame_root := Node3D.new()
	frame_root.name = "ObservationWindowFrame"
	frame_root.position = win.position
	frame_root.rotation = win.rotation
	parent.add_child(frame_root)

	var half_w := win_w * 0.5
	var half_h := win_h * 0.5

	# Top frame
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(win_w + frame_thickness * 2, frame_thickness, frame_thickness)
	top.mesh = tm
	top.material_override = frame_mat
	top.position = Vector3(0.0, half_h + frame_thickness * 0.5, 0.0)
	frame_root.add_child(top)

	# Bottom frame
	var bot := MeshInstance3D.new()
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(win_w + frame_thickness * 2, frame_thickness, frame_thickness)
	bot.mesh = bm2
	bot.material_override = frame_mat
	bot.position = Vector3(0.0, -half_h - frame_thickness * 0.5, 0.0)
	frame_root.add_child(bot)

	# Left frame
	var lf := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(frame_thickness, win_h, frame_thickness)
	lf.mesh = lm
	lf.material_override = frame_mat
	lf.position = Vector3(-half_w - frame_thickness * 0.5, 0.0, 0.0)
	frame_root.add_child(lf)

	# Right frame
	var rf := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(frame_thickness, win_h, frame_thickness)
	rf.mesh = rm
	rf.material_override = frame_mat
	rf.position = Vector3(half_w + frame_thickness * 0.5, 0.0, 0.0)
	frame_root.add_child(rf)


func _build_back_solid_with_window(parent: Node3D) -> void:
	# Build the +Z back wall as a solid panel split around a central large
	# window — three strips above/below/sides of the window opening, then a
	# tinted glass pane fills the opening. Reads as a real building wall.
	var win_w: float = clamp(back_window_size.x, 0.5, max(0.5, room_width - 0.6))
	var win_h: float = clamp(back_window_size.y, 0.5, max(0.5, room_height - 1.0))
	var win_y: float = room_height * 0.5  # window centred vertically
	var side_w: float = (room_width - win_w) * 0.5
	var top_h: float = room_height - (win_y + win_h * 0.5)
	var bot_h: float = win_y - win_h * 0.5
	var z_plane: float = room_depth * 0.5 - WALL_THICKNESS * 0.5

	var wall_mat := _make_wall_material()

	if side_w > 0.001:
		# Left strip
		var left := MeshInstance3D.new()
		left.name = "BackWallLeft"
		var lm := BoxMesh.new()
		lm.size = Vector3(side_w, room_height, WALL_THICKNESS)
		left.mesh = lm
		left.material_override = wall_mat
		left.position = Vector3(-room_width * 0.5 + side_w * 0.5, room_height * 0.5, z_plane)
		parent.add_child(left)

		# Right strip
		var right := MeshInstance3D.new()
		right.name = "BackWallRight"
		var rm := BoxMesh.new()
		rm.size = Vector3(side_w, room_height, WALL_THICKNESS)
		right.mesh = rm
		right.material_override = wall_mat
		right.position = Vector3(room_width * 0.5 - side_w * 0.5, room_height * 0.5, z_plane)
		parent.add_child(right)

	if bot_h > 0.001:
		var bot := MeshInstance3D.new()
		bot.name = "BackWallBot"
		var bm := BoxMesh.new()
		bm.size = Vector3(win_w, bot_h, WALL_THICKNESS)
		bot.mesh = bm
		bot.material_override = wall_mat
		bot.position = Vector3(0.0, bot_h * 0.5, z_plane)
		parent.add_child(bot)

	if top_h > 0.001:
		var top := MeshInstance3D.new()
		top.name = "BackWallTop"
		var tm := BoxMesh.new()
		tm.size = Vector3(win_w, top_h, WALL_THICKNESS)
		top.mesh = tm
		top.material_override = wall_mat
		top.position = Vector3(0.0, room_height - top_h * 0.5, z_plane)
		parent.add_child(top)

	# The glass pane filling the window opening.
	var glass := MeshInstance3D.new()
	glass.name = "BackWindowGlass"
	var gm := BoxMesh.new()
	gm.size = Vector3(win_w, win_h, WALL_THICKNESS * 0.5)
	glass.mesh = gm
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.78, 0.86, 0.94, 0.30)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.12
	glass_mat.metallic = 0.0
	glass_mat.refraction_enabled = false
	glass.material_override = glass_mat
	glass.position = Vector3(0.0, win_y, z_plane)
	parent.add_child(glass)

	# Window frame (4 thin dark strips ringing the glass).
	_build_window_frame_strips(parent, "BackWindowFrame", win_w, win_h, Vector3(0.0, win_y, z_plane), 0.0)


func _build_front_small_window(parent: Node3D) -> void:
	# Small window cut into the -Z front (signage) wall. Above signage by
	# default; can be offset along X so it sits beside the centred signage.
	var win_w: float = clamp(front_window_size.x, 0.3, max(0.3, room_width - 0.6))
	var win_h: float = clamp(front_window_size.y, 0.3, max(0.3, room_height - 1.5))
	var win_y: float = clamp(front_window_y, win_h * 0.5 + 0.1, room_height - win_h * 0.5 - 0.1)
	var z_plane: float = -room_depth * 0.5 + WALL_THICKNESS * 0.5
	var cx: float = clamp(front_window_offset_x, -room_width * 0.5 + win_w * 0.5 + 0.1, room_width * 0.5 - win_w * 0.5 - 0.1)

	# Glass pane — placed slightly forward into the room so it reads as
	# a hole in the existing front wall (rather than tearing the wall
	# down, we layer a translucent panel inside the wall thickness).
	var glass := MeshInstance3D.new()
	glass.name = "FrontWindowGlass"
	var gm := BoxMesh.new()
	gm.size = Vector3(win_w, win_h, WALL_THICKNESS * 0.4)
	glass.mesh = gm
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.30, 0.42, 0.58, 0.55)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.18
	glass_mat.metallic = 0.0
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.40, 0.55, 0.78)
	glass_mat.emission_energy_multiplier = 0.30
	glass.material_override = glass_mat
	glass.position = Vector3(cx, win_y, z_plane + WALL_THICKNESS * 0.25)
	parent.add_child(glass)

	_build_window_frame_strips(parent, "FrontWindowFrame", win_w, win_h, Vector3(cx, win_y, z_plane + WALL_THICKNESS * 0.25), 0.0)


func _build_window_frame_strips(parent: Node3D, root_name: String, win_w: float, win_h: float, centre: Vector3, y_rot: float) -> void:
	# Four thin dark strips ringing a window opening. y_rot rotates the
	# frame around vertical (used when frame is on east/west walls).
	var frame_root := Node3D.new()
	frame_root.name = root_name
	frame_root.position = centre
	frame_root.rotation = Vector3(0.0, y_rot, 0.0)
	parent.add_child(frame_root)

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.12, 0.13, 0.16)
	frame_mat.roughness = 0.4
	frame_mat.metallic = 0.6

	var ft: float = 0.05
	var half_w: float = win_w * 0.5
	var half_h: float = win_h * 0.5
	var z_off: float = -WALL_THICKNESS * 0.25 # slight pull toward interior

	# Top
	var t := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(win_w + ft * 2.0, ft, ft)
	t.mesh = tm
	t.material_override = frame_mat
	t.position = Vector3(0.0, half_h + ft * 0.5, z_off)
	frame_root.add_child(t)
	# Bottom
	var b := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(win_w + ft * 2.0, ft, ft)
	b.mesh = bm
	b.material_override = frame_mat
	b.position = Vector3(0.0, -half_h - ft * 0.5, z_off)
	frame_root.add_child(b)
	# Left
	var l := MeshInstance3D.new()
	var lm2 := BoxMesh.new()
	lm2.size = Vector3(ft, win_h, ft)
	l.mesh = lm2
	l.material_override = frame_mat
	l.position = Vector3(-half_w - ft * 0.5, 0.0, z_off)
	frame_root.add_child(l)
	# Right
	var r := MeshInstance3D.new()
	var rm2 := BoxMesh.new()
	rm2.size = Vector3(ft, win_h, ft)
	r.mesh = rm2
	r.material_override = frame_mat
	r.position = Vector3(half_w + ft * 0.5, 0.0, z_off)
	frame_root.add_child(r)


func _build_sliding_door(parent: Node3D) -> void:
	const HANDLER_SCRIPT_PATH := "res://commons/artifacts/lab_room/lab_door_sensor.gd"
	# Two-panel sliding door with proximity sensor (Area3D) on the upper
	# frame. The panels slide outward into wall pockets when the player
	# enters the sensor radius.
	var door_root := Node3D.new()
	door_root.name = "SlidingDoor"

	# Place + orient the door according to door_wall. The local frame
	# of door_root has X = door width, Y = up, Z = wall normal (outward).
	var pos: Vector3 = Vector3.ZERO
	var y_rot: float = 0.0
	match door_wall:
		"north":  # -Z front wall (signage wall — usually not chosen)
			pos = Vector3(0.0, 0.0, -room_depth * 0.5 + WALL_THICKNESS * 0.5)
			y_rot = PI
		"south":  # +Z back wall
			pos = Vector3(0.0, 0.0, room_depth * 0.5 - WALL_THICKNESS * 0.5)
			y_rot = 0.0
		"west":   # -X wall
			pos = Vector3(-room_width * 0.5 + WALL_THICKNESS * 0.5, 0.0, 0.0)
			y_rot = -PI * 0.5
		"east", _:  # +X wall
			pos = Vector3(room_width * 0.5 - WALL_THICKNESS * 0.5, 0.0, 0.0)
			y_rot = PI * 0.5
	door_root.position = pos
	door_root.rotation = Vector3(0.0, y_rot, 0.0)
	parent.add_child(door_root)

	# Frame material (matt dark metal).
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.13, 0.14, 0.17)
	frame_mat.roughness = 0.45
	frame_mat.metallic = 0.55

	# Door panels material (slightly lighter, more reflective — reads as
	# steel doors against the dark frame).
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.18, 0.20, 0.23)
	panel_mat.roughness = 0.35
	panel_mat.metallic = 0.60

	var ft: float = 0.08          # frame thickness
	var fd: float = 0.14          # how far the frame sticks out from the wall (toward interior)
	var dh: float = door_height   # opening height
	var dw: float = door_width    # opening width
	var half_dw: float = dw * 0.5
	var pt: float = 0.06          # panel thickness

	# Top beam
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(dw + ft * 2.0, ft, fd)
	top.mesh = tm
	top.material_override = frame_mat
	top.position = Vector3(0.0, dh + ft * 0.5, 0.0)
	door_root.add_child(top)

	# Left and right side frames
	var left_f := MeshInstance3D.new()
	var lfm := BoxMesh.new()
	lfm.size = Vector3(ft, dh, fd)
	left_f.mesh = lfm
	left_f.material_override = frame_mat
	left_f.position = Vector3(-half_dw - ft * 0.5, dh * 0.5, 0.0)
	door_root.add_child(left_f)

	var right_f := MeshInstance3D.new()
	var rfm := BoxMesh.new()
	rfm.size = Vector3(ft, dh, fd)
	right_f.mesh = rfm
	right_f.material_override = frame_mat
	right_f.position = Vector3(half_dw + ft * 0.5, dh * 0.5, 0.0)
	door_root.add_child(right_f)

	# Upper sensor box — visibly mounted on top of the frame, slightly
	# protruding toward the interior so the player sees it as they approach.
	var sensor := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.30, 0.12, 0.18)
	sensor.mesh = sm
	var sensor_mat := StandardMaterial3D.new()
	sensor_mat.albedo_color = Color(0.09, 0.10, 0.12)
	sensor_mat.roughness = 0.42
	sensor_mat.metallic = 0.35
	sensor.material_override = sensor_mat
	sensor.position = Vector3(0.0, dh + ft + 0.06, fd * 0.25)
	door_root.add_child(sensor)

	# Indicator LED dot on the sensor face.
	var indicator := MeshInstance3D.new()
	var idm := SphereMesh.new()
	idm.radius = 0.035
	idm.height = 0.07
	indicator.mesh = idm
	var ind_mat := StandardMaterial3D.new()
	ind_mat.albedo_color = Color(0.9, 0.22, 0.27)
	ind_mat.emission_enabled = true
	ind_mat.emission = Color(0.9, 0.22, 0.27)
	ind_mat.emission_energy_multiplier = 2.2
	ind_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator.material_override = ind_mat
	indicator.position = Vector3(0.0, dh + ft + 0.06, fd * 0.25 + 0.10)
	door_root.add_child(indicator)

	# Two sliding panels. Default closed: panels meet at centre.
	var panel_w: float = half_dw
	var left_panel := MeshInstance3D.new()
	left_panel.name = "DoorPanelLeft"
	var lpm := BoxMesh.new()
	lpm.size = Vector3(panel_w, dh, pt)
	left_panel.mesh = lpm
	left_panel.material_override = panel_mat
	left_panel.position = Vector3(-panel_w * 0.5, dh * 0.5, 0.0)
	door_root.add_child(left_panel)

	var right_panel := MeshInstance3D.new()
	right_panel.name = "DoorPanelRight"
	var rpm := BoxMesh.new()
	rpm.size = Vector3(panel_w, dh, pt)
	right_panel.mesh = rpm
	right_panel.material_override = panel_mat
	right_panel.position = Vector3(panel_w * 0.5, dh * 0.5, 0.0)
	door_root.add_child(right_panel)

	# Proximity sensor Area3D. Place it on the door's interior side so it
	# triggers as the player approaches from outside the room or from
	# inside.
	var area := Area3D.new()
	area.name = "DoorSensorArea"
	area.collision_layer = 0
	area.collision_mask = 0xFFFFF  # everything — VR rig, desktop player, characters
	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = door_sensor_radius
	cs.shape = sphere
	cs.position = Vector3(0.0, dh * 0.5, 0.0)
	area.add_child(cs)
	door_root.add_child(area)

	# Handler script — opens/closes the panels on body_entered / body_exited.
	var handler_pack: GDScript = load(HANDLER_SCRIPT_PATH)
	if handler_pack == null:
		push_warning("LabRoom: could not load lab_door_sensor.gd")
		return
	var handler: Node3D = handler_pack.new()
	handler.name = "DoorHandler"
	handler.set("left_panel", left_panel)
	handler.set("right_panel", right_panel)
	handler.set("indicator", indicator)
	handler.set("area", area)
	handler.set("panel_width", panel_w)
	handler.set("open_offset", door_open_offset)
	handler.set("open_color", Color(0.40, 1.00, 0.55))
	handler.set("closed_color", Color(0.90, 0.22, 0.27))
	door_root.add_child(handler)


# ── Ceiling ───────────────────────────────────────────────────────────

func _build_ceiling() -> void:
	var ceil := MeshInstance3D.new()
	ceil.name = "Ceiling"
	var m := BoxMesh.new()
	m.size = Vector3(room_width, CEILING_THICKNESS, room_depth)
	ceil.mesh = m
	var mat := StandardMaterial3D.new()
	match ceiling_style:
		"skylight":
			# Bright frosted-glass panel feel — brighter albedo and slight emission.
			mat.albedo_color = Color(0.96, 0.97, 1.0)
			mat.roughness = 0.30
			mat.metallic = 0.0
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.98, 0.92)
			mat.emission_energy_multiplier = 0.55
		"exposed":
			# Darker industrial ceiling — the trays will read against it.
			mat.albedo_color = Color(0.30, 0.30, 0.33)
			mat.roughness = 0.85
			mat.metallic = 0.1
		_:
			# default tile_grid (plain panel)
			mat.albedo_color = ceiling_color
			mat.roughness = 0.75
			mat.metallic = 0.0
	ceil.material_override = mat
	ceil.position = Vector3(0.0, room_height - CEILING_THICKNESS * 0.5, 0.0)
	add_child(ceil)

	if ceiling_style == "exposed":
		_build_exposed_ceiling()
	elif ceiling_style == "skylight":
		_build_skylight_grid()


func _build_exposed_ceiling() -> void:
	# A few long thin cable-tray boxes running along the room's depth, plus
	# a handful of light fixture strips. Reads as raw industrial ceiling.
	var trays := Node3D.new()
	trays.name = "ExposedCeilingTrays"
	add_child(trays)

	var tray_mat := StandardMaterial3D.new()
	tray_mat.albedo_color = Color(0.18, 0.18, 0.20)
	tray_mat.roughness = 0.45
	tray_mat.metallic = 0.6

	var fixture_mat := StandardMaterial3D.new()
	fixture_mat.albedo_color = Color(0.92, 0.90, 0.78)
	fixture_mat.emission_enabled = true
	fixture_mat.emission = Color(1.0, 0.95, 0.78)
	fixture_mat.emission_energy_multiplier = 1.6
	fixture_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var tray_count: int = 3
	var ceiling_y := room_height - CEILING_THICKNESS - 0.04
	for i in range(tray_count):
		var t := float(i + 1) / float(tray_count + 1)
		var x := -room_width * 0.5 + t * room_width
		var tray := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.12, 0.08, room_depth - 0.4)
		tray.mesh = m
		tray.material_override = tray_mat
		tray.position = Vector3(x, ceiling_y - 0.05, 0.0)
		trays.add_child(tray)

		# Skinny light fixture strip alongside the central tray.
		if i == 1 or tray_count <= 1:
			var fix := MeshInstance3D.new()
			var fm := BoxMesh.new()
			fm.size = Vector3(0.20, 0.03, room_depth * 0.6)
			fix.mesh = fm
			fix.material_override = fixture_mat
			fix.position = Vector3(x, ceiling_y - 0.02, 0.0)
			fix.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			trays.add_child(fix)


func _build_skylight_grid() -> void:
	# Thin dark crossbeams overlaid on the bright ceiling — reads as a
	# skylight panel grid (frosted glass between the beams).
	var beams := Node3D.new()
	beams.name = "SkylightGrid"
	add_child(beams)

	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(0.22, 0.22, 0.25)
	beam_mat.roughness = 0.5
	beam_mat.metallic = 0.4

	var beam_thickness := 0.05
	var ceiling_y := room_height - CEILING_THICKNESS - 0.005

	# 2 longitudinal beams (along Z)
	var lon_count := 2
	for i in range(1, lon_count + 1):
		var t := float(i) / float(lon_count + 1)
		var x := -room_width * 0.5 + t * room_width
		var b := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(beam_thickness, beam_thickness, room_depth)
		b.mesh = m
		b.material_override = beam_mat
		b.position = Vector3(x, ceiling_y, 0.0)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beams.add_child(b)

	# 2 cross beams (along X)
	for i in range(1, lon_count + 1):
		var t := float(i) / float(lon_count + 1)
		var z := -room_depth * 0.5 + t * room_depth
		var b := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(room_width, beam_thickness, beam_thickness)
		b.mesh = m
		b.material_override = beam_mat
		b.position = Vector3(0.0, ceiling_y, z)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beams.add_child(b)


# ── Accent strip ──────────────────────────────────────────────────────

func _build_accent_strip() -> void:
	# Horizontal strip along the top of the front wall (-Z) — the room's *color*.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var m := BoxMesh.new()
	m.size = Vector3(room_width - 0.4, 0.10, 0.05)
	strip.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = accent_strip_energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Just inside the front wall (offset a hair toward the room interior).
	strip.position = Vector3(
		0.0,
		room_height - 0.25,
		-room_depth * 0.5 + WALL_THICKNESS + 0.03
	)
	add_child(strip)

	# Mirror a thinner strip along the floor edge of the same wall —
	# the room reads as a sandwich of light at top and bottom.
	var floor_strip := MeshInstance3D.new()
	floor_strip.name = "AccentStripFloor"
	var fm := BoxMesh.new()
	fm.size = Vector3(room_width - 0.4, 0.04, 0.04)
	floor_strip.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = accent_color
	fmat.emission_enabled = true
	fmat.emission = accent_color
	fmat.emission_energy_multiplier = accent_strip_energy * 0.6
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_strip.material_override = fmat
	floor_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	floor_strip.position = Vector3(
		0.0,
		0.08,
		-room_depth * 0.5 + WALL_THICKNESS + 0.025
	)
	add_child(floor_strip)


# ── Plinth + mount_point ──────────────────────────────────────────────

func _build_plinth_and_mount() -> void:
	if show_plinth:
		var plinth := MeshInstance3D.new()
		plinth.name = "Plinth"
		var m := BoxMesh.new()
		m.size = plinth_size
		plinth.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = plinth_color
		mat.roughness = 0.35
		mat.metallic = 0.25
		plinth.material_override = mat
		# Plinth centered on origin, bottom at floor top (y=0).
		plinth.position = Vector3(0.0, plinth_size.y * 0.5, 0.0)
		add_child(plinth)

	# mount_point sits at the plinth top center (or at floor if no plinth)
	mount_point = Node3D.new()
	mount_point.name = "mount_point"
	var mount_y := plinth_size.y if show_plinth else 0.0
	mount_point.position = Vector3(0.0, mount_y, 0.0)
	add_child(mount_point)


# ── Signage ───────────────────────────────────────────────────────────

func _build_signage() -> void:
	# Mounted on the front wall (-Z, same wall as the accent strip).
	var signage_root := Node3D.new()
	signage_root.name = "Signage"
	# Just in front of the front wall, at chest-to-head height.
	# Front wall faces +Z, so signage labels (which face -Z by default)
	# need to be flipped 180° to face +Z (readable from inside).
	signage_root.position = Vector3(
		0.0,
		room_height * 0.62,
		-room_depth * 0.5 + WALL_THICKNESS + 0.06
	)
	# Label3D in Godot 4 defaults to facing +Z (readable from +Z-side
	# viewers). The player is at +Z looking toward -Z, so default
	# orientation reads correctly. No rotation needed.
	add_child(signage_root)

	# TOP line: large white identifier.
	var top := Label3D.new()
	top.name = "SignageTop"
	top.text = signage_top
	top.font_size = 72
	top.outline_size = 6
	top.pixel_size = 0.005
	top.modulate = Color(1.0, 1.0, 1.0)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.position = Vector3(0.0, 0.18, 0.0)
	signage_root.add_child(top)

	# SUB line: smaller, accent-tinted.
	var sub := Label3D.new()
	sub.name = "SignageSub"
	sub.text = signage_sub
	sub.font_size = 36
	sub.outline_size = 4
	sub.pixel_size = 0.005
	sub.modulate = accent_color.lerp(Color(1.0, 1.0, 1.0), 0.25)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.position = Vector3(0.0, -0.04, 0.0)
	signage_root.add_child(sub)


# ── Wall annotations ──────────────────────────────────────────────────

func _build_wall_annotations() -> void:
	var anno := Node3D.new()
	anno.name = "WallAnnotations"
	add_child(anno)

	var anno_color := Color(0.40, 0.42, 0.48)

	# East wall (+X) — text reads from inside (label faces -X).
	# Default Label3D normal is -Z; rotating around Y by -90° makes the
	# label face -X (toward the room interior).
	var east := Label3D.new()
	east.name = "AnnotationEast"
	east.text = annotation_top
	east.font_size = 28
	east.outline_size = 3
	east.pixel_size = 0.005
	east.modulate = anno_color
	east.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	east.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	east.position = Vector3(
		room_width * 0.5 - WALL_THICKNESS - 0.06,
		1.5,
		0.0
	)
	east.rotation = Vector3(0.0, -PI * 0.5, 0.0)
	anno.add_child(east)

	# West wall (-X).
	var west := Label3D.new()
	west.name = "AnnotationWest"
	west.text = annotation_bottom
	west.font_size = 28
	west.outline_size = 3
	west.pixel_size = 0.005
	west.modulate = anno_color
	west.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	west.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	west.position = Vector3(
		-room_width * 0.5 + WALL_THICKNESS + 0.06,
		1.5,
		0.0
	)
	west.rotation = Vector3(0.0, PI * 0.5, 0.0)
	anno.add_child(west)


# ── Lighting ──────────────────────────────────────────────────────────

func _build_lighting() -> void:
	var lights := Node3D.new()
	lights.name = "Lighting"
	add_child(lights)

	# Directional from above-and-back (slightly toward player side for
	# rim-lit signage). Warm/cool by slider.
	var dir := DirectionalLight3D.new()
	dir.name = "KeyLight"
	var warm := Color(1.0, 0.93, 0.78)
	var cool := Color(0.78, 0.88, 1.0)
	dir.light_color = warm.lerp(cool, light_warmth)
	dir.light_energy = light_energy
	# Tilt down 40°, slight yaw to give shadowing relief.
	dir.rotation_degrees = Vector3(-40.0, 25.0, 0.0)
	dir.position = Vector3(0.0, room_height + 1.0, 0.0)
	dir.shadow_enabled = true
	lights.add_child(dir)

	# Accent omni — high, biased toward the front strip wall.
	# Casts the room's color into the air, lights the mounted artifact
	# from the front for visual emphasis.
	var omni := OmniLight3D.new()
	omni.name = "AccentOmni"
	omni.light_color = accent_color
	omni.light_energy = accent_strip_energy * 0.8
	omni.omni_range = max(room_width, room_depth) * 0.9
	omni.omni_attenuation = 1.5
	omni.position = Vector3(
		0.0,
		room_height * 0.85,
		-room_depth * 0.30
	)
	lights.add_child(omni)

	# A soft fill omni on the player side so faces are readable.
	var fill := OmniLight3D.new()
	fill.name = "FillOmni"
	fill.light_color = Color(1.0, 1.0, 1.0)
	fill.light_energy = light_energy * 0.6
	fill.omni_range = max(room_width, room_depth)
	fill.omni_attenuation = 1.2
	fill.position = Vector3(
		0.0,
		room_height * 0.75,
		room_depth * 0.25
	)
	lights.add_child(fill)


# ── Mounted artifact ──────────────────────────────────────────────────

func _instantiate_mounted_artifact() -> void:
	if mounted_artifact_scene == "":
		return
	if not ResourceLoader.exists(mounted_artifact_scene):
		push_warning("LabRoom: mounted_artifact_scene not found: %s" % mounted_artifact_scene)
		return
	var packed: PackedScene = load(mounted_artifact_scene)
	if packed == null:
		push_warning("LabRoom: failed to load mounted_artifact_scene: %s" % mounted_artifact_scene)
		return
	var instance := packed.instantiate()
	instance.name = "MountedArtifact"
	mount_point.add_child(instance)


func _instantiate_mounted_lab_json() -> void:
	# Defer LabLoader to avoid a hard dependency at parse time —
	# script load only when this path is configured.
	const LAB_LOADER_PATH := "res://commons/artifacts/lab_room/lab_loader.gd"
	if mounted_lab_json == "":
		return
	if not FileAccess.file_exists(mounted_lab_json):
		push_warning("LabRoom: mounted_lab_json not found: %s" % mounted_lab_json)
		return
	var loader_script: GDScript = load(LAB_LOADER_PATH)
	if loader_script == null:
		push_warning("LabRoom: could not load LabLoader script")
		return
	# Static call — LabLoader is a class with static methods only.
	loader_script.call("load_into", mount_point, mounted_lab_json)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	# "r,g,b" or "r,g,b,a" with floats in [0,1].
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
	var t := s.strip_edges().to_lower()
	if t == "true" or t == "1" or t == "yes" or t == "on":
		return true
	if t == "false" or t == "0" or t == "no" or t == "off":
		return false
	return fallback


func _parse_vec2(s: String, fallback: Vector2) -> Vector2:
	var parts := s.split(",")
	if parts.size() < 2:
		return fallback
	return Vector2(float(parts[0]), float(parts[1]))


# Legacy: full-wall glass on the +Z back wall. Kept so existing maps
# (like Random_Walk) that rely on south_wall_is_glass continue working.
# New maps should use show_back_window for a defined-size window.
func _build_back_glass(parent: Node3D) -> void:
	var glass := MeshInstance3D.new()
	glass.name = "WallBackGlass"
	var gm := BoxMesh.new()
	gm.size = Vector3(room_width, room_height, WALL_THICKNESS * 0.5)
	glass.mesh = gm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic = 0.0
	mat.refraction_enabled = false
	glass.material_override = mat
	glass.position = Vector3(0.0, room_height * 0.5, room_depth * 0.5 - WALL_THICKNESS * 0.25)
	parent.add_child(glass)

	# Glass frame strips (thin dark borders) to read as "panel" not "void".
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.15, 0.16, 0.18)
	frame_mat.roughness = 0.4
	frame_mat.metallic = 0.6

	var frame_thickness := 0.04
	var top_frame := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(room_width, frame_thickness, frame_thickness)
	top_frame.mesh = tm
	top_frame.material_override = frame_mat
	top_frame.position = Vector3(0.0, room_height - frame_thickness * 0.5, room_depth * 0.5)
	parent.add_child(top_frame)

	var bottom_frame := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(room_width, frame_thickness, frame_thickness)
	bottom_frame.mesh = bm
	bottom_frame.material_override = frame_mat
	bottom_frame.position = Vector3(0.0, frame_thickness * 0.5, room_depth * 0.5)
	parent.add_child(bottom_frame)
