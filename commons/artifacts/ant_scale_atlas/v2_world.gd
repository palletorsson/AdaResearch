extends Node
## Run the original physics scene once, in its own world at its original size.
## All three museum displays read this state. They have no insect collisions.
const Colony = preload("res://algorithms/swarmintelligence/ants_v2/AntColonyV2.tscn")
var viewport: SubViewport
var colony: Node3D
var ants: Array[SimpleAnt] = []
var ticks := 0
var running := false

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.name = "OriginalColonyWorld"
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	# Count after the original root and its ants finish a physics tick.
	process_physics_priority = 1
	restart()

func restart() -> void:
	if is_instance_valid(colony):
		viewport.remove_child(colony)
		colony.queue_free()
	ants.clear()
	ticks = 0
	colony = Colony.instantiate()
	colony.process_mode = Node.PROCESS_MODE_DISABLED
	# Duplicate only the shader material so its texture binding cannot leak
	# into another V2 instance. No simulation parameter or source is altered.
	var surface: MeshInstance3D = colony.get_node("ResultMesh")
	var finish: Material = surface.get_active_material(0).duplicate()
	surface.set_surface_override_material(0, finish)
	viewport.add_child(colony)
	for child in colony.get_children():
		if child is SimpleAnt: ants.append(child)
	set_running(running)

func set_running(value: bool) -> void:
	running = value
	if is_instance_valid(colony):
		colony.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED

func _physics_process(_delta: float) -> void:
	if running: ticks += 1

func digest() -> String:
	var records: Array = []
	for ant in ants:
		records.append([ant.position, ant.rotation, ant.current_state, ant.pheromone_energy, ant.rng.state])
	return var_to_str([ticks, colony.grid.grid_home, colony.grid.grid_food, records]).sha256_text()
