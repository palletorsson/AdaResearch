extends Node3D

# @identity
# essence: the root of the Melencolia I tableau — Dürer's truncated rhombohedron, the polished sphere, the 4x4 magic square, the compass, the ladder, the hourglass, the bell and the scales, lit by one warm key and two cold fills. Until now this root carried NO script, so the map token `durer_scene` could place the tableau but could not say anything to it.
# desire: to let the scene answer the question the engraving itself asks — whether an instrument shows you a finished world or shows you the machinery that made the world showable.
# critical_parameter: apparatus — finish / cage / block / veil. Which of its own construction the tableau is willing to admit.
# triggers: _ready reads the axis and dresses the tableau; apply_grid_config strips the previous dressing, restores every prop's own material and render layers, and dresses again.
# emerges: that "geometry" and "a picture of geometry" are not the same object, and the difference is a decision someone made about what to leave in.
# relationships: root of [[durer_scene]]; the solid itself is [[DurerPolyhedron]]; the square is [[MagicSquare]]; a cousin of the perspective machines in the coordinate-systems maps.
# truth: Dürer's engraving is a heap of instruments no one is using. The instruments are the subject. Melancholy is what measurement looks like when it stops being able to hide the measuring.

## Albrecht Dürer, Melencolia I (1514) — the tableau root.
##
## The props are authored in DurerScene.tscn and this script never rebuilds them; it
## only dresses (or undresses) what the scene already contains. `finish` touches
## nothing at all, so the legacy tableau is reproduced byte for byte.

# ── DNA ───────────────────────────────────────────────────────────────
## AXIS — HOW MUCH OF ITS OWN MAKING THE TABLEAU ADMITS. Dürer wrote the
## Underweysung der Messung so that a craftsman could BUILD a solid rather than
## admire one: nets to cut out, boxes to project through, a gridded veil to draw
## across. Melencolia I is the other half of that argument — the same instruments,
## put down, in a picture that shows only surfaces. This axis walks between them.
##
##   finish   the legacy lineage, byte for byte. Stone, brass, wood, glass. Eight
##            finished objects in a lit room and no evidence whatever of how any of
##            them came to be. The engraving's own claim.
##   cage     every prop is repainted near-black and overlaid with its own triangle
##            edges: the whole tableau as a pale line drawing. The bodies stay in the
##            depth buffer so the drawing gets hidden-line removal and a sphere reads
##            as a sphere. Solid becomes a triangulation and admits it. The heaviest
##            change in the set — the room keeps its lights and loses its surfaces.
##   block    the draughtsman's blocking-in. Every prop is repainted flat construction
##            grey and enclosed in a wireframe crate on its own local bounds — Dürer's
##            method of putting a form inside a box before projecting it. The shapes
##            are still there; the SURFACES have been withdrawn until the drawing is
##            underway.
##   veil     the apparatus arrives. A framed grid of taut threads — Alberti's velo,
##            the machine Dürer engraved a draughtsman working behind — stands upright
##            through the tableau, with a sighting post at eye height and sight-lines
##            running from the eyepoint through the veil to the corners of the solid.
##            Nothing is taken away; the machine that makes a picture possible is
##            simply put back in the picture.
##
## The bodies are the pivot. `cage` and `block` both act on all eight props at once
## (a single prop is far too small a fraction of a ten-metre tableau to be measurable),
## and `veil` answers them by adding rather than subtracting.
@export_enum("finish", "cage", "block", "veil") var apparatus: String = "finish"
const APPARATUS: PackedStringArray = ["finish", "cage", "block", "veil"]

# ── Constants ─────────────────────────────────────────────────────────
const DRESS_PREFIX := "Apparatus_"          # every node this script adds is named with it
const WIRE_INDEX_CAP := 40000               # don't wire a pathological mesh
const CRATE_BAR := 0.035                    # section of a construction-crate edge (m)

# Where the veil stands. The tableau's own camera looks down −Z from (1, 2, 5), and
# the sweep camera is also parked on +Z, so this plane faces the viewer square on.
const VEIL_CENTER := Vector3(-0.4, 2.05, 1.55)
const VEIL_SIZE := Vector2(3.4, 3.2)
const VEIL_DIVISIONS := 8
const EYEPOINT := Vector3(1.05, 2.05, 4.30)

# ── State ─────────────────────────────────────────────────────────────
var _props: Array[NodePath] = []
var _orig_mat: Dictionary = {}              # NodePath -> Material (may be null)
var _orig_layers: Dictionary = {}           # NodePath -> int
var _captured := false


# ── Lifecycle ─────────────────────────────────────────────────────────
func _ready() -> void:
	_capture_props()
	_read_metadata_overrides()
	_dress()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_capture_props()
	_read_metadata_overrides()
	_undress()
	_dress()


func _read_metadata_overrides() -> void:
	if has_meta("config_apparatus"):
		# Normalising read — an unknown word keeps the default rather than stripping
		# the tableau, so a typo in a map token can never publish a bare room.
		var _a: String = str(get_meta("config_apparatus")).strip_edges().to_lower()
		apparatus = _a if APPARATUS.has(_a) else apparatus


# ── Prop bookkeeping ──────────────────────────────────────────────────
# The eight props are authored in the .tscn. Record what they looked like BEFORE
# anything is dressed, so any value can be swapped for any other at runtime and the
# tableau returns to the engraving exactly.
func _capture_props() -> void:
	if _captured:
		return
	_captured = true
	for n in _walk(self):
		if not (n is GeometryInstance3D):
			continue
		if n is Light3D:
			continue
		if String(n.name).begins_with(DRESS_PREFIX):
			continue
		var gi := n as GeometryInstance3D
		var p: NodePath = get_path_to(gi)
		_props.append(p)
		_orig_mat[p] = gi.material_override
		_orig_layers[p] = gi.layers


func _undress() -> void:
	for p in _props:
		var gi := get_node_or_null(p) as GeometryInstance3D
		if gi == null:
			continue
		gi.material_override = _orig_mat.get(p, null)
		gi.layers = int(_orig_layers.get(p, 1))
	for n in _walk(self):
		if n == self or not String(n.name).begins_with(DRESS_PREFIX):
			continue
		var parent: Node = n.get_parent()
		if parent == null:
			continue
		# Only detach the TOP of each dressing: a bar inside a crate goes with its
		# crate, and touching it after the crate is already queued would be a
		# use-after-free on a stale snapshot.
		if String(parent.name).begins_with(DRESS_PREFIX):
			continue
		parent.remove_child(n)
		n.queue_free()


func _dress() -> void:
	match apparatus:
		"cage":
			_dress_cage()
		"block":
			_dress_block()
		"veil":
			_dress_veil()
		_:
			pass                              # "finish" — the legacy lineage


# ── CAGE ──────────────────────────────────────────────────────────────
## The surfaces go. Every prop is repainted a near-black matte and its own triangle
## edges are laid over it, in its own local space, as a child that inherits its
## transform. The body stays in the depth buffer on purpose — that is what gives the
## drawing hidden-line removal, so a sphere reads as a sphere of lines instead of a
## ball of mush with all its back faces showing through. What is left is the tableau
## as a wire drawing: still lit, still composed, no longer pretending to be stone.
##
## The wire child is scaled 1.004 about its mesh's own centre so the lines sit just
## outside the surface. Without that offset every edge z-fights with the face it
## belongs to and the whole drawing shimmers.
func _dress_cage() -> void:
	var wire_mat := _line_material(Color(0.80, 0.85, 0.96))
	var soot := StandardMaterial3D.new()
	soot.albedo_color = Color(0.045, 0.048, 0.058)
	soot.roughness = 0.95
	soot.metallic = 0.0

	for p in _props:
		var gi := get_node_or_null(p) as GeometryInstance3D
		if gi == null:
			continue
		var src: Mesh = null
		if gi is MeshInstance3D:
			src = (gi as MeshInstance3D).mesh
		var pivot: Vector3 = Vector3.ZERO
		var wire: Mesh = null
		if src != null:
			wire = _edge_mesh(src, wire_mat)
			pivot = src.get_aabb().get_center()
		else:
			var box: AABB = gi.get_aabb()
			wire = _box_edge_mesh(box, wire_mat)
			pivot = box.get_center()
		gi.material_override = soot
		if wire == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = DRESS_PREFIX + "Wire"
		mi.mesh = wire
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var k: float = 1.004
		mi.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * k), pivot - pivot * k)
		gi.add_child(mi)


# ── BLOCK ─────────────────────────────────────────────────────────────
## The blocking-in. Bodies stay, but every one of them is repainted the same flat
## construction grey — brass, stone, wood and glass all withdrawn at once — and a
## wireframe crate is built on its local bounds out of thin solid bars, so the crate
## survives at tableau distance where a one-pixel line would not.
func _dress_block() -> void:
	var clay := StandardMaterial3D.new()
	clay.albedo_color = Color(0.52, 0.51, 0.49)
	clay.roughness = 0.92
	clay.metallic = 0.0
	var bar_mat := StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.92, 0.62, 0.24)
	bar_mat.roughness = 0.5
	bar_mat.emission_enabled = true
	bar_mat.emission = Color(0.92, 0.62, 0.24)
	bar_mat.emission_energy_multiplier = 0.45

	for p in _props:
		var gi := get_node_or_null(p) as GeometryInstance3D
		if gi == null:
			continue
		gi.material_override = clay
		var crate := _crate(gi.get_aabb(), bar_mat)
		if crate:
			gi.add_child(crate)


## Twelve thin bars on the edges of `box` — the perspective crate a form is drawn
## inside before it is projected.
func _crate(box: AABB, mat: Material) -> Node3D:
	if box.size.length() < 0.0001:
		return null
	var root := Node3D.new()
	root.name = DRESS_PREFIX + "Crate"
	var lo: Vector3 = box.position
	var hi: Vector3 = box.position + box.size
	var t: float = CRATE_BAR
	var xs: Array[float] = [lo.x, hi.x]
	var ys: Array[float] = [lo.y, hi.y]
	var zs: Array[float] = [lo.z, hi.z]
	# 4 bars along X, 4 along Y, 4 along Z.
	for yy in ys:
		for zz in zs:
			root.add_child(_bar(Vector3((lo.x + hi.x) * 0.5, yy, zz),
				Vector3(box.size.x, t, t), mat))
	for xx in xs:
		for zz in zs:
			root.add_child(_bar(Vector3(xx, (lo.y + hi.y) * 0.5, zz),
				Vector3(t, box.size.y, t), mat))
	for xx in xs:
		for yy in ys:
			root.add_child(_bar(Vector3(xx, yy, (lo.z + hi.z) * 0.5),
				Vector3(t, t, box.size.z), mat))
	return root


# ── VEIL ──────────────────────────────────────────────────────────────
## Alberti's velo, the gridded screen Dürer engraved a draughtsman working behind: a
## heavy frame strung with taut threads, standing upright through the tableau, with a
## sighting post marking the fixed eye and sight-lines running from that eye through
## the veil to the corners of the solid. This value takes nothing away — it puts the
## machine that makes a picture possible back into the picture.
func _dress_veil() -> void:
	var root := Node3D.new()
	root.name = DRESS_PREFIX + "Veil"
	root.position = VEIL_CENTER
	add_child(root)

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.42, 0.30, 0.18)
	frame_mat.roughness = 0.75
	var thread_mat := StandardMaterial3D.new()
	thread_mat.albedo_color = Color(0.95, 0.90, 0.74)
	thread_mat.roughness = 0.6
	thread_mat.emission_enabled = true
	thread_mat.emission = Color(0.95, 0.90, 0.74)
	thread_mat.emission_energy_multiplier = 0.55

	var w: float = VEIL_SIZE.x
	var h: float = VEIL_SIZE.y
	var post: float = 0.10

	# Frame: two stiles, two rails.
	root.add_child(_bar(Vector3(-w * 0.5, 0.0, 0.0), Vector3(post, h + post, post), frame_mat))
	root.add_child(_bar(Vector3(w * 0.5, 0.0, 0.0), Vector3(post, h + post, post), frame_mat))
	root.add_child(_bar(Vector3(0.0, h * 0.5, 0.0), Vector3(w + post, post, post), frame_mat))
	root.add_child(_bar(Vector3(0.0, -h * 0.5, 0.0), Vector3(w + post, post, post), frame_mat))

	# Threads.
	var n: int = VEIL_DIVISIONS
	for i in range(1, n):
		var f: float = float(i) / float(n)
		root.add_child(_bar(Vector3(0.0, -h * 0.5 + h * f, 0.0),
			Vector3(w, 0.028, 0.020), thread_mat))
		root.add_child(_bar(Vector3(-w * 0.5 + w * f, 0.0, 0.0),
			Vector3(0.028, h, 0.020), thread_mat))

	# The pane between the threads — a barely-there wash, so the veil reads as a
	# SURFACE the picture is caught on and not as a bare grid of sticks.
	var pane := MeshInstance3D.new()
	pane.name = DRESS_PREFIX + "Pane"
	var pane_mesh := QuadMesh.new()
	pane_mesh.size = Vector2(w, h)
	pane.mesh = pane_mesh
	var pane_mat := StandardMaterial3D.new()
	pane_mat.albedo_color = Color(0.72, 0.80, 0.92, 0.14)
	pane_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pane_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane_mat.emission_enabled = true
	pane_mat.emission = Color(0.55, 0.66, 0.85)
	pane_mat.emission_energy_multiplier = 0.30
	pane.material_override = pane_mat
	pane.position = Vector3(0.0, 0.0, -0.012)
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(pane)

	# The sighting post — the fixed eye the whole construction depends on.
	var eye := Node3D.new()
	eye.name = DRESS_PREFIX + "Eyepoint"
	eye.position = EYEPOINT
	add_child(eye)
	eye.add_child(_bar(Vector3(0.0, -0.62, 0.0), Vector3(0.09, 1.24, 0.09), frame_mat))
	var sight_mat := _line_material(Color(0.98, 0.86, 0.42))
	var knob := MeshInstance3D.new()
	knob.name = DRESS_PREFIX + "EyeKnob"
	var knob_mesh := SphereMesh.new()
	knob_mesh.radius = 0.07
	knob_mesh.height = 0.14
	knob.mesh = knob_mesh
	knob.material_override = sight_mat
	eye.add_child(knob)

	# Sight-lines from the eye to the corners of the solid, passing through the veil.
	var solid := get_node_or_null("Polyhedron") as GeometryInstance3D
	if solid == null:
		return
	var box: AABB = solid.get_aabb()
	var lines := Node3D.new()
	lines.name = DRESS_PREFIX + "Sightlines"
	add_child(lines)
	for i in range(8):
		var corner: Vector3 = solid.global_transform * (box.position + Vector3(
			box.size.x * float(i & 1),
			box.size.y * float((i >> 1) & 1),
			box.size.z * float((i >> 2) & 1)))
		var th: MeshInstance3D = _thread(EYEPOINT, corner, 0.016, sight_mat)
		if th:
			lines.add_child(th)


# ── Helpers ───────────────────────────────────────────────────────────
func _bar(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = DRESS_PREFIX + "Bar"
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A taut solid thread between two points — a box, not a PRIMITIVE_LINE, because a
## one-pixel line is invisible at the distance this tableau is framed from.
func _thread(from: Vector3, to: Vector3, thickness: float, mat: Material) -> MeshInstance3D:
	var v: Vector3 = to - from
	var d: float = v.length()
	if d < 0.001:
		return null
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thickness, thickness, d)
	var mi := MeshInstance3D.new()
	mi.name = DRESS_PREFIX + "Thread"
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Basis built by hand: look_at() reads global_transform and this node is not in
	# the tree yet, so calling it here would warn and leave the thread unaimed.
	var dir: Vector3 = v / d
	var up_ref: Vector3 = Vector3.UP
	if absf(dir.dot(up_ref)) > 0.99:
		up_ref = Vector3.RIGHT
	var zax: Vector3 = dir
	var xax: Vector3 = up_ref.cross(zax).normalized()
	if xax.length_squared() < 0.0001:
		xax = Vector3.FORWARD.cross(zax).normalized()
	var yax: Vector3 = zax.cross(xax).normalized()
	mi.transform = Transform3D(Basis(xax, yax, zax), from + v * 0.5)
	return mi


func _line_material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 0.8
	mat.disable_receive_shadows = true
	return mat


## Every triangle edge of `src` as a line mesh in the mesh's own local space.
func _edge_mesh(src: Mesh, mat: Material) -> Mesh:
	if src == null:
		return null
	var im := ImmediateMesh.new()
	var wrote := false
	for si in range(src.get_surface_count()):
		var arrays: Array = src.surface_get_arrays(si)
		if arrays.is_empty():
			continue
		var raw_verts: Variant = arrays[Mesh.ARRAY_VERTEX]
		if not (raw_verts is PackedVector3Array):
			continue
		var verts: PackedVector3Array = raw_verts
		if verts.size() < 3:
			continue
		var idx := PackedInt32Array()
		var raw_idx: Variant = arrays[Mesh.ARRAY_INDEX]
		if raw_idx is PackedInt32Array:
			idx = raw_idx
		if idx.is_empty():
			# An unindexed surface: the vertices are already triangle soup.
			idx = PackedInt32Array(range(verts.size()))
		if idx.size() > WIRE_INDEX_CAP:
			continue
		if not wrote:
			im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
			wrote = true
		var tri: int = idx.size() - (idx.size() % 3)
		for i in range(0, tri, 3):
			var a: Vector3 = verts[idx[i]]
			var b: Vector3 = verts[idx[i + 1]]
			var c: Vector3 = verts[idx[i + 2]]
			im.surface_add_vertex(a); im.surface_add_vertex(b)
			im.surface_add_vertex(b); im.surface_add_vertex(c)
			im.surface_add_vertex(c); im.surface_add_vertex(a)
	if not wrote:
		return null
	im.surface_end()
	return im


## Fallback wire for a prop with no readable mesh (the CSG hourglass frame, the
## scale strings): the twelve edges of its bounding box.
func _box_edge_mesh(box: AABB, mat: Material) -> Mesh:
	if box.size.length() < 0.0001:
		return null
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	var c: Array = []
	for i in range(8):
		c.append(box.position + Vector3(
			box.size.x * float(i & 1),
			box.size.y * float((i >> 1) & 1),
			box.size.z * float((i >> 2) & 1)))
	var edges: Array = [[0,1],[2,3],[4,5],[6,7],[0,2],[1,3],[4,6],[5,7],[0,4],[1,5],[2,6],[3,7]]
	for e in edges:
		im.surface_add_vertex(c[e[0]])
		im.surface_add_vertex(c[e[1]])
	im.surface_end()
	return im


func _walk(node: Node) -> Array:
	var out: Array = [node]
	for ch in node.get_children():
		out.append_array(_walk(ch))
	return out
