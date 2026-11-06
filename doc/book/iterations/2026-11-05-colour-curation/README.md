# Colour, floors 30-37, tested and curated (2026-11-05)

Palle: *"test and curate other artifacts ... start from the color sequence and suggest improvements and tell me how
they fit into the room and how they need scaffolding to convey their message, fit in the space, have presence; many
work but others not fully."* Then, on the morning note: *"go"* (apply the moves) and *"the spectrum forest must have
a full ceiling that we want see from above and below."*

Two passes in one day. The morning survey (the floor-by-floor section, corrected below) found three floors placed
wrong and four works outside the building; the afternoon applied the moves, re-measured them in the tower, and found
that two of the morning's verdicts were wrong. The corrections come first, because the forum post of 09:32 repeats
the wrong ones.

## Corrections to the morning's findings

| morning claim | what was actually the case | how it was caught |
|---|---|---|
| 34: the pillar field is drawn across shaft A, four samples in the hole | the field's Void layout (`_build_void_gallery`, seven lanes at x -18/-14/-6/0/6/14/18, rows z -6..6) stands between and beside the shafts; the "field over the hole" photo was **floor 35's forest seen down through shaft A** | the tower descends (floor f at -6f); the survey now records world boxes and faults per work |
| 35: the forest hangs in shaft A - broken fit | **it stands in the shaft on purpose.** Palle: a full ceiling, seen from above and below. Its 6 x 6 m footprint is the opening; it has no bodies, so the fall is still safe | Palle, early afternoon, after I had moved it onto the slab; moved back |
| 34: the sets wall shows a blank back to the hall | the camera at (14, 0) stood **inside a pillar of the field**; the frame was the pillar's inside, at facing 270 and at 90 alike. The real fault was different: the wall stood at x 18.25, **in the field's x 18 lane, three pillars through the board** | the from-the-edge photo showed a pillar in the middle of "COLOUR COLLECTIONS" |
| 37: the hallway is a small work in the sky at z 13.4 | a **24 m x 8 m CSG tube** (12 segments of 2 m, radius 4 -> 1.5) running the floor's whole depth, mouth past the south edge, lower half through the slab | world box: y -3.3..5.3 with the mount at height 1 |
| 37: the Gillick bays are misplaced, half outside | they are half outside **because the shafts are there**: a 12.5-13.6 m deep collision floor must stay north of z -3 or it seals a hole. Price of the stairs, not an error | box z -15.8..-2.2 (assembly) and -15.5..-3.0 (studies) against shaft z -3..3 |
| 34: the mixing bench is 0.6 m past the north edge | box z -8.1..-3.9: inside (edge -9). The local-frame box had its axes swapped | world box |
| 36: Albers wall to (3, 8) | (3, 8) is the spray demo's own spot; the wall went to the bay west of it | collision check against the floor's other works |

## What was applied (`commons/void/rooms.json`, uncommitted) and what the tower measured afterwards

Every row re-surveyed in the actual Void after the edit (`tools/test_color_survey.py --floors=...`, world box in
floor-local metres, faults against `layout.json`: slab 42 x 18, shafts A/B 6 x 6 at x -10/10, columns at x
-20/-14/-5/5/14/20, z +-7, ceiling 5.64 m up).

| floor | work | before | after | measured | picture |
|---|---|---|---|---|---|
| 30 | reference_landscape (`museum-color_context_placed-71-11`) | origin z 16.2, 12 x 13 m, 7 m past the south edge | **removed**; record in `removed-records.json` | floor 30: 23 works, no faults | `30__floor_*` |
| 34 | color_sets_overview | (18.25, -0.25) facing 270, inside the x 18 pillar lane | **(20, -0.25) facing 270** | box x 19.7..20.3, z -3.5..3.0; 0.7 m from the east edge; the lane's pillars 1.7 m in front; swatches face the hall; no faults | `34_sets_wall` |
| 35 | spectrum_forest | (-10, 0), ceiling 5.4, lines 5.25 (a 0.15 m gap at the floor, 0.24 at the ceiling) | **(-10, 0), `ceiling_height` 5.6, `line_length` 5.6, `connects_next_floor` true** - floor to 0.04 m under the ceiling, and floor 35 stays live while the visitor is on 36; the copy at (-9, 1) (1 m of lines over the slab) removed, record kept | box x -13..-7, z -3..3 = shaft A exactly; y 0.00..5.60 | `34_shaft_rim_down` (from above), `35_forest_over_shaft` (from the rim), `36_shaft_up` (from below) |
| 36 | albers_wall_gallery | (-4, 8): building column (-5, 7) 1 m in front, splitting the wall | **(-9.5, 8)** | box x -13.4..-5.6 in the 8.1 m bay between columns -14 and -5; 0.15 m clear each side; no faults | `36_albers_west_bay`, `36_south_wall` |
| 37 | color_constellation_office | (0, 3.4): south end 2 m past the edge | **(0, 1.2)** | box z -6.4..9.1 (0.1 m over the edge, inside tolerance); columns (+-5, 7) inside its 10.7 m width - see below | `37_office`, `37_office_south` |
| 37 | rainbow_hallway | (-16.7, 13.4), 12 segments, height 1: 24 m through the floor, mouth in the sky, belly 3.3 m under the slab (into floor 38) | **(-17, 6), `num_segments` 5, `start_radius` 2.5, `end_radius` 1.2, height 2.7**: a 10 m tunnel from z 6 to -4 | box x -19.8..-14.2, z -4..6, y -0.10..5.50: mouth bottom on the slab, top 0.14 m under the ceiling, columns (-20, 7) and (-14, 7) flank the mouth from outside, nothing in floor 38; no faults | `37_hallway_mouth`, `37_west_end`, `37_hallway_inside` |
| 37 | dark_sphere | (-15.3, 15), 6 m past the edge | **(-11.5, 8)** | no faults | `37_west_end` |

The hallway's 2.5 m radius is the ceiling's: a radius-4 mouth is 8.6 m across and the floor is 5.64 m tall, so
the museum's version was buried 3.3 m into the slab and showed as a rainbow belly from floor 38's ceiling (Tiling's
first hall). The taper ratio, which the script calls its critical parameter, is 2.1 instead of 2.7. Inside, the
visitor walks the cone's own floor, which rises 1.5 m over the 10 m; the far end opens into the wall-studies bay
1 m above its floor.

**Still standing as it was, by choice or because it is not a move:**

- 37 office: 10.7 m wide in a 10 m bay, so the building's columns at x +-5 fall 0.35-0.8 m inside its outer
  edge at z 7 (photo `37_office_south`: the column stands just inside the white south wall). Was so before the
  move. Only a narrower office or one turned along x would clear it.
- 37 colour_assembly's floor reaches z -2.2: a 0.8 m lip over shaft B's north strip (the studies bay stops at
  -3.0 exactly). The opening is narrowed, not sealed.
- 36 ball_painting_demo's tray at z 9.6: 0.6 m past the south edge. Not touched.
- 35 film_foundation_class's box reaches x 8.3 at z -2.1..3: 1.3 m over shaft B's west strip. May be the
  console's screen stand or the film's private stage (the box is 218 m tall); not checked.
- 34 visual_color_mixing: inside the slab, on the north strip beside the column at x -14, at 0.9 m (photo
  `34_mixing`). Small, present, in the dark between the field's row and the edge. A lamp, or the bench on a
  plinth, would do more than a move.
- The pillar field's merged box spans both shafts; the lanes do not. The survey's `faults` is a box test.

**Seen from below.** `floor_stream.gd` keeps the current floor live, the floor below as a preview and puts every
other floor to sleep, so a floor above is normally invisible from a shaft: the first photo up from 36 showed the two
openings A/35 and A/34 and no lines. The stream has a data hook for exactly this - an artifact config
`connects_next_floor: true` keeps its floor live while the visitor is on the floor below (written for routes that
span storeys) - and the forest now carries it. Verified in the tower (shots run 13:50, floors 35 then 36): from
36 the rainbow underside fills the A/35 opening with the soft-landing plinth at its corner (`36_shaft_up`); from
35's own rim the lines rise to the ceiling (`35_forest_over_shaft`); from 34 the ceiling of lines fills the hole
(`34_shaft_rim_down`). The hook keeps 35 awake only when the visitor came down through it; a visitor dropped
straight onto 36 never built 35 and sees an empty shaft.

## How it was tested

Not by reading. Every work on the eight colour floors was mounted in the actual Void, measured and photographed
(`tools/probes/color_survey.gd`, `tools/probes/color_shots.gd`, runners `tools/test_color_survey.py` and
`tools/test_color_shots.py`; reports and pictures under `ada_run/color-survey/` and `ada_run/color-shots/`, local):

- **presence**: the world box of its meshes (each mesh's AABB carried by its own global transform, CSG included),
  the count of visible meshes and lights;
- **touch**: bodies and pickables (can a hand take it, can a body walk into it);
- **voice**: visible Label3D text (does it say anything in the room);
- **fit**: `faults` against the building's own numbers - past a slab edge, over a shaft (unless the box starts
  2.5 m up), a column centre inside the box, a box over 60 m ("a stage, not a footprint");
- **route**: the distance to the floor's walking route (seven of the eight colour floors have no route).

Then each floor against what it is meant to say: `final.md` (the narrator's essay), the spine roles
(`/api/spine-roles`), the course lesson (`COLOUR_SUMMARIES.md`), and the September reviews
(`2026-09-19-color-review`, `-24-colour-review-comments`, `-28-colour-another-order`).

Both runners take `--beside-play`: no native slot, window off-screen. Palle's desktop play session held the slot
from 12:04 and the afternoon's runs went beside it (Palle, 2026-09-17: many games at once are fine; the limit is
the card).

One fact first: **the Void floors are faithful imports of the museum maps** (same tokens, hall by hall; the only
additions are Codex's four colour stations on 30, his three light rooms on 31, the moving canvases, the graffiti stick
and my drone canvas on 36). So most of what was wrong was wrong in the map too, and the museum's own furniture
(`plinths: false` on every colour map) was never there to lose.

## The sequence as a whole (after the moves)

| | floors | finding |
|---|---|---|
| works, and reads | 30, 31, 32, 33, 37 (office) | the columns' aisle, the light rooms, the salon, the celebration, the twelve panes: presence, touch and voice all there |
| works, now placed | 34, 35, 36, 37 | the sets wall out of the pillar lane; the forest filling shaft A floor to ceiling; the Albers wall in a clear bay; the hallway a tunnel on the slab, the sphere beside it, the office inside the edge |
| works where it is, half outside | 37 | Gillick's two bays: half past the north edge so the shafts stay open |
| gone | 30 | McLeod's landscape (no 13 m column-free bay on this floor; scaling kills its walkable path): removed, record kept |
| built, stands nowhere | - | paint_station (29 Oct), chroma_translation / chroma_filter / chroma_drum / chroma_life (Sept, DNA-promoted, swept), boolean_colour_chamber |

The pattern behind the morning's misplacements: the museum maps were deeper than the Void floor (Color_Walls 37 x
79 cells, Context_Placed 23 x 82, Pillar 41 x 38) and the import kept the map positions. Whatever stood past cell
+-9 in z stood in the sky.

## Floor by floor

### 30 Color_Context_Placed - *Before we ask what colour is*

**Message:** the same five parts under four colour rules; then the alphabet changes, then the pose; colour as an
assignment you can compare column by column. (The course lesson: palette = values, slots = destinations.)

| work | presence | touch / voice | fit | verdict |
|---|---|---|---|---|
| 4 Codex stations (one / by shape / by height / by neighbour) | 2.4 x 4.4 m, consoles | 17 bodies, console labels | at the aisle's head | **works** - the lesson's four columns, with a repeatable experiment |
| 19 chroma_stack / color_dna_stack columns | 4.4-7.4 m tall | solid, **no label** | three rows + a gallery | **works** as presence; mute as a lesson |
| reference_landscape (McLeod) | 12 x 5 x 13 m, console SHORTER/TALLER/RESET | 7 bodies, labels | was 7 m past the south edge | **removed** (see above) |

The essay walks the visitor "begin with the four columns near the entrance ... further down ... now find the four
columns made from blocks and wedges". In the Void nothing marks which four are which: the 19 columns carry no name,
and the floor's 4-point route is not drawn (route captions exist only on Trans_ floors). The stations have their
"01 / one" labels; the rows do not.

**Scaffolding it needs:** a name at the foot of each row (one `association_tape`-style floor text per row: "02 /
alphabet", "03 / pose", "04 / compose", "05 / gallery"), in the order the essay reads them. The landscape wants a
floor of its own or the museum; a 13 m deep work does not fit an 18 m floor with columns at z +-7.

### 31 Color_Flashlight - *What reaches the surface*

**Message:** keep the board, move the light; what a surface shows is a condition, not its material.

| work | presence | touch / voice | fit | verdict |
|---|---|---|---|---|
| lamps (flashlight_demo) | 7 x 1.7 m pale board, four lamps, the side cube | 4 pickable lamps | at the west edge, board 1 m past it (sky behind) | **works** - the receiving cube the Sept review asked for is there |
| Codex's light rooms (white room, pink threshold, light well) | 29 x 5.6 x 10 m | 48 bodies, 17 lights | spans both shafts (their own floors) | **works** - the strongest *room* in the sequence |
| pink station (five switches) | 8 x 4.3 m | 13 bodies, LIGHT / MATERIAL labels | | **works** |
| cube wall (16 cubicles) | 4.2 x 4.6 m | 80 lights, 16 labels | at the east edge | **works** - the five-light score made legible |

The registry still says `map_ready: false` for flashlight_demo and its description is the token's name. Stale.

**Scaffolding it needs:** a dark wall behind the lamps' board - the pools of colour read against the pink sky now;
against black they are the whole lesson. The white room already does this for itself.

### 32 Color_Nails - *The choosing hand*

**Message:** one colour choice dresses a body at two scales.

| work | presence | touch / voice | fit | verdict |
|---|---|---|---|---|
| nail_salon | 4.3 m hand, table, stools, petite hand | GRAND / PETIT, NAILS, SKIN | centre | **works** |
| nail / hand colour controllers | RGB boxes on labelled plinths | 1 pickable each, readouts | beside the table | **works** - the Sept "seat them on their plinths" is done |
| colorballs (case), brick_wall_factory (0.4) | secondary palettes | | sides | work; the brick wall is a palette demo, not the hand's |
| science_screen (FIELD MAP) | 3 x 2.4 m | | right edge | **wrong instrument** - a field map has nothing to do with nails |

**Scaffolding:** none missing. The screen could go, or show the RGB box's own values large (the essay: "a colour you
left can be found again at the same place").

### 33 Color_Rainbow - *More colour, another rainbow*

**Message:** the familiar arch can hold another division of colour; celebration before correctness.

| work | presence | touch / voice | fit | verdict |
|---|---|---|---|---|
| rainbow (stage: celebration) | the arch, candy steps, dressed mushroom, flag, confetti, clouds, the coloured path | 32 bodies, EVERY BODY / MORE COLOUR | centre | **works** - the essay's whole room is built by this one token |
| film_rainbow_partitions | console: 2 bands / 5.6 m, PAUSE, REPLAY, STEP, TURN VIEW | 7 bodies | east | works (its 207 m box is the film's private stage, not a fault) |
| pick_up_cube, catalyst_pedestal | the two offers by the entrance | | north edge, on the slab | work |

The essay's RE-DIVIDE button is the film's STEP here. Fine.

### 34 Color_Pillar - *The colour between the pillars*

**Message:** a continuous field, thirty-five samples; hue across, saturation along, value up.

| work | presence | touch / voice | fit | verdict |
|---|---|---|---|---|
| pillarcolorcollection (spatial_gradient, `void_gallery`) | 35 pillars 5.5 m, seven lanes, the rails overhead: box 38.8 x 5.5 x 13 m | 37 bodies, sampler, GREY TO WHITE / VALUE labels | lanes between and beside the shafts, on the slab | **works** - the best presence in the sequence; the morning's "cut by a hole" was floor 35 seen through the hole |
| color_sets_overview | 6.5 m board, 144 swatches, 12 set labels | 144 pickables | **moved to x 20**, out of the x 18 lane; the lane's three pillars now a colonnade 1.7 m before it; swatches toward the hall | **works** (photo `34_sets_wall`); a sill at 0.9 m would still help 144 things to take |
| visual_color_mixing | 3.2 x 4.5 m bench at 0.9 m | 18 pickables | north strip beside column -14, inside the edge | present; dark; see above |
| grab_rainbow_stick | a stick with X / Y / Z readout | 1 body | | works |
| film_colour_edge, SpectrumVisualizer, dark_sphere | | | | work |

**Scaffolding:** the field needs nothing. The sets wall needs its sill; the mixing bench a light.

### 35 Color_Grid_Pallet - *Find the colour again*

**Message:** a colour written at an address stays; the rule overwrites it; the floor keeps holding you.

| work | presence | touch / voice | fit | verdict |
|---|---|---|---|---|
| gridcolorizer (central_bay, lesson: addresses) | 9 x 12 m colour floor, console | 21 bodies | centre | **works** - the essay step by step |
| spectrum_forest | 6 x 5.6 x 6 m, 5000 lines, floor to ceiling | 0 bodies (the fall stays safe) | **in shaft A**, the opening exactly | **works** - a ceiling of lines seen from 34's rim, a wall of lines from 35's, the underside from 36 once floor 35 is kept live |
| film_foundation_class, science_screen (grid), dark_sphere | | | | work; the film's box reaches 1.3 m over shaft B (unchecked whether stage or stand) |

**Scaffolding:** none for the forest. The copy at (-9, 1) is in `removed-records.json` if the density (10 000
lines) was the point rather than an accident.

### 36 Color_Paint - *Before the hand*

**Message:** a surface keeps what a gesture leaves; manual and automatic reach one canvas.

| work | presence | touch / voice | fit | verdict |
|---|---|---|---|---|
| ball_painting_demo (spray) | canvas, 30 spray cans on the tray | 30 pickables, 30 SPRAY labels | south, tray 0.6 m past the edge | **works** |
| albers_wall_gallery | 7.8 x 4.5 m, 98 canvases, 5 spotlights | 0 bodies | **(-9.5, 8)**: the bay between columns -14 and -5, 0.15 m clear each side, 6 m of floor in front | **works** (photos `36_albers_west_bay`, `36_south_wall`) |
| graffiti_stick (uncommitted, 2 Nov) | its own 5.3 m wall | 1 pickable | north edge | works |
| moving_canvas x4, unit_drone_graffiti | | labels | | work |

**Scaffolding:** the Albers wall's `medium: cubes` (glass, Oct) is built but not switched on here.

### 37 Color_Walls - *The view has partitions*

**Message:** what stands between you and the far wall changes with a step; passage does not.

| work | presence | touch / voice | fit | verdict |
|---|---|---|---|---|
| color_constellation_office (planes) | 12 panes 4.2 m, three desks: 10.7 x 15.5 m | 41 bodies | **(0, 1.2)**: z -6.4..9.1; the columns at x +-5 inside its outer 0.35-0.8 m | **works** - the panes, the desks, the overlap: the lesson in one glance; the columns are the bay's, not a move away |
| colour_wall_studies (Gillick) | 19 x 12.5 m bay, works on a pale wall, console SPACING / DEPTH / OMIT / COLOUR / RESET | 57 bodies | origin at the north edge; floor to z -3.0; 6.5 m outside | works where it is inside; placed so for the shaft |
| colour_assembly (Gillick) | 14 x 13.6 m bay, canopy, 12 numbered places | 27 bodies | floor to z -2.2 (0.8 m lip over shaft B); 6.8 m outside | same |
| color_space_navigator, gradient_interpolator | RGB cube + HSV cylinder; 16 cubes, MODE: RGB | labels | north, on the slab | work; small (1-2 m) and far apart (10 m) |
| subpixel_display | **0.2 x 0.6 m** | 3 pickables | west edge | present, no presence |
| rainbow_hallway | a 10 m tunnel, 5 m to 2.4 m across, floor to ceiling | CSG collision | **(-17, 6)**, mouth between the columns, end in the studies bay | **works** (photos `37_hallway_mouth`, `37_west_end`, `37_hallway_inside`) |
| dark_sphere | | | **(-11.5, 8)** beside the mouth | works |
| film_gradient_paths | | | | works |

**Scaffolding:** the three colour-space instruments are the chapter's named primaries after the office and stand
10 m apart at knee height: one table, three instruments, a wall behind (`station_plinth` 3 x 1 cells at 0.9 m; an
`unfinished_wall`).

## What the sequence still needs, in order

1. ~~Four moves and one turn~~ **Done** (table above). Open from it: the office's columns; the landscape's new
   home.
2. **Names on the floor** (30): one floor text per column row, in the essay's order. The museum had none either.
3. **A backing wall** behind the lamps' board (31) and the three colour-space instruments (37): the Void's
   `unfinished_wall` prop or a `walls` entry, 2.6 m, black for the lamps.
4. **A sill for the sets wall** (34) at 0.9 m: 144 things to take.
5. **Place what is built:** paint_station belongs on 36 (timber panels, buckets, stain - the hand's version of the
   automatic painter); chroma_translation on 30's north (the Sept plan, forum 260917-q1h14/13jf7); chroma_filter
   and chroma_drum on 37 (standpoint decides the colour - the office's own argument, as objects); chroma_life on 35
   (a rule's record as colour, beside the grid's rule).
6. **Titles:** floors 32, 34, 36 are titled "original museum artifacts"; the others have a line.
7. **Registry:** flashlight_demo, visual_color_mixing, grab_rainbow_stick carry their token as their description;
   flashlight_demo and color_sets_overview are marked not map-ready while standing in the tower.
8. **Routes:** no colour floor but 30 has a route; the placement probe scores spots by it and the agent walks it.

Nothing is committed. `rooms.json` also carries other sessions' uncommitted hunks (+4955/-576 against HEAD before
this pass); the Colour rows are the ones in the table.

## Method notes

- A work's local box lies: `void_game_probe.mesh_bounds` merges in the host's frame, so a turned work reports its
  length on the wrong axis. `color_survey.gd::world_bounds` carries each mesh's AABB by its own global transform
  (MeshInstance3D, MultiMeshInstance3D, CSGShape3D) and `faults` tests it against `game.building.spec`.
- A `film_*` work reports 200 m tall (its SubViewport stage is a private world far above); the survey's shaft test
  ignores boxes that start 2.5 m up, but a film's box starts at its console, so the film rows carry a shaft fault
  that is the stage's. Read `world_top` before believing one.
- **A camera can stand inside a work.** The automatic per-work camera (3 m off the box centre, toward the hall's
  middle) and two hand-placed ones landed inside pillars of the field and inside a shaft's airspace; the frame is
  then one flat colour. `color_shots.gd` notes the field's lane and row coordinates for that reason.
- **The tower descends, and the floor above sleeps.** A photo into a shaft shows the next floor's work (the
  preview floor); the floor above is drawn only while something on it is pinned.
- An empty `MeshInstance3D` (a capture anchor before its mesh) made `mesh_bounds` throw on floor 34; it now skips
  a null mesh.
- `game.body.visible = false` does not hide the costume: the avatar stands in several frames (`37_office_south`).
- Routes: `floor_content.gd` draws route captions only on Trans_ floors and trials; a colour route would serve the
  tools, not the visitor.
