# wallpaper_cage.gd — REACH FOR 5-FOLD AND THE PLANE WON'T CLOSE.
#
# The symmetry seam. Rotation is a continuous dial — turn by any real angle and
# the circle is unchanged (SO(2), a smooth infinity of symmetries). But a
# periodic tiling of the plane cannot use just any angle: the crystallographic
# restriction allows only 1, 2, 3, 4, and 6-fold rotation. Five-fold, seven-fold
# — the gaps never close, the lattice never repeats. Amber: the continuous dial,
# every angle a symmetry. Blue: the five orders the plane permits. Red: the
# forbidden ones. From this cage falls a finite catalogue — exactly 17 wallpaper
# groups, the complete list of ways a pattern can repeat. The continuum walks in
# and a countable law walks out.
extends Node3D
class_name WallpaperCage

@export var radius: float = 0.24
@export var color_cont: Color = Color(1.0, 0.62, 0.18)
@export var color_ok: Color = Color(0.3, 0.7, 1.0)
@export var color_no: Color = Color(1.0, 0.35, 0.32)


func _ready() -> void:
	_backing()
	# amber continuous ring — every angle is a symmetry of the circle
	var steps: int = 120
	var prev: Vector2 = Vector2(radius, 0.0)
	for i in range(1, steps + 1):
		var a: float = TAU * float(i) / float(steps)
		var p: Vector2 = Vector2(cos(a) * radius, sin(a) * radius)
		_seg(prev, p, color_cont, 0.004)
		prev = p
	# allowed n-fold orders: their smallest rotation angle = 360/n
	var allowed := [1, 2, 3, 4, 6]
	for n in allowed:
		var ang: float = deg_to_rad(360.0 / float(n))
		var dir: Vector2 = Vector2(cos(ang + PI * 0.5), sin(ang + PI * 0.5))
		_seg(Vector2.ZERO, dir * radius, color_ok, 0.006)
		_dot(dir * radius, color_ok, 0.012)
		_tag("%d" % n, dir * (radius + 0.045), color_ok, 26)
	# forbidden orders (5, 7) — a cross where the spoke would be
	for n in [5, 7]:
		var ang2: float = deg_to_rad(360.0 / float(n))
		var dir2: Vector2 = Vector2(cos(-ang2 - PI * 0.4), sin(-ang2 - PI * 0.4))
		var c: Vector2 = dir2 * radius * 0.86
		_seg(c + Vector2(-0.018, -0.018), c + Vector2(0.018, 0.018), color_no, 0.005)
		_seg(c + Vector2(-0.018, 0.018), c + Vector2(0.018, -0.018), color_no, 0.005)
		_tag("%d✗" % n, dir2 * (radius + 0.05), color_no, 24)
	_dot(Vector2.ZERO, Color(0.95, 0.96, 1.0), 0.01)
	_tag("any angle turns the circle", Vector2(0.0, -radius - 0.07), color_cont, 28)
	_plate("SYMMETRY",
		"rotation is a continuous dial — every angle a symmetry\na periodic tiling admits only 1, 2, 3, 4, 6-fold\nexactly 17 wallpaper groups fall out — reach for 5 and it won't close",
		Vector3(0.0, radius + 0.2, 0.0), color_ok)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.78, 0.78, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.02, -0.014)
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
	mi.position = Vector3(p.x, p.y, 0.006)
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
