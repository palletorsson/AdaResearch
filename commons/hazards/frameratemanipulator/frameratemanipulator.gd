# FramerateManipulatorEntity.gd
# Evil entity that gradually changes the game's framerate to mess with player experience
extends Node3D
class_name FramerateManipulatorEntity

# Framerate manipulation settings
@export var target_fps_min: int = 10
@export var target_fps_max: int = 120
@export var fps_change_interval: float = 5.0
@export var fps_change_amount: int = 5
@export var enable_fps_spikes: bool = true
@export var spike_intensity: float = 0.3  # How often spikes occur

# Frame dropping settings
@export var enable_frame_dropping: bool = true
@export var frame_drop_chance: float = 0.1  # 10% chance per frame
@export var frame_drop_duration: float = 0.5

# Lag simulation
@export var enable_artificial_lag: bool = true
@export var lag_duration_ms: float = 100.0
@export var lag_interval: float = 10.0

# Visual distortion effects
@export var enable_visual_glitches: bool = true
@export var screen_freeze_duration: float = 2.0
@export var screen_freeze_interval: float = 15.0

# Entity appearance
@export var entity_color: Color = Color(0.5, 0.0, 0.5, 1.0)  # Dark purple
@export var warning_color: Color = Color(1.0, 0.0, 0.0, 1.0)  # Red warning

# Internal state
var current_target_fps: int = 60
var original_fps_limit: int
var fps_change_timer: float = 0.0
var lag_timer: float = 0.0
var freeze_timer: float = 0.0
var frame_drop_timer: float = 0.0

# Frame timing manipulation
var artificial_frame_delay: float = 0.0
var is_dropping_frames: bool = false
var is_lagging: bool = false
var is_screen_frozen: bool = false

# Entity components
var entity_mesh: MeshInstance3D
var warning_light: OmniLight3D
var manipulation_particles: GPUParticles3D
var audio_player: AudioStreamPlayer3D

# Performance monitoring
var frame_times: Array = []
var average_frame_time: float = 0.0
var fps_history: Array = []

# Chaos modes
enum ChaosMode {
	SUBTLE_DEGRADATION,
	RANDOM_SPIKES,
	PROGRESSIVE_SLOWDOWN,
	CHAOTIC_SWINGS,
	MALICIOUS_FREEZE
}

var current_chaos_mode: ChaosMode = ChaosMode.SUBTLE_DEGRADATION
var chaos_intensity: float = 1.0

signal fps_changed(new_fps: int)
signal lag_spike_started(duration: float)
signal screen_freeze_started(duration: float)
signal performance_degraded(severity: String)
signal entity_detected()

func _ready():
	# Store original FPS settings
	original_fps_limit = Engine.max_fps
	
	# Create entity appearance
	_create_entity_mesh()
	
	# Setup visual effects
	_create_visual_effects()
	
	# Setup audio
	_setup_audio()
	
	# Initialize monitoring
	_initialize_performance_monitoring()
	
	# Start chaos
	_start_manipulation()
	
	print("FramerateManipulatorEntity: Performance chaos entity initialized")
	print("Original FPS limit: ", original_fps_limit)

func _create_entity_mesh():
	entity_mesh = MeshInstance3D.new()
	
	# Create menacing geometric shape
	var prism_mesh = PrismMesh.new()
	prism_mesh.left_to_right = 0.5
	prism_mesh.size = Vector3(1.0, 1.5, 1.0)
	entity_mesh.mesh = prism_mesh
	
	# Create ominous material
	var entity_material = StandardMaterial3D.new()
	entity_material.albedo_color = entity_color
	entity_material.emission_enabled = true
	entity_material.emission = entity_color * 0.5
	entity_material.emission_energy = 2.0
	entity_material.metallic = 0.9
	entity_material.roughness = 0.2
	entity_mesh.material_override = entity_material
	
	add_child(entity_mesh)
	
	# Add warning indicators
	_create_warning_indicators()

func _create_warning_indicators():
	# Create pulsing warning light
	warning_light = OmniLight3D.new()
	warning_light.light_color = warning_color
	warning_light.light_energy = 0.0  # Start dim
	warning_light.omni_range = 10.0
	warning_light.position.y = 2.0
	add_child(warning_light)

func _create_visual_effects():
	# Create particle system that represents "performance drain"
	manipulation_particles = GPUParticles3D.new()
	manipulation_particles.emitting = true
	manipulation_particles.amount = 150
	manipulation_particles.lifetime = 3.0
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)  # Downward like draining performance
	particle_material.spread = 30.0
	particle_material.initial_velocity_min = 2.0
	particle_material.initial_velocity_max = 6.0
	particle_material.gravity = Vector3(0, -2.0, 0)
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.4
	
	# Performance drain colors (red to black)
	var drain_gradient = Gradient.new()
	drain_gradient.add_point(0.0, Color.RED)
	drain_gradient.add_point(0.5, Color(0.5, 0.0, 0.0, 0.8))
	drain_gradient.add_point(1.0, Color(0, 0, 0, 0))
	
	var drain_texture = GradientTexture1D.new()
	drain_texture.gradient = drain_gradient
	particle_material.color_ramp = drain_texture
	
	manipulation_particles.process_material = particle_material
	manipulation_particles.draw_pass_1 = QuadMesh.new()
	add_child(manipulation_particles)

func _setup_audio():
	audio_player = AudioStreamPlayer3D.new()
	add_child(audio_player)

func _initialize_performance_monitoring():
	frame_times.resize(60)  # Track last 60 frames
	fps_history.resize(10)  # Track last 10 FPS readings
	frame_times.fill(0.0)
	fps_history.fill(60)

func _start_manipulation():
	current_target_fps = original_fps_limit
	_change_chaos_mode()
	print("FramerateManipulatorEntity: Started performance manipulation")
	emit_signal("entity_detected")

func _process(delta):
	# Update timers
	fps_change_timer += delta
	lag_timer += delta
	freeze_timer += delta
	frame_drop_timer += delta
	
	# Monitor performance
	_update_performance_monitoring(delta)
	
	# Apply current chaos mode
	_apply_chaos_mode(delta)
	
	# Update visual effects
	_update_visual_effects(delta)
	
	# Apply frame manipulations
	_apply_frame_manipulations(delta)

func _update_performance_monitoring(delta):
	# Track frame times
	frame_times.push_back(delta)
	if frame_times.size() > 60:
		frame_times.pop_front()
	
	# Calculate average frame time
	var total_time = 0.0
	for time in frame_times:
		total_time += time
	average_frame_time = total_time / frame_times.size()
	
	# Track FPS
	var current_fps = 1.0 / delta if delta > 0 else 60
	fps_history.push_back(current_fps)
	if fps_history.size() > 10:
		fps_history.pop_front()

func _apply_chaos_mode(delta):
	match current_chaos_mode:
		ChaosMode.SUBTLE_DEGRADATION:
			_apply_subtle_degradation(delta)
		ChaosMode.RANDOM_SPIKES:
			_apply_random_spikes(delta)
		ChaosMode.PROGRESSIVE_SLOWDOWN:
			_apply_progressive_slowdown(delta)
		ChaosMode.CHAOTIC_SWINGS:
			_apply_chaotic_swings(delta)
		ChaosMode.MALICIOUS_FREEZE:
			_apply_malicious_freeze(delta)

func _apply_subtle_degradation(delta):
	# Gradually reduce FPS over time
	if fps_change_timer >= fps_change_interval:
		if current_target_fps > target_fps_min:
			current_target_fps = max(target_fps_min, current_target_fps - fps_change_amount)
			_set_target_fps(current_target_fps)
		fps_change_timer = 0.0

func _apply_random_spikes(delta):
	# Random FPS spikes and drops
	if fps_change_timer >= fps_change_interval * randf_range(0.5, 2.0):
		var spike_direction = 1 if randf() > 0.5 else -1
		var spike_amount = int(fps_change_amount * randf_range(1.0, 3.0) * chaos_intensity)
		
		current_target_fps = clamp(current_target_fps + (spike_direction * spike_amount), 
									target_fps_min, target_fps_max)
		_set_target_fps(current_target_fps)
		fps_change_timer = 0.0

func _apply_progressive_slowdown(delta):
	# Continuously slow down the game
	if fps_change_timer >= fps_change_interval * 0.5:  # More frequent changes
		if current_target_fps > target_fps_min:
			var slowdown_amount = max(1, int(fps_change_amount * chaos_intensity))
			current_target_fps = max(target_fps_min, current_target_fps - slowdown_amount)
			_set_target_fps(current_target_fps)
		fps_change_timer = 0.0

func _apply_chaotic_swings(delta):
	# Wild FPS swings
	if fps_change_timer >= fps_change_interval * randf_range(0.2, 1.0):
		current_target_fps = randi_range(target_fps_min, target_fps_max)
		_set_target_fps(current_target_fps)
		fps_change_timer = 0.0

func _apply_malicious_freeze(delta):
	# Periodic screen freezes
	if freeze_timer >= screen_freeze_interval and not is_screen_frozen:
		_trigger_screen_freeze()
		freeze_timer = 0.0

func _set_target_fps(fps: int):
	Engine.max_fps = fps
	print("FramerateManipulatorEntity: Changed FPS to ", fps)
	emit_signal("fps_changed", fps)
	
	# Update visual intensity based on how bad the FPS is
	var performance_severity = _calculate_performance_severity(fps)
	emit_signal("performance_degraded", performance_severity)

func _calculate_performance_severity(fps: int) -> String:
	if fps >= 50:
		return "mild"
	elif fps >= 30:
		return "moderate"
	elif fps >= 20:
		return "severe"
	else:
		return "critical"

func _apply_frame_manipulations(delta):
	# Apply artificial lag
	if enable_artificial_lag and lag_timer >= lag_interval:
		_trigger_artificial_lag()
		lag_timer = 0.0
	
	# Apply frame dropping
	if enable_frame_dropping and not is_dropping_frames:
		if randf() < frame_drop_chance * chaos_intensity:
			_trigger_frame_dropping()

func _trigger_artificial_lag():
	if is_lagging:
		return
	
	is_lagging = true
	var lag_duration = lag_duration_ms / 1000.0  # Convert to seconds
	
	print("FramerateManipulatorEntity: Triggering artificial lag for ", lag_duration, " seconds")
	emit_signal("lag_spike_started", lag_duration)
	
	# Create lag by busy waiting (evil but effective)
	var start_time = Time.get_time_dict_from_system()
	var target_time = start_time.second * 1000 + start_time.minute * 60000 + lag_duration_ms
	
	# Use a timer instead of busy waiting to be less evil
	var lag_timer_node = Timer.new()
	lag_timer_node.wait_time = lag_duration
	lag_timer_node.one_shot = true
	lag_timer_node.timeout.connect(_end_artificial_lag)
	add_child(lag_timer_node)
	lag_timer_node.start()

func _end_artificial_lag():
	is_lagging = false
	print("FramerateManipulatorEntity: Artificial lag ended")

func _trigger_frame_dropping():
	if is_dropping_frames:
		return
	
	is_dropping_frames = true
	print("FramerateManipulatorEntity: Starting frame dropping")
	
	var drop_timer = Timer.new()
	drop_timer.wait_time = frame_drop_duration
	drop_timer.one_shot = true
	drop_timer.timeout.connect(_end_frame_dropping)
	add_child(drop_timer)
	drop_timer.start()

func _end_frame_dropping():
	is_dropping_frames = false
	print("FramerateManipulatorEntity: Frame dropping ended")

func _trigger_screen_freeze():
	if is_screen_frozen:
		return
	
	is_screen_frozen = true
	print("FramerateManipulatorEntity: Triggering screen freeze for ", screen_freeze_duration, " seconds")
	emit_signal("screen_freeze_started", screen_freeze_duration)
	
	# Temporarily set FPS to 1 for freeze effect
	var original_fps = Engine.max_fps
	Engine.max_fps = 1
	
	var freeze_timer_node = Timer.new()
	freeze_timer_node.wait_time = screen_freeze_duration
	freeze_timer_node.one_shot = true
	freeze_timer_node.timeout.connect(func(): _end_screen_freeze(original_fps))
	add_child(freeze_timer_node)
	freeze_timer_node.start()

func _end_screen_freeze(restore_fps: int):
	is_screen_frozen = false
	Engine.max_fps = restore_fps
	print("FramerateManipulatorEntity: Screen freeze ended")

func _update_visual_effects(delta):
	if not entity_mesh or not warning_light:
		return
	
	# Rotate entity based on chaos intensity
	entity_mesh.rotation.y += delta * chaos_intensity * 2.0
	entity_mesh.rotation.x += delta * chaos_intensity * 0.5
	
	# Pulse warning light based on performance severity
	var fps_ratio = float(current_target_fps) / float(original_fps_limit)
	var warning_intensity = 1.0 - fps_ratio  # Higher intensity when FPS is lower
	warning_light.light_energy = warning_intensity * 3.0
	
	# Pulse particle intensity
	if manipulation_particles:
		var emission_rate = 50 + (warning_intensity * 100)
		manipulation_particles.amount = int(emission_rate)

func _change_chaos_mode():
	# Randomly select a new chaos mode
	var mode_count = ChaosMode.size()
	current_chaos_mode = ChaosMode.values()[randi() % mode_count]
	print("FramerateManipulatorEntity: Changed to chaos mode: ", ChaosMode.keys()[current_chaos_mode])

# Public API
func set_chaos_intensity(intensity: float):
	chaos_intensity = clamp(intensity, 0.1, 5.0)
	print("FramerateManipulatorEntity: Chaos intensity set to ", chaos_intensity)

func set_target_fps_range(min_fps: int, max_fps: int):
	target_fps_min = max(1, min_fps)
	target_fps_max = max(min_fps + 10, max_fps)

func force_chaos_mode(mode: ChaosMode):
	current_chaos_mode = mode
	print("FramerateManipulatorEntity: Forced chaos mode to ", ChaosMode.keys()[mode])

func restore_original_performance():
	Engine.max_fps = original_fps_limit
	is_lagging = false
	is_dropping_frames = false
	is_screen_frozen = false
	print("FramerateManipulatorEntity: Performance restored to original settings")

func get_performance_stats() -> Dictionary:
	var avg_fps = 0.0
	for fps in fps_history:
		avg_fps += fps
	avg_fps /= fps_history.size()
	
	return {
		"current_fps_limit": Engine.max_fps,
		"original_fps_limit": original_fps_limit,
		"average_fps": avg_fps,
		"average_frame_time": average_frame_time,
		"chaos_mode": ChaosMode.keys()[current_chaos_mode],
		"chaos_intensity": chaos_intensity,
		"is_lagging": is_lagging,
		"is_dropping_frames": is_dropping_frames,
		"is_screen_frozen": is_screen_frozen
	}

func destroy_entity():
	restore_original_performance()
	queue_free()
	print("FramerateManipulatorEntity: Entity destroyed, performance restored")
