# coincident_face.gd — THE EXACT BOUNDARY IS A COIN TOSS PER PIXEL.
#
# The boolean-surfaces seam. Constructive solid geometry promises exact cuts:
# subtract one solid from another and the boundary is a clean mathematical
# surface. But when the two surfaces are coincident — the cut plane lands exactly
# on a face — they claim the same depth, and the float grid cannot say which is
# in front. So the renderer flickers: pixel by pixel it awards the surface to
# whichever number rounded higher this frame. Amber solid, blue solid, and along
# the shared face a stripe of z-fighting where the exact answer dissolves into
# floating-point noise. The clean boolean was exact everywhere except the one
# place you asked it to be.
extends Node3D
class_name CoincidentFace

@export var color_a: Color = Color(1.0, 0.62, 0.18)
@export var color_b: Color = Color(0.3, 0.7, 1.0)


func _ready() -> void:
	_backing()
	# two overlapping solids sharing a coincident vertical face at x = 0
	var a_min := Vector2(-0.34, -0.20)
	var a_max := Vector2(0.02, 0.20)
	var b_min := Vector2(-0.02, -0.20)
	var b_max := Vector2(0.34, 0.20)
	_rect_outline(a_min, a_max, color_a, 0.006)
	_rect_fill(a_min, a_max, Color(color_a.r, color_a.g, color_a.b, 0.10))
	_rect_outline(b_min, b_max, color_b, 0.006)
	_rect_fill(b_min, b_max, Color(color_b.r, color_b.g, color_b.b, 0.10))
	# the coincident face: a vertical band of alternating amber/blue slivers —
	# the two surfaces fighting for one depth
	var band_x0: float = -0.02
	var band_x1: float = 0.02
	var slivers: int = 26
	var sw: float = (band_x1 - band_x0) / float(slivers)
	for i in range(slivers):
		var x: float = band_x0 + (float(i) + 0.5) * sw
		var col: Color = color_a if (i % 2 == 0) else color_b
		_bar(Vector2(x, a_min.y), Vector2(x, a_max.y), col, sw * 0.9)
	_tag("solid A", Vector2(-0.22, a_max.y + 0.05), color_a, 26)
	_tag("solid B", Vector2(0.22, b_max.y + 0.05), color_b, 26)
	_tag("z-fight: the shared face flickers", Vector2(0.0, a_min.y - 0.06), Color(0.95, 0.6, 0.4), 26)
	_plate("BOOLEAN",
		"CSG promises an exact cut — a clean surface\nwhere the cut plane lands on a coincident face,\ntwo surfaces claim one depth and the pixel is a coin toss",
		Vector3(0.0, a_max.y + 0.2, 0.0), color_b)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.66, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.02, -0.016)
	add_child(mi)


func _rect_outline(mn: Vector2, mx: Vector2, color: Color, thick: float) -> void:
	_seg(Vector2(mn.x, mn.y), Vector2(mx.x, mn.y), color, thick)
	_seg(Vector2(mx.x, mn.y), Vector2(mx.x, mx.y), color, thick)
	_seg(Vector2(mx.x, mx.y), Vector2(mn.x, mx.y), color, thick)
	_seg(Vector2(mn.x, mx.y), Vector2(mn.x, mn.y), color, thick)


func _rect_fill(mn: Vector2, mx: Vector2, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(absf(mx.x - mn.x), absf(mx.y - mn.y), 0.004)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 0.15
	mi.material_override = mat
	mi.position = Vector3((mn.x + mx.x) * 0.5, (mn.y + mx.y) * 0.5, -0.006)
	add_child(mi)


func _bar(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, absf(b.y - a.y), 0.007)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mi.material_override = mat
	mi.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.004)
	add_child(mi)


func _seg(a: Vector2, b: Vector2, color: Color, thick: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var d: float = a.distance_to(b)
	bm.size = Vector3(maxf(d, 0.001), thick, thick)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mi.material_override = mat
	mi.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.0)
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	add_child(mi)


func _tag(text: String, pos: Vector2, color: Color, fs: int) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = fs
	t.pixel_size = 0.00044
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector3(pos.x, pos.y, 0.02)
	add_child(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.86, 0.15, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.86, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.083, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 30
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
