extends "res://algorithms/cellularautomata/ca_showcase/disease_spread_ca.gd"
## Same 64³ synchronous SIR rule and probabilities, evaluated on its exact
## infectious frontier. Draw occupied addresses rather than blind stride samples.
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const Block = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
var infected: Dictionary = {}
var recovered: Dictionary = {}
var candidates: Array = []
var changes: Dictionary = {}
var cursor := 0
var clock := 0.0
var console: Node3D
var readout: Label3D
var last_draw := 0.0
func _ready() -> void:
	museum_budget = true
	setup_common_materials();initialize_grid();index_state()
	sphere_mesh = SphereMesh.new();sphere_mesh.radius = CUBE_SIZE*.9;sphere_mesh.height = sphere_mesh.radius*2;sphere_mesh.radial_segments = 8;sphere_mesh.rings = 4
	configure_multimesh(sphere_mesh,4096)
	var finish := StandardMaterial3D.new();finish.vertex_color_use_as_albedo = true;finish.emission_enabled = true;finish.emission = Color("66515c");finish.emission_energy_multiplier = .35
	multi_mesh_instance.material_override = finish;is_running = true;update_visualization();install_console.call_deferred()
	set_meta("void_preview_kind","Original 64-cubed synchronous SIR; sparse frontier evaluation. Occupied addresses drawn without blind stride sampling; display capped at4096, counts report all states.")
func index_state() -> void:
	infected.clear();recovered.clear()
	for x in GRID_SIZE:
		for y in GRID_SIZE:
			for z in GRID_SIZE:
				var p := Vector3i(x,y,z)
				if grid[x][y][z]==1:infected[p] = true
				elif grid[x][y][z]==2:recovered[p] = true
func begin_step() -> void:
	var eligible: Dictionary = infected.duplicate()
	for p: Vector3i in infected:
		for q: Vector3i in get_3d_neighbors(p):
			if is_valid_3d_position(q) and grid[q.x][q.y][q.z]==0:eligible[q] = true
	candidates = eligible.keys()
	candidates.sort_custom(func(a,b):return a.x*4096+a.y*64+a.z<b.x*4096+b.y*64+b.z)
	changes.clear();cursor = 0
	if candidates.is_empty():iteration_count += 1;budget_commits += 1;update_visualization()
func step_once() -> void:
	is_running = false
	if candidates.is_empty():begin_step()
func toggle_run() -> void:is_running = not is_running
func _process(delta: float) -> void:
	clock += delta;last_draw += delta
	if candidates.is_empty() and is_running and clock>=.25:begin_step();clock = 0
	if not candidates.is_empty():
		for i in range(cursor,mini(cursor+512,candidates.size())):
			var p: Vector3i = candidates[i];var state: int = grid[p.x][p.y][p.z]
			if state==0 and randf()<INFECTION_RATE:changes[p] = 1
			elif state==1 and randf()<RECOVERY_RATE:changes[p] = 2
		cursor = mini(cursor+512,candidates.size())
		if cursor==candidates.size():
			for p: Vector3i in changes:
				grid[p.x][p.y][p.z] = changes[p]
				if changes[p]==1:infected[p] = true
				else:infected.erase(p);recovered[p] = true
			candidates.clear();changes.clear();iteration_count += 1;budget_commits += 1;update_visualization()
	if last_draw>.1:last_draw = 0;update_visualization()
func update_visualization() -> void:
	if multi_mesh_instance==null or multi_mesh_instance.multimesh==null:return
	var positions: Array = infected.keys();positions.append_array(recovered.keys())
	var stride := maxi(1,ceili(positions.size()/4096.0));var drawn := 0
	var mm: MultiMesh = multi_mesh_instance.multimesh
	for i in range(0,positions.size(),stride):
		var p: Vector3i = positions[i];var pulse := 1.0+sin(Time.get_ticks_msec()*.003+p.x*.1)*.2
		mm.set_instance_transform(drawn,Transform3D(Basis().scaled(Vector3.ONE*pulse),_grid_to_world(p)))
		mm.set_instance_color(drawn,Color("ef476f") if infected.has(p) else Color("80d19a"));drawn += 1
	mm.visible_instance_count = drawn
	if readout!=null:readout.text = "SIR / GEN %d\nS %d  I %d  R %d\n%d OF %d OCCUPIED ADDRESSES"%[iteration_count,262144-infected.size()-recovered.size(),infected.size(),recovered.size(),drawn,positions.size()]
func reset_simulation() -> void:
	initialize_grid();index_state();candidates.clear();changes.clear();cursor = 0;iteration_count = 0;budget_commits = 0;clock = 0;is_running = false;update_visualization()
func get_disease_counts() -> Dictionary:return {"susceptible":262144-infected.size()-recovered.size(),"infected":infected.size(),"recovered":recovered.size()}
func install_console() -> void:
	console = Rack.create_panel("LOCAL TRANSMISSION",[[{"type":"button","label":"STEP"},{"type":"button","label":"RUN"},{"type":"button","label":"RESET"}]],false)
	console.name = "LiveControls";console.scale = Vector3.ONE*1.6/scale.x
	console.position = Vector3(0,(1.12-get_parent().position.y)/scale.y,3.3/scale.z);console.rotation_degrees.x = -25;add_child(console)
	var callbacks: Array[Callable] = [step_once,toggle_run,reset_simulation]
	for i in callbacks.size():
		var callback := callbacks[i];console.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b):callback.call())
	readout = Label3D.new();readout.font_size = 32;readout.pixel_size = .001/scale.x;readout.position = console.position+Vector3(0,.34/scale.y,0);add_child(readout);update_visualization()
	var pedestal: Node3D = Block.instantiate();pedestal.name = "OperatingPlinth";pedestal.platform_size = Vector3(.65,.92,.5)
	pedestal.scale = Vector3.ONE/scale.x;pedestal.position = Vector3(0,-get_parent().position.y/scale.y,3.3/scale.z);add_child(pedestal)
