extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Opt-in desks for the five PG encounters. Existing algorithms own their state.
const BRANCH = preload("res://algorithms/proceduralgeneration/growth_systems/branchinggrowthalgorithm/branching_growth_algorithm.gd")
var chapter := ""
var works: Dictionary = {}
var model
var other
var ready_for_input := false
var busy := false
var step_count := 0
var variant := 0
var sample_index := 0
var trace: MultiMeshInstance3D
var held: MeshInstance3D
var held_field: Array = []
var source_points: Array[Vector3] = []
var graph_view: Node3D
var show_surface := false
var rule_card: Label3D
var sampled := false
var notice := ""
var ids: Array = []
const TITLES = {"branching":"ONE NEAREST INVITATION", "percolation":"TOUCHING IS NOT ENOUGH", "caves":"HOW IS A PASSAGE MADE?", "sculpted":"WHAT DID THE SAMPLE KEEP?", "mirrored":"COPY AN IMAGE / CONNECT A PATH"}
const RULES = {
 "branching":"Each active site chooses ONE nearest unreached point.\nNormalize that direction; add a 0.5 m segment.\nOlder sites can act again, including coincident children.\n192 records is a computational cap, not maturity.",
 "percolation":"18 cubed sites. Six FACE neighbours transmit flow.\nA corner does not count. STEP reads the previous generation.\nWhite sites collide; pink flow sites do not.\nA signal route is not a certificate for your body.",
 "caves":"CAVE: biased lateral walks carve two cells of headroom,\nthen climb through prescribed levels. Dots mark carving centres.\nMAZE: choose an unvisited neighbour, remove the intervening wall;\npush the current cell. At a dead end, pop the stack.",
 "sculpted":"DROP runs physics. SAMPLE freezes the current cubes.\nThe mesh expands axis-aligned voxels around their CENTRES.\nRotation and exact contact shapes are not copied.\nCUT reveals Boolean operands: absence has a shape.",
 "mirrored":"HOLD keeps a cellular field. STENCIL copies that held field.\nSTEP evolves the displayed field, then applies its symmetry.\nNETWORK rebuilds six fixed seed positions: tree / rhizome / severed.\nGraph components and cycles do not certify tunnel clearance."
}

func apply_grid_config(config: Dictionary) -> void:
	if config.has("chapter"): chapter = str(config.chapter)

func _ready() -> void:
	chapter = str(get_meta("config_chapter", chapter))
	_bind.call_deferred()

func _bind() -> void:
	var hall: Node = get_parent()
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	if hall == null: return
	var em: Node = hall
	while em != null and not "_edit_records" in em: em = em.get_parent()
	if em == null: return
	var requirements: Dictionary = {
	 "branching":["branching_growth_algorithm"],"percolation":["percolationnetwork_ca"],
	 "caves":["caverandomwalk","maze_generation"],"sculpted":["cube_mound_scene","dome"],
	 "mirrored":["mirror_cellular_texture_for_3d","rhizomatic_maze_space"]}
	if not requirements.has(chapter): return
	for attempt in 80:
		for rec: Dictionary in em.get("_edit_records"):
			var n = rec.get("node")
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.get("token") in requirements[chapter]:
				works[rec.token] = n
		if works.size() == requirements[chapter].size(): break
		await get_tree().create_timer(0.1).timeout
	if works.size() != requirements[chapter].size(): push_error("PG workshop could not bind " + chapter); return
	match chapter:
		"branching":
			model = _script_node(works.branching_growth_algorithm, "branching_growth_algorithm.gd")
			model.set_process(false); model.is_growing = false
			model.attraction_distance=8.0; model.growth_distance=0.5; model.min_branch_distance=0.32
			model.max_branches=192; model.jitter=0.0; model.pulse_strength=0.0; model.aftermath="apparatus"
			ids=["STEP","VARIATION","HOLD","RESET","TEN STEPS","RULE"]
			_reset_branch()
		"percolation":
			model = works.percolationnetwork_ca; model.set_process(false)
			ids=["STEP","CONTACT","LATTICE","DENSITY","RESET","RULE"]
			_reset_percolation(false)
		"caves":
			model=_script_node(works.caverandomwalk,"caverandomwalk.gd"); other=works.maze_generation; other.set_process(false)
			ids=["CAVE SEED","TRACE","MAZE STEP","FINISH","RESET","RULE"]
			_build_trace()
		"sculpted":
			model=works.cube_mound_scene; other=works.dome; model.set_process(false)
			ids=["DROP","SAMPLE","VOXEL","ORIGINAL","CUT","RULE"]
			_drop()
		"mirrored":
			model=_script_node(works.mirror_cellular_texture_for_3d,"mirrored_cellular_automata.gd")
			other=works.rhizomatic_maze_space; model.auto_evolve=false; model.set_process(false)
			model.display_size=5.0; model.cell_world_size=5.0/model.grid_size
			model.birth_probability=1.0; model.death_probability=1.0
			model.symmetry_type=3; model.initialize_grid()
			for y in range(2,model.grid_size-2):
				for x in range(2,model.grid_size-2):
					model.grid[y][x]=1 if (x*13+y*7+x*y)%11<3 else 0
			held_field=model.grid.duplicate(true); variant=3; model._rebuild_mesh()
			source_points=other.maze_generator.growth_points.duplicate()
			ids=["STEP","HOLD","STENCIL","NETWORK","SURFACE","RULE"]
			_draw_graph()
	for work in works.values():
		for ui in work.find_children("*","CanvasLayer",true,false): ui.hide()
	# Old scene panels remain ordinary scene controls outside this lesson.
	# In the museum they must not cover the view or leave hidden touch colliders.
	for ui in hall.find_children("*","CanvasLayer",true,false):
		ui.hide()
		for item in ui.find_children("*","Control",true,false): item.hide()
		for item in ui.find_children("*","Node3D",true,false):
			if item is CollisionObject3D: item.collision_layer=0; item.collision_mask=0
			item.hide()
	var dims: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+str(hall.get_meta("em_map"))+"/map_data.json")).map_info.dimensions
	for z in range(7,int(dims.depth),10):
		for x in [int(dims.width)*0.3,int(dims.width)*0.7]:
			var fill:=OmniLight3D.new(); fill.position=Vector3(x,7,z+int(em.get("VESTIBULE_H")))
			fill.omni_range=19; fill.light_energy=5; fill.omni_attenuation=0.7; hall.add_child(fill)
	_build_compact_console(ids,TITLES[chapter])
	rule_card=label(RULES[chapter],Vector3(0,2.4,0.4),0.001)
	rule_card.visible=false
	for at in [Vector3(-3,5,-2),Vector3(3,5,-8)]:
		var light:=OmniLight3D.new();light.position=at;light.omni_range=20;light.light_energy=3;add_child(light)
	ready_for_input=true; refresh()

func _script_node(n: Node, ending: String):
	if n.get_script() != null and str(n.get_script().resource_path).ends_with(ending): return n
	for child in n.get_children():
		var found = _script_node(child,ending)
		if found != null: return found
	return null

func _reset_branch() -> void:
	model.branches.clear(); model.attractors.clear(); step_count=0
	model.add_branch(Vector3.ZERO,Vector3.UP)
	for p in [Vector3(-2,1.5,0),Vector3(-2.5,2.5,0.4),Vector3(-3,3.5,0),Vector3(1.5,2.5,0),Vector3(2,3.5,-0.5),Vector3(2.5,4.5,0),Vector3(0,5.5,1),Vector3(0,6,0)]:
		model.attractors.append(BRANCH.Attractor.new(p))
	model.time_elapsed=0.0; model.pulse_timer=0.0
	model.update_mesh_immediate()

func _branch_step() -> void:
	if model.branches.size()>=192: return
	model.time_elapsed+=0.2; model.pulse_timer+=0.2
	model.grow_step(); step_count+=1; model.update_mesh_immediate()

func _reset_percolation(lattice: bool) -> void:
	step_count=0; model.iteration_count=0; model.percolation_complete=false
	model._rng.seed=1337
	for x in 18:
		for y in 18:
			for z in 18:
				model.grid[x][y][z]=1 if lattice and model._rng.randf()<[0.2,0.4,0.6][sample_index] else 0
				model.flow_grid[x][y][z]=0.0
	if lattice:
		for x in 18:
			for y in 18:
				model.grid[x][y][17]=4; model.flow_grid[x][y][17]=1.0
	else:
		model.grid[9][1][9]=4; model.flow_grid[9][1][9]=1.0
		var p:=Vector3i(10,1,9) if variant==0 else Vector3i(10,2,10)
		model.grid[p.x][p.y][p.z]=1
	model.update_cube_visualization(); sampled=lattice

func _build_trace() -> void:
	if is_instance_valid(trace): trace.get_parent().remove_child(trace); trace.queue_free()
	trace=MultiMeshInstance3D.new(); model.add_child(trace)
	var sphere:=SphereMesh.new(); sphere.radius=0.055; sphere.height=0.11; sphere.radial_segments=8; sphere.rings=4
	var multi:=MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D; multi.mesh=sphere
	multi.instance_count=model.carve_history.size(); trace.multimesh=multi; trace.material_override=material("f0bc56",true)
	var offset:=Vector3(-model.grid_size.x*model.cube_size*0.5+model.cube_size*0.5,0,-model.grid_size.z*model.cube_size*0.5+model.cube_size*0.5)
	for i in model.carve_history.size(): multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(model.carve_history[i])*model.cube_size+offset))
	trace.visible=false

func _drop() -> void:
	model.state="done"; model.start_generation(); sampled=false
	model.set_process(false)

func act(id: String) -> void:
	if not ready_for_input or busy: return
	if id=="RULE": rule_card.visible=not rule_card.visible; return
	busy=true
	match chapter:
		"branching":
			match id:
				"STEP": _branch_step()
				"TEN STEPS": for i in 10: _branch_step()
				"VARIATION":
					variant=1-variant; model.jitter=0.15*variant; model.pulse_strength=0.3*variant; _reset_branch()
				"HOLD":
					if is_instance_valid(held): held.queue_free()
					held=MeshInstance3D.new(); held.mesh=model.immediate_mesh.duplicate(); held.scale=Vector3.ONE*0.4
					held.position=Vector3(-3,1,-2); add_child(held)
				"RESET": variant=0; model.jitter=0; model.pulse_strength=0; _reset_branch()
		"percolation":
			match id:
				"STEP":
					if step_count<64: model.update_percolation_automata(); model.update_cube_visualization(); step_count+=1
				"CONTACT": variant=1-variant; _reset_percolation(false)
				"LATTICE": _reset_percolation(true)
				"DENSITY": sample_index=(sample_index+1)%3; _reset_percolation(true)
				"RESET": variant=0; sample_index=0; _reset_percolation(false)
		"caves":
			match id:
				"CAVE SEED":
					model.seed+=1; model.regenerate(); await get_tree().process_frame; _build_trace()
				"TRACE": trace.visible=not trace.visible
				"MAZE STEP":
					if other.generating: other._generation_step(); step_count+=1
				"FINISH":
					for i in 128:
						if other.generating: other._generation_step(); step_count+=1
				"RESET": await other.regenerate(); other.set_process(false); step_count=0
		"sculpted":
			match id:
				"DROP": _drop()
				"SAMPLE","VOXEL":
					if id=="VOXEL": model.voxel_size=1.0 if model.voxel_size<0.75 else 0.5
					for body in model.cubes: body.freeze=true
					model.clear_generated_mesh(); await model.generate_mesh_from_cubes(); sampled=true
				"ORIGINAL":
					if sampled:
						var show: bool=not model.cubes[0].visible
						for body in model.cubes: body.visible=show
						model.generated_mesh.visible=not show
				"CUT": variant=(variant+1)%4; other.apply_grid_config({"facture":["cast","blank","core","section"][variant]})
		"mirrored":
			match id:
				"STEP": model.update_grid(); model.generation+=1; model._rebuild_mesh()
				"HOLD": held_field=model.grid.duplicate(true)
				"STENCIL": variant=(variant+1)%4; _stencil()
				"NETWORK":
					sample_index=(sample_index+1)%3; other.apply_grid_config({"topology":["tree","rhizome","severed"][sample_index]})
					_draw_graph()
				"SURFACE": show_surface=not show_surface; _draw_graph()
	busy=false; refresh()

func _stencil() -> void:
	model.grid=held_field.duplicate(true); model.symmetry_type=variant
	match variant:
		0: model.apply_quad_symmetry(model.grid)
		1: model.apply_eight_way_symmetry(model.grid)
		2: model.apply_rotational_symmetry(model.grid)
	model._rebuild_mesh()

func _draw_graph() -> void:
	if is_instance_valid(graph_view): graph_view.get_parent().remove_child(graph_view); graph_view.queue_free()
	graph_view=Node3D.new(); other.add_child(graph_view)
	other.environment_container.visible=show_surface
	# This is an observation specimen. Its shell must not leave invisible barriers.
	for body in other.environment_container.find_children("*","CollisionObject3D",true,false):
		body.collision_layer=0; body.collision_mask=0
	graph_view.visible=not show_surface
	var mat:=material("efbf80",true)
	for n in other.maze_generator.network_nodes:
		var dot:=MeshInstance3D.new();var ball:=SphereMesh.new();ball.radius=0.16;ball.height=0.32;ball.radial_segments=12;ball.rings=6
		dot.mesh=ball;dot.material_override=mat;dot.position=n.position;graph_view.add_child(dot)
	var seen: Dictionary={}
	for edge in other.maze_generator.connections:
		var key: String="%d:%d" % [mini(edge.start_id,edge.end_id),maxi(edge.start_id,edge.end_id)]
		if seen.has(key):continue
		seen[key]=true
		var delta: Vector3=edge.end-edge.start
		if delta.length()<0.0001:continue
		var rod:=MeshInstance3D.new();var cylinder:=CylinderMesh.new();cylinder.top_radius=0.045;cylinder.bottom_radius=0.045;cylinder.height=delta.length();cylinder.radial_segments=8
		rod.mesh=cylinder;rod.material_override=mat;rod.position=(edge.start+edge.end)*0.5;rod.quaternion=Quaternion(Vector3.UP,delta.normalized());graph_view.add_child(rod)

func graph_metrics() -> Dictionary:
	var nodes: Array=other.maze_generator.network_nodes
	var edges: Array=other.maze_generator.connections
	var seen: Dictionary={}; var components:=0
	var adj: Dictionary={}
	for n in nodes: adj[n.id]=[]
	var unique: Dictionary={}
	for edge in edges:
		var key := "%d:%d" % [mini(edge.start_id,edge.end_id),maxi(edge.start_id,edge.end_id)]
		if unique.has(key): continue
		unique[key]=true
		adj[edge.start_id].append(edge.end_id); adj[edge.end_id].append(edge.start_id)
	for n in nodes:
		if seen.has(n.id): continue
		components+=1; var todo: Array=[n.id]; seen[n.id]=true
		while not todo.is_empty():
			var a=todo.pop_back()
			for b in adj[a]:
				if not seen.has(b): seen[b]=true; todo.append(b)
	return {"nodes":nodes.size(),"edges":unique.size(),"components":components,"cycles":unique.size()-nodes.size()+components}

func refresh() -> void:
	if readout==null: return
	match chapter:
		"branching":
			var children: Dictionary={}; var forks:=0; var unique: Dictionary={}
			for b in model.branches:
				unique[b.position]=true
				if b.parent_index>=0: children[b.parent_index]=children.get(b.parent_index,0)+1
			for n in children.values():
				if n>1: forks+=1
			readout.text="Step %d | %d/192 records | %d distinct positions\n%d parent records with multiple children\nVariation %s | same eight targets" % [step_count,model.branches.size(),unique.size(),forks,"ON" if variant else "OFF"]
		"percolation":
			var reached:=0; var far:=0
			for x in 18:
				for y in 18:
					for z in 18:
						if model.grid[x][y][z] in [2,3]:
							reached+=1
							if z==0: far+=1
			readout.text="%s | step %d/64\n%d reached sites | %d on opposite face\nWhite = solid; pink = no collision" % [("Lattice p="+str([0.2,0.4,0.6][sample_index])) if sampled else ("FACE contact" if variant==0 else "CORNER contact"),step_count,reached,far]
		"caves": readout.text="Cave seed %d | %d carving centres\nMaze step %d | stack %d | %s\nTRACE marks centres, including repeated visits" % [model.seed,model.carve_history.size(),step_count,other.generation_stack.size(),"complete" if other.generation_complete else "building"]
		"sculpted": readout.text="%d bodies | voxels %.1f m | %s\nDome: %s\nORIGINAL changes visibility; sampled collision stays" % [model.cubes.size(),model.voxel_size,"sampled" if sampled else "physics running",other.facture]
		"mirrored":
			var g:=graph_metrics()
			readout.text="CA generation %d | %s\n%s: %d nodes / %d edges\n%d components / %d independent cycles" % [model.generation,["quad","eight-way","rotation","none"][variant],other.topology,g.nodes,g.edges,g.components,g.cycles]

func _build_compact_console(ids: Array, title: String) -> void:
	# All six controls fit within one standing position. Keep the physical
	# button size; compact the spacing instead of shrinking the touch targets.
	var casing := material("263a44")
	box(Vector3(0, 0.95, 2.0), Vector3(1.12, 0.12, 0.44), casing, true)
	for x in [-0.42, 0.42]:
		box(Vector3(x, 0.445, 2.0), Vector3(0.08, 0.89, 0.30), casing, true)
	for i in ids.size():
		var id: String = ids[i]
		var column: int = i % 3
		var row: int = i / 3
		var button = PUSH.instantiate()
		button.position = Vector3((column - 1) * 0.32, 1.045, 1.88 + row * 0.23)
		button.rotation = Vector3.ZERO
		button.scale = Vector3.ONE * 1.15
		add_child(button)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
		var caption := label(id, button.position + Vector3(0, 0.01, 0.09), 0.00065)
		caption.rotation_degrees.x = -70
	box(Vector3(0, 0.90, 2.235), Vector3(1.12, 0.15, 0.025), casing)
	label(title, Vector3(0, 0.90, 2.252), 0.00063)

	# A single transparent plane avoids the doubled opacity of a glass box.
	# Text keeps an opaque outline, so the exhibit is visible behind the panel
	# while the reading remains distinct from its changing background.
	var panel := Node3D.new()
	panel.name = "TextPanel"
	add_child(panel)
	panel.position = Vector3(0, 1.27, 1.58)
	panel.rotation_degrees.x = -35
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var pane := QuadMesh.new()
	pane.size = Vector2(1.18, 0.36)
	glass.mesh = pane
	var tint := StandardMaterial3D.new()
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	tint.albedo_color = Color(0.12, 0.25, 0.30, 0.14)
	glass.material_override = tint
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(glass)
	for y in [-0.19, 0.19]:
		box(Vector3(0, y, 0), Vector3(1.22, 0.016, 0.016), casing, false, panel)
	for x in [-0.60, 0.60]:
		box(Vector3(x, 0, 0), Vector3(0.016, 0.38, 0.016), casing, false, panel)
	for x in [-0.48, 0.48]:
		box(Vector3(x, 1.09, 1.70), Vector3(0.018, 0.22, 0.018), casing)
	readout = label(title, Vector3.ZERO, 0.0011)
	readout.font_size = 28
	readout.outline_size = 7
	readout.outline_modulate = Color(0.025, 0.04, 0.055, 0.95)
	readout.reparent(panel, false)
	readout.position = Vector3(0, 0, 0.009)
