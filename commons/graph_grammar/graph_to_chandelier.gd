# graph_to_chandelier.gd — Render a GraphState as a Lindsey Adelman-style
# chandelier: edges as thin dark metal rods, leaf nodes as large emissive
# frosted-glass spheres, internal joints invisible (or optional small beads).
#
# This is the Adelman aesthetic — the Branching Bubble Chandelier family.
# The grammar is already there (graph grammar with spawn_branch rules);
# only the rendering was missing. This file fills that gap.
#
# Params (read from config under `chandelier:` key):
#   edge_radius       — rod thickness (default 0.015)
#   edge_color        — [r,g,b] dark metal (default [0.12, 0.1, 0.09])
#   edge_metallic     — 0.85 for bronze/nickel look (default 0.85)
#   edge_roughness    — rod finish (default 0.35)
#   bulb_radius       — leaf sphere size (default 0.13)
#   bulb_color        — base color of glass (default [1.0, 0.94, 0.82])
#   bulb_emission     — glow strength (default 1.8)
#   bulb_roughness    — frosted = higher (default 0.65)
#   show_joints       — small beads at Y-junctions (default false)
#   joint_radius      — if show_joints (default 0.025)
extends RefCounted


static func to_node3d(g, cfg: Dictionary = {}) -> Node3D:
	var edge_radius: float = float(cfg.get("edge_radius", 0.015))
	var edge_color_arr = cfg.get("edge_color", [0.12, 0.1, 0.09])
	var edge_metallic: float = float(cfg.get("edge_metallic", 0.85))
	var edge_roughness: float = float(cfg.get("edge_roughness", 0.35))
	var bulb_radius: float = float(cfg.get("bulb_radius", 0.13))
	var bulb_color_arr = cfg.get("bulb_color", [1.0, 0.94, 0.82])
	var bulb_emission: float = float(cfg.get("bulb_emission", 1.8))
	var bulb_roughness: float = float(cfg.get("bulb_roughness", 0.65))
	var show_joints: bool = bool(cfg.get("show_joints", false))
	var joint_radius: float = float(cfg.get("joint_radius", 0.025))

	var edge_color := Color(
		float(edge_color_arr[0]),
		float(edge_color_arr[1]),
		float(edge_color_arr[2]),
	)
	var bulb_color := Color(
		float(bulb_color_arr[0]),
		float(bulb_color_arr[1]),
		float(bulb_color_arr[2]),
	)

	var edge_mat := _metal_material(edge_color, edge_metallic, edge_roughness)
	var bulb_mat := _glass_material(bulb_color, bulb_emission, bulb_roughness)
	var joint_mat := _metal_material(edge_color, edge_metallic, edge_roughness)

	# Identify leaf nodes (no children) — those get bulbs.
	var has_child: Array = []
	has_child.resize(g.node_count())
	for i in g.node_count():
		has_child[i] = false
	for e in g.edges:
		has_child[e[0]] = true

	var root := Node3D.new()
	root.name = "Chandelier"

	# Edges — thin dark metal rods
	for e in g.edges:
		var a_idx: int = e[0]
		var b_idx: int = e[1]
		if a_idx >= g.nodes.size() or b_idx >= g.nodes.size():
			continue
		var a: Vector3 = g.nodes[a_idx]
		var b: Vector3 = g.nodes[b_idx]
		var mi := _rod(a, b, edge_radius)
		mi.material_override = edge_mat
		root.add_child(mi)

	# Nodes — bulbs at leaves, optionally small joints at branch points
	for i in g.node_count():
		var pos: Vector3 = g.nodes[i]
		if not has_child[i]:
			# Leaf → big frosted-glass bulb
			var bulb := MeshInstance3D.new()
			var bm := SphereMesh.new()
			bm.radius = bulb_radius
			bm.height = bulb_radius * 2.0
			bm.radial_segments = 24
			bm.rings = 12
			bulb.mesh = bm
			bulb.position = pos
			bulb.material_override = bulb_mat
			bulb.name = "bulb_%d" % i
			root.add_child(bulb)
		elif show_joints:
			# Interior node → small dark bead at the fork
			var joint := MeshInstance3D.new()
			var jm := SphereMesh.new()
			jm.radius = joint_radius
			jm.height = joint_radius * 2.0
			jm.radial_segments = 12
			jm.rings = 6
			joint.mesh = jm
			joint.position = pos
			joint.material_override = joint_mat
			root.add_child(joint)

	return root


static func _rod(a: Vector3, b: Vector3, radius: float) -> MeshInstance3D:
	var dir: Vector3 = b - a
	var length: float = dir.length()
	if length < 1e-6:
		length = 0.01
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mid: Vector3 = (a + b) * 0.5
	var t := Transform3D.IDENTITY
	t.origin = mid
	var n: Vector3 = dir.normalized()
	var up := Vector3(0, 1, 0)
	if (n - up).length_squared() > 1e-6 and (n + up).length_squared() > 1e-6:
		var axis: Vector3 = up.cross(n).normalized()
		var angle: float = acos(clamp(up.dot(n), -1.0, 1.0))
		t.basis = Basis(axis, angle)
	elif (n + up).length_squared() <= 1e-6:
		t.basis = Basis(Vector3(1, 0, 0), PI)
	mi.transform = t
	return mi


static func _metal_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m


static func _glass_material(color: Color, emission: float, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.0
	m.roughness = roughness
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = emission
	# Frosted — light scatters through
	m.rim_enabled = true
	m.rim_tint = 0.8
	return m
