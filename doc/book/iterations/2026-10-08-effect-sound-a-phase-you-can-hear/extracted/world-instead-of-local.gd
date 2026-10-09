extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const SAMPLE_RATE := 44100
const DURATION := 0.6
const ATTACK := 0.01
@export var frequency := 440.0
@export var ratio := 2.0
var point: RigidBody3D
var label: Label3D
var player: AudioStreamPlayer3D
var reference: AudioStreamWAV
var rods: Array[MeshInstance3D] = []
var last_index := 0.0
var busy := false

func phase_depth() -> float:
    return 4.0 * clampf((point.global_position.y - 1.0) / 0.6, 0.0, 1.0)

func sample_at(t: float, depth: float) -> float:
    var modulator := depth * exp(-t / 0.25) * sin(TAU * frequency * ratio * t)
    var carrier := sin(TAU * frequency * t + modulator)
    var envelope := minf(t / ATTACK, 1.0) * exp(-maxf(t - ATTACK, 0.0) / 0.3)
    envelope *= clampf((DURATION - t) / 0.02, 0.0, 1.0)
    return 0.5 * tanh(0.8 * carrier * envelope)

func make_note(depth: float) -> AudioStreamWAV:
    var bytes := PackedByteArray()
    var count := int(SAMPLE_RATE * DURATION)
    bytes.resize(count * 2)
    for i in range(count):
        var t := float(i) / SAMPLE_RATE
        bytes.encode_s16(i * 2, int(sample_at(t, depth) * 32767.0))
    var note := AudioStreamWAV.new()
    note.format = AudioStreamWAV.FORMAT_16_BITS
    note.mix_rate = SAMPLE_RATE
    note.stereo = false
    note.data = bytes
    return note

func _ready() -> void:
    point = PointBody.new()
    point.position = Vector3(0, 1.0, 0)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(func(_body): play_pair())
    player = AudioStreamPlayer3D.new()
    player.position = Vector3(0, 1.2, 0)
    player.volume_db = -12.0
    player.max_distance = 7.0
    add_child(player)
    label = Label3D.new()
    label.position = Vector3(0, 2.05, 0)
    label.font_size = 30
    label.pixel_size = 0.004
    add_child(label)
    for i in range(96):
        var line := LineSkin.new()
        add_child(line)
        rods.append(line)
    reference = make_note(0.0)
    draw_state()

func _process(_delta: float) -> void:
    draw_state()

func graph_point(i: int, depth: float) -> Vector3:
    var fraction := float(i) / rods.size()
    var t := ATTACK + fraction * 2.0 / frequency
    return Vector3(-1.1 + 2.2 * fraction, 1.4 + 1.2 * sample_at(t, depth), -0.35)

func draw_state() -> void:
    var depth := phase_depth()
    for i in range(rods.size()):
        var a := graph_point(i, depth)
        var b := graph_point(i + 1, depth)
        rods[i].show_segment(a, b - a, a.distance_to(b))
    label.text = "Raise the point: phase depth %.2f rad\nHold + trigger: A, then B | last B %.2f\nScope: two carrier periods near the attack" % [depth, last_index]

func play_pair() -> void:
    if busy:
        return
    busy = true
    last_index = phase_depth()
    var changed := make_note(last_index)
    player.stream = reference
    player.play()
    await get_tree().create_timer(DURATION + 0.25).timeout
    player.stream = changed
    player.play()
    await get_tree().create_timer(DURATION).timeout
    busy = false
