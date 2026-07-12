# model_seam.gd — CONFIDENT AND WRONG OFF THE DATA. ADA READING HERSELF.
#
# The machine-learning seam, and the one that points the apparatus at itself.
# A network is a lossy compressor of its training data: it interpolates
# smoothly where it has seen examples and extrapolates a straight line where it
# has not — because a ReLU network IS piecewise-linear, its "curved
# understanding" is a staircase of line segments. On the data (white) the blue
# model hugs the true amber function. Off the data, at the edges, the model
# shoots off straight and confident while the truth curves away. This is the
# compressed human record close-reading its own compression: the model does not
# know where its knowledge ends; it only knows how to keep drawing the last line.
extends Node3D
class_name ModelSeam

@export var amp: float = 0.13
@export var freq: float = 6.2
@export var data_reach: float = 0.19
@export var span: float = 0.45
@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_model: Color = Color(0.3, 0.7, 1.0)
@export var color_data: Color = Color(0.95, 0.96, 1.0)


func _ready() -> void:
	_backing()
	# the true function (amber, dense)
	var steps: int = 180
	var prev: Vector3 = _tp(-span)
	for i in range(1, steps + 1):
		var x: float = -span + 2.0 * span * float(i) / float(steps)
		var p: Vector3 = _tp(x)
		_seg(prev, p, color_true, 0.004)
		prev = p
	# the model — piecewise linear: knots on the curve inside the data region,
	# then a straight extrapolation beyond it (the confabulation)
	var knots: Array[Vector3] = []
	var inner: int = 6
	for i in range(inner + 1):
		var x: float = -data_reach + 2.0 * data_reach * float(i) / float(inner)
		knots.append(_tp(x))
	# left extrapolation: continue the slope of the first inner segment
	var kL0: Vector3 = knots[0]
	var kL1: Vector3 = knots[1]
	var slopeL: float = (kL1.y - kL0.y) / (kL1.x - kL0.x)
	var xL: float = -span
	knots.insert(0, Vector3(xL, kL0.y + slopeL * (xL - kL0.x), 0.0))
	# right extrapolation
	var kR0: Vector3 = knots[knots.size() - 1]
	var kR1: Vector3 = knots[knots.size() - 2]
	var slopeR: float = (kR0.y - kR1.y) / (kR0.x - kR1.x)
	var xR: float = span
	knots.append(Vector3(xR, kR0.y + slopeR * (xR - kR0.x), 0.0))
	for i in range(knots.size() - 1):
		_seg(knots[i], knots[i + 1], color_model, 0.008)
	# the training data (white dots, only in the data region)
	for i in range(11):
		var x: float = -data_reach + 2.0 * data_reach * float(i) / 10.0
		var jitter: float = 0.012 * sin(float(i) * 12.9)
		_dot(Vector3(x, amp * sin(freq * x) + jitter, 0.0), color_data, 0.009)
	# region markers
	_tag("← where it has seen examples →", Vector3(0.0, -0.19, 0.0), color_data)
	_tag("confabulating", Vector3(-0.35, 0.17, 0.0), color_model)
	_tag("confabulating", Vector3(0.35, 0.17, 0.0), color_model)
	_plate("THE MODEL",
		"a network is a lossy compressor of its data\non the data it fits · off the data it invents,\nconfident and wrong — Ada reading herself",
		Vector3(0.0, 0.31, 0.0), color_model)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])


func _tp(x: float) -> Vector3:
	return Vector3(x, amp * sin(freq * x), 0.0)


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.44, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.0, -0.014)
	add_child(mi)


func _seg(a: Vector3, b: Vector3, color: Color, thick: float) -> void:
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
	mi.position = (a + b) * 0.5
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	add_child(mi)


func _dot(p: Vector3, color: Color, r: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4
	mi.material_override = mat
	mi.position = p + Vector3(0.0, 0.0, 0.012)
	add_child(mi)


func _tag(text: String, pos: Vector3, color: Color) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = 28
	t.pixel_size = 0.00042
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos
	add_child(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.82, 0.13, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.82, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.072, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 32
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
