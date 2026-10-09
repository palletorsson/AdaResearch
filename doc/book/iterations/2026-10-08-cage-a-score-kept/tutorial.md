# John Cage — a score kept

## Learning elements

- Choosing from a finite sound vocabulary.
- Keeping an event's time and sound index in a dictionary.
- Reading an ordered event list with a clock and cursor.
- Replaying a record without drawing new choices.

Let the museum's soundscape finish loading. Hear the continuing background, then wait for a separate event. You do not know its next entrance. Its possible sounds have nevertheless been prepared.

Bernini separated a stored form from its movement. Here we separate a score from its performance. Build a six-event study beside the existing soundscape. Make the choices once, keep them, then listen to that record again.

## Carry the sound and the point

Keep `point_body.gd` and `line_skin.gd`. Copy the two sound-making functions from Effect Sound into `note_voice.gd`; their sample calculation is unchanged. Three modulation depths give us three short sounds at the same base pitch. Sound synthesis is carried material here. Choosing and scheduling those sounds is the new work.

In your prepared Endless Museum working copy, put all four files together. Attach `08_chance_score.gd` to an empty, unit-scale `Node3D` at hall-local `(16, 0, 10)`, yaw 180 degrees. This is the entrance study bay. The museum supplies the floor, camera, light, player and XR pickup/trigger routing. The script creates its point, score markers, labels and audio players. Only the point has a pickup collider; the score is a visual display.

Grab the black point. Hold it left of the study's centre and press the trigger to replay. Hold it on the right and press to make a new score and play it. The label names the selected action. Both actions restart the clock. Releasing the sphere keeps it where you leave it. Left and right use the study's **local X**, so turning the whole study does not reverse its own controls.

Read the score before playing. Horizontal position represents seconds from the start; the three rows are sound indices, zero to two. The small cubes are six events. Their labels give their times. The vertical guide moves across the record, and events turn pink as they are dispatched. All six notes sound from one position in the study; the display is a timeline, not an arrangement of six spatial sound sources.

## Complete program

<!-- student-code:08_chance_score.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const NoteVoice = preload("note_voice.gd")
signal event_started(index: int)
var min_interval := 0.8
var max_interval := 1.6
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
```


## Choose once

`notes` holds three generated clips. `rng.randi_range(0, notes.size() - 1)` chooses a valid index, including both ends of that range. `randf_range` chooses the wait before an event. This is a small introduction to bounded random choices; distributions and seeds receive their own sequence later.

In `new_score`, `at` begins at zero and **accumulates** the waits. Waits of 1.0, 0.8 and 1.4 seconds produce event times 1.0, 1.8 and 3.2. They do not produce three unrelated delays measured from now. Every wait is positive, so the event list is already in time order.

Each dictionary keeps two named fields: `at` is a time in seconds; `voice` is an address in `notes`. The array keeps their order. This extends Trace's retained list: a record can carry several related values rather than only a position. Neither the row number nor the timestamp contains the sound itself.

The generator runs when the study starts and when you choose NEW. It does not run on every frame. A new draw can repeat an earlier choice; randomness does not promise novelty. The current score survives replay, but only while this study exists. We are not yet writing it to a file.

## Read the record

`replay` stops the players and resets the clock and `cursor`. It leaves `score` and the random generator untouched. `cursor` is the address of the next event, starting at zero. Every frame, `elapsed` grows by `delta`. When an event's stored time has arrived, its player receives the chosen clip and starts.

The `while` matters. A slow frame can cross more than one event time. The loop dispatches every overdue event in order and advances the cursor after each one. An `if` would dispatch only one per frame and could leave overdue events waiting. Six players allow overdue notes to overlap instead of replacing one another in a single player. `event_started` reports the dispatched index; the tests use that signal to inspect what happened.

This is a frame-timed sequencer. If a frame is very late, overdue notes start together. The saved choices and intended times remain the same; the heard timing is not sample-accurate. Effect Sound calculated samples at 44,100 per second. Starting playback from `_process` is a different clock, with frame and audio-buffer delays.

## Predict, replay, change

Read the first event's row and time aloud. Trigger REPLAY. Check its entrance and the moving guide. Replay again: every marker must remain in place, with the same row and timestamp. Then choose NEW. The displayed choices are replaced and the clock starts again. The larger museum soundscape continues independently; it does not share this replay command.

For your own variation, set both `min_interval` and `max_interval` to `1.0`. Predict all six timestamps before running. They should be 1, 2, 3, 4, 5 and 6 seconds, while the selected voices can still differ. Explain what became periodic and what still varies. The download includes this complete variation as `08_equal_intervals.gd`; attach it instead of the main script to compare.

Keep the distinction between selecting an event and starting it. In Air Music, your strike will supply the beginning. The sound can continue after your contact ends.

## Carried code

`note_voice.gd` — Effect Sound's unchanged sample and note functions, gathered into a small reusable helper. `make_note` returns a clip; it does not play it.

<!-- student-code:note_voice.gd -->

```gdscript
extends RefCounted

const SAMPLE_RATE := 44100
const DURATION := 0.6
const ATTACK := 0.01
var frequency := 440.0
var ratio := 2.0

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
```


`point_body.gd` — the point and its existing pickup behaviour.

<!-- student-code:point_body.gd -->

```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```


`line_skin.gd` — the finite cylinder used for rows and playhead.

<!-- student-code:line_skin.gd -->

```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


Implementation references: [Godot RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html) and [audio synchronisation](https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html). The installed soundscape is `algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.gd`. Its prepared vocabulary and live scheduling are richer and different from this six-event study. Neither this lesson nor that artifact records your breath or performs a particular Cage score.
