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
