# ArtifactDisplay.gd
# Visual representation of collected artifacts in the lab
# Creates different display types based on artifact properties

extends Node3D
class_name ArtifactDisplay

# Configuration
@export var display_type: String = "pedestal"  # pedestal, hologram, interactive, floating
@export var artifact_scale: float = 1.0
@export var enable_interaction: bool = false

# Artifact data
var artifact_data: Dictionary = {}
var artifact_id: String = ""
var artifact_name: String = ""

# Visual components
var display_base: Node3D
var artifact_visual: Node3D
var info_panel: Node3D
var interaction_area: Area3D

# Animation
var rotation_speed: float = 15.0
var float_height: float = 0.05
var float_speed: float = 1.5

# Signals
signal artifact_examined(artifact_id: String)
signal artifact_interacted(artifact_id: String)

func _ready():
	print("ArtifactDisplay: Initializing display")

func setup_display(data: Dictionary):
	"""Setup the display with artifact data"""
	artifact_data = data
	artifact_id = data.get("id", "")
	artifact_name = data.get("name", artifact_id)
	display_type = data.get("display_type", "pedestal")
	enable_interaction = data.get("interactive", false)
	
	print("ArtifactDisplay: Setting up display for '%s' (type: %s)" % [artifact_name, display_type])
	
	_create_display_base()
	_create_artifact_visual()
	_create_info_panel()
	
	if enable_interaction:
		_setup_interaction()

func _create_display_base():
	"""Create the base/pedestal for the artifact"""
	display_base = Node3D.new()
	display_base.name = "DisplayBase"
	add_child(display_base)
	
	match display_type:
		"pedestal":
			_create_pedestal()
		"hologram":
			_create_hologram_base()
		"floating":
			_create_floating_base()
		"interactive":
			_create_interactive_base()
		_:
			_create_pedestal()  # Default

func _create_pedestal():
	"""Create a classic pedestal display"""
	var pedestal = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.15
	cylinder_mesh.bottom_radius = 0.15
	cylinder_mesh.height = 0.1
	pedestal.mesh = cylinder_mesh
	
	# Pedestal material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.9)
	material.metallic = 0.7
	material.roughness = 0.3
	pedestal.material_override = material
	
	display_base.add_child(pedestal)
	print("ArtifactDisplay: Created pedestal base")

func _create_hologram_base():
	"""Create a holographic projector base"""
	var projector = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.1
	cylinder_mesh.bottom_radius = 0.1
	cylinder_mesh.height = 0.05
	projector.mesh = cylinder_mesh
	
	# Projector material - glowing tech style
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission = Color.CYAN * 0.5
	material.metallic = 1.0
	material.roughness = 0.1
	projector.material_override = material
	
	display_base.add_child(projector)
	print("ArtifactDisplay: Created hologram base")

func _create_floating_base():
	"""Create an invisible base for floating artifacts"""
	# Just a position marker, no visual
	print("ArtifactDisplay: Created floating base")

func _create_interactive_base():
	"""Create an interactive display base"""
	var base = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.3, 0.1, 0.3)
	base.mesh = box_mesh
	
	# Interactive material - slightly glowing
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.9, 1.0)
	material.emission = Color(0.7, 0.9, 1.0) * 0.2
	material.metallic = 0.5
	material.roughness = 0.4
	base.material_override = material
	
	display_base.add_child(base)
	print("ArtifactDisplay: Created interactive base")

func _create_artifact_visual():
	"""Create the visual representation of the artifact"""
	artifact_visual = Node3D.new()
	artifact_visual.name = "ArtifactVisual"
	artifact_visual.position = Vector3(0, 0.1, 0)  # Above base
	add_child(artifact_visual)
	
	# Determine what kind of visual to create
	var visual_type = artifact_data.get("visual_type", "auto")
	if visual_type == "auto":
		visual_type = _determine_visual_type()
	
	match visual_type:
		"cube":
			_create_cube_visual()
		"sphere":
			_create_sphere_visual()
		"crystal":
			_create_crystal_visual()
		"disc":
			_create_disc_visual()
		_:
			_create_generic_visual()

func _determine_visual_type() -> String:
	"""Automatically determine visual type from artifact name/id"""
	var name_lower = artifact_name.to_lower()
	
	if "cube" in name_lower:
		return "cube"
	elif "sphere" in name_lower or "ball" in name_lower:
		return "sphere"
	elif "crystal" in name_lower or "gem" in name_lower:
		return "crystal"
	elif "disc" in name_lower or "grid" in name_lower:
		return "disc"
	else:
		return "cube"  # Default

func _create_cube_visual():
	"""Create a cube artifact visual"""
	var mesh_instance = MeshInstance3D.new()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(0.15, 0.15, 0.15) * artifact_scale
	mesh_instance.mesh = cube_mesh
	
	_apply_artifact_material(mesh_instance)
	artifact_visual.add_child(mesh_instance)
	print("ArtifactDisplay: Created cube visual")

func _create_sphere_visual():
	"""Create a sphere artifact visual"""
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1 * artifact_scale
	sphere_mesh.height = 0.2 * artifact_scale
	mesh_instance.mesh = sphere_mesh
	
	_apply_artifact_material(mesh_instance)
	artifact_visual.add_child(mesh_instance)
	print("ArtifactDisplay: Created sphere visual")

func _create_crystal_visual():
	"""Create a crystal artifact visual"""
	var mesh_instance = MeshInstance3D.new()
	var prism_mesh = PrismMesh.new()
	prism_mesh.left_to_right = 0.1 * artifact_scale
	prism_mesh.size = Vector3(0.15, 0.2, 0.15) * artifact_scale
	mesh_instance.mesh = prism_mesh
	
	_apply_artifact_material(mesh_instance, true)  # More crystalline
	artifact_visual.add_child(mesh_instance)
	print("ArtifactDisplay: Created crystal visual")

func _create_disc_visual():
	"""Create a disc artifact visual"""
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.12 * artifact_scale
	cylinder_mesh.bottom_radius = 0.12 * artifact_scale
	cylinder_mesh.height = 0.02 * artifact_scale
	mesh_instance.mesh = cylinder_mesh
	
	_apply_artifact_material(mesh_instance)
	artifact_visual.add_child(mesh_instance)
	print("ArtifactDisplay: Created disc visual")

func _create_generic_visual():
	"""Create a generic artifact visual"""
	_create_cube_visual()  # Default to cube

func _apply_artifact_material(mesh_instance: MeshInstance3D, crystalline: bool = false):
	"""Apply material based on artifact properties"""
	var material = StandardMaterial3D.new()
	
	# Get color from artifact data or use default
	var base_color = Color.WHITE
	if artifact_data.has("color"):
		var color_data = artifact_data.color
		if typeof(color_data) == TYPE_ARRAY and color_data.size() >= 3:
			base_color = Color(color_data[0], color_data[1], color_data[2])
		elif typeof(color_data) == TYPE_STRING:
			base_color = Color(color_data)
	else:
		# Generate color based on source sequence
		base_color = _get_sequence_color()
	
	material.albedo_color = base_color
	
	if crystalline:
		# Crystal properties
		material.emission = base_color * 0.3
		material.metallic = 0.1
		material.roughness = 0.0
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.8
	else:
		# Standard artifact properties
		material.emission = base_color * 0.2
		material.metallic = 0.6
		material.roughness = 0.2
	
	# Hologram effect for hologram display type
	if display_type == "hologram":
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.7
		material.emission = base_color * 0.5
	
	mesh_instance.material_override = material

func _get_sequence_color() -> Color:
	"""Get color based on source sequence"""
	var source = artifact_data.get("source_sequence", "unknown")
	match source:
		"array_tutorial":
			return Color.CYAN
		"randomness_exploration":
			return Color.MAGENTA
		"geometric_algorithms":
			return Color.GREEN
		"advanced_concepts":
			return Color.YELLOW
		_:
			return Color.WHITE

func _create_info_panel():
	"""Create information display"""
	info_panel = Node3D.new()
	info_panel.name = "InfoPanel"
	info_panel.position = Vector3(0, 0.3, 0)
	add_child(info_panel)
	
	# Create label
	var label = Label3D.new()
	label.text = artifact_name
	label.font_size = 16
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.9, 0.9, 1.0)
	info_panel.add_child(label)
	
	print("ArtifactDisplay: Created info panel")

func _setup_interaction():
	"""Setup interaction for interactive artifacts"""
	interaction_area = Area3D.new()
	interaction_area.name = "InteractionArea"
	
	var collision_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.3
	collision_shape.shape = shape
	
	interaction_area.add_child(collision_shape)
	add_child(interaction_area)
	
	# Connect signals
	interaction_area.body_entered.connect(_on_interaction_entered)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	
	print("ArtifactDisplay: Interaction setup complete")

func _process(delta):
	if not artifact_visual:
		return
	
	# Rotation animation
	artifact_visual.rotation_degrees.y += rotation_speed * delta
	
	# Floating animation for appropriate display types
	if display_type in ["hologram", "floating"]:
		var float_offset = sin(Time.get_time_dict_from_system().second * float_speed) * float_height
		artifact_visual.position.y = 0.1 + float_offset

func _on_interaction_entered(body):
	"""Handle interaction with the artifact"""
	if _is_player_body(body):
		print("ArtifactDisplay: Player examining artifact '%s'" % artifact_name)
		artifact_examined.emit(artifact_id)

func _on_interaction_area_entered(area):
	"""Handle area-based interaction"""
	if "Hand" in area.name:
		print("ArtifactDisplay: Hand interaction with artifact '%s'" % artifact_name)
		artifact_interacted.emit(artifact_id)

func _is_player_body(body: Node3D) -> bool:
	"""Check if body belongs to player"""
	return body.name.contains("Hand") or body.get_parent().name.contains("Hand")

# Public API
func get_artifact_id() -> String:
	return artifact_id

func get_artifact_name() -> String:
	return artifact_name

func get_artifact_data() -> Dictionary:
	return artifact_data

func set_highlight(enabled: bool):
	"""Highlight or unhighlight the artifact"""
	if not artifact_visual:
		return
	
	for child in artifact_visual.get_children():
		if child is MeshInstance3D:
			var material = child.material_override as StandardMaterial3D
			if material:
				if enabled:
					material.emission_energy = 2.0
				else:
					material.emission_energy = 1.0 
