extends MeshInstance3D

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION — grab_sphere_F, grab_sphere_lambda, grab_sphere_E
# (and grab_sphere_phi, which shares the body). ONE AXIS, ONE FILE, because
# there is only one file: all four QFEP term spheres are the SAME SCENE,
# res://commons/primitives/point/grab_sphere_point_with_color.tscn, and the
# only thing the registry gives them to differ by is a `default_params.color`
# that NOTHING IN THE ENGINE READS. See "WHAT WAS ALREADY TRUE" below.
#
#   grasp   WHAT YOUR HAND CLOSES ON WHEN YOU PICK UP A TERM
#           atom · socket · chorus · hollow · swarm
#
# WHY THIS, AND NOT A REGISTER OR AN EXPOSURE AXIS. These are not things in a
# room and not instruments you operate. They are the four terms of
# QFE = F - λE(S) + φΔE(S,t) handed to you as objects, one per hand. That
# handing-over is the whole argument, and its limit is that A TERM IS NOT A
# THING. F has no referent you can point at; it is a position in a sentence.
# λ is worse — a bare coefficient, which exists only as a ratio between two
# other terms and has no body even in principle. The sphere lends objecthood
# to something that has none, and the part it cannot represent is the formula
# that gives the term its meaning. So the axis is not how much mechanism shows
# (there is none) or what furniture surrounds it (there is none). It is what
# is actually in your hand when you close it.
#
# WHAT EACH VALUE DOES WITH THE PART IT CANNOT REPRESENT — the sieve's third
# question, and what decides whether this is a family or a menu:
#   atom    HIDES it.      One closed pellet, uniform, uncuttable, in a colour
#                          that is not even its own. No sign that there is an
#                          equation. Your hand closes on a thing, and the
#                          claim is that a term is one.
#   socket  BOUNDS it.     Half the body is built and half is a dark void
#                          behind a bright rim, ribbed so the missing volume
#                          has a measured shape. The term admits it is a
#                          fragment and shows exactly how much is not there.
#   chorus  EXHIBITS it.   The other three terms stand on a rail below in the
#                          formula's written order and their own colours; this
#                          one is lifted off the rail, full size and lit. You
#                          reach for one and you lift four.
#   hollow  LEAVES A HOLE. The outline survives and the substance does not —
#                          the sphere is only its great circles, and you see
#                          straight through the place where a referent would
#                          be. Your hand closes on a contour.
#   swarm   BUILDS THERE.  No body at all: a graded population of points
#                          through twice the volume, with nothing at the
#                          centre. Nothing to close your hand on, and still
#                          something there — the term as a region you could be
#                          inside rather than an object you could carry off.
#
# WHAT WAS ALREADY TRUE, and is the reason this axis exists at all. Today
# grab_sphere_F, grab_sphere_E, grab_sphere_lambda and grab_sphere_phi are not
# four objects. They are four registry names on one 24 mm sphere that renders
# HOT PINK for all four — point_color.gd's `current_color` default paints over
# the scene's own material in _ready(), and the red / blue / green / magenta
# the registry declares in `default_params.color` is dead data no loader
# consumes. The formula is on the floor as four identical pink pellets. So
# `atom` is not a neutral baseline: it is the strongest possible version of
# the claim this axis interrogates, hiding the relation so completely that it
# also hides WHICH TERM IT IS. Every other value has to name the term before
# it can say anything about the term's relation to the rest, which is why the
# four hexes below are read off the registry entries and used by all four
# non-legacy values. That is not a colour axis smuggled in; it is the minimum
# condition of the axis having a subject.
#
# grasp=atom is the legacy lineage exactly: _ready() returns before it reads a
# radius, allocates a material or adds a node. The mesh point_mesh.gd built,
# the hot pink point_color.gd applied, the highlight ring, the collision
# sphere, the pickable behaviour — all untouched, on all 24 placements of the
# four terms.
#
# REACHABLE ON 7 OF THOSE 24, and that is worth writing down rather than
# discovering later. Seven spheres are placed straight into the grid, which
# stamps artifact_lookup_name and can carry a `#grasp:` token. The other
# seventeen sit inside a wrapper — eleven in curation_station, six mounted on
# sim_cube podiums — and neither wrapper stamps the name on what it
# instantiates, though both are holding it at the time
# (curation_station.gd:362, sim_cube.gd:122-124). A sphere inside a wrapper
# cannot tell which term it is, so it stays atom whatever a map says. That is
# the same one-scene-many-names fault the three SPAWNERS were fixed for; the
# two wrapper artifacts never were. Reported, not fixed: not this pass's files.
#
# WHAT IT COST. Two things, and they are real. First, the shared body now has
# a branch in it: grab_sphere_point_with_color.tscn is also the primitives
# artifact `grab_sphere_point_with_color`, which is NOT a term of anything, so
# this script refuses to stage it — a `grasp` value set on that token changes
# nothing and would measure INERT if anyone swept it. Silence is the honest
# answer there, but it is a silence a future reader has to be told about.
# Second, `atom` used to be innocent. A pink pellet was just an unfinished
# render. Standing beside socket and chorus it is legible as a CLAIM — that a
# term is uncuttable and self-identical — and this object can no longer be
# naive about making it.
#
# NOT ROUTED THROUGH grasp: the formula, its terms, their names, the colours
# the registry assigns them, the slot order (taken from the written form
# F, λ, E(S), φ), the grab behaviour, the collision radius, the highlight
# ring, and the pickable/XR contract. This pass stages the curriculum's last
# claim; it does not edit it.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS. atom is the legacy lineage and builds nothing. The registry
## declaration is derived from THIS LINE by tools/apply_dna_block.py.
@export_enum("atom", "socket", "chorus", "hollow", "swarm") var grasp: String = "atom"

## The allow-list a map token is checked against. A word that is not here falls
## back to the shipped look rather than stranding a placement with a body the
## registry never declared.
const GRASPS: PackedStringArray = ["atom", "socket", "chorus", "hollow", "swarm"]

## THE FOUR TERMS. `slot` is position in the written formula
## QFE = F - λE(S) + φΔE(S,t); `hex` is copied verbatim from each registry
## entry's `default_params.color` in commons/artifacts/registry/qfep.json —
## the field the engine never reads. A lookup name absent from this table is
## not a term of the formula and this script leaves it entirely alone.
const TERMS: Dictionary = {
	"grab_sphere_F": {"slot": 0, "hex": "4080FF"},
	"grab_sphere_lambda": {"slot": 1, "hex": "40FF80"},
	"grab_sphere_E": {"slot": 2, "hex": "FF6060"},
	"grab_sphere_phi": {"slot": 3, "hex": "FF80FF"},
}

## Neutral used for the rail under a chorus and the ribs across a socket's
## void: present, structural, and arguing nothing.
const NEUTRAL := Color(0.42, 0.44, 0.49)

var _term: String = ""
var _tint: Color = Color.WHITE
var _r: float = 0.012


func _ready() -> void:
	# The one-scene-many-names contract: GridInteractablesComponent (line 1135),
	# capture_multi_angle (line 433) and capture_config_sweep (line 104) all
	# stamp artifact_lookup_name on the ROOT before add_child, so it is readable
	# from a child's _ready(). Without it a family that shares a scene renders
	# every member as the family default.
	_term = str(_host_meta("artifact_lookup_name", ""))
	if not TERMS.has(_term):
		return
	# A map token reaches a child this way and only this way: the grid calls
	# apply_grid_config on the ROOT, whose script is grab_sphere.gd and has no
	# such method, but it sets config_<key> as metadata first — also before
	# add_child. The sweep instead sets the export directly (_holder_of finds
	# this node breadth-first), so the export is the fallback, not the override.
	var want: String = grasp
	var token: String = str(_host_meta("config_grasp", ""))
	if token != "":
		want = token
	grasp = _normalise(want)
	if grasp == "atom":
		return

	_tint = Color.html(str(TERMS[_term]["hex"]))
	_r = _radius()
	match grasp:
		"socket":
			_build_socket()
		"chorus":
			_build_chorus()
		"hollow":
			_build_hollow()
		"swarm":
			_build_swarm()


## HALF A BODY AND A BOUNDED VOID. The solid half is the term in its own
## colour; the missing half is built too — as a dark shell with ribs running
## rim to pole — so the absence has a size instead of merely not being there.
func _build_socket() -> void:
	var top := SphereMesh.new()
	top.radius = _r
	top.height = _r          # a regular hemisphere needs height == radius
	top.radial_segments = 32
	top.rings = 12
	top.is_hemisphere = true
	mesh = top
	material_override = _mat(_tint, 1.5, 1.0)

	var void_half := SphereMesh.new()
	void_half.radius = _r * 0.985
	void_half.height = _r * 0.985
	void_half.radial_segments = 32
	void_half.rings = 12
	void_half.is_hemisphere = true
	# faintly lit rather than merely dark: an unlit shell against a 0.055 background
	# is indistinguishable from nothing being there, which would turn socket into a
	# second hollow. The void has to READ as built.
	var hole: MeshInstance3D = _add(void_half, Vector3.ZERO,
		_mat(Color(0.11, 0.11, 0.15), 0.30, 0.55))
	hole.rotation_degrees = Vector3(180, 0, 0)

	# the rim: where the term stops
	var rim := TorusMesh.new()
	rim.inner_radius = _r * 0.94
	rim.outer_radius = _r * 1.10
	rim.rings = 32
	rim.ring_segments = 8
	_add(rim, Vector3.ZERO, _mat(_tint.lightened(0.35), 2.4, 1.0))

	# the ribs: the shape of what is not there, measured. These carry the claim, so
	# they are sized to survive the capture — at the sweep's default framing this
	# whole artifact is 24 px wide and anything under ~0.07 R is sub-pixel.
	var ribs := _mat(NEUTRAL.lightened(0.25), 0.90, 1.0)
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		_strut(Vector3(cos(a) * _r * 0.97, 0.0, sin(a) * _r * 0.97),
			Vector3(0.0, -_r * 0.99, 0.0), _r * 0.075, ribs)


## ONE OF FOUR, LIFTED. The rail carries every slot of the formula; the three
## terms this artifact is not stand on it, dim and small, in their own colours
## and in written order. This term is off the rail, full size and lit, with a
## riser still joining it to the row it came out of.
func _build_chorus() -> void:
	material_override = _mat(_tint, 1.8, 1.0)

	var mine: int = int(TERMS[_term]["slot"])
	var span: float = _r * 2.7
	var rail_y: float = -_r * 2.4
	var lo: float = 0.0
	var hi: float = 0.0
	for key: String in TERMS.keys():
		var x: float = float(int(TERMS[key]["slot"]) - mine) * span
		lo = minf(lo, x)
		hi = maxf(hi, x)
		if key == _term:
			continue
		var sib := SphereMesh.new()
		sib.radius = _r * 0.60
		sib.height = _r * 1.20
		sib.radial_segments = 20
		sib.rings = 10
		var col: Color = Color.html(str(TERMS[key]["hex"]))
		_add(sib, Vector3(x, rail_y, 0.0), _mat(col.darkened(0.34), 0.34, 1.0))

	var bar := _mat(NEUTRAL.darkened(0.15), 0.16, 1.0)
	_strut(Vector3(lo - _r * 0.9, rail_y, 0.0), Vector3(hi + _r * 0.9, rail_y, 0.0),
		_r * 0.10, bar)
	_strut(Vector3(0.0, rail_y, 0.0), Vector3(0.0, -_r * 0.95, 0.0),
		_r * 0.10, _mat(_tint.darkened(0.30), 0.30, 1.0))


## THE CONTOUR WITHOUT THE CONTENT. Great circles and two latitudes, nothing
## between them. The solid body is hidden rather than destroyed so the pickable
## keeps a valid surface to swap materials on when you grab it.
func _build_hollow() -> void:
	visible = false
	var wire: StandardMaterial3D = _mat(_tint, 2.1, 1.0)
	var t: float = _r * 0.090
	for rot: Vector3 in [Vector3.ZERO, Vector3(90, 0, 0), Vector3(0, 0, 90),
			Vector3(90, 45, 0), Vector3(90, 135, 0)]:
		var g := TorusMesh.new()
		g.inner_radius = _r - t
		g.outer_radius = _r + t
		g.rings = 40
		g.ring_segments = 8
		var ring: MeshInstance3D = _add(g, Vector3.ZERO, wire)
		ring.rotation_degrees = rot
	for sy: float in [1.0, -1.0]:
		var lat := TorusMesh.new()
		var lr: float = _r * 0.835
		lat.inner_radius = lr - t * 0.8
		lat.outer_radius = lr + t * 0.8
		lat.rings = 32
		lat.ring_segments = 8
		_add(lat, Vector3(0.0, sy * _r * 0.55, 0.0), wire)


## A REGION, NOT A BODY. Three Fibonacci shells, brightest inside and thinning
## outward, with nothing at the centre. Deterministic on purpose: a still has
## to be the same still twice.
func _build_swarm() -> void:
	visible = false
	var grain := SphereMesh.new()
	grain.radius = _r * 0.165
	grain.height = _r * 0.330
	grain.radial_segments = 8
	grain.rings = 4
	var shells: Array = [
		[12, 0.42, 2.2, 1.0],
		[22, 0.95, 1.2, 0.92],
		[34, 1.75, 0.55, 0.72],
	]
	for s: Array in shells:
		var mat: StandardMaterial3D = _mat(_tint, float(s[2]), float(s[3]))
		for p: Vector3 in _fib_points(int(s[0]), _r * float(s[1])):
			_add(grain, p, mat)


# ── helpers ──────────────────────────────────────────────────────────────────

## Walk up to the node the spawner stamped. The metas live on the artifact
## ROOT, which is this node's parent; walking rather than assuming keeps this
## working if the body is ever re-parented under a wrapper.
func _host_meta(key: String, fallback: Variant) -> Variant:
	var n: Node = self
	while n != null:
		if n.has_meta(key):
			return n.get_meta(key)
		n = n.get_parent()
	return fallback


func _normalise(raw: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if GRASPS.has(v) else "atom"


## The radius the body actually ended up with — point_mesh.gd rebuilds the mesh
## in its own _ready() and this node's _ready() runs after its children's, so
## asking the mesh is more honest than repeating the number.
func _radius() -> float:
	var sm: SphereMesh = mesh as SphereMesh
	if sm != null and sm.radius > 0.0:
		return sm.radius
	return 0.012


func _mat(c: Color, energy: float, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = energy
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = alpha
	return m


func _add(m: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	add_child(mi)
	mi.position = pos
	return mi


## A rod from a to b. CylinderMesh runs along its own Y, so the basis is built
## with Y on the chord.
func _strut(a: Vector3, b: Vector3, thick: float, mat: Material) -> void:
	var d: Vector3 = b - a
	var length: float = d.length()
	if length < 0.0001:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = thick
	cyl.bottom_radius = thick
	cyl.height = length
	cyl.radial_segments = 8
	cyl.rings = 1
	var mi: MeshInstance3D = _add(cyl, (a + b) * 0.5, mat)
	var up: Vector3 = d.normalized()
	var ref: Vector3 = Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD
	var xa: Vector3 = ref.cross(up).normalized()
	var za: Vector3 = xa.cross(up).normalized()
	mi.basis = Basis(xa, up, za)


func _fib_points(n: int, rad: float) -> Array:
	var pts: Array = []
	var golden: float = PI * (3.0 - sqrt(5.0))
	for i in range(n):
		var y: float = 1.0 - (float(i) + 0.5) / float(n) * 2.0
		var ring: float = sqrt(maxf(0.0, 1.0 - y * y))
		var th: float = golden * float(i)
		pts.append(Vector3(cos(th) * ring, y, sin(th) * ring) * rad)
	return pts
