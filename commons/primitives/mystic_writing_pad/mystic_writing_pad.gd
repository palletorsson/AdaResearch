extends Node3D
class_name MysticWritingPad

# @identity
# essence: a child's magic slate standing on the lab floor — Freud's Mystic Writing-Pad (the "Wunderblock", 1925): a red-framed toy with a dark wax slab beneath a translucent grey sheet. A luminous stylus wanders the surface and writes a bright trace out of points; every so often the sheet is "lifted" — the bright surface clears blank again — and the trace it just made does not vanish: it sinks into the wax below as a faint warm ghost, where all the earlier traces already lie, overlapping, a palimpsest of everything that was ever written. The surface forgets. The depth remembers. This is the exact apparatus Derrida used to think the trace ("Freud and the Scene of Writing", 1967): there is no clean page and no pure erasure, only a perception-surface that stays fresh over a memory that keeps the lot.
# desire: it wants to teach the trace as the play of presence and absence on two layers at once — to show that "clearing the screen" is never deletion, only displacement into a layer you stopped looking at. It wants the player to write, watch the surface wipe clean, and feel the small dishonesty of that clean: the wax got darker. It wants to put the toy in drag as the AI memory and the platform delete-button — the friendly surface that says "forgotten" over a log that forgot nothing.
# critical_parameter: clear_interval × ghost_persistence. Short clear_interval with high persistence = the surface is almost always blank while the wax goes black with history — the maximal trace, the unconscious that keeps everything. Long clear_interval with zero persistence = an ordinary whiteboard that truly forgets when wiped — mode-collapse, no depth, no trace, a present with no past. ghost_count is the wax's horizon: how far back the depth still holds before the oldest sinks past recall.
# triggers: _ready builds frame + wax + sheet, pre-seeds the wax with several ghost traces (so the palimpsest is there on arrival) and starts a half-written current trace; _process walks the stylus and grows the current trace out of points; every clear_interval it sinks the current trace into the wax as a ghost, fades the older ghosts by age, clears the surface and begins again; apply_grid_config rebuilds on DNA change.
# emerges: watched once it reads as a toy writing by itself. Watched as a loop it teaches that the line you see is only the most recent of many, and that the blank surface is a claim the wax disproves. Beside `draw_dot` (the hand that writes a single trace) it is the apparatus draw_dot writes ONTO — the memory the gesture lands in; beside `klee_walking_point` (the point that walks a line and dims) it is the point that walks, dims, AND is kept. The Trace map's quiet thesis — "no original behind the trace, only encodings at different scales" — made into a thing you can stand in front of.
# needs: a surface that can be cleared [the translucent sheet, present]; a depth that retains [the wax slab + ghost pool, present]; a writing point [the stylus, present]; traces built of points so the line stays honest about being discrete [MultiMesh dot-strokes, present]; age legible as depth [ghosts fade warm with recency, present]
# relationships: the trace-apparatus sibling of `draw_dot` (instrument) and `dark_sphere` (anchor) in the Point_Trace map; theory-cousin to `fontana_puncture` (absence as form — there the void is sculptural, here the erasure is a lie); on the point-timeline of verbs it is the point REMEMBERED, after `klee_walking_point` (1925, moves), `fontana_puncture` (1958, cuts), `you_are_here` (2005, locates) — this is the point as record (Freud 1925 / Derrida 1967 / your data 2036); ancestor of every log, undo-history, version-diff and memory system in the project (including the lab/map diff tools — the trace is what a diff reads).
# truth: a point is position without extension — and a trace is what a point leaves when time is allowed to pass over it. The Mystic Pad is the most honest object about memory in the lab because it lies the way every memory system lies: it shows you a clean surface and keeps the wax. To learn the trace is to learn that nothing you write is ever only on the surface, and that "clear" is the politest word a machine knows for "kept, where you can no longer see it."

## Mystic Writing Pad — Freud's Wunderblock as the trace apparatus.
##
## Built procedurally. Origin at the floor; a stand holds an upright
## framed slate at reading height, facing +Z by default (rotate to face
## the player). The "current" trace is a bright string of points on the
## clearing sheet; sunk traces are faint warm ghosts in the wax beneath.
## Strokes are MultiMesh dot-clouds (cheap, and on-theme: the line made
## of points). The wax keeps the last `ghost_count` traces, fading by age.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Slate")
@export var board_width: float = 0.95
@export var board_height: float = 0.62
@export var stand_height: float = 0.78
@export var frame_color: Color = Color(0.80, 0.12, 0.12)      # the toy's red frame
@export var wax_color: Color = Color(0.09, 0.07, 0.08)        # near-black wax
@export var sheet_color: Color = Color(0.62, 0.65, 0.70, 0.30)  # translucent celluloid

@export_group("Trace")
## Bright "live" mark on the clearing surface.
@export var ink_color: Color = Color(0.80, 0.97, 1.0)
## Faint warm mark kept in the wax (memory).
@export var ghost_color: Color = Color(0.95, 0.62, 0.35)
## Seconds the surface holds a trace before it is lifted (cleared).
@export var clear_interval: float = 3.2
## 0 = wiping truly forgets (no ghost kept). 1 = the wax keeps it fully.
@export var ghost_persistence: float = 0.85
## How many past traces the wax holds before the oldest sinks past recall.
@export var ghost_count: int = 7
## Points a finished trace is quantised into.
@export var stroke_points: int = 64
## How fast the stylus writes (units of curve-parameter per second).
@export var write_speed: float = 0.55
## Ghosts run the spectrum by age instead of the warm wax tone.
@export var pride_ghosts: bool = false

# ── State ─────────────────────────────────────────────────────────────

const DOT_RADIUS := 0.009

var _built: bool = false
var _panel: Node3D = null
var _stylus: MeshInstance3D = null
var _current_mm: MultiMeshInstance3D = null
var _ghosts: Array[MultiMeshInstance3D] = []     # newest last
var _dot_mesh: SphereMesh = null

# current-trace authoring state
var _t: float = 0.0                # how far the current trace is drawn (curve param)
var _elapsed: float = 0.0          # seconds since last clear
var _coeffs: Array = []            # [ax, ay, px, py] for the current scribble
var _seed_phase: float = 0.0       # advances each new stroke for variety


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_reset_state()
		_build()


func _reset_state() -> void:
	_built = false
	_panel = null
	_stylus = null
	_current_mm = null
	_ghosts.clear()
	_dot_mesh = null
	_t = 0.0
	_elapsed = 0.0
	_seed_phase = 0.0


func _read_metadata_overrides() -> void:
	if has_meta("config_clear_interval"):
		clear_interval = float(str(get_meta("config_clear_interval")))
	if has_meta("config_ghost_persistence"):
		ghost_persistence = clampf(float(str(get_meta("config_ghost_persistence"))), 0.0, 1.0)
	if has_meta("config_ghost_count"):
		ghost_count = int(str(get_meta("config_ghost_count")))
	if has_meta("config_write_speed"):
		write_speed = float(str(get_meta("config_write_speed")))
	if has_meta("config_ink_color"):
		ink_color = _parse_color(str(get_meta("config_ink_color")), ink_color)
	if has_meta("config_ghost_color"):
		ghost_color = _parse_color(str(get_meta("config_ghost_color")), ghost_color)
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_pride_ghosts"):
		var s: String = str(get_meta("config_pride_ghosts")).to_lower()
		pride_ghosts = s == "true" or s == "1" or s == "yes"


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var panel_cy: float = stand_height + board_height * 0.5

	# Stand: a post + foot under the slate.
	var post := MeshInstance3D.new()
	post.name = "Post"
	var pm := BoxMesh.new()
	pm.size = Vector3(0.06, stand_height, 0.06)
	post.mesh = pm
	post.material_override = _matte(frame_color.darkened(0.45))
	post.position = Vector3(0, stand_height * 0.5, 0)
	add_child(post)

	var foot := MeshInstance3D.new()
	foot.name = "Foot"
	var fm := BoxMesh.new()
	fm.size = Vector3(0.34, 0.03, 0.22)
	foot.mesh = fm
	foot.material_override = _matte(frame_color.darkened(0.55))
	foot.position = Vector3(0, 0.015, 0)
	add_child(foot)

	# Panel container — all slate geometry is in local coords centred here,
	# so stroke math runs around (0,0,0) in the panel's XY plane (+Z front).
	_panel = Node3D.new()
	_panel.name = "Panel"
	_panel.position = Vector3(0, panel_cy, 0)
	add_child(_panel)

	var hw: float = board_width * 0.5
	var hh: float = board_height * 0.5

	# Red frame — four bars around the slate.
	var frame_mat := _matte(frame_color)
	_add_bar(Vector3(0,  hh + 0.025, 0), Vector3(board_width + 0.10, 0.05, 0.07), frame_mat, "FrameTop")
	_add_bar(Vector3(0, -hh - 0.025, 0), Vector3(board_width + 0.10, 0.05, 0.07), frame_mat, "FrameBottom")
	_add_bar(Vector3(-hw - 0.025, 0, 0), Vector3(0.05, board_height + 0.10, 0.07), frame_mat, "FrameLeft")
	_add_bar(Vector3( hw + 0.025, 0, 0), Vector3(0.05, board_height + 0.10, 0.07), frame_mat, "FrameRight")

	# Wax slab — the depth that remembers (matte, near-black).
	var wax := MeshInstance3D.new()
	wax.name = "Wax"
	var wm := BoxMesh.new()
	wm.size = Vector3(board_width, board_height, 0.04)
	wax.mesh = wm
	var wax_mat := _matte(wax_color)
	wax_mat.roughness = 0.95
	wax.material_override = wax_mat
	wax.position = Vector3(0, 0, -0.005)
	_panel.add_child(wax)

	# Translucent sheet — the perception surface that clears.
	var sheet := MeshInstance3D.new()
	sheet.name = "Sheet"
	var sm := BoxMesh.new()
	sm.size = Vector3(board_width, board_height, 0.004)
	sheet.mesh = sm
	var sheet_mat := StandardMaterial3D.new()
	sheet_mat.albedo_color = sheet_color
	sheet_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sheet_mat.roughness = 0.25
	sheet_mat.metallic = 0.0
	sheet.material_override = sheet_mat
	sheet.position = Vector3(0, 0, 0.026)
	_panel.add_child(sheet)

	# Dot mesh shared by every stroke's MultiMesh.
	_dot_mesh = SphereMesh.new()
	_dot_mesh.radius = DOT_RADIUS
	_dot_mesh.height = DOT_RADIUS * 2.0
	_dot_mesh.radial_segments = 6
	_dot_mesh.rings = 3

	# Pre-seed the wax with ghosts so the palimpsest is present on arrival.
	var seed_n: int = maxi(0, mini(ghost_count, 5))
	for i in range(seed_n):
		_seed_phase += 1.7
		var ghost := _make_stroke_mm("SeedGhost%d" % i, _ghost_material_for(seed_n - i, seed_n))
		_fill_stroke(ghost, _new_coeffs(_seed_phase), 1.0, 0.014 + 0.002 * float(i))
		_panel.add_child(ghost)
		_ghosts.append(ghost)

	# Begin a current trace, already partway written.
	_begin_new_current()
	_t = 0.62
	_elapsed = _t / max(write_speed, 0.01)
	_redraw_current()

	# Stylus — the bright writing nib at the trace head.
	_stylus = MeshInstance3D.new()
	_stylus.name = "Stylus"
	var stm := SphereMesh.new()
	stm.radius = 0.02
	stm.height = 0.04
	_stylus.mesh = stm
	_stylus.material_override = _emissive(ink_color, 2.6)
	_panel.add_child(_stylus)
	_move_stylus()

	set_process(true)


func _add_bar(pos: Vector3, size: Vector3, mat: Material, nm: String) -> void:
	var b := MeshInstance3D.new()
	b.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	b.mesh = bm
	b.material_override = mat
	b.position = pos
	_panel.add_child(b)


# ── Trace animation ───────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _built:
		return
	_elapsed += delta
	_t = _elapsed * write_speed
	if _t >= 1.0:
		_t = 1.0
	_redraw_current()
	_move_stylus()
	if _elapsed >= clear_interval:
		_lift_sheet()


# Sink the current trace into the wax as a ghost, fade older ghosts by
# age, drop the oldest past the horizon, and start a fresh surface.
func _lift_sheet() -> void:
	if ghost_persistence > 0.001 and _current_mm != null:
		var keep := _make_stroke_mm("Ghost", _ghost_material_for(1, max(ghost_count, 1)))
		_fill_stroke(keep, _coeffs, 1.0, 0.013)
		_panel.add_child(keep)
		_ghosts.append(keep)
		# Re-grade every ghost by recency: newest brightest, oldest dimmest.
		var n := _ghosts.size()
		for i in range(n):
			var mat := _ghost_material_for(n - i, max(ghost_count, 1))
			(_ghosts[i] as MultiMeshInstance3D).material_override = mat
		# Drop anything past the wax's horizon.
		while _ghosts.size() > ghost_count:
			var old: MultiMeshInstance3D = _ghosts.pop_front()
			if is_instance_valid(old):
				old.queue_free()

	_elapsed = 0.0
	_t = 0.0
	_begin_new_current()
	_redraw_current()


func _begin_new_current() -> void:
	_seed_phase += 2.3
	_coeffs = _new_coeffs(_seed_phase)
	if _current_mm == null or not is_instance_valid(_current_mm):
		_current_mm = _make_stroke_mm("CurrentTrace", _emissive(ink_color, 2.2))
		_panel.add_child(_current_mm)


func _redraw_current() -> void:
	if _current_mm == null:
		return
	_fill_stroke(_current_mm, _coeffs, _t, 0.03)


# A loopy "handwriting" curve inside the slate rect, sampled to dots.
# coeffs = [ax, ay, px, py]; t01 = fraction of the curve drawn so far;
# z = local depth (sheet front for the live mark, wax for ghosts).
func _fill_stroke(mm_inst: MultiMeshInstance3D, coeffs: Array, t01: float, z: float) -> void:
	var mm: MultiMesh = mm_inst.multimesh
	var n: int = maxi(2, int(round(float(stroke_points) * clampf(t01, 0.02, 1.0))))
	mm.instance_count = n
	var hw: float = board_width * 0.42
	var hh: float = board_height * 0.40
	var ax: float = coeffs[0]
	var ay: float = coeffs[1]
	var px: float = coeffs[2]
	var py: float = coeffs[3]
	var span: float = TAU * 1.6 * clampf(t01, 0.02, 1.0)
	for i in range(n):
		var u: float = float(i) / float(stroke_points)
		var a: float = u * TAU * 1.6
		# left→right drift + lissajous wander keeps it reading as writing.
		var x: float = lerpf(-hw, hw, u) * 0.65 + hw * 0.5 * sin(a * ax + px)
		var y: float = hh * sin(a * ay + py) * (0.6 + 0.4 * sin(a * 0.5 + py))
		var tf := Transform3D(Basis(), Vector3(clampf(x, -hw, hw), clampf(y, -hh, hh), z))
		mm.set_instance_transform(i, tf)
	# silence unused warning on span while keeping the param expressive
	span = span


func _move_stylus() -> void:
	if _stylus == null:
		return
	var hw: float = board_width * 0.42
	var hh: float = board_height * 0.40
	var u: float = clampf(_t, 0.02, 1.0)
	var a: float = u * TAU * 1.6
	var x: float = lerpf(-hw, hw, u) * 0.65 + hw * 0.5 * sin(a * _coeffs[0] + _coeffs[2])
	var y: float = hh * sin(a * _coeffs[1] + _coeffs[3]) * (0.6 + 0.4 * sin(a * 0.5 + _coeffs[3]))
	_stylus.position = Vector3(clampf(x, -hw, hw), clampf(y, -hh, hh), 0.034)
	_stylus.visible = _t < 0.999


func _new_coeffs(phase: float) -> Array:
	# Deterministic-but-varied scribble coefficients from a phase seed.
	return [
		2.0 + 2.0 * abs(sin(phase * 1.7)),
		3.0 + 2.0 * abs(cos(phase * 1.1)),
		phase * 0.9,
		phase * 1.3,
	]


# ── Materials ─────────────────────────────────────────────────────────

func _make_stroke_mm(nm: String, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _dot_mesh
	mm.instance_count = 0
	mmi.multimesh = mm
	mmi.material_override = mat
	return mmi


func _ghost_material_for(recency: int, total: int) -> StandardMaterial3D:
	# recency: total = newest, 1 = oldest. Fade emission + alpha by age, and
	# pull old ghosts toward the wax so depth reads as time.
	var f: float = clampf(float(recency) / float(max(total, 1)), 0.12, 1.0)
	var base: Color = ghost_color
	if pride_ghosts:
		base = Color.from_hsv(fmod(float(recency) * 0.13, 1.0), 0.7, 1.0)
	var c: Color = base.lerp(wax_color, 1.0 - f) * ghost_persistence
	var mat := _emissive(c, 0.5 + 1.4 * f)
	mat.albedo_color = c
	return mat


func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _matte(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	m.metallic = 0.0
	return m
