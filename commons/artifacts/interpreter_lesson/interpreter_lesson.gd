extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Same sentence and physical stride; change one interpretation at a time.
var source: Node3D
var sentence := ""
var generation := 1
var cursor := 1
var turn_angle := 25.0
var sideways := false
const STEP_LENGTH := 0.32
var readings: Array = []
var views: Array[Node3D] = []
var captions: Array[Label3D] = []
var program: Label3D
var show_rule := false

func _ready() -> void:
	source=get_parent()
	_build_compact_console(["STEP","READ F","ANGLE","TREE","RESET","RULE"],"WHEN FORWARD GOES SIDEWAYS")
	for x in [-4.5,0.0,4.5]:
		box(Vector3(x,0.325,0),Vector3(3.8,0.65,0.6),material("233e48"),true)
		# Lift all three origins equally so downward reflected branches stay visible.
		var view:=Node3D.new();view.position=Vector3(x,2.2,0);add_child(view);views.append(view)
		captions.append(label("",Vector3(x,0.42,0.32),0.0017))
		# Axes belong to the comparison frame; they are never mirrored with a reader.
		box(Vector3(x+1.5,2.19,-0.1),Vector3(3.0,0.012,0.012),material("72857e",true))
		box(Vector3(x,3.69,-0.1),Vector3(0.012,3.0,0.012),material("72857e",true))
		for m in range(1,4):
			label(str(m)+" m",Vector3(x+m,2.10,-0.06),0.0009)
		label("x",Vector3(x+3.1,2.19,0),0.0012)
		label("y",Vector3(x,5.33,0),0.0012)
	program=label("",Vector3(0,1.65,0.3),0.0013);program.font_size=30
	reset_readings()
	_stage_hall.call_deferred()

func reset_readings() -> void:
	generation=1;cursor=1;turn_angle=25.0;sideways=false;show_rule=false
	rebuild()

func rebuild() -> void:
	sentence=source._rewrite(source.axiom,source.rule_f,generation)
	readings=[source.interpret(sentence,25.0,STEP_LENGTH,false),source.interpret(sentence,turn_angle,STEP_LENGTH,false),source.interpret(sentence,25.0,STEP_LENGTH,sideways)]
	cursor=clampi(cursor,0,sentence.length())
	refresh()

func act(id: String) -> void:
	show_rule=false
	match id:
		"STEP":cursor=(cursor+1)%(sentence.length()+1)
		"READ F":sideways=not sideways;rebuild();return
		"ANGLE":
			var angles: Array=[25.0,45.0,90.0]
			turn_angle=angles[(angles.find(turn_angle)+1)%angles.size()];rebuild();return
		"TREE":
			generation=2 if generation==1 else 1;cursor=10000;rebuild();return
		"RESET":reset_readings();return
		"RULE":show_rule=true
	refresh()

func refresh() -> void:
	if views.is_empty():return
	var colors: Array=["8bcda4","efbb68","92bfe4"]
	for i in range(3):
		var reading: Dictionary=readings[i]
		var frame: Dictionary=reading.frames[cursor]
		var view: Node3D=views[i]
		for child in view.get_children():view.remove_child(child);child.queue_free()
		var count: int=frame.count
		if count>0:
			var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
			var tube:=CylinderMesh.new();tube.top_radius=0.016;tube.bottom_radius=0.016;tube.height=1;tube.radial_segments=8
			mm.mesh=tube;mm.instance_count=count
			for j in count:
				var a: Vector3=reading.segments[j][0];var b: Vector3=reading.segments[j][1]
				mm.set_instance_transform(j,Transform3D(Basis(Quaternion(Vector3.UP,(b-a).normalized())).scaled(Vector3(1,a.distance_to(b),1)),(a+b)*0.5))
			var mesh:=MultiMeshInstance3D.new();mesh.multimesh=mm;mesh.material_override=material(colors[i],true);view.add_child(mesh)
		var point:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=0.05;sphere.height=0.1
		point.mesh=sphere;point.position=frame.pos;point.material_override=material("fff1c9",true);view.add_child(point)
		var heading:=Vector3(cos(frame.heading),sin(frame.heading),0)
		var direction:=Vector3(heading.y,heading.x,0) if i==2 and sideways else heading
		# Heading and interpreted step may disagree. A short shaft marks each.
		view.add_child(source._arrow(frame.pos+Vector3(0,0,0.05),frame.pos+Vector3(0,0,0.05)+heading*0.24,0.009,material("ffc967",true)))
		view.add_child(source._arrow(frame.pos+Vector3(0,0,0.10),frame.pos+Vector3(0,0,0.10)+direction*0.32,0.008,material("ffffff",true)))
		captions[i].text=["REFERENCE / 25 degrees","TURN / %.0f degrees"%turn_angle,"READ F / "+("exchange x,y" if sideways else "forward")][i]+"\n%d segments / 0.32 m each"%count
	var current: Dictionary=readings[0].frames[cursor]
	var start: int=0 if sentence.length()<=20 else maxi(0,cursor-10)
	program.text=("... " if start>0 else "")+sentence.substr(start,20)+(" ..." if start+20<sentence.length() else "")+"\nsymbol %d / %d : %s"%[cursor,sentence.length(),current.symbol]
	if show_rule:readout.text="F: direction * 0.32 m\nREAD F: (x,y) becomes (y,x)"
	else:readout.text="gen %d / symbol %d of %d / stack %d\ngold: heading / white: next drawing direction"%[generation,cursor,sentence.length(),current.stack]

func _stage_hall() -> void:
	var hall: Node=source
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null or str(hall.get_meta("em_map"))!="LSystems_Grammars_And_Curves":return
	for light in hall.find_children("*","DirectionalLight3D",true,false):light.hide()
	for camera in hall.find_children("*","Camera3D",true,false):camera.current=false
	for caption in hall.find_children("*","Label3D",true,false):
		if not source.is_ancestor_of(caption) and caption.pixel_size>0.002:caption.pixel_size=0.002
	for at in [Vector3(4,4,10),Vector3(15,4,10),Vector3(9.5,4,24)]:
		var light:=OmniLight3D.new();light.position=at;light.omni_range=14;light.light_energy=2.0;hall.add_child(light)

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
