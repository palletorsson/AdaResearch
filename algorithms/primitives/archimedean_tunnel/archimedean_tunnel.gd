# archimedean_tunnel.gd — A DIGITAL LINE IS A POLYGON PRETENDING TO BE A CURVE.
#
# The primitives seam (the sampling crack). Your hand moves continuously; the
# machine records a finite set of points and connects them with straight
# chords. At arm's length the chords read as a smooth curve. Walk into the
# tunnel — magnify — and the truth resolves: a polyline cutting every corner,
# with holes between the samples where the hand was and the machine never
# looked. Archimedes exhausted the circle with polygons of more and more sides;
# the machine stops the exhaustion at N and calls the polygon a line.
extends Node3D
class_name ArchimedeanTunnel

@export var samples: int = 9
@export var width: float = 0.95
@export var amp: float = 0.12
@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_sample: Color = Color(0.95, 0.96, 1.0)
@export var color_digital: Color = Color(0.3, 0.7, 1.0)


func _ready() -> void:
	# TOP — "at arm's length": the digital polyline reads as a curve
	_panel(Vector3(0.0, 0.24, 0.0), 1.0, false)
	_plate("AT ARM'S LENGTH", "the machine's line looks like a curve",
		Vector3(0.0, 0.46, 0.0), color_digital)
	# BOTTOM — "the tunnel": magnify three samples; the chords cut the corners,
	# the true curve bulges away, the holes open
	_panel(Vector3(0.0, -0.22, 0.0), 3.2, true)
	_plate("THE TUNNEL", "magnified: a polyline, cutting every corner\nthe hand was in the holes the machine skipped",
		Vector3(0.0, -0.46, 0.0), color_true)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_samples"):
		samples = int(str(get_meta("config_samples")))


func _curve(t: float) -> float:
	# a smooth hand-drawn feel: two blended sines
	return amp * (0.7 * sin(TAU * 1.0 * t) + 0.3 * sin(TAU * 2.0 * t + 1.1))


func _pt(t: float, zoom: float, cx: float) -> Vector3:
	# zoom magnifies around the centre window [cx-0.5/zoom, cx+0.5/zoom]
	var x: float = (t - cx) * zoom
	var y: float = _curve(t) * zoom
	return Vector3(clampf(x * width, -width * 0.5, width * 0.5), clampf(y, -amp * 2.5, amp * 2.5), 0.0)


func _panel(origin: Vector3, zoom: float, show_holes: bool) -> void:
	var holder := Node3D.new()
	holder.position = origin
	add_child(holder)
	_backing(holder)
	var cx: float = 0.5
	# the true continuous curve (amber, dense) — shown faint behind
	var steps: int = 240
	var prev_t: float = 0.0
	var prev: Vector3 = _pt(0.0, zoom, cx)
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector3 = _pt(t, zoom, cx)
		_seg(holder, prev, p, color_true, 0.003)
		prev = p
		prev_t = t
	# the samples + the digital polyline (blue) connecting them
	var pts: Array[Vector3] = []
	for i in range(samples + 1):
		var t: float = float(i) / float(samples)
		pts.append(_pt(t, zoom, cx))
	for i in range(pts.size() - 1):
		_seg(holder, pts[i], pts[i + 1], color_digital, 0.008)
	for p in pts:
		_dot(holder, p, color_sample, 0.009)


func _backing(parent: Node3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width + 0.08, amp * 5.4, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.0, -0.012)
	parent.add_child(mi)


func _seg(parent: Node3D, a: Vector3, b: Vector3, color: Color, thick: float) -> void:
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
	parent.add_child(mi)


func _dot(parent: Node3D, p: Vector3, color: Color, r: float) -> void:
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
	parent.add_child(mi)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.66, 0.10, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.66, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.055, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 34
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
