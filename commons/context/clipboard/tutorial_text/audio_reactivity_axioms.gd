extends Node

var content = """[font_size=28][b]Audio Reactivity[/b][/font_size]
[i]Listening to the Machine[/i]

[i][color=gray]Summary: To make the digital world responsive, we must give it ears. Audio reactivity transforms sound waves (pressure) into data (amplitude/frequency). This process requires sampling—slicing continuous reality into discrete chunks. We ask: what is lost in the cut?[/color][/i]

[hr]

[b]1. The Audio Bus[/b]

Godot's audio server processes sound in buses. To analyze sound, we tap into a bus and read the peak amplitude.

[color=green][b]Code[/b][/color]
[color=green][code]
var bus_index = AudioServer.get_bus_index("Master")
var analyzer = AudioServer.get_bus_effect(bus_index, 0)

# Get the volume (0.0 to 1.0)
var magnitude = analyzer.get_magnitude_for_frequency_range(
    20, 20000
).length()
[/code][/color]

This [code]magnitude[/code] becomes a driver for animation. A loud sound scales a mesh; a quiet sound shrinks it.

[hr]

[b]2. The Spectrum (FFT)[/b]

Volume is crude. To understand *timbre*, we use the Fast Fourier Transform (FFT). It breaks a complex waveform into its constituent sine waves (frequencies).

It asks: "How much bass? How much treble?"

[color=green][b]Code[/b][/color]
[color=green][code]
# Splitting sound into frequency bands
var bass = get_energy(20, 200)
var mids = get_energy(200, 2000)
var highs = get_energy(2000, 20000)

# Mapping to visual properties
material.albedo_color = Color(bass, mids, highs)
[/code][/color]

[hr]

[b]3. Quantization Noise[/b]

Digital audio is not a curve; it is a staircase. We sample the wave 44,100 times a second. Between sample 1 and sample 2, the machine is deaf.

[color=orange][b]Critical Note:[/b][/color] The "glitch" often lives in these gaps. When we visualize audio, we are visualizing a reconstruction, a memory of a sound that has already passed. We are always reacting to the past, never the immediate present. The latency (buffer size) is the time it takes the machine to think about what it heard.

[hr]

[color=cyan][b]→ Next: Resonance[/b][/color]
How materials talk back when struck.
"""

