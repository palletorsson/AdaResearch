extends Node3D
class_name DomeKit

# @identity
# essence: the geodesic argument in five stations — the icosahedron seed, the subdivision that multiplies its faces, the handful of strut lengths it resolves to, the half-built frame, and the finished dome that is nothing but triangles agreeing to curve
# desire: one artifact that stages the whole bricolage payoff room, so Bricolage_Dome reads as a single derivation (seed -> subdivide -> stock -> assemble -> stand) rather than five unrelated props
# critical_parameter: the station read from the lookup_name meta the grid stamps before _ready — icosahedron_base / subdivision_demo / strut_inventory / dome_builder / geodesic_dome; it selects which step of the derivation this instance embodies
# triggers: _ready() reads get_meta("artifact_lookup_name"), lays a witness pad, builds that station's geometry from real geodesic math (icosahedron vertices from the golden ratio, midpoint subdivision, vertices normalised to the sphere, upper hemisphere kept), and names it on a plaque
# emerges: a room you can derive rather than admire — the same twenty faces visible in the seed, in the subdivision, and in the dome's curve, so the dome stops being a shape and becomes a consequence
# needs: CylinderMesh struts [Godot built-in, one shared resource re-transformed per edge]; Grid.gdshader [present]; TextScreen PAD plate [present]; the lookup_name meta [set by GridInteractablesComponent before add_child]
# relationships: the payoff of the bricolage sequence — it consumes what constraint_demo taught (a quad hinges, a triangle cannot) and what specimen_plinth shelved (the triangle as stock); the dome is the triangulation_pass_demo repeated over a sphere
# truth: a geodesic dome is not designed, it is derived. Nobody chose its shape; someone chose a seed solid and a subdivision, and the sphere did the rest. That is bricolage formalised — the moment recombination stops being improvisation and becomes a method that can be handed to someone else.

## The geodesic kit for the bricolage sequence. One script serves all five
## stations of Bricolage_Dome; the station is read from the lookup_name the
## grid stamps as metadata before _ready(), the same wrapper pattern as
## specimen_plinth and constraint_demo.

@export var station: String = ""      # override; empty = derive from lookup_name
@export var kit_label: String = ""
@export var kit_note: String = ""

## Stage-2 DNA axis — the geodesic FREQUENCY the dome is derived at.
##
## The artifact's own truth line says a geodesic dome is not designed but derived:
## "someone chose a seed solid and a subdivision, and the sphere did the rest." Until
## now that subdivision was the literal integer 2, hardcoded inside _build_dome, in all
## 23 placements. The artifact named its generating parameter in prose and then put it
## out of reach — bias from the inside. This axis is the reach.
##
## Same radius, same hemisphere cut, same struts. Only the resolution of the curve
## changes: v1 is the raw icosahedral cap at 15 members, v4 is a 242-member mesh. Every
## step roughly doubles the count and halves the member, so no value is inert.
##
## Named `subdivision`, not `frequency` — in geodesic practice the word is spatial
## (1V / 2V / 3V), but `frequency` reads as Hz, and a time-domain axis cannot be
## photographed. The VALUES keep the domain's own notation.
##
## Class I ("alternate") frequency: each icosahedron edge is cut into n parts. n=2 is
## exactly one midpoint halving, so v2 IS the shipped call and the default look is
## untouched. n=3 is not reachable by halving at all — that is why _geo_faces exists.
@export_enum("v1", "v2", "v3", "v4") var subdivision: String = "v2"

const SUBDIVISIONS: PackedStringArray = ["v1", "v2", "v3", "v4"]

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

const STRUT_R := 0.016

# lookup_name -> [station, LABEL, note]
const STATIONS := {
	"icosahedron_base": ["icosahedron", "ICOSAHEDRON", "twenty faces — the seed solid"],
	"subdivision_demo": ["subdivision", "SUBDIVISION", "one face becomes four, then nine"],
	"strut_inventory":  ["struts",      "STRUTS",      "a few lengths build a sphere"],
	"dome_builder":     ["builder",     "DOME BUILDER", "the frame, half raised"],
	"geodesic_dome":    ["dome",        "GEODESIC DOME", "what triangulated struts become"],
}

var _built := false

## Every node THIS script parents onto itself. The teardown walks this and nothing
## else. The old _build() freed get_children(), which would also have destroyed the
## label plates, packaging and tag markers the grid adds after us.
var _created: Array[Node] = []


func _ready() -> void:
	_resolve_identity()
	_build_all()          # synchronous — children exist when _ready returns
	_built = true


func _resolve_identity() -> void:
	var lookup := ""
	if has_meta("artifact_lookup_name"):
		lookup = str(get_meta("artifact_lookup_name"))
	if station == "" and STATIONS.has(lookup):
		var s: Array = STATIONS[lookup]
		station = str(s[0])
		if kit_label == "":
			kit_label = str(s[1])
		if kit_note == "":
			kit_note = str(s[2])
	if station == "":
		station = "icosahedron"
	if kit_label == "":
		kit_label = station.to_upper()


## Parent a node we made, and remember we made it.
func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _build_all() -> void:
	var pad_w := 1.7 if station == "dome" else 0.95
	_add_pad(pad_w)
	match station:
		"icosahedron":
			_build_icosahedron()
		"subdivision":
			_build_subdivision()
		"struts":
			_build_struts()
		"builder":
			_build_builder()
		"dome":
			_build_dome()
		_:
			_build_icosahedron()
	_add_label(pad_w)


# --- geodesic maths -------------------------------------------------------

# The 12 icosahedron vertices, normalised. Golden-ratio rectangles.
func _ico_verts() -> Array:
	var t := (1.0 + sqrt(5.0)) * 0.5
	var raw := [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	var out := []
	for v in raw:
		out.append((v as Vector3).normalized())
	return out


# The 20 faces as index triples.
func _ico_faces() -> Array:
	return [
		[0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],
		[1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],
		[3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],
		[4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1],
	]


# Triangles (as Vector3 triples) at a given subdivision frequency, each vertex
# pushed back out to the unit sphere — that projection is what makes it geodesic.
func _sphere_faces(freq: int) -> Array:
	var verts := _ico_verts()
	var tris := []
	for f in _ico_faces():
		tris.append([verts[f[0]], verts[f[1]], verts[f[2]]])
	for _i in range(max(0, freq - 1)):
		var next := []
		for t in tris:
			var a: Vector3 = t[0]
			var b: Vector3 = t[1]
			var c: Vector3 = t[2]
			var ab := ((a + b) * 0.5).normalized()
			var bc := ((b + c) * 0.5).normalized()
			var ca := ((c + a) * 0.5).normalized()
			next.append([a, ab, ca])
			next.append([ab, b, bc])
			next.append([ca, bc, c])
			next.append([ab, bc, ca])
		tris = next
	return tris


# The axis as an integer frequency. "v3" -> 3. Anything unrecognised has already
# been folded to the default by _pick_axis, so this cannot return a surprise.
func _freq() -> int:
	var n: int = int(SUBDIVISIONS.find(subdivision)) + 1
	return n if n >= 1 else 2


# Triangles at a Class I frequency n: each icosahedron edge cut into n equal parts,
# the barycentric lattice on the flat face, every point pushed out to the sphere.
#
# n = 1 and n = 2 are handed straight back to _sphere_faces. They are the two the
# halving recursion can reach, they are what shipped, and delegating means the default
# path runs the SAME arithmetic it ran before this axis existed rather than a
# reimplementation that agrees to within a float. n = 3 has no halving that reaches it
# at all — three is not a power of two — which is the whole reason this function is here.
func _geo_faces(freq: int) -> Array:
	var n: int = maxi(1, freq)
	if n <= 2:
		return _sphere_faces(n)
	var verts := _ico_verts()
	var tris := []
	for f in _ico_faces():
		var a: Vector3 = verts[f[0]]
		var b: Vector3 = verts[f[1]]
		var c: Vector3 = verts[f[2]]
		var grid := []
		for i in range(n + 1):
			var row := []
			for j in range(n + 1 - i):
				var p: Vector3 = a \
					+ (b - a) * (float(i) / float(n)) \
					+ (c - a) * (float(j) / float(n))
				row.append(p.normalized())
			grid.append(row)
		for i in range(n):
			var lo: Array = grid[i]
			var hi: Array = grid[i + 1]
			for j in range(n - i):
				tris.append([lo[j], hi[j], lo[j + 1]])
				if j < n - i - 1:
					tris.append([hi[j], hi[j + 1], lo[j + 1]])
	return tris


# Member diameter tracks member length, so slenderness stays at the shipped 12.5:1 at
# every frequency — the stock a real kit would order once its struts halve. At v2 this
# returns STRUT_R unchanged, to the bit.
func _strut_radius(freq: int) -> float:
	return STRUT_R * 2.0 / float(maxi(1, freq))


# Unique edges of a triangle set, optionally keeping only the upper hemisphere.
func _edges(tris: Array, hemisphere: bool = false) -> Array:
	var seen := {}
	var out := []
	for t in tris:
		var pairs := [[t[0], t[1]], [t[1], t[2]], [t[2], t[0]]]
		for p in pairs:
			var p0: Vector3 = p[0]
			var p1: Vector3 = p[1]
			if hemisphere and (p0.y < -0.01 or p1.y < -0.01):
				continue
			var k := "%.3f,%.3f,%.3f|%.3f,%.3f,%.3f" % [p0.x, p0.y, p0.z, p1.x, p1.y, p1.z]
			var k2 := "%.3f,%.3f,%.3f|%.3f,%.3f,%.3f" % [p1.x, p1.y, p1.z, p0.x, p0.y, p0.z]
			if seen.has(k) or seen.has(k2):
				continue
			seen[k] = true
			out.append([p0, p1])
	return out


# --- the five stations ----------------------------------------------------

func _build_icosahedron() -> void:
	var r := 0.34
	var root := Node3D.new()
	root.position = Vector3(0.0, 0.06 + r, 0.0)
	_own(root)
	for e in _edges(_sphere_faces(1)):
		root.add_child(_strut(e[0] * r, e[1] * r, STRUT_R, _subject_mat()))


# One face at frequency 1, 2 and 3 — the multiplication, left to right.
func _build_subdivision() -> void:
	var xs := [-0.30, 0.0, 0.30]
	var tri_scale := 0.30
	for i in 3:
		var holder := Node3D.new()
		holder.position = Vector3(float(xs[i]), 0.06 + tri_scale * 0.55, 0.0)
		_own(holder)
		# a single icosahedron face, subdivided i+1 times, laid flat-on to the viewer
		var tri: Array = _sphere_faces(1)[0]
		var sub := [[tri[0], tri[1], tri[2]]]
		for _s in range(i):
			var nxt := []
			for t in sub:
				var a: Vector3 = t[0]
				var b: Vector3 = t[1]
				var c: Vector3 = t[2]
				var ab := ((a + b) * 0.5).normalized()
				var bc := ((b + c) * 0.5).normalized()
				var ca := ((c + a) * 0.5).normalized()
				nxt.append([a, ab, ca]); nxt.append([ab, b, bc])
				nxt.append([ca, bc, c]); nxt.append([ab, bc, ca])
			sub = nxt
		var mat := _subject_mat() if i > 0 else _witness_mat()
		for e in _edges(sub):
			holder.add_child(_strut(e[0] * tri_scale, e[1] * tri_scale, STRUT_R * 0.8, mat))


# The stock: a rack carrying the handful of distinct lengths a dome resolves to.
func _build_struts() -> void:
	var rack := MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.78, 0.05, 0.10)
	rack.mesh = bar
	rack.position = Vector3(0.0, 0.085, 0.0)
	rack.material_override = _witness_mat()
	_own(rack)
	var lengths := [0.30, 0.38, 0.46]
	for i in 3:
		var l := float(lengths[i])
		var z := -0.16 + float(i) * 0.16
		_own(_strut(Vector3(-l * 0.5, 0.15, z), Vector3(l * 0.5, 0.15, z),
			STRUT_R * 1.3, _subject_mat()))


# The frame half raised: the dome's lower band standing, the rest still stock.
#
# Reads the SAME axis as the dome. The two stations stand in one room, and a 2V frame
# beside a 4V dome would say the builder was assembling a different building. The band
# cut stays at mid.y < 0.45, so "half raised" is a proportion of the sphere and holds
# at every frequency: 10 members up at v1, 30 at v2, 60 at v3, 112 at v4.
func _build_builder() -> void:
	var r := 0.42
	var n := _freq()
	var rad := _strut_radius(n)
	var mat := _subject_mat()
	var stock_mat := _witness_mat()
	var root := Node3D.new()
	root.position = Vector3(0.0, 0.06, 0.0)
	_own(root)
	# only the struts whose midpoint is low on the sphere — the base band, built
	for e in _edges(_geo_faces(n), true):
		var mid: Vector3 = ((e[0] + e[1]) * 0.5)
		if mid.y < 0.45:
			root.add_child(_strut(e[0] * r, e[1] * r, rad, mat))
	# the remainder, still lying on the pad as stock. Cut to the same length the raised
	# members are — members shorten as 1/n, so the loose stock does too. The 2.0/n
	# factor returns the shipped 0.26 m exactly at the default.
	var stock_len: float = 0.26 * 2.0 / float(n)
	for i in 3:
		var z := -0.12 + float(i) * 0.12
		_own(_strut(Vector3(0.20, 0.075, z), Vector3(0.20 + stock_len, 0.075, z),
			rad * 1.2, stock_mat))


# The payoff: a hemisphere at the chosen frequency, standing on its ring.
#
# Radius 0.76 m and the y >= -0.01 cut are fixed — this is always the same dome, always
# 1.52 m across and 0.76 m tall. What the axis moves is the resolution of the curve:
#   v1   15 members, every one 0.799 m — a faceted shelter, visibly polyhedral
#   v2   60 members, 0.415-0.470 m — the shipped dome, unchanged
#   v3  139 members, 0.265-0.313 m — the facets stop reading as facets
#   v4  242 members, 0.192-0.247 m — a fine mesh; a surface made of line
func _build_dome() -> void:
	var r := 0.76
	var n := _freq()
	var rad := _strut_radius(n)
	# One material for the whole frame instead of one per member. Same shader, same
	# constants, same pixels — but v4 raises the member count fourfold and there is no
	# reason to mint 242 identical ShaderMaterials to draw one dome.
	var mat := _subject_mat()
	var root := Node3D.new()
	root.position = Vector3(0.0, 0.06, 0.0)
	_own(root)
	for e in _edges(_geo_faces(n), true):
		root.add_child(_strut(e[0] * r, e[1] * r, rad, mat))


# --- pieces ---------------------------------------------------------------

# A strut between two points: one cylinder, oriented so its Y axis runs the edge.
func _strut(p1: Vector3, p2: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var d := p1.distance_to(p2)
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = max(0.001, d)
	cyl.radial_segments = 6
	cyl.rings = 1
	mi.mesh = cyl
	var dir := (p2 - p1).normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var xa := up.cross(dir).normalized()
	var za := dir.cross(xa).normalized()
	mi.transform = Transform3D(Basis(xa, dir, za), (p1 + p2) * 0.5)
	mi.material_override = mat
	return mi


func _add_pad(w: float) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Pad"
	var box := BoxMesh.new()
	box.size = Vector3(w, 0.04, w)
	mi.mesh = box
	mi.position = Vector3(0.0, 0.02, 0.0)
	mi.material_override = _witness_mat()
	add_child(mi)


func _add_label(pad_w: float) -> void:
	# Configure BEFORE add_child — TextScreen's setters rebuild only when
	# already in-tree, so driving them post-add forces a queue_free/rebuild per
	# property and leaves the renderer holding freed materials. Set first, add last.
	var ts := TextScreenScript.new()
	ts.name = "KitPlate"
	ts.mode = 2                       # Mode.PAD — reclined plaque
	ts.width_m = 0.36
	ts.position = Vector3(0.0, 0.045, pad_w * 0.5 - 0.06)
	if ts.has_method("set_text"):
		ts.set_text(kit_label, kit_note)
	add_child(ts)


# --- material -------------------------------------------------------------

func _subject_mat() -> Material:
	return _grid_material(Color(0.55, 0.62, 0.72), Color(0.45, 0.85, 1.0), 2.0)


func _witness_mat() -> Material:
	return _grid_material(Color(0.30, 0.32, 0.38), Color(0.45, 0.50, 0.60), 0.5)


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


## Accept an axis value only if it names something we actually build. A typo in a map
## token has to land on the shipped look whole — a half-recognised value would strand a
## placement with a frequency nobody chose.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Tear down only what this script made, then build again — synchronously and in place.
## No call_deferred: a deferred rebuild that removes children first makes the grid's
## _auto_ground_artifact measure a zero AABB, return early, and never ground the dome.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_build_all()


## Grid config. Keys: "station", "label", "note", and the DNA axis "subdivision".
func apply_grid_config(config_data: Dictionary) -> void:
	var before_station: String = station
	var before_label: String = kit_label
	var before_note: String = kit_note
	var before_subdivision: String = subdivision

	if config_data.has("station"):
		station = str(config_data["station"])
	if config_data.has("label"):
		kit_label = str(config_data["label"])
	if config_data.has("note"):
		kit_note = str(config_data["note"])
	# Stage-2 DNA axis — #subdivision:v3
	if config_data.has("subdivision"):
		subdivision = _pick_axis(str(config_data["subdivision"]), SUBDIVISIONS, subdivision)

	if not _built:
		# _ready has not run yet; it will build with the values just resolved.
		return
	if (station == before_station and kit_label == before_label
			and kit_note == before_note and subdivision == before_subdivision):
		# Nothing geometric changed. curation_station hands every artifact it curates
		# {"emissive": false} one line after framing our labels — rebuilding here would
		# throw that framing away, and it is never re-applied. Say nothing, touch nothing.
		return

	_rebuild_now()
	print("[DomeKit] Config applied — station=%s, subdivision=%s" % [station, subdivision])
