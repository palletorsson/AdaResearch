extends RefCounted
const Learner := preload("res://commons/artifacts/vogue_timeline/movement_learner.gd")
const Library := preload("res://commons/artifacts/vogue_timeline/phrase_library.gd")
const CheckLesson := preload("res://commons/artifacts/vogue_timeline/phrase_check.gd")
const Phrase := preload("res://commons/artifacts/vogue_timeline/dance_phrase.gd")
const Rack := preload("res://commons/audio/rack_templates/RackTemplates.gd")
const SAVE_PATH := "user://ada_two_hand_phrase_v1.json"
const LIBRARY_PATH := "user://ada_two_hand_phrase_library_v1.json"
const ORIGIN := Vector3(0.97,1.60,0.25)
var station:Node3D
var model:=Learner.new()
var single_model:RefCounted=model
var library:=Library.new()
var two_phrases:=false
var selected:="A"
var mode:="TEACH"
var capturing:=false
var clock:=0.0
var sample_clock:=0.0
var pending:Array=[]
var facing:=Basis.IDENTITY
var replay_time:=-1.0
var message:="CAPTURE three takes of ONE four-second phrase. Move both hands."
var result:Dictionary={}
var visuals:Array[Node3D]=[]
var paths:Array[MeshInstance3D]=[]
var trails:Array[MeshInstance3D]=[]
var tips:Array[MeshInstance3D]=[]
var beats:Array[MeshInstance3D]=[]
var beat_numbers:Array[Label3D]=[]
var beat_caption:Label3D
var check_lesson:RefCounted
var click:AudioStreamPlayer3D
var sound:=true
var last_beat:=-999
var reset_until:=0
var response_home:=Vector3.ZERO
var status_width:=690.0

func _init(owner:Node3D) -> void: station=owner

func activate() -> void:
	if station.host.playing: station.host.command("PLAY")
	station.host.hand_space.visible=false
	mode="TEST" if ready_to_test() else "TEACH"
	capturing=false;pending.clear();replay_time=-1;result.clear()
	build_controls()
	for item in station.bars+station.chart: item.visible=false
	station.score_label.visible=false
	response_home=station.response_label.position
	status_width=station.status.width
	station.status.width=520.0
	station.response_label.position=Vector3(1.02,1.94,0.1)
	visuals.append(station._box(Vector3(1.05,1.61,-0.28),Vector3(0.98,0.94,0.04),Color(0.022,0.028,0.04)))
	for hand in 2:
		var material=station.host._mat(station.COLORS[hand])
		for i in Learner.STEPS-1:
			var rod=station.host._rod(material,station);paths.append(rod);visuals.append(rod)
			rod=station.host._rod(material,station);trails.append(rod);visuals.append(rod)
		var tip=station.host._sphere(0.024,material,station);tips.append(tip);visuals.append(tip)
	for i in 8:
		var box=station._box(Vector3(-0.49+i*0.14,1.23,-0.40),Vector3(0.095,0.035,0.025),Color(0.16,0.20,0.29))
		beats.append(box);visuals.append(box)
		var number:Label3D=station._label(str(i+1),Vector3(-0.49+i*0.14,1.17,-0.40),16,Color.WHITE,0.0018)
		visuals.append(number);beat_numbers.append(number)
	beat_caption=station._label("8 BEATS / 120 BPM / 4 SECONDS",Vector3(0,1.35,-0.4),19,Color.WHITE,0.0018);visuals.append(beat_caption)
	visuals.append(station._label("LEFT + RIGHT / LEARNED IN TIME",Vector3(0.97,2.06,0.1),17,Color.WHITE,0.0018))
	click=AudioStreamPlayer3D.new();click.stream=make_click();click.volume_db=-16;click.max_distance=4.0;click.position=Vector3(0,1.4,0.2)
	station.add_child(click);visuals.append(click)
	message="A + B / select a label to TEACH; TEST compares both." if two_phrases else "CAPTURE three takes of ONE four-second phrase. Or choose A + B."
	refresh();draw()

func build_controls() -> void:
	var commands:=["CAPTURE","TEACH","TEST","TRY","TRAIN","REPLAY","UNDO","SOUND","SAVE","LOAD","RESET","POSE","HEIGHT","PHRASE","ONE","A","B","CHECK"]
	var rows:Array=[]
	for names in [["CAPTURE","TEACH","TEST","TRY"],["TRAIN","REPLAY","UNDO","SOUND"],["SAVE","LOAD","RESET"],["POSE","HEIGHT","PHRASE"],["ONE","A","B","CHECK"]]:
		var row:Array=[]
		for word in names: row.append({"type":"button","label":word})
		rows.append(row)
	station.replace_controls(Rack.create_panel("PHRASE / BOTH HANDS",rows))
	for i in commands.size():
		var button=station.controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
		button.button_pressed.connect(func(_area):station.command(commands[i]))

func ready_to_test() -> bool:
	return library.trained if two_phrases else model.trained

func select_phrase(which:String) -> void:
	cancel();replay_time=-1;result.clear();reset_until=0
	if not two_phrases: single_model=model
	two_phrases=which!="ONE"
	if two_phrases:
		selected=which;model=library.models[selected];mode="TEACH"
		message="TEACH %s / CAPTURE three whole takes. Then teach the other label."%selected
	else:
		model=single_model;mode="TEST" if model.trained else "TEACH"
		message="ONE / your earlier single phrase is kept separately."
	refresh();draw()

func library_command(which:String) -> void:
	match which:
		"TEACH": mode="TEACH";message="TEACH %s / one whole take per example."%selected
		"TEST":
			if library.trained: mode="TEST";message="CAPTURE a NEW phrase. Compared with BOTH labels; sphere waits."
			else: message="Teach at least three takes of EACH label, then TRAIN."
		"TRY":
			if library.trained: mode="TRY";begin_capture();return
			else: message="Teach A + B and TRAIN before recognition."
		"TRAIN":
			if library.fit(): mode="TEST"
			message=library.message
		"REPLAY":
			if model.trained: replay_time=0;message="PREVIEW %s / selected learned path, not recognition."%selected
			else: message="Train the selected phrase first."
		"UNDO":
			if library.undo(selected): mode="TEACH"
			message=library.message
		"SAVE": message="A + B examples and paths saved locally." if library.save_file(LIBRARY_PATH)==OK else "Save failed. Examples remain."
		"LOAD":
			if library.load_file(LIBRARY_PATH):
				model=library.models[selected];mode="TEST" if library.trained else "TEACH";message=library.message
			else: message="No valid A + B save. Current session unchanged."
		"RESET":
			if Time.get_ticks_msec()<reset_until:
				library=Library.new();model=library.models[selected];mode="TEACH";reset_until=0
				message="A + B session cleared. ONE, pose, height and files remain."
			else: reset_until=Time.get_ticks_msec()+4000;message="Press RESET again to clear BOTH A + B sessions."
	refresh();draw()

static func make_click() -> AudioStreamWAV:
	var data:=PackedByteArray();data.resize(2205*2)
	for i in 2205:
		var t:=i/22050.0
		var value:=sin(TAU*660*t)*exp(-t*65)*minf(t*500,1)*0.3
		data.encode_s16(i*2,int(value*32767))
	var wav:=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050;wav.data=data
	return wav

func deactivate() -> void:
	if check_lesson!=null and check_lesson.active:check_lesson.leave(false)
	cancel();replay_time=-1
	station.host.hand_space.visible=true
	for item in visuals: station.remove_child(item);item.queue_free()
	visuals.clear();paths.clear();trails.clear();tips.clear();beats.clear();beat_numbers.clear()
	station.score_label.visible=true
	station.response_label.position=response_home
	station.status.width=status_width
	for bar in station.bars: bar.visible=true

func cancel() -> void:
	capturing=false;pending.clear();sample_clock=0;last_beat=-999
	if is_instance_valid(click): click.stop()

func command(which:String) -> void:
	if check_lesson!=null and check_lesson.active:check_lesson.command(which);return
	if which=="CHECK":
		if not two_phrases or not library.trained:message="Teach A + B and TRAIN before CHECK.";refresh();return
		if check_lesson==null:check_lesson=CheckLesson.new(self)
		check_lesson.enter();return
	if which in ["ONE","A","B"]: select_phrase(which);return
	if which=="SOUND": sound=not sound;message="Beat click ON" if sound else "Beat click OFF / visual beats remain";refresh();return
	if which=="CAPTURE": begin_capture();return
	cancel();replay_time=-1;result.clear()
	if two_phrases: library_command(which);return
	match which:
		"TEACH": mode="TEACH";message="Repeat one phrase. Each complete performance is one example."
		"TEST":
			if model.trained: mode="TEST";message="CAPTURE a fresh phrase. Both hand errors shown; no training."
			else: message="Teach at least three takes and TRAIN first."
		"TRY":
			if model.trained: mode="TRY";begin_capture();return
			else: message="Teach and TRAIN before asking the sphere to recognise you."
		"TRAIN":
			if model.fit(): mode="TEST"
			message=model.message
		"REPLAY":
			if model.trained: replay_time=0;message="PREVIEW / replaying the learned mean, not a recognition result."
			else: message="Train first; there is no built-in learned phrase."
		"UNDO":
			if model.undo(): mode="TEACH"
			message=model.message
		"SAVE": message="Phrase examples + fitted paths saved locally." if model.save_file(SAVE_PATH)==OK else "Save failed. Current examples remain."
		"LOAD":
			if model.load_file(SAVE_PATH): mode="TEST" if model.trained else "TEACH";message=model.message
			else: message="No valid saved phrase. Current session unchanged."
		"RESET":
			if Time.get_ticks_msec()<reset_until: model=Learner.new();mode="TEACH";reset_until=0;message="Phrase session cleared. Pose, height and saved files remain."
			else: reset_until=Time.get_ticks_msec()+4000;message="Press RESET again within four seconds."
	refresh();draw()

func begin_capture() -> void:
	if capturing: return
	if mode=="CHECK" and check_lesson.intent=="":message="Choose MEAN A, MEAN B or NEITHER first.";refresh();return
	if not station.tracked_here(): message="Head + both tracked hands needed at the station."
	elif mode!="TEACH" and not ready_to_test(): message="Train first."
	else:
		station.align();facing=station.facing
		if station.host.playing: station.host.command("PLAY")
		capturing=true;clock=-3.0;sample_clock=0;pending.clear();replay_time=-1;result.clear();last_beat=-999
		message="READY 3 / arrange both hands. Move when beat 1 lights."
	refresh();draw()

func tick(delta:float) -> void:
	# Starting the neighbouring dance explicitly returns control to that activity.
	if station.host.playing:
		station.command("POSE")
		return
	if capturing:
		var valid:bool=station.tracked_here()
		var x:Array=[]
		if valid:
			var left:=Phrase.feature(station.host.head.global_position,station.host.left.global_position,facing,0.65)
			var right:=Phrase.feature(station.host.head.global_position,station.host.right.global_position,facing,0.65)
			x=[left.x,left.y,left.z,right.x,right.y,right.z]
		advance_capture(delta,x,valid)
	elif replay_time>=0:
		replay_time+=maxf(0,delta)
		if replay_time>Learner.SECONDS: replay_time=-1;click.stop()
		else:
			var beat:=mini(7,int(replay_time/0.5))
			if beat!=last_beat:
				last_beat=beat
				if sound:click.pitch_scale=1.0;click.play()
	refresh();draw()

func advance_capture(delta:float,x:Array,valid:bool) -> void:
	if not capturing: return
	if not valid or not Learner.valid_x(x) or delta>0.15:
		cancel();message="Tracking or timing interrupted / whole take discarded.";return
	clock+=maxf(0,delta)
	if clock>=Learner.SECONDS-0.000001: clock=Learner.SECONDS
	var beat:=int(floor(clock)) if clock<0 else int(floor(clock/0.5))
	if beat!=last_beat:
		last_beat=beat
		if sound and clock<Learner.SECONDS:
			click.pitch_scale=1.5 if clock<0 else 1.0
			click.play()
	if clock<0: message="READY %d / arrange hands, then MOVE for 8 beats"%ceili(-clock);return
	message="%s / BEAT %d OF 8 / move BOTH hands"%[("TEACH "+selected) if two_phrases and mode=="TEACH" else mode,mini(8,beat+1)]
	sample_clock+=delta
	if pending.is_empty() or sample_clock>=0.05 or clock>=Learner.SECONDS:
		sample_clock=0
		var t:=minf(clock,Learner.SECONDS)
		if pending.is_empty() or t>float(pending[-1].t): pending.append({"t":t,"x":x.duplicate()})
	if clock>=Learner.SECONDS: complete_capture()

func complete_capture() -> void:
	var take:=pending.duplicate(true)
	cancel()
	if mode=="CHECK":check_lesson.complete(take);return
	if two_phrases:
		if mode=="TEACH": library.add_example(selected,take);message=library.message
		else:
			result=library.test_example(take)
			if result.is_empty(): message="Incomplete take discarded. Try again."
			else:
				message="%s / distance A %.2f B %.2f\n"%[result.label,result.scores[0],result.scores[1]]
				if result.accepted:
					selected=result.label;model=library.models[selected]
					message+="Both hands fit %s. %s"%[selected,"Sphere responds." if mode=="TRY" else "TEST only."]
					if mode=="TRY": replay_time=0.0
				else: message+="Too close to choose. Sphere waits." if result.label=="AMBIGUOUS" else "Neither phrase fits. Sphere waits."
		return
	if mode=="TEACH": model.add_example(take);message=model.message
	else:
		result=model.test_example(take)
		if result.is_empty(): message="Incomplete take discarded. Try again."
		else:
			message="%s / left %.2f m / right %.2f m"%["MATCH" if result.accepted else "NOT THIS PHRASE",result.rms[0]*0.65,result.rms[1]*0.65]
			if mode=="TRY" and result.accepted: replay_time=0.0

func mini_position(x:Array,hand:int) -> Vector3:
	# Bounded miniature is the display; recognition uses unaltered measurements.
	return ORIGIN+Vector3(x[hand*3],x[hand*3+1],x[hand*3+2]).limit_length(1.8)*0.40

func draw() -> void:
	for hand in 2:
		for i in Learner.STEPS-1:
			var rod:=paths[hand*(Learner.STEPS-1)+i]
			rod.visible=model.trained
			if rod.visible: station.host._place_rod(rod,mini_position(model.prototype[i],hand),mini_position(model.prototype[i+1],hand),0.005)
			var trail:=trails[hand*(Learner.STEPS-1)+i]
			trail.visible=capturing and pending.size()>i*2+2 and station.tracked_here()
			if trail.visible:
				var a:Array=pending[i*2].x;var b:Array=pending[i*2+2].x
				var offset:=hand*3
				var anchor:Vector3=station.host.head.global_position
				station.host._place_rod(trail,station.to_local(anchor+facing*Vector3(a[offset],a[offset+1],a[offset+2])*0.65),station.to_local(anchor+facing*Vector3(b[offset],b[offset+1],b[offset+2])*0.65),0.005)
		var row:Array=model.target(replay_time) if replay_time>=0 else ([] if not model.trained else model.prototype[0])
		tips[hand].visible=not row.is_empty()
		if tips[hand].visible: tips[hand].position=mini_position(row,hand)
	station.sphere.position=ORIGIN
	station.sphere.scale=Vector3.ONE;station.sphere.rotation=Vector3.ZERO
	station.sphere_material.albedo_color=Color(0.85,0.87,0.91)
	if replay_time>=0 and model.trained:
		var row:=model.target(replay_time)
		var left:=mini_position(row,0);var right:=mini_position(row,1)
		station.sphere.position=(left+right)*0.5
		station.sphere.scale=Vector3.ONE*clampf(left.distance_to(right)*2.4,0.65,1.5)
		station.sphere_material.albedo_color=Color(1,0.77,0.25)
	station.response_label.text=("SPHERE / %s REPLAY"%selected if two_phrases else "SPHERE / PHRASE REPLAY") if replay_time>=0 else "SPHERE / WAITING"
	for i in 8:
		var lit:bool=(capturing and clock>=0 and mini(7,int(clock/0.5))==i) or (replay_time>=0 and mini(7,int(replay_time/0.5))==i)
		beats[i].material_override.albedo_color=Color(1,0.77,0.25) if lit else Color(0.16,0.20,0.29)
	if check_lesson!=null and check_lesson.active:check_lesson.draw()

func refresh() -> void:
	if check_lesson!=null and check_lesson.active:check_lesson.refresh();return
	station.status.text=message
	if two_phrases:
		station.count_label.text="A %d TAKES / B %d TAKES / %s"%[library.models.A.examples.size(),library.models.B.examples.size(),"FITTED" if library.trained else "TRAIN BOTH"]
		station.metrics.text="%s / selected %s / click %s\n"%[mode,selected,"ON" if sound else "OFF"]
		station.metrics.text+="TEST + TRY compare both; selection only teaches/previews\n"
		station.metrics.text+="Fresh tests %d / distance margin %.2f (not confidence)"%[library.tests.size(),Library.MARGIN]
		return
	station.count_label.text="PHRASE / %d COMPLETE TAKES / %s"%[model.examples.size(),"FITTED" if model.trained else "NEEDS TRAINING"]
	station.metrics.text="%s / ordered two-hand paths / click %s\n"%[mode,"ON" if sound else "OFF"]
	station.metrics.text+="Fit MSE %.4f / limits L %.2f R %.2f m"%[model.fit_error,model.limits[0]*0.65,model.limits[1]*0.65] if model.trained else "Three whole performances; never split frames into tests"
	var accepted:=0
	for row:Dictionary in model.tests:
		if row.accepted: accepted+=1
	station.metrics.text+="\nFresh tests %d / matched %d (not accuracy)"%[model.tests.size(),accepted]
