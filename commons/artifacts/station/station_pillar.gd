extends Node3D
class_name StationPillar

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR corner column of a curation station — a square painted-metal pillar that claims one 1 m cell and rises to height, banded with a lit accent groove and a base/capital. Origin at the floor centre. The vertical that turns a flat backing into a built bay corner.
# desire: to mark where the room turns — to give a wall run a corner to die into and an artifact set an upright frame, so the stage reads as architecture, not furniture in a void.
# critical_parameter: height + post_width — how tall and how heavy the corner reads; the composer matches it to the backing wall height.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: a plain shaft reads "structure"; a lit groove reads "powered"; a capital + base reads "finished, intentional"; a readout face reads "this corner reports".
# needs: a base plate [present]; a shaft [present]; a capital [present]; a lit accent groove [present]; optional readout face [optional].
# relationships: the upright that ends a [[station_wall]] run and frames the [[station_stage]]; placed at the back corners by [[curation_station]]; shares the HangarKit family look.
# truth: a column is the oldest claim that a place is built. One upright, repeated, makes a room out of an open floor.

@export_group("Dimensions")
## Pillar height (Y).
@export var height: float = 2.5
## Shaft width (X/Z) — fits inside a 1 m cell.
@export var post_width: float = 0.42

@export_group("Style")
## Vertical lit accent groove down each face.
@export var lit_groove: bool = true
## A small framed readout on the +Z face.
@export var readout_face: bool = false

@export_group("Surface")
@export var stencil_text: String = ""
@export var wear: float = 0.08
@export var grime: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const BASE_H := 0.12
const CAP_H := 0.12

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
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_post_width"): post_width = float(str(get_meta("config_post_width")))
	if has_meta("config_lit_groove"): lit_groove = _b(get_meta("config_lit_groove"))
	if has_meta("config_readout_face"): readout_face = _b(get_meta("config_readout_face"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var h: float = maxf(height, 0.6)
	var pw: float = clampf(post_width, 0.2, 0.95)
	var body_mat := _mat(body_color)
	var trim_mat := _mat(panel_color.darkened(0.04))

	# Base plate.
	add_child(_box(Vector3(0, BASE_H * 0.5, 0), Vector3(pw + 0.14, BASE_H, pw + 0.14), trim_mat))
	# Shaft.
	var shaft_bottom: float = BASE_H
	var shaft_top: float = h - CAP_H
	var shaft_h: float = maxf(shaft_top - shaft_bottom, 0.2)
	add_child(_box(Vector3(0, shaft_bottom + shaft_h * 0.5, 0), Vector3(pw, shaft_h, pw), body_mat))
	# Capital.
	add_child(_box(Vector3(0, h - CAP_H * 0.5, 0), Vector3(pw + 0.12, CAP_H, pw + 0.12), trim_mat))

	# Recessed face panels on the four sides.
	var pmat := _mat(panel_color)
	var t := 0.02
	for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var center: Vector3 = nrm * (pw * 0.5 + t * 0.5) + Vector3(0, shaft_bottom + shaft_h * 0.5, 0)
		var size: Vector3 = Vector3(t, shaft_h * 0.82, pw * 0.6) if absf(nrm.x) > 0.5 else Vector3(pw * 0.6, shaft_h * 0.82, t)
		add_child(_box(center, size, pmat))

	if lit_groove:
		var lit := _emi(accent_color, 0.7)
		for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var center: Vector3 = nrm * (pw * 0.5 + 0.012) + Vector3(0, shaft_bottom + shaft_h * 0.5, 0)
			var size: Vector3 = Vector3(0.02, shaft_h * 0.7, 0.03) if absf(nrm.x) > 0.5 else Vector3(0.03, shaft_h * 0.7, 0.02)
			add_child(_box(center, size, lit))
	if readout_face:
		var screen: Node3D = HangarKit.readout("NODE", ["ONLINE", "PWR OK"], Vector2(pw * 0.7, pw * 0.5))
		if screen:
			screen.position = Vector3(0, h * 0.6, pw * 0.5 + 0.03)
			add_child(screen)
	if grime:
		add_child(HangarKit.grime_band(pw + 0.14, 0.05, (pw + 0.14) * 0.5 + 0.004, body_color))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(pw * 0.7, 0.12))
		if q:
			q.position = Vector3(0, h * 0.2, pw * 0.5 + 0.02)
			add_child(q)


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
