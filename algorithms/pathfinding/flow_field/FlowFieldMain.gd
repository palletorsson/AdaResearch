extends Node3D

# @identity
# essence: v_i(t+1) = field[grid(pos_i)] — each agent reads one arrow and moves; the entire "decision" is a lookup
# desire: to stand inside an invisible force that bends your trajectory before you notice — to feel steered without a steerer
# critical_parameter: sequence_mode — switching between open field, U-wall, zig-zag, linear wind, and noise turbulence reveals how field topology determines reachability
# triggers: placing an obstacle changes the entire downstream vector field instantly via Dijkstra propagation from the target cell
# emerges: traffic-like lane formation where many agents converge on the same narrow corridor without coordination or negotiation
# needs: [missing] no VR controls — mouse-click target and right-click walls are desktop-only; VR needs controller-raycast placement of target and obstacles
# relationships: foundation for ant pheromone fields; contrasts with boid_flocking (field is external vs. social); shares grid_resolution with PhysarumColony approach
# truth: purpose is not inside the agent — it lives in the field the agent inhabits

@export var agent_scene: PackedScene

# --- DNA (stage 2, promoted 2026-07-29) -------------------------------------
# scenario: which field topology the piece holds. "tour" is the shipped
#   behaviour — all six scenarios on a 10-second carousel, ending parked in
#   noise. Pinning a single scenario stops the carousel and makes the artifact
#   argue one thing instead of surveying six: a wall that traps the gradient,
#   a wind with no destination at all, a noise field that steers without
#   steering anywhere.
# field_display: whether the arrows are drawn. With arrows the piece is a
#   diagram of a cause; with them hidden the agents look like they want
#   something. Same simulation, opposite claim about where purpose lives.
@export_enum("tour", "open", "block", "u_wall", "zigzag", "wind", "noise") var scenario: String = "tour"
@export_enum("arrows", "hidden") var field_display: String = "arrows"

# Scenario name -> the mode int set_scenario() already understood.
# "tour" is -1: not a mode, the carousel that visits all of them.
const SCENARIO_MODES = {
	"tour": -1,
	"open": 0,
	"block": 1,
	"u_wall": 2,
	"zigzag": 3,
	"wind": 4,
	"noise": 5,
}

@onready var visualizer: MeshInstance3D = $FieldVisualizer
@onready var camera: Camera3D = $Camera3D

var grid: FlowGrid
var agents = []
var _xr_active: bool = false

var sequence_timer: float = 0.0
var sequence_mode: int = 0
const DURATION = 10.0
var current_target = Vector2i(20, 20)

func _ready() -> void:
	_xr_active = XRServer.primary_interface != null

	# 1. Setup Grid
	grid = FlowGrid.new(40, 40, 1.0)

	# 2. Setup Visualizer
	visualizer.setup(grid)
	visualizer.visible = (field_display != "hidden")

	# 3. Spawn Agents
	spawn_agents(200)

	# 4. Start Sequence
	_apply_scenario()

# Enter the declared scenario. With the default ("tour") this is exactly the
# old set_scenario(0) plus a timer reset, so the carousel starts where it
# always did.
func _apply_scenario() -> void:
	sequence_timer = 0.0
	var mode: int = int(SCENARIO_MODES.get(scenario, -1))
	if mode < 0:
		mode = 0  # tour begins at Open Field
	sequence_mode = mode
	set_scenario(sequence_mode)

func _process(delta: float) -> void:
	# Animate Noise (if in final mode)
	if sequence_mode == 5:
		var time = Time.get_ticks_msec() / 1000.0
		grid.generate_noise_field(12345, time * 0.05) # Slow, smooth scroll
		visualizer.update_visuals()
		return # Stay in this mode forever (or until manual reset)

	# A pinned scenario holds; only the tour advances.
	if scenario != "tour":
		return

	# Standard Sequence Logic
	sequence_timer += delta
	if sequence_timer >= DURATION:
		sequence_timer = 0.0
		sequence_mode = (sequence_mode + 1) % 6
		set_scenario(sequence_mode)

func set_scenario(mode: int) -> void:
	grid.reset_costs()
	print("Changing Flow Field Scenario: ", mode)
	
	match mode:
		0: # Open Field (Target Center)
			current_target = Vector2i(20, 20)
			
		1: # Center Block (Target Corner)
			current_target = Vector2i(5, 5)
			# Square obstacle in middle
			grid.fill_rect(15, 15, 10, 10, 255)
			
		2: # U-Wall (Target Inside)
			current_target = Vector2i(20, 25)
			# Draw U shape opening UP (towards +Z)
			grid.fill_rect(10, 10, 2, 20, 255)   # Left
			grid.fill_rect(28, 10, 2, 20, 255)   # Right
			grid.fill_rect(10, 10, 20, 2, 255)   # Top (Cost is 255)
			
		3: # Zig-Zag Maze
			current_target = Vector2i(35, 35)
			# Wall 1
			grid.fill_rect(0, 10, 30, 2, 255)
			# Wall 2
			grid.fill_rect(10, 25, 30, 2, 255)
			
		4: # Linear Wind
			grid.generate_linear_field(Vector2(1, 0.5))
			visualizer.update_visuals()
			return

		5: # Noise Turbulence
			grid.generate_noise_field(randi())
			visualizer.update_visuals()
			return
			
	update_field(current_target.x, current_target.y)

func spawn_agents(count: int) -> void:
	for i in range(count):
		var agent = agent_scene.instantiate()
		add_child(agent)
		
		# Random pos
		var pos = Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
		agent.initialize(grid, pos)
		agents.append(agent)

func update_field(target_x: int, target_y: int) -> void:
	# Recalculate Logic
	grid.calculate_flow_field(target_x, target_y)
	
	# Update Arrows
	visualizer.update_visuals()

func _unhandled_input(event: InputEvent) -> void:
	# VR: interaction handled by XR controller raycasts
	if _xr_active:
		return
	if event is InputEventMouseButton and event.pressed:
		var result = raycast_from_mouse(event.position)
		if result:
			var pos = result.position
			var coord = grid.world_to_grid(pos)
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Set Target
				print("New Target: ", coord)
				update_field(coord.x, coord.y)
				
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# Toggle Wall
				print("Toggle Wall: ", coord)
				grid.set_cost(coord.x, coord.y, 255)
				# Update current target (we need to store it to refresh)
				# Simplified: just refresh assuming last target is 0 cost
				# Actually re-running 0,0 might be wrong.
				# Proper way: Store target. For demo, just click target again.
				pass

func raycast_from_mouse(mouse_pos):
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	# query.collision_mask = ... (Ground layer)
	return space.intersect_ray(query)

func apply_grid_config(config: Dictionary) -> void:
	# Guarded: only touch anything a token actually names, and only re-enter
	# a scenario when the value really changed AND _ready has already built
	# the grid once. A map that passes no scenario/field_display token keeps
	# the exact behaviour it shipped with.
	var rebuild_scenario: bool = false

	if config.has("scenario"):
		var want: String = str(config["scenario"]).strip_edges().to_lower()
		if SCENARIO_MODES.has(want) and want != scenario:
			scenario = want
			rebuild_scenario = true

	if config.has("field_display"):
		var display: String = str(config["field_display"]).strip_edges().to_lower()
		if (display == "arrows" or display == "hidden") and display != field_display:
			field_display = display
			if visualizer != null:
				visualizer.visible = (field_display != "hidden")

	if rebuild_scenario and grid != null:
		_apply_scenario()
