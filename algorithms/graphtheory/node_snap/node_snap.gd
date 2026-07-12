# node_snap.gd — YOU CAN BE AT A NODE, OR ON AN EDGE — NEVER OFF THE GRAPH.
#
# The graph-theory seam. Real space is continuous — you can stand anywhere and
# walk in any direction. A graph keeps only nodes and edges: a finite skeleton
# laid over the continuum, and everything off it is gone. Amber: the desire line,
# the straight route you would walk from start to goal across open ground. Blue:
# the route the graph permits — node to node along edges, zigzagging, longer,
# because the shortcut through the middle was never stored. The map is not the
# territory; the graph is the map admitting it kept only the crossings.
extends Node3D
class_name NodeSnap

@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_path: Color = Color(0.3, 0.7, 1.0)
@export var color_node: Color = Color(0.95, 0.96, 1.0)


func _ready() -> void:
	_backing()
	var nodes: Array[Vector2] = [
		Vector2(-0.34, -0.18),  # 0  START
		Vector2(-0.12, -0.24),  # 1
		Vector2(0.10, -0.16),   # 2
		Vector2(0.32, -0.20),   # 3
		Vector2(-0.28, 0.04),   # 4
		Vector2(-0.04, 0.08),   # 5
		Vector2(0.20, 0.03),    # 6
		Vector2(-0.18, 0.22),   # 7
		Vector2(0.30, 0.22),    # 8  GOAL
	]
	var edges := [
		[0, 1], [1, 2], [2, 3], [0, 4], [1, 5], [2, 6], [3, 6],
		[4, 5], [5, 6], [4, 7], [5, 7], [6, 8], [7, 8],
	]
	var path := [0, 4, 5, 6, 8]  # the route the graph permits
	# dim edges
	for e in edges:
		_seg(nodes[e[0]], nodes[e[1]], Color(0.24, 0.27, 0.32), 0.003)
	# the desire line (continuum) — straight START -> GOAL
	_seg(nodes[0], nodes[8], color_true, 0.006)
	# the graph path, highlighted
	for i in range(path.size() - 1):
		_seg(nodes[path[i]], nodes[path[i + 1]], color_path, 0.006)
	# nodes
	for i in range(nodes.size()):
		_dot(nodes[i], color_node, 0.011)
	_tag("START", nodes[0] + Vector2(-0.02, -0.05), color_path)
	_tag("GOAL", nodes[8] + Vector2(0.02, 0.05), color_path)
	_tag("the desire line vs the route the graph permits", Vector2(0.0, -0.34), color_true)
	_plate("SPACE → GRAPH",
		"real space is continuous — walk anywhere\nthe graph keeps only nodes and edges\nthe shortcut through the middle was never stored",
		Vector3(0.0, 0.40, 0.0), color_path)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.62, 0.006)
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
	mi.position = Vector3(p.x, p.y, 0.01)
	add_child(mi)


func _tag(text: String, pos: Vector2, color: Color) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = 28
	t.pixel_size = 0.00044
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector3(pos.x, pos.y, 0.02)
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
