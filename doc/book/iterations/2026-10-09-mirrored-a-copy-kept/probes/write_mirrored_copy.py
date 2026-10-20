from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Mirrored_Patterns'
M=R/'commons/maps/PG_Mirrored_Patterns'
O=R/'doc/book/iterations/2026-10-09-mirrored-a-copy-kept'
def code(name): return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```'
text = """# Mirrored Patterns — a copy kept

## Learning elements

- Hold an independent copy of a nested array
- Reflect addresses into a separate result
- Inspect the centre row and column of an odd-sized grid
- Change a copying rule while preserving its input

Sculpted Forms kept captured centres separate from their surface. Here we keep a field separate from the image copied out of it. The point returns as the action that commits an operation. The cells, arrays and loops are familiar; the new decision is which addresses may speak for others.

## Start with the existing field

At the museum desk, HOLD keeps the current cellular array. STENCIL returns to that held array and applies quadrant reflection, eight-way reflection, rotation or none. STEP first evolves the displayed field, then applies the selected copying rule. These are two operations in a chosen order.

Our reconstruction isolates quadrant reflection. It uses a declared five-by-five input, so you can account for every destination before trying the larger display. The original automaton, network and pattern tunnel remain available in the hall. We do not need another Life implementation to understand this copying step.

## Keep a witness

Save the following three files together in the prepared Endless Museum project. Attach `panels.gd` to an empty Node3D at unit scale in an open bay; our test placement is hall-local (8.5, 0, 6.5), yaw 180 degrees. The museum already supplies the player, camera and XRTools.

`reflection.gd` owns a held field and a result. Both contain rows, which are themselves arrays. `duplicate(true)` copies those rows too. A shallow copy would leave the rows shared: writing the result could silently alter the input we meant to preserve.

The function requires a non-empty square field. `n / 2` uses integer division. For five cells, the loop limit is two: rows 0–1 and columns 0–1 supply the values. The reflected partner of x is `n - 1 - x`, because valid addresses run from zero to n minus one. Thus 0 pairs with 4, 1 with 3, and 2 with itself.

""" + code('reflection.gd') + """

Each REFLECT begins again from the held input. A cell in the upper-left quarter writes to its three partners; its own value is already in the copy. The held field never receives those writes. Applying the same operation twice gives the same result.

There is a deliberate limit here. With `INCLUDE_AXES` false, the centre row and column are not written. They retain their held values, which need not be symmetric. This reproduces the installed quadrant loop. A symmetric set of four corners is not proof that every cell in the image obeys the same reflection.

## Put input and result beside each other

`panels.gd` builds two grids from the cubes we already know. The display is fixed to five by five; the reflection model itself accepts any non-empty square array. Each cell is 0.16 metres apart. Dark cells contain 0; light cells contain 1. The pink cross marks the centre row and column in both panels, with dark and light pink carrying the same two values.

Hold the point and use its action to reflect. Moving the point alone does nothing to the array. SPACE does the same on desktop; V restores the held input to the result. The left panel is the witness throughout.

""" + code('panels.gd') + """

M flips the right tip of the result's centre row: address (4, 2), written as `result[2][4]`. It does not edit the held input. Press REFLECT and the mark disappears because the operation starts from that input again. This is not an accumulating drawing tool.

Try M, then H instead. HOLD takes the changed result as a new independent input. Now REFLECT retains that centre-row mark in the baseline rule, since this loop does not overwrite the axes. R restores the declared opening field. These actions make the difference between viewing, editing and committing a record visible.

The inherited point is unchanged from Sculpted Forms. It supplies pickup and action; its host keeps the release position in the museum's local frame.

""" + code('point_body.gd') + """

## Give the axes a rule

Change only `INCLUDE_AXES := false` to `INCLUDE_AXES := true` in `reflection.gd`. Restart the whole example with the same field.

For five cells, the loop limit becomes three. The top half of the centre column now supplies its lower half; the left half of the centre row supplies its right half. The central cell maps to itself. This is an intentional extension of the installed quadrant operation, not a correction silently made to the museum artifact.

Predict the right-hand centre row: 0, 1, 1, 1, 0. Predict the centre column from top to bottom: 1, 0, 1, 0, 1. Four cells change between the baseline reflection and this edit. Both results still contain thirteen 1s. A count alone cannot tell you whether the axes are symmetric; inspect the addresses and their partners.

The left panel must stay identical. Compare every right-hand address with its horizontal and vertical partner. Then make a different five-by-five input and predict the result before running it. For an even-sized square there is no centre row or column: the two model versions should agree. Our automated checks include those arrays; the five-by-five display would need its layout loops resized before showing them.

## Return to the other constructions

The museum's held field contains 31 by 31 cells. Its quadrant loop reads 15 by 15 positions and leaves the middle cross alone. Eight-way and rotational copying use different loops; this lesson does not claim that they are the same operation with a different name. The rotational implementation passes through floating-point trigonometry and integer addresses.

The network beside the image asks another question. NETWORK changes how six seed positions are connected; SURFACE adds or hides their tunnel skin. Its collision is disabled in both views. The graph counts describe connections, not a guarantee that a body can walk through the specimen. Repeating an image value creates no new passage by itself.

We leave this sequence with operations we can compose: select, guide, branch, connect, carve, sample and copy. Keep their inputs and results explicit. An image can look complete while an address, an opening or a body's support still needs its own rule.

Source: `algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirrored_cellular_automata.gd`, `apply_quad_symmetry()`. Held-field control: `commons/artifacts/timing_machines/pg_workshop.gd`, `_stencil()`.
"""
(M/'tutorial.md').write_bytes(text.encode('utf8'))
f=(O/'before/commons/maps/PG_Mirrored_Patterns/final.md').read_text(encoding='utf8')
f=re.sub(r'For the quadrant arrangement,.*?```\n', 'For the quadrant arrangement, one quarter supplies the corresponding positions in the other three. The source of the repetition occupies only part of what we see.\n', f, count=1, flags=re.S)
f=f.replace('A symmetrical intention still passes through a particular implementation.', 'A symmetrical intention still passes through a particular implementation. Look along the centre cross: what the loop leaves alone may interrupt the unity the rest of the image promises. Keeping the input beside the result gives that interruption somewhere to be seen.')
(M/'final.md').write_bytes(f.encode('utf8'))
print('Wrote Mirrored Patterns tutorial and targeted reflection')
