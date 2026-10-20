extends Node3D

const ClickSound = preload("click_sound.gd")
signal note_played(index: int)

var score: Array[bool] = [true, false, false, true, false, false, false, false]
var bpm := 120.0
var score_running := false
var floor_running := false
var floor_period := 0.5
var step := -1
var phase := 0
var score_elapsed := 0.0
var floor_elapsed := 0.0
var tiles: Array = []
var playhead := MeshInstance3D.new()
var speaker := AudioStreamPlayer3D.new()
var readout := Label3D.new()

func _ready() -> void:
    assert(not score.is_empty() and bpm > 0 and floor_period > 0)
    for x in 4:
        tiles.append([])
        for z in 4:
            tiles[x].append(make_box(Vector3(x * 0.65, 0.025, -3 + z * 0.65), Vector3(0.6, 0.05, 0.6)))
    for i in score.size():
        var cell := make_box(Vector3(i * 0.65, 0.8, 0), Vector3(0.55, 0.15, 0.55))
        cell.material_override.albedo_color = Color.WHITE if score[i] else Color(0.08, 0.08, 0.08)
    var marker_mesh := BoxMesh.new()
    marker_mesh.size = Vector3(0.55, 0.03, 0.55)
    playhead.mesh = marker_mesh
    playhead.visible = false
    add_child(playhead)
    speaker.stream = ClickSound.make()
    speaker.position = Vector3(2.3, 1, 0)
    speaker.volume_db = -12
    add_child(speaker)
    readout.position = Vector3(2.3, 2.0, -0.6)
    readout.font_size = 26
    add_child(readout)
    var names := ["FLOOR PLAY/HOLD", "FLOOR STEP", "SCORE PLAY/HOLD", "SCORE STEP"]
    for i in names.size():
        var button := make_box(Vector3(i * 1.6, 0.4, 2.3), Vector3(0.9, 0.15, 0.9))
        var sensor := Area3D.new()
        sensor.collision_layer = 0
        sensor.collision_mask = 1
        sensor.set_collision_mask_value(20, true)
        button.add_child(sensor)
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(0.9, 1.2, 0.9)
        collision.shape = shape
        sensor.add_child(collision)
        sensor.body_entered.connect(_on_control.bind(i))
        var label := Label3D.new()
        label.text = names[i]
        label.font_size = 22
        label.position = button.position + Vector3(0, 0.7, 0)
        add_child(label)
    refresh_floor()
    refresh_readout()

func make_box(at: Vector3, size: Vector3) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    body.mesh = box
    body.material_override = StandardMaterial3D.new()
    body.position = at
    add_child(body)
    return body

func _process(delta: float) -> void:
    advance(delta)

func advance(delta: float) -> void:
    if floor_running:
        floor_elapsed += delta
        var ticks := floori(floor_elapsed / floor_period)
        if ticks > 0:
            floor_elapsed -= ticks * floor_period
            phase = (phase + ticks) % 2
            refresh_floor()
    if score_running:
        var duration := 60.0 / bpm / 4.0
        score_elapsed += delta
        var ticks := floori(score_elapsed / duration)
        if ticks > 0:
            score_elapsed -= ticks * duration
            step = (step + ticks) % score.size()
            read_step()
    refresh_readout()

func _on_control(body: Node3D, action: int) -> void:
    if not (body.is_in_group("player_body") or body.is_in_group("em_walker")):
        return
    if action == 0:
        floor_running = not floor_running
    elif action == 1 and not floor_running:
        phase = (phase + 1) % 2
        refresh_floor()
    elif action == 2:
        score_running = not score_running
    elif action == 3 and not score_running:
        step = (step + 1) % score.size()
        read_step()
    refresh_readout()

func refresh_floor() -> void:
    for x in 4:
        for z in 4:
            var value := (x + z + phase) % 2
            tiles[x][z].material_override.albedo_color = Color.WHITE if value == 1 else Color(0.08, 0.08, 0.08)

func read_step() -> void:
    playhead.visible = true
    playhead.position = Vector3(step * 0.65, 1.05, 0)
    if score[step]:
        speaker.play()
        note_played.emit(step)

func refresh_readout() -> void:
    readout.text = "floor phase %d | playing %s\nscore step %d | playing %s" % [phase, str(floor_running), step, str(score_running)]
