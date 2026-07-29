@tool
extends GraphSpace3D
class_name Konigsberg3D

# @identity
# essence: Euler's bridge problem embedded in a 3D river city - four landmasses become vertices, seven arched bridges become edges, and degree parity determines whether a walk can cross each bridge exactly once
# desire: to inhabit the historical paradox that started graph theory - the city looks strollable, yet every attempted route eventually proves the topology itself refuses the walk
# critical_parameter: parity - what the bridge set does to vertex degree parity, and therefore which walk the structure admits: none, an open walk, a closed circuit, or nothing at all because the graph is in pieces
# triggers: parity selects the bridge table before any geometry exists; historical_mode rebuilds the 1736 layout; show_degree_labels and show_theorem_explanation surface Euler's parity test; keyboard input can attempt the walk, toggle labels, and compare bridge-removal scenarios
# emerges: when the red odd-degree landmasses are read together, the impossibility becomes visible before it is stated - parity turns geography into proof
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [has] (degree labels, bridge nameplates, theorem label)
# relationships: specific historical counterpart to graphspace's general graph layout; prepares pathfinding and connectivity artifacts by showing that some traversal questions are answered by topology before search begins
# truth: graph theory begins when you stop asking "which route should I try?" and ask "what does the structure allow at all?"

# Enhanced Königsberg Bridge Problem for 3D Graph System
# Demonstrates the famous "Seven Bridges of Königsberg" problem in immersive 3D VR
# Shows why an Eulerian path is impossible with this specific graph topology

@export_category("Königsberg Problem")
@export var historical_mode: bool = true  # Use original 1736 layout
@export var modern_layout: bool = false   # Show modern Kaliningrad bridges
@export var show_euler_analysis: bool = true
@export var highlight_odd_degree_nodes: bool = true
@export var animate_path_attempts: bool = true

@export_category("Educational Features")
@export var show_degree_labels: bool = true
@export var show_theorem_explanation: bool = true
@export var interactive_bridge_removal: bool = true
@export var eulerian_path_demo: bool = true

@export_category("3D Visualization")
@export var river_visualization: bool = true
@export var landmass_elevation: float = 2.0
@export var bridge_arch_height: float = 1.5
@export var water_level: float = -1.0
@export var historical_building_style: bool = true

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `parity`
# ═══════════════════════════════════════════════════════════════════
#
# What the BRIDGE SET does to vertex parity, and therefore which walk the
# structure admits. The artifact that IS this sequence's founding question could
# only ever ask it in the negative: seven hard-coded bridges, four odd
# landmasses, the same four red platforms in every placement. A player learned
# "these seven bridges fail", not "odd degree is what fails". The rule only
# becomes a rule when a map can stand the solvable case next to the unsolvable
# one, and that is what this axis is for.
#
# Carried by the EDGE SET and by the platform colours it forces — not by any
# animation. Everything here is standing geometry, photographable in one frame.
#
#   blocked   The 1736 set. Four 8 m platforms 1 m thick at y=2, seven stone
#             arches 2 m wide rising 1.5 m over a 50 x 30 m river slab. Degrees
#             5/3/3/3 — every platform odd, so all four render red and no walk
#             of any kind exists. The shipped look, unchanged.
#   walk      One 24 m arch added between Kneiphof and Vorstadt: eight bridges,
#             degrees 5/3/4/4. Two platforms turn green, two stay red, and an
#             open Eulerian walk exists whose only legal start and finish are
#             those two red ends.
#   circuit   Two arches added — the Kneiphof–Vorstadt span plus a second
#             Altstadt–Löbenicht crossing standing 3 m north of the Grüne
#             Brücke. Nine bridges, every degree even, all four platforms green,
#             and the arch field over the river is visibly denser than the
#             shipped set.
#   severed   Löbenicht is cut loose: every bridge that touched it is gone and
#             the 8 m platform stands alone in open water. This is the value
#             that earns the axis. Its degrees are all EVEN — parity says yes
#             and the walk is still impossible, because the graph is in two
#             pieces. Without it, a player reads parity as the only way a walk
#             can fail. The isolated platform therefore renders neither red nor
#             green but slate, and its caption says so.
#
# DEVIATION FROM THE WRITTEN SPEC, stated rather than hidden. The spec asked for
# "the two Löbenicht bridges removed — five arches". This file's table gives
# Löbenicht THREE bridges (Grüne A–B, Köttel B–C, Honig B–D), and the graph's
# minimum cut is 3, so removing two disconnects nothing — it would merely produce
# a second graph with two odd vertices, i.e. a duplicate of `walk`. Removing
# every bridge incident to Löbenicht is the only edit that produces the
# disconnection the value is named for. Four arches remain, not five. The cut is
# derived from the node index, never from a hard-coded list, so it stays true if
# the bridge table is ever edited.
@export_enum("blocked", "walk", "circuit", "severed") var parity: String = "blocked"

## Allow-list. A typo in a map token falls back to the shipped 1736 set rather
## than stranding a placement with no bridges at all.
const PARITIES: PackedStringArray = ["blocked", "walk", "circuit", "severed"]

## The landmass `severed` cuts loose — Löbenicht, index 1 in the topology below.
const SEVERED_NODE: int = 1

## Metres a genuinely parallel pair of nameplates is fanned apart, perpendicular
## to the bridge they name. There really are two bridges there, so the caption
## says two bridges; the arches themselves are untouched.
const PARALLEL_FAN: float = 0.9
## Metres a nameplate drops when a DIFFERENT bridge already claimed this exact
## midpoint — `walk` and `circuit` send a span straight over the Grüne Brücke's
## centre. 0.40 m leaves a 0.09 m gap between the two plates, under LabelFramer's
## 0.16 m MERGE_GAP, so the framer folds them into ONE plate naming both
## crossings instead of shingling two slabs at the centre of the piece.
const COINCIDENT_TIER: float = 0.40
const MIDPOINT_Q: float = 0.05
## Metres the degree caption steps out along the landmass's own side, so the two
## landmasses that both sit at x=0 stop sharing a column.
const DEGREE_SIDESTEP: float = 2.5

# Königsberg-specific state
var landmasses: Array = []  # The four landmasses A, B, C, D
var bridges: Array = []     # The seven original bridges
var euler_analysis: Dictionary = {}
var path_attempt_visualization: Array = []
var degree_counts: Dictionary = {}
## Component id per node, and the id of the largest component. Empty until the
## first analysis pass.
var component_of: Array = []
var largest_component: int = 0

# Educational UI
var theorem_display: CanvasLayer
var analysis_panel: Panel

## Only the nodes THIS script created in the build path. _rebuild_now frees these
## and nothing else — get_children() would take the grid's own added plates with it.
var _created: Array[Node] = []
var _degree_labels: Array[Node] = []
var _theorem_label: Label3D = null
var _built: bool = false
## Honoured by every material this script makes. An accepted key that is applied
## nowhere is the same lie as one that was never accepted.
var _emissive: bool = true

func _ready() -> void:
	# Override parent _ready to use Königsberg topology
	_build_all()
	_built = true

## SYNCHRONOUS, from @export values alone — the sweep sets `parity` before the
## node enters the tree and never calls apply_grid_config, so every value has to
## be reachable from here.
func _build_all() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 1736  # Historical date

	_setup_konigsberg_topology()
	_create_3d_konigsberg_world()
	_analyze_euler_properties()
	_setup_educational_ui()

	if show_theorem_explanation:
		_display_euler_theorem()

func _setup_konigsberg_topology() -> void:
	"""Setup the exact topology of the Königsberg bridge problem"""
	nodes.clear()
	edges.clear()
	adjacency = []
	
	# The four landmasses with 3D positioning
	var landmass_positions = []
	
	if historical_mode:
		# Historical layout based on actual 1736 Königsberg
		landmass_positions = [
			Vector3(-15, landmass_elevation, 0),    # A - Altstadt (Old Town)
			Vector3(15, landmass_elevation, 0),     # B - Löbenicht
			Vector3(0, landmass_elevation, -12),    # C - Kneiphof Island
			Vector3(0, landmass_elevation, 12)      # D - Vorstadt
		]
	else:
		# Modern interpretive layout
		landmass_positions = [
			Vector3(-20, landmass_elevation, 5),
			Vector3(20, landmass_elevation, -5),
			Vector3(0, landmass_elevation + 2, -15),
			Vector3(0, landmass_elevation + 1, 15)
		]
	
	# Create the four nodes (landmasses)
	var landmass_names = ["Altstadt", "Löbenicht", "Kneiphof", "Vorstadt"]
	for i in range(4):
		var node_data = {
			"pos": landmass_positions[i],
			"vel": Vector3.ZERO,
			"inst": null,
			"degree": 0,
			"structure": null,
			"landmass_name": landmass_names[i],
			"historical_significance": get_historical_info(i)
		}
		nodes.append(node_data)
		adjacency.append([])
		landmasses.append(node_data)
	
	# The bridge set — THE AXIS. Chosen before a single piece of geometry exists.
	var bridge_connections: Array = _bridge_table()

	for i in range(bridge_connections.size()):
		var bridge = bridge_connections[i]
		var edge_data = {
			"a": bridge.from,
			"b": bridge.to,
			"w": calculate_historical_bridge_cost(bridge),
			"portal": null,
			"bridge_type": BridgeType.CURVED,  # Historical stone arch bridges
			"historical_name": bridge.name,
			"construction_year": bridge.built,
			"lateral": float(bridge.get("lateral", 0.0)),
			"bridge_id": i
		}
		edges.append(edge_data)
		bridges.append(edge_data)
		
		# Update adjacency
		adjacency[bridge.from].append({"to": bridge.to, "w": edge_data.w})
		adjacency[bridge.to].append({"to": bridge.from, "w": edge_data.w})
	
	# Calculate node degrees for Euler analysis
	_calculate_konigsberg_degrees()

## THE AXIS BUILDER. Returns the bridge set `parity` names.
##
## `lateral` is metres the span is shifted sideways, perpendicular to the line
## between the two landmasses it joins. Every historical bridge carries 0.0, so
## `blocked` builds exactly the geometry this artifact shipped with — the value
## exists for `circuit`, whose second Altstadt–Löbenicht crossing would otherwise
## be drawn straight through the Grüne Brücke and add no visible density at all,
## which is precisely the inert-branch failure this loop exists to catch.
func _bridge_table() -> Array:
	# The seven bridges of 1736, with historical names.
	var table: Array = [
		{"from": 0, "to": 2, "name": "Krämer-Brücke", "built": 1286, "lateral": 0.0},      # A-C
		{"from": 0, "to": 2, "name": "Schmieden-Brücke", "built": 1379, "lateral": 0.0},   # A-C (parallel)
		{"from": 0, "to": 3, "name": "Holz-Brücke", "built": 1322, "lateral": 0.0},        # A-D
		{"from": 0, "to": 3, "name": "Hohe Brücke", "built": 1542, "lateral": 0.0},        # A-D (parallel)
		{"from": 0, "to": 1, "name": "Grüne Brücke", "built": 1322, "lateral": 0.0},       # A-B
		{"from": 1, "to": 2, "name": "Köttel-Brücke", "built": 1457, "lateral": 0.0},      # B-C
		{"from": 1, "to": 3, "name": "Honig-Brücke", "built": 1542, "lateral": 0.0}        # B-D
	]

	match parity:
		"walk":
			# Kneiphof (0,·,-12) to Vorstadt (0,·,12): one 24 m arch. Degrees
			# become 5/3/4/4 — exactly two odd ends, so an open walk exists and
			# those two red platforms are its only legal start and finish.
			table.append({"from": 2, "to": 3, "name": "Kneiphof-Steg", "built": 1737, "lateral": 0.0})
		"circuit":
			table.append({"from": 2, "to": 3, "name": "Kneiphof-Steg", "built": 1737, "lateral": 0.0})
			# A second 30 m Altstadt–Löbenicht crossing, standing 3 m north of
			# the Grüne Brücke so it reads as a second bridge rather than a
			# repaint of the first. 3 m keeps both ends inside the 4 m platform
			# radius, so it still lands on land. Nine bridges, every degree even.
			table.append({"from": 0, "to": 1, "name": "Zweite Grüne Brücke", "built": 1737, "lateral": 3.0})
		"severed":
			# Cut Löbenicht loose. DERIVED from the node index, not a hard-coded
			# list of names, so it stays true if the table above is ever edited.
			var kept: Array = []
			for b in table:
				if int(b["from"]) != SEVERED_NODE and int(b["to"]) != SEVERED_NODE:
					kept.append(b)
			table = kept

	return table

func get_historical_info(landmass_id: int) -> String:
	"""Get historical information about each landmass"""
	var info = [
		"Altstadt - The Old Town, political and commercial center of Königsberg",
		"Löbenicht - Eastern district, home to craftsmen and merchants", 
		"Kneiphof - Cathedral island, religious center with Königsberg Cathedral",
		"Vorstadt - Northern suburb, residential area outside the old walls"
	]
	return info[landmass_id]

func calculate_historical_bridge_cost(bridge_data: Dictionary) -> float:
	"""Calculate bridge traversal cost based on historical factors"""
	var base_cost = 1.0
	var age_factor = 1.0 + (1736 - bridge_data.built) * 0.001  # Older bridges slightly harder
	# Seeded, not global: two builds of one axis value must be identical or the
	# pixel critic reads noise as signal.
	var traffic_factor = rng.randf_range(0.8, 1.2)  # Traffic variation
	return base_cost * age_factor * traffic_factor

func _calculate_konigsberg_degrees() -> void:
	"""Calculate node degrees and analyze Eulerian properties"""
	degree_counts.clear()
	
	for i in range(nodes.size()):
		var degree = 0
		for edge in edges:
			if edge.a == i or edge.b == i:
				degree += 1
		nodes[i]["degree"] = degree
		degree_counts[i] = degree
	
	# Analyze for Eulerian path/circuit
	_analyze_euler_properties()

func _analyze_euler_properties() -> void:
	"""Analyze the graph for Eulerian path and circuit properties"""
	euler_analysis.clear()

	var odd_degree_nodes = []
	var even_degree_nodes = []

	for i in range(nodes.size()):
		var degree = degree_counts[i]
		if degree % 2 == 1:
			odd_degree_nodes.append(i)
		else:
			even_degree_nodes.append(i)

	# CONNECTIVITY, not just parity. `severed` produces a graph whose degrees are
	# all even and whose walk is still impossible, and a parity-only reading would
	# call that solvable — the exact misreading the value exists to prevent.
	_compute_components()
	var piece_count: int = 0
	for c in component_of:
		piece_count = maxi(piece_count, int(c) + 1)
	var connected: bool = piece_count <= 1

	# Determine Eulerian properties
	euler_analysis["odd_degree_count"] = odd_degree_nodes.size()
	euler_analysis["even_degree_count"] = even_degree_nodes.size()
	euler_analysis["odd_degree_nodes"] = odd_degree_nodes
	euler_analysis["connected"] = connected
	euler_analysis["component_count"] = piece_count
	euler_analysis["has_eulerian_circuit"] = connected and odd_degree_nodes.size() == 0
	euler_analysis["has_eulerian_path"] = connected and odd_degree_nodes.size() == 2
	euler_analysis["has_no_eulerian_solution"] = not connected or odd_degree_nodes.size() > 2

	# The conclusion the current bridge set actually supports.
	euler_analysis["problem_solvable"] = bool(
		euler_analysis["has_eulerian_circuit"] or euler_analysis["has_eulerian_path"])
	if not connected:
		euler_analysis["euler_conclusion"] = \
			"Impossible - the city is in %d pieces; parity is not the fault" % piece_count
	elif odd_degree_nodes.size() == 0:
		euler_analysis["euler_conclusion"] = \
			"Eulerian circuit - every landmass has even degree"
	elif odd_degree_nodes.size() == 2:
		euler_analysis["euler_conclusion"] = \
			"Eulerian walk - the two odd landmasses are its only start and finish"
	elif odd_degree_nodes.size() == 4:
		euler_analysis["euler_conclusion"] = "Impossible - all four landmasses have odd degree"
	else:
		euler_analysis["euler_conclusion"] = \
			"Impossible - %d landmasses have odd degree" % odd_degree_nodes.size()

## Flood-fill the adjacency into components, and remember which one holds the
## most landmasses. Anything outside it has been cut loose.
func _compute_components() -> void:
	component_of = []
	component_of.resize(nodes.size())
	component_of.fill(-1)
	largest_component = 0
	if nodes.is_empty():
		return

	var sizes: Array = []
	var next_id: int = 0
	for start in range(nodes.size()):
		if int(component_of[start]) != -1:
			continue
		var reached: int = 0
		var queue: Array = [start]
		component_of[start] = next_id
		while not queue.is_empty():
			var cur: int = int(queue.pop_back())
			reached += 1
			if cur < adjacency.size():
				for link in adjacency[cur]:
					var nxt: int = int(link["to"])
					if int(component_of[nxt]) == -1:
						component_of[nxt] = next_id
						queue.append(nxt)
		sizes.append(reached)
		next_id += 1

	var best: int = -1
	for i in range(sizes.size()):
		if int(sizes[i]) > best:
			best = int(sizes[i])
			largest_component = i

## True when this landmass sits outside the largest component — i.e. `severed`
## has cut it loose. Always false for the connected values.
func _is_cut_off(index: int) -> bool:
	if component_of.size() != nodes.size():
		return false
	return int(component_of[index]) != largest_component

func _create_3d_konigsberg_world() -> void:
	"""Create the 3D world representation of historical Königsberg"""
	_create_river_system()
	_create_landmass_structures()
	_create_historical_bridges()
	_create_educational_markers()

func _create_river_system() -> void:
	"""Create the Pregel River system"""
	if not river_visualization:
		return
	
	# Create river plane
	var river = CSGBox3D.new()
	river.name = "PregelRiver"
	river.size = Vector3(50, 0.5, 30)
	river.position = Vector3(0, water_level, 0)
	
	var water_material = StandardMaterial3D.new()
	water_material.albedo_color = Color(0.1, 0.3, 0.8, 0.7)
	water_material.flags_transparent = true
	water_material.emission_enabled = _emissive
	water_material.emission = Color(0.05, 0.15, 0.4)
	river.material_override = water_material

	add_child(river)
	_created.append(river)

func _create_landmass_structures() -> void:
	"""Create structures representing the historical landmasses"""
	for i in range(nodes.size()):
		var node = nodes[i]
		
		# Create landmass platform
		_create_landmass_platform(node, i)
		
		# Create historical building if available
		if historical_building_style and structure_scenes.size() > 0:
			_create_historical_building(node, i)
		
		# Create degree indicator
		if show_degree_labels:
			_create_degree_indicator(node, i)

func _create_landmass_platform(node: Dictionary, index: int) -> void:
	"""Create a platform representing each landmass"""
	var platform = CSGCylinder3D.new()
	platform.name = "Landmass_" + node.landmass_name
	platform.radius = 4.0
	platform.height = 1.0
	platform.position = node.pos
	
	var platform_material = StandardMaterial3D.new()
	if _is_cut_off(index):
		# `severed` only. Neither red nor green, because neither answer applies:
		# this landmass has even degree and is still unreachable. Slate is the
		# third verdict the shipped two-colour scheme had no room for.
		platform_material.albedo_color = Color(0.36, 0.40, 0.48)
		platform_material.emission = Color(0.08, 0.10, 0.14)
	elif highlight_odd_degree_nodes and degree_counts[index] % 2 == 1:
		platform_material.albedo_color = Color(0.8, 0.3, 0.3)  # Red for odd degree
		platform_material.emission = Color(0.4, 0.1, 0.1)
	else:
		platform_material.albedo_color = Color(0.4, 0.6, 0.3)  # Green for even degree
		platform_material.emission = Color(0.1, 0.2, 0.1)

	platform_material.emission_enabled = _emissive
	platform.material_override = platform_material
	platform.use_collision = true

	add_child(platform)
	_created.append(platform)
	node.inst = platform

func _create_historical_building(node: Dictionary, index: int) -> void:
	"""Create historical building on landmass"""
	if structure_scenes.is_empty():
		return
	
	var building = structure_scenes[index % structure_scenes.size()].instantiate()
	building.name = "Building_" + node.landmass_name
	building.position = node.pos + Vector3(0, 1.0, 0)
	building.scale = Vector3.ONE * rng.randf_range(0.8, 1.2)

	add_child(building)
	_created.append(building)
	node.structure = building

## CAPTION PLACEMENT — degree indicators.
##
## These hung at node.pos + (0, 3, 0), font 32, two lines, so LabelFramer gave
## each a ~1.0 x 0.39 m opaque plate. Kneiphof (0,·,-12) and Vorstadt (0,·,12)
## both sit at x=0, so in frontal projection their two plates landed in the SAME
## column and occluded each other outright.
##
## Each caption now steps DEGREE_SIDESTEP metres out along its own landmass's
## side — east landmasses east, west landmasses west, and the two that sit on the
## centre line take their side from their z instead. Four landmasses, four
## columns: -17.5, -2.5, +2.5, +17.5. The height drops to node.y + 2.2 = 4.2 m
## (plate 4.00..4.40), which is 0.5 m clear of the 3.5 m arch apexes — the whole
## caption band lives above the body, never in front of it.
func _create_degree_indicator(node: Dictionary, index: int) -> void:
	"""Create visual indicator showing node degree"""
	var cut_off: bool = _is_cut_off(index)

	var label = Label3D.new()
	label.name = "DegreeLabel_" + str(node.landmass_name)
	label.text = "Degree: " + str(degree_counts[index]) + "\n" + node.landmass_name
	if cut_off:
		# The caption has to say the second impossibility out loud, or a green
		# "Degree: 0" reads as a solved landmass.
		label.text += "\n(cut off)"

	var side: float = signf(float(node.pos.x))
	if is_zero_approx(side):
		side = signf(float(node.pos.z))
	if is_zero_approx(side):
		side = 1.0
	label.position = Vector3(
		node.pos.x + DEGREE_SIDESTEP * side,
		node.pos.y + 2.2,
		node.pos.z)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32

	# Color based on degree parity — or on being unreachable, which parity cannot say.
	if cut_off:
		label.modulate = Color(0.62, 0.72, 0.92)
	elif degree_counts[index] % 2 == 1:
		label.modulate = Color(1.0, 0.3, 0.3)  # Red for odd
	else:
		label.modulate = Color(0.3, 1.0, 0.3)  # Green for even

	add_child(label)
	_created.append(label)
	_degree_labels.append(label)

func _create_historical_bridges() -> void:
	"""Create the historical bridges with proper 3D representation"""
	var spans: Array = _bridge_spans()
	var plate_positions: Array = _nameplate_positions(spans)
	for i in range(edges.size()):
		var span: Dictionary = spans[i]
		_create_arched_bridge(span["a"], span["b"], edges[i], i)
		_create_bridge_nameplate(plate_positions[i], edges[i])

## Where each span actually starts and ends, with any `lateral` shift applied
## perpendicular to the line between its two landmasses. Every shipped bridge
## carries lateral 0.0, so this returns the node centres unchanged for `blocked`.
func _bridge_spans() -> Array:
	var spans: Array = []
	for i in range(edges.size()):
		var edge = edges[i]
		var from_pos: Vector3 = nodes[edge.a]["pos"]
		var to_pos: Vector3 = nodes[edge.b]["pos"]
		var lat: float = float(edge.get("lateral", 0.0))
		if not is_zero_approx(lat):
			var shift: Vector3 = _horizontal_perp(to_pos - from_pos) * lat
			from_pos += shift
			to_pos += shift
		var lo: int = mini(int(edge.a), int(edge.b))
		var hi: int = maxi(int(edge.a), int(edge.b))
		spans.append({"a": from_pos, "b": to_pos, "pair": "%d-%d" % [lo, hi]})
	return spans

## Unit vector at right angles to a span, in the horizontal plane.
func _horizontal_perp(d: Vector3) -> Vector3:
	var perp: Vector3 = Vector3(-d.z, 0.0, d.x)
	if perp.length() < 0.001:
		return Vector3.RIGHT
	return perp.normalized()

## CAPTION PLACEMENT — bridge nameplates.
##
## Every nameplate sat on its span's midpoint, so the two Krämer/Schmieden plates
## (both Altstadt–Kneiphof) and the two Holz/Hohe plates (both Altstadt–Vorstadt)
## shared a position EXACTLY and z-fought in place. Two faults, two rules, both
## DERIVED — `walk` and `circuit` change how many spans meet at a point and
## `severed` changes the set entirely, so nothing here may be hard-coded.
##
##  1. PARALLEL BUNDLE. Spans joining the same two landmasses are fanned: the
##     k-th of m steps (k - (m-1)/2) * 0.9 m perpendicular to the span. Which is
##     also simply true — there really are two bridges there.
##  2. COINCIDENT MIDPOINT. Spans between DIFFERENT landmasses that happen to
##     cross at one point — `walk` and `circuit` send the Kneiphof-Steg straight
##     over the centre of the Grüne Brücke — get tiered DOWN by 0.40 m per
##     bundle. That leaves a 0.09 m gap, inside LabelFramer's 0.16 m MERGE_GAP,
##     so the framer folds them into ONE plate naming both crossings. Tiering
##     upward instead would have collided with the theorem plate's merge window.
##
## The lowest plate any value produces has its underside at 3.945 m, still 0.44 m
## above the 3.5 m arch apexes, so no nameplate crosses the body at any value.
func _nameplate_positions(spans: Array) -> Array:
	var out: Array = []
	out.resize(spans.size())

	# Bucket by quantised midpoint, first-seen order preserved.
	var groups: Dictionary = {}
	var group_order: Array = []
	for i in range(spans.size()):
		var mid: Vector3 = ((spans[i]["a"] as Vector3) + (spans[i]["b"] as Vector3)) * 0.5
		var key: String = "%d_%d_%d" % [
			int(round(mid.x / MIDPOINT_Q)),
			int(round(mid.y / MIDPOINT_Q)),
			int(round(mid.z / MIDPOINT_Q))]
		if not groups.has(key):
			groups[key] = []
			group_order.append(key)
		(groups[key] as Array).append(i)

	for key in group_order:
		var members: Array = groups[key]
		# Split each coincident group into parallel bundles by landmass pair.
		var bundles: Dictionary = {}
		var bundle_order: Array = []
		for idx in members:
			var pair: String = str(spans[idx]["pair"])
			if not bundles.has(pair):
				bundles[pair] = []
				bundle_order.append(pair)
			(bundles[pair] as Array).append(idx)

		for tier in range(bundle_order.size()):
			var bundle: Array = bundles[bundle_order[tier]]
			var m: int = bundle.size()
			for k in range(m):
				var idx2: int = int(bundle[k])
				var a: Vector3 = spans[idx2]["a"]
				var b: Vector3 = spans[idx2]["b"]
				var mid2: Vector3 = (a + b) * 0.5
				var fan: float = (float(k) - float(m - 1) * 0.5) * PARALLEL_FAN
				var pos: Vector3 = mid2 + _horizontal_perp(b - a) * fan
				pos.y = mid2.y + bridge_arch_height + 1.0 - float(tier) * COINCIDENT_TIER
				out[idx2] = pos

	return out

func _create_arched_bridge(from_pos: Vector3, to_pos: Vector3, edge: Dictionary, bridge_index: int) -> void:
	"""Create an arched stone bridge"""
	var segments = 12
	var arch_height = bridge_arch_height
	
	for i in range(segments):
		var t1 = float(i) / float(segments)
		var t2 = float(i + 1) / float(segments)
		
		var p1 = _bridge_arch_point(from_pos, to_pos, arch_height, t1)
		var p2 = _bridge_arch_point(from_pos, to_pos, arch_height, t2)
		
		var segment = CSGBox3D.new()
		segment.name = "BridgeSegment_" + edge.historical_name + "_" + str(i)
		var seg_distance = p1.distance_to(p2)
		segment.size = Vector3(bridge_width, bridge_thickness, seg_distance)
		
		var mid = (p1 + p2) * 0.5
		var dir = (p2 - p1).normalized()
		var basis = Basis().looking_at(dir, Vector3.UP)
		segment.transform = Transform3D(basis, mid)
		segment.use_collision = true
		
		# Historical stone material
		var stone_material = StandardMaterial3D.new()
		stone_material.albedo_color = Color(0.7, 0.7, 0.6)
		stone_material.roughness = 0.8
		stone_material.metallic = 0.1
		segment.material_override = stone_material

		add_child(segment)
		_created.append(segment)

func _bridge_arch_point(start: Vector3, end: Vector3, height: float, t: float) -> Vector3:
	"""Calculate point on bridge arch"""
	var base_point = start.lerp(end, t)
	var arch_factor = sin(t * PI)  # Sine curve for natural arch
	base_point.y += height * arch_factor
	return base_point

func _create_bridge_nameplate(plate_pos: Vector3, edge: Dictionary) -> void:
	"""Create nameplate for each historical bridge, at its slot from _nameplate_positions"""
	var nameplate = Label3D.new()
	nameplate.name = "BridgeName_" + str(edge.historical_name)
	nameplate.text = edge.historical_name + "\n(Built: " + str(edge.construction_year) + ")"
	nameplate.position = plate_pos
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nameplate.font_size = 24
	nameplate.modulate = Color(0.9, 0.9, 0.7)

	add_child(nameplate)
	_created.append(nameplate)

func _create_educational_markers() -> void:
	"""Create educational information markers"""
	if not show_theorem_explanation:
		return
	
	# Central information pillar
	var info_pillar = CSGCylinder3D.new()
	info_pillar.name = "EulerTheoremPillar"
	info_pillar.radius = 0.5
	info_pillar.height = 3.0
	info_pillar.position = Vector3(0, 1.5, 0)
	
	var pillar_material = StandardMaterial3D.new()
	pillar_material.albedo_color = Color(0.2, 0.2, 0.8)
	pillar_material.emission_enabled = _emissive
	pillar_material.emission = Color(0.1, 0.1, 0.4)
	info_pillar.material_override = pillar_material

	add_child(info_pillar)
	_created.append(info_pillar)

	# CAPTION PLACEMENT — the theorem, the one caption that speaks for the whole
	# artifact.
	#
	# It sat at (0, 4.0, 0): four lines at font 28 make a ~2.1 x 0.62 m plate
	# spanning y 3.70..4.32, which cleared the Altstadt–Löbenicht arch apex by
	# 0.20 m and landed 0.18 m under the Grüne Brücke nameplate — outside
	# LabelFramer's 0.16 m MERGE_GAP, so the two shingled as separate slabs at
	# the exact centre of the piece.
	#
	# Raised to 5.4 m it clears every nameplate by 0.43 m: no merge, no shingle,
	# and it reads as the single top caption of the whole artifact. The AABB grows
	# from about 4.75 m to 6.9 m tall against a 50 m width, so the auto-framing
	# camera pays nothing for it. NOT printed on the info pillar: four lines at
	# font 28 are 2.1 m wide against a 1.0 m pillar face, and shrinking to font 14
	# to fit would make the artifact's thesis unreadable at framing distance.
	var theorem_label = Label3D.new()
	theorem_label.name = "EulerTheoremLabel"
	theorem_label.text = "Euler's Theorem:\nA graph has an Eulerian path\nif and only if it has exactly\n0 or 2 vertices of odd degree"
	theorem_label.position = Vector3(0, 5.4, 0)
	theorem_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	theorem_label.font_size = 28
	theorem_label.modulate = Color(1.0, 1.0, 0.3)

	add_child(theorem_label)
	_created.append(theorem_label)
	_theorem_label = theorem_label

func _setup_educational_ui() -> void:
	"""Setup educational UI overlay"""
	theorem_display = CanvasLayer.new()
	theorem_display.name = "KonigsbergUI"
	add_child(theorem_display)
	_created.append(theorem_display)

	analysis_panel = Panel.new()
	analysis_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	analysis_panel.size = Vector2(400, 300)
	analysis_panel.position = Vector2(-410, 10)
	theorem_display.add_child(analysis_panel)
	
	var vbox = VBoxContainer.new()
	analysis_panel.add_child(vbox)
	
	# Create analysis labels
	for i in range(15):
		var label = Label.new()
		label.name = "analysis_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	_update_analysis_ui()

func _update_analysis_ui() -> void:
	"""Update the analysis UI with current state"""
	if not analysis_panel:
		return
	
	var labels = []
	for i in range(15):
		var label = analysis_panel.get_node_or_null("VBoxContainer/analysis_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 15:
		labels[0].text = "🌉 Königsberg Bridge Problem"
		labels[1].text = "Historical Date: 1736"
		labels[2].text = ""
		labels[3].text = "Graph Analysis:"
		labels[4].text = "Vertices (Landmasses): " + str(nodes.size())
		labels[5].text = "Edges (Bridges): " + str(edges.size())
		labels[6].text = ""
		labels[7].text = "Degree Analysis:"
		
		var label_index = 8
		for i in range(nodes.size()):
			var landmass_name = nodes[i]["landmass_name"]
			var degree = degree_counts[i]
			var parity = "odd" if degree % 2 == 1 else "even"
			labels[label_index].text = landmass_name + ": " + str(degree) + " (" + parity + ")"
			label_index += 1
		
		labels[12].text = ""
		labels[13].text = "Euler's Conclusion:"
		labels[14].text = euler_analysis["euler_conclusion"]

func attempt_eulerian_path() -> void:
	"""Demonstrate why no Eulerian path exists"""
	if not animate_path_attempts:
		return
	
	print("Attempting Eulerian path... (parity=%s)" % parity)
	print("Degrees: ", degree_counts)
	print("Euler's theorem: A connected graph has an Eulerian path if and only if it has exactly 0 or 2 vertices of odd degree")
	print(euler_analysis.get("euler_conclusion", ""))

func demonstrate_bridge_removal() -> void:
	"""Show how removing bridges affects Eulerian properties"""
	if not interactive_bridge_removal:
		return
	
	print("Try removing bridges to create an Eulerian path...")
	print("Need to reduce odd-degree vertices to exactly 2 or 0")

func _input(event: InputEvent) -> void:
	"""Handle educational interactions"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E:
				attempt_eulerian_path()
			KEY_H:
				show_theorem_explanation = not show_theorem_explanation
				_display_euler_theorem()
			KEY_D:
				show_degree_labels = not show_degree_labels
				_toggle_degree_indicators()
			KEY_B:
				demonstrate_bridge_removal()

func _display_euler_theorem() -> void:
	"""Display or hide Euler theorem explanation"""
	var theorem_pillar = get_node_or_null("EulerTheoremPillar")
	if theorem_pillar:
		theorem_pillar.visible = show_theorem_explanation
	if is_instance_valid(_theorem_label):
		_theorem_label.visible = show_theorem_explanation

func _toggle_degree_indicators() -> void:
	"""Toggle visibility of degree indicators"""
	# Tracked, not name-sniffed: the old version matched on the auto-generated
	# "Label3D…" node names and would have caught the bridge nameplates too.
	for label in _degree_labels:
		if is_instance_valid(label):
			(label as Node3D).visible = show_degree_labels

func get_konigsberg_info() -> Dictionary:
	"""Get comprehensive information about the Königsberg problem"""
	return {
		"problem_name": "Seven Bridges of Königsberg",
		"historical_date": 1736,
		"mathematician": "Leonhard Euler",
		"significance": "First problem in graph theory",
		"parity": parity,
		"graph_properties": {
			"vertices": nodes.size(),
			"edges": edges.size(),
			"connected": bool(euler_analysis.get("connected", true)),
			"planar": true
		},
		"euler_analysis": euler_analysis,
		"degree_sequence": degree_counts,
		"historical_context": "Solved by Euler in 1736, proving no solution exists",
		"modern_relevance": "Foundation of graph theory and topology"
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before_parity: String = parity
	var before_arch: float = bridge_arch_height
	var before_elevation: float = landmass_elevation

	# Stage-2 DNA axis — #parity:circuit
	if config_data.has("parity"):
		parity = _pick_axis(str(config_data["parity"]), PARITIES, parity)

	# Geometry keys, snapshotted above so they trigger the same rebuild.
	if config_data.has("bridge_arch_height"):
		bridge_arch_height = clampf(float(config_data["bridge_arch_height"]), 0.2, 6.0)
	if config_data.has("landmass_elevation"):
		landmass_elevation = clampf(float(config_data["landmass_elevation"]), 0.0, 8.0)

	# NON-GEOMETRY, APPLIED IN PLACE, BEFORE THE RETURNS. curation_station hands
	# every artifact it curates {"emissive": false} one line after framing its
	# labels — a dict with no axis key, which must therefore leave the bridge set
	# alone and still actually do its own job. Applying it here rather than
	# leaning on the rebuild is the whole point: the early returns below mean a
	# rebuild is not guaranteed, and two artifacts once accepted this key and
	# applied it nowhere for exactly that reason.
	if config_data.has("emissive"):
		var want: bool = _as_bool(config_data["emissive"], _emissive)
		if want != _emissive:
			_emissive = want
			_apply_emissive_in_place()

	if not _built:
		return
	if parity == before_parity \
			and is_equal_approx(bridge_arch_height, before_arch) \
			and is_equal_approx(landmass_elevation, before_elevation):
		return

	_rebuild_now()
	print("[Konigsberg] Config applied — parity=%s, bridges=%d, conclusion=%s" % [
		parity, edges.size(), euler_analysis.get("euler_conclusion", "")])


## Accept an axis value only if it names something we actually build. A typo in a
## map token has to fall back to the shipped 1736 set — a half-recognised value
## would strand a placement with no bridges at all.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _as_bool(raw, fallback: bool) -> bool:
	if raw is bool:
		return bool(raw)
	var s: String = str(raw).to_lower().strip_edges()
	if s in ["false", "0", "off", "no"]:
		return false
	if s in ["true", "1", "on", "yes"]:
		return true
	return fallback


## Walk what this script built and switch emission on the live materials. No
## geometry is touched, so a placement that only sends `emissive` keeps the exact
## bridge set it was shipped with.
func _apply_emissive_in_place() -> void:
	var queue: Array = []
	for n in _created:
		queue.append(n)
	while not queue.is_empty():
		var node: Node = queue.pop_back()
		if node is GeometryInstance3D and not (node is Label3D):
			var mat = (node as GeometryInstance3D).material_override
			if mat is StandardMaterial3D:
				(mat as StandardMaterial3D).emission_enabled = _emissive
		for c in node.get_children():
			queue.append(c)


## SYNCHRONOUS. Free only what this script created — a deferred rebuild that
## removes children first makes auto-grounding measure a zero AABB and bail, and
## get_children() would take the grid's own added plates with it.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_created.clear()

	# LabelFramer parents a MERGED plate to the label's parent — us — so those
	# plates are not in _created and would otherwise be left hanging in mid-air
	# over a rebuilt artifact. They belong to captions this script made, so they
	# go with them. Nothing else under this node carries the marker.
	for child in get_children():
		if child.has_meta("label_plate"):
			remove_child(child)
			child.queue_free()

	_degree_labels.clear()
	landmasses.clear()
	bridges.clear()
	path_attempt_visualization.clear()
	component_of = []
	largest_component = 0
	theorem_display = null
	analysis_panel = null
	_theorem_label = null

	_build_all()
