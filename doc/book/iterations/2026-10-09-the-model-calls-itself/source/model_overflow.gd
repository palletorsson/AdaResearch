extends Node3D
## Bounded model-level fault studies. No native stack/memory corruption.
## The call stack is explicit data; mesh addressing always stays in bounds.
const Source = preload("res://commons/artifacts/architecture_spine/architecture_spine.gd")
const Console = preload("res://commons/artifacts/model_overflow/overflow_console.gd")
const MeshTools = preload("res://commons/artifacts/architecture_variations/architecture_variations.gd")
const TITLES := ["ONE SOURCE / THREE FAILURES", "A CALL THAT NEVER RETURNS", "THE FORGOTTEN RESTORE", "NEW DATA / OLD FACES"]
const MAX_STEPS := 32
var mode := 1
var steps := 0
var capacity := 16
var playing := false
var elapsed := 0.0
var syncing := false
var panel: Node3D
var body: Node3D
var reference: Node3D
var frame_display: Node3D
var caption: Label3D
var bay_mesh: ArrayMesh
var original_vertices := PackedVector3Array()
var original_indices := PackedInt32Array()
var buffer_vertices := PackedVector3Array()
var call_stack: Array[Transform3D] = []
var poses: Array[Transform3D] = []
var rendered: Array[MeshInstance3D] = []
var refused := 0
var status := ""
var active_vertices := 0
var last_write := -1
var version := 0

func _ready() -> void:
	panel=Console.new();panel.position=Vector3(0,0,11);add_child(panel)
	for i in 4:panel.buttons[["SOURCE","CALLS","LEAK","WRAP"][i]].pressed.connect(select_mode.bind(i))
	panel.buttons["STEP"].pressed.connect(advance)
	panel.buttons["PLAY / HOLD"].pressed.connect(toggle_play)
	panel.buttons["RESET"].pressed.connect(reset)
	panel.step_dial.hinge_moved.connect(read_controls)
	panel.limit_dial.hinge_moved.connect(read_controls)
	body=Node3D.new();body.name="ModelStudy";body.position=Vector3(0,.12,-2);add_child(body)
	reference=Node3D.new();reference.name="UnchangedSource";reference.position=Vector3(-5,.75,8.0);add_child(reference)
	frame_display=Node3D.new();frame_display.position=Vector3(3.4,.15,8);add_child(frame_display)
	make_bay();make_tower()
	var ref_bay:=MeshInstance3D.new();ref_bay.mesh=bay_mesh;ref_bay.scale=Vector3.ONE*.45;reference.add_child(ref_bay)
	panel.box(self,Vector3(-4.75,.35,8),Vector3(2.1,.7,1.8),Color("243238"),true)
	panel.text(self,"SOURCE / KEPT",Vector3(-4.75,.40,8.92),.0013,Color("eee5d5"))
	caption=panel.text(self,"",Vector3(0,2.9,8.7),.0021,Color("283a3b"))
	select_mode(1)
	set_steps(6)

func make_bay() -> void:
	# Reuse the real earlier column/roof/floor recipe without subdividing it.
	var donor=Source.new();donor.panel=Console.new()
	var holder:=Node3D.new();donor.build_bay(holder,0)
	var groups:Dictionary={};var materials:Dictionary={}
	for part in donor.original_meshes:
		var key:String=part.material_override.albedo_color.to_html()
		if not groups.has(key):groups[key]=PackedVector3Array();materials[key]=part.material_override
		var arrays:Array=part.mesh.get_mesh_arrays()
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		for i in arrays[Mesh.ARRAY_INDEX]:groups[key].append(part.transform*vertices[i])
	bay_mesh=ArrayMesh.new()
	var helper=MeshTools.new()
	for key in groups:helper.append_surface(bay_mesh,groups[key],materials[key])
	helper.free();holder.free();donor.panel.free();donor.free()

func make_tower() -> void:
	# Address study: twelve vertices per ring, nineteen rings, one indexed skin.
	for ring in 19:
		for side in 12:
			var angle:=side*TAU/12.0
			original_vertices.append(Vector3(cos(angle)*2.8,ring*.42,sin(angle)*2.8))
	for ring in 18:
		for side in 12:
			var a:=ring*12+side;var b:=ring*12+(side+1)%12
			original_indices.append_array(PackedInt32Array([a,a+12,b,b,a+12,b+12]))

func next_call(parent:Transform3D) -> Transform3D:
	var turn:=Basis(Vector3.UP,deg_to_rad(16))*Basis(Vector3.BACK,deg_to_rad(11))
	return parent*Transform3D(turn.scaled_local(Vector3.ONE*1.025),Vector3(1.32,.22,0))

func sibling(i:int) -> Transform3D:
	var a:=i*TAU/16.0
	return Transform3D(Basis(Vector3.UP,-a).scaled_local(Vector3.ONE*1.035),Vector3(cos(a)*4.5,0,sin(a)*4.5))

func mesh_at(mesh:Mesh,pose:Transform3D,override:Material=null) -> void:
	var instance:=MeshInstance3D.new();instance.mesh=mesh;instance.transform=pose
	instance.material_override=override;body.add_child(instance);rendered.append(instance)

func rebuild() -> void:
	for item in body.get_children():item.free()
	for item in frame_display.get_children():item.free()
	rendered.clear();poses.clear();call_stack.clear();refused=0;last_write=-1
	buffer_vertices=original_vertices.duplicate()
	var pink:Material=panel.material(Color("d66490"))
	if mode==0:
		for i in 16:poses.append(sibling(i))
		status="16 SIBLINGS / EACH STARTS AT ROOT"
	elif mode==1:
		var pose:=Transform3D(Basis.IDENTITY,Vector3(-5,0,0))
		for i in steps:
			if call_stack.size()>=capacity:
				refused=1;break
			call_stack.append(pose);poses.append(pose);pose=next_call(pose)
		status="%d PENDING / LIMIT %d"%[call_stack.size(),capacity]
		if refused:
			status+="\nNEXT CALL REFUSED / MODEL RETAINED"
			mesh_at(bay_mesh,pose,pink)
			var sign=panel.text(body,"CALL %d REFUSED"%(capacity+1),pose*Vector3(.6,3,0),.002,Color("9c315f"));sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	elif mode==2:
		var current:=Transform3D.IDENTITY
		for i in mini(steps,16):
			# Intended: save root, emit local sibling, restore root.
			# Fault: save the current transform but never restore it.
			if call_stack.size()>=capacity:refused=1;break
			call_stack.append(current);current=current*sibling(i);poses.append(current)
		status="%d SAVES / 0 RESTORES"%call_stack.size()
		if refused:status+="\nSTACK LIMIT / NEXT SIBLING REFUSED"
	else:
		# An explicit wrap policy simulates reuse of the first model's addresses.
		# Existing triangles retain indices into these overwritten slots.
		var writes:=mini(steps*7,original_vertices.size())
		for i in writes:
			var address: int=(original_vertices.size()+i)%original_vertices.size()
			var a:=i*TAU/12.0
			buffer_vertices[address]=Vector3(7+cos(a)*2.8,3+float(i/12)*.42,sin(a)*2.8-3)
			last_write=address
		var mesh:=ArrayMesh.new();var vertices:=PackedVector3Array()
		for index in original_indices:vertices.append(buffer_vertices[index])
		var helper=MeshTools.new();var mat=panel.material(Color("d1b99d"));mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		helper.append_surface(mesh,vertices,mat);helper.free();mesh_at(mesh,Transform3D.IDENTITY)
		status="%d / 228 SLOTS OVERWRITTEN\n%s"%[writes,"SAME TRIANGLES / WRONG POSITIONS" if writes>0 else "UNCHANGED BUFFER / CAPACITY FIXED"]
		# A thin original cage remains as a location witness, not part of the mesh.
		for ring in [0,18]:
			for side in 12:
				rod(original_vertices[ring*12+side],original_vertices[ring*12+(side+1)%12],.018,Color("57646a"))
		if last_write>=0:
			var sm:=SphereMesh.new();sm.radius=.13;sm.height=.26
			mesh_at(sm,Transform3D(Basis.IDENTITY,buffer_vertices[last_write]),pink)
	for pose in poses:mesh_at(bay_mesh,pose)
	active_vertices=0
	for item in rendered:
		for s in item.mesh.get_surface_count():active_vertices+=item.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX].size()
	var frames:=call_stack.size() if mode!=3 else mini(steps,32)
	for i in (capacity if mode!=3 else 32):
		panel.box(frame_display,Vector3(0,i*.105,0),Vector3(.72,.072,.42),Color("d66490") if i<frames else Color("9ea8a5"))
	panel.text(frame_display,"PENDING FRAMES" if mode!=3 else "WRAPPED WRITES",Vector3(0,-.08,.24),.0009,Color("27383a"))
	caption.text=TITLES[mode]+"\n"+status
	panel.screen_title.text=TITLES[mode]
	panel.screen_state.text=status
	version+=1

func rod(a:Vector3,b:Vector3,r:float,colour:Color) -> void:
	var cylinder:=CylinderMesh.new();cylinder.top_radius=r;cylinder.bottom_radius=r;cylinder.height=a.distance_to(b);cylinder.radial_segments=8
	var up:Vector3=(b-a).normalized();var right:=up.cross(Vector3.FORWARD).normalized()
	if right.length()<.1:right=up.cross(Vector3.RIGHT).normalized()
	mesh_at(cylinder,Transform3D(Basis(right,up,right.cross(up)),(a+b)*.5),panel.material(colour))

func select_mode(value:int) -> void:
	mode=clampi(value,0,3);capacity=16;steps=0;playing=false
	if mode==0:steps=16
	sync_controls();rebuild()

func set_steps(value:int) -> void:
	steps=clampi(value,0,MAX_STEPS);sync_controls();rebuild()

func set_capacity(value:int) -> void:
	capacity=clampi(value,4,24);sync_controls();rebuild()

func advance() -> void:
	if refused>0 or steps>=MAX_STEPS or (mode==2 and steps>=16):playing=false;sync_controls();return
	set_steps(steps+1)

func toggle_play() -> void:
	playing=not playing;elapsed=0;sync_controls()

func reset() -> void:
	playing=false;set_steps(0)

func sync_controls() -> void:
	syncing=true
	panel.step_dial.set_normalized_value(steps/32.0)
	panel.limit_dial.set_normalized_value((capacity-4)/20.0)
	for i in 4:panel.buttons[["SOURCE","CALLS","LEAK","WRAP"][i]].set_selected(i==mode)
	panel.buttons["PLAY / HOLD"].set_selected(playing)
	syncing=false

func read_controls(_value:float) -> void:
	if syncing:return
	steps=clampi(roundi(panel.step_dial.get_normalized_value()*32),0,32)
	capacity=clampi(4+roundi(panel.limit_dial.get_normalized_value()*20),4,24)
	playing=false;rebuild()

func _process(delta:float) -> void:
	if not playing:return
	elapsed+=delta
	if elapsed>=.35:elapsed=0;advance()

func _unhandled_key_input(event:InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	var key:int=event.physical_keycode
	if key>=KEY_1 and key<=KEY_4:select_mode(key-KEY_1)
	elif key==KEY_SPACE:toggle_play()
	elif key==KEY_ENTER:advance()
	elif key==KEY_R:reset()
	elif key==KEY_LEFT or key==KEY_RIGHT:set_steps(steps+(-1 if key==KEY_LEFT else 1))
	elif key==KEY_UP or key==KEY_DOWN:set_capacity(capacity+(1 if key==KEY_UP else -1))

func apply_grid_config(_config:Dictionary) -> void:
	pass
