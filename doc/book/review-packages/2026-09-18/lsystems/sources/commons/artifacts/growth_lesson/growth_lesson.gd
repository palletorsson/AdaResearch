extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Reveal the existing interpreter's trace, in metres, without fitting either view.
var source: Node3D
var cursor := 1
var reference: Dictionary = {}
var live_view: Node3D
var held_view: Node3D
var live_caption: Label3D
var held_caption: Label3D
var program_label: Label3D
var state_label: Label3D
var show_rule := false

func _ready() -> void:
	source=get_parent()
	_build_compact_console(["STEP","RATIO","HOLD","TREE","RESET","RULE"],"WHAT A BRANCH REMEMBERS")
	for x in [-3.0,3.0]:
		box(Vector3(x,0.175,0),Vector3(3.6,0.35,0.65),material("294447"),true)
		box(Vector3(x-2.0,4.35,0),Vector3(0.016,8,0.016),material("90aaa5",true))
		for m in range(9):
			box(Vector3(x-1.93,0.35+m,0),Vector3(0.15,0.014,0.014),material("90aaa5",true))
			if m%2==0: label(str(m)+" m",Vector3(x-2.25,0.35+m,0),0.0018)
	live_view=Node3D.new();live_view.position=Vector3(-3,0.35,0);add_child(live_view)
	held_view=Node3D.new();held_view.position=Vector3(3,0.35,0);add_child(held_view)
	live_caption=label("",Vector3(-3,0.2,0.34),0.002)
	held_caption=label("",Vector3(3,0.2,0.34),0.002)
	label("WHAT RETURNS\nWHEN A BRANCH ENDS?",Vector3(0,3.1,0.2),0.002)
	label("Both readings use metres / no fitting",Vector3(0,2.7,0.2),0.0012)
	program_label=label("",Vector3(0,2.05,0.2),0.0018);program_label.font_size=32
	state_label=label("",Vector3(0,2.38,0.2),0.0016);state_label.font_size=32
	source._mesh_instance.hide();source.get_node("Base").hide();source._info_label.hide()
	source.tree_changed.connect(refresh)
	begin()
	_stage_hall.call_deferred()

func begin() -> void:
	show_rule=false;cursor=1
	source.iterations=1;source.base_length=0.8;source.base_angle=40.0
	source.angle_variation=0.0;source.length_decay=0.72
	source._generate()
	reference=_snapshot();refresh()

func _snapshot() -> Dictionary:
	if source.trace_frames.is_empty():return {}
	var index: int=clampi(cursor,0,source.trace_frames.size()-1)
	var frame: Dictionary=source.trace_frames[index].duplicate(true)
	return {"frame":frame,"segments":source.tree_segments.slice(0,frame.segments).duplicate(true),"ratio":source.length_decay,"cursor":index,"sentence":source._current_string,"generation":source.effective_iterations}

func act(id: String) -> void:
	show_rule=false
	match id:
		"RESET":begin();return
		"STEP":cursor=mini(cursor+1,source.trace_frames.size()-1)
		"RATIO":
			var ratios: Array=[0.45,0.72,1.0,1.15]
			source.length_decay=ratios[(ratios.find(float(source.length_decay))+1)%ratios.size()]
			source.reinterpret()
		"HOLD":reference=_snapshot()
		"TREE":
			source.iterations=2 if source.iterations==1 else 1
			source._generate();cursor=source.trace_frames.size()-1
		"RULE":show_rule=true
	refresh()

func _draw(host: Node3D,reading: Dictionary,tint: String) -> void:
	for child in host.get_children():host.remove_child(child);child.queue_free()
	if reading.is_empty():return
	var segments: Array=reading.segments
	if not segments.is_empty():
		var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
		var tube:=CylinderMesh.new();tube.top_radius=0.018;tube.bottom_radius=0.018;tube.height=1;tube.radial_segments=8
		mm.mesh=tube;mm.instance_count=segments.size()
		for i in segments.size():
			var a: Vector3=segments[i][0];var b: Vector3=segments[i][1];var direction: Vector3=(b-a).normalized()
			mm.set_instance_transform(i,Transform3D(Basis(Quaternion(Vector3.UP,direction)).scaled(Vector3(1,a.distance_to(b),1)),(a+b)*0.5))
		var mesh:=MultiMeshInstance3D.new();mesh.multimesh=mm;mesh.material_override=material(tint,true);host.add_child(mesh)
	var marker:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=0.065;sphere.height=0.13;marker.mesh=sphere
	marker.position=reading.frame.pos;marker.material_override=material("fff2c9",true);host.add_child(marker)

func refresh() -> void:
	if live_view==null:return
	var live:=_snapshot()
	if live.is_empty():return
	_draw(live_view,live,"70d5c2");_draw(held_view,reference,"edafd3")
	live_caption.text="LIVE / ratio %.2f / %d segments"%[live.ratio,live.segments.size()]
	if not reference.is_empty():held_caption.text="HELD / ratio %.2f / %d segments"%[reference.ratio,reference.segments.size()]
	var frame: Dictionary=live.frame
	var event: String={"[":"SAVE / enter branch","]":"RESTORE / return to fork","+":"TURN","-":"TURN","F":"DRAW"}.get(frame.symbol,frame.symbol)
	state_label.text=event+"\nnext length %.3f m / stack %d"%[frame.length,frame.stack_depth]
	var sentence: String=live.sentence
	# The complete 11-symbol sentence remains readable; the longer tree shows a
	# declared local window around the interpreter instead of a false full transcript.
	var start: int=0 if sentence.length()<=11 else maxi(0,live.cursor-6)
	var finish: int=mini(sentence.length(),start+11)
	program_label.text=("... " if start>0 else "")+sentence.substr(start,finish-start)+(" ..." if finish<sentence.length() else "")+"\nsymbol %d / %d : %s"%[live.cursor,sentence.length(),frame.symbol]
	if show_rule:
		readout.text="[ save state; length *= ratio\n] restore state and length"
	else:
		readout.text="gen %d / read %d of %d symbols\nlength %.3f m / ratio %.2f / stack %d"%[live.generation,live.cursor,sentence.length(),frame.length,live.ratio,frame.stack_depth]

func _stage_hall() -> void:
	var hall: Node=source
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null or str(hall.get_meta("em_map"))!="LSystems_Growth":return
	for light in hall.find_children("*","DirectionalLight3D",true,false):light.hide()
	var lamps:=Node3D.new();lamps.name="GrowthStudyLights";hall.add_child(lamps)
	for at in [Vector3(5,5,10),Vector3(16,5,10),Vector3(10.5,5,25)]:
		var light:=OmniLight3D.new();light.position=at;light.omni_range=15;light.light_energy=2.0;light.light_color=Color("e4f2e6");lamps.add_child(light)
	# Retained studies keep their algorithms and clocks. Shrink only oversized
	# captions; standalone cameras must not take the visitor's view.
	for camera in hall.find_children("*","Camera3D",true,false):camera.current=false
	for caption in hall.find_children("*","Label3D",true,false):
		if source.is_ancestor_of(caption):continue
		if caption.pixel_size>0.002:caption.pixel_size=0.002

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
