extends RefCounted
## A second lesson on the same station and sphere; examples stay separate.
const Learner := preload("res://commons/artifacts/vogue_timeline/height_learner.gd")
const Rack := preload("res://commons/audio/rack_templates/RackTemplates.gd")
const SAVE_PATH := "user://ada_hand_height_v1.json"
const LOW := 0.95
const HIGH := 1.95
var station: Node3D
var model := Learner.new()
var mode := "TEACH"
var training := false
var target := 0.5
var capture_target := 0.5
var capturing := false
var capture_time := 0.0
var sample_time := 0.0
var samples: Array = []
var reset_until := 0
var message := "Set HEIGHT, press CAPTURE, then hold both hands after the countdown."
var prediction: Dictionary = {}
var input := 0.0
var valid_input := false
var slider: Node3D
var visuals: Array[Node3D] = []
var dots: Array[MeshInstance3D] = []
var fit_line: MeshInstance3D
var cursor: MeshInstance3D
var display_value := 0.5

func _init(owner: Node3D) -> void: station=owner

func activate() -> void:
	mode="TEST" if model.trained else "TEACH"
	prediction.clear();capturing=false;samples.clear()
	station.replace_controls(Rack.create_panel("HEIGHT / REGRESSION",[
		[{"type":"slider_h","label":"HEIGHT m"},{"type":"button","label":"CAPTURE"}],
		[{"type":"button","label":"TEACH"},{"type":"button","label":"TEST"},{"type":"button","label":"LIVE"}],
		[{"type":"button","label":"TRAIN"},{"type":"button","label":"SAVE"},{"type":"button","label":"LOAD"},{"type":"button","label":"RESET"}],
		[{"type":"button","label":"POSE"},{"type":"button","label":"HEIGHT"},{"type":"button","label":"PHRASE"}]]))
	var commands := ["CAPTURE","TEACH","TEST","LIVE","TRAIN","SAVE","LOAD","RESET","POSE","HEIGHT","PHRASE"]
	for i in commands.size():
		var button=station.controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
		button.button_pressed.connect(func(_area): station.command(commands[i]))
	slider=station.controls.find_child("Param_0",true,false)
	slider.set_range(LOW,HIGH);slider.set_normalized_value(target)
	slider.slider_moved.connect(func(_value): set_target(slider.get_normalized_value()))
	for item in station.bars+station.chart: item.visible=false
	station.score_label.visible=false
	# A one-metre rail displays the same sphere away from the reading panel.
	var rail=station._box(Vector3(0.83,1.45,0.10),Vector3(0.008,1.0,0.008),Color(0.6,0.65,0.7))
	visuals.append(rail)
	for y in [LOW,HIGH]:
		visuals.append(station._label("%.2f m"%y,Vector3(0.85,y,-0.15),18,Color.WHITE,0.0018))
	for a in [[Vector3(-0.55,1.11,-0.41),Vector3(0.55,1.11,-0.41)],[Vector3(-0.55,1.11,-0.41),Vector3(-0.55,1.44,-0.41)]]:
		var rod=station.host._rod(station.host._mat(Color(0.4,0.5,0.6)),station)
		station.host._place_rod(rod,a[0],a[1],0.003);visuals.append(rod)
	fit_line=station.host._rod(station.host._mat(Color(1,0.78,0.25)),station);visuals.append(fit_line)
	cursor=station.host._sphere(0.018,station.host._mat(Color.WHITE),station);visuals.append(cursor)
	for i in Learner.LIMIT:
		var dot=station.host._sphere(0.01,station.host._mat(Color(0.2,0.9,1)),station)
		dots.append(dot);visuals.append(dot)
	visuals.append(station._label("HAND HEIGHT -> SPHERE HEIGHT",Vector3(0,1.02,-0.41),17,Color.WHITE,0.0018))
	message="Set HEIGHT, press CAPTURE; demonstrate at least 3 different hand heights."
	refresh();animate(0.0)

func deactivate() -> void:
	capturing=false;samples.clear();prediction.clear()
	for item in visuals:
		station.remove_child(item);item.queue_free()
	visuals.clear();dots.clear()
	station.score_label.visible=true
	for bar in station.bars: bar.visible=true

func set_target(value: float) -> void:
	if not is_finite(value): return
	if capturing or training or mode=="LIVE":
		slider.set_normalized_value(target)
		return
	target=clampf(value,0,1)
	refresh();animate(0.0)

func command(which: String) -> void:
	if training: return
	if which=="CAPTURE":
		if capturing: return
		if mode not in ["TEACH","TEST"]: message="Choose TEACH or TEST before CAPTURE."
		elif not station.tracked_here(): message="Head + both controllers needed here."
		else:
			if station.host.playing: station.host.command("PLAY")
			capturing=true;capture_time=-3.0;sample_time=0.0;samples.clear()
			capture_target=target
		refresh();return
	capturing=false;samples.clear();prediction.clear()
	match which:
		"TEACH": mode="TEACH";message="Choose a sphere height, then demonstrate a hand height."
		"TEST","LIVE":
			if model.trained:
				mode=which
				message="Set expected HEIGHT; CAPTURE a fresh take." if mode=="TEST" else "Move hands within your taught range. The fitted line drives this sphere."
			else: message="Teach at least 3 heights and TRAIN first."
		"TRAIN":
			if model.begin_training():
				training=true;mode="TRAIN";message="Fitting slope + intercept to YOUR pairs."
			else: message="Need 3 takes and at least 0.16 m of hand-height variation."
		"SAVE": message="Height examples + fit saved locally." if model.save_file(SAVE_PATH)==OK else "Could not save; current examples remain."
		"LOAD":
			if model.load_file(SAVE_PATH):
				mode="TEST" if model.trained else "TEACH"
				message="Height model loaded; fresh evaluation starts here."
			else: message="No valid height session. Current model unchanged."
		"RESET":
			if Time.get_ticks_msec()<reset_until:
				model=Learner.new();mode="TEACH";reset_until=0;message="Height session cleared. Pose lesson and saved files remain."
			else:
				reset_until=Time.get_ticks_msec()+4000;message="Press RESET again within 4 seconds."
	refresh()

func tick(delta: float) -> void:
	if training:
		for i in 2: model.train_epoch()
		if model.trained: training=false;mode="TEST";message="Trained. Set expected HEIGHT; CAPTURE a fresh take."
	valid_input=station.tracked_here()
	if valid_input:
		input=((station.host.left.global_position.y+station.host.right.global_position.y)*0.5-station.host.head.global_position.y)/0.65
		valid_input=Learner.number(input,-2,2)
	advance_capture(delta,input,valid_input)
	if mode=="LIVE":
		prediction=model.predict(input) if valid_input else {}
		message="Tracking lost / idle" if not valid_input else ("Within taught range / predicting height" if prediction.get("accepted",false) else "Outside taught range / idle. Add examples to extend it.")
	refresh();animate(delta)

func advance_capture(delta: float, x: float, valid: bool) -> void:
	if not capturing: return
	if not valid or not Learner.number(x,-2,2) or delta>0.20:
		capturing=false;samples.clear();message="Tracking or timing interrupted / take discarded.";return
	capture_time+=maxf(0,delta)
	if capture_time<0:
		message="READY %d / arrange hands / target %.2f m"%[ceili(-capture_time),lerpf(LOW,HIGH,capture_target)]
	else:
		message="HOLD / one input-target pair"
		sample_time+=delta
		if sample_time>=0.05: sample_time=0.0;samples.append(x)
		if capture_time>=0.65: complete_capture()

func complete_capture() -> void:
	capturing=false
	if samples.size()<8: samples.clear();message="Too few samples / try again.";return
	var mean := 0.0
	for value in samples: mean+=float(value)/samples.size()
	var variance := 0.0
	for value in samples: variance+=pow(float(value)-mean,2)/samples.size()
	samples.clear()
	if sqrt(variance)>0.08: message="Hand height moved too much / try a brief hold.";return
	if mode=="TEACH":
		message="Pair saved. Choose another HEIGHT and hand position." if model.add_example(mean,capture_target) else "Maximum 30 pairs / reset to start again."
	else:
		prediction=model.test_example(mean,capture_target)
		message="Fresh test / raw error %+.3f m / %s"%[prediction.error*(HIGH-LOW),"inside range" if prediction.accepted else "outside range; live withheld"] if not prediction.is_empty() else "Train before testing."

func animate(delta: float) -> void:
	var desired := target if mode in ["TEACH","TEST"] else 0.5
	if mode=="LIVE" and prediction.get("accepted",false): desired=float(prediction.value)
	# Bounded display easing is an authored presentation choice, not learning.
	display_value=lerpf(display_value,desired,1.0-exp(-12.0*maxf(delta,0))) if delta>0 else desired
	station.sphere.position=Vector3(0.83,lerpf(LOW,HIGH,display_value),0.12)
	station.sphere.rotation=Vector3.ZERO;station.sphere.scale=Vector3.ONE
	station.sphere_material.albedo_color=Color(0.2,0.9,1) if mode=="LIVE" and prediction.get("accepted",false) else Color(0.85,0.87,0.91)
	station.response_label.text="%s %.2f m"%["PREDICTED" if mode=="LIVE" and prediction.get("accepted",false) else ("TARGET" if mode in ["TEACH","TEST"] else "IDLE"),station.sphere.position.y]

func graph_point(x: float, y: float) -> Vector3:
	var limits := model.bounds()
	var span := maxf(0.25,limits.y-limits.x)
	return Vector3(-0.55+clampf((x-limits.x)/span,0,1)*1.10,1.11+clampf(y,0,1)*0.33,-0.39)

func refresh() -> void:
	station.status.text=message
	station.count_label.text="HEIGHT / %d PAIRS / %d UPDATES"%[model.examples.size(),model.epoch]
	station.metrics.text="%s / straight-line regression / 2 parameters\n"%mode
	station.metrics.text+="MSE %.5f / slope %+.2f"%[model.loss(),model.slope/model.spread] if model.epoch>0 else "Input: mean hand height relative to your head"
	var error := 0.0
	for row: Dictionary in model.tests: error+=absf(row.error)
	station.metrics.text+="\nFresh tests %d / mean error %.3f m"%[model.tests.size(),error/maxi(1,model.tests.size())] if not model.tests.is_empty() else "\nFresh tests 0 / not evaluated"
	for i in dots.size():
		dots[i].visible=i<model.examples.size()
		if dots[i].visible: dots[i].position=graph_point(model.examples[i].x,model.examples[i].target)
	fit_line.visible=model.trained or model.epoch>0
	if fit_line.visible:
		var limits := model.bounds()
		var start := float(limits.x)
		var end := float(limits.y)
		if absf(model.slope)>0.00001:
			var at_zero:float=model.centre-model.intercept*model.spread/model.slope
			var at_one:float=model.centre+(1.0-model.intercept)*model.spread/model.slope
			start=maxf(start,minf(at_zero,at_one));end=minf(end,maxf(at_zero,at_one))
		fit_line.visible=start<end and (absf(model.slope)>0.00001 or (model.intercept>=0 and model.intercept<=1))
		if fit_line.visible: station.host._place_rod(fit_line,graph_point(start,model.raw(start)),graph_point(end,model.raw(end)),0.005)
	cursor.visible=mode=="LIVE" and prediction.get("accepted",false)
	if cursor.visible: cursor.position=graph_point(input,prediction.value)
