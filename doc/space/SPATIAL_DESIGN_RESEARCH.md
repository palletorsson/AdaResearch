# Spatial Design Research for AdaResearch

Date: 2026-02-06

Research into spatial formulas from game level design, architecture, and small-scale/particle spatial solutions. All patterns are mapped to the AdaResearch grid-based map system.

---

## Part 1: Game Level Design Patterns

### 1) Portal -- The Isolation-Before-Combination Teaching Pattern

**Spatial Formula:**
```
SAFE ROOM (one mechanic, no fail state)
  -> PRACTICE ROOM (same mechanic, mild consequence)
    -> COMBINATION ROOM (mechanic A + previously learned mechanic B)
      -> MASTERY ROOM (A + B + spatial pressure / time pressure)
        -> EXIT to next mechanic cycle
```

**Technique:** Every new gameplay element is introduced in isolation before it gets combined with previously learned elements. The first encounter is always in a fail-proof environment. Valve calls this the "one new thing" principle: never introduce more than one unknown per room.

**Cognitive/Emotional effect:** Builds confidence before challenge. The learner develops a mental model of each mechanic individually, then experiences the satisfaction of combining known tools in novel ways.

**Application to AdaResearch:** The `WaveFunctions_Intro` map already follows this with its Static -> Y-oscillation -> Rotation -> Combined progression. To strengthen it, ensure each stage is spatially separated within the grid (walls between stages), so the learner must physically move to the next concept. Each map in a sequence should introduce exactly one new concept relative to the previous map, and the first encounter should be consequence-free.

---

### 2) Half-Life 2 -- The Invisible Guidance Toolkit

**Spatial Formula:**
```
ENTRY (constrained view, one visible landmark ahead)
  -> LEADING CORRIDOR (light gradient: dark behind, bright ahead)
    -> VISTA MOMENT (wide opening, framed view of destination landmark)
      -> CHOICE POINT (movement bait: NPC, physics object, or enemy draws eye)
        -> NARROW AGAIN (funnel toward next landmark)
```

**Techniques:**
1. **Light as path** -- Bright areas attract movement; dark areas repel. Warm light on correct path, cool light on environmental mood areas.
2. **Leading lines** -- Architecture elements (pipes, railings, floor markings, columns) form physical lines pointing toward destinations.
3. **Movement bait** -- Anything that moves in peripheral vision draws the eye.
4. **Vista framing** -- Constrain view with corridor, then open into wide space with destination visible. Contrast between constrained and open creates a "look here" moment.
5. **Sound as compass** -- Ambient sound sources emanate from specific locations; the player unconsciously orients toward audio cues.

**Cognitive/Emotional effect:** The player feels autonomous ("I figured out where to go") even though the environment is carefully designed. Control without feeling controlled.

**Application to AdaResearch:** Use lighting data for guidance within maps. Place teleporters along leading lines. Make each map's entry point have a vista showing the room's "headline artifact" from a distance before the learner reaches it. The waypoint (`wp`) system can be strengthened with light gradients -- cells behind the player dimmer, cells toward the waypoint brighter.

---

### 3) Dark Souls -- The Shortcut Loop and Vertical Fold

**Spatial Formula:**
```
SAFE HUB (bonfire / home base)
  -> LONG PATH (one-way forward, vertical ascent or descent)
    -> SMALL LOOPS (optional exploration branches that circle back)
      -> SHORTCUT DISCOVERY (elevator, door, ladder back to HUB)
        = "How did I get back here?!" moment
```

**Technique:** Vertical structure is the primary tool -- wind the player up or down through complex 3D space, then a single shortcut collapses all that distance back to the hub. At macro scale: hub -> area -> church -> hub. At level scale: large loops contain small loops, creating a fractal pattern.

**Cognitive/Emotional effect:** The shortcut discovery creates spatial comprehension -- the entire 3D space suddenly "clicks" in the player's mental model. Two locations they thought were far apart are actually adjacent.

**Application to AdaResearch:** Within a map, create paths that wind through the grid but reveal shortcuts. Between maps, the end of a sequence could return to earlier content viewed through new understanding. The `return_to: "lab"` field already supports this. The educational "how did I get back here?!" moment is "oh, THAT'S what that concept means!" -- revisiting earlier content with new understanding.

---

### 4) Journey -- The Weenie and the Compression/Expansion Cycle

**Spatial Formula:**
```
CONFINED ENTRY (small, limited vision, learn basic controls)
  -> EXPANSION (world opens dramatically, distant landmark visible)
    -> COMPRESSION (narrow passage, intimate, guided)
      -> GREATER EXPANSION (even bigger space, more freedom)
        -> COMPRESSION (tight, emotional, vulnerable)
          -> CLIMACTIC EXPANSION (peak moment, maximum scale)
```

**Technique:** Disney Imagineering's "weenie" concept -- a visual landmark always visible that pulls the player forward without instruction. The compression/expansion cycle creates a breathing rhythm. Each expansion feels larger than the last.

**Cognitive/Emotional effect:** The weenie prevents feeling lost while maintaining illusion of freedom. Compression/expansion creates oscillation between intimacy and awe, safety and vulnerability.

**Application to AdaResearch:** The Unit Circle map should be a dramatic expansion moment. Follow large maps with tighter, focused ones before expanding again. Within a map, place a tall/bright artifact at the far end visible from entry -- keep `max_height` tall on the destination artifact, entry area low, no walls blocking the sightline. The `Wavefunctions_Sky_Stairs` already suggests literal ascent to a vista.

---

### 5) Zelda: Breath of the Wild -- The Triangle Rule and Gravity Bowls

**Spatial Formula:**
```
GRAVITY BOWL (low-elevation area containing a point of interest)
  -> TRIANGULAR OBSTACLE (blocks sightline)
    -> CHOICE: climb over (effort + new vista) OR walk around (easier + surprise)
      -> NEW GRAVITY BOWL (next point of interest pulls player "downhill")
```

**Three sizes of triangles:**
1. **Large triangles (landmarks)** -- Visible from great distance, orientation beacons.
2. **Medium triangles (view blockers)** -- Create curiosity ("what's on the other side?") and binary choice: climb or walk around.
3. **Small triangles (tempo controllers)** -- Prevent holding forward in a straight line, keeping engagement through micro-decisions.

**The gravity principle:** Key locations are placed in topographical depressions (bowls/valleys), never on peaks. Players naturally "fall" toward important content.

**Cognitive/Emotional effect:** Constant micro-decisions prevent boredom. View-blocking creates perpetual curiosity. Gravity bowls ensure players feel like they're discovering rather than being led.

**Application to AdaResearch:** Use height values in the grid to create topographical variation -- place key artifacts in low areas (floor height 0), raised wall sections around them. For open-world-style sequences, make maps accessible non-linearly with each map being a "gravity bowl." The `prerequisites` field already supports this.

---

### 6) Super Mario -- Kishotenketsu (Four-Act Level Structure)

**Spatial Formula:**
```
Ki  (INTRODUCE):  Safe flat area. One new mechanic. No death possible.
Sho (DEVELOP):    Same mechanic, vertical dimension added. Safety net exists.
Ten (TWIST):      Unexpected combination or inversion. Safety net removed.
Ketsu (CONCLUDE): Full mastery demonstration. Speed increases. Reward at end.
```

**Technique:** From Japanese manga/poetry structure (four-line poetic form). The twist in act three forces the learner to revise their mental model -- this is when deep learning happens.

**Cognitive/Emotional effect:** Complete emotional arc within a single level: curiosity -> growing confidence -> surprise and reframing -> triumph.

**Application to AdaResearch:** Primary template for individual map design. For `WaveFunctions_Intro`:
- **Ki zone** (rows 0-4): Static cube + oscillating cube. Safe. Flat. Interact at own pace.
- **Sho zone** (rows 5-9): Rotating cube demo, vertical dimension. Same concept, more complex.
- **Ten zone** (rows 10-15): Pendulum controlling cube -- TWIST: oscillation generated by gravity instead of pure math.
- **Ketsu zone** (rows 16-21): Spherical harmonics + teleporter exit -- full synthesis.

---

### 7) Dead Space -- The Diegetic Breadcrumb and Hub-and-Spoke

**Spatial Formula:**
```
HUB (safe room with save point)
  -> SPOKE CORRIDOR (linear, narrowing, atmosphere building)
    -> TASK ROOM (objective, tension peaks)
      -> RETURN PATH (same spoke, now altered)
        -> HUB (relief, restock)
          -> NEXT SPOKE (new section)
```

**Technique:** Diegetic guidance system -- a blue light trail in the game world (no UI overlay). Hub-and-spoke topology with distinct sections. Previously safe corridors transform after story beats, forcing re-evaluation of familiar space.

**Cognitive/Emotional effect:** Never truly lost while maintaining immersion. Hub provides reliable mental model. Corruption of safe spaces forces heightened attention on return.

**Application to AdaResearch:** Lab = hub; each sequence = spoke. Implement diegetic breadcrumbs via glowing floor tiles or particle trails toward next learning objective. When learner returns to lab after completing a sequence, the lab should be subtly different -- new doors open, new artifacts visible. The `lab_map: "Lab/map_data_post_wavefunctions"` field already supports this.

---

### 8) Doom (2016/Eternal) -- The Arena Lock-In and Resource Circuit

**Spatial Formula:**
```
EXPLORATION CORRIDOR (calm, secrets, collectibles)
  -> ARENA ENTRANCE (one-way door locks behind)
    -> COMBAT ARENA (multi-level, asymmetric, vertical layers)
    -> ARENA EXIT (rewards, upgrade station)
      -> EXPLORATION CORRIDOR (decompression)
```

**Technique:** Arenas are asymmetrical with 2-3 vertical layers. "Push-forward" philosophy: every mechanic that would slow the player or encourage retreating was removed. Health comes from engagement, not avoidance.

**Cognitive/Emotional effect:** Lock-in creates commitment. Resource loop prevents passivity. Push-forward produces flow state. Exploration corridors provide decompression.

**Application to AdaResearch:** Challenge rooms where exit is locked until the learner demonstrates understanding. The "resource circuit" translates to: actively apply knowledge (not just observe) to progress. The corridor/arena/corridor rhythm maps to sequence pacing: calm observation maps alternating with active challenge maps.

---

## Part 2: Architectural Spatial Design Patterns

### Le Corbusier's Promenade Architecturale

Transitions between spaces should never be empty -- the ramp/corridor IS the experience. Culminate each sequence in a "roof garden" -- an elevated panoramic view of everything covered.

### Gothic Compression-Release

Narrow corridors (1-2 cells wide) opening into tall chambers. Research suggests high ceilings promote abstract thinking; low ceilings promote focused detail work.

### Carlo Scarpa's Thresholds

At every boundary between content domains, design a visible transition: floor material change, light shift, audio transition. The threshold is the most carefully designed element.

### Frank Lloyd Wright's Central Anchor

Every space needs a spatial "hearth" the learner can orient from. You always know where home is.

### Museum Design's 3-1-3 Rhythm

For every 3 content-dense maps, insert 1 breathing map (ambient, reflective, minimal artifacts).

---

## Part 3: Particle-Level Spatial Solutions (3x3, 5x5, 7x7 grids)

### From Japanese Gardens (Tsuboniwa)

Traditional courtyard gardens are 1.8-3.3 square meters. They create perceived depth using **three-layer composition** (foreground/midground/background) even in tiny footprints.

- **Forced perspective** -- larger/brighter artifacts near viewer, smaller/subtler ones farther away, along the diagonal. A 3x3 grid feels like a 5x5.
- **Borrowed scenery (shakkei)** -- what's visible beyond the grid boundary (skybox, distant environment) is part of the composition. The room doesn't end at the grid edge.

### From Single-Room Games

- **12 Minutes** -- constraint generates focus. A 3x3 grid is a focusing lens where every artifact is visible, holdable in working memory, and comparable to every neighbor.
- **Obra Dinn's lateral information** -- understanding artifact A requires examining artifact B. Design cross-references between cells. Physical space is small but information network is deep.
- **Papers Please's desk-as-world** -- every square centimeter serves a mechanical function. Zero filler in small grids.

### From VR Ergonomics

- A 3x3 grid at 1m cell spacing = 3m x 3m room -- matches the VR comfort zone almost perfectly.
- Center artifact at ~1.5m from user is in the sweet spot.
- Content should be 0.75-10m from viewer.
- Interactive artifacts at waist-to-chest height.
- **30-degree cone rule** -- primary content within 30 degrees off-center (60 degrees total). Peripheral content up to 80 degrees per side.

### From Diorama/Vignette Design

- **Three-plane composition** -- foreground (primary), midground (context), background (atmosphere). Use atmospheric haze between planes.
- **Vignette staging over taxonomy** -- don't arrange by category, arrange by narrative. A sine wave artifact + frequency artifact + speaker artifact form a *scene*, not a shelf.
- **Negative space is intentional** -- in a 3x3 grid, one empty cell = 11% of total space. That's a design choice, not waste.

### From Board Games

- **Relationships > objects** -- a 3x3 grid has 9 cells but up to 36 adjacency relationships (including diagonals). Design the relationships, not just the placements.
- Adjacency = related concepts. Diagonal = contrasting concepts. Empty = breathing room.
- **Rule of thirds** -- in a 3x3 grid, the four corner cells are the rule-of-thirds intersection points. Place the hero artifact off-center for visual tension.

---

## Part 4: Concrete Grid Formulas

### Particle Formula: 3x3 Map
```
[context]  [      ]  [contrast]
[      ]   [ANCHOR]  [      ]
[entry]    [tool]    [exit]
```
- Center = anchor artifact (the main concept)
- Entry corner = arrival + orientation
- Exit corner = progression
- Opposite corners = context and contrast (why it matters, what it's not)
- Empty cells = breathing room / borrowed scenery views
- Tool cell = interactive manipulation of the anchor concept

### Particle Formula: 5x5 Map
```
[      ]  [context]  [      ]  [preview]  [      ]
[entry]   [intro ]   [      ]  [develop]  [      ]
[      ]  [      ]   [ANCHOR]  [      ]   [      ]
[      ]  [reflect]  [      ]  [twist ]   [exit  ]
[      ]  [      ]   [      ]  [      ]   [      ]
```
- Follows kishotenketsu in a spiral around the center anchor
- Empty cells create Japanese garden "ma" (negative space)
- Diagonal flow from entry (row 1, col 0) to exit (row 3, col 4)

### Standard Map Template (combining all game patterns)
```
Row 0-2:   ENTRY (Ki) -- Confined. One artifact. Safe. Well-lit.
           Tall "weenie" artifact visible through gap at far end.

Row 3-5:   VIEW BLOCKER -- Partial walls (BotW triangles). Path curves.

Row 6-10:  DEVELOPMENT (Sho) -- Opens wider. Same concept, more complex.
           Light gradient brightens toward center.
           Small exploration branch loops back (Dark Souls small loop).

Row 11-13: COMPRESSION -- Narrow corridor. Sound changes. Threshold moment (Scarpa).

Row 14-18: TWIST (Ten) -- Largest space in the map. Unexpected combination.
           Multiple interactive artifacts distributed spatially (Doom arena).
           Learner must engage actively, not just observe.

Row 19-21: CONCLUSION (Ketsu) -- Narrows toward exit. Synthesis artifact.
           Teleporter to next map.
           The "weenie" from entry is now behind you, recontextualized.
```

---

## Part 5: Cross-Scale Application Matrix

### At the SEQUENCE level (10-20 maps):

| Pattern | Application |
|---|---|
| Journey compression/expansion | Alternate map sizes: small intro -> medium -> LARGE experience -> small focused -> LARGE synthesis |
| Dark Souls loop | Learner returns to lab hub with new capabilities; lab changes post-completion |
| Dead Space hub-and-spoke | Lab = hub, each topic sequence = spoke, tram = sequence selector |
| BotW gravity bowls | Sequences accessible non-linearly where prerequisites allow; each entry feels like arriving somewhere interesting |
| Museum 3-1-3 | For every 3 content-dense maps, 1 breathing map |

### At the INDIVIDUAL MAP level (single grid room):

| Pattern | Application |
|---|---|
| Mario kishotenketsu | Four spatial zones: introduce -> develop -> twist -> conclude |
| Portal isolation | Each zone introduces exactly one new element; first zone is fail-safe |
| Half-Life 2 guidance | Light gradients, leading lines, artifact "weenies" visible from entry |
| Doom arena | Challenge rooms lock learner in until they demonstrate understanding |
| Gothic compression-release | Narrow corridors opening into tall chambers |
| Scarpa thresholds | Visible transitions between content domains |

### At the PARTICLE level (3x3 to 7x7 grids):

| Pattern | Application |
|---|---|
| Tsuboniwa three-layer | Foreground/midground/background even in tiny footprints |
| Forced perspective | Larger near, smaller far, along diagonal |
| Borrowed scenery | Skybox and distant environment are part of composition |
| Obra Dinn cross-reference | Understanding A requires examining B |
| Zero filler | Every cell serves a function or is intentionally empty |
| Adjacency relationships | Design the connections between cells, not just the placements |

---

## Key Insight

At the particle level, every cell must do double duty, relationships between cells matter more than individual placements, and depth is perceptual (created through layering, perspective, and borrowed scenery) rather than physical.
