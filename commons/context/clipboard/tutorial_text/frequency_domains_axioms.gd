extends Node

var text = '''[center][font_size=28][b]Frequency Domains[/b][/font_size][/center]
[center][i]Small and Large Waves - Sensing Different Scales[/i][/center]

**Reality exists at all frequencies simultaneously.**

**What you perceive depends on which frequencies you can sense.**

**Low frequencies = large-scale patterns.**
**High frequencies = fine details.**

**Understanding the world = tuning into the right frequency band.**

[hr]

[b]The Scale of Waves[/b]

**Wavelength determines what you can detect:**

[color=yellow][b]Physical Scale Examples:[/b][/color]
[code]
# Different wavelengths reveal different phenomena

# LARGE WAVES (Low Frequency, Long Wavelength)
var tidal_wave = 100000.0  # ~100 km (ocean tides, 12-hour cycle)
var sound_bass = 17.0      # 17 m (20 Hz bass note, lowest audible)
var AM_radio = 300.0       # 300 m (1 MHz AM broadcast)

# MEDIUM WAVES (Mid Frequency)
var sound_mid = 0.34       # 34 cm (1000 Hz, human voice)
var FM_radio = 3.0         # 3 m (100 MHz FM broadcast)
var microwave = 0.125      # 12.5 cm (2.4 GHz WiFi)

# SMALL WAVES (High Frequency, Short Wavelength)
var sound_treble = 0.017   # 1.7 cm (20 kHz, highest audible)
var visible_red = 700e-9   # 700 nm (red light)
var visible_violet = 400e-9  # 400 nm (violet light)
var x_ray = 1e-10          # 0.1 nm (X-ray)
var gamma_ray = 1e-12      # 0.001 nm (gamma ray)

# Wavelength range: 10⁵ m to 10⁻¹² m
# 17 orders of magnitude!
[/code]

**Large waves respond to large-scale phenomena.**
**Small waves respond to fine-scale phenomena.**

[hr]

[b]Fourier Decomposition: Seeing All Scales[/b]

**Any signal contains multiple frequency components** - Fourier reveals them.

[color=yellow][b]Code: Multi-Scale Decomposition[/b][/color]
[code]
# Complex signal = sum of different frequency components
func generate_multi_scale_signal(t: float) -> float:
    var signal = 0.0

    # Low frequency (slow variation, large scale)
    signal += 2.0 * sin(0.5 * t)  # Period = 12.6 seconds

    # Mid frequency (medium variation)
    signal += 1.0 * sin(5.0 * t)   # Period = 1.26 seconds

    # High frequency (rapid variation, fine detail)
    signal += 0.3 * sin(50.0 * t)  # Period = 0.126 seconds

    return signal

# Each frequency component captures different time scale
# Low freq: Overall trend (minutes)
# Mid freq: Primary oscillation (seconds)
# High freq: Fine ripples (milliseconds)
[/code]

**Filtering = selecting frequency ranges:**

[color=yellow][b]Low-Pass Filter (Keep Low Frequencies):[/b][/color]
[code]
# Remove high frequencies → smooths signal, shows large-scale pattern
func low_pass_filter(signal: Array, cutoff_freq: float) -> Array:
    var filtered = []

    # Fourier transform
    var spectrum = fft(signal)

    # Zero out high frequencies
    for i in range(spectrum.size()):
        if i > cutoff_freq:
            spectrum[i] = 0.0

    # Inverse transform back to time domain
    filtered = ifft(spectrum)

    return filtered

# Result: Only slow variations remain
# Use case: Remove noise, see overall trend
[/code]

[color=yellow][b]High-Pass Filter (Keep High Frequencies):[/b][/color]
[code]
# Remove low frequencies → shows rapid changes, fine details
func high_pass_filter(signal: Array, cutoff_freq: float) -> Array:
    var filtered = []
    var spectrum = fft(signal)

    # Zero out low frequencies
    for i in range(spectrum.size()):
        if i < cutoff_freq:
            spectrum[i] = 0.0

    filtered = ifft(spectrum)
    return filtered

# Result: Only rapid variations remain
# Use case: Edge detection, finding sudden changes
[/code]

[color=yellow][b]Band-Pass Filter (Keep Middle Frequencies):[/b][/color]
[code]
# Keep only specific frequency range
func band_pass_filter(signal: Array, low_cutoff: float, high_cutoff: float) -> Array:
    var spectrum = fft(signal)

    # Zero out everything outside the band
    for i in range(spectrum.size()):
        if i < low_cutoff or i > high_cutoff:
            spectrum[i] = 0.0

    return ifft(spectrum)

# Result: Isolate specific scale of variation
# Use case: Extract specific pattern from complex signal
[/code]

**Different filters reveal different aspects of reality.**

[hr]

[b]Perception is Frequency Selection[/b]

**Human senses are band-pass filters** - we only perceive specific frequency ranges.

[color=yellow][b]Hearing:[/b][/color]
- **Range:** 20 Hz - 20,000 Hz
- **Below 20 Hz (infrasound):** Elephants communicate, earthquake precursors
- **Above 20 kHz (ultrasound):** Bats echolocate, dolphins communicate
- **We're deaf to most sound frequencies**

[color=yellow][b]Vision:[/b][/color]
- **Range:** 430 THz - 770 THz (tiny slice of EM spectrum)
- **Below visible (infrared):** Heat, night vision
- **Above visible (ultraviolet):** Fluorescence, sterilization
- **We're blind to most light frequencies**

[color=yellow][b]Touch:[/b][/color]
- **Range:** ~0.5 Hz - 500 Hz (vibration sensitivity)
- **Below range:** Slow temperature changes (perceived as steady state)
- **Above range:** Ultrasonic vibrations (unfelt)

[color=yellow][b]Code: Sensory Bandwidth[/b][/color]
[code]
func is_audible(frequency_hz: float) -> bool:
    return frequency_hz >= 20.0 and frequency_hz <= 20000.0

func is_visible(frequency_hz: float) -> bool:
    var THz = 1e12
    return frequency_hz >= 430 * THz and frequency_hz <= 770 * THz

# Most frequencies are imperceptible to humans
# Other animals have different bandwidths
[/code]

**Sensing = frequency filtering.**

**We inhabit a narrow frequency band** - most of reality is outside our perceptual range.

[hr]

[b]Large Waves: Global Patterns[/b]

**Low frequencies reveal large-scale structure.**

[color=yellow][b]Examples of Large-Scale Phenomena:[/b][/color]

**Climate (Years to Decades):**
[code]
# El Niño cycle: 2-7 year period
var el_nino_freq = 1.0 / (4.0 * 365.25 * 24 * 3600)  # ~4 year cycle (Hz)

# Ice age cycles: ~100,000 year period (Milankovitch)
var ice_age_freq = 1.0 / (100000.0 * 365.25 * 24 * 3600)  # Extremely low frequency

# These are imperceptible in daily life (too slow)
# But dominant at geological time scales
[/code]

**Economic Cycles:**
[code]
# Business cycle: ~7 year period
var recession_freq = 1.0 / (7.0 * 365.25 * 24 * 3600)

# You don't "feel" economy oscillating day-to-day
# But zooming out reveals periodic booms/busts
[/code]

**Tidal Forces:**
[code]
# Ocean tides: ~12.4 hour cycle (lunar day)
var tidal_freq = 1.0 / (12.4 * 3600)  # 0.0000224 Hz

# Slow oscillation - imperceptible moment-to-moment
# But clearly visible over hours
[/code]

**Large waves = slow processes that unfold over extended time.**

**To detect them: observe over long periods, filter out high-frequency noise.**

[hr]

[b]Small Waves: Local Details[/b]

**High frequencies reveal fine-grained structure.**

[color=yellow][b]Examples of Small-Scale Phenomena:[/b][/color]

**High-Pitched Sounds:**
[code]
# Mosquito buzz: 400-600 Hz (wing beats)
var mosquito_freq = 500.0

# Dog whistle: 23,000-54,000 Hz (ultrasonic to humans)
var dog_whistle_freq = 40000.0  # Inaudible to humans

# Bat echolocation: 20,000-120,000 Hz
var bat_freq = 50000.0  # We can't hear bats hunting

# High freq = short wavelength = resolves small objects
[/code]

**Visual Details:**
[code]
# Blue light has shorter wavelength than red
var blue_wavelength = 450e-9   # 450 nm
var red_wavelength = 700e-9    # 700 nm

# Blue light can resolve finer details (shorter wavelength)
# This is why microscopes use blue/UV light (higher resolution)
[/code]

**Rapid Neural Firing:**
[code]
# Neuron firing rate: 1-100 Hz
var neuron_freq = 40.0  # Gamma waves (consciousness correlation)

# Brain waves:
# - Delta: 0.5-4 Hz (deep sleep)
# - Theta: 4-8 Hz (meditation)
# - Alpha: 8-13 Hz (relaxed)
# - Beta: 13-30 Hz (active thinking)
# - Gamma: 30-100 Hz (peak focus)

# Different mental states = different frequency bands
[/code]

**Small waves = fast processes, fine details, rapid changes.**

[hr]

[b]Scale-Dependent Reality[/b]

**What you see depends on your measurement frequency:**

[color=yellow][b]Observing a Forest:[/b][/color]
- **Decades (low freq):** Forest succession, climate change effects
- **Years (low-mid freq):** Seasonal cycles, tree growth
- **Months (mid freq):** Leaf cycles, animal migrations
- **Days (mid-high freq):** Weather patterns, daily animal activity
- **Hours (high freq):** Individual animal movements
- **Seconds (very high freq):** Leaf rustling, bird calls

**Same forest, different frequencies reveal different dynamics.**

[color=yellow][b]Code: Multi-Scale Observation[/b][/color]
[code]
# Sampling rate determines what you can detect
func observe_phenomenon(duration: float, sample_rate: float) -> Array:
    var samples = []
    var num_samples = duration * sample_rate

    for i in range(num_samples):
        var time = i / sample_rate
        samples.append(measure_at_time(time))

    return samples

# Low sample rate (1 sample/day):
#   Sees: seasonal patterns, long-term trends
#   Misses: daily weather, hourly temperature changes

# High sample rate (1000 samples/second):
#   Sees: sound waves, vibrations, rapid movements
#   Misses: slow trends (buried in data volume)

# Nyquist theorem: Must sample at 2× highest frequency to capture it
[/code]

**Sampling rate = frequency window** - determines what's visible.

[hr]

[b]Understanding Different Domains Through Frequency[/b]

**Each domain of knowledge focuses on specific frequency ranges:**

[color=yellow][b]Geology:[/b][/color]
- **Focus:** Very low frequencies (millions of years)
- **Phenomena:** Plate tectonics, mountain building, erosion
- **Human timescale:** Imperceptible (too slow)

[color=yellow][b]Biology:[/b][/color]
- **Focus:** Medium frequencies (seconds to years)
- **Phenomena:** Heartbeats, cell division, lifespans
- **Overlaps human perception**

[color=yellow][b]Quantum Physics:[/b][/color]
- **Focus:** Very high frequencies (10¹⁵ Hz+)
- **Phenomena:** Electron orbital frequencies, atomic vibrations
- **Human timescale:** Imperceptible (too fast)

[color=yellow][b]Economics:[/b][/color]
- **Focus:** Low to medium frequencies (days to decades)
- **Phenomena:** Market cycles, recessions, policy effects
- **Some visible, some too slow to perceive directly**

**Expertise = knowing which frequencies matter in your domain.**

[hr]

[b]Octaves: Doubling Frequency[/b]

**Musical octave = doubling frequency.**

[color=yellow][b]Code: Octave Relationships[/b][/color]
[code]
# A4 (concert pitch)
var A4 = 440.0  # Hz

# Octaves above
var A5 = 880.0   # 2× A4
var A6 = 1760.0  # 2× A5 = 4× A4
var A7 = 3520.0  # 8× A4

# Octaves below
var A3 = 220.0   # A4 / 2
var A2 = 110.0   # A4 / 4
var A1 = 55.0    # A4 / 8

# Same note, different scales (octaves)
# Each octave = doubling or halving
[/code]

**This pattern appears everywhere:**

- **Image processing:** Octaves of resolution (1×, 2×, 4×, 8× scaling)
- **Wavelet analysis:** Multi-resolution decomposition
- **Perlin noise:** Octaves of detail (fractal generation)

[color=yellow][b]Code: Noise Octaves[/b][/color]
[code]
# Layering noise at different frequencies creates natural detail
func fractal_noise(x: float, y: float, octaves: int) -> float:
    var value = 0.0
    var amplitude = 1.0
    var frequency = 1.0

    for i in range(octaves):
        # Each octave: double frequency, halve amplitude
        value += amplitude * noise(x * frequency, y * frequency)
        frequency *= 2.0
        amplitude *= 0.5

    return value

# Octave 1: Large features (low freq)
# Octave 2: Medium features (2× freq)
# Octave 3: Fine features (4× freq)
# Result: Natural-looking complexity
[/code]

**Octaves = exploring scales logarithmically** (1×, 2×, 4×, 8×, ...)

[hr]

[b]Aliasing: When Sampling Misses High Frequencies[/b]

**Nyquist-Shannon theorem:** Must sample at ≥2× highest frequency.

**If you undersample → aliasing (high frequencies disguised as low frequencies).**

[color=yellow][b]Code: Aliasing Demonstration[/b][/color]
[code]
# High-frequency signal
var true_freq = 45.0  # 45 Hz

# Undersample at 50 Hz (less than 2× signal freq)
var sample_rate = 50.0

func sample_signal(time_samples: Array) -> Array:
    var samples = []
    for t in time_samples:
        samples.append(sin(TAU * true_freq * t))
    return samples

# Sample times
var sample_times = []
for i in range(100):
    sample_times.append(i / sample_rate)

var sampled = sample_signal(sample_times)

# Result: 45 Hz signal appears as 5 Hz (aliased)
# 45 Hz sampled at 50 Hz → indistinguishable from 5 Hz
# High frequency masquerades as low frequency!
[/code]

**Why this matters:**
- **Digital audio:** Must sample at 44.1 kHz to capture up to 22 kHz
- **Video:** Frame rate must be 2× fastest motion (else wagon wheels appear to spin backward)
- **Science:** Undersampling leads to false conclusions

**Anti-aliasing filter:** Remove frequencies above Nyquist limit before sampling.

[hr]

[b]The Queerness of Frequency Domains[/b]

**Reality doesn't privilege any frequency band.**

**"Important" frequencies depend on the observer:**

- **Geologist:** 10⁻¹⁵ Hz matters (million-year cycles)
- **Human:** 1-1000 Hz matters (perception range)
- **Atom:** 10¹⁵ Hz matters (electron orbital frequencies)

**No objective "correct" time scale** - each perspective is valid.

**Zooming in reveals finer details (high freq).**
**Zooming out reveals larger patterns (low freq).**

**Both are real. Both are present. Frequency selection is observational choice.**

**Queerness of scale:**
- **No single "true" resolution** (fractal complexity at all scales)
- **Different perspectives reveal different truths** (geologist vs physicist)
- **What is "noise" at one scale is "signal" at another** (daily weather = noise to climatologist, signal to meteorologist)

**Understanding = ability to switch between frequency domains fluidly.**

[hr]

[b]Picking Up Small vs Large Frequencies[/b]

**Strategy for understanding complex systems:**

[color=yellow][b]1. Start with Low Frequencies (Big Picture):[/b][/color]
[code]
# Remove high-frequency noise to see overall trend
var smoothed_data = low_pass_filter(raw_data, cutoff_low)
# Reveals: Long-term trends, stable patterns, gross structure
[/code]

[color=yellow][b]2. Add Medium Frequencies (Primary Dynamics):[/b][/color]
[code]
# Keep mid-range frequencies
var mid_band = band_pass_filter(raw_data, cutoff_low, cutoff_mid)
# Reveals: Main oscillations, dominant cycles, key rhythms
[/code]

[color=yellow][b]3. Examine High Frequencies (Fine Details):[/b][/color]
[code]
# Look at rapid variations
var details = high_pass_filter(raw_data, cutoff_mid)
# Reveals: Noise, sudden events, local irregularities
[/code]

**Hierarchical understanding:**
- **Low freq:** What's the overall pattern?
- **Mid freq:** What are the main variations?
- **High freq:** What are the details and anomalies?

**This is how wavelets work** - multi-scale analysis.

[hr]

[color=cyan][b]Summary:[/b][/color]
Reality contains all frequencies simultaneously. Large waves (low freq) = global patterns, slow changes, coarse scale. Small waves (high freq) = local details, rapid changes, fine scale. Perception is frequency filtering - we only sense narrow bands. Low-pass filter shows trends. High-pass filter shows details. Band-pass isolates specific scales. Different domains focus on different frequency ranges. Octaves (2× frequency) = logarithmic scale exploration. Aliasing occurs when sampling rate too low. No privileged frequency - perspective determines what matters. Understanding = switching between frequency domains. Start low (big picture) → add mid (dynamics) → examine high (details).

[hr]

[color=orange][b]Next:[/b] Wavelet Analysis[/color]
Fourier decomposes signal into frequencies but loses time information.
Wavelets solve this: **localized waves** that capture both frequency AND time.
Multi-resolution analysis: seeing all scales simultaneously.
Used in JPEG2000, audio compression, edge detection, feature extraction.
The next evolution beyond Fourier for understanding time-varying signals.

'''
