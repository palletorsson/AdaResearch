extends Node3D
class_name StationStage

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR raised deck a curated set stands ON — a low painted-metal platform exactly width_cells × depth_cells metres (1 m per cell), with a panelled bolted skirt, a chamfered cap with a lit toe-groove, a caution-striped front lip, and an optional framed name-plate. Origin at the floor centre; the walkable cap sits at step_height.
# desire: to lift a set a hand's-height off the floor so it reads as staged, presented, on display — not scattered on the ground; and to do it on whole cells so plinths land on grid centres.
# critical_parameter: width_cells × depth_cells — the footprint of the stage, which the composer sizes to hold N plinths plus margin, always whole cells.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new footprint.
# emerges: a low solid deck reads "stand here"; the striped front lip reads "the front, mind the step"; a grate top reads "serviced floor"; the bolted skirt panels read "built, modular"; the framed plate reads "this set has a name".
# needs: a deck cap at step_height [present]; a skirt body below it [present]; a bolted panel skirt [present]; a hazard front lip + corner foot plates [present]; optional chamfer/bevel, lit toe-groove, three-colour bar, grate top, framed name-plate [optional].
# relationships: the floor sibling of [[station_wall]] (stand ON this, back AGAINST that); holds [[station_plinth]] columns; assembled by [[curation_station]]. Shares the HangarKit look with [[hangar_step_base]] but tiles on the grid.
# truth: to stage a thing is to raise it a little and admit you are presenting it. The step is the smallest honest pedestal — height enough to mean "look", low enough to step onto.

@export_group("Grid")
## Stage width in 1 m cells (X).
@export var width_cells: int = 5
## Stage depth in 1 m cells (Z).
@export var depth_cells: int = 3

@export_group("Dimensions")
## Step rise — the deck height above the floor (clamped ≤ 0.35 m, a single comfortable step).
@export var step_height: float = 0.22
## Chamfer on the cap's top edge — a tasteful bevel so the deck reads machined, not slab-cut (0 = square).
@export var cap_chamfer: float = 0.025

@export_group("Style")
## "solid" | "grate" walkable cap.
@export var top_style: String = "solid"
## Caution stripe along the front (+Z) lip.
@export var hazard_edge: bool = true
## A slim emissive accent line under the front lip (the lit toe-groove).
@export var edge_light: bool = false
## A clean Dieter-Rams three-colour accent bar on the front skirt.
@export var three_bar: bool = false
## Rows of bolt cylinders down the panel seams — the bolted-built read.
@export var bolts: bool = true

@export_group("Surface")
## The visual finish family: "rams" (light Braun default) | "terminal" (dark console).
@export var finish: String = "rams"
@export var stencil_text: String = "STAGE-01"
## Optional words harvested into a framed surface-pinned name-plate on the front lip ("" = none).
@export var name_plate: String = ""
@export var wear: float = 0.08
@export var grime: bool = true
## Faint vertical dust streaks down the front skirt (restrained dirt).
@export var dust: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const TOP_THICK := 0.05
const SKIRT_INSET := 0.07

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
	if has_meta("config_width_cells"): width_cells = int(str(get_meta("config_width_cells")))
	if has_meta("config_depth_cells"): depth_cells = int(str(get_meta("config_depth_cells")))
	if has_meta("config_step_height"): step_height = float(str(get_meta("config_step_height")))
	if has_meta("config_cap_chamfer"): cap_chamfer = float(str(get_meta("config_cap_chamfer")))
	if has_meta("config_top_style"): top_style = str(get_meta("config_top_style")).to_lower()
	if has_meta("config_hazard_edge"): hazard_edge = _b(get_meta("config_hazard_edge"))
	if has_meta("config_edge_light"): edge_light = _b(get_meta("config_edge_light"))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_bolts"): bolts = _b(get_meta("config_bolts"))
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_name_plate"): name_plate = str(get_meta("config_name_plate"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_dust"): dust = _b(get_meta("config_dust"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var pal := HangarKit.finish_palette(finish)
	# In "terminal" finish the props read as the dark console family: honour the DNA colours
	# only if the author moved them off the rams default, else take the family palette.
	var is_terminal := finish == "terminal"
	var bcol: Color = body_color
	var pcol: Color = panel_color
	var acol: Color = accent_color
	if is_terminal and _is_default_rams():
		bcol = pal["body"]; pcol = pal["panel"]; acol = pal["accent"]
	var wr: float = wear if not is_terminal else maxf(wear, 0.28)

	var w: float = float(maxi(width_cells, 1)) * CELL
	var d: float = float(maxi(depth_cells, 1)) * CELL
	var sh: float = clampf(step_height, 0.08, 0.35)
	var cham: float = clampf(cap_chamfer, 0.0, minf(0.06, sh * 0.4))
	var body_mat := _body(bcol, wr)
	var cap_mat := _body(bcol.lightened(0.05), wr)

	# Skirt body — the bulk below the deck, slightly inset so the cap overhangs.
	add_child(_box(Vector3(0, (sh - TOP_THICK) * 0.5, 0),
		Vector3(w - SKIRT_INSET * 2.0, sh - TOP_THICK, d - SKIRT_INSET * 2.0), body_mat))

	# Walkable cap — overhangs the skirt; top sits exactly at step_height.
	if top_style == "grate":
		_build_grate(w, d, sh, bcol, pcol, wr)
	else:
		add_child(_box(Vector3(0, sh - TOP_THICK * 0.5, 0), Vector3(w, TOP_THICK, d), cap_mat))
		# Chamfered top edge — a thin lighter bevel frame so the deck reads machined.
		if cham > 0.0:
			_build_cap_chamfer(w, d, sh, cham, _body(bcol.lightened(0.12), wr))

	# Skirt panels (with seams + bolts) on the four faces — the modular built read.
	_build_skirt_panels(w, d, sh, pcol, wr)

	# Corner foot plates with a bolt at each.
	var fmat := HangarKit.worn_metal(pcol)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var fp := Vector3(sx * (w * 0.5 - 0.18), 0.015, sz * (d * 0.5 - 0.18))
			add_child(_box(fp, Vector3(0.3, 0.03, 0.3), fmat))
			add_child(_box(fp + Vector3(0, 0.025, 0), Vector3(0.05, 0.02, 0.05), HangarKit.worn_metal(pcol.darkened(0.2))))

	# Caution-striped front lip.
	if hazard_edge:
		add_child(_box(Vector3(0, sh * 0.5, d * 0.5 + 0.005), Vector3(w * 0.96, sh * 0.7, 0.02), HangarKit.striped_mat()))
	# Lit toe-groove just under the cap lip.
	if edge_light:
		add_child(_box(Vector3(0, sh - TOP_THICK - 0.02, d * 0.5 + 0.012), Vector3(w * 0.9, 0.025, 0.018), _emi(acol, 0.7)))
		# recessed dark channel behind the lit line so the groove reads cut-in.
		add_child(_box(Vector3(0, sh - TOP_THICK - 0.02, d * 0.5 - 0.004), Vector3(w * 0.92, 0.05, 0.02), _body(bcol.darkened(0.4), wr)))
	# Rams three-colour accent bar on the front skirt (left of the stencil).
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(minf(w * 0.34, 0.9), 0.045, [acol, HangarKit.DISPLAY_DARK, pcol])
		bar.position = Vector3(w * 0.5 - minf(w * 0.22, 0.6), sh * 0.62, d * 0.5 - SKIRT_INSET + 0.022)
		add_child(bar)

	if grime:
		add_child(HangarKit.grime_band(w, 0.05, d * 0.5 - SKIRT_INSET + 0.004, bcol))
	if dust:
		add_child(HangarKit.dust_streaks(w * 0.92, sh - TOP_THICK, d * 0.5 - SKIRT_INSET + 0.006, maxi(3, mini(width_cells + 1, 7))))

	# Stencil ID painted on the front skirt (surface-pinned, no float).
	if stencil_text.strip_edges() != "":
		var stencil_col: Color = pal.get("text", Color(0.86, 0.87, 0.90))
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.22, 0.5), sh * 0.5), stencil_col)
		if q:
			q.position = Vector3(-w * 0.5 + 0.45, sh * 0.45, d * 0.5 + 0.02)
			add_child(q)

	# Optional framed, surface-pinned name-plate — the set's words harvested onto the lip.
	if name_plate.strip_edges() != "":
		_build_name_plate(w, sh, d, pal)


func _build_cap_chamfer(w: float, d: float, sh: float, cham: float, mat: Material) -> void:
	# A thin proud frame ringing the cap top edge, reading as a machined bevel.
	var ty: float = sh - cham * 0.5
	add_child(_box(Vector3(0, ty, d * 0.5 - cham * 0.5), Vector3(w, cham, cham), mat))
	add_child(_box(Vector3(0, ty, -d * 0.5 + cham * 0.5), Vector3(w, cham, cham), mat))
	add_child(_box(Vector3(w * 0.5 - cham * 0.5, ty, 0), Vector3(cham, cham, d), mat))
	add_child(_box(Vector3(-w * 0.5 + cham * 0.5, ty, 0), Vector3(cham, cham, d), mat))


func _build_skirt_panels(w: float, d: float, sh: float, pcol: Color, wr: float) -> void:
	var pmat := _body(pcol, wr)
	var seam_mat := _body(pcol.darkened(0.45), wr)
	var bolt_mat := HangarKit.worn_metal(pcol.darkened(0.25))
	var ph: float = (sh - TOP_THICK) * 0.7
	var t := 0.02
	var cy: float = (sh - TOP_THICK) * 0.5
	var wc: int = maxi(width_cells, 1)
	# front/back run a panel per cell with a recessed seam + a vertical bolt pair between cells.
	for sz in [1.0, -1.0]:
		var face_z: float = sz * (d * 0.5 - SKIRT_INSET)
		for i in range(wc):
			var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
			add_child(_box(Vector3(cx, cy, face_z + sz * t * 0.5), Vector3(CELL * 0.82, ph, t), pmat))
			# recessed seam line at the cell boundary (skip the last)
			if i < wc - 1:
				var seam_x: float = -w * 0.5 + (float(i) + 1.0) * CELL
				add_child(_box(Vector3(seam_x, cy, face_z + sz * t * 0.3), Vector3(0.018, ph * 1.02, t * 0.6), seam_mat))
				if bolts:
					add_child(HangarKit.bolts(
						Vector3(seam_x, cy + ph * 0.34, face_z + sz * (t + 0.006)),
						Vector3(seam_x, cy - ph * 0.34, face_z + sz * (t + 0.006)),
						3, 0.011, bolt_mat))
	# sides one panel each.
	for sx in [1.0, -1.0]:
		add_child(_box(Vector3(sx * (w * 0.5 - SKIRT_INSET) + sx * t * 0.5, cy, 0), Vector3(t, ph, d * 0.8), pmat))


func _build_grate(w: float, d: float, sh: float, bcol: Color, pcol: Color, wr: float) -> void:
	var fmat := HangarKit.worn_metal(pcol.darkened(0.1))
	# perimeter frame
	add_child(_box(Vector3(0, sh - TOP_THICK * 0.5, 0), Vector3(w, TOP_THICK, d), _body(bcol.darkened(0.1), wr)))
	var slats := maxi(int(d / 0.18), 4)
	for i in range(slats):
		var z: float = lerpf(-d * 0.46, d * 0.46, float(i) / float(slats - 1))
		add_child(_box(Vector3(0, sh - TOP_THICK + 0.01, z), Vector3(w * 0.94, 0.02, 0.05), fmat))


func _build_name_plate(w: float, sh: float, d: float, pal: Dictionary) -> void:
	# A framed, surface-pinned readout reading the set's name — flat on the front lip.
	var pw: float = clampf(w * 0.4, 0.42, 1.1)
	var ph: float = clampf(sh * 0.78, 0.12, 0.2)
	var plate: Node3D = HangarKit.readout(name_plate, [], Vector2(pw, ph),
		pal.get("screen", HangarKit.DISPLAY_DARK), pal.get("text", HangarKit.TEXT_DISPLAY),
		pal.get("header", HangarKit.BRAUN_ACCENT))
	plate.position = Vector3(w * 0.5 - pw * 0.5 - 0.22, sh * 0.5, d * 0.5 + 0.03)
	add_child(plate)


func _is_default_rams() -> bool:
	return body_color.is_equal_approx(Color(0.81, 0.79, 0.75)) \
		and panel_color.is_equal_approx(Color(0.70, 0.68, 0.64)) \
		and accent_color.is_equal_approx(Color(0.86, 0.34, 0.11))


func _body(c: Color, wr: float) -> StandardMaterial3D:
	return HangarKit.finish_body(finish, c, wr)


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
