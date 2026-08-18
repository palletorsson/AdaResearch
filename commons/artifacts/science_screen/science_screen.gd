## ScienceScreen — A large VR display showing 2D abstractions of 3D content.
##
## The meeting point of 2D and 3D in Ada Research. You EXPERIENCE the pattern
## with your body while you UNDERSTAND it with your eyes. Split consciousness:
## the 3D world around you rendered as a flat, legible grid on this screen.
##
## Detects nearby artifacts that have grid data (via apply_grid_config) and
## renders a simplified pixel-grid view on a SubViewport. Shows algorithm name,
## grid dimensions, pattern type, and cell counts as overlay text.
##
## Grid config keys:
##   screen_width   - Width in meters (0.5–4.0, default 2.0)
##   screen_height  - Height in meters (0.5–3.0, default 1.5)
##   scan_radius    - How far to look for artifacts (1.0–20.0, default 8.0)
##   label          - Override the algorithm name text
##   highlight      - Highlight color as "r,g,b" (0–1 floats)
##   border         - Border color as "r,g,b"
##   bg             - Background color as "r,g,b"
##   support        - none | bracket | stand | cradle | frame | gantry | cabinet | pylon
##                    (stage-2 DNA, default stand). The shared support vocabulary —
##                    what apparatus holds this object up. Built natively here:
##                    stand, frame, cabinet, pylon. The other four DEGRADE to the
##                    nearest native rather than silently no-opping.
##                    Retired VALUE spellings still accepted: console -> cabinet and
##                    wall -> pylon. The retired TOKEN `housing` is not: a retired token
##                    that still resolves is how `regard` came to select two different
##                    axes in the exhibits family, so the shim was deleted rather than
##                    kept. Corpus census for `housing`: zero.
##   surface        - plane | curve | triptych | tiles (stage-2 DNA, default plane)

# @identity
# essence: a SubViewport renders the grid-state of nearby artifacts as a 2D pixel-map on a large wall-mounted screen — you stand in the 3D world and see its cellular logic flattened beside you
# desire: to make the abstract legible without leaving the embodied — the learner walks the algorithm and simultaneously reads it; the gap between 3D experience and 2D representation IS the research question made visible
# critical_parameter: scan_radius (8.0m) — determines which artifacts the screen can detect and mirror; too small and it misses wall-placed artifacts, too large and it picks up unrelated neighbors
# triggers: periodic scan_interval timer scans for nearby artifacts with get_grid_data(); _draw_grid() on SubViewport renders colored cells; point_mode activates when a pickable point is grabbed nearby
# emerges: point_mode transforms the screen into a live coordinate tracker — it shows the trajectory of a grabbed point in relative space, turning a simple grab into a navigation display
# needs: VR interaction for changing scan_radius [missing]; multi-artifact switching [missing — always shows nearest]; apply_grid_config [has]
# relationships: placed next to primary teaching artifacts in primitives/color/array maps; pairs with player_trace (records path) and interactive_point_origin (shows position); depends on artifacts implementing get_grid_data()
# truth: the map is not the territory — science_screen shows a flattened version of the algorithm you are already inside, and the difference between the two is where understanding lives

extends Node3D
class_name ScienceScreen

## Integrated 2D-in-3D text helper — replaces floating Label3D signage with a
## framed dark board (baked, billboarded, lit accent edge). Drop-in for Label3D.
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

## Shared station-furniture parts. The supports are cut from the same kit as the
## benches and cabinets they stand beside, so a cabinet-bodied screen reads as
## belonging to the room rather than arriving from another project.
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")


# Spine-corridor contract — see doc/SPINE_HINTS_CONTRACT.md
func spine_hints() -> Dictionary:
	return {
		"role":         "reflection",
		"footprint":    Vector2i(2, 1),
		"approach":     "south",
		"reading_dist": 1.0,
		"height":       2.0,
		"rotation_y":   180,   # face south so player reads while walking north
		"budget_ms":    0.4,
		"tags":         ["label", "static"],
	}


## Physical dimensions
@export var screen_width: float = 3.0
@export var screen_height: float = 2.2

## Colors
@export var screen_color: Color = Color(0.05, 0.05, 0.08)
@export var border_color: Color = Color(0.3, 0.3, 0.35)
@export var grid_color: Color = Color(0.15, 0.2, 0.25)
@export var highlight_color: Color = Color(0.2, 0.8, 0.4)

## Scanning
@export var scan_radius: float = 8.0
@export var scan_interval: float = 1.0


# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — two axes, both cut from this artifact's own question
# ═══════════════════════════════════════════════════════════════════
#
# @identity says the screen exists to hold open the gap between the algorithm
# you are standing inside and the flattened picture of it beside you: "the map
# is not the territory ... the difference between the two is where understanding
# lives." Both axes are that difference, made into geometry.
#
#   support — what apparatus holds the flattening up, which is a claim about who
#     is speaking. A monitor someone wheeled in is provisional. A slab the
#     building owns is architecture. A cabinet is an instrument you stand at. An
#     open frame around it says out loud that this is staging and could be struck
#     tomorrow. Same image, four institutions.
#
#   surface — how flat the flattening actually IS. A perfect plane is the
#     strongest possible claim to map-ness: no angle, no thickness, no body.
#     Bending, folding or tiling the image lets the territory back in — the
#     picture starts to have a shape of its own, and reading it costs you a
#     position to read it from.
#
# What this costs: a folded or tiled face is harder to read straight on, and the
# cabinet support gives up the architectural reading entirely. That is the trade —
# these are not four skins, they are four different arguments.
#
# Defaults (stand / plane) rebuild the pre-DNA screen node-for-node. The 215
# existing placements must not be able to tell this was written.
#
# ── The shared support vocabulary ────────────────────────────────────
# `support` is not this artifact's private axis. It is the one word every artifact
# now uses for "what apparatus holds this object up", replacing four local names
# that all asked the same question (`station` on the fire pieces, `carriage` on the
# info board, `rig` on catalyst_target, `housing` here). Eight canonical values,
# every one of them a lowercase noun and every one of them visible in a still:
#
#   none     no apparatus — the object meets the room on its own
#   bracket  minimal hardware fixing it to a vertical surface; the wall takes it
#   stand    a slender floor member — pole, legs, base plate; demountable
#   cradle   a low wide base with grips reaching up; presented from below, not lifted
#   frame    an open upright structure standing AROUND it; you see the room through it
#   gantry   an open structure OVER it; the load comes from above
#   cabinet  a body of cabinetwork takes the floor or wall and serves the object
#   pylon    a mass of building; the object is sunk into a slab with a reveal
#
# ALL EIGHT ARE ACCEPTED HERE. This screen natively builds four of them; the other
# four resolve through DEGRADE to the nearest thing it does build. That table is the
# point of the convergence pass — under a shared vocabulary an unrecognised value
# falling through to the default is a silent lie, because `support:gantry` on this
# screen would quietly become a stand instead of the frame it most resembles.
const SUPPORTS: PackedStringArray = [
	"none", "bracket", "stand", "cradle", "frame", "gantry", "cabinet", "pylon"]

## The four this artifact has real geometry for. Everything else lands on one of
## these — declared, never silent.
const SUPPORTS_NATIVE: PackedStringArray = ["stand", "frame", "cabinet", "pylon"]

## Every canonical value with no builder here, mapped to its nearest native.
##
##   none    -> stand. No bare-panel build exists, and stripping the 0.06 m pole
##             plus the 0.3 x 0.02 x 0.2 foot would very likely miss the 3% bite
##             bar — so `none` stays a declared degrade rather than being promoted
##             into a variant the critic would rightly call inert.
##   bracket -> stand. Deliberately NOT pylon. `bracket` and `stand` share the
##             provisional-hardware register; `pylon` makes an architectural claim
##             ("the building is speaking") that a bracket explicitly refuses.
##             Understating by a pole is a smaller lie than overstating by a
##             floor-to-lintel slab, and degrading ACROSS a register boundary is
##             worse than degrading within one.
##   cradle  -> stand. The stand's wider foot is its only floor-borne base under
##             the face.
##   gantry  -> frame. The frame carries a top tie bar above the panel plus posts
##             either side — the nearest overhead structure this screen owns.
const DEGRADE: Dictionary = {
	"none": "stand",
	"bracket": "stand",
	"cradle": "stand",
	"gantry": "frame",
}

## Retired spellings, kept readable forever. The pre-convergence names were cut on
## register and on room-element; the canonical ones are cut on FORM.
##   console -> cabinet  (the 1960s console television is the type specimen — a
##                        screen and a cabinet are one object)
##   wall    -> pylon    (`wall` named WHERE rather than WHAT, and collided with
##                        the map's own layers.walls)
## `rig` is retired from the grammar ENTIRELY — neither token nor value, and not even an
## alias, because an alias would keep it alive as a second spelling of `frame`. What it
## used to name here (two posts, side collars, cross braces, a top tie bar) is a frame,
## not a suspension. Its old meaning on catalyst_target is now the token `support`.
const SUPPORT_ALIASES: Dictionary = {
	"console": "cabinet",
	"wall": "pylon",
}

const SURFACES: PackedStringArray = ["plane", "curve", "triptych", "tiles"]

## DECLARED = what this artifact BUILDS NATIVELY, not the whole canonical vocabulary.
## The full eight live in `const SUPPORTS` and _pick_support still accepts every one of
## them; they degrade to a native. Declaring all eight here would advertise four variants
## that render pixel-identical to another tile, which is the inert-axis failure the
## declaration checker exists to catch.
@export_enum("stand", "frame", "cabinet", "pylon") var support: String = "stand"
@export_enum("plane", "curve", "triptych", "tiles") var surface: String = "plane"

## Curve: metres the outer edges reach toward the viewer. Big on purpose — at
## 0.40 m on a 3 m screen the edge normals swing ~28°, which is the difference
## between a curved monitor and a still that looks identical to the flat one.
## A polite 5 cm bow would have been invisible and therefore worthless.
const CURVE_BOW: float = 0.40
const CURVE_SEGS: int = 14

## Triptych: wing hinge angle, and the seam left open at each hinge so the three
## panels read as three panels and not as one creased sheet.
const FOLD_DEG: float = 38.0
const FOLD_SEAM: float = 0.06

## Tiles: a video wall cut out of one image. The gap is what the seams eat —
## the flattening is lossy and this is where it shows you.
const TILE_COLS: int = 4
const TILE_ROWS: int = 3
const TILE_GAP: float = 0.045
const TILE_RELIEF: float = 0.026

## Cabinet: how far the cabinetwork lifts the face, and how far the face then
## leans back off its own bottom edge. Kept modest — screen_height is author-set up
## to 3.0 m and a taller lift would push the assembly through low ceilings.
## The names keep CONSOLE_ because the console television is the type specimen for
## `cabinet`, and renaming a private constant buys nothing a reader needs.
const CONSOLE_LIFT: float = 0.55
const CONSOLE_LEAN_DEG: float = 11.0

## Internal nodes
var _screen_mesh: MeshInstance3D
var _border_mesh: MeshInstance3D
var _stand_mesh: MeshInstance3D

## The support value RESOLVED THROUGH DEGRADE — i.e. one of SUPPORTS_NATIVE. Three
## consumers read it (the face lift, the face lean, the build match) and they must
## all read the SAME resolution: if each degraded on its own, or one of them missed
## the table, `support:gantry` could lean like a cabinet while building a frame.
## Resolve once, store, read the store. Initialised to the export default so the
## legacy value is already correct before anything calls _resolve_support().
var _support_native: String = "stand"

## Everything belonging to the display FACE hangs off one root, so a support can
## lift or lean the whole display without a single panel coordinate knowing it.
var _face_root: Node3D

## Every surface mode is just a list of quads carrying a sub-rectangle of the one
## SubViewport — which is why curve/triptych/tiles cost geometry and not a second
## rendering path. Entries: {mesh, uv_offset, uv_scale}.
var _screen_panels: Array[Dictionary] = []

## The face's real outline, which the folded and bent surfaces move. The LED and
## the brand mark hang off these instead of off screen_width.
var _face_half_w: float = 0.0
var _brand_half_w: float = 0.0
var _viewport: SubViewport
var _canvas: Control
var _label_name: String = ""
var _override_label: String = ""

## Grid data extracted from nearby artifact
var _grid_cols: int = 0
var _grid_rows: int = 0
var _grid_cells: Array = []  # 2D array of int (color indices)
var _cell_count: int = 0
var _pattern_type: String = "none"
var _source_artifact_name: String = ""

## Point tracking mode — when a pickable point is nearby
var _tracking_point: Node3D = null
var _point_mode: bool = false
var _point_origin: Vector3 = Vector3.ZERO  # Initial position — all coords relative to this
var _point_origin_set: bool = false
var _point_trail: Array[Vector3] = []  # Stores RELATIVE positions
const MAX_TRAIL := 100

## Point game state — target, score, particles
var _point_target: Vector3 = Vector3.ZERO
var _point_target_color: Color = Color(0.06, 0.65, 0.88)
var _point_score: int = 0
var _point_exploding: bool = false
var _point_explode_timer: float = 0.0
var _point_particles: Array[Dictionary] = []  # [{pos: Vector3, vel: Vector3, life: float, color: Color}]
var _point_target_idx: int = 0
const POINT_SNAP_DIST := 0.5
const POINT_TARGET_COLORS: Array[Color] = [
	Color(0.06, 0.65, 0.88), Color(0.96, 0.62, 0.04), Color(0.06, 0.73, 0.51),
	Color(0.94, 0.27, 0.27), Color(0.93, 0.29, 0.60), Color(0.02, 0.71, 0.83),
]

## Line tracking mode — two endpoints forming a line segment
var _line_mode: bool = false
var _tracking_line_p1: Node3D = null
var _tracking_line_p2: Node3D = null
var _line_origin: Vector3 = Vector3.ZERO  # Midpoint of initial line — all coords relative
var _line_origin_set: bool = false

## Draw dot mode — tracks a drawing artifact's trail
var _draw_mode: bool = false
var _tracking_draw_dot: Node3D = null

## Triangle mode — three vertices forming a triangle
var _triangle_mode: bool = false
var _tracking_tri_points: Array[Node3D] = []

## Generic mode — catch-all for other artifact types
var _generic_mode: bool = false
var _generic_mode_name: String = ""
var _tracking_generic: Node3D = null

## Viewport resolution
const VP_WIDTH: int = 768
const VP_HEIGHT: int = 576

## Scan timer
var _scan_timer: float = 0.0
var _mode_locked: bool = false  # Once a mode is set, stop scanning
var _explicit_mode: String = ""  # Set via map JSON: "point", "line", "trace", "triangle", "generic"

## Dynamic info text — loaded from blurb.md / intent.md
var _info_lines: Array[String] = []  # All available info sentences
var _info_index: int = 0  # Current info line
var _info_timer: float = 0.0  # Timer for cycling text
var _info_cycle_interval: float = 6.0  # Seconds between text changes
var _info_current: String = ""  # Currently displayed line
var _info_sub: String = ""  # Sub-line (dim text)

func _ready() -> void:
	_build_screen()
	_build_viewport()
	_apply_viewport_to_screen()
	# Start with point mode as visual default (white grid shown immediately)
	_point_mode = true
	# Load map text for info bar
	call_deferred("_load_map_text")
	# Deferred scan connects tracking nodes after artifacts are placed
	call_deferred("_deferred_first_scan")


## Load blurb.md and intent.md from the current map directory for the info bar
func _load_map_text() -> void:
	# call_deferred from _ready, and then a THREE SECOND wait — the widest window in
	# this artifact for the map to be torn down underneath it. A detached node still
	# runs its deferred callback, and get_tree() is null there.
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(3.0).timeout  # Wait for map name to be set
	var map_name: String = ""
	var gs := _find_grid_system()
	if gs:
		map_name = gs.get("map_name") if gs.get("map_name") else ""
	if map_name == "":
		_info_lines = ["Drag to interact. The screen shows what you do."]
		_info_current = _info_lines[0]
		return

	# Load blurb.md
	var blurb_path: String = "res://commons/maps/%s/blurb.md" % map_name
	if FileAccess.file_exists(blurb_path):
		var f := FileAccess.open(blurb_path, FileAccess.READ)
		if f:
			var text: String = f.get_as_text().strip_edges()
			f.close()
			# Split into sentences
			for sentence in text.split("."):
				var s: String = sentence.strip_edges()
				if s.length() > 10:
					_info_lines.append(s + ".")

	# Load intent.md — extract concept and critical angle
	var intent_path: String = "res://commons/maps/%s/intent.md" % map_name
	if FileAccess.file_exists(intent_path):
		var f := FileAccess.open(intent_path, FileAccess.READ)
		if f:
			var text: String = f.get_as_text()
			f.close()
			for line in text.split("\n"):
				line = line.strip_edges()
				if line.begins_with("Concept:"):
					_info_lines.append(line.substr(8).strip_edges())
				elif line.begins_with("Critical angle:"):
					_info_lines.append(line.substr(15).strip_edges())

	if _info_lines.is_empty():
		_info_lines = ["Interact with the artifacts. The screen shows the math."]
	_info_current = _info_lines[0]
	if _info_lines.size() > 1:
		_info_sub = _info_lines[1]
	print("[ScienceScreen] Loaded %d info lines from %s" % [_info_lines.size(), map_name])


func _find_grid_system() -> Node:
	var parent := get_parent()
	while parent:
		if parent.get("map_name") != null:
			return parent
		parent = parent.get_parent()
	return null


## Find nearest sibling artifact that has a specific property
func _find_artifact_with_property(prop_name: String) -> Node3D:
	var parent := get_parent()
	if not parent:
		return null
	var my_pos := global_position
	var best: Node3D = null
	var best_dist: float = scan_radius + 1.0
	for child in parent.get_children():
		if child == self or not (child is Node3D):
			continue
		if prop_name in child:
			var d: float = my_pos.distance_to(child.global_position)
			if d < best_dist:
				best_dist = d
				best = child as Node3D
	return best


## Set mode explicitly — called from apply_grid_config when map JSON has #mode:xxx
func _set_explicit_mode(mode_str: String) -> void:
	_explicit_mode = mode_str
	# Clear all modes first
	_point_mode = false
	_line_mode = false
	_draw_mode = false
	_triangle_mode = false
	_generic_mode = false
	match mode_str:
		"point":
			_point_mode = true
			_label_name = "POINT TRACKER"
		"line":
			_line_mode = true
			_label_name = "LINE ANALYZER"
		"trace", "draw":
			_draw_mode = true
			_label_name = "TRACE RECORDER"
		"triangle":
			_triangle_mode = true
			_label_name = "TRIANGLE ANALYZER"
		"net", "cube":
			_generic_mode = true
			_generic_mode_name = "net"
			_label_name = "CUBE NET"
		"wave", "pendulum", "sine":
			_generic_mode = true
			_generic_mode_name = "wave"
			_label_name = "WAVEFORM"
		"field", "noise":
			_generic_mode = true
			_generic_mode_name = "field"
			_label_name = "FIELD MAP"
		"scatter", "swarm", "boids":
			_generic_mode = true
			_generic_mode_name = "scatter"
			_label_name = "SCATTER PLOT"
		"grid", "ca", "automata":
			_generic_mode = true
			_generic_mode_name = "grid"
			_label_name = "GRID VIEW"
		"bars", "histogram", "sort":
			_generic_mode = true
			_generic_mode_name = "bars"
			_label_name = "BAR CHART"
		_:
			_point_mode = true  # Unknown mode → default to point
			_label_name = "SCIENCE SCREEN"
	_mode_locked = true
	print("[ScienceScreen] Explicit mode set: %s" % mode_str)


func _get_active_mode() -> String:
	if _point_mode: return "point"
	if _line_mode: return "line"
	if _draw_mode: return "trace"
	if _triangle_mode: return "triangle"
	if _generic_mode: return "generic"
	return "none"


func _deferred_first_scan() -> void:
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(2.0).timeout  # Wait for all artifacts to be placed
	# If mode was already set explicitly via config, just connect tracking nodes
	if _mode_locked:
		_connect_tracking_for_mode()
		print("[ScienceScreen] Mode locked (explicit): %s" % _get_active_mode())
		return
	# Fallback: scan if no explicit mode was set (legacy maps without #mode:xxx)
	_point_mode = false
	_scan_for_points()
	if not _point_mode:
		_scan_for_lines()
	if not _point_mode and not _line_mode:
		_scan_for_draw_dot()
	if not _point_mode and not _line_mode and not _draw_mode:
		_scan_for_triangles()
	if not _point_mode and not _line_mode and not _draw_mode and not _triangle_mode:
		_scan_for_generic()
	if not _point_mode and not _line_mode and not _draw_mode and not _triangle_mode and not _generic_mode:
		_point_mode = true
	_mode_locked = true
	print("[ScienceScreen] Mode locked (scan): %s" % _get_active_mode())


## Connect the right tracking node for the explicit mode
func _connect_tracking_for_mode() -> void:
	match _explicit_mode:
		"point":
			_scan_for_points()
		"line":
			_scan_for_lines()
		"trace", "draw":
			_scan_for_draw_dot()
		"triangle":
			_scan_for_triangles()
		"wave", "pendulum", "sine":
			# Find pendulum or oscillation artifact
			var art: Node3D = _find_artifact_with_property("_angle")
			if not art: art = _find_artifact_with_property("current_amplitude")
			if art:
				_tracking_generic = art
				print("[ScienceScreen] Tracking wave: %s" % art.name)
		"scatter", "swarm", "boids":
			# Find boid container
			var art: Node3D = _find_artifact_with_property("boid_count")
			if art:
				_tracking_generic = art
				print("[ScienceScreen] Tracking swarm: %s" % art.name)
		"grid", "ca", "automata":
			# Find CA or grid artifact
			var art: Node3D = _find_artifact_with_property("grid_size")
			if art:
				_tracking_generic = art
				print("[ScienceScreen] Tracking grid: %s" % art.name)
		"bars", "histogram", "sort":
			# Find bar array artifact
			var art: Node3D = _find_artifact_with_property("_current_heights")
			if not art: art = _find_artifact_with_property("_array")
			if art:
				_tracking_generic = art
				print("[ScienceScreen] Tracking bars: %s" % art.name)
		"field", "noise":
			# Find noise field artifact
			var art: Node3D = _find_artifact_with_property("noise_frequency")
			if not art: art = _find_artifact_with_property("height_scale")
			if art:
				_tracking_generic = art
				print("[ScienceScreen] Tracking field: %s" % art.name)
		"net", "cube":
			_scan_for_generic()

func _process(delta: float) -> void:
	# Never rescan once a mode is locked
	if not _mode_locked:
		_scan_timer += delta
		if _scan_timer >= scan_interval:
			_scan_timer = 0.0
			# Only scan if no mode is active (besides default point mode)
			if not _line_mode and not _draw_mode and not _triangle_mode and not _generic_mode:
				_scan_for_points()
				if not _point_mode:
					_scan_for_lines()
				if not _point_mode and not _line_mode:
					_scan_for_draw_dot()
				if not _point_mode and not _line_mode and not _draw_mode:
					_scan_for_triangles()
				if not _point_mode and not _line_mode and not _draw_mode and not _triangle_mode:
					_scan_for_generic()
			# Lock once any mode is active
			if _point_mode or _line_mode or _draw_mode or _triangle_mode or _generic_mode:
				_mode_locked = true

	# Track point position for trail + game logic
	if _point_mode and is_instance_valid(_tracking_point) and _tracking_point.visible:
		var abs_pos: Vector3 = _tracking_point.global_position

		# Set origin on first frame — all subsequent positions are relative
		if not _point_origin_set:
			_point_origin = abs_pos
			_point_origin_set = true

		# Relative position (origin = 0,0)
		var pos: Vector3 = abs_pos - _point_origin
		_point_trail.append(pos)
		if _point_trail.size() > MAX_TRAIL:
			_point_trail.pop_front()

		# Initialize target if needed
		if _point_target == Vector3.ZERO:
			_spawn_new_target()

		# Check if point reached target (using relative coords)
		if not _point_exploding:
			var d: float = Vector2(pos.x, pos.y).distance_to(Vector2(_point_target.x, _point_target.y))
			if d < POINT_SNAP_DIST:
				_point_exploding = true
				_point_explode_timer = 0.5
				_point_score += 1
				_spawn_point_particles()

		# Update explosion
		if _point_exploding:
			_point_explode_timer -= delta
			if _point_explode_timer <= 0:
				_point_exploding = false
				_spawn_new_target()

		# Update particles
		for i in range(_point_particles.size() - 1, -1, -1):
			var p: Dictionary = _point_particles[i]
			p["pos"] += p["vel"] * delta
			p["vel"].y -= 2.0 * delta
			p["life"] -= delta
			if p["life"] <= 0:
				_point_particles.remove_at(i)

	# Track line origin
	if _line_mode and is_instance_valid(_tracking_line_p1) and is_instance_valid(_tracking_line_p2):
		if not _line_origin_set:
			_line_origin = (_tracking_line_p1.global_position + _tracking_line_p2.global_position) * 0.5
			_line_origin_set = true

	# Cycle info bar text
	if _info_lines.size() > 1:
		_info_timer += delta
		if _info_timer >= _info_cycle_interval:
			_info_timer = 0.0
			_info_index = (_info_index + 1) % _info_lines.size()
			_info_current = _info_lines[_info_index]
			_info_sub = _info_lines[(_info_index + 1) % _info_lines.size()] if _info_lines.size() > 1 else ""

	_canvas.queue_redraw()


func _spawn_new_target() -> void:
	_point_target = Vector3(
		randf_range(-0.5, 0.5),
		randf_range(-0.5, 0.5),
		0
	)
	_point_target_idx += 1
	_point_target_color = POINT_TARGET_COLORS[_point_target_idx % POINT_TARGET_COLORS.size()]


func _spawn_point_particles() -> void:
	for i in range(20):
		var angle: float = (float(i) / 20.0) * TAU + randf() * 0.3
		var speed: float = 1.5 + randf() * 3.0
		_point_particles.append({
			"pos": Vector3(_point_target.x, _point_target.y, 0),
			"vel": Vector3(cos(angle) * speed, sin(angle) * speed, 0),
			"life": 0.4 + randf() * 0.3,
			"color": [Color(0.55, 0.36, 0.96), Color(0.06, 0.65, 0.88), Color(0.96, 0.62, 0.04), Color(1, 1, 1)].pick_random(),
		})


# ═══════════════════════════════════════════════════════════════════
# CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════

func _build_screen() -> void:
	var screen_y: float = screen_height * 0.5 + 0.05
	_screen_panels.clear()
	# Cleared, not just overwritten: after a _rebuild() these still point at freed
	# nodes, which compare unequal to null and would defeat the "first panel wins"
	# assignments below.
	_screen_mesh = null
	_border_mesh = null

	# Resolve the shared vocabulary to something this artifact actually builds, ONCE,
	# before any consumer looks. Cheap and idempotent, so calling it from both here
	# and apply_grid_config costs nothing and covers the .tscn-authored path too.
	_resolve_support()

	# The face gets its own root so a support can lift or lean the entire display
	# without touching a panel coordinate. `stand` leaves it at identity, which is
	# why the legacy build comes out unchanged despite the extra node.
	_face_root = Node3D.new()
	_face_root.name = "Face"
	var lift: float = _support_lift()
	_face_root.position = Vector3(0, lift, 0)
	if _support_native == "cabinet":
		# Rotation pivots on the root's own origin, which after the lift sits at
		# the screen's bottom edge — so the face leans back OFF the cabinet lip
		# instead of swinging through it.
		_face_root.rotation_degrees = Vector3(-CONSOLE_LEAN_DEG, 0, 0)
	add_child(_face_root)

	_build_face(screen_y)
	_build_support(screen_y, lift)


## Collapse the eight-value shared vocabulary onto the four this artifact builds.
## A value already native maps to itself (it is absent from DEGRADE), so the
## default `stand` comes out of here as `stand` and the legacy path is untouched.
## Anything outside all eight never reaches here — _pick_support rejects it to the
## current value first, because that case is a typo and not a sibling's gesture.
func _resolve_support() -> void:
	# Fold the alias HERE, not only in _pick_support, so every route agrees. Its two
	# siblings fold in the resolver; this file folded only on the map-token path, so a
	# value assigned directly to the property resolved differently from the same value
	# written as a map token — an asymmetry in a pass whose point is that these five
	# files behave identically.
	var v: String = str(SUPPORT_ALIASES.get(support.strip_edges().to_lower(), support))
	v = str(DEGRADE.get(v, v))
	# Enforce the invariant the three consumers rely on rather than assume it: after
	# this line _support_native is ALWAYS one of SUPPORTS_NATIVE. If a future value
	# is added to SUPPORTS and forgotten in DEGRADE, it lands on the legacy stand
	# here instead of falling through _build_support's wildcard unnoticed.
	_support_native = v if SUPPORTS_NATIVE.has(v) else "stand"


## Metres the support raises the display face. Only the cabinet lifts: the pylon
## slab and the frame reach the floor on their own, and raising their base would
## fight the grid's base→floor auto-grounding rather than read as height.
func _support_lift() -> float:
	return CONSOLE_LIFT if _support_native == "cabinet" else 0.0


# ── The face: bevel, border, image, glow, marks ───────────────────────

func _build_face(screen_y: float) -> void:
	var border_margin: float = 0.04
	var outer_margin: float = 0.07

	match surface:
		"curve":
			_build_face_curve(screen_y, border_margin, outer_margin)
		"triptych":
			_build_face_triptych(screen_y)
		"tiles":
			_build_face_tiles(screen_y, border_margin, outer_margin)
		_:
			_build_face_plane(screen_y, border_margin, outer_margin)

	# ── Screen glow light — makes the screen cast green light into the room ──
	var screen_light: OmniLight3D = OmniLight3D.new()
	screen_light.name = "ScreenGlow"
	screen_light.light_color = Color(0.3, 0.9, 0.5)  # green tint
	screen_light.light_energy = 0.6
	screen_light.omni_range = 4.0
	screen_light.omni_attenuation = 1.5
	screen_light.position = Vector3(0, screen_y, -0.3)  # slightly in front of screen
	screen_light.shadow_enabled = false
	_face_root.add_child(screen_light)

	_build_face_marks(screen_y, border_margin)


## Legacy face, node for node: a flat quad behind a flat border behind a flat
## bevel. The strongest claim to map-ness the artifact can make — no angle, no
## thickness, nothing of the room in it.
func _build_face_plane(screen_y: float, border_margin: float, outer_margin: float) -> void:
	# ── Outer bevel (dark, larger border for depth) ──
	var outer_bevel: MeshInstance3D = _flat_quad(
		Vector2(screen_width + outer_margin * 2, screen_height + outer_margin * 2), _bevel_mat())
	outer_bevel.position = Vector3(0, screen_y, -0.012)
	_face_root.add_child(outer_bevel)

	# ── Inner border frame (lighter) ──
	_border_mesh = _flat_quad(
		Vector2(screen_width + border_margin * 2, screen_height + border_margin * 2), _border_mat())
	_border_mesh.position = Vector3(0, screen_y, -0.008)
	_face_root.add_child(_border_mesh)

	# ── Screen quad (standing upright, face toward +Z) ──
	_screen_mesh = _image_panel(Vector2(screen_width, screen_height), Vector2.ZERO, Vector2.ONE)
	_screen_mesh.position = Vector3(0, screen_y, 0)
	_face_root.add_child(_screen_mesh)

	_face_half_w = screen_width * 0.5
	_brand_half_w = screen_width * 0.5


## The image gives up being a plane: the outer thirds bend toward the body, so
## the map admits it is being read from somewhere. The frame bends with it — a
## flat bezel behind a bent sheet reads as a bug, not as a decision.
func _build_face_curve(screen_y: float, border_margin: float, outer_margin: float) -> void:
	_bend_run(screen_y, screen_width + outer_margin * 2, screen_height + outer_margin * 2,
		CURVE_BOW * 1.06, -0.012, _bevel_mat(), false)
	_border_mesh = _bend_run(screen_y, screen_width + border_margin * 2, screen_height + border_margin * 2,
		CURVE_BOW * 1.03, -0.008, _border_mat(), false)
	_screen_mesh = _bend_run(screen_y, screen_width, screen_height,
		CURVE_BOW, 0.0, _placeholder_mat(), true)

	_face_half_w = screen_width * 0.5
	_brand_half_w = screen_width * 0.5


## One image, three framed panels, the wings hinged toward the viewer. You can
## no longer take the whole map in from one angle — the seams cost you the
## single glance and charge you a walk for it.
func _build_face_triptych(screen_y: float) -> void:
	var fold: float = deg_to_rad(FOLD_DEG)
	var mid_w: float = screen_width * 0.5
	var wing_w: float = screen_width * 0.25
	var hinge_x: float = mid_w * 0.5 + FOLD_SEAM

	_screen_mesh = _framed_panel(Vector3(0, screen_y, 0), 0.0,
		Vector2(mid_w, screen_height), Vector2(0.25, 0.0), Vector2(0.5, 1.0))

	for si in range(2):
		var s: float = -1.0 if si == 0 else 1.0
		# Local +X of each wing runs outward-and-forward, so the image continues
		# across the hinge instead of mirroring back on itself.
		var cx: float = s * (hinge_x + cos(fold) * wing_w * 0.5)
		var cz: float = sin(fold) * wing_w * 0.5
		var uo: float = 0.0 if s < 0.0 else 0.75
		_framed_panel(Vector3(cx, screen_y, cz), -s * fold,
			Vector2(wing_w, screen_height), Vector2(uo, 0.0), Vector2(0.25, 1.0))

	_face_half_w = hinge_x + cos(fold) * wing_w
	_brand_half_w = mid_w * 0.5


## The map arrives as a mosaic — one picture cut into a video wall with the
## seams left in. The gaps eat real image, which is the honest version: the
## flattening was always lossy and here it shows you exactly where.
func _build_face_tiles(screen_y: float, border_margin: float, outer_margin: float) -> void:
	var outer_bevel: MeshInstance3D = _flat_quad(
		Vector2(screen_width + outer_margin * 2, screen_height + outer_margin * 2), _bevel_mat())
	outer_bevel.position = Vector3(0, screen_y, -0.012)
	_face_root.add_child(outer_bevel)

	_border_mesh = _flat_quad(
		Vector2(screen_width + border_margin * 2, screen_height + border_margin * 2), _border_mat())
	_border_mesh.position = Vector3(0, screen_y, -0.008)
	_face_root.add_child(_border_mesh)

	var tw: float = (screen_width - TILE_GAP * float(TILE_COLS - 1)) / float(TILE_COLS)
	var th: float = (screen_height - TILE_GAP * float(TILE_ROWS - 1)) / float(TILE_ROWS)
	var top_y: float = screen_y + screen_height * 0.5

	for r in range(TILE_ROWS):
		for c in range(TILE_COLS):
			var px: float = -screen_width * 0.5 + tw * 0.5 + float(c) * (tw + TILE_GAP)
			var py: float = top_y - th * 0.5 - float(r) * (th + TILE_GAP)
			# UV sub-rect measured off the tile's own place in the full image, so
			# the gaps subtract from the picture rather than squeezing it.
			var uo: Vector2 = Vector2(
				(px - tw * 0.5 + screen_width * 0.5) / screen_width,
				(top_y - py - th * 0.5) / screen_height)
			var us: Vector2 = Vector2(tw / screen_width, th / screen_height)
			var relief: float = TILE_RELIEF if (r + c) % 2 == 0 else 0.0
			var tile: MeshInstance3D = _image_panel(Vector2(tw, th), uo, us)
			tile.position = Vector3(px, py, 0.004 + relief)
			_face_root.add_child(tile)
			if _screen_mesh == null:
				_screen_mesh = tile

	_face_half_w = screen_width * 0.5
	_brand_half_w = screen_width * 0.5


## LED and brand mark, placed against the face's REAL outline rather than against
## screen_width — otherwise a folded face leaves them hanging in the air where
## the flat one used to end. For `plane` these resolve to the legacy numbers.
func _build_face_marks(screen_y: float, border_margin: float) -> void:
	# ── LED indicator dot (top-right corner, small green sphere) ──
	var led_x: float = _face_half_w + border_margin + 0.01
	var led: MeshInstance3D = MeshInstance3D.new()
	var led_sphere: SphereMesh = SphereMesh.new()
	led_sphere.radius = 0.012
	led_sphere.height = 0.024
	led.mesh = led_sphere
	led.position = Vector3(led_x, screen_y + screen_height * 0.5 + border_margin - 0.01, _face_z_at(led_x) + 0.005)
	_face_root.add_child(led)

	var led_mat: StandardMaterial3D = StandardMaterial3D.new()
	led_mat.albedo_color = Color(0.2, 1.0, 0.3)
	led_mat.emission_enabled = true
	led_mat.emission = Color(0.2, 1.0, 0.3)
	led_mat.emission_energy_multiplier = 2.0
	led_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	led.material_override = led_mat

	# ── "ADA RESEARCH" brand mark (bottom-left of border) ──
	# Integrated 2D-in-3D board baked onto the bezel, replacing a floating Label3D.
	# Fixed orientation (billboard=false) so it reads as a printed mark on the frame.
	var brand_h: float = 0.048
	var brand_tag: Node3D = BakedText.make_tag(
		"ADA RESEARCH",
		Color(0.35, 0.35, 0.4),          # same dim text tone as the old modulate
		brand_h,
		Color(0.08, 0.08, 0.1),          # matches the outer bezel dark
		false,                            # fixed-orientation, not billboarded
		Color(0.2, 1.0, 0.3, 1.0)         # green accent edge, echoes the screen glow
	)
	if brand_tag:
		# make_tag auto-fits width ≈ world_h * (0.9 + 0.66*len); left-align the
		# board where the old Label3D's left edge sat.
		var brand_w: float = brand_h * (0.9 + 0.66 * float("ADA RESEARCH".length()))
		var brand_x: float = -_brand_half_w + 0.15 + brand_w * 0.5
		brand_tag.position = Vector3(
			brand_x,
			screen_y - screen_height * 0.5 - border_margin - 0.015,
			_face_z_at(brand_x) + 0.006
		)
		_face_root.add_child(brand_tag)


# ── Face parts ────────────────────────────────────────────────────────

func _bevel_mat() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(0.08, 0.08, 0.1)
	m.metallic = 0.8
	m.roughness = 0.2
	return m


func _border_mat() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = border_color
	m.metallic = 0.6
	m.roughness = 0.3
	return m


## Screen base material — replaced by the viewport texture one frame later.
func _placeholder_mat() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = screen_color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _flat_quad(size: Vector2, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var pm: PlaneMesh = PlaneMesh.new()
	pm.size = size
	pm.orientation = PlaneMesh.FACE_Z
	mi.mesh = pm
	mi.material_override = mat
	return mi


## A quad carrying one sub-rectangle of the SubViewport. PlaneMesh FACE_Z maps
## u left→right along +X and v top→bottom, so the sub-rects can be read straight
## off world positions without a flip.
func _image_panel(size: Vector2, uv_offset: Vector2, uv_scale: Vector2) -> MeshInstance3D:
	var mi: MeshInstance3D = _flat_quad(size, _placeholder_mat())
	_screen_panels.append({"mesh": mi, "uv_offset": uv_offset, "uv_scale": uv_scale})
	return mi


## One panel of a folded face, with its own bevel and border, so each leaf reads
## as a framed screen rather than as a torn corner of a big one.
func _framed_panel(center: Vector3, rot_y: float, size: Vector2,
		uv_offset: Vector2, uv_scale: Vector2) -> MeshInstance3D:
	var holder: Node3D = Node3D.new()
	holder.position = center
	holder.rotation = Vector3(0, rot_y, 0)
	_face_root.add_child(holder)

	var bevel: MeshInstance3D = _flat_quad(size + Vector2(0.10, 0.10), _bevel_mat())
	bevel.position = Vector3(0, 0, -0.012)
	holder.add_child(bevel)

	var border: MeshInstance3D = _flat_quad(size + Vector2(0.056, 0.056), _border_mat())
	border.position = Vector3(0, 0, -0.008)
	holder.add_child(border)
	if _border_mesh == null:
		_border_mesh = border

	var img: MeshInstance3D = _image_panel(size, uv_offset, uv_scale)
	holder.add_child(img)
	return img


## Lay a rectangle out as vertical strips bent into a shallow parabola whose
## edges reach `bow` metres toward the viewer. Strips rather than a hand-built
## ArrayMesh: PlaneMesh already gets the winding and the UVs right, and the
## faceting is invisible on an unshaded emissive face. Returns the middle strip.
func _bend_run(screen_y: float, w: float, h: float, bow: float, z_off: float,
		mat: StandardMaterial3D, is_image: bool) -> MeshInstance3D:
	var mid: MeshInstance3D = null
	var seg_w: float = w / float(CURVE_SEGS)
	var half: float = w * 0.5
	for i in range(CURVE_SEGS):
		var t: float = (float(i) + 0.5) / float(CURVE_SEGS)
		var a: float = (t - 0.5) * 2.0                    # -1 at the left edge, +1 at the right
		var x: float = -half + w * t
		var z: float = bow * a * a
		var slope: float = 4.0 * bow * a / w              # dz/dx of the parabola
		var tilt: float = atan(slope)
		# A tilted strip covers only cos(tilt) of the x-slot it owns, so at the
		# bent edges uniform-width strips tear open into dark hairlines. Widen
		# each strip by 1/cos(tilt) — plus 3% — so every slot stays covered.
		var strip_w: float = seg_w * 1.03 / maxf(cos(tilt), 0.25)
		var strip: MeshInstance3D
		if is_image:
			strip = _image_panel(Vector2(strip_w, h),
				Vector2(float(i) / float(CURVE_SEGS), 0.0),
				Vector2(1.0 / float(CURVE_SEGS), 1.0))
		else:
			strip = _flat_quad(Vector2(strip_w, h), mat)
		strip.position = Vector3(x, screen_y, z + z_off)
		strip.rotation = Vector3(0, -tilt, 0)
		_face_root.add_child(strip)
		if i == int(CURVE_SEGS / 2):
			mid = strip
	return mid


## The z the face reaches at a given x. Lets the LED and the brand mark sit ON
## whatever shape the surface has instead of floating where the flat one was.
func _face_z_at(x: float) -> float:
	if surface == "curve":
		var a: float = x / maxf(screen_width * 0.5, 0.001)
		return CURVE_BOW * a * a
	if surface == "triptych":
		var hinge_x: float = screen_width * 0.25 + FOLD_SEAM
		return maxf(absf(x) - hinge_x, 0.0) * tan(deg_to_rad(FOLD_DEG))
	return 0.0


# ── The support: what apparatus holds the flattening up ──────────────

## Dispatch on the RESOLVED value, never on the authored one. Every arm names a
## value this artifact really builds, and DEGRADE has already folded the other four
## canonical values onto one of them — so no member of the shared vocabulary can
## reach the wildcard. That wildcard is the pre-convergence legacy fallback and is
## now unreachable in practice; it is kept, and kept calling the stand builder
## rather than `pass`, so that a future ninth value fails visible rather than
## invisible.
func _build_support(screen_y: float, lift: float) -> void:
	match _support_native:
		"pylon":
			_build_support_pylon(screen_y)
		"cabinet":
			_build_support_cabinet(lift)
		"frame":
			_build_support_frame(screen_y)
		"stand":
			_build_support_stand(screen_y)
		_:
			_build_support_stand(screen_y)


## Legacy support: a thin pole and a small foot behind the panel. Provisional —
## something wheeled into the room for the duration of a lesson.
func _build_support_stand(screen_y: float) -> void:
	# ── Stand pole ──
	_stand_mesh = MeshInstance3D.new()
	var stand_box: BoxMesh = BoxMesh.new()
	stand_box.size = Vector3(0.06, screen_y, 0.06)
	_stand_mesh.mesh = stand_box
	_stand_mesh.position = Vector3(0, screen_y * 0.5, -0.08)
	add_child(_stand_mesh)

	var stand_mat: StandardMaterial3D = StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.15, 0.15, 0.18)
	stand_mat.metallic = 0.7
	stand_mat.roughness = 0.25
	_stand_mesh.material_override = stand_mat

	# ── Stand base (wider foot) ──
	var base_mesh: MeshInstance3D = MeshInstance3D.new()
	var base_box: BoxMesh = BoxMesh.new()
	base_box.size = Vector3(0.3, 0.02, 0.2)
	base_mesh.mesh = base_box
	base_mesh.position = Vector3(0, 0.01, -0.08)
	add_child(base_mesh)

	var base_mat: StandardMaterial3D = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.12, 0.12, 0.15)
	base_mat.metallic = 0.8
	base_mat.roughness = 0.2
	base_mesh.material_override = base_mat


## No pole, no foot: the display is not visiting the room, the room admits it.
## A mass of building — a floor-to-lintel slab with the screen sunk into a shadow
## reveal, a base course and a capping course. The image is unchanged and the claim
## is completely different: the building owns it, and contradicting it costs money.
func _build_support_pylon(screen_y: float) -> void:
	var top: float = screen_y + screen_height * 0.5 + 0.07
	var slab_w: float = screen_width + 0.9
	var slab_h: float = top + 0.34
	var slab_d: float = 0.16
	var front_z: float = -0.02

	var slab_mat: StandardMaterial3D = HangarKit.painted_metal(Color(0.17, 0.17, 0.20), 0.2, 0.28, 0.68)
	add_child(HangarKit.box(Vector3(0, slab_h * 0.5, front_z - slab_d * 0.5),
		Vector3(slab_w, slab_h, slab_d), slab_mat))

	# The reveal: a dark rim just proud of the slab, so the screen reads as SET
	# INTO the wall. A shadow gap does what a heavier bezel would, without adding
	# a second frame in front of the one the face already carries.
	var reveal_mat: StandardMaterial3D = HangarKit.painted_metal(Color(0.06, 0.06, 0.07), 0.1, 0.2, 0.8)
	add_child(HangarKit.box(Vector3(0, screen_y, front_z - 0.004),
		Vector3(screen_width + 0.30, screen_height + 0.30, 0.012), reveal_mat))

	var bolt_mat: StandardMaterial3D = HangarKit.worn_metal(Color(0.30, 0.31, 0.34))
	for si in range(2):
		var s: float = -1.0 if si == 0 else 1.0
		add_child(HangarKit.bolts(
			Vector3(s * (slab_w * 0.5 - 0.09), 0.22, front_z + 0.005),
			Vector3(s * (slab_w * 0.5 - 0.09), slab_h - 0.22, front_z + 0.005),
			6, 0.014, bolt_mat))

	var gb: MeshInstance3D = HangarKit.grime_band(slab_w * 0.9, 0.09, front_z + 0.005, Color(0.17, 0.17, 0.20))
	if gb:
		add_child(gb)

	var code: MeshInstance3D = HangarKit.stencil("VIEW 02", Vector2(0.26, 0.06), Color(0.42, 0.90, 0.55))
	if code:
		code.position = Vector3(-slab_w * 0.5 + 0.24, slab_h - 0.17, front_z + 0.007)
		add_child(code)


## The screen stops being a picture and becomes an instrument you stand at: a body
## of cabinetwork takes the floor, the face leans back off its lip at working
## height. The console television is the type specimen — a screen and a cabinet as
## one object. What it costs is the architectural reading: a door, a cap lip and a
## recessed toe kick cannot pass for building.
func _build_support_cabinet(lift: float) -> void:
	var cab_h: float = maxf(lift - 0.02, 0.2)
	var cab_w: float = screen_width * 0.94
	var cab_d: float = 0.62
	var front_z: float = 0.22
	var cz: float = front_z - cab_d * 0.5
	var kick_h: float = 0.09

	var body_mat: StandardMaterial3D = HangarKit.painted_metal(Color(0.20, 0.21, 0.24), 0.16, 0.4, 0.55)
	var dark_mat: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.11), 0.1, 0.4, 0.5)
	var trim_mat: StandardMaterial3D = HangarKit.worn_metal(Color(0.34, 0.35, 0.38))

	# Recessed toe kick first, then the body standing on it — the inset is what
	# makes the mass read as furniture instead of as a crate.
	add_child(HangarKit.box(Vector3(0, kick_h * 0.5, cz),
		Vector3(cab_w - 0.14, kick_h, cab_d - 0.10), dark_mat))
	add_child(HangarKit.box(Vector3(0, kick_h + (cab_h - kick_h) * 0.5, cz),
		Vector3(cab_w, cab_h - kick_h, cab_d), body_mat))
	# Cap lip the face sits on
	add_child(HangarKit.box(Vector3(0, cab_h + 0.018, cz),
		Vector3(cab_w + 0.06, 0.036, cab_d + 0.05), trim_mat))
	# Ember line under the lip — the same green the screen throws into the room
	add_child(HangarKit.box(Vector3(0, cab_h - 0.014, front_z + 0.004),
		Vector3(cab_w * 0.9, 0.008, 0.008), HangarKit.emissive(Color(0.2, 1.0, 0.3), 2.0)))

	# Sloped operator shelf, so the console has somewhere a hand would go
	var shelf: MeshInstance3D = HangarKit.wedge(cab_w * 0.66, 0.13, 0.26, 0.07, body_mat)
	shelf.position = Vector3(0, cab_h - 0.12, front_z)
	add_child(shelf)

	for si in range(2):
		var s: float = -1.0 if si == 0 else 1.0
		add_child(HangarKit.box(Vector3(s * cab_w * 0.30, cab_h * 0.45, front_z + 0.03),
			Vector3(0.18, 0.035, 0.06), trim_mat))


## An open upright structure standing AROUND the screen: posts either side, side
## collars gripping the panel, cross braces and a head beam. Bracketed, not
## enclosed — you can see the room straight through it, which is what makes it
## admit out loud that this is staged. No furniture, no building, and it could be
## struck tomorrow.
func _build_support_frame(screen_y: float) -> void:
	var top: float = screen_y + screen_height * 0.5 + 0.07
	var post_h: float = top + 0.40
	var post_x: float = screen_width * 0.5 + 0.20
	var post_z: float = -0.07

	var post_mat: StandardMaterial3D = HangarKit.painted_metal(Color(0.22, 0.23, 0.26), 0.22, 0.5, 0.5)
	var clamp_mat: StandardMaterial3D = HangarKit.worn_metal(Color(0.33, 0.34, 0.37))
	var collar_y: PackedFloat32Array = PackedFloat32Array([
		screen_y - screen_height * 0.32, screen_y + screen_height * 0.32])
	var brace_y: PackedFloat32Array = PackedFloat32Array([top * 0.26, top * 0.90])

	for si in range(2):
		var s: float = -1.0 if si == 0 else 1.0
		add_child(HangarKit.box(Vector3(s * post_x, post_h * 0.5, post_z),
			Vector3(0.10, post_h, 0.10), post_mat))
		add_child(HangarKit.box(Vector3(s * post_x, 0.016, post_z),
			Vector3(0.36, 0.032, 0.32), clamp_mat))
		for cy in collar_y:
			# Collars reach in toward the panel edge — the structure visibly grips
			# the panel rather than the panel floating between two poles.
			add_child(HangarKit.box(Vector3(s * (post_x - 0.07), cy, post_z),
				Vector3(0.16, 0.11, 0.14), clamp_mat))

	for by in brace_y:
		add_child(HangarKit.box(Vector3(0, by, post_z - 0.11),
			Vector3(post_x * 2.0, 0.06, 0.06), post_mat))

	# Top tie bar, above the screen — the head beam that makes it read as one frame
	# and not as two unrelated poles that happen to stand there.
	add_child(HangarKit.box(Vector3(0, post_h - 0.06, post_z),
		Vector3(post_x * 2.0 + 0.10, 0.08, 0.08), clamp_mat))

func _build_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(VP_WIDTH, VP_HEIGHT)
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.canvas_item_default_texture_filter = SubViewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_viewport)

	_canvas = _ScreenCanvas.new()
	_canvas.screen_ref = self
	_canvas.size = Vector2(VP_WIDTH, VP_HEIGHT)
	_viewport.add_child(_canvas)

func _apply_viewport_to_screen() -> void:
	if not _viewport or _screen_panels.is_empty():
		return
	var tex: ViewportTexture = _viewport.get_texture()
	for entry in _screen_panels:
		var mi: MeshInstance3D = entry["mesh"]
		if not is_instance_valid(mi):
			continue
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.emission_enabled = true
		mat.emission_texture = tex
		mat.emission_energy_multiplier = 4.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# One SubViewport, many panels: each panel samples its own sub-rectangle,
		# so a folded or tiled face shows ONE image broken across surfaces rather
		# than N copies of the same picture. Identity remap on the flat default.
		var uo: Vector2 = entry["uv_offset"]
		var us: Vector2 = entry["uv_scale"]
		mat.uv1_scale = Vector3(us.x, us.y, 1.0)
		mat.uv1_offset = Vector3(uo.x, uo.y, 0.0)
		mi.material_override = mat


# ═══════════════════════════════════════════════════════════════════
# ARTIFACT SCANNING
# ═══════════════════════════════════════════════════════════════════

func _scan_for_artifacts() -> void:
	var best_node: Node = null
	var best_dist: float = scan_radius + 1.0

	# Walk siblings and their children looking for grid-aware artifacts
	var parent := get_parent()
	if not parent:
		return

	var my_pos := global_position
	_scan_subtree(parent, my_pos, best_dist, best_node)

	if best_node:
		_extract_grid_data(best_node)

## Recursively scan a subtree for the nearest artifact with grid data
func _scan_subtree(node: Node, origin: Vector3, best_dist: float, best_node: Node) -> void:
	for child in node.get_children():
		if child == self:
			continue
		if child is Node3D and child.has_method("apply_grid_config"):
			var d: float = origin.distance_to((child as Node3D).global_position)
			if d < best_dist and d < scan_radius:
				best_dist = d
				best_node = child
				_source_artifact_name = child.name
		# Also check grandchildren (one level deeper)
		for grandchild in child.get_children():
			if grandchild == self:
				continue
			if grandchild is Node3D and grandchild.has_method("apply_grid_config"):
				var d: float = origin.distance_to((grandchild as Node3D).global_position)
				if d < best_dist and d < scan_radius:
					best_dist = d
					best_node = grandchild
					_source_artifact_name = grandchild.name

func _scan_for_points() -> void:
	## Look for nearby pickable points (XRToolsPickable with position data)
	var parent := get_parent()
	if not parent:
		return
	var my_pos := global_position
	_scan_point_subtree(parent, my_pos)

func _scan_point_subtree(node: Node, origin: Vector3) -> void:
	for child in node.get_children():
		if child == self:
			continue
		if child is Node3D:
			var lookup: String = str(child.get_meta("artifact_lookup_name", ""))
			var is_point: bool = "point" in lookup or "point" in child.name.to_lower()
			if is_point and child.get("freeze") != null:
				var d: float = origin.distance_to(child.global_position)
				if d < scan_radius:
					_tracking_point = child
					_point_mode = true
					_label_name = "POINT TRACKER"
					_source_artifact_name = lookup if lookup != "" else child.name
					print("[ScienceScreen] Tracking point: %s" % _source_artifact_name)
					return
		for grandchild in child.get_children():
			if grandchild is Node3D:
				var lookup: String = str(grandchild.get_meta("artifact_lookup_name", ""))
				var is_point: bool = "point" in lookup or "point" in grandchild.name.to_lower()
				if is_point and grandchild.get("freeze") != null:
					var d: float = origin.distance_to(grandchild.global_position)
					if d < scan_radius:
						_tracking_point = grandchild
						_point_mode = true
						_label_name = "POINT TRACKER"
						_source_artifact_name = lookup if lookup != "" else grandchild.name
						print("[ScienceScreen] Tracking point: %s" % _source_artifact_name)
						return


## ── Line scanning: find artifacts with "line" in lookup_name that have two grabbable points ──
func _scan_for_lines() -> void:
	var parent: Node = get_parent()
	if not parent:
		return
	var my_pos: Vector3 = global_position
	for child in parent.get_children():
		if child == self or not (child is Node3D):
			continue
		var lookup: String = str(child.get_meta("artifact_lookup_name", ""))
		var cname: String = child.name.to_lower()
		var is_line: bool = "line" in lookup or "line" in cname
		if not is_line:
			continue
		var d: float = my_pos.distance_to(child.global_position)
		if d > scan_radius:
			continue
		# Find two grabbable points anywhere in subtree (GrabSphere, RigidBody3D with freeze)
		var points: Array[Node3D] = []
		_find_grabbable_points(child, points)
		if points.size() >= 2:
			_tracking_line_p1 = points[0]
			_tracking_line_p2 = points[1]
			_line_mode = true
			_label_name = "LINE ANALYZER"
			_source_artifact_name = lookup if lookup != "" else child.name
			print("[ScienceScreen] Tracking line: %s (p1=%s, p2=%s)" % [_source_artifact_name, points[0].name, points[1].name])
			return


## Recursively find grabbable nodes (RigidBody3D / XRToolsPickable) in a subtree
func _find_grabbable_points(node: Node, results: Array[Node3D], depth: int = 0) -> void:
	if depth > 4:
		return
	for child in node.get_children():
		if child is Node3D and child.get("freeze") != null:
			results.append(child as Node3D)
		_find_grabbable_points(child, results, depth + 1)

## ── Draw dot scanning: find artifacts with "draw_dot" in lookup_name ──
func _scan_for_draw_dot() -> void:
	var parent: Node = get_parent()
	if not parent:
		return
	var my_pos: Vector3 = global_position
	for child in parent.get_children():
		if child == self or not (child is Node3D):
			continue
		var lookup: String = str(child.get_meta("artifact_lookup_name", ""))
		var cname: String = child.name.to_lower()
		var is_draw: bool = "draw_dot" in lookup or "draw_dot" in cname or "draw" in lookup
		if not is_draw:
			continue
		var d: float = my_pos.distance_to(child.global_position)
		if d > scan_radius:
			continue
		_tracking_draw_dot = child as Node3D
		_draw_mode = true
		_label_name = "DRAW PATH TRACER"
		_source_artifact_name = lookup if lookup != "" else child.name
		print("[ScienceScreen] Tracking draw_dot: %s" % _source_artifact_name)
		return

## ── Triangle scanning: find artifacts with "triangle" in lookup_name ──
func _scan_for_triangles() -> void:
	var parent: Node = get_parent()
	if not parent:
		return
	var my_pos: Vector3 = global_position
	for child in parent.get_children():
		if child == self or not (child is Node3D):
			continue
		var lookup: String = str(child.get_meta("artifact_lookup_name", ""))
		var cname: String = child.name.to_lower()
		var is_tri: bool = "triangle" in lookup or "triangle" in cname
		if not is_tri:
			continue
		var d: float = my_pos.distance_to(child.global_position)
		if d > scan_radius:
			continue
		# Collect child points (vertices)
		var verts: Array[Node3D] = []
		for sub in child.get_children():
			if sub is Node3D:
				var sn: String = sub.name.to_lower()
				if "point" in sn or "vertex" in sn or "vert" in sn or sub.get("freeze") != null:
					verts.append(sub as Node3D)
		if verts.size() >= 3:
			_tracking_tri_points = [verts[0], verts[1], verts[2]]
			_triangle_mode = true
			_label_name = "TRIANGLE ANALYZER"
			_source_artifact_name = lookup if lookup != "" else child.name
			print("[ScienceScreen] Tracking triangle: %s" % _source_artifact_name)
			return

## ── Generic scanning: catch-all for sorting, noise, wave, force, fractal, swarm, graph, mesh ──
func _scan_for_generic() -> void:
	var parent: Node = get_parent()
	if not parent:
		return
	var my_pos: Vector3 = global_position
	var keywords: PackedStringArray = PackedStringArray([
		"sort", "noise", "wave", "force", "fractal", "swarm", "graph", "mesh",
		"boid", "flock", "particle", "field", "oscillat", "pendulum", "spring"
	])
	for child in parent.get_children():
		if child == self or not (child is Node3D):
			continue
		var lookup: String = str(child.get_meta("artifact_lookup_name", ""))
		var cname: String = child.name.to_lower()
		var combined: String = lookup.to_lower() + " " + cname
		var matched: bool = false
		var match_word: String = ""
		for kw in keywords:
			if kw in combined:
				matched = true
				match_word = kw
				break
		if not matched:
			continue
		var d: float = my_pos.distance_to(child.global_position)
		if d > scan_radius:
			continue
		_tracking_generic = child as Node3D
		_generic_mode = true
		_generic_mode_name = match_word
		_label_name = match_word.to_upper() + " MONITOR"
		_source_artifact_name = lookup if lookup != "" else child.name
		print("[ScienceScreen] Tracking generic (%s): %s" % [match_word, _source_artifact_name])
		return


func _extract_grid_data(node: Node) -> void:
	# Try to read grid dimensions from common patterns
	_grid_cols = 0
	_grid_rows = 0
	_grid_cells = []
	_cell_count = 0
	_pattern_type = "unknown"

	# Check for known grid properties
	if "grid_width" in node:
		_grid_cols = int(node.get("grid_width"))
	elif "cols" in node:
		_grid_cols = int(node.get("cols"))
	elif "width" in node:
		var w = node.get("width")
		if w is int or w is float:
			_grid_cols = int(w)

	if "grid_height" in node:
		_grid_rows = int(node.get("grid_height"))
	elif "rows" in node:
		_grid_rows = int(node.get("rows"))
	elif "height" in node:
		var h = node.get("height")
		if h is int or h is float:
			_grid_rows = int(h)

	# Check for cell/grid data arrays
	if "cells" in node:
		var c = node.get("cells")
		if c is Array:
			_grid_cells = c
			_cell_count = _count_active_cells(c)
	elif "grid" in node:
		var g = node.get("grid")
		if g is Array:
			_grid_cells = g
			_cell_count = _count_active_cells(g)

	# Check for pattern/algorithm type
	if "algorithm_name" in node:
		_pattern_type = str(node.get("algorithm_name"))
	elif "pattern_type" in node:
		_pattern_type = str(node.get("pattern_type"))
	elif "rule" in node:
		_pattern_type = "Rule %s" % str(node.get("rule"))

	# Fallback: generate a representative grid from the artifact class name
	if _grid_cols == 0 and _grid_rows == 0:
		_grid_cols = 8
		_grid_rows = 8
		_pattern_type = _classify_artifact(node)
		_generate_representative_grid(node)

	_label_name = _override_label if _override_label != "" else _source_artifact_name

func _count_active_cells(data: Array) -> int:
	var count := 0
	for row in data:
		if row is Array:
			for cell in row:
				if cell is int and cell > 0:
					count += 1
				elif cell is bool and cell:
					count += 1
				elif cell is float and cell > 0.0:
					count += 1
		elif row is int and row > 0:
			count += 1
	return count

func _classify_artifact(node: Node) -> String:
	var class_str: String = node.get_class() if node.get_class() != "Node3D" else node.name
	class_str = class_str.to_snake_case().replace("_", " ")
	return class_str

func _generate_representative_grid(node: Node) -> void:
	# Create a hash-based pattern from the artifact's properties
	var seed_val: int = hash(node.name) if node else 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	_grid_cells = []
	_cell_count = 0
	for y in range(_grid_rows):
		var row: Array = []
		for x in range(_grid_cols):
			var val: int = 0
			# Create structured patterns rather than pure noise
			var cx := x - _grid_cols / 2
			var cy := y - _grid_rows / 2
			var dist := sqrt(float(cx * cx + cy * cy))

			match (seed_val % 4):
				0:  # Concentric rings
					val = int(dist) % 3
				1:  # Diagonal stripes
					val = (x + y) % 3
				2:  # Checker
					val = (x + y) % 2 * 2
				3:  # Radial sectors
					var angle := atan2(float(cy), float(cx))
					val = int((angle + PI) / (PI * 2.0) * 4.0) % 3

			if val > 0:
				_cell_count += 1
			row.append(val)
		_grid_cells.append(row)


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("screen_width"):
		screen_width = clampf(float(config_data["screen_width"]), 0.5, 4.0)
	if config_data.has("screen_height"):
		screen_height = clampf(float(config_data["screen_height"]), 0.5, 3.0)
	if config_data.has("scan_radius"):
		scan_radius = clampf(float(config_data["scan_radius"]), 1.0, 20.0)
	if config_data.has("label"):
		_override_label = str(config_data["label"])
	if config_data.has("highlight"):
		highlight_color = _parse_color(str(config_data["highlight"]), highlight_color)
	if config_data.has("border"):
		border_color = _parse_color(str(config_data["border"]), border_color)
	if config_data.has("bg"):
		screen_color = _parse_color(str(config_data["bg"]), screen_color)

	# Stage-2 DNA axes — #support:cabinet, #surface:triptych
	# No `#housing:` fallback. The census found zero maps carrying it, and a retired
	# token that still resolves is exactly how one word came to select two different
	# axes in the exhibits family. Retired means gone.
	if config_data.has("support"):
		support = _pick_support(str(config_data["support"]))
	if config_data.has("surface"):
		surface = _pick_axis(str(config_data["surface"]), SURFACES, surface)

	# Resolve here as well as in _build_screen so the log line below reports what
	# will actually be built — _rebuild() is deferred a frame.
	_resolve_support()

	# Explicit mode from map JSON — skips all scanning
	if config_data.has("mode"):
		var mode_str: String = str(config_data["mode"]).to_lower().strip_edges()
		_set_explicit_mode(mode_str)

	# Rebuild with new dimensions
	_rebuild()
	# Report both when they differ, so a degrade is stated in the log rather than
	# discovered by looking at a screenshot and wondering.
	var support_str: String = support
	if support != _support_native:
		support_str = "%s -> %s" % [support, _support_native]
	print("[ScienceScreen] Config applied — %sx%s, mode=%s, support=%s, surface=%s" % [
		screen_width, screen_height, _get_active_mode(), support_str, surface])


## Read a `support` token: fold a retired spelling onto its canonical one, then
## accept it if it names any of the eight shared values. The allow-list is the FULL
## vocabulary, not just what this screen builds — a sibling's gesture is a real
## request and gets answered by DEGRADE, not thrown away. Only a value outside all
## eight falls back, and that case is a typo.
func _pick_support(raw: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	v = str(SUPPORT_ALIASES.get(v, v))
	return _pick_axis(v, SUPPORTS, support)


## Accept an axis value only if it names something we actually build. A typo in a
## map token has to fall back to the legacy look — a half-recognised value would
## strand a placement with no support at all.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() == 3:
		return Color(
			clampf(parts[0].strip_edges().to_float(), 0.0, 1.0),
			clampf(parts[1].strip_edges().to_float(), 0.0, 1.0),
			clampf(parts[2].strip_edges().to_float(), 0.0, 1.0)
		)
	return Color.from_string(s, fallback)

func _rebuild() -> void:
	# Remove old nodes
	for child in get_children():
		child.queue_free()
	# Rebuild next frame after queue_free completes
	call_deferred("_deferred_rebuild")

func _deferred_rebuild() -> void:
	_build_screen()
	_build_viewport()
	_apply_viewport_to_screen()
	# Do NOT scan for artifacts here — respect the locked mode
	# The initial scan in _deferred_first_scan handles mode detection


# ═══════════════════════════════════════════════════════════════════
# 2D CANVAS (draws inside SubViewport)
# ═══════════════════════════════════════════════════════════════════

class _ScreenCanvas extends Control:
	var screen_ref: ScienceScreen

	# Color palette for cell values
	var CELL_COLORS: Array = [
		Color(0.05, 0.05, 0.08),   # 0 — empty/background
		Color(0.2, 0.8, 0.4),      # 1 — primary (green)
		Color(0.3, 0.5, 0.9),      # 2 — secondary (blue)
		Color(0.9, 0.4, 0.2),      # 3 — tertiary (orange)
		Color(0.8, 0.2, 0.7),      # 4 — quaternary (magenta)
	]

	func _draw() -> void:
		if not screen_ref:
			return

		var vp_size: Vector2 = size
		var font: Font = ThemeDB.fallback_font

		# ── CHECK MODES FIRST — each mode draws its own full screen ──
		var grid_top: float = 60.0
		var grid_margin: float = 16.0
		var grid_area: Vector2 = Vector2(vp_size.x - grid_margin * 2, vp_size.y - grid_top - grid_margin)

		# Point mode — white coordinate grid with point game
		if screen_ref._point_mode:
			_draw_point_tracker(vp_size, grid_top, grid_margin, grid_area, font)
			return

		# Line mode — draw even without tracking (shows zeroed coordinate grid)
		if screen_ref._line_mode:
			_draw_line_tracker(vp_size, grid_top, grid_margin, grid_area, font)
			return

		# Trace/draw mode — draw even without tracking
		if screen_ref._draw_mode:
			_draw_dot_tracker(vp_size, grid_top, grid_margin, grid_area, font)
			return

		# Triangle mode
		if screen_ref._triangle_mode:
			_draw_triangle_tracker(vp_size, grid_top, grid_margin, grid_area, font)
			return

		# Generic tracking — dispatch by mode name
		if screen_ref._generic_mode:
			match screen_ref._generic_mode_name:
				"net":
					_draw_net_tracker(vp_size, grid_top, grid_margin, grid_area, font)
				"wave":
					_draw_wave_tracker(vp_size, grid_top, grid_margin, grid_area, font)
				"field":
					_draw_field_tracker(vp_size, grid_top, grid_margin, grid_area, font)
				"scatter":
					_draw_scatter_tracker(vp_size, grid_top, grid_margin, grid_area, font)
				"grid":
					_draw_grid_tracker(vp_size, grid_top, grid_margin, grid_area, font)
				"bars":
					_draw_bars_tracker(vp_size, grid_top, grid_margin, grid_area, font)
				_:
					_draw_generic_tracker(vp_size, grid_top, grid_margin, grid_area, font)
			return

		# ── FALLBACK: grid mode (only if no mode matched) ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), screen_ref.screen_color)
		var header_h: float = 32.0
		draw_rect(Rect2(0, 0, vp_size.x, header_h), Color(0.08, 0.08, 0.12))
		var title: String = screen_ref._label_name if screen_ref._label_name != "" else "SCIENCE SCREEN"
		draw_string(font, Vector2(8, 22), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, screen_ref.highlight_color)
		var status_y: float = header_h + 16
		var status: String = "%dx%d  |  %s  |  %d cells" % [
			screen_ref._grid_cols, screen_ref._grid_rows,
			screen_ref._pattern_type, screen_ref._cell_count
		]
		draw_string(font, Vector2(8, status_y), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.5, 0.55))

		if screen_ref._grid_cols > 0 and screen_ref._grid_rows > 0:
			var cell_w := grid_area.x / float(screen_ref._grid_cols)
			var cell_h := grid_area.y / float(screen_ref._grid_rows)
			var cell_size := minf(cell_w, cell_h)

			# Center the grid
			var total_w := cell_size * screen_ref._grid_cols
			var total_h := cell_size * screen_ref._grid_rows
			var ox := grid_margin + (grid_area.x - total_w) * 0.5
			var oy := grid_top + (grid_area.y - total_h) * 0.5

			# Draw grid background
			draw_rect(Rect2(ox - 1, oy - 1, total_w + 2, total_h + 2), screen_ref.grid_color)

			# Draw cells
			for row_idx in range(screen_ref._grid_rows):
				if row_idx >= screen_ref._grid_cells.size():
					break
				var row = screen_ref._grid_cells[row_idx]
				if not row is Array:
					continue
				for col_idx in range(screen_ref._grid_cols):
					if col_idx >= row.size():
						break
					var val: int = int(row[col_idx]) if row[col_idx] is int or row[col_idx] is float else 0
					var color: Color = CELL_COLORS[val % CELL_COLORS.size()]

					# Use highlight color for value 1
					if val == 1:
						color = screen_ref.highlight_color

					var cell_rect := Rect2(
						ox + col_idx * cell_size + 0.5,
						oy + row_idx * cell_size + 0.5,
						cell_size - 1.0,
						cell_size - 1.0
					)
					draw_rect(cell_rect, color)

			# Grid lines (subtle)
			var line_color := Color(screen_ref.grid_color, 0.3)
			for c in range(screen_ref._grid_cols + 1):
				var lx := ox + c * cell_size
				draw_line(Vector2(lx, oy), Vector2(lx, oy + total_h), line_color, 0.5)
			for r in range(screen_ref._grid_rows + 1):
				var ly := oy + r * cell_size
				draw_line(Vector2(ox, ly), Vector2(ox + total_w, ly), line_color, 0.5)
		else:
			# No data — show waiting message
			var msg := "Scanning for artifacts..."
			draw_string(font, Vector2(vp_size.x * 0.5 - 60, vp_size.y * 0.5), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.3, 0.35))

	# Dark instrument colors (shared across all modes)
	# Instrument palette — BRIGHT for VR (4x emission + OmniLight on screen)
	const I_BG := Color(0.1, 0.18, 0.12)           # lighter green bg
	const I_PANEL := Color(0.15, 0.32, 0.2)        # light green panel — glows strongly
	const I_PANEL_BORDER := Color(0.5, 1.0, 0.65, 0.8)    # bright green border
	const I_GRID_MINOR := Color(0.25, 1.0, 0.5, 0.3)      # green grid
	const I_GRID_MAJOR := Color(0.3, 1.0, 0.55, 0.6)      # green grid quarter lines — bold
	const I_AXIS_X := Color(1.0, 0.5, 0.5)         # bright red
	const I_AXIS_Y := Color(0.4, 1.0, 0.6)         # bright green
	const I_DOT := Color(0.8, 0.65, 1.0)           # bright violet
	const I_CYAN := Color(0.55, 1.0, 1.0)          # bright cyan
	const I_AMBER := Color(1.0, 0.75, 0.2)         # bright amber
	const I_TEXT := Color(1.0, 1.0, 1.0)            # white text
	const I_DIM := Color(0.7, 0.8, 0.75)           # readable dim
	const I_MUTED := Color(0.45, 0.6, 0.5)         # visible muted
	const I_CORNER := 18.0

	func _draw_corner_brackets(ox: float, oy: float, side: float) -> void:
		var L: float = I_CORNER
		var c: Color = I_PANEL_BORDER
		draw_line(Vector2(ox, oy + L), Vector2(ox, oy), c, 2.0)
		draw_line(Vector2(ox, oy), Vector2(ox + L, oy), c, 2.0)
		draw_line(Vector2(ox + side - L, oy), Vector2(ox + side, oy), c, 2.0)
		draw_line(Vector2(ox + side, oy), Vector2(ox + side, oy + L), c, 2.0)
		draw_line(Vector2(ox, oy + side - L), Vector2(ox, oy + side), c, 2.0)
		draw_line(Vector2(ox, oy + side), Vector2(ox + L, oy + side), c, 2.0)
		draw_line(Vector2(ox + side - L, oy + side), Vector2(ox + side, oy + side), c, 2.0)
		draw_line(Vector2(ox + side, oy + side), Vector2(ox + side, oy + side - L), c, 2.0)

	func _draw_instrument_header(vp_size: Vector2, font: Font, title: String, formula: String, score_val: int) -> void:
		draw_rect(Rect2(0, 0, vp_size.x, 38), I_PANEL)
		draw_line(Vector2(0, 38), Vector2(vp_size.x, 38), I_PANEL_BORDER, 2.0)
		draw_string(font, Vector2(14, 26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_TEXT)
		draw_string(font, Vector2(vp_size.x * 0.4, 26), formula, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, I_CYAN)
		draw_string(font, Vector2(vp_size.x - 130, 26), "SCORE %03d" % score_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, I_DIM)

	# Layout constants
	const INFO_H := 64.0    # bottom info bar height
	const HEADER_H := 38.0  # top header height
	const DATA_W := 220.0   # right data panel width
	const PAD := 6.0        # spacing between panels

	## Returns {ox, oy, side, cx, cy, data_x, data_y, data_w, data_h, info_y} — full layout metrics
	func _draw_instrument_grid(vp_size: Vector2, font: Font, grid_range: float) -> Dictionary:
		var grid_top_y: float = HEADER_H + PAD
		# Grid is square, left-aligned, leaving room for data panel on right and info bar at bottom
		var available_h: float = vp_size.y - grid_top_y - INFO_H - PAD * 2
		var available_w: float = vp_size.x - DATA_W - PAD * 3
		var side: float = minf(available_w, available_h)
		var ox: float = PAD + (available_w - side) * 0.5
		var oy: float = grid_top_y + (available_h - side) * 0.5
		var cx: float = ox + side * 0.5
		var cy: float = oy + side * 0.5

		# Data panel position (right of grid)
		var data_x: float = ox + side + PAD
		var data_y: float = grid_top_y
		var data_w: float = vp_size.x - data_x - PAD
		var data_h: float = available_h

		# Info bar position (bottom)
		var info_y: float = vp_size.y - INFO_H

		# Grid surface + outline
		draw_rect(Rect2(ox, oy, side, side), I_PANEL)
		draw_rect(Rect2(ox, oy, side, side), I_PANEL_BORDER, false, 2.0)

		# Minor grid (10 divisions)
		var step: float = side / 10.0
		for i in range(1, 10):
			var p: float = float(i) * step
			draw_line(Vector2(ox + p, oy), Vector2(ox + p, oy + side), I_GRID_MINOR, 1.0)
			draw_line(Vector2(ox, oy + p), Vector2(ox + side, oy + p), I_GRID_MINOR, 1.0)

		# Quarter lines (brighter)
		for frac in [0.25, 0.75]:
			draw_line(Vector2(ox + side * frac, oy), Vector2(ox + side * frac, oy + side), I_GRID_MAJOR, 1.5)
			draw_line(Vector2(ox, oy + side * frac), Vector2(ox + side, oy + side * frac), I_GRID_MAJOR, 1.5)

		# Axes
		draw_line(Vector2(ox, cy), Vector2(ox + side, cy), I_AXIS_X, 2.0)
		draw_line(Vector2(cx, oy), Vector2(cx, oy + side), I_AXIS_Y, 2.0)

		# Corner brackets
		_draw_corner_brackets(ox, oy, side)

		# Axis labels
		draw_string(font, Vector2(ox + side + 6, cy + 6), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, I_AXIS_X)
		draw_string(font, Vector2(cx - 4, oy - 6), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, I_AXIS_Y)

		# Scale ticks
		var rl: String = "%.1f" % grid_range
		draw_string(font, Vector2(ox - 4, cy + 16), "-%s" % rl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
		draw_string(font, Vector2(ox + side - 20, cy + 16), rl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
		draw_string(font, Vector2(cx + 5, oy + 13), rl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
		draw_string(font, Vector2(cx + 5, oy + side - 3), "-%s" % rl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)

		# Data panel background
		draw_rect(Rect2(data_x, data_y, data_w, data_h), I_PANEL)
		draw_rect(Rect2(data_x, data_y, data_w, data_h), I_PANEL_BORDER, false, 2.0)

		# Info bar background
		draw_rect(Rect2(0, info_y, vp_size.x, INFO_H), I_PANEL)
		draw_rect(Rect2(0, info_y, vp_size.x, INFO_H), I_PANEL_BORDER, false, 2.0)

		return {"ox": ox, "oy": oy, "side": side, "cx": cx, "cy": cy,
				"data_x": data_x, "data_y": data_y, "data_w": data_w, "data_h": data_h,
				"info_y": info_y}

	## Draw labeled values in the data panel — entries is [{label, value, color}]
	func _draw_data_panel(font: Font, g: Dictionary, entries: Array, title: String = "DATA") -> void:
		var dx: float = g["data_x"]
		var dy: float = g["data_y"]
		var dw: float = g["data_w"]
		# Title
		draw_string(font, Vector2(dx + 10, dy + 18), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, I_DIM)
		draw_line(Vector2(dx + 8, dy + 24), Vector2(dx + dw - 8, dy + 24), Color(I_PANEL_BORDER, 0.3), 1.0)
		# Entries
		var y_off: float = 42.0
		for entry in entries:
			var label: String = entry.get("label", "")
			var value: String = entry.get("value", "")
			var col: Color = entry.get("color", I_TEXT)
			draw_string(font, Vector2(dx + 10, dy + y_off), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
			draw_string(font, Vector2(dx + 10, dy + y_off + 16), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
			y_off += 40.0

	## Draw info/explain text in the bottom bar
	func _draw_info_bar(font: Font, vp_size: Vector2, info_y: float, text_line1: String, text_line2: String = "") -> void:
		draw_string(font, Vector2(14, info_y + 20), text_line1, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, I_TEXT)
		if text_line2 != "":
			draw_string(font, Vector2(14, info_y + 40), text_line2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)

	func _draw_point_tracker(vp_size: Vector2, grid_top: float, margin: float, area: Vector2, font: Font) -> void:
		var pos: Vector3 = Vector3.ZERO
		if is_instance_valid(screen_ref._tracking_point):
			pos = screen_ref._tracking_point.global_position - screen_ref._point_origin
		var grid_range: float = 2.0

		# ── Dark background ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), I_BG)

		# ── Header + grid ──
		_draw_instrument_header(vp_size, font, "POINT POSITION", "P = (x, y)", screen_ref._point_score)
		var g: Dictionary = _draw_instrument_grid(vp_size, font, grid_range)
		var ox: float = g["ox"]; var oy: float = g["oy"]; var side: float = g["side"]
		var cx: float = g["cx"]; var cy: float = g["cy"]

		# ── Map position (negate X: screen faces player at 180) ──
		var dot_x: float = cx - (pos.x / grid_range) * (side * 0.5)
		var dot_y: float = cy - (pos.y / grid_range) * (side * 0.5)

		# ── Trail ──
		if screen_ref._point_trail.size() > 1:
			var n: int = screen_ref._point_trail.size()
			for i in range(n - 1):
				var t0: Vector3 = screen_ref._point_trail[i]
				var t1: Vector3 = screen_ref._point_trail[i + 1]
				var tx0: float = cx - (t0.x / grid_range) * (side * 0.5)
				var ty0: float = cy - (t0.y / grid_range) * (side * 0.5)
				var tx1: float = cx - (t1.x / grid_range) * (side * 0.5)
				var ty1: float = cy - (t1.y / grid_range) * (side * 0.5)
				var t: float = float(i) / float(n)
				draw_line(Vector2(tx0, ty0), Vector2(tx1, ty1), Color(I_DOT, 0.1 + t * 0.6), 1.0 + t * 1.5)

		# ── Target ──
		if not screen_ref._point_exploding and screen_ref._point_target != Vector3.ZERO:
			var tgt: Vector3 = screen_ref._point_target
			var tgt_x: float = cx - (tgt.x / grid_range) * (side * 0.5)
			var tgt_y: float = cy - (tgt.y / grid_range) * (side * 0.5)
			var pulse: float = sin(Time.get_ticks_msec() / 300.0) * 3.0
			var tgt_col: Color = screen_ref._point_target_color
			draw_circle(Vector2(tgt_x, tgt_y), 22.0 + pulse, Color(tgt_col, 0.15))
			draw_circle(Vector2(tgt_x, tgt_y), 14.0, Color(tgt_col, 0.35))
			draw_circle(Vector2(tgt_x, tgt_y), 4.0, tgt_col)
			# Crosshair
			draw_line(Vector2(tgt_x - 28, tgt_y), Vector2(tgt_x + 28, tgt_y), Color(tgt_col, 0.15), 1.0)
			draw_line(Vector2(tgt_x, tgt_y - 28), Vector2(tgt_x, tgt_y + 28), Color(tgt_col, 0.15), 1.0)
			# Distance line
			draw_line(Vector2(dot_x, dot_y), Vector2(tgt_x, tgt_y), Color(tgt_col, 0.1), 1.0)

		# ── Particles ──
		for p_data in screen_ref._point_particles:
			var p_pos: Vector3 = p_data["pos"]
			var p_life: float = p_data["life"]
			var p_color: Color = p_data["color"]
			var p_sx: float = cx - (p_pos.x / grid_range) * (side * 0.5)
			var p_sy: float = cy - (p_pos.y / grid_range) * (side * 0.5)
			draw_circle(Vector2(p_sx, p_sy), 2.5, Color(p_color, clampf(p_life * 2.0, 0.0, 1.0)))

		# ── Projections ──
		draw_line(Vector2(dot_x, dot_y), Vector2(dot_x, cy), Color(I_AXIS_X, 0.2), 1.5)
		draw_line(Vector2(dot_x, dot_y), Vector2(cx, dot_y), Color(I_AXIS_Y, 0.2), 1.5)
		draw_circle(Vector2(dot_x, cy), 4.0, I_AXIS_X)
		draw_circle(Vector2(cx, dot_y), 4.0, I_AXIS_Y)

		# ── Point dot ──
		draw_circle(Vector2(dot_x, dot_y), 18.0, Color(I_DOT, 0.12))
		draw_circle(Vector2(dot_x, dot_y), 12.0, Color(I_DOT, 0.35))
		draw_circle(Vector2(dot_x, dot_y), 7.0, I_DOT)
		draw_circle(Vector2(dot_x - 2, dot_y - 2), 2.0, Color(1, 1, 1, 0.4))

		# ── Inline coordinate label ──
		draw_string(font, Vector2(dot_x + 14, dot_y - 6), "(%.2f, %.2f)" % [pos.x, pos.y], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, I_DIM)

		# ── Data panel (right side) ──
		var d_to_target: float = Vector2(pos.x, pos.y).distance_to(Vector2(screen_ref._point_target.x, screen_ref._point_target.y))
		var sign_x: String = "+" if pos.x >= 0 else ""
		var sign_y: String = "+" if pos.y >= 0 else ""
		_draw_data_panel(font, g, [
			{"label": "X POSITION", "value": "%s%.3f" % [sign_x, pos.x], "color": I_AXIS_X},
			{"label": "Y POSITION", "value": "%s%.3f" % [sign_y, pos.y], "color": I_AXIS_Y},
			{"label": "DISTANCE", "value": "%.3f" % d_to_target, "color": I_CYAN},
			{"label": "TRAIL", "value": "%d pts" % screen_ref._point_trail.size(), "color": I_DOT},
			{"label": "SCORE", "value": "%d" % screen_ref._point_score, "color": I_TEXT},
		], "POINT DATA")

		# ── Info bar (bottom) — dynamic text from blurb.md/intent.md ──
		_draw_info_bar(font, vp_size, g["info_y"],
			screen_ref._info_current,
			screen_ref._info_sub)

		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# SHARED HELPERS
	# ═══════════════════════════════════════════════════════════════

	func _draw_scanlines(vp_size: Vector2) -> void:
		var scanline_spacing: int = 3
		var y_pos: int = 0
		while y_pos < int(vp_size.y):
			draw_line(Vector2(0, float(y_pos)), Vector2(vp_size.x, float(y_pos)), Color(0.0, 0.0, 0.0, 0.04), 1.0)
			y_pos += scanline_spacing

	func _draw_xy_grid(vp_size: Vector2, grid_top_y: float, area: Vector2, font: Font, grid_range: float) -> Dictionary:
		## Draws a standard XY coordinate grid and returns {ox, oy, side, cx, cy}
		var side: float = minf(area.x, vp_size.y - grid_top_y - 70.0)
		var ox: float = (vp_size.x - side) * 0.5
		var oy: float = grid_top_y + 4.0

		# Grid background
		draw_rect(Rect2(ox - 1.0, oy - 1.0, side + 2.0, side + 2.0), Color(0.04, 0.04, 0.06))

		# Minor grid
		var minor_div: int = 20
		var minor_step: float = side / float(minor_div)
		for i in range(minor_div + 1):
			var p: float = float(i) * minor_step
			draw_line(Vector2(ox + p, oy), Vector2(ox + p, oy + side), Color(0.06, 0.07, 0.09), 0.5)
			draw_line(Vector2(ox, oy + p), Vector2(ox + side, oy + p), Color(0.06, 0.07, 0.09), 0.5)

		# Major grid
		var major_div: int = 4
		var major_step: float = side / float(major_div)
		for i in range(major_div + 1):
			var p: float = float(i) * major_step
			draw_line(Vector2(ox + p, oy), Vector2(ox + p, oy + side), Color(0.1, 0.12, 0.16), 1.0)
			draw_line(Vector2(ox, oy + p), Vector2(ox + side, oy + p), Color(0.1, 0.12, 0.16), 1.0)

		# Center axes
		var cx: float = ox + side * 0.5
		var cy: float = oy + side * 0.5
		draw_line(Vector2(ox, cy), Vector2(ox + side, cy), Color(0.7, 0.15, 0.15, 0.5), 1.5)
		draw_line(Vector2(cx, oy), Vector2(cx, oy + side), Color(0.15, 0.7, 0.15, 0.5), 1.5)

		# Axis labels
		draw_string(font, Vector2(ox + side + 4.0, cy + 4.0), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.2, 0.2))
		draw_string(font, Vector2(cx + 4.0, oy - 2.0), "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.7, 0.2))

		# Scale labels
		var range_str: String = "%.0f" % grid_range
		draw_string(font, Vector2(ox - 2.0, cy + 14.0), "-%s" % range_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.25, 0.25, 0.3))
		draw_string(font, Vector2(ox + side - 14.0, cy + 14.0), range_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.25, 0.25, 0.3))

		return {"ox": ox, "oy": oy, "side": side, "cx": cx, "cy": cy}

	func _world_to_screen(world_pos: Vector3, cx: float, cy: float, side: float, grid_range: float) -> Vector2:
		# Negate X because screen faces player (rotation 180)
		var sx: float = cx - (world_pos.x / grid_range) * (side * 0.5)
		var sy: float = cy - (world_pos.y / grid_range) * (side * 0.5)
		return Vector2(sx, sy)


	# ═══════════════════════════════════════════════════════════════
	# LINE TRACKER
	# ═══════════════════════════════════════════════════════════════

	func _draw_line_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, area: Vector2, font: Font) -> void:
		var pos_a: Vector3 = Vector3.ZERO
		var pos_b: Vector3 = Vector3(0.5, 0.3, 0)
		if is_instance_valid(screen_ref._tracking_line_p1):
			pos_a = screen_ref._tracking_line_p1.global_position - screen_ref._line_origin
		if is_instance_valid(screen_ref._tracking_line_p2):
			pos_b = screen_ref._tracking_line_p2.global_position - screen_ref._line_origin
		var grid_range: float = 2.5

		# ── Dark background ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), I_BG)
		_draw_instrument_header(vp_size, font, "LINE MEASUREMENT", "|AB| = sqrt(dx^2+dy^2)", 0)
		var g: Dictionary = _draw_instrument_grid(vp_size, font, grid_range)
		var ox: float = g["ox"]; var oy: float = g["oy"]; var side: float = g["side"]
		var cx: float = g["cx"]; var cy: float = g["cy"]

		var sa: Vector2 = _world_to_screen(pos_a, cx, cy, side, grid_range)
		var sb: Vector2 = _world_to_screen(pos_b, cx, cy, side, grid_range)

		# ── Projections ──
		draw_line(Vector2(sa.x, sa.y), Vector2(sa.x, cy), Color(I_AXIS_X, 0.12), 1.0)
		draw_line(Vector2(sa.x, sa.y), Vector2(cx, sa.y), Color(I_AXIS_Y, 0.12), 1.0)
		draw_line(Vector2(sb.x, sb.y), Vector2(sb.x, cy), Color(I_AXIS_X, 0.12), 1.0)
		draw_line(Vector2(sb.x, sb.y), Vector2(cx, sb.y), Color(I_AXIS_Y, 0.12), 1.0)

		# ── Line AB (violet with glow) ──
		draw_line(sa, sb, Color(I_DOT, 0.25), 16.0)
		draw_line(sa, sb, I_DOT, 5.0)

		# ── Midpoint ──
		var mid: Vector2 = (sa + sb) * 0.5
		draw_circle(mid, 5.0, Color(I_DOT, 0.5))
		draw_string(font, Vector2(mid.x + 8, mid.y - 6), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, I_DIM)

		# ── Endpoint A (cyan) ──
		draw_circle(sa, 16.0, Color(I_CYAN, 0.15))
		draw_circle(sa, 10.0, Color(I_CYAN, 0.4))
		draw_circle(sa, 5.0, I_CYAN)
		draw_string(font, Vector2(sa.x + 10, sa.y - 8), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_CYAN)

		# ── Endpoint B (amber) ──
		draw_circle(sb, 16.0, Color(I_AMBER, 0.15))
		draw_circle(sb, 10.0, Color(I_AMBER, 0.4))
		draw_circle(sb, 5.0, I_AMBER)
		draw_string(font, Vector2(sb.x + 10, sb.y - 8), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_AMBER)

		# ── Data panel (right side) ──
		var dx: float = pos_b.x - pos_a.x
		var dy: float = pos_b.y - pos_a.y
		var dist: float = sqrt(dx * dx + dy * dy)
		var angle_deg: float = rad_to_deg(atan2(dy, dx))
		var sign_th: String = "+" if angle_deg >= 0 else ""

		_draw_data_panel(font, g, [
			{"label": "|AB| LENGTH", "value": "%.3f" % dist, "color": I_DOT},
			{"label": "THETA ANGLE", "value": "%s%.1f deg" % [sign_th, angle_deg], "color": Color(0.925, 0.306, 0.604)},
			{"label": "DELTA X", "value": "%+.3f" % dx, "color": I_AXIS_X},
			{"label": "DELTA Y", "value": "%+.3f" % dy, "color": I_AXIS_Y},
			{"label": "MIDPOINT", "value": "(%.2f, %.2f)" % [(pos_a.x + pos_b.x) * 0.5, (pos_a.y + pos_b.y) * 0.5], "color": I_DIM},
		], "LINE DATA")

		# ── Info bar (bottom) — dynamic text from blurb.md/intent.md ──
		_draw_info_bar(font, vp_size, g["info_y"],
			screen_ref._info_current,
			screen_ref._info_sub)

		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# DRAW DOT / PATH TRACER
	# ═══════════════════════════════════════════════════════════════

	func _draw_dot_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, area: Vector2, font: Font) -> void:
		var draw_node: Node3D = screen_ref._tracking_draw_dot if is_instance_valid(screen_ref._tracking_draw_dot) else null

		# ── Dark background + shared layout ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), I_BG)
		_draw_instrument_header(vp_size, font, "TRACE PATH", "L = sum|p[i]-p[i-1]|", 0)

		# Use auto-zoom grid range based on trail
		var trail_points: Array = []
		if draw_node:
			if "_trail_points" in draw_node:
				trail_points = draw_node.get("_trail_points")
			elif "trail_points" in draw_node:
				trail_points = draw_node.get("trail_points")
			if trail_points.size() == 0:
				trail_points = [draw_node.global_position]

		# Bounding box + length
		var min_x: float = 99999.0; var max_x: float = -99999.0
		var min_y: float = 99999.0; var max_y: float = -99999.0
		var total_length: float = 0.0
		for i in range(trail_points.size()):
			var tp: Vector3 = trail_points[i] if trail_points[i] is Vector3 else Vector3.ZERO
			min_x = minf(min_x, tp.x); max_x = maxf(max_x, tp.x)
			min_y = minf(min_y, tp.y); max_y = maxf(max_y, tp.y)
			if i > 0:
				var prev: Vector3 = trail_points[i - 1] if trail_points[i - 1] is Vector3 else Vector3.ZERO
				total_length += Vector2(tp.x - prev.x, tp.y - prev.y).length()

		var span_x: float = max_x - min_x
		var span_y: float = max_y - min_y
		var grid_range: float = maxf(maxf(span_x, span_y) * 0.575, 0.5)

		var g: Dictionary = _draw_instrument_grid(vp_size, font, grid_range)
		var ox: float = g["ox"]; var oy: float = g["oy"]; var side: float = g["side"]
		var cx: float = g["cx"]; var cy: float = g["cy"]

		var center_x: float = (min_x + max_x) * 0.5
		var center_y: float = (min_y + max_y) * 0.5

		# ── Draw trail (in grid area, centered on trail bbox) ──
		if trail_points.size() > 1:
			var n: int = trail_points.size()
			for i in range(n - 1):
				var p0: Vector3 = trail_points[i] if trail_points[i] is Vector3 else Vector3.ZERO
				var p1: Vector3 = trail_points[i + 1] if trail_points[i + 1] is Vector3 else Vector3.ZERO
				var s0: Vector2 = Vector2(cx + ((p0.x - center_x) / grid_range) * side * 0.5, cy - ((p0.y - center_y) / grid_range) * side * 0.5)
				var s1: Vector2 = Vector2(cx + ((p1.x - center_x) / grid_range) * side * 0.5, cy - ((p1.y - center_y) / grid_range) * side * 0.5)
				var t: float = float(i) / float(n)
				draw_line(s0, s1, Color(I_DOT, 0.15 + 0.85 * t), 1.5 + 4.5 * t)

		# ── Current position dot ──
		var cur_pos: Vector3 = draw_node.global_position if draw_node else Vector3.ZERO
		var cur_scr: Vector2 = Vector2(cx + ((cur_pos.x - center_x) / grid_range) * side * 0.5, cy - ((cur_pos.y - center_y) / grid_range) * side * 0.5)
		draw_circle(cur_scr, 16.0, Color(I_DOT, 0.12))
		draw_circle(cur_scr, 10.0, Color(I_DOT, 0.35))
		draw_circle(cur_scr, 5.0, I_DOT)

		# ── Data panel (right side) — continuous position data ──
		_draw_data_panel(font, g, [
			{"label": "X POSITION", "value": "%.3f" % cur_pos.x, "color": I_AXIS_X},
			{"label": "Y POSITION", "value": "%.3f" % cur_pos.y, "color": I_AXIS_Y},
			{"label": "POINTS", "value": "%d" % trail_points.size(), "color": I_DOT},
			{"label": "PATH LENGTH", "value": "%.3f m" % total_length, "color": I_TEXT},
			{"label": "ZOOM", "value": "%.0f cm" % (grid_range * 200.0), "color": I_DIM},
		], "TRACE DATA")

		# ── Info bar (bottom) — dynamic text ──
		_draw_info_bar(font, vp_size, g["info_y"],
			screen_ref._info_current,
			screen_ref._info_sub)

		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# TRIANGLE ANALYZER
	# ═══════════════════════════════════════════════════════════════

	func _draw_triangle_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, area: Vector2, font: Font) -> void:
		# Default vertices match the triangle artifact (commons/primitives/triangle/triangle.gd)
		var pa: Vector3 = Vector3(-0.25, 0.25, 0)
		var pb: Vector3 = Vector3(0.25, 0.25, 0)
		var pc: Vector3 = Vector3(0, 0.75, 0)
		if screen_ref._tracking_tri_points.size() >= 3:
			if is_instance_valid(screen_ref._tracking_tri_points[0]):
				pa = screen_ref._tracking_tri_points[0].global_position
			if is_instance_valid(screen_ref._tracking_tri_points[1]):
				pb = screen_ref._tracking_tri_points[1].global_position
			if is_instance_valid(screen_ref._tracking_tri_points[2]):
				pc = screen_ref._tracking_tri_points[2].global_position
		var grid_range: float = 3.0

		# ── Dark background + shared layout ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), I_BG)
		_draw_instrument_header(vp_size, font, "TRIANGLE", "A = 0.5|AB x AC|", 0)
		var g: Dictionary = _draw_instrument_grid(vp_size, font, grid_range)
		var ox: float = g["ox"]
		var oy: float = g["oy"]
		var side: float = g["side"]
		var cx: float = g["cx"]
		var cy: float = g["cy"]

		# Map vertices to screen
		var sa: Vector2 = _world_to_screen(pa, cx, cy, side, grid_range)
		var sb: Vector2 = _world_to_screen(pb, cx, cy, side, grid_range)
		var sc: Vector2 = _world_to_screen(pc, cx, cy, side, grid_range)

		# ── Filled triangle (semi-transparent) ──
		var tri_color: Color = Color(I_DOT, 0.08)
		var tri_points: PackedVector2Array = PackedVector2Array([sa, sb, sc])
		var tri_colors: PackedColorArray = PackedColorArray([tri_color, tri_color, tri_color])
		draw_polygon(tri_points, tri_colors)

		# ── Triangle edges (glow + solid) ──
		draw_line(sa, sb, Color(I_DOT, 0.2), 14.0)
		draw_line(sb, sc, Color(I_DOT, 0.2), 14.0)
		draw_line(sc, sa, Color(I_DOT, 0.2), 14.0)
		draw_line(sa, sb, I_DOT, 4.0)
		draw_line(sb, sc, I_DOT, 4.0)
		draw_line(sc, sa, I_DOT, 4.0)

		# ── Vertex A (cyan) ──
		draw_circle(sa, 14.0, Color(I_CYAN, 0.15))
		draw_circle(sa, 8.0, Color(I_CYAN, 0.4))
		draw_circle(sa, 4.0, I_CYAN)
		draw_string(font, Vector2(sa.x + 10, sa.y - 8), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_CYAN)

		# ── Vertex B (amber) ──
		draw_circle(sb, 14.0, Color(I_AMBER, 0.15))
		draw_circle(sb, 8.0, Color(I_AMBER, 0.4))
		draw_circle(sb, 4.0, I_AMBER)
		draw_string(font, Vector2(sb.x + 10, sb.y - 8), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_AMBER)

		# ── Vertex C (violet) ──
		draw_circle(sc, 14.0, Color(I_DOT, 0.15))
		draw_circle(sc, 8.0, Color(I_DOT, 0.4))
		draw_circle(sc, 4.0, I_DOT)
		draw_string(font, Vector2(sc.x + 10, sc.y - 8), "C", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_DOT)

		# ── Centroid ──
		var centroid_x: float = (pa.x + pb.x + pc.x) / 3.0
		var centroid_y: float = (pa.y + pb.y + pc.y) / 3.0
		var centroid_screen: Vector2 = _world_to_screen(Vector3(centroid_x, centroid_y, 0.0), cx, cy, side, grid_range)
		draw_circle(centroid_screen, 4.0, Color(1.0, 1.0, 0.4, 0.6))
		draw_string(font, Vector2(centroid_screen.x + 6.0, centroid_screen.y - 4.0), "G", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 1.0, 0.4, 0.6))

		# ── Compute side lengths ──
		var ab_dx: float = pb.x - pa.x
		var ab_dy: float = pb.y - pa.y
		var len_ab: float = sqrt(ab_dx * ab_dx + ab_dy * ab_dy)

		var bc_dx: float = pc.x - pb.x
		var bc_dy: float = pc.y - pb.y
		var len_bc: float = sqrt(bc_dx * bc_dx + bc_dy * bc_dy)

		var ca_dx: float = pa.x - pc.x
		var ca_dy: float = pa.y - pc.y
		var len_ca: float = sqrt(ca_dx * ca_dx + ca_dy * ca_dy)

		# ── Compute angles (law of cosines) ──
		var angle_a: float = 0.0
		var angle_b: float = 0.0
		var angle_c: float = 0.0
		if len_ab > 0.001 and len_ca > 0.001:
			var cos_a: float = clampf((len_ab * len_ab + len_ca * len_ca - len_bc * len_bc) / (2.0 * len_ab * len_ca), -1.0, 1.0)
			angle_a = rad_to_deg(acos(cos_a))
		if len_ab > 0.001 and len_bc > 0.001:
			var cos_b: float = clampf((len_ab * len_ab + len_bc * len_bc - len_ca * len_ca) / (2.0 * len_ab * len_bc), -1.0, 1.0)
			angle_b = rad_to_deg(acos(cos_b))
		angle_c = 180.0 - angle_a - angle_b

		# ── Area (cross product / 2) ──
		var tri_area: float = absf((pb.x - pa.x) * (pc.y - pa.y) - (pc.x - pa.x) * (pb.y - pa.y)) * 0.5

		# ── Data panel (right side) ──
		var perimeter: float = len_ab + len_bc + len_ca
		_draw_data_panel(font, g, [
			{"label": "AREA", "value": "%.3f" % tri_area, "color": I_DOT},
			{"label": "PERIMETER", "value": "%.3f" % perimeter, "color": I_TEXT},
			{"label": "ANGLES", "value": "%.0f  %.0f  %.0f" % [angle_a, angle_b, angle_c], "color": Color(0.925, 0.306, 0.604)},
			{"label": "AB / BC / CA", "value": "%.2f / %.2f / %.2f" % [len_ab, len_bc, len_ca], "color": I_DIM},
			{"label": "CENTROID", "value": "(%.2f, %.2f)" % [centroid_x, centroid_y], "color": Color(1.0, 1.0, 0.4)},
		], "TRIANGLE DATA")

		# ── Info bar (bottom) — dynamic text ──
		_draw_info_bar(font, vp_size, g["info_y"],
			screen_ref._info_current,
			screen_ref._info_sub)

		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# CUBE NET — unfold a 3D cube's faces into 2D cross layout
	# ═══════════════════════════════════════════════════════════════

	func _draw_net_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, grid_area: Vector2, font: Font) -> void:
		draw_rect(Rect2(Vector2.ZERO, vp_size), I_BG)
		_draw_instrument_header(vp_size, font, "CUBE NET", "6 faces, 8 vertices, 12 edges", 0)
		var g: Dictionary = _draw_instrument_grid(vp_size, font, 3.0)
		var ox: float = g["ox"]; var oy: float = g["oy"]; var side: float = g["side"]
		var cx: float = g["cx"]; var cy: float = g["cy"]

		# Get 8 vertex positions from the tracked artifact
		var verts: Array[Vector3] = []
		for i in range(8):
			verts.append(Vector3(
				[-0.5, 0.5, 0.5, -0.5, -0.5, 0.5, 0.5, -0.5][i],
				[-0.5, -0.5, 0.5, 0.5, -0.5, -0.5, 0.5, 0.5][i],
				[-0.5, -0.5, -0.5, -0.5, 0.5, 0.5, 0.5, 0.5][i]
			))

		# Try to read actual positions from the tracked artifact
		if is_instance_valid(screen_ref._tracking_generic):
			var art: Node = screen_ref._tracking_generic
			if "handle_nodes" in art:
				var handles: Array = art.get("handle_nodes")
				for i in range(mini(handles.size(), 8)):
					if is_instance_valid(handles[i]):
						var origin: Vector3 = art.global_position
						verts[i] = handles[i].global_position - origin

		# Cube faces as quads (indices into verts) — standard cube net cross layout
		# Face order: front, right, back, left, top, bottom
		var faces: Array = [
			[4, 5, 6, 7],  # front (+Z)
			[1, 5, 6, 2],  # right (+X)
			[0, 1, 2, 3],  # back (-Z)
			[4, 0, 3, 7],  # left (-X)
			[3, 2, 6, 7],  # top (+Y)
			[4, 5, 1, 0],  # bottom (-Y)
		]
		var face_colors: Array[Color] = [
			I_CYAN, I_AMBER, Color(0.925, 0.306, 0.604), I_AXIS_Y, I_DOT, I_DIM
		]
		var face_names: Array[String] = ["FRONT", "RIGHT", "BACK", "LEFT", "TOP", "BOTTOM"]

		# Net layout: cross pattern — each face gets a 2D offset in grid units
		# Layout (face_size = side/4):
		#       [TOP]
		# [LEFT][FRONT][RIGHT][BACK]
		#       [BOTTOM]
		var face_size: float = side / 4.2
		var net_cx: float = cx - face_size * 0.5  # Center the cross
		var net_cy: float = cy - face_size * 0.5
		var net_offsets: Array[Vector2] = [
			Vector2(1, 1),   # front — center
			Vector2(2, 1),   # right
			Vector2(3, 1),   # back
			Vector2(0, 1),   # left
			Vector2(1, 0),   # top
			Vector2(1, 2),   # bottom
		]

		# Draw each face as a deformed quad
		for fi in range(6):
			var face: Array = faces[fi]
			var offset: Vector2 = net_offsets[fi]
			var base_x: float = ox + offset.x * face_size + (side - face_size * 4) * 0.5
			var base_y: float = oy + offset.y * face_size + (side - face_size * 3) * 0.5
			var col: Color = face_colors[fi]

			# Get the 4 vertex positions for this face and project to 2D
			# Map each vertex's local displacement to deform the square
			var corners: Array[Vector2] = []
			for vi in range(4):
				var v: Vector3 = verts[face[vi]]
				# Simple projection: use two axes per face for the 2D layout
				var u: float = 0.0; var w: float = 0.0
				match fi:
					0: u = v.x; w = v.y  # front: XY
					1: u = -v.z; w = v.y  # right: ZY
					2: u = -v.x; w = v.y  # back: XY flipped
					3: u = v.z; w = v.y  # left: ZY flipped
					4: u = v.x; w = -v.z  # top: XZ
					5: u = v.x; w = v.z  # bottom: XZ
				corners.append(Vector2(
					base_x + (u + 0.5) * face_size,
					base_y + (0.5 - w) * face_size
				))

			# Fill
			if corners.size() == 4:
				var poly: PackedVector2Array = PackedVector2Array(corners)
				var colors: PackedColorArray = PackedColorArray([Color(col, 0.1), Color(col, 0.1), Color(col, 0.1), Color(col, 0.1)])
				draw_polygon(poly, colors)
				# Edges
				for ei in range(4):
					draw_line(corners[ei], corners[(ei + 1) % 4], Color(col, 0.7), 2.0)
				# Face label
				var center_2d: Vector2 = (corners[0] + corners[1] + corners[2] + corners[3]) * 0.25
				draw_string(font, Vector2(center_2d.x - 12, center_2d.y + 4), face_names[fi], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(col, 0.5))

		# ── Data panel ──
		var vol: float = absf(verts[0].distance_to(verts[1]) * verts[0].distance_to(verts[3]) * verts[0].distance_to(verts[4]))
		var edge_len: float = verts[0].distance_to(verts[1])
		_draw_data_panel(font, g, [
			{"label": "EDGE LENGTH", "value": "%.3f" % edge_len, "color": I_TEXT},
			{"label": "VERTICES", "value": "8", "color": I_CYAN},
			{"label": "EDGES", "value": "12", "color": I_AMBER},
			{"label": "FACES", "value": "6", "color": I_DOT},
			{"label": "V-E+F", "value": "%d" % (8 - 12 + 6), "color": Color(1.0, 1.0, 0.4)},
		], "CUBE NET DATA")

		_draw_info_bar(font, vp_size, g["info_y"],
			screen_ref._info_current,
			screen_ref._info_sub)
		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# WAVE — time-series sine/oscillation graph
	# ═══════════════════════════════════════════════════════════════

	func _draw_wave_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, grid_area: Vector2, font: Font) -> void:
		draw_rect(Rect2(Vector2.ZERO, vp_size), I_BG)
		_draw_instrument_header(vp_size, font, "WAVEFORM", "y = A sin(wt + phi)", 0)
		var g: Dictionary = _draw_instrument_grid(vp_size, font, 2.0)
		var ox: float = g["ox"]; var oy: float = g["oy"]; var side: float = g["side"]
		var cx: float = g["cx"]; var cy: float = g["cy"]

		# Read waveform data from artifact or generate live sine
		var t: float = Time.get_ticks_msec() / 1000.0
		var amplitude: float = 1.5
		var frequency: float = 1.0
		var cur_angle: float = 0.0
		var angular_vel: float = 0.0

		# Try reading from artifact
		var art: Node3D = screen_ref._tracking_generic if is_instance_valid(screen_ref._tracking_generic) else null
		if art:
			if "current_amplitude" in art: amplitude = float(art.get("current_amplitude"))
			if "current_angular_velocity" in art: angular_vel = float(art.get("current_angular_velocity"))
			if "_angle" in art: cur_angle = float(art.get("_angle"))
			# Use angle to modulate the wave
			if cur_angle != 0.0:
				frequency = maxf(absf(angular_vel) / TAU, 0.1)

		# Draw waveform — 200 sample points
		var prev_scr: Vector2 = Vector2.ZERO
		var grid_range: float = 2.0
		for i in range(200):
			var x_val: float = -grid_range + (float(i) / 199.0) * grid_range * 2.0
			var y_val: float = amplitude * sin(frequency * (x_val + t) * TAU + cur_angle)
			y_val = clampf(y_val, -grid_range, grid_range)
			var sx: float = ox + ((x_val + grid_range) / (grid_range * 2.0)) * side
			var sy: float = cy - (y_val / grid_range) * (side * 0.5)
			var scr: Vector2 = Vector2(sx, sy)
			if i > 0:
				draw_line(prev_scr, scr, I_DOT, 2.5)
				draw_line(prev_scr, scr, Color(I_DOT, 0.15), 8.0)
			prev_scr = scr

		# Current value marker at center
		var cur_y: float = amplitude * sin(cur_angle)
		var cur_scr: Vector2 = Vector2(cx, cy - (cur_y / grid_range) * (side * 0.5))
		draw_circle(cur_scr, 8.0, Color(I_CYAN, 0.3))
		draw_circle(cur_scr, 4.0, I_CYAN)

		# Data panel
		_draw_data_panel(font, g, [
			{"label": "AMPLITUDE", "value": "%.3f" % amplitude, "color": I_DOT},
			{"label": "FREQUENCY", "value": "%.2f Hz" % frequency, "color": I_CYAN},
			{"label": "ANGLE", "value": "%.2f rad" % cur_angle, "color": I_AMBER},
			{"label": "VELOCITY", "value": "%.3f" % angular_vel, "color": I_AXIS_Y},
			{"label": "CURRENT Y", "value": "%.3f" % cur_y, "color": I_TEXT},
		], "WAVE DATA")
		_draw_info_bar(font, vp_size, g["info_y"], screen_ref._info_current, screen_ref._info_sub)
		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# FIELD — 2D noise/force intensity heatmap
	# ═══════════════════════════════════════════════════════════════

	func _draw_field_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, grid_area: Vector2, font: Font) -> void:
		draw_rect(Rect2(Vector2.ZERO, vp_size), I_BG)
		_draw_instrument_header(vp_size, font, "FIELD MAP", "f(x,y) intensity", 0)
		var g: Dictionary = _draw_instrument_grid(vp_size, font, 2.0)
		var ox: float = g["ox"]; var oy: float = g["oy"]; var side: float = g["side"]

		# Generate a field heatmap — read from artifact or procedural
		var t: float = Time.get_ticks_msec() / 3000.0
		var field_cells: int = 20
		var noise_freq: float = 2.0
		var noise_scale: float = 1.0
		var threshold: float = 0.5
		var art: Node3D = screen_ref._tracking_generic if is_instance_valid(screen_ref._tracking_generic) else null
		if art:
			if "grid_size" in art: field_cells = clampi(int(art.get("grid_size")), 4, 40)
			if "noise_frequency" in art: noise_freq = float(art.get("noise_frequency"))
			if "noise_scale" in art: noise_scale = float(art.get("noise_scale"))
			if "height_scale" in art: noise_scale = float(art.get("height_scale"))
			if "threshold" in art: threshold = float(art.get("threshold"))
			if "damage_threshold" in art: threshold = float(art.get("damage_threshold"))

		var cell_size: float = side / float(field_cells)

		# Try to read tile materials for real color data
		var has_real_data: bool = false
		if art and "_tile_mats" in art:
			var mats: Array = art.get("_tile_mats")
			var gs: int = int(art.get("grid_size")) if "grid_size" in art else 10
			for yi in range(mini(gs, field_cells)):
				for xi in range(mini(gs, field_cells)):
					var idx: int = yi * gs + xi
					if idx < mats.size() and mats[idx] is StandardMaterial3D:
						var mat_col: Color = mats[idx].albedo_color
						var brightness: float = (mat_col.r + mat_col.g + mat_col.b) / 3.0
						var col: Color = Color(I_AXIS_Y, brightness * 0.8) if brightness > 0.2 else Color(I_BG, 0.5)
						draw_rect(Rect2(ox + xi * cell_size, oy + yi * cell_size, cell_size - 1, cell_size - 1), col)
			has_real_data = mats.size() > 0

		if not has_real_data:
			for yi in range(field_cells):
				for xi in range(field_cells):
					var fx: float = float(xi) / float(field_cells) * 4.0 - 2.0
					var fy: float = float(yi) / float(field_cells) * 4.0 - 2.0
					var val: float = (sin(fx * noise_freq + t) * cos(fy * (noise_freq * 1.5) - t * 0.7) + 1.0) * 0.5
					val = clampf(val * noise_scale, 0.0, 1.0)
					var col: Color = Color(I_AXIS_Y, val * 0.6) if val > threshold * 0.5 else Color(I_BG, 0.5)
					draw_rect(Rect2(ox + xi * cell_size, oy + yi * cell_size, cell_size - 1, cell_size - 1), col)

		# Data panel
		_draw_data_panel(font, g, [
			{"label": "RESOLUTION", "value": "%dx%d" % [field_cells, field_cells], "color": I_TEXT},
			{"label": "FREQUENCY", "value": "%.2f" % noise_freq, "color": I_CYAN},
			{"label": "SCALE", "value": "%.2f" % noise_scale, "color": I_AMBER},
			{"label": "THRESHOLD", "value": "%.2f" % threshold, "color": I_AXIS_X},
			{"label": "SOURCE", "value": "LIVE" if has_real_data else "DEMO", "color": I_AXIS_Y if has_real_data else I_DIM},
		], "FIELD DATA")
		_draw_info_bar(font, vp_size, g["info_y"], screen_ref._info_current, screen_ref._info_sub)
		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# SCATTER — multi-agent/particle positions as dots
	# ═══════════════════════════════════════════════════════════════

	func _draw_scatter_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, grid_area: Vector2, font: Font) -> void:
		draw_rect(Rect2(Vector2.ZERO, vp_size), I_BG)
		_draw_instrument_header(vp_size, font, "SCATTER PLOT", "N agents in 2D space", 0)
		var g: Dictionary = _draw_instrument_grid(vp_size, font, 5.0)
		var ox: float = g["ox"]; var oy: float = g["oy"]; var side: float = g["side"]
		var cx: float = g["cx"]; var cy: float = g["cy"]
		var grid_range: float = 5.0

		# Try to read agent positions from artifact
		var agents: Array = []
		var art: Node3D = screen_ref._tracking_generic if is_instance_valid(screen_ref._tracking_generic) else null
		if art:
			# Walk children recursively to find boid-like nodes (small mesh instances)
			for child in art.get_children():
				if child is Node3D:
					if child.visible and (child is MeshInstance3D or child.get_child_count() > 0):
						agents.append(child.global_position - art.global_position)
					# Also check grandchildren (boid containers often nest)
					for gc in child.get_children():
						if gc is Node3D and gc.visible and gc is MeshInstance3D:
							agents.append(gc.global_position - art.global_position)

		# If no agents found, generate demo swarm
		if agents.is_empty():
			var t: float = Time.get_ticks_msec() / 1000.0
			var rng := RandomNumberGenerator.new()
			rng.seed = 42
			for i in range(30):
				var a: float = float(i) / 30.0 * TAU + t * 0.3
				var r: float = 1.5 + rng.randf() * 2.0 + sin(t + float(i) * 0.5) * 0.5
				agents.append(Vector3(cos(a) * r, sin(a) * r, 0))

		# Draw agents as dots
		var count: int = agents.size()
		for i in range(count):
			var pos: Vector3 = agents[i]
			var sx: float = cx + (pos.x / grid_range) * (side * 0.5)
			var sy: float = cy - (pos.y / grid_range) * (side * 0.5)
			var hue: float = float(i) / float(maxi(count, 1))
			var col: Color = Color.from_hsv(hue * 0.6 + 0.5, 0.7, 1.0)
			draw_circle(Vector2(sx, sy), 5.0, Color(col, 0.3))
			draw_circle(Vector2(sx, sy), 2.5, col)

		# Data panel — read params from artifact
		var sep_w: float = art.get("separation_weight") if art and "separation_weight" in art else 0.0
		var ali_w: float = art.get("alignment_weight") if art and "alignment_weight" in art else 0.0
		var coh_w: float = art.get("cohesion_weight") if art and "cohesion_weight" in art else 0.0
		var max_spd: float = art.get("max_speed") if art and "max_speed" in art else 0.0
		_draw_data_panel(font, g, [
			{"label": "AGENTS", "value": "%d" % count, "color": I_CYAN},
			{"label": "SEPARATION", "value": "%.2f" % sep_w, "color": I_AXIS_X},
			{"label": "ALIGNMENT", "value": "%.2f" % ali_w, "color": I_AXIS_Y},
			{"label": "COHESION", "value": "%.2f" % coh_w, "color": I_DOT},
			{"label": "MAX SPEED", "value": "%.1f m/s" % max_spd, "color": I_DIM},
		], "SWARM DATA")
		_draw_info_bar(font, vp_size, g["info_y"], screen_ref._info_current, screen_ref._info_sub)
		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# GRID — 2D cellular automata / cell state heatmap
	# ═══════════════════════════════════════════════════════════════

	func _draw_grid_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, grid_area: Vector2, font: Font) -> void:
		draw_rect(Rect2(Vector2.ZERO, vp_size), I_BG)
		_draw_instrument_header(vp_size, font, "GRID VIEW", "cell state heatmap", 0)

		# Use custom grid area (not coordinate-based)
		var gtop: float = HEADER_H + PAD
		var avail_h: float = vp_size.y - gtop - INFO_H - PAD * 2
		var avail_w: float = vp_size.x - DATA_W - PAD * 3
		var grid_side: float = minf(avail_w, avail_h)
		var gx: float = PAD + (avail_w - grid_side) * 0.5
		var gy: float = gtop + (avail_h - grid_side) * 0.5

		# Try to read grid data from artifact
		var cols: int = 16; var rows: int = 16
		var cells: Array = []
		var gen_count: int = 0
		var art: Node3D = screen_ref._tracking_generic if is_instance_valid(screen_ref._tracking_generic) else null
		if art:
			if "grid_size" in art:
				cols = int(art.get("grid_size"))
				rows = cols
			if "grid_width" in art: cols = int(art.get("grid_width"))
			if "grid_height" in art: rows = int(art.get("grid_height"))
			if "cells" in art and art.get("cells") is Array:
				cells = art.get("cells")
			elif "_grid" in art and art.get("_grid") is Array:
				cells = art.get("_grid")
			if "_generation" in art: gen_count = int(art.get("_generation"))
			elif "generation" in art: gen_count = int(art.get("generation"))

		# Panel backgrounds
		draw_rect(Rect2(gx, gy, grid_side, grid_side), I_PANEL)
		draw_rect(Rect2(gx, gy, grid_side, grid_side), I_PANEL_BORDER, false, 2.0)

		var data_x: float = gx + grid_side + PAD
		var data_y: float = gtop
		var data_w: float = vp_size.x - data_x - PAD
		draw_rect(Rect2(data_x, data_y, data_w, avail_h), I_PANEL)
		draw_rect(Rect2(data_x, data_y, data_w, avail_h), I_PANEL_BORDER, false, 2.0)

		var info_y: float = vp_size.y - INFO_H
		draw_rect(Rect2(0, info_y, vp_size.x, INFO_H), I_PANEL)
		draw_rect(Rect2(0, info_y, vp_size.x, INFO_H), I_PANEL_BORDER, false, 2.0)

		# Draw cells
		var cell_w: float = grid_side / float(cols)
		var cell_h: float = grid_side / float(rows)
		var alive_count: int = 0
		var t: float = Time.get_ticks_msec() / 1000.0

		for r in range(rows):
			for c in range(cols):
				var val: int = 0
				if r < cells.size() and cells[r] is Array and c < cells[r].size():
					val = int(cells[r][c]) if cells[r][c] is int or cells[r][c] is float else 0
				else:
					# Demo pattern: procedural CA-like
					val = 1 if (sin(float(c) * 0.7 + t) * cos(float(r) * 0.9 - t * 0.5)) > 0.2 else 0

				if val > 0:
					alive_count += 1
					var intensity: float = clampf(float(val) / 3.0, 0.3, 1.0)
					var col: Color = Color(I_AXIS_Y, intensity)
					draw_rect(Rect2(gx + c * cell_w + 0.5, gy + r * cell_h + 0.5, cell_w - 1, cell_h - 1), col)

		# Grid lines
		for c in range(cols + 1):
			draw_line(Vector2(gx + c * cell_w, gy), Vector2(gx + c * cell_w, gy + grid_side), I_GRID_MINOR, 0.5)
		for r in range(rows + 1):
			draw_line(Vector2(gx, gy + r * cell_h), Vector2(gx + grid_side, gy + r * cell_h), I_GRID_MINOR, 0.5)

		# Data panel text
		var font2: Font = ThemeDB.fallback_font
		draw_string(font2, Vector2(data_x + 10, data_y + 18), "GRID DATA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, I_DIM)
		draw_line(Vector2(data_x + 8, data_y + 24), Vector2(data_x + data_w - 8, data_y + 24), Color(I_PANEL_BORDER, 0.3), 1.0)
		draw_string(font2, Vector2(data_x + 10, data_y + 42), "SIZE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
		draw_string(font2, Vector2(data_x + 10, data_y + 58), "%dx%d" % [cols, rows], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_TEXT)
		draw_string(font2, Vector2(data_x + 10, data_y + 82), "ALIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
		draw_string(font2, Vector2(data_x + 10, data_y + 98), "%d" % alive_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_AXIS_Y)
		draw_string(font2, Vector2(data_x + 10, data_y + 122), "DENSITY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
		var density: float = float(alive_count) / float(cols * rows) * 100.0
		draw_string(font2, Vector2(data_x + 10, data_y + 138), "%.1f%%" % density, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_CYAN)
		if gen_count > 0:
			draw_string(font2, Vector2(data_x + 10, data_y + 162), "GENERATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
			draw_string(font2, Vector2(data_x + 10, data_y + 178), "%d" % gen_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_AMBER)

		_draw_info_bar(font2, vp_size, info_y, screen_ref._info_current, screen_ref._info_sub)
		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# BARS — histogram / sorted array visualization
	# ═══════════════════════════════════════════════════════════════

	func _draw_bars_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, grid_area: Vector2, font: Font) -> void:
		draw_rect(Rect2(Vector2.ZERO, vp_size), I_BG)
		_draw_instrument_header(vp_size, font, "BAR CHART", "array[i] as height", 0)

		var gtop: float = HEADER_H + PAD
		var avail_h: float = vp_size.y - gtop - INFO_H - PAD * 2
		var avail_w: float = vp_size.x - DATA_W - PAD * 3
		var chart_w: float = avail_w
		var chart_h: float = avail_h
		var chart_x: float = PAD
		var chart_y: float = gtop

		# Panel backgrounds
		draw_rect(Rect2(chart_x, chart_y, chart_w, chart_h), I_PANEL)
		draw_rect(Rect2(chart_x, chart_y, chart_w, chart_h), I_PANEL_BORDER, false, 2.0)

		var data_x: float = chart_x + chart_w + PAD
		var data_y: float = gtop
		var data_w: float = vp_size.x - data_x - PAD
		draw_rect(Rect2(data_x, data_y, data_w, chart_h), I_PANEL)
		draw_rect(Rect2(data_x, data_y, data_w, chart_h), I_PANEL_BORDER, false, 2.0)

		var info_y: float = vp_size.y - INFO_H
		draw_rect(Rect2(0, info_y, vp_size.x, INFO_H), I_PANEL)
		draw_rect(Rect2(0, info_y, vp_size.x, INFO_H), I_PANEL_BORDER, false, 2.0)

		# Try to read array data from artifact
		var values: Array = []
		var algo_name: String = ""
		var is_sorted: bool = false
		var art: Node3D = screen_ref._tracking_generic if is_instance_valid(screen_ref._tracking_generic) else null
		if art:
			# bar_array_renderer exposes _current_heights
			if "_current_heights" in art:
				var h = art.get("_current_heights")
				if h is PackedFloat32Array:
					for v in h: values.append(float(v))
			# bar_array_substrate exposes _array
			elif "_array" in art:
				var a = art.get("_array")
				if a is PackedFloat32Array:
					for v in a: values.append(float(v))
			elif "values" in art and art.get("values") is Array:
				values = art.get("values")
			# Check for child renderer
			if values.is_empty():
				for child in art.get_children():
					if "_current_heights" in child:
						var h = child.get("_current_heights")
						if h is PackedFloat32Array:
							for v in h: values.append(float(v))
						break
			if "_is_done" in art: is_sorted = bool(art.get("_is_done"))
			if "algorithm" in art: algo_name = str(art.get("algorithm"))

		# Demo: generate bars if no data
		if values.is_empty():
			var rng := RandomNumberGenerator.new()
			rng.seed = 12345
			for i in range(20):
				values.append(rng.randf_range(0.1, 1.0))

		# Draw bars
		var n: int = values.size()
		var bar_w: float = (chart_w - 20) / float(maxi(n, 1))
		var max_val: float = 0.001
		for v in values:
			max_val = maxf(max_val, float(v))

		for i in range(n):
			var val: float = float(values[i])
			var h: float = (val / max_val) * (chart_h - 20)
			var bx: float = chart_x + 10 + i * bar_w
			var by: float = chart_y + chart_h - 10 - h
			var hue: float = float(i) / float(maxi(n, 1)) * 0.3 + 0.3
			var col: Color = Color.from_hsv(hue, 0.7, 0.9)
			# Bar glow
			draw_rect(Rect2(bx + 1, by, bar_w - 2, h), Color(col, 0.6))
			draw_rect(Rect2(bx, by - 1, bar_w, h + 2), Color(col, 0.15))

		# Baseline
		draw_line(Vector2(chart_x + 10, chart_y + chart_h - 10), Vector2(chart_x + chart_w - 10, chart_y + chart_h - 10), I_GRID_MAJOR, 1.5)

		# Data panel
		var font2: Font = ThemeDB.fallback_font
		draw_string(font2, Vector2(data_x + 10, data_y + 18), "ARRAY DATA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, I_DIM)
		draw_line(Vector2(data_x + 8, data_y + 24), Vector2(data_x + data_w - 8, data_y + 24), Color(I_PANEL_BORDER, 0.3), 1.0)
		draw_string(font2, Vector2(data_x + 10, data_y + 42), "ELEMENTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
		draw_string(font2, Vector2(data_x + 10, data_y + 58), "%d" % n, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_CYAN)
		draw_string(font2, Vector2(data_x + 10, data_y + 82), "MAX VALUE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
		draw_string(font2, Vector2(data_x + 10, data_y + 98), "%.3f" % max_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_AMBER)
		var avg: float = 0.0
		for v in values: avg += float(v)
		avg /= float(maxi(n, 1))
		draw_string(font2, Vector2(data_x + 10, data_y + 122), "AVERAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
		draw_string(font2, Vector2(data_x + 10, data_y + 138), "%.3f" % avg, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, I_DOT)
		if algo_name != "":
			draw_string(font2, Vector2(data_x + 10, data_y + 162), "ALGORITHM", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, I_DIM)
			draw_string(font2, Vector2(data_x + 10, data_y + 178), algo_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, I_CYAN)
		if is_sorted:
			draw_string(font2, Vector2(data_x + 10, data_y + 200), "SORTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, I_AXIS_Y)

		_draw_info_bar(font2, vp_size, info_y, screen_ref._info_current, screen_ref._info_sub)
		_draw_scanlines(vp_size)


	# ═══════════════════════════════════════════════════════════════
	# GENERIC TRACKER (catch-all)
	# ═══════════════════════════════════════════════════════════════

	func _draw_generic_tracker(vp_size: Vector2, grid_top: float, grid_margin: float, area: Vector2, font: Font) -> void:
		var target: Node3D = screen_ref._tracking_generic if is_instance_valid(screen_ref._tracking_generic) else null
		var mode_name: String = screen_ref._generic_mode_name

		# ── Background ──
		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.02, 0.02, 0.04))

		# ── Header ──
		draw_rect(Rect2(0.0, 0.0, vp_size.x, 36.0), Color(0.05, 0.05, 0.08))
		var header_text: String = mode_name.to_upper() + " MONITOR"
		draw_string(font, Vector2(12.0, 25.0), header_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.4, 0.8, 1.0))
		draw_string(font, Vector2(vp_size.x - 180.0, 25.0), screen_ref._source_artifact_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 0.3, 0.4))

		# ── Visualization area ──
		var viz_top: float = 44.0
		var viz_margin: float = 20.0
		var viz_width: float = vp_size.x - viz_margin * 2.0
		var viz_height: float = vp_size.y - viz_top - 90.0

		# ── Draw background rect ──
		draw_rect(Rect2(viz_margin, viz_top, viz_width, viz_height), Color(0.04, 0.04, 0.06))

		# ── Mode-specific visualization ──
		if "sort" in mode_name:
			_draw_generic_sort(target, viz_margin, viz_top, viz_width, viz_height, font)
		elif "noise" in mode_name or "wave" in mode_name or "oscillat" in mode_name or "pendulum" in mode_name:
			_draw_generic_waveform(target, viz_margin, viz_top, viz_width, viz_height, font)
		elif "force" in mode_name or "swarm" in mode_name or "boid" in mode_name or "flock" in mode_name or "particle" in mode_name or "field" in mode_name or "spring" in mode_name:
			_draw_generic_scatter(target, viz_margin, viz_top, viz_width, viz_height, font)
		elif "graph" in mode_name or "mesh" in mode_name:
			_draw_generic_graph(target, viz_margin, viz_top, viz_width, viz_height, font)
		else:
			_draw_generic_radar(target, viz_margin, viz_top, viz_width, viz_height, font)

		# ── Info panel ──
		var panel_y: float = viz_top + viz_height + 8.0
		draw_rect(Rect2(viz_margin, panel_y, viz_width, 60.0), Color(0.04, 0.04, 0.06))
		draw_rect(Rect2(viz_margin, panel_y, viz_width, 1.0), Color(0.15, 0.2, 0.25))

		var pos: Vector3 = target.global_position if target else Vector3.ZERO
		var pos_str: String = "Position: (%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]
		draw_string(font, Vector2(viz_margin + 14.0, panel_y + 18.0), pos_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.7, 0.9))

		var child_count: int = target.get_child_count()
		var child_str: String = "Children: %d" % child_count
		draw_string(font, Vector2(viz_margin + 14.0, panel_y + 38.0), child_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.4, 0.5))

		var type_str: String = "Type: %s" % mode_name
		draw_string(font, Vector2(viz_margin + viz_width * 0.5, panel_y + 38.0), type_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.4, 0.5))

		_draw_scanlines(vp_size)


	# ── Generic sub-modes ──

	func _draw_generic_sort(target: Node3D, viz_x: float, viz_y: float, viz_w: float, viz_h: float, font: Font) -> void:
		## Bar chart visualization — tries to read values from the artifact
		var values: Array = []
		if "values" in target:
			values = target.get("values")
		elif "data" in target:
			values = target.get("data")

		# Fallback: generate from children positions
		if values.size() == 0:
			for child in target.get_children():
				if child is Node3D:
					values.append(child.position.y)

		if values.size() == 0:
			# Deterministic fallback pattern
			var seed_hash: int = hash(target.name)
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = seed_hash
			for bar_idx in range(16):
				values.append(rng.randf_range(0.1, 1.0))

		var bar_count: int = mini(values.size(), 64)
		var bar_width: float = viz_w / float(bar_count)
		var max_val: float = 0.001
		for v_idx in range(bar_count):
			var v: float = absf(float(values[v_idx]))
			if v > max_val:
				max_val = v

		for bar_i in range(bar_count):
			var normalized: float = absf(float(values[bar_i])) / max_val
			var bar_h: float = normalized * viz_h * 0.9
			var bar_x: float = viz_x + float(bar_i) * bar_width + 1.0
			var bar_y: float = viz_y + viz_h - bar_h
			var hue: float = float(bar_i) / float(bar_count)
			var bar_color: Color = Color.from_hsv(hue * 0.3 + 0.4, 0.7, 0.8, 0.8)
			draw_rect(Rect2(bar_x, bar_y, maxf(bar_width - 2.0, 1.0), bar_h), bar_color)

		draw_string(font, Vector2(viz_x + 4.0, viz_y + 14.0), "n=%d" % bar_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.5))

	func _draw_generic_waveform(target: Node3D, viz_x: float, viz_y: float, viz_w: float, viz_h: float, font: Font) -> void:
		## Waveform line plot
		var mid_y: float = viz_y + viz_h * 0.5

		# Zero line
		draw_line(Vector2(viz_x, mid_y), Vector2(viz_x + viz_w, mid_y), Color(0.15, 0.15, 0.2), 1.0)

		# Generate waveform from target state
		var time_val: float = 0.0
		if "time" in target:
			time_val = float(target.get("time"))
		elif "_time" in target:
			time_val = float(target.get("_time"))
		else:
			time_val = float(Engine.get_frames_drawn()) * 0.016

		var step_count: int = int(viz_w)
		var prev_screen_y: float = mid_y
		for px in range(step_count):
			var t: float = float(px) / viz_w * 4.0 * PI + time_val
			var wave_val: float = sin(t) * 0.5 + sin(t * 2.3) * 0.25 + sin(t * 0.7) * 0.25
			var screen_y: float = mid_y - wave_val * viz_h * 0.4
			if px > 0:
				var alpha: float = 0.5 + 0.5 * absf(wave_val)
				draw_line(Vector2(viz_x + float(px) - 1.0, prev_screen_y), Vector2(viz_x + float(px), screen_y), Color(0.3, 0.8, 1.0, alpha), 1.5)
			prev_screen_y = screen_y

		draw_string(font, Vector2(viz_x + 4.0, viz_y + 14.0), "t=%.2f" % time_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.5))

	func _draw_generic_scatter(target: Node3D, viz_x: float, viz_y: float, viz_w: float, viz_h: float, font: Font) -> void:
		## Particle position scatter plot from children
		var scatter_range: float = 10.0
		var center_x: float = viz_x + viz_w * 0.5
		var center_y: float = viz_y + viz_h * 0.5
		var origin: Vector3 = target.global_position
		var particle_count: int = 0

		for child in target.get_children():
			if child is Node3D:
				var rel: Vector3 = child.global_position - origin
				var sx: float = center_x + (rel.x / scatter_range) * (viz_w * 0.45)
				var sy: float = center_y - (rel.y / scatter_range) * (viz_h * 0.45)
				# Clamp to visualization area
				sx = clampf(sx, viz_x + 2.0, viz_x + viz_w - 2.0)
				sy = clampf(sy, viz_y + 2.0, viz_y + viz_h - 2.0)
				var dot_hue: float = fmod(float(particle_count) * 0.1, 1.0)
				draw_circle(Vector2(sx, sy), 3.0, Color.from_hsv(dot_hue, 0.7, 0.9, 0.7))
				particle_count += 1

		# Cross-hairs at center
		draw_line(Vector2(center_x - 8.0, center_y), Vector2(center_x + 8.0, center_y), Color(0.5, 0.5, 0.6, 0.3), 1.0)
		draw_line(Vector2(center_x, center_y - 8.0), Vector2(center_x, center_y + 8.0), Color(0.5, 0.5, 0.6, 0.3), 1.0)

		draw_string(font, Vector2(viz_x + 4.0, viz_y + 14.0), "n=%d" % particle_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.5))

	func _draw_generic_graph(target: Node3D, viz_x: float, viz_y: float, viz_w: float, viz_h: float, font: Font) -> void:
		## Node and edge visualization from children
		var nodes_2d: Array = []  # Array of Vector2
		var origin: Vector3 = target.global_position
		var graph_range: float = 8.0
		var center_x: float = viz_x + viz_w * 0.5
		var center_y: float = viz_y + viz_h * 0.5

		for child in target.get_children():
			if child is Node3D:
				var rel: Vector3 = child.global_position - origin
				var nx: float = center_x + (rel.x / graph_range) * (viz_w * 0.4)
				var ny: float = center_y - (rel.y / graph_range) * (viz_h * 0.4)
				nodes_2d.append(Vector2(nx, ny))

		# Draw edges between nearby nodes
		for i in range(nodes_2d.size()):
			for j in range(i + 1, mini(nodes_2d.size(), i + 4)):
				var ni: Vector2 = nodes_2d[i]
				var nj: Vector2 = nodes_2d[j]
				var edge_dist: float = ni.distance_to(nj)
				if edge_dist < viz_w * 0.3:
					var edge_alpha: float = 1.0 - (edge_dist / (viz_w * 0.3))
					draw_line(ni, nj, Color(0.3, 0.5, 0.8, edge_alpha * 0.4), 1.0)

		# Draw nodes
		for k in range(nodes_2d.size()):
			var node_pos: Vector2 = nodes_2d[k]
			var node_hue: float = fmod(float(k) * 0.15, 1.0)
			draw_circle(node_pos, 5.0, Color.from_hsv(node_hue, 0.6, 0.9, 0.8))
			draw_circle(node_pos, 3.0, Color.from_hsv(node_hue, 0.4, 1.0))

		draw_string(font, Vector2(viz_x + 4.0, viz_y + 14.0), "V=%d" % nodes_2d.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.5))

	func _draw_generic_radar(target: Node3D, viz_x: float, viz_y: float, viz_w: float, viz_h: float, font: Font) -> void:
		## Fallback: radar/scope animation with artifact info
		var center_x: float = viz_x + viz_w * 0.5
		var center_y: float = viz_y + viz_h * 0.5
		var radius: float = minf(viz_w, viz_h) * 0.4

		# Concentric rings
		for ring_i in range(4):
			var ring_r: float = radius * (float(ring_i + 1) / 4.0)
			var ring_segments: int = 48
			for seg in range(ring_segments):
				var a0: float = float(seg) / float(ring_segments) * TAU
				var a1: float = float(seg + 1) / float(ring_segments) * TAU
				var r0: Vector2 = Vector2(center_x + cos(a0) * ring_r, center_y + sin(a0) * ring_r)
				var r1: Vector2 = Vector2(center_x + cos(a1) * ring_r, center_y + sin(a1) * ring_r)
				draw_line(r0, r1, Color(0.1, 0.2, 0.15, 0.4), 1.0)

		# Cross-hairs
		draw_line(Vector2(center_x - radius, center_y), Vector2(center_x + radius, center_y), Color(0.1, 0.3, 0.15, 0.3), 1.0)
		draw_line(Vector2(center_x, center_y - radius), Vector2(center_x, center_y + radius), Color(0.1, 0.3, 0.15, 0.3), 1.0)

		# Sweeping line (animated)
		var sweep_angle: float = fmod(float(Engine.get_frames_drawn()) * 0.03, TAU)
		var sweep_end_x: float = center_x + cos(sweep_angle) * radius
		var sweep_end_y: float = center_y + sin(sweep_angle) * radius
		draw_line(Vector2(center_x, center_y), Vector2(sweep_end_x, sweep_end_y), Color(0.2, 1.0, 0.4, 0.6), 2.0)

		# Sweep trail (fading arc behind the line)
		for trail_i in range(20):
			var trail_angle: float = sweep_angle - float(trail_i) * 0.05
			var trail_end_x: float = center_x + cos(trail_angle) * radius
			var trail_end_y: float = center_y + sin(trail_angle) * radius
			var trail_alpha: float = 0.3 * (1.0 - float(trail_i) / 20.0)
			draw_line(Vector2(center_x, center_y), Vector2(trail_end_x, trail_end_y), Color(0.2, 0.8, 0.3, trail_alpha), 1.0)

		# Center dot
		draw_circle(Vector2(center_x, center_y), 4.0, Color(0.3, 1.0, 0.5, 0.8))

		# Artifact name
		var name_str: String = screen_ref._source_artifact_name
		draw_string(font, Vector2(viz_x + 8.0, viz_y + viz_h - 8.0), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.7, 0.3, 0.6))
