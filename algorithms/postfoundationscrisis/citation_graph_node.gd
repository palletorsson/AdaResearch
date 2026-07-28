# Citation Graph Node — a single claim, its supporters, its detractors
#
# A central glowing sphere (the claim) surrounded by smaller satellites at different
# orbits. Some satellites pulse green (supporting citations); some pulse red
# (refutations). Lines connect the central sphere to each satellite, colored by stance.
#
# A claim doesn't stand alone. It is held up — or pulled down — by the network of
# other claims it is in conversation with. The point of the citation graph is that the
# claim's *truth* lives in the relations, not in the lone sphere.
#
# @identity: First map where the player sees a claim's social fabric.
# @qfep_term: Edge — relational truth.

extends Node3D
class_name CitationGraphNode

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS
# ═══════════════════════════════════════════════════════════════════

## RECEPTION — what the surrounding network DOES to this claim, and whether there is
## a network at all. This is the axis worth having because the satellite census IS the
## argument: a 7-green / 4-red ring quietly stages consensus-with-healthy-dissent as
## the natural shape of knowledge, and every placement of this artifact has so far
## argued exactly that one mild case. Varying the census lets a map put a claim whose
## relations are hostile, unanimous, or entirely absent into the room.
##
##   cited       the legacy look — 7 green on the near orbit, 4 red further out
##   contested   even split, one shared orbit, green and red alternating in a collar
##   overturned  a red crowd pulled in tight around a shrunken core, green pushed away
##   dogma       nothing but green, two concentric rings, no red anywhere
##   orphan      no satellites, no lines — the lone sphere the artifact says is impossible
##
## `orphan` is the value that earns the axis. It builds the thing this artifact's own
## thesis calls impossible, so a map can stand the refuted claim next to what refutes it.
## Counts and orbit radii are this object's most room-legible knob — the deltas here are
## whole rings appearing and vanishing, not a polite few centimetres of orbit.
@export_enum("cited", "contested", "overturned", "dogma", "orphan") var reception: String = "cited"

## The allow-list the token parser checks against. A typo in a map token has to land on
## the legacy look — a half-recognised value would strand a placement with a claim whose
## social fabric it never asked for.
const RECEPTIONS: PackedStringArray = ["cited", "contested", "overturned", "dogma", "orphan"]

@export var central_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var support_color: Color = Color(0.5, 0.95, 0.55, 1.0)
@export var refute_color: Color = Color(1.0, 0.45, 0.4, 1.0)
@export var support_count: int = 7
@export var refute_count: int = 4
@export var orbit_radius_supports: float = 0.7
@export var orbit_radius_refutes: float = 1.1
@export var rotation_speed: float = 0.25

## Radius of the claim itself, per reception. The default 0.16 is the shipped size.
const CENTRAL_R_DEFAULT: float = 0.16
## Overturned: the claim is diminished by what surrounds it, so the core loses mass
## while the red crowd closes in — the two moves have to happen together or neither reads.
const CENTRAL_R_OVERTURNED: float = 0.10
## Orphan: with nothing to relate to, all the mass the network used to carry is in the
## sphere. 0.40 is 2.5x the shipped radius — big enough that an empty orbit reads as a
## statement rather than as a failed build.
const CENTRAL_R_ORPHAN: float = 0.40

var _central: MeshInstance3D
var _label: Label3D
## Flat per-stance lists, kept for anything that introspects the node.
var _supports: Array = []
var _refutes: Array = []
## The real structure: one entry per orbital ring.
## { color, nodes:Array, orbit, y, spin, slots, stride, slot_offset }
var _rings: Array = []
## Every node THIS script parented, so a rebuild frees only its own work and never
## the label plates, packaging or tags the grid system hangs off the same parent.
var _owned: Array = []
## Connection lines are replaced every frame, so they are tracked apart from _owned.
var _lines: Array = []
var _t: float = 0.0
## True once _ready has built the node. Before that, apply_grid_config only records
## values — _ready will build with them — so nothing is constructed off-tree.
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	# Stage-2 DNA axis — #reception:overturned
	var before_reception: String = reception
	if config_data.has("reception"):
		reception = _pick_axis(str(config_data["reception"]), RECEPTIONS, reception)

	if not _built:
		# The grid path configures before add_child, so _ready has not run and there is
		# nothing to rebuild. _ready will build with the values just resolved.
		return
	if reception == before_reception:
		# Nothing geometric changed. This is curation_station's {"emissive": false}:
		# rebuilding here would throw away the label framing it applied a line earlier.
		return
	_rebuild_now()
	print("[CitationGraphNode] Config applied — reception=%s" % [reception])


## Accept an axis value only if it names something we actually build. Lower-cased and
## stripped so `#reception: Overturned ` behaves; anything else falls back whole.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous, inline, no call_deferred: the new geometry exists before this returns,
## so the auto-grounder that runs after add_child measures the census actually built —
## which matters most for `orphan`, whose core is 0.40 m against the shipped 0.16 m.
func _rebuild_now() -> void:
	_clear_lines()
	for c in _owned:
		if is_instance_valid(c):
			# remove_child leaves the tree NOW; queue_free only reclaims memory later.
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_supports.clear()
	_refutes.clear()
	_rings.clear()
	_central = null
	_label = null
	_build_all()


## Parent a node and remember that this script made it.
func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)


func _clear_lines() -> void:
	for line in _lines:
		if is_instance_valid(line):
			remove_child(line)
			line.queue_free()
	_lines.clear()


func _build_all() -> void:
	_build_central()
	_build_satellites()
	_place_satellites()
	_build_connections()
	_build_label()


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	if _rings.is_empty():
		# `orphan` — nothing orbits and nothing connects, so there is nothing to redraw.
		return
	_place_satellites()
	# Redraw the connection lines (cheap and clear).
	_clear_lines()
	_build_connections()


# ═══════════════════════════════════════════════════════════════════
# THE CENSUS — what reception builds
# ═══════════════════════════════════════════════════════════════════

## One dictionary per ring. `slots` is how many angular seats the ring divides the
## circle into and `stride`/`slot_offset` say which of those seats this ring takes —
## that is what lets two rings share one orbit and interleave instead of overlapping.
func _ring_specs() -> Array:
	var specs: Array = []
	match reception:
		"contested":
			# Twelve seats on ONE 0.9 m orbit, green on the even seats and red on the
			# odd ones, both turning the same way so the alternation never scrambles.
			# The claim wears an evenly divided collar: no side is nearer or higher.
			specs.append(_ring(support_color, 6, 0.9, 0.07, 1.0, 1.0, 12, 2, 0))
			specs.append(_ring(refute_color, 6, 0.9, 0.07, 1.0, 1.0, 12, 2, 1))
		"overturned":
			# Three supporters exiled to 1.3 m; twelve refutations crowded onto a
			# 0.45 m orbit at a fatter 0.09 m so they nearly touch the shrunken core.
			# They sit at the core's own height, not lifted, so the crowd reads as
			# closing in rather than passing overhead.
			specs.append(_ring(support_color, 3, 1.3, 0.07, 1.0, 1.0, 3, 1, 0))
			specs.append(_ring(refute_color, 12, 0.45, 0.09, 1.0, -0.7, 12, 1, 0))
		"dogma":
			# Twelve green on the near orbit, eight more green on the far one, and no
			# red ring built at all — so no red satellite and no red line exists to be
			# drawn. Twenty green lines, unanimous.
			specs.append(_ring(support_color, 12, 0.7, 0.07, 1.0, 1.0, 12, 1, 0))
			specs.append(_ring(support_color, 8, 1.1, 0.07, 1.15, -0.7, 8, 1, 0))
		"orphan":
			# Deliberately empty. No rings means no satellites and no connection lines.
			pass
		_:
			# "cited" — the shipped look, still driven by the exported counts and radii
			# so any scene-level override keeps working exactly as before.
			specs.append(_ring(support_color, support_count, orbit_radius_supports,
				0.07, 1.0, 1.0, support_count, 1, 0))
			specs.append(_ring(refute_color, refute_count, orbit_radius_refutes,
				0.07, 1.15, -0.7, refute_count, 1, 0))
	return specs


func _ring(color: Color, count: int, orbit: float, sat_r: float, y: float,
		spin: float, slots: int, stride: int, slot_offset: int) -> Dictionary:
	return {
		"color": color,
		"count": count,
		"orbit": orbit,
		"sat_r": sat_r,
		"y": y,
		"spin": spin,
		"slots": max(slots, 1),
		"stride": stride,
		"slot_offset": slot_offset,
		"nodes": [],
	}


func _central_radius() -> float:
	match reception:
		"overturned":
			return CENTRAL_R_OVERTURNED
		"orphan":
			return CENTRAL_R_ORPHAN
	return CENTRAL_R_DEFAULT


# ═══════════════════════════════════════════════════════════════════
# BUILDERS
# ═══════════════════════════════════════════════════════════════════

func _build_central() -> void:
	_central = MeshInstance3D.new()
	var s := SphereMesh.new()
	var r: float = _central_radius()
	s.radius = r
	s.height = r * 2.0
	_central.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = central_color
	mat.emission_enabled = true
	mat.emission = central_color
	mat.emission_energy_multiplier = 2.2
	_central.material_override = mat
	_central.position.y = 1.0
	_own(_central)


func _build_satellites() -> void:
	_rings = _ring_specs()
	for r in _rings.size():
		var ring: Dictionary = _rings[r]
		var color: Color = ring["color"]
		var sat_r: float = float(ring["sat_r"])
		var nodes: Array = ring["nodes"]
		for i in int(ring["count"]):
			var node := _make_sat(color, sat_r)
			_own(node)
			nodes.append(node)
			if color == refute_color:
				_refutes.append(node)
			else:
				_supports.append(node)


func _place_satellites() -> void:
	for r in _rings.size():
		var ring: Dictionary = _rings[r]
		var nodes: Array = ring["nodes"]
		var slots: int = int(ring["slots"])
		var stride: int = int(ring["stride"])
		var slot_offset: int = int(ring["slot_offset"])
		var orbit: float = float(ring["orbit"])
		var y: float = float(ring["y"])
		var spin: float = float(ring["spin"])
		for i in nodes.size():
			var sat: MeshInstance3D = nodes[i]
			if not is_instance_valid(sat):
				continue
			var a: float = TAU * float(slot_offset + i * stride) / float(slots) + _t * spin
			sat.position = Vector3(cos(a) * orbit, y, sin(a) * orbit)


func _make_sat(color: Color, sat_r: float) -> MeshInstance3D:
	var sat := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = sat_r
	s.height = sat_r * 2.0
	sat.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.3
	sat.material_override = mat
	return sat


func _build_connections() -> void:
	var center := Vector3(0, 1.0, 0)
	for r in _rings.size():
		var ring: Dictionary = _rings[r]
		var color: Color = ring["color"]
		var nodes: Array = ring["nodes"]
		for i in nodes.size():
			var sat: MeshInstance3D = nodes[i]
			if not is_instance_valid(sat):
				continue
			_draw_line("_conn_%d_%d" % [r, i], center, sat.position, color)


func _draw_line(line_name: String, a: Vector3, b: Vector3, color: Color) -> void:
	var line := MeshInstance3D.new()
	line.name = line_name
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	imm.surface_add_vertex(a)
	imm.surface_add_vertex(b)
	imm.surface_end()
	line.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = mat
	add_child(line)
	_lines.append(line)


func _build_label() -> void:
	_label = Label3D.new()
	_label.text = "the claim, and what argues with it"
	_label.font_size = 22
	_label.outline_size = 5
	_label.modulate = Color(0.95, 0.95, 0.7, 1.0)
	_label.position = Vector3(0, 1.55, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(_label)
