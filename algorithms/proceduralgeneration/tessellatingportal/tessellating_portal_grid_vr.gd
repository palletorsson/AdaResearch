# tessellating_portal_grid_vr.gd
# Display all portal types in a 10x10 grid for VR viewing
extends Node3D

@export var grid_size: int = 10
@export var spacing: float = 4.0
@export var portal_radius: float = 1.5
@export var portal_thickness: float = 0.8
@export var block_size: float = 0.3
@export var animate_portals: bool = false

const TessellatingPortal = preload("res://algorithms/proceduralgeneration/tessellatingportal/tessellating_portal.gd")

# Portal types
const PORTAL_TYPES = [
	"CUBE",
	"TRUNCATED_OCTAHEDRON",
	"RHOMBIC_DODECAHEDRON",
	"TRIANGULAR_PRISM",
	"HEXAGONAL_PRISM",
	"GYROBIFASTIGIUM"
]

var portals: Array = []

func _ready():
	generate_portal_grid()

func generate_portal_grid():
	print("Generating %dx%d portal grid..." % [grid_size, grid_size])
	
	# Clear existing portals
	for portal in portals:
		if is_instance_valid(portal):
			portal.queue_free()
	portals.clear()
	
	# Calculate grid offset to center it
	var grid_offset = Vector3(
		-(grid_size - 1) * spacing / 2.0,
		0,
		-(grid_size - 1) * spacing / 2.0
	)
	
	var portal_index = 0
	
	# Create grid of portals
	for z in range(grid_size):
		for x in range(grid_size):
			var position = grid_offset + Vector3(x * spacing, 0, z * spacing)
			
			# Determine portal type (cycle through available types)
			var type_index = portal_index % PORTAL_TYPES.size()
			
			# Vary parameters slightly for visual variety
			var variation = float(portal_index) / float(grid_size * grid_size)
			var local_radius = portal_radius + sin(variation * TAU) * 0.3
			var local_thickness = portal_thickness + cos(variation * TAU * 2) * 0.2
			var local_block_size = block_size + sin(variation * TAU * 3) * 0.05
			
			# Vary color based on position
			var hue = float(portal_index) / float(grid_size * grid_size)
			var color = Color.from_hsv(hue, 0.7, 0.9)
			
			# Create portal
			var portal = create_portal(
				type_index,
				position,
				local_radius,
				local_thickness,
				local_block_size,
				color
			)
			
			if portal:
				add_child(portal)
				portals.append(portal)
			
			portal_index += 1
	
	print("Generated %d portals" % portals.size())

func create_portal(type_index: int, position: Vector3, radius: float, thickness: float, block_sz: float, color: Color) -> Node3D:
	"""Create a single portal instance"""
	var portal_node = Node3D.new()
	portal_node.position = position
	
	# Create the portal script instance
	var portal_script = TessellatingPortal.new()
	portal_node.set_script(TessellatingPortal)
	
	# Set portal properties
	portal_node.portal_type = type_index
	portal_node.portal_radius = radius
	portal_node.portal_thickness = thickness
	portal_node.block_size = block_sz
	portal_node.portal_color = color
	portal_node.emission_strength = 1.5
	portal_node.animate_rotation = animate_portals  # No rotation for VR
	
	# Add label below portal
	var label = Label3D.new()
	label.text = PORTAL_TYPES[type_index]
	label.position = Vector3(0, -2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.modulate = color
	portal_node.add_child(label)
	
	return portal_node

func _input(event):
	"""Handle regeneration input"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("Regenerating portal grid...")
			generate_portal_grid()
		elif event.keycode == KEY_T:
			animate_portals = !animate_portals
			print("Portal animation: ", "ON" if animate_portals else "OFF")
			for portal in portals:
				if is_instance_valid(portal):
					portal.animate_rotation = animate_portals
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			# Increase spacing
			spacing += 0.5
			print("Spacing: %.1f" % spacing)
			generate_portal_grid()
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			# Decrease spacing
			spacing = max(2.0, spacing - 0.5)
			print("Spacing: %.1f" % spacing)
			generate_portal_grid()




