extends Node3D

# Ada Research: Queer Environment for VR World
# This script sets up an environment that challenges normative 3D spaces
# and explores the queer potential of algorithms

@onready var world_environment = $"../WorldEnvironment"


# Environment colors that shift gradually
var color_palette = [
	Color(0.9, 0.2, 0.8, 1.0),  # Magenta
	Color(0.2, 0.8, 0.9, 1.0),  # Cyan
	Color(0.8, 0.9, 0.2, 1.0),  # Lime
	Color(0.6, 0.2, 0.9, 1.0),  # Purple
	Color(0.9, 0.5, 0.2, 1.0),  # Orange
]

# Non-binary light direction and intensity values
var light_directions = [
	Vector3(1.0, -0.5, 0.7),
	Vector3(-0.8, 0.2, 0.5),
	Vector3(0.3, 0.8, -0.4)
]

var time_elapsed = 0.0
var morph_speed = 0.02
var entropy_factor = 0.0

func _ready():
	# Initialize the environment
	setup_world_environment()


func setup_world_environment():
	# Create a unique environment that defies traditional 3D space norms
	var environment = world_environment.environment
	
	# Set up background with shifting gradient
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = color_palette[0]
	
	# Fog that creates liminal spaces and blurs boundaries
	environment.fog_enabled = true
	environment.fog_density = 0.01
	environment.fog_sun_scatter = 0.5
	environment.fog_height = -10
	environment.fog_height_density = 0.05
	
	# Glow effect for emphasis on queer aesthetics
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	environment.glow_bloom = 0.3
	environment.glow_hdr_threshold = 0.7
	
	# Ambient light for mood
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.1, 0.1, 0.3)
	environment.ambient_light_energy = 1.2
	
	# SSR for reflective surfaces that morph and change
	environment.ssr_enabled = true
	environment.ssr_max_steps = 64
	environment.ssr_fade_in = 0.15
	environment.ssr_depth_tolerance = 0.2
	
	# SSAO for depth and dimensional feeling
	environment.ssao_enabled = true
	environment.ssao_radius = 2.0
	environment.ssao_intensity = 2.0
	environment.ssao_power = 1.5
	
	# Adjustments to make colors pop in a queer aesthetic
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.05
	environment.adjustment_contrast = 1.1
	environment.adjustment_saturation = 1.2
