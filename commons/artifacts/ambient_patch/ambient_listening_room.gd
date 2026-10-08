extends Node3D
## Walk-in instrument room. Each wall station has a clear standing approach.
signal exit_requested
const Audio = preload("res://commons/artifacts/ambient_patch/ambient_patch_audio.gd")
const PhysicalSlider = preload("res://commons/interactables/physical_stepped_slider.gd")
const Baked = preload("res://commons/utils/baked_text_albedo.gd")
const Case = preload("res://commons/ui/instrument_panel_case.gd")
const Screen = preload("res://commons/ui/data_instrument_surface.gd")
const GOLD := Color(.94,.68,.34)
const MINT := Color(.35,.85,.76)
const ROSE := Color(.86,.34,.57)
var audio: Node3D
var desk: Node3D
var sliders: Dictionary = {}
var buttons: Dictionary = {}
var display: Node3D
var sources: Array[Node3D] = []
var environment: Environment
var entry := Transform3D(Basis.IDENTITY,Vector3(0,0,2.05))
var stations: Dictionary = {}
var _scope := ImmediateMesh.new()
var _flash := [0.0,0.0,0.0]
var _ui_time := 0.0
var _peak := 0.0

func _ready() -> void:
	name = "ListeningRoom"
	audio = Audio.new()
	audio.name = "AmbientAudio"
	audio.spatial_orbit = true
	audio.source_positions = PackedVector3Array([Vector3(-2.35,1.35,-.75),Vector3(0,1.7,2.1),Vector3(2.35,1.35,-.75)])
	add_child(audio)
	audio.note_started.connect(func(lane: int, _midi: int): _flash[lane] = 1.0)
	audio.state_changed.connect(_refresh)
	_build_room()
	_build_stations()
	_build_sources()
	_refresh()

func _build_room() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(.025,.038,.047)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(.71,.81,.80)
	environment.ambient_light_energy = .72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	_cylinder(self,"Floor",3.22,.08,Vector3(0,-.04,0),Color(.12,.16,.17),true)
	_cylinder(self,"Ceiling",3.22,.08,Vector3(0,2.94,0),Color(.12,.14,.16),true)
	# A 30-degree opening behind the entry view makes a clear 1.6-metre doorway.
	var wall := SurfaceTool.new()
	wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 44:
		var a := deg_to_rad(-165.0+i*7.5)
		var b := deg_to_rad(-165.0+(i+1)*7.5)
		var p := Vector3(sin(a)*3.1,0,-cos(a)*3.1)
		var q := Vector3(sin(b)*3.1,0,-cos(b)*3.1)
		for vertex in [p,q,p+Vector3.UP*2.9,q,q+Vector3.UP*2.9,p+Vector3.UP*2.9]: wall.add_vertex(vertex)
		var collision := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		shape.shape.size = Vector3(p.distance_to(q)+.02,2.9,.10)
		collision.position = (p+q)*.5+Vector3.UP*1.45
		collision.rotation.y = -(a+b)*.5
		collision.add_child(shape)
		add_child(collision)
	wall.generate_normals()
	var shell := MeshInstance3D.new()
	shell.name = "CurvedWall"
	shell.mesh = wall.commit()
	shell.material_override = _material(Color(.15,.23,.245))
	shell.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	add_child(shell)
	# Repeated wood fins share one draw call.
	var fins := MultiMeshInstance3D.new()
	fins.name = "AcousticFins"
	fins.multimesh = MultiMesh.new()
	fins.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	fins.multimesh.mesh = BoxMesh.new()
	fins.multimesh.mesh.size = Vector3(.032,2.62,.07)
	fins.multimesh.instance_count = 89
	for i in 89:
		var angle := deg_to_rad(-165.0+i*330.0/88)
		fins.multimesh.set_instance_transform(i,Transform3D(Basis(Vector3.UP,-angle),Vector3(sin(angle)*3.045,1.48,-cos(angle)*3.045)))
	fins.material_override = _material(Color(.32,.20,.12))
	add_child(fins)
	_arc(self,"CeilingLight",2.84,2.9,2.72,-165,165,GOLD,true)
	_arc(self,"FloorLight",2.89,2.91,.022,-165,165,MINT,true)
	_arc(self,"ListeningMark",.53,.55,.008,-180,180,GOLD,true)
	_label(self,"SLOW CIRCUITS",Vector3(0,2.63,-2.89),Vector2(2.2,.18),GOLD)
	_label(self,"THREE CLOCKS / ONE LISTENING BODY",Vector3(0,2.43,-2.89),Vector2(2.35,.085),MINT)
	_box(self,"ScopeBacking",Vector3(2.75,.38,.065),Vector3(0,2.15,-2.90),Color(.025,.045,.05))
	var scope_mesh := MeshInstance3D.new()
	scope_mesh.name = "RoomOutputWaveform"
	scope_mesh.mesh = _scope
	scope_mesh.material_override = _material(MINT,true)
	scope_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(scope_mesh)
	_label(self,"OUTPUT / THE SOUND YOU ARE HEARING",Vector3(0,1.91,-2.87),Vector2(2.3,.075),Color(.68,.79,.78))
	var exit_label := Node3D.new()
	exit_label.position = Vector3(0,2.34,2.92)
	exit_label.rotation.y = PI
	add_child(exit_label)
	_label(exit_label,"RETURN TO THE MUSEUM",Vector3.ZERO,Vector2(1.45,.095),GOLD)
	var exit_area := Area3D.new()
	exit_area.name = "ExitDoor"
	exit_area.position = Vector3(0,1.05,2.79)
	exit_area.collision_layer = 0
	exit_area.collision_mask = 1 | (1 << 19)
	var exit_shape := CollisionShape3D.new()
	exit_shape.shape = BoxShape3D.new()
	exit_shape.shape.size = Vector3(1.25,2.1,.24)
	exit_area.add_child(exit_shape)
	exit_area.body_entered.connect(func(body):
		if body.is_in_group("player_body"): exit_requested.emit())
	add_child(exit_area)
	for at in [Vector3(-1.7,2.3,-1.2),Vector3(1.7,2.3,-1.2)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.omni_range = 4.0
		lamp.light_energy = 1.1
		lamp.light_color = Color(1,.82,.64)
		lamp.shadow_enabled = false
		add_child(lamp)

func _build_stations() -> void:
	desk = Node3D.new()
	desk.name = "WallStations"
	add_child(desk)
	var layouts := [
		["RHYTHM",-70.0,["density","rate"],GOLD,"allow a note / leave a gap"],
		["TONE",0.0,["warmth","level"],MINT,"change the edge / change the level"],
		["SPACE",70.0,["space","drift"],ROSE,"leave echoes / move the sources"]]
	for layout in layouts:
		var angle := deg_to_rad(float(layout[1]))
		var station := Node3D.new()
		station.name = String(layout[0]).capitalize()+"Station"
		station.position = Vector3(sin(angle)*2.30,0,-cos(angle)*2.30)
		station.rotation.y = -angle
		desk.add_child(station)
		stations[layout[0]] = station
		var casing := Case.new()
		station.add_child(casing)
		casing.fit_rect(Vector2(0,1.09),Vector2(.73,.62),layout[3])
		_box(station,"StationFace",Vector3(.73,.62,.008),Vector3(0,1.09,.005),Color(.05,.085,.095))
		_box(station,"CabinetBack",Vector3(.79,.68,.10),Vector3(0,1.09,-.067),Color(.06,.09,.11),true)
		_label(station,layout[0],Vector3(0,1.34,.014),Vector2(.60,.058),layout[3])
		_label(station,layout[4],Vector3(0,1.255,.014),Vector2(.66,.027),Color(.78,.85,.83))
		for x in [-.26,.26]: _box(station,"Support",Vector3(.035,.72,.065),Vector3(x,.36,-.055),Color(.10,.14,.15),true)
		var names: Array = layout[2]
		for i in 2:
			var slider := PhysicalSlider.new()
			slider.name = names[i].capitalize()+"Slider"
			slider.continuous = true
			slider.param_name = names[i].to_upper()
			slider.position = Vector3((i-.5)*.29,1.045,.035)
			slider.set_normalized_value(audio.parameters[names[i]])
			_connect_slider(slider,names[i])
			station.add_child(slider)
			sliders[names[i]] = slider
	_button(stations.RHYTHM,"transport","PLAY / STOP",Vector3(-.17,.79,.035),MINT,_transport)
	_button(stations.RHYTHM,"seed","NEW SEED",Vector3(.17,.79,.035),GOLD,audio.new_seed)
	_button(stations.SPACE,"route","LFO ROUTE",Vector3(0,.79,.035),ROSE,_route)
	var exit_station := Node3D.new()
	exit_station.name = "ExitStation"
	exit_station.position = Vector3(-1.02,0,2.61)
	exit_station.rotation.y = PI
	add_child(exit_station)
	stations.EXIT = exit_station
	_button(exit_station,"exit","BACK TO HALL",Vector3(0,1.02,.015),GOLD,func(): exit_requested.emit())
	_box(exit_station,"ReturnPedestal",Vector3(.06,.91,.06),Vector3(0,.455,-.045),Color(.10,.14,.15),true)
	display = Screen.new()
	display.name = "RoomReadout"
	display.size_m = Vector2(1.46,.23)
	display.position = Vector3(0,1.66,-2.86)
	add_child(display)
	display.heading.position = Vector2(24,12)
	display.heading.add_theme_font_size_override("font_size",41)
	display.viewport.get_child(2).position.y = 83
	display.table.position = Vector2(24,102)
	display.table.add_theme_font_size_override("font_size",31)

func _connect_slider(slider: Node3D, key: String) -> void:
	slider.value_changed.connect(func(value: float): audio.set_parameter(key,value))

func _button(parent: Node3D, key: String, caption: String, at: Vector3, color: Color, action: Callable) -> void:
	var mount := Node3D.new()
	mount.position = at
	parent.add_child(mount)
	var casing := Case.new()
	mount.add_child(casing)
	casing.fit_rect(Vector2.ZERO,Vector2(.23,.12),color)
	var button: Node3D = load("res://commons/interactables/push_button.tscn").instantiate()
	button.name = key.capitalize()+"Button"
	button.position = Vector3(0,.016,.022)
	button.released_color = color
	button.play_press_sound = false
	button.pressed.connect(action)
	mount.add_child(button)
	buttons[key] = button
	_label(mount,caption,Vector3(0,-.047,.006),Vector2(.215,.025),Color(.90,.94,.9))

func _build_sources() -> void:
	for i in 3:
		var source := Node3D.new()
		source.name = "SoundPosition%d" % i
		source.position = audio.source_positions[i]
		add_child(source)
		var sphere := MeshInstance3D.new()
		sphere.mesh = SphereMesh.new()
		sphere.mesh.radius = .105
		sphere.mesh.height = .21
		sphere.mesh.radial_segments = 16
		sphere.mesh.rings = 8
		sphere.material_override = _material([GOLD,ROSE,MINT][i],true)
		source.add_child(sphere)
		var ring := MeshInstance3D.new()
		ring.mesh = TorusMesh.new()
		ring.mesh.inner_radius = .19
		ring.mesh.outer_radius = .204
		ring.mesh.rings = 24
		ring.mesh.ring_segments = 6
		ring.rotation.x = PI/2
		ring.material_override = _material([GOLD,ROSE,MINT][i],true)
		source.add_child(ring)
		sources.append(source)

func _transport() -> void:
	if audio.wanted or audio.playing: audio.stop()
	else: audio.start()

func _route() -> void:
	audio.set_route("pan" if audio.route == "filter" else "filter")

func _process(delta: float) -> void:
	_ui_time += delta
	if _ui_time < .1: return
	_ui_time = 0
	for i in 3:
		_flash[i] = maxf(0,_flash[i]-.12)
		sources[i].position = audio.source_position(i)
		sources[i].get_child(1).scale = Vector3.ONE*(1+_flash[i]*.3)
	_read_scope()
	_refresh()

func _refresh() -> void:
	if not display: return
	var status := "PLAYING" if audio.playing else ("PREPARING" if audio.wanted and audio.preparing else "PRESS PLAY")
	display.heading.text = "%s / LFO > %s" % [status,"SOUND POSITIONS" if audio.route == "pan" else "FILTER"]
	display.table.text = "seed %d / chance %d%% / %.2fx\nC D E G A / %d notes" % [audio.patch_seed,audio.parameters.density*100,lerpf(.45,1.7,audio.parameters.rate),audio.notes_played]
	var content: String = display.heading.text+display.table.text
	if display.get_meta("content","")!=content:
		display.set_meta("content",content)
		display.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _read_scope() -> void:
	var pcm := PackedVector2Array()
	if audio.capture: pcm = audio.capture.get_buffer(audio.capture.get_frames_available())
	_scope.clear_surfaces()
	_scope.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	_peak = 0
	for i in 128:
		var amplitude := 0.0
		if not pcm.is_empty():
			var index := mini(pcm.size()-1,maxi(0,pcm.size()-1024)+i*8)
			amplitude = (pcm[index].x+pcm[index].y)*.5
			_peak = maxf(_peak,absf(amplitude))
		_scope.surface_add_vertex(Vector3(lerpf(-1.30,1.30,i/127.0),2.15+clampf(amplitude*5,-1,1)*.16,-2.855))
	_scope.surface_end()

func _arc(parent: Node3D, part: String, inner: float, outer: float, y: float, from: float, to: float, color: Color, emissive := false) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 64:
		var a := deg_to_rad(lerpf(from,to,i/64.0))
		var b := deg_to_rad(lerpf(from,to,(i+1)/64.0))
		var p := Vector3(sin(a),0,-cos(a))
		var q := Vector3(sin(b),0,-cos(b))
		for v in [p*inner,q*outer,p*outer,p*inner,q*inner,q*outer]: st.add_vertex(v+Vector3.UP*y)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = part
	mesh.mesh = st.commit()
	mesh.material_override = _material(color,emissive)
	mesh.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	parent.add_child(mesh)

func _label(parent: Node3D, text: String, at: Vector3, size: Vector2, color: Color) -> void:
	var label := Baked.make_label_mesh(text,color,size,1600,true)
	label.position = at
	parent.add_child(label)

func _material(color: Color, emissive := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .77
	if emissive: material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _box(parent: Node3D, part: String, size: Vector3, at: Vector3, color: Color, solid := false) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = part
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.position = at
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.position = at
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		shape.shape.size = size
		body.add_child(shape)
		parent.add_child(body)

func _cylinder(parent: Node3D, part: String, radius: float, height: float, at: Vector3, color: Color, solid := false) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = part
	mesh.mesh = CylinderMesh.new()
	mesh.mesh.top_radius = radius
	mesh.mesh.bottom_radius = radius
	mesh.mesh.height = height
	mesh.mesh.radial_segments = 64
	mesh.position = at
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.position = at
		var shape := CollisionShape3D.new()
		shape.shape = CylinderShape3D.new()
		shape.shape.radius = radius
		shape.shape.height = height
		body.add_child(shape)
		parent.add_child(body)
