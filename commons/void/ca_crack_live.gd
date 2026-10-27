extends "res://algorithms/cellularautomata/ca_showcase/crack_propagation_ca.gd"
## The original rule only changes stress points and their immediate neighbours.
## Render those actual occupied cells, without striding past them or parking
## unused instances 1000 metres below the floor. The propagation rule is unchanged.
var occupied_finish: StandardMaterial3D
var console: Node3D
var elapsed := 0.0
func _ready() -> void:
	super._ready();install_console.call_deferred()
func _process(delta: float) -> void:
	if not is_running:return
	elapsed += delta
	if elapsed>=.25:elapsed = 0;propagate_cracks();iteration_count += 1;update_visualization()
func step_once() -> void:
	is_running = false;propagate_cracks();iteration_count += 1;update_visualization()
func toggle_run() -> void:is_running = not is_running
func reset_simulation() -> void:
	super.reset_simulation();is_running = false;update_visualization()
func install_console() -> void:
	console = preload("res://commons/audio/rack_templates/RackTemplates.gd").create_panel("STRESS / LOCAL CRACKS",[[{"type":"button","label":"STEP"},{"type":"button","label":"RUN"},{"type":"button","label":"RESET"}]],false)
	console.name = "LiveControls";console.scale = Vector3.ONE*1.6/scale.x
	console.position = Vector3(0,(1.05-get_parent().position.y)/scale.y,1.5/scale.z);console.rotation_degrees.x = -25;add_child(console)
	var callbacks: Array[Callable] = [step_once,toggle_run,reset_simulation]
	for i in callbacks.size():
		var callback := callbacks[i];console.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b):callback.call())
	var plinth: Node3D = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn").instantiate();plinth.name = "OperatingPlinth";plinth.platform_size = Vector3(.6,.85,.5)
	plinth.scale = Vector3.ONE/scale.x;plinth.position = Vector3(0,-get_parent().position.y/scale.y,1.5/scale.z);add_child(plinth)
func update_visualization() -> void:
	if multi_mesh_instance==null or multi_mesh_instance.multimesh==null:return
	var possible: Dictionary = {}
	for p: Vector3i in stress_points:
		possible[p] = true
		for q: Vector3i in get_3d_neighbors(p):
			if is_valid_3d_position(q):possible[q] = true
	var occupied: Array = possible.keys().filter(func(p):return grid[p.x][p.y][p.z]>0)
	var mm: MultiMesh = multi_mesh_instance.multimesh
	mm.instance_count = occupied.size();mm.visible_instance_count = -1
	for i in occupied.size():
		var p: Vector3i = occupied[i]
		mm.set_instance_transform(i,Transform3D(Basis(),Vector3(p-Vector3i.ONE*(GRID_SIZE/2))*CUBE_SIZE))
		mm.set_instance_color(i,Color("ef476f") if grid[p.x][p.y][p.z]==1 else Color("d9d8d2"))
	if occupied_finish==null:occupied_finish = StandardMaterial3D.new();occupied_finish.vertex_color_use_as_albedo = true
	multi_mesh_instance.material_override = occupied_finish
