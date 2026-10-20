# Sequence Memory — both hands, in order

## Learning elements

- Carry the point sphere and the same six hand coordinates from Perception.
- Store a complete, timestamped movement instead of one averaged pose.
- Resample takes onto common times; fit a two-hand prototype.
- Test order, timing and each hand separately.
- Compare two taught phrases without forcing every take into A or B.
- Distinguish learned memory, a manual memory cell and replay.

## What we carry

Perception gave the point a learned response to a pose. Its short recording ended as six averages. Make a rising movement with both hands, then the same movement descending. Those averages can be the same. The movement is not.

Keep point_body.gd, pose_learner.gd and pose_study.gd from [Perception](../ML_Perception/tutorial.md), unchanged. The new sequence_study.gd **extends pose_study.gd**. Its call to the parent's ready function makes the same pickable PointBody, ring, board and tracking connections. We replace the controls and recording loop; we do not rebuild or explain the sphere again. An existing student pose save is read if present; phrase teaching never alters that model.

The object is continuous as a class and a design. During this study ONE, A/B, tests and replay all use one sphere instance. Reloading a museum hall does not yet transfer the visitor's live node between scenes. The phrase files below preserve learned data locally.

## Where to work

In the ordinary museum, the full phrase station remains in Perception's separate learning bay. In the Sequence Memory hall, inspect the existing gate cell and its transformer diagram. The supplied lesson launcher brings **your printed-code study** into a clear side area in that actual hall; it leaves those exhibits present.

Open res://doc/book/studies/ml-lineage/SequenceMemory.tscn in the Ada project and run it. Its supplied sequence_museum.gd prepares the room. Put the three new files below beside the three carried files. Camera, light, XR tracking, pickup and the RackTemplates button factory remain declared museum infrastructure. Every new learning operation is printed here. Recording needs a tracked head and both controllers; desktop can preview the room.

## One phrase before two

Choose ONE. Invent a comfortable four-second phrase that moves **both** hands. For example: open outward, lift, draw inward and settle. This is your phrase; the model has no supplied dance to copy. Begin from a repeatable arrangement.

Press CAPTURE. Arrange your hands during the three-second count-in. Move on beat 1, continue through eight beats at 120 BPM, and finish at four seconds. A click and the readout mark the time; SOUND toggles the click. STOP discards a pending performance. Lost tracking, a long frame or leaving the station's tracking range discards the whole take.

Each take becomes an array of records. Each record keeps elapsed seconds and the same ordered six values: left x, y, z, then right x, y, z. We still subtract the current head position and divide by 0.65 metres. The horizontal frame is aligned at the start of each take and stays fixed until it ends. This describes hands relative to your moving head; it is not a record of your route across the floor.

Capture at least three separate performances, then TRAIN. Three is an exercise minimum, not evidence of reliable recognition. UNDO removes the latest whole teaching take if you made a mistake. It invalidates the fitted result, so train again.

REPLAY previews the fitted phrase: pink is left, cyan is right. Both paths sit in the air, the tips follow time, and the same sphere follows their midpoint. The display is a bounded miniature; the recogniser uses the unaltered coordinates. The response is authored. It does not mean the system has invented choreography.

Choose TEST, then CAPTURE a **fresh** performance. Testing records an answer without moving the sphere or changing the learned path. TRY records a fresh performance too, but an accepted result then replays the model's path. During capture the learned paths are hidden so the preview does not become the answer you are tracing.

## Why this retains a sequence

The movement learner samples every valid take at 41 common times: 0.0, 0.1, …, 4.0 seconds. When a time falls between recorded samples, sample() interpolates between its two neighbours. A large missing interval is rejected before interpolation.

At each time, fit() averages the six coordinates across the teaching takes. This gives 41 six-number rows. The same mean operation from Perception now happens **separately at each time**. It cannot replace the first moment with the last without changing the model.

This is a learned prototype, not a recurrent neural network. It learns an average path and tolerances directly from examples; there is no backpropagation here. For fixed aligned samples, the coordinate-wise mean minimises summed squared coordinate error. The earlier neural classifier remains available as carried code, but a new kind of observation does not require pretending this prototype has its architecture.

Prediction compares corresponding times and computes a root-mean-square distance **for each hand**, plus its largest single-time error. A good left hand cannot hide a motionless right hand. The code requires a small amount of movement from both hands. That is an explicit two-hand exercise rule, not a universal definition of a phrase.

Limits come from teaching variation. For each take, the code measures its error from the mean of the *other* takes. It widens each hand's limit within fixed bounds, 0.14 to 0.32 coordinate units. Acceptance also caps peak error at 2.5 times that hand's limit. Multiplying distance by 0.65 converts it to metres. Training loss, these limits and the choice to reject are different things.

There is no time warping. The same route at very different moments can be rejected. A deliberate pause is data, not an interruption; missing tracking is an interruption. Conflicting teaching takes can make TRAIN refuse a fit rather than erase the conflict with a huge tolerance.

## Then A and B

ONE keeps its own model. Choose A and teach three complete takes; choose B and teach three more. You could teach the rising phrase as A and its reverse as B. TRAIN now fits both.

TEST and TRY compare the new take with **both** models, regardless of which teaching button was last selected. A/B selection tells the program where to store teaching or which model to preview; it never supplies the answer during inference.

- A or B: an accepted choice.
- UNKNOWN: neither prototype accepts the performance.
- AMBIGUOUS: both accept, but their normalised distances are too close to choose.

The comparison uses the worst hand's RMS distance divided by that model's hand limit. Smaller is closer. A difference below 0.20 with both candidates accepted is ambiguous. These scores are distances, not probabilities. Similar teaching under different names is a useful way to produce an ambiguous result deliberately.

SAVE keeps ONE in user://ada_student_phrase_v1.json or both classes in user://ada_student_phrase_ab_v1.json. LOAD validates the saved examples and fitted data before replacing anything; testing starts fresh. The older pose save is separate. Starting an empty scene keeps files on disk until SAVE overwrites the relevant student file. This small study retains only the latest 60 test results in memory; Synthesis will add a richer evaluation record.

## Read the code in this order

Start with valid_take and resample: what counts as a complete observation? Then follow fit, distances and predict: what does the fitted path keep? Read the two-phrase wrapper only after ONE makes sense. Finally trace begin_phrase → advance_phrase → complete_phrase in the host. It carries one whole take into either teaching or testing, and only TRY enables the response.

The three complete new files follow. The reconstruction test also extracts the three declared carried files from Perception's printed text, so no unprinted helper fills a gap.


## One phrase: complete learner

<!-- student-code:movement_learner.gd -->
```gdscript
extends RefCounted
## A learned, time-aligned two-hand prototype. Complete takes are observations.
## Timing is retained: no unordered pose bag and no time warping.
const SCHEMA := "ada-two-hand-phrase-1"
const SECONDS := 4.0
const STEPS := 41
const MAX_TAKES := 12
const MIN_LIMIT := 0.14
const MAX_LIMIT := 0.32
var examples: Array = []
var prototype: Array = []
var limits: Array = []
var tests: Array = []
var trained := false
var fit_error := 0.0
var message := "Record three complete takes of one phrase."

static func number(v: Variant, low: float, high: float) -> bool:
	return (v is float or v is int) and is_finite(float(v)) and float(v)>=low and float(v)<=high

static func valid_x(x: Variant) -> bool:
	if not x is Array or x.size()!=6: return false
	for v in x:
		if not number(v,-4,4): return false
	return true

static func valid_take(take: Variant) -> bool:
	if not take is Array or take.size()<40 or take.size()>100: return false
	var previous := -1.0
	for row in take:
		if not row is Dictionary or not number(row.get("t"),0,SECONDS) or not valid_x(row.get("x")): return false
		if float(row.t)<=previous or (previous>=0 and float(row.t)-previous>0.151): return false
		previous=float(row.t)
	return float(take[0].t)<=0.10 and float(take[-1].t)>=SECONDS-0.05

static func sample(take: Array, t: float) -> Array:
	if take.is_empty(): return []
	if t<=float(take[0].t): return take[0].x.duplicate()
	for i in range(1,take.size()):
		if t<=float(take[i].t):
			var a:Dictionary=take[i-1];var b:Dictionary=take[i]
			var amount:=inverse_lerp(float(a.t),float(b.t),t)
			var x:Array=[]
			for j in 6: x.append(lerpf(float(a.x[j]),float(b.x[j]),amount))
			return x
	return take[-1].x.duplicate()

static func resample(take: Array) -> Array:
	if not valid_take(take): return []
	var rows:Array=[]
	for i in STEPS: rows.append(sample(take,SECONDS*i/(STEPS-1)))
	return rows

static func hand_motion(rows: Array, hand: int) -> float:
	var mean:=Vector3.ZERO
	for x:Array in rows: mean+=Vector3(x[hand*3],x[hand*3+1],x[hand*3+2])/rows.size()
	var variance:=0.0
	for x:Array in rows: variance+=Vector3(x[hand*3],x[hand*3+1],x[hand*3+2]).distance_squared_to(mean)/rows.size()
	return sqrt(variance)

static func distances(a: Array, b: Array) -> Dictionary:
	var rms:=[0.0,0.0];var peak:=[0.0,0.0]
	for i in STEPS:
		for hand in 2:
			var squared:=0.0
			for j in 3: squared+=pow(float(a[i][hand*3+j])-float(b[i][hand*3+j]),2)
			rms[hand]+=squared/STEPS;peak[hand]=maxf(peak[hand],sqrt(squared))
	for hand in 2: rms[hand]=sqrt(rms[hand])
	return {"rms":rms,"peak":peak}

func invalidate() -> void:
	trained=false;prototype.clear();limits.clear();tests.clear();fit_error=0.0

func add_example(take: Array) -> bool:
	var rows:=resample(take)
	if rows.is_empty(): message="Incomplete or invalid take.";return false
	if hand_motion(rows,0)<0.07 or hand_motion(rows,1)<0.07: message="Move BOTH hands through the phrase.";return false
	if examples.size()>=MAX_TAKES: message="Maximum 12 takes. UNDO or RESET first.";return false
	examples.append(take.duplicate(true));invalidate()
	message="One complete phrase kept. Perform it again from the same start."
	return true

func undo() -> bool:
	if examples.is_empty(): return false
	examples.pop_back();invalidate();message="Last teaching take removed. Train again."
	return true

func fit() -> bool:
	invalidate()
	if examples.size()<3: message="Need at least three complete teaching takes.";return false
	var samples:Array=[]
	for take:Array in examples: samples.append(resample(take))
	for i in STEPS:
		var row:=[0.0,0.0,0.0,0.0,0.0,0.0]
		for take:Array in samples:
			for j in 6: row[j]+=float(take[i][j])/samples.size()
		prototype.append(row)
	limits=[MIN_LIMIT,MIN_LIMIT]
	var coherent:=true
	for take:Array in samples:
		var d:=distances(take,prototype)
		for hand in 2:
			# Residual to the average of the OTHER complete takes.
			var leave_one_out:float=d.rms[hand]*samples.size()/(samples.size()-1.0)
			coherent=coherent and leave_one_out<=MAX_LIMIT
			limits[hand]=clampf(maxf(limits[hand],leave_one_out*1.5+0.025),MIN_LIMIT,MAX_LIMIT)
			fit_error+=pow(float(d.rms[hand]),2)/(samples.size()*2)
	if not coherent:
		invalidate();message="Takes differ too much. UNDO an accidental take or RESET; teach one phrase.";return false
	trained=true;message="Timed paths fitted. Test a NEW performance."
	return true

func predict(take: Array) -> Dictionary:
	if not trained: return {}
	var rows:=resample(take)
	if rows.is_empty(): return {}
	var result:=distances(rows,prototype)
	var accepted:=true
	for hand in 2:
		accepted=accepted and result.rms[hand]<=limits[hand] and result.peak[hand]<=float(limits[hand])*2.5 and hand_motion(rows,hand)>=0.07
	result.accepted=accepted
	return result

func test_example(take: Array) -> Dictionary:
	var result:=predict(take)
	if result.is_empty(): return {}
	tests.append(result.duplicate(true))
	if tests.size()>60: tests.pop_front()
	return result

func target(t: float) -> Array:
	if not trained: return []
	var phase:=clampf(t/SECONDS,0,1)*(STEPS-1)
	var a:=mini(int(phase),STEPS-2)
	var result:Array=[]
	for j in 6: result.append(lerpf(prototype[a][j],prototype[a+1][j],phase-a))
	return result

func snapshot() -> Dictionary:
	return {"schema":SCHEMA,"seconds":SECONDS,"examples":examples.duplicate(true),"prototype":prototype.duplicate(true),"limits":limits.duplicate(),"trained":trained}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema")!=SCHEMA or data.get("seconds")!=SECONDS or not data.get("trained") is bool: return false
	if not data.get("examples") is Array or data.examples.size()>MAX_TAKES or not data.get("prototype") is Array or not data.get("limits") is Array: return false
	var candidate:RefCounted=get_script().new()
	for take:Variant in data.examples:
		if not take is Array or not candidate.add_example(take): return false
	if data.trained:
		if not candidate.fit() or data.prototype.size()!=STEPS or data.limits.size()!=2: return false
		for i in STEPS:
			if not valid_x(data.prototype[i]): return false
			for j in 6:
				if absf(float(data.prototype[i][j])-candidate.prototype[i][j])>1e-8: return false
		for hand in 2:
			if not number(data.limits[hand],MIN_LIMIT,MAX_LIMIT) or absf(data.limits[hand]-candidate.limits[hand])>1e-8: return false
	elif not data.prototype.is_empty() or not data.limits.is_empty(): return false
	examples=candidate.examples;prototype=candidate.prototype;limits=candidate.limits
	trained=candidate.trained;fit_error=candidate.fit_error;tests.clear()
	message="Loaded locally. Fresh tests begin here."
	return true

func save_file(path: String) -> Error:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  ",true,true))
	return file.get_error()

func load_file(path: String) -> bool:
	return restore(JSON.parse_string(FileAccess.get_file_as_string(path))) if FileAccess.file_exists(path) else false
```


## Two phrases: complete comparison

<!-- student-code:phrase_library.gd -->
```gdscript
extends RefCounted
## Two visitor-taught timed prototypes. Labels name examples, not dance quality.
const Learner := preload("movement_learner.gd")
const SCHEMA := "ada-two-hand-phrase-library-1"
const MARGIN := 0.20
var models: Dictionary = {"A": Learner.new(), "B": Learner.new()}
var tests: Array = []
var message := "Teach three whole takes of A and three of B."
var trained: bool:
	get: return models.A.trained and models.B.trained

func add_example(label: String, take: Array) -> bool:
	if not models.has(label): return false
	var kept: bool = models[label].add_example(take)
	message = label + " / " + models[label].message
	if kept: tests.clear()
	return kept

func undo(label: String) -> bool:
	if not models.has(label): return false
	var changed: bool = models[label].undo()
	message = label + " / " + models[label].message
	if changed: tests.clear()
	return changed

func fit() -> bool:
	tests.clear()
	var a: bool = models.A.fit()
	var b: bool = models.B.fit()
	if not a: message = "A / " + models.A.message
	elif not b: message = "B / " + models.B.message
	else: message = "A + B fitted. TEST a NEW whole performance."
	return a and b

func predict(take: Array) -> Dictionary:
	if not trained: return {}
	var a: Dictionary = models.A.predict(take)
	var b: Dictionary = models.B.predict(take)
	if a.is_empty() or b.is_empty(): return {}
	# Worst hand, relative to that prototype's limit. These are distances, not probabilities.
	var sa: float = maxf(a.rms[0]/models.A.limits[0], a.rms[1]/models.A.limits[1])
	var sb: float = maxf(b.rms[0]/models.B.limits[0], b.rms[1]/models.B.limits[1])
	var label := "UNKNOWN"
	if a.accepted and b.accepted:
		label = "AMBIGUOUS" if absf(sa-sb)<MARGIN else ("A" if sa<sb else "B")
	elif a.accepted: label = "A"
	elif b.accepted: label = "B"
	return {"label": label, "accepted": label in ["A", "B"], "scores": [sa,sb], "margin": absf(sa-sb), "candidates": {"A":a,"B":b}}

func test_example(take: Array) -> Dictionary:
	var result := predict(take)
	if result.is_empty(): return {}
	tests.append(result.duplicate(true))
	if tests.size()>60: tests.pop_front()
	return result

func snapshot() -> Dictionary:
	return {"schema":SCHEMA,"margin":MARGIN,"A":models.A.snapshot(),"B":models.B.snapshot()}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema")!=SCHEMA or data.get("margin")!=MARGIN: return false
	var a := Learner.new()
	var b := Learner.new()
	if not a.restore(data.get("A")) or not b.restore(data.get("B")): return false
	models={"A":a,"B":b};tests.clear();message="A + B loaded locally. Fresh tests begin here."
	return true

func save_file(path: String) -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  ",true,true))
	return file.get_error()

func load_file(path: String) -> bool:
	return restore(JSON.parse_string(FileAccess.get_file_as_string(path))) if FileAccess.file_exists(path) else false
```


## The carried sphere: complete extension

<!-- student-code:sequence_study.gd -->
```gdscript
extends "pose_study.gd"
## Keep the PointBody, tracking and coordinate function from Perception.
const Movement = preload("movement_learner.gd")
const Library = preload("phrase_library.gd")
const ONE_FILE := "user://ada_student_phrase_v1.json"
const TWO_FILE := "user://ada_student_phrase_ab_v1.json"
var one := Movement.new()
var library := Library.new()
var selected := "ONE"
var capturing := false
var phrase_time := 0.0
var pending: Array = []
var replay_time := -1.0
var replay_model: RefCounted
var result: Dictionary = {}
var rods: Array[MeshInstance3D] = []
var tips: Array[MeshInstance3D] = []
var click := AudioStreamPlayer3D.new()
var sound := true
var last_beat := -999

func _ready() -> void:
    super._ready() # Creates the same point, ring, collision, board and readout.
    if FileAccess.file_exists(SAVE_PATH): model.load_file(SAVE_PATH)
    remove_child(panel)
    panel.free()
    var rows: Array = []
    var commands: Array = []
    for names in [["ONE","A","B"],["CAPTURE","TEACH","TRAIN"],["TEST","TRY","REPLAY"],["UNDO","SAVE","LOAD"],["SOUND","STOP"]]:
        var row: Array = []
        for word in names:
            row.append({"type":"button","label":word})
            commands.append(word)
        rows.append(row)
    panel = Rack.create_panel("BOTH HANDS / A PHRASE KEPT", rows)
    panel.position = Vector3(0, 0.75, 0.8)
    panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE * 2
    add_child(panel)
    for i in commands.size():
        var button = panel.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area): command(commands[i]))
    readout.position.y = 2.38
    readout.font_size = 23
    for hand in 2:
        var ink := StandardMaterial3D.new()
        ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        ink.albedo_color = Color(1,0.22,0.55) if hand==0 else Color(0.1,0.8,1)
        for i in Movement.STEPS-1:
            var rod := MeshInstance3D.new()
            var tube := CylinderMesh.new()
            tube.top_radius=0.005; tube.bottom_radius=0.005; tube.height=1
            tube.radial_segments=6
            rod.mesh=tube; rod.material_override=ink; rod.hide()
            add_child(rod); rods.append(rod)
        var tip := MeshInstance3D.new()
        var ball := SphereMesh.new(); ball.radius=0.024; ball.height=0.048
        tip.mesh=ball; tip.material_override=ink; tip.hide()
        add_child(tip); tips.append(tip)
    click.stream=make_click(); click.volume_db=-18
    click.position=Vector3(0,1.4,0.2); click.max_distance=4
    add_child(click)
    mode="TEACH"; message="ONE: record three separate four-second phrases."
    refresh()

func active_model() -> RefCounted:
    return one if selected=="ONE" else library.models[selected]

func ready_to_test() -> bool:
    return one.trained if selected=="ONE" else library.trained

func stop() -> void:
    capturing=false; pending.clear(); replay_time=-1
    click.stop(); last_beat=-999

func command(which: String) -> void:
    if which=="STOP":
        stop(); message="Stopped. No partial take kept."; draw_phrase(); refresh(); return
    if which=="SOUND": sound=not sound; refresh(); return
    if capturing: return # The target cannot change halfway through a take.
    replay_time=-1; result.clear()
    if which in ["ONE","A","B"]:
        selected=which; mode="TEACH"; message="Teach %s. Earlier sets stay." % selected
    elif which=="TEACH": mode="TEACH"; message="CAPTURE a new whole performance."
    elif which=="TRAIN":
        var ok: bool=one.fit() if selected=="ONE" else library.fit()
        if ok: mode="TEST"
        message=one.message if selected=="ONE" else library.message
    elif which in ["TEST","TRY"]:
        if ready_to_test():
            mode=which; message="CAPTURE a fresh phrase; tests never train."
            if which=="TRY": begin_phrase()
        else: message="Teach three takes per set, then TRAIN."
    elif which=="CAPTURE": begin_phrase()
    elif which=="REPLAY":
        if active_model().trained:
            replay_model=active_model(); replay_time=0; last_beat=-999
            message="PREVIEW %s / learned mean, not a recognition result." % selected
        else: message="Train the selected phrase first."
    elif which=="UNDO":
        if selected=="ONE": one.undo(); message=one.message
        else: library.undo(selected); message=library.message
        mode="TEACH"
    elif which in ["SAVE","LOAD"]:
        var store=one if selected=="ONE" else library
        var path:=ONE_FILE if selected=="ONE" else TWO_FILE
        if which=="SAVE":
            message="Saved student phrase." if store.save_file(path)==OK else "Save failed."
        else:
            message="Loaded; collect fresh tests." if store.load_file(path) else "Invalid/missing save; current data kept."
            mode="TEST" if ready_to_test() else "TEACH"
    draw_phrase(); refresh()

func begin_phrase() -> void:
    bind_tracking()
    if not tracked(): message="Head and BOTH tracked hands needed here."; return
    if mode!="TEACH" and not ready_to_test(): message="Train before testing."; return
    align() # Same feature contract; horizontal frame held for this entire take.
    if not aligned: return
    capturing=true; phrase_time=-3.0; sample_time=0; pending.clear()
    replay_time=-1; last_beat=-999
    message="READY 3 / arrange both hands, then move for eight beats."

func _process(delta: float) -> void:
    if capturing:
        var valid:=tracked()
        var x:Array=features(head.global_position,left.global_position,right.global_position,facing) if valid else []
        advance_phrase(delta,x,valid)
    elif replay_time>=0:
        replay_time+=maxf(0,delta)
        if replay_time>Movement.SECONDS: replay_time=-1; click.stop()
        else: beat(replay_time)
    draw_phrase(); refresh()

func beat(t: float) -> void:
    var index:=int(floor(t)) if t<0 else int(floor(t/0.5))
    if index!=last_beat:
        last_beat=index
        if sound and t<Movement.SECONDS:
            click.pitch_scale=1.5 if t<0 else 1.0
            click.play()

func advance_phrase(delta: float, x: Array, valid: bool) -> void:
    if not capturing: return
    if not valid or not Movement.valid_x(x) or delta>0.15 or delta<0:
        stop(); message="Tracking/timing interrupted: WHOLE take discarded."; return
    phrase_time+=delta
    if phrase_time>=Movement.SECONDS-0.000001: phrase_time=Movement.SECONDS
    beat(phrase_time)
    if phrase_time<0:
        message="READY %d / arrange hands" % ceili(-phrase_time); return
    message="%s / BEAT %d OF 8 / move BOTH hands" % [mode,mini(8,int(phrase_time/0.5)+1)]
    sample_time+=delta
    if pending.is_empty() or sample_time>=0.05 or phrase_time>=Movement.SECONDS:
        sample_time=0
        if pending.is_empty() or phrase_time>float(pending[-1].t):
            pending.append({"t":phrase_time,"x":x.duplicate()})
    if phrase_time>=Movement.SECONDS: complete_phrase()

func complete_phrase() -> void:
    var take:=pending.duplicate(true)
    stop()
    if mode=="TEACH":
        if selected=="ONE": one.add_example(take); message=one.message
        else: library.add_example(selected,take); message=library.message
        return
    result=one.test_example(take) if selected=="ONE" else library.test_example(take)
    if result.is_empty(): message="Incomplete take discarded."; return
    if selected=="ONE":
        message="%s / L %.3f / R %.3f (distance)" % ["MATCH" if result.accepted else "UNKNOWN",result.rms[0],result.rms[1]]
        replay_model=one
    else:
        message="%s / distance A %.2f / B %.2f" % [result.label,result.scores[0],result.scores[1]]
        if result.accepted: replay_model=library.models[result.label]
    if mode=="TRY" and result.accepted: replay_time=0; last_beat=-999

func miniature(x: Array, hand: int) -> Vector3:
    # Only the displayed miniature is bounded. Recognition retains full data.
    return Vector3(0,1.65,0.15)+Vector3(x[hand*3],x[hand*3+1],x[hand*3+2]).limit_length(1.8)*0.4

func draw_phrase() -> void:
    var showing:bool=replay_time>=0 and replay_model!=null and replay_model.trained
    for hand in 2:
        for i in Movement.STEPS-1:
            var rod:=rods[hand*(Movement.STEPS-1)+i]
            rod.visible=showing
            if showing:
                var a:=miniature(replay_model.prototype[i],hand)
                var b:=miniature(replay_model.prototype[i+1],hand)
                var direction:=b-a
                rod.position=(a+b)*0.5
                rod.scale=Vector3(1,maxf(direction.length(),0.0001),1)
                rod.quaternion=Quaternion(Vector3.UP,direction.normalized()) if direction.length()>0.0001 else Quaternion.IDENTITY
        tips[hand].visible=showing
        if showing: tips[hand].position=miniature(replay_model.target(replay_time),hand)
    if sphere==null or sphere.is_picked_up(): return
    sphere.position=(tips[0].position+tips[1].position)*0.5 if showing else Vector3(0,1.15,0.15)
    surface.scale=Vector3.ONE
    material.albedo_color=Color(1,0.77,0.25) if showing else Color(0.75,0.78,0.82)

func refresh() -> void:
    # super._ready() calls this before the phrase panel is built.
    readout.text="BOTH HANDS / %s / %s\n" % [selected,mode]
    readout.text+="ONE %d takes / A %d / B %d\n" % [one.examples.size(),library.models.A.examples.size(),library.models.B.examples.size()]
    readout.text+=message+"\n8 BEATS / 120 BPM / 4 SECONDS\n"
    readout.text+="Fresh tests %d / sound %s" % [one.tests.size() if selected=="ONE" else library.tests.size(),"ON" if sound else "OFF"]

static func make_click() -> AudioStreamWAV:
    var wav:=AudioStreamWAV.new()
    wav.format=AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate=22050
    var bytes:=PackedByteArray(); bytes.resize(1102*2)
    for i in 1102:
        var t:=float(i)/wav.mix_rate
        bytes.encode_s16(i*2,int(sin(TAU*880*t)*exp(-t*100)*10000))
    wav.data=bytes
    return wav
```

## Predict a difference, then test it

Before running, predict what happens when you reverse the phrase, exchange the two hands, hold one hand still, or delay a large movement until the final beat. Keep the model fixed and try them as fresh tests. A particular symmetric phrase may survive reversal; rejection is not guaranteed merely because you intended a change. Inspect what actually changed in the recorded coordinates.

Then teach the reverse as B. What was previously unfamiliar can become a taught alternative. The rules of comparison did not change; its examples did. In another fresh experiment, teach near-identical phrases under A and B and inspect the ambiguous result. An independent demonstration of learning is being able to produce and explain both effects without editing the decision rule.

## Compare the room's other kind of memory

The gate cell uses a different representation. Its present state depends on the last state and the new token. Its three gate spheres are set by hand; the current exhibit does not train them. Our prototype keeps a time-indexed path from whole performances. Both involve earlier information, but only the latter fits this visitor's movement examples. Neither exercise implements a trained LSTM.

## Ghost-student reconstruction

Run python tools/test_ml_sequence_lesson.py from the project root. The test writes a fresh learner folder from this chapter's three code blocks plus Perception's three carried blocks. It tests interpolation and the fitted mean with independent calculations, then fresh, reversed, retimed, swapped-hand and stationary-hand fixtures. It checks A/B, unknown and ambiguous results; corrupt saves; whole-take capture with supplied XR trackers; and sphere identity across the controls.

It also mounts the reconstructed code in the actual Sequence Memory hall for a separate spatial/runtime check. Synthetic fixtures can establish that these mechanisms work and catch missing code. They cannot establish recognition across people or headset comfort. This is an author-informed ghost student, not an independent blind reader.

Carry the same point, the six-coordinate contract and a fitted ordered phrase onward. Generative changes the question: would the next result be a replay of what we kept, a sampled variation, or something produced by a trained generator? This chapter establishes the replay we must be able to distinguish from those other operations.
