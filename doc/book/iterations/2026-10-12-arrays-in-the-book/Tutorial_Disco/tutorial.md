# Disco — a reader returns

**Learning elements**

- A Boolean score
- A playhead that wraps through addresses
- Elapsed time, tempo and retained remainder
- Independent readers of independent records

Hold the museum floor, then press ONE STEP. Black and white exchange places. Hold the sequencer instead and let the floor run. One clock can stop while the other continues. Your footsteps are not being recorded into its score.

We bring back the clock from Transformation and the retained addresses from Array. This lesson has two short readings: the floor uses a changing phase in a rule; the score keeps decisions that a playhead visits. The installed instrument has four tracks and sixteen steps. Our construction begins with one track and eight steps so you can hear and follow each visit.

## Begin with both clocks held

Save the two files below together. Attach `lesson.gd` to an empty unit-scale `Node3D`, `DiscoStudy`, at floor level on clear floor in this museum hall. Allow about six metres across and seven deep. Keep the museum's player and support floor. The little floor behind the score is visual; it does not add holes or steps to the museum floor.

The four labelled pads use the overlap connection from Array. Walk into a pad to activate it, then leave before entering again. A pad is an `Area3D` sensor, not a physical push switch. The VR player's declared group and layer are the same as before. No controller installation or new input mapping is required here.

First use FLOOR STEP twice. Then leave the pad and return to SCORE STEP until you have visited all eight places. White score cells mean `true`, asking for a click; dark cells mean `false`, asking for silence. A small raised marker shows the last address read. It starts hidden because step `-1` means no address has been read yet.

### lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const ClickSound = preload("click_sound.gd")
signal note_played(index: int)

var score: Array[bool] = [true, false, false, false, true, false, false, false]
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
```

### click_sound.gd — supplied receiver

This small receiver creates one short, quiet sound used by every event. Copy it unchanged for now. Its sample construction is printed so `speaker.play()` has a real source. Learning sound synthesis is a later task.

<!-- student-code:click_sound.gd -->
```gdscript
extends RefCounted

static func make() -> AudioStreamWAV:
    var bytes := PackedByteArray()
    var sample_count := 1323
    bytes.resize(sample_count)
    for i in sample_count:
        var sign_value := 1.0 if i % 50 < 25 else -1.0
        var envelope := 1.0 - float(i) / sample_count
        bytes[i] = int(48 * sign_value * envelope) & 255
    var sound := AudioStreamWAV.new()
    sound.format = AudioStreamWAV.FORMAT_8_BITS
    sound.mix_rate = 22050
    sound.data = bytes
    return sound
```

## A field receives a phase

The floor uses `(x + z + phase) % 2`. At phase zero, neighbouring cells alternate. Adding one exchanges them; adding another returns to the first arrangement. Sixteen boxes keep their positions. Their separately owned materials let one address change without repainting every box through a shared material.

The construction function returns each new box, as in Array. The floor stores those references in `tiles[x][z]`. The two nested loops in `refresh_floor` revisit them. This time we change an appearance instead of occupancy. We still use only black, white and grey before Colour.

Start FLOOR PLAY/HOLD. Every `floor_period` seconds the phase advances. Hold it again. FLOOR STEP changes the phase only while held, giving you time to compare two states. Walking on the little field does not advance or record anything.

## A score receives a reader

`score` is an `Array[bool]`: each entry is either `true` or `false`. The first and fifth entries begin true. `step` names the most recently read address. Adding one and taking `% score.size()` visits the next address and returns from seven to zero. Reading an event does not consume it. Its value remains available on the next circuit.

SCORE STEP makes one visit while playback is held. SCORE PLAY/HOLD lets elapsed time choose when to visit. The duration `60.0 / bpm / 4.0` gives a sixteenth-note step when BPM counts quarter-note beats. At 120 BPM, one step takes 0.125 seconds. Tempo describes visits, not how many entries the array owns.

`floori` takes the integer part of a non-negative quotient. Dividing accumulated seconds by step duration tells us how many complete steps have elapsed. Subtracting those complete durations keeps the leftover fraction. Resetting the accumulator to zero would repeatedly discard that time and make playback drift.

There is a deliberate rule for a stalled frame: advance the playhead past all elapsed steps, but sound only the final visited address. Missed visits stay in the stored score; they are not played in a burst. This small reader follows elapsed time without claiming to be an audio-accurate scheduler. Synthesis and precise musical scheduling can develop later.

The receiver stores signed sample bytes, their sample rate and a short decay. Its masking expression keeps a signed value's byte representation in the byte array. Those encoding details belong to the supplied sound helper, not to the meaning of a Boolean score. [Godot's AudioStreamWAV reference](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html) specifies signed eight-bit PCM for this format.

## Keep one thing; change another

Play the score while holding the floor. Then reverse the arrangement. Neither clock writes into the other clock's record. Holding a reader retains its position and fractional elapsed time; resuming continues it. Stopping does not abruptly cut a click already sounding. Our small study omits the museum's additional sound-to-floor flash bridge.

Keep BPM at 120. Move the second `true` from index four to index three, and run again. The sound is the same; the interval between its visits changes. Restore that score, then change BPM to 90. The addresses stay fixed while their visits spread out in time.

Choose your own eight-entry score. Predict which steps will sound before you use SCORE STEP. Then run it, hold it, and resume. Explain which variable keeps your decisions and which keeps the reader's place. Changing the source and starting again makes a fresh study; pause and resume happen within the current run.

Across these halls, a value has meant an occupant, an orientation and an instruction to sound. The array gives each value an address; the reader gives it work to do. Keep that distinction for Colour. The same familiar forms will receive material values, and the neighbours already held in an arrangement will change how those values appear.
