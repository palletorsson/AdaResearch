extends "res://commons/artifacts/spine_films/film_stage.gd"
const Rules = preload("res://commons/artifacts/spine_films/foundation_b/study_rules.gd")
const PINK := Color("ef9dab")
const WHITE := Color("eee8dd")
const TEAL := Color("76cec2")
var manual := false
var model: Dictionary = Rules.initial_state()
var traveller: MeshInstance3D
var visitor: MeshInstance3D
var panels: Array[MeshInstance3D] = []
var gate_labels: Array[Label3D] = []
var clock_label: Label3D
var condition_label: Label3D

func _build() -> void:
	title_text = "A response can remember"
	duration = 28.0
	phases = ["INITIALISE", "STEP THE CLOCK", "APPROACH", "LEAVE; KEEP THE VISIT"]
	notes = ["One initial call. Two gates start closed; no visit has been recorded.",
		"Each teaching FRAME adds 0.5 s. Four steps complete the cube's two-second journey.",
		"Approach opens both gates. One reads current input; the other stores the visit.",
		"Away: the current gate closes. The retained gate stays open; the clock can keep counting."]
	source_paths = ["res://commons/artifacts/spine_films/foundation_source.js"]
	evidence = {"source":"State browser study: drawState and its three event listeners",
		"teaching_step_seconds":0.5,"travel_seconds":2.0,"ready_calls":1,
		"gate_open_fraction":0.7,"model":"Exact browser state transitions; 3D display is an explanatory port.",
		"limits":"FRAME is a synthetic teaching step, not a measured Godot frame. APPROACH is a button, not tracked proximity. No hall gates are controlled."}
	add_box(Vector3(0,-.1,0),Vector3(7,.16,3.2),Color("202b37"))
	for x in [-2.5,2.5]:
		add_rod(Vector3(x,2.5,-.6),Vector3(x,3.3,-.6),.025,WHITE)
	add_rod(Vector3(-2.5,3.04,-.6),Vector3(2.5,3.04,-.6),.022,WHITE)
	traveller = add_box(Vector3(-2.5,3.25,-.6),Vector3(.30,.30,.30),PINK)
	clock_label = add_label("",Vector3(0,3.79,-.6),WHITE)
	clock_label.font_size = 37
	clock_label.pixel_size = .007
	condition_label = add_label("",Vector3(0,2.65,.05),PINK)
	condition_label.font_size = 34
	condition_label.pixel_size = .007
	for gate in range(2):
		var cx := -1.8+3.6*gate
		for x in [cx-1.06,cx+1.06]: add_box(Vector3(x,1.01,0),Vector3(.12,2.02,.25),WHITE)
		add_box(Vector3(cx,2.05,0),Vector3(2.24,.12,.25),WHITE)
		add_box(Vector3(cx,.04,0),Vector3(2.24,.06,.5),WHITE)
		for side in range(2): panels.append(add_box(Vector3(cx,1.02,0),Vector3(1,1.86,.16),TEAL if gate else PINK))
		var label := add_label("",Vector3(cx,-.35,1.96),WHITE)
		label.font_size = 35
		label.pixel_size = .008
		gate_labels.append(label)
	visitor = add_ball(Vector3(0,.19,1.7),.14,PINK)
	frame_scene(Vector3(0,1.65,0),12.1,.08,.19)

func _automatic(time: float) -> Dictionary:
	var state := Rules.initial_state()
	var phase := phase_index(time)
	var progress := phase_progress(time)
	var count := 0
	if phase == 1: count = mini(4,1+int(progress*4.0))
	if phase >= 2: count = 4
	if phase == 3: count = 5+int(progress>=.5)
	for i in count: Rules.state_action(state,"frame")
	if phase >= 2: Rules.state_action(state,"proximity")
	if phase == 3: Rules.state_action(state,"proximity")
	return state

func _draw(time: float) -> void:
	if not manual: model = _automatic(time)
	traveller.position.x = lerpf(-2.5,2.5,minf(float(model.elapsed)/2.0,1.0))
	clock_label.text = "initial calls  1     steps  %d     elapsed  %.1f s" % [model.frames,model.elapsed]
	condition_label.text = "elapsed < 2  =  %s" % str(float(model.elapsed)<2.0)
	for gate in range(2):
		var open: bool = model.near if gate==0 else model.visited
		var width := .3 if open else 1.0
		var cx := -1.8+3.6*gate
		for side in range(2):
			var panel := panels[gate*2+side]
			panel.scale.x = width
			panel.position.x = cx + (-1.0+width*.5 if side==0 else 1.0-width*.5)
		gate_labels[gate].text = ("NEAR NOW" if gate==0 else "HAS VISITED")+"\n"+str(open)
	visitor.position.z = .65 if model.near else 1.65
	frame_scene(Vector3(0,1.65,0),12.1,.08,.19)

func refresh() -> void:
	super.refresh()
	if manual and _note != null:
		_note.text = "FRAME adds 0.5 s. Approach and leave independently. RESET clears both clock and visit."
		_footer.text = "YOUR COMPARISON   /   Teaching state; no museum door is controlled"

func experiment_controls() -> Array:
	return [{"key":"frame","label":"FRAME"},{"key":"proximity","label":"AWAY" if model.near else "APPROACH"},{"key":"reset","label":"RESET"}]

func experiment_action(key: String) -> void:
	if key not in ["frame","proximity","reset"]: return
	manual = true
	running = false
	Rules.state_action(model,key)
	refresh()

func experiment_snapshot() -> Dictionary:
	var state := model.duplicate(true)
	state.manual = manual
	state.travel_fraction = minf(float(model.elapsed)/2.0,1.0)
	state.ready_calls = 1
	state.gate_open = [model.near,model.visited]
	state.gate_panel_width = [panels[0].scale.x,panels[2].scale.x]
	return state

func replay() -> void:
	manual = false
	super.replay()

func validation() -> Dictionary:
	var tests: Array[Dictionary] = []
	var state := Rules.initial_state()
	tests.append({"test":"Initial state is empty and both gates closed","passed":state.frames==0 and state.elapsed==0 and not state.near and not state.visited})
	for i in range(1,9):
		Rules.state_action(state,"frame")
		tests.append({"test":"Exact half-second step %d" % i,"passed":state.frames==i and state.elapsed==float(i)*.5 and not state.visited})
	tests.append({"test":"Travel clamps while elapsed continues","passed":minf(state.elapsed/2.0,1.0)==1.0 and state.elapsed==4.0})
	Rules.state_action(state,"proximity")
	tests.append({"test":"Approach sets current and retained state without ticking clock","passed":state.near and state.visited and state.frames==8})
	Rules.state_action(state,"proximity")
	tests.append({"test":"Leaving closes only current gate","passed":not state.near and state.visited and state.elapsed==4.0})
	Rules.state_action(state,"reset")
	tests.append({"test":"Reset clears visit and clock","passed":state==Rules.initial_state()})
	var passed := true
	for test in tests: passed = passed and test.passed
	return {"passed":passed,"checks":tests,"evidence":evidence}
