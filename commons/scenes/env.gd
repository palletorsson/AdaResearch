# VibrantVREnvironment.gd - Creates stunning queer-celebratory VR environments
# Handles WorldEnvironment setup, dynamic lighting, particles, and VR optimization
extends Node3D

# === ENVIRONMENT CONFIGURATION ===
@export_group("Environment Settings")
@export var auto_setup_on_ready: bool = true
@export var target_platform: String = "desktop_vr"  # "desktop_vr" or "mobile_vr"
@export var enable_advanced_effects: bool = true
@export var performance_target_fps: int = 90

# === VISUAL THEME SETTINGS ===
@export_group("Visual Theme")
@export var primary_theme: String = "pride_rainbow"  # "pride_rainbow", "trans_pride", "progress_flag"
@export var ambient_intensity: float = 0.4
@export var magical_atmosphere: bool = true
@export var particle_density: float = 1.0

# === LIGHTING CONFIGURATION ===
@export_group("Dynamic Lighting")
@export var enable_animated_lighting: bool = true
@export var sun_color_cycle: bool = true
@export var magical_orb_lights: bool = true
@export var max_dynamic_lights: int = 6

# === PERFORMANCE SETTINGS ===
@export_group("VR Performance")
@export var enable_foveated_rendering: bool = true
@export var use_msaa: bool = true
@export var particle_lod_enabled: bool = true
@export var auto_quality_adjustment: bool = true

# === INTERNAL VARIABLES ===
var world_environment: WorldEnvironment
var main_environment: Environment
var sun_light: DirectionalLight3D
var magical_lights: Array[OmniLight3D] = []
var particle_systems: Array[GPUParticles3D] = []
var performance_monitor: Node

# Color palettes for different themes
var color_themes = {
	"pride_rainbow": [
		Color(0.9, 0.1, 0.1),  # Red - Life
		Color(1.0, 0.5, 0.0),  # Orange - Healing  
		Color(1.0, 1.0, 0.0),  # Yellow - Sunlight
		Color(0.0, 0.8, 0.0),  # Green - Nature
		Color(0.0, 0.4, 1.0),  # Blue - Serenity
		Color(0.6, 0.0, 0.8)   # Purple - Spirit
	],
	"trans_pride": [
		Color(0.3, 0.8, 1.0),  # Light Blue
		Color(1.0, 0.7, 0.8),  # Pink
		Color(1.0, 1.0, 1.0),  # White
		Color(1.0, 0.7, 0.8),  # Pink
		Color(0.3, 0.8, 1.0)   # Light Blue
	],
	"progress_flag": [
		Color(0.9, 0.1, 0.1),  # Red
		Color(1.0, 0.5, 0.0),  # Orange
		Color(1.0, 1.0, 0.0),  # Yellow
		Color(0.0, 0.8, 0.0),  # Green
		Color(0.0, 0.4, 1.0),  # Blue
		Color(0.6, 0.0, 0.8),  # Purple
		Color(0.4, 0.2, 0.0),  # Brown
		Color(0.0, 0.0, 0.0),  # Black
		Color(0.3, 0.8, 1.0),  # Trans Blue
		Color(1.0, 0.7, 0.8),  # Trans Pink
		Color(1.0, 1.0, 0.0)   # Intersex Yellow
	]
}

func _ready():
	if auto_setup_on_ready:
		setup_vr_environment()
		setup_performance_monitoring()
		print("VR Environment initialized - Theme: " + primary_theme)

func setup_vr_environment():
	"""Main setup function that configures the entire VR environment"""
	configure_rendering_backend()
	create_world_environment()
	setup_dynamic_lighting()
	create_magical_particle_systems()
	setup_vr_optimizations()
	apply_visual_theme()

func configure_rendering_backend():
	"""Configure Godot 4 rendering settings for VR"""
	var viewport = get_viewport()
	
	if target_platform == "mobile_vr":
		# Mobile VR optimizations (Quest, PICO)
		RenderingServer.camera_set_use_vertical_aspect(viewport.get_camera_3d().get_camera_rid(), true)
		
		# Enable MSAA for tile-based GPUs
		if use_msaa:
			viewport.msaa_3d = Viewport.MSAA_2X
			
		# Disable expensive effects
		enable_advanced_effects = false
		
	else:
		# Desktop VR optimizations (PCVR)
		if use_msaa:
			viewport.msaa_3d = Viewport.MSAA_4X
		
		# Enable foveated rendering if supported
		if enable_foveated_rendering and Engine.has_singleton("OpenXRInterface"):
			var xr_interface = Engine.get_singleton("OpenXRInterface")
			if xr_interface.has_method("set_foveation_level"):
				xr_interface.set_foveation_level(3)  # High foveation
	
	# Common VR settings
	#viewport.hdr_2d = true
	# viewport.use_debanding = true
	
	print("Rendering backend configured for: " + target_platform)

func create_world_environment():
	"""Create and configure the WorldEnvironment with VR-optimized settings"""
	world_environment = WorldEnvironment.new()
	world_environment.name = "VRWorldEnvironment"
	add_child(world_environment)
	
	main_environment = Environment.new()
	world_environment.environment = main_environment
	
	# Configure sky
	setup_rainbow_sky()
	
	# Configure ambient lighting
	main_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	main_environment.ambient_light_energy = ambient_intensity
	
	# Configure bloom for magical atmosphere
	if enable_advanced_effects:
		main_environment.glow_enabled = true
		main_environment.glow_intensity = 0.3
		main_environment.glow_strength = 1.2
		main_environment.glow_bloom = 0.1
		main_environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		
		# Add slight color grading for warmth
		main_environment.adjustment_enabled = true
		main_environment.adjustment_brightness = 1.1
		main_environment.adjustment_contrast = 1.05
		main_environment.adjustment_saturation = 1.15
	
	# Configure fog for depth (Forward+ only)
	if target_platform == "desktop_vr" and enable_advanced_effects:
		main_environment.fog_enabled = true
		main_environment.fog_light_color = Color(0.8, 0.9, 1.0)
		main_environment.fog_light_energy = 0.5
		main_environment.fog_sun_scatter = 0.3
		main_environment.fog_density = 0.01

func setup_rainbow_sky():
	"""Create a custom rainbow sky shader"""
	var sky_material = ShaderMaterial.new()
	var sky_shader = create_rainbow_sky_shader()
	sky_material.shader = sky_shader
	
	# Set rainbow parameters based on theme
	var theme_colors = color_themes[primary_theme]
	if theme_colors.size() >= 2:
		sky_material.set_shader_parameter("sky_top_color", theme_colors[0])
		sky_material.set_shader_parameter("sky_horizon_color", theme_colors[-1])
	
	sky_material.set_shader_parameter("rainbow_intensity", 1.2)
	sky_material.set_shader_parameter("sky_energy", 1.0)
	
	var sky = Sky.new()
	sky.sky_material = sky_material
	
	main_environment.sky = sky
	main_environment.background_mode = Environment.BG_SKY

func create_rainbow_sky_shader() -> Shader:
	"""Create custom rainbow sky shader"""
	var shader = Shader.new()
	shader.code = """
shader_type sky;

uniform sampler2D sky_tex : source_color;

uniform float energy : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float gamma : hint_range(0.0,4.0) = 1.0;
uniform sampler2D tint_ramp : source_color, repeat_disable, hint_default_white;
uniform vec3 scale = vec3(1);
uniform float triplanar_blend_power : hint_range(0.0,40.0) = 4.0;
uniform float seamless_blend : hint_range(0.0,0.5) = 0.1;

vec4 textureSeamless(sampler2D tex, vec2 uv, vec2 padding){
	vec2 inv_scale = 1.0 / (1.0 + 2.0 * padding);

	// Get partial derivatives here for textureGrad() to avoid mipmapping seams
	vec2 dx = dFdx(uv) * inv_scale;
	vec2 dy = dFdy(uv) * inv_scale;

	// Textures need to repeat somewhere. In addition, repeat must be enabled on the sampler
	uv = fract(uv+0.5)-0.5;

	// Get the bilinear blend factors. This is actually undefined for padding = 0
	vec2 u = smoothstep(-padding, padding, uv);

	// Apply scale
	uv *= inv_scale;

	// Bilinear interpolation
	inv_scale = 0.5 * (1.0 - inv_scale);
	vec4 lower_right = textureGrad(tex, uv - vec2(-1,-1) * inv_scale,  dx, dy);
	vec4 lower_left = textureGrad(tex, uv - vec2(1,-1) * inv_scale,  dx, dy);
	vec4 upper_right = textureGrad(tex, uv - vec2(-1,1) * inv_scale, dx, dy);
	vec4 upper_left = textureGrad(tex, uv - vec2(1,1) * inv_scale, dx, dy);

	lower_right = mix(lower_left, lower_right, u.x);
	upper_right = mix(upper_left, upper_right, u.x);

	return mix(upper_right, lower_right, u.y);
}

// "p" point being textured
// "n" surface normal at "p"
// "k" controls the sharpness of the blending in the transitions areas
// "s" texture sampler
vec4 boxmap( in sampler2D s, in vec3 p, in vec3 n, in float k )
{
	// project+fetch
	vec4 x = textureSeamless( s, p.yz, vec2(seamless_blend) );
	vec4 y = textureSeamless( s, p.zx, vec2(seamless_blend) );
	vec4 z = textureSeamless( s, p.xy, vec2(seamless_blend) );

	// blend weights
	vec3 w = pow( abs(n), vec3(k) );

	// blend and return
	return (x*w.x + y*w.y + z*w.z) / (w.x + w.y + w.z);
}

void sky() {
	// Ray direction
	vec3 rd = EYEDIR;
	
	// Apply scaling
	vec3 p = rd;
	p = normalize(rd / scale) * scale;
	vec3 n = normalize(p / scale);
	
	// Triplanar mapping of sky texture
	COLOR = boxmap(sky_tex, p, n, triplanar_blend_power).rgb;
	COLOR = energy * pow(COLOR, vec3(gamma));
	COLOR *= textureLod(tint_ramp, SKY_COORDS.yx, 0.0).rgb;
	
	// Alpha of tint ramp determines transparency of sky texture
	COLOR = mix(textureLod(tint_ramp, SKY_COORDS.yx, 0.0).rgb, COLOR, textureLod(tint_ramp, SKY_COORDS.yx, 0.0).a);
}
"""
	return shader

func setup_dynamic_lighting():
	"""Create animated magical lighting system"""
	# Main directional light (sun/moon)
	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunMoonLight"
	sun_light.light_energy = 1.2
	sun_light.light_color = Color(1.0, 0.95, 0.8)
	sun_light.rotation_degrees = Vector3(-45, 30, 0)
	
	# Disable shadows on mobile VR for performance
	if target_platform == "mobile_vr":
		sun_light.shadow_enabled = false
	else:
		sun_light.shadow_enabled = true
		sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	
	add_child(sun_light)
	
	# Create magical orb lights
	if magical_orb_lights:
		create_magical_orb_lights()
	
	# Start lighting animation
	if enable_animated_lighting:
		start_lighting_animation()

func create_magical_orb_lights():
	"""Create floating magical light orbs with rainbow colors"""
	var theme_colors = color_themes[primary_theme]
	var light_count = min(max_dynamic_lights, theme_colors.size())
	
	for i in range(light_count):
		var orb_light = OmniLight3D.new()
		orb_light.name = "MagicalOrb_" + str(i)
		orb_light.light_energy = 2.0
		orb_light.light_color = theme_colors[i]
		orb_light.omni_range = 10.0
		orb_light.omni_attenuation = 0.5
		
		# Disable shadows for performance
		orb_light.shadow_enabled = false
		
		# Position in a circle around origin
		var angle = (float(i) / float(light_count)) * TAU
		var radius = 8.0
		var height = randf_range(2.0, 6.0)
		orb_light.position = Vector3(
			cos(angle) * radius,
			height,
			sin(angle) * radius
		)
		
		add_child(orb_light)
		magical_lights.append(orb_light)

func start_lighting_animation():
	"""Start animated lighting effects"""
	var tween = create_tween()
	tween.set_loops()
	
	# Animate sun color cycling
	if sun_color_cycle:
		animate_sun_colors()
	
	# Animate magical orb movement
	for i in range(magical_lights.size()):
		animate_orb_light(magical_lights[i], i)

func animate_sun_colors():
	"""Animate sun light through rainbow colors"""
	var color_tween = create_tween()
	color_tween.set_loops()
	
	var theme_colors = color_themes[primary_theme]
	var duration = 60.0  # Full cycle in 60 seconds
	
	for i in range(theme_colors.size()):
		var target_color = theme_colors[i]
		var time_point = (float(i) / float(theme_colors.size())) * duration
		color_tween.tween_method(set_sun_color, sun_light.light_color, target_color, duration / theme_colors.size())

func set_sun_color(color: Color):
	"""Set sun light color with smooth transition"""
	if sun_light:
		sun_light.light_color = color

func animate_orb_light(light: OmniLight3D, index: int):
	"""Animate individual magical orb light"""
	var move_tween = create_tween()
	move_tween.set_loops()
	
	var original_pos = light.position
	var float_height = 1.5
	var duration = 4.0 + (index * 0.5)  # Stagger timing
	
	# Floating motion
	move_tween.tween_method(
		func(pos): light.position = pos,
		original_pos,
		original_pos + Vector3(0, float_height, 0),
		duration
	)
	move_tween.tween_method(
		func(pos): light.position = pos,
		original_pos + Vector3(0, float_height, 0),
		original_pos,
		duration
	)
	
	# Energy pulsing
	var energy_tween = create_tween()
	energy_tween.set_loops()
	energy_tween.tween_property(light, "light_energy", 3.0, 2.0)
	energy_tween.tween_property(light, "light_energy", 1.5, 2.0)

func create_magical_particle_systems():
	"""Create VR-optimized particle systems for magical atmosphere"""
	if not magical_atmosphere:
		return
	
	# Ambient sparkles
	create_sparkle_system()
	
	# Rainbow energy fields
	if enable_advanced_effects:
		create_energy_field_system()
	
	# Interactive particles (respond to VR controllers)
	create_interactive_particles()

func create_sparkle_system():
	"""Create ambient sparkle particle system"""
	var sparkles = GPUParticles3D.new()
	sparkles.name = "AmbientSparkles"
	sparkles.emitting = true
	
	# VR-optimized particle count
	var particle_count = 200 if target_platform == "mobile_vr" else 500
	var final_count = int(particle_count * particle_density)
	sparkles.amount = max(1, final_count)  # Ensure at least 1 particle
	
	var material = ParticleProcessMaterial.new()
	
	# Emission settings
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(20, 10, 20)
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 2.0
	
	# Appearance
	material.scale_min = 0.1
	material.scale_max = 0.3
	
	# Create color gradient from theme
	var gradient = Gradient.new()
	var theme_colors = color_themes[primary_theme]
	for i in range(theme_colors.size()):
		var offset = float(i) / float(theme_colors.size() - 1)
		gradient.add_point(offset, theme_colors[i])
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Physics
	material.gravity = Vector3(0, -0.5, 0)
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	
	sparkles.process_material = material
	sparkles.lifetime = 8.0
	
	add_child(sparkles)
	particle_systems.append(sparkles)

func create_energy_field_system():
	"""Create flowing energy field particles"""
	var energy_field = GPUParticles3D.new()
	energy_field.name = "EnergyField"
	energy_field.emitting = true
	
	var particle_count = 100 if target_platform == "mobile_vr" else 300
	var final_count = int(particle_count * particle_density)
	energy_field.amount = max(1, final_count)  # Ensure at least 1 particle
	
	var material = ParticleProcessMaterial.new()
	
	# Flowing motion
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_radius = 5.0
	material.emission_ring_inner_radius = 3.0
	material.direction = Vector3(0, 0, 1)
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 3.0
	
	# Turbulence for organic flow
	material.turbulence_enabled = true
	material.turbulence_noise_strength = 0.5
	material.turbulence_noise_scale = 2.0
	
	# Glowing appearance
	material.scale_min = 0.2
	material.scale_max = 0.8
	
	energy_field.process_material = material
	energy_field.lifetime = 12.0
	
	add_child(energy_field)
	particle_systems.append(energy_field)

func create_interactive_particles():
	"""Create particles that respond to VR controller input"""
	var interactive_particles = GPUParticles3D.new()
	interactive_particles.name = "InteractiveParticles"
	interactive_particles.emitting = false  # Activated by controller proximity
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 1.0
	
	# Burst emission for responsive feel
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3(0, -1.0, 0)
	
	interactive_particles.process_material = material
	interactive_particles.amount = 50
	interactive_particles.lifetime = 3.0
	
	add_child(interactive_particles)
	particle_systems.append(interactive_particles)
	
	# Connect to XR controller signals if available
	setup_vr_controller_interaction(interactive_particles)

func setup_vr_controller_interaction(particles: GPUParticles3D):
	"""Setup VR controller interaction with particles"""
	# Find XR controllers in scene
	var xr_controllers = find_children("*", "XRController3D", true, false)
	
	for controller in xr_controllers:
		if controller is XRController3D:
			# Create interaction area
			var area = Area3D.new()
			var collision = CollisionShape3D.new()
			var sphere = SphereShape3D.new()
			sphere.radius = 0.3
			collision.shape = sphere
			area.add_child(collision)
			controller.add_child(area)
			
			# Connect signals
			area.body_entered.connect(_on_controller_interaction.bind(particles, true))
			area.body_exited.connect(_on_controller_interaction.bind(particles, false))

func _on_controller_interaction(particles: GPUParticles3D, entered: bool):
	"""Handle VR controller interaction with particles"""
	if entered:
		particles.emitting = true
		particles.restart()
	else:
		particles.emitting = false

func setup_vr_optimizations():
	"""Apply VR-specific performance optimizations"""
	# Configure LOD for particles
	if particle_lod_enabled:
		setup_particle_lod()
	
	# Setup automatic quality adjustment
	if auto_quality_adjustment:
		setup_performance_monitoring()
	
	# Additional VR optimizations
	var viewport = get_viewport()
	if viewport:
		# Check if Forward+ renderer is available for FSR
		# Note: FSR is available in Godot 4.4+ with Forward+ renderer
		# We'll try to enable FSR and fallback to bilinear if not supported
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		viewport.scaling_3d_scale = 0.8 if target_platform == "mobile_vr" else 1.0
		
		# Verify FSR is working by checking if the mode was actually set
		if viewport.scaling_3d_mode != Viewport.SCALING_3D_MODE_FSR:
			# Fallback to basic scaling if FSR is not supported
			viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			viewport.scaling_3d_scale = 0.8 if target_platform == "mobile_vr" else 1.0
			print("FSR not available - using bilinear scaling")
	
	print("VR optimizations applied for target FPS: " + str(performance_target_fps))

func setup_particle_lod():
	"""Setup distance-based LOD for particle systems"""
	for particles in particle_systems:
		# Add visibility range based on target platform
		var max_range = 50.0 if target_platform == "desktop_vr" else 30.0
		particles.visibility_range_begin = max_range * 0.7
		particles.visibility_range_end = max_range

func setup_performance_monitoring():
	"""Setup automatic performance monitoring and adjustment"""
	performance_monitor = Node.new()
	performance_monitor.name = "PerformanceMonitor"
	add_child(performance_monitor)
	
	# Create timer for performance checks
	var perf_timer = Timer.new()
	perf_timer.wait_time = 1.0  # Check every second
	perf_timer.timeout.connect(_on_performance_check)
	perf_timer.autostart = true
	performance_monitor.add_child(perf_timer)

func _on_performance_check():
	"""Monitor performance and adjust quality if needed"""
	var fps = Engine.get_frames_per_second()
	
	if fps < performance_target_fps * 0.9:  # 10% tolerance
		# Reduce quality
		adjust_quality_down()
	elif fps > performance_target_fps * 1.1 and particle_density < 1.0:
		# Increase quality if we have headroom
		adjust_quality_up()

func adjust_quality_down():
	"""Reduce visual quality to maintain frame rate"""
	if particle_density > 0.3:
		particle_density = max(0.3, particle_density - 0.1)
		update_particle_counts()
		print("Quality reduced to maintain performance - Particle density: " + str(particle_density))

func adjust_quality_up():
	"""Increase visual quality when performance allows"""
	if particle_density < 1.0:
		particle_density = min(1.0, particle_density + 0.1)
		update_particle_counts()
		print("Quality increased - Particle density: " + str(particle_density))

func update_particle_counts():
	"""Update particle system counts based on current density"""
	for particles in particle_systems:
		var base_amount = particles.get_meta("base_amount", particles.amount)
		particles.set_meta("base_amount", base_amount)
		var final_count = int(base_amount * particle_density)
		particles.amount = max(1, final_count)  # Ensure at least 1 particle

func apply_visual_theme():
	"""Apply the selected visual theme to all elements"""
	print("Applying visual theme: " + primary_theme)
	
	# Update magical light colors
	var theme_colors = color_themes[primary_theme]
	for i in range(magical_lights.size()):
		if i < theme_colors.size():
			magical_lights[i].light_color = theme_colors[i]
	
	# Update environment colors
	var primary_color = theme_colors[0] if theme_colors.size() > 0 else Color.WHITE
	var secondary_color = theme_colors[-1] if theme_colors.size() > 1 else Color.WHITE
	
	main_environment.ambient_light_color = primary_color.lerp(Color.WHITE, 0.7)

# === PUBLIC API FUNCTIONS ===

func set_theme(theme_name: String):
	"""Change the visual theme at runtime"""
	if theme_name in color_themes:
		primary_theme = theme_name
		apply_visual_theme()
		print("Theme changed to: " + theme_name)
	else:
		print("Unknown theme: " + theme_name)

func set_magical_intensity(intensity: float):
	"""Adjust the intensity of magical effects"""
	particle_density = clamp(intensity, 0.0, 2.0)
	update_particle_counts()
	
	for light in magical_lights:
		light.light_energy = 2.0 * intensity

func toggle_performance_mode():
	"""Toggle between high quality and performance modes"""
	if target_platform == "mobile_vr":
		target_platform = "desktop_vr"
		enable_advanced_effects = true
	else:
		target_platform = "mobile_vr"
		enable_advanced_effects = false
	
	setup_vr_environment()
	print("Switched to: " + target_platform)

func get_environment_info() -> Dictionary:
	"""Get current environment configuration info"""
	return {
		"theme": primary_theme,
		"platform": target_platform,
		"fps": Engine.get_frames_per_second(),
		"particle_density": particle_density,
		"magical_lights": magical_lights.size(),
		"particle_systems": particle_systems.size(),
		"advanced_effects": enable_advanced_effects
	}

func _input(event):
	"""Handle debug input for testing"""
	if not OS.is_debug_build():
		return
		
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				set_theme("pride_rainbow")
			KEY_F2:
				set_theme("trans_pride")
			KEY_F3:
				set_theme("progress_flag")
			KEY_F4:
				toggle_performance_mode()
			KEY_EQUAL:
				set_magical_intensity(particle_density + 0.2)
			KEY_MINUS:
				set_magical_intensity(particle_density - 0.2)
			KEY_I:
				print(get_environment_info())
