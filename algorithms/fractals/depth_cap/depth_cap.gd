# depth_cap.gd — INFINITY, FAKED TO A BUDGET.
#
# The fractals seam (the depth-cap crack). A Koch curve is infinitely deep —
# every segment holds a smaller copy, forever. The machine renders to iteration
# N and stops. Above: the curve at depth N, endlessly crinkled to the eye.
# Below: magnify one of its smallest segments — and the endless detail is gone.
# It is a straight line. Flat. The self-similarity that was supposed to go all
# the way down has a floor, and the floor is wherever the budget ran out.
extends Node3D
class_name DepthCap

@export var depth: int = 4
@export var width: float = 0.95
@export var color_curve: Color = Color(1.0, 0.62, 0.18)
@export var color_floor: Color = Color(0.3, 0.7, 1.0)


func _ready() -> void:
	var base: Array = [Vector2(-width * 0.5, 0.12), Vector2(width * 0.5, 0.12)]
	var pts: Array = _koch(base, depth)
	for i in range(pts.size() - 1):
		_seg(pts[i], pts[i + 1], color_curve, 0.004)
	_plate("THE CURVE", "a Koch curve at iteration %d — crinkled to the eye" % depth,
		Vector3(0.0, 0.30, 0.0), color_curve)
	# magnify the smallest segment: it is straight — the floor
	var a: Vector2 = pts[0]
	var b: Vector2 = pts[1]
	var mag: float = width / a.distance_to(b) * 0.9
	var m0: Vector2 = Vector2(-width * 0.45, -0.16)
	var m1: Vector2 = m0 + (b - a) * mag
	_seg(m0, m1, color_floor, 0.012)
	_dot(m0, Color(0.95, 0.96, 1.0), 0.011)
	_dot(m1, Color(0.95, 0.96, 1.0), 0.011)
	_plate("THE FLOOR", "magnify one smallest segment: it is a straight line\nbelow iteration %d the endless detail is simply gone" % depth,
		Vector3(0.0, -0.34, 0.0), color_floor)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_depth"):
		depth = int(str(get_meta("config_depth")))


func _koch(points: Array, d: int) -> Array:
	var pts: Array = points
	for _iter in range(d):
		var np: Array = []
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var seg: Vector2 = (b - a) / 3.0
			var p1: Vector2 = a + seg
			var p3: Vector2 = a + seg * 2.0
			var ang: float = -PI / 3.0
			var peak: Vector2 = p1 + Vector2(
				seg.x * cos(ang) - seg.y * sin(ang),
				seg.x * sin(ang) + seg.y * cos(ang))
			np.append(a)
			np.append(p1)
			np.append(peak)
			np.append(p3)
		np.append(pts[pts.size() - 1])
		pts = np
	return pts


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
	mi.position = Vector3(p.x, p.y, 0.012)
	add_child(mi)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.78, 0.11, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.78, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.06, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 32
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
