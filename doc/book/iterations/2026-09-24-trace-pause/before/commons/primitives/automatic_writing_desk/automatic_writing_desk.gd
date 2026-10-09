extends Node3D
class_name AutomaticWritingDesk

# @identity
# essence: a small desk with a sheet of paper on it, and an invisible pen that writes by itself — driven by the movement of your HEAD. The headset is the hand. A nib travels left to right across the page laying down an ink line; when it reaches the right margin it returns to the left and drops to the next row, the way a typewriter or a hand fills a page. What it writes is asemic — wordless script, the look of handwriting with no language in it — and its shape is your head's motion: hold still and the row comes out a calm flat line; turn, lean, look around, and the row breaks into jagged loops. Row by row the page fills with a transcription of how your head moved while you stood there. Surrealist automatic writing and the spiritualist planchette, with the headset as the medium.
# desire: it wants to write you without your consent and without your words — to take the one input you cannot hold still (the head, always microscopically moving, always turning toward what catches the eye) and render it as a script you didn't choose to produce. It wants the page to look like a confession in a language no one can read: legibly handwriting, illegibly meaning. It puts automatic writing in drag as biometric transcription — the headset that knows where you looked, writing it down in asemic cursive, row after row.
# critical_parameter: head_speed_scale × letters_freq. A small head_speed_scale makes the pen leap into jagged script at the faintest head motion (the page is loud, every glance inscribed); a large one keeps the rows calm unless you move sharply (the page is discreet). letters_freq sets how many "letters" per row — coarse scrawl or fine hand. Between them: how much of your attention the page is allowed to write down, and how finely.
# triggers: _ready builds the desk + paper + faint ruled lines and pre-seeds several written rows; _process finds the XRCamera3D (the head), measures its speed, and advances the pen left-to-right / row-by-row, laying ink dots whose vertical wander scales with head speed; at the bottom of the page it starts a fresh sheet; with no headset it runs a demo head-drift so the page writes itself in capture.
# emerges: on the lab table beside the cold hand-telemetry diptych, it is the warm, involuntary member of the trace set — not your hands logged as numbers but your head transcribed as script. Where `mystic_writing_pad` keeps what you draw and the diptych logs where your hands are, this writes what your attention does, in a hand that is yours and unreadable.
# needs: a desk + a page to write on [present]; an instrument that advances row by row like writing [the pen, present]; a driver that is involuntary and always moving [the head / XRCamera3D, with a demo fallback]; ink that reads as asemic handwriting [dot script whose amplitude is head speed, present]; ruled lines so the page reads as paper [present]
# relationships: warm head-driven counterpart to `hand_telemetry_diptych` (cold, hand-driven) in the lab trace set; shares the dot-trace motif with `mystic_writing_pad`, `living_paper`, and `draw_dot`; descendant of Surrealist automatic writing (Breton), asemic writing (Michaux, Dermisache), and the seismograph drum; the head-as-pen sibling to the hand-as-pen of `draw_dot`.
# truth: a point is position without extension — and a head, sampled as it turns toward whatever it cannot help looking at, is a confession written in a hand you can't read. The desk transcribes the one thing you never agreed to author: your attention, row by row, in asemic cursive, kept on the page after you walk away.

## Automatic writing desk — the headset's motion writes asemic script on a
## sheet of paper, row by row. The pen sweeps left→right, drops a row at the
## margin, fills the page top→bottom; the vertical wander of each row scales
## with head speed (still = flat line, moving = jagged script). Driven by the
## XRCamera3D; demo head-drift fallback so it writes in capture / desktop.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Desk")
@export var table_w: float = 0.9
@export var table_d: float = 0.66
@export var table_h: float = 0.74
@export var paper_color: Color = Color(0.94, 0.91, 0.83)
@export var wood_color: Color = Color(0.30, 0.26, 0.22)
@export var paper_tilt_deg: float = -14.0

@export_group("Writing")
@export var ink_color: Color = Color(0.10, 0.08, 0.10)
@export var rows: int = 11
@export var letters_freq: float = 7.0
## Page-fractions of u per second the pen advances.
@export var write_speed: float = 0.32
## Head speed (m/s) that maps to maximum row amplitude.
@export var head_speed_scale: float = 1.4
@export var run_demo: bool = true

# ── State ─────────────────────────────────────────────────────────────

const PW := 0.5     # page width  (local x)
const PD := 0.62    # page depth  (local z)
const DOT_R := 0.0062
const SPACING := 0.012

var _built: bool = false
var _paper: Node3D = null
var _ink: MultiMeshInstance3D = null
var _dot_mesh: SphereMesh = null
var _nib: Node3D = null

var _head: Node3D = null
var _find_timer: float = 0.0
var _have_last_head: bool = false
var _last_head: Vector3 = Vector3.ZERO
var _head_drive: float = 0.0
var _t: float = 0.0

var _pen_u: float = 0.0
var _pen_row: int = 0
var _trace: Array = []      # array of Vector2(u, v)
var _last_ink_u: float = -1.0
var _ink_dirty: bool = false


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
		_built = false
		_paper = null
		_ink = null
		_nib = null
		_trace.clear()
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_rows"):
		rows = maxi(3, int(str(get_meta("config_rows"))))
	if has_meta("config_letters_freq"):
		letters_freq = float(str(get_meta("config_letters_freq")))
	if has_meta("config_write_speed"):
		write_speed = float(str(get_meta("config_write_speed")))
	if has_meta("config_head_speed_scale"):
		head_speed_scale = maxf(0.1, float(str(get_meta("config_head_speed_scale"))))
	if has_meta("config_ink_color"):
		ink_color = _parse_color(str(get_meta("config_ink_color")), ink_color)
	if has_meta("config_paper_color"):
		paper_color = _parse_color(str(get_meta("config_paper_color")), paper_color)
	if has_meta("config_run_demo"):
		var s: String = str(get_meta("config_run_demo")).to_lower()
		run_demo = s == "true" or s == "1" or s == "yes"


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	_build_desk()

	# Paper node on the tabletop, tilted like a writing slope.
	_paper = Node3D.new()
	_paper.name = "Paper"
	_paper.position = Vector3(0, table_h + 0.03, 0.0)
	_paper.rotation_degrees = Vector3(paper_tilt_deg, 0, 0)
	add_child(_paper)

	# Sheet.
	var sheet := MeshInstance3D.new()
	sheet.name = "Sheet"
	var sm := BoxMesh.new()
	sm.size = Vector3(PW, 0.006, PD)
	sheet.mesh = sm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = paper_color
	pmat.roughness = 0.96
	pmat.emission_enabled = true
	pmat.emission = paper_color * 0.5
	pmat.emission_energy_multiplier = 0.2
	sheet.material_override = pmat
	_paper.add_child(sheet)

	# Faint ruled lines (so it reads as writing paper).
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.55, 0.6, 0.72, 0.5)
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for r in range(rows):
		var v: float = _row_baseline(r)
		var line := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(PW * 0.84, 0.0012, 0.0016)
		line.mesh = lm
		line.material_override = lmat
		var lp: Vector3 = _uv_to_local(0.5, v)
		line.position = Vector3(lp.x, 0.0045, lp.z)
		_paper.add_child(line)

	# Ink dots.
	_dot_mesh = SphereMesh.new()
	_dot_mesh.radius = DOT_R
	_dot_mesh.height = DOT_R * 2.0
	_dot_mesh.radial_segments = 6
	_dot_mesh.rings = 3
	_ink = MultiMeshInstance3D.new()
	_ink.name = "Ink"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _dot_mesh
	mm.instance_count = 0
	_ink.multimesh = mm
	var imat := StandardMaterial3D.new()
	imat.albedo_color = ink_color
	imat.roughness = 0.7
	_ink.material_override = imat
	_paper.add_child(_ink)

	# Pen nib.
	_nib = Node3D.new()
	_nib.name = "Pen"
	var nib := MeshInstance3D.new()
	var nmesh := SphereMesh.new()
	nmesh.radius = 0.01
	nmesh.height = 0.02
	nib.mesh = nmesh
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(0.95, 0.85, 0.4)
	nmat.emission_enabled = true
	nmat.emission = Color(0.95, 0.8, 0.3)
	nmat.emission_energy_multiplier = 2.2
	nmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	nib.material_override = nmat
	_nib.add_child(nib)
	# pen body — a thin barrel rising up-and-back from the nib
	var barrel := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.006
	bm.bottom_radius = 0.009
	bm.height = 0.14
	barrel.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.12, 0.12, 0.14)
	bmat.metallic = 0.5
	bmat.roughness = 0.4
	barrel.material_override = bmat
	barrel.rotation_degrees = Vector3(28, 0, 0)
	barrel.position = Vector3(0, 0.07, -0.03)
	_nib.add_child(barrel)
	_paper.add_child(_nib)

	_seed_rows()
	_rebuild_ink()
	_pen_u = 0.1
	_update_nib()


func _build_desk() -> void:
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = wood_color
	wmat.roughness = 0.7
	wmat.metallic = 0.1

	var top := MeshInstance3D.new()
	top.name = "Tabletop"
	var tm := BoxMesh.new()
	tm.size = Vector3(table_w, 0.05, table_d)
	top.mesh = tm
	top.material_override = wmat
	top.position = Vector3(0, table_h, 0)
	add_child(top)

	var lx: float = table_w * 0.5 - 0.06
	var lz: float = table_d * 0.5 - 0.06
	for c in [Vector2(-lx, -lz), Vector2(lx, -lz), Vector2(-lx, lz), Vector2(lx, lz)]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.05, table_h - 0.025, 0.05)
		leg.mesh = lm
		leg.material_override = wmat
		leg.position = Vector3(c.x, (table_h - 0.025) * 0.5, c.y)
		add_child(leg)


# ── Writing ───────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _built:
		return
	_t += delta

	# Find the head (headset) periodically.
	if _head == null or not is_instance_valid(_head):
		_find_timer += delta
		if _find_timer >= 0.5:
			_find_timer = 0.0
			_head = _find_head()

	# Drive = head speed mapped 0..1 (or a demo drift).
	if _head != null and is_instance_valid(_head):
		var hp: Vector3 = _head.global_position
		if _have_last_head:
			var sp: float = (hp - _last_head).length() / maxf(delta, 0.001)
			var target: float = clampf(sp / head_speed_scale, 0.0, 1.0)
			_head_drive = lerpf(_head_drive, target, clampf(delta * 5.0, 0.0, 1.0))
		_last_head = hp
		_have_last_head = true
	elif run_demo:
		var d: float = 0.35 + 0.32 * sin(_t * 1.3) + 0.18 * sin(_t * 0.47 + 1.0)
		_head_drive = clampf(d, 0.0, 1.0)

	# Advance the pen left→right, drop a row at the margin.
	_pen_u += write_speed * delta
	while _pen_u >= 1.0:
		_pen_u -= 1.0
		_pen_row += 1
		_last_ink_u = -1.0
		if _pen_row >= rows:
			_pen_row = 0
			_trace.clear()        # fresh sheet
			_ink_dirty = true

	# Lay ink at the current pen position (throttled by spacing).
	if absf(_pen_u - _last_ink_u) >= SPACING:
		_last_ink_u = _pen_u
		_trace.push_back(Vector2(_pen_u, _row_v(_pen_row, _pen_u)))
		_ink_dirty = true

	if _ink_dirty:
		_rebuild_ink()
		_ink_dirty = false
	_update_nib()


# Vertical position of the ink within a row: a baseline + asemic wander
# whose amplitude is the current head drive (still = flat, moving = jagged).
# Rows inset within page margins [0.10, 0.90] so none escape the sheet edge.
func _row_baseline(row: int) -> float:
	return 0.10 + 0.80 * (float(row) + 0.5) / float(rows)


func _row_v(row: int, u: float) -> float:
	var base_v: float = _row_baseline(row)
	var amp: float = _head_drive * 0.34 / float(rows)
	var wig: float = amp * (0.6 * sin(u * letters_freq * TAU + float(row) * 1.3)
		+ 0.4 * sin(u * letters_freq * 1.9 * TAU + float(row)))
	return clampf(base_v + wig, 0.06, 0.94)


func _uv_to_local(u: float, v: float) -> Vector3:
	# u: 0..1 left→right (x). v: 0..1 top→bottom = far→near (z).
	var x: float = lerpf(-PW * 0.42, PW * 0.42, u)
	var z: float = lerpf(-PD * 0.44, PD * 0.44, v)
	return Vector3(x, 0.006, z)


func _rebuild_ink() -> void:
	var mm: MultiMesh = _ink.multimesh
	var n: int = _trace.size()
	mm.instance_count = n
	for i in range(n):
		var uv: Vector2 = _trace[i]
		mm.set_instance_transform(i, Transform3D(Basis(), _uv_to_local(uv.x, uv.y)))


func _update_nib() -> void:
	if _nib == null:
		return
	_nib.position = _uv_to_local(_pen_u, _row_v(_pen_row, _pen_u))


func _seed_rows() -> void:
	# Pre-fill the top rows so the page arrives already written-into.
	var seed_rows: int = mini(rows - 2, 6)
	for r in range(seed_rows):
		var amp: float = 0.3 + 0.55 * absf(sin(float(r) * 1.7 + 0.4))
		var u: float = 0.07
		while u < 0.93:
			var base_v: float = _row_baseline(r)
			var wig: float = (amp * 0.34 / float(rows)) * (0.6 * sin(u * letters_freq * TAU + float(r) * 1.3)
				+ 0.4 * sin(u * letters_freq * 1.9 * TAU + float(r)))
			_trace.push_back(Vector2(u, clampf(base_v + wig, 0.06, 0.94)))
			u += SPACING
	_pen_row = seed_rows


# ── Head (headset camera) ─────────────────────────────────────────────

func _find_head() -> Node3D:
	var root := get_tree().get_root()
	if root == null:
		return null
	return _search_cam(root)


func _search_cam(node: Node) -> Node3D:
	if node is XRCamera3D:
		return node as Node3D
	for c in node.get_children():
		var f := _search_cam(c)
		if f != null:
			return f
	return null
