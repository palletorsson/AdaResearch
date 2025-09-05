extends Node3D
class_name PeabodyChronologicalChart

# Elizabeth Peabody's Chronological Chart System (1859)
# Revolutionary visual timeline of universal history

@export var grid_width: int = 20
@export var grid_height: int = 15
@export var cell_size: float = 0.1
@export var chart_scale: float = 1.0
@export var paper_color: Color = Color(0.92, 0.88, 0.82, 1)
@export var grid_line_color: Color = Color(0.4, 0.35, 0.3, 1)

var paper_material: StandardMaterial3D
var grid_material: StandardMaterial3D
var color_materials: Dictionary = {}

# Historical color coding system used by Peabody
var historical_colors = {
	"ancient_civilizations": Color(0.2, 0.6, 0.8, 1),    # Blue - Ancient civilizations
	"classical_period": Color(0.8, 0.4, 0.2, 1),         # Orange - Classical antiquity
	"medieval_period": Color(0.3, 0.7, 0.3, 1),          # Green - Medieval period
	"renaissance": Color(0.9, 0.7, 0.8, 1),              # Pink - Renaissance
	"modern_era": Color(0.7, 0.3, 0.7, 1),               # Purple - Modern era
	"wars_conflicts": Color(0.8, 0.2, 0.2, 1),           # Red - Wars and conflicts
	"discoveries": Color(0.9, 0.6, 0.2, 1),              # Gold/Orange - Discoveries
	"cultural_movements": Color(0.4, 0.8, 0.9, 1),       # Light blue - Cultural movements
	"political_changes": Color(0.6, 0.4, 0.2, 1),        # Brown - Political changes
	"religious_events": Color(0.5, 0.3, 0.6, 1)          # Dark purple - Religious events
}

# Chart data representing historical events and periods
var chart_data = [
	# Format: [x, y, width, height, color_key, label]
	# Ancient Civilizations
	[1, 1, 2, 2, "wars_conflicts", "Ancient Conflicts"],
	[4, 2, 3, 1, "ancient_civilizations", "Mesopotamia"],
	[8, 1, 2, 2, "classical_period", "Early Greece"],
	[11, 2, 2, 1, "discoveries", "Bronze Age"],
	[14, 1, 1, 1, "cultural_movements", "Early Art"],
	[16, 2, 2, 1, "classical_period", "Homer"],
	[19, 1, 1, 2, "political_changes", "City States"],
	
	# Classical Period
	[2, 4, 1, 1, "classical_period", "Rome Founded"],
	[5, 5, 2, 1, "cultural_movements", "Greek Philosophy"],
	[9, 4, 2, 2, "renaissance", "Classical Art"],
	[13, 5, 1, 1, "political_changes", "Republic"],
	[15, 4, 2, 1, "classical_period", "Caesar"],
	[18, 5, 1, 1, "religious_events", "Christianity"],
	
	# Medieval Period
	[1, 7, 1, 2, "wars_conflicts", "Barbarian Invasions"],
	[3, 8, 2, 1, "medieval_period", "Dark Ages"],
	[7, 7, 2, 2, "religious_events", "Byzantine Empire"],
	[11, 8, 2, 1, "cultural_movements", "Islamic Golden Age"],
	[15, 7, 1, 1, "discoveries", "Vikings"],
	[17, 8, 2, 1, "medieval_period", "Feudalism"],
	
	# Later Periods
	[2, 10, 2, 1, "renaissance", "Renaissance Italy"],
	[6, 11, 1, 1, "discoveries", "Printing Press"],
	[9, 10, 2, 2, "medieval_period", "Late Medieval"],
	[13, 11, 1, 1, "wars_conflicts", "Crusades"],
	[16, 10, 2, 1, "cultural_movements", "Humanism"],
	
	# Modern Era
	[1, 13, 1, 1, "discoveries", "New World"],
	[4, 14, 2, 1, "political_changes", "Reformation"],
	[8, 13, 1, 1, "wars_conflicts", "Religious Wars"],
	[11, 14, 1, 1, "modern_era", "Enlightenment"],
	[14, 13, 2, 1, "discoveries", "Scientific Revolution"],
	[17, 14, 2, 1, "political_changes", "Nation States"],
	
	# Complex multi-part entries (triangular divisions like in original)
	[1, 6, 1, 1, "multi_color_1", "Complex Period"],
	[12, 3, 1, 1, "multi_color_2", "Transition"],
	[16, 12, 2, 2, "multi_color_3", "Modern Conflicts"],
	[6, 9, 1, 1, "multi_color_4", "Cultural Shift"]
]

func _ready():
	setup_materials()
	create_paper_background()
	create_grid_structure()
	populate_historical_data()
	setup_lighting()
	create_legend()

func setup_materials():
	# Paper background
	paper_material = StandardMaterial3D.new()
	paper_material.albedo_color = paper_color
	paper_material.roughness = 0.9
	paper_material.metallic = 0.0
	
	# Grid lines
	grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = grid_line_color
	grid_material.roughness = 0.8
	grid_material.metallic = 0.0
	
	# Create materials for each historical color
	for key in historical_colors:
		var material = StandardMaterial3D.new()
		material.albedo_color = historical_colors[key]
		material.roughness = 0.7
		material.metallic = 0.1
		color_materials[key] = material
	
	# Special multi-color materials for complex entries
	create_multi_color_materials()

func create_multi_color_materials():
	# Create materials that represent multiple historical aspects
	# (triangular divisions like in the original chart)
	
	var multi_colors = {
		"multi_color_1": [historical_colors["wars_conflicts"], historical_colors["political_changes"]],
		"multi_color_2": [historical_colors["ancient_civilizations"], historical_colors["classical_period"]],
		"multi_color_3": [historical_colors["renaissance"], historical_colors["wars_conflicts"]],
		"multi_color_4": [historical_colors["medieval_period"], historical_colors["cultural_movements"]]
	}
	
	for key in multi_colors:
		var material = StandardMaterial3D.new()
		# Blend the two colors
		var color1 = multi_colors[key][0]
		var color2 = multi_colors[key][1]
		material.albedo_color = color1.lerp(color2, 0.5)
		material.roughness = 0.7
		material.metallic = 0.1
		color_materials[key] = material

func create_paper_background():
	var background = StaticBody3D.new()
	background.name = "PaperBackground"
	add_child(background)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "BackgroundSheet"
	mesh_instance.transform.basis = mesh_instance.transform.basis.rotated(Vector3.RIGHT, -PI/2)
	mesh_instance.position.y = -0.005
	
	var total_width = grid_width * cell_size * chart_scale
	var total_height = grid_height * cell_size * chart_scale
	
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(total_width + 0.2, total_height + 0.2)
	mesh_instance.mesh = quad_mesh
	mesh_instance.material_override = paper_material
	
	background.add_child(mesh_instance)

func create_grid_structure():
	var grid_group = Node3D.new()
	grid_group.name = "GridStructure"
	add_child(grid_group)
	
	var start_x = -(grid_width * cell_size * chart_scale) / 2
	var start_z = -(grid_height * cell_size * chart_scale) / 2
	
	# Vertical lines
	for i in range(grid_width + 1):
		var line = create_grid_line(
			Vector3(start_x + i * cell_size * chart_scale, 0, start_z),
			Vector3(start_x + i * cell_size * chart_scale, 0, start_z + grid_height * cell_size * chart_scale),
			"VerticalLine" + str(i)
		)
		grid_group.add_child(line)
	
	# Horizontal lines
	for i in range(grid_height + 1):
		var line = create_grid_line(
			Vector3(start_x, 0, start_z + i * cell_size * chart_scale),
			Vector3(start_x + grid_width * cell_size * chart_scale, 0, start_z + i * cell_size * chart_scale),
			"HorizontalLine" + str(i)
		)
		grid_group.add_child(line)
	
	# Major division lines (thicker, representing centuries or major periods)
	create_major_divisions(grid_group, start_x, start_z)

func create_major_divisions(parent: Node3D, start_x: float, start_z: float):
	# Create thicker lines for major historical divisions
	var major_divisions_x = [5, 10, 15]  # Major time periods
	var major_divisions_z = [3, 6, 9, 12]  # Major historical eras
	
	for div_x in major_divisions_x:
		var thick_line = create_thick_grid_line(
			Vector3(start_x + div_x * cell_size * chart_scale, 0.001, start_z),
			Vector3(start_x + div_x * cell_size * chart_scale, 0.001, start_z + grid_height * cell_size * chart_scale),
			"MajorDivisionX" + str(div_x)
		)
		parent.add_child(thick_line)
	
	for div_z in major_divisions_z:
		var thick_line = create_thick_grid_line(
			Vector3(start_x, 0.001, start_z + div_z * cell_size * chart_scale),
			Vector3(start_x + grid_width * cell_size * chart_scale, 0.001, start_z + div_z * cell_size * chart_scale),
			"MajorDivisionZ" + str(div_z)
		)
		parent.add_child(thick_line)

func create_grid_line(start_pos: Vector3, end_pos: Vector3, line_name: String) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	line.name = line_name
	
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	vertices.append(start_pos)
	vertices.append(end_pos)
	indices.append(0)
	indices.append(1)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	line.mesh = mesh
	line.material_override = grid_material
	return line

func create_thick_grid_line(start_pos: Vector3, end_pos: Vector3, line_name: String) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	line.name = line_name
	
	var direction = (end_pos - start_pos).normalized()
	var length = start_pos.distance_to(end_pos)
	var center = (start_pos + end_pos) / 2
	
	var box_mesh = BoxMesh.new()
	if abs(direction.x) > abs(direction.z):
		box_mesh.size = Vector3(length, 0.002, 0.003)
	else:
		box_mesh.size = Vector3(0.003, 0.002, length)
	
	line.mesh = box_mesh
	line.position = center
	
	var thick_material = grid_material.duplicate()
	thick_material.albedo_color = grid_line_color * 0.7  # Darker for emphasis
	line.material_override = thick_material
	
	return line

func populate_historical_data():
	var data_group = Node3D.new()
	data_group.name = "HistoricalData"
	add_child(data_group)
	
	var start_x = -(grid_width * cell_size * chart_scale) / 2
	var start_z = -(grid_height * cell_size * chart_scale) / 2
	
	for entry in chart_data:
		var x = entry[0]
		var z = entry[1]
		var width = entry[2]
		var height = entry[3]
		var color_key = entry[4]
		var label = entry[5]
		
		create_historical_entry(data_group, x, z, width, height, color_key, label, start_x, start_z)

func create_historical_entry(parent: Node3D, grid_x: int, grid_z: int, width: int, height: int, color_key: String, label: String, start_x: float, start_z: float):
	var entry = Node3D.new()
	entry.name = "Entry_" + label.replace(" ", "_")
	parent.add_child(entry)
	
	var pos_x = start_x + (grid_x + width/2.0 - 0.5) * cell_size * chart_scale
	var pos_z = start_z + (grid_z + height/2.0 - 0.5) * cell_size * chart_scale
	
	# Check if this should be a complex multi-part entry
	if color_key.begins_with("multi_color"):
		create_complex_entry(entry, pos_x, pos_z, width, height, color_key, label)
	else:
		create_simple_entry(entry, pos_x, pos_z, width, height, color_key, label)

func create_simple_entry(parent: Node3D, pos_x: float, pos_z: float, width: int, height: int, color_key: String, label: String):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "HistoricalBlock"
	mesh_instance.position = Vector3(pos_x, 0.002, pos_z)
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(
		width * cell_size * chart_scale * 0.95,
		0.004,
		height * cell_size * chart_scale * 0.95
	)
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = color_materials[color_key]
	
	parent.add_child(mesh_instance)
	
	# Add subtle label (very small)
	if chart_scale > 0.5:  # Only show labels if chart is large enough
		var label_3d = Label3D.new()
		label_3d.text = label
		label_3d.position = Vector3(pos_x, 0.01, pos_z)
		label_3d.font_size = int(8 * chart_scale)
		label_3d.modulate = Color(0.2, 0.2, 0.2, 0.8)
		parent.add_child(label_3d)

func create_complex_entry(parent: Node3D, pos_x: float, pos_z: float, width: int, height: int, color_key: String, label: String):
	# Create triangular divisions like in Peabody's original
	var cell_width = width * cell_size * chart_scale
	var cell_height = height * cell_size * chart_scale
	
	# Create base block
	var base_block = MeshInstance3D.new()
	base_block.name = "ComplexBase"
	base_block.position = Vector3(pos_x, 0.001, pos_z)
	
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(cell_width * 0.95, 0.003, cell_height * 0.95)
	base_block.mesh = base_mesh
	base_block.material_override = color_materials[color_key]
	parent.add_child(base_block)
	
	# Add triangular divisions
	create_triangular_divisions(parent, pos_x, pos_z, cell_width, cell_height, color_key)

func create_triangular_divisions(parent: Node3D, pos_x: float, pos_z: float, cell_width: float, cell_height: float, color_key: String):
	# Create triangular mesh for complex historical periods
	var triangle_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var half_width = cell_width * 0.45
	var half_height = cell_height * 0.45
	
	# Triangle 1 (upper left)
	vertices.append(Vector3(-half_width, 0, -half_height))
	vertices.append(Vector3(0, 0, -half_height))
	vertices.append(Vector3(-half_width, 0, 0))
	
	# Triangle 2 (lower right)
	vertices.append(Vector3(0, 0, 0))
	vertices.append(Vector3(half_width, 0, 0))
	vertices.append(Vector3(half_width, 0, half_height))
	
	for i in range(6):
		normals.append(Vector3.UP)
	
	indices.append_array([0, 2, 1])  # Triangle 1
	indices.append_array([3, 5, 4])  # Triangle 2
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	triangle_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var triangle_instance = MeshInstance3D.new()
	triangle_instance.name = "TriangularDivision"
	triangle_instance.position = Vector3(pos_x, 0.003, pos_z)
	triangle_instance.mesh = triangle_mesh
	
	# Use a slightly different color for the triangular divisions
	var division_material = color_materials[color_key].duplicate()
	division_material.albedo_color = division_material.albedo_color * 0.8
	triangle_instance.material_override = division_material
	
	parent.add_child(triangle_instance)

func create_legend():
	var legend = Node3D.new()
	legend.name = "ColorLegend"
	legend.position = Vector3(
		(grid_width * cell_size * chart_scale) / 2 + 0.3,
		0,
		-(grid_height * cell_size * chart_scale) / 2
	)
	add_child(legend)
	
	var legend_titles = [
		["Ancient Civilizations", "ancient_civilizations"],
		["Classical Period", "classical_period"],
		["Medieval Period", "medieval_period"],
		["Renaissance", "renaissance"],
		["Modern Era", "modern_era"],
		["Wars & Conflicts", "wars_conflicts"],
		["Discoveries", "discoveries"],
		["Cultural Movements", "cultural_movements"],
		["Political Changes", "political_changes"],
		["Religious Events", "religious_events"]
	]
	
	for i in range(legend_titles.size()):
		var entry_data = legend_titles[i]
		var title = entry_data[0]
		var color_key = entry_data[1]
		
		# Color swatch
		var swatch = MeshInstance3D.new()
		swatch.name = "Swatch_" + str(i)
		swatch.position = Vector3(0, 0.002, i * 0.15)
		
		var swatch_mesh = BoxMesh.new()
		swatch_mesh.size = Vector3(0.08, 0.004, 0.08)
		swatch.mesh = swatch_mesh
		swatch.material_override = color_materials[color_key]
		legend.add_child(swatch)
		
		# Label
		var label = Label3D.new()
		label.text = title
		label.position = Vector3(0.15, 0.01, i * 0.15)
		label.font_size = int(12 * chart_scale)
		label.modulate = grid_line_color
		legend.add_child(label)

func setup_lighting():
	var lighting = Node3D.new()
	lighting.name = "DocumentLighting"
	add_child(lighting)
	
	# Soft directional light simulating reading lamp
	var main_light = DirectionalLight3D.new()
	main_light.name = "DocumentLight"
	main_light.position = Vector3(0, 2, 1)
	main_light.look_at(Vector3.ZERO, Vector3.UP)
	main_light.light_energy = 1.0
	main_light.light_color = Color(1, 0.95, 0.85, 1)  # Warm paper lighting
	main_light.shadow_enabled = true
	lighting.add_child(main_light)
	
	# Ambient lighting
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.95, 0.92, 0.88, 1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.9, 0.85, 0.8, 1)
	environment.ambient_light_energy = 0.6
	world_env.environment = environment
	add_child(world_env)

# Utility function to add custom historical events
func add_historical_event(grid_x: int, grid_z: int, width: int, height: int, color_key: String, label: String):
	var data_group = get_node_or_null("HistoricalData")
	if data_group:
		var start_x = -(grid_width * cell_size * chart_scale) / 2
		var start_z = -(grid_height * cell_size * chart_scale) / 2
		create_historical_entry(data_group, grid_x, grid_z, width, height, color_key, label, start_x, start_z)

# Animation function for educational presentations
func animate_historical_progression():
	var data_group = get_node_or_null("HistoricalData")
	if not data_group:
		return
	
	# Hide all entries initially
	for child in data_group.get_children():
		child.modulate.a = 0.0
	
	# Animate entries appearing in chronological order
	var tween = create_tween()
	var delay = 0.0
	
	for child in data_group.get_children():
		tween.parallel().tween_property(child, "modulate:a", 1.0, 0.5).set_delay(delay)
		delay += 0.2
