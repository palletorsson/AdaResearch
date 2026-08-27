# Color, taught in the order the engine needs it — and the recipe for every sequence

> 2026-08-27, Palle: *"color does not teach color but has some good examples, we need to
> order them into a taxonomy. Can we make a list thinking about the taxonomy and what
> concept we need to introduce to make an object exist. The cheat code in the godot
> documentation, for instance what color is for the godot engine but the goal is to teach
> us that we queer fun and very very beautiful objects. Let's think about that for every
> sequence but start with color."*

The move: **the engine's own API is the honest dependency order.** For a coloured object
to exist in Godot, things must exist in a fixed sequence — a light, then a triple, then a
surface slot, then everything culture builds on top. That order IS the taxonomy, each
rung earns its existence proof as one queer, beautiful object, and where the engine goes
silent (harmony, context), the silence itself is a rung.

This replaced the June color concept map, whose "concepts" were map blurbs ("A salon for
digital fingers…") — grouping by where things stood, not what they teach. The new canon
is authored in `tools/build_concept_map.py` (CONFIG.color), regenerated to
`doc/color_concept_map.json`, and live at **localhost:3003/color-concepts** — 53 tiles
across 13 sections in dependency order.

## The Godot cheat-code for color

| engine primitive | what it admits about color |
|---|---|
| `Light3D.light_color`, `light_energy` | no light, no color — the room decides first |
| `Color(r, g, b, a)` | the whole visible world is three floats (and a fourth for through) |
| `Color.from_hsv(h, s, v)` | the same triple through human knobs |
| `StandardMaterial3D.albedo_color` | color as what a body reflects |
| `emission`, `emission_energy_multiplier` | color as what a body emits |
| `transparency`, alpha | color light passes through |
| shading = light × albedo | what you SEE is a product, not a property |
| `Color.lerp`, `Gradient` | between two colors there are many roads |
| — (no primitive) | harmony/complement: the engine has no word for the chord |
| — (no primitive) | simultaneous contrast: nor for the ground |
| sRGB↔linear, banding, subpixels | the screen's own flesh shows through |
| `Environment` ambient/fog/sky | color as a place you stand inside |

## The ladder — 12 rungs, 6 acts

Per rung: the concept, its bodies today (53 tiles), and the **hero** — existing (adopt)
or to build (the prop-gallery discipline: seeded, placarded, physics/optics honest).

**Act I — before the object**
1. **No light, no color** — `RotatingLaser`, `disco_lights`, `strobe_lasers`, `flashlight_demo`.
   HERO to build: `one_bulb_room` — a single bulb on a cord in a dark room; grab it and
   swing, and every colour in the room swings with it.

**Act II — the number**
2. **The triple** — `color_mixing`, `visual_color_mixing`, `colorballs`, `coloredlines`, `spherecolors`.
   HERO to build: `three_taps` — R, G and B faucets over one basin that fills with light.
3. **The second door (HSV)** — `SpectrumVisualizer`, `color_space_navigator`.
   HERO to build: `hue_carousel` — a fairground wheel: hue is where it points, saturation
   is how far out you sit, value is the dimmer pole.

**Act III — the body**
4. **Skin (albedo)** — `nail_color_controller`, `hand_color_controller`, `colorsheets`,
   `gridcolorizer`, `ball_painting_demo`. HERO: **the salon, adopted as it stands** —
   colour applied to a body as an act is already the queerest, truest object here.
5. **Glow (emission)** — `rainbow`, `mario_cube` (hand layer; the registry had no emitter).
   HERO to build: `neon_garden` — flowers of pure emission, visible only as the room dies.
6. **Through (alpha)** — `dark_side_prism`, `chromatic_form_artifact`.
   HERO: adopt the **Cruz-Diez chromatic fins** family — walk past, the colour recomposes.

**Act IV — the meeting**
7. **Multiplication (light × skin)** — `MetamerismLab`, `color_scanner`, `grab_stick_scanner`.
   HERO to build: `the_dressing_room` — ONE dress, cycling stage light: it "changes
   colour" without changing. Metamerism as drag.
8. **The path (lerp/Gradient)** — `gradient_interpolator`, `colortrails`, `rainbow_hallway`.
   HERO to build: `two_roads` — walk A→B twice between the same two colours: the RGB
   corridor greys out mid-way, the HSV corridor stays saturated round the wheel.

**Act V — the relation**
9. **The chord** — `color_sets_overview`, `pillarcolorcollection`, `grabcolorcollection`,
   `k_means_color` + the promoted stacks (complementary, triadic, value-steps, monochrome).
   HERO to build: `complementary_couple` — two armchairs locked opposite in hue; turn
   one, its partner answers across the wheel.
10. **The ground** — `SimultaneousContrast`, `albers_wall_gallery`, `albers_relief`,
    the contrast stack, `albers_homage_warm`. HERO: **Albers, adopted** — the wall gallery
    is the canon; a `same_grey_twins` pair (two identical grey cats on different grounds)
    can join later.

**Act VI — the screen and the room**
11. **The screen's flesh** — `subpixel_display`, `banding_gradient` (never photographed —
    the one portrait gap), `advancedglitch`, `glitchcolor`, `minimalglitch`, `textureglitch`.
    HERO to build: `glitch_mirror` — your reflection with its subpixels pulled apart, a
    banding halo where the gradient quantises. The queer flesh of digital colour.
12. **The room** — `color_constellation_office`, `rothko_chromatic_field`, `chromatic_field`.
    HERO: adopt the **Turrell spaces / gradient corridors** families — colour as fog and
    ambient, a room with no wall to find. The loop closes on the sequence truth:
    *"color is perception, not physics."*

**How this crosses the 08-24 fold.** The fold's ladder (unit→index→attribute→rule→
composition) is the sequence's ARRAY skeleton — colour was only its "attribute" rung.
The two orders compose rather than compete: rooms keep the fold's structure; the colour
taxonomy is the CONTENT order for curation, placement and the concept gallery's sections.
`Off the ladder` holds what neither claims yet (`shelf`, `grab_stick`) — a chip decides.

## The recipe, for every sequence

Three questions produce this taxonomy for any sequence:
1. **What is X for the engine?** Find the cheat-code: the minimal API a thing of X needs
   to exist. The docs' own property list is the dependency graph.
2. **Order by existence:** each rung introduces exactly the concept without which the
   next object cannot be built. Where the engine has no primitive, the silence is a rung.
3. **One queer, beautiful hero per rung** — a body, not a diagram (the forces prop-gallery
   discipline), placarded with the rung's truth.

Seed cheat-codes (the one-line engine answer per sequence, to be grown like color's):

| sequence | what it is for the engine |
|---|---|
| primitives | `MeshInstance3D` + primitive meshes — a thing must have a surface to be |
| transformation | `Transform3D` = basis + origin: move, turn, scale, COMPOSE |
| change | `_process(delta)` — nothing changes except per frame; time is delta-shaped |
| forces | `RigidBody3D.apply_force` — done: see FORCES_PROP_GALLERY.md |
| wavefunctions | `sin(t)` + `AudioStreamPlayer` — one oscillator wearing two costumes |
| randomness | `RandomNumberGenerator.seed` — chance the engine can replay |
| noise | `FastNoiseLite` — randomness with a NEIGHBOURHOOD |
| cellularautomata | no primitive: a grid, a rule, and YOU must build time yourself |
| fractals | recursion — the function that calls itself until a depth mercy-kills it |
| lsystems | no primitive: a string that rewrites itself, then a turtle believes it |
| proceduralgeneration | `PackedScene.instantiate()` + seed — authorship at arm's length |
| softbodies | `SoftBody3D` / joints — a mesh that admits it has insides |
| isosurfaces | a field sampled → `ArrayMesh` — the surface is an OPINION about a threshold |
| boolean_surfaces | `CSGShape3D` — form by argument: union, intersection, subtraction |
| swarmintelligence | `MultiMesh` + one rule many times — the crowd is the primitive |
| machinelearning | no primitive: a loss, a gradient, and weights the engine never sees |
| graphtheory | the scene tree ITSELF — `get_children()`: the engine is already a graph |
| formfinding | constraints relaxing — the shape the forces agree to (needs its canon first) |
| foundationscrisis | the stack limit and the infinite loop — where the engine refuses |
| qfeplaboratory | every primitive at once, aimed at the framework itself |
| postfoundationscrisis | building anyway — the same APIs, held differently |

Rollout: same mechanics as color — author CONFIG.<seq> in `build_concept_map.py`
(rungs, truths, keywords), regenerate, additions file for cross-registry bodies,
`build_concept_gallery.py <seq>`, curate at `/{seq}-concepts`. Color is the worked
example; graphtheory ("the engine is already a graph") is the natural second — its
cheat-code is the deepest one-liner in the table.
