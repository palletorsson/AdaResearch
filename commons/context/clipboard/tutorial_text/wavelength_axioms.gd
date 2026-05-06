extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Wavelength[/b][/font_size][/center]
[center][i]The Measurement That Cannot Explain Experience[/i][/center]

In 1672, Isaac Newton passed white sunlight through a prism and saw it split into a spectrum of colors. Red, orange, yellow, green, blue, indigo, violet.

This was a triumph: **color reduced to wavelength**. A measurable, objective, physical property. No longer a mysterious subjective quality - just electromagnetic radiation at different frequencies.

Physics promised to unify color. To explain it completely.

**The promise failed.**

[hr]

[b]The Visible Spectrum: 380-750 Nanometers[/b]

Visible light is electromagnetic radiation with wavelengths between approximately 380nm and 750nm (nanometers - billionths of a meter).

[color=yellow][b]The Spectrum:[/b][/color]
[code]
# Wavelength (nm)  →  Perceived Color
# 380-450         →  Violet
# 450-495         →  Blue
# 495-570         →  Green
# 570-590         →  Yellow
# 590-620         →  Orange
# 620-750         →  Red

# Objective measurement
# Repeatable, universal
# Should explain everything about color
[/code]

Wavelength is a **primary quality** (in Locke's terminology):
- Exists independently of observation
- Measurable with instruments
- Objective, not subjective

Unlike RGB (computational convenience) or qualia (subjective experience), wavelength seems like **true color** - the physical reality behind appearances.

[hr]

[b]The Continuous Spectrum vs Discrete Categories[/b]

Newton identified **seven colors** in the spectrum (adding indigo to match the seven notes in a musical scale, the seven days of the week - mystical numerology, not physics).

But the spectrum is **continuous**. There are no boundaries between "yellow" and "orange" - just gradual wavelength change.

[color=yellow][b]Code: Arbitrary Segmentation[/b][/color]
[code]
var wavelength = 585.0  # nanometers

# Is this yellow or orange?
# The wavelength is objective (585nm)
# The category is arbitrary

# 585nm is continuous with 584nm and 586nm
# We impose discrete labels ("yellow", "orange")
# On continuous physical reality

# Where exactly does yellow end and orange begin?
# Physics has no answer
# The boundary is perceptual, cultural, linguistic
[/code]

**Wavelength is continuous. Color names are discrete.** The categories we use to divide the spectrum are human constructions imposed on physical continuum.

[hr]

[b]Metamerism: One Perception, Many Physics[/b]

Here is where wavelength's unification fails:

**Metamers** are physically different light sources (different spectral distributions) that produce **identical color perception**.

[color=yellow][b]Example: Two Yellows[/b][/color]
[code]
# Yellow 1: Pure spectral yellow
var spectral_yellow_wavelength = 580  # nm (single wavelength)

# Yellow 2: Mixed yellow
var mixed_yellow = {
    "red": 700,    # nm wavelength
    "green": 540   # nm wavelength
}
# Two wavelengths combined

# Both look IDENTICAL to human eye
# Same perceived yellow
# Different physical reality

# Wavelength does not determine color
# Multiple physical states → same perceptual state
[/code]

If color were truly "just wavelength," metamers would be impossible. But they exist.

**This means:** Wavelength is not sufficient to specify color. The same perception can arise from different physics.

[hr]

[b]The Explanatory Gap: Why 650nm Feels Red[/b]

You can measure everything about 650nm light:
- Wavelength: 650 nanometers
- Frequency: 461 terahertz
- Energy: 1.91 electron volts
- Speed: 299,792,458 m/s
- How it reflects off surfaces
- How it stimulates L-cones in retina (long-wavelength receptors)

**But none of this explains redness.**

The subjective experience - the **quale** of red - is not captured by the measurements.

[color=yellow][b]Code: The Unbridgeable Gap[/b][/color]
[code]
var wavelength = 650  # Objective measurement

# Physics tells us:
var frequency = 299792458 / (wavelength * 1e-9)  # Hz
var energy = 1240 / wavelength  # eV (approximate)

# Neuroscience tells us:
# L-cones activate (long wavelength receptors)
# Signal travels via optic nerve to V1 cortex
# Neural pattern encodes wavelength information

# But what is the experience of redness?
# Why does this particular neural pattern feel red?
# Why is there something it is like to see red?

# Measurement → ??? → Experience
# The gap cannot be bridged by more measurement
[/code]

This is the **hard problem of consciousness** (Chalmers): even with complete physical description, we cannot explain subjective experience.

**Wavelength does not unify color.** It describes one aspect (physical stimulus) but fails to explain another (phenomenological experience).

[hr]

[b]Color Constancy: Same Physics, Different Perception[/b]

A white piece of paper **looks white** whether you view it:
- Under sunlight (bluish spectrum, ~5500K)
- Under tungsten bulb (yellowish spectrum, ~3000K)
- Under fluorescent light (spiky spectrum with gaps)

But the **wavelengths reflected** are completely different in each case.

[color=yellow][b]Code: Wavelength Changes, Perception Stays Constant[/b][/color]
[code]
# White paper under sunlight
var sunlight_spectrum = [high blue, high green, medium red]
var reflected_wavelengths_sun = sunlight_spectrum  # Paper reflects all

# Same paper under tungsten
var tungsten_spectrum = [low blue, medium green, high red]
var reflected_wavelengths_tungsten = tungsten_spectrum

# Physical wavelengths are DIFFERENT
# But both look "white"

# Your brain compensates for illumination
# Constructs stable "white" perception
# Despite changing physical stimulus

# Perception is not passive reception of wavelengths
# It is active construction by visual cortex
[/code]

**Same wavelengths can look like different colors** (depending on context).
**Different wavelengths can look like the same color** (brain compensates).

Wavelength does not determine perception. The relationship is **mediated** by neural processing.

[hr]

[b]Newton vs Goethe: The Unresolved Debate[/b]

**Newton (1672):** Color is wavelength. Objective, measurable, reducible to physics.

**Goethe (1810):** Color is phenomenological - it arises in the **relationship** between light, darkness, and the perceiving eye. You cannot reduce yellow to "580nm" because yellow is an **experience**, not a measurement.

*Theory of Colours* argued:
- Color exists at **boundaries** (light/dark transitions)
- Perception is active, not passive
- Subjective experience is irreducible to physics

[color=orange][b]The Debate Remains Unresolved[/b][/color]

Modern physics vindicated Newton's measurements - wavelength is real, objective, predictive.

But modern neuroscience/philosophy vindicated Goethe's phenomenology - experience is not reducible to measurement, perception actively constructs color.

**Both are correct. They describe different aspects that do not unify.**

[hr]

[b]The Quantum Complication: Wavelength Is Observer-Dependent[/b]

It gets worse: wavelength itself is not simply "out there" independent of observation.

**Wave-particle duality:**
- Photon as wave: continuous, has wavelength
- Photon as particle: discrete, localized

**Before measurement:** Photon exists in superposition (multiple wavelengths simultaneously)
**After measurement:** Wavefunction collapses to definite wavelength

[color=yellow][b]The Measurement Problem:[/b][/color]
[code]
# Quantum state before observation
var photon = superposition_of_wavelengths([620, 630, 640, ...])

# Measurement collapses to eigenstate
var measured_wavelength = observe(photon)  # Now: 630nm

# But measurement is interaction with observer
# Wavelength emerges through observation
# Not pre-existing independent property

# Color perception IS a measurement
# The act of seeing collapses the wavefunction
[/code]

Wavelength is not purely objective - it's a property that **emerges through measurement/observation**.

Color is observer-involved at the quantum level, not just the perceptual level.

[hr]

[b]What Wavelength Cannot Explain[/b]

Physics can measure wavelength precisely. But wavelength cannot account for:

1. **Metamerism** - Different wavelengths, same color
2. **Color constancy** - Same wavelength, different color (depending on context)
3. **Qualia** - Why 650nm **feels** red (explanatory gap)
4. **Categories** - Where does yellow end and orange begin?
5. **Cultural variation** - Russian has two "blues", Japanese "ao" covers blue and green
6. **Perceptual construction** - Brain invents stable color from changing input

Wavelength is **necessary but not sufficient** for color.

[hr]

[b]The Promise of Reduction Failed[/b]

Newton's prism seemed to promise: **color is just wavelength**. A complete physical reduction. Secondary quality collapsed into primary quality.

But 350 years later, we know:
- Wavelength describes stimulus, not experience
- Same stimulus → different experiences (constancy, context)
- Different stimuli → same experience (metamerism)
- Experience involves neural construction, cultural categories, subjective qualia

**Wavelength is one description among several** (alongside RGB, HSV, qualia, cultural categories). None of them unify. None reduce to the others.

[hr]

[b]The Spectrum as Arbitrary Discretization[/b]

When you see a rainbow, you see **discrete bands** of color. Red, orange, yellow, green, blue, violet.

But the spectrum is **continuous**. Your brain imposes categorical boundaries on smooth wavelength gradient.

[color=yellow][b]Code: The Rainbow Lie[/b][/color]
[code]
# Physical reality: continuous wavelength change
# 400nm → 401nm → 402nm → ... → 700nm

# Perceptual experience: discrete color bands
# Violet | Blue | Green | Yellow | Orange | Red

# The boundaries are constructed
# The categories are learned
# The "seven colors" are cultural (Newton added indigo for numerology)

# Reality is continuous
# Perception discretizes it
# Language names the categories
[/code]

The rainbow you see is not "out there" in the physics. It's constructed by your visual system applying learned categories to continuous gradients.

[hr]

[b]What Wavelength Reveals[/b]

Wavelength shows us:

1. **Measurement is not explanation** - We can measure precisely without understanding experience
2. **Physics is incomplete** - Cannot bridge to phenomenology
3. **Reduction fails** - Secondary qualities do not collapse into primary
4. **Reality is relational** - Color emerges in observer-stimulus interaction, not in either alone
5. **The spectrum is continuous** - Discrete categories are imposed, not discovered
6. **Multiple descriptions coexist** - Wavelength, RGB, qualia - none unify

**Wavelength promised to cut through to unified truth. It revealed instead that color exists in the irreducible gap between physics and experience.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Wavelength (380-750nm) is the physical measurement of visible light - objective, repeatable, seemingly complete. But wavelength cannot explain color: metamerism shows different physics producing same perception; color constancy shows same physics producing different perception; the explanatory gap shows measurement cannot capture qualia. Wavelength is necessary but not sufficient. The reduction of color to physics fails. Multiple descriptions coexist without unifying.

[hr]

[color=orange][b]Next:[/b] Perception[/color]
If wavelength is physics and RGB is computation, perception is the irreducible third.
Not three cone types (universal), but tetrachromacy, dichromacy, plurality.
Not universal categories, but Russian blues, Japanese ao, constructed color.
Perception reveals: there is no "normal" vision.

'''
