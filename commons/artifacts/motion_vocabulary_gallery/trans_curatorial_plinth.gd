extends Node3D
## Architectural monochrome gallery monolith for Transformation floors (F14-F21).
## Configured via rooms.json config keys: heading, subtitle, body, footer.

var _mat_black: StandardMaterial3D
var _mat_slate: StandardMaterial3D
var _mat_white: StandardMaterial3D
var _mat_accent: StandardMaterial3D

func _ready() -> void:
	_mat_black = StandardMaterial3D.new()
	_mat_black.albedo_color = Color("14161b")
	_mat_black.roughness = 0.72
	_mat_black.metallic = 0.08

	_mat_slate = StandardMaterial3D.new()
	_mat_slate.albedo_color = Color("2a2d34")
	_mat_slate.roughness = 0.78

	_mat_white = StandardMaterial3D.new()
	_mat_white.albedo_color = Color("f2f2ee")
	_mat_white.roughness = 0.55

	_mat_accent = StandardMaterial3D.new()
	_mat_accent.albedo_color = Color("ffffff")
	_mat_accent.emission_enabled = true
	_mat_accent.emission = Color("f6f6f2")
	_mat_accent.emission_energy_multiplier = 0.55

	var heading := str(get_meta("config_heading", "TRANSFORMATION"))
	var subtitle := str(get_meta("config_subtitle", ""))
	var body_text := str(get_meta("config_body", ""))
	var footer := str(get_meta("config_footer", ""))
	var w := float(get_meta("config_width", 2.9))
	var h := float(get_meta("config_panel_height", 1.92))

	# Grounded steel feet + architectural matte slate-black frame
	_box("FootLeft", Vector3(-w * 0.38, 0.16, 0.0), Vector3(0.24, 0.32, 0.36), _mat_slate, true)
	_box("FootRight", Vector3(w * 0.38, 0.16, 0.0), Vector3(0.24, 0.32, 0.36), _mat_slate, true)
	var cy := 0.32 + h * 0.5
	_box("WallSlab", Vector3(0.0, cy, 0.0), Vector3(w, h, 0.12), _mat_black, true)
	_box("FrameTop", Vector3(0.0, cy + h * 0.5 + 0.02, 0.0), Vector3(w + 0.06, 0.04, 0.16), _mat_accent, false)
	_box("FrameBot", Vector3(0.0, cy - h * 0.5 - 0.02, 0.0), Vector3(w + 0.06, 0.04, 0.16), _mat_white, false)
	_box("FrameLeft", Vector3(-w * 0.5 - 0.02, cy, 0.0), Vector3(0.04, h + 0.08, 0.16), _mat_white, false)
	_box("FrameRight", Vector3(w * 0.5 + 0.02, cy, 0.0), Vector3(0.04, h + 0.08, 0.16), _mat_white, false)
	_box("RuleTop", Vector3(0.0, cy + h * 0.24, 0.068), Vector3(w - 0.34, 0.012, 0.01), _mat_white, false)
	_box("RuleBot", Vector3(0.0, cy - h * 0.30, 0.068), Vector3(w - 0.34, 0.012, 0.01), _mat_white, false)

	_label(heading, Vector3(0.0, cy + h * 0.39, 0.075), 36, 0.0031, Color("ffffff"), 0.0)
	if not subtitle.is_empty():
		_label(subtitle, Vector3(0.0, cy + h * 0.295, 0.075), 22, 0.0027, Color("d8dce2"), 0.0)
	if not body_text.is_empty():
		_label(body_text, Vector3(0.0, cy - h * 0.03, 0.075), 26, 0.0028, Color("f0f0ec"), (w - 0.38) / 0.0028)
	if not footer.is_empty():
		_label(footer, Vector3(0.0, cy - h * 0.40, 0.075), 21, 0.0026, Color("ffffff"), (w - 0.32) / 0.0026)

func _box(node_name: String, at: Vector3, size: Vector3, mat: Material, solid: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	if solid:
		var sb := StaticBody3D.new()
		sb.name = node_name + "_Body"
		sb.position = at
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
		add_child(sb)
	return mi

func _label(text: String, at: Vector3, font_sz: int, px_sz: float, col: Color, width_px: float) -> void:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = font_sz
	lb.pixel_size = px_sz
	lb.modulate = col
	lb.outline_size = 5
	lb.outline_modulate = Color("0c0d10")
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if width_px > 0.0:
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.width = width_px
	lb.position = at
	add_child(lb)
