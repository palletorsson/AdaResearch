
# Supporting classes for the rhizomatic maze system

class_name RhizomaticMazeGenerator
extends Node

var growth_points: Array[Vector3] = []
var network_nodes: Array[Dictionary] = []
var connections: Array[Dictionary] = []
var config: Dictionary = {}

## Depth from the root, filled ONLY when topology is "tree". A rhizome has no depth to
## measure — no root to measure it from — and that absence is exactly what the axis puts
## on display, so nothing here is computed on the default path.
var _depth: Dictionary = {}
var _root_position: Vector3 = Vector3.ZERO

## The wound `severed` opens, as fractions of maze_size.x. RhizomaticMazeSpace reads them
## too, so the tendril pass knows not to hang anything across the gap; one definition, not
## two that can drift apart.
const FISSURE_FRACTION: float = 0.14
const DRIFT_FRACTION: float = 0.06

func configure(params: Dictionary) -> void:
	config = params

func initialize_growth_points(seeds: Array[Vector3]) -> void:
	growth_points = seeds.duplicate()

func generate_rhizomatic_network() -> Dictionary:
	"""Generate the rhizomatic network structure"""
	network_nodes.clear()
	connections.clear()
	_depth.clear()

	# Convert growth points to network nodes
	for i in range(growth_points.size()):
		network_nodes.append({
			"id": i,
			"position": growth_points[i],
			"connections": [],
			"properties": {"type": "junction", "size": randf_range(0.8, 1.5)}
		})
	
	# Generate rhizomatic connections
	generate_primary_connections()
	generate_secondary_branches()
	prune_redundant_paths()
	sever_network()

	return {
		"nodes": network_nodes,
		"connections": connections
	}

func generate_primary_connections() -> void:
	"""Create main connecting paths between growth points"""
	var topo: String = str(config.get("topology", "rhizome"))
	if topo == "tree":
		connect_as_tree()
		return
	# A plateau is dense as well as flat: more of every seed's neighbours are admitted, so
	# the mat reads as a continuous region rather than a thin flattened tangle.
	var neighbours: int = 5 if topo == "plateau" else 3
	# Connect nearby nodes using Delaunay-like triangulation
	for i in range(network_nodes.size()):
		var node_a = network_nodes[i]
		var closest_nodes = find_closest_nodes(node_a, neighbours)

		for node_b in closest_nodes:
			if randf() < config.get("branch_prob", 0.7):
				create_connection(node_a, node_b, {"type": "primary", "width_multiplier": 1.0})

## TREE — the figure a rhizome is defined AGAINST, built as a minimum spanning tree from the
## lowest seed. Every node but the root reaches the network through exactly one parent, so
## the graph carries no cycle: one origin, a strict descent, and between any two points
## exactly one route. There is no randf() in here on purpose. A tree is not a matter of
## chance; it is a rule about who is permitted to connect to whom, and that rule is the
## thing the axis puts on trial.
func connect_as_tree() -> void:
	if network_nodes.size() < 2:
		return

	var root_index: int = 0
	var lowest: float = network_nodes[0].position.y
	for i in range(network_nodes.size()):
		if network_nodes[i].position.y < lowest:
			lowest = network_nodes[i].position.y
			root_index = i
	_root_position = network_nodes[root_index].position
	_depth[network_nodes[root_index].id] = 0

	var joined: Array[int] = [root_index]
	var pending: Array[int] = []
	for i in range(network_nodes.size()):
		if i != root_index:
			pending.append(i)

	while pending.size() > 0:
		var best_p: int = 0
		var best_j: int = 0
		var best_d: float = INF
		for pi in range(pending.size()):
			for ji in range(joined.size()):
				var d: float = network_nodes[pending[pi]].position.distance_to(
					network_nodes[joined[ji]].position)
				if d < best_d:
					best_d = d
					best_p = pi
					best_j = ji
		var child_node: Dictionary = network_nodes[pending[best_p]]
		var parent_node: Dictionary = network_nodes[joined[best_j]]
		var child_depth: int = int(_depth.get(parent_node.id, 0)) + 1
		_depth[child_node.id] = child_depth
		create_connection(parent_node, child_node,
			{"type": "primary", "width_multiplier": taper_for_depth(child_depth)})
		joined.append(pending[best_p])
		pending.remove_at(best_p)

## In a tree, thickness IS the hierarchy: a trunk carries everything below it and a twig
## carries only itself. The rhizome has no equivalent claim, which is why every connection
## there keeps the flat 1.0 / 0.7 pair the file has always used.
func taper_for_depth(depth: int) -> float:
	return maxf(0.25, 0.95 * pow(0.86, float(depth)))

func generate_secondary_branches() -> void:
	"""Add secondary branching connections"""
	var branch_count = config.get("iterations", 100)
	var topo: String = str(config.get("topology", "rhizome"))
	var flat: bool = topo == "plateau"
	var arboreal: bool = topo == "tree"

	for i in range(branch_count):
		# Pick random existing node
		var source_node = network_nodes[randi() % network_nodes.size()]

		# Create new branch node nearby
		var branch_direction: Vector3 = Vector3(
			randf_range(-1, 1),
			randf_range(-0.5, 0.5),  # Less vertical variation
			randf_range(-1, 1)
		).normalized()
		if flat:
			branch_direction.y = 0.0
			branch_direction = branch_direction.normalized()
		elif arboreal:
			# Growth in a tree is ORIENTED: it leaves the root and does not come back.
			var away: Vector3 = source_node.position - _root_position
			if away.length() < 0.001:
				away = Vector3.UP
			branch_direction = (branch_direction + away.normalized() * 1.4).normalized()

		var branch_distance = randf_range(3.0, 8.0)
		var branch_pos: Vector3 = source_node.position + branch_direction * branch_distance
		if flat:
			branch_pos.y = source_node.position.y

		# Add new node
		var new_node = {
			"id": network_nodes.size(),
			"position": branch_pos,
			"connections": [],
			"properties": {"type": "branch", "size": randf_range(0.5, 1.0)}
		}
		network_nodes.append(new_node)

		var width_multiplier: float = 0.7
		if arboreal:
			var branch_depth: int = int(_depth.get(source_node.id, 0)) + 1
			_depth[new_node.id] = branch_depth
			width_multiplier = taper_for_depth(branch_depth)

		# Connect to source
		create_connection(source_node, new_node,
			{"type": "branch", "width_multiplier": width_multiplier})

## SEVERED — asignifying rupture. "A rhizome may be broken, shattered at a given spot, but it
## will start up again on one of its old lines." The rhizome is grown IN FULL first and then
## cut, because a rupture is an operation performed on a network and not a different way of
## growing one: a fissure is opened through the middle and every tunnel that crosses it or
## ends inside it is removed, leaving fragments that are each still rhizomatic. The node
## degrees are recounted afterwards so the chamber pass does not put a nine-metre CSG sphere
## in the gap it just opened. What a still cannot show is the second half of the principle,
## the starting-up-again; this value claims only the break.
##
## AND THEN THE FRAGMENTS ARE MOVED APART, which is the 2026-08-05 repair and needs its
## defence. The first version cut the graph and left both halves where they were, and it
## measured 0.012% against the intact rhizome — the smallest number in the whole sweep. The
## obvious reading is the Deleuzian one, that severing a rhizome changes nothing because any
## point still reaches any other, and it is the wrong reading of what happened here: a plane
## cut removes EVERY edge crossing it, so the graph really does fall into two components that
## cannot reach each other at all. The failure was not in the topology, it was in the
## photograph. CONNECTION IS NOT A VISIBLE PROPERTY. Two halves that no longer reach each
## other look exactly like two halves that do, especially from outside a tangle where the
## fissure is behind two hundred tunnels. Moving the fragments apart is not theatre added to
## a real cut; it is the only rendering a still can carry of a fact that is otherwise purely
## relational — and it is also the truer picture, because what a rupture produces is not a
## damaged rhizome but TWO rhizomes, and to see two you have to see two.
func sever_network() -> void:
	if str(config.get("topology", "rhizome")) != "severed":
		return

	var size: Vector3 = config.get("size", Vector3(40, 20, 40))
	var half_fissure: float = maxf(2.0, size.x * FISSURE_FRACTION)
	var drift: float = size.x * DRIFT_FRACTION

	var kept: Array[Dictionary] = []
	for c in connections:
		var conn: Dictionary = c
		var a: Vector3 = conn["start"]
		var b: Vector3 = conn["end"]
		if absf(a.x) < half_fissure or absf(b.x) < half_fissure:
			continue
		if (a.x < 0.0) != (b.x < 0.0):
			continue
		kept.append(conn)
	connections = kept

	# Every surviving connection has both ends on the same side of the cut, so a fragment
	# moves as one piece and no tunnel is stretched across the gap. Node positions move by
	# the same rule, because the chamber and waypoint passes read those and not the edges.
	for i in range(connections.size()):
		var moved: Dictionary = connections[i]
		var s: Vector3 = moved["start"]
		var e: Vector3 = moved["end"]
		s.x += (drift if s.x > 0.0 else -drift)
		e.x += (drift if e.x > 0.0 else -drift)
		moved["start"] = s
		moved["end"] = e
	for i in range(network_nodes.size()):
		var p: Vector3 = network_nodes[i]["position"]
		p.x += (drift if p.x > 0.0 else -drift)
		network_nodes[i]["position"] = p

	for i in range(network_nodes.size()):
		network_nodes[i]["connections"] = []
	for c in connections:
		var conn: Dictionary = c
		var start_id: int = int(conn["start_id"])
		var end_id: int = int(conn["end_id"])
		if start_id >= 0 and start_id < network_nodes.size():
			network_nodes[start_id]["connections"].append(end_id)
		if end_id >= 0 and end_id < network_nodes.size():
			network_nodes[end_id]["connections"].append(start_id)

func find_closest_nodes(target_node: Dictionary, count: int) -> Array:
	"""Find closest nodes to target"""
	var distances = []
	
	for node in network_nodes:
		if node.id != target_node.id:
			var distance = target_node.position.distance_to(node.position)
			distances.append({"node": node, "distance": distance})
	
	distances.sort_custom(func(a, b): return a.distance < b.distance)
	
	var result = []
	for i in range(min(count, distances.size())):
		result.append(distances[i].node)
	
	return result

func create_connection(node_a: Dictionary, node_b: Dictionary, properties: Dictionary) -> void:
	"""Create connection between two nodes"""
	var connection = {
		"start": node_a.position,
		"end": node_b.position,
		"start_id": node_a.id,
		"end_id": node_b.id,
		"properties": properties
	}
	
	connections.append(connection)
	node_a.connections.append(node_b.id)
	node_b.connections.append(node_a.id)

func prune_redundant_paths() -> void:
	"""Remove redundant or problematic connections"""
	# Implementation would remove overly short connections, 
	# connections that create too dense areas, etc.
	pass
