# spring_lattice.gd — THE SMOOTHNESS IS THE LATTICE RESOLUTION IN DISGUISE.
#
# The soft-bodies seam. A jelly is an elastic continuum — infinitely divisible,
# smooth under any load. The machine cannot integrate a continuum; it replaces
# it with a finite mesh of point masses joined by springs. Left: the true
# smooth blob. Right: the same blob as a mass-spring lattice — nodes and springs,
# a faceted polygon at the resolution someone chose. Squeeze it and it deforms
# at the lattice, not the continuum; stiffen the springs past the timestep and
# the whole thing detonates (the same discrete-integration crack as the thrown
# ball). What felt continuous was always a grid of dots pretending.
extends Node3D
class_name SpringLattice

@export var radius: float = 0.19
@export var node_h: float = 0.042
@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_node: Color = Color(0.95, 0.96, 1.0)
@export var color_spring: Color = Color(0.3, 0.7, 1.0)


func _ready() -> void:
	_backing()
	# LEFT — the true smooth blob
	var lc: Vector2 = Vector2(-0.28, 0.02)
	var steps: int = 96
	var prev: Vector2 = lc + Vector2(radius, 0.0)
	for i in range(1, steps + 1):
		var a: float = TAU * float(i) / float(steps)
		var p: Vector2 = lc + Vector2(cos(a) * radius, sin(a) * radius)
		_seg(prev, p, color_true, 0.005)
		prev = p
	_tag("the continuum", lc + Vector2(0.0, -radius - 0.05), color_true)
	# RIGHT — the mass-spring lattice
	var rc: Vector2 = Vector2(0.30, 0.02)
	var reach: int = int(ceil(radius / node_h)) + 1
	var nodes: Array = []           # Array of Vector2 (grid positions inside)
	var index := {}                 # "gx,gy" -> Vector2
	for gy in range(-reach, reach + 1):
		for gx in range(-reach, reach + 1):
			var off: float = node_h * 0.5 if (gy & 1) == 1 else 0.0
			var pos: Vector2 = rc + Vector2(float(gx) * node_h + off, float(gy) * node_h)
			if (pos - rc).length() <= radius:
				index["%d,%d" % [gx, gy]] = pos
				nodes.append(pos)
	# springs: connect to right, up, up-diagonal (triangular mesh)
	for gy in range(-reach, reach + 1):
		for gx in range(-reach, reach + 1):
			var key: String = "%d,%d" % [gx, gy]
			if not index.has(key):
				continue
			var a: Vector2 = index[key]
			var diag: int = 1 if (gy & 1) == 1 else -1
			for nb in [[gx + 1, gy], [gx, gy + 1], [gx + diag, gy + 1]]:
				var k2: String = "%d,%d" % [nb[0], nb[1]]
				if index.has(k2):
					_seg(a, index[k2], color_spring, 0.0035)
	for p in nodes:
		_dot(p, color_node, 0.006)
	_tag("the lattice", rc + Vector2(0.0, -radius - 0.05), color_spring)
	_plate("MASS-SPRING",
		"an elastic continuum, rendered as point masses on springs\nfaceted, not smooth · stiffen it and it detonates\nwhat felt continuous was a grid of dots pretending",
		Vector3(0.0, 0.32, 0.0), color_spring)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_node_h"):
		node_h = float(str(get_meta("config_node_h")))


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.92, 0.5, 0.006)
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


func _tag(text: String, pos: Vector2, color: Color) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = 30
	t.pixel_size = 0.00045
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector3(pos.x, pos.y, 0.0)
	add_child(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.84, 0.13, 0.008)
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
	strip.position = pos + Vector3(0.0, 0.072, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 30
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
