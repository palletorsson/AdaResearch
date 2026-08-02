extends Node3D
class_name StationFloorline

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the FLUSH floor element the kit lays DOWN, not up — a length_cells × width (m) strip of painted metal set ~2 cm proud of the floor, read with the feet. Three styles: "line" = a single lit groove that joins two bays; "path" = a dashed processional runner with directional chevrons; "threshold" = a wider bar with end ticks you cross. Origin at the floor CENTRE; the strip runs along +X. The kit's only piece about BETWEEN, never ON.
# desire: to join two places — the ground made to point. Where the plinth says "this one, here, alone", the floorline says "from here, this way, to there"; it lays a relation across the floor so the body knows the route before it reads a label.
# critical_parameter: length_cells × style + direction — how far the relation reaches, what kind of joining it is (a line that links, a runner that processes, a bar that admits), and which way it points (chevrons along +X, none, or −X). The composer lays one between two curated bays to make the walk legible.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new length/style.
# emerges: "line" = a hairline of light tying a set together; "path" = a dashed runner with chevrons that reads as a direction of travel; "threshold" = a crossing bar with ticks that says "you are entering". Direction turns a neutral strip into an arrow you walk.
# needs: a recessed inlay channel set into the floor [present]; a flush emissive accent run [present]; per-style dressing — solid groove / dashed segments + chevrons / wide bar + end ticks [present]; an optional grime band where the inlay meets the floor [optional].
# relationships: the BETWEEN-sibling of [[station_plinth]] (the plinth isolates a thing; the floorline connects two of them); routes the set the [[station_stage]] holds; laid + aimed by [[curation_station]]; the floor-bound complement of the overhead [[station_luminaire]]; KIN of [[station_pillar]], [[station_crates]] and [[station_wall]] — one `upkeep` vocabulary across the kit, the route telling the same time as the structure.
# truth: a floorline is a claim that meaning lives in the relation, not only the object. The ground that points is already an argument — it says these two belong to one walk, and the body agrees with its feet before the mind reads a word.

# ─────────────────────────────────────────────────────────────────────────────
# This artifact's truth line says the ground that points is already an argument —
# that a route is a claim about a walk somebody takes. But the route had no time.
# Every one of its 19 placements renders the same instant: freshly inlaid, lit,
# unobstructed, the walk always available. A path that can only be open cannot
# say anything about a bay where the walk is shut.
#
#   upkeep   WHICH MOMENT of the working life   service · works · store · scrap
#
#   service  in commission — the legacy lineage, byte for byte
#   works    mid-job       — a trestle barrier standing ACROSS the run, cable laid beside it, WORKS
#   store    packed down   — a board runner sheeted over the whole strip and banded; the light is under it
#   scrap    robbed        — the lit run lifted out, a dead channel, two cover plates leaning, tape across
#
# The lit run is the pivot, exactly as the groove is on the pillar and the seam is
# on the wall: it is the only emissive surface the piece has and so owns the
# brightest pixels in any frame it appears in. `store` covers it and `scrap`
# rebuilds it as dead metal — the difference between a route that is on and a
# route that is not, visible from across a room rather than only under measurement.
#
# What it cost: two guards inside `_build()`/`_build_threshold()` where there used
# to be a straight `_emi()` call. Both are written so `service` evaluates to the
# old expression, and the dressing is appended LAST so no child index above moves.
#
# Deliberately NOT routed through upkeep: `length_cells`, `width` and `direction`.
# The composer lays a floorline to reach exactly between two bays and aims it; an
# upkeep value that changed the run or the arrow would tear the route it was laid
# to make. Upkeep dresses the strip; it never re-routes it.
# ─────────────────────────────────────────────────────────────────────────────

@export_group("Grid")
## Length of the run in 1 m cells along +X. The strip is laid centred on the floor; it joins one bay to the next.
@export var length_cells: int = 3

@export_group("Dimensions")
## Strip width across Z, in metres (~0.2 broad-line to ~0.6 processional bar).
@export var width: float = 0.3
## How far the inlay sits proud of the floor (a flush element — only ~2 cm of relief).
@export var proud: float = 0.02

@export_group("Style")
## "line" (a single lit groove) | "path" (a dashed runner with chevrons) | "threshold" (a wider crossing bar with end ticks).
@export var style: String = "line"
## Which way the relation points: 1 = chevrons toward +X, -1 = toward -X, 0 = no chevrons (a neutral join).
@export var direction: int = 1

## AXIS — WHICH MOMENT of the working life this run of floor is caught in. Adopted word for
## word from [[station_pillar]], [[station_crates]] and [[station_wall]], which already share
## it: one kit, one vocabulary, so a bay whose corners read "packed down" cannot have a route
## through it that still reads "in commission". curation_station passes its own #upkeep: down
## to everything it composes.
##
##   service  in commission — the legacy lineage, byte for byte
##   works    mid-job       — a trestle barrier across the run, a cable laid beside it
##   store    packed down   — a board runner sheeted over the whole strip and banded
##   scrap    robbed        — the lit run lifted out, plates leaning, tape across the channel
@export var upkeep: String = "service"
const UPKEEPS: PackedStringArray = ["service", "works", "store", "scrap"]

@export_group("Surface")
@export var wear: float = 0.08
## A faint grime band where the inlay meets the floor, so the strip reads as set into the ground, not stuck on.
@export var grime: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.74, 0.72, 0.68)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const INLAY_DEPTH := 0.05      # how deep the recessed channel reads (the floor inlay frame)
const FRAME_MARGIN := 0.04     # border of body-metal around the lit run, each side across Z

var _built := false

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
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_length_cells"): length_cells = int(str(get_meta("config_length_cells")))
	if has_meta("config_width"): width = float(str(get_meta("config_width")))
	if has_meta("config_proud"): proud = float(str(get_meta("config_proud")))
	if has_meta("config_style"): style = str(get_meta("config_style")).to_lower()
	if has_meta("config_direction"): direction = int(str(get_meta("config_direction")))
	if has_meta("config_upkeep"):
		var _u: String = str(get_meta("config_upkeep")).strip_edges().to_lower()
		upkeep = _u if UPKEEPS.has(_u) else upkeep
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var lcells: int = maxi(length_cells, 1)
	var length: float = float(lcells) * CELL
	var w: float = clampf(width, 0.12, CELL)
	var ph: float = maxf(proud, 0.008)
	# "threshold" reads as a crossing bar — give it a touch more width so it reads as a thing you step over.
	if style == "threshold":
		w = clampf(width * 1.4, 0.18, CELL)

	var body_mat := _mat(body_color)
	var frame_mat := _mat(body_color.darkened(0.16))
	# `scrap` lifts the lit run out of the channel: the same geometry is rebuilt in dead worn
	# metal, so the strip keeps its shape and loses its light. Every other value evaluates to
	# the old expression, byte for byte.
	var lit: Material = _emi(accent_color, 0.7)
	if upkeep == "scrap":
		lit = HangarKit.worn_metal(body_color.darkened(0.58))

	# Recessed inlay channel: a slightly oversized darker frame set into the floor, with the proud body
	# plate on top of it — so the strip reads as a channel cut into the ground (Rams "let the join show"),
	# never a slab dropped on the surface. The frame sits below 0, the body just proud of it.
	add_child(_box(Vector3(0, -INLAY_DEPTH * 0.5, 0), Vector3(length + 0.06, INLAY_DEPTH, w + 0.08), frame_mat))
	add_child(_box(Vector3(0, ph * 0.5, 0), Vector3(length, ph, w), body_mat))

	# A faint grime band where the inlay meets the floor (front edge, +Z), so it reads as set in.
	if grime:
		add_child(HangarKit.grime_band(length, 0.04, w * 0.5 + 0.004, body_color))

	match style:
		"path": _build_path(length, w, ph, lit)
		"threshold": _build_threshold(length, w, ph, lit)
		_: _build_line(length, w, ph, lit)

	# UPKEEP dressing, appended LAST so every child index and position above is untouched
	# on the legacy path. "service" falls through and adds nothing at all.
	match upkeep:
		"works":
			_upkeep_works(length, w, ph)
		"store":
			_upkeep_store(length, w, ph)
		"scrap":
			_upkeep_scrap(length, w, ph)
		_:
			pass                                  # "service" — the legacy lineage


func _build_line(length: float, w: float, ph: float, lit: Material) -> void:
	# A single continuous lit groove down the centre of the strip — the hairline of light that ties two
	# bays together. The lit run is inset from the strip edges by FRAME_MARGIN so body-metal frames it.
	var groove_w: float = maxf(w - FRAME_MARGIN * 2.0, 0.04)
	add_child(_box(Vector3(0, ph + 0.004, 0), Vector3(length - 0.06, 0.014, groove_w), lit))
	# Direction, if set, still shows as a few sparse chevrons riding the line.
	if direction != 0:
		_build_chevrons(length, w, ph, lit, maxi(int(length / 1.2), 2), 0.55)


func _build_path(length: float, w: float, ph: float, lit: Material) -> void:
	# A dashed processional runner: lit segments with gaps, plus directional chevrons — reads at a glance
	# as a direction of travel, the ground saying "this way".
	var dash_w: float = maxf(w - FRAME_MARGIN * 2.0, 0.04)
	var seg_len := 0.34
	var gap := 0.22
	var pitch := seg_len + gap
	var n: int = maxi(int((length - 0.1) / pitch), 1)
	var span: float = float(n - 1) * pitch
	for i in range(n):
		var x: float = -span * 0.5 + float(i) * pitch
		add_child(_box(Vector3(x, ph + 0.004, 0), Vector3(seg_len, 0.014, dash_w), lit))
	if direction != 0:
		_build_chevrons(length, w, ph, lit, maxi(int(length / 0.8), 3), 0.7)


func _build_threshold(length: float, w: float, ph: float, lit: Material) -> void:
	# A wider crossing bar with end ticks — the line you step over to enter. The lit field fills the bar,
	# capped at each end by a short perpendicular tick that reads as a gate post laid flat.
	var field_w: float = maxf(w - FRAME_MARGIN * 2.0, 0.06)
	add_child(_box(Vector3(0, ph + 0.004, 0), Vector3(length - 0.12, 0.014, field_w), lit))
	# End ticks: short bright bars across the full width at each end of the bar.
	# Dead under `scrap` for the same reason the run is: the ticks are part of the lit fitting
	# that was lifted out. `service`, `works` and `store` evaluate to the old expression.
	var tick_mat: Material = _emi(accent_color, 1.0)
	if upkeep == "scrap":
		tick_mat = HangarKit.worn_metal(body_color.darkened(0.5))
	var ex: float = length * 0.5 - 0.04
	add_child(_box(Vector3(ex, ph + 0.006, 0), Vector3(0.05, 0.018, w + 0.04), tick_mat))
	add_child(_box(Vector3(-ex, ph + 0.006, 0), Vector3(0.05, 0.018, w + 0.04), tick_mat))


func _build_chevrons(length: float, w: float, ph: float, lit: Material, count: int, fill: float) -> void:
	# Directional chevrons (a ">" pointing along +X, or "<" for -X) laid flush on the strip: each is two
	# short emissive bars meeting at a point. direction sets which way the point faces.
	var dir: int = signi(direction)
	if dir == 0:
		return
	var chev_w: float = w * fill                       # how far across Z the chevron arms reach
	var arm_len: float = chev_w * 0.62
	var tip: float = chev_w * 0.5                       # X offset from arm base to the meeting point
	var span: float = length - 0.5
	var n: int = maxi(count, 1)
	var step: float = span / float(maxi(n, 1))
	for i in range(n):
		var cx: float = -span * 0.5 + (float(i) + 0.5) * step
		var holder := Node3D.new()
		holder.position = Vector3(cx, ph + 0.007, 0)
		# Two arms forming a chevron in the XZ plane; rotate the whole holder so the point faces dir·+X.
		var a := _box(Vector3(-tip * 0.5 * dir, 0, chev_w * 0.25), Vector3(arm_len, 0.012, 0.03), lit)
		a.rotation_degrees = Vector3(0, -32 * dir, 0)
		var b := _box(Vector3(-tip * 0.5 * dir, 0, -chev_w * 0.25), Vector3(arm_len, 0.012, 0.03), lit)
		b.rotation_degrees = Vector3(0, 32 * dir, 0)
		holder.add_child(a)
		holder.add_child(b)
		add_child(holder)


func _mat(c: Color) -> StandardMaterial3D:
	return HangarKit.rams_body(c, wear)


func _emi(c: Color, energy: float) -> StandardMaterial3D:
	return HangarKit.emissive(c, energy)


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))


# ── UPKEEP ───────────────────────────────────────────────────────────────────
# One axis, four moments, shared word for word with station_pillar.gd,
# station_crates.gd and station_wall.gd. Built from HangarKit helpers so the
# family stays inside the cabinet grammar. Every value dresses the run; none of
# them moves it, re-lengths it or turns the arrow around.

## WORKS — the route mid-job. A trestle barrier stands ACROSS the strip with a striped top
## rail, and a cable is run down the side of the inlay. The barrier is the silhouette change:
## a half-metre upright mass standing on a piece that is otherwise 2 cm of relief, and it
## reads instantly as a walk you cannot take right now.
func _upkeep_works(length: float, w: float, ph: float) -> void:
	var steel: StandardMaterial3D = HangarKit.worn_metal(body_color.lightened(0.04))
	var bx: float = -length * 0.16                 # the barrier stands short of centre
	var leg_h: float = 0.50
	var zleg: float = w * 0.5 + 0.07
	for sz in [-1.0, 1.0]:
		add_child(_box(Vector3(bx, ph + leg_h * 0.5, sz * zleg), Vector3(0.05, leg_h, 0.05), steel))
		# a splayed foot so the trestle stands rather than floats
		add_child(_box(Vector3(bx, ph + 0.02, sz * zleg), Vector3(0.30, 0.035, 0.07), steel))
	# Striped top rail spanning the full crossing, plus a plain mid rail under it.
	add_child(_box(Vector3(bx, ph + leg_h, 0), Vector3(0.07, 0.10, w + 0.30), HangarKit.striped_mat()))
	add_child(_box(Vector3(bx, ph + leg_h * 0.58, 0), Vector3(0.05, 0.05, w + 0.24), steel))
	# Cable run laid down the +Z side of the inlay — the sign that the strip is opened.
	add_child(_box(Vector3(0, ph + 0.025, w * 0.5 + 0.12),
		Vector3(length * 0.86, 0.05, 0.05),
		HangarKit.worn_metal(accent_color.darkened(0.35))))
	for f in [-0.3, 0.1, 0.4]:
		add_child(_box(Vector3(length * f, ph + 0.012, w * 0.5 + 0.12),
			Vector3(0.05, 0.026, 0.09), steel))
	var q: MeshInstance3D = HangarKit.stencil("WORKS", Vector2(minf(length * 0.18, 0.5), 0.12))
	if q:
		q.position = Vector3(length * 0.28, ph + 0.012, 0)
		q.rotation_degrees = Vector3(-90, 0, 0)    # laid flat, read from above
		add_child(q)


## STORE — the route packed down. A board runner is pulled over the whole strip and banded,
## which covers the lit run, the dashes and the chevrons together. The floorline stops being
## a surface that points anywhere and becomes a wrapped length. The cover overhangs by 9 cm
## per side, more than the 6.5 cm of parallax the sweep camera's 15° elevation can see under
## it, so nothing lit peeks out at the edge.
func _upkeep_store(length: float, w: float, ph: float) -> void:
	var sheet: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.31, 0.33), 0.88)
	sheet.roughness = 0.95
	var cy: float = ph + 0.040
	add_child(_box(Vector3(0, cy, 0), Vector3(length + 0.14, 0.045, w + 0.18), sheet))
	# Bands: three straps across the runner in the safety orange the depot register already uses.
	var strap: StandardMaterial3D = HangarKit.painted_metal(Color(0.86, 0.34, 0.11), 0.55)
	for f in [-0.32, 0.0, 0.32]:
		add_child(_box(Vector3(length * f, cy + 0.030, 0),
			Vector3(0.055, 0.014, w + 0.24), strap))
	var q: MeshInstance3D = HangarKit.stencil("PACKED", Vector2(minf(length * 0.20, 0.55), 0.13))
	if q:
		q.position = Vector3(-length * 0.30, cy + 0.026, 0)
		q.rotation_degrees = Vector3(-90, 0, 0)
		add_child(q)


## SCRAP — robbed. The lit fitting has already been lifted out of the channel by the guard in
## _build(), so the run is dead metal in a bare inlay. What is added here is the evidence of
## the lifting: two cover plates stood on edge against the side of the channel, hazard tape
## across the opening, and the fixings left loose on the floor beside it.
func _upkeep_scrap(length: float, w: float, ph: float) -> void:
	var plate: StandardMaterial3D = HangarKit.worn_metal(body_color.darkened(0.22))
	var plate_len: float = minf(length * 0.30, 0.62)
	for sx in [-1.0, 1.0]:
		var p: MeshInstance3D = _box(Vector3(sx * length * 0.24, ph + w * 0.44,
			w * 0.5 + 0.20), Vector3(plate_len, 0.022, w * 0.92), plate)
		p.rotation_degrees = Vector3(72, 0, 0)     # stood on edge, leaning off the channel
		add_child(p)
	# Tape across the opening, two runs, crossed off square.
	for i in range(2):
		var a: float = -0.14 if i == 0 else 0.16
		var t: MeshInstance3D = _box(Vector3(length * a, ph + 0.030, 0),
			Vector3(0.065, 0.012, w + 0.20), HangarKit.striped_mat())
		t.rotation_degrees = Vector3(0, 9.0 if i == 0 else -9.0, 0)
		add_child(t)
	# The fixings, left on the floor beside the bare channel.
	var loose: Node3D = HangarKit.bolts(
		Vector3(-length * 0.34, ph + 0.014, -(w * 0.5 + 0.11)),
		Vector3(length * 0.10, ph + 0.014, -(w * 0.5 + 0.11)),
		5, 0.022, HangarKit.worn_metal(body_color.darkened(0.34)))
	loose.rotation_degrees = Vector3(-90, 0, 0)    # bolts() lays caps facing +Z; face them up
	add_child(loose)
