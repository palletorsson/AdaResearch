extends Node3D

# Portal torus configuration
@export var num_portals : int = 7
@export var portal_radius : float = 50.0  # Outer radius of each torus
@export var portal_thickness : float = 15.0  # Thickness of torus tube
@export var portal_spacing : float = 300.0  # Distance between portals
@export var portal_emergence_height : float = -30.0  # How much of torus is buried
@export var use_fallback : bool = false

# Terrain settings
@export var terrain_material : Material
@export var portal_colors : Array[Color] = [
	Color(1.0, 0.3, 0.3, 1.0),  # Red
	Color(0.3, 1.0, 0.3, 1.0),  # Green
	Color(0.3, 0.3, 1.0, 1.0),  # Blue
	Color(1.0, 1.0, 0.3, 1.0),  # Yellow
	Color(1.0, 0.3, 1.0, 1.0),  # Magenta
	Color(0.3, 1.0, 1.0, 1.0),  # Cyan
	Color(1.0, 0.6, 0.2, 1.0),  # Orange
]

var portal_meshes : Array[MeshInstance3D] = []
var terrain_mesh : MeshInstance3D

func _ready():
	print("🌟 TerrainGeneratorPortals: Creating portal landscape...")
	print("  - Portals: %d" % num_portals)
	print("  - Spacing: %.1fm" % portal_spacing)
	print("  - Radius: %.1fm" % portal_radius)
	print("  - Emergence: %.1fm" % portal_emergence_height)
	print("  - Fallback mode: %s" % str(use_fallback))
	
	_create_terrain()
	await get_tree().create_timer(0.5).timeout  # Give terrain time to initialize
	
	_create_portals()
	await get_tree().create_timer(0.5).timeout  # Give portals time to initialize
	
	print("✅ TerrainGeneratorPortals: Complete!")
	print("  - Check scene tree for Terrain and Portal_0 through Portal_%d nodes" % (num_portals - 1))

func _create_terrain():
	"""Create the base flat terrain"""
	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.name = "Terrain"
	
	if terrain_material:
		terrain_mesh.material_override = terrain_material
	
	# Use TerrainGeneratorFlat script - SET BEFORE ADDING TO TREE
	var terrain_script = load("res://algorithms/proceduralgeneration/marchingcave/Scripts/TerrainGeneratorFlat.gd")
	terrain_mesh.set_script(terrain_script)
	
	# Configure terrain BEFORE adding to tree
	terrain_mesh.set("noise_scale", 2.0)
	terrain_mesh.set("noise_offset", Vector3(100, 50, 75))
	terrain_mesh.set("iso_level", 0.0)
	terrain_mesh.set("chunk_scale", 400.0)
	terrain_mesh.set("center_position", Vector3.ZERO)
	terrain_mesh.set("use_fallback_cave", use_fallback)
	
	# Add to tree AFTER configuration - this will trigger _ready()
	add_child(terrain_mesh)
	
	print("✅ Terrain created")

func _create_portals():
	"""Create 7 torus portals at different positions"""
	# Arrange portals in a circle around the center
	var angle_step = TAU / num_portals
	
	for i in range(num_portals):
		var angle = i * angle_step
		var x = cos(angle) * portal_spacing
		var z = sin(angle) * portal_spacing
		var position = Vector3(x, portal_emergence_height, z)
		
		# Create portal mesh instance
		var portal = MeshInstance3D.new()
		portal.name = "Portal_%d" % i
		portal.position = position
		
		# Apply torus generator script BEFORE adding to tree
		var torus_script = load("res://algorithms/proceduralgeneration/marchingcave/Scripts/TerrainGeneratorTorus.gd")
		portal.set_script(torus_script)
		
		# Configure portal BEFORE adding to tree
		portal.set("noise_scale", 2.0)
		portal.set("noise_offset", Vector3(50 + i * 30, 25 + i * 10, 100 + i * 20))
		portal.set("iso_level", 0.0)
		portal.set("chunk_scale", portal_radius * 2.0)
		portal.set("center_position", Vector3.ZERO)
		portal.set("use_fallback", use_fallback)
		
		# Add to tree AFTER configuration - this will trigger _ready()
		add_child(portal)
		
		# Apply colored material
		var mat = StandardMaterial3D.new()
		if i < portal_colors.size():
			mat.albedo_color = portal_colors[i]
		else:
			mat.albedo_color = Color(randf(), randf(), randf(), 1.0)
		mat.metallic = 0.5
		mat.roughness = 0.3
		mat.emission_enabled = true
		mat.emission = mat.albedo_color * 0.3
		portal.material_override = mat
		
		portal_meshes.append(portal)
		
		# Add portal marker/label
		_create_portal_label(portal, i)
	
	print("✅ Created %d portals" % num_portals)

func _create_portal_label(portal: MeshInstance3D, index: int):
	"""Add a floating label above each portal"""
	var label = Label3D.new()
	label.name = "PortalLabel"
	label.text = "Portal %d" % (index + 1)
	label.position = Vector3(0, portal_radius + 20, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.modulate = portal_colors[index] if index < portal_colors.size() else Color.WHITE
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	portal.add_child(label)

