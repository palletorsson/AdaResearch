extends "res://commons/artifacts/matter_reference/computing_board.gd"
## Source state machines: only observed marble zones execute stations/counters.
var study := "call-stack"
var options: Dictionary
var settings: Dictionary = {}
var preset_name := "mirror"
var preset_index := 0
var job: Dictionary = {}
var marble: RigidBody3D
var frames: Array = []
var outputs: Array = []
var output_nodes: Array[Node3D] = []
var rack: Node3D
var index := 0
var x := 1
var done := false
var overflow := false
var errors := 0
var history: Array = []
var paused := false
func _init() -> void:super._init();kind = "functions"
func apply_grid_config(config: Dictionary) -> void:
	study = str(config.get("study",study));kind = "functions" if study=="call-stack" else "loops";var translated := config.duplicate(true);translated.kind = kind;super.apply_grid_config(translated)
func _ready() -> void:
	options = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/matter_reference/program-presets.json"))[study];settings = options.defaults.duplicate(true);settings.merge(pending.get("settings",{}),true);preset_name = str(settings.get("prog",options.presets.keys()[0]));preset_index = options.presets.keys().find(preset_name)
	super._ready();build_rack()
	set_meta("void_preview_kind","Source computing-board planks, flaps, sphere and crate templates. Original preset state machine, real Jolt zone readings. Lift and flap setting remain explicit kinematic program operations as in Three.js; no fabricated arrival events. Native controls select source presets; config.settings retains detailed settings.")
func build_controls() -> void:console(["PRESET","LESS","MORE","RUN","CLEAR"],command)
func command(id: String) -> void:
	match id:
		"PRESET":
			reset_take();preset_index = (preset_index+1)%options.presets.size();preset_name = options.presets.keys()[preset_index]
			if study=="call-stack":settings.prog = preset_name
			else:settings.merge(options.presets[preset_name],true)
			reset_take();build_rack()
		"LESS","MORE":
			reset_take();var key := "n0" if study=="call-stack" else "step" if study=="list-loop" else "limit";settings[key] = clampi(int(settings[key])+(-1 if id=="LESS" else 1),0 if key=="n0" else 1,6 if key=="n0" else 16)
		"RUN":
			if running:
				running = false;paused = true;suspend_generated();button_text("RUN","RESUME");return
			if paused:
				paused = false;resume_generated();running = true;button_text("RUN","PAUSE");return
			if done:reset_take()
			running = true;button_text("RUN","PAUSE")
			if study=="call-stack":push_frame(int(settings.n0),"main");job = {"phase":"start","t":0.0}
			else:begin_pass()
		"CLEAR":reset_take()
func reset_take() -> void:
	running = false;paused = false;done = false;overflow = false;errors = 0;history.clear();job.clear();clear_generated();marble = null;frames.clear();outputs.clear();button_text("RUN","RUN")
	for n in output_nodes:
		if is_instance_valid(n):n.queue_free()
	output_nodes.clear();index = int(settings.get("list",[]).size())-1 if settings.get("dir","")=="back" else 0;x = int(settings.get("xStart",1))
func build_rack() -> void:
	if is_instance_valid(rack):rack.free()
	rack = Node3D.new();rack.name = "SourceRack";add_child(rack)
	var items: Array = settings.get("items",settings.get("list",[settings.get("a","monitor"),settings.get("b","cone")]))
	for i in items.size():
		var object := prefab(items[i]);object.position = Vector3(4.35,2.75-i*.78,0);object.scale = Vector3.ONE*.75;rack.add_child(object)
		box_mesh(rack,Vector3(4.35,2.72-i*.78,0),Vector3(.8,.05,.65),"stop")
	remember(rack,"Original source prefab rack")
	apply_poses(pending) # Rack is created after the base scene, and rebuilt on PRESET.
func new_marble(where: String) -> void:
	if is_instance_valid(marble):generated.erase(marble);marble.queue_free()
	marble = make_dynamic(where);marble.linear_damp = float(pending.get("program_marble_drag",-log(.99)))
func remove_marble() -> void:
	if is_instance_valid(marble):generated.erase(marble);marble.queue_free()
	marble = null
func push_frame(n: int,ret: String) -> void:
	var body := make_dynamic("crate");body.set_meta("n",n);body.set_meta("ret",ret);frames.append(body)
	var size := Vector3(.72,.52,.6)
	for axis in range(3):
		for a in [-1,1]:
			for b in [-1,1]:
				var dim := Vector3.ONE*.035;dim[axis] = size[axis];var at := Vector3.ZERO;at[(axis+1)%3] = a*size[(axis+1)%3]*.5;at[(axis+2)%3] = b*size[(axis+2)%3]*.5;box_mesh(body,at,dim,"stop")
	var label := Label3D.new();label.text = "n="+str(n)+"\nreturn "+ret;label.position.z = .32;label.pixel_size = .0018;label.font_size = 30;body.add_child(label)
func top_frame() -> RigidBody3D:
	frames.sort_custom(func(a,b):return to_local(a.global_position).y>to_local(b.global_position).y);return frames[0] if not frames.is_empty() else null
func emit_item(item: Variant) -> void:
	if item==null or str(item).is_empty() or str(item)=="-":outputs.append("-");return
	var offset := outputs.size();outputs.append(item)
	if str(item) in ["0","1"]:
		var host := Node3D.new();host.position = Vector3(-2.9+(offset%12)*.3,-2.32,1.5+floori(offset/12.0)*.4);add_child(host);box_mesh(host,Vector3(0,.04,0),Vector3(.28,.08,.35),"rocker" if str(item)=="1" else "track");output_nodes.append(host)
	else:
		var object := prefab(str(item));object.position = Vector3(-2.9+(offset%8)*.75,graph.constants.get("FLOOR_Y",-2.35),1.4+floori(offset/8.0)*.85);add_child(object);output_nodes.append(object)
func function_place(n: int) -> void:
	if n>=0 and n<settings.items.size():emit_item(settings.items[n])
func begin_function() -> void:
	var f := top_frame();var spec: Dictionary = options.presets[settings.prog];var base: bool = spec.hasIf and int(f.get_meta("n"))==0
	pose(graph.flap,"flap"+str(int(base)));job = {"phase":"set","t":0.0,"base":base,"from":"entry","seen":{}}
func condition() -> bool:
	if study=="list-loop":
		if index<0 or index>=settings.list.size():return false
		var item: String = settings.list[index]
		return settings.filt=="all" or (settings.filt=="is" and item==settings.filtKind) or (settings.filt=="not" and item!=settings.filtKind)
	if settings.cond=="even":return (index&1)==0
	if settings.cond=="pairs":return (index&2)==0
	return x==1
func in_range() -> bool:return index>=0 and index<settings.list.size() if study=="list-loop" else index<int(settings.limit)
func begin_pass() -> void:
	var go := in_range();var bit := condition();pose(graph.flap,"flap"+str(int(bit)));pose(graph.trap,"trap"+str(int(go)));job = {"phase":"set","t":0.0,"go":go,"c":bit,"seen":{}}
func zone() -> String:
	if not is_instance_valid(marble):return ""
	var p := to_local(marble.global_position);var c: Dictionary = graph.constants
	if study=="call-stack":
		var xl: float = c.TUBE.cx-c.TUBE.half;var xr: float = c.TUBE.cx+c.TUBE.half
		if p.x>xl and p.x<c.TUBE.cx and p.y<c.CUP.y+.25 and p.y>c.CUP.y-.2:return "call"
		if p.y<.95 and p.y>.3 and p.x>xl and p.x<xr:return "base" if p.x>c.TUBE.cx else "before"
		if p.x>c.AFTER.x0 and p.x<c.AFTER.x1 and p.y>c.RESUME.y1-.2 and p.y<c.RESUME.y0+.4:return "after"
		if p.x<c.RET.x1+.3 and p.y<c.RET.y1+.4 and p.y>c.RET.y1-.4:return "ret"
		if p.y< -2.2 or p.x>2.9 or p.x< -2.9:return "lost"
	else:
		if p.x>c.SENS.exitX and p.y>c.EXIT.y1-.6:return "exit"
		if p.y<c.SENS.stationTop and p.y>c.SENS.stationBottom and absf(p.x)<c.TUBE.half:return "then" if p.x>0 else "else"
		if p.y<c.SENS.counterY and p.y>c.CHUTE.bottom-.1 and absf(p.x)<.3:return "counter"
		if p.x<c.SENS.liftX and p.y<c.RET.y0:return "lift"
		if p.y< -2.2:return "lost"
	return ""
func on_zone(z: String) -> void:
	history.append({"zone":z,"i":index,"t":elapsed})
	if study=="call-stack":
		var f := top_frame();var spec: Dictionary = options.presets[settings.prog];var n := int(f.get_meta("n"))
		match z:
			"before":
				if spec.before:function_place(n)
			"base":
				if spec.hasIf:function_place(0)
			"after":
				if spec.after:function_place(n)
			"call":
				remove_marble()
				if frames.size()>=8:overflow = true;running = false;done = true;return
				push_frame(n-1,"after");job.phase = "jump";job.t = 0.0
			"ret":
				remove_marble();frames.erase(f);generated.erase(f);f.queue_free();job.phase = "home" if f.get_meta("ret")=="main" else "lift";job.t = 0.0
	else:
		if z in ["then","else"]:
			var took := z=="then"
			if took!=bool(job.c):errors+=1
			if study=="list-loop":
				if took:emit_item(settings.list[index])
			elif study=="prefab-loop":
				var key: String = settings.thenOut if took else settings.elseOut;emit_item(settings.get(key,null))
			else:emit_item(settings.thenKnit if took else settings.elseKnit)
			if study!="list-loop":
				var act: String = settings.thenX if took else settings.elseX
				if act=="flip":x = 1-x
				elif act in ["0","1"]:x = int(act)
		elif z=="counter":index += int(settings.step)*(-1 if settings.dir=="back" else 1) if study=="list-loop" else 1
func _physics_process(dt: float) -> void:
	var key := "n0" if study=="call-stack" else "step" if study=="list-loop" else "limit"
	status.text = study.replace("-"," ").to_upper()+" / "+preset_name+"\n"+key+"="+str(settings[key])+" / i="+str(index)+" / x="+str(x)+" / "+("PAUSED" if paused else "OVERFLOW" if overflow else "DONE" if done else str(job.get("phase","READY")))+"\n"+JSON.stringify(outputs)
	if done:button_text("RUN","RESTART")
	if not running:return
	elapsed += dt;job.t = float(job.get("t",0))+dt
	match str(job.get("phase","")):
		"start":
			if job.t>=.8:begin_function()
		"set":
			if job.t>=.45:new_marble("entry" if study=="call-stack" else "marble");job.phase = "roll";job.t = 0.0
		"jump":
			if job.t>=.9:begin_function()
		"lift":
			if job.t>=1.1:
				if study=="call-stack":new_marble("resume");job = {"phase":"roll","from":"resume","t":0.0,"seen":{}}
				else:begin_pass()
		"home":
			if job.t>=1.4:done = true;running = false
		"roll":
			var z := zone()
			if not z.is_empty() and not job.seen.has(z):job.seen[z] = true;on_zone(z)
			if study!="call-stack":
				if z=="lift":remove_marble();job.phase = "lift";job.t = 0.0
				elif z=="exit":remove_marble();running = false;done = true
			if z=="lost" or job.t>15:
				errors+=1;new_marble(str(job.get("from","entry")) if study=="call-stack" else "marble");job.t = 0.0;job.seen = {}
