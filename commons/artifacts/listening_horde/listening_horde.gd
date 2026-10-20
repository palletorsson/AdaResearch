extends Node3D
## Full-size optional ABM encounter; the foraging tutorial remains the primary lesson.
const Horde = preload("horde.gd")
const PointBody = preload("res://commons/artifacts/particle_swarm_walk/point_body.gd")
const HOME := Vector3(-3.2, 1.18, 3.1)
const COLOURS := [Color("90a6b5"), Color("ff829d"), Color("76dbda")]
const GLYPHS := ["o", "?", "<"]
var model = Horde.new()
var point: XRToolsPickable
var bodies: Array[Node3D] = []
var heads: Array[MeshInstance3D] = []
var limbs: Array[Node3D] = []
var glyphs: Array[Label3D] = []
var marker: Node3D
var wave: MeshInstance3D
var status: Label3D
var message: Label3D
var sound: AudioStreamPlayer3D
var playing := true
var elapsed := 0.0
var cooldown := 0.0
var dropped_time := 0.0
var wave_time := 99.0
var heard := 0
var recorded_position := Vector3.ZERO

func material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = colour; m.roughness = 0.38; m.metallic = 0.18
	return m

func part(mesh: Mesh, at: Vector3, colour: Color, parent: Node3D = self) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = mesh; n.position = at; n.material_override = material(colour)
	parent.add_child(n); return n

func box(size: Vector3, at: Vector3, colour: Color, parent: Node3D = self) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size = size; return part(mesh, at, colour, parent)

func label(text: String, at: Vector3, size := 28, parent: Node3D = self) -> Label3D:
	var n := Label3D.new(); n.text = text; n.position = at; n.font_size = size; n.pixel_size = 0.003
	n.outline_size = 7; n.billboard = BaseMaterial3D.BILLBOARD_ENABLED; parent.add_child(n); return n

func ring(radius: float, thickness: float, at: Vector3, colour: Color, parent: Node3D = self) -> MeshInstance3D:
	var mesh := TorusMesh.new(); mesh.inner_radius = radius - thickness; mesh.outer_radius = radius + thickness
	mesh.rings = 48; mesh.ring_segments = 6; return part(mesh, at, colour, parent)

func solid(size: Vector3, at: Vector3, colour: Color) -> void:
	box(size, at, colour)
	var body := StaticBody3D.new(); body.collision_layer = 1; body.collision_mask = 0
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
	collision.shape = shape; body.position = at; body.add_child(collision); add_child(body)

func _ready() -> void:
	# Two low walls leave a 2.2 m gap; people can see the crowd before crossing.
	for z in [-2.275, 2.275]:
		solid(Vector3(0.24, 1.15, 2.35), Vector3(0, 0.575, z), Color("3b4654"))
		box(Vector3(0.26, 0.025, 2.35), Vector3(0, 1.16, z), COLOURS[1])
	for z in [-1.1, 1.1]:
		box(Vector3(0.10, 2.3, 0.10), Vector3(0, 1.15, z), Color("8994a0"))
	box(Vector3(0.10, 0.10, 2.3), Vector3(0, 2.3, 0), COLOURS[1])
	solid(Vector3(0.38, 1.02, 0.38), HOME - Vector3(0, 0.67, 0), Color("e7e5de"))
	point = PointBody.new(); point.name = "ListeningPoint"; add_child(point); point.position = HOME
	point.action_pressed.connect(_on_action)
	sound = AudioStreamPlayer3D.new(); sound.name = "PulseSound"; sound.max_distance = 12; sound.volume_db = -12
	var audio := AudioStreamWAV.new(); audio.format = AudioStreamWAV.FORMAT_16_BITS; audio.mix_rate = 22050
	var samples := PackedByteArray(); samples.resize(4410 * 2)
	for i in range(4410):
		var t := float(i) / 22050.0
		var envelope := minf(t * 100, 1.0) * pow(1.0 - t / 0.2, 2)
		samples.encode_s16(i * 2, int(sin(TAU * 660 * t) * envelope * 16000))
	audio.data = samples; sound.stream = audio; add_child(sound)
	label("THEY HEARD YOU THERE", Vector3(-2.6, 2.45, 3.15), 34)
	label("Carry the point. Press trigger / left click.\nWalk away. They keep the place of the pulse.", Vector3(-2.6, 2.08, 3.15), 20)
	status = label("", Vector3(-2.6, 1.75, 3.15), 19)
	message = label("Pulse inside this court · range 8 m", Vector3(-2.6, 1.51, 3.15), 17)
	label("o  REST     ?  INVESTIGATE     <  RETURN", Vector3(2.4, 2.65, 0), 24)
	marker = Node3D.new(); marker.name = "RememberedPlace"; add_child(marker); marker.visible = false
	ring(0.62, 0.022, Vector3(0, 0.035, 0), Color("ffd58a"), marker)
	ring(1.0, 0.012, Vector3(0, 0.025, 0), Color("ffd58a"), marker)
	label("LAST PULSE", Vector3(0, 0.45, 0), 22, marker)
	wave = ring(1, 0.016, Vector3.ZERO, Color("ffd58a")); wave.visible = false
	var head := SphereMesh.new(); head.radius = 0.13; head.height = 0.26; head.radial_segments = 16; head.rings = 8
	var torso := CylinderMesh.new(); torso.top_radius = 0.16; torso.bottom_radius = 0.23; torso.height = 0.62; torso.radial_segments = 8
	var eye := SphereMesh.new(); eye.radius = 0.026; eye.height = 0.052; eye.radial_segments = 8; eye.rings = 4
	for i in range(Horde.COUNT):
		var body := Node3D.new(); body.name = "Listener%02d" % i; add_child(body); bodies.append(body)
		part(torso, Vector3(0, 0.96, 0), Color("29313c"), body)
		heads.append(part(head, Vector3(0, 1.45, 0), COLOURS[0], body))
		for x in [-0.055, 0.055]: part(eye, Vector3(x, 1.47, -0.119), Color("101820"), body)
		var pair := Node3D.new(); body.add_child(pair); limbs.append(pair)
		for side in [-1.0, 1.0]:
			var leg := Node3D.new(); pair.add_child(leg); leg.position = Vector3(side * 0.1, 0.65, 0)
			box(Vector3(0.09, 0.59, 0.1), Vector3(0, -0.295, 0), Color("455262"), leg)
			box(Vector3(0.12, 0.07, 0.23), Vector3(0, -0.61, -0.06), Color("202632"), leg)
			var arm := Node3D.new(); pair.add_child(arm); arm.position = Vector3(side * 0.25, 1.19, 0)
			box(Vector3(0.075, 0.5, 0.08), Vector3(0, -0.25, 0), Color("455262"), arm)
		glyphs.append(label("o", Vector3(0, 1.83, 0), 32, body))
		var rest: Vector2 = model.homes[i]
		ring(0.28, 0.008, Vector3(rest.x, 0.018, rest.y), COLOURS[0])
	_refresh()

func _on_action(_pickable: Node3D) -> void:
	if not point.held() or cooldown > 0: return
	var local := to_local(point.global_position)
	if not model.valid_source(local):
		message.text = "Bring the point into the court to send a pulse."; return
	heard = model.pulse(local); recorded_position = local; cooldown = 0.5
	sound.position = local; sound.play()
	marker.position = Vector3(local.x, 0, local.z); marker.visible = true
	wave.position = local; wave_time = 0
	message.text = "%d heard this pulse · position kept" % heard
	_refresh()

func _physics_process(dt: float) -> void:
	cooldown = maxf(0, cooldown - dt)
	if playing: model.step(dt)
	if point.held(): dropped_time = 0
	else:
		dropped_time += dt
		if dropped_time > 1.5: point.global_position = to_global(HOME)

func _process(dt: float) -> void:
	elapsed += dt; wave_time += dt
	wave.visible = wave_time < 1.5
	if wave.visible: wave.scale = Vector3.ONE * maxf(0.02, wave_time * Horde.HEARING_RADIUS / 1.5)
	_refresh()

func _refresh() -> void:
	for i in range(bodies.size()):
		var p: Vector2 = model.positions[i]; var v: Vector2 = model.velocities[i]
		bodies[i].position = Vector3(p.x, 0, p.y)
		if v.length() > 0.02: bodies[i].rotation.y = atan2(-v.x, -v.y)
		var state: int = model.states[i]
		heads[i].material_override.albedo_color = COLOURS[state]
		glyphs[i].text = GLYPHS[state]; glyphs[i].modulate = COLOURS[state]
		var swing := sin(elapsed * 7.0 + i * 0.31) * 0.42 * minf(v.length(), 1.0)
		for j in range(4): limbs[i].get_child(j).rotation.x = swing * (1 if j < 2 else -1)
	if status != null:
		var count: Array[int] = model.counts()
		status.text = "o REST %02d     ? INVESTIGATE %02d     < RETURN %02d" % count

func get_museum_occupied_cells() -> Array[Vector2i]:
	# Explicit static footprint. Moving bodies and captions never seal the court.
	var cells: Array[Vector2i] = []
	for z in [-3.25, -2.25, -1.4, 1.4, 2.25, 3.25]:
		var p := to_global(Vector3(0, 0, z)); var cell := Vector2i(floori(p.x), floori(p.z))
		if not cells.has(cell): cells.append(cell)
	var stand := to_global(HOME); cells.append(Vector2i(floori(stand.x), floori(stand.z)))
	return cells
