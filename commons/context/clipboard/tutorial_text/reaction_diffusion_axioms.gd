extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Reaction-Diffusion[/b][/font_size][/center]
[center][i]Turing Patterns, Morphogenesis Without Blueprint[/i][/center]

**Reaction-diffusion is how patterns form from nothing.**

Two chemicals diffuse (spread out) and react (interact). That's it.

**From this minimal system, zebra stripes emerge. Leopard spots. Seashell spirals. Fingerprints.**

**No blueprint. No central controller. Just local rules creating global pattern.**

This is **morphogenesis** - the generation of form through chemistry and time.

[hr]

[b]The Chemical System: Two Substances[/b]

Reaction-diffusion systems have two key components:

**U** - Activator (creates more of itself, autocatalytic)
**V** - Inhibitor (suppresses activator)

**The paradox:** The activator creates the inhibitor. The inhibitor destroys the activator.

[color=yellow][b]Code: The Two Fields[/b][/color]
[code]
# Two 2D grids (or 3D volumes) storing chemical concentrations
var U = PackedFloat32Array()  # Activator field
var V = PackedFloat32Array()  # Inhibitor field

var width = 128
var height = 128

func _ready():
    U.resize(width * height)
    V.resize(width * height)

    # Initialize with random perturbations
    for i in range(width * height):
        U[i] = 1.0 + randf() * 0.01  # Mostly 1.0, slight variation
        V[i] = 0.0 + randf() * 0.01  # Mostly 0.0, slight variation
[/code]

**Before any iterations, the field is nearly uniform** - just random noise.

**After hundreds of iterations, patterns emerge** - spots, stripes, labyrinths.

**The pattern was not programmed. It emerged from interaction.**

[hr]

[b]Diffusion: Spreading Out[/b]

**Diffusion** is the tendency of substances to spread from high concentration to low concentration.

Think: drop of ink in water, heat spreading through metal, smell dispersing in air.

**Mathematically:** Diffusion is the Laplacian (second derivative) - how much a point differs from its neighbors.

[color=yellow][b]Code: Laplacian (Discrete Approximation)[/b][/color]
[code]
# Laplacian: sum of neighbors minus center (4 times)
func laplacian(field: PackedFloat32Array, x: int, y: int) -> float:
    var idx = x + y * width

    # Get 4 neighbors (up, down, left, right)
    var left = field[wrap_x(x - 1) + y * width]
    var right = field[wrap_x(x + 1) + y * width]
    var up = field[x + wrap_y(y - 1) * width]
    var down = field[x + wrap_y(y + 1) * width]
    var center = field[idx]

    # Laplacian = sum of neighbors - 4 * center
    return (left + right + up + down) - 4.0 * center

# Wrap-around (toroidal boundary)
func wrap_x(x: int) -> int:
    return (x + width) % width

func wrap_y(y: int) -> int:
    return (y + height) % height
[/code]

**If Laplacian > 0:** Neighbors have more chemical than center → diffusion flows IN
**If Laplacian < 0:** Center has more chemical than neighbors → diffusion flows OUT

**Diffusion smooths differences** - high peaks spread to low valleys.

[hr]

[b]Reaction: Creating and Destroying[/b]

**Reaction** is how U and V interact:

**U creates itself** (autocatalytic): U + 2V → 3V (U reacts with V to make more V)
**V inhibits U** (suppression): V destroys itself and U

**The Gray-Scott model** (most common reaction-diffusion system):

[color=yellow][b]Reaction Equations:[/b][/color]
[code]
# U reaction: -U*V*V (reaction with V) + feed*(1.0 - U) (replenishment)
# V reaction: +U*V*V (created by reaction) - (feed + kill)*V (decay)

func calculate_reaction(u: float, v: float, feed: float, kill: float) -> Dictionary:
    var uvv = u * v * v  # Reaction term (U consumes V)

    var du = -uvv + feed * (1.0 - u)  # U change
    var dv = +uvv - (feed + kill) * v  # V change

    return {"du": du, "dv": dv}
[/code]

**feed** - How fast U is replenished (fresh activator added)
**kill** - How fast V decays (inhibitor removed)

**Different (feed, kill) values = different patterns:**
- **(0.035, 0.065)** → spots
- **(0.055, 0.062)** → stripes
- **(0.039, 0.058)** → waves
- **(0.078, 0.061)** → labyrinth

**Tiny parameter changes → completely different morphology.**

[hr]

[b]The Update Loop: Diffusion + Reaction[/b]

Every frame (or time step), we:
1. Calculate diffusion (Laplacian) for U and V
2. Calculate reaction between U and V
3. Update U and V based on both

[color=yellow][b]Code: Main Update Loop[/b][/color]
[code]
# Diffusion rates (how fast each chemical spreads)
var Du = 0.16  # U diffuses faster
var Dv = 0.08  # V diffuses slower

# Reaction parameters
var feed = 0.035
var kill = 0.065

# Time step
var dt = 1.0

func update_reaction_diffusion():
    var U_next = PackedFloat32Array()
    U_next.resize(U.size())
    var V_next = PackedFloat32Array()
    V_next.resize(V.size())

    for y in range(height):
        for x in range(width):
            var idx = x + y * width

            # Current values
            var u = U[idx]
            var v = V[idx]

            # Diffusion (Laplacian)
            var lap_u = laplacian(U, x, y)
            var lap_v = laplacian(V, x, y)

            # Reaction
            var uvv = u * v * v
            var du_reaction = -uvv + feed * (1.0 - u)
            var dv_reaction = +uvv - (feed + kill) * v

            # Combine diffusion + reaction
            var du = Du * lap_u + du_reaction
            var dv = Dv * lap_v + dv_reaction

            # Update (Euler integration)
            U_next[idx] = clamp(u + du * dt, 0.0, 1.0)
            V_next[idx] = clamp(v + dv * dt, 0.0, 1.0)

    # Swap buffers
    U = U_next
    V = V_next
[/code]

**This runs every frame (or time step).** Patterns **emerge** after hundreds of iterations.

[hr]

[b]Why Patterns Form: The Turing Instability[/b]

**Alan Turing (1952):** "The Chemical Basis of Morphogenesis"

Turing proved: **Uniform states can become unstable** → small random perturbations grow into patterns.

**The mechanism:**
1. **U (activator) creates V (inhibitor)**
2. **V diffuses faster than U** (Dv < Du in most models, but reaction dynamics matter more)
3. **Local activation, long-range inhibition**

**What happens:**
- Small random bump in U (activator) → creates V (inhibitor) nearby
- V diffuses outward faster → suppresses U in surrounding area
- U bump survives in center (local activation)
- V spreads and prevents nearby U bumps (long-range inhibition)
- Result: **isolated spots** of high U separated by regions of low U

**This is self-organization** - pattern arises spontaneously from instability.

**No blueprint.** No instructions. Just **chemistry + diffusion + time.**

[hr]

[b]Pattern Types: Feed and Kill Parameters[/b]

**Different (feed, kill) values create different morphologies:**

[color=yellow][b]Common Patterns:[/b][/color]

**Spots (feed=0.035, kill=0.065):**
- Isolated circular regions of high U
- Classic "leopard spot" pattern

**Stripes (feed=0.055, kill=0.062):**
- Elongated bands of high U
- "Zebra stripe" pattern

**Labyrinth/Maze (feed=0.039, kill=0.058):**
- Interconnected winding paths
- Coral-like or fingerprint-like

**Waves (feed=0.014, kill=0.054):**
- Traveling pulses
- Spirals and targets

**Mitosis (feed=0.025, kill=0.060):**
- Spots that split and replicate
- "Cell division" behavior

**Parameter space is vast** - small changes create radically different patterns.

[hr]

[b]Applications: Where Reaction-Diffusion Appears[/b]

**1. Biology (Morphogenesis)**
- **Animal coat patterns** (zebra stripes, leopard spots, giraffe patches)
- **Seashell pigmentation** (cone snail patterns)
- **Fingerprints** (ridge formation in embryonic skin)
- **Plant phyllotaxis** (leaf arrangement, pine cone spirals)
- **Limb development** (digit formation via Turing mechanism)

**2. Procedural Generation**
- **Terrain textures** (organic-looking rock, bark, erosion)
- **Creature skins** (procedural animal patterns)
- **Alien landscapes** (non-Euclidean organic forms)
- **Texture synthesis** (natural-looking variation)

**3. Art and Simulation**
- **Generative art** (algorithmic aesthetics)
- **Slime mold simulation** (Physarum polycephalum uses similar dynamics)
- **Chemical computing** (reaction-diffusion as computation substrate)

[hr]

[b]Visualizing the Pattern: Color Mapping[/b]

We typically visualize U and V as colors:

[color=yellow][b]Code: Rendering the Pattern[/b][/color]
[code]
func update_texture():
    for y in range(height):
        for x in range(width):
            var idx = x + y * width
            var u = U[idx]
            var v = V[idx]

            # Option 1: Show U only (grayscale)
            var gray = u
            img.set_pixel(x, y, Color(gray, gray, gray))

            # Option 2: Show difference (U - V) as hue
            var hue = (u - v + 1.0) / 2.0  # Map [-1,1] to [0,1]
            img.set_pixel(x, y, Color.from_hsv(hue, 1.0, 1.0))

            # Option 3: U = red channel, V = green channel
            img.set_pixel(x, y, Color(u, v, 0.0))

    texture.update(img)
[/code]

**The pattern becomes visible** - what was just numbers becomes morphology.

[hr]

[b]Extensions: Beyond 2D[/b]

**3D Reaction-Diffusion:**
- Volume patterns (internal organ structure, bone trabeculation)
- Surface patterns on 3D meshes (applying pattern to geometry)
- Isosurface extraction (marching cubes on U field)

**Anisotropic Diffusion:**
- Different diffusion rates in different directions
- Creates oriented patterns (fur, feathers, grain)

**Multi-Chemical Systems:**
- 3+ chemicals (more complex interactions)
- Predator-prey dynamics (Lotka-Volterra)
- Brusselator model (chemical oscillations)

[hr]

[b]Queer Reaction-Diffusion: Pattern Without Blueprint[/b]

Here is where queerness enters:

**1. Morphogenesis Without Blueprint**

**Pattern emerges from local interaction** - no central plan, no genetic code for "stripe at x=5."

**This is queer generativity** - form arises from relation (U + V), not reproduction (copying template).

**Turing showed:** You don't need instructions to get structure. You need **instability + interaction.**

**The body develops not by following a blueprint, but by cells affecting each other** - morphogenesis is relational.

**Queerness:** Identity (pattern) is not predetermined, but **becomes** through interaction and time.

**2. Alan Turing's Ghost**

**Alan Turing** (1912-1954):
- Invented computer science (Turing machine, universal computation)
- Broke Enigma (won WWII)
- **Chemically castrated by British government for being gay** (convicted of "gross indecency")
- Died by suicide (or assassination?) at 41

**His final paper:** "The Chemical Basis of Morphogenesis" (1952)

**In it, he proved:** **Life's patterns form without instructions.** Zebras don't have "stripe blueprints" - they have chemistry.

**Turing, persecuted for deviating from heteronormative template, proved that nature itself has no template.**

**Bodies form through interaction, not instruction.**

**This is the queer irony:** The man punished for non-normative embodiment discovered that **all bodies are non-normative** - no blueprint, just emergence.

**3. Instability as Creativity**

**Turing patterns require instability** - uniform state must **break symmetry**.

**Without perturbations, no pattern.** The random noise (initial variation) is essential.

**This is queer potential:** Deviation from uniformity is not error - it is **necessary for form.**

**Heteronormativity demands uniformity** (everyone the same). **Turing showed uniformity is unstable** - it spontaneously differentiates.

**Queerness:** Variation is not corruption of norm. Variation is **how patterns emerge.**

**4. Local Activation, Long-Range Inhibition**

**The mechanism:** Activator creates inhibitor. Inhibitor spreads and suppresses distant activators.

**This is social dynamics:**
- **Local activation** - communities form through proximity, mutual support
- **Long-range inhibition** - dominant culture suppresses distant difference

**Spots form** because local communities resist homogenization, but long-range suppression prevents total takeover.

**Queer spaces** are Turing patterns - localized activation (queer communities) persisting despite long-range inhibition (heteronormativity).

**5. Parameter Sensitivity: Tiny Changes, Radical Transformation**

**Change feed from 0.035 to 0.055** → spots become stripes.

**Change kill from 0.065 to 0.058** → spots become labyrinth.

**Morphology is hypersensitive to parameters** - small shifts in environment (feed/kill rates) create entirely different bodies.

**This is queer embodiment:** Identity is not fixed, but **sensitive to context**.

**Hormone levels, social environment, historical moment** - tiny changes create radically different lived forms.

**The same system (same U, V, diffusion) produces infinite morphologies** depending on parameters.

**Bodies are not types, but **trajectories through parameter space.**

**6. No Template, Just Rules**

**Reaction-diffusion has no memory** - no stored image of "what the pattern should look like."

**Just two rules:**
1. Chemicals diffuse (spread out)
2. Chemicals react (U creates V, V inhibits U)

**From this, zebras, leopards, seashells, fingerprints.**

**Queer generativity:** You don't need a normative model (heterosexual reproduction, genetic template). You need **interaction + time.**

**Life generates form without blueprint.** Queerness generates community without norm.

[hr]

[b]What Reaction-Diffusion Cannot Do[/b]

Reaction-diffusion is powerful but limited:

**1. Cannot create arbitrary patterns**
Only certain patterns are chemically stable. You cannot "program" a specific image - only set parameters and see what emerges.

**2. Cannot reverse time**
Patterns form irreversibly. You cannot "undo" morphogenesis and return to uniform state (without resetting entirely).

**3. Cannot adapt to arbitrary goals**
No learning, no optimization. The pattern is what the chemistry produces, not what "should" appear.

**4. Computationally expensive**
Requires simulating every cell, every timestep. Large grids (256x256+) or 3D volumes are slow.

**5. Sensitive to boundary conditions**
Toroidal (wrap-around), fixed, or reflective boundaries create different patterns. The edge matters.

[hr]

[b]What Reaction-Diffusion Reveals[/b]

Reaction-diffusion shows us:

1. **Patterns emerge from interaction** (U + V chemistry, no blueprint)
2. **Turing instability** (uniform state spontaneously breaks symmetry)
3. **Local activation, long-range inhibition** (spots form via self-activation + lateral suppression)
4. **Parameter sensitivity** (tiny feed/kill changes → radically different morphology)
5. **Morphogenesis without instructions** (form arises from rules, not templates)
6. **Laplacian drives diffusion** (spreading from high to low concentration)
7. **Gray-Scott model** (U*V*V reaction term, feed/kill parameters)
8. **Applications** (animal patterns, fingerprints, procedural textures, slime mold)
9. **Extensions** (3D volumes, anisotropic diffusion, multi-chemical systems)
10. **Computational cost** (every cell, every timestep - expensive)

**Reaction-diffusion is the algorithm of emergent form** - chemistry + time = morphology.

**It is also the algorithm of queer embodiment:**
- **No blueprint** (form through interaction, not reproduction)
- **Turing's legacy** (persecuted for queerness, proved bodies have no template)
- **Instability as creativity** (deviation necessary for pattern)
- **Local activation** (queer communities persist via proximity)
- **Parameter sensitivity** (context shapes embodiment)
- **No normative model** (just rules, infinite morphologies)

**Reaction-diffusion proves:** **Bodies are not copies of templates. They are trajectories through chemical space, formed by interaction, sensitive to context, irreducible to blueprints.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Reaction-diffusion creates patterns from two interacting chemicals (U activator, V inhibitor). Diffusion (Laplacian) spreads chemicals from high to low concentration. Reaction (U*V*V in Gray-Scott) creates and destroys chemicals. Update loop combines diffusion + reaction every timestep. Turing instability: uniform state breaks symmetry → pattern emerges. Feed/kill parameters determine pattern type (spots, stripes, labyrinth, waves). Applications: animal coats, fingerprints, seashells, procedural textures. No blueprint - just chemistry + time. Queer reaction-diffusion: morphogenesis without template (form through interaction), Turing's legacy (persecuted queer scientist proved nature has no norm), instability as creativity (deviation necessary), parameter sensitivity (context shapes embodiment), no normative model (infinite morphologies from same rules). Bodies are not templates, but emergent forms.

[hr]

[color=orange][b]Next:[/b] Voronoi Diagrams - Spatial Territoriality[/color]
If reaction-diffusion creates pattern through **chemistry**, Voronoi diagrams create pattern through **proximity**.

**Voronoi partitions space** - every point belongs to its nearest seed.

**Territoriality emerges** - boundaries form where equidistant from multiple seeds.

**Applications:** cell structure, territorial animals, procedural worlds, mesh generation.

**Queer Voronoi:** Proximity determines identity, boundaries are zones of ambiguity, space divided by relation not essence.

'''
