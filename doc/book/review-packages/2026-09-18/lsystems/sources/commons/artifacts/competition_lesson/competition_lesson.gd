extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## A controlled pair uses the forest's actual consumption, growth and turtle code.
## Fixed initial conditions; a change of order/season resets the comparison.
const COLORS := ["f0b776", "92d5d9"]
const FIELD := Vector3(0,0,-3)
const ENLARGEMENT := 4.0
var model: Node3D
var first := 0
var winter := false
var totals := [0.0,0.0]
var last_takes := [0.0,0.0]
var events: Array = []
var soil_seconds := 0
var notice := "Predict who gets more from the shared patch."
var geometry: Node3D
var specimens: Array[Label3D] = []
var instruction: Label3D

func _ready() -> void:
	model = get_parent().get_script().new()
	model.simulation_model = true
	add_child(model)
	_build_compact_console(["STEP", "ORDER", "SEASON", "SOIL", "RESET", "RULE"], "WHO GETS THE FIRST TURN?")
	label("ORDER / SEASON start afresh",Vector3(0,0.73,2.253),0.0008)
	box(FIELD+Vector3(0,0.006,0),Vector3(7.2,0.012,7.2),material("173136"))
	for x in [-3.6,3.6]:box(FIELD+Vector3(x,0.02,0),Vector3(0.025,0.025,7.2),material("bba36e",true))
	for z in [-3.6,3.6]:box(FIELD+Vector3(0,0.02,z),Vector3(7.2,0.025,0.025),material("bba36e",true))
	for i in 2:
		var x: float = -2.5 if i==0 else 2.5
		box(Vector3(x,0.20,-4.8),Vector3(1.65,0.4,1.25),material("253e43"),true)
		specimens.append(label("",Vector3(x,0.90,-4.05),0.002))
		label("4x branch display\nroot address marked on soil",Vector3(x,0.24,-4.16),0.001)
	instruction=label("SAME F RULE / SAME INITIAL DIAMETER\nA shared soil. Two turns.",Vector3(0,2.7,-6.4),0.0018)
	reset_pair()
	_stage_original.call_deferred()

func reset_pair() -> void:
	model.reset_lesson_pair(first,winter)
	totals=[0.0,0.0];last_takes=[0.0,0.0];events.clear();soil_seconds=0
	rebuild()

func act(id: String) -> void:
	match id:
		"STEP":
			model._grow_step()
			var event: Dictionary=model.last_growth_event.duplicate(true)
			var who: int=event.tree
			totals[who]+=event.uptake;last_takes[who]=event.uptake
			events.append(event)
			if events.size()>80:events.pop_front()
			notice="%s took %.3f / %s" % ["A" if who==0 else "B",event.uptake,event.reason]
		"ORDER":
			first=1-first;notice="Fresh comparison. %s goes first." % ("A" if first==0 else "B");reset_pair();return
		"SEASON":
			winter=not winter;notice="Fresh comparison. %s held steady." % ("Winter" if winter else "Spring");reset_pair();return
		"SOIL":
			# A deliberate second for the field; no tree attempt or season advance.
			for tick in 60:
				model._diffuse_nutrients(1.0/60.0)
				model._replenish_nutrients(1.0/60.0)
			soil_seconds+=1;notice="Soil +1 second. No tree took a turn."
		"RESET":
			first=0;winter=false;notice="Opening state. Same grammar; A goes first.";reset_pair();return
		"RULE":
			readout.text="consume soil; then test the rewrite:\nuptake > 0.05 and season != WINTER\nF -> F[+F]F[-F][F]";return
	rebuild()

func rebuild() -> void:
	if is_instance_valid(geometry):remove_child(geometry);geometry.queue_free()
	geometry=Node3D.new();geometry.name="MeasuredState";add_child(geometry)
	# One shared mesh for all 400 cells; colour and height expose depletion.
	var mesh:=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in 20:
		for x in 20:
			var val: float=model._nutrient_grid[z][x]
			var p:=FIELD+Vector3(-3.5+x*0.35,0.025+val*0.20,-3.5+z*0.35)
			var col:=Color("322837").lerp(Color("6daa85"),clampf(val/0.6,0,1))
			for d in [Vector3.ZERO,Vector3(0.33,0,0.33),Vector3(0.33,0,0),Vector3.ZERO,Vector3(0,0,0.33),Vector3(0.33,0,0.33)]:
				mesh.surface_set_color(col);mesh.surface_add_vertex(p+d)
	mesh.surface_end()
	var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	var cells:=MeshInstance3D.new();cells.mesh=mesh;cells.material_override=mat;geometry.add_child(cells)
	# Preview precisely the square each next attempt will sample, at its grid address.
	for i in 2:
		var tree=model._trees[i]
		var gc: Vector2i=model._world_to_grid(tree.position)
		var radius: int=clampi(int(ceil(tree.crown_radius/0.35))+1,1,4)
		var size: float=(2*radius+1)*0.35
		var center:=FIELD+Vector3(-3.5+(gc.x+0.5)*0.35,0.17+i*0.025,-3.5+(gc.y+0.5)*0.35)
		var color:=material(COLORS[i],true)
		for side in [-1,1]:
			box(center+Vector3(side*size*0.5,0,0),Vector3(0.02,0.015,size),color,false,geometry)
			box(center+Vector3(0,0,side*size*0.5),Vector3(size,0.015,0.02),color,false,geometry)
		box(FIELD+tree.position+Vector3(0,0.24,0),Vector3(0.07,0.14,0.07),color,false,geometry)
		var origin:=Vector3(-2.5 if i==0 else 2.5,0.43,-4.8)
		# Display enlargement never alters the model's root, uptake or crowding radius.
		var lines:=ImmediateMesh.new();lines.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for segment in tree.segments:
			var a: Vector3=origin+(segment[0]-tree.position)*ENLARGEMENT
			var b: Vector3=origin+(segment[1]-tree.position)*ENLARGEMENT
			var across: Vector3=segment[4]*segment[3]*ENLARGEMENT
			for perp in [across,across.rotated((b-a).normalized(),PI/2)]:
				for v in [a-perp,a+perp,b+perp*0.7,a-perp,b+perp*0.7,b-perp*0.7]:lines.surface_add_vertex(v)
		lines.surface_end()
		var branch:=MeshInstance3D.new();branch.mesh=lines;branch.material_override=color;geometry.add_child(branch)
		specimens[i].text="%s / generation %d of 3\nlast %.3f / total %.3f" % ["A" if i==0 else "B",tree.generation,last_takes[i],totals[i]]
		specimens[i].modulate=Color(COLORS[i])
	refresh()

func refresh() -> void:
	readout.text="%s / next %s / soil +%ds\nA %.3f | B %.3f (last uptake)\n%s" % ["WINTER" if winter else "SPRING","A" if model._current_grow_idx%2==0 else "B",soil_seconds,last_takes[0],last_takes[1],notice]

func _stage_original() -> void:
	var source: Node3D=get_parent()
	for at in [Vector3(-4,4,-3),Vector3(4,4,-3),Vector3(-4,4,-15),Vector3(4,4,-15)]:
		var lamp:=OmniLight3D.new();lamp.position=at;lamp.omni_range=11;lamp.light_energy=4.0;source.add_child(lamp)
	for n in [source._tree_mi,source._soil_mi,source._graph_mi,source._title_label,source._stats_label,source._season_label,source._diffusion_ctrl,source._supply_ctrl,source._speed_ctrl,source._trees_ctrl]:
		n.position+=Vector3(0,0.06,-15)
	source._soil_mi.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	for caption in [source._title_label,source._stats_label,source._season_label]:caption.pixel_size=0.0015
	box(Vector3(0,0.012,-15),Vector3(7.2,0.024,7.2),material("294037"))
	box(Vector3(-3,0.40,-17),Vector3(0.9,0.8,0.9),material("253e43"),true)
	label("CORAL / retained form study",Vector3(-3,0.55,-16.53),0.0007)
	# Flush covers keep the old two void addresses without a fall in the soil view.
	for p in [Vector3(-2,0,-15),Vector3(2,0,-18)]:
		box(p+Vector3(0,0.005,0),Vector3(1,0.01,1),material("294037"),true)
	label("THE ORIGINAL FIVE STRATEGIES\nautomatic seasons / shared soil / one turn at a time",Vector3(0,2.4,-11),0.0017)
	var hall: Node=get_parent()
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null or str(hall.get_meta("em_map"))!="LSystems_Competition":return
	for light in hall.find_children("*","DirectionalLight3D",true,false):light.hide()
	for camera in hall.find_children("*","Camera3D",true,false):camera.current=false
	for at in [Vector3(5,4,12),Vector3(15,4,12),Vector3(9.5,4,26)]:
		var light:=OmniLight3D.new();light.position=at;light.omni_range=16;light.light_energy=3.2;hall.add_child(light)

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
