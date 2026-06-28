# algo_gun.gd
# Evolved Gravity Gun - Captures and directs Grid Agents
# Extends gravity_gun.gd to add Grid Agent capture/direction capabilities
# ===========================================================================
# @identity
# essence: A gravity gun that has learned to herd — it captures living grid agents, orbits them at the wrist, and dispatches them to tasks
# desire: To turn raw attraction into command — not just pulling inert objects, but conscripting autonomous agents into orbit and direction
# critical_parameter: agent_detection_radius — the reach within which an autonomous agent stops being free and becomes capturable
# triggers: Grip near an agent to capture it; captured agents orbit the wrist; aim and release to direct one toward a target position
# emerges: Force becomes governance — the same attraction that pulls a box now redirects a population, turning a physics tool into a shepherd
# needs: parent gravity-gun pull [has], grid-agent detection area [has], orbit-angle bookkeeping [has], directed-task dispatch [has]
# relationships: subclass of gravity_gun; commands GridAgent instances; the bridge between the forces sequence and autonomous-agent behavior
# truth: To capture a thing that moves on its own is a different power than to pull a thing that cannot — direction is attraction with a will attached.
# ===========================================================================
extends "res://algorithms/forces/gravity_gun.gd"

@export_group("Grid Agent Settings")
@export var can_capture_grid_agents: bool = true
@export var agent_detection_radius: float = 3.0
@export var agent_orbit_radius: float = 0.3
@export var agent_orbit_speed: float = 2.0
@export var grid_agent_task_duration: float = 30.0

# Grid Agent management
var captured_grid_agents: Array[GridAgent] = []
var agent_orbit_angles: Dictionary = {}  # GridAgent -> float (angle)
var original_agent_states: Dictionary = {}  # GridAgent -> state info
var last_grip_state: bool = false  # Track grip button state

# Agent detection area (separate from physics attraction)
var agent_detection_area: Area3D

# Optional visual/muzzle nodes. These are null-safe fallbacks so this script
# remains compatible if the parent gravity gun implementation changes.
var gun_mesh: MeshInstance3D = null
var force_field_mesh: MeshInstance3D = null
var muzzle_point: Node3D = null

# Signals for Grid Agents
signal agent_captured(agent: GridAgent)
signal agent_directed(agent: GridAgent, target: Vector3)
signal agent_released(agent: GridAgent)

func _ready() -> void:
	super._ready()
	gun_mesh = get_node_or_null("GunMesh") as MeshInstance3D
	force_field_mesh = get_node_or_null("ForceFieldMesh") as MeshInstance3D
	muzzle_point = get_node_or_null("MuzzlePoint") as Node3D
	setup_agent_detection()
	
	# Update visual color for algo-gun
	if gun_mesh and gun_mesh.material_override:
		var mat = gun_mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color(0.6, 0.9, 1.0)  # Brighter cyan
		mat.emission = Color(0.4, 0.8, 1.0) * 0.5
	
	if force_field_mesh and force_field_mesh.material_override:
		var mat = force_field_mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color(0.4, 0.9, 1.0, 0.3)  # More opaque cyan

func setup_agent_detection() -> void:
	"""Setup Area3D for detecting Grid Agents"""
	if not can_capture_grid_agents:
		return
	
	agent_detection_area = Area3D.new()
	agent_detection_area.name = "AgentDetectionArea"
	agent_detection_area.monitoring = true
	agent_detection_area.monitorable = false
	
	# Detect agents (they're CharacterBody3D, not RigidBody3D)
	agent_detection_area.collision_layer = 0
	agent_detection_area.collision_mask = 1  # Default layer
	
	add_child(agent_detection_area)
	
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = agent_detection_radius
	collision_shape.shape = sphere_shape
	agent_detection_area.add_child(collision_shape)
	
	# Connect signals
	agent_detection_area.body_entered.connect(_on_agent_entered_range)
	agent_detection_area.body_exited.connect(_on_agent_exited_range)

func _on_agent_entered_range(body: Node3D) -> void:
	"""Called when a body enters agent detection range"""
	if body is GridAgent and body not in captured_grid_agents:
		if debug:
			print("[AlgoGun] Grid Agent detected: ", body.name)

func _on_agent_exited_range(body: Node3D) -> void:
	"""Called when a body exits agent detection range"""
	if body is GridAgent:
		if debug:
			print("[AlgoGun] Grid Agent left range: ", body.name)

func _physics_process(delta: float) -> void:
	"""Extend parent with agent management"""
	super._physics_process(delta)
	
	# Update captured agents (orbit them around muzzle)
	_update_captured_agents(delta)
	
	# Check for agent capture (grip button)
	if can_capture_grid_agents:
		_check_agent_capture_input()

func _check_agent_capture_input() -> void:
	"""Check for grip button press to capture/release agents"""
	if not controller or not controller.get_is_active():
		return
	
	# Use grip button for agent capture
	var grip_pressed = controller.is_button_pressed("grip")
	
	# Detect rising edge (button just pressed)
	if grip_pressed and not last_grip_state:
		if debug:
			print("[AlgoGun] Grip pressed - attempting agent operation")
		
		# If we have captured agents, aim and release one
		if not captured_grid_agents.is_empty():
			_direct_agent_to_target()
		else:
			# Try to capture nearest agent
			_attempt_agent_capture()
	
	last_grip_state = grip_pressed

func _attempt_agent_capture() -> void:
	"""Try to capture the nearest Grid Agent in range"""
	if not agent_detection_area:
		return
	
	var overlapping = agent_detection_area.get_overlapping_bodies()
	var nearest_agent: GridAgent = null
	var nearest_distance = INF
	
	# Find nearest Grid Agent
	for body in overlapping:
		if body is GridAgent and body not in captured_grid_agents:
			var distance = global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_agent = body
	
	if nearest_agent:
		_capture_agent(nearest_agent)

func _capture_agent(agent: GridAgent) -> void:
	"""Capture a Grid Agent"""
	if agent in captured_grid_agents:
		return
	
	captured_grid_agents.append(agent)
	
	# Store original state
	original_agent_states[agent] = {
		"scale": agent.scale,
		"position": agent.global_position
	}
	
	# Initialize orbit angle
	agent_orbit_angles[agent] = randf() * TAU
	
	# Tell agent it's captured
	agent.capture()
	
	# Scale down agent
	agent.scale = agent.scale * captured_scale
	
	agent_captured.emit(agent)
	
	if debug:
		print("[AlgoGun] Captured Grid Agent: ", agent.name, " (tier: ", EvolutionTiers.get_tier_string(agent.current_tier), ")")

func _update_captured_agents(delta: float) -> void:
	"""Update positions of captured agents (orbit around muzzle)"""
	if captured_grid_agents.is_empty():
		return
	
	var target_pos = muzzle_point.global_position if muzzle_point else global_position
	var count = captured_grid_agents.size()
	
	for i in range(count):
		var agent = captured_grid_agents[i]
		if not is_instance_valid(agent):
			continue
		
		# Update orbit angle
		agent_orbit_angles[agent] += agent_orbit_speed * delta
		if agent_orbit_angles[agent] > TAU:
			agent_orbit_angles[agent] -= TAU
		
		# Calculate orbit position
		var angle = agent_orbit_angles[agent]
		var offset = Vector3(
			cos(angle) * agent_orbit_radius,
			sin(angle * 2.0) * agent_orbit_radius * 0.5,  # Figure-8 pattern
			sin(angle) * agent_orbit_radius
		)
		
		# Apply gun's rotation to offset
		offset = global_transform.basis * offset
		
		# Position agent
		agent.global_position = target_pos + offset
		
		# Face the agent toward the gun
		agent.look_at(target_pos, Vector3.UP)

func _direct_agent_to_target() -> void:
	"""Direct the captured agent to a target location on the grid"""
	if captured_grid_agents.is_empty():
		return
	
	# Get the first captured agent
	var agent = captured_grid_agents[0]
	
	# Raycast from gun to find target position
	var ray_origin = global_position
	var ray_direction = -global_transform.basis.z  # Forward from gun
	var ray_length = 10.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	query.collision_mask = 1  # Grid structures
	query.exclude = [agent]  # Don't hit the agent itself
	
	var result = space_state.intersect_ray(query)
	
	var target_position: Vector3
	if result:
		target_position = result.position
		if debug:
			print("[AlgoGun] Directing agent to grid at: ", target_position)
	else:
		# No hit, use point in front of gun
		target_position = ray_origin + ray_direction * 5.0
		if debug:
			print("[AlgoGun] No grid hit, directing agent to space: ", target_position)
	
	# Release and direct the agent
	_release_agent(agent, target_position)

func _release_agent(agent: GridAgent, target: Vector3) -> void:
	"""Release an agent and direct it to a target"""
	if agent not in captured_grid_agents:
		return
	
	captured_grid_agents.erase(agent)
	agent_orbit_angles.erase(agent)
	
	# Restore scale
	if agent in original_agent_states:
		agent.scale = original_agent_states[agent].scale
		original_agent_states.erase(agent)
	
	# Tell agent to go to target
	agent.direct_to_position(target)
	
	agent_directed.emit(agent, target)
	agent_released.emit(agent)
	
	if debug:
		print("[AlgoGun] Released agent ", agent.name, " to target: ", target)

func release_all_agents() -> void:
	"""Release all captured agents (for cleanup)"""
	var agents_to_release = captured_grid_agents.duplicate()
	for agent in agents_to_release:
		if is_instance_valid(agent):
			var pos = agent.global_position + Vector3(0, 1, 0)  # Release above current position
			_release_agent(agent, pos)

func get_captured_agent_count() -> int:
	"""Get number of currently captured Grid Agents"""
	return captured_grid_agents.size()

func get_highest_captured_tier() -> EvolutionTiers.Tier:
	"""Get the highest tier of any captured agent"""
	if captured_grid_agents.is_empty():
		return EvolutionTiers.Tier.TIER_1_COPY
	
	var max_tier = EvolutionTiers.Tier.TIER_1_COPY
	for agent in captured_grid_agents:
		if agent.current_tier > max_tier:
			max_tier = agent.current_tier
	
	return max_tier

func _exit_tree() -> void:
	"""Clean up when gun is removed"""
	release_all_agents()


func apply_grid_config(config: Dictionary) -> void:
	pass
