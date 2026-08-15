extends Node3D
class_name FrequencyShell

## frequency_shell — a dome gets rounder and less buildable at the same time.
##
## THE FAMILY. Five artifacts share the axis `subdivision` with the values v1 v2 v3 v4:
## dome_builder, geodesic_dome, icosahedron_base, strut_inventory, subdivision_demo. Every one
## of them treats the number as a quality setting — turn it up, get a better sphere. None of
## them shows what it costs, and strut_inventory is in the family, which means the corpus has
## an artifact whose entire subject is the parts list and still nobody put the two together.
##
## THE ARGUMENT. A geodesic sphere at frequency v is an icosahedron whose twenty faces have
## each been cut into v^2 triangles and pushed out onto the sphere. Two things happen at once
## and they pull in opposite directions:
##
##   the SHAPE converges   — v1 is visibly a solid, v4 is visibly a ball, and past that the
##                           eye cannot tell. The gain per step collapses.
##   the PARTS diverge     — the edges do NOT come out equal. Pushing a flat triangle onto a
##                           sphere stretches its edges by different amounts depending where
##                           they sit, so a real dome needs several DISTINCT strut lengths,
##                           and the count of distinct lengths climbs with frequency.
##
## So "more subdivision" buys roundness and is paid for in part numbers. That is a claim the
## family's own five members each half-state and none of them puts on one bench.
##
## THE BODY, NOT A GAUGE. This does not draw a chart of strut counts against frequency. It
## builds the four domes and, in the `inventory` reading, lays each dome's distinct strut
## lengths out as actual struts of those actual lengths, sorted, in a row underneath it. The
## bar chart is banned; the parts list is made of parts.

## How finely each icosahedral face is cut. The four values are the family's own — dome_builder,
## geodesic_dome, icosahedron_base, strut_inventory and subdivision_demo all declare v1..v4.
@export_enum("v1", "v2", "v3", "v4") var frequency: String = "v3":
	set(v):
		frequency = v
		if is_inside_tree():
			_rebuild()

## What is drawn of each dome.
##   shell     — the triangulated surface. The reading that makes the convergence obvious.
##   struts    — the edges only, as rods. What a builder actually orders.
##   inventory — struts, plus every DISTINCT strut length laid out below as a sorted row of


##               real struts. strut_inventory's subject, given the whole ladder to stand in.
@export_enum("shell", "struts", "inventory") var reading: String = "shell":
	set(v):
		reading = v
		if is_inside_tree():
			_rebuild()


## Whether the rungs stand together or one at a time. THIS IS NOT PART OF THE AXIS, and
## separating it cost a sweep to learn: with "ladder" declared as a value of the ladder axis
## itself, capture_config_sweep unioned the AABB of the all-rungs view with every single-rung
## view, framed the singles against a row five times their width, and photographed them as
## specks — the critic then crashed on a subject box too small to sample. A layout is not a
## rung. The sweep pins this to `single` through dna.fixture; the artifact still stands as the
## whole comparison by default, which is what it is for.
@export_enum("ladder", "single") var layout: String = "ladder":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

@export var radius: float = 0.42
@export var spacing: float = 1.15

const GOLD := 1.618033988749895
## Two edge lengths count as the same strut if they agree to this, in metres, at radius 1.
## A real dome shop works to millimetres; this is deliberately coarser than the differences
## the sphere actually produces, so the count it reports is a floor and not an artefact of
## floating point.
const STRUT_TOL := 0.002

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("frequency"):
		frequency = str(config_data["frequency"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	if config_data.has("radius"):
		radius = float(config_data["radius"])
	_rebuild()


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var freqs: Array = [1, 2, 3, 4] if layout == "ladder" else [int(frequency.substr(1))]
	var n: int = freqs.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = "v%d" % freqs[i]
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * spacing, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_dome(holder, int(freqs[i]))


## One dome at frequency f, in whichever reading is set.
func _build_dome(holder: Node3D, f: int) -> void:
	var tris: Array = _geodesic(f)
	if reading == "shell":
		_add_shell(holder, tris)
	else:
		var edges: Dictionary = _edges_of(tris)
		_add_struts(holder, edges)
		if reading == "inventory":
			_add_inventory(holder, edges)


## The triangles of a frequency-f geodesic sphere, as arrays of three unit vectors.
func _geodesic(f: int) -> Array:
	var base: Array = _icosahedron()
	var out: Array = []
	for t in base:
		var a: Vector3 = t[0]
		var b: Vector3 = t[1]
		var c: Vector3 = t[2]
		# Cut the face into f^2 small triangles in barycentric steps, then push each corner
		# onto the sphere. Subdividing THEN normalising is what makes the edges unequal — it
		# is the whole reason a parts list exists.
		for i in range(f):
			for j in range(f - i):
				var p1: Vector3 = _bary(a, b, c, i, j, f)
				var p2: Vector3 = _bary(a, b, c, i + 1, j, f)
				var p3: Vector3 = _bary(a, b, c, i, j + 1, f)
				out.append([p1, p2, p3])
				if j < f - i - 1:
					var p4: Vector3 = _bary(a, b, c, i + 1, j + 1, f)
					out.append([p2, p4, p3])
	return out


func _bary(a: Vector3, b: Vector3, c: Vector3, i: int, j: int, f: int) -> Vector3:
	var u := float(i) / float(f)
	var v := float(j) / float(f)
	return (a * (1.0 - u - v) + b * u + c * v).normalized()


func _icosahedron() -> Array:
	var v: Array = []
	for s1 in [-1.0, 1.0]:
		for s2 in [-GOLD, GOLD]:
			v.append(Vector3(0, s1, s2).normalized())
			v.append(Vector3(s1, s2, 0).normalized())
			v.append(Vector3(s2, 0, s1).normalized())
	# The twenty faces are every triple of vertices mutually at the icosahedron's edge
	# distance. Deriving them beats transcribing a face table nobody can check.
	var edge := 0.0
	for i in range(v.size()):
		for j in range(i + 1, v.size()):
			var d: float = (v[i] as Vector3).distance_to(v[j])
			if edge == 0.0 or d < edge:
				edge = d
	var out: Array = []
	for i in range(v.size()):
		for j in range(i + 1, v.size()):
			if absf((v[i] as Vector3).distance_to(v[j]) - edge) > 0.001:
				continue
			for k in range(j + 1, v.size()):
				if absf((v[i] as Vector3).distance_to(v[k]) - edge) > 0.001:
					continue
				if absf((v[j] as Vector3).distance_to(v[k]) - edge) > 0.001:
					continue
				# WIND IT OUTWARD. Deriving the faces from mutual edge distance finds all
				# twenty but says nothing about their orientation, so roughly half came out
				# wound the wrong way and were culled — the v1 shell photographed as a handful
				# of loose triangles and v4 as a ball with a bite out of it. The centroid of a
				# face on a sphere centred at the origin points outward by definition, so the
				# cross product has to agree with it.
				var a: Vector3 = v[i]
				var b: Vector3 = v[j]
				var c: Vector3 = v[k]
				if (b - a).cross(c - a).dot(a + b + c) < 0.0:
					out.append([a, c, b])
				else:
					out.append([a, b, c])
	return out


## Unique edges, keyed by rounded length, so the dictionary IS the parts list.
func _edges_of(tris: Array) -> Dictionary:
	var seen: Dictionary = {}
	for t in tris:
		for pair in [[t[0], t[1]], [t[1], t[2]], [t[2], t[0]]]:
			var a: Vector3 = pair[0]
			var b: Vector3 = pair[1]
			var key := "%.4f,%.4f,%.4f|%.4f,%.4f,%.4f" % [
				minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z),
				maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z)]
			if not seen.has(key):
				seen[key] = [a, b]
	return seen


func _add_shell(holder: Node3D, tris: Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tris:
		var nrm: Vector3 = ((t[0] as Vector3) + (t[1] as Vector3) + (t[2] as Vector3)).normalized()
		for p in t:
			st.set_normal(nrm)
			st.add_vertex((p as Vector3) * radius)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Shell"
	mi.mesh = st.commit()
	mi.material_override = _mat(Color(0.74, 0.70, 0.62), 0.0)
	holder.add_child(mi)


func _add_struts(holder: Node3D, edges: Dictionary) -> void:
	var lengths: Array = _distinct_lengths(edges)
	for key in edges:
		var a: Vector3 = (edges[key][0] as Vector3) * radius
		var b: Vector3 = (edges[key][1] as Vector3) * radius
		# Colour by which distinct length the strut is, so the parts list is legible on the
		# dome itself and not only in the row below it.
		var idx: int = _length_index(lengths, a.distance_to(b))
		holder.add_child(_rod(a, b, _band(idx, lengths.size()), 0.008))


## Every distinct strut length, sorted, drawn as real struts in a row beneath the dome.
func _add_inventory(holder: Node3D, edges: Dictionary) -> void:
	var lengths: Array = _distinct_lengths(edges)
	var row := Node3D.new()
	row.name = "Inventory"
	row.position = Vector3(0.0, -radius - 0.22, 0.0)
	holder.add_child(row)
	var n: int = lengths.size()
	var pitch: float = (radius * 1.9) / float(maxi(n, 1))
	for i in range(n):
		var l: float = float(lengths[i])
		var x: float = (float(i) - float(n - 1) * 0.5) * pitch
		row.add_child(_rod(Vector3(x, -l * 0.5, 0.0), Vector3(x, l * 0.5, 0.0),
				_band(i, n), 0.010))


func _distinct_lengths(edges: Dictionary) -> Array:
	var out: Array = []
	for key in edges:
		var l: float = (edges[key][0] as Vector3).distance_to(edges[key][1]) * radius
		var found := false
		for e in out:
			if absf(float(e) - l) <= STRUT_TOL:
				found = true
				break
		if not found:
			out.append(l)
	out.sort()
	return out


func _length_index(lengths: Array, l: float) -> int:
	for i in range(lengths.size()):
		if absf(float(lengths[i]) - l) <= STRUT_TOL:
			return i
	return 0


func _band(i: int, n: int) -> Color:
	if n <= 1:
		return Color(0.82, 0.72, 0.44)
	var t := float(i) / float(n - 1)
	return Color(0.86, 0.74, 0.42).lerp(Color(0.36, 0.58, 0.72), t)


func _rod(a: Vector3, b: Vector3, c: Color, r: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = maxf(a.distance_to(b), 0.0001)
	cyl.radial_segments = 5
	cyl.rings = 0
	mi.mesh = cyl
	mi.material_override = _mat(c, 0.30)
	mi.position = (a + b) * 0.5
	var dir: Vector3 = (b - a).normalized()
	if absf(dir.dot(Vector3.UP)) < 0.999:
		mi.look_at_from_position(mi.position, mi.position + dir, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	return mi


func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m
