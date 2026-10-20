extends Node3D
## Three declared interventions on one immutable eight-bay source.
## Precision uses a genuine float32 encode/decode. Time skew and feedback are
## deliberate data operations, not renderer races or an unstable physics engine.
const BayMaker = preload("res://commons/artifacts/model_overflow/model_overflow.gd")
const MeshTools = preload("res://commons/artifacts/architecture_variations/architecture_variations.gd")
const Console = preload("res://commons/artifacts/model_disagreement/disagreement_console.gd")
const TITLES := ["THE RETAINED SOURCE", "A POSITION TOO FAR AWAY", "EIGHT PARTS / EIGHT TIMES", "THE OUTPUT RETURNS"]
const COUNT:=8
const MAX_STEPS:=32
var panel:Node3D
var body:Node3D
var reference:Node3D
var caption:Label3D
var original:Array=[]
var owners:Array=[]
var materials:Array[Material]=[]
var output:Array=[]
var rendered:Array[MeshInstance3D]=[]
var samples:PackedFloat64Array=[]
var mode:=0
var amount:=.65
var steps:=0
var control:=false
var playing:=false
var syncing:=false
var elapsed:=0.0
var distance_origin:=0.0
var error_max:=0.0
var collapsed:=0
var executed_passes:=0
var limited:=false
var status:=""
var version:=0
var packed:=PackedByteArray()

func _ready() -> void:
	packed.resize(4)
	panel=Console.new();panel.position=Vector3(0,0,11);add_child(panel)
	for i in 4:panel.buttons[["SOURCE","PRECISION","CLOCKS","FEEDBACK"][i]].pressed.connect(select_mode.bind(i))
	panel.buttons["STEP"].pressed.connect(advance)
	panel.buttons["PLAY / HOLD"].pressed.connect(toggle_play)
	panel.buttons["CONTROL"].pressed.connect(toggle_control)
	panel.buttons["RESET"].pressed.connect(reset)
	panel.strength_dial.hinge_moved.connect(read_controls);panel.step_dial.hinge_moved.connect(read_controls)
	body=Node3D.new();body.name="ChangedModel";body.position=Vector3(0,.14,-3);add_child(body)
	reference=Node3D.new();reference.name="KeptSource";reference.position=Vector3(-5,.8,8);reference.scale=Vector3.ONE*.27;add_child(reference)
	make_source()
	var helper=MeshTools.new();var mesh:=ArrayMesh.new()
	for i in original.size():helper.append_surface(mesh,original[i],materials[i])
	var instance:=MeshInstance3D.new();instance.mesh=mesh;reference.add_child(instance);helper.free()
	panel.box(self,Vector3(-5,.35,8),Vector3(3.5,.7,1.5),Color("24343a"),true)
	panel.text(self,"EIGHT BAYS / SOURCE KEPT",Vector3(-5,.42,8.76),.001,Color("efe6d8"))
	caption=panel.text(self,"",Vector3(0,2.9,8.5),.0019,Color("28373a"))
	select_mode(3)

func make_source() -> void:
	var donor=BayMaker.new();donor.make_bay()
	for s in donor.bay_mesh.get_surface_count():
		var vertices:=PackedVector3Array();var ids:=PackedInt32Array()
		var raw:PackedVector3Array=donor.bay_mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
		for bay in COUNT:
			for p in raw:vertices.append(p+Vector3((bay-4)*1.2,0,0));ids.append(bay)
		original.append(vertices);owners.append(ids);materials.append(donor.bay_mesh.surface_get_material(s))
	donor.free()

func float32(value:float) -> float:
	packed.encode_float(0,value)
	return packed.decode_float(0)

func remote_coordinate(value:float,origin:float) -> float:
	return float32(origin+value)-origin

func pose_at(t:float) -> Transform3D:
	var b:=Basis(Vector3.UP,sin(t*.7)*.8)*Basis(Vector3.BACK,sin(t*.9)*.32)
	return Transform3D(b,Vector3(0,2.5+sin(t)*1.8,cos(t*.6)*2))

func sample_time(bay:int,t:float) -> float:
	return t-amount*float(bay)/float(COUNT-1)*4.0

func deform(p:Vector3) -> Vector3:
	var h:=maxf(p.y,0)
	return Vector3(p.x+.03*h*h*amount,p.y+h*.09*amount,p.z+.18*sin(p.x*.7)*minf(h/2.6,3)*amount)

func rebuild() -> void:
	for item in body.get_children():item.free()
	rendered.clear();output=original.duplicate(true);samples.clear()
	collapsed=0;error_max=0;executed_passes=0;limited=false;distance_origin=0
	var t:=steps*.2
	if mode==1:
		distance_origin=0.0 if amount<.001 else pow(2,18+roundi(amount*7))
		var shift:=sin(t)*.8
		for s in output.size():
			for i in output[s].size():
				var p:Vector3=original[s][i]+Vector3(shift,0,0)
				var q:=p if control else Vector3(remote_coordinate(p.x,distance_origin),remote_coordinate(p.y,distance_origin),remote_coordinate(p.z,distance_origin))
				output[s][i]=q;error_max=maxf(error_max,p.distance_to(q))
	elif mode==2:
		for bay in COUNT:samples.append(t if control else sample_time(bay,t))
		for s in output.size():
			for i in output[s].size():output[s][i]=pose_at(samples[owners[s][i]])*original[s][i]
	elif mode==3:
		var passes:=mini(steps,1) if control else steps
		for iteration in passes:
			var next:Array=output.duplicate(true);var accept:=true
			for s in next.size():
				for i in next[s].size():
					var p:Vector3=deform(output[s][i]);next[s][i]=p
					accept=accept and p.is_finite() and p.length()<64
			if not accept:limited=true;break
			output=next;executed_passes+=1
	var mesh:=ArrayMesh.new();var helper=MeshTools.new()
	for s in output.size():
		for i in range(0,output[s].size(),3):
			var a:Vector3=output[s][i+1]-output[s][i];var b:Vector3=output[s][i+2]-output[s][i]
			if a.cross(b).length_squared()<.000000000001:collapsed+=1
		helper.append_surface(mesh,output[s],materials[s])
	helper.free()
	var instance:=MeshInstance3D.new();instance.mesh=mesh;body.add_child(instance);rendered.append(instance)
	match mode:
		0:status="8 BAYS / ORIGINAL POSITIONS"
		1:status="ORIGIN %.0f / FLOAT32 ROUNDTRIP\nMAX ERROR %.3fm / %d COLLAPSED FACES"%[distance_origin,error_max,collapsed]
		2:status="TIME %.2fs / AGE SPREAD %.2fs\n%s"%[t,absf(samples[0]-samples[-1]),"ONE SHARED TIME" if control else "PARTS USE DIFFERENT SAVED TIMES"]
		3:status="%d DEFORMATION PASSES\n%s"%[executed_passes,"64m LIMIT: LAST COMPLETE STATE KEPT" if limited else ("READ ORIGINAL EACH TIME" if control else "EACH OUTPUT BECOMES NEXT INPUT")]
	if control:status="CONTROL\n"+status
	panel.screen_title.text=TITLES[mode];panel.screen_state.text=status
	caption.text=TITLES[mode]+"\n"+status;version+=1

func select_mode(value:int) -> void:
	mode=clampi(value,0,3);control=false;playing=false;amount=.65;steps=0
	if mode==1:amount=.72;steps=6
	if mode==2:amount=.85;steps=18
	if mode==3:steps=24
	sync_controls();rebuild()

func set_steps(value:int) -> void:
	steps=clampi(value,0,MAX_STEPS);sync_controls();rebuild()

func set_amount(value:float) -> void:
	amount=clampf(value,0,1);sync_controls();rebuild()

func advance() -> void:
	if steps>=MAX_STEPS or limited:playing=false;sync_controls();return
	set_steps(steps+1)

func toggle_control() -> void:
	control=not control;sync_controls();rebuild()

func toggle_play() -> void:
	playing=not playing;elapsed=0;sync_controls()

func reset() -> void:
	playing=false;control=false;set_steps(0)

func sync_controls() -> void:
	syncing=true
	panel.strength_dial.set_normalized_value(amount);panel.step_dial.set_normalized_value(steps/32.0)
	for i in 4:panel.buttons[["SOURCE","PRECISION","CLOCKS","FEEDBACK"][i]].set_selected(mode==i)
	panel.buttons["CONTROL"].set_selected(control);panel.buttons["PLAY / HOLD"].set_selected(playing)
	syncing=false

func read_controls(_value:float) -> void:
	if syncing:return
	amount=panel.strength_dial.get_normalized_value();steps=roundi(panel.step_dial.get_normalized_value()*32)
	playing=false;rebuild()

func _process(delta:float) -> void:
	if not playing:return
	elapsed+=delta
	if elapsed>=.20:elapsed=0;advance()

func _unhandled_key_input(event:InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	var key:int=event.physical_keycode
	if key>=KEY_1 and key<=KEY_4:select_mode(key-KEY_1)
	elif key==KEY_C:toggle_control()
	elif key==KEY_R:reset()
	elif key==KEY_SPACE:toggle_play()
	elif key==KEY_ENTER:advance()
	elif key==KEY_LEFT or key==KEY_RIGHT:set_steps(steps+(-1 if key==KEY_LEFT else 1))
	elif key==KEY_UP or key==KEY_DOWN:set_amount(amount+(.05 if key==KEY_UP else -.05))

func apply_grid_config(_config:Dictionary) -> void:
	pass
