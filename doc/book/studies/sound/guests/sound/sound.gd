extends Node3D
## The guest of the Sound chapter: a chord you can walk into. It is chord.gd
## of the kit, with the kit's colours written out, because a guest names
## nothing outside its folder. Two tones are computed sample by sample into
## one second of 16-bit sound. A voice plays it in a loop while a body stands
## inside the reach. The same two sines, one across and one up, draw the
## chord's figure in beads. Nothing here is recorded.

# The kit's BODY, SECOND, THIRD and BONE, its LINE and its GHOST, written out.
const BODIES: Array[Color] = [Color("c6ff3d"), Color("22d9ff"), Color("ff8b1f"), Color("f4efe6")]
const LINE := Color("ffffff")
const GHOST := Color("9b7bff")
const RATE := 44100    # samples in one second of sound
const BEADS := 5512    # the samples of an eighth of a second: one bead for each

@export var ratio := "3:2"    # the faster tone to the slower one
@export var low_hz := 256.0   # the slower tone: turns in one second
@export var member := 0       # which of a family: BODIES[member] is its colour

var high_hz := 384.0          # the faster tone; _ready() works it out from the ratio
var voice: AudioStreamPlayer3D

func _ready() -> void:
	var parts := ratio.split(":")
	high_hz = low_hz * float(parts[0]) / float(parts[1])
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = render()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = RATE
	voice = AudioStreamPlayer3D.new()
	voice.stream = stream
	voice.unit_size = 1.0
	voice.position = Vector3(0, 0.4, 0)
	add_child(voice)
	add_speaker()
	add_reach()
	add_figure()
	print(name, ": ", ratio, ", ", low_hz, " and ", high_hz, " Hz")

## One second of the two tones as 16-bit samples: two bytes for each sample.
func render() -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(RATE * 2)
	for i in range(RATE):
		var t := float(i) / RATE
		var wave := 0.5 * sin(TAU * low_hz * t) + 0.5 * sin(TAU * high_hz * t)
		data.encode_s16(i * 2, int(wave * 32767.0))
	return data

## The box the sound comes from: a mesh for the eye and a shape for a body.
func add_speaker() -> void:
	var speaker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.4, 0.3)
	speaker.mesh = box
	speaker.material_override = paint(BODIES[member])
	speaker.position.y = 0.2
	add_child(speaker)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var solid := BoxShape3D.new()
	solid.size = box.size
	shape.shape = solid
	body.add_child(shape)
	speaker.add_child(body)

## Where the chord is heard: a round area, and a ring on the floor that shows it.
func add_reach() -> void:
	var reach := Area3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.8
	cylinder.height = 2.0
	shape.shape = cylinder
	shape.position.y = 1.0
	reach.add_child(shape)
	add_child(reach)
	reach.body_entered.connect(_on_body_entered)
	reach.body_exited.connect(_on_body_exited)
	var ring := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.8
	disc.bottom_radius = 0.8
	disc.height = 0.01
	ring.mesh = disc
	ring.material_override = ghost()
	ring.position.y = 0.01
	add_child(ring)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		voice.play()
		print(name, " sounds")

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		voice.stop()
		print(name, " is silent")

## The same two sines as a figure: the slower tone across, the faster one up.
func add_figure() -> void:
	var beads := MultiMesh.new()
	beads.transform_format = MultiMesh.TRANSFORM_3D
	var bead := BoxMesh.new()
	bead.size = Vector3(0.02, 0.02, 0.02)
	beads.mesh = bead
	beads.instance_count = BEADS
	for i in range(BEADS):
		var t := float(i) / RATE
		var at := Vector3(0.5 * sin(TAU * low_hz * t), 1.1 + 0.5 * sin(TAU * high_hz * t), 0)
		beads.set_instance_transform(i, Transform3D(Basis(), at))
	var figure := MultiMeshInstance3D.new()
	figure.multimesh = beads
	figure.material_override = paint(LINE)
	add_child(figure)

## The kit's paint: a colour, matt.
func paint(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.8
	return material

## The kit's ghost: GHOST, half seen through.
func ghost() -> StandardMaterial3D:
	var material := paint(Color(GHOST, 0.45))
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
