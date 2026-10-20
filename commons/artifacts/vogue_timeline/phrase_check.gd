extends RefCounted
const Evaluation := preload("res://commons/artifacts/vogue_timeline/phrase_evaluation.gd")
const Rack := preload("res://commons/audio/rack_templates/RackTemplates.gd")
var owner:WeakRef
var lesson:RefCounted:
	get:return owner.get_ref()
var journal:=Evaluation.new()
var active:=false
var intent:=""
var labels:Array[Label3D]=[]
var cells:Array[Label3D]=[]
var footer:Label3D
var clear_until:=0
var export_path:="user://ada_phrase_checks_v1.json"
var totals:Dictionary={}
var status_width:=690.0

func _init(value:RefCounted) -> void: owner=weakref(value)

func enter() -> void:
	lesson.cancel();lesson.replay_time=-1;lesson.result.clear()
	active=true;intent="";lesson.mode="CHECK";clear_until=0
	status_width=lesson.station.status.width;lesson.station.status.width=520
	totals=journal.summary(lesson.library)
	var rows:Array=[]
	for names in [["MEAN A","MEAN B","NEITHER"],["CAPTURE","EXPORT","CLEAR"],["BACK","POSE","HEIGHT","PHRASE"]]:
		var row:Array=[]
		for name in names:row.append({"type":"button","label":name})
		rows.append(row)
	lesson.station.replace_controls(Rack.create_panel("CHECK / YOUR INTENTION",rows))
	var commands:=["EXPECT_A","EXPECT_B","EXPECT_OTHER","CAPTURE","EXPORT_CHECKS","CLEAR_CHECKS","BACK","POSE","HEIGHT","PHRASE"]
	for i in commands.size():
		var button=lesson.station.controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
		button.button_pressed.connect(func(_area):lesson.station.command(commands[i]))
	var xs:=[-0.54,-0.23,-0.01,0.21,0.42]
	for col in 5:
		labels.append(lesson.station._label(["MEANT","A","B","UNK","AMB"][col],Vector3(xs[col],1.77,-0.40),21,Color(0.6,0.85,1),0.0018))
	for row in 3:
		labels.append(lesson.station._label(["A","B","OTHER"][row],Vector3(xs[0],1.62-row*0.14,-0.40),21,Color.WHITE,0.0018))
		for col in 4:
			var label=lesson.station._label("0",Vector3(xs[col+1],1.62-row*0.14,-0.40),24,Color.WHITE,0.0018)
			labels.append(label);cells.append(label)
	footer=lesson.station._label("",Vector3(0,1.17,-0.4),17,Color.WHITE,0.0018);labels.append(footer)
	lesson.message="Choose MEAN A, MEAN B or NEITHER; then CAPTURE."
	lesson.refresh();lesson.draw()

func leave(rebuild:bool=true) -> void:
	if not active:return
	active=false;intent="";lesson.cancel();lesson.replay_time=-1;lesson.result.clear()
	for label in labels:lesson.station.remove_child(label);label.queue_free()
	labels.clear();cells.clear();lesson.station.metrics.visible=true
	lesson.station.status.width=status_width
	for beat in lesson.beats:beat.visible=true
	for label in lesson.beat_numbers:label.visible=true
	lesson.beat_caption.visible=true
	if rebuild:
		lesson.build_controls();lesson.mode="TEST" if lesson.library.trained else "TEACH"
		lesson.message="Check history kept. A/B to teach new takes; TRAIN, then CHECK again."
		lesson.refresh();lesson.draw()

func command(which:String) -> void:
	if which=="BACK":leave();return
	if lesson.capturing:
		lesson.message="Intention locked for this take. BACK cancels it."
		return
	if which.begins_with("EXPECT_"):
		var choice:=which.trim_prefix("EXPECT_")
		if choice in Evaluation.INTENTS:
			intent=choice;lesson.message="Next take: %s. CAPTURE when ready; this label does not guide prediction."%intent
	elif which=="CAPTURE":lesson.begin_capture()
	elif which=="EXPORT_CHECKS":
		lesson.message="Check history + model versions exported locally." if journal.export_file(export_path)==OK else "Export failed. History remains."
	elif which=="CLEAR_CHECKS":
		if Time.get_ticks_msec()<clear_until:
			journal.clear();totals=journal.summary(lesson.library);clear_until=0;lesson.message=journal.message
		else:clear_until=Time.get_ticks_msec()+4000;lesson.message="Press CLEAR again within four seconds. Teaching data remains."
	lesson.refresh();lesson.draw()

func complete(take:Array) -> void:
	var row:=journal.record(lesson.library,take,intent)
	lesson.result={} if row.is_empty() else row.result.duplicate(true)
	lesson.message=journal.message
	totals=journal.summary(lesson.library)
	intent="" # Each new check requires an explicit intention; never reuse one silently.
	lesson.replay_time=-1

func refresh() -> void:
	lesson.station.status.text=lesson.message
	lesson.station.count_label.text="CHECK / MEAN %s"%(intent if intent!="" else "? / CHOOSE FIRST")
	lesson.station.metrics.text="Intention locked: %s / recording BOTH hands"%intent
	for row in 3:
		for col in 4:cells[row*4+col].text=str(totals.matrix[row][col])
	footer.text="%d THIS MODEL / %d EARLIER\nColumns = model answer / counts, not a dance score"%[totals.total,totals.previous]

func draw() -> void:
	lesson.station.metrics.visible=lesson.capturing
	for label in labels:label.visible=not lesson.capturing
	for beat in lesson.beats:beat.visible=lesson.capturing
	for label in lesson.beat_numbers:label.visible=lesson.capturing
	lesson.beat_caption.visible=lesson.capturing
