extends Node3D

## Color Walls Office - Transparent colored glass walls like office partitions
## Spread out and rotated at various angles to create color mixing effects

@export var wall_size: Vector2 = Vector2(2.0, 2.4)
@export var wall_thickness: float = 0.03
@export var transparency: float = 0.4
@export var emit_strength: float = 0.6
@export var light_energy: float = 3.0
@export var light_range: float = 5.0

@export_category("Layout")
@export var spread: float = 2.5
@export var room_size: Vector3 = Vector3(12.0, 3.0, 10.0)

func _ready() -> void:
	_build_office_walls()

func _build_office_walls() -> void:
	# RGB Section - Primary additive colors
	_add_glass_wall(Vector3(-4, 0, -2), 15, Color.RED)
	_add_glass_wall(Vector3(-2.5, 0, -3), -20, Color.GREEN)
	_add_glass_wall(Vector3(-3.5, 0, -0.5), 45, Color.BLUE)
	
	# CMY Section - Primary subtractive colors  
	_add_glass_wall(Vector3(3, 0, -2), -25, Color.CYAN)
	_add_glass_wall(Vector3(4.5, 0, -3.5), 10, Color.MAGENTA)
	_add_glass_wall(Vector3(2, 0, -0.5), -40, Color.YELLOW)
	
	# Mixed colors section - center area
	_add_glass_wall(Vector3(-1, 0, 1), 30, Color.ORANGE)
	_add_glass_wall(Vector3(1, 0, 0.5), -35, Color.PURPLE)
	_add_glass_wall(Vector3(0, 0, 2.5), 0, Color.LIME)
	
	# Overlapping area - creates color mixing when viewed through multiple
	_add_glass_wall(Vector3(-0.8, 0, -1.5), 60, Color.RED, Vector2(1.5, 2.0))
	_add_glass_wall(Vector3(0, 0, -1.2), 60, Color.GREEN, Vector2(1.5, 2.0))
	_add_glass_wall(Vector3(0.8, 0, -0.9), 60, Color.BLUE, Vector2(1.5, 2.0))
	
	# Back wall partitions - warm colors
	_add_glass_wall(Vector3(-4, 0, 3), -10, Color(1.0, 0.3, 0.1), Vector2(2.5, 2.8))
	_add_glass_wall(Vector3(-1.5, 0, 3.5), 20, Color(1.0, 0.6, 0.0), Vector2(2.5, 2.8))
	
	# Back wall partitions - cool colors
	_add_glass_wall(Vector3(2, 0, 3), 5, Color(0.1, 0.5, 1.0), Vector2(2.5, 2.8))
	_add_glass_wall(Vector3(4.5, 0, 3.5), -15, Color(0.4, 0.1, 0.9), Vector2(2.5, 2.8))
	
	# Corner accents
	_add_glass_wall(Vector3(-5, 0, 0), 90, Color.WHITE, Vector2(1.0, 2.4))
	_add_glass_wall(Vector3(5, 0, 0), 90, Color(0.2, 0.2, 0.2), Vector2(1.0, 2.4))

func _add_glass_wall(pos: Vector3, angle_deg: float, color: Color, size: Vector2 = Vector2.ZERO) -> MeshInstance3D:
	var actual_size = size if size != Vector2.ZERO else wall_size
	
	var wall = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(actual_size.x, actual_size.y, wall_thickness)
	wall.mesh = mesh
	wall.position = Vector3(pos.x, actual_size.y * 0.5, pos.z)
	wall.rotation_degrees.y = angle_deg
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color.r, color.g, color.b, transparency)
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # See from both sides
	
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = emit_strength
	
	wall.material_override = mat
	add_child(wall)
	
	# Add colored light to the wall
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = light_energy
	light.omni_range = light_range
	light.position = Vector3(0, 0, wall_thickness * 2)  # Slightly in front of wall
	wall.add_child(light)
	
	return wall

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

