extends Node3D
## A bounded application-frame interval monitor, not an entropy estimator.
## Seed capture supplies the exact intervals that it hashes; LIVE is independent.
const STAGE = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const RACK = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const CAPACITY := 240
const BASELINE_SAMPLES := 30
const RANGES := [0.0, 0.25, 1.0, 5.0, 20.0]
var intervals: Array = []
var mode := "LIVE"
var baseline_usec := 0.0
var range_index := 0
var range_ms := 1.0
var clipped := 0
var _previous := -1
var _baseline_samples: Array = []
var _draw_elapsed := 0.0
var trace: MeshInstance3D
var status: Label3D
var readings: Label3D
var axis: Label3D
var controls: Node3D
var kept_seed := -1

func _ready() -> void:
	name = "FrameJitterScope"
	set_meta("em_local_instrument",true)
	STAGE.box(self,Vector3(0,1.99,-0.04),Vector3(2.60,1.62,0.08),Color("101e24"))
	STAGE.box(self,Vector3(0,0.59,-0.1),Vector3(0.24,1.18,0.24),Color("273c40"),true)
	_label("THE TIME BETWEEN FRAMES",Vector3(0,2.69,0.015),36,Color("ffda98"))
	status = _label("",Vector3(0,2.55,0.015),27)
	readings = _label("",Vector3(0,1.58,0.015),27)
	axis = _label("",Vector3(0,1.78,0.015),22)
	var hall_seed = load("res://commons/artifacts/randomness_space/hall_seed.gd")
	var caption := "Variation is measured here. Entropy is not.\nThis trace does not change the hall seed." if hall_seed.enabled(self) else "Variation is measured here. Entropy is not.\nFRAMES + NEW SAMPLE keeps 120 intervals as a seed."
	_label(caption,Vector3(0,1.30,0.015),23,Color("ffda98"))
	trace = MeshInstance3D.new(); add_child(trace)
	controls = RACK.create_panel("FRAME TIMING",[[
		{"type":"button","label":"HOLD / LIVE","shape":"rect"},
		{"type":"button","label":"REBASE","shape":"rect"},
		{"type":"button","label":"RANGE","shape":"rect"}]])
	controls.set_meta("em_local_instrument",true)
	controls.position=Vector3(0,1.00,0.22)
	controls.rotation_degrees.x=-25
	controls.scale=Vector3.ONE*3.0
	add_child(controls)
	controls.find_child("Btn_0",true,false).pressed.connect(toggle_hold)
	controls.find_child("Btn_1",true,false).pressed.connect(rebase)
	controls.find_child("Btn_2",true,false).pressed.connect(cycle_range)
	redraw()

func _label(words: String, at: Vector3, size: int, colour: Color = Color("cde9de")) -> Label3D:
	var item := STAGE.label(self,words,at)
	item.font_size=size; item.pixel_size=0.00165; item.outline_size=0
	item.modulate=colour
	return item

func _process(delta: float) -> void:
	if mode != "LIVE": return
	observe_tick(Time.get_ticks_usec())
	# Sample every callback, but redraw the instrument at most 10 times/second.
	_draw_elapsed += delta
	if _draw_elapsed >= 0.10:
		_draw_elapsed=0.0
		redraw()

func observe_tick(now: int) -> void:
	if mode != "LIVE": return
	if _previous >= 0 and now > _previous: append_interval(now-_previous)
	_previous=now

func append_interval(usec: int) -> void:
	if usec <= 0: return
	intervals.append(usec)
	if intervals.size() > CAPACITY: intervals.pop_front()
	if _baseline_samples.size() < BASELINE_SAMPLES:
		_baseline_samples.append(usec)
		baseline_usec = mean(_baseline_samples)

func mean(values: Array) -> float:
	if values.is_empty(): return 0.0
	var total := 0.0
	for value in values: total += float(value)
	return total/values.size()

func resume_live() -> void:
	mode="LIVE"; kept_seed=-1; _previous=-1
	intervals.clear(); _baseline_samples.clear(); baseline_usec=0.0
	redraw()

func toggle_hold() -> void:
	# A view control must not silently interrupt or replace a seed recording.
	if mode == "RECORD": return
	if mode == "LIVE":
		mode="HOLD"; _previous=-1; redraw()
	else: resume_live()

func rebase() -> void:
	if intervals.is_empty() or mode == "RECORD": return
	baseline_usec=mean(intervals)
	# Lock this measured reference until the next explicit rebase or new run.
	_baseline_samples.resize(BASELINE_SAMPLES)
	redraw()

func cycle_range() -> void:
	range_index=(range_index+1)%RANGES.size()
	redraw()

func begin_recording() -> void:
	resume_live()
	mode="RECORD"
	redraw()

func record_interval(usec: int) -> void:
	if mode != "RECORD": return
	append_interval(usec)
	if intervals.size()%6==0: redraw()

func cancel_recording() -> void:
	if mode == "RECORD": resume_live()

func show_kept(receipt: Dictionary) -> void:
	intervals=receipt.get("intervals_usec",[]).duplicate()
	while intervals.size()>CAPACITY: intervals.pop_front()
	baseline_usec=mean(intervals)
	_baseline_samples.resize(BASELINE_SAMPLES)
	kept_seed=int(receipt.get("seed",-1)); mode="KEPT"; _previous=-1
	redraw()

func deviation_ms(index: int) -> float:
	return (float(intervals[index])-baseline_usec)/1000.0

func redraw() -> void:
	if not is_instance_valid(trace): return
	var peak := 0.0
	var span := 0.0
	for value in intervals:
		peak=maxf(peak,absf(float(value)-baseline_usec)/1000.0)
		span+=float(value)/1000000.0
	range_ms=float(RANGES[range_index])
	if range_index==0:
		range_ms=0.25
		while range_ms < peak: range_ms*=2.0
	clipped=0
	var mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo=true
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,mat)
	for column in range(11):
		var x := -1.12+2.24*column/10.0
		_line(mesh,Vector3(x,1.92,0.01),Vector3(x,2.44,0.01),Color("254642"))
	for row in range(5):
		var y := 1.92+row*0.13
		_line(mesh,Vector3(-1.12,y,0.01),Vector3(1.12,y,0.01),Color("9f8350") if row==2 else Color("254642"))
	for i in range(intervals.size()):
		if absf(deviation_ms(i))>range_ms: clipped+=1
		if i==0: continue
		var a := plot_point(i-1)
		var b := plot_point(i)
		var colour := Color("ffad78") if absf(deviation_ms(i))>range_ms else Color("8affca")
		# A 4 mm ribbon stays legible in the headset without simulating a pulse.
		for dy in [-0.002,0.0,0.002]:
			_line(mesh,a+Vector3.UP*dy,b+Vector3.UP*dy,colour)
	mesh.surface_end(); trace.mesh=mesh
	var title := "KEPT RECORDING · seed %d" % kept_seed if mode=="KEPT" else mode
	status.text="%s · %d frames · %.2f s" % [title,intervals.size(),span]
	var ref_name := "recording mean" if mode=="KEPT" else "reference"
	if _baseline_samples.size()<BASELINE_SAMPLES: ref_name="learning reference"
	var last := float(intervals.back())/1000.0 if not intervals.is_empty() else 0.0
	var change := deviation_ms(intervals.size()-1) if not intervals.is_empty() else 0.0
	readings.text="last %.3f ms   ·   difference %+.3f ms\n%s %.3f ms" % [last,change,ref_name,baseline_usec/1000.0]
	axis.text="frame index →   zero = reference   ±%.2f ms %s\n%d outside range" % [range_ms,"AUTO" if range_index==0 else "FIXED",clipped]

func plot_point(index: int) -> Vector3:
	return Vector3(-1.12+2.24*index/maxi(1,intervals.size()-1),2.18+0.26*clampf(deviation_ms(index)/range_ms,-1.0,1.0),0.025)

func _line(mesh: ImmediateMesh, a: Vector3, b: Vector3, colour: Color) -> void:
	mesh.surface_set_color(colour); mesh.surface_add_vertex(a); mesh.surface_add_vertex(b)
