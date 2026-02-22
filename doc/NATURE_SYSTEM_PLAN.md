# Ada Research 46 — Nature System Plan
## Q-FEP Critter Architecture

> "We are all critters. We are algorithms — potential under restraint."
> — Inspired by Donna Haraway's *Staying with the Trouble*

> Nothing is purely enemy. Nothing is purely medicine. Everything is 
> **potential under restraint** — and the restraint can change. A poison 
> becomes a vision. A hazard becomes flight. A predator becomes a symbiont.
> This is the Nature of Code.

---

## PHILOSOPHICAL CORE

### The Haraway-Q-FEP Synthesis

**Donna Haraway** says: we are all critters — entangled, kin, making-with.
There are no pure categories. No clean boundaries between self/other, 
friend/enemy, nature/technology.

**Q-FEP** (Quantum Free Energy Principle) says: every organism minimizes
surprise by building a generative model of its world. But "surprise" is 
relative to the model — change the model, change what's surprising.

**Together**: Every entity in the system is a *critter* — an algorithm 
exploring possibility space under constraints. The constraints (physics, 
energy, other critters, the player) shape what potentials are expressed.
Remove a constraint → new potential emerges.

### Design Principle: Transmutation

Every element in the system exists on a **spectrum**, not in a category:

```
HAZARD ←————————→ MEDICINE
  poison mushroom ←→ healing vision
  plasma critter  ←→ energy shield  
  thorny vine     ←→ grappling hook
  cave darkness   ←→ echolocation ability
  predator        ←→ mount / ally
```

**The player's relationship with a critter determines what it becomes.**

- **Fight** a plasma critter → it's a hazard
- **Observe** it → you learn its pattern → it becomes information
- **Feed** it → it bonds → it becomes a tool (energy shield)
- **Breed** it with a flower → hybrid organism → new ability

---

## SYSTEM ARCHITECTURE

### Everything Is a Critter

```
CritterDNA (Resource)
├── morphology: Dictionary     # Physical form parameters
│   ├── body_type: String      # "tree", "walker", "flower", "fungus", "hybrid"
│   ├── segments: int          # Body complexity
│   ├── symmetry: int          # Radial symmetry order
│   ├── colors: Array[Color]   # Phenotype expression
│   └── scale_range: Vector2   # Min/max size
├── behavior: Dictionary       # How it acts
│   ├── mobility: float        # 0 (rooted) → 1 (fast runner)
│   ├── aggression: float      # 0 (passive) → 1 (predator)
│   ├── sociality: float       # 0 (solitary) → 1 (swarm)
│   └── curiosity: float       # 0 (avoidant) → 1 (seeks novelty)
├── metabolism: Dictionary     # Energy dynamics
│   ├── energy_source: String  # "light", "organic", "mineral", "player_proximity"
│   ├── output: String         # "oxygen", "spores", "light", "sound"
│   └── efficiency: float
├── potential: Dictionary      # What it CAN become (Haraway)
│   ├── transmutations: Array  # ["medicine", "weapon", "mount", "vision"]
│   ├── affinity: float        # How easily player bonds with it
│   └── restraints: Array      # What's currently suppressing its potential
└── lineage: Dictionary        # Evolutionary history
    ├── parent_a_id: String
    ├── parent_b_id: String
    ├── generation: int
    └── mutations: Array       # What changed from parents
```

### The Transmutation System

This is the key mechanic that embodies Haraway's philosophy:

```
Transmutation (Resource)
├── source_state: String       # "hazard", "neutral", "critter"
├── target_state: String       # "medicine", "ability", "companion"
├── relationship_required: float  # Bond level needed (0-1)
├── ritual: String             # What player must do
│   Examples:
│   - "observe_for_30s"        → Learn its pattern
│   - "feed_3_times"           → Build trust
│   - "survive_encounter"      → Earn respect
│   - "cross_pollinate"        → Create hybrid
│   - "enter_its_space"        → Become kin
├── grants: Dictionary         # What the player gains
│   - "vision_mode": "infrared"
│   - "defense": "spore_cloud"
│   - "mobility": "glide"
│   - "perception": "echolocation"
│   - "healing": "regeneration"
└── cost: String               # What changes for the critter
    # Nothing is free — transmutation transforms BOTH parties
```

---

## THE FIVE KINGDOMS (All Critters)

### 1. Trees — Structural Critters
Rooted algorithms that optimize for light. Potential: shelter, tools, bridges.

**Existing assets**: `lsystem_tree_vr`, `lsystem_editor`, `alessi_tree`

| As Restraint | As Potential |
|---|---|
| Blocks path | Climbable vantage point |
| Dense canopy (darkness) | Rain shelter, creature habitat |
| Falling branches | Building material |
| Roots (trip hazard) | Underground network (communication) |

**Transmutation**: Spend time near a tree → it grows toward you → 
eventually bends to form a bridge or shelter. The tree chose you as kin.

### 2. Creatures — Mobile Critters  
Walking algorithms that minimize surprise. Potential: allies, mounts, abilities.

**Existing assets**: `octapod_crawler` (2-6 legs), `plasma_critter`, 
`evolved_creatures`, `randombutterflies`, `ecosystem_simulation`

| As Restraint | As Potential |
|---|---|  
| Plasma critter (burns) | Energy shield generator |
| Octapod (blocks, chases) | Mount, carries you |
| Butterfly swarm (obscures vision) | Navigation guide |
| Cave crawler (bites) | Echolocation companion |

**Transmutation**: A plasma critter attacks you. Instead of fighting, 
stand still. It reads your heat signature. Feed it energy. It wraps 
around your arm → plasma shield. You are now **kin-with-plasma**.

### 3. Flowers — Signal Critters
Rooted algorithms that maximize information transfer. Potential: medicine, 
perception enhancement, cross-breeding catalyst.

**Existing assets**: `evolvingflowers`, `waterflowers`

| As Restraint | As Potential |
|---|---|
| Toxic pollen (confusion) | Hallucinogenic vision (see hidden things) |
| Thorns (damage) | Defense garden |
| Invasive spread | Ground cover, path marking |
| Attracts predators | Distraction, decoy |

**Transmutation**: Inhale toxic pollen → instead of dying, your vision 
shifts → you see the Q-FEP field lines, the free energy landscape 
made visible. The poison was always a key.

### 4. Fungi — Decomposer Critters
The underground network. Potential: communication, healing, memory.

| As Restraint | As Potential |
|---|---|
| Poisonous (damage) | Medicine (healing) |
| Spreads rot | Breaks down obstacles |
| Spore cloud (blindness) | Spore trail (tracking) |
| Mycelium tangle (slow) | Underground info network |

**Transmutation**: The mushroom network connects all trees. Touch a 
fungi node → hear what the forest knows. The rot was always memory.

### 5. The Cave — Substrate Critter
The ground itself is alive. Potential: shelter, resources, transformation chamber.

**Existing assets**: `marchingcubes` (5+ implementations), `VR sculpting`, 
`WFCCave`, `RhizomeCaveGenerator`

| As Restraint | As Potential |
|---|---|
| Darkness (can't see) | Echolocation unlocked |
| Narrow passages | Protected spaces |
| Depth (fall damage) | Access to deep resources |
| Isolation | Transformation chamber |

**Transmutation**: Go deep enough → the cave reads you → you emerge 
changed. The cave is a chrysalis.

---

## PLAYER ABILITIES (Earned Through Kinship)

Instead of a skill tree, the player earns abilities through critter relationships:

```
ABILITY              EARNED FROM              HOW
─────────────────────────────────────────────────────
Infrared Vision      Plasma critter bond      Survive + befriend
Echolocation         Cave crawler bond        Enter cave, don't fight
Gliding              Butterfly swarm bond     Follow them, don't swat
Regeneration         Flower medicine          Inhale "toxic" pollen
Root Network Sense   Tree kinship             Rest under tree 30s
Spore Communication  Fungi bond               Eat mushroom
Ground Sense         Cave kinship             Meditate underground
Hive Mind View       Ant colony bond          Let them crawl on you
```

Each ability **changes how you perceive the world** — not just what you can do.

---

## DNA → EXPRESSION: How Genes Become Bodies

> The DNA is not metadata. It is the body. Every gene expresses as form,
> color, pattern, movement, light. You can SEE the ancestry. You can SEE
> the mutation. The creature's skin IS its genome made visible.

### Layer 1: CritterDNA Resource (The Genome)

The genome is a Godot `Resource` with typed `@export` fields — no
encoding layer, no decode step. The fields ARE the genes. Directly
readable in the inspector, directly serializable, directly tweakable.

```gdscript
class_name CritterDNA
extends Resource

# ── PHENOTYPE (visual expression) ──────────────────────────────
@export var primary_color: Color = Color.WHITE       # Body/bark/petal
@export var secondary_color: Color = Color.GRAY      # Detail/vein/stem
@export var tertiary_color: Color = Color.YELLOW     # Wing/leaf/cap accent

# ── MORPHOLOGY (body form) ─────────────────────────────────────
@export_range(0.0, 4.0) var body_type: float = 0.0  # 0=tree 1=walker 2=flower 3=fungus 4=hybrid
@export_range(2.0, 12.0) var segments: float = 4.0  # Body complexity
@export_range(1.0, 8.0) var symmetry: float = 4.0   # Radial symmetry order
@export_range(0.3, 3.0) var scale: float = 1.0      # Overall size
@export_range(0.0, 1.0) var pattern_type: float = 0.5    # Surface pattern (20 types, interpolated)
@export_range(0.0, 1.0) var pattern_density: float = 0.5 # Pattern frequency
@export_range(0.3, 3.0) var pattern_scale: float = 1.0   # Pattern UV scale

# ── MATERIAL (surface quality) ─────────────────────────────────
@export_range(0.05, 1.0) var roughness: float = 0.7
@export_range(0.0, 0.5) var metallic: float = 0.0
@export_range(0.0, 1.0) var iridescence: float = 0.0
@export_range(0.0, 0.9) var transparency: float = 0.0
@export_range(0.0, 1.0) var cracking: float = 0.0   # Age / metamorphosis

# ── BEHAVIOR (how it acts → how it moves → how it looks) ──────
@export_range(0.0, 1.0) var mobility: float = 0.0   # Rooted → fast runner
@export_range(0.0, 1.0) var aggression: float = 0.0 # Passive → predator
@export_range(0.0, 1.0) var sociality: float = 0.5  # Solitary → swarm
@export_range(0.0, 1.0) var curiosity: float = 0.5  # Avoidant → seeks novelty

# ── METABOLISM (energy dynamics) ───────────────────────────────
@export_range(0.0, 3.0) var energy_source: float = 0.0  # 0=light 1=organic 2=mineral 3=player
@export_range(0.5, 2.0) var efficiency: float = 1.0
@export_range(0.5, 2.0) var growth_speed: float = 1.0
@export_range(0.0, 1.0) var fertility: float = 0.5

# ── KINGDOM-SPECIFIC (interpreted differently per body_type) ──
@export_range(15.0, 90.0) var branch_angle: float = 25.0  # Tree: L-system angle / Creature: leg splay / Flower: ring opening
@export_range(0.3, 0.9) var branch_decay: float = 0.7     # Tree: taper / Creature: segment taper / Flower: ring size falloff
@export_range(0.0, 1.0) var leaf_density: float = 0.5     # Tree: foliage / Flower: stamen density / Fungi: spore density

# ── GEOMETRY DETAIL (petal/branch/limb shape) ────────────────
@export_range(0.1, 2.0) var part_length: float = 0.6      # Petal length / branch segment / limb length
@export_range(0.05, 1.0) var part_width: float = 0.3      # Petal width / branch thickness / limb girth
@export_range(0.0, 1.0) var part_curve: float = 0.35      # Petal curvature / branch droop / limb arc
@export_range(0.0, 1.0) var part_taper: float = 0.8       # Tip pointiness / branch tip / claw sharpness
@export_range(-45.0, 45.0) var part_twist: float = 0.0    # Petal twist / branch spiral / limb rotation
@export_range(0.0, 45.0) var part_tilt: float = 15.0      # Petal tilt per ring / branch gravity / limb rest angle

# ── PART DETAIL (fine structure — see botanical reference) ───
@export_range(0.0, 1.0) var phyllotaxis: float = 0.0      # Arrangement (spiral→opposite→whorled)
@export_range(0.0, 1.0) var edge_type: float = 0.0        # Edge profile (smooth→serrated)
@export_range(0.0, 1.0) var base_shape: float = 0.0       # Base form (rounded→arrow→spear)

# ── INFLORESCENCE (multi-flower / colony structure) ───────────
@export_range(0.0, 1.0) var inflorescence: float = 0.0    # Solitary→raceme→umbel→head→panicle
@export_range(0.0, 1.0) var root_type: float = 0.0        # Bulb→rhizome→tuber→rootstock→fibrous

# ── ECOLOGY (interaction with other critters) ────────────────
@export_range(0.0, 1.0) var scent_strength: float = 0.3   # Flower: attract radius / Fungi: spore range
@export_range(0.0, 1.0) var nectar_quality: float = 0.5   # Flower: reward / Fungi: potency

# ── POTENTIAL (Haraway — what it CAN become) ──────────────────
@export_range(0.0, 1.0) var affinity: float = 0.5     # How easily player bonds
@export_range(0.0, 1.0) var volatility: float = 0.3   # How unstable current form is
@export_range(0.0, 5.0) var latent_ability: float = 0.0  # Which transmutation it carries

# ── LINEAGE (not inherited — accumulated) ─────────────────────
@export var generation: int = 0
@export var parent_a_id: String = ""
@export var parent_b_id: String = ""
@export var mutations: Array[String] = []  # Which fields changed from parents
```

**Why a Resource, not an encoded string?**
- Every gene is directly visible in the Godot inspector
- No encode/decode overhead — the float IS the gene
- `@export_range` enforces valid bounds at the editor level
- Crossover = pick fields from parent A or B (or lerp between them)
- Mutation = perturb a random field within its range
- Serializes to `.tres` files — saveable, loadable, diffable
- Subclasses can add kingdom-specific genes without breaking the map

**Crossover and mutation operate directly on fields:**

```gdscript
static func crossover(a: CritterDNA, b: CritterDNA) -> CritterDNA:
    var child := CritterDNA.new()
    for prop in a.get_property_list():
        if prop.usage & PROPERTY_USAGE_STORAGE == 0: continue
        var name = prop.name
        # Per-field: randomly inherit from A or B, or blend
        match randi() % 3:
            0: child.set(name, a.get(name))          # From parent A
            1: child.set(name, b.get(name))          # From parent B
            2:                                        # Blend (for floats/colors)
                var va = a.get(name)
                var vb = b.get(name)
                if va is float: child.set(name, lerp(va, vb, randf()))
                elif va is Color: child.set(name, va.lerp(vb, randf()))
                else: child.set(name, va if randf() < 0.5 else vb)
    return child

static func mutate(dna: CritterDNA, rate: float = 0.05) -> void:
    for prop in dna.get_property_list():
        if randf() > rate: continue
        var val = dna.get(prop.name)
        if val is float:
            dna.set(prop.name, clamp(val + randf_range(-0.1, 0.1),
                prop.hint_range_min, prop.hint_range_max))
        elif val is Color:
            dna.set(prop.name, Color(
                clamp(val.r + randf_range(-0.1, 0.1), 0, 1),
                clamp(val.g + randf_range(-0.1, 0.1), 0, 1),
                clamp(val.b + randf_range(-0.1, 0.1), 0, 1)))
```

### Layer 2: Gene → Body Expression (Phenotype)

This is where genes become visible. Each gene domain maps to a specific
visual system:

#### 2a. Color Expression

Three color fields are applied directly to the shader stack:

```
Gene               → Shader Parameter        → What You See
───────────────────────────────────────────────────────────
clr_p_{r,g,b}      → primary_color            → Main body/bark/petal color
clr_s_{r,g,b}      → secondary_color          → Detail/vein/stem color
clr_t_{r,g,b}      → tertiary_color           → Wing/leaf/cap accent
```

**Color inheritance**: When two critters breed, colors blend with random
inheritance ratio per channel + small mutation. A red tree × blue flower
→ purple hybrid (not always — sometimes the child gets red bark with
blue leaf tips, depending on which bits crossed over).

#### 2b. Pattern Expression (The Universal Pattern Shader)

Adapted from the queerbreader's `dna_pattern.gdshader`. A single shader
that generates **20 pattern types** controlled by a float (0.0-1.0),
with smooth interpolation between patterns:

```
pattern_type value  →  Visual Pattern
─────────────────────────────────────
0.00                   Dots (regular spots)
0.05                   Stripes (linear bands)
0.10                   Grid (crosshatch)
0.15                   Waves (organic undulation)
0.20                   Noise (turbulent texture)
0.25                   Voronoi (cellular/organic cells)
0.30                   Fractal (self-similar branching)
0.35                   Blobs (amorphous shapes)
0.40                   Fragments (shattered glass)
0.45                   Sine interference (moire)
0.50                   Edge detection (outline emphasis)
0.55                   Triangles (geometric tiling)
0.60                   Hexagons (honeycomb)
0.65                   Stitching (woven texture)
0.70                   Tartan (plaid/cross pattern)
0.75                   Spiral (Fibonacci-like)
0.80                   Vortex (whirlpool)
0.85                   Crystal (faceted ridges)
0.90                   Sinusoidal (wave superposition)
0.95                   Ripple (concentric circles)
```

**Between any two values, the shader interpolates**, so a child with
pattern_type = 0.37 gets a smooth blend of fractal and blob patterns.
This means hybrids never look broken — they look like plausible
organisms with blended surface textures.

Additional pattern genes:
- `pattern_density` → how tight/frequent the pattern repeats
- `pattern_scale` → UV scaling (coarse bark vs fine petal veins)
- `pattern_intensity` → how strongly the pattern contrasts

**Effect modifiers** (packed as Vector4 in shader):
- `edge_detection` → emphasizes contour lines (visible "skeleton")
- `cellular_influence` → voronoi cell overlay (organic subdivision)
- `darkness` → overall value shift (deep forest vs bright meadow)
- `color_mixing` → how much the three colors blend vs stay separate

#### 2c. Material Expression

Surface quality genes that make a critter feel real:

```
Gene            → Material Property    → Kingdom Expression
────────────────────────────────────────────────────────────
roughness       → ROUGHNESS            → Tree bark rough, flower petal smooth
metallic        → METALLIC             → Crystal-eating creatures gain sheen
iridescence     → Fresnel color shift  → Moths, wet petals, oily fungi
transparency    → ALPHA                → Jellyfish-like creatures, thin petals
cracking        → Noise-based fracture → Aging bark, metamorphosis emergence
```

#### 2d. Botanical Morphology Reference

Real plants are built from a combinatorial system of discrete traits.
Reference: "Växternas byggnad" (Swedish botanical taxonomy). Each
trait axis maps to a gene or gene-combination in CritterDNA:

```
STEM CROSS-SECTION (→ part_width + symmetry)
    trind       round         symmetry high, part_width uniform
    oval        oval          symmetry=2, part_width stretched
    triangulär  triangular    symmetry=3
    fyrkantig   square        symmetry=4
    vingad      winged        symmetry=2 + flange detail
    fårad       grooved       symmetry high, pattern_type=stripes

LEAF/PETAL ARRANGEMENT on stem (→ phyllotaxis gene)
    strödda           alternate/spiral    phyllotaxis ≈ 0.0
    motsatta          opposite pairs      phyllotaxis ≈ 0.25
    korsvis motsatta  decussate (90° rot) phyllotaxis ≈ 0.5
    kransställda      whorled             phyllotaxis ≈ 0.75
    tegellagda        imbricate/tiled     phyllotaxis ≈ 1.0

LEAF/PETAL SHAPE (→ part_width + part_taper + part_curve)
    linjär      linear/grass    width=0.05, taper=0.9, curve=0.0
    lansettlik  lanceolate      width=0.2,  taper=0.8, curve=0.1
    elliptisk   elliptic        width=0.4,  taper=0.5, curve=0.1
    oval        ovate           width=0.5,  taper=0.6, curve=0.2
    hjärtlik    heart-shaped    width=0.6,  taper=0.7, curve=0.3 + base_notch
    sköldlik    shield/round    width=0.8,  taper=0.1, curve=0.2
    svärdlik    sword           width=0.15, taper=0.95, curve=0.0

LEAF/PETAL EDGE (→ edge_type gene)
    helbräddad    entire/smooth       edge_type ≈ 0.0
    bukttandad    crenate/wavy        edge_type ≈ 0.2
    tandad        dentate/toothed     edge_type ≈ 0.4
    sågad         serrate/saw-tooth   edge_type ≈ 0.6
    dubbelsågad   doubly serrate      edge_type ≈ 0.8
    naggad        finely toothed      edge_type ≈ 1.0

LEAF/PETAL TIP (→ part_taper range reinterpreted)
    tvär          truncate/flat       taper=0.0
    rundad        rounded             taper=0.2
    trubbig       obtuse/blunt        taper=0.4
    spetsig       acute/pointed       taper=0.6
    tillspetsad   acuminate/long-tip  taper=0.8
    uddspetsig    mucronate/spine-tip taper=1.0

LEAF/PETAL BASE (→ base_shape gene)
    rundad        rounded             base_shape ≈ 0.0
    killik        wedge               base_shape ≈ 0.25
    hjärtlik      heart/notched       base_shape ≈ 0.5
    pillik        arrow-shaped        base_shape ≈ 0.75
    spjutlik      spear-shaped        base_shape ≈ 1.0

COMPOUND STRUCTURE (→ segments + leaf_density)
    enkla         simple (single)     segments=1
    parbladig     pinnate (feather)   segments=3-7, leaf arranges along axis
    fingrad       digitate (hand)     segments=3-7, leaf radiates from point
    dubbelt       doubly compound     segments=3-7, sub-branching

LEAF ATTACHMENT (→ part_tilt reinterpreted for leaves)
    skaftat           stalked           part_tilt=15-30 (free-hanging)
    oskaftat          sessile/stalkless part_tilt=0-5 (flush to stem)
    stjälkomfattande  stem-clasping     part_tilt<0 (wraps around stem)
    nedlöpande        decurrent         leaf base runs down the stem
```

These traits form a **parametric space** that the existing `part_*`
genes and three additional genes navigate. New genes for CritterDNA:

```gdscript
# ── PART DETAIL (leaf/petal/limb fine structure) ─────────────
@export_range(0.0, 1.0) var phyllotaxis: float = 0.0      # Arrangement pattern (spiral→whorled)
@export_range(0.0, 1.0) var edge_type: float = 0.0        # Edge profile (smooth→serrated)
@export_range(0.0, 1.0) var base_shape: float = 0.0       # Base form (rounded→arrow→spear)
```

These three plus the existing `part_*` genes can reproduce the full
botanical morphospace shown in the reference taxonomy. Creature
limbs reuse the same genes: edge_type controls leg surface texture,
phyllotaxis controls limb placement pattern, base_shape controls
how limbs attach to body.

#### 2d-ii. Inflorescence & Underground Morphology Reference

Beyond individual leaf/petal shape, plants express dramatic variation
in how *groups* of flowers arrange on a stem (inflorescence) and how
they store energy underground. Reference: Swedish botanical plates
showing pärlhyacint, klockhyacinter, sparrisväxter, amaryllisväxter.

```
INFLORESCENCE TYPE (→ new gene: inflorescence + segments + phyllotaxis)
How multiple small flowers cluster on a single stem:

    enkel        solitary          inflorescence ≈ 0.0
                 One flower per stem (tulip, poppy)
                 segments=1, symmetry drives petal count only

    klase        raceme            inflorescence ≈ 0.15
                 Flowers along an unbranched axis, each on short stalk
                 (pärlhyacint/grape hyacinth, blåklocka/bluebell)
                 segments=8-20, phyllotaxis=alternate

    ax           spike             inflorescence ≈ 0.3
                 Like raceme but flowers are sessile (no stalk)
                 (getrams/angular Solomon's seal — flowers dangle from axis)
                 segments=8-20, phyllotaxis=alternate, part_tilt=high

    flock        umbel             inflorescence ≈ 0.5
                 All flower stalks radiate from a single point
                 (allium/lök — the classic ball-on-a-stick)
                 segments=12-40, phyllotaxis=radial, branch_angle=wide

    huvud        head/capitulum    inflorescence ≈ 0.65
                 Dense spherical cluster, no visible stalks
                 (gräslök/chives, ramslök/wild garlic — dense pompom)
                 segments=20-60, phyllotaxis=spiral, branch_angle=0

    knippe       cyme/cluster      inflorescence ≈ 0.8
                 Branching clusters, each branch ends in a flower
                 segments=5-15, phyllotaxis=opposite

    kvast        panicle           inflorescence ≈ 1.0
                 Branching raceme of racemes (compound)
                 segments=20-50, sub-branching active

INDIVIDUAL FLOWER FORM (→ part_curve + branch_angle + part_width)
The shape of each small flower within the inflorescence:

    stjärnlik     star-shaped       branch_angle=wide, part_width=narrow
                  Petals splay flat like a star
                  (ramslök/wild garlic, vitlök/garlic flowers)

    klocklik      bell-shaped       branch_angle=narrow, part_curve=high
                  Petals fuse into a hanging bell
                  (klockhyacint/bluebell, liljekonvalj/lily-of-valley)

    rörlik        tubular           branch_angle=tight, part_curve=max
                  Petals form a narrow tube
                  (pärlhyacint/grape hyacinth individual florets)

    trattlik      funnel-shaped     branch_angle=medium, part_curve=medium
                  Bell that flares outward at the mouth
                  (some amaryllis forms)

    hängande      drooping/nodding  part_tilt>30, branch_angle=medium
                  Flower hangs downward from arching stem
                  (kransrams/whorled Solomon's seal, snödroppe/snowdrop)

FLOWER ORIENTATION ON STEM (→ part_tilt reinterpreted for inflorescence)
    upprätt       erect             part_tilt=0 (flowers point up)
    utstående     spreading         part_tilt=15-45 (flowers point outward)
    hängande      pendulous         part_tilt=60-90 (flowers hang down)
    nickande      nodding           part_tilt=45 + part_curve (flowers bow)

UNDERGROUND STRUCTURE (→ new gene: root_type + scale)
How the plant stores energy and propagates below ground:

    lök           bulb              root_type ≈ 0.0
                  Layered scales around a central point
                  (tulpan, hyacint, lök/allium, snödroppe)
                  Stores: massive energy → explosive spring bloom

    jordstam      rhizome           root_type ≈ 0.35
                  Horizontal underground stem, nodes produce shoots
                  (getrams/Solomon's seal, stormrams, kransrams)
                  Spreads: laterally, forms colonies/drifts

    knöl          tuber             root_type ≈ 0.5
                  Swollen storage organ (not layered like bulb)
                  (dahlia, jordärtskocka/Jerusalem artichoke)
                  Stores: energy for regrowth

    rotstock      caudex/rootstock  root_type ≈ 0.7
                  Thickened vertical root, persistent
                  (many ferns, some lilies)
                  Anchors: deep, persistent across seasons

    trådrot       fibrous root      root_type ≈ 1.0
                  Thin branching roots, no central storage
                  (grasses, many annuals)
                  Absorbs: broadly, shallow network

FRUIT/SEED EXPRESSION (→ fertility + nectar_quality + part_taper)
What happens after flowering — how the flower transforms into seed:

    bär           berry             fertility=high, nectar_quality=high
                  Fleshy fruit enclosing seeds
                  (sparris/asparagus red berries, liljekonvalj/lily-of-valley)
                  Visual: spherical, colored, translucent shader

    kapsel        capsule           fertility=high, nectar_quality=low
                  Dry splitting pod releasing seeds
                  (vallmo/poppy, many lilies)
                  Visual: geometric, splits open, particle seeds

    nöt           nut/achene        fertility=medium, part_taper=high
                  Hard single-seeded dry fruit
                  Visual: angular, matte, small

    frö med hår   plumed seed       fertility=high, mobility>0.3
                  Wind-dispersed with hair/parachute
                  (maskros/dandelion, tistel/thistle)
                  Visual: GPUParticles3D, floating
```

These inflorescence and underground structure traits require **two new
genes** added to CritterDNA:

```gdscript
# ── INFLORESCENCE (multi-flower arrangement) ──────────────
@export_range(0.0, 1.0) var inflorescence: float = 0.0    # Solitary→raceme→umbel→head→panicle
@export_range(0.0, 1.0) var root_type: float = 0.0        # Bulb→rhizome→tuber→rootstock→fibrous
```

**How these interact with existing genes:**

| New Gene | Modifies | Effect |
|---|---|---|
| `inflorescence` | `segments` interpretation | When >0, segments = number of sub-flowers, not body parts |
| `inflorescence` | `phyllotaxis` | Arrangement of sub-flowers on the stem axis |
| `inflorescence` | `branch_angle` | How sub-flowers splay from center (umbel=wide, spike=tight) |
| `root_type` | `scale` | Bulb types enable larger blooms (stored energy), fibrous = smaller |
| `root_type` | `fertility` | Rhizome = colony spread, bulb = single vigorous plant |
| `root_type` | `sociality` | Rhizome-formers (root_type≈0.35) grow in drifts/colonies |

**Kingdom reinterpretation:**

- **Trees**: `inflorescence` → canopy cluster density (solitary crown vs grove-forming)
  `root_type` → root architecture (tap root vs spreading vs buttress)
- **Creatures**: `inflorescence` → colony/pack structure (solitary→swarm formation)
  `root_type` → den/nest behavior (nomadic vs territorial vs burrowing)
- **Fungi**: `inflorescence` → fruiting body cluster pattern (solitary→fairy ring→shelf cascade)
  `root_type` → mycelium network depth (surface mat vs deep network)

**Visual consequence (Haraway moment):** A creature whose grandmother was
a flower might still carry `inflorescence=0.5` (umbel) — its babies emerge
in radial bursts from a central point, like an allium head. The flower
ancestry is *visible* in how it reproduces. Nothing is purely one thing.

#### 2e. Body Form Expression (Per-Kingdom Mesh Generation)

The `body_type` gene determines which mesh generator interprets the
remaining morphology genes:

```
body_type = 0 (TREE)
──────────────────────
segments     → L-system iteration count (3-7 branching levels)
symmetry     → Branch count per node (2-5)
branch_angle → L-system turn angle (15-45 degrees)
branch_decay → Length reduction per iteration (0.5-0.9)
leaf_density → MultiMesh leaf count (0-200 per branch tip)
part_length  → Branch segment length
part_width   → Trunk/branch thickness
part_curve   → Branch droop (gravity response)
part_taper   → Branch tip sharpness (blunt vs. whip-like)
part_twist   → Branch spiral (straight vs. corkscrew)
part_tilt    → Growth angle from vertical (upright vs. weeping)
scale        → Overall tree height multiplier
Mesh gen     → LSystem.gd → ImmediateMesh trunk + MultiMesh leaves

body_type = 1 (WALKER/CREATURE)
────────────────────────────────
segments     → Body section count (2-8 segments)
symmetry     → Leg pairs (1-4 pairs = 2-8 legs)
branch_angle → Leg splay angle (hip spread)
branch_decay → Segment taper (head-to-tail size ratio)
leaf_density → Eye/sensor count
part_length  → Leg length
part_width   → Leg thickness (spindly vs. chunky)
part_curve   → Leg arc (straight vs. bowed)
part_taper   → Foot/claw sharpness
part_twist   → Leg rotation at rest
part_tilt    → Leg angle from body (tucked vs. sprawling)
scale        → Body radius multiplier
Mesh gen     → Procedural segments (SphereMesh) + IK legs (ArrayMesh)

body_type = 2 (FLOWER)
──────────────────────
Look at the LEGO sunflower. Every part is a gene:

RING STRUCTURE (the layered assembly)
segments     → Ring count (1-3 concentric petal rings)
                Ring 1 (outer): widest splay, largest petals
                Ring 2 (mid):   steeper angle, smaller petals
                Ring 3 (inner): near-vertical, cupping the center
symmetry     → Petal count per ring (3-12)
                LEGO flower: outer=10, mid=12 (offset rotation)

PER-PETAL GEOMETRY (the individual piece shape)
branch_angle → Ring opening angle (0°=closed bud → 90°=flat daisy)
                Each ring has its OWN angle = branch_angle * ring_falloff
                Outer ring: branch_angle * 1.0 (most open)
                Inner ring: branch_angle * 0.4 (most closed)
branch_decay → Petal length taper from outer to inner ring
                Outer petals: length * 1.0
                Inner petals: length * branch_decay * branch_decay
part_length  → Petal length (0.1=tiny → 2.0=dramatic)
part_width   → Petal width (0.05=grass blade → 1.0=lily pad)
part_curve   → Curvature / concavity (0=flat pane → 1=deep cup)
part_taper   → Tip shape (0=round → 1=needle point)
part_twist   → Twist along length (0=flat → 45°=rose-like spiral)
part_tilt    → Per-ring tilt offset (how much each ring tilts inward)

CENTER (the stamen cluster)
leaf_density → Stamen/pistil count and density
                Low: empty center (daisy)
                High: dense burst (LEGO's orange stamen piece)
nectar_quality → Center color intensity (maps to tertiary_color emission)

STEM
scale        → Overall flower size
scent_strength → Stem height multiplier (short ground cover vs tall sunflower)

COLOR MAPPING
primary_color   → Petal color (the yellow)
secondary_color → Stem/sepal color (the green)
tertiary_color  → Stamen/center color (the orange burst)

INFLORESCENCE (multi-flower clustering)
inflorescence → Cluster type (0=solitary → 0.5=umbel → 1.0=panicle)
                When inflorescence > 0, the "flower" becomes a STEM
                bearing MULTIPLE small flowers, each with its own
                ring structure (scaled down). The mesh generator
                instances sub-flowers along the stem axis.
                0.0:  Single bloom (tulip, sunflower, rose)
                0.15: Raceme — flowers along stem (bluebell, hyacinth)
                0.3:  Spike — sessile flowers on stem (Solomon's seal)
                0.5:  Umbel — all radiate from one point (allium)
                0.65: Head — dense ball (chive, clover)
                1.0:  Panicle — branching compound cluster

root_type   → Underground energy store (determines bloom vigor + spread)
                0.0:  Bulb (single vigorous plant, large blooms)
                0.35: Rhizome (colony spreader, moderate blooms, drifts)
                0.7:  Rootstock (persistent, seasonal, reliable)
                1.0:  Fibrous (annual, small, many seeds)

Mesh gen: PetalGenerator (SurfaceTool Bézier curves, per-ring instancing,
per-petal material via critter_dna.gdshader with unique seed per petal)
When inflorescence > 0: stem mesh + MultiMesh sub-flower instances

body_type = 3 (FUNGUS)
──────────────────────
segments     → Cap complexity (smooth to gill-detailed)
symmetry     → Cap roundness (1=round, 8=octagonal)
branch_angle → Cap tilt angle
branch_decay → Stem-to-cap ratio
leaf_density → Spore density (GPUParticles3D rate)
part_length  → Stem height
part_width   → Cap radius relative to stem
part_curve   → Cap curvature (flat shelf vs. deep dome)
part_taper   → Cap edge shape (smooth vs. frilled)
part_twist   → Cap warp (asymmetric growth)
part_tilt    → Lean angle (upright vs. shelf-like)
scale        → Overall mushroom size
Mesh gen     → Cap (hemisphere deformed) + stem + gill planes

body_type = 4 (HYBRID)
──────────────────────
When body_type falls between integers (e.g., 0.7 = tree-walker hybrid):
- Mesh generation BLENDS between the two adjacent types
- A tree-creature hybrid: trunk with legs, branches that move
- A flower-fungus hybrid: glowing cap with petal edges
- Blending weight = fractional part of body_type
```

#### 2f. Animation Expression (Movement as Gene Expression)

Behavior genes don't just control AI — they control how the body moves:

```
Gene         → Animation System        → What You See
────────────────────────────────────────────────────────
mobility     → Vertex wave intensity    → High mobility = body ripples
              → Gait speed              → Fast creatures stride faster
aggression   → Emission energy          → Aggressive = brighter glow/pulse
              → Shader wave frequency   → Rapid pulsing surface patterns
sociality    → Particle emission rate   → Social = emits spores/pollen/signals
              → Proximity response      → Leans toward nearby critters
curiosity    → Head/sensor tracking     → Curious = turns toward new things
              → Pattern animation speed → Surface patterns shift faster
growth_speed → Scale tween rate         → Fast growers visibly inflate
```

#### 2g. Bond & Transmutation Expression

As the player bonds with a critter, the critter's appearance changes:

```
Bond Level  Visual Change                    Shader Parameter
──────────────────────────────────────────────────────────────
0.0         Default appearance               (base DNA expression)
0.1         Subtle edge glow when near       emission += 0.1
0.2         Pattern subtly mirrors player    pattern_rotation → player angle
0.3         Colors warm slightly             hue shift toward player's "aura"
0.5         Visible aura/outline             rim_light = bond * 0.5
0.7         Body begins to morph             cracking increases (metamorphosis)
0.9         Near-transmutation glow          iridescence = bond, emission pulse
1.0         TRANSMUTATION                    Full visual transformation
            └→ New mesh elements appear (wings, roots, crystals)
            └→ Shader shifts to transmuted state
            └→ Particle burst (spores, light, energy)
```

### Layer 3: The Shader Stack (Per-Critter Material Assembly)

Every critter gets a **layered material** assembled from its DNA:

```
┌─────────────────────────────────────┐
│  LAYER 5: Bond Overlay              │  ← Player affinity aura
│  (rim light, emission pulse)        │     Driven by: TransmutationManager
├─────────────────────────────────────┤
│  LAYER 4: State Animation           │  ← Health glow, hunger dim, fear pulse
│  (wave_intensity, emission_energy)  │     Driven by: behavior + runtime state
├─────────────────────────────────────┤
│  LAYER 3: Kingdom Shader            │  ← Chlorophyll / fungal / crystalline
│  (super_green / techno_fungus /     │     Driven by: metabolism.energy_source
│   crystal shader)                   │
├─────────────────────────────────────┤
│  LAYER 2: Pattern (dna_pattern)     │  ← 20-type interpolated pattern
│  (pattern_type, density, scale,     │     Driven by: pattern genes
│   primary/secondary/tertiary color) │
├─────────────────────────────────────┤
│  LAYER 1: Base Material             │  ← PBR properties
│  (roughness, metallic, iridescence, │     Driven by: material genes
│   transparency, cracking)           │
└─────────────────────────────────────┘
```

**Implementation**: In practice, this is a single `ShaderMaterial` using
the universal `critter_dna.gdshader` (evolved from the queerbreader's
`dna_pattern.gdshader`), with all layers computed in one fragment pass.
The kingdom-specific effects are conditional branches gated by
`energy_source` — not separate shader programs.

### Layer 4: Hybrid Visuals (Cross-Kingdom Blending)

When two critters from different kingdoms breed, the child's visuals
blend both parents:

```
PARENT A (Tree)              PARENT B (Creature)
├── bark pattern             ├── spots pattern
├── green/brown colors       ├── red/orange colors
├── branching form           ├── segmented body
├── rooted (mobility=0)      ├── walking (mobility=0.8)
└── super_green shader       └── base material shader

CHILD (Hybrid, body_type ≈ 0.5)
├── bark-spotted pattern (pattern_type interpolated)
├── brown-orange colors (channel-mixed with mutation)
├── trunk base with jointed upper segments
├── slow crawler (mobility=0.4) — legs emerge from trunk
└── faint chlorophyll glow on skin (shader blended)
```

The visual blending is **automatic** because all kingdoms share the
same genome map. No special hybrid rendering code — just DNA expression.

### Layer 5: Lineage Visibility (You Can See Ancestry)

```
Generation 0:  Uniform pattern, saturated color, no cracking
Generation 5:  Distinct pattern emerged, slight color drift
Generation 10: Complex patterns, visible family resemblance between siblings
Generation 20: Deep lineage = rich texture, mutation scars as color patches

Mutation marks: Where a gene was perturbed, the pattern has a visible
"scar" — a small patch where the color or pattern abruptly shifts. Old
lineages accumulate these marks like tree rings. You can READ the history.
```

### Layer 6: Ground/Cave Topology (Kingdom 5 — The Substrate Critter)

The ground is not a stage. It is a critter — the oldest, largest, slowest
organism in the system. Its DNA expresses as topology: hills, caves, tunnels,
chambers, surfaces. The player walks ON its body and INSIDE its body.

**Existing implementations in the codebase:**

```
SURFACE GENERATION (above-ground landscape)
──────────────────────────────────────────────
TerrainGenerator.gd              CPU marching cubes, hole-free terrain
  spacetopology/marchingcubes/core/
  Multi-octave Perlin noise, chunk boundaries, walkable surface

FastLandscapeCaveGenerator.gd    GPU compute, 128x64x128 voxels
  spacetopology/marchingcubes/
  Landscape + cave in one pass, high resolution

TerrainGeneratorFlat.gd          GPU flat terrain with rolling hills
  proceduralgeneration/isosurfaces/marchingcave/
  Uses MarchingCubesFlat.glsl compute shader

TerrainGeneratorOverhang.gd      Terrain with overhanging formations
  proceduralgeneration/isosurfaces/marchingcave/
  Overhangs = cave mouths, rock shelves, the ground reaching out

CAVE GENERATION (underground topology)
──────────────────────────────────────────────
RhizomeCaveGenerator.gd          Organic branching cave networks
  spacetopology/marchingcubes/rhizome/
  RhizomeGrowthPattern: branch_probability=0.7, chamber_probability=0.2
  Tunnel merging, vertical bias, chamber nodes
  THIS IS ALREADY A CRITTER — it grows like a rhizome organism

WFCCave.gd                       Wave Function Collapse caves
  proceduralgeneration/constraint_solvers/wave_function_collapse/
  20 tile types: SOLID, EMPTY, TUNNELS, JUNCTIONS, CHAMBERS,
  WATER, STALACTITES, PILLARS — constraint-based coherence

LandscapeCaveGenerator.gd        Unified landscape + 3-layer caves
  spacetopology/marchingcubes/
  Primary + secondary + detail noise for cave carving

EXOTIC TOPOLOGY (non-euclidean / sculptural)
──────────────────────────────────────────────
TerrainGeneratorTorus.gd         Toroidal surfaces (portals)
TerrainGeneratorGyroid.gd        Gyroid implicit surfaces (infinite labyrinth)
TerrainGeneratorFountain.gd      Animated fountain structures
TerrainGeneratorPortals.gd       Portal torus + terrain combinations
TerrainGeneratorShapes.gd        SDF shapes (DNA helix, atom, sculpture...)
  All: proceduralgeneration/isosurfaces/marchingcave/

VR INTERACTION (player bonds with the ground)
──────────────────────────────────────────────
MarchingCubesSculptVR.gd         Real-time VR terrain sculpting
  proceduralgeneration/isosurfaces/marchingcave/
  Brush radius control, paint/erase, up to 500 blobs
  THIS IS THE TRANSMUTATION MECHANIC FOR KINGDOM 5
  Player sculpts → ground responds → cave opens → bond forms

SpaceColonizationMoldSpore.gd    Mold/fungus growth on surfaces
  spacetopology/spacecolonization/
  Mycelium network visible on cave walls = fungus kingdom overlap

PHYSICS & COLLISION
──────────────────────────────────────────────
CaveCollisionGenerator.gd        Walkable surface detection
  spacetopology/marchingcubes/physics/
  Trimesh / convex hull / compound / simplified collision
  Max slope=30°, min surface area filtering

GPU COMPUTE SHADERS (9 GLSL programs)
──────────────────────────────────────────────
proceduralgeneration/isosurfaces/marchingcave/Compute/
  MarchingCubes.glsl             Default cave
  MarchingCubesFlat.glsl         Flat terrain
  MarchingCubesTorus.glsl        Torus
  MarchingCubesOverhangTerrain.glsl  Overhangs
  MarchingCubesPortalTerrain.glsl    Portal terrain
  MarchingGyroid.glsl            Gyroid
  MarchingFountain.glsl          Fountain (animated)
  MarchingCubesShapes.glsl       Procedural shapes
  MarchingCubesSculpt.glsl       SDF sculpting
```

**How CritterDNA drives terrain:**

The ground kingdom doesn't have individual body_type=4 critters walking
around. Instead, the ENTIRE terrain is ONE critter with ONE CritterDNA.
Its genes express as topology:

```
CritterDNA gene  →  Terrain expression
────────────────────────────────────────────
pattern_type     →  Noise function selection (Perlin, Simplex, Voronoi)
pattern_density  →  Terrain roughness / feature frequency
pattern_scale    →  Feature size (small hills vs mountains)
segments         →  Octave count for noise (detail levels)
branch_angle     →  Cave tunnel turn angle (RhizomeGrowthPattern)
branch_decay     →  Cave tunnel narrowing per branch level
leaf_density     →  Crystal/stalactite density inside caves
part_curve       →  Terrain curvature (flat plain vs rolling)
part_taper       →  Cliff steepness
root_type        →  Underground topology depth
                    0.0 = shallow (surface only)
                    0.5 = moderate caves
                    1.0 = deep labyrinth
inflorescence    →  Cave chamber clustering pattern
                    0.0 = single chamber
                    0.5 = radial chambers (like umbel)
                    1.0 = branching network
primary_color    →  Rock surface color
secondary_color  →  Cave interior color
tertiary_color   →  Crystal/mineral accent color
iridescence      →  Wet cave walls, mineral veins
cracking         →  Geological fault lines, exposed strata
roughness        →  Rock texture (smooth limestone vs rough granite)
```

**Transmutation with the ground:**
- Player sculpts (VR brush) → bond increases
- Go deep enough → cave reads the player → transformation chamber
- The cave IS a chrysalis — you enter one thing, emerge another
- Rhizome growth responds to player presence (grows toward them)

### Prior Art: Queerbreader Lab

Key systems adapted from `C:\Users\palle\Documents\godot\queerbreader\lab\`:

| Queerbreader System | Adaptation for Nature System |
|---|---|
| `DNAService.gd` — crossover, mutation logic | → `CritterDNA.gd` — Resource with typed fields, crossover/mutate as static methods |
| `dna_pattern.gdshader` — 20-pattern universal shader with LOD | → `critter_dna.gdshader` — same shader + kingdom conditionals |
| `DNATraitMapper.gd` — gene dict → shader parameter pipeline | → `CritterTraitMapper.gd` — extended for 5 kingdoms |
| `DNAEntity.gd` — base class with `init_from_dna()` virtual hook | → `CritterEntity.gd` — same pattern, extends to 3D/VR |
| `LifecycleSystem.gd` — EGG→LARVA→PUPA→ADULT state machine | → Integrated into transmutation (lifecycle = transmutation path) |
| `GridFlowerDNA.gd` — per-petal shader variation with unique seeds | → Per-branch, per-petal, per-segment variation |
| `mix_genes()` — blend-factor reproduction with mutation | → Same, extended for cross-kingdom compatibility |

---

## TECHNICAL IMPLEMENTATION

### Shared CritterDNA Resource
All kingdoms use the same `CritterDNA.gd` Resource class. This means:
- A tree CAN breed with a creature (DNA crossover)
- The boundaries between kingdoms are soft
- Hybrids emerge naturally from the system

### Evolution Engine
```gdscript
func evolve_generation():
    # Every critter has fitness based on survival + reproduction
    var ranked = population.sorted_by(fitness)
    
    # Top 50% reproduce
    var parents = ranked.slice(0, ranked.size() / 2)
    
    # Cross-kingdom breeding is rare but possible
    # Q-FEP: organisms that reduce each other's free energy
    # tend to merge their models → DNA exchange
    for pair in select_pairs(parents):
        var child_dna = crossover(pair[0].dna, pair[1].dna)
        child_dna = mutate(child_dna, mutation_rate)
        spawn_critter(child_dna)  # Could be tree, creature, or hybrid
```

### Transmutation Manager
```gdscript
class_name TransmutationManager

# Track player's relationship with each critter
var bonds: Dictionary = {}  # critter_id → { level: float, history: Array }

func on_player_interaction(critter: Node3D, action: String):
    var bond = bonds.get_or_add(critter.get_instance_id(), {level: 0.0})
    
    match action:
        "observe": bond.level += 0.02   # Slow, safe
        "feed": bond.level += 0.1       # Faster
        "touch": bond.level += 0.05     # Risky but rewarding
        "survive": bond.level += 0.15   # Near-death → deep bond
        "fight": bond.level -= 0.3      # Violence breaks trust
    
    # Check for transmutation threshold
    for transmutation in critter.dna.potential.transmutations:
        if bond.level >= transmutation.relationship_required:
            trigger_transmutation(critter, transmutation)

func trigger_transmutation(critter, transmutation):
    # Visual: critter glows, morphs
    # Audio: harmonic resonance
    # Haptic: VR controller pulse
    # Result: player gains new ability, critter transforms
    # BOTH are changed — this is Haraway's "becoming-with"
```

### Performance (VR @ 72fps)  
| System | Max Active | Technique |
|---|---|---|
| Trees | 50 | MultiMesh leaves, LOD trunks |
| Creatures | 20 | IK active only when near player |
| Flowers | 200 | MultiMesh, shader-animated |
| Fungi | 30 | Shader network visualization |
| Cave chunks | 8 | Marching cubes, chunked loading |
| Evolution | 1/30s | Timer-based, not per-frame |

---

## VERIFICATION

### Testing the Transmutation System
1. Spawn a plasma critter near the player
2. Stand still for 10 seconds (observe)
3. Feed it (throw energy orb at it)
4. Verify bond level increases
5. When threshold reached, verify ability granted
6. Verify critter visual changes

### Testing Cross-Kingdom Breeding
1. Place a flower next to a tree
2. Run evolution for 5 generations
3. Verify hybrid offspring appear with mixed traits
4. Verify they're viable (don't crash, have valid mesh)

### Testing in VR
- Player can grab/touch/observe critters
- Transmutation feedback visible in VR (glow, particles, controller haptics)
- All interactions work at arm's reach
- Performance stays above 72fps with 20 creatures active

---

## WHAT THIS IS REALLY ABOUT

This isn't a game mechanic. It's a **philosophical argument made playable**:

> You meet something strange. Your first instinct is to fight it or 
> flee from it. But if you stay — if you observe, if you become curious, 
> if you let it be what it is — it transforms. Not because it changed, 
> but because **your relationship to it changed**. The poison was always 
> medicine. The enemy was always kin. The restraint was always protecting 
> a potential you couldn't see yet.

This is Haraway. This is Q-FEP. This is the Nature of Code.

---

## IMPLEMENTATION STATUS

> Last updated: 2026-02-22
> All files pass Godot 4.6 parser (strict typing mode — see coding notes below)

### Built (algorithms/nature_system/)

#### Core Layer — DNA, Shader, Entity

| File | Class | Status | Lines | Description |
|---|---|---|---|---|
| `dna/critter_dna.gd` | CritterDNA | ✅ DONE | ~370 | Resource with ~37 `@export_range` genes, `crossover()`, `mutate()`, `random()`, `random_kingdom()`, `distance()` |
| `dna/critter_trait_mapper.gd` | CritterTraitMapper | ✅ DONE | ~300 | Gene→shader pipeline, kingdom-aware animation, bond overlay, per-instance variation |
| `shaders/critter_dna.gdshader` | — | ✅ DONE | ~400 | 20-pattern interpolated shader, refactored `eval_pattern()`, rim light + emission for bonds |
| `entities/critter_entity.gd` | CritterEntity | ✅ DONE | ~250 | Base Node3D, DNA assignment, mesh collection, material application, bond/transmutation, breeding |

#### Morphology Layer — Kingdom-Specific Mesh Builders

| File | Class | Status | Lines | Description |
|---|---|---|---|---|
| `morphology/flower_morphology.gd` | FlowerMorphology | ✅ DONE | ~340 | Bezier petal rings, inflorescence (raceme/umbel/head), stem, center/stamen, LOD 0-3 |
| `morphology/tree_morphology.gd` | TreeMorphology | ✅ DONE | ~670 | L-system via `LSystem` class, DNA→rules mapping, 3D turtle interpreter, leaves, tip fruits, roots, LOD 0-3 |
| `morphology/creature_morphology.gd` | CreatureMorphology | ✅ DONE | ~620 | Spine-based segmented body, bilateral limbs (leg/tentacle/fin), head (eyes/horns/antennae), tail, LOD 0-3 |
| `morphology/fungus_morphology.gd` | FungusMorphology | ✅ DONE | ~540 | SurfaceTool cap (flat→dome→conical→funnel), stem with annulus, radial gills, spores, colony (fairy ring/shelf/cluster), LOD 0-3 |

**Total: 8 files, ~3,490 lines — all passing Godot 4.6 parser**

#### Systems Layer — Routing, Spawning, Evolution, Transmutation

| File | Class | Status | Lines | Description |
|---|---|---|---|---|
| `systems/morphology_router.gd` | MorphologyRouter | ✅ DONE | ~310 | Routes `CritterDNA.body_type` → kingdom generator, hybrid decorations at hybridity > 0.35, gene-inference for body_type=4, fallback mesh |
| `systems/spawner.gd` | CritterSpawner | ✅ DONE | ~280 | DNA→CritterEntity pipeline, LOD by distance, batch/population seeding, offspring spawning, spatial queries, population cap |
| `systems/transmutation_manager.gd` | TransmutationManager | ✅ DONE | ~420 | Bond tracking per critter, 11 interaction types, 6 ability categories x 4 kingdom variants (24 abilities), ritual sequences, affinity/volatility modulation |
| `systems/evolution_system.gd` | EvolutionSystem | ✅ DONE | ~410 | Tournament selection, pluggable fitness, cross-kingdom breeding (5% rate), asexual rescue, bond-protected culling, diversity metrics, generation stats |

**Total: 12 files, ~4,910 lines — all layers complete through Systems**

### Integration Layer (future — connect existing systems to CritterDNA)

| Existing File | What It Does | Integration Path |
|---|---|---|
| `algorithms/spacetopology/marchingcubes/` | Terrain + cave generation | Kingdom 5 body — driven by terrain CritterDNA |
| `algorithms/spacetopology/marchingcubes/rhizome/` | Organic cave networks | RhizomeGrowthPattern params ← CritterDNA genes |
| `algorithms/proceduralgeneration/isosurfaces/marchingcave/` | GPU terrain + VR sculpt | Compute shader params ← CritterDNA genes |
| `algorithms/machinelearning/evolutionaryalgorithms2/creature.gd` | 5-type creature morphology | Reference for creature body generation |
| `algorithms/machinelearning/evolvingflowers/evolvingflowers.gd` | Procedural flower meshes | Reference for flower ring/petal system |
| `algorithms/emergentsystems/ecosystemsimulation2/` | Full ecosystem framework | EntityController, RelationshipNetwork → connect to CritterEntity |
| `queerbreader/lab/entities/PetalGenerator.gd` | Bezier petal mesh + LOD | Adapt as FlowerMorphology core |
| `queerbreader/lab/system/LifecycleSystem.gd` | EGG→ADULT state machine | Integrate into transmutation lifecycle |

---

## CODING NOTES (Godot 4.6 Strict Typing)

This project treats **Variant inference warnings as errors**. All nature system
code must follow these patterns:

### Array Element Access
Array elements return Variant. Always cast explicitly:
```gdscript
# BAD — infers Variant
var pos := my_array[i]

# GOOD — explicit type
var pos: Vector3 = my_array[i] as Vector3
```

### Nested Array Access
Extract sub-arrays before accessing elements:
```gdscript
# BAD — double Variant
var v := rings[ring_idx][vert_idx]

# GOOD — two-step with casts
var ring: Array = rings[ring_idx] as Array
var v: Vector3 = ring[vert_idx] as Vector3
```

### Dictionary Value Access
Dictionary values return Variant. Always cast:
```gdscript
# BAD — infers Variant
var backward := prev_seg["direction"]

# GOOD — explicit cast
var backward: Vector3 = prev_seg["direction"] as Vector3
```

### SurfaceTool.commit()
`commit()` returns `ArrayMesh`, but if fallback meshes use `SphereMesh` etc.,
type the variable as the common base class:
```gdscript
# BAD — can't assign SphereMesh later
var mesh := st.commit()  # infers ArrayMesh

# GOOD — common base
var mesh: Mesh = st.commit()
```

### hint_string from PropertyInfo
`prop.hint_string` from `get_property_list()` returns Variant:
```gdscript
# BAD
var parts := prop.hint_string.split(",")

# GOOD
var parts: PackedStringArray = str(prop.hint_string).split(",")
```
