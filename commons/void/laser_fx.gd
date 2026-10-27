extends Node3D
## Bounded, renderer-independent beam/spark geometry; no physical debris in the route.
var life := 0.22
var age := 0.0
var velocities: Array[Vector3] = []
var tumble := false
static var sounds: Dictionary = {}

static func finish(colour: Color, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.68
	if glow:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = colour
		material.emission_energy_multiplier = 2.0
	return material

static func box(host: Node3D, at: Vector3, size: Vector3, material: Material, title := "Shell") -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = material
	host.add_child(node)
	return node

static func rod(host: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius; mesh.bottom_radius = radius
	mesh.height = maxf(0.001, a.distance_to(b)); mesh.radial_segments = 8
	node.mesh = mesh
	node.position = (a+b)*0.5
	var axis := (b-a).normalized()
	if axis.length_squared() > 0.5: node.quaternion = Quaternion(Vector3.UP, axis)
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(node)
	return node

static func beam(host: Node3D, a: Vector3, b: Vector3, colour: Color, width := 0.018, seconds := 0.13) -> Node3D:
	var fx: Node3D = load("res://commons/void/laser_fx.gd").new()
	fx.life = seconds
	host.add_child(fx)
	rod(fx, fx.to_local(a), fx.to_local(b), width, finish(colour, true))
	return fx

static func sparks(host: Node3D, at: Vector3, destruction := false) -> Node3D:
	var fx: Node3D = load("res://commons/void/laser_fx.gd").new()
	fx.life = 1.05 if destruction else 0.3
	host.add_child(fx)
	fx.global_position = at
	var material := finish(Color("ffc16c"),true)
	for i in range(24 if destruction else 8):
		var angle := float(i)*2.39996
		var velocity := Vector3(cos(angle), float(i%7)/4.0-0.5, sin(angle))*(2.8 if destruction else 1.4)
		rod(fx, Vector3.ZERO, velocity.normalized()*0.11, 0.009, material)
		fx.velocities.append(velocity)
	if destruction:
		for i in range(6):
			var shard := box(fx,Vector3.ZERO,Vector3(0.12,0.06,0.18),finish(Color("55595b")),"CasingFragment")
			shard.rotation=Vector3(i*0.7,i*1.3,0.4)
			fx.velocities.append(Vector3(cos(i*1.05)*1.8,-0.3,sin(i*1.05)*1.8))
	return fx

static func confetti(host: Node3D, at: Vector3) -> Node3D:
	var fx: Node3D=load("res://commons/void/laser_fx.gd").new()
	fx.life=2.0; fx.tumble=true; host.add_child(fx); fx.global_position=at
	fx.add_to_group("void_confetti")
	var colours := [Color("ff66bb"),Color("61f5ee"),Color("ffe06b"),Color("a78bff")]
	for i in range(40):
		var angle := i*2.39996
		var sheet := box(fx,Vector3.ZERO,Vector3(0.075,0.008,0.14),finish(colours[i%4],true),"Confetti")
		sheet.rotation=Vector3(angle,i*0.7,0.3)
		# Outrun the expanding smoke, so the colours can be read around its edge.
		fx.velocities.append(Vector3(cos(angle)*5.0,float(i%5)*0.48-0.4,sin(angle)*5.0))
	return fx

## Short, spatial synthesized cues; no imported sample or unbounded audio nodes.
static func sound(host: Node3D, at: Vector3, kind: String) -> void:
	if not is_instance_valid(host): return
	if host.get_tree().get_nodes_in_group("void_weapon_sound").size()>=8: return
	if not sounds.has(kind):
		var stream := AudioStreamWAV.new()
		stream.format=AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate=22050
		var seconds := 0.45 if kind=="break" else 0.12
		var samples := int(seconds*stream.mix_rate)
		var data := PackedByteArray(); data.resize(samples*2)
		var phase := 0.0
		var rng := RandomNumberGenerator.new(); rng.seed=714
		for i in range(samples):
			var t := float(i)/samples
			var frequency := lerpf(1800,180,t) if kind=="shot" else 740.0 if kind=="warning" else 2300.0
			phase+=TAU*frequency/stream.mix_rate
			var wave := sin(phase)*0.7+sin(phase*1.51)*0.3
			if kind=="break" or kind=="pin": wave=rng.randf_range(-1,1)*0.5+wave*0.5
			var envelope := minf(1.0,t*30.0)*pow(1.0-t,2.0)
			data.encode_s16(i*2,int(wave*envelope*13000))
		stream.data=data; sounds[kind]=stream
	var player := AudioStreamPlayer3D.new()
	player.add_to_group("void_weapon_sound"); player.stream=sounds[kind]
	player.bus="VoidEffects" if AudioServer.get_bus_index("VoidEffects")>=0 else "Master"
	player.unit_size=4; player.max_distance=24; player.volume_db=-5 if kind=="shot" else -9
	host.add_child(player); player.global_position=at
	player.finished.connect(player.queue_free); player.play()
	# Also bound lifetime in simulation time: headless/dummy audio may advance
	# on a different clock and never deliver finished during a fast test run.
	host.get_tree().create_timer(player.stream.get_length()+0.15).timeout.connect(player.queue_free)

func _process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free(); return
	for i in range(get_child_count()):
		var part: Node3D = get_child(i)
		if i < velocities.size():
			velocities[i].y -= delta*5.0
			part.position += velocities[i]*delta
		if tumble: part.rotate_object_local(Vector3(1,0.4,0.7).normalized(),delta*7)
		part.scale = Vector3.ONE*maxf(0.03,1.0-age/life)
