extends Node3D
## Shannon colour shares beside Boltzmann configurational entropy S_B / k_B.
## The state space has one A/B occupant at each labelled site, at fixed 8/8 counts.
const Model = preload("compartment_model.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const SCHEMA := "entropy-compartments/1"
const MAX_STATES := 1025
const DEFAULT_POINTER := "user://entropy-compartments-latest.json"
@export var experiment_seed := 435
@export var step_seconds := 0.75
@export_multiline var observation := ""
@export_multiline var next_change := ""
var pointer_path := DEFAULT_POINTER
var model = Model.new()
var rng := RandomNumberGenerator.new()
var history: Array[Dictionary] = []
var cursor := 0
var running := false
var replaying := false
var elapsed := 0.0
var message := "Move one A across the divider; compare both readings."
var cells: Array[MeshInstance3D] = []
var cell_labels: Array[Label3D] = []
var buttons: Dictionary = {}
var h_label: Label3D
var s_label: Label3D
var left_label: Label3D
var right_label: Label3D
var status: Label3D
var s_bar: MeshInstance3D
var s_needle: Node3D
var s_ticks: Array[MeshInstance3D] = []
const STEEL := Color("293d48")
const CYAN := Color("4bb9d1")
const AMBER := Color("ed9b47")
var last_saved_path := ""

func _ready() -> void:
	build()
	reset()

func _process(delta: float) -> void:
	if not running and not replaying: return
	elapsed += delta
	if elapsed < step_seconds: return
	elapsed = 0.0 # One visible event at a time; no frame-rate sampling claim.
	if replaying: replay_step()
	else: random_swap()

func state(action: String) -> Dictionary:
	return {"sites":model.sites.duplicate(), "rng_state":str(rng.state), "action":action}

func reset() -> void:
	running = false
	replaying = false
	elapsed = 0.0
	model = Model.new()
	rng.seed = experiment_seed
	history = [state("Separated baseline")]
	cursor = 0
	message = "Would one exchange change both dials? A LEFT - exchanges A with B."
	refresh()

func can_edit() -> bool:
	replaying = false
	if cursor >= MAX_STATES - 1:
		running = false
		message = "Record full. KEEP this trial, then RESET."
		refresh()
		return false
	return true

func retain(action: String) -> void:
	history.resize(cursor + 1) # A change during replay creates a new continuation.
	history.append(state(action))
	cursor += 1
	message = action
	refresh()

func change_left(amount: int) -> void:
	running = false
	if not can_edit(): return
	var wanted := 1 if amount < 0 else 0
	var left := -1
	var right := -1
	for i in range(8):
		if model.sites[i] == wanted: left = i; break
	for i in range(8, 16):
		if model.sites[i] != wanted: right = i; break
	if left < 0 or right < 0:
		message = "A left is already at its limit. No change."
		refresh()
		return
	model.exchange(left, right)
	retain("Authored exchange: sites %d and %d" % [left + 1, right + 1])

func same_k() -> void:
	running = false
	if not can_edit(): return
	var previous: Array = model.sites.duplicate()
	for start in [0, 8]:
		var held: int = model.sites[start]
		for i in range(start, start + 7): model.sites[i] = model.sites[i + 1]
		model.sites[start + 7] = held
	retain("SAME k: rotate within both compartments%s" % ["; no visible change" if model.sites == previous else ""])

func random_swap() -> void:
	if not can_edit(): return
	var i := rng.randi_range(0, 15)
	var j := rng.randi_range(0, 14)
	if j >= i: j += 1
	var equal: bool = model.sites[i] == model.sites[j]
	model.exchange(i, j)
	retain("Seeded swap: sites %d and %d%s" % [i + 1, j + 1, " (same colour)" if equal else ""])

func toggle_run() -> void:
	replaying = false
	running = not running
	elapsed = 0.0
	message = "Random swaps running" if running else "Paused; arrangement retained"
	refresh()

func capture() -> Dictionary:
	return {"schema":SCHEMA, "seed":str(experiment_seed), "cursor":cursor,
		"states":history.slice(0,cursor+1).duplicate(true), "observation":observation, "next_change":next_change,
		"engine":Engine.get_version_info().string, "model":"16-sites-fixed-8A-8B/1",
		"step_seconds":step_seconds}

func valid_record(record: Variant) -> bool:
	if not record is Dictionary or record.get("schema") != SCHEMA: return false
	if record.get("model") != "16-sites-fixed-8A-8B/1": return false
	if not record.get("seed") is String or not record.seed.is_valid_int(): return false
	if str(int(record.seed)) != record.seed: return false
	if not record.get("states") is Array or record.states.is_empty() or record.states.size() > MAX_STATES: return false
	var index = record.get("cursor")
	if not (index is int or index is float) or not is_finite(index) or index != int(index): return false
	if index < 0 or index >= record.states.size(): return false
	var period = record.get("step_seconds")
	if not (period is int or period is float) or not is_finite(period) or period < 0.1 or period > 10: return false
	for item in record.states:
		if not item is Dictionary or not item.get("sites") is Array or item.sites.size() != 16: return false
		var count := 0
		for value in item.sites:
			if not (value is int or value is float) or (value != 0 and value != 1): return false
			count += int(value)
		if count != 8: return false
		if not item.get("rng_state") is String or not item.rng_state.is_valid_int(): return false
		if str(int(item.rng_state)) != item.rng_state or not item.get("action") is String: return false
	return true

func restore(record: Variant, from_start := false) -> bool:
	if not valid_record(record): return false
	running = false
	replaying = false
	elapsed = 0.0
	experiment_seed = int(record.seed)
	step_seconds = float(record.step_seconds)
	history.assign(record.states.duplicate(true))
	if from_start: history.resize(int(record.cursor)+1)
	cursor = 0 if from_start else int(record.cursor)
	observation = str(record.get("observation", ""))
	next_change = str(record.get("next_change", ""))
	apply_current()
	message = "Loaded exact site record; no new draws."
	refresh()
	return true

func apply_current() -> void:
	model.sites.clear()
	for value in history[cursor].sites: model.sites.append(int(value))
	rng.state = int(history[cursor].rng_state)

func keep() -> String:
	running = false
	replaying = false
	var path := "user://entropy-compartments-%d-%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	var serial := 0
	while FileAccess.file_exists(path):
		serial += 1
		path = "user://entropy-compartments-%d-%d-%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec(), serial]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: message = "Could not save; current trial retained."; refresh(); return ""
	file.store_string(JSON.stringify(capture(), "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: message = "Save incomplete; current trial retained."; refresh(); return ""
	last_saved_path = path
	print("Entropy record: ", ProjectSettings.globalize_path(path))
	var pointer := FileAccess.open(pointer_path, FileAccess.WRITE)
	if pointer == null: message = "Record saved; see Output for file path."; refresh(); return path
	pointer.store_string(JSON.stringify({"path":path}))
	pointer.close()
	message = "KEPT %d events. REPLAY reads the saved record." % cursor
	refresh()
	return path

func replay_saved() -> bool:
	if not FileAccess.file_exists(pointer_path):
		message = "KEEP a trial first. REPLAY will read its saved states."
		refresh()
		return false
	var pointer = JSON.parse_string(FileAccess.get_file_as_string(pointer_path))
	if not pointer is Dictionary or not pointer.get("path") is String: return false
	var file := FileAccess.open(pointer.path, FileAccess.READ)
	if file == null or file.get_length() > 2000000: return false
	var record = JSON.parse_string(file.get_as_text())
	file.close()
	if not restore(record, true):
		message = "Incompatible record; current trial retained."
		refresh()
		return false
	last_saved_path = pointer.path
	replaying = history.size() > 1
	message = "REPLAY: reading saved arrangements, not resampling."
	refresh()
	return true

func replay_step() -> void:
	if cursor < history.size() - 1: cursor += 1; apply_current()
	replaying = cursor < history.size() - 1
	message = "Replay %d/%d: %s" % [cursor, history.size() - 1, history[cursor].action]
	refresh()

func build() -> void:
	# Surreal-lab vocabulary: dark steel, open specimen frames and actual gauges.
	# All ornamental geometry is static; only the measured Boltzmann dial moves.
	metal(box("Plinth",Vector3(2.42,0.14,1.46),Vector3(0,0.10,0.10),STEEL))
	metal(box("Cabinet",Vector3(2.22,0.68,1.18),Vector3(0,0.49,0.02),STEEL))
	metal(box("Table",Vector3(2.5,0.12,1.55),Vector3(0,0.91,0.10),STEEL,true))
	for x in [-1.05,1.05]:
		metal(box("Foot",Vector3(0.22,0.18,1.30),Vector3(x,0.10,0.10),STEEL))
		glow(box("FootLight",Vector3(0.12,0.025,0.012),Vector3(x,0.16,0.757),CYAN),CYAN,0.5)
	for i in 20:
		box("CabinetVent",Vector3(0.042,0.20,0.02),Vector3((i-9.5)*0.09,0.28,0.62),Color("111d25"))
	for x in [-0.60,0.60]:
		metal(cylinder("InstrumentPost",0.037,0.95,Vector3(x,1.39,-0.57),STEEL))
		metal(cylinder("PostCollar",0.07,0.08,Vector3(x,1.25,-0.57),STEEL))
		build_tray(x)
	box("Divider",Vector3(0.028,0.28,0.68),Vector3(0,1.10,-0.15),Color("9eaeb3"))
	build_gauge(-0.62,CYAN,false)
	build_gauge(0.62,AMBER,true)
	metal(box("TitlePlate",Vector3(2.45,0.15,0.06),Vector3(0,2.45,-0.50),STEEL))
	label("Title","TWO ACCOUNTS OF ONE ARRANGEMENT",Vector3(0,2.45,-0.462),25)
	h_label = label("Shannon","",Vector3(-0.62,1.92,-0.365),23)
	s_label = label("Boltzmann","",Vector3(0.62,1.92,-0.365),23)
	h_label.pixel_size=0.0021;s_label.pixel_size=0.0021
	glow(box("HBar",Vector3(0.66,0.025,0.012),Vector3(-0.62,1.72,-0.365),CYAN),CYAN,0.6)
	s_bar = glow(box("SBar",Vector3(0.66,0.025,0.012),Vector3(0.62,1.72,-0.365),AMBER),AMBER,0.6)
	label("HRange","0 to 1 bit / colour",Vector3(-0.62,1.66,-0.355),17).pixel_size=0.002
	label("SRange","0 to 8.497  (S_B / k_B)",Vector3(0.62,1.66,-0.355),17).pixel_size=0.002
	box("ContractPlate",Vector3(2.18,0.16,0.02),Vector3(0,0.48,0.67),Color("101f29"))
	label("Contract","16 labelled sites | 8 A + 8 B | Omega = C(8,k) x C(8,8-k)\nConfiguration model: no heat or temperature simulated.",Vector3(0,0.48,0.685),19)
	left_label = label("LeftCount","",Vector3(-0.60,1.38,-0.15),21)
	right_label = label("RightCount","",Vector3(0.60,1.38,-0.15),21)
	for i in 16:
		var half := 0 if i < 8 else 1
		var local := i % 8
		var at := Vector3((-0.60 if half == 0 else 0.60) + (local % 4 - 1.5)*0.23,1.12,-0.24+(local / 4)*0.26)
		metal(cylinder("SiteSocket_%02d" % i,0.088,0.035,at-Vector3(0,0.093,0),STEEL))
		label("Address_%02d" % i,"%02d" % (i+1),at+Vector3(0,-0.09,0.095),13)
		var mesh := SphereMesh.new()
		mesh.radius=0.075;mesh.height=0.15;mesh.radial_segments=16;mesh.rings=8
		var view := MeshInstance3D.new();view.name="Site_%02d" % (i+1);view.mesh=mesh;view.position=at
		var mat := StandardMaterial3D.new();mat.roughness=0.24;mat.metallic=0.12
		mat.emission_enabled=true;mat.emission_energy_multiplier=0.35;view.material_override=mat
		add_child(view);cells.append(view)
		cell_labels.append(label("Occupant_%02d" % i,"",at+Vector3(0,0.025,0.076),22,Color("101b20")))
	var actions := [change_left.bind(-1),change_left.bind(1),same_k,random_swap,toggle_run,reset,keep,replay_saved]
	var names := ["A LEFT -","A LEFT +","SAME k","ONE SWAP","RUN / PAUSE","RESET","KEEP","REPLAY"]
	for i in names.size():
		var button = load("res://commons/interactables/push_button.tscn").instantiate()
		button.name = "Control_%d" % i
		Rack.make_button_rectangular(button)
		button.position=Vector3((i%4-1.5)*0.57,0.98,0.48+(i/4)*0.29)
		# Both rows face up: front-facing rows at the same height block each other.
		button.rotation=Vector3.ZERO;button.scale=Vector3.ONE*1.5
		button.released_color=Color("3f6773");button.released_emission_energy=0.12
		add_child(button);button.pressed.connect(actions[i]);buttons[names[i]]=button
		box("ButtonCaption_%d" % i,Vector3(0.49,0.016,0.08),button.position+Vector3(0,0.01,0.105),Color("17282f"))
		var words: String="SAME k / WITHIN TRAYS" if names[i]=="SAME k" else names[i]
		var caption:=label("ButtonLabel_%d" % i,words,button.position+Vector3(0,0.022,0.105),17 if names[i]=="SAME k" else 21)
		caption.rotation.x=-PI/2
	box("StatusPlate",Vector3(2.36,0.17,0.02),Vector3(0,0.80,0.90),Color("101f29"))
	status=label("Status","",Vector3(0,0.80,0.916),19)

func build_tray(x: float) -> void:
	metal(box("SpecimenTray",Vector3(1.08,0.065,0.69),Vector3(x,1.005,-0.15),STEEL))
	box("TrayInset",Vector3(0.98,0.012,0.59),Vector3(x,1.044,-0.15),Color("0f222a"))
	for side in [-1.0,1.0]:
		for depth in [-0.47,0.17]:
			metal(cylinder("TrayStanchion",0.019,0.29,Vector3(x+side*0.52,1.18,depth),STEEL))
		glass(box("SideGlass",Vector3(0.008,0.26,0.62),Vector3(x+side*0.51,1.18,-0.15),CYAN))
		metal(box("SideRail",Vector3(0.026,0.026,0.68),Vector3(x+side*0.52,1.33,-0.15),STEEL))
	glass(box("RearGlass",Vector3(1.02,0.26,0.008),Vector3(x,1.18,-0.47),CYAN))
	# The front and top stay open so the site labels are not behind glass.
	for depth in [-0.48,0.18]:
		glow(box("TrayRim",Vector3(1.02,0.014,0.014),Vector3(x,1.047,depth),CYAN),CYAN,0.35)

func build_gauge(x: float, colour: Color, changing: bool) -> void:
	var center := Vector3(x,1.88,-0.46)
	var housing := cylinder("GaugeHousing",0.49,0.10,center,STEEL)
	housing.rotation.x=PI/2;metal(housing)
	var face := cylinder("GaugeFace",0.446,0.012,center+Vector3(0,0,0.06),Color("0b1922"))
	face.rotation.x=PI/2
	var rim := MeshInstance3D.new();rim.name="GaugeRim"
	var torus:=TorusMesh.new();torus.inner_radius=0.455;torus.outer_radius=0.485
	torus.rings=40;torus.ring_segments=8;rim.mesh=torus;rim.position=center+Vector3(0,0,0.067);rim.rotation.x=PI/2
	var mat:=StandardMaterial3D.new();mat.albedo_color=STEEL;rim.material_override=mat
	add_child(rim);metal(rim)
	for i in 25:
		var angle:=lerpf(-PI*0.75,PI*0.75,i/24.0)
		var tick:=box("GaugeTick",Vector3(0.012,0.035 if i%4==0 else 0.022,0.01),center+Vector3(sin(angle)*0.405,cos(angle)*0.405,0.09),colour)
		tick.rotation.z=-angle;glow(tick,colour,0.6)
		if changing: s_ticks.append(tick)
	# Needles live on the outer arc, leaving the numerical reading unobstructed.
	var pivot:=Node3D.new();pivot.name="BoltzmannNeedle" if changing else "ShannonNeedle"
	pivot.position=center+Vector3(0,0,0.105);add_child(pivot)
	var needle:=box("DialPointer",Vector3(0.016,0.075,0.012),Vector3(0,0.365,0),colour)
	remove_child(needle);pivot.add_child(needle);glow(needle,colour,0.9)
	if changing: s_needle=pivot
	else: pivot.rotation.z=-PI*0.75
	for side in [-1,1]:
		var clamp:=box("GaugeClamp",Vector3(0.07,0.14,0.12),center+Vector3(side*0.475,0,0.005),STEEL)
		metal(clamp)

func cylinder(name_text: String, radius: float, height: float, at: Vector3, colour: Color) -> MeshInstance3D:
	var view:=MeshInstance3D.new();view.name=name_text;view.position=at
	var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=height;mesh.radial_segments=32
	view.mesh=mesh;var mat:=StandardMaterial3D.new();mat.albedo_color=colour;view.material_override=mat
	add_child(view);return view

func metal(view: MeshInstance3D) -> MeshInstance3D:
	var mat: StandardMaterial3D=view.material_override
	mat.metallic=0.75;mat.roughness=0.32;mat.emission_enabled=true
	mat.emission=STEEL;mat.emission_energy_multiplier=0.20
	return view

func glow(view: MeshInstance3D, colour: Color, energy: float) -> MeshInstance3D:
	var mat: StandardMaterial3D=view.material_override
	mat.emission_enabled=true;mat.emission=colour;mat.emission_energy_multiplier=energy
	mat.roughness=0.32;return view

func glass(view: MeshInstance3D) -> void:
	var mat: StandardMaterial3D=view.material_override
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color=Color(0.30,0.66,0.74,0.10);mat.roughness=0.16
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	view.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func refresh() -> void:
	if cells.is_empty(): return
	for i in 16:
		var colour: Color=AMBER if model.sites[i] else CYAN
		cells[i].material_override.albedo_color=colour
		cells[i].material_override.emission=colour
		cell_labels[i].text="A" if model.sites[i] else "B"
	var k: int=model.a_left()
	h_label.text="SHANNON\nH = %.3f bits\ncolour shares: 8 A / 8 B" % model.shannon_colour()
	s_label.text="BOLTZMANN\nS_B / k_B = %.3f\nOmega = %d" % [model.boltzmann_over_kb(),model.multiplicity()]
	left_label.text="LEFT: %d A / %d B" % [k,8-k]
	right_label.text="RIGHT: %d A / %d B" % [8-k,k]
	var fraction: float=model.boltzmann_over_kb()/log(4900.0)
	s_bar.visible=fraction>0
	s_bar.scale.x=maxf(fraction,0.001)
	s_bar.position.x=0.62-0.33+0.33*fraction
	s_needle.rotation.z=-lerpf(-PI*0.75,PI*0.75,fraction)
	for i in s_ticks.size():
		var lit: bool=i/24.0<=fraction
		s_ticks[i].material_override.albedo_color=AMBER if lit else Color("34444d")
		s_ticks[i].material_override.emission_energy_multiplier=0.6 if lit else 0.0
	status.text="%s\nseed %d | event %d/%d%s" % [message,experiment_seed,cursor,history.size()-1," | REPLAY" if replaying else (" | RUN" if running else "")]
	status.text+="\nTouch a cap, or point + trigger."
	buttons["RUN / PAUSE"].set_selected(running)

func box(name_text: String, size: Vector3, at: Vector3, colour: Color, solid := false) -> MeshInstance3D:
	var view := MeshInstance3D.new();view.name=name_text
	var mesh := BoxMesh.new();mesh.size=size;view.mesh=mesh;view.position=at
	var mat := StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=0.85;view.material_override=mat
	add_child(view)
	if solid:
		var body := StaticBody3D.new();body.collision_layer=1;body.collision_mask=0
		var hit := CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;hit.shape=shape
		view.add_child(body);body.add_child(hit)
	return view

func label(name_text: String, text: String, at: Vector3, size: int, colour := Color("eff2e9")) -> Label3D:
	var view := Label3D.new();view.name=name_text;view.text=text;view.position=at
	view.font_size=size;view.pixel_size=0.0025;view.modulate=colour;view.outline_size=0
	add_child(view)
	return view
