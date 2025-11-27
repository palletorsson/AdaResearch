extends Node

var text = '''[center][font_size=28][b]The Electromagnetic Spectrum[/b][/font_size][/center]
[center][i]Light is Just One Frequency Band[/i][/center]

**All electromagnetic radiation is the same phenomenon** - oscillating electric and magnetic fields.

**The only difference: FREQUENCY.**

Radio, microwave, infrared, visible light, ultraviolet, X-rays, gamma rays - **all are light waves at different frequencies.**

**We call them different names, but physics sees one continuous spectrum.**

[hr]

[b]The Wave Equation is Universal[/b]

[color=yellow][b]Electromagnetic Wave:[/b][/color]
[code]
# ALL EM waves follow this form
func em_wave(position: float, time: float, frequency: float) -> float:
    var wavelength = 299792458.0 / frequency  # c/f (speed of light in m/s)
    var k = TAU / wavelength                  # Wave number
    var omega = TAU * frequency               # Angular frequency

    # Electric field oscillation
    var E = sin(k * position - omega * time)

    return E

# THIS SAME EQUATION DESCRIBES:
# - Radio waves (frequency = 100 MHz)
# - Microwaves (frequency = 2.4 GHz)
# - Visible light (frequency = 540 THz for green)
# - X-rays (frequency = 30 EHz)
[/code]

**Same sine wave. Different frequency. Different reality.**

[hr]

[b]The Spectrum: Frequency Determines Phenomenon[/b]

**Electromagnetic spectrum from low to high frequency:**

[color=yellow][b]Radio Waves:[/b][/color]
- **Frequency:** 3 kHz - 300 GHz
- **Wavelength:** 100 km - 1 mm
- **Uses:** Broadcasting, communication, radar
- **Properties:** Pass through walls, long-range transmission

[color=yellow][b]Microwaves:[/b][/color]
- **Frequency:** 300 MHz - 300 GHz
- **Wavelength:** 1 m - 1 mm
- **Uses:** Cooking, WiFi, satellite communication
- **Properties:** Absorbed by water molecules → heating

[color=yellow][b]Infrared:[/b][/color]
- **Frequency:** 300 GHz - 430 THz
- **Wavelength:** 1 mm - 700 nm
- **Uses:** Heat sensing, remote controls, thermal imaging
- **Properties:** Felt as heat, emitted by warm objects

[color=yellow][b]Visible Light:[/b][/color]
- **Frequency:** 430 THz - 770 THz
- **Wavelength:** 700 nm - 390 nm
- **Uses:** Vision, photography, illumination
- **Properties:** **The ONLY band humans can see**
- **Colors:**
  - Red: ~430 THz (lowest visible)
  - Orange: ~480 THz
  - Yellow: ~510 THz
  - Green: ~540 THz
  - Blue: ~630 THz
  - Violet: ~770 THz (highest visible)

[color=yellow][b]Ultraviolet:[/b][/color]
- **Frequency:** 770 THz - 30 PHz
- **Wavelength:** 390 nm - 10 nm
- **Uses:** Sterilization, tanning, fluorescence
- **Properties:** Causes sunburn, damages DNA, ionizing

[color=yellow][b]X-Rays:[/b][/color]
- **Frequency:** 30 PHz - 30 EHz
- **Wavelength:** 10 nm - 0.01 nm
- **Uses:** Medical imaging, security scanning
- **Properties:** Penetrate soft tissue, blocked by bone/metal

[color=yellow][b]Gamma Rays:[/b][/color]
- **Frequency:** > 30 EHz
- **Wavelength:** < 0.01 nm
- **Uses:** Cancer treatment, nuclear imaging
- **Properties:** Highest energy, most penetrating, dangerous

[hr]

[b]Code: Visualizing the Spectrum[/b]

[color=yellow][b]Frequency to Color:[/b][/color]
[code]
func frequency_to_color(frequency_hz: float) -> Color:
    # Visible spectrum: 430 THz to 770 THz

    var THz = 1e12  # Terahertz

    if frequency_hz < 430 * THz:
        return Color.BLACK  # Infrared (invisible)
    elif frequency_hz < 480 * THz:
        return Color.RED  # 430-480 THz
    elif frequency_hz < 510 * THz:
        return Color.ORANGE  # 480-510 THz
    elif frequency_hz < 530 * THz:
        return Color.YELLOW  # 510-530 THz
    elif frequency_hz < 580 * THz:
        return Color.GREEN  # 530-580 THz
    elif frequency_hz < 630 * THz:
        return Color.CYAN  # 580-630 THz
    elif frequency_hz < 680 * THz:
        return Color.BLUE  # 630-680 THz
    elif frequency_hz < 770 * THz:
        return Color.from_hsv(0.75, 1.0, 1.0)  # Violet 680-770 THz
    else:
        return Color.BLACK  # Ultraviolet (invisible)

# Only 430-770 THz becomes color
# Everything else is invisible to human eyes
[/code]

**Tiny visible slice in vast spectrum.**

[hr]

[b]Energy Increases with Frequency[/b]

**Planck's equation:** E = h × f

Where:
- E = photon energy
- h = Planck's constant (6.626 × 10⁻³⁴ J·s)
- f = frequency

[color=yellow][b]Code: Photon Energy[/b][/color]
[code]
func photon_energy(frequency_hz: float) -> float:
    var h = 6.626e-34  # Planck's constant (Joule-seconds)
    var energy_joules = h * frequency_hz
    return energy_joules

# Radio photon (100 MHz):
var radio_energy = photon_energy(100e6)  # 6.626 × 10⁻²⁶ J

# Visible photon (540 THz green):
var visible_energy = photon_energy(540e12)  # 3.58 × 10⁻¹⁹ J

# X-ray photon (30 PHz):
var xray_energy = photon_energy(30e15)  # 1.99 × 10⁻¹⁷ J

# Gamma ray photon (30 EHz):
var gamma_energy = photon_energy(30e18)  # 1.99 × 10⁻¹⁴ J

# Gamma photon has 1 million times more energy than visible photon
[/code]

**Higher frequency = shorter wavelength = more energy.**

**This is why:**
- Radio waves are harmless (low energy)
- Visible light is safe (medium energy)
- UV causes sunburn (enough energy to damage molecules)
- X-rays penetrate tissue (high energy)
- Gamma rays are deadly (extremely high energy)

[hr]

[b]Wavelength and Frequency Relationship[/b]

**All EM waves travel at speed of light: c = 299,792,458 m/s**

**Wavelength × frequency = c**

[color=yellow][b]Code: Wavelength Calculation[/b][/color]
[code]
var SPEED_OF_LIGHT = 299792458.0  # meters per second

func wavelength_from_frequency(freq_hz: float) -> float:
    return SPEED_OF_LIGHT / freq_hz

func frequency_from_wavelength(wavelength_m: float) -> float:
    return SPEED_OF_LIGHT / wavelength_m

# Examples:
var radio_wave = wavelength_from_frequency(100e6)      # 3 meters
var microwave = wavelength_from_frequency(2.4e9)       # 12.5 cm (WiFi)
var green_light = wavelength_from_frequency(540e12)    # 555 nm
var xray = wavelength_from_frequency(30e15)            # 0.01 nm

# Low frequency → long wavelength
# High frequency → short wavelength
[/code]

**Inverse relationship: f ↑ means λ ↓**

[hr]

[b]Why We Only See Visible Light[/b]

**Evolution tuned our eyes to the Sun's peak emission.**

Sun's spectrum peaks at ~500 THz (green) - **our eyes evolved to detect this range.**

**Also:**
- **Atmosphere is transparent** to visible light (400-700 nm)
- **Water is transparent** to visible light
- **Balanced energy** - not too weak (radio) or too strong (UV)

**Other animals see different ranges:**
- **Bees see ultraviolet** (detect nectar guides on flowers)
- **Snakes see infrared** (heat sensing for hunting)
- **Mantis shrimp see 12+ color channels** (vs our 3)

**"Visible light" is human-centric** - physics doesn't privilege this band.

[hr]

[b]Atmospheric Windows[/b]

**Earth's atmosphere blocks most EM spectrum** - only certain "windows" pass through.

[color=yellow][b]Transparent Windows:[/b][/color]
- **Visible light (400-700 nm):** Atmosphere transparent → we evolved eyes for this
- **Radio waves (cm to m wavelengths):** Passes through → radio astronomy, WiFi
- **Some infrared (near-IR):** Partial transmission → night vision

[color=yellow][b]Blocked Regions:[/b][/color]
- **UV (most):** Blocked by ozone layer → protects DNA
- **X-rays:** Blocked by atmosphere → need space telescopes
- **Gamma rays:** Blocked by atmosphere → space-based detection only
- **Far infrared:** Absorbed by water vapor, CO₂

**This is why space telescopes exist** - see wavelengths Earth's atmosphere blocks.

[hr]

[b]EM Spectrum in Technology[/b]

**Different frequencies = different applications:**

[color=yellow][b]Code: Frequency Bands in Use[/b][/color]
[code]
# Communication frequency allocations
var AM_radio = 1e6        # ~1 MHz (long range, low quality)
var FM_radio = 100e6      # ~100 MHz (shorter range, better quality)
var WiFi_2_4GHz = 2.4e9   # 2.4 GHz (WiFi, Bluetooth)
var WiFi_5GHz = 5e9       # 5 GHz (faster WiFi, shorter range)
var cellular_4G = 2e9     # ~2 GHz (LTE)
var cellular_5G = 28e9    # 28-39 GHz (mmWave 5G, very high speed, very short range)

# Higher frequency = more bandwidth = faster data
# But also = shorter range, more obstacles blocked
[/code]

**Why 5G uses higher frequencies:**
- More bandwidth available → faster speeds
- Shorter wavelengths → more data density
- BUT: Blocked by walls, rain, leaves → need more towers

**Microwave ovens use 2.45 GHz** - same as WiFi! (why running microwave can disrupt WiFi)

[hr]

[b]Blackbody Radiation: Temperature Determines Color[/b]

**Hot objects emit EM radiation** - hotter = higher frequency.

**Wien's displacement law:** λ_peak = 2.898 × 10⁻³ / T

Where T is temperature in Kelvin.

[color=yellow][b]Code: Temperature to Color[/b][/color]
[code]
func blackbody_color(temperature_kelvin: float) -> Color:
    # Wien's law: peak wavelength (meters)
    var lambda_peak = 2.898e-3 / temperature_kelvin

    # Convert to frequency
    var freq_peak = 299792458.0 / lambda_peak

    # Map to visible color (simplified)
    if temperature_kelvin < 1000:
        return Color.BLACK  # Too cool (infrared)
    elif temperature_kelvin < 2000:
        return Color.RED  # Dim red (candle flame)
    elif temperature_kelvin < 3000:
        return Color.ORANGE  # Orange (incandescent bulb)
    elif temperature_kelvin < 5000:
        return Color.from_hsv(0.15, 0.4, 1.0)  # Yellowish white (sunlight)
    elif temperature_kelvin < 10000:
        return Color.from_hsv(0.55, 0.3, 1.0)  # Blue-white (arc welder)
    else:
        return Color.CYAN  # Blue (hot stars)

# Sun surface: 5778 K → yellowish white
# Candle flame: 1800 K → orange-red
# Blue stars: 30,000 K → blue-white
[/code]

**Hotter objects glow blue. Cooler objects glow red.**

**This is why:**
- Lava is red-orange (800-1200 K)
- Incandescent bulbs are yellow (2700 K)
- Sun is white (5778 K)
- Blue stars are hottest (>10,000 K)
- Red stars are coolest (3000 K)

[hr]

[b]Doppler Shift: Motion Changes Frequency[/b]

**Moving source → frequency shifts.**

- Moving toward you: **higher frequency** (blue shift)
- Moving away: **lower frequency** (red shift)

[color=yellow][b]Code: Doppler Effect[/b][/color]
[code]
func doppler_shifted_frequency(source_freq: float, velocity: float) -> float:
    # velocity: positive = moving toward observer, negative = away
    # velocity in m/s
    var c = 299792458.0  # Speed of light

    # Relativistic Doppler formula (for EM waves)
    var beta = velocity / c
    var shifted_freq = source_freq * sqrt((1 + beta) / (1 - beta))

    return shifted_freq

# Galaxy moving away at 0.1c (very fast):
var emitted_freq = 540e12  # Green light
var observed_freq = doppler_shifted_frequency(emitted_freq, -0.1 * 299792458)
# Result: ~490 THz (shifted toward red)

# This is cosmological redshift - proves universe expanding
[/code]

**Astronomical applications:**
- **Redshift of distant galaxies** → universe is expanding
- **Binary star wobble** → detect exoplanets
- **Galaxy rotation curves** → dark matter evidence

[hr]

[b]The Queerness of the Spectrum[/b]

**"Visible light" is cultural category, not physical reality.**

Physics sees **continuous spectrum** - humans divide into named bands.

**Where does "red" end and "infrared" begin?** Arbitrary human cutoff at ~700 nm.

**Why is "violet" separate from "ultraviolet"?** Only because our eyes stop responding at ~400 nm.

**Different observers see different spectra:**
- Bees: UV is "visible," red is "dark"
- Snakes: IR is "visible" (pit organs)
- Radio telescopes: See completely different "sky"

**The spectrum reveals:**
- **Categories are observer-dependent** (visible vs invisible)
- **Boundaries are constructed** (where does one band end?)
- **Same phenomenon, multiple perspectives** (all EM, different names)
- **What is "real" depends on sensing apparatus** (eyes, antennas, instruments)

**Queerness: reality exceeds human perceptual categories.**

**Most of reality is invisible** - we see 430-770 THz, but spectrum extends infinitely in both directions.

[hr]

[b]Spectroscopy: Reading Light's Fingerprints[/b]

**Each element absorbs/emits specific frequencies.**

[color=yellow][b]Code: Emission Lines[/b][/color]
[code]
# Hydrogen emission lines (Balmer series, visible spectrum)
var hydrogen_lines = [
    656.3e-9,  # H-alpha (red)
    486.1e-9,  # H-beta (cyan)
    434.0e-9,  # H-gamma (blue)
    410.2e-9   # H-delta (violet)
]

# Convert to frequencies
for wavelength in hydrogen_lines:
    var freq = 299792458.0 / wavelength
    print("Hydrogen line: ", freq / 1e12, " THz")

# Astronomers identify elements by their spectral lines
# Each element has unique "barcode" of frequencies
[/code]

**How we know what distant stars are made of** - analyze their light spectrum.

**Applications:**
- **Astronomy:** Composition of stars/galaxies
- **Chemistry:** Identify unknown substances
- **Forensics:** Trace element analysis
- **Medicine:** Blood oxygen sensors (pulse oximeters)

[hr]

[color=cyan][b]Summary:[/b][/color]
All EM radiation is same wave phenomenon at different frequencies. Radio, microwave, IR, visible, UV, X-ray, gamma = continuous spectrum. Energy = h×f (higher frequency = more energy). Wavelength × frequency = speed of light. Visible (430-770 THz) is tiny fraction of spectrum. Atmospheric windows determine what penetrates. Temperature determines blackbody color (Wien's law). Doppler shift changes frequency with motion. "Visible" is human-centric category - spectrum is continuous. Different organisms sense different bands. Spectroscopy identifies elements by emission/absorption lines. Most reality is invisible to human eyes.

[hr]

[color=orange][b]Next:[/b] Frequency Domains and Scale[/color]
Small waves, big waves - picking up different frequencies reveals different domains of reality.
**Low frequencies:** Long-range patterns, slow variations, global structure.
**High frequencies:** Local details, rapid changes, fine texture.
Same world, different scales - Fourier decomposes reality into frequency layers.
Understanding the world = picking up the right frequencies.

'''
