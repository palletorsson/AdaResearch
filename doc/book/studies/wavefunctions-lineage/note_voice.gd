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

