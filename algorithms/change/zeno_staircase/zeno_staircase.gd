# zeno_staircase.gd — THE RATE IS A SECANT OVER ONE FROZEN FRAME.
#
# The change (calculus) seam. Motion is continuous; the machine reads it at
# frame ticks and holds the value between them — Zeno's arrow, frozen then
# jumped. The amber curve is the true continuous change; the blue staircase is
# what the machine actually has: a held value at each tick and a jump to the
# next. The "instantaneous" rate it reports is not the tangent — it is a secant,
# rise over run across one frozen frame, a slope the true curve only touches for
# an instant the machine never samples. Shrink the frame and the staircase gets
# finer; it never becomes the curve.
extends Node3D
class_name ZenoStaircase

@export var samples: int = 9
@export var span: float = 0.44
@export var amp: float = 0.13
@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_step: Color = Color(0.3, 0.7, 1.0)
@export var color_secant: Color = Color(0.95, 0.5, 0.5)


func _ready() -> void:
	_backing()
	# the true continuous curve (amber, dense)
	var steps: int = 180
	var prev: Vector3 = _tp(-span)
	for i in range(1, steps + 1):
		var x: float = -span + 2.0 * span * float(i) / float(steps)
		var p: Vector3 = _tp(x)
		_seg(prev, p, color_true, 0.004)
		prev = p
	# the staircase (zero-order hold): flat, then jump, at each frame tick
	var xs: Array[float] = []
	for i in range(samples + 1):
		xs.append(-span + 2.0 * span * float(i) / float(samples))
	for i in range(samples):
		var y0: float = _tp(xs[i]).y
		var y1: float = _tp(xs[i + 1]).y
		_seg(Vector3(xs[i], y0, 0.0), Vector3(xs[i + 1], y0, 0.0), color_step, 0.008)  # hold
		_seg(Vector3(xs[i + 1], y0, 0.0), Vector3(xs[i + 1], y1, 0.0), color_step, 0.008)  # jump
		_dot(Vector3(xs[i], y0, 0.0), Color(0.95, 0.96, 1.0), 0.008)
	# the secant the machine calls the "tangent" — rise over run, one frame,
	# drawn extended so its wrong slope is obvious against the true curve
	var mi: int = int(samples / 2)
	var a: Vector3 = _tp(xs[mi])
	var b: Vector3 = _tp(xs[mi + 1])
	var sl: float = (b.y - a.y) / (b.x - a.x)
	var ext: float = 0.14
	_seg(Vector3(a.x - ext, a.y - sl * ext, 0.0), Vector3(b.x + ext, b.y + sl * ext, 0.0),
		color_secant, 0.005)
	_tag("the 'tangent' = a secant over one frame", Vector3(0.0, -0.2, 0.0), color_secant)
	_plate("THE FRAME",
		"motion is continuous · the machine reads at ticks\nand holds between (frozen, then jump — Zeno)\nthe rate it reports is a secant, not the tangent",
		Vector3(0.0, 0.31, 0.0), color_step)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_samples"):
		samples = int(str(get_meta("config_samples")))


func _tp(x: float) -> Vector3:
	var u: float = (x + span) / (2.0 * span)   # 0..1
	var y: float = amp * (pow(u, 1.7) * 2.0 - 1.0)
	return Vector3(x, y, 0.0)


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
