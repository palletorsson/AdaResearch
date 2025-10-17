@tool
extends GraphSpace3D
class_name Konigsberg3D

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

# Königsberg-specific state
var landmasses: Array = []  # The four landmasses A, B, C, D
var bridges: Array = []     # The seven original bridges
var euler_analysis: Dictionary = {}
var path_attempt_visualization: Array = []
var degree_counts: Dictionary = {}

# Educational UI
var theorem_display: CanvasLayer
var analysis_panel: Panel

func _ready():
	# Override parent _ready to use Königsberg topology
	rng = RandomNumberGenerator.new()
	rng.seed = 1736  # Historical date
	
	_setup_konigsberg_topology()
	_create_3d_konigsberg_world()
	_analyze_euler_properties()
	_setup_educational_ui()
	
	if show_theorem_explanation:
		_display_euler_theorem()

func _setup_konigsberg_topology():
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
	
	# Create the seven bridges (edges) with historical names
	var bridge_connections = [
		{"from": 0, "to": 2, "name": "Krämer-Brücke", "built": 1286},      # A-C
		{"from": 0, "to": 2, "name": "Schmieden-Brücke", "built": 1379},   # A-C (parallel)
		{"from": 0, "to": 3, "name": "Holz-Brücke", "built": 1322},        # A-D
		{"from": 0, "to": 3, "name": "Hohe Brücke", "built": 1542},        # A-D (parallel)
		{"from": 0, "to": 1, "name": "Grüne Brücke", "built": 1322},       # A-B
		{"from": 1, "to": 2, "name": "Köttel-Brücke", "built": 1457},      # B-C
		{"from": 1, "to": 3, "name": "Honig-Brücke", "built": 1542}        # B-D
	]
	
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
			"bridge_id": i
		}
		edges.append(edge_data)
		bridges.append(edge_data)
		
		# Update adjacency
		adjacency[bridge.from].append({"to": bridge.to, "w": edge_data.w})
		adjacency[bridge.to].append({"to": bridge.from, "w": edge_data.w})
	
	# Calculate node degrees for Euler analysis
	_calculate_konigsberg_degrees()

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
	var traffic_factor = randf_range(0.8, 1.2)  # Random traffic variation
	return base_cost * age_factor * traffic_factor

func _calculate_konigsberg_degrees():
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

func _analyze_euler_properties():
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
	
	# Determine Eulerian properties
	euler_analysis["odd_degree_count"] = odd_degree_nodes.size()
	euler_analysis["even_degree_count"] = even_degree_nodes.size()
	euler_analysis["odd_degree_nodes"] = odd_degree_nodes
	euler_analysis["has_eulerian_circuit"] = odd_degree_nodes.size() == 0
	euler_analysis["has_eulerian_path"] = odd_degree_nodes.size() == 2
	euler_analysis["has_no_eulerian_solution"] = odd_degree_nodes.size() > 2
	
	# The Königsberg problem conclusion
	euler_analysis["problem_solvable"] = false  # All 4 nodes have odd degree
	euler_analysis["euler_conclusion"] = "Impossible - all four landmasses have odd degree"

func _create_3d_konigsberg_world():
	"""Create the 3D world representation of historical Königsberg"""
	_create_river_system()
	_create_landmass_structures()
	_create_historical_bridges()
	_create_educational_markers()

func _create_river_system():
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
	water_material.emission_enabled = true
	water_material.emission = Color(0.05, 0.15, 0.4)
	river.material_override = water_material
	
	add_child(river)

func _create_landmass_structures():
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

func _create_landmass_platform(node: Dictionary, index: int):
	"""Create a platform representing each landmass"""
	var platform = CSGCylinder3D.new()
	platform.name = "Landmass_" + node.landmass_name
	platform.radius = 4.0
	platform.height = 1.0
	platform.position = node.pos
	
	var platform_material = StandardMaterial3D.new()
	if highlight_odd_degree_nodes and degree_counts[index] % 2 == 1:
		platform_material.albedo_color = Color(0.8, 0.3, 0.3)  # Red for odd degree
		platform_material.emission = Color(0.4, 0.1, 0.1)
	else:
		platform_material.albedo_color = Color(0.4, 0.6, 0.3)  # Green for even degree
		platform_material.emission = Color(0.1, 0.2, 0.1)
	
	platform_material.emission_enabled = true
	platform.material_override = platform_material
	platform.use_collision = true
	
	add_child(platform)
	node.inst = platform

func _create_historical_building(node: Dictionary, index: int):
	"""Create historical building on landmass"""
	if structure_scenes.is_empty():
		return
	
	var building = structure_scenes[index % structure_scenes.size()].instantiate()
	building.name = "Building_" + node.landmass_name
	building.position = node.pos + Vector3(0, 1.0, 0)
	building.scale = Vector3.ONE * randf_range(0.8, 1.2)
	
	add_child(building)
	node.structure = building

func _create_degree_indicator(node: Dictionary, index: int):
	"""Create visual indicator showing node degree"""
	var label = Label3D.new()
	label.text = "Degree: " + str(degree_counts[index]) + "\n" + node.landmass_name
	label.position = node.pos + Vector3(0, 3.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	
	# Color based on degree parity
	if degree_counts[index] % 2 == 1:
		label.modulate = Color(1.0, 0.3, 0.3)  # Red for odd
	else:
		label.modulate = Color(0.3, 1.0, 0.3)  # Green for even
	
	add_child(label)

func _create_historical_bridges():
	"""Create the seven historical bridges with proper 3D representation"""
	for i in range(edges.size()):
		var edge = edges[i]
		var from_pos = nodes[edge.a]["pos"]
		var to_pos = nodes[edge.b]["pos"]
		
		_create_arched_bridge(from_pos, to_pos, edge, i)
		_create_bridge_nameplate(from_pos, to_pos, edge, i)

func _create_arched_bridge(from_pos: Vector3, to_pos: Vector3, edge: Dictionary, bridge_index: int):
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

func _bridge_arch_point(start: Vector3, end: Vector3, height: float, t: float) -> Vector3:
	"""Calculate point on bridge arch"""
	var base_point = start.lerp(end, t)
	var arch_factor = sin(t * PI)  # Sine curve for natural arch
	base_point.y += height * arch_factor
	return base_point

func _create_bridge_nameplate(from_pos: Vector3, to_pos: Vector3, edge: Dictionary, bridge_index: int):
	"""Create nameplate for each historical bridge"""
	var mid = (from_pos + to_pos) * 0.5
	mid.y += bridge_arch_height + 1.0
	
	var nameplate = Label3D.new()
	nameplate.text = edge.historical_name + "\n(Built: " + str(edge.construction_year) + ")"
	nameplate.position = mid
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nameplate.font_size = 24
	nameplate.modulate = Color(0.9, 0.9, 0.7)
	
	add_child(nameplate)

func _create_educational_markers():
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
	pillar_material.emission_enabled = true
	pillar_material.emission = Color(0.1, 0.1, 0.4)
	info_pillar.material_override = pillar_material
	
	add_child(info_pillar)
	
	# Theorem explanation
	var theorem_label = Label3D.new()
	theorem_label.text = "Euler's Theorem:\nA graph has an Eulerian path\nif and only if it has exactly\n0 or 2 vertices of odd degree"
	theorem_label.position = Vector3(0, 4.0, 0)
	theorem_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	theorem_label.font_size = 28
	theorem_label.modulate = Color(1.0, 1.0, 0.3)
	
	add_child(theorem_label)

func _setup_educational_ui():
	"""Setup educational UI overlay"""
	theorem_display = CanvasLayer.new()
	theorem_display.name = "KonigsbergUI"
	add_child(theorem_display)
	
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

func _update_analysis_ui():
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

func attempt_eulerian_path():
	"""Demonstrate why no Eulerian path exists"""
	if not animate_path_attempts:
		return
	
	print("Attempting Eulerian path...")
	print("All four landmasses have odd degree: ", degree_counts)
	print("Euler's theorem: A connected graph has an Eulerian path if and only if it has exactly 0 or 2 vertices of odd degree")
	print("Since we have 4 odd-degree vertices, no Eulerian path exists!")

func demonstrate_bridge_removal():
	"""Show how removing bridges affects Eulerian properties"""
	if not interactive_bridge_removal:
		return
	
	print("Try removing bridges to create an Eulerian path...")
	print("Need to reduce odd-degree vertices to exactly 2 or 0")

func _input(event):
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

func _display_euler_theorem():
	"""Display or hide Euler theorem explanation"""
	var theorem_pillar = get_node_or_null("EulerTheoremPillar")
	if theorem_pillar:
		theorem_pillar.visible = show_theorem_explanation

func _toggle_degree_indicators():
	"""Toggle visibility of degree indicators"""
	for child in get_children():
		if child.name.begins_with("Label3D"):
			child.visible = show_degree_labels

func get_konigsberg_info() -> Dictionary:
	"""Get comprehensive information about the Königsberg problem"""
	return {
		"problem_name": "Seven Bridges of Königsberg",
		"historical_date": 1736,
		"mathematician": "Leonhard Euler",
		"significance": "First problem in graph theory",
		"graph_properties": {
			"vertices": nodes.size(),
			"edges": edges.size(),
			"connected": true,
			"planar": true
		},
		"euler_analysis": euler_analysis,
		"degree_sequence": degree_counts,
		"historical_context": "Solved by Euler in 1736, proving no solution exists",
		"modern_relevance": "Foundation of graph theory and topology"
	}
