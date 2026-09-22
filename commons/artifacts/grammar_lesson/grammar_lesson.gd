extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## A held sentence and its spatial reading. Both views use the actual editor output.
var source: Node3D
var show_rule := false
var reference: Dictionary = {}
var current_view: Node3D
var reference_view: Node3D
var current_text: Label3D
var reference_text: Label3D
var relation: Label3D

func _ready() -> void:
	source=get_parent()
	_build_compact_console(["NEXT","TURN","HOLD","PRESET","RESET","RULE"],"A SENTENCE / TWO READINGS")
	for x in [-2.2,2.2]:
		box(Vector3(x,0.5,0),Vector3(3.4,1.0,0.45),material("253b45"),true)
		var tag=label("LIVE" if x<0 else "HELD",Vector3(x,0.8,0.25),0.002)
		tag.font_size=28
	current_view=Node3D.new();current_view.position=Vector3(-2.2,1.35,0);add_child(current_view)
	reference_view=Node3D.new();reference_view.position=Vector3(2.2,1.35,0);add_child(reference_view)
	current_text=label("",Vector3(-2.2,0.42,0.27),0.0024);current_text.font_size=28
	reference_text=label("",Vector3(2.2,0.42,0.27),0.0024);reference_text.font_size=28
	relation=label("",Vector3(0,3.4,0),0.0032);relation.font_size=32
	label("CAN ONE SENTENCE HAVE TWO BODIES?",Vector3(0,4.45,0),0.0028)
	label("NEXT / HOLD / TURN",Vector3(0,2.92,0),0.0018)
	source.display_size=3.4
	source._mesh_instance.hide();source.get_node("Base").hide();source._info_label.hide()
	source.drawing_changed.connect(refresh)
	begin()
	_light_hall.call_deferred()

func begin() -> void:
	show_rule=false
	source.depth=1
	source.preset=0
	source.generations=0
	reference=_snapshot()
	refresh()

func _snapshot() -> Dictionary:
	return {"text":source.get_string(),"lines":source.fitted_lines.duplicate(),"angle":source.angle_degrees,"generation":source.effective_generations,"preset":source.preset}

func act(id: String) -> void:
	if id=="RESET":begin();return
	show_rule=false
	match id:
		"NEXT":source.generations=mini(source.generations+1,4)
		"TURN":
			var turns: Array=[30.0,60.0,90.0,120.0]
			source.angle_degrees=turns[(turns.find(float(source.angle_degrees))+1)%turns.size()]
		"HOLD":reference=_snapshot()
		"PRESET":
			source.preset=(source.preset+1)%7
			source.generations=0
		"RULE":show_rule=true
	refresh()

func _draw(host: Node3D,points: Array,tint: String) -> void:
	for child in host.get_children():host.remove_child(child);child.queue_free()
	if points.is_empty():return
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
	var cylinder:=CylinderMesh.new();cylinder.top_radius=0.009;cylinder.bottom_radius=0.009;cylinder.height=1;cylinder.radial_segments=6
	mm.mesh=cylinder;mm.instance_count=points.size()/2
	for i in mm.instance_count:
		var a: Vector3=points[i*2];var b: Vector3=points[i*2+1]
		var length_: float=a.distance_to(b)
		var direction: Vector3=(b-a).normalized() if length_>0.000001 else Vector3.UP
		var basis_=Basis(Quaternion(Vector3.UP,direction)).scaled(Vector3(1,length_,1))
		mm.set_instance_transform(i,Transform3D(basis_,(a+b)*0.5))
	var mesh:=MultiMeshInstance3D.new();mesh.multimesh=mm;mesh.material_override=material(tint,true);host.add_child(mesh)

func _sentence(s: String) -> String:
	var prefix:=s.substr(0,120)
	var rows:=PackedStringArray()
	for i in range(0,prefix.length(),40):rows.append(prefix.substr(i,40))
	return "\n".join(rows)+("\nfirst 120 / %d symbols"%s.length() if s.length()>120 else "")

func refresh() -> void:
	if current_view==null:return
	var live:=_snapshot()
	_draw(current_view,live.lines,"78dccc")
	current_text.text=_sentence(live.text)
	if not reference.is_empty():
		_draw(reference_view,reference.lines,"f0b3db")
		reference_text.text=_sentence(reference.text)
		relation.text=("SAME SENTENCE" if live.text==reference.text else "DIFFERENT SENTENCES")+"\nLIVE %.0f deg / HELD %.0f deg\nBoth drawings fitted to their display"%[live.angle,reference.angle]
	var names: Array=["KOCH","SIERPINSKI","DRAGON","PLANT","BUSH","FERN","BINARY TREE","CUSTOM"]
	if show_rule:
		var rules:=PackedStringArray()
		for c in source._rules:rules.append("%s -> %s"%[c,source._rules[c]])
		readout.text=" | ".join(rules)+"\nrewrite symbols; then interpret turns"
	else:
		readout.text="%s | gen %d / asked %d | %.0f deg\n%d symbols | %d drawn segments%s"%[names[source.preset],source.effective_generations,source.generations,source.angle_degrees,live.text.length(),live.lines.size()/2," | LIMIT" if source.budget_limited else ""]

func _light_hall() -> void:
	var hall: Node=source
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null or str(hall.get_meta("em_map"))!="LSystems_Grammar_Lab":return
	for light in hall.find_children("*","DirectionalLight3D",true,false):light.hide()
	var lights:=Node3D.new();lights.name="GrammarStudyLights";hall.add_child(lights)
	for at in [Vector3(5,4.5,9),Vector3(14,4.5,9),Vector3(9.5,4.5,22)]:
		var light:=OmniLight3D.new();light.position=at;light.omni_range=12;light.light_energy=2.1;light.light_color=Color("f3e6d6");lights.add_child(light)

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
