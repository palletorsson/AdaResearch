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
