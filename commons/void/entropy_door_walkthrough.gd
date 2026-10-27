extends "res://commons/artifacts/ordinary_entropies/door_study.gd"
## Three spatial samples of the original rules, driven by one original clock.
## The extra leaves are later states of the same two starts, not extra draws.
const Fittings=preload("res://commons/void/entropies_staging.gd")
const Supply=preload("res://commons/void/hardware_supply.gd")
const OFFSETS=[0,4,8]
const LEAF_WIDTH=1.0
const PAIR_X=1.75
var frames: Array[Dictionary]=[]
var part_defaults: Dictionary={}
var installed:=false

func _ready() -> void:
	kind=3;automatic=false
	for row in 3:build_frame(row)
	build_console()
	for child in get_children():
		if child is Node3D:
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[0,0,0],"label":str(child.get_meta("editor_label",child.name))}
	advance_doors(0)
	set_process(false)

func build_frame(row: int) -> void:
	var frame:=Node3D.new();frame.name="Frame%02d"%(row+1)
	frame.position.z=(2-row)*1.7;add_child(frame)
	frame.set_meta("editor_label","Frame %02d / step n+%d"%[row+1,OFFSETS[row]])
	# Two narrower original door pairs flank a 2.21 m unobstructed opening.
	var pairs: Array[Node3D]=[]
	var records: Array[Label3D]=[]
	for rule in 2:
		var door:=Encounter.new();door.kind=3;door.setting=rule
		door.controls_enabled=false;door.door_width=LEAF_WIDTH
		door.name="Halving" if rule==0 else "Doubling"
		door.position.x=PAIR_X if rule==0 else -PAIR_X
		frame.add_child(door);pairs.append(door)
		if row==0:versions.append(door)
		Objects.box(frame,Vector3(door.position.x,2.47,0),Vector3(1.29,.25,.18),Color("e8e4d8"),true)
		Objects.ink(frame,"HALVE / x : 2" if rule==0 else "DOUBLE / wrap",Vector3(door.position.x,2.47,.10),25,.0025)
		Objects.box(frame,Vector3(door.position.x,.30,.22),Vector3(1.25,.48,.045),Color("e8e4d8"))
		var record:=Objects.ink(frame,"",Vector3(door.position.x,.30,.25),22,.0014)
		records.append(record)
	Objects.box(frame,Vector3(0,2.47,0),Vector3(2.21,.25,.18),Color("343b3d"),true)
	var headings: Array[Label3D]=[]
	for side in [1,-1]:
		var title:=Objects.ink(frame,"",Vector3(0,2.47,side*.101),32,.003)
		title.modulate=Color("f1e9db");title.rotation.y=0 if side==1 else PI
		headings.append(title)
	# Small shoes outside the opening; no threshold across the walking route.
	for x in [-2.335,-1.165,1.165,2.335]:
		Objects.box(frame,Vector3(x,.025,0),Vector3(.20,.05,.28),Objects.DARK,true)
	frames.append({"node":frame,"pairs":pairs,"records":records,"titles":headings,"offset":OFFSETS[row]})

func build_console() -> void:
	var console_root:=Node3D.new();console_root.name="Console"
	console_root.set_meta("editor_label","Shared STEP / GAP / RESET console")
	console_root.position=Vector3(3.5,0,1.7);add_child(console_root)
	wall_text=WallText.new();wall_text.backing_enabled=false
	wall_text.heading="4 / WALK THROUGH THE CALCULATION"
	wall_text.explanation="Frames show the SAME starts at n, n+4 and n+8.\nSTEP advances n; GAP changes the starting difference.\nRESET returns the three views to steps 0, 4 and 8.\nSolid starts at 0.8; translucent at 0.8 + gap.\nDoor angle = 90 degrees x value. LOW < 0.5; HIGH >= 0.5.\nNo new random draw occurs when a door moves."
	wall_text.position=Vector3(0,1.92,0);console_root.add_child(wall_text)
	var face:=Node3D.new();face.name="SharedDoorControls";face.position=Vector3(0,1.08,.025)
	console_root.add_child(face)
	Objects.box(face,Vector3.ZERO,Vector3(1.6,.36,.05),Color("e8e4d8"),true)
	panel_state=Objects.ink(face,"",Vector3(0,.13,.035),25,.0014)
	var names=["STEP","RESET","GAP -","GAP +"]
	var actions=[step_once,reset_study,change_gap.bind(-1),change_gap.bind(1)]
	for i in names.size():buttons[names[i]]=Controls.button(face,Vector3((i-1.5)*.38,-.025,.04),names[i],actions[i],i==0)
	Objects.box(console_root,Vector3(0,1.39,-.10),Vector3(1.72,.85,.12),Objects.DARK,true)

func trajectory(at_step: int, expanding: bool, ghost: bool=false) -> Array:
	var x: float=START+(GAPS[gap_index] if ghost else 0.0)
	var values: Array=[x]
	for i in at_step:
		x=Model.door_step(x,expanding);values.append(x)
	return values

func advance_doors(step: int) -> void:
	step_index=clampi(step,0,MAX_STEP);last_step=step_index
	for row in frames:
		if not is_instance_valid(row.node):continue
		var at_step: int=step_index+row.offset
		for title in row.titles:title.text="%02d / STEP %d"%[OFFSETS.find(row.offset)+1,at_step]
		for rule in 2:
			var solid:=trajectory(at_step,rule==1)
			var ghost:=trajectory(at_step,rule==1,true)
			row.pairs[rule].hinges[0].rotation.y=-PI/2*float(solid[-1])
			row.pairs[rule].hinges[1].rotation.y=-PI/2*float(ghost[-1])
			row.records[rule].text="STEP %d / value gap %.6f\nsolid %s\nghost %s"%[at_step,absf(solid[-1]-ghost[-1]),symbols(solid),symbols(ghost)]
	if is_instance_valid(panel_state):panel_state.text="n %d / %d   START GAP %s"%[step_index,MAX_STEP,GAP_NAMES[gap_index]]
	if is_instance_valid(wall_text):
		var lines: Array[String]=["H(record) across 1024 equal starting bins:"]
		for offset in OFFSETS:
			var n: int=step_index+offset+1
			lines.append("Step %d: halve %.1f / double %.1f bits"%[n-1,Model.word_entropy(n,false),Model.word_entropy(n,true)])
		lines.append("Visible pairs are examples, not that ensemble.")
		lines.append("Finite starts cap records at 10 bits; pairs can rejoin.")
		wall_text.reading.text="\n".join(lines)

func finish_installation() -> void:
	if installed:return
	installed=true
	if is_instance_valid(wall_text):Fittings.mount_reading(wall_text)
	var console_root:=get_node_or_null("Console") as Node3D
	if console_root!=null:Fittings.case_controls(console_root.get_node("SharedDoorControls"),Vector2(1.6,.36),false)
	# Each frame is a movable assembly, with its cable at the outside jamb.
	for row in frames:
		if not is_instance_valid(row.node):continue
		Supply.connect_unit(row.node,Vector3(2.39,2.60,0))
	for key in part_defaults:
		var part:=get_node_or_null(NodePath(key)) as Node3D
		if part==null:continue
		var b:=AABB()
		var first:=true
		for mesh in part.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh==null:continue
			var local: AABB=(part.global_transform.affine_inverse()*mesh.global_transform)*mesh.mesh.get_aabb()
			b=local if first else b.merge(local);first=false
		part_defaults[key]["bounds"]=[b.position.x,b.position.y,b.position.z,b.size.x,b.size.y,b.size.z]

func apply_grid_config(config: Dictionary) -> void:
	if config.has("only_parts"):
		for key in part_defaults.keys():
			if key not in config.only_parts:
				get_node(NodePath(key)).free();part_defaults.erase(key)
	for key in config.get("parts",{}):
		var part:=get_node_or_null(NodePath(key)) as Node3D
		if part==null or not part_defaults.has(key):continue
		var pose: Dictionary=config.parts[key]
		var p: Array=pose.get("position",part_defaults[key].position)
		var r: Array=pose.get("rotation",part_defaults[key].rotation)
		part.position=Vector3(p[0],p[1],p[2]);part.rotation_degrees=Vector3(r[0],r[1],r[2])
