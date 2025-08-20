class_name RhizomaticPathNetwork
extends Node

var network_data: Dictionary = {}

func set_network_data(data: Dictionary):
	network_data = data

func get_all_connections() -> Array:
	return network_data.get("connections", [])

func get_chamber_nodes() -> Array:
	var chambers = []
	for node in network_data.get("nodes", []):
		if node.connections.size() >= 3:  # Intersection = potential chamber
			chambers.append(node)
	return chambers

func get_intersection_points() -> Array[Vector3]:
	var intersections: Array[Vector3] = []
	for node in network_data.get("nodes", []):
		if node.connections.size() > 2:
			intersections.append(node.position)
	return intersections

func get_major_paths() -> Array:
	# Return main connecting paths for navigation
	return []
