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
# relationships: the BETWEEN-sibling of [[station_plinth]] (the plinth isolates a thing; the floorline connects two of them); routes the set the [[station_stage]] holds; laid + aimed by [[curation_station]]; the floor-bound complement of the overhead [[station_luminaire]].
# truth: a floorline is a claim that meaning lives in the relation, not only the object. The ground that points is already an argument — it says these two belong to one walk, and the body agrees with its feet before the mind reads a word.

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
	var lit := _emi(accent_color, 0.7)

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
	var tick_mat := _emi(accent_color, 1.0)
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
