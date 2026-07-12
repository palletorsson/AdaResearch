# stepped_transform.gd — REACH FOR THE POSE BETWEEN TWO STEPS. YOU SNAP.
#
# The transformation seam. Rigid motion — translate and rotate — is continuous:
# SE(3), a smooth manifold, a pose for every real number. The machine keeps only
# a lattice of representable transforms: positions on a grid, angles on a step.
# Amber: the continuous glide, an object moving and turning through every
# in-between pose. Blue: the same motion as the machine holds it — a staircase of
# translations, the heading snapping in fixed increments. You can be here or
# there, at this angle or that, never in the pose between.
extends Node3D
class_name SteppedTransform

@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_step: Color = Color(0.3, 0.7, 1.0)
@export var steps: int = 6


func _ready() -> void:
	_backing()
	var a: Vector2 = Vector2(-0.32, -0.20)
	var b: Vector2 = Vector2(0.30, 0.20)
	# CONTINUUM — smooth diagonal glide, heading rotating smoothly 0..90
	_seg(a, b, color_true.darkened(0.25), 0.004)
	var ghosts: int = 9
	for i in range(ghosts + 1):
		var t: float = float(i) / float(ghosts)
		var p: Vector2 = a.lerp(b, t)
		_arrow(p, lerp(0.0, 90.0, t), color_true, 0.05, 0.6)
	_tag("continuous rigid motion", Vector2((a.x + b.x) * 0.5, b.y + 0.07), color_true)
	# LATTICE — staircase of translations, heading snapping in 30 deg steps
	var prev: Vector2 = a
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var target: Vector2 = a.lerp(b, t)
		# move in axis steps: x first, then y (Manhattan stair)
		var corner: Vector2 = Vector2(target.x, prev.y)
		_seg(prev, corner, color_step, 0.005)
		_seg(corner, target, color_step, 0.005)
		var snapped: float = round(lerp(0.0, 90.0, t) / 30.0) * 30.0
		_arrow(target + Vector2(0.0, 0.0), snapped, color_step, 0.05, 1.0)
		prev = target
	_tag("snapped to a lattice of steps", Vector2((a.x + b.x) * 0.5, a.y - 0.08), color_step)
	_plate("MOVE + TURN",
		"SE(3) is continuous — a pose for every real number\nthe machine keeps a lattice: grid positions, stepped angles\nreach for the pose between two steps and you snap",
		Vector3(0.0, 0.34, 0.0), color_step)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_steps"):
		steps = int(str(get_meta("config_steps")))


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.6, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.04, -0.014)
	add_child(mi)


func _arrow(pos: Vector2, angle_deg: float, color: Color, length: float, alpha: float) -> void:
	var rad: float = deg_to_rad(angle_deg)
	var dir: Vector2 = Vector2(cos(rad), sin(rad))
	var tip: Vector2 = pos + dir * length
	var col := Color(color.r, color.g, color.b, alpha)
	_seg(pos, tip, col, 0.004)
	_dot(tip, col, 0.007)


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
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
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
	mat.emission = Color(color.r, color.g, color.b)
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = Vector3(p.x, p.y, 0.008)
	add_child(mi)


func _tag(text: String, pos: Vector2, color: Color) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = 28
	t.pixel_size = 0.00044
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector3(pos.x, pos.y, 0.0)
	add_child(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.84, 0.15, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.84, 0.01, 0.012)
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
