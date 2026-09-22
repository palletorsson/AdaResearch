extends "res://commons/artifacts/timing_machines/machine_stage.gd"
const SC = preload("res://algorithms/proceduralgeneration/growth_systems/space_colonization_algorithm/SpaceColonizationAlgorithm.gd")
var model: Node3D
var live: Node3D
var witness: Node3D
var held_record: Array = []
var field_index := 0
var rule_visible := false
var notice := "Read the three requests. Where will their sum go?"
var rule_card: Label3D
var stopped := false
var field_names := ["THREE REQUESTS", "ASYMMETRIC FIELD", "ASYMMETRIC CANOPY"]
var origin_display := Vector3(0,0.18,-6)

func _ready() -> void:
	_build_compact_console(["STEP", "FIELD", "POLICY", "HOLD", "RESET", "RULE"], "WHICH POINTS GET A SAY?")
	model.set_process(false);model.is_growing=false;model.show_growth_animation=false;model.hide()
	model.segment_length=0.5;model.influence_distance=8.0;model.kill_distance=0.32
	model.node_budget=192;model.max_iterations=60;model.branch_thickness=0.7;model.thickness_decay=0.97
	model.growth_policy="tips"
	box(Vector3(0,0.04,-6),Vector3(8,0.08,7),material("1f3d48"),false)
	box(Vector3(-5.2,0.6,-6),Vector3(2.5,1.2,3),material("314c59"),true)
	label("HELD / 0.45 x DISPLAY SCALE",Vector3(-5.2,0.83,-4.4),0.0008)
	rule_card=label("Every point chooses its nearest eligible site.\nSum UNIT directions; normalize; take one 0.5 m step.\nTIPS replaces growing ends. NETWORK keeps older sites eligible.\nLimits: 192 nodes / 60 generations. A budget is not maturity.",Vector3(0,2.85,0),0.00115)
	rule_card.visible=false
	reset_field()
	_build_support.call_deferred()
	for at in [Vector3(-4,4,-2),Vector3(4,5,-7),Vector3(-5.2,3,-5)]:
		var light:=OmniLight3D.new();light.position=at;light.omni_range=16;light.light_energy=3;add_child(light)

func points_for_field() -> Array[Vector3]:
	var points: Array[Vector3]=[]
	if field_index==0:
		points.assign([Vector3(-2,3,0),Vector3(2,3,0),Vector3(0,5,0)])
	elif field_index==1:
		points.assign([Vector3(-2,1.5,0),Vector3(-2.5,2.5,0.4),Vector3(-3,3.5,0),Vector3(1.5,2.5,0),Vector3(2,3.5,-0.5),Vector3(2.5,4.5,0),Vector3(0,5.5,1),Vector3(0,6,0)])
	else:
		for y in 4:
			for ring in 3:
				for i in 8:
					# Authored deterministic asymmetry, not a new random field at each step.
					var a: float=TAU*(i/8.0)+y*0.19+ring*0.13+0.37*sin(i*1.7+ring)
					var radius: float=1.1+ring*0.8+0.2*sin(i*2.1+y)
					points.append(Vector3(cos(a)*radius,2.4+y*1.0,sin(a)*radius))
	return points

func reset_field() -> void:
	model.clear_structure();model.current_iteration=0
	model.attraction_points=points_for_field();model.active_attraction_points=model.attraction_points.duplicate()
	model.growth_origin=Vector3.ZERO;model.origin_type=0;model.create_root_nodes()
	stopped=false;refresh()

func record() -> Array:
	var rows: Array=[]
	for n in model.all_nodes:rows.append([n.position,model.all_nodes.find(n.parent),n.depth])
	return rows

func forks() -> int:
	var result:=0
	for n in model.all_nodes:
		if n.children.size()>1: result+=1
	return result

func act(id: String) -> void:
	match id:
		"STEP":
			if not stopped:
				stopped=not model.grow_iteration()
				notice="Stopped: "+model.stop_reason if stopped else "One assignment pass, one generation. Gold arrows show the next decision."
		"FIELD":
			field_index=(field_index+1)%3;reset_field();notice="New known field; same policy. Growth starts again."
		"POLICY":
			model.growth_policy="network" if model.growth_policy=="tips" else "tips"
			reset_field();notice="Same points and origin; eligible sites changed. Growth starts again."
		"HOLD":
			held_record=record().duplicate(true)
			if is_instance_valid(witness):remove_child(witness);witness.queue_free()
			witness=Node3D.new();witness.position=Vector3(-5.2,1.2,-6);witness.scale=Vector3.ONE*0.45;add_child(witness)
			_draw_record(held_record,witness,material("aaa6da"));notice="Held geometry stays while policy or field changes. Displayed at 0.45 x."
		"RESET":field_index=0;model.growth_policy="tips";reset_field();notice="Three opening requests and TIPS restored. Held geometry remains."
		"RULE":rule_visible=not rule_visible;rule_card.visible=rule_visible
	refresh()

func _sphere(at: Vector3, radius: float, mat: Material, host: Node3D) -> void:
	var mesh:=MeshInstance3D.new();var shape:=SphereMesh.new();shape.radius=radius;shape.height=radius*2;shape.radial_segments=12;shape.rings=6;mesh.mesh=shape;mesh.position=at;mesh.material_override=mat;host.add_child(mesh)

func _rod(a: Vector3,b: Vector3,r: float,mat: Material,host: Node3D) -> void:
	if a.distance_squared_to(b)<0.000001:return
	var mesh:=MeshInstance3D.new();mesh.mesh=model.create_cylinder_between(a,b,r,r);mesh.material_override=mat;host.add_child(mesh)

func _draw_record(rows: Array,host: Node3D,mat: Material) -> void:
	for row in rows:
		if row[1]>=0:_rod(rows[row[1]][0],row[0],0.045,mat,host)
	_sphere(Vector3.ZERO,0.11,mat,host)

func refresh() -> void:
	if is_instance_valid(live):remove_child(live);live.queue_free()
	live=Node3D.new();live.position=origin_display;add_child(live)
	_draw_record(record(),live,material("84d0c6"))
	for point in model.attraction_points:
		var active: bool=point in model.active_attraction_points
		_sphere(point,0.085 if active else 0.045,material("efb2d1" if active else "4f626a",active),live)
	var decision: Dictionary=model.decision_snapshot()
	# Draw one site's decision so a canopy does not become a cloud of arrows.
	var chosen: Dictionary={}
	for site in decision.sites:
		if site.count>0:chosen=site;break
	if not chosen.is_empty():
		_sphere(chosen.position,0.14,material("f1d57b",true),live)
		for a in decision.assignments:
			if a.index==chosen.index:
				_rod(a.site,a.point,0.009,material("896d80"),live)
				_rod(a.site,a.site+a.direction,0.025,material("f1d57b",true),live)
		var endpoint: Vector3=chosen.position+chosen.sum.normalized()*model.segment_length
		_rod(chosen.position,endpoint,0.06,material("f2fcff",true),live)
		_sphere(endpoint,0.065,material("f2fcff",true),live)
	readout.text="%s | %s | step %d/60\n%d/192 sites / %d forks / %d requests left\n%s" % [field_names[field_index],model.growth_policy.to_upper(),model.current_iteration,model.all_nodes.size(),forks(),model.active_attraction_points.size(),notice]

func _build_support() -> void:
	var hall: Node=get_parent()
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null:return
	var museum: Node=hall.get_parent()
	while museum!=null and not "VESTIBULE_H" in museum:museum=museum.get_parent()
	if museum==null:return
	var v: float=float(museum.get("VESTIBULE_H"))
	var points:=PackedVector3Array([Vector3(1,0,23+v),Vector3(4,0,23+v),Vector3(4,2,23+v),Vector3(1,0,25+v),Vector3(4,0,25+v),Vector3(4,2,25+v)])
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for indices in [[0,2,1],[3,4,5],[0,3,5],[0,5,2],[1,2,5],[1,5,4],[0,1,4],[0,4,3]]:
		for i in indices:st.add_vertex(points[i])
	st.generate_normals();var mesh:=MeshInstance3D.new();mesh.name="ObservationRamp";mesh.mesh=st.commit();var mat:=material("9badb3");mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.material_override=mat;hall.add_child(mesh)
	var body:=StaticBody3D.new();body.name="ObservationRampSupport";hall.add_child(body)
	var c:=CollisionShape3D.new();var shape:=ConvexPolygonShape3D.new();shape.points=points;c.shape=shape;body.add_child(c)
	var light:=OmniLight3D.new();light.position=Vector3(8,5,25+v);light.omni_range=14;light.light_energy=3;hall.add_child(light)

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
