"""Write the focused first Noise lesson; preserve the optional surface study."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
STUDY = ROOT / 'doc/book/studies/noise-lineage'
OUT = ROOT / 'doc/book/iterations/2026-10-09-noise-revision/Random_Noise_Types'

INTRO = '''# A place is still a request

**Learning elements**

- Rejection sampling
- Minimum centre-to-centre distance
- A finite attempt budget for each requested place
- Accepted points, refused candidates and unfilled places
- A construction rule versus an ongoing constraint

At the two framed clouds in Random Noise Types, press REDRAW, then LOAD. The right cloud must leave room between its points. Asking for more does not give it more space. Read how many places remain unfilled.

## What you bring

Keep the pickable `PointBody`, the position list from Trace, the distance comparison from Lines, and the local seeded generator from Randomness. Random Remove chose among eligible addresses. Here the eligibility of a new position depends on the positions already accepted. Nothing moves them aside to make room.

**Build:** one bounded cloud of the same point spheres, admitting a centre only when it is far enough from every earlier centre.

**Investigate:** request more points, spend a limited number of attempts, then carry an accepted point into a relation its generator would refuse.

This is the opening distinction in Noise: neighbours can affect a procedure in different ways. Minimum spacing does not make a smooth scalar field. The columns in the next hall will give a field value a form to change.

## Work inside the museum

Continue in the prepared Endless Museum project. Its floor, light, player, desktop interaction and XR Tools are already running. Create an upright `PointStudy` Node3D at unit scale in the first Noise hall, at map-space `(2, 0, 7)` metres, with Y rotation 90 degrees. That west-side working position was checked in the museum; its local +Z side faces the approach. If placing under a translated hall, use the map's origin rather than treating these numbers as world coordinates.

Save the two complete files below together. Attach `01_spaced_points.gd` to `PointStudy`. It creates its own frame, label, points and control. No mesh child or scene-path reference is required. The point file is unchanged from Randomness; it is printed again so the dependency is available.

The twelve white spheres have the familiar 0.14-metre radius and frozen release. We give their centres a larger frame—2.4 × 1.4 × 0.12 metres—to keep that body useful to the hand. Its centre is 1.5 metres above the study's origin. The frame shows where centres may be generated; it is not a colliding container for their surfaces.

Hold the black point over a caption and press its action trigger: REDRAW repeats, NEXT SEED increments the seed, LOAD switches 12 / 48, RESTORE returns the generated positions. The choice uses the control's local X coordinate. The same point action works through the museum's existing desktop pickup controls. Release sampled white balls before using these actions; a held sample prevents replacement or restoration.

## Complete code — 01_spaced_points.gd

Start with `sample` and `far_enough`. The rest gives their result a familiar body, a record and an input. There is one `_ready` in this file.

'''

EXPLANATION = '''
## Follow one candidate

The outer loop asks for one place at a time. The inner loop may try one hundred candidates for that place. Each candidate uses three successive uniform draws: local X, Y and Z. The generator belongs to this study, so other museum artifacts cannot spend its next request.

`far_enough` reads the centres already in `homes`. One distance smaller than `separation` is enough to refuse the candidate. If there are no earlier centres, there is nothing to conflict with. A distance exactly equal to the separation is allowed.

On admission, `append` keeps the centre and `break` ends only the inner loop. The next requested place gets its own attempts. When all attempts fail, the inner loop simply ends without appending. The next place still gets a chance. No fallback point is secretly added.

The record uses metres in the study's local axes, relative to `CENTRE`. A point is displayed at `CENTRE + home`. All points share that parent and its unit scale, so rotating or translating the study preserves their distances. Scaling the host would change the world-space distance represented by the numbers; keep it at unit scale.

## Keep the two accounts separate

Every candidate is either accepted or refused:

`attempts = homes.size() + refused`

Every requested place is either filled or still unfilled:

`requested = homes.size() + unfilled`

One unfilled place may have refused a hundred candidates. It is not one refusal. With no more than one hundred attempts per place, the total cannot exceed `requested * tries_per_place`. Successfully finding a point stops that place's search early.

REDRAW resets the local seed before sampling. Identical bounds, spacing, request count, budget and call order repeat the record in the same Godot version. NEXT SEED changes the recipe's starting seed. It does not guarantee a different visible result or a similar result to the previous integer.

## Predict, then change the request

Press LOAD. Before reading the result, name what stays fixed: frame dimensions, centre separation and attempt budget per place. The request rises from twelve to forty-eight. The readout may show unfilled places. A finite search ending does not establish that no legal position remains; it establishes that this search stopped finding one within its budget.

For a decisive code experiment, set `requested = 5`, `tries_per_place = 7` and `separation = 3.0`, then restart the study. The frame's centre-to-centre diagonal is less than three metres. Predict the result before running: the first candidate is accepted, then each of the four remaining places exhausts seven attempts. That gives one filled place, four unfilled places, twenty-eight refused candidates and twenty-nine candidates in total. Here geometry, rather than the exhausted budget alone, explains why another centre cannot fit. Return to the original settings afterward.

## What continues after construction?

Carry a white point beside another, then release it. The close-pair count can rise. The update reads current positions; it never assigns replacement positions. Its one-millimetre tolerance is for the observer, not a relaxation of the generator's admission rule. `j` starts at `i + 1` so each pair is counted once and no point is compared with itself. Three coincident centres make three pairs.

The saved `homes` do not follow your hand. RESTORE reads them without requesting another random value. REDRAW regenerates and replaces the sampled bodies. They can produce the same arrangement by different routes. The black control survives both actions.

This record lives only in this study instance. It is not a saved trace file, and it does not automatically travel through the next portal. What we carry onward here is the procedure and the distinction between a sampled value and its later use.

## Make a deeper cloud

Change only `half_size.z` from `0.06` to `0.30`, keeping the seed and three requests per candidate. Predict the first accepted centre: its X and Y stay the same; its Z becomes five times as large. Later accepted centres need not correspond one for one. Changing depth changes distances, which can change admission and how far the generator proceeds.

Run your version. Find two points that overlap when viewed from the front but separate when you lean sideways. The rule measures three-dimensional centre distance. A projected overlap is not enough to establish a breach. Keep this version and explain why stretching the already generated picture would be a different operation.

## The inherited point — point_body.gd

This file is unchanged. It creates the sphere and its collision shape; Day Zero's XR Tools parent provides pickup and `action_pressed`. We reuse that class for white samples and the black control. The spheres share a construction, not one live identity carried through every room.

'''

ENDING = '''
## Compare with the installed work

The installed bench uses two smaller 0.90 × 0.90 × 0.12-metre slabs and requests 24 / 96 centres. The left keeps uniform proposals. The right continues the same generator's stream and applies its spacing rule. These are not the same candidate list with and without filtering. Our one-cloud construction starts directly at the seeded stream and keeps the admission loop visible.

The bench also shows at most 220 refused proposals as grey specks, although its refusal counter includes all of them. Our smaller lesson counts refusals without drawing them. Both allow a hundred attempts per requested place. The bench's RULE control can replace spacing with clamped Gaussian draws; that branch promises no minimum pair distance. It is a comparison with what you learned in Random Gaussian, not another implementation required here.

At the separate single-point frame, move the point out of its plane. The artifact keeps clipping X and Y to its bounds and setting local Z to zero. It does so continuously, without drawing another position on release. Compare that response with your freely altered cloud.

The needle field, noise-colour sculpture and sound console extend the encounter. Their image and sound generators are separate; the bars are not a measured audio spectrum. The moving walls of Related Weather let you compare fresh draws, accumulated steps and a filtered record. Those works have a place in the reflection without becoming extra requirements for this lesson.

## What travels onward

We can now say when a relation acts: during admission, during display, or after a hand changes a body. In Noise Columns, keep the receiving form fixed and compare a held value, a periodic value and a value read from a field. The next question is what the same number can make a body do.
'''

def listing(name):
    return f'<!-- student-code:{name} -->\n\n```gdscript\n' + (STUDY/name).read_text(encoding='utf-8').rstrip() + '\n```\n'

def main():
    old = (OUT/'before/tutorial.md').read_text(encoding='utf-8-sig')
    optional = old[old.index('## Optional experiment:'):]
    tutorial = INTRO + listing('01_spaced_points.gd') + EXPLANATION + listing('point_body.gd') + ENDING + '\n' + optional
    (ROOT/'commons/maps/Random_Noise_Types/tutorial.md').write_text(tutorial, encoding='utf-8')
    # Retain the reflective voice and all six encounters. Move code detail out of its reading flow.
    final = (OUT/'before/final.md').read_text(encoding='utf-8-sig')
    replacements = [
        ('The point\'s script repeatedly takes its current position and clips it:', 'Its current coordinates are repeatedly clipped to the frame. Local Z is set to zero.'),
        ('Read the last line again.', 'Stay with that zero.'),
        ('Only this condition lets it join them:', 'It joins them only if its nearest accepted neighbour is at least the stated distance away.'),
        ('This passage watches.', 'The observer watches.'),
        ('At the BROWN setting, a stored value receives a small part of the next draw:', 'At the BROWN setting, a stored value receives a small part of the next draw. The result is bounded before it is made louder.'),
        ('Its short passage keeps the previous draw in order to subtract it:', 'It keeps the previous draw in order to subtract it from the current one.'),
        ('The two lines give us another way to hear the relation between memory and change.', 'That subtraction gives us another way to hear the relation between memory and change.'),
        ('The brown wall adds a little of that same draw to its previous value:', 'The brown wall adds a little of that same draw to its previous value.'),
        ('the measured frequency range and preparation are recorded in the tutorial companion.', 'the measured frequency range and preparation are recorded in the [artifact notes](../../artifacts/related_weather/README.md).'),
    ]
    for a,b in replacements:
        assert a in final, a
        final=final.replace(a,b,1)
    final=re.sub(r'\n```gdscript\n.*?\n```\n','\n',final,flags=re.S)
    final=re.sub(r'\n{3,}','\n\n',final)
    (ROOT/'commons/maps/Random_Noise_Types/final.md').write_text(final,encoding='utf-8')
    print('Wrote first Noise tutorial and light reflective edit; optional surface passage retained.')

if __name__ == '__main__': main()
