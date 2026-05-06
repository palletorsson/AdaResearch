# KnowledgeTerrainSpace.gd
# Generates a walkable terrain from the AdaResearch knowledge taxonomy
# The topology IS the curriculum - concepts as terrain, relationships as paths
#
# "The ground you walk on is shaped by what humanity wrote down."

extends TopologySpace
class_name KnowledgeTerrainSpace

# QFEP Phase colors (from WorldMapDataProvider)
const PHASE_COLORS := {
	"F_order": Color("#4A90D9"),       # Blue - order, prediction
	"oscillation": Color("#9B59B6"),   # Purple - F↔E balance
	"E_entropy": Color("#E74C3C"),     # Red - entropy, disorder
	"lambda_edge": Color("#F39C12"),   # Orange - edge of chaos
	"integration": Color("#2ECC71"),   # Green - φΔE emergence
	"synthesis": Color("#E91E63")      # Pink - full QFEP
}

# Category positions in concept space (hand-tuned embedding approximation)
# These create the "neighborhoods" of the knowledge terrain
const CATEGORY_POSITIONS := {
	"Primitives": Vector2(0.0, 0.0),
	"Arrays": Vector2(2.0, 1.0),
	"Transformations": Vector2(1.0, 2.0),
	"Vectors": Vector2(3.0, 2.0),
	"WaveFunctions": Vector2(2.0, 4.0),
	"Color": Vector2(-1.0, 2.0),
	"PatternGeneration": Vector2(4.0, 3.0),
	"DataStructures": Vector2(5.0, 1.0),
	"Algorithms": Vector2(6.0, 2.0),
	"SpaceTopology": Vector2(3.0, 5.0),
	"Fractals": Vector2(4.0, 5.0),
	"Randomness": Vector2(5.0, 4.0),
	"Effects": Vector2(-1.0, 4.0),
	"Tutorial": Vector2(-2.0, 0.0),
}

# Terrain generation parameters
@export var terrain_scale: float = 5.0  # How spread out the terrain is
@export var concept_influence_radius: float = 3.0  # How far each concept affects terrain
@export var base_height: float = 0.5  # Minimum terrain height
@export var phase_height_influence: float = 1.5  # How much QFEP phase affects height
@export var show_concept_markers: bool = true
@export var marker_height: float = 2.0

# Internal state
var _sequences: Array[Dictionary] = []
var _concept_positions: Dictionary = {}  # sequence_name -> Vector2
var _concept_markers: Array[Node3D] = []
var _connection_lines: Array[MeshInstance3D] = []

func _ready():
	_load_knowledge_data()
	_calculate_concept_positions()
	super._ready()  # Calls setup_topology_space() and generate_space()

func _load_knowledge_data():
	"""Load sequence and map data from the curriculum"""
	# Try to use WorldMapDataProvider if available
	if ClassDB.class_exists("WorldMapDataProvider"):
		_sequences = WorldMapDataProvider.get_all_sequences()
	else:
		# Fallback: load directly from curriculum_spine.json
		_load_from_spine_file()
	
	print("KnowledgeTerrainSpace: Loaded %d sequences" % _sequences.size())

func _load_from_spine_file():
	"""Fallback loader if WorldMapDataProvider not available"""
	var file = FileAccess.open("res://commons/maps/curriculum_spine.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.data
			var spine = data.get("spine", {})
			var sequences = spine.get("sequences", [])
			for seq in sequences:
				_sequences.append({
					"name": seq.get("name", ""),
					"phase": seq.get("phase", "F_order"),
					"is_spine": true,
					"spine_order": seq.get("order", 0)
				})
		file.close()

func _calculate_concept_positions():
	"""Calculate 2D positions for each concept based on category and relationships"""
	for seq in _sequences:
		var seq_name: String = seq.get("name", "")
		var category = _extract_category(seq_name)
		var base_pos = CATEGORY_POSITIONS.get(category, Vector2(0, 0))
		
		# Add some variation based on sequence name hash
		var hash_offset = _name_to_offset(seq_name)
		var pos = base_pos * terrain_scale + hash_offset
		
		_concept_positions[seq_name] = pos

func _extract_category(sequence_name: String) -> String:
	"""Extract category from sequence name (e.g., 'Primitives_Points' -> 'Primitives')"""
	var parts = sequence_name.split("_")
	if parts.size() > 0:
		# Check if first part matches known categories
		for cat in CATEGORY_POSITIONS.keys():
			if sequence_name.begins_with(cat):
				return cat
	return "Tutorial"  # Default

func _name_to_offset(name: String) -> Vector2:
	"""Generate consistent pseudo-random offset from name"""
	var h = name.hash()
	var x = fmod(float(h), 100.0) / 50.0 - 1.0  # -1 to 1
	var z = fmod(float(h >> 8), 100.0) / 50.0 - 1.0
	return Vector2(x, z) * 2.0

func generate_space():
	"""Generate the knowledge terrain mesh"""
	var heights: Array = []
	heights.resize((resolution + 1) * (resolution + 1))
	
	# Generate height for each point based on concept proximity
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var world_x = (x / float(resolution)) * space_size.x - space_size.x / 2
			var world_z = (z / float(resolution)) * space_size.y - space_size.y / 2
			var point = Vector2(world_x, world_z)
			
			var height = _calculate_height_at(point)
			heights[z * (resolution + 1) + x] = height
	
	# Create mesh from heights
	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	
	# Apply knowledge terrain material
	var material = _create_terrain_material()
	mesh_instance.material_override = material
	
	# Create collision
	create_collision_from_mesh(mesh)
	
	# Add concept markers
	if show_concept_markers:
		_create_concept_markers()
		_create_connection_lines()

func _calculate_height_at(point: Vector2) -> float:
	"""Calculate terrain height based on nearby concepts"""
	var height = base_height
	
	for seq in _sequences:
		var seq_name: String = seq.get("name", "")
		var concept_pos = _concept_positions.get(seq_name, Vector2.ZERO)
		var distance = point.distance_to(concept_pos)
		
		if distance < concept_influence_radius:
			# Gaussian falloff
			var influence = exp(-distance * distance / (concept_influence_radius * 0.5))
			
			# Phase affects height (later phases = higher peaks)
			var phase: String = seq.get("phase", "F_order")
			var phase_height = _phase_to_height(phase)
			
			height += influence * phase_height * phase_height_influence
	
	return height * height_scale

func _phase_to_height(phase: String) -> float:
	"""Convert QFEP phase to height multiplier"""
	match phase:
		"F_order": return 0.5
		"oscillation": return 0.7
		"E_entropy": return 0.9
		"lambda_edge": return 1.2
		"integration": return 1.4
		"synthesis": return 1.6
		_: return 0.5

func _create_terrain_material() -> ShaderMaterial:
	"""Create material that colors terrain by concept proximity"""
	var material = ShaderMaterial.new()
	
	# Try to load a terrain shader, fallback to standard material
	var shader = load("res://commons/resourses/shaders/worldspacecolor.gdshader")
	if shader:
		material.shader = shader
	else:
		# Fallback to standard material
		var std_mat = StandardMaterial3D.new()
		std_mat.albedo_color = Color(0.3, 0.4, 0.5)
		std_mat.roughness = 0.8
		std_mat.vertex_color_use_as_albedo = true
		return std_mat
	
	return material

func _create_concept_markers():
	"""Create visual markers for each concept/sequence"""
	# Clear existing markers
	for marker in _concept_markers:
		marker.queue_free()
	_concept_markers.clear()
	
	for seq in _sequences:
		var seq_name: String = seq.get("name", "")
		var pos_2d = _concept_positions.get(seq_name, Vector2.ZERO)
		var phase: String = seq.get("phase", "F_order")
		
		# Calculate 3D position (sample terrain height)
		var terrain_height = _calculate_height_at(pos_2d)
		var pos_3d = Vector3(pos_2d.x, terrain_height + marker_height, pos_2d.y)
		
		# Create marker
		var marker = _create_single_marker(seq_name, phase, seq.get("is_spine", false))
		marker.position = pos_3d
		add_child(marker)
		_concept_markers.append(marker)

func _create_single_marker(seq_name: String, phase: String, is_spine: bool) -> Node3D:
	"""Create a single concept marker"""
	var marker = Node3D.new()
	marker.name = "Marker_" + seq_name
	
	# Sphere for the concept
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.3 if is_spine else 0.2
	sphere.radial_segments = 16
	sphere.rings = 8
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = PHASE_COLORS.get(phase, Color.WHITE)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.5
	mat.emission_energy_multiplier = 0.8
	sphere.material_override = mat
	marker.add_child(sphere)
	
	# Label
	var label = Label3D.new()
	label.text = seq_name.replace("_", "\n")
	label.font_size = 24 if is_spine else 18
	label.position = Vector3(0, 0.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = PHASE_COLORS.get(phase, Color.WHITE)
	label.outline_size = 4
	label.outline_modulate = Color.BLACK
	marker.add_child(label)
	
	return marker

func _create_connection_lines():
	"""Create lines connecting related concepts"""
	# Clear existing lines
	for line in _connection_lines:
		line.queue_free()
	_connection_lines.clear()
	
	# Connect spine sequences in order
	var spine_seqs = _sequences.filter(func(s): return s.get("is_spine", false))
	spine_seqs.sort_custom(func(a, b): return a.get("spine_order", 0) < b.get("spine_order", 0))
	
	for i in range(spine_seqs.size() - 1):
		var from_name: String = spine_seqs[i].get("name", "")
		var to_name: String = spine_seqs[i + 1].get("name", "")
		
		var from_pos = _concept_positions.get(from_name, Vector2.ZERO)
		var to_pos = _concept_positions.get(to_name, Vector2.ZERO)
		
		var from_3d = Vector3(from_pos.x, _calculate_height_at(from_pos) + 0.5, from_pos.y)
		var to_3d = Vector3(to_pos.x, _calculate_height_at(to_pos) + 0.5, to_pos.y)
		
		var line_mesh = _create_line_mesh(from_3d, to_3d, PHASE_COLORS.get(spine_seqs[i + 1].get("phase", "F_order"), Color.WHITE))
		add_child(line_mesh)
		_connection_lines.append(line_mesh)

func _create_line_mesh(from: Vector3, to: Vector3, color: Color) -> MeshInstance3D:
	"""Create a line mesh between two points"""
	var mesh_instance_line = MeshInstance3D.new()
	
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_set_color(color)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()
	
	mesh_instance_line.mesh = immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance_line.material_override = mat
	
	return mesh_instance_line

# ============================================================================
# PUBLIC API
# ============================================================================

func get_concept_at_position(world_pos: Vector3) -> String:
	"""Find which concept is nearest to a world position"""
	var point = Vector2(world_pos.x, world_pos.z)
	var closest_name = ""
	var closest_dist = INF
	
	for seq_name in _concept_positions.keys():
		var concept_pos = _concept_positions[seq_name]
		var dist = point.distance_to(concept_pos)
		if dist < closest_dist:
			closest_dist = dist
			closest_name = seq_name
	
	return closest_name if closest_dist < concept_influence_radius else ""

func get_nearby_concepts(world_pos: Vector3, radius: float = 5.0) -> Array[String]:
	"""Get all concepts within radius of position"""
	var point = Vector2(world_pos.x, world_pos.z)
	var result: Array[String] = []
	
	for seq_name in _concept_positions.keys():
		var concept_pos = _concept_positions[seq_name]
		if point.distance_to(concept_pos) < radius:
			result.append(seq_name)
	
	return result

func highlight_concept(seq_name: String):
	"""Highlight a specific concept marker"""
	for marker in _concept_markers:
		if marker.name == "Marker_" + seq_name:
			var sphere = marker.get_child(0) as CSGSphere3D
			if sphere:
				sphere.radius *= 1.5
				var mat = sphere.material_override as StandardMaterial3D
				if mat:
					mat.emission_energy_multiplier = 2.0
			break

func teleport_to_concept(seq_name: String) -> Vector3:
	"""Get position to teleport player to a concept"""
	var pos_2d = _concept_positions.get(seq_name, Vector2.ZERO)
	var height = _calculate_height_at(pos_2d)
	return Vector3(pos_2d.x, height + 1.0, pos_2d.y)
