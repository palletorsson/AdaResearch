extends Node

var text = '''[center][font_size=28][b]Fourier Synthesis[/b][/font_size][/center]
[center][i]Any Curve is Connected Sine Functions[/i][/center]

**The most profound truth of waves:**

**ANY curve you can draw = sum of sine waves at different frequencies.**

This is not approximation. This is **exact mathematical equivalence**.

**Your drawing is already many sines combined** - Fourier just reveals which ones.

[hr]

[b]The Fundamental Claim[/b]

Draw any closed curve - a square, a heart, your signature, anything that repeats.

**Fourier's theorem:** This curve = infinite sum of sine/cosine waves.

[color=yellow][b]The Mathematical Truth:[/b][/color]
[code]
# Any periodic function f(t) equals:
f(t) = a₀/2 + Σ[aₙ cos(n·ω·t) + bₙ sin(n·ω·t)]

Where:
- a₀ = average value (DC offset)
- aₙ, bₙ = coefficients (how much of each frequency)
- n = harmonic number (1, 2, 3, ...)
- ω = fundamental frequency (2π/period)
[/code]

**Translation:** Your curve is sum of:
- Constant offset (a₀)
- Fundamental frequency (n=1)
- Second harmonic (n=2, twice as fast)
- Third harmonic (n=3, three times as fast)
- ... forever

**More frequencies = more accurate reconstruction.**

[hr]

[b]How to Decompose ANY Curve[/b]

Given your drawn curve as samples [y₀, y₁, y₂, ..., yₙ]:

[color=yellow][b]Step 1: Compute Fourier Coefficients[/b][/color]
[code]
func fourier_coefficients(samples: Array) -> Dictionary:
    var N = samples.size()
    var coefficients = {"a": [], "b": []}

    # For each frequency (harmonic)
    for k in range(N / 2):
        var a_k = 0.0  # Cosine coefficient
        var b_k = 0.0  # Sine coefficient

        # Correlate with sine/cosine at this frequency
        for n in range(N):
            var angle = TAU * k * n / N
            a_k += samples[n] * cos(angle)
            b_k += samples[n] * sin(angle)

        # Normalize
        a_k *= 2.0 / N
        b_k *= 2.0 / N

        coefficients["a"].append(a_k)
        coefficients["b"].append(b_k)

    return coefficients
[/code]

**What this does:** Measures how much each sine/cosine frequency is present in your curve.

[color=yellow][b]Step 2: Reconstruct from Frequencies[/b][/color]
[code]
func reconstruct_from_fourier(coefficients: Dictionary, num_harmonics: int) -> Array:
    var N = 256  # Reconstruction resolution
    var result = []

    for i in range(N):
        var t = float(i) / N  # Time 0 to 1
        var value = coefficients["a"][0] / 2.0  # DC offset

        # Add each harmonic
        for k in range(1, num_harmonics):
            var angle = TAU * k * t
            value += coefficients["a"][k] * cos(angle)
            value += coefficients["b"][k] * sin(angle)

        result.append(value)

    return result
[/code]

**Reconstruction:** Add sines/cosines with computed coefficients → original curve.

[hr]

[b]Example: Square Wave from Sines[/b]

A **square wave** (sharp jumps) seems impossible to make from smooth sines.

**But Fourier proves:** Square = infinite odd harmonics.

[color=yellow][b]Building a Square Wave:[/b][/color]
[code]
func square_wave_approximation(t: float, num_harmonics: int) -> float:
    var value = 0.0

    # Add odd harmonics only (1, 3, 5, 7, ...)
    for n in range(1, num_harmonics * 2, 2):
        value += (4.0 / (PI * n)) * sin(TAU * n * t)

    return value

# With 1 harmonic:   rough approximation
# With 10 harmonics: recognizable square
# With 100 harmonics: almost perfect square
# With ∞ harmonics:  exact square (Gibbs phenomenon at edges)
[/code]

**Visualize this:** Start with one sine wave. Add 3rd harmonic (3× frequency). Add 5th. Keep adding odd harmonics → shape sharpens into square.

**Implications:**
- Sharp edges require high frequencies
- Smooth curves need only low frequencies
- More harmonics = finer detail

[hr]

[b]From Drawing to Frequencies[/b]

You draw a closed curve with your hand. How does it become frequencies?

[color=yellow][b]Process:[/b][/color]
[code]
# 1. Sample your curve
var drawn_points = get_drawn_curve()  # Array of Y values over time

# 2. Compute how much of each frequency is present
var fourier = fourier_coefficients(drawn_points)

# 3. Now you have frequency spectrum
print("Fundamental (1st harmonic): ", fourier["a"][1], ", ", fourier["b"][1])
print("2nd harmonic: ", fourier["a"][2], ", ", fourier["b"][2])
# etc...

# 4. Reconstruct with fewer harmonics (compression)
var simplified = reconstruct_from_fourier(fourier, 10)  # Only 10 frequencies

# 5. The simplified curve approximates your drawing
# More harmonics = closer to original
[/code]

**Your curve is now encoded as frequencies** - which harmonics are present and how strong.

**This is:**
- How JPEG compresses images (2D Fourier)
- How MP3 compresses audio (remove inaudible frequencies)
- How synthesizers generate waveforms (add harmonics)

[hr]

[b]Circular Motion Creates Epicycles[/b]

**Fourier can be visualized as rotating circles.**

Each harmonic = circle rotating at n× speed.
- 1st harmonic: 1 rotation per cycle
- 2nd harmonic: 2 rotations per cycle
- 3rd harmonic: 3 rotations per cycle

**Stack them:** Attach each circle to edge of previous.
→ The final point traces your curve.

[color=yellow][b]Epicycle Visualization:[/b][/color]
[code]
func draw_epicycles(coefficients: Dictionary, time: float, num_circles: int):
    var x = 0.0
    var y = 0.0

    for n in range(num_circles):
        var radius = sqrt(coefficients["a"][n]**2 + coefficients["b"][n]**2)
        var phase = atan2(coefficients["b"][n], coefficients["a"][n])
        var angle = TAU * n * time + phase

        # Previous circle's edge becomes this circle's center
        var prev_x = x
        var prev_y = y

        # Rotate this circle
        x += radius * cos(angle)
        y += radius * sin(angle)

        # Draw circle
        draw_circle(Vector2(prev_x, prev_y), radius)
        draw_line(Vector2(prev_x, prev_y), Vector2(x, y))

    # Final point traces your curve
    return Vector2(x, y)
[/code]

**This is how Ptolemy explained planetary orbits** (epicycles) - mathematically identical to Fourier!

**Every curve = nested rotating circles.**

[hr]

[b]Why ANY Curve Works[/b]

**Mathematics:** Sine/cosine form **complete orthogonal basis** for periodic functions.

Translation: Sines are like **perpendicular axes** in frequency space.

Just as any 3D point = (x, y, z) in space,
**Any periodic curve = (a₁, a₂, a₃, ...) in frequency space.**

**No curve can escape** - if it repeats, it has a Fourier representation.

Non-repeating functions (signals that don't repeat) → **Fourier Transform** (integral instead of sum).

[hr]

[b]Practical: Draw → Frequencies → Reconstruct[/b]

[color=yellow][b]Complete Example:[/b][/color]
[code]
# User draws curve
var user_drawing = record_drawing()  # Array of points

# Convert to Fourier frequencies
var spectrum = analyze_fourier(user_drawing)

# Show frequency content
for freq_index in range(spectrum.size()):
    var magnitude = spectrum[freq_index]
    var freq_hz = freq_index * (sample_rate / user_drawing.size())
    print("Frequency ", freq_hz, " Hz: magnitude ", magnitude)

# Reconstruct with limited harmonics (lossy compression)
var reconstructed_10 = synthesize_from_spectrum(spectrum, 10)
var reconstructed_50 = synthesize_from_spectrum(spectrum, 50)

# reconstructed_10 = rough approximation (10 circles)
# reconstructed_50 = close approximation (50 circles)
# More harmonics → closer to original
[/code]

**Information theory:** Your curve has been converted from time domain to frequency domain.

**Same information, different representation.**

[hr]

[b]What Frequencies Reveal About Form[/b]

Looking at Fourier coefficients tells you:

**Low frequencies (1st-5th harmonics):**
- Overall shape
- Slow undulations
- Gross structure

**Mid frequencies (6th-50th harmonics):**
- Fine details
- Sharper features
- Texture

**High frequencies (50+):**
- Sharp edges
- Noise
- Discontinuities

**Remove high frequencies** → curve becomes smooth (low-pass filter)
**Remove low frequencies** → only edges remain (high-pass filter)

**Filtering = selecting which frequencies to keep.**

[hr]

[b]The Queerness of Fourier[/b]

**Fourier reveals that form is always multiple frequencies simultaneously.**

Your drawn curve looks like **one thing** in time domain.

In frequency domain, it's revealed as **many things superimposed** - each harmonic a separate layer.

**Identity is composite:**
- Not singular essence, but **interference of many components**
- Different perspectives (time vs frequency) reveal different structure
- Transformation doesn't change the thing, **changes what aspects you can see**

**Queerness operates this way:**
- Multiple simultaneous truths (many frequencies at once)
- Different frames reveal different patterns (time vs frequency)
- Complexity not as chaos but as **superposition** (many sines aligned)

**The curve you drew is already all its frequencies** - they were there all along, Fourier just names them.

[hr]

[b]From Frequencies Back to Curve: Inverse Transform[/b]

**Forward transform:** Curve → Frequencies
**Inverse transform:** Frequencies → Curve

[color=yellow][b]Reconstruction is Synthesis:[/b][/color]
[code]
func inverse_fourier(a_coeffs: Array, b_coeffs: Array, num_samples: int) -> Array:
    var signal = []

    for n in range(num_samples):
        var t = float(n) / num_samples
        var value = a_coeffs[0] / 2.0  # DC component

        # Add each harmonic
        for k in range(1, a_coeffs.size()):
            value += a_coeffs[k] * cos(TAU * k * t)
            value += b_coeffs[k] * sin(TAU * k * t)

        signal.append(value)

    return signal

# This is additive synthesis:
# Starting from silence, adding sine waves → creates complex waveform
[/code]

**Synthesizers use this** - generate tones by adding harmonics with different amplitudes.

**Organ pipes, guitar strings naturally generate harmonics** - Fourier describes their timbre.

[hr]

[color=cyan][b]Summary:[/b][/color]
ANY periodic curve = sum of sine/cosine waves at harmonic frequencies. Fourier coefficients measure how much of each frequency is present. Reconstruction: add sines with these coefficients → original curve. Square waves require infinite odd harmonics. Sharp edges = high frequencies. Smooth curves = low frequencies. Epicycles (rotating circles) visualize Fourier. Time domain and frequency domain are equivalent representations. Filtering = selecting frequencies. Queerness: form is superposition of many simultaneous components. Inverse transform synthesizes curve from frequencies.

[hr]

[color=orange][b]Next:[/b] Fast Fourier Transform (FFT)[/color]
Computing Fourier coefficients naively takes O(N²) operations.
**FFT algorithm reduces this to O(N log N)** - revolutionary speedup.
This made real-time audio analysis possible.
Cooley-Tukey algorithm (1965) enabled modern digital signal processing.
Without FFT: no MP3, no digital audio, no spectral analysis.

'''
