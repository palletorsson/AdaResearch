# A note continues after contact

## Learning elements

- Contact as an onset event
- One audio player per voice
- Restarting one voice; overlapping two
- Playback age and decay
- Adding samples from independent voices

In the Cage hall, a kept score supplied the times. Here your hand supplies them. Strike a bar of the existing metallophone, lift the stick away, then strike another. Two notes can continue together. Strike the first again: its age starts over while the second keeps going.

We reconstruct that distinction with two touch bars and the black PointBody you already made. Move the point into one bar, withdraw it, then touch the other. The bars are sensors: they detect entry without blocking the sphere. The museum instrument has a physical stick, speed-sensitive strikes and eight bars. Our study keeps two voices at a fixed level so the new operation is clear.

## Continue inside the museum

Use your Day Zero Endless Museum working copy, with its camera, lighting, player and XR Tools pickup already running. Save the four scripts below together. Keep `point_body.gd` and `line_skin.gd` unchanged. Attach `09_contact_voices.gd` to an empty, unit-scale Node3D in the Air Music learner bay: hall-local position **(13, 0, 14)**, Y rotation **180 degrees**. Run that museum scene as before. Do not attach this study to the existing metallophone.

The script makes the point, two visible bars, contact volumes, players and readout. There are no named scene children to prepare. Grab with the established pickup control and move the point into a bar. No trigger press is needed. Desktop pickup uses the same point; the lesson does not install another player.

## Two voices, two beginnings

The arrays use one shared index: bar 0, player 0 and samples 0 belong together. `body_entered` supplies the contacting body; `bind(i)` adds the bar's index. We accept only this point. The collision mask includes both its normal layer and the layer XR Tools uses while it is held.

`players[index].play()` starts that player's clip from the beginning. Calling it again replaces that voice's current playback. We do not stop the other player. Remaining inside a bar causes no further entry event: leave and return to strike again.

<!-- student-code:09_contact_voices.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const RingVoice = preload("ring_voice.gd")
signal struck(index: int)
var frequencies: Array[float] = [261.63, 392.0]
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
```


Each audio player owns its playback clock. `ages_now()` reads those clocks once for each drawing frame; `-1` means quiet. The visible study does not invent a second timer and try to keep it synchronized with sound. In conceptual terms, age is the time since this voice's onset. Godot gives us that age through `get_playback_position()`.

`sum_at()` reads each active voice at its own age plus the same small offset, then adds the values. A new strike changes one age, so it changes how the samples meet. The pink line shows 12 milliseconds across its width at a fixed vertical scale. It reads the generated data before spatial attenuation and the audio bus. Moving your head can change what you hear without changing this curve. Playback position is reported at audio-mix intervals; this is an inspectable display, not a sample-accurate oscilloscope.

## Let the note fade

Effect Sound already taught a sampled sine, an envelope and 16-bit encoding. `RingVoice` uses that construction with a longer, plain decaying sine. The previous phase-modulated `NoteVoice` remains available to Cage; we do not change its sound to write this lesson.

<!-- student-code:ring_voice.gd -->

```gdscript
extends RefCounted

const SAMPLE_RATE := 44100
const DURATION := 3.0
const DECAY := 0.8

func sample_at(age: float, frequency: float) -> float:
    if age < 0.0 or age >= DURATION:
        return 0.0
    var envelope := minf(age / 0.005, 1.0) * exp(-age / DECAY)
    envelope *= minf((DURATION - age) / 0.05, 1.0)
    return 0.25 * sin(TAU * frequency * age) * envelope

func make_note(frequency: float) -> AudioStreamWAV:
    var bytes := PackedByteArray()
    var count := int(SAMPLE_RATE * DURATION)
    bytes.resize(count * 2)
    for i in range(count):
        bytes.encode_s16(i * 2, int(sample_at(float(i) / SAMPLE_RATE, frequency) * 32767.0))
    var note := AudioStreamWAV.new()
    note.format = AudioStreamWAV.FORMAT_16_BITS
    note.mix_rate = SAMPLE_RATE
    note.stereo = false
    note.data = bytes
    return note

func read_sample(bytes: PackedByteArray, age: float) -> float:
    if age < 0.0:
        return 0.0
    var index := int(age * SAMPLE_RATE)
    if index * 2 >= bytes.size():
        return 0.0
    return float(bytes.decode_s16(index * 2)) / 32767.0
```


`exp(-age / DECAY)` falls as age grows. With `DECAY = 0.8`, its value is about 0.37 after 0.8 seconds. That number is a decay time constant, not the note's duration. The finite buffer lasts three seconds. A short attack and final fade soften its edges. The chosen frequency makes the sound; the box's size does not calculate a metal bar's resonance.

`encode_s16()` stores a signed integer for each sample. `read_sample()` reverses that conversion for the display, returning zero before or after the buffer. We cache the bytes once in `samples`, so drawing does not repeatedly fetch whole sound resources. Each voice is bounded by 0.25; two unscaled source voices cannot exceed 0.5 in magnitude. That leaves source headroom. The prepared audio output still determines the listening level.

## The two carried pieces

These are the same point body and finite cylinder renderer. Their complete files are included so this reconstruction has no missing dependency; the black finish is applied by the main script.

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


## Test the distinction

1. Touch the left bar and withdraw. One age should keep increasing after contact ends.
2. Before it finishes, touch the right. There should be two ages. The first must not jump back to zero.
3. Leave the right bar and return to it. Only the right age restarts. Hold the point still inside: it must not keep restarting.
4. Withdraw and wait three seconds. Both labels should read quiet, and the sum should become a straight line.

Now change only the second frequency from `392.0` to `261.63`. Predict what stays separate. Run again, striking the bars with a gap. The two clips now contain the same samples, but their playback ages remain independent. Equal pitch does not require equal phase or simultaneous beginnings. The download includes the complete `09_same_pitch.gd` variation; attach it instead of the original, never alongside it in the same bay.

Native tests extract the exact printed scripts, move the actual sphere collider through both areas, test the held collision layer, reject an unrelated body, check independent restart and compare the displayed sum with stored samples. They also run the same-pitch variation and wait for playback to finish. These assertions check the reconstruction; they do not establish headset comfort or whether a reader can build it unaided.

The original eight-bar instrument remains in the hall. Return to it and try the same sequence with its stick. Sky Stairs next asks what a sampled curve needs before it can support a body. Later, the beat and synthesis studies will make relations between simultaneous waves the subject.
