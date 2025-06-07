# CubeShaderController.gd
# Chapter 2: Material and Shader Magic
# Animates shader parameters for visual effects

extends Node3D

@export var color_cycle_speed: float = 1.0
@export var grid_pulse_speed: float = 2.0
@export var emission_intensity: float = 2.0

var mesh_instance: MeshInstance3D
var shader_material: ShaderMaterial
var time_elapsed: float = 0.0

func _ready():
	# Find the mesh instance in our cube
	mesh_instance = find_child("CubeBaseMesh", true, false)
	
	if mesh_instance and mesh_instance.material_override:
		shader_material = mesh_instance.material_override as ShaderMaterial
		print("CubeShaderController: Found shader material")
	else:
		print("CubeShaderController: No shader material found")

func _process(delta):
	if not shader_material:
		return
	
	time_elapsed += delta
	
	# Animate emission color with cycling hue
	var hue = fmod(time_elapsed * color_cycle_speed, 1.0)
	var emission_color = Color.from_hsv(hue, 0.8, 1.0)
	shader_material.set_shader_parameter("emissionColor", emission_color)
	
	# Pulse grid width for breathing effect
	var grid_width = 8.0 + sin(time_elapsed * grid_pulse_speed) * 2.0
	shader_material.set_shader_parameter("width", grid_width)
	
	# Pulse emission strength
	var current_emission = emission_intensity + sin(time_elapsed * grid_pulse_speed * 1.5) * 0.5
	shader_material.set_shader_parameter("emission_strength", current_emission)

# Public methods for external control
func set_emission_color(color: Color):
	if shader_material:
		shader_material.set_shader_parameter("emissionColor", color)

func set_grid_visibility(visible: bool):
	if shader_material:
		var opacity = 1.0 if visible else 0.0
		shader_material.set_shader_parameter("modelOpacity", opacity)
