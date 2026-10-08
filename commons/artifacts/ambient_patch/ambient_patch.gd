extends Node3D
## A fixed, legible patch with one switchable LFO destination. Local +Z is front.
const Audio = preload("res://commons/artifacts/ambient_patch/ambient_patch_audio.gd")
const PhysicalSlider = preload("res://commons/interactables/physical_stepped_slider.gd")
const Baked = preload("res://commons/utils/baked_text_albedo.gd")
const Case = preload("res://commons/ui/instrument_panel_case.gd")
const Screen = preload("res://commons/ui/data_instrument_surface.gd")
const GOLD := Color(.96,.71,.36)
const TEAL := Color(.30,.89,.77)
const PINK := Color(.95,.38,.62)
var audio: Node3D
var sliders: Dictionary = {}
var buttons: Dictionary = {}
var display: Node3D
var _scope: MeshInstance3D
var _scope_mesh := ImmediateMesh.new()
var _route_cable: MeshInstance3D
var _lamps: Array[MeshInstance3D] = []
var _flash := [0.0,0.0,0.0]
var _ui_time := 0.0
var scope_peak := 0.0

func _ready() -> void:
	name = "AmbientPatch"
	audio = Audio.new()
	audio.name = "AmbientAudio"
	add_child(audio)
	audio.note_started.connect(_note)
	audio.state_changed.connect(_refresh)
	_build_body()
	_build_patch()
	_build_controls()
	_refresh()

func _build_body() -> void:
	var casing := Case.new()
	add_child(casing)
	casing.fit_rect(Vector2(0,1.32),Vector2(1.20,1.16),GOLD)
	_box("Face",Vector3(1.20,1.16,.014),Vector3(0,1.32,.01),Color(.065,.095,.105))
	for x in [-.655,.655]:
		_box("WalnutCheek",Vector3(.055,1.28,.16),Vector3(x,1.32,-.045),Color(.24,.105,.066))
		_box("Leg",Vector3(.045,.71,.06),Vector3(x*.77,.355,-.06),Color(.11,.15,.17),true)
		_box("Foot",Vector3(.20,.035,.46),Vector3(x*.77,.0175,.0),Color(.10,.12,.13),true)
	var body := StaticBody3D.new()
	body.name = "CabinetCollision"
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(1.32,1.27,.10)
	shape.position = Vector3(0,1.32,-.055)
	body.add_child(shape)
	add_child(body)
	_label("SLOW CIRCUITS",Vector3(-.16,1.85,.025),Vector2(.77,.055),GOLD)
	_label("AMBIENT / 01",Vector3(.40,1.85,.025),Vector2(.26,.03),TEAL)
	_label("THREE CLOCKS / ONE SCALE / A ROOM OF ECHOES",Vector3(0,.731,.025),Vector2(1.08,.022),Color(.7,.77,.75))

func _build_patch() -> void:
	# The actual graph: clocks -> chance -> quantization -> voices -> filter -> echo/reverb.
	_module("CLOCKS", "3.7 / 6.1 / 10.9", Vector2(-.40,1.70),GOLD)
	_module("CHANCE", "allow / leave silence",Vector2(0,1.70),GOLD)
	_module("PITCH", "C D E G A",Vector2(.40,1.70),GOLD)
	_module("VOICES", "pad + FM bell / LFO 29s",Vector2(-.40,1.49),TEAL)
	_module("FILTER", "soften the edge",Vector2(0,1.49),TEAL)
	_module("SPACE", "echo + reverb",Vector2(.40,1.49),TEAL)
	for i in 3:
		var lamp := _box("Clock%d" % i,Vector3(.018,.011,.008),Vector3(-.49+i*.09,1.643,.045),GOLD)
		_lamps.append(lamp)
	_cable(Vector3(-.25,1.645,.055),Vector3(-.15,1.645,.055),GOLD,.018)
	_cable(Vector3(.15,1.645,.055),Vector3(.25,1.645,.055),GOLD,.018)
	_cable(Vector3(.55,1.645,.055),Vector3(.55,1.60,.055),GOLD,0)
	_cable(Vector3(.55,1.60,.055),Vector3(-.55,1.60,.055),GOLD,0)
	_cable(Vector3(-.55,1.60,.055),Vector3(-.55,1.435,.055),GOLD,0)
	_cable(Vector3(-.25,1.435,.06),Vector3(-.15,1.435,.06),TEAL,.022)
	_cable(Vector3(.15,1.435,.06),Vector3(.25,1.435,.06),TEAL,.022)
	_route_cable = _cable(Vector3(-.55,1.435,.07),Vector3(-.15,1.435,.07),PINK,.045)
	# The scope reads post-effects PCM. It never pretends a decorative sine is the output.
	_box("ScopeBed",Vector3(.35,.054,.008),Vector3(.40,1.425,.034),Color(.014,.025,.03))
	_scope = MeshInstance3D.new()
	_scope.name = "OutputWaveform"
	_scope.mesh = _scope_mesh
	_scope.material_override = _material(TEAL,true)
	_scope.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_scope)

func _build_controls() -> void:
	display = Screen.new()
	display.name = "Readout"
	display.size_m = Vector2(1.12,.17)
	display.position = Vector3(0,1.295,.035)
	add_child(display)
	# A shallow screen uses its own one-line layout, retaining UPDATE_ONCE text.
	display.viewport.get_child(2).position.y = 74
	display.heading.position = Vector2(20,5)
	display.heading.size = Vector2(1080,60)
	display.heading.add_theme_font_size_override("font_size",31)
	display.table.position = Vector2(20,83)
	display.table.size = Vector2(1080,65)
	display.table.add_theme_font_size_override("font_size",25)
	var names := ["density","rate","warmth","space","drift","level"]
	for i in names.size():
		var key: String = names[i]
		var slider := PhysicalSlider.new()
		slider.name = key.capitalize()+"Slider"
		slider.continuous = true
		slider.param_name = key.to_upper()
		slider.position = Vector3((i-2.5)*.188,1.026,.047)
		slider.set_normalized_value(audio.parameters[key])
		slider.value_changed.connect(func(value: float): audio.set_parameter(key,value))
		add_child(slider)
		sliders[key] = slider
	_button("transport","PLAY / STOP",-.45,TEAL,_transport)
	_button("seed","NEW SEED",-.15,GOLD,audio.new_seed)
	_button("route","LFO ROUTE",.15,PINK,_route)
	_button("room","ENTER ROOM",.45,TEAL,_enter_room)

func _button(key: String, caption: String, x: float, color: Color, action: Callable) -> void:
	var plate := Case.new()
	plate.name = caption.replace(" / ","_")+"Plate"
	add_child(plate)
	plate.fit_rect(Vector2(x,.82),Vector2(.21,.13),color)
	var button: Node3D = load("res://commons/interactables/push_button.tscn").instantiate()
	button.name = key.capitalize()+"Button"
	button.position = Vector3(x,.834,.042)
	button.released_color = color.darkened(.2)
	button.released_emission_energy = .04
	button.play_press_sound = false
	button.pressed.connect(action)
	add_child(button)
	buttons[key] = button
	_label(caption,Vector3(x,.774,.04),Vector2(.215,.025),Color(.91,.94,.89))

func _enter_room() -> void:
	var travel = preload("res://commons/artifacts/ambient_patch/ambient_room_travel.gd")
	if travel.go(self,travel.ROOM): audio.stop(true)

func _transport() -> void:
	if audio.wanted or audio.playing: audio.stop()
	else: audio.start()

func _route() -> void:
	audio.set_route("pan" if audio.route == "filter" else "filter")
	if _route_cable:
		remove_child(_route_cable)
		_route_cable.queue_free()
	_route_cable = _cable(Vector3(-.55,1.435,.07),Vector3(-.15 if audio.route == "filter" else .55,1.435,.07),PINK,.045)

func _note(lane: int, _midi: int) -> void:
	_flash[lane] = 1.0

func _process(delta: float) -> void:
	_ui_time += delta
	if _ui_time < .1: return
	_ui_time = 0
	for i in 3:
		_flash[i] = maxf(0,_flash[i]-.15)
		(_lamps[i].material_override as StandardMaterial3D).albedo_color = GOLD.darkened(.8*(1-_flash[i]))
	_read_scope()
	_refresh()

func _refresh() -> void:
	if not display: return
	var state := "PLAYING" if audio.playing else ("PREPARING VOICES" if audio.preparing and audio.wanted else "PRESS PLAY")
	display.heading.text = "%s    |    seed %d    |    LFO > %s" % [state,audio.patch_seed,audio.route.to_upper()]
	display.table.text = "chance %d%%   clock %.2fx   space %d%%   notes %d / voices 8" % [audio.parameters.density*100,lerpf(.45,1.7,audio.parameters.rate),audio.parameters.space*100,audio.notes_played]
	# Screen.refresh's general tall-table layout isn't appropriate for this shallow strip.
	var key: String = display.heading.text+display.table.text
	if display.get_meta("content","") != key:
		display.set_meta("content",key)
		display.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _read_scope() -> void:
	_scope_mesh.clear_surfaces()
	_scope_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var samples := PackedVector2Array()
	if audio.capture: samples = audio.capture.get_buffer(audio.capture.get_frames_available())
	scope_peak = 0
	for i in 64:
		var sample := 0.0
		if not samples.is_empty():
			var index := maxi(0,samples.size()-512)+mini(i*8,samples.size()-1)
			sample = samples[mini(index,samples.size()-1)].x
			scope_peak = maxf(scope_peak,absf(sample))
		_scope_mesh.surface_add_vertex(Vector3(.238+float(i)/63*.324,1.425+clampf(sample*3,-1,1)*.023,.043))
	_scope_mesh.surface_end()

func _module(title: String, subtitle: String, at: Vector2, color: Color) -> void:
	_box(title+"Module",Vector3(.375,.178,.018),Vector3(at.x,at.y,.025),Color(.11,.15,.17))
	_label(title,Vector3(at.x,at.y+.05,.038),Vector2(.32,.036),color)
	_label(subtitle,Vector3(at.x,at.y,.038),Vector2(.32,.024),Color(.86,.90,.85))
	for side in [-1,1]:
		var socket := MeshInstance3D.new()
		socket.mesh = CylinderMesh.new()
		socket.mesh.top_radius = .010
		socket.mesh.bottom_radius = .010
		socket.mesh.height = .008
		socket.mesh.radial_segments = 8
		socket.rotation.x = PI/2
		socket.position = Vector3(at.x+side*.15,at.y-.055,.043)
		socket.material_override = _material(color)
		add_child(socket)

func _cable(a: Vector3, b: Vector3, color: Color, sag: float) -> MeshInstance3D:
	# One low-poly mesh per cable, not a node/collider for every segment.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 16:
		var t0 := float(i)/16
		var t1 := float(i+1)/16
		var p0 := a.lerp(b,t0)+Vector3(0,-sin(t0*PI)*sag,sin(t0*PI)*.022)
		var p1 := a.lerp(b,t1)+Vector3(0,-sin(t1*PI)*sag,sin(t1*PI)*.022)
		var tangent := (p1-p0).normalized()
		var side := tangent.cross(Vector3.FORWARD).normalized()
		var other := tangent.cross(side).normalized()
		for j in 6:
			var n0 := (side*cos(j*TAU/6)+other*sin(j*TAU/6))*.003
			var n1 := (side*cos((j+1)*TAU/6)+other*sin((j+1)*TAU/6))*.003
			for vertex in [p0+n0,p1+n0,p0+n1,p0+n1,p1+n0,p1+n1]: st.add_vertex(vertex)
	st.generate_normals()
	var cable := MeshInstance3D.new()
	cable.mesh = st.commit()
	cable.material_override = _material(color)
	cable.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cable)
	return cable

func _label(text: String, at: Vector3, size: Vector2, color: Color) -> void:
	var label := Baked.make_label_mesh(text,color,size,2000,true)
	label.position = at
	add_child(label)

func _material(color: Color, unshaded := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .65
	if unshaded: material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _box(part: String, size: Vector3, at: Vector3, color: Color, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = part
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.position = at
	mesh.material_override = _material(color)
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		shape.shape.size = size
		body.position = at
		body.add_child(shape)
		add_child(body)
	return mesh
