extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]RGB: The Three Primaries[/b][/font_size][/center]
[center][i]Additive Color and the Screen's Deception[/i][/center]

Your screen displays millions of colors. But it only emits three wavelengths.

Red. Green. Blue.

Every color you see right now - the subtle gradients, the rich hues, the soft pastels - is created by mixing just these three primaries in different intensities. This is **additive color**: light added to light.

The screen is deceiving your eyes. And you cannot help but be deceived.

[hr]

[b]The Three Primaries: Why RGB?[/b]

Human eyes (most of them) have three types of cone cells:
- **L cones** - respond to long wavelengths (red, ~560-580nm peak)
- **M cones** - respond to medium wavelengths (green, ~530-540nm peak)
- **S cones** - respond to short wavelengths (blue, ~420-440nm peak)

RGB displays **exploit this biology**. By emitting three wavelengths that stimulate each cone type, the screen can trigger any combination of cone responses - fooling your visual system into perceiving colors that aren't actually there.

[color=yellow][b]Code: The Three Channels[/b][/color]
[code]
# Every pixel stores three values
var red_intensity = 0.8    # How much red light (0.0 to 1.0)
var green_intensity = 0.3  # How much green light
var blue_intensity = 0.1   # How much blue light

var color = Color(red_intensity, green_intensity, blue_intensity)

# Three numbers
# Millions of perceived hues
[/code]

Three dimensions of variation. 256 levels per channel (in 8-bit color). **16,777,216 possible combinations.**

But the screen never emits 16 million different wavelengths. Only three. The rest is **perceptual construction**.

[hr]

[b]Additive Color: Light Upon Light[/b]

Unlike paint (which is **subtractive** - pigments absorb wavelengths), screens use **additive color** - emitting light that combines.

[color=yellow][b]The Additive Primaries:[/b][/color]
[code]
# Red + Green = Yellow
var yellow = Color(1.0, 1.0, 0.0)

# Red + Blue = Magenta
var magenta = Color(1.0, 0.0, 1.0)

# Green + Blue = Cyan
var cyan = Color(0.0, 1.0, 1.0)

# Red + Green + Blue = White
var white = Color(1.0, 1.0, 1.0)

# No light = Black
var black = Color(0.0, 0.0, 0.0)
[/code]

This is **counterintuitive** if you learned color from mixing paint:
- Paint: Yellow + Blue = Green
- Light: Yellow (Red+Green) + Blue = White

Additive and subtractive color are inverse systems. The algorithm uses additive because screens **emit** light. Printers use subtractive (CMYK) because ink **absorbs** light.

[hr]

[b]The Screen Has No Yellow[/b]

When you see yellow on this screen, **no yellow light is being emitted**.

The screen displays:
- Red pixel at full intensity
- Green pixel at full intensity
- Blue pixel off

These pixels are so small and close together that your eye cannot resolve them individually. The red and green light **blend in your retina**, and your brain interprets the combined stimulus as "yellow."

[color=yellow][b]Code: The Yellow That Isn't There[/b][/color]
[code]
# This looks yellow
var yellow = Color(1.0, 1.0, 0.0)

# But the screen is actually emitting:
# - 100% red LED light (~630nm)
# - 100% green LED light (~530nm)
# - 0% blue LED light

# No 580nm "yellow" wavelength is present
# Your cones receive red + green stimulus
# Your brain constructs "yellow" perception

# The yellow exists in your visual cortex, not in the photons
[/code]

**Every color on screen is a neurological construction triggered by three primaries.**

[hr]

[b]The Discretization of Continuous Experience[/b]

In 8-bit color, each channel has 256 levels (0-255). This seems like a lot. But the visible spectrum is **continuous** - infinite gradations between wavelengths.

[color=yellow][b]Code: 256 Levels Per Channel[/b][/color]
[code]
# 8-bit RGB
var red = 204    # 0-255 integer
var green = 87
var blue = 34

# Why 256 levels?
# Because 256 = 2^8 (one byte)
# Computational convenience, not perceptual necessity

# Convert to 0.0-1.0 range for Godot
var color = Color(red/255.0, green/255.0, blue/255.0)
[/code]

**Why 256?** Because of **8-bit bytes** - the fundamental unit of computer memory. The number of color levels we can perceive is discretized to fit byte boundaries.

This is arbitrary. 10-bit color (1024 levels per channel) exists. 16-bit color (65,536 levels). The "standard" is a computational compromise, not a natural boundary.

[hr]

[b]Normalization: Trichromacy as Default[/b]

RGB assumes **trichromatic vision** - three cone types. This covers most humans. But:

- **Dichromats** (colorblind, ~8% of men): Two cone types - cannot distinguish certain color combinations
- **Tetrachromats** (rare, some women): Four cone types - can distinguish colors that look identical to trichromats
- **Mantis shrimp**: 12-16 photoreceptor types

**RGB normalizes trichromacy.** The three primaries match the three cone types of the majority. Everyone else gets approximation or excess.

[color=yellow][b]Code: The Unrenderable Fourth Primary[/b][/color]
[code]
# For a tetrachromat with 4 cone types
# Ideal display would have 4 primaries: R, G, B, ???

# But screens only emit 3
# So tetrachromats see identical RGB values
# for colors they can perceptually distinguish

# Their excess perception is invisible to the algorithm
# The fourth dimension cannot be rendered
[/code]

RGB is not "correct" color representation. It's **normalized** color representation - calibrated to majority biology, excluding perceptual minorities.

[hr]

[b]Gamma Correction: The Nonlinear Secret[/b]

RGB values are not **perceptually linear**. Doubling the RGB value does not double perceived brightness.

[color=yellow][b]Code: The Gamma Curve[/b][/color]
[code]
# Linear RGB (what you might expect)
var linear_50_percent = Color(0.5, 0.5, 0.5)

# But this looks darker than 50% brightness
# Because human perception is nonlinear

# sRGB applies gamma correction (~2.2 curve)
# To make 0.5 RGB look like 50% brightness

# The "straight" representation is curved
# To match your eye's logarithmic response
[/code]

The RGB values you specify are **already compensated** for your eye's nonlinearity. "Linear" RGB is a lie - it's pre-distorted to **appear** linear to perception.

Another layer of deception built into the standard.

[hr]

[b]Gamut: The Colors You Cannot See Here[/b]

RGB can only display colors within its **gamut** - the range of colors producible by mixing the three primaries.

Many real-world colors fall **outside sRGB gamut**:
- Saturated cyans (pure 490nm)
- Deep magentas
- Certain greens

[color=yellow][b]Code: Out of Gamut[/b][/color]
[code]
# Some spectral colors cannot be displayed
# The most saturated cyan in nature (~490nm wavelength)
# is more vivid than any RGB combination can produce

# When you photograph it, the camera clamps:
# var out_of_gamut_cyan = Color(???)  # No valid RGB

# The photo is always less saturated than reality
# Gamut is a cage
[/code]

**Your screen cannot show you all the colors that exist.** Some wavelengths are **unrenderable** in RGB space.

The algorithm admits: there are colors we cannot represent.

[hr]

[b]What RGB Reveals[/b]

The three primaries system shows us:

1. **Perception is hackable** - Three wavelengths create millions of colors neurologically
2. **Standards are arbitrary** - Why 256 levels? Because bytes.
3. **Normalization excludes** - Trichromacy privileged, tetrachromats ignored
4. **Representation is limited** - Gamut cage, unrenderable colors
5. **"Natural" is pre-distorted** - Gamma correction makes nonlinear appear linear
6. **The screen lies** - Yellow with no yellow light, white from three colors

RGB is not "true" color. It's **engineered perception** - a hack that exploits your cone cells' response curves to create the illusion of continuous color from three discrete primaries.

And it works. You cannot see the deception while experiencing it.

[hr]

[b]The Algorithm's Confession[/b]

[code]
var color = Color(0.7, 0.4, 0.2)

# This is:
# - Three intensities (discrete)
# - Triggering three cone types (biological)
# - Interpreted by visual cortex (neurological)
# - Perceived as unified hue (phenomenological)

# Not wavelength
# Not "real" color
# Just three numbers that reliably produce an experience

# The algorithm cannot give you color
# Only the trigger
[/code]

RGB is the first admission: **We cannot render reality, only stimulate perception.**

[hr]

[color=cyan][b]Summary:[/b][/color]
RGB uses three additive primaries (red, green, blue) to exploit trichromatic vision - three cone types in most human eyes. Screens emit only three wavelengths but create millions of perceived colors by varying intensity. This is normalized to majority biology (excluding tetrachromats), discretized to byte boundaries (256 levels), and gamma-corrected to appear linear. RGB is engineered illusion, not true color - a hack that works by fooling your visual system.

[hr]

[color=orange][b]Next:[/b] The Spectrum[/color]
If RGB is computational representation, wavelength is physical measurement.
Physics promised to unify color - reduce it to electromagnetic frequency.
But wavelength cannot explain why 650nm **feels** red.
The explanatory gap opens.

'''
