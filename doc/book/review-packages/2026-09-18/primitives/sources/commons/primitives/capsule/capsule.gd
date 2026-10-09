extends Node3D

# @identity
# essence: the capsule primitive's DNA head — a thin root over the authored CapsuleMesh in capsule.tscn that restates the same body in one of five states of making, without moving it, rescaling it or stopping it turning
# desire: to let the first solid a learner meets be met FIVE ways, so that "what a capsule is" is asked before "what a capsule is for"
# critical_parameter: facture — which state of making the body is shown in; every other number in the scene (radius 0.25, height 1.0, 5 radial segments, 5 rings, the olive albedo, the 45 deg/s spin) is the legacy scene and is never written to
# triggers: _ready() reads facture, returns immediately on the default, and otherwise rebuilds the child MeshInstance3D's mesh and material_override from the authored CapsuleMesh's own arrays
# emerges: the recognition that a capsule is not a shape but a cylinder that had to be capped — and that whether you see it as poured, as counted, as wired, as sawn or as handled is a decision somebody made, not a property the solid has
# needs: the authored capsule.tscn child MeshInstance3D named "capsule" [present]; CapsuleMesh.get_mesh_arrays() [present]; a still-legible wire gauge [present, tubes not lines]
# relationships: the body half of the primitives tier — [[platonic_grabbables]] is the claim that form can be perfect, this is the claim that it cannot; shares the facture vocabulary with [[folded_strip]] and [[triangleprofiles]], which ask it of a surface instead of a solid
# truth: a capsule is a cylinder that had to be capped so nothing would be sharp. It is the primitive of the compromise — and the five ways of showing it are five answers to whether geometry was found or built.

## AXIS — WHAT STATE OF MAKING THE BODY IS SHOWN IN. The solid never changes: same radius,
## same height, same 5 x 5 tessellation, same spin. What changes is how much of its own
## construction it admits. This is the first argument a primitive can make, and it is made
## before a learner has met any other: a platonic solid is the claim that form can be
## perfect, and a capsule is the claim that it cannot — it is a cylinder that had to be
## capped so nothing would be sharp.
##
##   cast      poured — one matte skin, normals averaged, no seam and no count. The form
##             as given. This is the legacy scene, byte for byte.
##   facet     counted — every triangle its own flat plane, alternate bands a shade
##             darker. The five segments and five rings become things you can point at.
##   armature  wired — the skin gone, the edge graph left standing as tubes. What holds
##             the shape up, with nothing draped over it.
##   section   sawn — the body cut on a horizontal plane through its middle, the upper
##             half removed and the cut plane drawn solid in the drawing convention. Half
##             a body reads as a body somebody opened.
##   wear      handled — the vertices dented inward by a fixed hash of their own position,
##             the skin darkened and roughened. The ideal put through use.
##
## The cut is horizontal ON PURPOSE. The child MeshInstance3D carries rotation.gd and turns
## 45 deg/s about Y; a vertical cut would face the camera at one yaw and away at another,
## and the sweep would be measuring what time it was rather than what the value says. A
## plane perpendicular to the spin axis looks identical at every yaw.
@export var facture: String = "cast"
const FACTURES: PackedStringArray = ["cast", "facet", "armature", "section", "wear"]

## The MeshInstance3D authored in capsule.tscn — it owns the CapsuleMesh and the spin.
const BODY_NODE := "capsule"
## Wire gauge for `armature`, in metres, against a 0.25 m radius. A PRIMITIVE_LINES wire is
## one pixel wide and disappears when a capture is downscaled; an axis that disappears
## measures the same as an axis that does nothing, so the edges are tubes.
const WIRE_RADIUS := 0.008
## Fallback albedo if the scene's material override is ever replaced by something that is
## not a StandardMaterial3D. Matches the authored olive.
const FALLBACK_ALBEDO := Color(0.5176471, 0.5254902, 0.47843137, 1.0)


func _ready() -> void:
	var f: String = str(facture).strip_edges().to_lower()
	facture = f if FACTURES.has(f) else "cast"

	# THE LEGACY PATH. "cast" is the scene exactly as it was authored — this script does
	# not read the mesh, does not touch the material, does not add a node. Nothing below
	# runs. That is the whole of the strictly-additive guarantee.
	if facture == "cast":
		return

	var mi: MeshInstance3D = get_node_or_null(BODY_NODE) as MeshInstance3D
	if mi == null:
		return
	var src: CapsuleMesh = mi.mesh as CapsuleMesh
	if src == null:
		return

	match facture:
		"facet":
			_facet(mi, src)
		"armature":
			_armature(mi, src)
		"section":
			_section(mi, src)
		"wear":
			_wear(mi, src)
		_:
			pass


# ── FACTURE ──────────────────────────────────────────────────────────────────

## COUNTED. The same triangles, but each one flat and each alternate one a shade darker,
## so radial_segments and rings stop being numbers in an inspector and become bands.
func _facet(mi: MeshInstance3D, src: CapsuleMesh) -> void:
	var tris: Array = _triangles(src)
	var base: Color = _albedo(mi)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var face: int = 0
	for t in tris:
		var tone: float = 0.72 if (face % 2) == 0 else 1.0
		_tri(st, t[0], t[1], t[2], Color(base.r * tone, base.g * tone, base.b * tone, 1.0))
		face += 1
	mi.mesh = st.commit()
	mi.material_override = _vertex_mat(false)


## WIRED. Every edge of the tessellation once, as a thin three-sided tube. The skin is not
## hidden — it is not built at all, so there is no VisualInstance3D left holding a subtree.
func _armature(mi: MeshInstance3D, src: CapsuleMesh) -> void:
	var arrays: Array = src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var base: Color = _albedo(mi)
	var wire: Color = Color(base.r, base.g, base.b, 1.0).lightened(0.35)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seen: Dictionary = {}
	var i: int = 0
	while i + 2 < idx.size():
		var ia: int = idx[i]
		var ib: int = idx[i + 1]
		var ic: int = idx[i + 2]
		for pair in [[ia, ib], [ib, ic], [ic, ia]]:
			var a: Vector3 = verts[int(pair[0])]
			var b: Vector3 = verts[int(pair[1])]
			var key: String = _edge_key(a, b)
			if seen.has(key):
				continue
			seen[key] = true
			_tube(st, a, b, WIRE_RADIUS, wire)
		i += 3
	mi.mesh = st.commit()
	mi.material_override = _vertex_mat(true)


## SAWN. Triangles whose centre sits above the equator are dropped and the cut plane is
## drawn as a solid disc — the technical-drawing convention, where a section is a filled
## face and not an absence.
func _section(mi: MeshInstance3D, src: CapsuleMesh) -> void:
	var tris: Array = _triangles(src)
	var base: Color = _albedo(mi)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tris:
		var a: Vector3 = t[0]
		var b: Vector3 = t[1]
		var c: Vector3 = t[2]
		if (a.y + b.y + c.y) / 3.0 > 0.0:
			continue
		_tri(st, a, b, c, base)
	# The cut face, one shade off the body so the plane reads as a plane and not as more skin.
	var cut: Color = base.lightened(0.42)
	var r: float = maxf(src.radius, 0.001)
	var seg: int = 28
	for k in range(seg):
		var t0: float = TAU * float(k) / float(seg)
		var t1: float = TAU * float(k + 1) / float(seg)
		_tri(st,
			Vector3.ZERO,
			Vector3(r * cos(t1), 0.0, r * sin(t1)),
			Vector3(r * cos(t0), 0.0, r * sin(t0)),
			cut)
	mi.mesh = st.commit()
	mi.material_override = _vertex_mat(false)


## HANDLED. Each vertex pushed in along its own normal by a fixed hash of its QUANTISED
## POSITION — never randf(), and keyed on position rather than index so the UV seam's
## duplicated vertices dent by the same amount and the shell does not split open. The
## same boot, the same machine, the same dent: the sweep measures the axis, not noise.
func _wear(mi: MeshInstance3D, src: CapsuleMesh) -> void:
	var arrays: Array = src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms := PackedVector3Array()
	if arrays[Mesh.ARRAY_NORMAL] != null:
		norms = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var r: float = maxf(src.radius, 0.001)
	var worn: PackedVector3Array = PackedVector3Array()
	worn.resize(verts.size())
	for k in range(verts.size()):
		var v: Vector3 = verts[k]
		var n: Vector3 = norms[k] if k < norms.size() else v.normalized()
		var h: float = _pos_hash(v)
		var dent: float = r * 0.20 * h
		if h > 0.82:
			dent = r * 0.44                          # a chip, not a scuff
		worn[k] = v - n * dent
	var base: Color = _albedo(mi)
	var dull: Color = Color(base.r, base.g, base.b, 1.0).darkened(0.28)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var i: int = 0
	while i + 2 < idx.size():
		var a: Vector3 = worn[idx[i]]
		var b: Vector3 = worn[idx[i + 1]]
		var c: Vector3 = worn[idx[i + 2]]
		# Grime pools where the dent is deepest, so the damage reads as history.
		var d: float = _pos_hash((a + b + c) / 3.0)
		var tone: float = 0.78 + 0.22 * d
		_tri(st, a, b, c, Color(dull.r * tone, dull.g * tone, dull.b * tone, 1.0))
		i += 3
	mi.mesh = st.commit()
	var mat: StandardMaterial3D = _vertex_mat(false)
	mat.roughness = 1.0
	mi.material_override = mat


# ── Local helpers ─────────────────────────────────────────────────────────────

## The authored mesh's triangles as [a, b, c] triples, in the mesh's own order.
func _triangles(src: CapsuleMesh) -> Array:
	var arrays: Array = src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var out: Array = []
	if idx.is_empty():
		var j: int = 0
		while j + 2 < verts.size():
			out.append([verts[j], verts[j + 1], verts[j + 2]])
			j += 3
		return out
	var i: int = 0
	while i + 2 < idx.size():
		out.append([verts[idx[i]], verts[idx[i + 1]], verts[idx[i + 2]]])
		i += 3
	return out


func _albedo(mi: MeshInstance3D) -> Color:
	var m: StandardMaterial3D = mi.material_override as StandardMaterial3D
	if m != null:
		return m.albedo_color
	return FALLBACK_ALBEDO


func _vertex_mat(unshaded: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.82
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(a)
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(b)
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(c)


func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, col: Color) -> void:
	_tri(st, p0, p1, p2, col)
	_tri(st, p0, p2, p3, col)


func _tube(st: SurfaceTool, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var d: Vector3 = b - a
	if d.length_squared() < 0.0000001:
		return
	var n: Vector3 = d.normalized()
	var seed_up: Vector3 = Vector3.UP
	if absf(n.dot(Vector3.UP)) > 0.9:
		seed_up = Vector3.RIGHT
	var u: Vector3 = n.cross(seed_up).normalized() * r
	var v: Vector3 = n.cross(u).normalized() * r
	var off: Array = []
	for k in range(3):
		var ang: float = TAU * float(k) / 3.0
		off.append(u * cos(ang) + v * sin(ang))
	for k in range(3):
		var o0: Vector3 = off[k]
		var o1: Vector3 = off[(k + 1) % 3]
		_quad(st, a + o0, a + o1, b + o1, b + o0, col)


func _edge_key(a: Vector3, b: Vector3) -> String:
	var ka: String = "%.4f_%.4f_%.4f" % [a.x, a.y, a.z]
	var kb: String = "%.4f_%.4f_%.4f" % [b.x, b.y, b.z]
	if ka < kb:
		return ka + "|" + kb
	return kb + "|" + ka


## Deterministic 0..1 from a QUANTISED position. Quantised so vertices duplicated at the
## UV seam hash identically and the wear does not tear the shell along it.
func _pos_hash(v: Vector3) -> float:
	var qx: float = float(int(round(v.x * 500.0)))
	var qy: float = float(int(round(v.y * 500.0)))
	var qz: float = float(int(round(v.z * 500.0)))
	var s: float = sin(qx * 12.9898 + qy * 78.233 + qz * 37.719) * 43758.5453
	return s - floor(s)
