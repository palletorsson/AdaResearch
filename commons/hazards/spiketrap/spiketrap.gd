# SpikeTrapHazard.gd
# Deadly spikes that emerge from the ground when player falls or steps on them
extends Area3D
class_name SpikeTrapHazard

# Damage and trigger settings
@export var spike_damage: float = 30.0
@export var activation_delay: float = 0.5  # Time before spikes emerge
@export var spike_duration: float = 3.0    # How long spikes stay up
@export var retraction_time: float = 1.0   # Time to retract spikes
@export var cooldown_time: float = 2.0     # Time before can trigger again

# Trigger conditions
@export var trigger_on_fall: bool = true   # Trigger when player falls on them
@export var trigger_on_proximity: bool = false  # Trigger when player gets close
@export var proximity_distance: float = 2.0
@export var fall_velocity_threshold: float = 5.0  # Minimum fall speed to trigger

# Visual settings
@export var spike_count: int = 12
@export var spike_height: float = 2.0
@export var spike_base_radius: float = 0.1
@export var warning_color: Color = Color.YELLOW
@export var spike_color: Color = Color(0.3, 0.3, 0.3, 1.0)  # Dark gray
@export var blood_color: Color = Color.RED

# Audio
@export var warning_sound: AudioStream
@export var spike_emerge_sound: AudioStream
@export var spike_retract_sound: AudioStream
@export var damage_sound: AudioStream

# State management
enum TrapState {
	IDLE,
	WARNING,
	EMERGING,
	ACTIVE,
	RETRACTING,
	COOLDOWN
}

var current_state: TrapState = TrapState.IDLE
var state_timer: float = 0.0
var spikes: Array = []
var warning_indicator: MeshInstance3D
var audio_player: AudioStreamPlayer3D
var collision_shape: CollisionShape3D
var triggered_by_player: bool = false

# Tracking
var players_in_area: Array = []
var damage_dealt_this_cycle: bool = false

signal spike_trap_triggered(trap_position: Vector3)
signal spike_damage_dealt(target, damage: float)
signal trap_state_changed(new_state: TrapState)

func _ready():
	# Setup collision detection
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Setup collision shape for detection area
	collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3.0, 1.0, 3.0)  # Detection area
	collision_shape.shape = box_shape
	add_child(collision_shape)
	
	# Set collision layers
	collision_layer = 0  # Don't collide with anything
	collision_mask = 2   # Detect player layer
	
	# Create warning indicator
	_create_warning_indicator()
	
	# Create spikes (hidden initially)
	_create_spikes()
	
	# Setup audio
	_setup_audio()
	
	print("SpikeTrapHazard: Initialized with ", spike_count, " spikes")

func _create_warning_indicator():
	warning_indicator = MeshInstance3D.new()
	
	# Create warning mesh (flat circle)
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 1.5
	cylinder_mesh.bottom_radius = 1.5
	cylinder_mesh.height = 0.05
	warning_indicator.mesh = cylinder_mesh
	
	# Create warning material
	var warning_material = StandardMaterial3D.new()
	warning_material.albedo_color = warning_color
	warning_material.emission_enabled = true
	warning_material.emission = warning_color
	warning_material.emission_energy = 1.0
	warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	warning_material.albedo_color.a = 0.6
	warning_indicator.material_override = warning_material
	
	warning_indicator.visible = false
	add_child(warning_indicator)

func _create_spikes():
	spikes.clear()
	
	for i in range(spike_count):
		var spike = _create_single_spike(i)
		spikes.append(spike)
		add_child(spike)

func _create_single_spike(index: int) -> MeshInstance3D:
	var spike_node = MeshInstance3D.new()
	
	# Create spike mesh (cone)
	var cone_mesh = SphereMesh.new()
	cone_mesh.radius = spike_base_radius
	cone_mesh.height = spike_height
	
	# Create custom cone shape by scaling the sphere
	spike_node.mesh = cone_mesh
	spike_node.scale = Vector3(1, spike_height / spike_base_radius, 1)
	
	# Position spike in circle pattern
	var angle = (float(index) / float(spike_count)) * 2.0 * PI
	var radius = 0.8
	var x = cos(angle) * radius
	var z = sin(angle) * radius
	spike_node.position = Vector3(x, -spike_height * 0.5, z)  # Start underground
	
	# Create spike material
	var spike_material = StandardMaterial3D.new()
	spike_material.albedo_color = spike_color
	spike_material.metallic = 0.2
	spike_material.roughness = 0.6
	spike_node.material_override = spike_material
	
	spike_node.visible = true
	return spike_node

func _setup_audio():
	audio_player = AudioStreamPlayer3D.new()
	add_child(audio_player)

func _process(delta):
	state_timer += delta
	_update_state(delta)
	
	# Check proximity trigger
	if trigger_on_proximity and current_state == TrapState.IDLE:
		_check_proximity_trigger()

func _update_state(delta):
	match current_state:
		TrapState.IDLE:
			_update_idle_state()
		
		TrapState.WARNING:
			_update_warning_state(delta)
		
		TrapState.EMERGING:
			_update_emerging_state(delta)
		
		TrapState.ACTIVE:
			_update_active_state(delta)
		
		TrapState.RETRACTING:
			_update_retracting_state(delta)
		
		TrapState.COOLDOWN:
			_update_cooldown_state(delta)

func _update_idle_state():
	# Reset visual elements
	warning_indicator.visible = false
	for spike in spikes:
		spike.position.y = -spike_height * 0.5  # Underground

func _update_warning_state(delta):
	# Show pulsing warning
	warning_indicator.visible = true
	var pulse = 0.5 + 0.5 * sin(state_timer * 15.0)  # Fast pulse
	var material = warning_indicator.get_surface_override_material(0)
	if material:
		material.emission_energy = 1.0 + pulse * 2.0
	
	# Transition to emerging after delay
	if state_timer >= activation_delay:
		_change_state(TrapState.EMERGING)

func _update_emerging_state(delta):
	# Animate spikes emerging
	var emerge_progress = min(state_timer / 0.5, 1.0)  # 0.5 second emerge time
	var target_height = spike_height * 0.4  # Emerge above ground
	
	for spike in spikes:
		var start_y = -spike_height * 0.5
		spike.position.y = lerp(start_y, target_height, ease_out(emerge_progress))
	
	# Transition to active when fully emerged
	if emerge_progress >= 1.0:
		_change_state(TrapState.ACTIVE)
		damage_dealt_this_cycle = false

func _update_active_state(delta):
	# Spikes are fully extended and dangerous
	warning_indicator.visible = false
	
	# Check for damage
	if not damage_dealt_this_cycle:
		_check_spike_damage()
	
	# Transition to retracting after duration
	if state_timer >= spike_duration:
		_change_state(TrapState.RETRACTING)

func _update_retracting_state(delta):
	# Animate spikes retracting
	var retract_progress = min(state_timer / retraction_time, 1.0)
	var start_height = spike_height * 0.4
	var target_height = -spike_height * 0.5
	
	for spike in spikes:
		spike.position.y = lerp(start_height, target_height, ease_in(retract_progress))
	
	# Transition to cooldown when fully retracted
	if retract_progress >= 1.0:
		_change_state(TrapState.COOLDOWN)

func _update_cooldown_state(delta):
	# Wait before trap can be triggered again
	if state_timer >= cooldown_time:
		_change_state(TrapState.IDLE)

func _change_state(new_state: TrapState):
	var old_state = current_state
	current_state = new_state
	state_timer = 0.0
	triggered_by_player = false
	
	# Play appropriate sounds
	match new_state:
		TrapState.WARNING:
			_play_sound(warning_sound)
		TrapState.EMERGING:
			_play_sound(spike_emerge_sound)
		TrapState.RETRACTING:
			_play_sound(spike_retract_sound)
	
	emit_signal("trap_state_changed", new_state)
	print("SpikeTrap state changed: ", TrapState.keys()[old_state], " -> ", TrapState.keys()[new_state])

func _on_body_entered(body):
	if _is_player(body):
		players_in_area.append(body)
		print("Player entered spike trap area: ", body.name)
		
		# Check if should trigger on fall
		if trigger_on_fall and current_state == TrapState.IDLE:
			var player_velocity = Vector3.ZERO
			if body.has_method("get_velocity"):
				player_velocity = body.get_velocity()
			elif body.has_property("velocity"):
				player_velocity = body.velocity
			elif body.has_property("linear_velocity"):
				player_velocity = body.linear_velocity
			
			# Check if falling fast enough
			if player_velocity.y < -fall_velocity_threshold:
				_trigger_trap()

func _on_body_exited(body):
	if _is_player(body):
		players_in_area.erase(body)
		print("Player exited spike trap area: ", body.name)

func _check_proximity_trigger():
	for player in players_in_area:
		if is_instance_valid(player):
			var distance = global_position.distance_to(player.global_position)
			if distance <= proximity_distance:
				_trigger_trap()
				break

func _trigger_trap():
	if current_state == TrapState.IDLE:
		triggered_by_player = true
		_change_state(TrapState.WARNING)
		emit_signal("spike_trap_triggered", global_position)
		print("Spike trap triggered!")

func _check_spike_damage():
	for player in players_in_area:
		if is_instance_valid(player) and current_state == TrapState.ACTIVE:
			# Check if player is close enough to spikes
			var player_pos = player.global_position
			var trap_pos = global_position
			var distance = Vector2(player_pos.x - trap_pos.x, player_pos.z - trap_pos.z).length()
			
			if distance <= 1.5:  # Within spike damage range
				_damage_player(player)
				damage_dealt_this_cycle = true
				break

func _damage_player(player):
	var damage_dealt = spike_damage
	
	# Try different damage methods
	if player.has_method("take_damage"):
		player.take_damage(damage_dealt)
	elif player.has_method("apply_health_damage"):
		player.apply_health_damage(damage_dealt)
	elif player.has_method("damage_player"):
		player.damage_player(damage_dealt)
	elif player.has_signal("health_changed"):
		player.emit_signal("health_changed", -damage_dealt)
	
	# Create blood effect
	_create_blood_effect(player.global_position)
	
	# Play damage sound
	_play_sound(damage_sound)
	
	emit_signal("spike_damage_dealt", player, damage_dealt)
	print("Spike trap dealt ", damage_dealt, " damage to ", player.name)

func _create_blood_effect(position: Vector3):
	# Create blood particle effect
	var blood_particles = GPUParticles3D.new()
	blood_particles.global_position = position
	blood_particles.emitting = true
	blood_particles.amount = 50
	blood_particles.lifetime = 1.0
	blood_particles.one_shot = true
	
	# Configure blood material
	var blood_material = ParticleProcessMaterial.new()
	blood_material.direction = Vector3(0, 1, 0)
	blood_material.spread = 30.0
	blood_material.initial_velocity_min = 3.0
	blood_material.initial_velocity_max = 8.0
	blood_material.gravity = Vector3(0, -9.8, 0)
	blood_material.scale_min = 0.1
	blood_material.scale_max = 0.3
	
	# Blood color gradient
	var blood_gradient = Gradient.new()
	blood_gradient.add_point(0.0, blood_color)
	blood_gradient.add_point(1.0, Color(blood_color.r * 0.3, 0, 0, 0))
	
	var blood_texture = GradientTexture1D.new()
	blood_texture.gradient = blood_gradient
	blood_material.color_ramp = blood_texture
	
	blood_particles.process_material = blood_material
	blood_particles.draw_pass_1 = QuadMesh.new()
	
	add_child(blood_particles)
	
	# Clean up after effect
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 3.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(blood_particles.queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()

func _is_player(body) -> bool:
	return ("player" in body.name.to_lower() or 
			body.is_in_group("player") or
			body.has_method("take_damage"))

func _play_sound(sound: AudioStream):
	if sound and audio_player:
		audio_player.stream = sound
		audio_player.play()

func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

func ease_in(t: float) -> float:
	return t * t * t

# Public API
func set_damage(new_damage: float):
	spike_damage = new_damage

func set_trigger_mode(fall_trigger: bool, proximity_trigger: bool):
	trigger_on_fall = fall_trigger
	trigger_on_proximity = proximity_trigger

func force_trigger():
	_trigger_trap()

func get_current_state() -> TrapState:
	return current_state

func is_dangerous() -> bool:
	return current_state == TrapState.ACTIVE
