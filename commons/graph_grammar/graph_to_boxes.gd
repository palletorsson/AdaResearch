# graph_to_boxes.gd — Alternative renderer: draw each node as a BOX at
# its Modulor scale, colored by category tag. Edges between nodes are
# drawn as thin connector sticks so the hierarchy is still visible.
#
# This renderer exposes the **ontology** of a Modulor-fold grammar —
# big box = room, smaller box inside = table, smaller still = book.
# Categories get distinct colors so the reading is instantaneous.
#
# Usage:
#   var node := GraphToBoxes.to_node3d(graph, palette)
#   add_child(node)
extends RefCounted

const ModulorScale = preload("res://commons/morphology/sdf/modulor_scale.gd")


const DEFAULT_PALETTE: Dictionary = {
	"room":    Color(0.88, 0.82, 0.7),
	"table":   Color(0.58, 0.4, 0.25),
	"shelf":   Color(0.5, 0.35, 0.22),
	"cushion": Color(0.75, 0.5, 0.45),
	"book":    Color(0.75, 0.2, 0.2),
	"cup":     Color(0.9, 0.88, 0.85),
	"pen":     Color(0.12, 0.14, 0.18),
	"tip":     Color(0.95, 0.85, 0.3),
	"nail":    Color(0.3, 0.3, 0.35),
	"default": Color(0.6, 0.55, 0.5),
	"connector": Color(0.3, 0.28, 0.25),
}


static func to_node3d(g, palette: Dictionary = {}) -> Node3D:
	var pal := palette if not palette.is_empty() else DEFAULT_PALETTE
	for k in DEFAULT_PALETTE:
		if not pal.has(k):
			pal[k] = DEFAULT_PALETTE[k]

	var root := Node3D.new()
	root.name = "GraphBoxes"

	# Draw each node as a box sized by its Modulor level.
	# Box size = Modulor.red(level) * sizing_factor. If no level tag, use radius.
	for i in g.node_count():
		var pos: Vector3 = g.nodes[i]
		var tags: PackedStringArray = g.node_tags[i] if i < g.node_tags.size() else PackedStringArray()
		var level: int = _read_level(tags)
		var category: String = _read_category(tags)
		var scale_m: float = ModulorScale.red(level) if level >= 0 else (g.radii[i] * 6.0)
		# Rooms render as floor-only so we can see the furniture inside.
		# All other categories render as solid boxes.
		if category == "room":
			var box_size_r: Vector3 = _box_size_for(category, scale_m)
			# Floor slab
			var floor_mesh := BoxMesh.new()
			floor_mesh.size = Vector3(box_size_r.x, scale_m * 0.04, box_size_r.z)
			var floor_mi := MeshInstance3D.new()
			floor_mi.mesh = floor_mesh
			floor_mi.position = pos + Vector3(0, scale_m * 0.02, 0)
			var floor_mat := StandardMaterial3D.new()
			floor_mat.albedo_color = pal.get(category, pal.get("default")) * 0.7
			floor_mat.roughness = 0.85
			floor_mi.material_override = floor_mat
			root.add_child(floor_mi)
			continue
		var box_size: Vector3 = _box_size_for(category, scale_m)
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = box_size
		mi.mesh = mesh
		# Position: lift so the box sits ON its parent (bottom of box at the
		# node position).
		mi.position = pos + Vector3(0, box_size.y * 0.5, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = pal.get(category, pal.get("default"))
		mat.roughness = 0.75
		mi.material_override = mat
		mi.name = "%s_%d" % [category, i]
		root.add_child(mi)

	# Thin connector sticks between parent and child — shows hierarchy
	for e in g.edges:
		var a_idx: int = e[0]
		var b_idx: int = e[1]
		if a_idx >= g.nodes.size() or b_idx >= g.nodes.size():
			continue
		var a_pos: Vector3 = g.nodes[a_idx]
		var b_pos: Vector3 = g.nodes[b_idx]
		var mi := _connector(a_pos, b_pos, pal["connector"])
		if mi:
			root.add_child(mi)

	return root


static func _read_level(tags: PackedStringArray) -> int:
	for t in tags:
		if t.begins_with("modulor_"):
			var s: String = t.substr(8)
			if s.is_valid_int():
				return int(s)
	return -1


static func _read_category(tags: PackedStringArray) -> String:
	# First tag that matches a known category
	var known: Array = [
		"room", "table", "shelf", "cushion", "book", "cup",
		"pen", "tip", "nail",
	]
	for t in tags:
		if t in known:
			return t
	return "default"


static func _box_size_for(category: String, scale_m: float) -> Vector3:
	# Rough proportion per category. Scale_m is the Modulor rung of the level.
	match category:
		"room":
			return Vector3(scale_m * 2.2, scale_m * 1.2, scale_m * 2.5)  # wider and longer than tall
		"table":
			return Vector3(scale_m * 1.3, scale_m * 0.12, scale_m * 0.9)  # flat surface
		"shelf":
			return Vector3(scale_m * 1.1, scale_m * 1.4, scale_m * 0.3)   # tall, narrow
		"cushion":
			return Vector3(scale_m, scale_m * 0.45, scale_m * 0.9)        # seat-like
		"book":
			return Vector3(scale_m * 0.7, scale_m * 0.15, scale_m * 0.9)  # flat block
		"cup":
			return Vector3(scale_m * 0.9, scale_m * 1.2, scale_m * 0.9)   # upright
		"pen":
			return Vector3(scale_m * 0.18, scale_m * 0.18, scale_m * 1.6) # long thin
		"tip":
			return Vector3(scale_m, scale_m, scale_m) * 0.7
		"nail":
			return Vector3(scale_m, scale_m * 0.3, scale_m) * 0.9
	return Vector3(scale_m, scale_m, scale_m)


static func _connector(a: Vector3, b: Vector3, color: Color) -> MeshInstance3D:
	var dir: Vector3 = b - a
	var length: float = dir.length()
	if length < 0.001: return null
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.008
	mesh.bottom_radius = 0.008
	mesh.height = length
	mesh.radial_segments = 6
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
	mi.transform = t
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mi.material_override = mat
	return mi
