**The Electromagnetic Spectrum**
Light is Just One Frequency Band

**All electromagnetic radiation is the same phenomenon** - oscillating electric and magnetic fields.

**The only difference: FREQUENCY.**

Radio, microwave, infrared, visible light, ultraviolet, X-rays, gamma rays - **all are light waves at different frequencies.**

**We call them different names, but physics sees one continuous spectrum.**

---

## The Wave Equation is Universal

**Electromagnetic Wave:**

```
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
```

**Same sine wave. Different frequency. Different reality.**

---

## The Spectrum: Frequency Determines Phenomenon

**Electromagnetic spectrum from low to high frequency:**

**Radio Waves:**
- **Frequency:** 3 kHz - 300 GHz
- **Wavelength:** 100 km - 1 mm
- **Uses:** Broadcasting, communication, radar
- **Properties:** Pass through walls, long-range transmission

**Microwaves:**
- **Frequency:** 300 MHz - 300 GHz
- **Wavelength:** 1 m - 1 mm
- **Uses:** Cooking, WiFi, satellite communication
- **Properties:** Absorbed by water molecules → heating

**Infrared:**
- **Frequency:** 300 GHz - 430 THz
- **Wavelength:** 1 mm - 700 nm
- **Uses:** Heat sensing, remote controls, thermal imaging
- **Properties:** Felt as heat, emitted by warm objects

**Visible Light:**
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

**Ultraviolet:**
- **Frequency:** 770 THz - 30 PHz
- **Wavelength:** 390 nm - 10 nm
- **Uses:** Sterilization, tanning, fluorescence
- **Properties:** Causes sunburn, damages DNA, ionizing

**X-Rays:**
- **Frequency:** 30 PHz - 30 EHz
- **Wavelength:** 10 nm - 0.01 nm
- **Uses:** Medical imaging, security scanning
- **Properties:** Penetrate soft tissue, blocked by bone/metal

**Gamma Rays:**
- **Frequency:** > 30 EHz
- **Wavelength:** < 0.01 nm
- **Uses:** Cancer treatment, nuclear imaging
- **Properties:** Highest energy, most penetrating, dangerous

---

## Code: Visualizing the Spectrum

**Frequency to Color:**

```
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
```

**Tiny visible slice in vast spectrum.**

---

## Energy Increases with Frequency

**Planck