# Two rooms, connected

CA_Introduction now has a direct comparison between the row and rug, a lower gallery instead of narrow wall pockets, and room around the growing network. All eight authored works remain. The decorative figure and its plinth remain too, relocated by the museum's existing placement system into the lower gallery.

## Applied layout

- Open two three-metre connections through the divider: beside the row/rug and beside the network/gallery.
- Open a two-metre passage from the rug room into the lower gallery. Keep enough wall to give the rooms separate identities.
- Convert 40 authored cells to level floor: the derived floor count rises from 134 to 174 within the same 13 × 19 footprint.
- Move the showcase from map cell (1,17) to (3,14). Keep the row, ring, rug, turmites, network, Rule 110 and both sphere placements.
- Reserve the teaching aisle and showcase approaches from automatic sculpture placement. In the captured build the retained figure moves from (9,12) to (3,10), over seven metres from the network instead of approximately one.
- Disable the generic start gate for this hall: its six-metre barrier crossed the rug and the new opening. The hall keeps its museum portals.
- Move sp from (2,1) to (6,0), with no arrival cage. Move t from (2,16) to the centred exit at (6,18), approached from the hall. Both authored frames now validate without fallback in this hall.

## What changes for the learner

The row remains the primary tutorial. The opening lets the visitor turn from its local rule towards the rug's mirrored pattern; the second connection lets the network be seen from another side. The showcase is a deliberate side encounter. The route does not turn every artifact into a lesson.

The tutorial and its runnable code are byte-identical to the baseline. The production CA engine, hand reader and history-ring scripts are also unchanged. Three location sentences in final.md now describe the new arrangement; the reflective argument is retained.

## Evidence

25 fresh native checks pass. Six routes have 209 sampled positions, spaced at most 0.15 m apart: a 0.56 m wide, 1.7 m high capsule clears layer-1 collision and finds level floor. Tests also check authored entry/exit validation, retained reader height, shared board/ring updates, showcase placement and figure separation.

Ten native images compare five identical camera viewpoints before/after: full overhead, raised oblique, rug opening, network and lower gallery. No walls are hidden for the pictures. Neighbouring halls and the player are hidden for capture only. Rule 90 is held at the same generation for both layout photographs; other running/random works can differ in state. Before eye-level cameras are diagnostic fixed viewpoints, including the previously obstructed opening, not evidence of a playable before route.

The first layout run failed four clearance checks: the generic gate, an entrance path too close to a corner, and the old exit frame beside the relocated showcase. The next pass identified collision shapes. The gate and portal placements were corrected; the entrance sample path moved 0.3 m off the corner. A probe-only undeclared stream variable caused a parse error and was corrected before the final run. These were not CA program failures. Initial layout diagnostics are retained.

Limit: this checks sampled clearance against museum layer 1, not every dynamic interaction, physical headset comfort, Quest performance or traversal into the next hall. The existing tutorial's 29 construction checks and 16 interaction checks were not re-run for this spatial edit; their code is unchanged. Final engine log contains no SCRIPT ERROR or Parse Error. Existing renderer/UID/Jolt warnings remain.

## Next

Continue with CA_ElementaryRules: inspect the existing three-dimensional empty/active/fading specimen. Keep overhead, elevated and visitor-height views in subsequent hall reviews. Do not infer the lesson from the old map title alone.
