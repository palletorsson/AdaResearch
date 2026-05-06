extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Perception[/b][/font_size][/center]
[center][i]There Is No Normal Vision[/i][/center]

The algorithm assumes **trichromacy** - three cone types, three primaries, RGB.

This is not universal biology. It is **normalized** biology - the majority treated as standard, all deviation marked as deficiency.

But there is no "correct" way to see color. Only **plural ways** - each valid, each constructing a different perceptual reality from the same physical wavelengths.

**Reality is fundamentally queer: it admits multiple incompatible perceptions without resolution.**

[hr]

[b]Trichromacy: The Assumed Default[/b]

Most humans have **three types of cone cells** in the retina:
- **S cones** - Short wavelength (~420nm peak sensitivity, "blue")
- **M cones** - Medium wavelength (~530nm peak sensitivity, "green")
- **L cones** - Long wavelength (~560nm peak sensitivity, "red")

Three receptors. Three dimensions of color variation. This is why RGB works - screens exploit trichromatic biology.

[color=yellow][b]Code: The Three-Channel System[/b][/color]
[code]
# Trichromat perception
var s_cone_response = measure_blue_cone(wavelength)
var m_cone_response = measure_green_cone(wavelength)
var l_cone_response = measure_red_cone(wavelength)

# Three signals to brain
# Interpreted as color
# This is the "normal" assumed by all displays
[/code]

But **trichromacy is not universal**. It's just the statistical majority.

[hr]

[b]Dichromacy: "Colorblind" as Deviation from Norm[/b]

**Dichromats** have only **two types of cone cells**. This affects approximately:
- 8% of men (X-linked genetic trait)
- 0.5% of women

**Types of dichromacy:**
- **Protanopia** - Missing L (red) cones
- **Deuteranopia** - Missing M (green) cones
- **Tritanopia** - Missing S (blue) cones (very rare)

[color=yellow][b]Code: Two-Dimensional Color Space[/b][/color]
[code]
# Dichromat (protanopia - missing red cones)
var s_cone_response = measure_blue_cone(wavelength)
var m_cone_response = measure_green_cone(wavelength)
# No L cone response

# Only two signals
# Color is two-dimensional, not three
# Many trichromat-distinct colors appear identical

# Red and green look similar (both stimulate M cones similarly)
# Cannot distinguish certain color pairs
[/code]

"Colorblind" is a normative term - it defines dichromacy as **deficiency** relative to trichromat majority.

But dichromats don't see "less color" - they see **different color**. Their perceptual space has two dimensions instead of three. Not missing, but **structurally different**.

[hr]

[b]Tetrachromacy: The Excess Perception[/b]

Some people (estimated 12% of women, though many may not realize it) are **tetrachromats** - possessing **four types of cone cells**.

The fourth cone type has peak sensitivity between M and L cones - an additional dimension of color variation invisible to trichromats.

[color=yellow][b]Code: The Fourth Dimension[/b][/color]
[code]
# Tetrachromat perception
var s_cone_response = measure_blue_cone(wavelength)
var m_cone_response = measure_green_cone(wavelength)
var l_cone_response = measure_red_cone(wavelength)
var x_cone_response = measure_fourth_cone(wavelength)  # Extra receptor

# Four signals
# Four-dimensional color space
# Can distinguish colors that look identical to trichromats

# Sees approximately 100x more color distinctions
# ~100 million distinguishable hues (vs ~1 million for trichromats)
[/code]

**Tetrachromats see colors trichromats cannot.**

When you and a tetrachromat look at the same object:
- You see: Color(0.7, 0.5, 0.3)
- Tetrachromat sees: Color(0.7, 0.5, 0.3, **0.6**) - fourth dimension

**But RGB screens only have three primaries.** The display cannot render for tetrachromats. Their excess perception is **unrepresentable** in standard systems.

[color=orange][b]Queer excess:[/b][/color] Perception that exceeds normative representation. The fourth dimension cannot be displayed because the algorithm assumes three.

[hr]

[b]Who Sees "True" Color?[/b]

- Dichromat sees ~10,000 colors (2D color space)
- Trichromat sees ~1,000,000 colors (3D color space)
- Tetrachromat sees ~100,000,000 colors (4D color space)
- Mantis shrimp has 12-16 photoreceptor types (12-16D color space??)

**Which one is "correct"?**

The algorithm says: **trichromacy is normal**. But this is normalization, not nature.
- Dichromacy is not "deficient" - it's a valid perceptual structure
- Tetrachromacy is not "superhuman" - it's a valid perceptual structure
- Trichromacy is not "correct" - it's just **statistically common**

**There is no universal "true" color.** Only plural perceptions, each constructing reality differently from the same wavelengths.

[hr]

[b]Cultural Color Categories: Language Shapes Perception[/b]

Color perception is not just biological - it's **culturally constructed**. The categories you use to divide the spectrum affect what you perceive.

**Russian: Two Blues**
Russian has separate words for:
- **Goluboy** (голубой) - Light blue
- **Siniy** (синий) - Dark blue

These are not shades of one color (like "light red" = pink). They are **distinct color categories** - like red and orange in English.

[color=yellow][b]Perceptual Effect:[/b][/color]
Russian speakers:
- Process goluboy and siniy as different colors (like English speakers process blue and green)
- Show faster reaction times distinguishing these shades
- The **linguistic category creates perceptual boundary**

English speakers see both as "blue." Russian speakers see two colors.

**Same wavelengths. Different perceptual reality based on language.**

[hr]

[b]Japanese: Ao Covers Blue and Green[/b]

Japanese **ao** (青) historically covered both:
- Blue (sky, ocean)
- Green (traffic lights, grass in some contexts)

Modern Japanese has *midori* (緑) for green, but **ao** still applies to:
- Green traffic lights (ao shingō)
- Young/fresh vegetation

[color=yellow][b]Code: Category Boundaries Are Cultural[/b][/color]
[code]
var wavelength = 505  # nm (cyan-green boundary)

# English speaker: "Is this blue or green?"
# Boundary around 490-500nm

# Russian speaker: "This is neither goluboy nor siniy"
# Different categories, different boundaries

# Japanese (traditional): "This is ao"
# One category spans both

# Same wavelength
# Different categorical perception
# Language mediates reality
[/code]

**Color categories are not natural kinds discovered by all cultures.** They are **constructed** - shaped by language, culture, environment.

[hr]

[b]Berlin & Kay vs Linguistic Relativity[/b]

**Berlin & Kay (1969)** argued for universal color categories:
- All languages evolve color terms in predictable order
- Black/white → red → green/yellow → blue → brown → others
- Suggested biological/perceptual universals

**Critics argued** this privileged Western categories:
- Many languages have categories that don't map to English
- "Blue" vs "green" boundary varies widely
- Categories reflect cultural salience, not perceptual inevitability

[color=orange][b]The Tension:[/b][/color]
- Some perceptual boundaries seem universal (all cultures distinguish warm vs cool)
- But exact categories vary enormously
- Biology constrains, culture constructs

**Color categories are neither purely universal nor purely arbitrary** - they emerge in the interaction between perceptual apparatus and cultural/linguistic practice.

[hr]

[b]The Dress: Irreducible Multiplicity[/b]

In 2015, a photo of a dress went viral. People saw it as:
- **Blue dress with black lace** (~70% of viewers)
- **White dress with gold lace** (~30% of viewers)

**Same RGB pixels. Genuinely different perceptions.**

[color=yellow][b]The Actual Pixels:[/b][/color]
[code]
# The dress pixels (measured from photo)
var pixel_color = Color(0.467, 0.427, 0.357)

# Ambiguous: could be blue in warm light, or white in shadow

# Viewer brain makes assumption about illumination:
# - Assume warm (yellowish) light → compensate by seeing blue/black
# - Assume cool (bluish) shadow → compensate by seeing white/gold

# Both perceptions are neurologically valid
# No "correct" answer
[/code]

**Color constancy algorithms** in your visual cortex make different assumptions about lighting. Both interpretations are **valid** given different contexts.

**The algorithm cannot resolve this.** Reality admits both perceptions. Multiplicity without synthesis.

[hr]

[b]Simultaneous Contrast: Context Determines Color[/b]

The same RGB value appears **different** depending on surrounding colors.

[color=yellow][b]Code: Context-Dependent Perception[/b][/color]
[code]
var gray_square = Color(0.5, 0.5, 0.5)

# Surrounded by white → looks dark gray
# Surrounded by black → looks light gray

# Same RGB value
# Different perceived brightness

# Your brain interprets color RELATIONALLY
# Not as absolute value, but as difference from context
[/code]

**Color is not a property of isolated pixels** - it emerges from relationships, contrasts, spatial context.

The algorithm stores `Color(0.5, 0.5, 0.5)` as absolute value. You experience it as relative to surroundings.

[hr]

[b]Synesthesia: Color Where There Is No Wavelength[/b]

Some people experience **synesthesia** - cross-activation between sensory modalities.

**Grapheme-color synesthesia:**
- Letters and numbers trigger color perception
- "A" might always appear red, "5" always blue
- Consistent, involuntary, perceptually real

[color=yellow][b]Perception Without Physical Stimulus:[/b][/color]
[code]
# Synesthete reads letter "A"
var letter = "A"

# No wavelength present (black text on white)
# But experiences red

# Color perception without color stimulus
# Neural cross-wiring creates qualia
# Experience is real despite absent physics
[/code]

Color can exist **experientially** without existing **physically**. Perception is not passive reception of wavelengths - it's active construction that can occur independently of stimulus.

[hr]

[b]What Perception Reveals: Reality Is Fundamentally Plural[/b]

There is no singular "true" color because:

1. **No universal biology** - Dichromats, trichromats, tetrachromats see different colors
2. **No universal categories** - Russian blues, Japanese ao, cultural construction
3. **No context-independent perception** - Simultaneous contrast, the dress
4. **No one-to-one mapping** - Metamerism (different physics, same color), constancy (same physics, different color)
5. **No purely physical basis** - Synesthesia creates color without wavelength

**Color exists in the irreducible relationship between:**
- Wavelength (physics)
- Cone cells (biology)
- Neural processing (neuroscience)
- Cultural categories (linguistics)
- Surrounding context (relational field)
- Subjective experience (phenomenology)

None of these levels reduces to the others. All are necessary. None is sufficient.

[hr]

[b]The Queer Ontology[/b]

**Queer** does not mean "rainbow flag." It means:
- **Resistance to normalization** - No "normal" vision (trichromacy is just common)
- **Irreducible plurality** - Dichromat, trichromat, tetrachromat all valid
- **Constructed categories** - Color names are cultural, not natural
- **Multiplicity without resolution** - The dress admits both perceptions
- **Excess beyond representation** - Tetrachromat's fourth dimension unrenderable
- **Relational over essential** - Color is context-dependent, not intrinsic property

**Reality is fundamentally queer because it resists singular description.**

The algorithm tries to normalize (RGB for trichromats). But:
- Dichromats see different reality
- Tetrachromats see excess reality
- Cultural categories reshape perceptual boundaries
- Context determines experience
- Multiple valid perceptions coexist

**Color is not "out there" to be measured correctly.** It's **constructed** in the intersection of physics, biology, culture, and consciousness.

[hr]

[b>The Algorithm's Limit[/b]

[code]
var color = Color(0.6, 0.4, 0.2)

# Trichromat: sees one color
# Dichromat: might see different color (missing dimension)
# Tetrachromat: sees insufficient color (missing fourth channel)

# English speaker: "brown"
# Russian speaker: different categorical perception
# Japanese speaker: different contextual meaning

# In bright context: looks lighter
# In dark context: looks darker

# There is no singular "correct" perception
# The algorithm cannot determine "true" color
# Because truth is plural
[/code]

**The three primaries are an admission:** We normalize to majority biology, represent in discrete categories, store absolute values that are experienced relationally.

Color is where the algorithm confesses: **I cannot capture reality, only approximate one normalized version.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Perception reveals color's irreducible plurality: dichromats (2 cone types), trichromats (3 cone types), tetrachromats (4 cone types) see different realities from same wavelengths. Cultural categories shape perception (Russian two blues, Japanese ao). Context determines experience (the dress, simultaneous contrast). No "normal" vision exists - only plural valid perceptions. Reality is fundamentally queer: multiple incompatible descriptions coexist without resolution.

[hr]

[color=orange][b]Next:[/b] Magenta[/color]
The impossible color - no wavelength, yet perceptually real.
Magenta is the color that should not exist according to physics.
But you see it anyway.
This is where perception constructs reality beyond physical substrate.

'''
