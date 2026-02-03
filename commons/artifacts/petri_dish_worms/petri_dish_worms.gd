# petri_dish_worms.gd
# Petri dish with small oscillating sine worms
# Biological creatures that move in sinusoidal patterns
# Demonstrates oscillation in living systems
extends Node3D

class_name PetriDishWorms

## Worm parameters
@export var num_worms: int = 8
@export var worm_length: int = 20
@export var worm_speed: float = 0.3
@export var oscillation_speed: float = 1.5
@export var oscillation_amplitude: float = 0.02
@export var worm_radius: float = 0.003

## Dish parameters
@export var dish_radius: float = 0.15
@export var dish_height: float = 0.02
@export var medium_color: Color = Color(0.9, 0.85, 0.7, 0.4)  # Agar color

## Internal
var worms: Array[Dictionary] = []
var worm_meshes: Array[MeshInstance3D] = []
var time: float = 0.0

@onready var dish: MeshInstance3D = $Dish
@onready var rim: MeshInstance3D = $Rim
@onready var medium: MeshInstance3D = $Medium
@onready var worm_container: Node3D = $WormContainer

func _ready() -> void:
	_setup_dish()
	_spawn_worms()

func _setup_dish() -> void:
	# Dish material (glass)
	if dish:
		var dish_mat = StandardMaterial3D.new()
		dish_mat.albedo_color = Color(0.95, 0.97, 1.0, 0.2)
		dish_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dish_mat.roughness = 0.0
		dish_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		dish.material_override = dish_mat
	
	# Rim/lid material (glass, same as dish)
	if rim:
		var rim_mat = StandardMaterial3D.new()
		rim_mat.albedo_color = Color(0.95, 0.97, 1.0, 0.15)
		rim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rim_mat.roughness = 0.0
		rim_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		rim.material_override = rim_mat
	
	# Medium (agar) material
	if medium:
		var medium_mat = StandardMaterial3D.new()
		medium_mat.albedo_color = medium_color
		medium_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		medium.material_override = medium_mat

func _spawn_worms() -> void:
	if not worm_container:
		worm_container = Node3D.new()
		worm_container.name = "WormContainer"
		add_child(worm_container)
	
	var worm_mat = StandardMaterial3D.new()
	worm_mat.vertex_color_use_as_albedo = true
	worm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	for i in range(num_worms):
		# Random starting position within dish
		var angle = randf() * TAU
		var dist = randf() * dish_radius * 0.7
		var start_pos = Vector3(cos(angle) * dist, 0.015, sin(angle) * dist)
		
		# Random direction
		var dir_angle = randf() * TAU
		var direction = Vector3(cos(dir_angle), 0, sin(dir_angle))
		
		# Random phase offset for variety
		var phase = randf() * TAU
		
		# Random color (pinkish/reddish tones)
		var hue = randf_range(0.95, 1.05)  # Red-pink range
		if hue > 1.0: hue -= 1.0
		var worm_color = Color.from_hsv(hue, 0.6, 0.9)
		
		var worm_data = {
			"position": start_pos,
			"direction": direction,
			"phase": phase,
			"speed": worm_speed * randf_range(0.7, 1.3),
			"color": worm_color,
			"frequency": oscillation_speed * randf_range(0.8, 1.2)
		}
		worms.append(worm_data)
		
		# Create mesh instance for this worm
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.material_override = worm_mat
		worm_container.add_child(mesh_instance)
		worm_meshes.append(mesh_instance)

func _process(delta: float) -> void:
	time += delta
	
	for i in range(worms.size()):
		_update_worm(i, delta)
		_draw_worm(i)

func _update_worm(index: int, delta: float) -> void:
	var worm = worms[index]
	
	# Move forward slowly
	var move_amount = worm.speed * delta * 0.1
	worm.position += worm.direction * move_amount
	
	# Bounce off dish edges
	var dist_from_center = Vector2(worm.position.x, worm.position.z).length()
	if dist_from_center > dish_radius * 0.85:
		# Reflect direction
		var normal = Vector3(worm.position.x, 0, worm.position.z).normalized()
		worm.direction = worm.direction - 2 * worm.direction.dot(normal) * normal
		worm.direction = worm.direction.normalized()
		
		# Push back inside
		worm.position = Vector3(normal.x, 0.015, normal.z) * dish_radius * 0.8
	
	# Occasionally change direction slightly
	if randf() < 0.01:
		var turn = randf_range(-0.3, 0.3)
		worm.direction = worm.direction.rotated(Vector3.UP, turn)

func _draw_worm(index: int) -> void:
	var worm = worms[index]
	var mesh_instance = worm_meshes[index]
	
	var mesh = ImmediateMesh.new()
	
	if worm_length < 2:
		mesh_instance.mesh = mesh
		return
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var head_pos = worm.position
	var dir = worm.direction
	var perpendicular = Vector3(-dir.z, 0, dir.x)
	
	for j in range(worm_length):
		var t = float(j) / (worm_length - 1)
		var segment_pos = head_pos - dir * t * 0.05  # Trail behind
		
		# Sine wave oscillation perpendicular to movement
		var wave_offset = sin(time * worm.frequency + worm.phase + t * 8.0) * oscillation_amplitude * (1.0 - t * 0.5)
		segment_pos += perpendicular * wave_offset
		
		# Color fades toward tail
		var alpha = 1.0 - t * 0.7
		var color = Color(worm.color.r, worm.color.g, worm.color.b, alpha)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(segment_pos)
	
	mesh.surface_end()
	mesh_instance.mesh = mesh