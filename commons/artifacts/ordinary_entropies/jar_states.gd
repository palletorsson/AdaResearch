extends Node3D
const Snapshot=preload("jar_column.gd")
const Objects=preload("objects.gd")
const Rack=preload("res://commons/audio/rack_templates/RackTemplates.gd")
const START_HOLD:=8.0
var jars: Array[Node3D]=[]
var activated:=false
var paused:=false
var elapsed:=0.0
var readout: Label3D
var clock_label: Label3D
var pause_label: Label3D
var buttons: Dictionary={}
var readout_wait:=0.0
func _ready() -> void:
	# One continuous, solid exhibition plinth; the toe recess leaves a shadow line.
	var toe:=Objects.box(self,Vector3(0,0.04,0),Vector3(5.56,0.08,1.32),Color("56535b"),true);toe.name="PlinthToe"
	var plinth:=Objects.box(self,Vector3(0,0.24,0),Vector3(5.80,0.32,1.55),Color("e5dfd6"),true);plinth.name="Plinth"
	Objects.box(self,Vector3(0,0.405,0),Vector3(5.84,0.01,1.59),Color("f1ece4"))
	for i in 4:
		var copy:=Snapshot.new();copy.found_state=["sorted","stirred","mixed","shelled"][i]
		copy.stream_index=i
		copy.position.x=(i-1.5)*1.42;add_child(copy);jars.append(copy)
		Objects.ink(self,["A / LAYERS","B / INTERFACE","C / MIXED","D / CORE + SHELL"][i],Vector3(copy.position.x,0.26,0.786),32,0.0025)
	build_reading_panel()
	update_reading()

func _process(delta: float) -> void:
	if not activated:
		var camera:=get_viewport().get_camera_3d()
		if camera!=null and camera.global_position.distance_to(to_global(Vector3(0,1.3,0)))<4.2:activated=true
	advance(delta)
	readout_wait+=delta
	if readout_wait>=0.25:readout_wait=0;update_reading()

func advance(seconds: float) -> void:
	if not activated or paused or seconds<=0 or not is_finite(seconds):return
	var old_mixing:=maxf(0,elapsed-START_HOLD)
	elapsed+=seconds
	var step:=maxf(0,elapsed-START_HOLD)-old_mixing
	if step>0:
		for jar in jars:jar.advance_mixing(step)

func restart() -> void:
	activated=true;paused=false;elapsed=0
	for jar in jars:jar.reset_mixing()
	update_reading()

func toggle_pause() -> void:
	activated=true;paused=not paused;update_reading()

func update_reading() -> void:
	if readout==null:return
	var seconds:=maxi(0,int(elapsed-START_HOLD))
	clock_label.text="Mixing %d:%02d" % [seconds/60,seconds%60]
	if not activated:clock_label.text="Approach to begin"
	elif elapsed<START_HOLD:clock_label.text="Starting arrangements / mixing in %d s" % int(ceil(START_HOLD-elapsed))
	if paused:clock_label.text+=" / paused"
	pause_label.text="RESUME" if paused else "PAUSE"
	var lines: Array[String]=["                 Height      Core/rim"]
	for i in 4:lines.append("%s                  %.2f             %.2f" % ["ABCD"[i],jars[i]._measure_entropy(),jars[i].radial_entropy()])
	readout.text="\n".join(lines)

func build_reading_panel() -> void:
	var panel:=Node3D.new();panel.name="ReadingPanel";add_child(panel)
	panel.position=Vector3(-3.05,0,1.35);panel.rotation_degrees.y=90
	Objects.box(panel,Vector3(0,1.15,-0.05),Vector3(1.8,2.3,0.10),Color("cbd1d2"),true)
	Objects.box(panel,Vector3(0,1.45,0.01),Vector3(1.65,1.12,0.025),Color("e9edeb"))
	Objects.ink(panel,"FOUR STARTS / ONE MIXING RULE",Vector3(0,1.90,0.029),26,0.0018)
	Objects.ink(panel,"40 lavender + 40 coral. Colour alone: 1 bit.\nCan we still tell how each began?",Vector3(0,1.74,0.029),24,0.0016)
	clock_label=Objects.ink(panel,"",Vector3(0,1.60,0.029),22,0.0014)
	readout=Objects.ink(panel,"",Vector3(0,1.37,0.029),25,0.0016)
	Objects.ink(panel,"Bits: colour given height or core/rim.\nSix height bands / two radial regions.\nSeed 435; four paths, same motion rule.\nA mixing model; no heat is measured.",Vector3(0,1.04,0.029),22,0.0014)
	for i in 2:
		var key: String=["PAUSE","RESTART"][i]
		var button=preload("res://commons/interactables/push_button.tscn").instantiate()
		Rack.make_button_rectangular(button);button.position=Vector3((i-0.5)*0.62,0.76,0.06)
		button.rotation.x=PI/2;button.scale=Vector3.ONE*1.5
		button.released_color=Color("a4afb3");button.released_emission_energy=0
		panel.add_child(button);buttons[key]=button
		button.pressed.connect(toggle_pause if i==0 else restart)
		var label:=Objects.ink(panel,key,Vector3(button.position.x,0.65,0.06),23,0.0015)
		if i==0:pause_label=label
