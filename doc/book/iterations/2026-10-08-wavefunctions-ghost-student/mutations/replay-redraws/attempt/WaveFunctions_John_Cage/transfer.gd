extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const NoteVoice = preload("note_voice.gd")
signal event_started(index: int)
var min_interval := 0.75
var max_interval := 0.75
var rng := RandomNumberGenerator.new()
var score: Array[Dictionary] = []
var notes: Array[AudioStreamWAV] = []
var players: Array[AudioStreamPlayer3D] = []
var markers: Array[MeshInstance3D] = []
var captions: Array[Label3D] = []
var point: RigidBody3D
var label: Label3D
var playhead: MeshInstance3D
var elapsed := 0.0
var cursor := 0
var playing := false

func text_at(words: String, at: Vector3, size: int = 26) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.003
    add_child(text)
    return text

func _ready() -> void:
    rng.randomize()
    var voice := NoteVoice.new()
    for depth in [0.0, 1.0, 3.0]:
        notes.append(voice.make_note(depth))
    point = PointBody.new()
    point.position = Vector3(-0.65, 1.0, 1.0)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(func(_body): activate())
    text_at("REPLAY", Vector3(-0.65, 0.68, 1.0))
    text_at("NEW + PLAY", Vector3(0.65, 0.68, 1.0))
    label = text_at("", Vector3(0, 2.35, 0), 30)
    for lane in range(notes.size()):
        var line := LineSkin.new()
        add_child(line)
        line.show_segment(Vector3(-1.8, 0.95 + 0.4 * lane, 0), Vector3(3.8, 0, 0), 3.8)
        text_at("%d" % lane, Vector3(-2.0, 0.95 + 0.4 * lane, 0))
    playhead = LineSkin.new()
    add_child(playhead)
    for i in range(6):
        var marker := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(0.12, 0.12, 0.12)
        marker.mesh = box
        marker.material_override = StandardMaterial3D.new()
        add_child(marker)
        markers.append(marker)
        captions.append(text_at("", Vector3.ZERO, 20))
        var player := AudioStreamPlayer3D.new()
        player.position = Vector3(0, 1.2, 0)
        player.volume_db = -18.0
        player.max_distance = 7.0
        add_child(player)
        players.append(player)
    new_score()
    draw_state()

func new_score() -> void:
    score.clear()
    var at := 0.0
    for i in range(players.size()):
        at += rng.randf_range(min_interval, max_interval)
        var voice := rng.randi_range(0, notes.size() - 1)
        score.append({"at": at, "voice": voice})
        markers[i].position = Vector3(-1.8 + 0.35 * at, 0.95 + 0.4 * voice, 0)
        captions[i].position = markers[i].position + Vector3(0, 0.17, 0)
        captions[i].text = "%.2fs" % at

func replay() -> void:
    new_score()
    for player in players:
        player.stop()
    elapsed = 0.0
    cursor = 0
    playing = true
    draw_state()

func activate() -> void:
    if point.position.x >= 0.0:
        new_score()
    replay()

func _process(delta: float) -> void:
    if playing:
        elapsed += delta
        while cursor < score.size() and float(score[cursor].at) <= elapsed:
            players[cursor].stream = notes[int(score[cursor].voice)]
            players[cursor].play()
            event_started.emit(cursor)
            cursor += 1
        if elapsed >= float(score[-1].at) + NoteVoice.DURATION:
            playing = false
    draw_state()

func draw_state() -> void:
    var end := float(score[-1].at)
    var x := -1.8 + 0.35 * minf(elapsed, end)
    playhead.show_segment(Vector3(x, 0.8, 0.05), Vector3(0, 1.1, 0), 1.1)
    for i in range(markers.size()):
        markers[i].material_override.albedo_color = Color(1, 0.5, 0.7) if i < cursor else Color(0.06, 0.06, 0.07)
    var choice := "REPLAY" if point.position.x < 0.0 else "NEW + PLAY"
    label.text = "Six events kept | seconds across, voice up\nHold point + trigger: %s\n%.2f s | %d / 6" % [choice, elapsed, cursor]
