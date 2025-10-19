@tool
extends GraphSpace
class_name KonigsbergBridge

# Enhanced Königsberg Bridge Problem using GraphSpace system
# Educational demonstration of Euler's famous graph theory problem

@export_category("Königsberg Problem")
@export var educational_mode: bool = true
@export var show_euler_analysis: bool = true
@export var highlight_odd_degree_nodes: bool = true
@export var animate_problem_explanation: bool = true

@export_category("Historical Settings")
@export var use_historical_layout: bool = true
@export var show_bridge_names: bool = true
@export var show_construction_dates: bool = true
@export var historical_scale: float = 1.0

# Bridge collision settings (inherited bridge settings from GraphSpace)
@export_group("Königsberg Bridges")
@export var bridge_collision_layer: int = 1
@export var bridge_collision_mask: int = 1

# Layout helpers
@export_group("Layout")
@export var scale_xy: float = 1.0          # spacing between landmasses
@export var center: Vector3 = Vector3.ZERO # scene offset
@export var y_plane: float = 0.0           # keep everything flat on this Y

# Structure settings (for compatibility)
@export_group("Structures")
@export var structure_rotation_variation_deg: float = 20.0

# Debug
@export_group("Debug")
@export var show_debug_lines: bool = true
@export var label_nodes_in_editor: bool = true

# Königsberg-specific data
var landmass_data: Array = []
var bridge_data: Array = []
var euler_analysis: Dictionary = {}
var historical_info: Dictionary = {}

# Educational UI
var analysis_ui: CanvasLayer

func _ready() -> void:
	# Override GraphSpace to use Königsberg topology
	rng = RandomNumberGenerator.new()
	rng.seed = 1736
	
	# Setup Königsberg-specific configuration
	node_count = 4
	avg_degree = 3.5
	layout_iters = 0  # No force-directed layout needed
	planar_layout = true
	plane_y = 0.0
	
	_setup_konigsberg_configuration()
	_build_konigsberg_graph()
	_layout_konigsberg()
	_instantiate_world()
	_analyze_euler_properties()
	
	if educational_mode:
		_setup_educational_ui()
	
	update_gizmos()

func _setup_konigsberg_configuration():
	"""Setup configuration specific to Königsberg problem"""
	historical_info = {
		"problem_date": 1736,
		"mathematician": "Leonhard Euler",
		"city": "Königsberg, Prussia (now Kaliningrad, Russia)",
		"significance": "First problem in graph theory"
	}
	
	# Historical bridge data
	bridge_data = [
		{"name": "Krämer-Brücke", "built": 1286, "connects": "Altstadt-Kneiphof"},
		{"name": "Schmieden-Brücke", "built": 1379, "connects": "Altstadt-Kneiphof"},
		{"name": "Holz-Brücke", "built": 1322, "connects": "Altstadt-Vorstadt"},
		{"name": "Hohe Brücke", "built": 1542, "connects": "Altstadt-Vorstadt"},
		{"name": "Grüne Brücke", "built": 1322, "connects": "Altstadt-Löbenicht"},
		{"name": "Köttel-Brücke", "built": 1457, "connects": "Löbenicht-Kneiphof"},
		{"name": "Honig-Brücke", "built": 1542, "connects": "Löbenicht-Vorstadt"}
	]

func _build_konigsberg_graph() -> void:
	"""Build the specific Königsberg graph topology"""
	nodes.clear()
	edges.clear()
	adjacency = []
	
	# Historical landmass names and positions
	var landmass_names = ["Altstadt", "Löbenicht", "Kneiphof", "Vorstadt"]
	var positions: Array[Vector3]
	
	if use_historical_layout:
		positions = [
			(Vector3(-8.0, plane_y, 0.0) * historical_scale) + center,    # Altstadt
			(Vector3(8.0, plane_y, 0.0) * historical_scale) + center,     # Löbenicht
			(Vector3(0.0, plane_y, -6.0) * historical_scale) + center,    # Kneiphof Island
			(Vector3(0.0, plane_y, 6.0) * historical_scale) + center      # Vorstadt
		]
	else:
		# Use GraphSpace layout system
		positions = [
			Vector3(-room_radius, plane_y, 0),
			Vector3(room_radius, plane_y, 0),
			Vector3(0, plane_y, -room_radius),
			Vector3(0, plane_y, room_radius)
		]
	
	# Create nodes with historical data
	for i in range(4):
		var node_data = {
			"pos": positions[i],
			"vel": Vector3.ZERO,
			"inst": null,
			"degree": 0,
			"structure": null,
			"landmass_name": landmass_names[i],
			"historical_info": _get_landmass_info(i)
		}
		nodes.append(node_data)
		adjacency.append([])
		landmass_data.append(node_data)
	
	# The seven bridges with historical context
	var bridge_connections = [
		{"a": 0, "b": 2, "bridge_id": 0},  # Altstadt-Kneiphof (Krämer)
		{"a": 0, "b": 2, "bridge_id": 1},  # Altstadt-Kneiphof (Schmieden)
		{"a": 0, "b": 3, "bridge_id": 2},  # Altstadt-Vorstadt (Holz)
		{"a": 0, "b": 3, "bridge_id": 3},  # Altstadt-Vorstadt (Hohe)
		{"a": 0, "b": 1, "bridge_id": 4},  # Altstadt-Löbenicht (Grüne)
		{"a": 1, "b": 2, "bridge_id": 5},  # Löbenicht-Kneiphof (Köttel)
		{"a": 1, "b": 3, "bridge_id": 6}   # Löbenicht-Vorstadt (Honig)
	]
	
	# Create edges with historical bridge data
	for connection in bridge_connections:
		var bridge_info = bridge_data[connection.bridge_id]
		var cost = _calculate_bridge_cost(connection.a, connection.b)
		
		var edge_data = {
			"a": connection.a,
			"b": connection.b,
			"w": cost,
			"portal": null,
			"bridge_name": bridge_info.name,
			"construction_year": bridge_info.built,
			"historical_connection": bridge_info.connects
		}
		
		edges.append(edge_data)
		adjacency[connection.a].append({"to": connection.b, "w": cost})
		adjacency[connection.b].append({"to": connection.a, "w": cost})
	
	_calculate_konigsberg_node_properties()

func _get_landmass_info(index: int) -> String:
	"""Get historical information about each landmass"""
	var info = [
		"Altstadt (Old Town) - Political and commercial center",
		"Löbenicht - Eastern district, craftsmen quarter",
		"Kneiphof - Cathedral island in the Pregel River",
		"Vorstadt - Northern suburb, residential area"
	]
	return info[index]

func _layout_konigsberg():
	"""No force-directed layout needed - use fixed historical positions"""
	pass  # Positions are already set in _build_konigsberg_graph

func _calculate_bridge_cost(from_id: int, to_id: int) -> float:
	"""Calculate cost for traversing a bridge"""
	var from_pos = nodes[from_id]["pos"]
	var to_pos = nodes[to_id]["pos"]
	return from_pos.distance_to(to_pos)

func _calculate_konigsberg_node_properties():
	"""Calculate node degrees for Königsberg analysis"""
	# Calculate degrees
	for i in range(nodes.size()):
		var degree = 0
		for e in edges:
			if e.a == i or e.b == i:
				degree += 1
		nodes[i]["degree"] = degree

# Override parent _instantiate_world to use Königsberg-specific implementation
func _instantiate_world() -> void:
	_instantiate_konigsberg_world()

func _instantiate_konigsberg_world() -> void:
	"""Instantiate the Königsberg world with historical elements"""
	# Create landmass structures (rooms)
	for i in range(nodes.size()):
		var node = nodes[i]
		if room_scene:
			var room := room_scene.instantiate()
			room.name = "Room_%s" % node["landmass_name"]
			room.transform.origin = node["pos"]
			add_child(room)
			node["inst"] = room

		# Optional decorative structure
		if place_structures and structure_scenes.size() > 0:
			var idx: int = int(rng.randi() % structure_scenes.size())
			var structure := structure_scenes[idx].instantiate()
			structure.name = "Structure_%s" % node["landmass_name"]
			var pos: Vector3 = node["pos"]
			pos.y += structure_offset_y
			structure.position = pos
			var scale_factor: float = rng.randf_range(structure_scale_range.x, structure_scale_range.y)
			structure.scale = Vector3.ONE * scale_factor
			structure.rotation.y = deg_to_rad(rng.randf_range(-structure_rotation_variation_deg, structure_rotation_variation_deg))
			add_child(structure)
			node["structure"] = structure

	# Create historical bridges
	for i in range(edges.size()):
		var edge = edges[i]
		var a: int = edge["a"]
		var b: int = edge["b"]
		var pa: Vector3 = nodes[a]["pos"]
		var pb: Vector3 = nodes[b]["pos"]
		var mid: Vector3 = (pa + pb) * 0.5
		var dir: Vector3 = (pb - pa).normalized()
		var dist: float = pa.distance_to(pb)

		# Create walkable bridge (CSG)
		if make_bridges:
			var bridge := CSGBox3D.new()
			bridge.name = "Bridge_%s_%d" % [edge["bridge_name"], i]
			bridge.size = Vector3(bridge_width, bridge_thickness, dist)
			var basis := Basis().looking_at(dir, Vector3.UP)
			bridge.transform = Transform3D(basis, mid)
			bridge.use_collision = true
			bridge.collision_layer = bridge_collision_layer
			bridge.collision_mask = bridge_collision_mask
			add_child(bridge)
			
			# Add bridge nameplate if enabled
			if show_bridge_names:
				_create_bridge_nameplate(bridge, edge, mid)

		# Optional portal marker
		if portal_scene:
			var portal := portal_scene.instantiate()
			portal.name = "Portal_%s_%d" % [edge["bridge_name"], i]
			var portal_basis := Basis().looking_at(dir, Vector3.UP)
			portal.transform = Transform3D(portal_basis, mid)
			add_child(portal)
			edge["portal"] = portal

func _create_bridge_nameplate(bridge: CSGBox3D, edge: Dictionary, position: Vector3):
	"""Create nameplate for historical bridge"""
	var label = Label3D.new()
	var nameplate_text = edge["bridge_name"]
	if show_construction_dates:
		nameplate_text += "\n(Built: " + str(edge["construction_year"]) + ")"
	
	label.text = nameplate_text
	label.position = position + Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 20
	label.modulate = Color(0.9, 0.9, 0.7)
	bridge.add_child(label)

# ---------------------------
# 3) Debug draw (use _process; Node3D has no update()/draw())
# ---------------------------
func _analyze_euler_properties():
	"""Analyze the Königsberg graph for Eulerian path properties"""
	euler_analysis.clear()
	
	var odd_degree_count = 0
	var even_degree_count = 0
	var degree_sequence = []
	
	for i in range(nodes.size()):
		var degree = nodes[i]["degree"]
		degree_sequence.append(degree)
		
		if degree % 2 == 1:
			odd_degree_count += 1
		else:
			even_degree_count += 1
	
	euler_analysis["degree_sequence"] = degree_sequence
	euler_analysis["odd_degree_count"] = odd_degree_count
	euler_analysis["even_degree_count"] = even_degree_count
	euler_analysis["has_eulerian_circuit"] = (odd_degree_count == 0)
	euler_analysis["has_eulerian_path"] = (odd_degree_count == 2)
	euler_analysis["is_impossible"] = (odd_degree_count > 2)
	
	# Königsberg conclusion
	euler_analysis["euler_conclusion"] = "No Eulerian path exists - all 4 vertices have odd degree (3 each)"
	euler_analysis["theorem"] = "A connected graph has an Eulerian path if and only if it has exactly 0 or 2 vertices of odd degree"

func _setup_educational_ui():
	"""Setup educational UI for the Königsberg problem"""
	analysis_ui = CanvasLayer.new()
	analysis_ui.name = "KonigsbergAnalysisUI"
	add_child(analysis_ui)
	
	# Main analysis panel
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(450, 500)
	panel.position = Vector2(10, 10)
	analysis_ui.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create educational labels
	for i in range(25):
		var label = Label.new()
		label.name = "edu_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	_update_educational_display()

func _update_educational_display():
	"""Update the educational information display"""
	if not analysis_ui:
		return
	
	var labels = []
	for i in range(25):
		var label = analysis_ui.get_node_or_null("Panel/VBoxContainer/edu_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 25:
		labels[0].text = "🌉 Seven Bridges of Königsberg"
		labels[1].text = "Solved by Leonhard Euler in 1736"
		labels[2].text = ""
		labels[3].text = "The Problem:"
		labels[4].text = "Can you walk through the city crossing each"
		labels[5].text = "of the seven bridges exactly once?"
		labels[6].text = ""
		labels[7].text = "Graph Analysis:"
		labels[8].text = "Vertices (Landmasses): " + str(nodes.size())
		labels[9].text = "Edges (Bridges): " + str(edges.size())
		labels[10].text = ""
		labels[11].text = "Degree Analysis:"
		
		for i in range(nodes.size()):
			var landmass = nodes[i]
			var degree = landmass["degree"]
			labels[12 + i].text = landmass["landmass_name"] + ": degree " + str(degree) + " (odd)"
		
		labels[16].text = ""
		labels[17].text = "Euler's Theorem:"
		labels[18].text = "A connected graph has an Eulerian path"
		labels[19].text = "if and only if it has exactly 0 or 2"
		labels[20].text = "vertices of odd degree."
		labels[21].text = ""
		labels[22].text = "Conclusion:"
		labels[23].text = "Since all 4 vertices have odd degree,"
		labels[24].text = "NO Eulerian path exists! ❌"

func _process(_delta: float) -> void:
	if show_debug_lines:
		# Draw debug lines for bridges
		for e in edges:
			var pa: Vector3 = nodes[e["a"]]["pos"]
			var pb: Vector3 = nodes[e["b"]]["pos"]
			# Note: Debug lines would be drawn here in a real implementation

func _input(event):
	"""Handle educational interactions"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_H:
				show_euler_analysis = not show_euler_analysis
				if analysis_ui:
					analysis_ui.visible = show_euler_analysis
			KEY_N:
				show_bridge_names = not show_bridge_names
				_update_bridge_labels()
			KEY_D:
				show_construction_dates = not show_construction_dates
				_update_bridge_labels()

func _update_bridge_labels():
	"""Update bridge name labels"""
	# This would update bridge labels based on current settings
	pass

func get_konigsberg_educational_info() -> Dictionary:
	"""Get educational information about the Königsberg problem"""
	return {
		"historical_info": historical_info,
		"euler_analysis": euler_analysis,
		"bridge_data": bridge_data,
		"landmass_data": landmass_data,
		"mathematical_significance": "First application of graph theory to solve a real-world problem",
		"modern_relevance": "Foundation for network analysis, routing algorithms, and topology"
	}
