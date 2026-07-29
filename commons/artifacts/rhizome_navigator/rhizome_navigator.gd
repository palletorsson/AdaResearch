extends Node3D
class_name RhizomeNavigator

# @identity
# essence: a three-metre dark plate with a pale rhizome grown across it in low relief — plinths standing 15 cm proud, strips raised 5 cm and narrow enough that dark plate shows between them, a thin hole where a centre would be, and the mat reaching the rim on every side so you can step on from anywhere
# desire: to make the rhizome something a body enters rather than a diagram a body reads; the tabletop graph always has a front, and a front is a beginning
# critical_parameter: links_per_node — how many existing points a new shoot joins. At one it is a tree with a hidden root; at three the mat closes into loops and no node can be called first
# triggers: _ready() grows the graph from a seeded annulus (shoots sprout at the rim, each joining its several nearest neighbours) and lays it as floor geometry; _process runs a wavefront that re-enters at a different random node every few seconds
# emerges: you arrive somewhere in the middle of something already connected. The pulse arrives from a different direction each time and the mat does not care, because there is nowhere it has to start
# needs: a dark matte plate to be pale against — without it the graph sat at floor height and read as one white smear; MultiMeshInstance3D for plinths and strips [one draw call each]; strips narrower than MIN_GAP or the mat welds shut; a seeded RNG so the mat is the same mat on every load; no collision anywhere — nothing here is a trip hazard
# relationships: the walkable twin of rhizome_grower, which grows the same rule at arm's length on a bench; where the grower says "no root" in a readout, this one says it by having no entrance
# truth: a map with an entrance has already told you where you are. This one has twelve, and the pulse comes from a different one every time.
# @qfep_term: Rhizome — connection without hierarchy, laid where feet go.

## Room-scale walk-through, 3x1x3. A floor-plane rhizome on a dark plate: node
## plinths in low relief and narrow raised edge strips, grown by the sideways
## rule (shoots link to SEVERAL neighbours, never to one parent), with no marked
## start and no privileged edge.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"

# --- knobs ----------------------------------------------------------------
## Nodes in the mat.
@export var node_count: int = 22
## Existing points each new shoot joins. Below 2 a hierarchy appears.
@export var links_per_node: int = 3
## Side of the walkable patch, in metres.
@export var patch_size: float = 3.0
## Seed for the growth. Same seed, same mat, every load.
@export var nav_seed: int = 20260729
## Seconds between wavefront re-entries. Each re-entry picks a new origin node.
@export var pulse_period: float = 3.2

const NODE_R := 0.13
const NODE_H := 0.15
## Strips must stay well under MIN_GAP or the mat welds shut into one sheet and
## the graph stops being a graph. At the old 0.30 the 59 strips covered 65% of
## the patch and fused; 0.12 leaves the plate showing across ~54% of it, which
## is what makes the web legible as a web.
const STRIP_W := 0.12
const STRIP_H := 0.05
const PLATE_H := 0.03
## Closest two nodes may sit. Keeps plinths from fusing into a slab.
const MIN_GAP := 0.38

## Dark ground so the pale mat has something to be pale against.
const PLATE := Color(0.075, 0.082, 0.105)
const COLD := Color(0.50, 0.55, 0.66)
const WARM := Color(0.46, 0.95, 0.82)
const PLINTH := Color(0.62, 0.58, 0.92)

var _rng := RandomNumberGenerator.new()
var _built := false
var _created: Array[Node] = []

var _points: Array[Vector3] = []
var _edges: Array = []            # [a:int, b:int]
var _adj: Array = []              # per node: Array[int]
var _hop: PackedInt32Array = PackedInt32Array()   # hops from the current origin, per node
var _edge_field: MultiMeshInstance3D = null
var _readout: Label3D = null
var _pulse_t: float = 0.0
var _origin_node: int = 0


func _ready() -> void:
	_build_all()
	_built = true
	set_process(true)


# ═══════════════════════════════════════════════════════════════════
# GROWTH — the sideways rule, run once at build time
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	_rng.seed = nav_seed
	_grow()
	_lay_plate()
	_lay_nodes()
	_lay_edges()
	_lay_readout()
	_reseat_pulse()


## Shoots sprout on an annulus and each joins its several nearest existing
## points. Two consequences, both wanted: the middle stays thin (there is no
## trunk to stand under) and the mat reaches the patch boundary on every side,
## so a walker can step on wherever they meet it.
func _grow() -> void:
	_points.clear()
	_edges.clear()
	_adj.clear()
	var half: float = patch_size * 0.5 - 0.22
	var target: int = clampi(node_count, 6, 60)

	# Two seeds, both off-centre, neither privileged. Nothing links them yet —
	# whatever joins them will join them the same way it joins everything else.
	_points.append(_annulus_point(half))
	_points.append(_annulus_point(half))

	var guard: int = 0
	while _points.size() < target and guard < target * 40:
		guard += 1
		var p: Vector3 = _annulus_point(half)
		if _too_close(p):
			continue
		# Link BEFORE appending, so a shoot can never pick itself as a parent.
		var targets: Array = _nearest(p, links_per_node)
		var idx: int = _points.size()
		_points.append(p)
		for t in targets:
			_edges.append([idx, int(t)])

	# Adjacency, built after the fact — the graph is symmetric even though the
	# growth was not, which is the whole difference from a tree.
	for _i in _points.size():
		_adj.append([])
	for e in _edges:
		var a: int = int(e[0])
		var b: int = int(e[1])
		(_adj[a] as Array).append(b)
		(_adj[b] as Array).append(a)


## A point on the annulus of the patch: radius biased outward, then folded into
## the square so the corners fill too. The thin middle is deliberate.
func _annulus_point(half: float) -> Vector3:
	var ang: float = _rng.randf_range(0.0, TAU)
	var rad: float = _rng.randf_range(half * 0.42, half * 1.32)
	var x: float = clampf(cos(ang) * rad, -half, half)
	var z: float = clampf(sin(ang) * rad, -half, half)
	return Vector3(x, 0.0, z)


func _too_close(p: Vector3) -> bool:
	for q in _points:
		if p.distance_to(q) < MIN_GAP:
			return true
	return false


func _nearest(from: Vector3, count: int) -> Array:
	var ranked: Array = []
	for i in _points.size():
		ranked.append({"i": i, "d": from.distance_to(_points[i])})
	ranked.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
	var out: Array = []
	var k: int = 0
	var want: int = clampi(count, 1, 6)
	while k < ranked.size() and out.size() < want:
		out.append(int((ranked[k] as Dictionary)["i"]))
		k += 1
	return out


# ═══════════════════════════════════════════════════════════════════
# THE FLOOR
# ═══════════════════════════════════════════════════════════════════

func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


## The ground the mat is laid on. Dark and matte: without it the pale plinths
## and strips sat at floor height with nothing behind them and the whole patch
## read as one white smear. The plate is what gives the graph a silhouette.
func _lay_plate() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(patch_size, PLATE_H, patch_size)
	var mi := MeshInstance3D.new()
	mi.name = "Plate"
	mi.mesh = box
	mi.position = Vector3(0.0, PLATE_H * 0.5, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PLATE
	mat.roughness = 0.92
	mat.metallic = 0.0
	mi.material_override = mat
	_own(mi)


## Node plinths: every one identical. Birth order is not encoded anywhere —
## no size ramp, no colour ramp, nothing that would let the eye rank them. They
## stand 15 cm proud of the plate — a step up, not a decal.
func _lay_nodes() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var cyl := CylinderMesh.new()
	cyl.top_radius = NODE_R
	cyl.bottom_radius = NODE_R + 0.02
	cyl.height = NODE_H
	cyl.radial_segments = 14
	mm.mesh = cyl
	mm.instance_count = _points.size()
	for i in _points.size():
		var t := Transform3D.IDENTITY
		t.origin = _points[i] + Vector3(0.0, PLATE_H + NODE_H * 0.5, 0.0)
		mm.set_instance_transform(i, t)
	var mi := MultiMeshInstance3D.new()
	mi.name = "Nodes"
	mi.multimesh = mm
	# Emission held well under 1: at 1.1 the plinths clipped to white and lost
	# the shading that tells you they have a side.
	mi.material_override = _grid_material(PLINTH, PLINTH.lightened(0.45), 0.5)
	_own(mi)


## Edge strips: narrow boxes laid between plinth centres, 5 cm proud of the
## plate — enough that the side face catches light and the strip has a visible
## edge, low enough to walk over. Narrower than MIN_GAP on purpose: wide strips
## overlap their neighbours and the mat stops being a graph. Coloured per
## instance, because the pulse rewrites those colours every frame.
func _lay_edges() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var box := BoxMesh.new()
	box.size = Vector3(1.0, STRIP_H, STRIP_W)
	mm.mesh = box
	mm.instance_count = _edges.size()
	for i in _edges.size():
		var e: Array = _edges[i]
		var a: Vector3 = _points[int(e[0])]
		var b: Vector3 = _points[int(e[1])]
		var d: Vector3 = b - a
		var length: float = maxf(d.length(), 0.001)
		var yaw: float = atan2(-d.z, d.x)
		# Named edge_basis, not basis — Node3D already has a `basis` property and a
		# local of that name shadows it.
		var edge_basis: Basis = Basis(Vector3.UP, yaw).scaled(Vector3(length, 1.0, 1.0))
		mm.set_instance_transform(i, Transform3D(edge_basis, (a + b) * 0.5 + Vector3(0.0, PLATE_H + STRIP_H * 0.5, 0.0)))
		mm.set_instance_color(i, COLD)
	_edge_field = MultiMeshInstance3D.new()
	_edge_field.name = "Edges"
	_edge_field.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.45
	# Emission is a fixed dim teal, NOT white. White emission at 0.7 added a flat
	# 0.7 to every channel of every strip, so cold and warm both clipped to paper
	# and the pulse was invisible. The pulse now lives in the vertex albedo.
	mat.emission_enabled = true
	mat.emission = Color(0.10, 0.22, 0.20)
	mat.emission_energy_multiplier = 0.45
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_edge_field.material_override = mat
	_own(_edge_field)


## Hung over the thin middle — the one place on the patch the mat left empty.
func _lay_readout() -> void:
	_readout = Label3D.new()
	_readout.text = "RHIZOME NAVIGATOR\nNODES: %d  EDGES: %d  (no root)" % [_points.size(), _edges.size()]
	_readout.font_size = 26
	_readout.outline_size = 6
	_readout.modulate = WARM
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.position = Vector3(0.0, 1.95, 0.0)
	_own(_readout)

	var sub := Label3D.new()
	sub.text = "enter anywhere — there is no beginning"
	sub.font_size = 16
	sub.outline_size = 4
	sub.modulate = PLINTH
	sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sub.position = Vector3(0.0, 1.72, 0.0)
	_own(sub)


# ═══════════════════════════════════════════════════════════════════
# THE PULSE — a signal that keeps entering somewhere else
# ═══════════════════════════════════════════════════════════════════

## Pick a new entry node and recompute hop distance from it. Breadth-first, so
## the wavefront spreads by connection rather than by geometry — the same claim
## the mat makes, animated.
func _reseat_pulse() -> void:
	if _points.is_empty():
		return
	_origin_node = _rng.randi() % _points.size()
	_hop = PackedInt32Array()
	_hop.resize(_points.size())
	for i in _points.size():
		_hop[i] = -1
	_hop[_origin_node] = 0
	var queue: Array[int] = [_origin_node]
	var head: int = 0
	while head < queue.size():
		var cur: int = queue[head]
		head += 1
		for nb in (_adj[cur] as Array):
			var j: int = int(nb)
			if _hop[j] < 0:
				_hop[j] = _hop[cur] + 1
				queue.append(j)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _edge_field == null or _hop.is_empty():
		return
	_pulse_t += delta
	if _pulse_t >= maxf(0.6, pulse_period):
		_pulse_t = 0.0
		_reseat_pulse()

	# Wavefront position, in hops. Runs past the far side then waits for reseat.
	var front: float = _pulse_t * 3.4
	var mm: MultiMesh = _edge_field.multimesh
	for i in _edges.size():
		var e: Array = _edges[i]
		var ha: int = _hop[int(e[0])]
		var hb: int = _hop[int(e[1])]
		if ha < 0 or hb < 0:
			mm.set_instance_color(i, COLD)
			continue
		var d: float = float(mini(ha, hb)) + 0.5
		var gap: float = absf(front - d)
		var heat: float = clampf(1.0 - gap * 0.85, 0.0, 1.0)
		mm.set_instance_color(i, COLD.lerp(WARM, heat))


# ═══════════════════════════════════════════════════════════════════
# MATERIAL / CONFIG
# ═══════════════════════════════════════════════════════════════════

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
	fallback.roughness = 0.5
	return fallback


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_edge_field = null
	_readout = null
	_build_all()


## Grid config. Keys: "node_count", "links_per_node", "patch_size", "pulse_period",
## "seed" (alias "nav_seed").
func apply_grid_config(config_data: Dictionary) -> void:
	var before_nodes: int = node_count
	var before_links: int = links_per_node
	var before_patch: float = patch_size
	var before_seed: int = nav_seed

	if config_data.has("node_count"):
		node_count = clampi(int(config_data["node_count"]), 6, 60)
	if config_data.has("links_per_node"):
		links_per_node = clampi(int(config_data["links_per_node"]), 1, 6)
	if config_data.has("patch_size"):
		patch_size = clampf(float(config_data["patch_size"]), 1.4, 6.0)
	if config_data.has("pulse_period"):
		pulse_period = clampf(float(config_data["pulse_period"]), 0.6, 20.0)
	if config_data.has("seed"):
		nav_seed = int(config_data["seed"])
	if config_data.has("nav_seed"):
		nav_seed = int(config_data["nav_seed"])

	if not _built:
		return
	if (node_count == before_nodes and links_per_node == before_links
			and is_equal_approx(patch_size, before_patch) and nav_seed == before_seed):
		# pulse_period alone needs no rebuild, and curation passes hand every
		# artifact {"emissive": false} — rebuilding on that discards their framing.
		return

	_rebuild_now()
	print("[RhizomeNavigator] Config applied — nodes=%d, links=%d, patch=%.2f, seed=%d" % [
		_points.size(), links_per_node, patch_size, nav_seed])
