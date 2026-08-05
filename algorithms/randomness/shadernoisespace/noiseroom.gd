extends Node3D

# @identity
# essence: GPU computes noise per-fragment in parallel — the room sphere and walls run independent shader noise loops animated by a time uniform, cycling color and density in real-time
# desire: to be inside the noise — to stand inside a sphere where the walls are made of animated GPU hash functions and feel surrounded by the mathematics of structured randomness
# critical_parameter: generator (perlin) — which noise basis the fragment shader evaluates; the room is made of the field, so the basis is the architecture
# triggers: toggling animation_enabled freezes the noise field, revealing its spatial structure without temporal motion; space bar toggles it; escape resets to original parameters
# emerges: the two materials (room sphere vs walls) animate out of phase, creating a sense that the space itself is breathing — an undesigned emergent rhythm from two independent cycles
# needs: animation_enabled toggle via spacebar [has]; no VR slider controls [missing]; color cycling and density animation are coupled to time only [has]
# relationships: demonstrates GPU noise as distinct from CPU noise in noiselayers; pairs with shader_arch_gallery; shows what QueerNoiseShader.gdshader produces at room scale
# truth: GPU noise is not one calculation but millions happening simultaneously — the shader room makes visible that what looks like a continuous field is massively parallel computation

## GENERATOR — which basis fills the field. The same axis, the same four values in the same
## order, as perlin_noise, simplex_noise and noise_terrain carry: the noise sequence is built
## on comparing bases, and spelling the comparison a second way would leave nothing to
## compare. What is different here is the scale of the question. On the bench a basis is a
## tabletop of displaced cubes you look down at; in this room it is the walls, the ceiling and
## the floor, so choosing one decides what the space you are standing inside is MADE of.
##
## The default is perlin and not simplex — the opposite of the bench artifacts — because that
## is what this shader has always computed: hash2 returns a gradient per lattice corner and
## noise2d dots it with the offset, which is Perlin's construction with a sine hash in place
## of a permutation table.
##
##   simplex    the same gradient idea on a triangular lattice, three corners with a radial
##              falloff. No preferred direction survives; the busiest of the four
##   perlin     the shipped field. Smooth swells with the square lattice faintly latent
##   value      a random height per corner rather than a gradient, so cells become plateaus
##              and the grid stops being latent and becomes the picture
##   cellular   Worley. Not a smooth field at all — space partitioned by feature points, and
##              the only one of the four with edges in it
@export_enum("simplex", "perlin", "value", "cellular") var generator: String = "perlin"
const GENERATORS: PackedStringArray = ["simplex", "perlin", "value", "cellular"]

## CAPTURE BENCH ONLY, and deliberately not an axis. Every visible parameter of this room is
## driven off a clock in _process, so a still is taken at whatever moment the shutter happened
## to fall. `frozen` leaves the .tscn's own authored uniforms in place and never advances
## them, which makes four basis frames comparable instead of four different instants. It is a
## String enum rather than a bool because the sweep sets exports from strings before _ready
## and a typed bool silently rejects "true". No placement passes it.
@export_enum("live", "frozen") var animation: String = "live"

# Animation controls
@export var animation_enabled: bool = true
@export var animation_speed: float = 1.0
@export var time_scale_variation: float = 0.5
@export var color_cycling: bool = true
@export var color_cycle_speed: float = 0.3
@export var cloud_density_animation: bool = true
@export var density_variation: float = 0.5

# Shader material references
var room_material: ShaderMaterial
var wall_material: ShaderMaterial

# Animation state
var base_time: float = 0.0
var color_cycle_time: float = 0.0
var density_cycle_time: float = 0.0

# Original shader parameters (for restoration)
var original_room_params: Dictionary = {}
var original_wall_params: Dictionary = {}

func _ready() -> void:
	"""Initialize the noise room animation system"""
	_setup_materials()
	_store_original_parameters()
	_apply_generator()
	if animation == "frozen":
		animation_enabled = false
	_setup_ui()


## Writes the basis into both materials. At the default this writes 1 into a uniform whose
## own default is already 1, so the room renders the field it has always rendered — the
## perlin branch in the shader is the shipped noise2d body, unmoved.
func _apply_generator() -> void:
	var index: int = GENERATORS.find(generator)
	if index < 0:
		index = GENERATORS.find("perlin")
	if room_material:
		room_material.set_shader_parameter("noise_basis", index)
	if wall_material:
		wall_material.set_shader_parameter("noise_basis", index)

func _setup_materials() -> void:
	"""Find and setup shader materials"""
	# Find the main room sphere material
	var room_sphere = get_node("RoomContainer/MainRoomBody/RoomShape")
	if room_sphere and room_sphere.material_override:
		room_material = room_sphere.material_override as ShaderMaterial
	
	# Find the wall material (all walls use the same material)
	var front_wall = get_node("WallsContainer/FrontWall")
	if front_wall and front_wall.material_override:
		wall_material = front_wall.material_override as ShaderMaterial
	
	print("Noise Room: Materials found - Room: ", room_material != null, ", Wall: ", wall_material != null)

func _store_original_parameters() -> void:
	"""Store original shader parameters for restoration"""
	if room_material:
		original_room_params = {
			"time_scale": room_material.get_shader_parameter("time_scale"),
			"cloud_density": room_material.get_shader_parameter("cloud_density"),
			"pink_intensity": room_material.get_shader_parameter("pink_intensity"),
			"base_pink": room_material.get_shader_parameter("base_pink"),
			"deep_pink": room_material.get_shader_parameter("deep_pink")
		}
	
	if wall_material:
		original_wall_params = {
			"time_scale": wall_material.get_shader_parameter("time_scale"),
			"cloud_density": wall_material.get_shader_parameter("cloud_density"),
			"pink_intensity": wall_material.get_shader_parameter("pink_intensity"),
			"base_pink": wall_material.get_shader_parameter("base_pink"),
			"deep_pink": wall_material.get_shader_parameter("deep_pink")
		}

func _setup_ui() -> void:
	"""Create UI controls for animation parameters"""
	# This could be expanded to create runtime UI controls
	# For now, we'll use the exported variables in the editor
	pass

func _process(delta: float) -> void:
	"""Main animation loop"""
	if not animation_enabled:
		return
	
	base_time += delta * animation_speed
	color_cycle_time += delta * color_cycle_speed
	density_cycle_time += delta * 0.4
	
	_update_room_animation()
	_update_wall_animation()

func _update_room_animation() -> void:
	"""Update the main room sphere animation"""
	if not room_material:
		return
	
	# Update time parameter
	room_material.set_shader_parameter("time", base_time)
	
	# Animate time scale with variation
	var time_scale = original_room_params.get("time_scale", 0.2)
	time_scale += sin(base_time * 0.3) * time_scale_variation * 0.1
	room_material.set_shader_parameter("time_scale", time_scale)
	
	# Animate cloud density
	if cloud_density_animation:
		var density = original_room_params.get("cloud_density", 1.0)
		density += sin(density_cycle_time) * density_variation
		room_material.set_shader_parameter("cloud_density", density)
	
	# Animate colors
	if color_cycling:
		_animate_room_colors()

func _update_wall_animation() -> void:
	"""Update the wall animation with different timing"""
	if not wall_material:
		return
	
	# Update time parameter with different speed
	var wall_time = base_time * 0.7
	wall_material.set_shader_parameter("time", wall_time)
	
	# Animate time scale with different variation
	var time_scale = original_wall_params.get("time_scale", 0.427)
	time_scale += cos(base_time * 0.2) * time_scale_variation * 0.15
	wall_material.set_shader_parameter("time_scale", time_scale)
	
	# Animate cloud density with different pattern
	if cloud_density_animation:
		var density = original_wall_params.get("cloud_density", 1.499)
		density += cos(density_cycle_time * 1.3) * density_variation * 0.3
		wall_material.set_shader_parameter("cloud_density", density)
	
	# Animate colors with different cycle
	if color_cycling:
		_animate_wall_colors()

func _animate_room_colors() -> void:
	"""Animate room colors with cycling effects"""
	if not room_material:
		return
	
	var base_pink = original_room_params.get("base_pink", Color(1, 0.6, 0.8, 1))
	var deep_pink = original_room_params.get("deep_pink", Color(0.8, 0.2, 0.6, 1))
	
	# Create color cycling
	var cycle_r = sin(color_cycle_time) * 0.2
	var cycle_g = cos(color_cycle_time * 0.8) * 0.15
	var cycle_b = sin(color_cycle_time * 1.2) * 0.1
	
	var animated_base = Color(
		clamp(base_pink.r + cycle_r, 0.0, 1.0),
		clamp(base_pink.g + cycle_g, 0.0, 1.0),
		clamp(base_pink.b + cycle_b, 0.0, 1.0),
		base_pink.a
	)
	
	var animated_deep = Color(
		clamp(deep_pink.r + cycle_r * 0.5, 0.0, 1.0),
		clamp(deep_pink.g + cycle_g * 0.7, 0.0, 1.0),
		clamp(deep_pink.b + cycle_b * 0.3, 0.0, 1.0),
		deep_pink.a
	)
	
	room_material.set_shader_parameter("base_pink", animated_base)
	room_material.set_shader_parameter("deep_pink", animated_deep)
	
	# Animate pink intensity
	var intensity = original_room_params.get("pink_intensity", 0.8)
	intensity += sin(color_cycle_time * 0.5) * 0.2
	room_material.set_shader_parameter("pink_intensity", clamp(intensity, 0.0, 2.0))

func _animate_wall_colors() -> void:
	"""Animate wall colors with different cycling effects"""
	if not wall_material:
		return
	
	var base_pink = original_wall_params.get("base_pink", Color(1, 0.6, 0.8, 1))
	var deep_pink = original_wall_params.get("deep_pink", Color(1, 1, 1, 1))
	
	# Create different color cycling for walls
	var cycle_r = cos(color_cycle_time * 0.6) * 0.15
	var cycle_g = sin(color_cycle_time * 1.1) * 0.2
	var cycle_b = cos(color_cycle_time * 0.9) * 0.25
	
	var animated_base = Color(
		clamp(base_pink.r + cycle_r, 0.0, 1.0),
		clamp(base_pink.g + cycle_g, 0.0, 1.0),
		clamp(base_pink.b + cycle_b, 0.0, 1.0),
		base_pink.a
	)
	
	var animated_deep = Color(
		clamp(deep_pink.r + cycle_r * 0.3, 0.0, 1.0),
		clamp(deep_pink.g + cycle_g * 0.4, 0.0, 1.0),
		clamp(deep_pink.b + cycle_b * 0.2, 0.0, 1.0),
		deep_pink.a
	)
	
	wall_material.set_shader_parameter("base_pink", animated_base)
	wall_material.set_shader_parameter("deep_pink", animated_deep)
	
	# Animate pink intensity with different pattern
	var intensity = original_wall_params.get("pink_intensity", 0.8)
	intensity += cos(color_cycle_time * 0.7) * 0.15
	wall_material.set_shader_parameter("pink_intensity", clamp(intensity, 0.0, 2.0))

func _input(event: InputEvent) -> void:
	"""Handle input for animation controls"""
	if event.is_action_pressed("ui_accept"):  # Space key
		animation_enabled = !animation_enabled
		print("Noise Room Animation: ", "Enabled" if animation_enabled else "Disabled")
	
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		_reset_to_original_parameters()
		print("Noise Room: Reset to original parameters")

func _reset_to_original_parameters() -> void:
	"""Reset shaders to their original parameters"""
	if room_material and not original_room_params.is_empty():
		for param in original_room_params:
			room_material.set_shader_parameter(param, original_room_params[param])
	
	if wall_material and not original_wall_params.is_empty():
		for param in original_wall_params:
			wall_material.set_shader_parameter(param, original_wall_params[param])
	
	base_time = 0.0
	color_cycle_time = 0.0
	density_cycle_time = 0.0

func set_animation_speed(speed: float) -> void:
	"""Set the animation speed"""
	animation_speed = clamp(speed, 0.0, 5.0)

func set_color_cycling(enabled: bool) -> void:
	"""Enable or disable color cycling"""
	color_cycling = enabled

func set_cloud_density_animation(enabled: bool) -> void:
	"""Enable or disable cloud density animation"""
	cloud_density_animation = enabled

func get_animation_info() -> Dictionary:
	"""Get current animation state information"""
	return {
		"animation_enabled": animation_enabled,
		"animation_speed": animation_speed,
		"base_time": base_time,
		"color_cycling": color_cycling,
		"cloud_density_animation": cloud_density_animation,
		"room_material_active": room_material != null,
		"wall_material_active": wall_material != null
	}

## Gated on the key, on the word being one this file knows, and on it differing from the word
## already held — so a map that says nothing about the generator (which is all five existing
## placements) gets no call at all. Nothing is torn down here in any case: the basis is a
## single int uniform, so switching it repaints the field without rebuilding the room.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("generator"):
		return
	var g: String = str(config["generator"]).strip_edges().to_lower()
	if not GENERATORS.has(g) or g == generator:
		return
	generator = g
	_apply_generator()
