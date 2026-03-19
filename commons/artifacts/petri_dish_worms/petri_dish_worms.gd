# petri_dish_worms.gd
## Simulates oscillating sine worms in a petri dish.
## Each worm follows a random walk with sinusoidal lateral oscillation,
## bouncing off the dish boundary to stay contained.
## Key parameters: num_worms sets population, oscillation_speed/amplitude
## control the sine wave, worm_speed sets forward crawling rate.
extends Node3D

class_name PetriDishWorms

## Number of worms in the dish (1–30)

# @identity
# essence: worm_segment[i].offset = amplitude * sin(oscillation_speed * t + i * phase_per_segment)
# desire: Watch tiny worms wriggle in a petri dish, their bodies undulating with traveling sine waves
# critical_parameter: oscillation_speed — controls the frequency of the sinusoidal body wave
# triggers: time drives phase-offset sine displacement along each worm body segment
# emerges: lifelike locomotion from pure sine wave propagation through a chain of segments
# needs: VR sliders for speed/count [has], observation [has]
# relationships: depends on phase-offset sine animation; contrasts with dna_specimen (motile vs static biology); unlocks biological wave locomotion
# truth: A worm moves by passing a sine wave through its body — locomotion is traveling oscillation.

@export_range(1, 30) var num_worms: int = 8
## Segments per worm body — higher values produce smoother curves (2–50)
@export_range(2, 50) var worm_length: int = 20
## Forward crawling speed in units per second (0.01–2.0)
@export_range(0.01, 2.0, 0.01) var worm_speed: float = 0.3
## Lateral sine oscillation frequency in Hz (0.1–10.0)
@export_range(0.1, 10.0, 0.1) var oscillation_speed: float = 1.5
## Lateral oscillation width in meters (0.001–0.1)
@export_range(0.001, 0.1, 0.001) var oscillation_amplitude: float = 0.02
## Half-width of each worm ribbon in meters (0.001–0.02)
@export_range(0.001, 0.02, 0.001) var worm_radius: float = 0.012

## Radius of the petri dish in meters (0.05–0.5)
@export_range(0.05, 0.5, 0.01) var dish_radius: float = 0.15
## Height of the dish wall in meters (0.005–0.1)
@export_range(0.005, 0.1, 0.005) var dish_height: float = 0.02
## Color of the agar growth medium
@export var medium_color: Color = Color(0.9, 0.85, 0.7, 0.4)

var _worms: Array[Dictionary] = []
var _worm_meshes: Array[MeshInstance3D] = []
var _worm_ims: Array[ImmediateMesh] = []
var _time: float = 0.0
var _speed_scale: float = 1.0

var SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
var _speed_slider: Node = null

@onready var dish: MeshInstance3D = $Dish
@onready var rim: MeshInstance3D = $Rim
@onready var medium: MeshInstance3D = $Medium
@onready var worm_container: Node3D = $WormContainer

func _ready() -> void:
	_setup_dish()
	_spawn_worms()
	_setup_controls()

## Applies glass and agar materials to the dish, rim, and medium meshes.
func _setup_dish() -> void:
	if dish:
		var dish_mat = StandardMaterial3D.new()
		dish_mat.albedo_color = Color(0.95, 0.97, 1.0, 0.2)
		dish_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dish_mat.roughness = 0.0
		dish_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		dish.material_override = dish_mat

	if rim:
		var rim_mat = StandardMaterial3D.new()
		rim_mat.albedo_color = Color(0.95, 0.97, 1.0, 0.15)
		rim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rim_mat.roughness = 0.0
		rim_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		rim.material_override = rim_mat

	if medium:
		var medium_mat = StandardMaterial3D.new()
		medium_mat.albedo_color = medium_color
		medium_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		medium.material_override = medium_mat

## Creates worm simulation data and pre-allocates reusable ImmediateMesh instances.
func _spawn_worms() -> void:
	if not worm_container:
		worm_container = Node3D.new()
		worm_container.name = "WormContainer"
		add_child(worm_container)

	var worm_mat = StandardMaterial3D.new()
	worm_mat.vertex_color_use_as_albedo = true
	worm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	worm_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	worm_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_worms.resize(num_worms)
	_worm_meshes.resize(num_worms)
	_worm_ims.resize(num_worms)

	for i in range(num_worms):
		var angle = randf() * TAU
		var dist = randf() * dish_radius * 0.7
		var start_pos = Vector3(cos(angle) * dist, 0.015, sin(angle) * dist)

		var dir_angle = randf() * TAU
		var direction = Vector3(cos(dir_angle), 0, sin(dir_angle))

		var phase = randf() * TAU

		# Varied worm hues: pinks, oranges, greens for contrast with agar
		var hue = randf_range(0.0, 0.4)
		var worm_color = Color.from_hsv(hue, 0.8, 1.0)

		_worms[i] = {
			"position": start_pos,
			"direction": direction,
			"phase": phase,
			"speed": worm_speed * randf_range(0.7, 1.3),
			"color": worm_color,
			"frequency": oscillation_speed * randf_range(0.8, 1.2)
		}

		var im = ImmediateMesh.new()
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = im
		mesh_instance.material_override = worm_mat
		worm_container.add_child(mesh_instance)
		_worm_meshes[i] = mesh_instance
		_worm_ims[i] = im

func _setup_controls() -> void:
	var slider = SliderScene.instantiate()
	slider.position = Vector3(0, 0.5, 0.6)
	slider.set_param_name("Speed")
	slider.set_normalized_value(0.5)
	slider.slider_moved.connect(_on_speed_changed)
	add_child(slider)
	_speed_slider = slider

func _on_speed_changed() -> void:
	if _speed_slider:
		_speed_scale = _speed_slider.get_normalized_value() * 2.0

func _process(delta: float) -> void:
	_time = wrapf(_time + delta, 0.0, 1000.0)

	for i in range(_worms.size()):
		_update_worm(i, delta)
		_draw_worm(i)

## Moves a worm forward, reflects off dish edges, and randomly turns.
func _update_worm(index: int, delta: float) -> void:
	var worm = _worms[index]

	var move_amount = worm.speed * _speed_scale * delta * 0.1
	worm.position += worm.direction * move_amount

	var dist_from_center = Vector2(worm.position.x, worm.position.z).length()
	if dist_from_center > dish_radius * 0.85:
		var normal = Vector3(worm.position.x, 0, worm.position.z).normalized()
		worm.direction = worm.direction - 2 * worm.direction.dot(normal) * normal
		worm.direction = worm.direction.normalized()
		worm.position = Vector3(normal.x, 0.015, normal.z) * dish_radius * 0.8

	if randf() < 0.01:
		var turn = randf_range(-0.3, 0.3)
		worm.direction = worm.direction.rotated(Vector3.UP, turn)

## Rebuilds a worm's ribbon mesh with sine-wave oscillation.
## Uses TRIANGLE_STRIP for visible width instead of invisible 1-pixel lines.
func _draw_worm(index: int) -> void:
	var worm = _worms[index]
	var im = _worm_ims[index]

	im.clear_surfaces()

	if worm_length < 2:
		return

	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var head_pos = worm.position
	var dir = worm.direction
	var perpendicular = Vector3(-dir.z, 0, dir.x)
	var ribbon_up = Vector3.UP  # ribbon width direction

	for j in range(worm_length):
		var t = float(j) / (worm_length - 1)
		var segment_pos = head_pos - dir * t * dish_radius * 0.6

		var wave_offset = sin(_time * worm.frequency + worm.phase + t * 6.0) * oscillation_amplitude * 2.0 * (1.0 - t * 0.5)
		segment_pos += perpendicular * wave_offset

		var alpha = 1.0 - t * 0.7
		var color = Color(worm.color.r, worm.color.g, worm.color.b, alpha)
		# Worm tapers: head is full width, tail is thinner
		var width = worm_radius * (1.0 - t * 0.6)
		var offset = perpendicular * width

		im.surface_set_color(color)
		im.surface_add_vertex(segment_pos + offset)
		im.surface_set_color(color)
		im.surface_add_vertex(segment_pos - offset)

	im.surface_end()

func _exit_tree() -> void:
	for mesh_instance in _worm_meshes:
		if is_instance_valid(mesh_instance):
			mesh_instance.queue_free()
	_worm_meshes.clear()
	_worm_ims.clear()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
