**Frequency Domains**
Small and Large Waves - Sensing Different Scales

**Reality exists at all frequencies simultaneously.**

**What you perceive depends on which frequencies you can sense.**

**Low frequencies = large-scale patterns.**
**High frequencies = fine details.**

**Understanding the world = tuning into the right frequency band.**

---

## The Scale of Waves

**Wavelength determines what you can detect:**

**Physical Scale Examples:**

```
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
```

**Large waves respond to large-scale phenomena.**
**Small waves respond to fine-scale phenomena.**

---

## Fourier Decomposition: Seeing All Scales

**Any signal contains multiple frequency components** - Fourier reveals them.

**Code: Multi-Scale Decomposition**

```
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
```

**Filtering = selecting frequency ranges:**

**Low-Pass Filter (Keep Low Frequencies):**

```
# Remove high frequencies → smooths signal, shows large-scale pattern
func low_pass_filter(signal: Array, cutoff_freq: float) -> Array:
    var filtered = []

    # Fourier transform
    var spectrum = fft(signal)

    # Zero out high frequencies
    for i in range(spectrum.size()):
        if i > cutoff_freq:
            spectrum = 0.0

    # Inverse transform back to time domain
    filtered = ifft(spectrum)

    return filtered

# Result: Only slow variations remain
# Use case: Remove noise, see overall trend
```

**High-Pass Filter (Keep High Frequencies):**

```
# Remove low frequencies → shows rapid changes, fine details
func high_pass_filter(signal: Array, cutoff_freq: float) -> Array:
    var filtered = []
    var spectrum = fft(signal)

    # Zero out low frequencies
    for i in range(spectrum.size()):
        if i < cutoff_freq:
            spectrum = 0.0

    filtered = ifft(spectrum)
    return filtered

# Result: Only rapid variations remain
# Use case: Edge detection, finding sudden changes
```

**Band-Pass Filter (Keep Middle Frequencies):**

```
# Keep only specific frequency range
func band_pass_filter(signal: Array, low_cutoff: float, high_cutoff: float) -> Array:
    var spectrum = fft(signal)

    # Zero out everything outside the band
    for i in range(spectrum.size()):
        if i < low_cutoff or i > high_cutoff:
            spectrum = 0.0

    return ifft(spectrum)

# Result: Isolate specific scale of variation
# Use case: Extract specific pattern from complex signal
```

**Different filters reveal different aspects of reality.**

---

## Perception is Frequency Selection

**Human senses are band-pass filters** - we only perceive specific frequency ranges.

**Hearing:**
- **Range:** 20 Hz - 20,000 Hz
- **Below 20 Hz (infrasound):** Elephants communicate, earthquake precursors
- **Above 20 kHz (ultrasound):** Bats echolocate, dolphins communicate
- **We