# @identity
# essence: eleven cutters placed by a seeded walk, unioned and subtracted from a block
# desire: compare an overlap graph with the clearance an actual body needs
# critical_parameter: carver_profile — sphere keeps the original scalloped hollow;
# level uses cylinders with the same centres and radius to make a level floor
# triggers: map configuration chooses the cutter profile, section, roof and stock/cast
# emerges: a connected cutter graph may still produce a passage a body cannot use
# needs: CSG collision, a supporting museum floor, a body with known dimensions
# relationships: contrast csg_architecture_cavity's visual wall and sdf_cavern_room's raised model
# truth: a geometric connection and a traversable connection are different claims

extends Node3D
class_name BooleanBurrow

@export_category("The carve")
## THE WALK, PINNED. Eleven carvers placed by one seeded walk. Change this and
## you get a different cave from the same rule — which is the point: nobody
## authored the hollow, and two seeds are two caves nobody authored.
##
## Named `generation_seed` because GDScript has a global `seed()` AND because it
## is one of the 302 keys in GridInteractablesComponent.CONFIG_PARAM_NAMES — an
## unlisted key with a numeric value is read as the positional shorthand and
## silently sets the yaw instead.
@export var generation_seed: int = 20260907
@export_range(3, 24) var carver_count: int = 11
## Metres. Body-sized on purpose: a carver you cannot stand in is a decoration.
@export var carver_radius: float = 1.15
@export var step_length: float = 1.6
## How far the walk may turn per step, in degrees. Small is a corridor, large is
## a warren that folds back through itself — and 55 was too large: the first
## capture came back as one blob in a corner, which the artifact's own
## connectivity readout had already said before anyone looked at the picture
## (11 carvers, 1 component, 14 independent cycles = 24 overlapping pairs out of
## 55 possible). A burrow is a walk that leaves; 26 leaves.
@export var turn_deg: float = 26.0
## How hard the walk is pulled back toward +X after each turn. 0 is a free random
## walk (which folds); 1 is a straight line (which is a tunnel, not a burrow).
@export_range(0.0, 1.0) var forward_bias: float = 0.35
@export var block_size: Vector3 = Vector3(11.0, 5.0, 9.0)

@export_category("The axes")
## WHICH OF THE TWO BODIES A DIFFERENCE PRODUCES IS THE OBJECT.
##
## Every subtraction makes two things — what is left standing and what was taken
## out — and a boundary model throws the second away because it never had a
## volume, only a surface and a rule. Same seed, same eleven carvers, same
## operand list; three lawful readings of it.
##
##   rock      A − S. The stone with the hollow in it. THE SHIPPED OBJECT.
##   cast      S alone. The removed volume, standing up in the room as a body.
##
## A third value, `returned` — both bodies drawn in place — was declared, swept
## and DROPPED on 2026-09-07. It measured byte-identical to `rock`: 0 of 577,600
## pixels, because a body drawn back inside opaque stone is invisible from every
## standpoint and not merely from the canonical one. Averaged over the axis it
## would have passed, carried entirely by the rock/cast reframe, which is the
## documented way a three-value axis that is really a two-value axis survives.
@export_enum("rock", "cast") var spoil: String = "rock"

## HOW MUCH STONE STANDS OVER THE HOLLOW.
##
## The hollow is the SAME hollow at all four rungs — same seed, same carvers,
## same walk — and the only thing that moves is the roof. Chosen because it is
## the one property of an interior a camera OUTSIDE the object can actually see:
## csg_architecture_cavity's step from one wall to a four-walled room, the rung
## its own source calls the first on which the player is INSIDE, measures 4.372%
## of pixels, because a camera standing outside a room cannot see that it has an
## inside.
##
##   roofed    nothing removed; the hollow is sealed under solid stone
##   broached  one shaft, where the walk's first carver reaches the surface
##   skylit    a roof opening over the middle of the run
##   ruined    the roof slab gone over the hollow's whole footprint
@export_enum("roofed", "broached", "skylit", "ruined") var overburden: String = "roofed"

@export_category("The body")
@export var stone_color: Color = Color(0.52, 0.50, 0.46)
@export var spoil_color: Color = Color(0.83, 0.36, 0.20)
## THE SECTION CUT — a second subtraction that removes the near slab, so the
## interior is photographable by the same verb that made it. Without it the
## whole artifact is a box from every standpoint the capture harness uses.
@export var section: bool = true
@export var section_depth: float = 2.4
## The chapter's own indictment: "twelve of the chapter's thirteen artifacts
## contain no collision construct of any kind." One flag is the remedy.
@export var walkable: bool = true
## Spheres keep the original sculptural carve. Upright cylinders use the same
## centres and radius but give the hollow a level floor and 2.3 m headroom.
## A connected overlap graph alone cannot establish clearance for a body.
@export_enum("sphere", "level") var carver_profile: String = "sphere"

## The carver floor sits this far below its own centre height, so every carver's
## lowest point is the ground plane and the hollow's floor IS the map's floor —
## the concrete rebuttal to a cavern that begins 1.2 m up in the air.
const FLOOR_EPS: float = 0.02

var _centres: Array[Vector3] = []
var _components: int = 0
var _cycles: int = 0


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	_plan_walk()
	_measure_connectivity()

	var stock := _build_stock()
	add_child(stock)

	# THE SPOIL, AS A BODY. Built a second time OUTSIDE the boolean tree, from the
	# same centres, so `cast` and `returned` can show the volume the subtraction
	# consumed. It is the same list read the other way round, not a new object.
	var body := _build_spoil_body()
	add_child(body)

	stock.visible = spoil != "cast"
	body.visible = spoil != "rock"
	if carver_profile == "level" and spoil == "rock":
		# Interior light is part of making the negative inspectable at body height.
		for i in [0, 3, 6]:
			if i >= _centres.size(): continue
			var lamp := OmniLight3D.new()
			lamp.position = _centres[i] + Vector3(0, 0.6, 0)
			lamp.light_color = Color(1.0, 0.86, 0.67)
			lamp.light_energy = 0.5
			lamp.omni_range = 4.0
			add_child(lamp)
		var invitation := Label3D.new()
		invitation.name = "EntranceLabel"
		invitation.text = "TRY THE OPENING"
		invitation.font_size = 24
		invitation.pixel_size = 0.002
		invitation.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		invitation.position = Vector3(-block_size.x * 0.5 - 0.15, 2.6, _centres[0].z)
		add_child(invitation)

	print("boolean_burrow: seed %d, %d carvers, %d component(s), %d independent cycle(s)"
			% [generation_seed, _centres.size(), _components, _cycles])


## ELEVEN SOLIDS, PLACED BY A WALK NOBODY STEERS.
##
## The walk starts at one face, turns by at most turn_deg each step and reflects
## off the inside of an inset box so it stays in the stone. Every centre is put
## at y = carver_radius − FLOOR_EPS: the carve's floor is the ground, at every
## step, for the hollow's whole length.
func _plan_walk() -> void:
	_centres.clear()
	seed(generation_seed)

	var half := block_size * 0.5
	var inset := carver_radius * 0.85
	var y: float = carver_radius - FLOOR_EPS
	var pos := Vector3(-half.x + inset, y, randf_range(-half.z + inset, half.z - inset))
	var heading: float = randf_range(-0.6, 0.6)

	for i in range(maxi(3, carver_count)):
		_centres.append(pos)
		heading += deg_to_rad(randf_range(-turn_deg, turn_deg))
		# AND IT HAS TO GET SOMEWHERE. Eleven steps of 1.6 m is 17.6 m of path in an
		# 11x9 box, so an unbiased walk MUST fold back into itself: the first two
		# captures returned 14 and then 18 independent cycles from 11 carvers — 24
		# and 28 overlapping pairs out of 55 — which is a mass, not a burrow.
		# Turning the turn down did not help because the fold is a consequence of
		# path length against box size, not of turn rate. Pulling the heading back
		# toward +X each step keeps the wander and makes it cross.
		heading = lerp_angle(heading, 0.0, forward_bias)
		var nxt := pos + Vector3(cos(heading), 0.0, sin(heading)) * step_length
		# reflect off the inset walls rather than clamping: a clamp piles carvers
		# up in a corner and quietly makes the last four steps one blob
		if nxt.x < -half.x + inset or nxt.x > half.x - inset:
			heading = PI - heading
			nxt = pos + Vector3(cos(heading), 0.0, sin(heading)) * step_length
		if nxt.z < -half.z + inset or nxt.z > half.z - inset:
			heading = -heading
			nxt = pos + Vector3(cos(heading), 0.0, sin(heading)) * step_length
		nxt.y = y
		pos = nxt


## CONNECTEDNESS IS COMPUTED, NOT CLAIMED.
##
## Union-find on overlapping cutters. E − V + C counts graph cycles. It does
## not count holes in the resulting solid: three mutually overlapping cutters
## can make a graph cycle without leaving an island. Neither count proves body
## clearance through the extracted surface.
func _measure_connectivity() -> void:
	var n: int = _centres.size()
	var parent: Array[int] = []
	for i in range(n):
		parent.append(i)

	var edges: int = 0
	for i in range(n):
		for j in range(i + 1, n):
			if _centres[i].distance_to(_centres[j]) < carver_radius * 2.0 - 0.05:
				edges += 1
				var a := _find(parent, i)
				var b := _find(parent, j)
				if a != b:
					parent[a] = b

	var roots := {}
	for i in range(n):
		roots[_find(parent, i)] = true
	_components = roots.size()
	_cycles = maxi(0, edges - n + _components)


func _find(parent: Array[int], i: int) -> int:
	var r: int = i
	while parent[r] != r:
		r = parent[r]
	return r


## THE STOCK, AND THE ONE SUBTRACTION.
##
## Topology matters here and it is a performance argument as much as a design
## one: eleven cheap unions among small primitives inside a child combiner, then
## ONE boolean against the massif — rather than eleven sequential subtractions
## each of which touches the whole block.
func _build_stock() -> CSGCombiner3D:
	var stock := CSGCombiner3D.new()
	stock.name = "Stock"
	stock.use_collision = walkable and spoil == "rock"
	stock.material_override = _stone()

	var mass := CSGBox3D.new()
	mass.name = "Massif"
	mass.size = block_size
	mass.position = Vector3(0, block_size.y * 0.5, 0)
	stock.add_child(mass)

	# THE NEGATIVE, AS A NAMED NODE. Not a loop of subtractions — one child called
	# Spoil that holds the whole removed volume and is taken out exactly once.
	var spoil_node := CSGCombiner3D.new()
	spoil_node.name = "Spoil"
	spoil_node.operation = CSGShape3D.OPERATION_SUBTRACTION
	for i in range(_centres.size()):
		spoil_node.add_child(_carver(i, _centres[i]))
	stock.add_child(spoil_node)

	var roof := _roof_cut()
	if roof != null:
		stock.add_child(roof)

	if section:
		# the same verb that made the hollow is the one that makes it visible
		var cut := CSGBox3D.new()
		cut.name = "Section"
		cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		cut.size = Vector3(block_size.x + 2.0, block_size.y + 2.0, section_depth)
		cut.position = Vector3(0, block_size.y * 0.5,
				block_size.z * 0.5 - section_depth * 0.5 + 0.01)
		stock.add_child(cut)

	return stock


func _carver(i: int, at: Vector3) -> CSGShape3D:
	if carver_profile == "level":
		var column := CSGCylinder3D.new()
		column.name = "Carver%02d" % i
		column.radius = carver_radius
		column.height = carver_radius * 2.0
		column.sides = 24
		column.position = at
		return column
	var s := CSGSphere3D.new()
	s.name = "Carver%02d" % i
	s.radius = carver_radius
	s.radial_segments = 16
	s.rings = 10
	s.position = at
	return s


## The roof pass. The hollow does not change on this axis — only the stone above
## it — so every value here is a subtraction from the TOP of the block, sized and
## placed from the walk that already happened.
func _roof_cut() -> CSGShape3D:
	if overburden == "roofed" or _centres.is_empty():
		return null

	if overburden == "broached":
		var shaft := CSGCylinder3D.new()
		shaft.name = "Broach"
		shaft.operation = CSGShape3D.OPERATION_SUBTRACTION
		shaft.radius = carver_radius * 0.45
		shaft.height = block_size.y + 2.0
		shaft.position = Vector3(_centres[0].x, block_size.y * 0.5, _centres[0].z)
		return shaft

	if overburden == "skylit":
		var mid: Vector3 = _centres[_centres.size() / 2]
		var eye := CSGCylinder3D.new()
		eye.name = "Skylight"
		eye.operation = CSGShape3D.OPERATION_SUBTRACTION
		eye.radius = carver_radius * 1.25
		eye.height = block_size.y + 2.0
		eye.position = Vector3(mid.x, block_size.y * 0.5, mid.z)
		return eye

	# ruined — the roof slab gone over the hollow's whole footprint
	var lo := _centres[0]
	var hi := _centres[0]
	for c in _centres:
		lo = Vector3(minf(lo.x, c.x), 0.0, minf(lo.z, c.z))
		hi = Vector3(maxf(hi.x, c.x), 0.0, maxf(hi.z, c.z))
	var slab := CSGBox3D.new()
	slab.name = "Ruin"
	slab.operation = CSGShape3D.OPERATION_SUBTRACTION
	var pad := carver_radius * 1.1
	var top: float = block_size.y - (carver_radius * 2.0 - FLOOR_EPS)
	slab.size = Vector3((hi.x - lo.x) + pad * 2.0, top + 1.0, (hi.z - lo.z) + pad * 2.0)
	slab.position = Vector3((lo.x + hi.x) * 0.5,
			block_size.y - slab.size.y * 0.5 + 0.5, (lo.z + hi.z) * 0.5)
	return slab


## The removed volume as a thing you can look at. Same centres, unioned, no
## stock — so `cast` is the cave with the rock taken away rather than a model of
## the cave.
func _build_spoil_body() -> CSGCombiner3D:
	var body := CSGCombiner3D.new()
	body.name = "SpoilBody"
	body.material_override = _spoil_skin()
	for i in range(_centres.size()):
		body.add_child(_carver(i, _centres[i]))
	return body


func _stone() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = stone_color
	m.roughness = 0.92
	m.metallic = 0.0
	return m


func _spoil_skin() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = spoil_color
	m.roughness = 0.55
	m.metallic = 0.0
	return m


## How many carvers, how many places, how many loops — for a probe or a readout.
func report() -> Dictionary:
	return {
		"seed": generation_seed,
		"carvers": _centres.size(),
		"components": _components,
		"cycles": _cycles,
		"spoil": spoil,
		"overburden": overburden,
		"carver_profile": carver_profile,
		"connectivity_scope": "overlap graph, not body clearance or cavity topology",
	}


## Called by the grid system to apply per-cell configuration. Keys honoured:
##   "generation_seed" · "carver_count" · "carver_radius" · "step_length"
##   "turn_deg" · "spoil" · "overburden" · "section" · "walkable"
##   "stone_color" / "spoil_color"
## The two axis keys take WORDS, which is what makes them safe in both engines:
## the grid reads `#key:<number>` on a key outside CONFIG_PARAM_NAMES as the
## positional shorthand, so a numeric axis value would set the yaw instead.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("carver_profile") and str(config_data["carver_profile"]) in ["sphere", "level"]:
		carver_profile = str(config_data["carver_profile"])
	if config_data.has("generation_seed"):
		generation_seed = int(config_data["generation_seed"])
	if config_data.has("carver_count"):
		carver_count = clampi(int(config_data["carver_count"]), 3, 24)
	if config_data.has("carver_radius"):
		carver_radius = float(config_data["carver_radius"])
	if config_data.has("step_length"):
		step_length = float(config_data["step_length"])
	if config_data.has("turn_deg"):
		turn_deg = float(config_data["turn_deg"])
	if config_data.has("spoil"):
		var s: String = str(config_data["spoil"]).strip_edges().to_lower()
		if s in ["rock", "cast"]:
			spoil = s
	if config_data.has("overburden"):
		var o: String = str(config_data["overburden"]).strip_edges().to_lower()
		if o in ["roofed", "broached", "skylit", "ruined"]:
			overburden = o
	if config_data.has("section"):
		section = _flag(config_data["section"])
	if config_data.has("walkable"):
		walkable = _flag(config_data["walkable"])
	if config_data.has("stone_color"):
		stone_color = _as_color(config_data["stone_color"], stone_color)
	if config_data.has("spoil_color"):
		spoil_color = _as_color(config_data["spoil_color"], spoil_color)
	if is_inside_tree():
		_build()


## `#section:0` arrives as the STRING "0", and bool("0") is true in GDScript.
func _flag(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]


func _as_color(v, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Color(float(a[0]), float(a[1]), float(a[2]))
	if v is String and str(v) != "":
		return Color(str(v))
	return fallback
