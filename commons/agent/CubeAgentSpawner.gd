# CubeAgentSpawner.gd
# Spawns cube agents in grid-based maps
# Can be added as an interactable or utility in map JSON

extends Node3D
class_name CubeAgentSpawner

# Configuration
@export var agent_data_path: String = "res://commons/agent/agent_data.json"
@export var cube_size: float = 0.2
@export var spawn_on_ready: bool = true
@export var auto_walk: bool = true
@export var walk_direction: Vector3 = Vector3.FORWARD

# References
var agent_builder: CubeAgentBuilder = null
var walk_controller: CubeAgentWalkController = null

func _ready() -> void:
	print("CubeAgentSpawner: Ready")

	if spawn_on_ready:
		call_deferred("spawn_agent")

func spawn_agent() -> CubeAgentBuilder:
	print("CubeAgentSpawner: Spawning agent...")

	# Create agent builder
	agent_builder = CubeAgentBuilder.new()
	agent_builder.name = "CubeAgent"
	agent_builder.agent_data_path = agent_data_path
	agent_builder.cube_size = cube_size
	add_child(agent_builder)

	# Create walk controller
	walk_controller = CubeAgentWalkController.new()
	walk_controller.name = "WalkController"
	agent_builder.add_child(walk_controller)

	# Wait for agent to be built
	await agent_builder.agent_built

	# Configure walking
	if auto_walk:
		walk_controller.set_walk_direction(walk_direction)
		walk_controller.start_walking(walk_direction)

	print("CubeAgentSpawner: Agent spawned successfully!")
	return agent_builder

func despawn_agent() -> void:
	if agent_builder:
		agent_builder.queue_free()
		agent_builder = null
		walk_controller = null
		print("CubeAgentSpawner: Agent despawned")

# Public API for grid system integration

func set_spawn_position(pos: Vector3) -> void:
	global_position = pos

func get_agent() -> CubeAgentBuilder:
	return agent_builder

func get_walk_controller() -> CubeAgentWalkController:
	return walk_controller

# Called when spawned via grid interactables layer
# Supports config like: "agent_spawner#direction:1,0,0"
func apply_grid_config(config: Dictionary) -> void:
	print("CubeAgentSpawner: Applying grid config: %s" % config)

	# Parse direction from config
	if config.has("direction"):
		var dir_str = str(config["direction"])
		var parts = dir_str.split(",")
		if parts.size() == 3:
			walk_direction = Vector3(
				float(parts[0]),
				float(parts[1]),
				float(parts[2])
			).normalized()
			print("  Set walk direction to: %s" % walk_direction)

	# Parse cube size
	if config.has("size"):
		cube_size = float(config["size"])
		print("  Set cube size to: %f" % cube_size)

	# Spawn if not already spawned
	if not agent_builder:
		spawn_agent()
