extends Node3D
class_name StationFloorModule

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the kit's WORKING floor member — beyond [[station_floorline]]'s pure relation-lines,
# this is floor that DOES something: "grate" (a walkable metal grate strip over a dark cavity),
# "channel" (a recessed cable channel with cover plates and a lit slit), "hatch" (a bolted
# square access hatch with hinges and a stencil). 1 m per cell along +X, flush-proud of the
# floor like the floorline (read with the feet). Origin at the floor centre.
# desire: to make the floor admit the building continues below — services arrive from the wall
# (the drop), run under the floor (the channel), and can be reached (the hatch).
# critical_parameter: kind × length_cells — what the floor does and for how far.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: a grate reads "machine room below"; a channel tracing wall-drop to bench reads "that
# is where the power goes"; a hatch reads "someone maintains this place".
# needs: flush frames [present]; slat grid / cover plates / hinge blocks [present].
# relationships: receives [[station_wall_module]]'s conduit drops; the underfoot complement of
# [[station_ceiling]]; the working sibling of [[station_floorline]] (that one relates, this one
# serves).
# truth: a floor that admits what runs beneath it makes the room honest — the walkable surface
# is a lid, and the kit says so.

@export_group("Kind")
## "grate" | "channel" | "hatch"
@export var kind: String = "grate"

@export_group("Grid")
## Run length in 1 m cells along +X (hatch is always a single 0.8 m plate).
@export var length_cells: int = 2

@export_group("Surface")
@export var finish: String = "rams"
@export var wear: float = 0.1
@export var stencil_text: String = ""

@export_group("Color")
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
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_term: bool = finish == "terminal"
	var pcol: Color = pal["panel"] if is_term else panel_color
	var acol: Color = pal["accent"] if is_term else accent_color
	var trim := HangarKit.worn_metal(pcol)
	match kind:
		"channel":
			_build_channel(trim, pcol, acol)
		"hatch":
			_build_hatch(trim, pcol, acol)
		_:
			_build_grate(trim, pcol, acol)


# ── grate: the walkable lid over the dark below ─────────────────────────────
func _build_grate(trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var w: float = maxf(float(length_cells), 1.0)
	var d: float = 0.9
	# dark cavity, just under the slats
	add_child(HangarKit.box(Vector3(0, 0.004, 0), Vector3(w - 0.1, 0.008, d - 0.1), HangarKit.worn_metal(Color(0.06, 0.065, 0.08))))
	# frame
	add_child(HangarKit.box(Vector3(0, 0.02, d * 0.5 - 0.03), Vector3(w, 0.04, 0.06), trim))
	add_child(HangarKit.box(Vector3(0, 0.02, -d * 0.5 + 0.03), Vector3(w, 0.04, 0.06), trim))
	add_child(HangarKit.box(Vector3(-w * 0.5 + 0.03, 0.02, 0), Vector3(0.06, 0.04, d), trim))
	add_child(HangarKit.box(Vector3(w * 0.5 - 0.03, 0.02, 0), Vector3(0.06, 0.04, d), trim))
	# slats across (walk direction along X)
	var n: int = int(w / 0.09)
	for i in range(n):
		var sx: float = -w * 0.5 + 0.08 + float(i) * (w - 0.16) / float(maxi(n - 1, 1))
		add_child(HangarKit.box(Vector3(sx, 0.028, 0), Vector3(0.025, 0.03, d - 0.14), HangarKit.worn_metal(pcol.darkened(0.12))))
	# one long runner each side
	add_child(HangarKit.box(Vector3(0, 0.03, d * 0.25), Vector3(w - 0.16, 0.028, 0.025), trim))
	add_child(HangarKit.box(Vector3(0, 0.03, -d * 0.25), Vector3(w - 0.16, 0.028, 0.025), trim))


# ── channel: services under the lid, the lit slit tracing the run ───────────
func _build_channel(trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var w: float = maxf(float(length_cells), 1.0)
	var d: float = 0.42
	# edge strips
	add_child(HangarKit.box(Vector3(0, 0.018, d * 0.5), Vector3(w, 0.036, 0.05), trim))
	add_child(HangarKit.box(Vector3(0, 0.018, -d * 0.5), Vector3(w, 0.036, 0.05), trim))
	# cover plates per cell with a breathing gap + the lit slit between plates
	for i in range(length_cells):
		var cx: float = -w * 0.5 + float(i) + 0.5
		add_child(HangarKit.box(Vector3(cx, 0.03, 0), Vector3(0.9, 0.028, d - 0.1), HangarKit.finish_body(finish, pcol, wear)))
		add_child(HangarKit.bolts(Vector3(cx - 0.38, 0.048, 0), Vector3(cx + 0.38, 0.048, 0), 2, 0.011, trim))
	add_child(HangarKit.box(Vector3(0, 0.012, 0), Vector3(w - 0.06, 0.012, 0.02), HangarKit.emissive(acol, 1.4)))


# ── hatch: the reachable below — bolted lid, hinges, stencil ────────────────
func _build_hatch(trim: StandardMaterial3D, pcol: Color, acol: Color) -> void:
	var s: float = 0.8
	add_child(HangarKit.box(Vector3(0, 0.014, 0), Vector3(s + 0.12, 0.028, s + 0.12), trim))
	add_child(HangarKit.box(Vector3(0, 0.034, 0), Vector3(s, 0.03, s), HangarKit.finish_body(finish, pcol, wear)))
	# hinge blocks + handle recess
	add_child(HangarKit.box(Vector3(-s * 0.5 + 0.06, 0.055, s * 0.28), Vector3(0.1, 0.03, 0.08), trim))
	add_child(HangarKit.box(Vector3(-s * 0.5 + 0.06, 0.055, -s * 0.28), Vector3(0.1, 0.03, 0.08), trim))
	add_child(HangarKit.box(Vector3(s * 0.32, 0.045, 0), Vector3(0.14, 0.012, 0.07), HangarKit.worn_metal(pcol.darkened(0.35))))
	# corner bolts + hazard corner tick + stencil
	for cz in [-1.0, 1.0]:
		add_child(HangarKit.bolts(Vector3(-s * 0.42, 0.052, cz * s * 0.42), Vector3(s * 0.42, 0.052, cz * s * 0.42), 3, 0.012, trim))
	add_child(HangarKit.box(Vector3(0, 0.052, s * 0.34), Vector3(s * 0.5, 0.008, 0.05), HangarKit.striped_mat()))
	var q := HangarKit.stencil(stencil_text if stencil_text.strip_edges() != "" else "SVC-04", Vector2(0.34, 0.07))
	if q:
		q.position = Vector3(0, 0.052, 0)
		q.rotation_degrees.x = -90
		add_child(q)


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
