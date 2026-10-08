extends Node3D
## Three walk-along viewing walls. Glass collision stays fixed; only the sight slits move.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const Signals = preload("res://commons/artifacts/related_weather/weather_signals.gd")
const HISTORY := 8
const LIMIT := 128
const TRAVEL := 1.0
const DWELL := 1.0
const COLOURS := [Color(0.89,0.91,0.86),Color(0.78,0.48,0.23),Color(0.93,0.31,0.57)]
const INK := Color(0.07,0.11,0.15)
@export var run_seed:int=4321
var source=Signals.new()
var records:Array=[]
var running:=false
var stepping:=false
var moving:=false
var phase:=0.0
var dwell:=0.0
var shutters:Array=[]
var starts:Array=[]
var targets:Array=[]
var states:Array=[]
var status:Label3D
var values:Label3D
var controls:Node3D
signal record_changed(state:Dictionary)
func _ready()->void:
	_build();replay()
func _label(text:String,pos:Vector3,height:float,yaw:float=PI)->Label3D:
	var node:=Label3D.new();node.text=text;node.position=pos;node.font_size=44;node.pixel_size=height/44;node.outline_size=4;node.rotation.y=yaw;add_child(node);return node
func _build()->void:
	var titles:=["FRESH DRAW","ACCUMULATED STEP","FILTERED / PINK"]
	for channel in range(3):
		var x:float=(1-channel)*3.30
		var colour:Color=COLOURS[channel]
		Stage.box(self,Vector3(x,0.12,0),Vector3(0.40,0.24,8.10),INK,true)
		Stage.box(self,Vector3(x,3.35,0),Vector3(0.34,0.10,8.10),INK,true)
		# A visibly glazed viewing wall, never a timed walking gate.
		var glass:=Stage.box(self,Vector3(x,1.78,0),Vector3(0.025,3.10,8.0),Color(0.40,0.79,0.85,0.075),true)
		glass.name="FixedGlass%d"%channel
		for z in [-4.08,4.08]:Stage.box(self,Vector3(x,1.78,z),Vector3(0.24,3.1,0.14),INK,true)
		Stage.box(self,Vector3(x,2.95,-4.25),Vector3(3.05,0.63,0.09),INK)
		_label(titles[channel],Vector3(x,3.10,-4.31),0.090)
		_label("NEWEST HERE / 8 MOMENTS HELD",Vector3(x,2.88,-4.31),0.048)
		_label("GLAZED VIEWING WALL",Vector3(x,2.72,-4.31),0.04)
		for slot in range(HISTORY):
			var z:float=-3.5+slot
			var lower:=Stage.box(self,Vector3(x,0.8,z),Vector3(0.18,1.1,0.91),colour)
			var upper:=Stage.box(self,Vector3(x,2.6,z),Vector3(0.18,1.1,0.91),colour)
			for edge in [-0.495,0.495]:Stage.box(self,Vector3(x,1.78,z+edge),Vector3(0.26,3.1,0.04),INK)
			var flag:=Stage.box(self,Vector3(x,0.30,z),Vector3(0.30,0.055,0.86),Color(0.16,0.22,0.25))
			var label:=_label("—",Vector3(x+0.16,0.46,z),0.065,PI/2)
			var back:=_label("—",Vector3(x-0.16,0.46,z),0.065,-PI/2)
			shutters.append({"lower":lower,"upper":upper,"flag":flag,"labels":[label,back],"channel":channel,"slot":slot})
			states.append(Vector2(1.70,0.0));targets.append(Vector2(1.70,0.0));starts.append(Vector2(1.70,0.0))
		# A path on either side, extending beyond the fixed glass.
		for side in [-1.0,1.0]:Stage.box(self,Vector3(x+side*0.75,0.016,0),Vector3(0.04,0.018,9.20),colour)
	# Fixed sight target beyond all three walls, keeping seeing separate from their moving apertures.
	Stage.box(self,Vector3(-4.8,1.70,0),Vector3(0.08,0.11,7.7),Color(1.0,0.78,0.25))
	for z in [-3.7,3.7]:Stage.box(self,Vector3(-4.8,0.85,z),Vector3(0.10,1.70,0.10),INK,true)
	controls=Rack.create_panel("",[[{"type":"button","label":"RUN / HOLD"},{"type":"button","label":"NEXT"},{"type":"button","label":"REPLAY"},{"type":"button","label":"NEW SEED"}]],true)
	controls.name="WeatherControls";controls.position=Vector3(0,1.12,-5.65);controls.rotation=Vector3(deg_to_rad(-50),PI,0);controls.scale=Vector3.ONE*1.65;add_child(controls)
	Stage.box(self,Vector3(0,0.48,-5.6),Vector3(1.30,0.96,0.35),INK,true)
	Stage.box(self,Vector3(0,1.70,-5.6),Vector3(3.3,0.58,0.075),INK)
	status=_label("",Vector3(0,1.87,-5.65),0.057)
	values=_label("",Vector3(0,1.67,-5.65),0.046)
	_label("ORANGE EDGE = DISPLAY LIMIT",Vector3(0,1.49,-5.65),0.039)
	_label("PINK FILTER / 4096 PREPARATION SAMPLES",Vector3(0,0.74,-5.9),0.045)
	for i in range(4):controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(_button.bind(i))
func _button(_node,index:int)->void:
	match index:
		0:toggle_run()
		1:step()
		2:replay()
		3:new_seed()
func replay()->void:
	running=false;stepping=false;moving=false;phase=0;dwell=0;records.clear();source.reset(run_seed)
	for i in range(states.size()):states[i]=Vector2(1.7,0);starts[i]=states[i];targets[i]=states[i]
	_render();_record_labels();_notice()
func new_seed()->void:
	var rng:=RandomNumberGenerator.new();rng.randomize();var value:=run_seed
	while value==run_seed:value=rng.randi_range(10000,99999)
	run_seed=value;replay()
func toggle_run()->void:
	if records.size()>=LIMIT and not moving:return
	running=not running;stepping=false
	if running and not moving:_begin_step()
	_notice()
func step()->void:
	running=false;stepping=true
	if not moving:_begin_step()
	_notice()
func _begin_step()->void:
	if records.size()>=LIMIT:running=false;stepping=false;_notice();return
	records.append(source.next_sample());moving=true;phase=0;dwell=0
	starts=states.duplicate()
	for i in range(shutters.size()):
		var channel:int=shutters[i].channel;var index:int=records.size()-1-int(shutters[i].slot)
		if index<0:targets[i]=Vector2(1.7,0)
		else:
			var display:Array=Signals.display_values(records[index])
			targets[i]=Vector2(1.7+0.75*clampf(display[channel],-1,1),0.64)
	_record_labels();record_changed.emit(get_state());_notice()
func _process(delta:float)->void:
	if not running and not stepping:return
	if moving:
		phase=minf(1.0,phase+delta/TRAVEL)
		var smooth:=phase*phase*(3-2*phase)
		for i in range(states.size()):states[i]=(starts[i] as Vector2).lerp(targets[i],smooth)
		_render()
		if phase>=1.0:
			moving=false;stepping=false;dwell=0
			if records.size()>=LIMIT:running=false
			_notice()
	elif running:
		dwell+=delta
		if dwell>=DWELL:_begin_step()
func _render()->void:
	for i in range(shutters.size()):
		var centre:float=states[i].x;var gap:float=states[i].y
		var bottom_height:=centre-gap/2-0.25
		var top_height:=3.30-(centre+gap/2)
		var lower:MeshInstance3D=shutters[i].lower;var upper:MeshInstance3D=shutters[i].upper
		lower.scale.y=bottom_height/1.1;lower.position.y=0.25+bottom_height/2
		upper.scale.y=top_height/1.1;upper.position.y=centre+gap/2+top_height/2
func _record_labels()->void:
	for data in shutters:
		var index:int=records.size()-1-int(data.slot);var text:="—";var clipped:=false
		if index>=0:
			var display:Array=Signals.display_values(records[index]);clipped=absf(display[data.channel])>1.0
			text="%d%s"%[index+1," / LIMIT" if clipped else ""]
		for label in data.labels:label.text=text
		data.flag.material_override.albedo_color=Color(1,0.54,0.12) if clipped else Color(0.16,0.22,0.25)
	if records.is_empty():values.text="FRESH —     SUM —     FILTER —"
	else:
		var v:Array=Signals.display_values(records.back());values.text="TARGET / %.2f     %.2f     %.2f"%[v[0],v[1],v[2]]
func _notice()->void:
	var mode:="RUN" if running else ("STEP" if stepping else "HOLD")
	if records.size()>=LIMIT and not moving:mode="RECORD FULL"
	status.text="%s / %d OF %d / SEED %d"%[mode,records.size(),LIMIT,run_seed]
func get_state()->Dictionary:
	return {"seed":run_seed,"count":records.size(),"running":running,"moving":moving,"stepping":stepping,"phase":phase,"last":records.back().duplicate() if not records.is_empty() else [],"targets":targets.duplicate(),"visible":states.duplicate(),"display_gain":[1,1,Signals.PINK_GAIN],"warmup":Signals.WARMUP,"history":HISTORY,"limit":LIMIT,"scope":"Raw independent, accumulated and filtered signals; fixed display gain, clamp and matched travel. Glass collision is fixed."}
