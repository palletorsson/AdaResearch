extends "res://commons/artifacts/ambient_patch/ambient_listening_room.gd"
## After Alvin Lucier's I Am Sitting in a Room (1969).
## Reuses the instrument's physical UI construction, not its generative score.
const MemoryAudio = preload("res://commons/artifacts/ambient_patch/room_memory_audio.gd")
var walls: Array[MeshInstance3D] = []
var spectrum_mesh := ImmediateMesh.new()
var _last_surface := -1.0

func _ready() -> void:
	name = "ListeningRoom"
	audio = MemoryAudio.new()
	audio.name = "RoomMemoryAudio"
	add_child(audio)
	audio.state_changed.connect(_refresh)
	_build_room()
	_build_stations()
	_refresh()

func _build_room() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(.03,.04,.045)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(.83,.85,.85)
	environment.ambient_light_energy = .75
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	_box(self,"Floor",Vector3(6.18,.12,5.18),Vector3(0,-.06,0),Color(.18,.21,.22),true)
	_box(self,"Ceiling",Vector3(6.18,.12,5.18),Vector3(0,3.06,0),Color(.21,.24,.25),true)
	# Internal dimensions match the three round-trip delays in the acoustic model.
	_box(self,"Front",Vector3(6.18,3,.12),Vector3(0,1.5,-2.56),Color(.42,.46,.46),true)
	_box(self,"Left",Vector3(.12,3,5.18),Vector3(-3.06,1.5,0),Color(.42,.46,.46),true)
	_box(self,"Right",Vector3(.12,3,5.18),Vector3(3.06,1.5,0),Color(.42,.46,.46),true)
	for x in [-1.92,1.92]: _box(self,"Rear",Vector3(2.32,3,.12),Vector3(x,1.5,2.56),Color(.42,.46,.46),true)
	_box(self,"Lintel",Vector3(1.52,.6,.12),Vector3(0,2.7,2.56),Color(.42,.46,.46),true)
	for child in get_children():
		if child is MeshInstance3D and String(child.name) in ["Front","Left","Right"]: walls.append(child)
	# Six acoustic panels change with the actual damping control.
	for side in [-1,1]:
		for z in [-1.45,0.0,1.45]:
			_box(self,"Absorber_%s_%s"%[side,z],Vector3(.055,1.5,.94),Vector3(side*2.965,1.7,z),Color(.60,.57,.47))
	for child in get_children():
		if child is MeshInstance3D and String(child.name).begins_with("Absorber"): walls.append(child)
	for x in [-2.9,2.9]: _box(self,"FloorSeam",Vector3(.015,.006,4.8),Vector3(x,.005,0),MINT)
	for x in [-1.4,1.4]:
		_box(self,"LightStrip",Vector3(.055,.04,4.2),Vector3(x,2.96,0),Color(1,.85,.6))
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x,2.5,-.3)
		lamp.omni_range = 5
		lamp.light_energy = 1.3
		lamp.shadow_enabled = false
		add_child(lamp)
	_label(self,"ROOM MEMORY",Vector3(0,2.76,-2.48),Vector2(2.5,.18),GOLD)
	_label(self,"AFTER ALVIN LUCIER / I AM SITTING IN A ROOM / 1969",Vector3(0,2.55,-2.48),Vector2(3.3,.064),Color(.83,.9,.87))
	_label(self,"VOICE  >  ROOM  >  RECORDING  >  ROOM  >  ...",Vector3(0,2.32,-2.48),Vector2(3,.09),MINT)
	_box(self,"SpectrumBack",Vector3(3.5,.51,.05),Vector3(0,1.97,-2.47),Color(.025,.04,.05))
	var spectrum_view := MeshInstance3D.new()
	spectrum_view.name = "AudibleSpectrum"
	spectrum_view.mesh = spectrum_mesh
	spectrum_view.material_override = _material(MINT,true)
	add_child(spectrum_view)
	_label(self,"WHAT REMAINS AUDIBLE? / LIVE OUTPUT SPECTRUM",Vector3(0,1.66,-2.43),Vector2(3,.06),MINT)
	# A loudspeaker and a microphone make the source/receiver relation explicit.
	var speaker: Vector3 = audio.player.position
	_box(self,"Speaker",Vector3(.34,.53,.27),speaker,Color(.055,.065,.07))
	_box(self,"SpeakerStand",Vector3(.065,1.09,.065),Vector3(speaker.x,.545,speaker.z),Color(.12,.14,.14),true)
	for height in [-.12,.13]:
		var cone := MeshInstance3D.new()
		cone.mesh = CylinderMesh.new()
		cone.mesh.top_radius = .09 if height<0 else .05
		cone.mesh.bottom_radius = cone.mesh.top_radius
		cone.mesh.height = .016
		cone.rotation.x = PI/2
		cone.position = speaker+Vector3(0,height,.142)
		cone.material_override = _material(Color(.23,.26,.26))
		add_child(cone)
	_label(self,"PLAYBACK",speaker+Vector3(0,.36,.16),Vector2(.47,.045),GOLD)
	_box(self,"MicStem",Vector3(.023,1.15,.023),Vector3(1.95,.575,-1.92),Color(.12,.14,.15),true)
	var mic_head := MeshInstance3D.new()
	mic_head.mesh = SphereMesh.new()
	mic_head.mesh.radius = .065
	mic_head.mesh.height = .16
	mic_head.position = Vector3(1.95,1.23,-1.92)
	mic_head.material_override = _material(Color(.18,.21,.23))
	add_child(mic_head)
	_label(self,"VIRTUAL RETURN",Vector3(1.95,1.52,-1.9),Vector2(.68,.045),ROSE)
	_label(self,"The model records this room. Your headset records only the first phrase.",Vector3(0,.41,-2.47),Vector2(3.5,.055),Color(.8,.86,.82))
	var exit_area := Area3D.new()
	exit_area.name = "ExitDoor"
	exit_area.position = Vector3(0,1.05,2.64)
	exit_area.collision_layer = 0
	exit_area.collision_mask = 1|(1<<19)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(1.4,2.1,.14)
	exit_area.add_child(shape)
	exit_area.body_entered.connect(func(body):
		if body.is_in_group("player_body"): exit_requested.emit())
	add_child(exit_area)

func _build_stations() -> void:
	desk = Node3D.new()
	add_child(desk)
	var specs := [["VOICE",Vector3(-2.4,0,.1),PI/2,GOLD],
		["RETURN",Vector3(0,0,-1.96),0,MINT],
		["SURFACE",Vector3(2.4,0,.1),-PI/2,ROSE]]
	for spec in specs:
		var station := Node3D.new()
		station.name = String(spec[0]).capitalize()+"Station"
		station.position = spec[1]
		station.rotation.y = spec[2]
		desk.add_child(station)
		stations[spec[0]] = station
		var casing := Case.new()
		station.add_child(casing)
		casing.fit_rect(Vector2(0,1.06),Vector2(.86,.60),spec[3])
		_box(station,"Back",Vector3(.9,.65,.10),Vector3(0,1.06,-.065),Color(.055,.085,.095),true)
		_box(station,"Stand",Vector3(.075,.735,.08),Vector3(0,.3675,-.06),Color(.10,.14,.16),true)
		_label(station,spec[0],Vector3(0,1.29,.01),Vector2(.64,.066),spec[3])
	_button(stations.VOICE,"record","RECORD / END",Vector3(-.2,1.10,.03),ROSE,audio.record_toggle)
	_button(stations.VOICE,"demo","DEMO VOICE",Vector3(.2,1.10,.03),GOLD,audio.load_demo)
	_button(stations.VOICE,"original","HEAR ORIGINAL",Vector3(0,.87,.03),GOLD,audio.play_original)
	_button(stations.RETURN,"next","NEXT PASS",Vector3(-.2,1.10,.03),MINT,audio.next_pass)
	_button(stations.RETURN,"auto","AUTO / STOP",Vector3(.2,1.10,.03),MINT,audio.toggle_auto)
	_button(stations.RETURN,"replay","REPLAY",Vector3(-.2,.87,.03),GOLD,audio.play_current)
	_button(stations.RETURN,"reset","RESET",Vector3(.2,.87,.03),ROSE,audio.reset)
	for i in 2:
		var key: String = ["absorption","level"][i]
		var slider := PhysicalSlider.new()
		slider.continuous = true
		slider.param_name = "ABSORB" if i==0 else "LEVEL"
		slider.position = Vector3((i-.5)*.36,1.055,.03)
		slider.set_normalized_value(audio.absorption if i==0 else audio.level)
		if i==0: slider.value_changed.connect(audio.set_absorption)
		else: slider.value_changed.connect(audio.set_level)
		stations.SURFACE.add_child(slider)
		sliders[key] = slider
	_label(stations.SURFACE,"Changing the surface restarts the phrase.",Vector3(0,.8,.014),Vector2(.79,.028),Color(.82,.86,.82))
	var exit_station := Node3D.new()
	exit_station.name = "ExitStation"
	exit_station.position = Vector3(-1.15,0,2.14)
	exit_station.rotation.y = PI
	add_child(exit_station)
	stations.EXIT = exit_station
	_button(exit_station,"exit","BACK TO HALL",Vector3(0,1.12,.03),GOLD,func(): exit_requested.emit())
	_button(exit_station,"ambient","AMBIENT ROOM",Vector3(0,.89,.03),MINT,_ambient_room)
	_box(exit_station,"Stand",Vector3(.06,.79,.065),Vector3(0,.395,-.06),Color(.10,.14,.16),true)
	_label(exit_station,"RETURN TO THE MUSEUM",Vector3(0,1.45,.03),Vector2(1.12,.06),GOLD)
	display = Screen.new()
	display.size_m = Vector2(2.6,.31)
	display.position = Vector3(0,1.46,-2.4)
	add_child(display)
	display.preferred_font_size = 37

func _ambient_room() -> void:
	var travel = preload("res://commons/artifacts/ambient_patch/ambient_room_travel.gd")
	if travel.go(self,"res://commons/scenes/ambient_listening_room.tscn"): audio.stop()

func _process(delta: float) -> void:
	_ui_time += delta
	if _ui_time<.1: return
	_ui_time = 0
	_refresh()
	_read_spectrum()

func _refresh() -> void:
	if not display: return
	var mode := "AUTO" if audio.automatic else "MANUAL"
	display.heading.text = "PASS %02d / %s / %s"%[audio.generation,mode,audio.source_name.to_upper()]
	display.table.text = audio.status+"\n6 x 5 x 3 m / absorption %d%% / simplified three-axis model"%roundi(audio.absorption*100)
	if audio.recording: display.table.text = "RECORDING %.1f / 8 s / press RECORD again to finish\nStored only in this session."%audio._record_seconds
	display.refresh()
	if not is_equal_approx(_last_surface,audio.absorption):
		_last_surface = audio.absorption
		for wall in walls:
			wall.material_override.albedo_color = Color(.56,.57,.52).lerp(Color(.12,.23,.25),audio.absorption)
			wall.material_override.roughness = lerpf(.3,1,audio.absorption)

func _read_spectrum() -> void:
	spectrum_mesh.clear_surfaces()
	spectrum_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var analyzer: AudioEffectSpectrumAnalyzerInstance
	if not audio.bus_name.is_empty(): analyzer = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index(audio.bus_name),2)
	for i in 48:
		var start := 50.0*pow(80.0,i/48.0)
		var end := 50.0*pow(80.0,(i+1)/48.0)
		var magnitude := 0.0
		if analyzer and audio.player.playing: magnitude = analyzer.get_magnitude_for_frequency_range(start,end).length()
		var height := clampf((linear_to_db(maxf(magnitude,.000001))+70)/65,0,1)*.42
		var x := lerpf(-1.65,1.65,i/47.0)
		spectrum_mesh.surface_add_vertex(Vector3(x,1.745,-2.433))
		spectrum_mesh.surface_add_vertex(Vector3(x,1.745+height,-2.433))
	spectrum_mesh.surface_end()
