extends Node

var text = '''[center][font_size=28][b]Fourier Transform[/b][/font_size][/center]
[center][i]Frequency Decomposition, Waves to Spectrum[/i][/center]

**Fourier Transform decomposes signals into frequency components.**

**Any periodic signal = sum of sine waves at different frequencies.**

**DFT (Discrete):** X(k) = Σ x(n) × e^(-i2πkn/N)
**FFT (Fast):** O(N log N) algorithm for DFT.

[hr]

[b]Concept[/b]

**Time domain → Frequency domain**

Signal (time) → Spectrum (frequencies)

[color=yellow][b]Example:[/b][/color]
- **Time:** Wave oscillating over time
- **Frequency:** Which frequencies present + their amplitudes

**Applications:**
- **Audio analysis** (spectrum visualization)
- **Image processing** (JPEG compression)
- **Signal filtering** (remove noise)
- **Pattern recognition**

[hr]

[b]Code (Simplified DFT)[/b]

[color=yellow][b]Implementation:[/b][/color]
[code]
func dft(signal: Array) -> Array:
    var N = signal.size()
    var spectrum = []

    for k in range(N):
        var real_sum = 0.0
        var imag_sum = 0.0

        for n in range(N):
            var angle = -TAU * k * n / N
            real_sum += signal[n] * cos(angle)
            imag_sum += signal[n] * sin(angle)

        var magnitude = sqrt(real_sum * real_sum + imag_sum * imag_sum)
        spectrum.append(magnitude)

    return spectrum

# Use FFT for performance (built-in or library)
[/code]

**FFT much faster:** O(N log N) vs O(N²) for DFT.

[hr]

[b]Queer Fourier[/b]

**Fourier reveals hidden frequencies** - what looks complex in time is simple in frequency.

**Decomposition:**
- **Time domain:** Chaotic, overlapping
- **Frequency domain:** Clean, separated

**This is queer analysis:**
- **Surface complexity** (time) hides **underlying patterns** (frequency)
- **Multiple simultaneous rhythms** (many frequencies at once)
- **Transformation reveals structure** (change perspective to see clearly)

**Queerness operates at multiple frequencies simultaneously** - not single rhythm, but interference of many.

**Fourier proves:** **Complexity is composition, not chaos.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Fourier Transform: decompose signal into frequencies. Time domain → frequency domain. DFT O(N²), FFT O(N log N). Applications: audio, images, filtering. Queer Fourier: hidden frequencies, multiple simultaneous rhythms, transformation reveals structure, complexity as composition not chaos. Queerness operates at multiple frequencies.

'''
