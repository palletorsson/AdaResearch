extends "res://commons/artifacts/spine_studies/study_forms.gd"
## A cable application beside the sweep workbench; reuses UVAC and its modules.
var rack: Node3D
var manager: SynthCableManager
var live: Node
var lever: Node3D
var speaker_jack: SynthJack
var gate: SynthJack
var motor: SynthJack
var bodies: Array[Node3D] = []
var wheels: Array[Node3D] = []
var rods: Array[MeshInstance3D] = []
var readout: Label3D
var phase := 0.0
var motor_running := false
var powered := false
var points := [Vector3(-1.25,0.65,-0.5),Vector3(0,0.65,-0.5),Vector3(1.25,0.65,-0.5)]

class PatchButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2: action.call()

func _ready() -> void:
	block(Vector3(0,2.3,-1.50),Vector3(4.9,4.6,0.12),Color("deded7"),true)
	block(Vector3(0,0.10,0),Vector3(4.9,0.20,3.4),Color("ede9e0"),true)
	block(Vector3(0,0.43,-0.5),Vector3(4.0,0.45,1.0),Color("24252b"),true)
	for i in 3:
		build_dancer(i)
	inscription("A CORD MAKES SOMETHING HAPPEN",Vector3(0,4.10,-1.35),0.0024)
	inscription("A moving study after Jean Tinguely and Niki de Saint Phalle",Vector3(0,3.85,-1.35),0.0015)
	# Use the existing controller with a focused three-module preset.
	rack = load("res://commons/audio/UniversalVRAudioController.gd").new()
	rack.name = "ExistingModularSynth"
	rack.rack_config_path = ""; rack.eurorack_preset_name = "patch_and_motion"
	var grid := Node3D.new(); grid.name = "ParameterGrid"; rack.add_child(grid)
	var speaker := AudioStreamPlayer3D.new(); speaker.name = "AudioStreamPlayer3D"
	speaker.unit_size = 3.0; speaker.max_distance = 12.0; rack.add_child(speaker)
	rack.position = Vector3(-0.95,1.42,2.12); add_child(rack)
	rack.scale = Vector3.ONE * 1.55
	manager = rack._eurorack_cable_manager; live = rack.live_patch
	block(Vector3(-0.95,0.50,1.80),Vector3(1.60,1.0,0.42),Color("e8e6df"),true)
	inscription("0 SAW · 1 SQUARE · 2 TRIANGLE · 3 SINE",Vector3(-0.95,0.88,2.035),0.0007)
	inscription("PATCH OUT TO IN · PULL A PLUG TO BREAK THE PATH",Vector3(-0.95,0.71,2.035),0.00068)
	lever = preload("res://commons/interactables/lever_smooth.tscn").instantiate()
	lever.position = Vector3(1.35,1.16,1.87); add_child(lever)
	lever.scale = Vector3.ONE * 1.6
	lever.set_caption("POWER"); lever.set_angle_degrees(-40)
	lever.hinge_moved.connect(func(angle: float): set_power(angle > 0))
	block(Vector3(1.15,0.51,1.78),Vector3(1.10,1.02,0.40),Color("e8e6df"),true)
	speaker_jack = add_jack("speaker_audio",SynthJack.JackType.INPUT,Vector3(0.05,1.08,2.13),"SPEAKER","audio")
	gate = add_jack("power_gate",SynthJack.JackType.OUTPUT,Vector3(0.92,1.21,2.02),"GATE")
	motor = add_jack("motor_gate",SynthJack.JackType.INPUT,Vector3(0.70,0.57,0.10),"MOTOR")
	readout = inscription("",Vector3(0,0.33,2.04),0.0012)
	button("POWER",Vector3(1.32,0.85,2.025),func(): lever.set_angle_degrees(-40 if powered else 40))
	button("PATCH EXAMPLE",Vector3(-1.15,0.47,2.035),example_patch)
	button("UNPATCH",Vector3(-0.45,0.47,2.035),unpatch)
	example_patch()

func add_jack(parameter: String, type: int, at: Vector3, label: String, kind := "gate") -> SynthJack:
	var jack := SynthJack.new(); jack.parameter_name = parameter; jack.jack_type = type
	jack.signal_kind = kind; jack.position = at; jack.scale = Vector3.ONE * 1.8
	add_child(jack); manager.register_jack(jack)
	inscription(label,at+Vector3(0,0.09,0),0.0009)
	return jack

func set_power(enabled: bool) -> void:
	powered = enabled; live.powered = enabled

func connect_pair(output: SynthJack, input: SynthJack) -> SynthCable:
	var cable := manager.spawn_cable()
	cable.plug_a.snap_to_jack(output); cable.plug_b.snap_to_jack(input)
	return cable

func unpatch() -> bool:
	for cable in manager.cables:
		if cable.plug_a.is_being_held() or cable.plug_b.is_being_held(): return false
	manager.clear_all_cables()
	return true

func example_patch() -> void:
	if not unpatch(): return
	connect_pair(manager.output_jacks.vco_frequency,manager.input_jacks.vcf_audio_in[0])
	connect_pair(manager.output_jacks.vcf_audio_out,manager.input_jacks.vca_audio_in[0])
	connect_pair(gate,motor)
	connect_pair(manager.output_jacks.vca_audio_out,speaker_jack)

func _process(delta: float) -> void:
	motor_running = powered and manager.has_route("power_gate","motor_gate")
	if motor_running: phase += delta * 1.15
	for i in 3:
		var angle: float = phase * [1.0,-0.75,1.35][i]
		wheels[i].rotation.z = angle
		bodies[i].rotation.y = angle * 0.55
		bodies[i].rotation.z = sin(angle)*0.16
		bodies[i].position.y = 1.04+0.08*sin(angle)
		var pin: Vector3 = wheels[i].position + wheels[i].basis * Vector3(0.17,0,0.04)
		var joint := Vector3(points[i].x,bodies[i].position.y+0.22,points[i].z+0.61)
		var up := (joint-pin).normalized()
		var right := up.cross(Vector3.FORWARD).normalized()
		rods[i].transform = Transform3D(Basis(right,up*joint.distance_to(pin),right.cross(up)),(joint+pin)*0.5)
	for cable in manager.cables:
		if cable.get_output_jack() == gate: cable.flow = 1.0 if powered else 0.0
	readout.text = ("POWER ON" if powered else "POWER OFF")+"   ·   "+("MOTOR TURNING" if motor_running else "MOTOR STILL")+"   ·   "+("FILTERED" if live.filtered and live.audible else "DIRECT" if live.audible else "SILENT")

func button(words: String, at: Vector3, action: Callable) -> void:
	var button := PatchButton.new(); button.name = words.replace(" ","_"); button.action = action
	button.position = at; button.collision_layer = (1<<20)|(1<<22); button.collision_mask = 0
	var shape := BoxShape3D.new(); shape.size = Vector3(0.62,0.16,0.04)
	var col := CollisionShape3D.new(); col.shape = shape; button.add_child(col)
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = shape.size
	mesh.mesh = box; mesh.material_override = material(Color("d484a3")); button.add_child(mesh); add_child(button)
	inscription(words,at+Vector3(0,0,0.03),0.00085)

func ellipsoid(parent: Node3D, at: Vector3, size: Vector3, colour: Color, patterned := false) -> void:
	var item := MeshInstance3D.new(); var sphere := SphereMesh.new()
	sphere.radius = 1; sphere.height = 2; sphere.radial_segments = 24; sphere.rings = 16
	item.mesh = sphere; item.position = at; item.scale = size
	if patterned:
		var shader := Shader.new()
		shader.code = "shader_type spatial; uniform vec4 coat:source_color; void fragment(){float spots=step(0.72,sin(UV.x*62.83)*sin(UV.y*37.7)); ALBEDO=mix(coat.rgb,vec3(0.98,0.72,0.08),spots); ROUGHNESS=0.3;}"
		var paint := ShaderMaterial.new(); paint.shader = shader; paint.set_shader_parameter("coat",colour)
		item.material_override = paint
	else:
		item.material_override = material(colour); item.material_override.roughness = 0.3
	parent.add_child(item)

func limb(parent: Node3D, path: PackedVector3Array, radius: float, colour: Color) -> void:
	var built := preload("res://commons/primitives/pipes/swept_tube.gd").build(path,radius,12)
	var mesh := MeshInstance3D.new(); mesh.mesh = built.mesh; mesh.material_override = material(colour)
	parent.add_child(mesh)
	ellipsoid(parent,path[0],Vector3.ONE*radius,colour)
	ellipsoid(parent,path[-1],Vector3.ONE*radius,colour)

func build_dancer(index: int) -> void:
	var dark := Color("222831"); var colours := [Color("e2367d"),Color("1478bd"),Color("f3b617")]
	var base: Vector3 = points[index]
	var wheel := Node3D.new(); wheel.position = base+Vector3(0,0.24,0.57); add_child(wheel); wheels.append(wheel)
	var rim := MeshInstance3D.new(); var torus := TorusMesh.new()
	torus.inner_radius = 0.27; torus.outer_radius = 0.32; torus.rings = 32; torus.ring_segments = 8
	rim.mesh = torus; rim.rotation.x = PI/2; rim.material_override = material(dark); wheel.add_child(rim)
	for k in 7:
		var a := TAU*k/7
		limb(wheel,PackedVector3Array([Vector3.ZERO,Vector3(cos(a),sin(a),0)*0.28]),0.017,dark)
	ellipsoid(wheel,Vector3(0.17,0,0.04),Vector3.ONE*0.055,Color("cda66a"))
	var link := MeshInstance3D.new(); var rod := CylinderMesh.new()
	rod.top_radius=0.022; rod.bottom_radius=0.022; rod.height=1; rod.radial_segments=8
	link.mesh=rod; link.material_override=material(Color("cda66a")); add_child(link); rods.append(link)
	# Exposed shafts and crossmembers remain legible below the bodies.
	limb(self,PackedVector3Array([base,base+Vector3(0,0.8,0)]),0.045,dark)
	limb(self,PackedVector3Array([base+Vector3(-0.52,0,0),base+Vector3(0.52,0,0)]),0.025,dark)
	var figure := Node3D.new(); figure.position = Vector3(base.x,1.04,base.z); add_child(figure); bodies.append(figure)
	var c: Color = colours[index]
	ellipsoid(figure,Vector3(0,1.1,0),Vector3(0.40,0.49,0.28),c,true)
	ellipsoid(figure,Vector3(0,0.69,0),Vector3(0.47,0.34,0.30),c)
	ellipsoid(figure,Vector3(0.08,1.73,0),Vector3(0.18,0.24,0.18),Color("f3b617"))
	var accent: Color = colours[(index+1)%3]
	limb(figure,PackedVector3Array([Vector3(-0.27,1.35,0),Vector3(-0.55,1.48,0),Vector3(-0.63,1.83,0.07)]),0.105,accent)
	limb(figure,PackedVector3Array([Vector3(0.28,1.35,0),Vector3(0.55,1.57,0),Vector3(0.47,1.90,0.04)]),0.105,accent)
	limb(figure,PackedVector3Array([Vector3(-0.23,0.67,0),Vector3(-0.42,0.35,0),Vector3(-0.25,0.04,0.10)]),0.14,c)
	limb(figure,PackedVector3Array([Vector3(0.23,0.67,0),Vector3(0.45,0.38,0),Vector3(0.35,0.06,0.14)]),0.14,accent)
