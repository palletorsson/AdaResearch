# Primitives Sequence Playthrough
**Date:** 2026-02-11
**Sequence:** primitives (from `commons/maps/sequences/primitives.json`)

---

## 🌙 Map 1: Point_One — *"that which has no part"*

I arrive. The system moves me immediately — `m:0:3:-0.5:0.1` — a tiny nudge, a tenth of a second, like being placed rather than entering. I didn't walk here. I was *instantiated*.

**The space:** An L-shaped platform of white cubes floats in a deep blue sky. Seven columns wide, but only the western three are solid — columns 0, 1, 2 form a runway stretching south. Most of the grid is void. One isolated block sits at position (4,0), disconnected from everything — an annotation board showing the map name and description. The tiles are initially hidden except at the corners; the space reveals itself as I move. I'm arriving in a world that doesn't fully exist yet.

**What I see looking forward (south):**

At my feet (0,0): an **origin marker**, rotated 180°, sunk half a unit below the floor. The origin is literally *beneath* me. I'm standing on zero.

To my left (0,0), at eye level: a **folding past** — nested rectangular frames collapsing inward like an accordion, time compressing into the present. Ten wireframe rectangles cycling from outer to inner every 4 seconds, each 85% the size of the last. It's a visual metronome. Time is folding behind me as I stand here.

Directly beside me at (0,1), elevated: the **script runner**, running the `point` script. I watch it type itself into existence:

```
# The Point as Data
var point = Vector3(1.0, 0.5, 0.0)

# Access the x component
print(point.x)    → 1.0
print(point.y)    → 0.5  
print(point.z)    → 0.0

# Move the point
point = Vector3(0.0, 1.5, 0.5)

# Add two vectors
var offset = Vector3(0.5, 0.0, 0.0)
point = point + offset

# The point has no size
# It's just numbers in memory
```

The code executes line by line, results appearing in real time. Then it clears and starts over. An infinite loop of demonstration. The point is defined, accessed, moved, added to — and then erased. *"It's just numbers in memory."*

A subtitle flashes: **"Point Zero? Point One."**

At (3,2): a **dark sphere** — a large black dome casting ambient darkness over the eastern void. The platform drops into shadow. The point exists; the space around it does not.

At (1,3), elevated on the platform: the **interactive point origin**. A tiny white sphere, 5cm radius, glowing with emission energy 2.5. I can grab it. When I pick it up, it draws a thin cyan line (0.003 width) back to Vector3(0,0,0) — the origin I'm standing above. The controller pulses once (0.5 intensity, 100ms). I am holding *position itself*, and a thread connects it to where everything starts. Wherever I move my hand, the line follows — a tether to zero.

Further south at row 5: the **teleporter** at (1,5). The exit. A gap in the platform — column 1 is void here, columns 0 and 2 frame it like a doorway.

And past the platform, floating in the blue void at row 8: **"that which has no part"** — Euclid's definition of a point, rendered as 3D text, hovering over nothing.

At the far edges of the world: a **frame counter display** at (0,9) — showing me the engine's heartbeat, frames ticking — and at (6,9), a **3-meter coordinate system** floating in the void. X, Y, Z axes. The scaffolding that makes the point possible. The infrastructure the point depends on but doesn't acknowledge.

**The experience:** This map is small and quick (3-4 minutes). It isolates one idea: *a point is position without extension*. The script runner shows me the code. The grabbable sphere lets me hold the idea physically. The line to origin reminds me that position is always *relative to something*. The folding past suggests that even this moment is collapsing. And Euclid's definition floats in void — "that which has no part" — a definition from 300 BC that still governs how the GPU thinks.

The tiles revealing themselves as I walk — that's the generative play. The world doesn't fully exist until I move through it.

---

## 🌙 Map 2: Point_Lines — *"The line measures because it has no room to escape comparison."*

I spawn at (0,0), high up — 5.5 units above the grid. The platform stretches below me, wider than before: 7 columns across, 21 rows deep. This is no longer a meditation on a single point. This is infrastructure.

An annotation board sits detached at (6,0), rotated to face me. The map's name and description: *"Multiplies lines into context: parallels, crossings, and grids... where discrete relations begin to behave as a network rather than a sequence."*

Again the tiles are hidden except at corners — the space reveals itself as I walk. But there's more ground to reveal this time.

**The Northern Plateau (rows 0–5):**

I descend to the platform. At (3,3): a **line demo** — the basic artifact, showing what a line *is* between two snap points. The simplest possible connection. Two positions, one relationship.

**The Canyon (rows 6–7):**

The floor drops — or rather, *rises*. Rows 6 and 7 are **4 cubes high** except for the central column (3), which stays at 1. I'm walking through a canyon. Towering walls on both sides, a single-tile path down the middle.

On the western wall at (1,6), sunk half a unit into the platform: **Le Corbusier's Modulor Man**. A human figure drawn as a single continuous line — left foot up through the legs, torso, arms, head, and back down. Every proportion derived from the golden ratio: 1.83m standing height, 2.26m with raised arm, navel at 1.13m (the golden section of 183cm), shoulder width exactly one quarter of height. The body as measurement system. The body as *line*.

On the eastern wall at (5,6), half-scale: a **Line Builder 3D** — a tool for drawing curves in space. Each line segment becomes a building block for wave forms. Connect points to see how discrete positions approximate continuous curves. The Modulor Man is the *body* measured by lines; the Line Builder is lines *freed* from the body.

**The Workshop (rows 8–12):**

I emerge from the canyon into a broad workspace. Two puzzles wait at row 10, elevated 1.2 units on pedestals:

At (2,10): a **Plus Line Puzzle** — drag endpoints to form a perpendicular cross. Below it at (2,11): a cube marked `#group:plusfillhole`. When I solve the puzzle, the cube disappears — the solution removes matter from the world.

At (4,10): a **Parallel Line Puzzle** — two lines with four draggable vertices. I need to align them parallel. Four target positions form two vertical lines side by side, 0.2 units apart. When all endpoints snap correctly and the parallel constraint is satisfied: *"Parallel Complete! Lines aligned."* Its companion cube at (4,11) also vanishes on success.

These puzzles teach relationships *between* lines — perpendicularity and parallelism — through physical manipulation. And solving them erases cubes. Knowledge removes obstacles.

At (3,12): a **dark sphere**. Shadow swallows the center of the workshop.

**The Measurement Gallery (rows 13–15):**

Three rows, each a station. The pattern repeats three times, getting smaller:

Row 13: a **cube at 0.6 scale**, a **grabbable line**, and a **laser measure** — a handheld distance tool with an LCD display. On the far edge: a **laser exploding sphere** elevated 2 units — a target I can shoot and watch burst into 40 particles with procedural explosion sound.

Row 14: the same, but the cube is **0.4 scale**. Smaller.

Row 15: the cube shrinks to **0.2 scale**. The line and laser measure repeat.

The lines let me physically measure the distance between two points — I grab both ends, stretch them, and a live distance reading appears. The laser measure confirms it numerically. The cubes shrink to give me different scales to measure *against*. And the exploding spheres? Target practice. A reward for pointing the laser — the line as weapon, the line as tool, the line as *distance that speaks of separation*.

A subtitle fires at row 16: **"The line measures because it has no room to escape comparison."**

**The Southern Vista (rows 17–24):**

The platform continues south. At row 19, position (5,19): the **teleporter**. But there's more beyond it — content you pass on your way.

At row 21, flanking the path: two sets of **perspective lines** at (1,21) and (5,21), elevated 2 units. Four lines each, converging from a rectangular frame to a vanishing point at the origin. Pink-red lines tracing the geometry of perspective — how parallel lines in 3D space appear to meet at infinity. Between them at (3,21): **scale lines** elevated 3 units — a vertical stack of horizontal lines at different measurements:

- 100m line at the top (red, thick)  
- 10m (orange)  
- 1m (yellow)  
- 10cm (green)  
- 1mm at the bottom (purple, hair-thin)

Five orders of magnitude made visible. The line as ruler across scales.

At the very bottom: **4 light rods** at (3,23) — glowing blue vertical pillars, 1 meter apart. And at (6,24): a **Dürer Grid** — a 5×5 standing perspective frame inspired by Albrecht Dürer's drawing machines. The grid that turns seeing into measurement. The grid that turns space into addresses.

Floating in the void at row 23: **"lines"** — 3D text, just the word itself.

**The experience:**

Point_One gave me a single position. Point_Lines multiplies it. Two points make a line; lines make parallels, perpendiculars, grids, perspectives, measurements. The Modulor Man says the body *is* a system of lines. The scale lines say measurement spans from millimeters to 100 meters. The perspective lines say parallel lines lie about meeting. The puzzles say relationships between lines (parallel, perpendicular) are things you can physically drag into being. The laser measure and exploding spheres say the line's first gift is *distance* — and distance can be a tool or a weapon.

The canyon at rows 6-7 is the spatial climax — four cubes high, forcing me through a slot one tile wide. Lines as walls. Lines as constraint.

---

## 🌙 Map 3: Point_Trace — *"There is no original behind the trace"*

The sky is almost black — `Color(0.05, 0.05, 0.1)`. Not the deep blue of the first two maps. Near-darkness. I'm moved on arrival — nudged one unit south and half a unit down — placed into the space like a pen touching paper.

The annotation board sits detached at (6,0). *"The Trace introduces duration and embodied residue into geometry... traces accumulate over time as records of movement... geometry as a lived process rather than a static system."*

**The space is small.** 7 columns wide, 14 rows. After the sprawling workshop of Point_Lines, this is a compression. Intimate. The platform is mostly flat — single-height cubes — except for row 5, where columns 1-2 and 4-5 rise to height 2 while the center column stays at 1, creating a low ridge with a gap. A threshold.

**What matters is at the center.**

At (3,3): a **dark sphere**. Darkness pools around the middle of the platform.

At (3,4), elevated 1 unit, right at the ridge: a **draw_dot** — configured with `#fillhole:remove`. This is the map's core artifact and its puzzle.

The draw_dot is a **drawing tool**. I grab a small sphere and move my hand through space. As I move, it records my position every centimeter and draws a glowing pink-magenta trail behind me — an ImmediateMesh rendered as LINE_STRIP, set as top-level so the trail stays in world space. Up to 1024 points of accumulated gesture.

While I draw, a **data table** appears near the trail's starting point — a Label3D flat on the ground showing:

```
TRACE DATA
─────────────────
Points: 47  Length: 1.83 m
─────────────────
LAST 10 POSITIONS
 1: (1.22, 1.45, 3.08)
 2: (1.24, 1.47, 3.12)
...
```

My gesture, quantized. Every position I pass through, frozen into a Vector3 and listed.

A **progress bar** floats above the trail's starting point. As I accumulate 6 meters of total drawing movement, it fills. When it reaches 100%: a synthesized *ding* — a 1200Hz sine with a 2400Hz harmonic, decaying over half a second. Then the draw_dot triggers `shrink_and_remove` on the tag `fillhole`.

At (3,5), directly below: a **cube** tagged `#group:fillhole`. When I draw enough — 6 meters of movement — the cube *vanishes*. My gesture erased geometry. The trace *consumed* a piece of the world.

A small reference frame hovers near the draw sphere while I hold it — a wireframe rectangle with a horizon line, 0.5 units wide. Like the viewfinder of a camera.

When I drop the sphere, the trail data is saved to TraceData (a global singleton). The space remembers what my hand did.

**Past the ridge (rows 6–10):**

At row 8, column 5: a subtitle triggers.

**"There is no original behind the trace — only encodings at different scales, each erasing differently, each affording differently, none closer to the real.."**

At (5,10): the **teleporter**. And floating in the void at row 13: **"the_trace"** — 3D text, white on near-black.

**The experience:** This map does one thing and does it fully. The draw_dot is the most physically intimate artifact yet. I move my hand, and a glowing trail follows. The data table narrates this in cold coordinates. The progress bar gamifies it — draw 6 meters and you unlock something. But what I'm really doing is *making the trace visible as a trace*.

The fillhole mechanic is clever: my drawing doesn't *create* something. It *removes* something. The trace is destructive. Gesture consumes the grid.

The near-black sky makes the magenta trail luminous. I'm drawing light in darkness.

---

## 🌙 Map 4: Point_Triangle — *"Everything triangle"*

The blue sky returns. And for the first time: **music**. The `fractal_exploration` preset hums beneath everything — a low Moog Minimoog bass drone at -20dB, and every 12-35 seconds, a random tone surfaces: a Korg M1 piano note or a PPG Wave metallic shimmer.

The map is compact: 7 wide, 9 deep. The ideas are concentrating.

**The Amphitheater (rows 3–4):**

Row 3: columns 0-1 and 5-6 rise to height 2, creating low walls on either side. A sunken stage.

At (3,3), elevated 1.2 units: a **triangle line puzzle** configured with `#fillhole:remove`. Three separate lines float in front of me. Three target vertices form an equilateral triangle (~40cm sides). I grab each endpoint and drag it to a target. The constraint requires **CONNECTED + CLOSED_LOOP**. When the loop closes: *"Triangle Complete!"*

Success removes a cube at (3,5). Solving the triangle puzzle erases it.

At (3,4): the **dark sphere**.

**The Exhibition (rows 5–8):**

At (3,6), elevated 1.2 units: an **interactive triangle**. Deep pink with dark violet wireframe. Three green grabbable spheres mark the vertices — I can pick up any corner and drag it through space. The triangle mesh updates in real time.

This is fundamentally different from the puzzle. The puzzle asked me to *construct*. The interactive triangle lets me *destroy* — pulling a perfect equilateral into whatever shape my hand makes.

At (3,7), elevated 2 units: **triangle profiles** — a folded zigzag surface built from 32 segments. What happens when you *repeat* the triangle — a single surface becomes a corrugated landscape.

The teleporter at (3,7) is placed in a void — the exit is literally a hole.

Floating below: **"Everything triangle"**

**The experience:** Three points. That's all it takes to close a boundary and produce a surface. The puzzle-then-manipulator sequence: first I build (analysis → synthesis), then I deform (synthesis → play), then the profiles show repetition (play → pattern).

---

## 🌙 Map 5: Point_Triangle_Context — *"Triangle everything"*

The Context map: after a focused encounter, the gallery — more objects, more variations, a survey.

**The Eastern Wall (rows 0–2):**

Column 6 rises to height 2. At (6,1): a **folded strip** — 24 triangles as folded paper, 4 meters long. Green and red faces alternate. Triangles as material. Paper folds.

**The Drawing Station (row 3):**

At (3,3): **draw_triangle_faces**. The draw_dot's evolution. Instead of tracing a line, I'm *placing points and closing loops to create triangle faces*. Each closed loop produces a colored triangle — pink, blue, green, yellow, purple cycling. I'm *building a mesh by hand*, triangle by triangle.

**The Workshop Row (row 6):**

Five artifacts on an elevated shelf:

- **(1,6):** Interactive triangle — pink/black faces, three drag spheres
- **(2,6):** Pythagorean triangle with angles — right triangle with squares on each edge (a² + b² = c²), angle arcs, live measurement labels. Draggable vertices update everything.
- **(4,6):** Quad line puzzle with `#fillhole:remove` — four lines, form a square
- **(5,6):** Interactive quad — four draggable corners, mesh split into two triangles with **bi-reflection** (deep pink/cyan front, black/gold back). The quad is two triangles sharing an edge.

The fillhole cube at (4,7) vanishes on solving the quad puzzle.

The progression reads left to right: *triangle → measurement → quadrilateral*. One shape becomes a theorem becomes a compound.

**The Exit:**

The platform fragments at the bottom. Row 11: a single cube floating in the void, holding the annotation and "Triangle everything" in 3D text. The map's own geometry decomposing into isolated pieces.

Teleporter at (5,8).

---

## 🌙 Map 6: Point_Animatedcube — *"Geometry becomes something that can be touched"*

Blue sky. 7 wide, 14 rows. About spectacle.

**The First Pair (row 4):**

Twin pedestals at columns 2 and 4 (height 2). On each: an **animated cube builder** at half scale. Between them at (3,4): the **dark sphere**.

The animated cube builder is a construction animation in four phases:

1. **SHOWING_VERTICES:** 8 green marble spheres appear one by one (0.5s each). Points.
2. **SHOWING_EDGES:** 12 white cylinder lines connect them (0.2s each). Wireframe.
3. *(3-second pause)*
4. **SHOWING_TRIANGLES:** 12 transparent faces fill in — dark pink, red, black cycling (0.15s each). The cube is made of triangles.
5. **COMPLETE:** All 8 vertex spheres become **grabbable**. I drag a corner, the entire cube deforms — edges and faces rebuild. Topology persists; geometry surrenders.

**The Second Pair (row 8):**

Same structure, two more animated cube builders. Four total.

**The Net (row 10):**

A **polyhedron nets cube** with `loop_fold:true`. Six square faces laid flat as a cross, then folding into a cube over 2 seconds, holding, unfolding, repeating. The inverse of the animated builder: construction from outside (faces → hinges → volume) instead of inside (vertices → edges → faces).

**The Exit:**

Platform tapers to a tail. Teleporter at (5,12).

**The experience:** Everything taught so far converges. Points → edges → triangles → cube. The animation makes the hierarchy visceral. The net adds the inversion: you can start with surfaces and fold them into volume. Both paths arrive at the same cube.

---

---

## 🌙 Map 7: Primitives_Ignorance — *"Let no one ignorant of geometry enter here"*

The map widens. 9 columns — the widest yet — and 25 rows deep. After six maps of concentrated pedagogy on a 7-wide platform, the space has *breadth*. Difficulty ticks up to intermediate. Time doubles to 5-6 minutes.

The description reframes everything: *"'Primitive' here names not a lowest form but a stage of unknowing."*

**The Entrance Hall (rows 0–7):** Flat 9-wide floor. At (4,4): **platonic grabbables** — all five Platonic solids, three grabbable copies each (15 objects). On a raised central plinth (rows 3-5, height 2). Perfection is finite.

**The Gate (row 8):** Columns 0-3 and 5-8 rise to **height 3**. A monumental gate. At (4,8): the **dark sphere** and floating text: **"Let no one ignorant of geometry enter here"** — Plato's Academy inscription. But the map is called *Ignorance*.

**The Gallery of Approximation (rows 9–16):** Studded with pedestals — a museum grid:

Left column: hole_with_cones (absence as geometry), righttriangle (triangle as architecture), roughrock (noise-perturbed irregular polyhedron).

Center columns: **Sphere LOD progression** — sphere_high (32×32), sphere_mid (16×16), sphere_low (8×8). Six spheres in descending resolution. The "same" shape at three levels of dishonesty.

Right column: star_primitive (not Platonic), truncatedtetrahedron (Archimedean), capsule (game engine primitive Euclid never imagined).

**The Octahedron Puzzle (row 17):** snap_octahedron_puzzle with fillhole:remove, flanked by grabbable octahedra.

**The Architecture Zone (rows 19–21):** Enormous sphere at 5.6 height. Mirrored L-shapes. A wall of 8 prism blocks. Walkable prism to climb over.

**The Menagerie (rows 23–25):** Low-poly tori (8:4 config), capsules at varying resolutions, diamond tower, plus shapes.

Teleporter at (4,23).

**The experience:** Overwhelms after six focused maps. Dozens of shapes. The sphere progression is the thesis: three resolutions, the "same" shape at three levels of honesty. Ignorance is structural — you can't see the triangles unless you lower the polygon count.

---

## 🌙 Map 8: Primitives_Portals — *"Discrete rings approaching π without arrival"*

7 columns wide, 35 rows deep — the longest map. But most of the grid is **void**. A corridor that breathes then collapses into a single-tile spine.

**The Head (rows 0–7):** Platform oscillates — 5 wide, 3 wide, 5 wide, 3 wide. Diamond rhythm.

At (3,4): **combine_portals** — twenty torus meshes, spaced 4.5 units apart along Z. Each portal has more polygons than the last: portal 0 = low segments (crude triangular ring), portal 19 = high segments (nearly smooth). A convergence sequence made architectural.

**The Spine (rows 8–31):** Single tile wide — column 3 only. A tightrope, 24 rows. But NOT empty — the portals surround this spine, forming a **tunnel of tori**. Each gate wraps around me, each rounder than the last. The space is claustrophobic, full of rings converging on a circle. Dark sphere at (3,18), halfway through.

This is Archimedes' method of exhaustion made physical. Each ring adds segments. The circle gets more circular. The polygon count is always finite. π is always irrational. The torus will never be round.

**The Exit (rows 32–34):** Spine widens. Teleporter at (4,33). The corridor ends because the map ends, not because the approximation completed.

**The experience:** Most minimal map — one artifact, one idea, one direction. Walking through rings getting rounder. After Ignorance's abundance, Portals is ascetic. The sequence's meditation after its feast.

---

## 🌙 Map 9: Primitives_Melencolia — *"The bell has not rung yet"*

The final map. 7 wide, 13 deep. Compact. Intimate.

**The Courtyard (rows 0–5):** Raised plaza at height 2 (cols 1-5). Four **pyramids** at corners — sentinels. Center cluster: cubes at half scale, a pyramidlong as altar piece. Walkable prism ramp to enter. snap_pyramid_puzzle at (3,1) — the last construction puzzle. Dark sphere at (2,5).

**The Descent (rows 6–9):** Twin teleporters at (1,8) and (5,8) — two exits, the only map with a choice. Both lead to the same place. Two **bigframes** — empty picture frames. The choice is illusory. Melancholy doesn't choose.

**The Cathedral (rows 10–12):** Floor rises to **height 3**. At (3,10): **diamond torus collection** floating 4m above — a chandelier. The torus from Portals returns as ornament.

At (3,12): the **Dürer Scene** at half scale — a complete 3D reconstruction of Melencolia I:
- **Polyhedron** — truncated rhombohedron, slowly rotating. Not Platonic. Not classified. 500 years of debate.
- **Sphere** — polished, high-poly. The ideal that's never real.
- **Magic Square** — 4×4, every sum = 34. Bottom row: 15 14 = 1514.
- **Compass** — brass, open, unused.
- **Ladder** — 8m tall, 7 rungs, leaning into darkness.
- **Hourglass** — glass bulbs, time passing.
- **Bell** — brass, hanging, unrung. Silent.
- **Scales** — balanced by emptiness.

Own environment: near-black, volumetric fog, glow. A painting inside a game.

At (3,13): **code_display with melencolia_axioms** — the longest tutorial. Walks through every element, traces the arc, then asks:

*"Having the tools is not the same as having the vision."*
*"Primitives alone do not make a world. They are the alphabet, not the poem."*
*"Are you building escape pods or consciousness tools?"*
*"The angel has not answered. Neither will this tutorial. That choice is yours."*

**The experience:** Ends in suspension. Not triumph. The architecture climbs — height 1, 2, 3 — and at the top: tools scattered, bell unrung, polyhedron unclassified. The twin exits offer a choice that isn't really a choice. The torus chandelier hangs unresolved.

*The bell will ring when you decide what to build.*

---

## Reflections on Playing Ada Research as Text

### What Worked
The CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md is genuinely functional as a playthrough method. The three-layer system (structure/utilities/interactables) is legible enough to reconstruct spatial experience from JSON. The artifact registry + source code chain gives full access to behavior, not just placement.

### What Surprised Me
- The **fillhole mechanic** as recurring ritual — solving geometry to remove obstacles. It builds into a language across maps.
- The **spatial compression/expansion rhythm** — maps alternate between intimate (Point_Trace: 14 rows, near-black) and expansive (Point_Lines: 21 rows, Ignorance: 25 rows). This is pacing through architecture.
- The **subtitle system** carrying the critical voice — poetic fragments that fire once and disappear. They function differently from clipboard text; they're ephemeral, atmospheric.
- The **dual description** fields — many maps have description and description_2, one philosophical, one technical. The duality is baked into the data structure.
- How much the **sky color** communicates. Point_Trace's near-black (0.05, 0.05, 0.1) vs the standard blue (0.2, 0.3, 0.7) changes everything.

### The Sequence as Textbook
primitives reads as a 9-chapter textbook:
1. **Point_One** — Definition (existence)
2. **Point_Lines** — Relation (connection, measurement)
3. **Point_Trace** — Duration (gesture, residue)
4. **Point_Triangle** — Closure (surface, interior)
5. **Point_Triangle_Context** — Application (rigidity, decomposition)
6. **Point_Animatedcube** — Assembly (hierarchy, construction)
7. **Primitives_Ignorance** — Critique (limits of vocabulary)
8. **Primitives_Portals** — Convergence (approximation, π)
9. **Primitives_Melencolia** — Threshold (knowledge without direction)

The arc: define → connect → accumulate → close → apply → assemble → question → converge → pause.

### Sequence Completed ✓