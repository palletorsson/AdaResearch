extends RefCounted
## One look for a floor's primitives (Palle, 2026-11-04, Primitives_Ignorance: "use the same shader on all primitives
## in that map ... the same as on the platonic solids"). floor_content.gd calls dress() for a placement whose config
## has "platonic"; a placement without the key is never touched.
##   finish  every solid mesh of the exhibit takes the platonic solids' warm white finish (PlatonicStudy.finish()).
##           Left as they are: anything transparent (glass, ghost shells), screens, labels and text, highlights, and
##           whatever a SubViewport draws. Applied again a second later for exhibits that build after _ready.
##   study   the exhibit becomes one of the hall's solids: its mesh on a plinth, a pickable that stays frozen until it
##           is picked up and falls only when released, with the finish, gold edges and reading plate of PlatonicStudy.
##           config "study_name" names it on the plate; "study_solid" builds a named solid exactly (SOLIDS) instead of
##           taking the exhibit's own mesh - the plate counts its vertices, edges and faces, so they must be true. The
##           truncatedtetrahedron artifact's mesh is a "simplified version" (8 corners, crossing faces), not the solid.
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const PlatonicStudy = preload("res://commons/void/platonic_study.gd")
const SKIP_WORDS := ["label", "text", "screen", "ghost", "shell", "highlight", "glass", "caption", "sign"]

static func dress(mount: Node3D, artifact: Node3D, mode: String, config: Dictionary) -> void:
	match mode:
		"finish":
			var finish := PlatonicStudy.finish()
			apply(artifact, finish)
			# Some exhibits build their meshes a frame or more after _ready.
			if artifact.is_inside_tree():
				artifact.get_tree().create_timer(1.0).timeout.connect(func(): if is_instance_valid(artifact): apply(artifact, finish))
		"study":
			var exact: Mesh = solid(str(config.get("study_solid", "")))
			study(mount, artifact, str(config.get("study_name", str(artifact.get_meta("void_artifact", "solid")))), exact)

## Named solids built exactly, as the convex hull of their vertices.
static func solid(title: String) -> Mesh:
	match title:
		"truncated_tetrahedron":
			# The 12 vertices: every permutation of (3, 1, 1) with an even number of minus signs.
			var points := PackedVector3Array()
			for perm in [Vector3(3, 1, 1), Vector3(1, 3, 1), Vector3(1, 1, 3)]:
				for sx in [1, -1]:
					for sy in [1, -1]:
						for sz in [1, -1]:
							if sx * sy * sz > 0:
								points.append(Vector3(perm.x * sx, perm.y * sy, perm.z * sz) * .1)
			return hull(points)
	return null

## The convex hull of a few points as triangles (each supporting plane's points ordered round it and fanned).
static func hull(points: PackedVector3Array) -> ArrayMesh:
	var faces := {}
	var n := points.size()
	for i in n:
		for j in range(i + 1, n):
			for k in range(j + 1, n):
				var normal := (points[j] - points[i]).cross(points[k] - points[i])
				if normal.length() < 1e-6:
					continue
				normal = normal.normalized()
				var d := normal.dot(points[i])
				var above := 0
				var below := 0
				for p in points:
					var s := normal.dot(p) - d
					if s > 1e-5: above += 1
					elif s < -1e-5: below += 1
				if above > 0 and below > 0:
					continue
				if above > 0:
					normal = -normal;d = -d
				var key := str(normal.snapped(Vector3.ONE * .001))
				if faces.has(key):
					continue
				var on: Array = []
				for p in points:
					if absf(normal.dot(p) - d) < 1e-5: on.append(p)
				faces[key] = [normal, on]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for key in faces:
		var normal: Vector3 = faces[key][0]
		var ring: Array = faces[key][1]
		var centre := Vector3.ZERO
		for p in ring: centre += p
		centre /= ring.size()
		var u: Vector3 = (ring[0] - centre).normalized()
		var w := normal.cross(u)
		ring.sort_custom(func(a, b): return atan2(w.dot(a - centre), u.dot(a - centre)) < atan2(w.dot(b - centre), u.dot(b - centre)))
		for t in range(1, ring.size() - 1):
			for p in [ring[0], ring[t], ring[t + 1]]:
				st.set_normal(normal);st.add_vertex(p)
	return st.commit()

## The finish on every solid mesh under node; returns how many took it.
static func apply(node: Node, finish: Material) -> int:
	var count := 0
	if node is SubViewport:
		return 0
	if node is GeometryInstance3D and (node is MeshInstance3D or node is MultiMeshInstance3D) and _takes_finish(node):
		node.material_override = finish
		count += 1
	for child in node.get_children():
		count += apply(child, finish)
	return count

static func _takes_finish(node: GeometryInstance3D) -> bool:
	var lowered := str(node.name).to_lower()
	for word in SKIP_WORDS:
		if lowered.contains(word):
			return false
	var mesh: Mesh = node.mesh if node is MeshInstance3D else (node.multimesh.mesh if node.multimesh != null else null)
	if mesh == null:
		return false
	var material: Material = node.material_override
	if material == null and node is MeshInstance3D and mesh.get_surface_count() > 0:
		material = node.get_active_material(0)
	if material is BaseMaterial3D:
		var base := material as BaseMaterial3D
		if base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or base.albedo_color.a < .99:
			return false
	return true

## The exhibit's largest solid mesh, rebuilt as a hall study standing on the floor under the mount.
static func study(mount: Node3D, artifact: Node3D, title: String, exact: Mesh = null) -> void:
	var mesh: Mesh = exact
	if mesh == null:
		var best := -1.0
		for visual in artifact.find_children("*", "MeshInstance3D", true, false):
			var m := visual as MeshInstance3D
			if m.mesh == null or not _takes_finish(m):
				continue
			var size := m.get_aabb().size.length()
			if size > best:
				best = size;mesh = m.mesh
	if mesh == null:
		push_warning("primitive_finish: no solid mesh to study in " + str(mount.name))
		return
	artifact.hide()
	var group := Node3D.new();group.name = "PlatonicStudy"
	group.position.y = -mount.position.y   # the plinth stands on the floor, whatever height the placement has
	mount.add_child(group)
	Kit.pedestal(group, Vector3.ZERO, .88, 1.12)
	var body := Kit.pickable_mesh(group, mesh, Vector3(0, .885, 0), Kit.WHITE, .88)
	body.name = "Solid";body.set_meta("solid_type", title)
	var study_node := PlatonicStudy.new();study_node.name = "Study";group.add_child(study_node)
	study_node.setup(body)
