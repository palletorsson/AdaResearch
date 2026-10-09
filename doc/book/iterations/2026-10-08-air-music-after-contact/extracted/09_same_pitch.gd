extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const RingVoice = preload("ring_voice.gd")
signal struck(index: int)
var frequencies: Array[float] = [261.63, 261.63]
var voice := RingVoice.new()
var players: Array[AudioStreamPlayer3D] = []
var samples: Array[PackedByteArray] = []
var bars: Array[Area3D] = []
var captions: Array[Label3D] = []
var lines: Array[MeshInstance3D] = []
var point: RigidBody3D
var label: Label3D

func text_at(words: String, at: Vector3, size: int = 24) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.002
    add_child(text)
    return text

func _ready() -> void:
    point = PointBody.new()
    point.position = Vector3(0, 1.05, 0.8)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    label = text_at("", Vector3(0, 2.2, 0), 28)
    text_at("Touch with the point; lift away; touch another.", Vector3(0, 0.68, 0.3))
    for i in range(frequencies.size()):
        var bar := Area3D.new()
        bar.position = Vector3(-0.55 + 1.1 * i, 1.05, 0)
        bar.collision_layer = 0
        bar.collision_mask = point.collision_layer | point.picked_up_layer
        var boundary := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(0.5, 0.14, 0.6)
        boundary.shape = shape
        bar.add_child(boundary)
        var surface := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = shape.size
        surface.mesh = box
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.85, 0.85, 0.82)
        surface.material_override = material
        bar.add_child(surface)
        bar.body_entered.connect(_on_contact.bind(i))
        add_child(bar)
        bars.append(bar)
        captions.append(text_at("", bar.position + Vector3(0, -0.2, 0.32), 21))
        var player := AudioStreamPlayer3D.new()
        player.position = bar.position
        player.max_distance = 7.0
        player.stream = voice.make_note(frequencies[i])
        samples.append(player.stream.data)
        add_child(player)
        players.append(player)
    for i in range(64):
        var line := LineSkin.new()
        add_child(line)
        lines.append(line)
    draw_state()

func _on_contact(body: Node3D, index: int) -> void:
    if body != point:
        return
    players[index].play()
    struck.emit(index)

func ages_now() -> PackedFloat64Array:
    var ages := PackedFloat64Array()
    for player in players:
        ages.append(player.get_playback_position() if player.playing else -1.0)
    return ages

func sum_at(ages: PackedFloat64Array, offset: float) -> float:
    var total := 0.0
    for i in range(players.size()):
        if ages[i] >= 0.0:
            total += voice.read_sample(samples[i], ages[i] + offset)
    return total

func _process(_delta: float) -> void:
    draw_state()

func draw_state() -> void:
    var ages := ages_now()
    var active := 0
    for i in range(players.size()):
        var state := "quiet"
        if ages[i] >= 0.0:
            active += 1
            state = "%.2f s" % ages[i]
        captions[i].text = "%.2f Hz | %s" % [frequencies[i], state]
    label.text = "%d voices | each has its own age\n12 ms of their stored samples added" % active
    var previous := Vector3(-1.0, 1.65 + 0.45 * sum_at(ages, 0.0), 0)
    for i in range(lines.size()):
        var u := float(i + 1) / lines.size()
        var next := Vector3(-1.0 + 2.0 * u, 1.65 + 0.45 * sum_at(ages, u * 0.012), 0)
        var delta := next - previous
        lines[i].show_segment(previous, delta, delta.length())
        previous = next
