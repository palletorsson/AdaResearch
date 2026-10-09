extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Three opt-in instruments share the compact six-button desk.
var kind := "koch"
var source: Node3D
var show_rule := false
var show_cover := false
var show_fit := false
var range_mode := 0
var reading: Node3D
var cover: MeshInstance3D
var fit_caption: Label3D

func _ready() -> void:
	source=get_parent()
	var ids: Array
	var title: String
	match kind:
		"koch":
			ids=["NEXT","BACK","FORM","TURN","RESET","RULE"]
			title="01 / FOLLOW THE DETOUR"
			source._depth_controller.queue_free()
			source._depth_controller=null
			source._info_label.hide();source._dimension_label.hide()
			source._mesh_instance.scale=Vector3.ONE*5
			source._mesh_instance.position.y=1.2
		"sierpinski":
			ids=["NEXT","BACK","VIEW","DEPTH","RESET","RULE"]
			title="02 / WHICH PART IS THE WORK?"
		"measure":
			ids=["FINER","COARSER","COVER","RANGE","RESET","RULE"]
			title="03 / WHAT DOES THIS GRID MISS?"
			_setup_reading()
	_build_compact_console(ids,title)
	begin()
	_use_hall_light.call_deferred()

func _setup_reading() -> void:
	for child in source.get_children():
		if child==self or child in [source._point_cloud,source._grid_instance,source._plot_instance]:continue
		if child is Node3D: child.hide()
	reading=Node3D.new();reading.name="ReadingPlane";source.add_child(reading)
	reading.rotation_degrees.x=-90
	reading.scale=Vector3.ONE*0.55
	reading.position.y=2.0
	source._point_cloud.reparent(reading,false)
	source._grid_instance.reparent(reading,false)
	source._plot_instance.position=Vector3(3.0,1.0,0)
	source._plot_instance.scale=Vector3.ONE*0.75
	source._plot_instance.material_override=null
	var backing:=material("162e3b")
	box(Vector3(0,2.0,-0.09),Vector3(3.6,3.6,0.08),backing,true)
	box(Vector3(4.15,2.1,-0.09),Vector3(2.65,2.8,0.08),backing,true)
	fit_caption=label("RANGE reveals the fit",Vector3(4.1,3.7,0),0.0018)
	label("log2(1 / box size)",Vector3(4.1,0.75,0),0.0018)
	label("log2(count)",Vector3(4.1,3.45,0),0.0018)
	label("8000 samples / fixed seed 2026",Vector3(0,3.95,0),0.0018)

func begin() -> void:
	show_rule=false
	match kind:
		"koch":
			source.animate_growth=false;source.max_depth=4
			source.snowflake_mode=false;source.peak_side=1.0;source.line_thickness=0.004
			set_stage(0)
		"sierpinski":
			source.auto_start=false;source.max_iterations=4
			source.triangle_size=6.0;source.triangle_thickness=0.08
			source.extrude_on_subdivision=false;source.excision="absence"
			set_stage(0)
		"measure":
			show_cover=false;show_fit=false;range_mode=0
			source._static_evidence=true;source._current_scale_idx=0;source.fit_indices.clear()
			source.replay_sample(2026)
			update_measurement()

func set_stage(n: int) -> void:
	n=clampi(n,0,4)
	if kind=="koch":
		source._precompute_all_depths()
		source._current_depth=n
		source._draw_depth(n)
	else:
		source.reset()
		for i in range(n):source.step()
		for mesh in source.get_children():
			if not mesh.has_meta("triangle_kind"):continue
			var kept: bool=mesh.get_meta("triangle_kind")=="kept"
			mesh.visible=(int(mesh.get_meta("triangle_depth"))==n and source.excision!="negative") if kept else true
			mesh.rotation_degrees.x=90
			mesh.position=Vector3(0,2.1,0)
	refresh()

func act(id: String) -> void:
	if id=="RESET":begin();return
	if id=="RULE":show_rule=not show_rule;refresh();return
	show_rule=false
	if kind=="measure":
		match id:
			"FINER":source._current_scale_idx=mini(source._current_scale_idx+1,5)
			"COARSER":source._current_scale_idx=maxi(source._current_scale_idx-1,0)
			"COVER":show_cover=not show_cover
			"RANGE":
				show_fit=true;range_mode=(range_mode+1)%3
				source.fit_indices.assign([0,1,2] if range_mode==1 else ([3,4,5] if range_mode==2 else []))
		update_measurement()
		return
	var n: int=source._current_depth if kind=="koch" else source.current_iteration
	match id:
		"NEXT":n+=1
		"BACK":n-=1
		"FORM":source.snowflake_mode=not source.snowflake_mode
		"TURN":source.peak_side*=-1.0
		"VIEW":source.excision={"absence":"ghost","ghost":"negative","negative":"absence"}.get(source.excision,"absence")
		"DEPTH":source.triangle_thickness=0.35 if source.triangle_thickness<0.1 else 0.08
	set_stage(n)

func update_measurement() -> void:
	source._update_grid_display();source._update_plot()
	source._plot_instance.visible=show_fit
	fit_caption.text="finite-scale fit %.3f / %s" % [source.measured_slope,["all six","coarse three","fine three"][range_mode]] if show_fit else "RANGE reveals the fit"
	if is_instance_valid(cover):
		source._evidence_parts.erase(cover)
		cover.get_parent().remove_child(cover);cover.queue_free()
	cover=null
	if show_cover:
		source._build_longhand_cover(source._current_scale_idx)
		cover=source._evidence_parts.back()
		cover.reparent(reading,false)
	refresh()

func refresh() -> void:
	match kind:
		"koch":
			var segments: Array=source._lines_by_depth[source._current_depth]
			var length:=0.0
			for seg in segments:length+=seg.start.distance_to(seg.end)*5.0
			readout.text="replace one segment with four thirds\nTURN changes direction; FORM closes a triangle" if show_rule else "step %d / 4 | %d segments | %.3f m path\n%s | %s turns" % [source._current_depth,segments.size(),length,"snowflake" if source.snowflake_mode else "open line","outward" if source.peak_side>0 and source.snowflake_mode else ("left" if source.peak_side>0 else "reversed")]
		"sierpinski":
			var area:=0.0
			for tri in source.current_triangles:area+=(tri.v2-tri.v1).cross(tri.v3-tri.v1).length()*0.5
			readout.text="m1 = (v1 + v2) / 2; likewise m2, m3\nkeep the three corners; choose how to draw the rest" if show_rule else "cut %d / 4 | %d kept triangles | %.3f m2\nview %s | drawn depth %.2f m" % [source.current_iteration,source.current_triangles.size(),area,source.excision,source.triangle_thickness]
		"measure":
			var divs: int=source.GRID_SCALES[source._current_scale_idx]
			readout.text="count occupied cells at several box sizes\nfit log(count) against log(1 / box size)" if show_rule else "%d x %d grid | %d occupied | box %.4f units\ncover %s | fit range %s" % [divs,divs,source._counts[source._current_scale_idx],6.0/divs,"on" if show_cover else "off",["all six","coarse three","fine three"][range_mode]]

func _use_hall_light() -> void:
	var hall: Node=source
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null or str(hall.get_meta("em_map"))!="Fractal_KochSierpinski":return
	for lamp in hall.find_children("*","DirectionalLight3D",true,false):lamp.hide()
	if kind!="koch" or hall.has_node("KochHallLights"):return
	var lights:=Node3D.new();lights.name="KochHallLights";hall.add_child(lights)
	for at in [Vector3(5.5,5,10),Vector3(15.5,5,10),Vector3(6.5,5,18),Vector3(15.5,4,19),Vector3(10.5,5,27)]:
		var lamp:=OmniLight3D.new();lamp.position=at;lamp.omni_range=10;lamp.light_energy=3;lights.add_child(lamp)

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
