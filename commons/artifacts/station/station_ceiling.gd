extends Node3D
class_name StationCeiling

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the kit's OVERHEAD member — a grid-modular ceiling run (1 m per cell along +X) hung
# at `mount_height`, in four kinds: "tiles" (coffered ceiling plane with one lit tile), "tray"
# (an open cable tray on drop rods, cables running the length), "duct" (a rectangular vent duct
# with a diffuser), "beam" (a painted I-beam). Origin at the FLOOR centre — the piece builds
# upward to its height, so placement stays floor-based like every other kit member.
# desire: to close the bay from above — a station with a floor line, a wall run and NO ceiling
# reads as a stage set; one overhead run makes it a room.
# critical_parameter: kind × length_cells × mount_height — what service runs overhead, how far,
# and how low it hangs over the work.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: a lit coffer reads "serviced room"; a cable tray overhead + a wall drop below reads
# "the power comes from somewhere"; a duct reads "air is handled"; a beam reads "held up".
# needs: drop rods for hung kinds [present]; per-cell coffers / cable runs / diffuser [present].
# relationships: continues [[station_wall_module]]'s cabletray at high level; lights what
# [[station_luminaire]] doesn't; the overhead complement of [[station_floor_module]].
# truth: a room is what happens between two horizontal planes. The kit had one; this is the other.

@export_group("Kind")
## "tiles" | "tray" | "duct" | "beam"
@export var kind: String = "tiles"

@export_group("Grid")
## Run length in 1 m cells along +X.
@export var length_cells: int = 3
## Ceiling plane height in metres (the run builds AT this height, hung members drop below it).
@export var mount_height: float = 3.0

@export_group("Surface")
@export var finish: String = "rams"
@export var wear: float = 0.08
@export var stencil_text: String = ""

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

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
	if has_meta("config_kind"): kind = str(get_meta("config_kind")).to_lower()
	if has_meta("config_length_cells"): length_cells = int(str(get_meta("config_length_cells")))
	if has_meta("config_mount_height"): mount_height = float(str(get_meta("config_mount_height")))
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_term: bool = finish == "terminal"
	var bcol: Color = pal["body"] if is_term else body_color
	var pcol: Color = pal["panel"] if is_term else panel_color
	var acol: Color = pal["accent"] if is_term else accent_color
	var w: float = maxf(float(length_cells), 1.0)
	var hy: float = maxf(mount_height, 2.2)
	var body := HangarKit.finish_body(finish, bcol, wear)
	var trim := HangarKit.worn_metal(pcol)

	match kind:
		"tray":
			_build_tray(w, hy, trim, pcol, acol)
		"duct":
			_build_duct(w, hy, body, trim, pcol, acol)
		"beam":
			_build_beam(w, hy, trim, pcol, acol)
		_:
			_build_tiles(w, hy, body, trim, pcol, acol)
	if stencil_text.strip_edges() != "":
		var q := HangarKit.stencil(stencil_text, Vector2(minf(w * 0.4, 0.5), 0.07))
		if q:
			q.position = Vector3(0, hy - 0.28, 0.16)
			add_child(q)


# ── tiles: the coffered plane, one tile lit ─────────────────────────────────
func _build_tiles(w: float, hy: float, body: StandardMaterial3D, trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	add_child(HangarKit.box(Vector3(0, hy, 0), Vector3(w, 0.08, 1.0), body))
	var lit: int = length_cells / 2
	for i in range(length_cells):
		var cx: float = -w * 0.5 + float(i) + 0.5
		var coffer_mat: StandardMaterial3D = HangarKit.emissive(Color(0.98, 0.96, 0.9), 1.8) if i == lit else HangarKit.finish_body(finish, pcol, wear)
		add_child(HangarKit.box(Vector3(cx, hy - 0.045, 0), Vector3(0.86, 0.015, 0.86), coffer_mat))
	# perimeter trim rails
	add_child(HangarKit.box(Vector3(0, hy - 0.05, 0.49), Vector3(w, 0.03, 0.03), trim))
	add_child(HangarKit.box(Vector3(0, hy - 0.05, -0.49), Vector3(w, 0.03, 0.03), trim))


# ── tray: the open cable run on drop rods ───────────────────────────────────
func _build_tray(w: float, hy: float, trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var ty: float = hy - 0.45
	for rx in [-w * 0.5 + 0.3, w * 0.5 - 0.3]:
		add_child(_vpipe(Vector3(rx, hy, 0), Vector3(rx, ty, 0), 0.015, trim))
		add_child(HangarKit.box(Vector3(rx, hy, 0), Vector3(0.12, 0.03, 0.12), trim))
	add_child(HangarKit.box(Vector3(0, ty, 0), Vector3(w, 0.025, 0.3), trim))
	add_child(HangarKit.box(Vector3(0, ty + 0.06, 0.14), Vector3(w, 0.12, 0.02), trim))
	add_child(HangarKit.box(Vector3(0, ty + 0.06, -0.14), Vector3(w, 0.12, 0.02), trim))
	for i in range(5):
		var cc: Color = [Color(0.16, 0.17, 0.2), acol, Color(0.2, 0.4, 0.65), Color(0.7, 0.7, 0.72), Color(0.16, 0.17, 0.2)][i]
		add_child(_vpipe(Vector3(-w * 0.5 + 0.04, ty + 0.05 + (i % 2) * 0.035, -0.09 + i * 0.045),
			Vector3(w * 0.5 - 0.04, ty + 0.05 + (i % 2) * 0.035, -0.09 + i * 0.045), 0.016, HangarKit.worn_metal(cc)))


# ── duct: air handled — the rectangular run + diffuser ──────────────────────
func _build_duct(w: float, hy: float, body: StandardMaterial3D, trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var dy: float = hy - 0.32
	add_child(HangarKit.box(Vector3(0, dy, 0), Vector3(w, 0.34, 0.46), HangarKit.finish_body(finish, pcol, wear)))
	# segment flanges every metre
	for i in range(length_cells + 1):
		add_child(HangarKit.box(Vector3(-w * 0.5 + float(i), dy, 0), Vector3(0.04, 0.38, 0.5), trim))
	# hanger rods
	for rx in [-w * 0.5 + 0.4, w * 0.5 - 0.4]:
		add_child(_vpipe(Vector3(rx, hy, 0), Vector3(rx, dy + 0.17, 0), 0.014, trim))
	# diffuser grille at centre bottom
	add_child(HangarKit.box(Vector3(0, dy - 0.19, 0), Vector3(0.6, 0.05, 0.5), trim))
	for i in range(4):
		add_child(HangarKit.box(Vector3(-0.21 + i * 0.14, dy - 0.22, 0), Vector3(0.02, 0.03, 0.44), HangarKit.worn_metal(pcol.darkened(0.3))))
	# hazard tap: a small accent band on one flange
	add_child(HangarKit.box(Vector3(w * 0.5 - 1.0, dy + 0.12, 0.24), Vector3(0.3, 0.05, 0.01), HangarKit.emissive(acol, 0.8)))


# ── beam: held up — the painted I-beam ──────────────────────────────────────
func _build_beam(w: float, hy: float, trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var by: float = hy - 0.18
	var painted := HangarKit.painted_metal(pcol.darkened(0.1), 0.25)
	add_child(HangarKit.box(Vector3(0, by + 0.14, 0), Vector3(w, 0.05, 0.3), painted))
	add_child(HangarKit.box(Vector3(0, by, 0), Vector3(w, 0.24, 0.05), painted))
	add_child(HangarKit.box(Vector3(0, by - 0.14, 0), Vector3(w, 0.05, 0.3), painted))
	# rivet rows along the web
	add_child(HangarKit.bolts(Vector3(-w * 0.5 + 0.15, by, 0.03), Vector3(w * 0.5 - 0.15, by, 0.03), maxi(length_cells * 3, 4), 0.012, trim))
	# a hazard-striped clamp collar near one end
	var collar := HangarKit.box(Vector3(w * 0.35, by, 0), Vector3(0.12, 0.3, 0.34), HangarKit.striped_mat())
	add_child(collar)


func _vpipe(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = maxf(a.distance_to(b), 0.001)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var yv: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(yv.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var xv: Vector3 = ref.cross(yv).normalized()
	var zv: Vector3 = xv.cross(yv).normalized()
	mi.transform = Transform3D(Basis(xv, yv, zv), (a + b) * 0.5)
	return mi


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
