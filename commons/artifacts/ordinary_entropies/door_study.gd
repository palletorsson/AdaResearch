extends "comparison.gd"
## A shared step clock. Pair separation and ensemble word entropy are distinct readings.
const Controls = preload("study_controls.gd")
const Model = preload("model.gd")
const GAPS = [0.0, 1.0/1024, 1.0/512, 1.0/128, 1.0/16, 0.1]
const GAP_NAMES = ["0", "1/1024", "1/512", "1/128", "1/16", "0.1"]
const START = 0.8
const MAX_STEP = 15
var gap_index := 2
var step_index := 0
var buttons: Dictionary = {}
var histories: Array[Label3D] = []
var panel_state: Label3D

func _ready() -> void:
	kind = 3
	automatic = false
	super._ready()
	remove_child(wall_text)
	wall_text.free()
	wall_text = WallText.new()
	wall_text.heading = "4 / TWO STARTS, TWO RULES"
	wall_text.explanation = "Will a small gap grow or disappear?\nSTEP moves both pairs once. Touch its cap, or point + trigger.\nGAP changes the starting difference; RESET starts again.\nSolid starts at 0.8; translucent at 0.8 + gap.\nLOW is below half the angle range; HIGH is above.\nThese doors calculate. They do not measure heat."
	wall_text.position = WALL_POSITIONS[3] + Vector3.UP * 0.30
	add_child(wall_text)
	var face := Node3D.new()
	face.name = "SharedDoorControls"
	face.position = Vector3(2.25,1.02,0.22)
	add_child(face)
	var control_back := Objects.box(face,Vector3.ZERO,Vector3(1.6,0.36,0.05),Color("e9e5d9"),true)
	control_back.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	panel_state = Objects.ink(face,"",Vector3(0,0.13,0.035),25,0.0014)
	var names = ["STEP","RESET","GAP -","GAP +"]
	var actions = [step_once,reset_study,change_gap.bind(-1),change_gap.bind(1)]
	for i in names.size():
		buttons[names[i]] = Controls.button(face,Vector3((i-1.5)*0.38,-0.025,0.04),names[i],actions[i],i==0)
	for i in 2:
		var p := Vector3(4.5 if i==0 else -4.5,0.50,2.55)
		var history_back := Objects.box(self,p,Vector3(3.05,0.62,0.045),Color("e9e5d9"),true)
		history_back.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for x in [-1.3,1.3]: Objects.box(self,p+Vector3(x,-0.25,-0.04),Vector3(0.035,0.5,0.06),Objects.DARK)
		var label := Objects.ink(self,"",p+Vector3(0,0,0.03),25,0.0017)
		histories.append(label)
	advance_doors(0)
	set_process(false)

func trace(expanding: bool, ghost: bool = false) -> Array:
	var x: float = START + (GAPS[gap_index] if ghost else 0.0)
	var result: Array = [x]
	for i in step_index:
		x = Model.door_step(x,expanding)
		result.append(x)
	return result

func symbols(values: Array) -> String:
	var result: Array[String] = []
	for value in values: result.append("H" if value>=0.5 else "L")
	return " ".join(result)

func advance_doors(step: int) -> void:
	step_index = clampi(step,0,MAX_STEP)
	last_step = step_index
	if versions.size()<2:return
	for i in 2:
		var solid := trace(i==1)
		var ghost := trace(i==1,true)
		versions[i].hinges[0].rotation.y = -PI/2 * float(solid[-1])
		versions[i].hinges[1].rotation.y = -PI/2 * float(ghost[-1])
		if histories.size()>i:
			histories[i].text = "%s   /   step %d\nsolid: %s\nghost: %s\nangle gap %.6f   /   LOW < 0.5 <= HIGH" % ["HALVE x / 2" if i==0 else "DOUBLE (2x) mod 1",step_index,symbols(solid),symbols(ghost),absf(solid[-1]-ghost[-1])]
	if is_instance_valid(panel_state):
		panel_state.text = "STEP %d / %d    START GAP %s" % [step_index,MAX_STEP,GAP_NAMES[gap_index]]
		var n := step_index+1
		wall_text.reading.text = "H(%d-symbol record), across 1024 equal starting bins:\nHalving %.1f bits / Doubling %.1f bits\nThe two visible paths are examples, not this ensemble.\nFinite starts cap the record at 10 bits.\nWrapped pairs can rejoin; separation is not monotonic." % [n,Model.word_entropy(n,false),Model.word_entropy(n,true)]

func step_once() -> void: advance_doors(step_index+1)
func reset_study() -> void: advance_doors(0)
func change_gap(direction: int) -> void:
	gap_index = clampi(gap_index+direction,0,GAPS.size()-1)
	reset_study()

func capture() -> Dictionary:
	return {"schema":"door-pairs/1","start":START,"gap_index":gap_index,"step":step_index,"partition":0.5,"starting_bins":1024}

func restore(record: Variant) -> bool:
	if not record is Dictionary or record.get("schema")!="door-pairs/1":return false
	if record.get("start")!=START or record.get("partition")!=0.5 or record.get("starting_bins")!=1024:return false
	for key in ["gap_index","step"]:
		var value: Variant = record.get(key)
		if not (value is int or value is float) or not is_finite(value) or value!=int(value):return false
	if record.gap_index<0 or record.gap_index>=GAPS.size() or record.step<0 or record.step>MAX_STEP:return false
	gap_index=int(record.gap_index)
	advance_doors(int(record.step))
	return true
