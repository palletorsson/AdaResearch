# Updated GraphSpace.gd with flexible structure system
# GraphSpace.gd
# Drop this on a Node3D. Assign room_scene and portal_scene in the Inspector.
@tool
extends Node3D

# @identity
# essence: force-directed graph layout — repulsion F_rep = k/d^2, spring attraction F_spring = stretch * stiffness, iterated layout_iters times to position node_count rooms connected by weighted edges
# desire: to walk through a graph — each room is a node, each bridge is an edge, and the spatial layout you traverse was computed by the same physics that arranges molecules
# critical_parameter: repulsion vs edge_stiffness ratio — high repulsion spreads rooms far apart, high stiffness pulls connected rooms close, the equilibrium defines the walkable topology
# triggers: seed parameter deterministically generates the graph; structure_type enum (RANDOM, BY_DEGREE, BY_DISTANCE) selects which building appears at each node based on graph properties
# emerges: Dijkstra distances from focal_node drive ambient lighting — rooms far from the focus grow dim and cool, creating atmospheric depth from pure graph distance
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: foundation of graph theory sequence — introduces what a graph IS as a walkable space; extends into KonigsbergBridge which constrains the topology to a specific historical problem
# truth: a graph is not a diagram — it is a set of relationships, and force-directed layout reveals that structure has a natural shape if you let physics find it

class_name GraphSpace

# Structure type enum
enum StructureType {
	RANDOM,          # Randomly choose from available structures
	BY_DEGREE,       # Choose based on node connectivity
	BY_DISTANCE,     # Choose based on distance from focal node
	SINGLE_TYPE,     # Use only one structure type
	CUSTOM_PATTERN   # Custom assignment pattern
}

# --- Assign in Inspector ---
@export var room_scene: PackedScene
@export var portal_scene: PackedScene

# --- Structure Configuration ---
@export_group("Structures")
@export var structure_scenes: Array[PackedScene] = []  # Multiple structure options
@export var structure_type: StructureType = StructureType.BY_DEGREE
@export var place_structures: bool = true
@export var structure_scale_range: Vector2 = Vector2(0.8, 1.2)  # Min/max scale variation
@export var structure_offset_y: float = 0.0
@export var structure_rotation_variation: float = 45.0  # Max random rotation in degrees

# --- Controls ---
@export_group("Graph Layout")
@export var node_count: int = 12
@export var avg_degree: float = 2.2  # average edges per node
@export var layout_iters: int = 250
@export var seed: int = 20250922
@export var room_radius: float = 6.0  # desired spacing between rooms
@export var edge_stiffness: float = 0.08  # spring force
@export var repulsion: float = 180.0  # node repulsion
@export var damping: float = 0.82
@export var bounds_radius: float = 60.0  # soft sphere bounds
@export var show_debug_links: bool = true

# --- Planar layout controls ---
@export_group("Layout")
@export var planar_layout: bool = true
@export var plane_y: float = 0.0
@export var plane_snap: float = 0.25   # 0..1, how strongly we pull toward plane

# --- Bridge system controls ---
@export_group("Bridges")
@export var make_bridges: bool = true
@export var bridge_width: float = 1.2
@export var bridge_thickness: float = 0.12

# Gameplay:
@export_group("Gameplay")
@export var focal_node: int = 0  # ambience source
@export var edge_cost_min: float = 1.0
@export var edge_cost_max: float = 3.0

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — axis `siting`
# ═══════════════════════════════════════════════════════════════════
#
# What law puts the rooms where they are — whether the graph's resting shape is
# relaxed out of its own tensions, imposed as a grid, drawn as the textbook
# circle, lifted off the ground plane, or centred on one hub.
#
#   relaxed  THE SHIPPED LOOK, byte-for-byte: 250 spring iterations with
#            planar_layout on, 12 rooms scattered irregularly over a ~70 m disc
#            at y = 0, bridges 1.2 m wide spanning 8-20 m each.
#   lattice  rooms snapped to a 4 x 3 grid at 12 m pitch (36 x 24 m overall),
#            edges kept ONLY between orthogonal neighbours — 17 bridges, every
#            one exactly 12.0 m and axis-aligned. This is the value that earns
#            the axis: it builds, at room scale, the sequence's retroactive
#            claim that every cellular-automaton cell was a node and every
#            adjacency an edge.
#   circle   all 12 rooms on one 30 m-radius circle (60 m across), layout
#            iterations skipped entirely, the shipped edge set redrawn as chords
#            across an empty 60 m middle — the textbook diagram underfoot.
#   shell    planar constraint off and the relaxation projected onto a 24 m
#            sphere each step: y from -24 to +24, footprint a 48 m cube, no
#            ground plane at all — the plane the whole sequence has quietly
#            assumed is removed.
#   star     one hub room at the origin and node_count-1 rooms on a 26 m ring,
#            radial bridges 26 m long and NO chords — 52 m across, with 11
#            wedges of empty ground between the spokes. Centrality becomes
#            architecture: every walk passes through the hub.
#
# Room positions and bridge spans are the only knob at this scale that reads.
# The artifact is ~85 m of walkable graph; an emission or colour delta across
# that distance is invisible in a still.
@export_enum("relaxed", "lattice", "circle", "shell", "star") var siting: String = "relaxed"

## Allow-list for _pick_axis. A map token outside these five is a typo and must
## fall back to the shipped look rather than strand a placement with no layout.
const SITINGS: PackedStringArray = ["relaxed", "lattice", "circle", "shell", "star"]

## Metres between lattice cells. 12 m ≈ twice the relaxed layout's room_radius,
## which is what keeps the 4 x 3 grid legible as a grid instead of a clump.
const LATTICE_PITCH: float = 12.0
## Circle radius — 60 m across, comfortably wider than the relaxed disc is deep,
## so the empty middle is the subject.
const CIRCLE_RADIUS: float = 30.0
## Sphere radius for `shell`. 48 m cube footprint.
const SHELL_RADIUS: float = 24.0
## Ring radius for `star`. 52 m across.
const STAR_RADIUS: float = 26.0

# CAPTIONS — deliberately none.
# There are ZERO Label3D nodes in this artifact; the only occurrence of the
# string in this file is the `# needs:` line of the @identity header above, which
# is a false positive. So LabelFramer has nothing to frame: plates = 0 and
# frontal crossing = 0 at all five values by construction. A caption is NOT added
# here on purpose — an 85 x 80 m walkable body framed at that distance would need
# a ~1 m glyph (font_size 200) to be readable at all, and inventing that plate is
# a separate design decision with its own risk. If one is ever wanted, the safe
# station is (0, highest_room_top + 4.0, 0) with billboard ENABLED, computed from
# the built AABB AFTER _instantiate_world() — because `shell` and `star` move the
# body's top by tens of metres and a hard-coded height would sink into the rooms.

# Internal
var rng: RandomNumberGenerator
var nodes := []  # Array[Dictionary]: {"pos": Vector3, "vel": Vector3, "inst": Node3D, "degree": int}
var edges := []  # Array[Dictionary]: {"a": int, "b": int, "w": float, "portal": Node}
var adjacency := []  # Array[Array[{to:int, w:float}]]

## Every node THIS script parented. Freed on rebuild; grid-added children
## (auto-grounding helpers, curation plates) are never touched.
var _created: Array[Node] = []
var _built: bool = false

func _ready() -> void:
	_build_all()
	_built = true

## The whole build, SYNCHRONOUS, from @export values alone. No call_deferred
## anywhere on this path: a deferred rebuild that removes children first makes
## the grid's auto-grounding measure a zero AABB and bail.
func _build_all() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = seed
	_build_graph()
	_layout_graph()
	_instantiate_world()
	_apply_ambience_by_distance()
	update_gizmos()

# ---------------------------
# 1) Build a connected, weighted undirected graph
# ---------------------------
func _build_graph() -> void:
	nodes.clear()
	edges.clear()
	adjacency = []
	
	for i in node_count:
		nodes.append({
			"pos": _rand_sphere(bounds_radius * 0.25),
			"vel": Vector3.ZERO,
			"inst": null,
			"degree": 0,
			"structure": null
		})
		adjacency.append([])

	# `siting` chooses the WIRING as well as the positions. relaxed / circle /
	# shell all keep the shipped random graph and differ only in where it rests;
	# lattice and star replace the edge set outright, because a grid whose edges
	# were random chords would not be a grid and a star with chords would not be
	# a star.
	match siting:
		"lattice":
			_wire_lattice()
		"star":
			_wire_star()
		_:
			_wire_relaxed()

	# Calculate node degrees
	_calculate_node_degrees()

## The shipped wiring, unchanged: a random spanning tree for connectivity, then
## extra chords up to approx avg_degree. Kept verbatim — including the order of
## rng draws — so `relaxed` is the pre-promotion graph exactly.
func _wire_relaxed() -> void:
	# Ensure connectivity via a random spanning tree
	var remaining := []
	for i in node_count:
		remaining.append(i)

	var connected := [remaining.pop_front()]
	while remaining.size() > 0:
		var a = connected[rng.randi() % connected.size()]
		var b = remaining.pop_at(rng.randi() % remaining.size())
		_add_edge(a, b, _rand_cost())
		connected.append(b)

	# Add extra edges to reach approx avg_degree
	var target_edges := int(round((avg_degree * node_count) / 2.0))
	while edges.size() < target_edges:
		var a = rng.randi() % node_count
		var b = rng.randi() % node_count
		if a == b:
			continue
		if !_has_edge(a, b):
			_add_edge(a, b, _rand_cost())

## Orthogonal 4-neighbour wiring over a cols x rows grid. At node_count = 12 this
## is 4 x 3 → 9 horizontal + 8 vertical = 17 edges, every one exactly one pitch
## long. Weights still come from _rand_cost so the Dijkstra ambience keeps its
## depth gradient.
func _wire_lattice() -> void:
	var cols: int = _lattice_cols()
	for i in node_count:
		var col: int = i % cols
		if col < cols - 1 and i + 1 < node_count:
			_add_edge(i, i + 1, _rand_cost())
		if i + cols < node_count:
			_add_edge(i, i + cols, _rand_cost())

## Hub-and-spokes: node 0 to every other node, nothing else. node_count - 1
## edges, no chords at all.
func _wire_star() -> void:
	for i in range(1, node_count):
		_add_edge(0, i, _rand_cost())

## Columns of the lattice. ceil(sqrt(n)) → 4 at the shipped node_count of 12,
## giving 4 x 3. Generic so a map that raises node_count still gets a grid.
func _lattice_cols() -> int:
	if node_count <= 1:
		return 1
	var c: int = int(ceil(sqrt(float(node_count))))
	if c < 1:
		c = 1
	return c

## Orientation for a bridge or portal spanning `dir`. Identical to the shipped
## Basis.looking_at(dir, Vector3.UP) for every horizontal edge — which is all of
## them at relaxed / lattice / circle / star. `shell` is the reason this exists:
## a near-vertical chord between two nodes on the sphere makes looking_at's up
## vector degenerate, and the fallback keeps that bridge oriented instead of
## snapping to identity.
func _facing_basis(dir: Vector3) -> Basis:
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.FORWARD
	return Basis.looking_at(dir, up)

func _add_edge(a: int, b: int, w: float) -> void:
	edges.append({"a": a, "b": b, "w": w, "portal": null})
	adjacency[a].append({"to": b, "w": w})
	adjacency[b].append({"to": a, "w": w})

func _has_edge(a: int, b: int) -> bool:
	for e in edges:
		if (e.a == a and e.b == b) or (e.a == b and e.b == a):
			return true
	return false

func _calculate_node_degrees() -> void:
	for i in node_count:
		var degree = 0
		for e in edges:
			if e.a == i or e.b == i:
				degree += 1
		nodes[i]["degree"] = degree

func _rand_cost() -> float:
	return lerp(edge_cost_min, edge_cost_max, rng.randf())

func _rand_sphere(r: float) -> Vector3:
	var dir = Vector3(rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0).normalized()
	return dir * (rng.randf() * r)

# ---------------------------
# 2) Force-directed 3D layout with planar option
# ---------------------------
func _layout_graph() -> void:
	match siting:
		"lattice":
			_place_lattice()
		"circle":
			_place_circle()
		"star":
			_place_star()
		"shell":
			# planar_layout off, plane_snap 0, relaxation confined to a sphere.
			_relax(false, SHELL_RADIUS)
		_:
			# `relaxed` — the shipped path, driven by the exports as before.
			_relax(planar_layout, 0.0)

## The force-directed relaxation. `planar` kills the vertical force component and
## pulls toward plane_y; `shell_radius` above 0 instead projects every node onto
## a sphere of that radius after each integration step, which is what turns the
## same spring/repulsion physics into a spherical embedding.
func _relax(planar: bool, shell_radius: float) -> void:
	for _i in layout_iters:
		# repulsion
		for i in node_count:
			var force := Vector3.ZERO
			var pi: Vector3 = nodes[i]["pos"]

			for j in node_count:
				if i == j:
					continue
				var pj: Vector3 = nodes[j]["pos"]
				var d := pi.distance_to(pj) + 0.001
				var dir := (pi - pj) / d
				force += dir * (repulsion / (d * d))

			# spring attraction along edges
			for nb in adjacency[i]:
				var j = nb.to
				var pj2: Vector3 = nodes[j]["pos"]
				var d2 := pi.distance_to(pj2) + 0.001
				var dir2 := (pj2 - pi).normalized()
				var desired := room_radius
				var stretch := d2 - desired
				force += dir2 * (stretch * edge_stiffness)

			# soft bounds pull
			var dist := pi.length()
			if dist > bounds_radius:
				force += -pi.normalized() * (dist - bounds_radius) * 0.02

			# Apply planar layout constraints
			if planar:
				# Kill vertical component of forces (XZ only)
				force.y = 0.0

			nodes[i]["vel"] = (nodes[i]["vel"] + force) * damping

		# Integrate
		for i in node_count:
			nodes[i]["pos"] += nodes[i]["vel"]

			# Gentle attraction to plane
			if planar:
				nodes[i]["pos"].y = lerp(nodes[i]["pos"].y, plane_y, plane_snap)

			# Or onto the shell. Deterministic fallback direction if a node has
			# somehow landed exactly on the origin.
			if shell_radius > 0.0:
				var p: Vector3 = nodes[i]["pos"]
				if p.length() < 0.001:
					p = Vector3(0.0, 1.0, 0.0)
				nodes[i]["pos"] = p.normalized() * shell_radius

## 4 x 3 cells at 12 m pitch, centred on the origin: 36 x 24 m overall, flat at
## plane_y. Layout iterations are skipped — the grid IS the law here, not an
## equilibrium the physics happens to find.
func _place_lattice() -> void:
	var cols: int = _lattice_cols()
	var rows: int = int(ceil(float(node_count) / float(cols)))
	var ox: float = (float(cols) - 1.0) * 0.5
	var oz: float = (float(rows) - 1.0) * 0.5
	for i in node_count:
		var col: int = i % cols
		var row: int = i / cols
		nodes[i]["pos"] = Vector3(
			(float(col) - ox) * LATTICE_PITCH,
			plane_y,
			(float(row) - oz) * LATTICE_PITCH)
		nodes[i]["vel"] = Vector3.ZERO

## Every room on one 30 m circle in graph-index order, 60 m across. The shipped
## edge set survives and is redrawn as chords over the empty middle; how long the
## longest chord runs is whatever the seeded graph gives (an edge between
## antipodal indices spans the full 60 m diameter).
func _place_circle() -> void:
	var count: int = node_count
	if count < 1:
		count = 1
	for i in node_count:
		var a: float = TAU * float(i) / float(count)
		nodes[i]["pos"] = Vector3(cos(a) * CIRCLE_RADIUS, plane_y, sin(a) * CIRCLE_RADIUS)
		nodes[i]["vel"] = Vector3.ZERO

## Hub at the origin, the rest evenly spaced on a 26 m ring: 52 m across, with
## one empty wedge of ground between each pair of spokes.
func _place_star() -> void:
	if node_count <= 0:
		return
	nodes[0]["pos"] = Vector3(0.0, plane_y, 0.0)
	nodes[0]["vel"] = Vector3.ZERO
	var spokes: int = node_count - 1
	if spokes < 1:
		spokes = 1
	for i in range(1, node_count):
		var a: float = TAU * float(i - 1) / float(spokes)
		nodes[i]["pos"] = Vector3(cos(a) * STAR_RADIUS, plane_y, sin(a) * STAR_RADIUS)
		nodes[i]["vel"] = Vector3.ZERO

# ---------------------------
# 3) Flexible Structure Selection System
# ---------------------------
func _select_structure_for_node(node_index: int) -> PackedScene:
	if structure_scenes.is_empty():
		return null
	
	match structure_type:
		StructureType.RANDOM:
			return structure_scenes[rng.randi() % structure_scenes.size()]
		
		StructureType.BY_DEGREE:
			return _select_by_degree(node_index)
		
		StructureType.BY_DISTANCE:
			return _select_by_distance(node_index)
		
		StructureType.SINGLE_TYPE:
			return structure_scenes[0]
		
		StructureType.CUSTOM_PATTERN:
			return _select_by_custom_pattern(node_index)
		
		_:
			return structure_scenes[0]

func _select_by_degree(node_index: int) -> PackedScene:
	var degree = nodes[node_index]["degree"]
	var max_degree = 0
	for i in node_count:
		max_degree = max(max_degree, nodes[i]["degree"])
	
	if max_degree == 0:
		return structure_scenes[0]
	
	# Map degree to structure index
	var structure_index = int((float(degree) / float(max_degree)) * (structure_scenes.size() - 1))
	return structure_scenes[clamp(structure_index, 0, structure_scenes.size() - 1)]

func _select_by_distance(node_index: int) -> PackedScene:
	var distances = _dijkstra(focal_node)
	var max_distance = 0.0
	for d in distances:
		if d != INF:
			max_distance = max(max_distance, d)
	
	if max_distance <= 0.0:
		return structure_scenes[0]
	
	var normalized_distance = clamp(distances[node_index] / max_distance, 0.0, 1.0)
	var structure_index = int(normalized_distance * (structure_scenes.size() - 1))
	return structure_scenes[clamp(structure_index, 0, structure_scenes.size() - 1)]

func _select_by_custom_pattern(node_index: int) -> PackedScene:
	# Example custom pattern: alternate structures in a pattern
	# You can modify this to create any pattern you want
	match node_index % 4:
		0: return structure_scenes[0] if structure_scenes.size() > 0 else null
		1: return structure_scenes[1 % structure_scenes.size()]
		2: return structure_scenes[0] if structure_scenes.size() > 0 else null
		3: return structure_scenes[min(2, structure_scenes.size() - 1)]
		_: return structure_scenes[0]

# ---------------------------
# 4) Instantiate world with flexible structures
# ---------------------------
func _instantiate_world() -> void:
	# Rooms
	for i in node_count:
		if room_scene:
			var room := room_scene.instantiate()
			room.name = "Room_%d" % i
			room.transform.origin = nodes[i]["pos"]
			add_child(room)
			_created.append(room)
			nodes[i]["inst"] = room
		
		# Place structure at each intersection/node with flexible selection
		if place_structures and structure_scenes.size() > 0:
			var selected_structure_scene = _select_structure_for_node(i)
			if selected_structure_scene:
				var structure := selected_structure_scene.instantiate()
				structure.name = "Structure_%d" % i
				
				# Position with offset
				var struct_pos = nodes[i]["pos"]
				struct_pos.y += structure_offset_y
				structure.position = struct_pos
				
				# Apply variable scaling
				var scale_factor = rng.randf_range(structure_scale_range.x, structure_scale_range.y)
				structure.scale = Vector3.ONE * scale_factor
				
				# Apply rotation variation
				var rotation_y = rng.randf_range(-structure_rotation_variation, structure_rotation_variation) * PI / 180.0
				structure.rotation.y = rotation_y
				
				# Additional rotation based on node properties (optional)
				if structure_type == StructureType.BY_DEGREE:
					structure.rotation.y += (nodes[i]["degree"] * 15.0) * PI / 180.0
				
				add_child(structure)
				_created.append(structure)
				nodes[i]["structure"] = structure
	
	# Pre-collect unit directions to neighbors per node
	var neighbor_dirs := []
	neighbor_dirs.resize(node_count)
	for i in node_count:
		neighbor_dirs[i] = []
	
	for e in edges:
		var a  = e.a
		var b  = e.b
		var pa: Vector3 = nodes[a]["pos"]
		var pb: Vector3 = nodes[b]["pos"]
		var ab := (pb - pa).normalized()
		neighbor_dirs[a].append(ab)
		neighbor_dirs[b].append(-ab)
	
	# Carve doors toward each neighbor
	for i in node_count:
		var room  = nodes[i]["inst"]
		if room and room.has_method("carve_door_facing"):
			for d in neighbor_dirs[i]:
				room.call("carve_door_facing", d)
	
	# Portals/links + bridges
	for e in edges:
		var a = e.a
		var b = e.b
		var pa: Vector3 = nodes[a]["pos"]
		var pb: Vector3 = nodes[b]["pos"]
		var mid := (pa + pb) * 0.5
		var dir := (pb - pa).normalized()
		var dist := pa.distance_to(pb)
		
		# Create bridge first (walkable pathway)
		if make_bridges:
			var bridge := CSGBox3D.new()
			bridge.name = "Bridge_%d_%d" % [a, b]
			bridge.size = Vector3(bridge_width, bridge_thickness, dist)  # Z = length
			var basis := _facing_basis(dir)  # -Z faces dir
			bridge.transform = Transform3D(basis, mid)
			bridge.operation = CSGShape3D.OPERATION_UNION
			bridge.use_collision = true
			add_child(bridge)
			_created.append(bridge)
		
		# Create portal (on top of bridge if both exist)
		if portal_scene:
			var portal := portal_scene.instantiate()
			portal.name = "Portal_%d_%d" % [a, b]
			var basis := _facing_basis(dir)
			portal.transform = Transform3D(basis, mid)
			
			# Optional: scale/mesh length to span between rooms if your portal uses a beam
			if portal.has_method("set_link_length"):
				portal.call("set_link_length", dist)
			
			# Tell the portal who it connects
			if portal.has_method("set_link_nodes"):
				portal.call("set_link_nodes", a, b)
			
			add_child(portal)
			_created.append(portal)
			e.portal = portal

# ---------------------------
# 5) Compute graph distances and drive ambience
# ---------------------------
func _apply_ambience_by_distance() -> void:
	var dist := _dijkstra(focal_node)
	var maxd := 0.0
	for d in dist:
		maxd = max(maxd, d)
	if maxd <= 0.0:
		maxd = 1.0
	
	for i in node_count:
		var t = clamp(dist[i] / maxd, 0.0, 1.0)
		# Example mappings:
		# - room light gets cooler & dimmer as distance increases
		# - background audio volume lowers with distance
		var room = nodes[i]["inst"]
		if room == null:
			continue
		
		if room.has_node("Light"):
			var light = room.get_node("Light")
			if light is OmniLight3D:
				light.light_energy = lerp(4.0, 0.8, t)
		
		if room.has_node("AudioStream"):
			var audio = room.get_node("AudioStream")
			if audio is AudioStreamPlayer3D:
				audio.volume_db = lerp(-2.0, -12.0, t)

# Dijkstra for non-negative weights
func _dijkstra(src: int) -> PackedFloat32Array:
	var dist := PackedFloat32Array()
	dist.resize(node_count)
	for i in node_count:
		dist[i] = INF
	dist[src] = 0.0
	
	var visited := {}
	while visited.size() < node_count:
		var u := -1
		var best := INF
		for i in node_count:
			if i in visited:
				continue
			if dist[i] < best:
				best = dist[i]
				u = i
		if u == -1:
			break
		visited[u] = true
		
		for nb in adjacency[u]:
			var alt = dist[u] + nb.w
			if alt < dist[nb.to]:
				dist[nb.to] = alt
	
	return dist

# ---------------------------
# Debug draw in-editor (Godot gizmos)
# ---------------------------
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update_gizmos()

func _get_configuration_warnings() -> PackedStringArray:
	var warns: PackedStringArray = []
	if room_scene == null:
		warns.append("Assign a Room PackedScene.")
	if portal_scene == null:
		warns.append("Assign a Portal PackedScene.")
	if structure_scenes.is_empty() and place_structures:
		warns.append("Add Structure PackedScenes to the array or disable place_structures.")
	return warns

func _draw() -> void:
	if !show_debug_links:
		return
	for e in edges:
		var pa: Vector3 = nodes[e.a]["pos"]
		var pb: Vector3 = nodes[e.b]["pos"]
		get_viewport().debug_draw_line_3d(pa, pb, Color(0.3, 0.9, 1.0, 0.7))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Called by GridInteractablesComponent via call_deferred, AFTER _ready() and
## first in the deferred queue — so the artifact is already standing when this
## arrives and the only job here is to notice a real change and rebuild.
##
## Keys accepted: `siting` only. Nothing else is read, deliberately: the
## curation station hands EVERY artifact it curates {"emissive": false} one line
## after framing its labels, and this artifact owns no material it could honestly
## apply that to — 12 rooms and their portals are separate scenes, and the
## bridges are untextured CSG. Accepting the key and applying it nowhere is the
## exact failure this pass exists to stop, so the dict simply changes nothing,
## which is what it is supposed to do.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_siting: String = siting

	if config_data.has("siting"):
		siting = _pick_axis(str(config_data["siting"]), SITINGS, siting)

	if not _built:
		return
	if siting == before_siting:
		return

	_rebuild_now()
	print("[GraphSpace] Config applied — siting=%s" % [siting])

## Accept an axis value only if it names something we actually build. A typo in a
## map token falls back to the shipped look rather than leaving a placement with
## no layout at all.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback

## Tear down and rebuild, SYNCHRONOUSLY and inline. Only nodes this script
## parented are freed — freeing get_children() would destroy grid-added plates
## and the curation station's framed labels.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_created.clear()
	nodes.clear()
	edges.clear()
	adjacency = []
	_build_all()
