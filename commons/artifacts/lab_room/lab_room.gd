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
# Default dimensions match the encyclopedia's /lab-editor DEFAULT_LAB
# (8 × 7 × 3.8 m) so the procedural GLB export and the lab JSON's
# prop positions agree at room scale. Per-lab configs still override
# these via mounted_lab_json or config metadata.
@export var room_width: float = 8.0
@export var room_depth: float = 7.0
@export var room_height: float = 3.8

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
## Offset of the back window along the back wall's X axis (metres).
## 0 = centred. Lab editor drag-on-wall writes this.
@export var back_window_offset_x: float = 0.0
## Smaller window on the -Z front wall (the signage / entry-from-grid
## side when door_wall=="south"). Off by default so the simple lab is
## clean front-wall (signage only) and back-wall (door + big window).
@export var show_front_window: bool = false
@export var front_window_size: Vector2 = Vector2(1.6, 0.8)
## Horizontal offset of the front window from the wall centre. With
## door_wall="north" and a centred door, leave at 0 to keep both
## centred (window above the door + flanking wall segments).
@export var front_window_offset_x: float = 0.0
@export var front_window_y: float = 2.45

@export_group("Floor window")
## Cut a translucent window into the floor — for "lab built over a
## coordinate" placements (e.g. a chamber sitting above origin_zero
## in the grid below). The floor is built as four strips around the
## window; a tinted glass pane fills the opening.
@export var show_floor_window: bool = false
@export var floor_window_size: Vector2 = Vector2(3.0, 3.0)
@export var floor_window_offset: Vector2 = Vector2(0.0, 0.0) # x,z offset of the centre

@export_group("Sliding door")
## Working sliding door with proximity sensor on the upper frame.
## Two panels slide outward when a body enters the sensor radius.
@export var show_sliding_door: bool = true
## Which wall hosts the door. "north"=-Z front, "south"=+Z back,
## "east"=+X, "west"=-X. Default "north" puts the door on the
## front (signage-side) wall, matching the large front_window so
## the front face reads as "glass wall + glass door".
## Default = "south" (back / +Z wall). Convention: the door is on the
## same wall as the large picture window — entering player sees the
## biome through the glass beside / above them.
@export var door_wall: String = "south"
@export var door_width: float = 1.4
@export var door_height: float = 2.2
## Distance in metres at which the sliding door triggers open. Default
## 1.0m so the door stays closed unless the player walks right up to it.
@export var door_sensor_radius: float = 1.0
@export var door_open_offset: float = 0.7
## If true, build ONE sliding panel of the full door width that slides
## to one side (left by default) instead of two panels meeting at the
## centre. Cleaner / more residential look. The sensor handler still
## opens / closes automatically.
@export var single_door: bool = true
## Offset of the door along its host wall, in metres. 0 = centred.
## Positive = +X direction on N/S walls or +Z on E/W walls. Negative =
## opposite. Clamped to leave at least 0.2m wall on each side.
@export var door_offset_x: float = 0.0

@export_group("Entry stairs")
## A short flight of steps OUTSIDE the door that descends from the
## lab floor down to the grid surface. Bridges the typical 0.5 m
## elevation so the player walks UP into the lab.
@export var show_stairs: bool = true
## Total vertical drop the stairs cover, in metres. Should equal the
## elevation of the lab floor above the grid surface (default 0.5).
@export var stairs_drop: float = 0.5
## Number of step risers. 2–4 is plausible for a 0.5 m drop.
@export var stairs_step_count: int = 3
## Horizontal depth of each step tread, in metres.
@export var stairs_step_depth: float = 0.32
## Width of the stair flight. Defaults to ~1.5× door_width so the
## landing reads as a small porch.
@export var stairs_width: float = 0.0  # 0 = auto = door_width * 1.5
@export var stairs_color: Color = Color(0.30, 0.30, 0.34)
## If true, build a smooth sloped ramp instead of stepped stairs. Same
## drop / width / outward direction. Useful for accessibility, transport
## carts, or just a different visual language.
@export var use_ramp: bool = false
@export var ramp_length: float = 1.2  # how far the ramp extends outward

@export_group("Wall bands")
## Horizontal trim strips on every wall: a HEADER along the top edge,
## a FOOTER along the bottom edge, and an optional MID-BAND between
## them. Each band is a thin box pulled slightly into the room so it
## reads as cladding / wainscot / accent stripe against the wall.
## The look is HL2 / Black Mesa: vent-style footer, accent-coloured
## header, tile/concrete mid-band.
@export var show_wall_header: bool = true
@export var wall_header_height: float = 0.18
@export var wall_header_color: Color = Color(0.32, 0.36, 0.34)

@export var show_wall_footer: bool = true
@export var wall_footer_height: float = 0.22
@export var wall_footer_color: Color = Color(0.20, 0.22, 0.24)

## Optional mid-band — sits at wall_band_y_centre (defaults to chair
## rail / wainscot height). Off by default.
@export var show_wall_band: bool = false
@export var wall_band_y_centre: float = 1.2
@export var wall_band_height: float = 0.15
@export var wall_band_color: Color = Color(0.16, 0.42, 0.62)

@export_group("Ceiling")
## "tile_grid" = the default; "exposed" = visible cable trays + light fixtures;
## "skylight" = bright panels with frosted glass look.
@export var ceiling_style: String = "tile_grid"

@export_group("Ceiling fixtures")
## Procedural ceiling-mounted props (vents, sprinklers, smoke sensors,
## speakers, light panels) distributed deterministically across the
## ceiling using ceiling_fixtures_seed. Each type's count is independent.
## Layout: tile grid cells sized by ceiling_tile_size; each fixture
## sits at the EXACT centre of its grid cell (no jitter).
@export var show_ceiling_fixtures: bool = true
@export var ceiling_fixtures_seed: int = 42
@export_range(0, 12) var ceiling_vent_count: int = 2
@export_range(0, 12) var ceiling_sprinkler_count: int = 3
@export_range(0, 12) var ceiling_sensor_count: int = 2
@export_range(0, 12) var ceiling_speaker_count: int = 1
@export_range(0, 12) var ceiling_light_count: int = 4
## Target acoustic-tile size for the ceiling grid. Actual cell size is
## derived so an integer number of cells fits the room exactly.
@export_range(0.5, 2.5, 0.1) var ceiling_tile_size: float = 1.2

# ── Multi-element arrays (IKEA mode) ──────────────────────────────────
# When these arrays are non-empty, lab_room uses them INSTEAD of the
# single door_wall / show_front_window / show_back_window / show_stairs
# config. Each entry is a Dictionary with at least { wall, offset_x }.
# Populated by lab_loader from the lab JSON's doors[] / windows[] /
# stairs[] arrays. Stored as runtime state, not @export — they're
# defined per-lab, not per-scene-instance.
var doors_cfg: Array = []
var windows_cfg: Array = []
var stairs_cfg: Array = []

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
	# After the room is built and the lab has been added to its parent
	# (so global_position is valid), walk all wall ShaderMaterials and
	# tell them where the lab sits in world Y. Deferred so the grid
	# system has finished positioning us.
	call_deferred("_patch_band_shader_world_y_offset")


func _read_metadata_overrides() -> void:
	# Strings — direct mapping.
	if has_meta("config_signage_top"):
		signage_top = str(get_meta("config_signage_top"))
	if has_meta("config_signage_sub"):
		signage_sub = str(get_meta("config_signage_sub"))
	if has_meta("config_annotation_top"):
		annotation_top = str(get_meta("config_annotation_top"))
	if has_meta("config_annotation_bottom"):
		annotation_bottom = str(get_meta("config_annotation_bottom"))
	if has_meta("config_mounted_artifact_scene"):
		mounted_artifact_scene = str(get_meta("config_mounted_artifact_scene"))
	if has_meta("config_mounted_lab_json"):
		mounted_lab_json = str(get_meta("config_mounted_lab_json"))

	# If a lab JSON is set, lift its `lab_room` block into our config
	# metadata BEFORE the rest of the overrides run. This lets the lab
	# JSON (the source of truth saved by /lab-editor) control room
	# dimensions, door wall + offset, window sizes, stairs/ramp etc.
	# Token-level configs still win because they are applied after.
	if mounted_lab_json != "":
		_lift_lab_room_block_into_meta(mounted_lab_json)

	# Colors as "r,g,b" strings.
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_floor_color"):
		floor_color = _parse_color(str(get_meta("config_floor_color")), floor_color)
	if has_meta("config_wall_color"):
		wall_color = _parse_color(str(get_meta("config_wall_color")), wall_color)

	# Floats / ints.
	if has_meta("config_room_width"):
		room_width = float(str(get_meta("config_room_width")))
	if has_meta("config_room_depth"):
		room_depth = float(str(get_meta("config_room_depth")))
	if has_meta("config_room_height"):
		room_height = float(str(get_meta("config_room_height")))
	if has_meta("config_light_warmth"):
		light_warmth = clampf(float(str(get_meta("config_light_warmth"))), 0.0, 1.0)

	# New: wall pattern / observation window / ceiling style.
	if has_meta("config_wall_pattern"):
		wall_pattern = str(get_meta("config_wall_pattern"))
	if has_meta("config_panel_columns"):
		panel_columns = int(str(get_meta("config_panel_columns")))
	if has_meta("config_seam_color"):
		seam_color = _parse_color(str(get_meta("config_seam_color")), seam_color)
	if has_meta("config_show_observation_window"):
		show_observation_window = bool(get_meta("config_show_observation_window"))
	if has_meta("config_window_wall"):
		window_wall = str(get_meta("config_window_wall"))
	if has_meta("config_ceiling_style"):
		ceiling_style = str(get_meta("config_ceiling_style"))

	# New: forward/back windows + sliding door.
	if has_meta("config_show_back_window"):
		show_back_window = _parse_bool(str(get_meta("config_show_back_window")), show_back_window)
	if has_meta("config_back_window_size"):
		back_window_size = _parse_vec2(str(get_meta("config_back_window_size")), back_window_size)
	if has_meta("config_back_window_offset_x"):
		back_window_offset_x = float(str(get_meta("config_back_window_offset_x")))
	if has_meta("config_show_front_window"):
		show_front_window = _parse_bool(str(get_meta("config_show_front_window")), show_front_window)
	if has_meta("config_front_window_size"):
		front_window_size = _parse_vec2(str(get_meta("config_front_window_size")), front_window_size)
	if has_meta("config_front_window_offset_x"):
		front_window_offset_x = float(str(get_meta("config_front_window_offset_x")))
	if has_meta("config_front_window_y"):
		front_window_y = float(str(get_meta("config_front_window_y")))
	if has_meta("config_show_floor_window"):
		show_floor_window = _parse_bool(str(get_meta("config_show_floor_window")), show_floor_window)
	if has_meta("config_floor_window_size"):
		floor_window_size = _parse_vec2(str(get_meta("config_floor_window_size")), floor_window_size)
	if has_meta("config_floor_window_offset"):
		floor_window_offset = _parse_vec2(str(get_meta("config_floor_window_offset")), floor_window_offset)
	if has_meta("config_show_sliding_door"):
		show_sliding_door = _parse_bool(str(get_meta("config_show_sliding_door")), show_sliding_door)
	if has_meta("config_door_wall"):
		door_wall = str(get_meta("config_door_wall"))
	if has_meta("config_door_width"):
		door_width = float(str(get_meta("config_door_width")))
	if has_meta("config_door_height"):
		door_height = float(str(get_meta("config_door_height")))
	if has_meta("config_door_sensor_radius"):
		door_sensor_radius = float(str(get_meta("config_door_sensor_radius")))
	if has_meta("config_door_open_offset"):
		door_open_offset = float(str(get_meta("config_door_open_offset")))
	if has_meta("config_door_offset_x"):
		door_offset_x = float(str(get_meta("config_door_offset_x")))
	# Entry stairs / ramp config — overrides for the lab editor.
	if has_meta("config_show_stairs"):
		show_stairs = _parse_bool(str(get_meta("config_show_stairs")), show_stairs)
	if has_meta("config_stairs_drop"):
		stairs_drop = float(str(get_meta("config_stairs_drop")))
	if has_meta("config_stairs_step_count"):
		stairs_step_count = int(str(get_meta("config_stairs_step_count")))
	if has_meta("config_stairs_step_depth"):
		stairs_step_depth = float(str(get_meta("config_stairs_step_depth")))
	if has_meta("config_stairs_width"):
		stairs_width = float(str(get_meta("config_stairs_width")))
	if has_meta("config_use_ramp"):
		use_ramp = _parse_bool(str(get_meta("config_use_ramp")), use_ramp)
	if has_meta("config_ramp_length"):
		ramp_length = float(str(get_meta("config_ramp_length")))
	# Wall band config (header / footer / optional mid-band).
	if has_meta("config_show_wall_header"):
		show_wall_header = _parse_bool(str(get_meta("config_show_wall_header")), show_wall_header)
	if has_meta("config_wall_header_height"):
		wall_header_height = float(str(get_meta("config_wall_header_height")))
	if has_meta("config_wall_header_color"):
		wall_header_color = _parse_color(str(get_meta("config_wall_header_color")), wall_header_color)
	if has_meta("config_show_wall_footer"):
		show_wall_footer = _parse_bool(str(get_meta("config_show_wall_footer")), show_wall_footer)
	if has_meta("config_wall_footer_height"):
		wall_footer_height = float(str(get_meta("config_wall_footer_height")))
	if has_meta("config_wall_footer_color"):
		wall_footer_color = _parse_color(str(get_meta("config_wall_footer_color")), wall_footer_color)
	if has_meta("config_show_wall_band"):
		show_wall_band = _parse_bool(str(get_meta("config_show_wall_band")), show_wall_band)
	if has_meta("config_wall_band_y_centre"):
		wall_band_y_centre = float(str(get_meta("config_wall_band_y_centre")))
	if has_meta("config_wall_band_height"):
		wall_band_height = float(str(get_meta("config_wall_band_height")))
	if has_meta("config_wall_band_color"):
		wall_band_color = _parse_color(str(get_meta("config_wall_band_color")), wall_band_color)
	if has_meta("config_show_plinth"):
		show_plinth = _parse_bool(str(get_meta("config_show_plinth")), show_plinth)
	# Ceiling fixtures
	if has_meta("config_show_ceiling_fixtures"):
		show_ceiling_fixtures = _parse_bool(str(get_meta("config_show_ceiling_fixtures")), show_ceiling_fixtures)
	if has_meta("config_ceiling_fixtures_seed"):
		ceiling_fixtures_seed = int(str(get_meta("config_ceiling_fixtures_seed")))
	if has_meta("config_ceiling_vent_count"):
		ceiling_vent_count = int(str(get_meta("config_ceiling_vent_count")))
	if has_meta("config_ceiling_sprinkler_count"):
		ceiling_sprinkler_count = int(str(get_meta("config_ceiling_sprinkler_count")))
	if has_meta("config_ceiling_sensor_count"):
		ceiling_sensor_count = int(str(get_meta("config_ceiling_sensor_count")))
	if has_meta("config_ceiling_speaker_count"):
		ceiling_speaker_count = int(str(get_meta("config_ceiling_speaker_count")))
	if has_meta("config_ceiling_light_count"):
		ceiling_light_count = int(str(get_meta("config_ceiling_light_count")))
	if has_meta("config_ceiling_tile_size"):
		ceiling_tile_size = float(str(get_meta("config_ceiling_tile_size")))
	# Legacy passthrough: explicit "false" disables the default full-glass back wall.
	if has_meta("config_south_wall_is_glass"):
		south_wall_is_glass = _parse_bool(str(get_meta("config_south_wall_is_glass")), south_wall_is_glass)


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
		# Rebuild created new wall materials — re-patch the world-Y offset.
		call_deferred("_patch_band_shader_world_y_offset")


## Read the lab_room block from the lab JSON and copy each key into
## our `config_<key>` metadata. Keys that already have meta set (e.g.
## from interactables-token configs) are NOT overwritten — tokens win
## over JSON. Arrays like [w, h] are serialised as "w,h" strings so the
## existing _parse_vec2 / _parse_color helpers can read them.
func _lift_lab_room_block_into_meta(json_path: String) -> void:
	if not FileAccess.file_exists(json_path):
		return
	var raw: String = FileAccess.get_file_as_string(json_path)
	if raw.is_empty():
		return
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return
	var lab_room_cfg = parsed.get("lab_room", null)
	if not (lab_room_cfg is Dictionary):
		return
	for k in lab_room_cfg.keys():
		var meta_key: String = "config_%s" % str(k)
		# Token configs (already in meta) win over JSON.
		if has_meta(meta_key):
			continue
		var v = lab_room_cfg[k]
		if v is Array:
			var parts: Array = []
			for n in v:
				parts.append(str(n))
			set_meta(meta_key, ",".join(PackedStringArray(parts)))
		else:
			set_meta(meta_key, v)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_room() -> void:
	_built = true
	_build_floor()
	_build_walls()
	_build_ceiling()
	_build_ceiling_fixtures()
	# Wall bands are PAINTED on the wall material via
	# lab_wall_bands.gdshader. The shader uses (world_y - lab_world_y)
	# so band thresholds in lab-local terms work regardless of where
	# the grid system places the lab. The lab_world_y uniform is
	# patched in _ready (deferred so global_position is valid).
	# Old _build_wall_bands() mesh-strip path remains in the file as
	# a fallback but is no longer called.
	_build_accent_strip()
	_build_plinth_and_mount()
	_build_signage()
	if show_wall_annotations:
		_build_wall_annotations()
	_build_lighting()
	_build_colliders()
	if show_stairs and show_sliding_door:
		_build_stairs()
	if mounted_artifact_scene != "":
		_instantiate_mounted_artifact()
	if mounted_lab_json != "":
		_instantiate_mounted_lab_json()


# ── Colliders ─────────────────────────────────────────────────────────
# Build StaticBody3D + CollisionShape3D children for floor / ceiling /
# walls so the VR rig and desktop player can walk on the lab floor and
# bump into the walls. The sliding door's wall is split into two
# segments with a gap matching door_width so the player can step
# through it; the door panels themselves are decorative (no collision).
# Windows are left solid because they're glass — visible but not
# walkable. The floor window (if any) is also left solid: the glass
# pane below the player carries them.

const COLLIDER_THICK: float = 0.06

func _build_colliders() -> void:
	var body := StaticBody3D.new()
	body.name = "LabColliders"
	# Layer 1 = world / static geometry (matches Godot's default
	# walkable surfaces). Mask 0 because we only block, never query.
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	var hw := room_width * 0.5
	var hd := room_depth * 0.5
	var rh := room_height

	# Floor — thin slab just below y=0 so the top surface is flush with
	# the lab floor plane.
	_add_box_collider(body, "FloorCollider",
		Vector3(0, -COLLIDER_THICK * 0.5, 0),
		Vector3(room_width, COLLIDER_THICK, room_depth))

	# Ceiling — thin slab at y=room_height.
	_add_box_collider(body, "CeilingCollider",
		Vector3(0, rh + COLLIDER_THICK * 0.5, 0),
		Vector3(room_width, COLLIDER_THICK, room_depth))

	# Walls — one per side. If the sliding door is enabled on this wall,
	# split into two segments leaving a door-shaped gap.
	# Wall conventions: north=-Z (front), south=+Z (back),
	# east=+X, west=-X. (Matches @export door_wall doc.)
	_add_wall_collider(body, "WallNorth", "north", hw, hd, rh)
	_add_wall_collider(body, "WallSouth", "south", hw, hd, rh)
	_add_wall_collider(body, "WallEast",  "east",  hw, hd, rh)
	_add_wall_collider(body, "WallWest",  "west",  hw, hd, rh)


func _add_box_collider(parent: Node, n: String, pos: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	cs.name = n
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = pos
	parent.add_child(cs)


func _add_wall_collider(body: StaticBody3D, n: String, side: String,
		hw: float, hd: float, rh: float) -> void:
	# Compute wall centre + axis along which the wall extends.
	# axis_len = wall length on its long axis (the room dimension parallel
	# to the wall). For north/south walls that's room_width (X).
	# For east/west walls that's room_depth (Z).
	var centre: Vector3
	var size: Vector3
	var horizontal_axis_len: float
	match side:
		"north":
			centre = Vector3(0, rh * 0.5, -hd)
			size = Vector3(hw * 2.0, rh, COLLIDER_THICK)
			horizontal_axis_len = hw * 2.0
		"south":
			centre = Vector3(0, rh * 0.5, hd)
			size = Vector3(hw * 2.0, rh, COLLIDER_THICK)
			horizontal_axis_len = hw * 2.0
		"east":
			centre = Vector3(hw, rh * 0.5, 0)
			size = Vector3(COLLIDER_THICK, rh, hd * 2.0)
			horizontal_axis_len = hd * 2.0
		"west":
			centre = Vector3(-hw, rh * 0.5, 0)
			size = Vector3(COLLIDER_THICK, rh, hd * 2.0)
			horizontal_axis_len = hd * 2.0
		_:
			return

	# If the door is on this wall, split into two segments around the
	# door gap. Door position along the wall is door_offset_x, clamped
	# so the door never punches outside the wall.
	if show_sliding_door and door_wall == side:
		var gap_w: float = door_width
		var half_axis: float = horizontal_axis_len * 0.5
		var min_edge: float = 0.2  # keep at least 20cm wall on each side
		var max_off: float = max(0.0, half_axis - gap_w * 0.5 - min_edge)
		var off: float = clamp(door_offset_x, -max_off, max_off)
		# Left + right segment widths (each measured from the wall's
		# end up to the door edge).
		var left_seg: float = half_axis + off - gap_w * 0.5
		var right_seg: float = half_axis - off - gap_w * 0.5
		if left_seg <= 0.01 and right_seg <= 0.01:
			# Door fills the wall — fall back to no collider on this side.
			return
		var lintel_h: float = max(0.0, rh - door_height)
		# Centre of each segment along the wall's long axis.
		var left_centre_axis: float = -half_axis + left_seg * 0.5
		var right_centre_axis: float = half_axis - right_seg * 0.5
		match side:
			"north", "south":
				if left_seg > 0.01:
					_add_box_collider(body, "%s_L" % n,
						Vector3(left_centre_axis, centre.y, centre.z),
						Vector3(left_seg, rh, COLLIDER_THICK))
				if right_seg > 0.01:
					_add_box_collider(body, "%s_R" % n,
						Vector3(right_centre_axis, centre.y, centre.z),
						Vector3(right_seg, rh, COLLIDER_THICK))
				if lintel_h > 0.01:
					_add_box_collider(body, "%s_Lintel" % n,
						Vector3(off, door_height + lintel_h * 0.5, centre.z),
						Vector3(gap_w, lintel_h, COLLIDER_THICK))
			"east", "west":
				if left_seg > 0.01:
					_add_box_collider(body, "%s_L" % n,
						Vector3(centre.x, centre.y, left_centre_axis),
						Vector3(COLLIDER_THICK, rh, left_seg))
				if right_seg > 0.01:
					_add_box_collider(body, "%s_R" % n,
						Vector3(centre.x, centre.y, right_centre_axis),
						Vector3(COLLIDER_THICK, rh, right_seg))
				if lintel_h > 0.01:
					_add_box_collider(body, "%s_Lintel" % n,
						Vector3(centre.x, door_height + lintel_h * 0.5, off),
						Vector3(COLLIDER_THICK, lintel_h, gap_w))
	else:
		_add_box_collider(body, n, centre, size)


# ── Stairs ────────────────────────────────────────────────────────────
# Build a short flight outside the door that descends to the grid
# surface. Each step is a box mesh + collider. Steps recede away from
# the door (along the wall-outward normal) and drop by stairs_drop /
# stairs_step_count each.

func _build_stairs() -> void:
	if stairs_drop <= 0.0:
		return
	if use_ramp:
		_build_ramp()
		return
	if stairs_step_count <= 0:
		return
	var step_w: float = stairs_width if stairs_width > 0.01 else door_width * 1.5
	var step_h: float = stairs_drop / float(stairs_step_count)
	var step_d: float = stairs_step_depth

	var hw := room_width * 0.5
	var hd := room_depth * 0.5
	var outward: Vector3
	var origin: Vector3
	match door_wall:
		"north":
			outward = Vector3(0, 0, -1)
			origin = Vector3(0, 0, -hd)
		"south":
			outward = Vector3(0, 0, 1)
			origin = Vector3(0, 0, hd)
		"east":
			outward = Vector3(1, 0, 0)
			origin = Vector3(hw, 0, 0)
		"west":
			outward = Vector3(-1, 0, 0)
			origin = Vector3(-hw, 0, 0)
		_:
			return

	var stairs_root := Node3D.new()
	stairs_root.name = "EntryStairs"
	add_child(stairs_root)

	var body := StaticBody3D.new()
	body.name = "StairsCollider"
	body.collision_layer = 1
	body.collision_mask = 0
	stairs_root.add_child(body)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = stairs_color
	mat.roughness = 0.6
	mat.metallic = 0.2

	# Step i = 0 is closest to door (highest, just below lab floor).
	# Step i = stairs_step_count - 1 is farthest, at grid surface level.
	# Each step's TOP surface = lab_floor - i*step_h.
	# Apply door offset so stairs sit directly in front of the door,
	# not always at wall centre.
	var off_vec: Vector3 = Vector3.ZERO
	match door_wall:
		"north", "south":
			off_vec = Vector3(door_offset_x, 0, 0)
		"east", "west":
			off_vec = Vector3(0, 0, door_offset_x)
	for i in range(stairs_step_count):
		var d: float = step_d * 0.5 + step_d * float(i)
		var step_centre_y: float = -step_h * 0.5 - step_h * float(i)
		var local_pos: Vector3 = origin + outward * d + off_vec
		local_pos.y = step_centre_y

		var step := MeshInstance3D.new()
		step.name = "Step%d" % i
		var bm := BoxMesh.new()
		if outward.x != 0:
			bm.size = Vector3(step_d, step_h, step_w)
		else:
			bm.size = Vector3(step_w, step_h, step_d)
		step.mesh = bm
		step.material_override = mat
		step.position = local_pos
		stairs_root.add_child(step)

		var cs := CollisionShape3D.new()
		cs.name = "StepCol%d" % i
		var box := BoxShape3D.new()
		box.size = bm.size
		cs.shape = box
		cs.position = local_pos
		body.add_child(cs)


# Sloped ramp variant of the entry. A single tilted box mesh +
# collider that bridges from the lab floor (y=0) down to the grid
# surface (y=-stairs_drop) over `ramp_length` meters outward from the
# door wall. Width matches stairs_width / auto.
func _build_ramp() -> void:
	if stairs_drop <= 0.0 or ramp_length <= 0.01:
		return
	var ramp_w: float = stairs_width if stairs_width > 0.01 else door_width * 1.5
	var hw := room_width * 0.5
	var hd := room_depth * 0.5
	var outward: Vector3
	var origin: Vector3
	match door_wall:
		"north":
			outward = Vector3(0, 0, -1); origin = Vector3(0, 0, -hd)
		"south":
			outward = Vector3(0, 0, 1); origin = Vector3(0, 0, hd)
		"east":
			outward = Vector3(1, 0, 0); origin = Vector3(hw, 0, 0)
		"west":
			outward = Vector3(-1, 0, 0); origin = Vector3(-hw, 0, 0)
		_:
			return

	var off_vec: Vector3 = Vector3.ZERO
	match door_wall:
		"north", "south": off_vec = Vector3(door_offset_x, 0, 0)
		"east", "west":   off_vec = Vector3(0, 0, door_offset_x)

	# Hypotenuse + tilt angle.
	var hyp: float = sqrt(ramp_length * ramp_length + stairs_drop * stairs_drop)
	var tilt: float = atan2(stairs_drop, ramp_length)
	# Centre point: midpoint between (origin) and (origin + outward*ramp_length, y=-drop).
	var centre: Vector3 = origin + outward * (ramp_length * 0.5) + off_vec
	centre.y = -stairs_drop * 0.5

	var ramp_root := Node3D.new()
	ramp_root.name = "EntryRamp"
	add_child(ramp_root)

	var body := StaticBody3D.new()
	body.name = "RampCollider"
	body.collision_layer = 1
	body.collision_mask = 0
	ramp_root.add_child(body)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = stairs_color
	mat.roughness = 0.65
	mat.metallic = 0.2

	var ramp := MeshInstance3D.new()
	ramp.name = "Ramp"
	var bm := BoxMesh.new()
	# Box oriented along its long axis = hyp; tilt it about an axis
	# perpendicular to outward direction.
	if abs(outward.x) > 0.5:
		# Outward along ±X — tilt about Z axis. The ramp's long axis
		# is along X after rotation.
		bm.size = Vector3(hyp, 0.08, ramp_w)
		ramp.mesh = bm
		ramp.rotation = Vector3(0, 0, sign(outward.x) * -tilt)
	else:
		# Outward along ±Z — tilt about X axis. Long axis along Z.
		bm.size = Vector3(ramp_w, 0.08, hyp)
		ramp.mesh = bm
		ramp.rotation = Vector3(sign(outward.z) * tilt, 0, 0)
	ramp.material_override = mat
	ramp.position = centre
	ramp_root.add_child(ramp)

	# Collider mirrors the visual.
	var cs := CollisionShape3D.new()
	cs.name = "RampCol"
	var box := BoxShape3D.new()
	box.size = bm.size
	cs.shape = box
	cs.transform = ramp.transform
	body.add_child(cs)


# ── Floor ─────────────────────────────────────────────────────────────

func _build_floor() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = floor_color
	mat.roughness = 0.6
	mat.metallic = 0.05

	if show_floor_window:
		_build_floor_with_window(mat)
	else:
		var floor_node := MeshInstance3D.new()
		floor_node.name = "Floor"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(room_width, FLOOR_THICKNESS, room_depth)
		floor_node.mesh = mesh
		floor_node.material_override = mat
		# Place floor centered at origin, top surface at y=0.
		floor_node.position = Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0)
		add_child(floor_node)

	if show_floor_tiles:
		_build_floor_tile_lines()


## Build the floor as four strips around a central cutout, with a
## tinted glass pane filling the opening. Used when show_floor_window
## is true — the lab is built over a coordinate in the grid below and
## the player can see down through the floor.
func _build_floor_with_window(mat: Material) -> void:
	var win_w: float = clamp(floor_window_size.x, 0.4, max(0.4, room_width - 0.4))
	var win_d: float = clamp(floor_window_size.y, 0.4, max(0.4, room_depth - 0.4))
	var cx: float = clamp(floor_window_offset.x, -room_width * 0.5 + win_w * 0.5 + 0.1, room_width * 0.5 - win_w * 0.5 - 0.1)
	var cz: float = clamp(floor_window_offset.y, -room_depth * 0.5 + win_d * 0.5 + 0.1, room_depth * 0.5 - win_d * 0.5 - 0.1)

	# Window bounds in lab-local space
	var win_x_min := cx - win_w * 0.5
	var win_x_max := cx + win_w * 0.5
	var win_z_min := cz - win_d * 0.5
	var win_z_max := cz + win_d * 0.5

	var floor_y := -FLOOR_THICKNESS * 0.5

	# West strip: x in [-W/2, win_x_min]
	var w_west: float = win_x_min - (-room_width * 0.5)
	if w_west > 0.001:
		var n := MeshInstance3D.new()
		n.name = "FloorWest"
		var m := BoxMesh.new()
		m.size = Vector3(w_west, FLOOR_THICKNESS, room_depth)
		n.mesh = m
		n.material_override = mat
		n.position = Vector3(-room_width * 0.5 + w_west * 0.5, floor_y, 0.0)
		add_child(n)

	# East strip: x in [win_x_max, W/2]
	var w_east: float = (room_width * 0.5) - win_x_max
	if w_east > 0.001:
		var n := MeshInstance3D.new()
		n.name = "FloorEast"
		var m := BoxMesh.new()
		m.size = Vector3(w_east, FLOOR_THICKNESS, room_depth)
		n.mesh = m
		n.material_override = mat
		n.position = Vector3(room_width * 0.5 - w_east * 0.5, floor_y, 0.0)
		add_child(n)

	# North strip (between west/east strips, z in [-D/2, win_z_min])
	var w_inner: float = win_x_max - win_x_min
	var d_north: float = win_z_min - (-room_depth * 0.5)
	if d_north > 0.001 and w_inner > 0.001:
		var n := MeshInstance3D.new()
		n.name = "FloorNorth"
		var m := BoxMesh.new()
		m.size = Vector3(w_inner, FLOOR_THICKNESS, d_north)
		n.mesh = m
		n.material_override = mat
		n.position = Vector3(cx, floor_y, -room_depth * 0.5 + d_north * 0.5)
		add_child(n)

	# South strip (between west/east strips, z in [win_z_max, D/2])
	var d_south: float = (room_depth * 0.5) - win_z_max
	if d_south > 0.001 and w_inner > 0.001:
		var n := MeshInstance3D.new()
		n.name = "FloorSouth"
		var m := BoxMesh.new()
		m.size = Vector3(w_inner, FLOOR_THICKNESS, d_south)
		n.mesh = m
		n.material_override = mat
		n.position = Vector3(cx, floor_y, room_depth * 0.5 - d_south * 0.5)
		add_child(n)

	# Glass pane sitting in the opening, slightly above floor top so
	# the player walking over it doesn't fall through.
	var glass := MeshInstance3D.new()
	glass.name = "FloorWindow"
	var gm := BoxMesh.new()
	gm.size = Vector3(w_inner, FLOOR_THICKNESS * 0.5, win_d)
	glass.mesh = gm
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.55, 0.78, 0.95, 0.35)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.12
	glass_mat.metallic = 0.0
	glass_mat.refraction_enabled = false
	glass.material_override = glass_mat
	glass.position = Vector3(cx, -FLOOR_THICKNESS * 0.25, cz)
	add_child(glass)

	# Frame strips ringing the window opening.
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.12, 0.13, 0.16)
	frame_mat.roughness = 0.4
	frame_mat.metallic = 0.55
	var ft := 0.05
	# North/south frames
	var fn := MeshInstance3D.new()
	var fnm := BoxMesh.new()
	fnm.size = Vector3(w_inner + ft * 2, ft, ft)
	fn.mesh = fnm
	fn.material_override = frame_mat
	fn.position = Vector3(cx, ft * 0.5, win_z_min - ft * 0.5)
	add_child(fn)
	var fs := MeshInstance3D.new()
	var fsm := BoxMesh.new()
	fsm.size = Vector3(w_inner + ft * 2, ft, ft)
	fs.mesh = fsm
	fs.material_override = frame_mat
	fs.position = Vector3(cx, ft * 0.5, win_z_max + ft * 0.5)
	add_child(fs)
	# East/west frames
	var fe := MeshInstance3D.new()
	var fem := BoxMesh.new()
	fem.size = Vector3(ft, ft, win_d)
	fe.mesh = fem
	fe.material_override = frame_mat
	fe.position = Vector3(win_x_max + ft * 0.5, ft * 0.5, cz)
	add_child(fe)
	var fwf := MeshInstance3D.new()
	var fwm := BoxMesh.new()
	fwm.size = Vector3(ft, ft, win_d)
	fwf.mesh = fwm
	fwf.material_override = frame_mat
	fwf.position = Vector3(win_x_min - ft * 0.5, ft * 0.5, cz)
	add_child(fwf)


func _build_floor_tile_lines() -> void:
	# Thin grout-colored boxes overlaid on the floor — cheap tile grid
	# without baking a texture. floor_tile_count divisions per side.
	# If a floor window is enabled, lines that would cross the window
	# are split into two segments so nothing visually bridges the glass.
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

	# Floor-window bounds (lab-local) — used to break lines that cross it.
	var win_active: bool = show_floor_window
	var fw_x_min: float = 0.0
	var fw_x_max: float = 0.0
	var fw_z_min: float = 0.0
	var fw_z_max: float = 0.0
	if win_active:
		var fw_w: float = clamp(floor_window_size.x, 0.4, max(0.4, room_width - 0.4))
		var fw_d: float = clamp(floor_window_size.y, 0.4, max(0.4, room_depth - 0.4))
		var fw_cx: float = clamp(floor_window_offset.x,
			-room_width * 0.5 + fw_w * 0.5 + 0.1, room_width * 0.5 - fw_w * 0.5 - 0.1)
		var fw_cz: float = clamp(floor_window_offset.y,
			-room_depth * 0.5 + fw_d * 0.5 + 0.1, room_depth * 0.5 - fw_d * 0.5 - 0.1)
		fw_x_min = fw_cx - fw_w * 0.5
		fw_x_max = fw_cx + fw_w * 0.5
		fw_z_min = fw_cz - fw_d * 0.5
		fw_z_max = fw_cz + fw_d * 0.5

	# Helper: add a grout line segment from (x_min, x_max) along X,
	# at z=zc. Or from (z_min, z_max) along Z, at x=xc.
	for i in range(1, floor_tile_count):
		var z := -room_depth * 0.5 + i * cell_z
		# Horizontal line at z. If the window covers z, split into two segments.
		if win_active and z > fw_z_min and z < fw_z_max:
			# Left segment: from -W/2 to fw_x_min
			var lw: float = fw_x_min - (-room_width * 0.5)
			if lw > 0.01:
				_add_grout(grout, mat,
					Vector3(-room_width * 0.5 + lw * 0.5, floor_top_y, z),
					Vector3(lw, line_height, line_thickness))
			# Right segment: fw_x_max to W/2
			var rw: float = (room_width * 0.5) - fw_x_max
			if rw > 0.01:
				_add_grout(grout, mat,
					Vector3(room_width * 0.5 - rw * 0.5, floor_top_y, z),
					Vector3(rw, line_height, line_thickness))
		else:
			_add_grout(grout, mat,
				Vector3(0.0, floor_top_y, z),
				Vector3(room_width, line_height, line_thickness))

	for i in range(1, floor_tile_count):
		var x := -room_width * 0.5 + i * cell_x
		if win_active and x > fw_x_min and x < fw_x_max:
			var nd: float = fw_z_min - (-room_depth * 0.5)
			if nd > 0.01:
				_add_grout(grout, mat,
					Vector3(x, floor_top_y, -room_depth * 0.5 + nd * 0.5),
					Vector3(line_thickness, line_height, nd))
			var sd: float = (room_depth * 0.5) - fw_z_max
			if sd > 0.01:
				_add_grout(grout, mat,
					Vector3(x, floor_top_y, room_depth * 0.5 - sd * 0.5),
					Vector3(line_thickness, line_height, sd))
		else:
			_add_grout(grout, mat,
				Vector3(x, floor_top_y, 0.0),
				Vector3(line_thickness, line_height, room_depth))


func _add_grout(parent: Node3D, mat: Material,
		pos: Vector3, size: Vector3) -> void:
	var line := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	line.mesh = m
	line.material_override = mat
	line.position = pos
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(line)


# ── Walls ─────────────────────────────────────────────────────────────
# Naming convention: "front" = -Z (signage wall, where the player looks),
#                    "back"  = +Z (glass observation wall, player's side).

func _build_walls() -> void:
	var walls := Node3D.new()
	walls.name = "Walls"
	add_child(walls)

	var wall_mat := _make_wall_material()

	# Front wall (-Z, signage wall). If a front window is enabled,
	# build the wall in strips around the window opening; otherwise
	# a single solid panel. This mirrors the back-wall builder.
	if show_front_window:
		_build_front_solid_with_window(walls)
	else:
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

	# Front-wall window is now drawn by _build_front_solid_with_window
	# above (called when show_front_window is true and replaces the
	# solid front-wall panel).

	# Sliding door with proximity sensor.
	if show_sliding_door:
		_build_sliding_door(walls)

	# Panel seams overlaid on the walls (Portal 2 look)
	if wall_pattern == "panels":
		_build_panel_seams(walls)

	# Observation window — translucent emissive overlay on the chosen wall.
	if show_observation_window:
		_build_observation_window(walls)


const WALL_BAND_SHADER := preload("res://commons/artifacts/lab_room/lab_wall_bands.gdshader")

func _make_wall_material() -> Material:
	# Use the shader-painted band material when ANY band is enabled.
	# Bands are painted into the wall surface itself — they auto-conform
	# to whatever wall geometry exists (window strips, door cutouts,
	# side panels) and avoid the segment-bookkeeping the mesh-strip
	# path needs. lab_world_y uniform is patched in _ready (deferred).
	if show_wall_header or show_wall_footer or show_wall_band:
		return _make_band_shader_material()
	var mat := StandardMaterial3D.new()
	match wall_pattern:
		"concrete":
			mat.albedo_color = Color(0.55, 0.53, 0.50)
			mat.roughness = 0.85
			mat.metallic = 0.0
		"panels":
			mat.albedo_color = wall_color
			mat.roughness = 0.45
			mat.metallic = 0.02
		_:
			mat.albedo_color = wall_color
			mat.roughness = 0.65
			mat.metallic = 0.0
	return mat


# Build a ShaderMaterial bound to lab_wall_bands.gdshader with the
# current band config baked into its uniforms. Returned per call —
# the bands look identical on every wall but each strip can carry its
# own instance so a future variant could vary per surface.
func _make_band_shader_material() -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.shader = WALL_BAND_SHADER
	sm.set_shader_parameter("base_color", wall_color)
	sm.set_shader_parameter("wall_roughness", 0.6 if wall_pattern != "concrete" else 0.85)
	sm.set_shader_parameter("wall_metallic", 0.02 if wall_pattern == "panels" else 0.0)
	# Header
	sm.set_shader_parameter("header_on", show_wall_header and wall_header_height > 0.001)
	sm.set_shader_parameter("header_color", wall_header_color)
	sm.set_shader_parameter("header_y_min", room_height - wall_header_height)
	sm.set_shader_parameter("header_y_max", room_height)
	# Footer
	sm.set_shader_parameter("footer_on", show_wall_footer and wall_footer_height > 0.001)
	sm.set_shader_parameter("footer_color", wall_footer_color)
	sm.set_shader_parameter("footer_y_min", 0.0)
	sm.set_shader_parameter("footer_y_max", wall_footer_height)
	# Mid-band
	sm.set_shader_parameter("band_on", show_wall_band and wall_band_height > 0.001)
	sm.set_shader_parameter("band_color", wall_band_color)
	sm.set_shader_parameter("band_y_min", wall_band_y_centre - wall_band_height * 0.5)
	sm.set_shader_parameter("band_y_max", wall_band_y_centre + wall_band_height * 0.5)
	return sm


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
	# Build the +Z back wall as a solid panel split around the picture
	# window. The window can be OFFSET along x via back_window_offset_x.
	# If the door is on this wall too, the BOTTOM strip is also split
	# around the door footprint and the glass is built in pieces so the
	# door's column is wall-free (player can walk through). Reads as a
	# real building wall.
	var win_w: float = clamp(back_window_size.x, 0.5, max(0.5, room_width - 0.6))
	var win_h: float = clamp(back_window_size.y, 0.5, max(0.5, room_height - 1.0))
	var win_y: float = room_height * 0.5  # window centred vertically
	# Apply back_window_offset_x — clamp so window stays on the wall.
	var max_off: float = max(0.0, (room_width - win_w) * 0.5 - 0.1)
	var win_cx: float = clamp(back_window_offset_x, -max_off, max_off)
	var win_left_x: float = win_cx - win_w * 0.5
	var win_right_x: float = win_cx + win_w * 0.5
	var top_h: float = room_height - (win_y + win_h * 0.5)
	var bot_h: float = win_y - win_h * 0.5
	var z_plane: float = room_depth * 0.5 - WALL_THICKNESS * 0.5

	# Is the sliding door also on this (+Z south) wall?
	var door_here: bool = show_sliding_door and door_wall == "south"
	var dx_centre: float = door_offset_x
	var dh: float = door_height
	var dw: float = door_width
	var d_left: float = dx_centre - dw * 0.5
	var d_right: float = dx_centre + dw * 0.5
	# Is the door FULLY INSIDE the window's x-range? Only then do we
	# split the bottom strip + glass around it. If the door is outside
	# the window (in a side strip), it cuts the side strip instead.
	var door_in_win_x: bool = door_here \
		and d_left >= win_left_x - 0.001 \
		and d_right <= win_right_x + 0.001
	# Is the door entirely OUTSIDE the window's x-range on one side?
	var door_in_left_strip: bool = door_here and d_right < win_left_x
	var door_in_right_strip: bool = door_here and d_left > win_right_x

	var wall_mat := _make_wall_material()

	# ── Side strips ─────────────────────────────────────────────────
	# Left strip: from wall left edge (-W/2) to window's left x.
	# Right strip: from window's right x to wall right edge (+W/2).
	# Either may be 0 if the window touches that wall edge.
	if (win_left_x - (-room_width * 0.5)) > 0.001:
		_build_back_side_strip(parent, wall_mat, "BackWallLeft",
			-room_width * 0.5, win_left_x, z_plane,
			door_in_left_strip, d_left, d_right, dh)
	if (room_width * 0.5 - win_right_x) > 0.001:
		_build_back_side_strip(parent, wall_mat, "BackWallRight",
			win_right_x, room_width * 0.5, z_plane,
			door_in_right_strip, d_left, d_right, dh)

	# ── Bottom strip — sits at x = win_cx (centred under the window).
	#    Split around door only if door is inside the window's x-range.
	if bot_h > 0.001:
		if door_in_win_x:
			var bl_w: float = d_left - win_left_x
			if bl_w > 0.001:
				var bl := MeshInstance3D.new()
				bl.name = "BackWallBotLeft"
				var blm := BoxMesh.new()
				blm.size = Vector3(bl_w, bot_h, WALL_THICKNESS)
				bl.mesh = blm
				bl.material_override = wall_mat
				bl.position = Vector3(win_left_x + bl_w * 0.5, bot_h * 0.5, z_plane)
				parent.add_child(bl)
			var br_w: float = win_right_x - d_right
			if br_w > 0.001:
				var br := MeshInstance3D.new()
				br.name = "BackWallBotRight"
				var brm := BoxMesh.new()
				brm.size = Vector3(br_w, bot_h, WALL_THICKNESS)
				br.mesh = brm
				br.material_override = wall_mat
				br.position = Vector3(win_right_x - br_w * 0.5, bot_h * 0.5, z_plane)
				parent.add_child(br)
		else:
			var bot := MeshInstance3D.new()
			bot.name = "BackWallBot"
			var bm := BoxMesh.new()
			bm.size = Vector3(win_w, bot_h, WALL_THICKNESS)
			bot.mesh = bm
			bot.material_override = wall_mat
			bot.position = Vector3(win_cx, bot_h * 0.5, z_plane)
			parent.add_child(bot)

	# ── Top strip ───────────────────────────────────────────────────
	if top_h > 0.001:
		var top := MeshInstance3D.new()
		top.name = "BackWallTop"
		var tm := BoxMesh.new()
		tm.size = Vector3(win_w, top_h, WALL_THICKNESS)
		top.mesh = tm
		top.material_override = wall_mat
		top.position = Vector3(win_cx, room_height - top_h * 0.5, z_plane)
		parent.add_child(top)

	# ── Glass pane ─────────────────────────────────────────────────
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.78, 0.86, 0.94, 0.30)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.12
	glass_mat.metallic = 0.0
	glass_mat.refraction_enabled = false

	var win_bot: float = win_y - win_h * 0.5
	var win_top: float = win_y + win_h * 0.5

	if door_in_win_x and dh > win_bot:
		# Door pokes into the window area. Build glass in 3 pieces:
		# (a) above the door across full window width (centred at win_cx)
		# (b) left of door from win_bot to dh
		# (c) right of door from win_bot to dh
		var above_h: float = max(0.0, win_top - dh)
		if above_h > 0.001:
			var gA := MeshInstance3D.new()
			gA.name = "BackWindowGlassAbove"
			var gam := BoxMesh.new()
			gam.size = Vector3(win_w, above_h, WALL_THICKNESS * 0.5)
			gA.mesh = gam
			gA.material_override = glass_mat
			gA.position = Vector3(win_cx, dh + above_h * 0.5, z_plane)
			parent.add_child(gA)
		var side_h: float = max(0.0, dh - win_bot)
		if side_h > 0.001:
			var glL_w: float = d_left - win_left_x
			if glL_w > 0.001:
				var gL := MeshInstance3D.new()
				gL.name = "BackWindowGlassLeft"
				var glm := BoxMesh.new()
				glm.size = Vector3(glL_w, side_h, WALL_THICKNESS * 0.5)
				gL.mesh = glm
				gL.material_override = glass_mat
				gL.position = Vector3(win_left_x + glL_w * 0.5, win_bot + side_h * 0.5, z_plane)
				parent.add_child(gL)
			var glR_w: float = win_right_x - d_right
			if glR_w > 0.001:
				var gR := MeshInstance3D.new()
				gR.name = "BackWindowGlassRight"
				var grm := BoxMesh.new()
				grm.size = Vector3(glR_w, side_h, WALL_THICKNESS * 0.5)
				gR.mesh = grm
				gR.material_override = glass_mat
				gR.position = Vector3(win_right_x - glR_w * 0.5, win_bot + side_h * 0.5, z_plane)
				parent.add_child(gR)
	else:
		# No door on this wall (or door entirely below window) — single
		# rectangular glass pane at the window's offset position.
		var glass := MeshInstance3D.new()
		glass.name = "BackWindowGlass"
		var gm := BoxMesh.new()
		gm.size = Vector3(win_w, win_h, WALL_THICKNESS * 0.5)
		glass.mesh = gm
		glass.material_override = glass_mat
		glass.position = Vector3(win_cx, win_y, z_plane)
		parent.add_child(glass)

	# Window frame (visual trim around the glass opening, follows offset).
	_build_window_frame_strips(parent, "BackWindowFrame", win_w, win_h, Vector3(win_cx, win_y, z_plane), 0.0)


# Build one of the back-wall's side strips. If `door_in_this_strip` is
# true, split the strip into an upper segment (above the door) +
# two left/right segments around the door footprint, leaving a gap
# the player can walk through.
func _build_back_side_strip(parent: Node3D, mat: Material,
		strip_name: String,
		x_min: float, x_max: float, z_plane: float,
		door_in_this_strip: bool,
		d_left: float, d_right: float, d_height: float) -> void:
	var strip_w: float = x_max - x_min
	if strip_w <= 0.001:
		return
	if not door_in_this_strip:
		var n := MeshInstance3D.new()
		n.name = strip_name
		var m := BoxMesh.new()
		m.size = Vector3(strip_w, room_height, WALL_THICKNESS)
		n.mesh = m
		n.material_override = mat
		n.position = Vector3((x_min + x_max) * 0.5, room_height * 0.5, z_plane)
		parent.add_child(n)
		return

	# Door is in this strip — three pieces: top lintel + left + right.
	var lintel_h: float = max(0.0, room_height - d_height)
	if lintel_h > 0.001:
		var top := MeshInstance3D.new()
		top.name = "%s_Lintel" % strip_name
		var tm := BoxMesh.new()
		tm.size = Vector3(strip_w, lintel_h, WALL_THICKNESS)
		top.mesh = tm
		top.material_override = mat
		top.position = Vector3((x_min + x_max) * 0.5, d_height + lintel_h * 0.5, z_plane)
		parent.add_child(top)

	var lw: float = d_left - x_min
	if lw > 0.001:
		var L := MeshInstance3D.new()
		L.name = "%s_L" % strip_name
		var lm := BoxMesh.new()
		lm.size = Vector3(lw, d_height, WALL_THICKNESS)
		L.mesh = lm
		L.material_override = mat
		L.position = Vector3(x_min + lw * 0.5, d_height * 0.5, z_plane)
		parent.add_child(L)

	var rw: float = x_max - d_right
	if rw > 0.001:
		var R := MeshInstance3D.new()
		R.name = "%s_R" % strip_name
		var rm := BoxMesh.new()
		rm.size = Vector3(rw, d_height, WALL_THICKNESS)
		R.mesh = rm
		R.material_override = mat
		R.position = Vector3(x_max - rw * 0.5, d_height * 0.5, z_plane)
		parent.add_child(R)


func _build_front_solid_with_window(parent: Node3D) -> void:
	# Build the -Z front (signage) wall as a solid panel split around
	# the front window. Same pattern as _build_back_solid_with_window,
	# minus the door-cut logic (the door lives on south by default; if
	# the user moves it to north, that's handled separately).
	var win_w: float = clamp(front_window_size.x, 0.5, max(0.5, room_width - 0.6))
	var win_h: float = clamp(front_window_size.y, 0.5, max(0.5, room_height - 1.0))
	var win_y: float = room_height * 0.5  # centred vertically
	var max_off: float = max(0.0, (room_width - win_w) * 0.5 - 0.1)
	var win_cx: float = clamp(front_window_offset_x, -max_off, max_off)
	var win_left_x: float = win_cx - win_w * 0.5
	var win_right_x: float = win_cx + win_w * 0.5
	var top_h: float = room_height - (win_y + win_h * 0.5)
	var bot_h: float = win_y - win_h * 0.5
	var z_plane: float = -room_depth * 0.5 + WALL_THICKNESS * 0.5

	var wall_mat := _make_wall_material()

	# Left strip
	var left_w: float = win_left_x - (-room_width * 0.5)
	if left_w > 0.001:
		var L := MeshInstance3D.new()
		L.name = "FrontWallLeft"
		var lm := BoxMesh.new()
		lm.size = Vector3(left_w, room_height, WALL_THICKNESS)
		L.mesh = lm
		L.material_override = wall_mat
		L.position = Vector3(-room_width * 0.5 + left_w * 0.5, room_height * 0.5, z_plane)
		parent.add_child(L)
	# Right strip
	var right_w: float = room_width * 0.5 - win_right_x
	if right_w > 0.001:
		var R := MeshInstance3D.new()
		R.name = "FrontWallRight"
		var rm := BoxMesh.new()
		rm.size = Vector3(right_w, room_height, WALL_THICKNESS)
		R.mesh = rm
		R.material_override = wall_mat
		R.position = Vector3(room_width * 0.5 - right_w * 0.5, room_height * 0.5, z_plane)
		parent.add_child(R)
	# Bottom strip
	if bot_h > 0.001:
		var B := MeshInstance3D.new()
		B.name = "FrontWallBot"
		var bm := BoxMesh.new()
		bm.size = Vector3(win_w, bot_h, WALL_THICKNESS)
		B.mesh = bm
		B.material_override = wall_mat
		B.position = Vector3(win_cx, bot_h * 0.5, z_plane)
		parent.add_child(B)
	# Top strip
	if top_h > 0.001:
		var T := MeshInstance3D.new()
		T.name = "FrontWallTop"
		var tm := BoxMesh.new()
		tm.size = Vector3(win_w, top_h, WALL_THICKNESS)
		T.mesh = tm
		T.material_override = wall_mat
		T.position = Vector3(win_cx, room_height - top_h * 0.5, z_plane)
		parent.add_child(T)

	# Glass pane filling the opening.
	var glass := MeshInstance3D.new()
	glass.name = "FrontWindowGlass"
	var gm := BoxMesh.new()
	gm.size = Vector3(win_w, win_h, WALL_THICKNESS * 0.5)
	glass.mesh = gm
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.78, 0.86, 0.94, 0.30)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.12
	glass_mat.metallic = 0.0
	glass.material_override = glass_mat
	glass.position = Vector3(win_cx, win_y, z_plane)
	parent.add_child(glass)

	# Frame trim around the opening — y_rot=PI so the frame's z_off
	# (always -WALL_THICKNESS*0.5-ft*0.5 in local coords, pulling toward
	# the room's interior for the back wall's z>0 plane) flips to point
	# into the room from the front wall's z<0 plane instead.
	_build_window_frame_strips(parent, "FrontWindowFrame", win_w, win_h, Vector3(win_cx, win_y, z_plane), PI)


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

	# Frame: thicker (0.12 m chunks) and pulled clearly into the room
	# so the frame edges don't co-plane with the wall mesh and z-fight.
	var ft: float = 0.12
	var half_w: float = win_w * 0.5
	var half_h: float = win_h * 0.5
	var z_off: float = -WALL_THICKNESS * 0.5 - ft * 0.5  # pull fully inside

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

	# Place + orient the door according to door_wall. door_offset_x
	# slides the door along the wall's long axis from its centre.
	# Clamped so the door never overlaps the wall's perpendicular edge.
	var pos: Vector3 = Vector3.ZERO
	var y_rot: float = 0.0
	var half_w: float = room_width * 0.5
	var half_d: float = room_depth * 0.5
	match door_wall:
		"north":  # -Z front wall — offset along X
			var ox_n: float = clamp(door_offset_x,
				-half_w + door_width * 0.5 + 0.2,
				half_w - door_width * 0.5 - 0.2)
			pos = Vector3(ox_n, 0.0, -half_d + WALL_THICKNESS * 0.5)
			y_rot = PI
		"south":  # +Z back wall — offset along X
			var ox_s: float = clamp(door_offset_x,
				-half_w + door_width * 0.5 + 0.2,
				half_w - door_width * 0.5 - 0.2)
			pos = Vector3(ox_s, 0.0, half_d - WALL_THICKNESS * 0.5)
			y_rot = 0.0
		"west":   # -X wall — offset along Z
			var oz_w: float = clamp(door_offset_x,
				-half_d + door_width * 0.5 + 0.2,
				half_d - door_width * 0.5 - 0.2)
			pos = Vector3(-half_w + WALL_THICKNESS * 0.5, 0.0, oz_w)
			y_rot = -PI * 0.5
		"east", _:  # +X wall — offset along Z
			var oz_e: float = clamp(door_offset_x,
				-half_d + door_width * 0.5 + 0.2,
				half_d - door_width * 0.5 - 0.2)
			pos = Vector3(half_w - WALL_THICKNESS * 0.5, 0.0, oz_e)
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

	# Top beam — dark matte science-lab metal.
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(dw + ft * 2.0, ft, fd)
	top.mesh = tm
	top.material_override = frame_mat
	top.position = Vector3(0.0, dh + ft * 0.5, 0.0)
	door_root.add_child(top)

	# Cyan accent strip across the top beam — the kind of running
	# indicator strip that gives the door a sci-fi airlock feel.
	# Sits flush with the interior face of the frame, slightly inset
	# from the edges so it reads as a single continuous bar.
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.30, 0.95, 1.00)
	accent_mat.emission_enabled = true
	accent_mat.emission = Color(0.30, 0.95, 1.00)
	accent_mat.emission_energy_multiplier = 1.4
	accent_mat.roughness = 0.2
	accent_mat.metallic = 0.0

	var accent_strip := MeshInstance3D.new()
	accent_strip.name = "TopAccentStrip"
	var as_mesh := BoxMesh.new()
	as_mesh.size = Vector3((dw + ft * 2.0) * 0.86, 0.008, 0.012)
	accent_strip.mesh = as_mesh
	accent_strip.material_override = accent_mat
	# Sit on the interior face of the top beam (+Z relative to the
	# door's local frame), with the strip running through the
	# lower-third of the beam height for that running-light look.
	accent_strip.position = Vector3(
		0.0,
		dh + ft * 0.20,
		fd * 0.5 - 0.005)
	door_root.add_child(accent_strip)

	# Two vertical guide rails — one on each side of the opening, on
	# the interior face of the side frames. Thin emissive strips that
	# match the top accent, giving the door a clear "approach me" cue.
	for sign in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.name = "GuideRail_%s" % ("R" if sign > 0 else "L")
		var rm := BoxMesh.new()
		rm.size = Vector3(0.010, dh * 0.85, 0.010)
		rail.mesh = rm
		rail.material_override = accent_mat
		rail.position = Vector3(
			sign * (half_dw + ft * 0.5 - 0.012),
			dh * 0.5,
			fd * 0.5 - 0.005)
		door_root.add_child(rail)

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

	# Sliding panel(s). When single_door is true, ONE full-width panel
	# centred in the opening; it slides one direction (negative X, i.e.
	# "left" relative to the door's local frame). When false, TWO
	# half-width panels meet at centre and slide symmetrically outward.
	var panel_w: float = dw if single_door else half_dw
	var left_panel := MeshInstance3D.new()
	left_panel.name = "DoorPanelLeft"
	var lpm := BoxMesh.new()
	lpm.size = Vector3(panel_w, dh, pt)
	left_panel.mesh = lpm
	left_panel.material_override = panel_mat
	# Single-door: panel sits in the centre of the opening.
	# Two-door:  panel sits at -half_dw (its right edge meets the centre).
	left_panel.position = Vector3((0.0 if single_door else -panel_w * 0.5), dh * 0.5, 0.0)
	door_root.add_child(left_panel)

	var right_panel: MeshInstance3D = null
	if not single_door:
		right_panel = MeshInstance3D.new()
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
	# Single door must slide the FULL door width to clear the opening.
	# Two-door uses the configured open_offset per panel.
	handler.set("open_offset", door_width if single_door else door_open_offset)
	handler.set("open_color", Color(0.40, 1.00, 0.55))
	handler.set("closed_color", Color(0.90, 0.22, 0.27))
	door_root.add_child(handler)


# ── Ceiling ───────────────────────────────────────────────────────────

func _build_ceiling() -> void:
	# Thin substrate slab — the dark backing behind the tile grid.
	# Without this, looking up between tiles would show through to
	# the sky. Sits flush with the top of the room.
	var substrate := MeshInstance3D.new()
	substrate.name = "CeilingSubstrate"
	var sm := BoxMesh.new()
	sm.size = Vector3(room_width, CEILING_THICKNESS, room_depth)
	substrate.mesh = sm
	var substrate_mat := StandardMaterial3D.new()
	substrate_mat.albedo_color = Color(0.10, 0.10, 0.12)
	substrate_mat.roughness = 0.95
	substrate.material_override = substrate_mat
	substrate.position = Vector3(0.0, room_height - CEILING_THICKNESS * 0.5, 0.0)
	add_child(substrate)

	# Skylight + exposed variants keep their original behaviour — only
	# the default tile_grid style now uses the reflective grid.
	if ceiling_style == "skylight":
		_build_skylight_panel()
		_build_skylight_grid()
		return
	if ceiling_style == "exposed":
		_build_exposed_ceiling()
		return

	# tile_grid (default): split the ceiling into ceiling_tile_size
	# cells, render each tile as its own reflective panel, and draw
	# thin T-grid lines between them.
	var cols: int = max(1, int(round(room_width / ceiling_tile_size)))
	var rows: int = max(1, int(round(room_depth / ceiling_tile_size)))
	var cell_w: float = room_width / float(cols)
	var cell_d: float = room_depth / float(rows)

	# Reflective tile material — satin-gloss white with a hint of
	# metallic so light fixtures and the floor read in the ceiling
	# reflection. Roughness low enough to bounce specular highlights.
	var tile_mat := StandardMaterial3D.new()
	tile_mat.albedo_color = ceiling_color
	tile_mat.roughness = 0.28
	tile_mat.metallic = 0.18
	tile_mat.metallic_specular = 0.75
	tile_mat.clearcoat_enabled = true
	tile_mat.clearcoat = 0.55
	tile_mat.clearcoat_roughness = 0.18

	# Grid line material — thin dark strips between tiles (the T-grid).
	var grid_mat := StandardMaterial3D.new()
	grid_mat.albedo_color = Color(0.18, 0.18, 0.21)
	grid_mat.roughness = 0.65
	grid_mat.metallic = 0.05

	var tiles_root := Node3D.new()
	tiles_root.name = "CeilingTiles"
	add_child(tiles_root)

	# Tiles hang BELOW the dark substrate so they're visible from inside
	# the room. Substrate spans [room_height - CEILING_THICKNESS,
	# room_height]; tiles sit centred just below that.
	var tile_thick: float = 0.012
	var tile_y: float = room_height - CEILING_THICKNESS - tile_thick * 0.5
	var tile_gap: float = 0.04  # leaves room for the T-grid line between tiles

	for i in range(cols):
		for j in range(rows):
			var tile := MeshInstance3D.new()
			tile.name = "Tile_%d_%d" % [i, j]
			var tm := BoxMesh.new()
			tm.size = Vector3(cell_w - tile_gap, tile_thick, cell_d - tile_gap)
			tile.mesh = tm
			tile.material_override = tile_mat
			var cx: float = -room_width * 0.5 + cell_w * (i + 0.5)
			var cz: float = -room_depth * 0.5 + cell_d * (j + 0.5)
			tile.position = Vector3(cx, tile_y, cz)
			tiles_root.add_child(tile)

	# Longitudinal grid lines (along Z, between columns).
	for i in range(cols + 1):
		var line := MeshInstance3D.new()
		line.name = "GridLineZ_%d" % i
		var lm := BoxMesh.new()
		lm.size = Vector3(tile_gap, tile_thick * 0.5, room_depth)
		line.mesh = lm
		line.material_override = grid_mat
		var lx: float = -room_width * 0.5 + cell_w * i
		line.position = Vector3(lx, tile_y - tile_thick * 0.25, 0.0)
		tiles_root.add_child(line)

	# Transverse grid lines (along X, between rows).
	for j in range(rows + 1):
		var line := MeshInstance3D.new()
		line.name = "GridLineX_%d" % j
		var lm := BoxMesh.new()
		lm.size = Vector3(room_width, tile_thick * 0.5, tile_gap)
		line.mesh = lm
		line.material_override = grid_mat
		var lz: float = -room_depth * 0.5 + cell_d * j
		line.position = Vector3(0.0, tile_y - tile_thick * 0.25, lz)
		tiles_root.add_child(line)


# Original simple ceiling slab (used by skylight variant via this helper).
func _build_skylight_panel() -> void:
	var ceil := MeshInstance3D.new()
	ceil.name = "Ceiling"
	var m := BoxMesh.new()
	m.size = Vector3(room_width, CEILING_THICKNESS, room_depth)
	ceil.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.97, 1.0)
	mat.roughness = 0.30
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.98, 0.92)
	mat.emission_energy_multiplier = 0.55
	ceil.material_override = mat
	ceil.position = Vector3(0.0, room_height - CEILING_THICKNESS * 0.5, 0.0)
	add_child(ceil)


# ── Ceiling fixtures ──────────────────────────────────────────────────
# Distribute vents / sprinklers / smoke sensors / speakers / light
# panels deterministically across the ceiling. Uses a seeded RNG to
# pick positions from a 6×4 candidate grid (with small jitter) so the
# layout is reproducible — same seed = same pattern. Skips fixture
# positions that overlap the floor window so the player can still see
# through the floor.

func _build_ceiling_fixtures() -> void:
	if not show_ceiling_fixtures:
		return
	var fixtures_root := Node3D.new()
	fixtures_root.name = "CeilingFixtures"
	add_child(fixtures_root)

	var rng := RandomNumberGenerator.new()
	rng.seed = ceiling_fixtures_seed

	# Use the SAME grid the ceiling tiles use, so each fixture sits at
	# the exact centre of a tile cell (no jitter — they "sit in the
	# grid" as the user requested).
	var cols: int = max(1, int(round(room_width / ceiling_tile_size)))
	var rows: int = max(1, int(round(room_depth / ceiling_tile_size)))
	var cell_w: float = room_width / float(cols)
	var cell_d: float = room_depth / float(rows)
	var ceil_y: float = room_height - CEILING_THICKNESS

	# Floor-window bounds (avoid placing fixtures directly above the
	# glass so the player's downward view stays clear).
	var fw_active: bool = show_floor_window
	var fw_x_min: float = 0.0
	var fw_x_max: float = 0.0
	var fw_z_min: float = 0.0
	var fw_z_max: float = 0.0
	if fw_active:
		var fw_w: float = floor_window_size.x
		var fw_d: float = floor_window_size.y
		fw_x_min = floor_window_offset.x - fw_w * 0.5
		fw_x_max = floor_window_offset.x + fw_w * 0.5
		fw_z_min = floor_window_offset.y - fw_d * 0.5
		fw_z_max = floor_window_offset.y + fw_d * 0.5

	# Build candidate position list at exact cell centres, excluding
	# cells over the floor window.
	var positions: Array = []
	for i in range(cols):
		for j in range(rows):
			var x: float = -room_width * 0.5 + cell_w * (i + 0.5)
			var z: float = -room_depth * 0.5 + cell_d * (j + 0.5)
			if fw_active and x > fw_x_min and x < fw_x_max and z > fw_z_min and z < fw_z_max:
				continue
			positions.append(Vector3(x, ceil_y, z))

	# Deterministic shuffle so the seeded RNG controls everything.
	_seeded_shuffle(positions, rng)

	# Consume positions in order — each fixture type uses N slots.
	var idx: int = 0
	for _i in range(ceiling_vent_count):
		if idx >= positions.size(): break
		_add_ceiling_vent_fixture(fixtures_root, positions[idx]); idx += 1
	for _i in range(ceiling_sprinkler_count):
		if idx >= positions.size(): break
		_add_sprinkler_fixture(fixtures_root, positions[idx]); idx += 1
	for _i in range(ceiling_sensor_count):
		if idx >= positions.size(): break
		_add_sensor_fixture(fixtures_root, positions[idx]); idx += 1
	for _i in range(ceiling_speaker_count):
		if idx >= positions.size(): break
		_add_speaker_fixture(fixtures_root, positions[idx]); idx += 1
	for _i in range(ceiling_light_count):
		if idx >= positions.size(): break
		_add_light_fixture(fixtures_root, positions[idx]); idx += 1


# Fisher–Yates with our seeded RNG so positions order is reproducible.
func _seeded_shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


# Each fixture is a small mesh mounted to the ceiling at the given
# anchor (ceiling-bottom Y). Fixtures hang BELOW the ceiling plane
# so they read as protrusions, not paint.

func _add_ceiling_vent_fixture(parent: Node3D, anchor: Vector3) -> void:
	# Square dark grate, 0.4×0.4 m, 0.04m deep.
	var n := MeshInstance3D.new()
	n.name = "Vent"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.40, 0.04, 0.40)
	n.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.20, 0.22)
	mat.roughness = 0.55
	mat.metallic = 0.5
	n.material_override = mat
	n.position = Vector3(anchor.x, anchor.y - 0.02, anchor.z)
	parent.add_child(n)


func _add_sprinkler_fixture(parent: Node3D, anchor: Vector3) -> void:
	# Small disc (recessed in ceiling) + downward nozzle.
	var disc := MeshInstance3D.new()
	disc.name = "SprinklerDisc"
	var dm := CylinderMesh.new()
	dm.top_radius = 0.06
	dm.bottom_radius = 0.06
	dm.height = 0.012
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.85, 0.85, 0.88)
	dmat.roughness = 0.45
	dmat.metallic = 0.3
	disc.material_override = dmat
	disc.position = Vector3(anchor.x, anchor.y - 0.006, anchor.z)
	parent.add_child(disc)
	# Brass-colored nozzle below the disc.
	var nozzle := MeshInstance3D.new()
	nozzle.name = "SprinklerNozzle"
	var nm := CylinderMesh.new()
	nm.top_radius = 0.022
	nm.bottom_radius = 0.012
	nm.height = 0.06
	nozzle.mesh = nm
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(0.82, 0.58, 0.22)  # brass
	nmat.roughness = 0.35
	nmat.metallic = 0.75
	nozzle.material_override = nmat
	nozzle.position = Vector3(anchor.x, anchor.y - 0.04, anchor.z)
	parent.add_child(nozzle)


func _add_sensor_fixture(parent: Node3D, anchor: Vector3) -> void:
	# Smoke detector — white disc with red LED.
	var disc := MeshInstance3D.new()
	disc.name = "SmokeDetector"
	var dm := CylinderMesh.new()
	dm.top_radius = 0.075
	dm.bottom_radius = 0.075
	dm.height = 0.025
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.94, 0.94, 0.95)
	dmat.roughness = 0.45
	dmat.metallic = 0.0
	disc.material_override = dmat
	disc.position = Vector3(anchor.x, anchor.y - 0.012, anchor.z)
	parent.add_child(disc)
	# LED dot
	var led := MeshInstance3D.new()
	led.name = "SensorLED"
	var lm := SphereMesh.new()
	lm.radius = 0.008
	lm.height = 0.016
	led.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.95, 0.20, 0.22)
	lmat.emission_enabled = true
	lmat.emission = Color(0.95, 0.20, 0.22)
	lmat.emission_energy_multiplier = 2.2
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	led.material_override = lmat
	led.position = Vector3(anchor.x + 0.03, anchor.y - 0.025, anchor.z + 0.02)
	parent.add_child(led)


func _add_speaker_fixture(parent: Node3D, anchor: Vector3) -> void:
	# Round overhead speaker — disc + slightly proud rim.
	var ring := MeshInstance3D.new()
	ring.name = "SpeakerRim"
	var rm := CylinderMesh.new()
	rm.top_radius = 0.10
	rm.bottom_radius = 0.10
	rm.height = 0.015
	ring.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.25, 0.26, 0.30)
	rmat.roughness = 0.55
	rmat.metallic = 0.35
	ring.material_override = rmat
	ring.position = Vector3(anchor.x, anchor.y - 0.007, anchor.z)
	parent.add_child(ring)
	# Cone (slightly recessed darker disc)
	var cone := MeshInstance3D.new()
	cone.name = "SpeakerCone"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.075
	cm.bottom_radius = 0.075
	cm.height = 0.005
	cone.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.08, 0.09, 0.11)
	cmat.roughness = 0.85
	cone.material_override = cmat
	cone.position = Vector3(anchor.x, anchor.y - 0.018, anchor.z)
	parent.add_child(cone)


func _add_light_fixture(parent: Node3D, anchor: Vector3) -> void:
	# Recessed flat light panel — 0.9 × 0.3 m, glows slightly.
	var p := MeshInstance3D.new()
	p.name = "LightPanel"
	var pm := BoxMesh.new()
	pm.size = Vector3(0.9, 0.03, 0.3)
	p.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.97, 1.00)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.98, 0.92)
	mat.emission_energy_multiplier = 0.9
	mat.roughness = 0.25
	mat.metallic = 0.0
	p.material_override = mat
	p.position = Vector3(anchor.x, anchor.y - 0.014, anchor.z)
	parent.add_child(p)


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


# ── Wall bands ────────────────────────────────────────────────────────
# Header (top), footer (bottom), and optional mid-band — horizontal
# strips on the INSIDE of every wall, pulled ~1cm into the room so they
# read as cladding instead of co-planar wall paint.

# Walk every MeshInstance3D in the lab and, for any using the wall-band
# shader, set its lab_world_y uniform to our current global Y. Called
# deferred from _ready so global_position is valid by then, and again
# from apply_grid_config so the bands stay correct if the lab moves
# after a config update.
func _patch_band_shader_world_y_offset() -> void:
	var y_off: float = global_position.y
	_patch_band_shader_recurse(self, y_off)


func _patch_band_shader_recurse(node: Node, y_off: float) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var m := mi.material_override
		if m is ShaderMaterial:
			var sm := m as ShaderMaterial
			if sm.shader == WALL_BAND_SHADER:
				sm.set_shader_parameter("lab_world_y", y_off)
	for c in node.get_children():
		_patch_band_shader_recurse(c, y_off)


func _build_wall_bands() -> void:
	if not (show_wall_header or show_wall_footer or show_wall_band):
		return
	var bands_root := Node3D.new()
	bands_root.name = "WallBands"
	add_child(bands_root)

	if show_wall_header and wall_header_height > 0.001:
		var hdr_y: float = room_height - wall_header_height * 0.5
		_add_band_loop(bands_root, "WallHeader", hdr_y, wall_header_height, wall_header_color)
	if show_wall_footer and wall_footer_height > 0.001:
		var ftr_y: float = wall_footer_height * 0.5
		_add_band_loop(bands_root, "WallFooter", ftr_y, wall_footer_height, wall_footer_color)
	if show_wall_band and wall_band_height > 0.001:
		_add_band_loop(bands_root, "WallBand", wall_band_y_centre, wall_band_height, wall_band_color)


# Compute the list of [min, max] cutout x-ranges that intersect the
# band at (band_y_centre, band_height) on the given wall side. Used to
# split each band into segments instead of drawing across windows and
# doorways.
func _cutouts_intersecting_band(side: String, y_centre: float, h: float) -> Array:
	var band_y_min: float = y_centre - h * 0.5
	var band_y_max: float = y_centre + h * 0.5
	var cutouts: Array = []
	# Door
	if show_sliding_door and door_wall == side:
		if 0.0 <= band_y_max and door_height >= band_y_min:
			cutouts.append([door_offset_x - door_width * 0.5,
				door_offset_x + door_width * 0.5])
	# Back / front window — vertically centred on the wall.
	var win_y: float = room_height * 0.5
	if side == "south" and show_back_window:
		var bw_h: float = back_window_size.y
		var bw_y_min: float = win_y - bw_h * 0.5
		var bw_y_max: float = win_y + bw_h * 0.5
		if bw_y_min <= band_y_max and bw_y_max >= band_y_min:
			cutouts.append([back_window_offset_x - back_window_size.x * 0.5,
				back_window_offset_x + back_window_size.x * 0.5])
	if side == "north" and show_front_window:
		var fw_h: float = front_window_size.y
		var fw_y_min: float = win_y - fw_h * 0.5
		var fw_y_max: float = win_y + fw_h * 0.5
		if fw_y_min <= band_y_max and fw_y_max >= band_y_min:
			cutouts.append([front_window_offset_x - front_window_size.x * 0.5,
				front_window_offset_x + front_window_size.x * 0.5])
	cutouts.sort_custom(func(a, b): return a[0] < b[0])
	return cutouts


# Add one band around the room's interior — segmented per wall so the
# band doesn't draw across doors or windows. Each strip is pulled 1cm
# toward the room interior so it doesn't z-fight with the wall mesh.
func _add_band_loop(parent: Node3D, n: String, y_centre: float, h: float, c: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.55
	mat.metallic = 0.30
	var inset: float = 0.01
	var strip_t: float = 0.04

	# Each wall built separately so each can split independently.
	_add_band_wall_segments(parent, "%s_N" % n, "north",
		y_centre, h, mat, inset, strip_t)
	_add_band_wall_segments(parent, "%s_S" % n, "south",
		y_centre, h, mat, inset, strip_t)
	_add_band_wall_segments(parent, "%s_E" % n, "east",
		y_centre, h, mat, inset, strip_t)
	_add_band_wall_segments(parent, "%s_W" % n, "west",
		y_centre, h, mat, inset, strip_t)


# Build segmented band strips along ONE wall. Walks the wall's long
# axis (X for N/S, Z for E/W), inserting cutouts where the band
# would cross a window or doorway, drawing a strip between each gap.
func _add_band_wall_segments(parent: Node3D, n: String, side: String,
		y_centre: float, h: float, mat: Material,
		inset: float, strip_t: float) -> void:
	var cutouts: Array = _cutouts_intersecting_band(side, y_centre, h)
	var axis_runs_x: bool = (side == "north" or side == "south")
	var axis_extent: float = (room_width if axis_runs_x else room_depth) * 0.5

	# Wall-plane position (perpendicular axis fixed).
	var perp_pos: float
	match side:
		"north": perp_pos = -room_depth * 0.5 + WALL_THICKNESS + inset + strip_t * 0.5
		"south": perp_pos =  room_depth * 0.5 - WALL_THICKNESS - inset - strip_t * 0.5
		"east":  perp_pos =  room_width * 0.5 - WALL_THICKNESS - inset - strip_t * 0.5
		"west":  perp_pos = -room_width * 0.5 + WALL_THICKNESS + inset + strip_t * 0.5
		_: return

	# Walk the axis adding segments.
	var cursor: float = -axis_extent
	var seg_index: int = 0
	for cutout in cutouts:
		var cut_left: float = max(cutout[0], -axis_extent)
		var cut_right: float = min(cutout[1], axis_extent)
		if cut_left > cursor:
			_add_band_segment(parent, "%s_%d" % [n, seg_index], side,
				cursor, cut_left, y_centre, h, mat, strip_t, perp_pos)
			seg_index += 1
		cursor = max(cursor, cut_right)
	if cursor < axis_extent:
		_add_band_segment(parent, "%s_%d" % [n, seg_index], side,
			cursor, axis_extent, y_centre, h, mat, strip_t, perp_pos)


func _add_band_segment(parent: Node3D, n: String, side: String,
		axis_min: float, axis_max: float, y_centre: float, h: float,
		mat: Material, strip_t: float, perp_pos: float) -> void:
	var seg_len: float = axis_max - axis_min
	if seg_len <= 0.001:
		return
	var seg_centre: float = (axis_min + axis_max) * 0.5
	var m := MeshInstance3D.new()
	m.name = n
	var bm := BoxMesh.new()
	var axis_runs_x: bool = (side == "north" or side == "south")
	if axis_runs_x:
		bm.size = Vector3(seg_len, h, strip_t)
		m.position = Vector3(seg_centre, y_centre, perp_pos)
	else:
		bm.size = Vector3(strip_t, h, seg_len)
		m.position = Vector3(perp_pos, y_centre, seg_centre)
	m.mesh = bm
	m.material_override = mat
	parent.add_child(m)


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
