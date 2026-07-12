# euler_drift.gd — THE FORCE IS REAL; THE STEPPING IS THE MACHINE'S.
#
# The forces seam (the discrete-integration crack). Continuous dynamics are
# integrated in jumps. The true parabola (amber) is where the throw goes; the
# Euler path (blue), stepped at a coarse timestep, drifts off it — gaining
# energy it was never given, arcing wider each step. And at a big step a fast
# body TUNNELS: it is on one side of the wall this frame and the far side the
# next, having stepped clean over the barrier the physics said was solid.
extends Node3D
class_name EulerDrift

@export var start: Vector2 = Vector2(-0.42, -0.12)
@export var v0: Vector2 = Vector2(0.72, 0.92)
@export var grav: Vector2 = Vector2(0.0, -1.55)
@export var euler_steps: int = 7
@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_euler: Color = Color(0.3, 0.7, 1.0)
@export var color_wall: Color = Color(0.75, 0.3, 0.28)


func _ready() -> void:
	_backing()
	_draw_true()
	_draw_euler()
	_wall()
	_plate("THE STEP",
		"physics is continuous · the engine jumps\nthe Euler path (blue) drifts from the true arc (amber)\nat a big step a fast body tunnels the wall",
		Vector3(0.0, 0.33, 0.0), color_euler)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_euler_steps"):
		euler_steps = int(str(get_meta("config_euler_steps")))


func _true_pos(t: float) -> Vector2:
	return start + v0 * t + 0.5 * grav * (t * t)


func _draw_true() -> void:
	var steps: int = 160
	var prev: Vector2 = _true_pos(0.0)
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector2 = _true_pos(t)
		_seg(_v(prev), _v(p), color_true, 0.004)
		prev = p


func _draw_euler() -> void:
	# explicit Euler at a coarse dt — it overshoots and gains energy
	var dt: float = 1.0 / float(euler_steps)
	var pos: Vector2 = start
	var vel: Vector2 = v0
	var prev: Vector2 = pos
	_dot(_v(pos), color_euler, 0.011)
	for _i in range(euler_steps):
		pos = pos + vel * dt
		vel = vel + grav * dt
		_seg(_v(prev), _v(pos), color_euler, 0.008)
		_dot(_v(pos), color_euler, 0.009)
		prev = pos
	# the tunnelled body: the last Euler point, sitting past the wall
	_dot(_v(pos), color_euler, 0.02)


func _wall() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.018, 0.16, 0.02)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_wall
	mat.emission_enabled = true
	mat.emission = color_wall
	mat.emission_energy_multiplier = 0.2
	mi.material_override = mat
	mi.position = Vector3(0.06, 0.02, 0.0)
	add_child(mi)


func _v(p: Vector2) -> Vector3:
	return Vector3(p.x, p.y, 0.0)


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.42, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.05, -0.012)
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


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.78, 0.12, 0.008)
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
	strip.position = pos + Vector3(0.0, 0.065, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 32
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
