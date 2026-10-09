# Arrays: keep the address, name the reader

4 October 2026. Guide to the revised five-hall teaching proposal in `early.json`. These are summaries for the next writing pass. Full lessons and learner adapters are still to be made. The host is the existing Endless Museum.

## What this sequence adds

Trace already introduced a list and traversal. Transformation supplied positioned bodies and operations on them. Arrays should give that knowledge a new use: read an address, change its value, and explain what the receiving construction does with it. This is more than multiplying the number of cubes.

Do not call all the records the same thing. Occupancy, orientation and musical events can use similar indexing while meaning different things. Carry the operation and its declared reader. A copied function, a written address table or a manually retained study can connect lessons before automatic museum transport exists.

The order stays **Array → Tutorial_3D → Tutorial_Tiling_Floor → Tutorial_Tiling_Walls → Tutorial_Disco**. The wall hall supplies a reflective pause. Its usefulness does not depend on teaching another algorithm.

## The actual conventions

| Encounter | Existing representation | Meaning and limit |
| --- | --- | --- |
| Labelled row | `array_data[0][i]`, four entries | Collection writes zero without renumbering the slots. The cube takes its own label away. |
| Square pickup grid | `grid_data[x][z]`, four by four | Occupancy; plates keep addresses visible. Table rows represent X, columns Z. |
| Flight enclosure | `values[y][z][x]`, four by four by four | Displayed address is XYZ; storage selects layer, row, entry. Flight is supplied separately. |
| Floor and wall patterns | An image generated from a rule, source orientation and exception | A quarter-turn count is not an occupancy value. A dark pixel is not a hole. |
| Musical score | `_grid_data[track][step]`, four by sixteen booleans | False asks for no new sound trigger. The address still exists. |
| Disco floor | 12 by 12 colours, flattened by `z * grid_width + x` | A different record from the score; visual animation has a separate clock. |

Sources: `algorithms/arrays/{row_3_x,grid_2d_4x4}.gd`; `commons/artifacts/regularity/{array_flight_lab,tiling_pattern,tiling_rule_study,disco_controls}.gd`; `commons/audio/sequencer/{sequencer_ui,step_sequencer}.gd`; `commons/context/discofloor/{StandaloneDiscoFloor,DiscoSequencerBridge}.gd`.

## Five bounded lessons

**Array — one address remains.** Start with the four slots, then the small two-index grid. Teach occupancy separately from the reference to a visible cube. Keep spacing as a display decision. The independent variation empties one slot and changes spacing without renumbering neighbours. Its result is a small record and a reader the student can explain. Molnár’s stored random departures become an optional extension after this relation is secure. The floor writer keeps its force as an encounter: absence underfoot has a consequence beyond a value in a table.

**Tutorial_3D — show the convention change.** The earlier plane is `[x][z]`; one layer of the installed volume is `[z][x]`. Merely enclosing the old plane in another list would yield `[y][x][z]`. Teach the conversion or explicit reader, then use unequal indices to reveal a mistaken swap. For example, displayed `[1, 2, 0]` reads `values[2][0][1]`. Selection, pickup and flight are supplied. The learner needs to understand the mapping, not implement locomotion.

**Floor — a value asks for a turn.** Reuse the paired four-by-four samples. A small function maps an address to quarter-turns; remainder makes the count repeat. Keep source motif, turn rule and one exception separate. Predict one address, then enlarge the field without expanding the rule. Zero now means zero added turns. This is a new interpretation, not a claim that the previous occupancy zeros have become tiles. Supply image generation; it already makes the large museum fields.

**Walls — a familiar image has another support.** Reuse the learner’s image on a named upright receiver. Compare its legibility at different distances. Predict which control only changes the picture and which turns a physical barrier. Preserve the eye chart, the landing and the view back at the museum’s thin enclosure. A short observation or comparison can complete this hall; it needs no new syntax.

**Disco — time visits an address.** Start with one short track, using the existing instrument’s track/step convention. Write a pattern, then advance a separate playhead. Move an event at fixed tempo; change tempo without changing the entries. Stop the score and watch the floor continue. The later comparison between sixteen score steps and twelve floor columns makes a many-to-one mapping visible: steps zero and twelve can flash the same column. It does not imply that footsteps are recorded.

## What can be reused now, and what needs connecting

The binary table display already has `set_data` and `set_cell`. Those functions update the table; they do not rebuild pickup geometry. A learner occupancy editor therefore needs a named geometry adapter. Existing pickup removal is not a general-purpose write-and-redraw interface.

The tiling renderer `image_for(rule, phase, exception, columns, rows, tile_pixels)` exists. The close study uses four-by-four sites; the expanded floor uses sixteen-by-sixteen. The wall eye chart repeats one generated texture at five sizes. A future reduced lesson must specify where the learner’s turn function enters that renderer. It need not replace the installed generator.

The sequencer exposes cell access and active-track lookup. Sound synthesis remains supplied. Its tick interval is `60 / (bpm * 4)` for sixteenth-note steps, while the floor’s phase has its own timing. A compact reader must preserve elapsed-time remainder; copying the old tutorial’s reset-to-zero clock is not a verified implementation.

Reusing a four-by-four record as sixteen events could be a later variation, with a declared order such as `step = row * 4 + column` and an explicit value conversion. Do not make this additional mapping compulsory before the basic score reader works. No current artifact connection automatically carries the learner’s data across all five halls.

## Full-companion work remains

`Array/tutorial.md` is absent. The 3D companion offers source edits to the open structures and fragments; those do not yet teach the proposed storage conversion. Floor and Walls mostly point to the main text. Disco’s old companion describes a 17×17 footstep-recording floor and deferred Chamber_Arrays; that is not the current encounter. It requires a full rewrite before being offered as reliable making instructions.

These are open writing tasks, not failures to be hidden by a polished summary. The current `final.md` texts already carry valuable distinctions and should guide the companion repairs. This pass preserves them.

## Return to the wider book

Colour can reuse an addressed assignment while declaring a colour value and its receiver. Tiling can deepen motif, palette and sampling; it need not reteach indexing. Later sound studies can reuse a timed reader. These returns accumulate capacity when the learner retains something small enough to understand and substantial enough to use.

**Compact AI brief:** Existing museum. Address → value → named reader. Teach XZ, then explicit YZX conversion. Separate occupancy/orientation/event semantics. Molnár optional. Floor rule supplied with raster host; wall reflection preserved. Score and floor clocks separate. One independent variation per making lesson. No automatic transport claims. Preserve finals; full companion repair still pending.
