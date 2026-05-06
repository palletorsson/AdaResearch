## ReplaceWithMeshByRoleOp — Stamp a primitive at each tagged face.
##
## The "primitive library bridge" op. Where extrude_by_role pushes a
## tagged face into a wall, this one *replaces* the face with a small
## mesh placed at the face centroid, oriented along the face normal,
## scaled by the per-role config. The original face is removed.
##
## Use cases:
##   - Petal cluster (12 sub-roles via cluster_by_role) → stamp a diamond
##     primitive at each, oriented outward → 12 actual petal pieces.
##   - Insect leg-tip → stamp a sphere as a foot.
##   - Tree leaf cluster → stamp an icosahedron as a leaf cluster.
##   - Stamen anther → stamp a small sphere.
##
## Primitive sources (in order of preference):
##   "primitive": "cube"|"sphere"|"icosahedron"|"disk"|"flower_disk"
##                — built-in MeshData factories (always available).
##   "scene":    "res://path/to/scene.tscn" — first MeshInstance3D's mesh.
##                Loaded lazily; falls back to built-in if missing.
##
## Each stamped mesh inherits the original face's tags + the role key
## + a "stamped" marker so downstream ops can find them.
##
## Params:
##   role_params: Dictionary{role_name -> {primitive|scene, scale,
##                                          y_offset, align_to_normal,
##                                          rotation_deg}}
##     scale:            float, default 0.2
##     y_offset:         float, push along face normal before stamping (default 0)
##     align_to_normal:  bool, default true. False = world-axis stamping.
##     rotation_deg:     float, twist around the normal axis.
##   tag_prefix: String = ""
##   remove_original: bool = true — delete the source face after stamping
##   default: Dictionary (optional) — params for unmatched roles
extends MeshRule
class_name ReplaceWithMeshByRoleOp


# Per-instance cache so we load + bake each scene at most once even when
# the op stamps it across dozens of faces.
var _scene_mesh_cache: Dictionary = {}


func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var role_params: Dictionary = params.get("role_params", {})
	var tag_prefix: String = String(params.get("tag_prefix", ""))
	var remove_original: bool = bool(params.get("remove_original", true))
	var default_params: Variant = params.get("default", null)

	var one_per_role: bool = bool(params.get("one_per_role", false))
	# When true (default for radial layouts), snap each cluster's centroid
	# to the median radial distance across all clusters in its role. Fixes
	# the swirl-aliasing bug where cluster centroid radii drift due to
	# uneven face distribution across concentric rings.
	var snap_radial: bool = bool(params.get("snap_radial", true))

	# Collect (face_idx, role_key, params) tuples; do all stamping AFTER the
	# scan so face indices stay stable through the process.
	var jobs: Array = []
	# When one_per_role: group by role first, stamp once per group at the
	# averaged centroid + averaged normal. The "src face" for tag inheritance
	# is the first face of the group.
	var role_groups: Dictionary = {}  # role_key -> [face_idx,...]
	for fi in selected:
		if fi >= mesh.faces.size() or fi >= mesh.face_tags.size():
			continue
		var role_key: String = ""
		for raw_tag in mesh.face_tags[fi]:
			var tag := String(raw_tag)
			var key := tag if tag_prefix.is_empty() else (
				tag.substr(tag_prefix.length()) if tag.begins_with(tag_prefix) else "")
			if not key.is_empty() and role_params.has(key):
				role_key = key; break
			if role_params.has(tag):
				role_key = tag; break
		var p: Dictionary = {}
		if not role_key.is_empty():
			p = role_params[role_key]
		elif default_params is Dictionary:
			p = default_params
		else:
			continue
		if one_per_role and not role_key.is_empty():
			if not role_groups.has(role_key):
				role_groups[role_key] = []
			(role_groups[role_key] as Array).append(fi)
		else:
			jobs.append([fi, role_key, p])

	# Build aggregated jobs from groups when one_per_role.
	if one_per_role:
		# Compute mesh centre across all selected faces (for align_radial).
		for role_key in role_groups.keys():
			var group: Array = role_groups[role_key]
			if group.is_empty(): continue
			var p2: Dictionary = role_params[role_key]
			# Use the first face as src; compute averaged centroid for placement.
			jobs.append([int(group[0]), role_key, p2, group])

	# Compute mesh-wide centre of selected faces (used by align_radial).
	var mesh_centre: Vector3 = Vector3.ZERO
	var centre_n: int = 0
	for fi in selected:
		if fi >= mesh.faces.size(): continue
		var ff := mesh.faces[fi]
		mesh_centre += (mesh.vertices[ff[0]] + mesh.vertices[ff[1]] + mesh.vertices[ff[2]]) / 3.0
		centre_n += 1
	if centre_n > 0:
		mesh_centre /= float(centre_n)

	# Pre-pass: when one_per_role + snap_radial, compute each role's median
	# radial distance from mesh_centre and remember it so cluster centroids
	# can be projected onto a single circle. Without this, clusters at
	# different ring offsets (e.g. inner-ring vs outer-ring petals) place
	# stamps at varying radii — visually a swirl.
	var role_target_radius: Dictionary = {}
	if one_per_role and snap_radial:
		var role_distances: Dictionary = {}
		for job in jobs:
			if job.size() < 4 or not (job[3] is Array): continue
			var role_key2: String = job[1]
			# Strip cluster suffix to find parent role.
			var parent_role: String = role_key2
			var us: int = role_key2.rfind("_")
			if us > 0 and role_key2.substr(us + 1).is_valid_int():
				parent_role = role_key2.substr(0, us)
			var grp: Array = job[3]
			var c2 := Vector3.ZERO
			for gi in grp:
				var ff := mesh.faces[int(gi)]
				c2 += (mesh.vertices[ff[0]] + mesh.vertices[ff[1]] + mesh.vertices[ff[2]]) / 3.0
			c2 /= float(grp.size())
			var d: float = (c2 - mesh_centre).length()
			if not role_distances.has(parent_role):
				role_distances[parent_role] = []
			(role_distances[parent_role] as Array).append(d)
		for parent_role in role_distances.keys():
			var arr: Array = role_distances[parent_role]
			arr.sort()
			role_target_radius[parent_role] = arr[arr.size() / 2]  # median

	# Stamp each job. New geometry is appended; faces to remove are
	# collected in a second pass and deleted at the end (reverse-sorted)
	# so indices remain valid throughout stamping.
	var to_delete: PackedInt32Array = PackedInt32Array()
	for job in jobs:
		var fi: int = job[0]
		var role_key: String = job[1]
		var p: Dictionary = job[2]
		# When one_per_role, the job carries a group; aggregate centroid + normal.
		var centroid: Vector3
		var normal: Vector3
		if job.size() >= 4 and job[3] is Array and (job[3] as Array).size() > 0:
			var group: Array = job[3]
			centroid = Vector3.ZERO
			normal = Vector3.ZERO
			for gi in group:
				var gff := mesh.faces[int(gi)]
				var gv0: Vector3 = mesh.vertices[gff[0]]
				var gv1: Vector3 = mesh.vertices[gff[1]]
				var gv2: Vector3 = mesh.vertices[gff[2]]
				centroid += (gv0 + gv1 + gv2) / 3.0
				var n := (gv1 - gv0).cross(gv2 - gv0)
				if n.length_squared() > 1e-10:
					normal += n.normalized()
			centroid /= float(group.size())
			if normal.length_squared() < 1e-10:
				normal = Vector3.UP
			normal = normal.normalized()
			# Snap radial: project centroid onto its parent role's median radius.
			if snap_radial and not role_key.is_empty():
				var parent_role: String = role_key
				var us: int = role_key.rfind("_")
				if us > 0 and role_key.substr(us + 1).is_valid_int():
					parent_role = role_key.substr(0, us)
				if role_target_radius.has(parent_role):
					var radial: Vector3 = centroid - mesh_centre
					radial = radial - normal * radial.dot(normal)  # planar component
					if radial.length_squared() > 1e-8:
						var target_r: float = float(role_target_radius[parent_role])
						centroid = mesh_centre + radial.normalized() * target_r
			if remove_original:
				for gi in group:
					to_delete.append(int(gi))
		else:
			var f := mesh.faces[fi]
			var v0: Vector3 = mesh.vertices[f[0]]
			var v1: Vector3 = mesh.vertices[f[1]]
			var v2: Vector3 = mesh.vertices[f[2]]
			var n2 := (v1 - v0).cross(v2 - v0)
			if n2.length_squared() < 1e-10:
				continue
			normal = n2.normalized()
			centroid = (v0 + v1 + v2) / 3.0
			if remove_original:
				to_delete.append(fi)
		_stamp_one(mesh, role_key, p, centroid, normal, fi, mesh_centre)

	if to_delete.size() > 0:
		var sorted := Array(to_delete)
		sorted.sort()
		sorted.reverse()
		mesh.remove_faces(PackedInt32Array(sorted))


# Place a primitive at (centroid + normal*y_offset), oriented and scaled
# per role params. Tags inherit the original face's tags + role + "stamped".
func _stamp_one(mesh: MeshData, role_key: String, p: Dictionary,
		centroid: Vector3, normal: Vector3, src_face_idx: int,
		mesh_centre: Vector3 = Vector3.ZERO) -> void:
	var prim_name: String = String(p.get("primitive", "icosahedron"))
	var scale_val: float = float(p.get("scale", 0.2))
	var y_offset: float = float(p.get("y_offset", 0.0))
	var align: bool = bool(p.get("align_to_normal", true))
	var align_radial: bool = bool(p.get("align_radial", false))
	var radial_tilt: float = float(p.get("radial_tilt", 0.4))
	var rotation_deg: float = float(p.get("rotation_deg", 0.0))

	var prim_mesh: MeshData = null
	if p.has("scene"):
		prim_mesh = _load_scene_mesh(String(p["scene"]), scale_val)
	if prim_mesh == null and p.has("graph") and p["graph"] is Dictionary:
		prim_mesh = _build_graph_primitive(p["graph"], scale_val)
	if prim_mesh == null:
		prim_mesh = _build_primitive(prim_name, scale_val)
	if prim_mesh == null or prim_mesh.vertices.size() == 0:
		return

	# Build orient basis. Three options, in priority order:
	#  1. align_radial — orient stamp's local Y along (centroid - mesh_centre)
	#                   plus radial_tilt * normal. Splays petals outward and up.
	#  2. align (default) — local Y maps to face normal.
	#  3. neither — world-axis identity.
	var basis: Basis = Basis.IDENTITY
	if align_radial:
		var radial: Vector3 = centroid - mesh_centre
		# Flatten radial onto the plane perpendicular to normal so we get a
		# clean horizontal "outward" direction, then mix with normal.
		radial = radial - normal * radial.dot(normal)
		if radial.length_squared() < 1e-8:
			radial = Vector3.RIGHT
		radial = radial.normalized()
		var up: Vector3 = (radial + normal * radial_tilt).normalized()
		var ref: Vector3 = normal if absf(up.dot(normal)) < 0.95 else Vector3.RIGHT
		var u: Vector3 = up.cross(ref).normalized()
		var v: Vector3 = up.cross(u).normalized()
		basis = Basis(v, up, u)
	elif align:
		var up: Vector3 = normal
		var ref: Vector3 = Vector3.UP if absf(up.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var u: Vector3 = up.cross(ref).normalized()
		var v: Vector3 = up.cross(u).normalized()
		basis = Basis(v, up, u)
	if rotation_deg != 0.0:
		basis = basis * Basis(Vector3.UP, deg_to_rad(rotation_deg))
	var origin: Vector3 = centroid + normal * y_offset
	var xform := Transform3D(basis, origin)

	# Inherited tags: original face's tags + role + stamped marker.
	var inherited_color: Variant = null
	if src_face_idx < mesh.face_metadata.size():
		var md: Dictionary = mesh.face_metadata[src_face_idx]
		if md.has("color"):
			inherited_color = md["color"]
	var inherited_tags: PackedStringArray = PackedStringArray()
	inherited_tags.append("stamped")
	if not role_key.is_empty():
		inherited_tags.append(role_key)
	if src_face_idx < mesh.face_tags.size():
		for t in mesh.face_tags[src_face_idx]:
			inherited_tags.append(String(t))

	var v_offset: int = mesh.vertices.size()
	for vert in prim_mesh.vertices:
		mesh.vertices.append(xform * (vert as Vector3))
	for face in prim_mesh.faces:
		var fi: int = mesh.faces.size()
		mesh.faces.append(PackedInt32Array([face[0] + v_offset,
											face[1] + v_offset,
											face[2] + v_offset]))
		while mesh.face_tags.size() <= fi:
			mesh.face_tags.append(PackedStringArray())
			mesh.face_metadata.append({})
			mesh.face_depth.append(0)
		for t in inherited_tags:
			mesh.face_tags[fi].append(t)
		if inherited_color != null:
			mesh.face_metadata[fi]["color"] = inherited_color
			mesh.face_metadata[fi]["painted"] = true
	while mesh.vertex_tags.size() < mesh.vertices.size():
		mesh.vertex_tags.append(PackedStringArray())


# Build a small MeshData primitive by name. Always-available factories.
func _build_primitive(name: String, scale_val: float) -> MeshData:
	match name:
		"cube":
			return MeshData.create_cube(scale_val)
		"sphere":
			return MeshData.create_sphere(scale_val, 8, 12)
		"icosahedron":
			return MeshData.create_icosahedron(scale_val)
		"disk":
			return MeshData.create_disk(scale_val, 12)
		"flower_disk":
			return MeshData.create_flower_disk(scale_val, 3, 12)
		"diamond":
			# Bipyramid: two cones joined at the equator (fast diamond shape).
			return _build_diamond(scale_val)
		"leaf":
			# Pointed almond shape — flat oval pinched at both ends.
			return _build_leaf(scale_val)
	push_warning("ReplaceWithMeshByRole: unknown primitive '%s'" % name)
	return MeshData.create_icosahedron(scale_val)


# Stamp a small graph (tagged tube tree) at each face. Lets the op
# place anything graph-shaped — a Y-fork stamen, a fern frond, a trident
# mandible — without leaving the mesh-grammar vocabulary.
# Graph spec is the same as the renderer's seed dispatcher accepts.
func _build_graph_primitive(g_cfg: Dictionary, scale_val: float) -> MeshData:
	var preset: String = String(g_cfg.get("preset", "")).to_lower()
	var nodes_arr: Array = []
	var radii_arr: Array = []
	var edges_arr: Array = []
	var tags_arr: Array = []
	if preset == "y_fork":
		# Y-shaped stamen: trunk + two tips.
		nodes_arr = [Vector3.ZERO, Vector3(0, 0.6, 0),
					 Vector3(-0.3, 1.0, 0), Vector3(0.3, 1.0, 0)]
		radii_arr = [0.06, 0.04, 0.025, 0.025]
		edges_arr = [[0, 1], [1, 2], [1, 3]]
		tags_arr = [["base"], ["fork"], ["tip"], ["tip"]]
	elif preset == "trident":
		nodes_arr = [Vector3.ZERO, Vector3(0, 0.5, 0),
					 Vector3(-0.25, 1.0, 0), Vector3(0, 1.05, 0), Vector3(0.25, 1.0, 0)]
		radii_arr = [0.08, 0.05, 0.03, 0.03, 0.03]
		edges_arr = [[0, 1], [1, 2], [1, 3], [1, 4]]
		tags_arr = [["base"], ["fork"], ["tip"], ["tip"], ["tip"]]
	else:
		# Literal nodes/edges from JSON.
		for n in g_cfg.get("nodes", []):
			if n is Array and n.size() >= 3:
				nodes_arr.append(Vector3(float(n[0]), float(n[1]), float(n[2])))
		for r in g_cfg.get("radii", []):
			radii_arr.append(float(r))
		for e in g_cfg.get("edges", []):
			if e is Array and e.size() >= 2:
				edges_arr.append([int(e[0]), int(e[1])])
		for t in g_cfg.get("node_tags", []):
			tags_arr.append(t if t is Array else [])
	# Apply uniform scale.
	for i in range(nodes_arr.size()):
		nodes_arr[i] = (nodes_arr[i] as Vector3) * scale_val
		if i < radii_arr.size():
			radii_arr[i] = float(radii_arr[i]) * scale_val
	while tags_arr.size() < nodes_arr.size():
		tags_arr.append([])
	var packed_tags: Array = []
	for t in tags_arr:
		var pp := PackedStringArray()
		for s in t:
			pp.append(String(s))
		packed_tags.append(pp)
	var segments: int = int(g_cfg.get("segments", 6))
	var mode: String = String(g_cfg.get("skin_mode", "shared_rings_capped"))
	return MeshData.skin_graph(nodes_arr, radii_arr, edges_arr, packed_tags, segments, mode)


# Synchronous scene-mesh loader. Loads a PackedScene, instantiates as an
# orphan, walks for the first MeshInstance3D, calls _ready manually if
# needed (handles procedural primitive scenes), extracts the ArrayMesh,
# converts to MeshData. Cached per scene path + scale so repeated stamps
# pay the cost once.
func _load_scene_mesh(scene_path: String, scale_val: float) -> MeshData:
	var key := "%s|%f" % [scene_path, scale_val]
	if _scene_mesh_cache.has(key):
		return _scene_mesh_cache[key]
	if not ResourceLoader.exists(scene_path):
		push_warning("ReplaceWithMeshByRole: scene not found: %s" % scene_path)
		return null
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return null
	var inst: Node = packed.instantiate()
	if inst == null:
		return null
	# Procedural primitive scenes generate geometry in _ready. Run it
	# manually on the orphan since we never add to a scene tree.
	if inst.has_method("_ready"):
		inst._ready()
	var mi: MeshInstance3D = _find_mesh_instance(inst)
	if mi == null or mi.mesh == null:
		inst.free()
		return null
	var array_mesh: ArrayMesh = mi.mesh as ArrayMesh
	var prim: MeshData = null
	if array_mesh != null:
		prim = MeshData.from_array_mesh(array_mesh)
	else:
		# Maybe it's a primitive mesh (BoxMesh, etc) — convert via SurfaceTool.
		var st := SurfaceTool.new()
		st.create_from(mi.mesh, 0)
		var am := st.commit()
		if am != null:
			prim = MeshData.from_array_mesh(am)
	inst.free()
	if prim == null:
		return null
	# Apply scale + center.
	var bb: AABB = prim.get_bounding_box()
	var max_extent: float = max(bb.size.x, max(bb.size.y, bb.size.z))
	var k: float = scale_val / max(max_extent * 0.5, 1e-4)
	for i in range(prim.vertices.size()):
		prim.vertices[i] = (prim.vertices[i] - bb.get_center()) * k
	_scene_mesh_cache[key] = prim
	return prim


# Walk the orphan tree for the first MeshInstance3D.
func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found: MeshInstance3D = _find_mesh_instance(child)
		if found != null:
			return found
	return null


# Eight-sided diamond (bipyramid) — fast petal/spike primitive.
func _build_diamond(s: float) -> MeshData:
	var md := MeshData.new()
	var top: int = md.add_vertex(Vector3(0, s, 0))
	var bot: int = md.add_vertex(Vector3(0, -s * 0.4, 0))
	var ring_n: int = 6
	var ring: PackedInt32Array = PackedInt32Array()
	for i in range(ring_n):
		var theta: float = TAU * float(i) / float(ring_n)
		ring.append(md.add_vertex(Vector3(cos(theta) * s * 0.45, 0, sin(theta) * s * 0.45)))
	for i in range(ring_n):
		var i2: int = (i + 1) % ring_n
		md.faces.append(PackedInt32Array([top, ring[i2], ring[i]]))
		md.faces.append(PackedInt32Array([bot, ring[i], ring[i2]]))
	md._init_metadata()
	return md


# Almond/leaf — flat oval pinched at both ends. Long axis is Y so that
# `align_radial` (which maps local Y to outward+tilt) makes the petal
# point radially outward, as a flower petal should.
func _build_leaf(s: float) -> MeshData:
	var md := MeshData.new()
	var n: int = 6
	# Long axis along Y: base at -s, tip at +s.
	var base: int = md.add_vertex(Vector3(0, -s, 0))
	var tip: int = md.add_vertex(Vector3(0, s, 0))
	var top_ring: PackedInt32Array = PackedInt32Array()
	var bot_ring: PackedInt32Array = PackedInt32Array()
	for i in range(1, n):
		var t: float = float(i) / float(n)
		var y: float = -s + 2.0 * s * t
		var w: float = sin(PI * t) * s * 0.4
		top_ring.append(md.add_vertex(Vector3(w, y, 0.02)))
		bot_ring.append(md.add_vertex(Vector3(-w, y, -0.02)))
	# Connect base → first ring vert, then quads, then last → tip.
	md.faces.append(PackedInt32Array([base, top_ring[0], bot_ring[0]]))
	for i in range(top_ring.size() - 1):
		md.faces.append(PackedInt32Array([top_ring[i], top_ring[i + 1], bot_ring[i + 1]]))
		md.faces.append(PackedInt32Array([top_ring[i], bot_ring[i + 1], bot_ring[i]]))
	md.faces.append(PackedInt32Array([top_ring[top_ring.size() - 1], tip, bot_ring[bot_ring.size() - 1]]))
	md._init_metadata()
	return md
