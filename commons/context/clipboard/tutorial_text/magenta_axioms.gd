extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Magenta[/b][/font_size][/center]
[center][i]The Impossible Color That Exists[/i][/center]

Magenta does not exist in the spectrum.

There is no wavelength for magenta. No frequency you can measure that produces it. It is **physically impossible** according to Newton's rainbow.

But you see it. Right now, you can see magenta. It is as real as red or blue.

**Magenta is proof that perception constructs reality beyond physical substrate.**

[hr]

[b]The Visible Spectrum: A Line, Not A Loop[/b]

The visible spectrum runs from red (long wavelength, ~700nm) to violet (short wavelength, ~380nm).

**It is a line:**
Red → Orange → Yellow → Green → Cyan → Blue → Violet

Not a circle. Not a loop.

[color=yellow][b]Code: The Linear Spectrum[/b][/color]
[code]
# Wavelength (nm)  →  Perceived Color
# 700             →  Red
# 650             →  Orange
# 580             →  Yellow
# 550             →  Green
# 490             →  Cyan
# 450             →  Blue
# 400             →  Violet

# The spectrum is LINEAR
# There is no wavelength "between" red and violet
# They are at opposite ends
[/code]

**Magenta would need to be "between" red and violet.** But they are endpoints, not neighbors. There is no wavelength that completes the loop.

Physics says: **Magenta cannot exist.**

[hr]

[b]How Your Brain Invents Magenta[/b]

You see magenta when:
- **L cones** (long wavelength - red) activate strongly
- **S cones** (short wavelength - blue/violet) activate strongly
- **M cones** (medium wavelength - green) do NOT activate

[color=yellow][b]Code: The Impossible Stimulus[/b][/color]
[code]
# Magenta stimulus
var l_cone_response = HIGH    # Red end of spectrum (~700nm)
var s_cone_response = HIGH    # Violet end of spectrum (~400nm)
var m_cone_response = LOW     # Middle of spectrum not activated

# This pattern does not correspond to any single wavelength
# No spectral color activates L and S without M

# But the pattern CAN occur from mixed light:
# Red light (700nm) + Violet light (400nm)
# Two wavelengths at opposite spectrum ends
[/code]

Your brain receives this stimulus pattern (L+S, no M) and says:

**"This is not red. Not violet. Not any spectral color. This is... magenta."**

Magenta is a **neural construction** - an invented color to represent a stimulus pattern that doesn't exist in the rainbow.

[hr]

[b]The Color Wheel: Closing The Spectrum[/b]

Artists and designers use a **color wheel** - a circle where:
- Red → Orange → Yellow → Green → Cyan → Blue → Violet → **Magenta** → Red

The wheel **closes the linear spectrum** by inserting magenta between red and violet.

[color=yellow][b]Code: The Perceptual Circle[/b][/color]
[code]
# Physical spectrum (linear)
var spectrum = ["Red", "Orange", "Yellow", "Green", "Cyan", "Blue", "Violet"]

# Perceptual color wheel (circular)
var color_wheel = ["Red", "Orange", "Yellow", "Green",
                   "Cyan", "Blue", "Violet", "Magenta"]

# Magenta completes the loop
# But has no place in the spectrum
# It is a perceptual addition to physics
[/code]

**The color wheel is not a map of wavelengths.** It's a map of **perceptual relationships** - how colors feel related, how they mix, how they oppose.

Magenta belongs to perception, not physics.

[hr]

[b]Complementary Colors: The Opponent Process[/b]

Magenta is the **complementary color** to green.

Opponent process theory (Hering, 1892): The visual system encodes color using **opponent channels**:
- Red ↔ Green
- Blue ↔ Yellow
- Light ↔ Dark

When M cones (green) are inhibited while L cones (red) and S cones (blue) activate, the brain interprets:
- "Not green" + "Red" + "Blue" = **Magenta**

[color=yellow][b]Code: The Opponent Signal[/b][/color]
[code]
# Opponent process encoding
var red_green_channel = l_cone_response - m_cone_response
var blue_yellow_channel = s_cone_response - (l_cone_response + m_cone_response)

# When viewing magenta:
# red_green_channel = HIGH (L active, M inactive) → RED side
# blue_yellow_channel = HIGH (S active, L+M low) → BLUE side

# Perception: "Red" + "Blue" + "Not-green" = Magenta

# Magenta is the absence of green combined with presence of red and blue
# It is defined oppositionally, not spectrally
[/code]

**Magenta exists as the negation of its complement.** It is anti-green. The color that occupies the perceptual space opposite to green.

[hr]

[b]Magenta in RGB: The Digital Construction[/b]

On your screen, magenta is trivial to create:

[color=yellow][b]Code: Full Red + Full Blue[/b][/color]
[code]
var magenta = Color(1.0, 0.0, 1.0)

# Screen emits:
# - 100% red LED light (~630nm)
# - 0% green LED light
# - 100% blue LED light (~450nm)

# Two wavelengths (red + blue)
# Zero green
# Your cones receive the pattern: L+S, no M
# Your brain constructs: MAGENTA

# The screen easily creates the "impossible" color
# Because it doesn't emit spectrum - it emits primaries
[/code]

RGB displays can show magenta **because they don't try to emit spectral colors**. They just trigger cone responses.

The screen exploits the fact that perception is constructive, not passive. It doesn't matter that magenta has no wavelength - what matters is the **cone activation pattern**.

[hr]

[b]Magenta in CMYK: Subtractive Primary[/b]

In **CMYK printing** (subtractive color - ink on paper), magenta is one of the **primary colors**:
- **C**yan
- **M**agenta
- **Y**ellow
- **K**ey (black)

**Why is magenta a primary in subtractive color?**

Because it **absorbs green** (reflects red and blue). When you want to remove green wavelengths from white light, you use magenta ink.

[color=yellow][b]Code: Subtractive Magenta[/b][/color]
[code]
# White light contains all wavelengths
var white_light = [Red, Green, Blue]  # Simplified

# Magenta ink absorbs green
var magenta_ink_absorbs = "Green"

# Reflected light: Red + Blue
# Perceived color: Magenta

# Magenta is a primary because it is anti-green
# It is the complement defined by what it removes
[/code]

**In print, magenta is foundational** - not a mixed color, but a primary. Because subtractive color is about **removing wavelengths**, and magenta removes the middle of the spectrum (green).

[hr]

[b]What Magenta Reveals: Experience Beyond Substrate[/b]

Magenta is **perceptually real but physically impossible**.

It demonstrates:

1. **Perception is constructive, not receptive**
   - Brain invents colors that don't exist in stimulus
   - Experience exceeds physical input

2. **Neural processing creates reality**
   - Magenta emerges from opponent channels
   - The color exists in neural computation, not in world

3. **Qualia can exist without physical correlate**
   - No wavelength → yet vivid color experience
   - Subjective reality independent of objective measure

4. **The algorithm can render the impossible**
   - RGB easily creates magenta (just mix primaries)
   - Digital color is about triggering perception, not replicating physics

[hr]

[b]Other "Impossible" Colors[/b]

Magenta is not alone. Other perceptually-constructed colors include:

**Brown:**
- No spectral brown - it's "dark orange"
- Exists only through context (orange on dark background looks brown)
- Relational color, not spectral

**Pink:**
- No spectral pink - it's "desaturated red"
- Requires white mixed with red
- Lightness + hue combination, not wavelength

**Olive, Tan, Beige:**
- All context-dependent constructions
- No pure wavelengths correspond to these experiences

[color=yellow][b]Code: Constructed Colors[/b][/color]
[code]
var magenta = Color(1.0, 0.0, 1.0)  # No wavelength
var brown = Color(0.4, 0.2, 0.0)    # Dark orange = brown (contextual)
var pink = Color(1.0, 0.7, 0.7)     # Desaturated red = pink

# All perceptually real
# None have spectral wavelengths
# All are neural constructions
[/code]

**Many colors you see daily do not exist in the rainbow.** They are **invented by your brain** to represent relationships, contexts, mixtures.

[hr]

[b]The Queer Implication[/b]

If magenta can be **experientially real without physical substrate**, what else can?

- **Gender** as performative construction (real but not biologically essential)?
- **Identity** as neural/social creation (valid without material basis)?
- **Meaning** as emergent from relations (not intrinsic to objects)?

**Magenta proves:** Something can be **genuinely real in experience** while **physically impossible** according to reductive frameworks.

The algorithm stores `Color(1.0, 0.0, 1.0)`. Physics says "no wavelength." You see vivid magenta.

**Which one is true?**

All of them. And none of them. Reality is **irreducibly multiple**.

[hr]

[b]Closing The Spectrum: Why The Brain Needs Magenta[/b]

The color wheel **must** close into a circle for opponent process theory to work.

If the spectrum stayed linear (red... violet, with gap), there would be no color opposite to green. But **green needs an opponent** for the red-green channel to function.

[color=yellow][b]Code: The Necessary Invention[/b][/color]
[code]
# Opponent channels require opposites
var red_green_channel = ???

# Red is opposite to green (spectrum endpoints mix perceptually)
# Blue is opposite to yellow (short vs combined long+medium)

# But green needs an opposite
# The spectrum has no color opposite to green
# So the brain INVENTS magenta

# Magenta exists because the visual system
# requires perceptual closure
# Physics is linear, perception is circular
[/code]

**Magenta is necessary for perceptual coherence** - even though it's physically impossible.

The brain constructs it because the alternative (open-ended spectrum) would break the opponent process system.

[hr]

[b]What The Algorithm Confesses[/b]

[code]
var magenta = Color(1.0, 0.0, 1.0)

# This value renders easily
# Three primaries, simple mix
# But what is it?

# Not a wavelength (physics)
# Not in the spectrum (Newton's rainbow)
# Yet perceptually vivid (phenomenology)

# The algorithm can render the impossible
# Because rendering is not replication
# It is perceptual triggering

# We do not show you magenta
# We trigger your brain to construct it
[/code]

Every time you see magenta on screen, you are experiencing **constructed reality** - color that exists in neural processing, not in emitted photons.

**The screen does not emit magenta light.** It emits red and blue. **You create magenta.**

[hr]

[b]The Ontological Claim[/b]

Magenta is proof that:

**Reality is not reducible to physical substrate.**

- Physics: "Magenta has no wavelength - it doesn't exist"
- Perception: "I see it - it's real"
- Both are correct

**Experience can exceed material basis.** Qualia can be **genuinely real** without corresponding to measurable physical properties.

This is not idealism (denying physical reality). This is **relationalism** - acknowledging that reality emerges in the **interaction** between physics, biology, neural processing, and consciousness.

Magenta exists **in the relation**, not in any single level.

[hr]

[color=cyan][b]Summary:[/b][/color]
Magenta has no wavelength - it does not exist in the visible spectrum. It is perceptually constructed when L cones (red) and S cones (blue) activate without M cones (green). The brain invents magenta to close the linear spectrum into a perceptual color wheel, providing an opponent to green. Magenta is real in experience but impossible in physics - proof that perception constructs reality beyond physical substrate. The algorithm renders it easily by triggering cone patterns, not emitting spectral light.

[hr]

[color=orange][b]Conclusion:[/b] Color Is Fundamentally Queer[/color]

Color reveals reality as:
- **Plural** (dichromat, trichromat, tetrachromat - all valid)
- **Constructed** (categories are cultural, not natural)
- **Relational** (context-dependent, not intrinsic)
- **Irreducible** (wavelength, RGB, qualia - none unify)
- **Exceeding substrate** (magenta exists without wavelength)

This is not "rainbow symbolizes diversity." This is **reality itself resisting singular description**.

The algorithm tries to normalize (RGB, trichromacy, discrete levels). But color confesses: I cannot be captured. I exist in the gap between physics and experience, in the plurality of perceptions, in the impossibility of magenta.

**Reality is fundamentally queer. Color proves it.**

'''
