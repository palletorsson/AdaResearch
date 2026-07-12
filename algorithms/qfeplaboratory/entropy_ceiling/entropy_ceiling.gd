# entropy_ceiling.gd — A NUMBER STANDING IN FOR INFINITY.
#
# The QFEP-laboratory seam, and the thesis at its most self-aware. This whole
# lab measures order and disorder — entropy, information, the tilt of a system
# toward chaos. But the meters are quantized: a finite ladder of ticks, a needle
# that moves in steps. True maximum entropy is a limit, an ideal of perfect
# structurelessness the instrument can never reach. Push a system toward it and
# the needle climbs to the last tick and PINS — reading MAX, a finite number
# standing in for an infinity it cannot hold. Amber: the true value, off the top
# of the scale. Blue: what the meter can say. The lab that studies the limit is
# built out of the limit; the ruler cannot measure its own end.
extends Node3D
class_name EntropyCeiling

@export var ticks: int = 10
@export var color_meter: Color = Color(0.3, 0.7, 1.0)
@export var color_true: Color = Color(1.0, 0.62, 0.18)


func _ready() -> void:
	_backing()
	var gx: float = -0.06
	var y0: float = -0.24
	var y1: float = 0.20
	var h: float = y1 - y0
	# meter frame
	_seg(Vector2(gx - 0.05, y0), Vector2(gx + 0.05, y0), Color(0.5, 0.55, 0.6), 0.004)
	_seg(Vector2(gx - 0.05, y1), Vector2(gx + 0.05, y1), Color(0.5, 0.55, 0.6), 0.004)
	_seg(Vector2(gx - 0.05, y0), Vector2(gx - 0.05, y1), Color(0.5, 0.55, 0.6), 0.003)
	_seg(Vector2(gx + 0.05, y0), Vector2(gx + 0.05, y1), Color(0.5, 0.55, 0.6), 0.003)
	# quantized ticks
	for i in range(ticks + 1):
		var ty: float = y0 + h * float(i) / float(ticks)
		_seg(Vector2(gx - 0.05, ty), Vector2(gx - 0.028, ty), Color(0.45, 0.5, 0.56), 0.003)
	# blue fill pinned to the top tick (saturated)
	for i in range(ticks):
		var fy: float = y0 + h * (float(i) + 0.5) / float(ticks)
		_seg(Vector2(gx - 0.04, fy), Vector2(gx + 0.04, fy), color_meter, h / float(ticks) * 0.72)
	# needle pinned at MAX
	_seg(Vector2(gx - 0.06, y1), Vector2(gx + 0.06, y1), color_meter, 0.007)
	_dot(Vector2(gx + 0.06, y1), color_meter, 0.012)
	_tag("MAX", Vector2(gx + 0.14, y1), color_meter, 28)
	_tag("the meter reads", Vector2(gx, y0 - 0.05), color_meter, 22)
	_tag("in quantized ticks", Vector2(gx, y0 - 0.085), color_meter, 22)
	# amber true value — off the top of the scale
	_seg(Vector2(gx, y1 + 0.02), Vector2(gx, y1 + 0.14), color_true, 0.005)
	_seg(Vector2(gx, y1 + 0.14), Vector2(gx - 0.02, y1 + 0.11), color_true, 0.004)
	_seg(Vector2(gx, y1 + 0.14), Vector2(gx + 0.02, y1 + 0.11), color_true, 0.004)
	_tag("true max entropy ↑", Vector2(gx + 0.02, y1 + 0.11), color_true, 24)
	_plate("QFEP LAB",
		"the lab measures order with quantized meters\ntrue maximum entropy is a limit the needle cannot reach\npast the last tick it pins — MAX, a number standing in for infinity",
		Vector3(0.0, 0.36, 0.0), color_meter)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_ticks"):
		ticks = int(str(get_meta("config_ticks")))


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.74, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.04, -0.014)
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
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 0.5
	mi.material_override = mat
	mi.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.0)
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	add_child(mi)


func _dot(p: Vector2, color: Color, r: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mi.material_override = mat
	mi.position = Vector3(p.x, p.y, 0.008)
	add_child(mi)


func _tag(text: String, pos: Vector2, color: Color, fs: int) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = fs
	t.pixel_size = 0.00044
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector3(pos.x, pos.y, 0.01)
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
