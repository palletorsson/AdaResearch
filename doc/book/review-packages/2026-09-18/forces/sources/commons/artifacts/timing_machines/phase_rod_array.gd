extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Twenty indexed rotors: common period, phase gradient, then frequency mismatch.
const COUNT := 20
var rods: Array[Node3D] = []
var elapsed := 0.0
var period := 6.0
var mode := "TOGETHER"
var one_offset := 0.0
var show_rule := false
var rule: Label3D
func _ready() -> void:
	var dark=material("182d38");box(Vector3(0,0.09,-0.2),Vector3(6.6,0.18,5.2),dark,true)
	for i in COUNT:
		var x=(i%5-2)*1.25;var z=-(i/5)*1.2+1.65
		box(Vector3(x,0.24,z),Vector3(0.40,0.3,0.40),dark,true)
		box(Vector3(x,0.96,z),Vector3(0.055,1.2,0.055),material("536373"))
		var pivot=Node3D.new();pivot.position=Vector3(x,1.57,z);add_child(pivot);rods.append(pivot)
		var ink=material(["ff669b","ffd75e","54e5da","9e99ff"][i/5],true)
		box(Vector3.ZERO,Vector3(0.045,1.05,0.045),ink,false,pivot)
		box(Vector3(0,0.54,0),Vector3(0.095,0.12,0.095),material("ffffff",true),false,pivot)
	console(["ONE +","WAVE","DRIFT","RESET","RULE"],3.3,"TWENTY CLOCKS")
	rule=label("",Vector3(0,2.75,-2.5),0.0018);rule.hide()
	var light=OmniLight3D.new();light.position=Vector3(0,3,0);light.omni_range=8;light.light_energy=1.4;add_child(light)
	_update_rods()
func angle_at(i: int, time: float) -> float:
	var frequency=1.0/period
	if mode=="DRIFT" and i>=10:frequency*=1.04
	var phase=(i%5)*TAU/5.0 if mode=="WAVE" else 0.0
	if i==9:phase+=one_offset
	return TAU*frequency*time+phase
func _process(delta: float) -> void:
	elapsed+=delta;_update_rods()
func _update_rods() -> void:
	for i in rods.size():rods[i].rotation.z=angle_at(i,elapsed)
	if readout:
		readout.text="%s / base period 6 s\n%s" % [mode,"back rows 4% faster" if mode=="DRIFT" else "rod 10 offset: %.0f degrees" % rad_to_deg(one_offset)]
	if rule:rule.text="angle = TAU * frequency * time + phase\nSame period + different phases can make a wave."
func act(id: String) -> void:
	match id:
		"ONE +":one_offset=fposmod(one_offset+PI/4,TAU)
		"WAVE":mode="WAVE";one_offset=0
		"DRIFT":mode="DRIFT";one_offset=0
		"RESET":mode="TOGETHER";one_offset=0
		"RULE":show_rule=not show_rule;rule.visible=show_rule
	_update_rods()
