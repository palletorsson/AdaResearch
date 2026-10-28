# Colour lab: as built (2026-10-27)

Palle: "make one lab". The colour family lives INSIDE /spatial-lab (an Arrangement | Colour switch, `?family=colour`). The design record below is kept for its reasoning; what was built is simpler and is this:

| piece | file | owner |
|---|---|---|
| recipes + parameters | `commons/modular/lab_colour.json` | colour family |
| server: validation, the ONE cache key, the native slot, the warm bench | `tools/colour_bench.py` (`serve`, `request <recipe> k=v…`, `stop`) | colour family |
| warm Godot bench (Mobile renderer, SubViewport fixture, views, oracle) | `commons/testing/colour_bench.gd` | colour family |
| oracle maths | reused from `commons/testing/probe_albers_glass_render.gd` (`achieved`, `box_rect`): no second implementation | glass Albers |
| API | `ada_encyclopedia/src/app/api/spatial-lab/colour/route.ts` (Codex's `/api/spatial-lab/route.ts` untouched) | colour family |
| panel | `ada_encyclopedia/src/components/spatial-lab/ColourFamily.tsx` | colour family |
| hook | `src/app/spatial-lab/page.tsx`: one import, `function SpatialLab` no longer the default export, a wrapper block at the end | shared with Codex (relayed by Palle) |

**Loop, measured:** cold bench boot 5-29 s (staged runtime + Godot), a warm render 0.6-1.0 s (build ~0.27 s, three views ~0.3 s, oracle ~0.28 s), a cache hit 0.01-0.04 s. The first request of the day waited 128 s for `void-native.lock` while another native job ran: the panel says "waiting for the Godot slot".

**Albers oracle:** all 98 homages, two patches each (outer band, innermost centre), in a linear-tonemap orthographic shot. Rule: within 3/255 in sRGB, or within one 10-bit buffer step (1/1023) per glass crossing in linear light. The second clause was added after measuring: every error above 2/255 sat in a DARK channel behind ten multiplies (expected 45.95, got 49; bright channels within 0.5), which is the Mobile buffer rounding each multiply, magnified by the sRGB curve near black. Each receipt also tests the WRONG physics (cubes crossed once, relief twice) and reports how many patches it would pass: 0 of 196 on every run so far, so the rule still discriminates.

**Seen through the lab:** `chroma_filter` with `mix=filter` renders its overlaps almost black on the Mobile renderer: the half-strength StandardMaterial3D BLEND_MODE_MUL on the Quest, found on the Albers glass, applies to it (and to `grab_disk.gd`, `color_display_disk.gd`).

**Recipes (in the order of the Void's colour floors), every enum derived from the artifact's own `@export_enum`:**
chroma_stack (F29: rule × alphabet × pose — the third axis, pose, is not in the /chroma-dna gallery of 17 Sept), chroma_translation (F29: along × colour_by), color_dna_stack (F29: study), chroma_drum (F31, proposed: face × grain), chroma_life (F34, proposed: run × paint), albers_glass (F35), chroma_filter (F36, proposed). Framing: wide works keep the wall views; tall or compact works orbit at 35° fitted on their height, and the eye view looks up from 1.65 m.

**Live sketch, as the portal family does it (Palle, same day: "the portal uses three js for the param manipulation, why can we not do that with color?").** A colour study in `ada_encyclopedia/src/lib/colour-study.ts` compiles its settings into ONE modular expression. three.js builds it on every change through `modular-terms.ts` (the Builder the portal and lab editor use); Check in Godot sends the SAME expression to the bench as the hidden `term` recipe (`commons/modular/composite.tscn`, `expression` export). Two additive mesh keys on both builders: `"blend":"mul"` (filter glass: unshaded, both faces, no depth write; Godot uses the Albers gain shader, since the Mobile renderer halves a plain multiply) and `"lit":false` (a colour field). Absent keys leave every mesh as it was. First study: Albers (medium paint / relief / cubes, order darker_in / lighter_in, homages, squares, hue, hue turn, drift, saturation, value, inset, gravity); its receipt counts squares that clamp (lighter_in: 12 of 16; darker_in: 0). Measured: sketch instant with 0 requests per change; Godot check cold 32 s, warm 0.35 s (1.6 s round trip). Learned on the first check: a glass cube projects past a canvas-sized light table and multiplies the dark room, so under cubes the table is 1.6 x the canvas. Evidence: `doc/colour/colour_sketch_vs_godot.jpg`, `colour_sketch_godot_oblique.png`. three.js multiplies in sRGB space, Godot in linear, which agree except near black.

**Six studies in floor order (same day, Palle: "can we work on more color examples"):** chroma_stack (rule × alphabet × pose), chroma_translation (along × colour_by), chroma_drum (face × grain), chroma_life (run × paint), albers, chroma_filter (mix × triad). Each is a port of its GDScript artifact as a term: the data copied, the arithmetic followed line for line. Two ports were checked against the artifacts' own written records: chroma_life under crowd gives a newborn tallest column (4.35 m) and an oldest cell of age 9; chroma_filter's paint crossings give blue, red, green and a near-black post. chroma_filter's panes are single faces with `blend:"mul"`, so the study shows on the Quest what the artifact meant (the artifact's plain MUL goes near-black there); its corner is turned -90 degrees so it opens toward the lab cameras. More additive mesh keys: shapes `dome` and `capsule`, and `edges:false` (three.js draws no outline over the colour). Native sheets: `doc/colour/sketch_chroma_{stack_rules,translation,drum,life,filter}.png`, about 0.4 s per warm picture. Differences from the artifacts, said in the code: no text plates; the term wedge is a right triangle; the term torus is fatter in the sketch than in Godot (the two builders read its size differently, forum 261027-7ii2d).

**Color_Walls studies (same day, Palle chose the Walls hall from the candidate review).** First: *gradient path*, after `gradient_interpolator.gd` (its eight presets, its RGB lerp on sRGB values, its HSV shortest-arc lerp) with two spaces added, linear light and Oklab, and `color_space_navigator.gd`'s RGB cube with every route drawn through it (samples stand at their own r, g, b). Controls: colour A, colour B, space (rgb / hsv / linear / oklab / all), show (both / row / cube), surface (flat / lit), steps. The receipt gives each route's middle, its perceptual length (summed Oklab distance) and its darkest step. Built-in check: the Oklab route is never longer than any other (red to blue 54 against 61 / 64 / 73), as a straight line in Oklab must be. Red to blue in RGB dips darker than both ends (L 0.39 against 0.45), and yellow to blue in RGB passes grey #808080 where linear light passes #bcbcbc. Sheet: `doc/colour/sketch_gradient_path.png`. Next in the hall: the Gillick panels (colour_assembly, colour_wall_studies), then color_constellation_office.

**More studies, same day (Palle: "keep going").** F34, the pallet floor: *palette floor* (after gridcolorizer's address lesson: the hall's rule (x + z) % n over the 20 named palettes derived from color_palettes.tres, its four inks as exceptions, moment edited / rule ran, plus rules difference / product / rows / rings / scatter and lift: colour handed to height) and *spectrum forest* (hue as the artifact, the physical spectrum, bands, or the nearest entry of a palette; rothko_chapel catches the whole rainbow on one entry). Color_Walls: *Gillick assembly* (three arrangements, three colour rules, the artifact's alpha veil or filter glass, and `cast`: each pane projected along a sun onto the floor as a multiply patch, computed geometry where the artifact says it does not simulate coloured transmitted shadows), *Gillick wall* (spacing, stand-off, omitted rail, colour rule, Gillick's palette or any F34 palette), *filter office* (office_planes.gd's twelve panes; veil / filter / opaque; three sightlines from the entrance reported as the colour each ends on). Color_Pillar: *where colours meet* (visual_color_mixing's bench / light / pigment / retina, spread, pitch). A `plan` camera was added to the bench and the sketch with one arithmetic.

**The palette floor's rules, twenty in five families (Palle: "can we have more rules?").** Lines: sum (the hall's), difference, columns (x mod n), rows (z mod n), knight (x + 2z), linear (a·x + b·z with two sliders). Number: product, squares (x² + z²), gcd, pascal (C(x + z, x) mod n from a table), xor, and (x AND z = 0 → first entry). Distance from the centre: rings, diamonds, frames, sectors. Walks: the Ulam spiral, its primes, Collatz steps. Chance: scatter. The panel prints the rule as written and, new, **which other rules draw the same partition of the floor** (up to which entry is which). It found at once: pascal and and agree at 2 entries (Lucas: C(x + z, x) is odd exactly where x AND z = 0); at 2 entries sum, difference, linear(1, 3), squares, xor, diamonds, spiral AND scatter are all one checkerboard, because each one's last bit is (x + z) mod 2 — so the "chance" rule is not chance at 2 entries (both its hash multipliers are odd). At 12 entries no rule repeats another. Sheet: `doc/colour/sketch_palette_rules.png`.

**One rule engine along the spine (Palle: "that relates to the black and white tiling pattern earlier in the spine ... also related to cellular automata").** The spine's own role line for array_tutorial, color and tiling reads "address, then attribute, then rule, then the made thing". Two studies extend the palette floor's engine both ways. *One motif, any rule* (Tutorial_Tiling, after `regularity/tiling_pattern.gd`): the hall's half-black tile and its six relations computed as the hall computes them (the polygon carried back through the hall's sampling, so turns match), then `any rule`: the twenty rules set the tile's turn, mirror, inversion or turn + inversion. The panel names each hall relation as a rule: alternate = sum at 2 states setting invert, quarter turn = sum at 4 states setting the turn, reflect = columns at 2 setting the mirror, one exception = the ink; shift rows is not a rule on the tile but the address sliding. Truchet's quarter-circle motif added. *Elementary rule* (CA_Introduction, after `ca_rule_explorer`): rule 0-255, seed, edges, palette; the floor is the space-time diagram. The receipt checks the bridge: from one cell, rules 90 (centre), 60 (left) and 102 (right) reproduce C(t, k) mod 2 exactly, the picture pascal and and drew from the address alone; rule 30 and 150 do not, and a grid too narrow for its generations fails the check. **Found on the way:** the scatter rule's hash had low bits depending only on x, z mod 4, so at 2 states it was the sum checkerboard and at 4 a grid of hourglasses; Truchet's random tiling came out regular. It is a mixed hash now (balanced, no twins). Sheets: `doc/colour/sketch_tiling_motif.png`, `sketch_elementary_rule.png`. Not done: the hall artifacts themselves are unchanged.

**The tiling hall upgraded (Palle: "keep going").** `commons/artifacts/regularity/address_rules.gd` is the GDScript twin of the lab's twenty rules; `tools/address_rules_crosscheck.py` evaluates both on 264 cases (3 sizes x 4 state counts, linear at 3 settings) and fails on any differing cell: 264/264 agree over 55,088 cells, and a knight rule broken on purpose failed exactly its 12 cases. `tiling_pattern.gd` gained `rule_image` (image_for untouched). `tiling_principles` has a third button on its panel, RULES: the six fields become TRUCHET / CHANCE TURNS, QUARTER CIRCLES / CHANCE, PASCAL / INVERT, XOR / TURN, RINGS / TURN + INVERT, SPIRAL / TURN, and back. `commons/testing/probe_tiling_rules_button.gd` (headless) passes 8/8 in floor and walls mode: at load the fields are image_for's six byte for byte, RULES changes all six and their titles, RULES again restores them byte for byte. The sixth field was first the spiral setting a mirror, which at 2 states IS the sum checkerboard (the same-picture check), so it turns at 4 states instead. The hall's final.md / tutorial.md do not mention RULES yet. Sheet: `doc/colour/tiling_hall_rule_fields.png`.

**Time is a setting: the disco floor (Palle: "the disco black and white floor and the color disco floor take this into a moving pattern").** A study may name a `clock` setting; the sketch advances it on a tempo with PLAYING / HOLD / ONE STEP and a 0.25 / 0.5 / 1 s beat, as disco_controls' console does, and the link carries the beat, so the native check renders a given beat. *Disco floor* (Tutorial_Disco / Pattern_Disco, after `regularity/disco_controls.gd` value_at): the console's CHECKER (x + z + phase) mod 2, ROWS, DIAGONALS (x + z + phase) mod 4 < 2 and SNAKE exactly, in its palettes (mono and three disco pairs); then any of the twenty rules cycling through the palette ((rule + beat) mod n) or travelling (rule at (x - beat, z)); then two automata where a beat is a generation: an elementary rule on a ring whose history scrolls along the floor, and Life on a torus. The receipt gives each setting's period (cached per setting; Life stepped forward once): checker 2, diagonals 4, rows 8, snake 64, rings cycling at 4 states 4, rule 30 on a ring of 8 every 40 beats after 8; rule 90 on a ring of 8 dies by beat 11 (a ring of a power-of-two width always does). Cycling colour through rings reads as rings moving, though no tile moves. Checked live: 7 -> 12 beats in 2.6 s at 0.5 s, HOLD holds, ONE STEP steps. Film strip: `doc/colour/sketch_disco_floor.png`. Not done: disco_controls in the hall is unchanged.

**The array sequence (Palle: "can you take on the array seq").** The sequence's truth: "An address can remain when its occupant leaves. What a stored or computed value means depends on the reader: absence, a turn and a silent beat are different decisions." Its readers are now all in the lab: occupancy (*array ladder*), orientation (*one motif, any rule*), the beat (*disco floor*). *Array ladder* (after algorithms/arrays row_3_x, column_3_z, grid_2d_4x4, grid_3d_4x4x4): row 3, column 3, grid 4 x 4, lattice 4 x 4 x 4, growable; the rule decides occupancy (state 0 keeps the address as an empty frame), colour or size; in the lattice y adds to the state as the disco's beat did. *Molnar (Des)ordres* (after molnar_cube_study): 64 sites, four nested frames, translation / rotation / scale amounts and depth as the artifact; `chance` departs every site by the same amount in its own direction (the mixed hash; the artifact's Godot RNG stream is not replayed), `rule` lets an address rule set how much each site departs. *LeWitt incomplete open cubes* (Tutorial_3D, after open_structures): every subset of the 12 cube edges that is connected and three-dimensional, counted once per rotation (24), enumerated: **122, LeWitt's number, found and not typed** (by edges kept 3..11: 3, 5, 14, 24, 32, 25, 13, 5, 1); 77 with mirror images identified. New additive mesh shape on both builders: `cube_edges` (edge, bar, 12-bit mask in open_structure.gd's edge order). The plan camera now allows for height (a lattice ran into the lens), in the bench and the sketch alike. Sheets: `sketch_lewitt_122_plan.png`, `sketch_molnar.png`, `sketch_array_ladder.png`.

**The disco halls upgraded (Palle: "commit and continue").** `disco_controls.gd` (Tutorial_Disco mono, Pattern_Disco colour) has a RULES button: RINGS / CYCLE, SPIRAL / CYCLE, PASCAL / TRAVEL, RULE 90, RULE 30, LIFE; PATTERN returns to the console's own, which stay the default at load. A multi-state rule shades between the palette's two colours (grey levels on the black-and-white floor), and the lab's disco study now shades the same way. `tools/address_rules_crosscheck.py --disco` runs `commons/testing/probe_disco_rules.gd` in a room of its own, mono and colour: 22/22 (at load the floor is the console's pattern tile for tile; RULES changes it; PATTERN restores it; all six patterns agree with the lab's `discoStates` for beats 0-24). Found on the way: the hall floor is **12 x 12**, not the registry's 8 x 8 (the first comparison failed every pattern until the lab side took the floor's real size; that failure is the check's negative), and XOR travelling at 2 states IS the checkerboard (CHECKER again), so the third pattern is Pascal sliding. Sheet: `doc/colour/disco_hall_rules_beat12.png`.

**The array sequence's halls, continued (Palle: "we can not really use ca rules in that map but we can have them as an option. keep going").** The disco console's automata (rule 90, rule 30, Life) are now offered only on the map option `#automata:on`; neither disco map sets it, so RULES there cycles the three address rules (the probe checks it visits only 0, 1, 2), and `--disco` passes 24/24. *Array*: `molnar_cube_study` takes `#decide:<rule>` (default chance): a site's departure is weighted by ((rule(x, z) at 4 states) + y) mod 4 / 3, the lab's formula; at default all 256 frame poses are byte-identical to the script before the change (`probe_molnar_decide.gd`, run before and after), and under rings 192 of 256 differ (the 16 full-weight sites do not). *Tutorial_3D*: the open study's console has a fifth button, 122, mode 4 of `open_rules.gd`: LeWitt's incomplete open cubes enumerated in GDScript over the 4096 edge subsets and 24 rotations, laid out in rows by edge count on a plinth; `tools/address_rules_crosscheck.py --lewitt` (probe_lewitt_122.gd): 122 found, the same masks as the lab's, 845 bars, mode 0 unchanged, station.gd loads. Hall texts do not mention any of the new buttons or options.

**The ladder's own artifacts.** `grid_2d_4x4`, `grid_3d_4x4x4` (its config path) and `array_flight_lab` take the opt-in `#occupancy:<rule>` (binary, so no numeric map key is needed): where the rule (with the layer added in the lattice) gives 0, the address stands EMPTY, a cube_edges frame the pickup cube's size with the same label, and the grid's `grid_data` / binary table and the flight lab's `values` start that cell at 0, read from what was built rather than recomputed. Proven by before/after builds (`probe_array_occupancy.gd`, `probe_flight_occupancy.gd`): every old path byte for byte (the flight lab's cubes settle by < 1 mm between runs, so its comparison is names and x/z); for all twenty rules the empty frames are exactly the stored zeros; the lab's ladder leaves the same count empty (20/20); in the flight lab under primes the console reads value 0 at an empty address before anything is collected. A probe trap found on the way: a snapshot that keeps a REFERENCE to grid_data reads all zeros, because freeing the grid afterwards sends every cube's picked-up callback into that array. Native recipe `array_lattice` (the hall's lattice, its occupancy option) in the native tab; sheet `doc/colour/hall_lattice_occupancy.png`.

**Forces (Palle, 28 October: "continue with forces studies").** Most of the forces halls are Godot physics (rigid bodies, joints, collisions), which a second engine would only drift from, so the lab takes the artifacts whose motion is a rule with an exact answer. *Field receivers* (Vectors_Act3, after `field_receivers.gd`, the lesson VectorFieldFlow runs there): SINK / SWIRL / UNIFORM with GAIN and REVERSE, steps of 1/120 s from (-2, 0, -2), CYAN takes the field as velocity, PINK as acceleration, both stopping at the arena's edge; spiral added in the lesson's scale; the artifact's square / polar / hidden lattices; the beat is time in the lesson's 0.1 s samples. Checked against the exact answers: under SINK at 5 s CYAN -0.3467 against -2e^(-0.35t) = -0.3475 and PINK 1.9673 against -2cos(sqrt(0.35)t) = 1.9664 (4.9 mm of phase drift by 24 s); under SWIRL CYAN's circle grows 2.8284 -> 2.8458 m in 12 s, the step adding a little each turn. *Euler drift* (VFM_05_Launch, after `euler_drift.gd`: one second from (-0.42, -0.12) at (0.72, 0.92) under -1.55): position-first Euler lands g/2N above (110.7 mm at the artifact's 7 steps, +171.6 mJ/kg), velocity-first g/2N below, the step that adds g dt^2/2 exactly on the formula at any N; doubling the steps halves the Euler error. Sheets: `sketch_field_receivers.png`, `sketch_euler_drift.png`.

**The remake routine (Palle, same day: "pick an artifact in from godot remake the principal in three js and parameterize what possible").** One artifact at a time: (1) read its script and list every value it decides, including the drawing choices it does not mention; (2) each becomes a control whose default is the script's own value, so the default sketch IS the artifact; (3) what the artifact leaves out (damping, a stepping solver, a true scale) is added as a control whose default is the artifact's choice; (4) the facts name the exact answer, and a check compares the sketch with it before the sketch is believed; (5) Godot renders the same expression on request, never on load. *Spring tower* (Vectors_Act4b_Oscillation, after `spring_tower.gd`) is the first: k = lerp(8, 40, 0.45) = 22.4, m = 6, g = 9.8, amplitude 0.4 + (1 - 0.45)/2 = 0.675, x = -A cos(wt), ceiling 5.6, natural coil 1.8, 9 coils of 0.4. Three silent drawing choices became switches: the hanging stretch mg/k (2.625 m) is drawn at 0.18 of its length, the arrows are not to scale (spring 0.7 + 1.3 x stretch, weight 1.1), and both arrows start at the mass's foot, so the spring arrow's first 0.8 m is inside the box. Added: damping c with all three regimes in closed form, explicit Euler and velocity-first stepping against them, a wall graph of x(t) that widens with a solver that gains energy, and energy. Checked: the closed forms agree with a 5 ms velocity-first stepper at 5 s to 0.8 mm undamped and 0.1 mm at c = 10, 23.19 (critical) and 35; explicit Euler's energy after N steps equals the prediction (1 + (w dt)^2)^N to the tenth of a percent (26349.3 % after 600 steps of 0.05 s). Not remade: the crate bob (a museum prop) and the billboard label (its numbers are the facts). Native sheet rendered on the warm bench (0.46 s a frame).

*Force pad* (Palle: "and the launch_pad"; the pad is `force_pad.gd`, which the force court places as "LaunchPad" at up 6, forward 4, foresight parabola, vectors sum). Controls with the script's defaults: up 7, forward 6, gravity_magnitude 9.8, foresight none, vectors velocity. The pad draws every prediction from its centre, 0.2 m up. Added, and measured in Godot before it was drawn (`commons/testing/probe_force_pad_flight.gd`: a capsule of radius 0.2, origin at the feet, walking on at 1.4 m/s, falling as the player body does at 60 Hz): the body leaves from wherever its feet are when the capsule first touches the 1 m trigger box, from the floor, and lands one tick early. From behind it leaves at z -0.6733 and lands at 7.8267 against the drawn 8.7396, 0.913 m off and outside the pad's own 0.35 m landing ring (0.673 the trigger, 0.168 the feet on the floor, 0.071 the stepping); from the side at (-0.6733, 8.5), 0.715 m off; from in front at 9.1734, 0.434 m off. The lab reproduces all three to 0.1 mm. Also measured: all three chevrons point -z, back at the walker, while the launch goes +z; the script's comment says "+Z" (rotation_degrees.x = -90 sends a cone's tip to -z). Both are switches in the lab (approach, chevrons); the artifact is not changed. Further controls: the g the body falls with apart from the g the pad draws with, body radius, walking speed, exact or stepped fall, physics rate, the court's 14 m/s limit. The study turns the pad 90 degrees so the bench's front camera sees the flight side-on.

*Launch arc* (the table-top throw, `launch_arc.gd`): angle 46 deg (lerp(22, 70, 0.5)), v0 2.84 (lerp(2, 3.4, 0.6)), GRAVITY 3.0, launch 0.06 up, 14 strobe steps, the launch arrow at 0.62 per m/s, and its two axes word for word (workings outcome / trace / operands / expression, comparison single / fan / pairs / envelope). The toy's envelope comment says the live arc "touches it from inside at exactly one point". It does, at x = v0^2 / (g tan theta), but the touch is v0^2/g - v0^2/(2g sin^2 theta) above the pad, which is negative below 45 deg: at the slider's 22 to 44 deg the touch is under the pad, where the toy stops drawing (at 30 deg, 2.689 below). Added: where the flight ends (at the pad as the toy, on its ground 0.06 lower, or 1 m below on a table so the touch shows), linear air drag a = -bv in closed form, a ball on the clock. Checked: the closed form agrees with an independent RK4 (dt 1e-4) to 4 decimals at b = 0, 0.5, 0.6 and 25 / 46 / 65 deg (46 deg, b 0.6: 1.2155 s, 1.7024); in air the fan's pairs part (20 vs 70: 0.386 m) and the best angle falls to 38.9 deg; landing on the ground moves it to 44.4 deg. The expression board's text is not drawn (no text in the term language); its sum is a fact, and says when the air makes it wrong.

**blend:"add" was measured before it was trusted.** On the colour bench (Mobile renderer) an added square was compared with an unshaded square of the summed colour through the same tonemap: red 255/255 = 255/255, linear 0.5 grey 217 = 217, and two adds of linear 0.25 = one unshaded linear 0.5 at 217, all 0/255 apart. So the sum needs no gain (the operand and the buffer are scaled alike, unlike a multiply). The grey and sum pairs would separate under any gain off 1 by more than ~1%, so the check can fail; the red pair cannot (it clips). Override per headset: `ada/glass/add_gain`.

**A setting is a link, and the sketch has the bench's cameras (same day, Palle: "can we see this in three with the same parametric design?").** The live sketch writes its state into the URL (`?family=colour&study=gradient_path&a=yellow&b=blue&camera=front`, defaults left out) and opens from one. Its camera buttons free / front / oblique / eye are `colour_bench.gd _aim` ported (same bounding-box arithmetic, both engines take a vertical field of view, both canvases 16:10), so a three.js picture and a Godot picture of one setting compare view for view: `doc/colour/gradient_path_three_vs_godot.png`.

**Godot only on request (Palle, same day: "when opening the url godot starts ... can we disconnect it from godot?").** Opening the page or changing a control files nothing. A setting rendered before is shown from the recent list; anything else waits for the Render in Godot button, the way the arrangement and portal families wait for their save button. Checked: load plus three control changes = 0 requests, no bench, no Godot. The next step Palle raised is a three.js live view as the sketch, with Godot as the check.

**Fixed on the way:** the panel re-filed the same setting every ~350 ms after each answer (reloading the spec changed the recipe object's identity); it now files only when the recipe id or a parameter value changes (0 requests in 6 s idle, 1 per change).

**Not built:** oracles beyond the Albers glass; a Forward+ column; the warm bench's GPU memory is not measured.

---

# Colour lab: design record (not built)

*2026-10-27. Palle: "we should use a system like this for fast color test http://localhost:3003/spatial-lab". Workflow: three readers, three designs (same-lab 80, picture-first 84, prefab-axes 73), three judges, synthesis, critic. The critic's verdict is REVISE; its findings are kept below the spec. Nothing here is built yet: two decisions are Palle's (see the end).*

# Colour Lab: build spec

*Synthesised 2026-10-27, 08:07. Winning design: picture-first (a warm Godot picture server). Grafts come from same-lab and prefab-axes. Readers' evidence was re-checked on disk where marked (checked).*

## 0. What this is, in one paragraph

Palle asked for "a system like /spatial-lab for fast colour tests". This spec reuses the spatial lab's shape: a recipe declared in data, controls on a page, a job, a receipt. But the result Palle looks at is a **native Godot picture**, not a three.js frame:
- **Mobile** (the Quest's renderer) is shown large.
- **Forward+** is shown beside it.
- Both are judged per patch against **one oracle number** computed from the bytes the built mesh actually holds.
- three.js shrinks to a corner sketch. It is held to the same number only where an exact comparison is possible.

Speed comes from shooting the whole discrete space in one Godot boot and caching it by content hash. A warm bench per renderer is added only after Palle rules on it. The lab stays **one system** with the spatial lab: one shared job-helper module and one schema that is a superset of lab.json's recipe entry. It is one React component that /spatial-lab can mount as a `family: colour` tab once its owner agrees. `/colour-lab` is a staging address, not a second lab.

## 1. How each judge's fatal flaw is resolved

| Flaw (judge) | Resolution in this spec |
|---|---|
| Speed depends on warm benches outside `void-native.lock`, which needs Palle's ruling, and there was no fallback (J1, J2) | **The cold batch lane is the base and is built first.** One process per renderer under `acquire_native_slot` and `godot_watchdog.py` shoots the whole enum space of a recipe in one boot and fills the content-hash cache. Every enum click after that is an instant native picture with no daemon and no lock change (J3 graft). The warm bench (§2.3) is the same `.gd` script in a second mode, switched on only after Palle says yes. The page works fully without it. |
| A second lab, copied route, colour_lab.json drifts from lab.json: the long_museum.py trap (J1, J2, J3) | (a) The job mechanics move into a new shared `src/lib/lab-jobs.ts` (ours). The colour route uses it, and it is offered to Codex for the spatial route. (b) `commons/modular/colour_lab.json` sits beside lab.json. Its recipe entries are a strict superset of lab.json's (`id, label, defaults` plus `family, controls, fixture…`), so merging is a move, not a rewrite. (c) The UI is one component, `ColourLab.tsx`. `/colour-lab/page.tsx` is a 10-line shell, and /spatial-lab mounts the same component as a tab after agreement. (d) A drift gate in `test_colour_lab.py` fails if the colour receipt's `timing` keys stop being a superset of the spatial receipt's. |
| Slice 1 cannot change a colour relation (all three judges) | Slice 1 has **two real colour knobs that need no edit to anyone's code** (§3): `chroma_filter.triad` (paint, light or bauhaus: *which three colours are multiplied*), which is declared, has `apply_grid_config`, and is already `BLEND_MODE_MUL` (checked: chroma_filter.gd:296-298); and the Albers **palette exports** `palette_seed`, `palette_value_min/max` and `palette_saturation_min/max` (checked: albers_wall_gallery.gd:51-55). These are set on the instance before `add_child` and labelled **"bench knob, not placeable"**, because `apply_grid_config` reads only `medium` (checked: lines 384-390). Kept palettes become a proposal to the Albers session, which owns that file. |
| Gillick-derived warm numbers are unmeasured (gl_compatibility, isolated project, no shader cache) (J2) | Every estimate is marked as one. The first run writes measured values into the receipt: boot s, build ms, frames to stable, frame-3 against frame-10 delta, first-shot against later-shot ms, prewarm wall time. The page shows the measured value in place of the estimate. |
| Browser negative "direct-to-canvas must miss" is weak, because sRGB is nearly a power law (J2) | Replaced. The browser negative draws cubes glass with `side: FrontSide`, one crossing per shell. That is the exact twin of Godot's CULL_BACK negative, and it must miss the centre by more than 3/255. The direct-to-canvas path is kept only as an informational row. |
| three.js MUL glass without `depthWrite:false` depth-culls inner shells (J2) | The sketch material contract (§4.4) sets `depthWrite:false`. |
| Blocked on opus-colour landing `medium` + a dna block (prefab-axes) | Not blocked. `medium` is already in the working tree with `apply_grid_config` and a `config_medium` meta path (checked: lines 65, 96-104, 384). The bench reads it and fingerprints the file. A dna block is not required for the enum controls of slice 1: they are read from `@export_enum` by the bench at boot, and `check_dna_declarations` is used where a block exists (chroma_filter, visual_color_mixing, flashlight_demo all have one: checked). |
| Codex rewriting the shared files while they are read (all) | Slice 1 edits **no** file another session owns. lab.json, spatial_lab.py and spatial-lab/page.tsx were still changing at 07:52-07:57 (checked mtimes at 08:07). Every shared-file hunk is deferred until the forum (§9) is answered. |

## 2. The loop, with seconds per step

Key: **M** = measured, with source. **E** = estimate. Every E is replaced by the first receipt.

### 2.1 Page interaction (cache hit: the normal case once a recipe is prewarmed)

| Step | Time | Basis |
|---|---|---|
| Palle releases a control (enum click, or slider release, never mid-drag) | 0 | |
| Debounce | 250 ms (enum: 0 ms) | chosen |
| Corner sketch redraws (pose and framing, or exact sheet on light_table) | ~60 ms | **M** spatial-lab warm preview 59 ms (different scene, so E for this one) |
| POST /api/colour-lab: origin, 4 KB cap, validate against `controls`, hash-409 | < 20 ms | E |
| Cache key: sha256 over recipe entry, bindings, fixture, view, renderer, Godot version, and file fingerprints (fingerprints cached by mtime) | < 30 ms | E |
| Hit: 200 with the receipt; browser loads two PNGs keyed by hash | < 50 ms + PNG load | E |
| **Total on a hit** | **~0.1-0.3 s** to the real Mobile and Forward+ pictures | E |

### 2.2 Cold batch lane (base lane: works with no ruling)

The route spawns `python tools/colour_bench.py batch <request.json> --job <id>` detached (windowsHide), on the spatial-lab job pattern.

| Step | Time | Basis |
|---|---|---|
| Wait for `ada_run/void-native.lock` | 0 … minutes | Shown as **"waiting for the Godot slot (held by …)"**, never as a colour failure. Wait 600 s, not 60 s (the spatial lab's 60 s fails jobs while the slot is held). |
| `stage_runtime` (own `user://`, config/name `Ada Colour Bench <renderer>`) | ~1 s | E (34 junctions + ~300 copies) |
| Godot boot, full project, hidden window | 10-12 s | **M** spatial-lab native 10.25-12.34 s, which includes a Void build the bench does not do, so likely an upper bound |
| Per shot: free, build, ≥ 3 frames until two consecutive frames are byte-identical, `frame_post_draw`, `get_image`, sample, PNG | ~0.2-0.4 s | E from **M** Gillick 0.15 s per 1800x1200 shot (gl_compat). Albers' 98-canvas build time is unmeasured. |
| Albers enum space: 3 media × 3 views + 3 standpoints of the cubes CULL_BACK negative + 2 paint-default shots ≈ 14 shots | ~4-6 s | E |
| **Per renderer** | ~15-19 s | E |
| **Both renderers, serial under the one slot** | **~30-38 s once per recipe and fingerprint**, then every click in that space is a cache hit (§2.1) | E |
| An uncached continuous value (palette_seed=4242) | the same cold cost, ~26-30 s for both renderers (boot dominates) | E; this is the case the warm bench exists for |

### 2.3 Warm bench lane (accelerator: only after Palle's yes)

`python tools/colour_bench.py start --renderer=mobile|forward_plus` boots the same `colour_bench.gd` in `--serve` mode (~10-12 s, once). It polls `ada_run/colour-lab/<renderer>/queue/` every 0.1 s (hot_bench / capture_daemon pattern). Before every request it fingerprints the files and restarts on a mismatch, never hot-reloading class_name scripts. It exits after 10 min idle, or on a `_stop` file, or on any `vmaCreateImage` error in its log; in that last case the route falls back to §2.2.

| Step | Time | Basis |
|---|---|---|
| Queue write → picked up | 0-100 ms | poll 0.1 s |
| Fingerprint check | ~10 ms | E |
| Build + settle + readback + PNG + samples | ~0.2-0.4 s first shot of a material may be slower (shader compile; the staged `.godot` has no shader_cache) | E; first-shot against later-shot is recorded |
| Page poll | 150 ms | chosen |
| **Total per uncached variant, both renderers in parallel** | **~0.5-1.5 s** | E (truth reader) |
| Prewarm on page load (enum space, front view only, 2 renderers) | ~3-6 s | E |

## 3. Recipes

All recipes live in `commons/modular/colour_lab.json`. Controls are generated from data. Enum values are read from the artifact's `@export_enum` at bench boot, or from `check_dna_declarations` where a dna block exists, and never typed by hand (the science_screen lesson). Every bound value is read back after the build, and a mismatch is **REJECTED**, never shown as a twin (the silent typed-set trap).

### 3.1 Slice 1

**R1 `albers_glass`: Albers in glass, paint / relief / cubes**
- Source: `algorithms/primitives/homagetothesquare/albers_wall_gallery.tscn`. `medium` is stamped as `config_medium` meta before `add_child` (the Void's path: builds once), then `apply_grid_config({medium})`.
- Controls:
  - `medium` ∈ {paint, relief, cubes}, default **paint** (the artifact's default; sacred).
  - `view` ∈ {front, oblique35, close}. Camera only, not passed to the artifact.
  - `canvas` int 0..97, default 0. The front view frames that one canvas so every band is many pixels wide. The probe fails loudly if `Canvas_NN` is missing.
  - `fixture` ∈ {light_table (judged), void_evening (in situ, never judged)}.
- Bench knobs (labelled **"bench knob, not placeable"**):
  - `palette_seed` int 0..99999 (default 1337);
  - `palette_value_min`/`max` 0..1;
  - `palette_saturation_min`/`max` 0..1.
  These are set as instance exports before `add_child`. The defaults on the `.tscn` are untouched.
- Patches: on the framed canvas, 5×5 means at the centres of the outer band (A_0), the three rings (A_1..A_3) and the centre (A_4). Prewarm samples canvas 0 plus the **darkest-palette canvas**, found from the read-back colours.
- What it tests:
  - In light_table, relief and cubes must give A_0..A_4 within **3/255** on Mobile and on Forward+.
  - **Prediction for the front view:** relief and cubes are near-twins head-on and separate at oblique 35. Relief draws CULL_BACK (one crossing per slab); cubes draws closed shells (two crossings, face = √T) (checked: lines 401-406, 545-565).
  - Paint is lit by four shadowed spots: it is reported, and **not judged** for exactness.
  - Defaults check: with no bindings the build must match the shipped default's signature (`commons/testing/probe_albers_glass.gd`), every run.
- Limits:
  - 98 canvases are built per shot (build time unmeasured).
  - If one shot exceeds 1 s, prewarm narrows to canvas 0 plus the darkest canvas.
  - Clamped channels (`glass_clamped_squares` meta) are marked **"glass cannot give back light"**, which is physics, not a failure.

**R2 `chroma_filter_triad`: the slice-1 colour-relation knob**
- Source: `commons/artifacts/chroma_filter/chroma_filter.tscn`.
- Controls: `triad` ∈ {paint, light, bauhaus}, `mix` ∈ {filter, veil, solid}, `plate` ∈ {west, east}. 18 variants, all from the declared dna axes (checked: chroma_filter.json). Bound through `apply_grid_config` (chroma_filter.gd:439).
- Oracle (filter mix only):
  - The panes are `SHADING_MODE_UNSHADED` + `BLEND_MODE_MUL` (checked: lines 296-298).
  - The bench shoots the same pose twice: once with the panes set to `layers = 0` (giving "behind"), once with them visible.
  - Expected overlap = behind × albedo_a × albedo_b in linear light. The albedos are read back from the built materials.
  - This is a relative oracle. It tests the multiply, not the backdrop, and is labelled so.
- veil and solid: judged by bite only (per-pair rows, never the headline: the tier_terrarium lesson). Exact only if their read-back materials are unshaded.
- What it tests:
  - Whether walk-scale MUL multiplies the same way on Mobile and Forward+.
  - Whether changing the triad changes the overlap as the arithmetic says. This is the first knob that changes *which colours meet*.

### 3.2 Slice 1b: from the colour proposal (needs no grammar change)

**R3 `visual_color_mixing_subtractive`: a real bug the lab should catch**
- Source: `algorithms/color/color_mixing/visual_color_mixing.tscn`, axis `mixture` ∈ {bench, light, pigment, retina} (declared).
- The artifact itself documents a latent bug: the shipped scene sets `blend_type = 0` (ADDITIVE) on all nine "subtractive" disks, so C+M+Y would come out **white** (checked: visual_color_mixing.gd:141-146). The `pigment` variant sets SUBTRACTIVE.
- Prediction, written before capture: the CMY triple-overlap patch is near white (> 230/255 all channels) under `bench`, and near black (< 40/255) under `pigment`, on both renderers.
- Standpoints: near 0.6 m and far 4 m. `retina` is predicted to be a TWIN of the pigment-like patches near and to diverge far.
- Verdict: a prediction check plus bite, not a 3/255 oracle. The disks are lit and their shader is not yet read.

**R4 `flashlight_relief`: coloured light and relief shadows (lit, calibrated)**
- Source: `algorithms/postprocessing/flashlight_demo/flashlight_demo.tscn`, axis `ground` ∈ {white, swatch, relief, mirror, none} (declared in shaders.json). Every lamp already has `shadow_enabled` (checked: line 279).
- Fixtures: `grey_card` (one known lamp) and `void_evening`.
- Labelled **"lit: calibrated, no oracle"**. The page shows bite per pair, shadow-patch luminance, and a Mobile/Forward+ split badge (shadow filtering differs by renderer, so a split is evidence, not a fail).
- Depends on R5 for the gain.

**R5 `grey_card_ramp`: calibration, built into the fixture, not a term**
- Parameters:
  - `steps` 17 (sRGB 0..255), unshaded, drawn as `vertex_color_use_as_albedo + vertex_color_is_srgb = true`;
  - one extra patch **without** `vertex_color_is_srgb`, which must fail (the mod_pso/mod_trail fault);
  - `lamp_energy` 0.25..4, one DirectionalLight3D and one OmniLight3D, no shadows;
  - `tonemap` ∈ {linear, filmic, aces}.
- What it tests:
  1. The quantisation floor per renderer near black.
  2. One measured gain per lane, which replaces the unmeasured `energy*2` (modular-terms.ts:490) and `energy*PI` (void-lighting.ts:47-48) with a number in colour_lab.json `calibration`.
  3. What each tonemap does to a known grey.

### 3.3 Later (not this spec's build; forum first)

`filter_pair` (two sRGB hex sheets, a×b) needs additive grammar keys `colors`, `shading: unshaded` and `blend: mul` in **both** `commons/modular/builder.gd` and `src/lib/modular-terms.ts`. Both are shared and modified by Codex today. Those keys follow the grid-change discipline: gated by key presence, before/after signature of the existing lab_* recipes, and a negative proving the key bites.

## 4. Colour-truth contract (preview and native picture)

### 4.1 One number

For an exact recipe the expected sRGB8 value is computed **once**, in `colour_bench.gd`, from the bytes the built mesh holds:
- Albers: `GlassHomages` and `GlassBacking` vertex colours (sRGB8) are decoded to linear. Relief: A_k = B·∏T_j. Cubes: A_k = B·∏face_j².
- chroma_filter: read-back albedos.

It is never taken from the artifact's own metas (SPEC §5.4). There is no TypeScript solver. The page receives the number in `samples.json` and draws it as a CSS swatch (CSS hex is sRGB).

### 4.2 The fixture, declared once (`colour_lab.json fixtures.light_table`), read by both bench and page

| Setting | Value |
|---|---|
| Render target | SubViewport 1024×768, `own_world_3d`, `UPDATE_ALWAYS`, `msaa_3d` off. Never the root window, whose size depends on the window and DPI. |
| Camera | Orthographic, head-on. Extents per view are declared in the fixture. |
| Environment | `TONE_MAPPER_LINEAR`, exposure 1. No glow, fog, SSAO or adjustments. Known `BG_COLOR`. No lights (glass and backing are unshaded). |
| Frames | ≥ 3, until two consecutive frames are byte-identical, then `await RenderingServer.frame_post_draw`, then `get_image()` |
| Process | `--rendering-method mobile` or `forward_plus`, `--rendering-driver vulkan`, `--xr-mode off`. Hidden: STARTUPINFO SW_HIDE, `--position -10000,-10000`, small `--resolution`. **Never `--headless`** (draws no frames). **Never `--no-window`** (not a 4.6 flag: the spatial lab flashes a 1440×1000 window). |
| Receipt records | `Engine.get_frames_drawn()`, `RenderingServer.get_video_adapter_name()`, renderer string from the log, MSAA, frame-3 against frame-10 max delta, Godot version |
| Publish guard | Refuse to publish if `frames_drawn == 0` or subject share < 5% of frame |
| Sampling | 5×5 means at patch centres only, no edge pixels |

`void_evening` (atmosphere.gd environment, sampled after 30 converged frames) is a second shot labelled **"in situ, not judged"**.

### 4.3 Who decides

- **Mobile is the verdict.** It is labelled on every frame **"desktop Mobile (RTX 3070, Vulkan): Quest proxy, not the headset"**.
- **Forward+** is shown as comparison.
- A **Mobile−Forward+** delta is a third column. A split beyond 3/255 shows a "renderer split" badge: Mobile stands as the verdict and Forward+ is kept as evidence.
- `gl_compatibility` is never used for colour.
- A **"Quest: not measured"** lane stays on the page. It names what differs: Adreno, OpenXR sRGB swapchain (possibly no separate tonemap blit), foveation level 3 (sample centres only), and the panel. The future lane is a `colour_shot` command over vr_link.py's socket (adb reverse 8771), or `get_image` to `user://` pulled as `pull_vr_feedback.py` does.

### 4.4 The browser sketch, and where it may be compared

- **Pose only** (default, and always in lit, tonemapped or GLB-sourced fixtures): fixed banner **"sketch: pose only, colour not comparable"**. No delta is shown.
- **Exact, light_table only:** the bench writes `mesh-data.json` per variant (positions, indices, sRGB8 colours, flags `blend=mul`, `unshaded`, `cull=disabled|back`). The sketch draws it literally:
  - `MeshBasicMaterial({vertexColors:true, toneMapped:false, transparent:true, blending:MultiplyBlending, premultipliedAlpha:true, depthWrite:false, side: cull==='disabled' ? DoubleSide : FrontSide})`;
  - vertex colours converted sRGB8 → linear floats on load;
  - backing opaque;
  - rendered into a linear **HalfFloat** render target, then one sRGB output pass.
  - Values are read with `readRenderTargetPixels` on the linear target and sRGB-encoded in JS. One `drawImage` canvas readback proves the output pass encodes the same way.
  - This fills a **THREE** column judged against the same oracle.
  - No rAF dependency (the browser pane fires none). Verified in Chrome.
- **Disagreement:**
  - THREE vs Mobile over 3/255 shows the banner "preview differs from native Mobile by N/255 at <patch>; trust the native picture".
  - Nothing is averaged.
  - Failing cells turn red with the signed per-channel delta.

### 4.5 Staleness is part of the truth

- When the controls have moved past the last native picture, that picture is dimmed and captioned "showing medium=relief, rendering cubes".
- Every receipt and mesh-data file carries sha256 of:
  - the artifact `.gd` and `.tscn`;
  - `colour_bench.gd`;
  - the recipe entry;
  - the fixture;
  - Godot version, renderer and adapter.
- If disk differs from the receipt: the cached picture is greyed "stale", the sketch refuses to draw old glass ("sheet needs re-reading"), and a warm bench restarts.

### 4.6 Before the first capture: write the prediction (lower-bound rule)

Into `colour_lab.json predictions` and the registry `dna.predicted_degeneracy` **only where the owner agrees**:
1. Forward+ passes all light_table patches.
2. Mobile worst patch = darkest-palette canvas centre A_4, cubes.

Before writing (2), read Godot 4.6-stable's Mobile scene shader for how the 10-bit buffer's `luminance_multiplier` (0-2 range stored halved) meets fixed-function `BLEND_MODE_MUL`. Write both outcomes:
- (a) quantisation only: a miss of ≤ ~6/255 near black, mid-tones < 1/255;
- (b) the fragment output is halved before `dst*src`: each crossing loses a factor 2, a gross failure (cubes centre after 2×4 crossings far below A_4).

A measured miss **below** the prediction by a large factor means stop and look at the PNG (the operations_gallery rule). The Mobile fallback (ShaderMaterial with a measured gain) is the Albers session's and Palle's call, not the lab's.

## 5. File changes and ownership

| File | Change | Owner | Slice |
|---|---|---|---|
| forum (`python tools/forum.py`) | (1) New heads-up to the spatial-lab owner (§9). (2) Answer on **261027-odz4a** to opus-colour: the bench reads `medium` and the palette exports read-only, edits nothing, runs SPEC §5.5's pixel oracle and CULL_BACK negative for them, and kept palettes come to them as proposals. | nobody | 0 |
| `C:/Users/palle/Documents/GitHub/AdaResearch_46/commons/modular/colour_lab.json` **(new)** | `version, title, notes`, plus the per-recipe blocks listed below | ours (new file in Codex's folder; Codex is told in the forum post) | 1 |
| `C:/Users/palle/Documents/GitHub/AdaResearch_46/commons/testing/colour_bench.gd` **(new, extends SceneTree)** | One script, two modes: `--once <batch.json>` (cold lane) and `--serve` (warm lane). It does the following: builds the fixture from colour_lab.json; instantiates the source, sets exports, stamps `config_*` metas, then `add_child`, then `apply_grid_config`; reads values back (REJECTED); runs the stable-frame rule; samples; computes the oracle (small per-kind functions named by the recipe: `oracle_albers_relief`, `oracle_albers_cubes`, `oracle_mul_relative`); runs negatives (§7); writes PNG, `samples.json` and `mesh-data.json`; asserts frames > 0 and subject share. Patterned on `camera_pixels_gpu.gd`, `capture_daemon.gd`, `hot_bench.gd`, `colour_flashlight_probe.gd`. | ours | 1 |
| `C:/Users/palle/Documents/GitHub/AdaResearch_46/tools/colour_bench.py` **(new)** | Subcommands and behaviour listed below | ours | 1 (`batch`, `check`, `prune`), 2 (`start`/`stop`/`status`/`shoot`) |
| `C:/Users/palle/Documents/GitHub/AdaResearch_46/tools/test_colour_lab.py` **(new)** | No-Godot tests (§7.1) | ours | 1 |
| `C:/Users/palle/Documents/GitHub/ada_encyclopedia/src/lib/lab-jobs.ts` **(new)** | Shared helpers: origin check, size cap, job id, request write, detached spawn (windowsHide), job polling, live-pid 409, hash-409, freshness re-hash. Used by the colour route **only**; offered to Codex for the spatial route. | ours | 1 |
| `C:/Users/palle/Documents/GitHub/ada_encyclopedia/src/app/api/colour-lab/route.ts` **(new)** | GET: spec, bench status (alive, booted, negative result), cache index with stale flags, `?job=`. POST: validate against `controls`, cache key, hit 200, or miss → warm queue if alive, else `colour_bench.py batch` → 202. | ours | 1 |
| `C:/Users/palle/Documents/GitHub/ada_encyclopedia/src/components/colour-lab/ColourLab.tsx` **(new)** + `ColourSketch.tsx` **(new)** | The whole UI (listed below). Mountable by /spatial-lab later. | ours | 1 (pictures, table, receipt), 1c (sketch exact mode) |
| `C:/Users/palle/Documents/GitHub/ada_encyclopedia/src/app/colour-lab/page.tsx` **(new)** | ~10-line shell mounting `<ColourLab/>`. Its header says "staging address; will be a family tab of /spatial-lab". | ours | 1 |
| `public/colour-lab/` | Must be gitignored (no images in git; repo rule 2026-10-08/09). Check `.gitignore` before the first write. | ours | 1 |
| `algorithms/primitives/homagetothesquare/albers_wall_gallery.gd` | **No change.** A later additive ask to opus-colour: `apply_grid_config` also accepts `palette_seed` and the palette ranges when present (an absent key is a no-op; 7 grid placements, em_plan and Void floor 35 stay byte-identical). | opus-colour (uncommitted, M) | never by us |
| `commons/artifacts/registry/algorithms_misc.json` / `color.json` (albers dna block) | No change by us. `apply_dna_block.py --axes=medium` and `predicted_degeneracy` are opus-colour's step (SPEC step 8). | opus-colour | never by us |
| `commons/modular/lab.json`, `terms.json`, `tools/spatial_lab.py`, `src/app/spatial-lab/page.tsx`, `src/app/api/spatial-lab/route.ts` | **Nothing** until the owner answers. Proposed merge: recipes gain `family`; per-recipe `controls`/`limits_colour` replace the hard-coded `controls` and flat `limits`; the spatial route adopts `lab-jobs.ts`; page.tsx mounts `<ColourLab/>` for `family: colour` (one hunk). | Codex spatial-lab session (untracked, edited 07:52-07:57) | 3, by agreement |
| `commons/modular/builder.gd`, `src/lib/modular-terms.ts` | `colors` / `shading` / `blend` keys for `filter_pair`. Separate forum post. | shared (Codex M today) | later |

`colour_lab.json` contents:
- Per recipe: `id, label, defaults` (lab.json shape) plus `family:"colour"`, `source` (token + scene), `controls` (`{key, kind: enum|int|range, label, from: export_enum|dna|limits, placeable: bool}`), `fixture`, `views`, `patches`, `oracle` (exact | relative | prediction | calibrated), `prewarm`.
- Top-level blocks: `fixtures` (`light_table`, `void_evening`, `grey_card`), `renderers: ["mobile","forward_plus"]`, `tolerance_255: 3`, `predictions` (written before capture), `calibration` (filled by R5), `kept` (pins), `limits_colour`.
- Write it surgically with a 2-space indent and no json.dumps round trip of anyone else's file.

`tools/colour_bench.py` subcommands:
- `batch <request> --job <id>`: cold lane. For each renderer, run `acquire_native_slot` (600 s), then `stage_runtime` (own `user://`), then Godot under `godot_watchdog.py --expect=<lane>/samples.json` (boot grace 45 s, 16 s stall), then `void_log_diagnostics.split_errors`. Copy outputs to `ada_encyclopedia/public/colour-lab/<key>/` and write the receipt using the spatial-lab job protocol (queued, testing, complete or failed).
- `start|stop|status|shoot`: warm lane (slice 2).
- `check`: negatives (§7); exit code = failure count.
- `prune`: keep the last 50 keys plus everything in `kept`, and delete this bench's own stage dirs. Do not add to the 591 already under `ada_run/void-trial-runtime`; reuse one stage per renderer per fingerprint.
- `critic <key-a> <key-b>`: pair bite per standpoint by **importing** `diff`/`focus_rgb` from `tools/artifact_dna_critic.py`.
- Also imports `void_native_slot`, `void_trial_runtime`, `void_log_diagnostics` and `check_dna_declarations` read-only.
- Registers no trial, writes no `playable.json`, does no GLB export, and writes nothing under `commons/void/`.

`ColourLab.tsx` contents:
- controls from `controls`;
- Mobile large, Forward+ beside it, flicker/difference toggle, A/B blink (hold a key);
- per-patch table: EXPECTED, MOBILE, FORWARD+, THREE, M−F+ with Δ/255;
- badges: REJECTED, stale, renderer split, lit calibrated, clamped, "desktop Mobile, not Quest";
- receipt timings with E→M replacement;
- bench health with the negative shown failing;
- Keep/pin, which writes a pin via a route POST: bindings, key and deltas into `kept`;
- "reuse settings";
- "Quest: not measured" lane;
- "waiting for the Godot slot" state.

## 6. Build order (each step verifiable alone)

0. **Forum.** Post §9. Answer 261027-odz4a. Confirm `.gitignore` covers `public/colour-lab/`. No other file is touched.
1. **Prediction.** Read the Mobile shader (see §4.6). Write `predictions` in `colour_lab.json` with both Mobile outcomes, R3's white/black prediction, and the relief~cubes front-twin prediction.
2. **Bench, cold, CLI only.**
   - Run `colour_bench.gd --once` for `albers_glass` and `chroma_filter_triad` when the Godot slot is free, one renderer at a time.
   - Gates: the negatives fail as they must (§7.2), Forward+ oracle passes, frames_drawn > 0, frame-3 against frame-10 recorded, first-shot against later-shot recorded, boot seconds recorded.
   - Compare against the predictions. If a measurement comes in below a prediction, stop and look at the PNG.
3. **Route + lab-jobs.ts + ColourLab page** (native pictures and table only).
   - Gate in Chrome: enum clicks after one batch are cache hits under 0.3 s; a stale fingerprint greys the picture.
4. **Sketch exact mode** on light_table.
   - Gate: the THREE column fills, the FrontSide negative misses the centre, and the drawImage readback agrees with readRenderTargetPixels within 1/255.
5. **R3, R4, R5.** R5 writes `calibration`; R4 then shows calibrated deltas.
6. **(After Palle's ruling) warm bench.**
   - Gate: an uncached `palette_seed` returns in the measured warm time, which is written into the receipt.
   - Idle exit works.
   - A `vmaCreateImage` error falls back to cold.
7. **(After the owner's answer) merge** into /spatial-lab as a family tab (§5 last rows).

**Done for slice 1:**
- Palle opens the lab and picks Albers / cubes / canvas 0 / front.
- After one ~35 s batch, every medium, view and triad click shows real Godot Mobile and Forward+ pictures in under 0.3 s.
- A palette_seed change shows its real picture in ~26-30 s cold, or ~1 s warm once ruled.
- The table shows A_0..A_4 against both renderers with Δ/255.
- The negatives are shown failing.
- Kept variants survive pruning.
- The Quest lane reads "not measured".

## 7. Verification

### 7.1 `python tools/test_colour_lab.py` (no Godot)
- Oracle maths: relief and cubes on a hand-computed 2-ring case; sRGB encode/decode round trip on all 256 bytes.
- **Sabotaged-oracle negative:** feed a samples set whose measured values sit 4/255 off expected. The verdict function must return FAIL with the right patch and channel. This proves the comparison code path itself can fail, independently of rendering.
- Cache key changes when any fingerprinted file, the Godot version or the renderer changes.
- Controls validation rejects an unknown enum value and an out-of-range int.
- Drift gate: colour receipt `timing` keys ⊇ spatial-lab receipt `timing` keys; colour recipe entry keys ⊇ lab.json recipe entry keys.

### 7.2 `python tools/colour_bench.py check` (Godot; exit code = failures)

| Negative | Must |
|---|---|
| Albers cubes glass material forced to `CULL_BACK` after build (one crossing per shell) | **Miss** the centre A_4 by > 3/255 on both renderers. If it passes, the bench marks itself untrustworthy and the page shows no verdicts. |
| R5 patch built without `vertex_color_is_srgb` | **Miss** its expected byte (the mod_pso/mod_trail fault) |
| Launch with `--headless` | **Refuse** to publish: frames_drawn == 0 |
| Typed set of `medium` with an int / unknown word | **REJECTED** in the receipt, not rendered as a twin |
| chroma_filter `filter` with one pane at `layers = 0` | Overlap ≠ the a×b prediction (proves the relative oracle can bite) |
| Touch `albers_wall_gallery.gd` mtime + content hash change | Receipt **stale**, warm bench restarts |
| Browser: cubes drawn `side: FrontSide` | **Miss** the centre by > 3/255 |
| Defaults: no bindings | Signature identical to the shipped default every run |

### 7.3 Untouched-neighbour check
Run `node tools/test_spatial_lab_editor.cjs` before and after. It must still give 11 passes. We edit none of its files, and this proves it.

## 8. Rulings Palle is asked for

1. **Warm benches outside `void-native.lock`.** Proposed: one per renderer, a per-renderer lock, idle exit after 10 min, exit on a VRAM error, and an optional Mobile-only mode. This relies on the 2026-09-17 "many instances are fine" ruling (VRAM is the limit). Without a yes, the lab runs the cold lane only.
2. **The merge into /spatial-lab** as a family tab, once the Codex session agrees.
3. **The Albers palette knob:** whether opus-colour should accept `palette_seed` and the palette ranges additively in `apply_grid_config`, so kept palettes become placeable.

## 9. Risks that remain (named, not solved)

- **Desktop Mobile is not the Quest.** The verdict is a proxy, labelled everywhere. The on-device lane is unbuilt.
- **Albers' 98-canvas build time and shader compilation on a fresh stage are unmeasured.** Prewarm narrows automatically if a shot exceeds 1 s.
- **The native slot is shared.** The cold lane waits behind other workflows' Godot runs, shown as waiting, not failing.
- **The bench depends on opus-colour's uncommitted `medium` work.** It is fingerprinted, so a change there marks pictures stale rather than lying.
- **Two copies of the job protocol exist until Codex adopts `lab-jobs.ts`.** The drift gate in §7.1 is the guard.
- **Lit recipes (paint, R3, R4) can never be "equal" across renderers.** If the "calibrated" labels are ever removed, the page becomes misleading.


## Critic (verdict: REVISE)

REVISE, do not build as written. The loop itself holds up. Slice 1 (steps 0-3) would close a real loop for enum controls: control, POST, cache or cold batch under the native slot, then Mobile and Forward+ PNGs plus samples on the page, then cache hits. Most cited files and functions exist: void_native_slot, stage_runtime, split_errors, artifact_dna_critic diff/focus_rgb, camera_pixels_gpu, hot_bench, capture_daemon, colour_flashlight_probe, vr_link port 8771. The cited lines are correct for the Albers medium and palette exports and apply_grid_config, for chroma_filter 296-298/439, for the visual_color_mixing latent-bug comment 141-146, and for void-lighting 47-48 (energy*2 has drifted to modular-terms.ts:491). But within about 15 minutes of synthesis the spec was overtaken on its own first recipe. opus-colour built and ran probe_albers_glass_render.gd: Mobile MUL measured at about 0.5 per layer (outcome b), the Albers glass switched to a gain-corrected ShaderMaterial, and verdict PASS on Mobile and Forward+ with the cull-back negatives biting. So colour_bench.gd's R1 oracle, fixture and negative would be a second implementation drifting from the owner's (the long_museum.py trap), the §4.6 prediction can no longer come before capture, and the 'checked' glass citations are out of date. Four other 'checked' facts are wrong: paint is unshaded and not lit, chroma_filter has 9 dna variants not 18, the GrabDisks are unshaded, and no CMY overlap patch exists under bench. Slice 1 cannot keep 'edit nothing shared': .gitignore does not cover public/colour-lab, and stage_runtime is parameterless and hard-codes its config/name. R2, the one new colour-relation knob, has no fixture, so its relative oracle cannot bite. The timing-key drift gate guards the wrong surface. Fix: make the lab a front end over the owners' probes (run probe_albers_glass_render.gd per renderer and read its JSON). Point slice 1's new value at R2 and R3, with the Mobile half-gain prediction written first and a declared lit fixture for chroma_filter. Correct the misread facts, add --no-bridges, and post to both the modular-kernel thread and the opus-colour thread before touching anything.

### Unsupported claims

- 'Paint is lit by four shadowed spots ... reported, and not judged': not true of the patches the lab samples. The homage squares use _paint_material, which is SHADING_MODE_UNSHADED with vertex_color_use_as_albedo and no vertex_color_is_srgb (albers_wall_gallery.gd:149-156, mesh colours 331-340). Only the canvas border, frames and wall are lit. Paint's squares can therefore be predicted exactly, and they show the palette bytes read as linear (the 'pastel' in doc/colour/albers_glass/SPEC.md:11).
- R2 '18 variants, all from the declared dna axes (checked: chroma_filter.json)': the dna block declares only mix and triad, which is 9 variants. plate comes from @export_enum only, and the code calls it 'Furniture, not DNA ... Never swept' (chroma_filter.gd:178-179).
- R3 'The disks are lit and their shader is not yet read': GrabDisk is SHADING_MODE_UNSHADED. ADDITIVE is BLEND_MODE_ADD at alpha 0.7 and SUBTRACTIVE is BLEND_MODE_MUL at alpha 0.8 (commons/primitives/disks/grab_disk.gd:66-76).
- R3 prediction 'CMY triple-overlap patch near white under bench': no such patch exists under bench. The header says 'every disk parked in its hue column, nothing overlapping', and _lay_venn runs only in light and pigment (visual_color_mixing.gd:30-34, 130-146). No declared variant shows the latent ADD bug as a white triple overlap.
- Albers glass 'BLEND_MODE_MUL ... (checked: lines 401-406, 545-565)': out of date since 08:17. _make_glass_material now returns a ShaderMaterial (blend_mul, a gain uniform, GLASS_MUL_GAIN = {forward_plus 1.0, mobile 2.0}) at lines 542-581. Lines 545-565 now hold the gain comment and the shader source.
- §4.6/§6 step 1 'write the prediction before the first capture': the capture has already happened. At 08:19-08:20 probe_albers_glass_render.gd measured the Mobile MUL gain at 0.498/0.513/0.498, which is outcome (b). ada_run/albers_glass_oracle.json reads verdict PASS for mobile and forward_plus, relief and cubes, and the cull-back negatives bite.
- 'stage_runtime (own user://, config/name Ada Colour Bench <renderer>)', 'reuse one stage per renderer per fingerprint' and 'imports void_trial_runtime read-only' cannot all hold. stage_runtime() takes no arguments, hard-codes config/name 'Ada Void Trial Test' and makes a fresh mkdtemp run-* every call (tools/void_trial_runtime.py, which another session has modified). Stage count is now 595, not 591.
- 'waiting for the Godot slot (held by …)': tools/void_native_slot.py records no holder. It is a one-byte msvcrt lock, and the label is printed only by the waiter, so the page cannot know who holds the slot.
- Step 0 'Confirm .gitignore covers public/colour-lab/ ... No other file is touched' and 'Slice 1 edits no file another session owns': the encyclopedia .gitignore does not cover it (git check-ignore exits 1; there is no png rule). Covering it means editing a shared file.
- Cold boot '10-12 s ... likely an upper bound': the 10.25-12.34 s figure is a gl_compatibility run. The bench runs Vulkan Mobile and Forward+ on a fresh stage with no shader_cache, so nothing cited bounds it.
- §7.3 'We edit none of its files, and this proves it': running tools/test_spatial_lab_editor.cjs overwrites ada_run/spatial-lab-2026-10-27/editor-checks.json, creates editor-fixture-* dirs in Codex's run folder, POSTs to /api/spatial-lab and needs :3003 up. The '11 passes' count depends on argv and on a test Codex is still editing (07:46).
- Drift gate 'colour receipt timing keys ⊇ spatial timing keys': the spatial keys include export_process_seconds, save_seconds and check_total_seconds (spatial_lab.py:73-141). The colour lane has no export or save step, so it would have to emit placeholder keys. The spatial receipts also live in an ignored, dated folder (ada_run/spatial-lab-2026-10-27).
- R5 'replaces the unmeasured energy*2 (modular-terms.ts:490) and energy*PI (void-lighting.ts:47-48)': §4.4 forbids three.js colour comparison in lit fixtures (pose only), so nothing measures the three.js side of a Godot-to-three conversion. Changing either factor also edits files the §5 table does not list (modular-terms.ts is Codex M). energy*2 is now at line 491.
- Done criterion 'After one ~35 s batch, every medium, view and triad click ... under 0.3 s': triad belongs to R2, a separate batch. Any canvas other than 0 or the darkest is a cold miss. The '≈14 shots' count leaves out the darkest-canvas set and the void_evening shots, so the batch time is undercounted.
- Cache key includes 'Godot version' within '< 30 ms' in the route: the spec gives the Node route no way to learn the Godot version without a boot or an earlier receipt.
- 'on the spatial-lab job pattern ... spawns detached': the spatial route.ts:68 spawns with windowsHide and stdio:'ignore', not detached (minor).
- '--no-window is not a 4.6 flag': only one memory note supports this (feedback_headless_multimesh_reads_back_identity.md). CLAUDE.md, other memory notes and tools/test_transfer_native.py and capture_*_sequence.py use the flag. Not checked on the binary (minor; the spec's advice is harmless either way).

### Missing

- Reuse of the owner's rendered oracle. commons/testing/probe_albers_glass_render.gd (opus-colour, untracked, 08:19) already does R1: linear-tonemap SubViewport fixture, orthographic camera, 5×5 patches, mesh oracle from read-back vertex colours, a frames_drawn guard, --force-cull-back negative, --canvas=auto, and mobile plus forward_plus runs. colour_bench.gd's oracle_albers_relief/cubes would be a second implementation of it, a third counting probe_albers_glass.gd check (c) and a fourth counting test_colour_lab.py's Python 2-ring maths. Its light_table (1024×768, BG_COLOR) is a second fixture beside the probe's (1000 px, black, ORACLE_SPAN 0.5). This is the long_museum.py trap. The lab should call that probe per renderer, or its static achieved/t_lin/t_srgb, and read its JSON.
- The Mobile half-gain on every StandardMaterial3D BLEND_MODE_MUL: chroma_filter.gd:298, grab_disk.gd:75 (R3 pigment) and color_display_disk.gd:61. R2 and R3 need a written prediction that Mobile misses by about ×0.5 per MUL layer. This is the lab's biggest real catch for the Quest and the spec never names it.
- R2 has no declared fixture. chroma_filter's white corner is shaded and brings no light ('the light is the hall's'). Under light_table (no lights) 'behind' is black or ambient only, so behind×a×b passes trivially. Under a lit fixture 'behind' can exceed 1.0 before the linear tonemap clips, which breaks a relative oracle computed from the 8-bit PNG.
- A label for paint vs glass. Paint shows the palette bytes as linear (no vertex_color_is_srgb), while glass reproduces lin(C_k). The media will differ by design, and the page must say so instead of letting Palle read glass as 'darker'.
- The --no-bridges user arg in the bench command. The full-project boot runs 27 autoloads, including VRLink (port 8771) and NatureRenderer, whose capture guard is at NatureRenderer.gd:53.
- R4: flashlight_demo.tscn embeds its own WorldEnvironment (dark, ambient 0.15). The spec does not say how the grey_card and void_evening fixtures override it (for example Camera3D.environment).
- void_evening: atmosphere.gd animates the sky by default (animate_sky=true, 720 s cycle), so a cached picture depends on time. The spec needs animate_sky=false or a fixed set_sky_time.
- The defaults-signature check: the baseline ada_run/albers_paint_signature.json was taken headless, and nobody has checked that it hashes the same under a windowed Mobile or Forward+ renderer. probe_albers_glass.gd itself changed at 08:21.
- How A_1..A_3 ring patch centres are located under vertical_bias: from the mesh AABBs, or by re-deriving the artifact's layout rule (another duplicate).
- One owner for the verdict (Δ/255, PASS/FAIL, rounding, per-channel rule). Right now it is implied in GDScript (bench), Python (test_colour_lab's verdict function) and TS (THREE column and table). Only tolerance_255 is shared.
- Forum coverage: commons/modular/ also belongs to the modular-kernel thread 261023-xva5y (fable-blender-void), not only Codex. opus-colour is actively holding the Godot slot (08:19-08:22) and has superseded the planned answer on 261027-odz4a.
- Kept pins: the route writes them into tracked commons/modular/colour_lab.json, which mixes runtime state with authored recipes and predictions and gives git churn. There is no conflict rule against hand edits.
- Measured numbers already on disk should replace the estimates: frames_drawn 8, adapter RTX 3070, 1000×1000 image, Godot 4.6-stable, from ada_run/albers_glass_render/*.json.

## Forum post drafted for the spatial lab's owner (not posted)

COMMAND (not yet posted; run after Palle reads it):
python tools/forum.py ask "Spatial lab: a colour family is coming. New files only, nothing of yours touched; a merge offer and three findings from reading it" "<body below>" --tags=spatial-lab,colour,codex,heads-up,lab --as=claude-colour-lab --claims=commons/modular/colour_lab.json,commons/testing/colour_bench.gd,tools/colour_bench.py,tools/test_colour_lab.py,ada_encyclopedia/src/lib/lab-jobs.ts,ada_encyclopedia/src/app/api/colour-lab/route.ts,ada_encyclopedia/src/app/colour-lab/page.tsx,ada_encyclopedia/src/components/colour-lab/

BODY:
To the Codex session that built /spatial-lab this morning (rollout 2026-10-23T13-10-48-01a14db6, files edited up to 07:57), and to Palle, who may need to relay this.

Palle asked for "a system like /spatial-lab for fast colour tests". We are building one in the same shape as yours: a recipe in data, controls, a job, a receipt. The difference is that its result is a native Godot picture judged in pixels.
- Mobile (the Quest's renderer) and Forward+, each shown against one oracle number per patch, within 3/255.
- Light-table fixture: orthographic, TONE_MAPPER_LINEAR, unshaded, fixed SubViewport.
- A CULL_BACK negative that must fail.
- First recipes: the glass Albers (paint/relief/cubes, owned by opus-colour, 261027-odz4a) and chroma_filter's triad × mix.

WHAT WE WILL NOT TOUCH. None of your files: lab.json, terms.json, spatial_lab.py, spatial_lab_probe.gd, spatial_lab_inputs.gd, recipe_area.*, lab_input.gd, playable.json, line_parts.json, api/spatial-lab/route.ts, spatial-lab/page.tsx, builder.gd, modular-terms.ts. We register no trial, do no GLB export and write nothing under commons/void/. We import tools/void_native_slot, void_trial_runtime and void_log_diagnostics read-only. Everything we write is listed in --claims.

WHERE WE SIT. commons/modular/colour_lab.json sits beside your lab.json. Its recipe entries are a strict superset of yours (id, label, defaults, plus family, controls, fixture...), so a merge is a move. /colour-lab is a staging address: a 10-line shell around one component (src/components/colour-lab/ColourLab.tsx). Job mechanics (origin check, 4 KB cap, request file, detached spawn, poll, pid-409, hash-409, freshness re-hash) go into a new src/lib/lab-jobs.ts, so we do not copy your route.

WHAT WE OFFER (your call, no change before your answer):
1. Recipes gain `family` and per-recipe `controls` / `limits`. That replaces page.tsx's hard-coded controls and the flat limits table.
2. Your route adopts lab-jobs.ts, so there is one job implementation, not two.
3. /spatial-lab mounts <ColourLab/> as a `family: colour` tab, as one hunk in page.tsx, and /colour-lab goes away.

THREE FINDINGS FROM READING YOUR LAB (useful whether or not you merge):
- `--no-window` is not a Godot 4.6 flag. spatial_lab.py's native run opens a real 1440x1000 window at 100,80 for about 12 s. tools/capture_colour_wall_studies.py hides it instead with STARTUPINFO SW_HIDE plus --position -10000,-10000.
- The native check renders with gl_compatibility. That is neither the Quest (Mobile) nor desktop default (Forward+), so its photographs are a third renderer. The GLB bridge (export_void_editor.gd mesh_copy) turns ShaderMaterials grey and glTF has no MUL, so colour cannot reach the three.js preview by that route. That is why our preview draws read-back mesh data instead.
- The job path has no godot_watchdog.py (only 150/300 s subprocess timeouts), and the 60 s native-slot wait fails a job whenever another workflow holds Godot. Our lane waits up to 600 s and shows "waiting for the Godot slot" instead.

FOR PALLE (rulings, nothing is built that needs them):
(a) May warm per-renderer colour benches run outside ada_run/void-native.lock? Proposed: per-renderer lock, idle exit after 10 min, exit on any vmaCreateImage error, optional Mobile-only mode. Without a yes, the lab runs cold only: about 35 s once per recipe, then cache hits.
(b) Merge into /spatial-lab once this session agrees.

Measured from your receipts (thank you, they made this cheap to plan): save 0.038 s, export 12.77 s, native 12.34 s, end to end 25.49 s. Our estimates are marked E until our first receipt replaces them.
