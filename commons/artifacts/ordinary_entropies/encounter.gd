extends Node3D
## Seven separately placeable encounters sharing objects, controls and receipts.
signal changed
const Model=preload("model.gd")
const Objects=preload("objects.gd")
const EncounterPanel=preload("encounter_panel.gd")
const TITLES=["1 / SHANNON ENTROPY","2 / BOLTZMANN ENTROPY","3 / ALGORITHMIC COMPLEXITY","4 / DYNAMICAL ENTROPY","5 / THERMODYNAMIC ENTROPY","6 / CONDITIONAL ENTROPY","7 / MIN-ENTROPY"]
@export_range(0,6) var kind:=0
@export var controls_enabled:=true
var chair_spacing:=1.02
var setting:=0
var steps:=0
var seconds:=0.0
var experiment_seed:=435
var draws:=0
var selected:=-1
var running:=false
var accumulator:=0.0
var visuals: Node3D
var readout: Label3D
var stage_index:=0
var buttons: Dictionary={}
var console: Node3D
var hinges: Array[Node3D]=[]
var steam: ShaderMaterial
var frost: ShaderMaterial
var coffee: ShaderMaterial
var cup_table_enabled:=true
var door_width:=2.17 # Installation width; museum default remains unchanged.
var mixing:=0.0
var milk_fraction:=0.25
var coffee_clock:=0.0
var glass_obscurity:=-1.0
var pointer_prefix:="user://ordinary-entropies-"
var last_saved:=""

const QUESTIONS=["Which colour comes next?","How many arrangements fit this brief?","Can a scatter have a short recipe?","Do nearby starts separate?","Where does the heat go?","What does this record leave unknown?","Which guess wins most often?"]
const PANEL_POSITIONS=[Vector3(-2.6,0,1.1),Vector3(-2.6,0,1.1),Vector3(-7.0,0,1.3),Vector3(-2.4,0,1.3),Vector3(-1.4,0,0.65),Vector3(-1.5,0,1.0),Vector3(-2.8,0,1.6)]
const STAGES=[
 ["FOUR OF EACH","REARRANGED","SEVEN TO ONE","ONE COLOUR"],
 ["SORTED","MIXED","SAME COUNT, NEW PLACES"],
 ["PATTERNS","RECIPES"],
 ["CLOSING","EXPANDING","PASSAGE OPEN"],
 ["0 SECONDS","5 SECONDS","15 SECONDS","30 SECONDS","60 SECONDS"],
 ["CLEAR / IDENTITY","FROSTED / COLOUR","OPAQUE / NO DETAIL"],
 ["BALL ID","COLOUR","LARGE BALL WEIGHTED"]
]
const TIMES=[0.0,5.0,15.0,30.0,60.0]

func _ready() -> void:
	visuals=Node3D.new();add_child(visuals)
	if not controls_enabled:
		# A comparison copy shares the model, without creating a console or visible readout.
		readout=Label3D.new();readout.visible=false;add_child(readout)
		rebuild();set_process(false);return
	var panel=EncounterPanel.new();panel.heading=TITLES[kind];panel.question=QUESTIONS[kind]
	panel.extra_action=["DRAW","","NEW SEED","STEP","PLAY","CHAIR","DRAW"][kind]
	panel.position=PANEL_POSITIONS[kind];add_child(panel);console=panel
	buttons=panel.buttons;readout=panel.readout
	panel.requested.connect(func(action: String):act.call_deferred(action))
	rebuild()

func change_stage(direction: int) -> void:
	if kind==4:
		# During playback, step to the next/previous marked time around the live time.
		var target: int=0 if direction<0 else TIMES.size()-1
		if direction>0:
			for i in TIMES.size():
				if TIMES[i]>seconds+0.001:target=i;break
			if seconds>=TIMES[-1]-0.001:target=0
		else:
			for i in range(TIMES.size()-1,-1,-1):
				if TIMES[i]<seconds-0.001:target=i;break
			if seconds<=0.001:target=TIMES.size()-1
		stage_index=target;seconds=TIMES[target]
	else:stage_index=posmod(stage_index+direction,STAGES[kind].size())
	running=false;accumulator=0.0;steps=0;draws=0
	# Keep the same chair while changing which details its record retains.
	if kind!=5:selected=-1
	match kind:
		0:
			setting=[0,0,2,1][stage_index];experiment_seed=436 if stage_index==1 else 435
		1:
			setting=0 if stage_index==0 else 1;experiment_seed=436 if stage_index==2 else 435
		2:setting=stage_index
		3,5,6:setting=stage_index
	rebuild()

func update_panel() -> void:
	if not controls_enabled:return
	var state: String="%d/%d  ·  %s" % [stage_index+1,STAGES[kind].size(),STAGES[kind][stage_index]]
	if kind==2:state+="  ·  seed %d" % experiment_seed
	if kind==3 and setting!=2:state+="  ·  step %d/8" % steps
	if kind==4:state="COOLING  ·  %.1f s" % seconds
	console.show_state(state,readout.text,running)

func infer_stage() -> int:
	match kind:
		0:return (0 if experiment_seed==435 else 1) if setting==0 else (2 if setting==2 else 3)
		1:return 0 if setting==0 else (1 if experiment_seed==435 else 2)
		4:
			var nearest:=0
			for i in TIMES.size():
				if absf(TIMES[i]-seconds)<absf(TIMES[nearest]-seconds):nearest=i
			return nearest
	return setting

func _process(delta: float) -> void:
	if not running: return
	if kind==4:
		seconds=minf(60,seconds+delta);running=seconds<60;update_motion()
	elif kind==3:
		accumulator+=delta
		if accumulator>=0.8:
			accumulator=0;steps=mini(8,steps+1);running=steps<8;update_motion()

func act(action: String) -> void:
	
	match action:
		"PREVIOUS": change_stage(-1);return
		"NEXT": change_stage(1);return
		"KEEP": keep();return
		"REPLAY": replay();return
		"PLAY","RUN / PAUSE":
			if kind==4 and seconds>=60:seconds=0;stage_index=0
			running=not running;update_motion();return
		"BALANCED","SORTED","CLEAR","BY ID","CLOSER": setting=0;steps=0;selected=-1;running=false
		"ONE COLOUR","MIXED","FROSTED","BY COLOUR","EXPAND": setting=1;steps=0;selected=-1;running=false
		"7 TO 1","OPAQUE","WEIGHT BIG": setting=2;selected=-1
		"REARRANGE","SAME k","SEED +1","NEW SEED": experiment_seed+=1
		"NEXT CHAIR","CHAIR": selected=(maxi(selected,0)+1)%8
		"SHOW RECIPE": setting=1-setting
		"STEP":
			if setting!=2:steps=(steps+1)%9
			running=false
		"HOLD OPEN": setting=2;running=false
		"RESET HEAT": seconds=0;running=false
		"+5 SECONDS": seconds=minf(60,seconds+5);running=false
		"DRAW": draw()
	stage_index=infer_stage();rebuild();changed.emit()

func draw() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=experiment_seed
	var r:=0.0
	for i in draws+1: r=rng.randf()
	draws+=1
	if kind==0: selected=mini(7,int(r*8))
	elif kind==6:
		var weights:=Model.pit_weights(setting)
		var target: float=r*(30 if setting==2 else 16)
		selected=15
		for i in 16:
			target-=float(weights[i])
			if target<0: selected=i;break

func rebuild() -> void:
	for child in visuals.get_children(): visuals.remove_child(child);child.free()
	hinges.clear();steam=null;frost=null;coffee=null
	match kind:
		0,1: build_chairs()
		2: build_descriptions()
		3: build_door()
		4: build_cup()
		5: build_glass()
		6: build_pit()
	update_motion()

func build_chairs() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=experiment_seed
	var order: Array=range(8)
	for i in range(7,0,-1):
		var j:=rng.randi_range(0,i);var tmp=order[i];order[i]=order[j];order[j]=tmp
	var pink:=4 if setting==0 else (8 if setting==1 else 7)
	for i in 8:
		var x: float=(i%4-1.5)*chair_spacing
		var p:=Vector3(x,0,(i/4-0.5)*1.15)
		var is_pink: bool=order[i]<pink
		if kind==1:
			var left: bool=i%4<2
			var local_index: int=(i/4)*2+i%2
			is_pink=left if setting==0 else (local_index==(experiment_seed%4) or local_index==(experiment_seed+1)%4)
			Objects.box(visuals,p+Vector3(0,0.009,0),Vector3(0.73,0.016,0.8),Color("d7d0be"))
		var chair=Objects.chair(visuals,p,Objects.PINK if is_pink else Objects.DARK)
		chair.set_meta("pink",is_pink)
		if kind==0 and i==selected: Objects.sphere(visuals,p+Vector3(0,1.1,0),0.055,Color("eab447"))
	if kind==1:
		Objects.box(visuals,Vector3(0,0.015,0),Vector3(0.035,0.02,2.1),Objects.PINK)
		var k:=4 if setting==0 else 2
		readout.text="%d pink on left / 4 pink + 4 black total\nOmega = %d  ·  S/kB = %.3f\nColour H stays 1 bit" % [k,Model.multiplicity(k),log(Model.multiplicity(k))]
	else:
		readout.text="%d pink / %d black  ·  H = %.3f bits\nEach chair equally likely; draw returns it" % [pink,8-pink,Model.shannon([pink,8-pink])]

func build_descriptions() -> void:
	for group in 4:
		var poses:=Model.chairs(experiment_seed,group)
		var center:=Vector3((group-1.5)*3.25,0,0)
		for i in 6:
			var chair=Objects.chair(visuals,Vector3.ZERO,Objects.PINK if i%2==0 else Objects.DARK)
			chair.transform=Transform3D(Basis(),center)*poses[i]
		var number:=Label3D.new();visuals.add_child(number);number.text=str(group+1)
		number.position=center+Vector3(0,0.025,1.1);number.rotation_degrees.x=-90
		number.font_size=40;number.pixel_size=0.003;number.outline_size=0;number.modulate=Objects.DARK
	readout.text=("1 grid  ·  2 one edit  ·  3 repeat a motif\n4 jitter(seed=%d) / shared generator" % experiment_seed) if setting==1 else "Four groups / six chairs each\nNEXT reveals their recipes"

func build_door() -> void:
	var half:=door_width/2
	for x in [-half-.085,half+.085]: Objects.box(visuals,Vector3(x,1.12,0),Vector3(0.12,2.24,0.18),Objects.DARK,true)
	Objects.box(visuals,Vector3(0,2.27,0),Vector3(door_width+.29,0.12,0.18),Objects.DARK,true)
	for i in 2:
		var hinge:=Node3D.new();visuals.add_child(hinge);hinge.position=Vector3(-half-.015,0,0)
		var leaf:=Objects.box(hinge,Vector3(half+.015,1.1,0),Vector3(door_width,2.18,0.055),Color("c39465") if i==0 else Objects.TEAL,i==0)
		if i==1:
			var mat=Objects.material(Objects.TEAL);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color.a=0.23;leaf.material_override=mat
		Objects.sphere(hinge,Vector3(door_width-.24,1.0,0.07),0.04,Objects.DARK)
		hinges.append(hinge)

func build_cup() -> void:
	if cup_table_enabled:Objects.table(visuals)
	var profile: Array[Vector2]=[Vector2(0.072,0),Vector2(0.09,0.13),Vector2(0.082,0.13),Vector2(0.065,0.016),Vector2(0,0.016),Vector2(0,0)]
	var mug:=Objects.lathe(visuals,profile,Vector3(0,0.75,0),Color("eee8dd"));mug.name="HollowCup"
	var liquid:=MeshInstance3D.new();var disc:=QuadMesh.new();disc.size=Vector2(0.158,0.158)
	liquid.mesh=disc;liquid.name="CoffeeSurface";visuals.add_child(liquid);liquid.position=Vector3(0,0.865,0);liquid.rotation.x=-PI/2
	coffee=ShaderMaterial.new();coffee.shader=preload("coffee.gdshader");coffee.set_shader_parameter("mixing",mixing);coffee.set_shader_parameter("milk_fraction",milk_fraction);coffee.set_shader_parameter("clock",coffee_clock);liquid.material_override=coffee
	var handle:=TorusMesh.new();handle.inner_radius=0.025;handle.outer_radius=0.045
	var ring:=MeshInstance3D.new();ring.mesh=handle;ring.material_override=Objects.material(Color("eee8dd"));visuals.add_child(ring);ring.position=Vector3(0.105,0.815,0);ring.rotation.x=PI/2
	steam=ShaderMaterial.new();steam.shader=preload("steam.gdshader")
	for angle in [0.0,PI/2]:
		var plume:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(0.34,0.65);plume.mesh=quad;plume.material_override=steam;visuals.add_child(plume);plume.position=Vector3(0,1.22,0);plume.rotation.y=angle

func build_glass() -> void:
	var identity:=maxi(0,selected)
	Objects.chair(visuals,Vector3(0,0,-0.3),Objects.PINK if identity<4 else Objects.DARK,identity%4)
	for x in [-0.82,0.82]: Objects.box(visuals,Vector3(x,0.85,0.6),Vector3(0.07,1.7,0.09),Objects.DARK,true)
	for y in [0.025,1.675]:Objects.box(visuals,Vector3(0,y,0.6),Vector3(1.7,0.05,0.09),Objects.DARK)
	var pane:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(1.6,1.65);pane.mesh=quad
	visuals.add_child(pane);pane.name="GlassPane";pane.position=Vector3(0,0.85,0.6)
	visuals.add_child(Objects.Kit.box_collider(Vector3(1.6,1.65,0.035),pane.position))
	frost=ShaderMaterial.new();frost.shader=preload("frost.gdshader")
	frost.set_shader_parameter("obscurity",glass_obscurity if glass_obscurity>=0 else [0.0,0.55,1.0,0.18][setting]);pane.material_override=frost
	if float(frost.get_shader_parameter("obscurity"))>=0.99:
		# A truly opaque last record must also occlude later transparent/depth effects.
		var opaque:=Objects.material(Color("c1ceca"));opaque.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		opaque.cull_mode=BaseMaterial3D.CULL_DISABLED;pane.material_override=opaque
	var colour: String="pink" if identity<4 else "black"
	var record: String="identity "+str(identity+1) if setting==0 else (colour if setting==1 else (colour+(", arms" if identity%2==1 else ", no arms") if setting==3 else "chair present"))
	readout.text="Record: %s  ·  H(X|Y) = %.1f bits\n8 equally likely identities / record channel" % [record,Model.conditional(setting)]

func build_pit() -> void:
	Objects.box(visuals,Vector3(0,0.06,0),Vector3(4,0.12,2.8),Color("d9ceba"),true)
	for x in [-2.0,2.0]: Objects.box(visuals,Vector3(x,0.27,0),Vector3(0.10,0.54,2.8),Objects.TEAL,true)
	for z in [-1.4,1.4]: Objects.box(visuals,Vector3(0,0.27,z),Vector3(4,0.54,0.10),Objects.TEAL,true)
	for i in 16:
		var angle: float=TAU*i/15.0
		var p:=Vector3(cos(angle)*1.55,0.30,sin(angle)*0.99) if i<15 else Vector3(0,0.71,0)
		Objects.sphere(visuals,p,0.17 if i<15 else 0.59,Objects.TEAL if i<15 else Objects.PINK)
		var number:=Objects.ink(visuals,str(i+1),p+Vector3(0,0,0.175 if i<15 else 0.595),32,0.0022)
		number.modulate=Color.WHITE
		if selected==i: Objects.sphere(visuals,p+Vector3(0,0.85 if i==15 else 0.30,0),0.06,Color("eab447"))
	build_tickets()
	var probabilities:=Model.pit_probabilities(setting)
	readout.text="H-min = %.3f bits  ·  p(max) = %.4f\n%s" % [Model.min_entropy(probabilities),probabilities.max(),["16 equal ID chances; size does not count","15 teal / 1 pink; record colour","Large ID weight 15 / each small ID weight 1"][setting]]

func build_tickets() -> void:
	# An equiprobable ticket is one visible chance. Repetition, not ball size,
	# gives #16 extra weight in C. Gold borders mark all tickets for one best guess.
	var tray:=Node3D.new();tray.name="ChanceTickets";visuals.add_child(tray)
	Objects.box(tray,Vector3(0,0.73,2.02),Vector3(3.8,0.06,0.98),Color("e7ddc9"),true)
	Objects.box(tray,Vector3(0,0.61,2.50),Vector3(3.8,0.24,0.04),Color("e7ddc9"))
	for x in [-1.65,1.65]:Objects.box(tray,Vector3(x,0.35,2.02),Vector3(0.07,0.7,0.07),Objects.DARK)
	var total:=30 if setting==2 else 16
	for j in total:
		var id:=mini(j,15);var pink:=id==15
		var winner:=id==15 if setting!=1 else id<15
		var cols:=10 if setting==2 else 8
		var p:=Vector3((j%cols-(cols-1)/2.0)*0.34,0.769,1.67+(j/cols)*0.29)
		if winner:Objects.box(tray,p-Vector3(0,0.008,0),Vector3(0.315,0.012,0.255),Color("d6a13c"))
		var tile:=Objects.box(tray,p,Vector3(0.28,0.014,0.22),Objects.PINK if pink else Objects.TEAL)
		tile.set_meta("ticket_id",id+1);tile.set_meta("wins",winner)
		var number:=Objects.ink(tray,str(id+1),p+Vector3(0,0.01,0),30,0.002);number.rotation.x=-PI/2;number.modulate=Color.WHITE
	var labels: Array[String]=[
		"GUESS A NUMBER / one ticket per ball\nExample best guess: 16 — 1 of 16 tickets wins",
		"GUESS A COLOUR / the same 16 tickets\nBest guess: TEAL — 15 of 16 tickets win",
		"GUESS A NUMBER / 16 now has 15 tickets\nBest guess: 16 — 15 of 30 tickets win"]
	Objects.ink(tray,labels[setting],Vector3(0,0.54,2.525),26,0.002)

func update_motion() -> void:
	if kind==3:
		var x:=0.8;var y:=0.8+1.0/512.0
		for i in steps: x=Model.door_step(x,setting==1);y=Model.door_step(y,setting==1)
		for i in hinges.size(): hinges[i].rotation.y=-PI/2*(1.0 if setting==2 else (x if i==0 else y))
		if setting==2:
			readout.text="Dynamics paused / walk through\nNEXT returns to the closing rule"
			update_panel();changed.emit();return
		var n:=maxi(1,steps)
		readout.text="%s  ·  H(%d-symbol record) = %.1f bits\nLOW/HIGH bins / 1024 initial positions" % [["x/2","2x modulo 1"][setting],n,Model.word_entropy(n,setting==1)]
	elif kind==4:
		var t:=Model.thermal(seconds)
		readout.text="Cup %.1f K / bath %.1f K\nDelta S: cup %.1f / bath %.1f J/K\nTotal +%.2f J/K" % [t.hot,t.cold,t.hot_entropy,t.cold_entropy,t.total]
		steam.set_shader_parameter("clock",seconds);steam.set_shader_parameter("warmth",(t.hot-t.cold)/60.0)
	update_panel();changed.emit()

func capture() -> Dictionary:
	return {"schema":"ordinary-entropies/1","kind":kind,"stage":stage_index,"setting":setting,"steps":steps,"seconds":seconds,"seed":str(experiment_seed),"draws":draws,"selected":selected,"mixing":mixing,"milk_fraction":milk_fraction,"coffee_clock":coffee_clock,"glass_obscurity":glass_obscurity,"cup_table_enabled":cup_table_enabled}

func restore(record: Variant) -> bool:
	if not record is Dictionary or record.get("schema")!="ordinary-entropies/1" or record.get("kind")!=kind: return false
	for key in ["setting","steps","draws","selected"]:
		var v=record.get(key)
		if not (v is int or v is float) or not is_finite(v) or v!=int(v):return false
	if record.setting<0 or record.setting>(3 if kind==5 else 2) or record.steps<0 or record.steps>8 or record.draws<0 or record.draws>100000 or record.selected< -1 or record.selected>15:return false
	if kind in [0,1,5] and record.selected>7:return false
	if kind in [1,2] and record.setting>1:return false
	var time=record.get("seconds")
	if not (time is int or time is float) or not is_finite(time) or time<0 or time>60:return false
	if not record.get("seed") is String or not record.seed.is_valid_int() or str(int(record.seed))!=record.seed:return false
	var stage_value: Variant=record.get("stage",0)
	if not (stage_value is int or stage_value is float) or not is_finite(stage_value) or stage_value!=int(stage_value):return false
	var saved_stage: int=int(stage_value)
	if saved_stage<0 or saved_stage>=STAGES[kind].size():return false
	for key in ["mixing","milk_fraction","glass_obscurity"]:
		var value: Variant=record.get(key,-1.0 if key=="glass_obscurity" else (0.25 if key=="milk_fraction" else 0.0))
		if not (value is float or value is int) or not is_finite(value) or value<(-1.0 if key=="glass_obscurity" else 0.0) or value>1.0:return false
	if record.has("cup_table_enabled") and not record.cup_table_enabled is bool:return false
	var saved_clock: Variant=record.get("coffee_clock",0.0)
	if not (saved_clock is float or saved_clock is int) or not is_finite(saved_clock) or saved_clock<0 or saved_clock>1000000000:return false
	stage_index=saved_stage
	coffee_clock=float(saved_clock)
	mixing=float(record.get("mixing",0.0));milk_fraction=float(record.get("milk_fraction",0.25));glass_obscurity=float(record.get("glass_obscurity",-1.0));cup_table_enabled=record.get("cup_table_enabled",true)
	setting=int(record.setting);steps=int(record.steps);seconds=float(time);experiment_seed=int(record.seed);draws=int(record.draws);selected=int(record.selected);running=false
	if not record.has("stage"):stage_index=infer_stage()
	rebuild();return true

func keep() -> String:
	var path: String=pointer_prefix+str(kind)+".json"
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return ""
	file.store_string(JSON.stringify(capture(),"\t",true,true));file.flush()
	var code:=file.get_error();file.close()
	if code!=OK:return ""
	last_saved=path
	print("Ordinary entropy receipt: ",ProjectSettings.globalize_path(path));return path

func replay() -> bool:
	var file:=FileAccess.open(pointer_prefix+str(kind)+".json",FileAccess.READ)
	if file==null:return false
	var parser:=JSON.new();var code:=parser.parse(file.get_as_text());file.close()
	var restored: bool=restore(parser.data) if code==OK else false
	return restored
