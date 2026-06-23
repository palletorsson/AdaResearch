extends Node3D
class_name StationPanel

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the GRID-MODULAR wall-mounted info panel of a curation station — a width_cells × 1 m (per cell) thin framed screen showing crisp 2D-in-3D text (a title + lines) on a dark face, that mounts flat on a [[station_wall]] section to caption the bay. Origin at the back, screen faces +Z.
# desire: to put words on the wall — to tell a viewer what the set IS, in readable 2D pinned to a surface, the way the reference lab screens read "SPECIMEN  ONLINE" above the benches.
# critical_parameter: header + lines — the content; width_cells sizes the frame to land on the grid beside the wall mullions.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds with new text.
# emerges: a title + short lines reads "label, status"; an amber header reads "live system"; a wide panel reads "the bay's headline". All text is 2D-in-3D (BakedTextAlbedo), never a billboard.
# needs: a thin frame [present]; a dark emissive face [present]; a 2D-in-3D header + text block [present]; optional accent bar [optional].
# relationships: the captioning sibling of [[station_wall]] (mounts on it) and the readable face of the whole station; placed on the backing wall by [[curation_station]]; uses the same BakedTextAlbedo plates as the plinth captions.
# truth: a place that presents must also explain. The panel is the station admitting it has something to say, and saying it in plain pinned words.

@export_group("Grid")
@export var width_cells: int = 2
@export_group("Dimensions")
@export var height: float = 0.6
@export_group("Content")
@export var header: String = "CURATION"
@export var lines: Array = ["ON SHOW", "LINK  OK"]
## Header colour (amber by default — a live-system read).
@export var header_color: Color = Color(0.86, 0.46, 0.16)
@export var text_color: Color = Color(0.90, 0.92, 0.95)
@export_group("Surface")
@export var accent_bar: bool = true
@export_group("Color")
@export var frame_color: Color = Color(0.74, 0.72, 0.68)
@export var screen_color: Color = Color(0.09, 0.10, 0.12)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)
@export var wear: float = 0.06

const CELL := 1.0
const FRAME_T := 0.05
const DEPTH := 0.08

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
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_header"): header = str(get_meta("config_header"))
	if has_meta("config_lines"):
		var raw = get_meta("config_lines")
		if raw is Array:
			lines = []
			for ln in raw:
				lines.append(str(ln))
	if has_meta("config_accent_bar"): accent_bar = _b(get_meta("config_accent_bar"))
	if has_meta("config_frame_color"): frame_color = _pc(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_screen_color"): screen_color = _pc(str(get_meta("config_screen_color")), screen_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)

func _build() -> void:
	_built = true
	var w: float = float(maxi(width_cells, 1)) * CELL - 0.1
	var h: float = maxf(height, 0.25)

	# Frame (light matte) + recessed dark emissive screen face.
	add_child(_box(Vector3(0, 0, 0), Vector3(w, h, DEPTH), HangarKit.rams_body(frame_color, wear)))
	var face := _emi(screen_color, 0.35)
	add_child(_box(Vector3(0, 0, DEPTH * 0.5), Vector3(w - FRAME_T * 2.0, h - FRAME_T * 2.0, 0.02), face))

	# 2D-in-3D header.
	var hz: float = DEPTH * 0.5 + 0.02
	var head: MeshInstance3D = BakedText.make_label_mesh(header.to_upper(), header_color, Vector2(minf(w * 0.8, 1.2), h * 0.22), 1400, true)
	if head:
		head.position = Vector3(-w * 0.5 + FRAME_T + minf(w * 0.4, 0.6), h * 0.5 - FRAME_T - h * 0.14, hz)
		add_child(head)
	# 2D-in-3D body lines.
	var ly: float = h * 0.5 - FRAME_T - h * 0.36
	var line_h: float = h * 0.18
	for ln in lines:
		var s := str(ln)
		if s.strip_edges() == "":
			ly -= line_h
			continue
		var q: MeshInstance3D = BakedText.make_label_mesh(s.to_upper(), text_color, Vector2(minf(w * 0.78, 1.4), line_h * 0.8), 1400, true)
		if q:
			q.position = Vector3(-w * 0.5 + FRAME_T + minf(w * 0.4, 0.7), ly, hz)
			add_child(q)
		ly -= line_h

	if accent_bar:
		add_child(_box(Vector3(0, h * 0.5 - FRAME_T * 0.5, hz), Vector3(w - FRAME_T * 2.0, 0.02, 0.015), _emi(accent_color, 0.7)))

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
