# DiseaseSpreadCA.gd
# Epidemic spread model (SIR)
#
# @identity
# essence: S → I with P(infection) * infected_neighbors; I → R with P(recovery) — the SIR model on a 3D grid
# desire: To spread — watch infection ripple outward from patient zero, then the green wave of recovery follow
# critical_parameter: INFECTION_RATE vs RECOVERY_RATE — their ratio determines whether the epidemic burns out or persists
# triggers: High infection rate → explosive spread; high recovery → quick burnout; few initial infected → slow simmer
# emerges: Epidemic wavefronts, herd immunity boundaries, and spatial clustering from two probabilities
# needs: VR rate sliders [missing], reset button [missing], SIR count display [has via get_disease_counts]
# relationships: Feeds into CA_EdgeOfChaos. Extends PulsingCA (pulsing spheres for visual drama).
# truth: Two probabilities and a grid of neighbors — this is how pandemics actually work.

extends PulsingCA

const INFECTION_RATE = 0.2
const RECOVERY_RATE = 0.1
const INITIAL_INFECTED = 5

# Optional museum scheduling: retain the full 64³ state and synchronous rule,
# but compute four x/y rows per frame before publishing the next generation.
var museum_budget:bool=false
var budget_next:Array=[]
var budget_row:int=0
var budget_commits:int=0

func _ready() -> void:
	if not museum_budget:
		super._ready();return
	setup_common_materials();initialize_grid()
	sphere_mesh=SphereMesh.new();sphere_mesh.radius=CUBE_SIZE*VISUALIZATION_STEP*0.4;sphere_mesh.height=sphere_mesh.radius*2
	sphere_mesh.radial_segments=8;sphere_mesh.rings=4
	configure_multimesh(sphere_mesh,16*16*16)
	var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;multi_mesh_instance.material_override=mat
	budget_next=duplicate_3d_grid(grid);update_visualization();is_running=true
	var note:=Label3D.new();note.text="LOCAL TRANSMISSION / S - I - R\n64 cubed / one update over 1024 display frames\n4-cell display stride / simplified local model";note.font_size=36;note.pixel_size=0.025;note.billboard=BaseMaterial3D.BILLBOARD_ENABLED;note.position.y=14;add_child(note)

func _process(delta:float) -> void:
	if not museum_budget:
		super._process(delta);return
	if not is_running:return
	for _row in range(4):
		var x:int=budget_row/GRID_SIZE;var y:int=budget_row%GRID_SIZE
		for z in range(GRID_SIZE):
			var state:int=grid[x][y][z];var value:int=state
			if state==0 and count_infected_neighbors(Vector3i(x,y,z))>0:
				if randf()<INFECTION_RATE:value=1
			elif state==1:
				if randf()<RECOVERY_RATE:value=2
			budget_next[x][y][z]=value
		budget_row+=1
		if budget_row==GRID_SIZE*GRID_SIZE:
			grid=budget_next;budget_next=duplicate_3d_grid(grid);budget_row=0;budget_commits+=1;iteration_count+=1;update_visualization()


func initialize_grid() -> void:
	# Configure PulsingCA settings
	pulse_speed = 3.0
	pulse_amount = 0.2
	base_scale = 1.2
	
	# Base class sets up the sphere mesh
	super.initialize_grid()
	
	grid = create_3d_grid()
	
	# Initialize with mostly susceptible population
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				grid[x][y][z] = 0  # Susceptible
	
	# Add initial infected individuals
	for i in range(INITIAL_INFECTED):
		var x = randi() % GRID_SIZE
		var y = randi() % GRID_SIZE
		var z = randi() % GRID_SIZE
		grid[x][y][z] = 1  # Infected

func update_simulation(_delta) -> void:
	spread_disease()
	update_visualization()

func spread_disease() -> void:
	var new_grid = duplicate_3d_grid(grid)
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var cell = grid[x][y][z]
				match cell:
					0:  # Susceptible
						var infected_neighbors = count_infected_neighbors(Vector3i(x, y, z))
						if infected_neighbors > 0 and randf() < INFECTION_RATE:
							new_grid[x][y][z] = 1  # Become infected
					
					1:  # Infected
						if randf() < RECOVERY_RATE:
							new_grid[x][y][z] = 2  # Recover
					
					2:  # Recovered
						pass  # Immune
	
	grid = new_grid

func count_infected_neighbors(pos: Vector3i) -> int:
	var count = 0
	var neighbors = get_3d_neighbors(pos)
	for neighbor in neighbors:
		if is_valid_3d_position(neighbor) and grid[neighbor.x][neighbor.y][neighbor.z] == 1:
			count += 1
	return count

func update_visualization() -> void:
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return
		
	var mm = multi_mesh_instance.multimesh
	var idx = 0
	var step = 4
	var time = Time.get_ticks_msec() / 1000.0
	
	# Reset remaining instances
	mm.visible_instance_count = 0
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				var state = grid[x][y][z]
				if state == 1 or state == 2:  # Infected or Recovered
					var pos = _grid_to_world(Vector3i(x, y, z))
					
					# Pulse effect
					var pulse = 1.0 + sin(time * pulse_speed + x * 0.1 + y * 0.1) * pulse_amount
					var scale = Vector3.ONE * pulse * base_scale
					
					var t = Transform3D(Basis().scaled(scale), pos)
					mm.set_instance_transform(idx, t)
					
					# Color logic
					if state == 1:
						mm.set_instance_color(idx, Color.RED) # Infected
					else:
						mm.set_instance_color(idx, Color.GREEN) # Recovered
						
					idx += 1
	
	mm.visible_instance_count = idx

func get_disease_counts() -> Dictionary:
	var susceptible = 0
	var infected = 0
	var recovered = 0
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				match grid[x][y][z]:
					0: susceptible += 1
					1: infected += 1
					2: recovered += 1
	
	return {"susceptible": susceptible, "infected": infected, "recovered": recovered}

func reset_simulation() -> void:
	grid = create_3d_grid()
	initialize_grid()
	iteration_count = 0

func apply_grid_config(config: Dictionary) -> void:
	if config.has("museum_budget"):museum_budget=str(config.museum_budget).to_lower() in ["true","1"]
